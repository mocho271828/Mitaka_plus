#include "earth_layers.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
double unit_dot(Vec3 a, Vec3 b) {
    for (const auto value : {a, b}) {
        const double length = std::hypot(value.x, value.y, value.z);
        if (!std::isfinite(length) || std::abs(length - 1) > 1e-8)
            throw std::invalid_argument("Earth layer directions must be finite unit vectors");
    }
    return std::clamp(a.x * b.x + a.y * b.y + a.z * b.z, -1.0, 1.0);
}
} // namespace

double earth_cloud_radius_factor(double topography_scale) {
    if (!std::isfinite(topography_scale) || topography_scale < 0)
        throw std::invalid_argument("Earth topography scale must be finite and nonnegative");
    const double factor = 1 + (10.0 / 6378.1) * topography_scale;
    if (!std::isfinite(factor))
        throw std::invalid_argument("Earth cloud radius must be finite");
    return factor;
}

void validate_earth_layer_view(const EarthLayerView& view) {
    const auto camera = view.earth_to_camera_ecliptic_au;
    const double distance = std::hypot(camera.x, camera.y, camera.z);
    if (!std::isfinite(distance) || distance <= 0
        || !std::isfinite(view.display_radius_au) || view.display_radius_au <= 0
        || !std::isfinite(distance / view.display_radius_au))
        throw std::invalid_argument("Earth layer camera distance and radius must be finite and positive");
    (void)unit_dot(view.earth_to_sun_ecliptic_unit, view.earth_to_sun_ecliptic_unit);
    const double factor = earth_cloud_radius_factor(view.topography_scale);
    if (!std::isfinite(view.display_radius_au * factor))
        throw std::invalid_argument("Earth cloud radius must be finite");
}

double earth_night_gain(const EarthLayerView& view, bool city_lights) {
    validate_earth_layer_view(view);
    const auto camera = view.earth_to_camera_ecliptic_au;
    const double distance = std::hypot(camera.x, camera.y, camera.z);
    if (!city_lights)
        return std::clamp(0.3 * (1 - (distance / view.display_radius_au - 1) / 1.7), 0.0, 1.0);
    const Vec3 direction{camera.x / distance, camera.y / distance, camera.z / distance};
    return std::max(0.0, -unit_dot(direction, view.earth_to_sun_ecliptic_unit));
}

double earth_layer_extent(const EarthLayerBinding& binding) {
    validate_earth_layer_view(binding.view);
    if (!binding.options.clouds || !binding.assets.clouds) return 1;
    const double factor = earth_cloud_radius_factor(binding.view.topography_scale);
    const auto camera = binding.view.earth_to_camera_ecliptic_au;
    const double distance = std::hypot(camera.x, camera.y, camera.z);
    return distance > binding.view.display_radius_au * factor ? factor : 1;
}

double earth_night_brightness(Vec3 normal, Vec3 sun_direction, double gain) {
    if (!std::isfinite(gain) || gain < 0 || gain > 1)
        throw std::invalid_argument("Earth night-light gain must be in [0, 1]");
    return gain * std::max(0.0, -unit_dot(normal, sun_direction));
}

double earth_cloud_brightness(Vec3 normal, Vec3 sun_direction) {
    return std::clamp(0.03 + std::max(0.0, unit_dot(normal, sun_direction)), 0.0, 1.0);
}

std::array<double, 3> earth_add_rgb(std::array<double, 3> destination,
                                  std::array<double, 3> source) {
    for (std::size_t channel = 0; channel < destination.size(); ++channel) {
        if (!std::isfinite(destination[channel]) || !std::isfinite(source[channel])
            || destination[channel] < 0 || destination[channel] > 255
            || source[channel] < 0 || source[channel] > 255)
            throw std::invalid_argument("Earth layer RGB must be finite and in [0, 255]");
        destination[channel] = std::min(255.0, destination[channel] + source[channel]);
    }
    return destination;
}

} // namespace mitaka::gui
