#include "mitaka/satellite_position.hpp"

#include <cmath>
#include <stdexcept>

namespace mitaka {
namespace {
bool finite(Vec3 v) { return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z); }
double dot(Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }
Vec3 cross(Vec3 a, Vec3 b) { return {a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x}; }

bool valid_rotation(const SatelliteRotation& r) {
    if (!finite(r.x_axis) || !finite(r.y_axis) || !finite(r.z_axis)) return false;
    constexpr double tolerance = 1e-10;
    return std::abs(dot(r.x_axis, r.x_axis)-1) <= tolerance &&
        std::abs(dot(r.y_axis, r.y_axis)-1) <= tolerance &&
        std::abs(dot(r.z_axis, r.z_axis)-1) <= tolerance &&
        std::abs(dot(r.x_axis, r.y_axis)) <= tolerance &&
        std::abs(dot(r.x_axis, r.z_axis)) <= tolerance &&
        std::abs(dot(r.y_axis, r.z_axis)) <= tolerance &&
        std::abs(dot(cross(r.x_axis, r.y_axis), r.z_axis)-1) <= tolerance;
}

SatellitePositionEvaluation failure(SatellitePositionDiagnosticCode code, const char* message) {
    return {std::nullopt, {{code, message}}};
}
} // namespace

SatellitePositionEvaluation evaluate_satellite_relative_position(
    const SatellitePositionElements& e, const SatelliteTimedRotation& timed_rotation, double jd) {
    using Code = SatellitePositionDiagnosticCode;
    if (!std::isfinite(jd) || !std::isfinite(timed_rotation.legacy_julian_date))
        return failure(Code::invalid_time, "satellite position: non-finite numeric Julian date");
    if (timed_rotation.legacy_julian_date != jd)
        return failure(Code::mismatched_rotation_time, "satellite position: rotation date differs from position date");
    for (const double value : {e.epoch_jd, e.semi_major_axis_km, e.eccentricity,
             e.mean_anomaly_deg, e.mean_motion_deg_per_day, e.periapsis_period_years,
             e.node_period_years}) {
        if (!std::isfinite(value)) return failure(Code::invalid_elements, "satellite position: non-finite element");
    }
    if (e.semi_major_axis_km <= 0 || e.eccentricity < 0)
        return failure(Code::invalid_elements, "satellite position: require a > 0 and e >= 0");
    if (e.eccentricity >= 1)
        return failure(Code::unsupported_orbit, "satellite position: only audited elliptic orbit branch is supported");
    if (!valid_rotation(timed_rotation.rotation))
        return failure(Code::invalid_rotation, "satellite position: rotation must be finite, orthonormal and right-handed");
    const double dw = e.periapsis_period_years == 0 ? 0 : 360.0 / e.periapsis_period_years / 365.25;
    const double dn = e.node_period_years == 0 ? 0 : 360.0 / e.node_period_years / 365.25;
    const double rate = e.mean_motion_deg_per_day - dw - dn;
    if (!std::isfinite(dw) || !std::isfinite(dn) || !std::isfinite(rate))
        return failure(Code::numerical_range, "satellite position: precession or mean-motion overflow");
    try {
        // n は独立入力なので a=1 AU の結果を無次元形状として利用できる。
        // a_km を最後に掛け、旧版と現代の AU 定数を混在させない。
        const auto unit = orbital_state({e.epoch_jd, 1, e.eccentricity, e.mean_anomaly_deg,
                                          rate, 0, 0, 0}, jd).position_au;
        const auto& r = timed_rotation.rotation;
        const Vec3 position{
            (r.x_axis.x*unit.x + r.y_axis.x*unit.y + r.z_axis.x*unit.z) * e.semi_major_axis_km,
            (r.x_axis.y*unit.x + r.y_axis.y*unit.y + r.z_axis.y*unit.z) * e.semi_major_axis_km,
            (r.x_axis.z*unit.x + r.y_axis.z*unit.y + r.z_axis.z*unit.z) * e.semi_major_axis_km};
        if (!finite(position)) return failure(Code::numerical_range, "satellite position: coordinate overflow");
        return {position, {}};
    } catch (const std::out_of_range& error) {
        return {std::nullopt, {{Code::numerical_range, error.what()}}};
    } catch (const std::invalid_argument& error) {
        return {std::nullopt, {{Code::invalid_elements, error.what()}}};
    } catch (const std::runtime_error& error) {
        return {std::nullopt, {{Code::convergence_failure, error.what()}}};
    }
}
} // namespace mitaka
