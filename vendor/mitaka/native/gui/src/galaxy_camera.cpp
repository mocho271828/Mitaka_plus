#include "galaxy_camera.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double tangent_half_fov = 0.41421356237309504880;

void position_valid(NativeEclipticPositionPc position) {
    for (double value : {position.x_pc, position.y_pc, position.z_pc})
        if (!std::isfinite(value) || std::abs(value) > maximum_galaxy_coordinate_pc)
            throw std::invalid_argument("galaxy position outside finite parsec range");
}
void dimensions(double width, double height) {
    if (!std::isfinite(width) || width <= 0 || width > 1e7 ||
        !std::isfinite(height) || height <= 0 || height > 1e7)
        throw std::invalid_argument("invalid galaxy viewport dimensions");
}
void deltas(double dx, double dy) {
    if (!std::isfinite(dx) || !std::isfinite(dy))
        throw std::invalid_argument("galaxy camera movement must be finite");
}
SolarCamera direction_camera(const GalaxyCameraPc& camera) {
    // pc 位置/距離は渡さず、既存の単位方向・操作角の契約だけを再利用する。
    SolarCamera direction;
    direction.yaw_deg = camera.yaw_deg;
    direction.pitch_deg = camera.pitch_deg;
    direction.frame = camera.frame;
    direction.roll_deg = camera.roll_deg;
    direction.frame_is_orbit = camera.frame_is_orbit;
    return direction;
}
double dot(NativeEclipticPositionPc value, Vec3 axis) {
    return value.x_pc * axis.x + value.y_pc * axis.y + value.z_pc * axis.z;
}
GalaxyCameraPc normalized_camera(GalaxyCameraPc camera) {
    const auto target = normalized_camera_target(
        {{camera.target.x_pc, camera.target.y_pc, camera.target.z_pc}, camera.target_offset_au},
        camera.distance_pc * astronomical_units_per_parsec);
    camera.target = {target.anchor_pc.x, target.anchor_pc.y, target.anchor_pc.z};
    camera.target_offset_au = target.offset_au;
    return camera;
}
} // namespace

GalaxyCameraPc checked_galaxy_camera(GalaxyCameraPc camera) {
    position_valid(camera.target);
    const auto offset = camera.target_offset_au;
    position_valid({camera.target.x_pc + offset.x / astronomical_units_per_parsec,
                    camera.target.y_pc + offset.y / astronomical_units_per_parsec,
                    camera.target.z_pc + offset.z / astronomical_units_per_parsec});
    if (!std::isfinite(camera.yaw_deg) || !std::isfinite(camera.pitch_deg) ||
        std::abs(camera.pitch_deg) > 89 || !std::isfinite(camera.distance_pc) ||
        camera.distance_pc < minimum_galaxy_projection_distance_pc ||
        camera.distance_pc > maximum_galaxy_coordinate_pc)
        throw std::invalid_argument("invalid galaxy camera in parsecs");
    (void)solar_camera_basis(direction_camera(camera));
    return camera;
}

void GalaxyCameraPc::orbit(double dx, double dy) {
    (void)checked_galaxy_camera(*this);
    auto direction = direction_camera(*this);
    direction.orbit(dx, dy);
    yaw_deg = direction.yaw_deg;
    pitch_deg = direction.pitch_deg;
    frame = direction.frame;
    roll_deg = direction.roll_deg;
}
void GalaxyCameraPc::roll(double degrees) {
    (void)checked_galaxy_camera(*this);
    auto direction = direction_camera(*this);
    direction.roll(degrees);
    frame = direction.frame;
    roll_deg = direction.roll_deg;
}
void GalaxyCameraPc::pan(double dx, double dy, double width, double height) {
    (void)checked_galaxy_camera(*this);
    dimensions(width, height);
    deltas(dx, dy);
    const auto axes = solar_camera_basis(direction_camera(*this));
    const double scale = 2 * distance_pc * astronomical_units_per_parsec * tangent_half_fov / height;
    const double horizontal = dx * scale, vertical = dy * scale;
    auto next = normalized_camera(*this);
    next.target_offset_au = {
        next.target_offset_au.x - axes.right.x * horizontal + axes.up.x * vertical,
        next.target_offset_au.y - axes.right.y * horizontal + axes.up.y * vertical,
        next.target_offset_au.z - axes.right.z * horizontal + axes.up.z * vertical};
    (void)checked_galaxy_camera(next);
    target = next.target;
    target_offset_au = next.target_offset_au;
}
void GalaxyCameraPc::zoom(double delta) {
    (void)checked_galaxy_camera(*this);
    deltas(delta, 0);
    const double next_log = std::log(distance_pc) + std::clamp(delta, -100.0, 100.0);
    if (next_log <= std::log(minimum_galaxy_distance_pc)) distance_pc = minimum_galaxy_distance_pc;
    else if (next_log >= std::log(maximum_galaxy_coordinate_pc)) distance_pc = maximum_galaxy_coordinate_pc;
    else distance_pc = std::exp(next_log);
}

GalaxyProjector::GalaxyProjector(GalaxyCameraPc camera, double width, double height)
    : camera_(normalized_camera(checked_galaxy_camera(camera))),
      basis_(solar_camera_basis(direction_camera(camera_))), width_(width), height_(height) {
    dimensions(width, height);
}

std::optional<GalaxyProjectionPc> GalaxyProjector::project(NativeEclipticPositionPc position) const {
    position_valid(position);
    const NativeEclipticPositionPc relative{
        (position.x_pc - camera_.target.x_pc) - camera_.target_offset_au.x / astronomical_units_per_parsec,
        (position.y_pc - camera_.target.y_pc) - camera_.target_offset_au.y / astronomical_units_per_parsec,
        (position.z_pc - camera_.target.z_pc) - camera_.target_offset_au.z / astronomical_units_per_parsec};
    const double depth_pc = camera_.distance_pc - dot(relative, basis_.outward);
    if (depth_pc < camera_.distance_pc * 1e-4) return std::nullopt;
    const double scale = (height_ / 2) / tangent_half_fov / depth_pc;
    const double x = width_ / 2 + dot(relative, basis_.right) * scale;
    const double y = height_ / 2 - dot(relative, basis_.up) * scale;
    if (!std::isfinite(x) || !std::isfinite(y)) return std::nullopt;
    return GalaxyProjectionPc{x, y, depth_pc};
}
bool GalaxyProjector::contains(const GalaxyProjectionPc& position) const noexcept {
    return position.x >= 0 && position.x <= width_ && position.y >= 0 && position.y <= height_;
}

} // namespace mitaka::gui
