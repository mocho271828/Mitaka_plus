#include "shared_camera.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {

PreciseCameraTarget precise_from_au(Vec3 target) {
    const double scale = astronomical_units_per_parsec;
    const Vec3 anchor{target.x / scale, target.y / scale, target.z / scale};
    return {anchor, {std::fma(-anchor.x, scale, target.x),
                     std::fma(-anchor.y, scale, target.y),
                     std::fma(-anchor.z, scale, target.z)}};
}

Vec3 approximate_au(const PreciseCameraTarget& position) {
    const double scale = astronomical_units_per_parsec;
    return {std::fma(position.anchor_pc.x, scale, position.offset_au.x),
            std::fma(position.anchor_pc.y, scale, position.offset_au.y),
            std::fma(position.anchor_pc.z, scale, position.offset_au.z)};
}

SolarCamera direction_camera(const SharedCamera& camera) {
    SolarCamera direction;
    direction.yaw_deg = camera.yaw_deg;
    direction.pitch_deg = camera.pitch_deg;
    direction.frame = camera.frame;
    direction.roll_deg = camera.roll_deg;
    direction.frame_is_orbit = camera.frame_is_orbit;
    direction.vertical_fov_deg = camera.vertical_fov_deg;
    return direction;
}

void validate(const SharedCamera& camera) {
    if (!std::isfinite(camera.target_au.x) || !std::isfinite(camera.target_au.y) ||
        !std::isfinite(camera.target_au.z) || !std::isfinite(camera.distance_au) ||
        camera.distance_au < minimum_shared_distance_au ||
        camera.distance_au > maximum_shared_distance_au)
        throw std::invalid_argument("invalid shared camera in AU");
    if (camera.precise_target) {
        const auto& p = *camera.precise_target;
        for (double value : {p.anchor_pc.x, p.anchor_pc.y, p.anchor_pc.z,
                             p.offset_au.x, p.offset_au.y, p.offset_au.z})
            if (!std::isfinite(value)) throw std::invalid_argument("invalid shared camera target");
        const Vec3 expected = approximate_au(p);
        if (expected.x != camera.target_au.x || expected.y != camera.target_au.y || expected.z != camera.target_au.z)
            throw std::invalid_argument("inconsistent shared camera target");
    }
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
    const double scale = 2 * distance_au * solar_camera_tangent(direction_camera(*this)) / height;
    const double horizontal = dx_points * scale, vertical = dy_points * scale;
    const Vec3 delta{-axes.right.x * horizontal + axes.up.x * vertical,
                     -axes.right.y * horizontal + axes.up.y * vertical,
                     -axes.right.z * horizontal + axes.up.z * vertical};
    for (double value : {delta.x, delta.y, delta.z})
        if (!std::isfinite(value)) throw std::invalid_argument("shared camera pan exceeds finite coordinate range");
    auto next = precise_target.value_or(precise_from_au(target_au));
    const auto anchor = next.anchor_pc;
    if (std::abs(anchor.x) > maximum_solar_anchor_pc || std::abs(anchor.y) > maximum_solar_anchor_pc ||
        std::abs(anchor.z) > maximum_solar_anchor_pc) {
        const Vec3 approximate{target_au.x + delta.x, target_au.y + delta.y, target_au.z + delta.z};
        for (double value : {approximate.x, approximate.y, approximate.z})
            if (!std::isfinite(value)) throw std::invalid_argument("shared camera pan exceeds finite coordinate range");
        target_au = approximate;
        precise_target.reset();
        return;
    }
    next = normalized_camera_target(next, distance_au);
    next.offset_au = {next.offset_au.x + delta.x, next.offset_au.y + delta.y, next.offset_au.z + delta.z};
    const Vec3 approximate = approximate_au(next);
    for (double value : {next.offset_au.x, next.offset_au.y, next.offset_au.z,
                         approximate.x, approximate.y, approximate.z})
        if (!std::isfinite(value)) throw std::invalid_argument("shared camera pan exceeds finite coordinate range");
    target_au = approximate;
    precise_target = next;
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
    SharedCamera result{camera.target, camera.yaw_deg, camera.pitch_deg, camera.distance_au, camera.frame, camera.roll_deg, camera.frame_is_orbit, camera.precise_target, camera.vertical_fov_deg};
    validate(result);
    return result;
}

SharedCamera shared_camera_from_galaxy(const GalaxyCameraPc& camera) {
    (void)checked_galaxy_camera(camera);
    const PreciseCameraTarget target{{camera.target.x_pc, camera.target.y_pc, camera.target.z_pc}, camera.target_offset_au};
    return {approximate_au(target), camera.yaw_deg, camera.pitch_deg,
            camera.distance_pc * astronomical_units_per_parsec,
            camera.frame, camera.roll_deg, camera.frame_is_orbit, target, camera.vertical_fov_deg};
}

SolarCamera solar_camera_from_shared(const SharedCamera& camera) {
    validate(camera);
    SolarCamera result{camera.target_au, camera.yaw_deg, camera.pitch_deg,
                       camera.distance_au, camera.frame, camera.roll_deg, camera.frame_is_orbit};
    result.precise_target = camera.precise_target;
    result.vertical_fov_deg = camera.vertical_fov_deg;
    (void)solar_camera_basis(result);
    return result;
}

GalaxyCameraPc galaxy_camera_from_shared(const SharedCamera& camera) {
    validate(camera);
    const auto scale = astronomical_units_per_parsec;
    const auto target = camera.precise_target.value_or(precise_from_au(camera.target_au));
    return checked_galaxy_camera({{target.anchor_pc.x, target.anchor_pc.y, target.anchor_pc.z},
                                  camera.yaw_deg, camera.pitch_deg, camera.distance_au / scale,
                                  camera.frame, camera.roll_deg, camera.frame_is_orbit, target.offset_au, camera.vertical_fov_deg});
}

} // namespace mitaka::gui
