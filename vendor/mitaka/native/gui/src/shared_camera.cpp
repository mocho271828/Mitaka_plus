#include "shared_camera.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double tangent_half_fov = 0.41421356237309504880;

SolarCamera direction_camera(const SharedCamera& camera) {
    SolarCamera direction;
    direction.yaw_deg = camera.yaw_deg;
    direction.pitch_deg = camera.pitch_deg;
    direction.frame = camera.frame;
    direction.roll_deg = camera.roll_deg;
    direction.frame_is_orbit = camera.frame_is_orbit;
    return direction;
}

void validate(const SharedCamera& camera) {
    if (!std::isfinite(camera.target_au.x) || !std::isfinite(camera.target_au.y) ||
        !std::isfinite(camera.target_au.z) || !std::isfinite(camera.distance_au) ||
        camera.distance_au < minimum_shared_distance_au ||
        camera.distance_au > maximum_shared_distance_au)
        throw std::invalid_argument("invalid shared camera in AU");
    (void)solar_camera_basis(direction_camera(camera));
}
} // namespace

void SharedCamera::orbit(double dx_points, double dy_points) {
    validate(*this);
    auto direction = direction_camera(*this);
    direction.orbit(dx_points, dy_points);
    yaw_deg = direction.yaw_deg;
    pitch_deg = direction.pitch_deg;
    frame = direction.frame;
    roll_deg = direction.roll_deg;
}

void SharedCamera::pan(double dx_points, double dy_points, double width, double height) {
    validate(*this);
    if (!std::isfinite(dx_points) || !std::isfinite(dy_points) || !std::isfinite(width) ||
        width <= 0 || !std::isfinite(height) || height <= 0)
        throw std::invalid_argument("invalid shared camera pan or viewport");
    const auto axes = solar_camera_basis(direction_camera(*this));
    const double scale = 2 * distance_au * tangent_half_fov / height;
    const double horizontal = dx_points * scale, vertical = dy_points * scale;
    const Vec3 next{target_au.x - axes.right.x * horizontal + axes.up.x * vertical,
                    target_au.y - axes.right.y * horizontal + axes.up.y * vertical,
                    target_au.z - axes.right.z * horizontal + axes.up.z * vertical};
    if (!std::isfinite(next.x) || !std::isfinite(next.y) || !std::isfinite(next.z))
        throw std::invalid_argument("shared camera pan exceeds finite coordinate range");
    target_au = next;
}

void SharedCamera::zoom(double logarithmic_delta) {
    validate(*this);
    if (!std::isfinite(logarithmic_delta))
        throw std::invalid_argument("shared camera zoom must be finite");
    const double next_log = std::log(distance_au) + std::clamp(logarithmic_delta, -100.0, 100.0);
    if (next_log <= std::log(minimum_shared_distance_au)) distance_au = minimum_shared_distance_au;
    else if (next_log >= std::log(maximum_shared_distance_au)) distance_au = maximum_shared_distance_au;
    else distance_au = std::clamp(std::exp(next_log), minimum_shared_distance_au,
                                  maximum_shared_distance_au);
}

SharedCamera shared_camera_from_solar(const SolarCamera& camera) {
    (void)solar_camera_basis(camera);
    SharedCamera result{camera.target, camera.yaw_deg, camera.pitch_deg, camera.distance_au, camera.frame, camera.roll_deg, camera.frame_is_orbit};
    validate(result);
    return result;
}

SharedCamera shared_camera_from_galaxy(const GalaxyCameraPc& camera) {
    (void)checked_galaxy_camera(camera);
    return {{camera.target.x_pc * astronomical_units_per_parsec,
             camera.target.y_pc * astronomical_units_per_parsec,
             camera.target.z_pc * astronomical_units_per_parsec},
            camera.yaw_deg, camera.pitch_deg, camera.distance_pc * astronomical_units_per_parsec,
            camera.frame, camera.roll_deg, camera.frame_is_orbit};
}

SolarCamera solar_camera_from_shared(const SharedCamera& camera) {
    validate(camera);
    SolarCamera result{camera.target_au, camera.yaw_deg, camera.pitch_deg,
                       camera.distance_au, camera.frame, camera.roll_deg, camera.frame_is_orbit};
    (void)solar_camera_basis(result);
    return result;
}

GalaxyCameraPc galaxy_camera_from_shared(const SharedCamera& camera) {
    validate(camera);
    const auto scale = astronomical_units_per_parsec;
    return checked_galaxy_camera({{camera.target_au.x / scale, camera.target_au.y / scale,
                                   camera.target_au.z / scale},
                                  camera.yaw_deg, camera.pitch_deg, camera.distance_au / scale,
                                  camera.frame, camera.roll_deg, camera.frame_is_orbit});
}

} // namespace mitaka::gui
