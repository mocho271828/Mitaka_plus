#include "mitaka/small_body_orbit.hpp"

#include <cmath>
#include <initializer_list>
#include <stdexcept>

namespace mitaka {
namespace {
constexpr double pi = 3.14159265358979323846;
constexpr double gaussian_k = 0.01720209895;

bool finite(Vec3 v) { return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z); }

Vec3 rotate(Vec3 v, const PerihelionElements& e) {
    const double w = std::remainder(e.argument_of_perihelion_deg, 360.0) * pi / 180;
    const double i = std::remainder(e.inclination_deg, 360.0) * pi / 180;
    const double n = std::remainder(e.ascending_node_deg, 360.0) * pi / 180;
    const double x = v.x * std::cos(w) - v.y * std::sin(w);
    const double y = v.x * std::sin(w) + v.y * std::cos(w);
    return {x * std::cos(n) - y * std::cos(i) * std::sin(n),
            x * std::sin(n) + y * std::cos(i) * std::cos(n), y * std::sin(i)};
}
} // namespace

OrbitalState perihelion_orbital_state(const PerihelionElements& e, double jd) {
    for (double value : {e.perihelion_distance_au, e.eccentricity, e.perihelion_jd,
                         e.ascending_node_deg, e.inclination_deg,
                         e.argument_of_perihelion_deg, jd}) {
        if (!std::isfinite(value)) throw std::invalid_argument("non-finite perihelion element or time");
    }
    if (e.perihelion_distance_au <= 0 || e.eccentricity < 0)
        throw std::invalid_argument("perihelion distance must be positive and eccentricity nonnegative");

    if (e.eccentricity != 1) {
        const double a = e.perihelion_distance_au / std::abs(1 - e.eccentricity);
        const double n = (gaussian_k * 180 / pi) / a / std::sqrt(a);
        if (!std::isfinite(a) || !std::isfinite(n) || a <= 0 || n <= 0)
            throw std::out_of_range("perihelion elements exceed Kepler numerical range");
        return orbital_state({e.perihelion_jd, a, e.eccentricity, 0, n,
                              e.ascending_node_deg, e.inclination_deg,
                              e.argument_of_perihelion_deg}, jd);
    }

    // D = tan(f/2)、D^3 + 3D = 2B。Viète 解で巨大な B の二乗を避ける。
    // 導出と定数の根拠は SMALL_BODY_PROVENANCE.md を参照。
    const double q = e.perihelion_distance_au;
    const double b = (3 * gaussian_k / (2 * std::sqrt(2.0))) * ((jd - e.perihelion_jd) / q) /
                     std::sqrt(q);
    if (!std::isfinite(b)) throw std::out_of_range("parabolic time exceeds numerical range");
    const double d = 2 * std::sinh(std::asinh(b) / 3);
    const double scale = (std::sqrt(2.0) * gaussian_k / std::sqrt(q)) / (1 + d*d);
    const OrbitalState result{rotate({q * (1 - d*d), 2 * q * d, 0}, e),
                              rotate({-d * scale, scale, 0}, e)};
    if (!finite(result.position_au) || !finite(result.velocity_au_per_day) || scale == 0)
        throw std::out_of_range("parabolic state exceeds numerical range");
    return result;
}
} // namespace mitaka
