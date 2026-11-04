#include "distance_scales.hpp"
#include "grid_geometry.hpp"
#include "surface_navigation.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double radians = 3.14159265358979323846 / 180;
constexpr double au_meters = astronomical_unit_km * 1000;
constexpr double light_year_au = 299792458.0 * 365.25 * 86400 / au_meters;

void require_positive(double value) {
    if (!std::isfinite(value) || value <= 0)
        throw std::invalid_argument("distance scale must be finite and positive");
}

double square_opacity(double ratio) {
    if (ratio <= 0.01 || ratio >= 5) return 0;
    return 0.9 * std::min({1.0, (ratio - 0.01) / 0.04, (5 - ratio) / 0.6});
}
} // namespace

const std::array<CircleDistanceScale, 21>& circle_distance_scales() {
    static const auto scales = [] {
        std::array<CircleDistanceScale, 21> result{};
        const std::array<double, 5> au{{1, 10, 100, 1000, 10000}};
        const std::array<double, 16> ly{{1, 3, 10, 30, 100, 300, 1000, 3000,
            1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1.38e10}};
        for (std::size_t index = 0; index < au.size(); ++index)
            result[index] = {au[index], au[index], false, index == 0 ? 230.0 : 45.0};
        for (std::size_t index = 0; index < ly.size(); ++index)
            result[index + au.size()] = {ly[index] * light_year_au, ly[index], true,
                                        index + 1 == ly.size() ? 300.0 : 45.0};
        return result;
    }();
    return scales;
}

Vec3 circle_distance_scale_point(const CircleDistanceScale& scale, double angle_deg) {
    require_positive(scale.radius_au);
    if (!std::isfinite(angle_deg)) throw std::invalid_argument("distance scale angle must be finite");
    const double angle = std::remainder(angle_deg, 360) * radians;
    const Vec3 point{scale.radius_au * std::cos(angle), scale.radius_au * std::sin(angle), 0};
    return scale.galactic_plane ? j2000_equatorial_to_ecliptic(galactic_to_j2000_equatorial(point)) : point;
}

double circle_distance_scale_opacity(double distance, double radius) {
    require_positive(distance);
    require_positive(radius);
    const double ratio = distance / radius;
    return std::clamp((ratio - 1) / 4, 0.0, 1.0) * std::clamp((70 - ratio) / 56, 0.0, 1.0);
}

std::vector<SquareDistanceScale> square_distance_scales(const SolarCamera& camera) {
    const auto axes = solar_camera_basis(camera);
    std::vector<SquareDistanceScale> result;
    for (int exponent = 0; exponent < 28; ++exponent) {
        const double side = std::pow(10.0, exponent) / au_meters;
        const double opacity = square_opacity(side / camera.distance_au);
        if (opacity <= 0) continue;
        SquareDistanceScale square{exponent, opacity, {}};
        const std::array<std::array<int, 2>, 5> signs{{{-1, -1}, {1, -1}, {1, 1}, {-1, 1}, {-1, -1}}};
        for (std::size_t index = 0; index < signs.size(); ++index) {
            const double x = signs[index][0] * side / 2, y = signs[index][1] * side / 2;
            square.vertices[index] = {camera.target.x + x * axes.right.x + y * axes.up.x,
                                      camera.target.y + x * axes.right.y + y * axes.up.y,
                                      camera.target.z + x * axes.right.z + y * axes.up.z};
        }
        result.push_back(square);
    }
    return result;
}

} // namespace mitaka::gui
