#include "mitaka/satellite_rotation.hpp"

#include <array>
#include <cmath>
#include <initializer_list>
#include <utility>

namespace mitaka {
namespace {
constexpr double degrees_to_radians = 3.141592653589793238462643383279502884 / 180.0;
// 対象 exe は L/I と Q に異なる値・符号を使う。既存の傾斜定数へ統一しない。
constexpr double legacy_li_tilt_deg = 23.43870583;
constexpr double legacy_q_tilt_deg = 23.439291111111114;

double radians(double angle) {
    return std::remainder(angle, 360.0) * degrees_to_radians;
}

SatelliteRotation rotate_x(SatelliteRotation basis, double angle) {
    const double c = std::cos(radians(angle)), s = std::sin(radians(angle));
    const auto rotate = [c, s](Vec3 v) -> Vec3 {
        return {v.x, c*v.y - s*v.z, s*v.y + c*v.z};
    };
    return {rotate(basis.x_axis), rotate(basis.y_axis), rotate(basis.z_axis)};
}

SatelliteRotation rotate_z(SatelliteRotation basis, double angle) {
    const double c = std::cos(radians(angle)), s = std::sin(radians(angle));
    const auto rotate = [c, s](Vec3 v) -> Vec3 {
        return {c*v.x - s*v.y, s*v.x + c*v.y, v.z};
    };
    return {rotate(basis.x_axis), rotate(basis.y_axis), rotate(basis.z_axis)};
}

Vec3 apply(const SatelliteRotation& a, Vec3 b) {
    return {a.x_axis.x*b.x + a.y_axis.x*b.y + a.z_axis.x*b.z,
            a.x_axis.y*b.x + a.y_axis.y*b.y + a.z_axis.y*b.z,
            a.x_axis.z*b.x + a.y_axis.z*b.y + a.z_axis.z*b.z};
}

SatelliteRotation compose(const SatelliteRotation& a, const SatelliteRotation& b) {
    return {apply(a, b.x_axis), apply(a, b.y_axis), apply(a, b.z_axis)};
}

SatelliteRotationEvaluation failure(SatelliteRotationDiagnosticCode code, std::size_t index,
                                    std::string field, std::string message) {
    return {std::nullopt, {{code, index, std::move(field), std::move(message)}}};
}

// 各 node の C 依存以外を評価する。C はローカル O(t) のみを返す。
SatelliteRotationEvaluation local_rotation(const SatelliteRotationInput& input,
                                           std::size_t index, double jd) {
    using Code = SatelliteRotationDiagnosticCode;
    if (input.name_bytes == "Moon") return {SatelliteRotation{}, {}};
    const char plane = input.reference_plane;
    if (plane != 'L' && plane != 'I' && plane != 'E' && plane != 'C' && plane != 'Q')
        return failure(Code::unknown_reference_plane, index, "RefPlane", "unknown satellite reference plane");
    if (!input.elements)
        return failure(Code::missing_elements, index, "orbit", "satellite rotation elements are unresolved");
    const auto& e = *input.elements;
    for (double value : {e.epoch_jd, e.argument_of_periapsis_deg, e.inclination_deg,
                         e.raw_ascending_node_deg, e.periapsis_period_years, e.node_period_years}) {
        if (!std::isfinite(value))
            return failure(Code::invalid_elements, index, "orbit", "non-finite satellite rotation element");
    }
    // 元の保存順と同様、親の補正は歳差前に一度だけ適用する。
    const double loaded_node = e.raw_ascending_node_deg + (input.apply_mars_node_correction ? 43.0 : 0.0);
    const double dw = e.periapsis_period_years == 0 ? 0 : 360.0 / e.periapsis_period_years / 365.25;
    const double dn = e.node_period_years == 0 ? 0 : 360.0 / e.node_period_years / 365.25;
    const double elapsed = jd - e.epoch_jd;
    const double w = e.argument_of_periapsis_deg + elapsed * dw;
    const double node = loaded_node + elapsed * dn;
    if (!std::isfinite(elapsed) || !std::isfinite(dw) || !std::isfinite(dn) ||
        !std::isfinite(w) || !std::isfinite(node))
        return failure(Code::numerical_range, index, "orbit", "satellite precession exceeds numerical range");
    SatelliteRotation rotation = rotate_z(rotate_x(rotate_z({}, w), e.inclination_deg), node);
    if (plane == 'L') {
        if (!e.pole_right_ascension_deg || !e.pole_declination_deg)
            return failure(Code::missing_elements, index, "RA/Decl", "Laplace pole is unresolved");
        const double ra = *e.pole_right_ascension_deg, dec = *e.pole_declination_deg;
        if (!std::isfinite(ra) || !std::isfinite(dec) || dec < -90 || dec > 90)
            return failure(Code::invalid_elements, index, "RA/Decl", "invalid Laplace pole");
        rotation = rotate_z(rotate_x(rotation, 90 - dec), 90 + std::remainder(ra, 360.0));
    }
    if (plane == 'I' || plane == 'L') rotation = rotate_x(rotation, legacy_li_tilt_deg);
    if (plane == 'Q') {
        if (!input.parent_pole)
            return failure(Code::unresolved_parent_pole, index, "parent", "parent pole is unresolved");
        const auto& pole = *input.parent_pole;
        if (!std::isfinite(pole.legacy_julian_date) || !std::isfinite(pole.right_ascension_deg) ||
            !std::isfinite(pole.declination_deg))
            return failure(Code::invalid_parent_pole, index, "parent", "invalid parent pole");
        if (pole.legacy_julian_date != jd)
            return failure(Code::mismatched_parent_time, index, "parent", "parent pole belongs to another date");
        rotation = rotate_z(rotate_x(rotation, 90 - pole.declination_deg),
                            90 + std::remainder(pole.right_ascension_deg, 360.0));
        rotation = rotate_x(rotation, -legacy_q_tilt_deg);
    }
    return {rotation, {}};
}
} // namespace

SatelliteParentPoleEvaluation evaluate_legacy_satellite_parent_pole(
    LegacyPlanetRegistrationIndex index, double jd) {
    using Code = SatelliteParentPoleDiagnosticCode;
    // 名前ではなく、対象 exe の switch(index) の順に並べる。
    struct Coefficients { double ra, ra_rate, dec, dec_rate; };
    static constexpr std::array<Coefficients,9> coefficients{{
        {281.01,-0.033,61.45,-0.005}, {272.76,0,67.16,0},
        {0,-0.641,90,-0.557}, {317.68143,-0.1061,52.8865,-0.0609},
        {268.05,-0.009,64.49,0.003}, {40.589,-0.036,83.537,-0.004},
        {257.311,0,-15.175,0}, {299.36,0,43.46,0}, {313.02,0,9.09,0}
    }};
    if (index.value >= coefficients.size())
        return {std::nullopt, {{Code::invalid_registration_index,"unknown legacy Planet registration index"}}};
    if (!std::isfinite(jd))
        return {std::nullopt, {{Code::invalid_time,"non-finite legacy Julian date"}}};
    const double centuries = (jd - 2451545.0) / 36525.0;
    const auto& c = coefficients[index.value];
    double ra = c.ra + c.ra_rate * centuries;
    double dec = c.dec + c.dec_rate * centuries;
    if (index.value == 7) {
        const double n = radians(357.85 + 52.316 * centuries);
        ra += 0.7 * std::sin(n);
        dec -= 0.51 * std::cos(n);
    }
    return {SatelliteParentPole{jd,ra,dec}, {}};
}

SatelliteRotationEvaluation evaluate_satellite_rotation(
    const std::vector<SatelliteRotationInput>& records, std::size_t index, double jd) {
    using Code = SatelliteRotationDiagnosticCode;
    if (index >= records.size())
        return failure(Code::invalid_record_index, index, "record", "satellite rotation index is out of range");
    if (!std::isfinite(jd))
        return failure(Code::invalid_time, index, "time", "non-finite legacy Julian date");
    // C は高々一つの依存を持つ。明示スタックにして深い入力でも C++ 再帰を使わない。
    std::vector<bool> visited(records.size(), false);
    std::vector<SatelliteRotation> pending;
    for (;;) {
        if (visited[index])
            return failure(Code::cyclic_dependency, index, "Charon", "cyclic satellite rotation dependency");
        visited[index] = true;
        const auto& input = records[index];
        auto result = local_rotation(input, index, jd);
        if (!result.rotation) return result;
        if (input.reference_plane != 'C' || input.name_bytes == "Moon") {
            for (auto child = pending.rbegin(); child != pending.rend(); ++child)
                result.rotation = compose(*result.rotation, *child);
            return result;
        }
        if (!input.charon_rotation_index)
            return failure(Code::unresolved_charon, index, "Charon", "Charon rotation reference is unresolved");
        if (*input.charon_rotation_index >= records.size())
            return failure(Code::invalid_charon_index, index, "Charon", "Charon rotation index is out of range");
        pending.push_back(*result.rotation);
        index = *input.charon_rotation_index;
    }
}
} // namespace mitaka
