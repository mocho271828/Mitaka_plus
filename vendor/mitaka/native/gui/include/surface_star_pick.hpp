#pragma once
#include "solar_camera.hpp"
#include "sky_model.hpp"
#include <cmath>
#include <functional>

namespace mitaka::gui {
inline std::optional<SolarProjection> project_surface_star(EquatorialCoordinates coordinates,
    const SolarCamera& camera, double width, double height) {
    constexpr double radians = 3.14159265358979323846 / 180;
    const double ra = coordinates.right_ascension_deg * radians;
    const double dec = coordinates.declination_deg * radians;
    const auto direction = j2000_equatorial_to_ecliptic(
        {std::cos(dec) * std::cos(ra), std::cos(dec) * std::sin(ra), std::sin(dec)});
    constexpr double distance = 1e6;
    const Vec3 position{camera.target.x + direction.x * distance, camera.target.y + direction.y * distance,
                        camera.target.z + direction.z * distance};
    const auto point = project_solar(position, camera, width, height);
    if (!point || point->x < 0 || point->x > width || point->y < 0 || point->y > height) return std::nullopt;
    return point;
}
inline std::optional<std::size_t> pick_surface_star(const std::vector<HipparcosRecord>& stars,
    const SolarCamera& camera, double width, double height, ScreenPoint click, bool visible, double magnitude_limit,
    const std::function<bool(ScreenPoint)>& is_occluded) {
    if (!visible || click.x < 0 || click.x >= width || click.y < 0 || click.y >= height || is_occluded(click)) return std::nullopt;
    double nearest = 8 * 8;
    std::optional<std::size_t> selected;
    for (std::size_t i = 0; i < stars.size(); ++i) {
        const auto& star = stars[i];
        if (star.apparent_v_magnitude > magnitude_limit) continue;
        const auto point = project_surface_star({star.right_ascension_degrees, star.declination_degrees}, camera, width, height);
        if (!point) continue;
        const double dx = point->x - click.x, dy = point->y - click.y, distance = dx * dx + dy * dy;
        if (distance <= nearest && !is_occluded({point->x, point->y})) { nearest = distance; selected = i; }
    }
    return selected;
}
} // namespace mitaka::gui
