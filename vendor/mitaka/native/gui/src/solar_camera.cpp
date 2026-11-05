#include "solar_camera.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double radians_per_degree = 3.14159265358979323846 / 180;
constexpr double tangent_half_fov = 0.41421356237309504880;
constexpr double minimum_distance = 0.000005;
constexpr double maximum_distance = maximum_solar_distance_au;

bool finite(Vec3 value) {
    return std::isfinite(value.x) && std::isfinite(value.y) && std::isfinite(value.z);
}

double dot(Vec3 left, Vec3 right) {
    return left.x * right.x + left.y * right.y + left.z * right.z;
}

Vec3 cross(Vec3 a, Vec3 b) {
    return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
}

double minimum(const SolarCamera& camera) { return camera.frame && !camera.frame_is_orbit ? 1e-12 : minimum_distance; }
double near_plane(const SolarCamera& camera) {
    return camera.frame && !camera.frame_is_orbit ? 1e-12 : camera.distance_au * 0.0001;
}

void validate(const SolarCamera& camera) {
    if (!finite(camera.target) || !std::isfinite(camera.yaw_deg)
        || !std::isfinite(camera.pitch_deg) || std::abs(camera.pitch_deg) > 89 || !std::isfinite(camera.roll_deg)
        || !std::isfinite(camera.distance_au) || camera.distance_au < minimum(camera)
        || camera.distance_au > maximum_distance)
        throw std::invalid_argument("invalid solar camera");
    if (camera.frame) {
        const auto& f = *camera.frame;
        for (const auto axis : {f.right, f.up, f.outward})
            if (!finite(axis) || std::abs(dot(axis, axis) - 1) > 1e-8)
                throw std::invalid_argument("solar camera frame must contain unit vectors");
        if (std::abs(dot(f.right, f.up)) > 1e-8
            || std::abs(dot(f.right, f.outward)) > 1e-8
            || std::abs(dot(f.up, f.outward)) > 1e-8
            || dot(cross(f.right, f.up), f.outward) < 1 - 1e-8)
            throw std::invalid_argument("solar camera frame must be right-handed and orthogonal");
    }
}

void dimensions(double width, double height) {
    if (!std::isfinite(width) || width <= 0 || !std::isfinite(height) || height <= 0)
        throw std::invalid_argument("invalid solar viewport dimensions");
}

void deltas(double dx, double dy) {
    if (!std::isfinite(dx) || !std::isfinite(dy))
        throw std::invalid_argument("solar camera movement must be finite");
}

SolarCameraBasis basis(const SolarCamera& camera) {
    if (camera.frame) return *camera.frame;
    const double yaw = std::remainder(camera.yaw_deg, 360) * radians_per_degree;
    const double pitch = camera.pitch_deg * radians_per_degree;
    const double cy = std::cos(yaw), sy = std::sin(yaw);
    const double cp = std::cos(pitch), sp = std::sin(pitch);
    const Vec3 right{-sy, cy, 0}, up{-sp * cy, -sp * sy, cp};
    const double angle = std::remainder(camera.roll_deg, 360) * radians_per_degree;
    const double c = std::cos(angle), s = std::sin(angle);
    return {{cp * cy, cp * sy, sp},
            {right.x*c + up.x*s, right.y*c + up.y*s, right.z*c + up.z*s},
            {up.x*c - right.x*s, up.y*c - right.y*s, up.z*c - right.z*s}};
}

Vec3 rotate(Vec3 value, Vec3 axis, double angle) {
    const double c = std::cos(angle), s = std::sin(angle), along = dot(value, axis) * (1 - c);
    const auto perpendicular = cross(axis, value);
    return {value.x * c + perpendicular.x * s + axis.x * along,
            value.y * c + perpendicular.y * s + axis.y * along,
            value.z * c + perpendicular.z * s + axis.z * along};
}

// x/yは画面の右/上方向のAU、zはカメラ前方の奥行AU。
Vec3 camera_point(Vec3 position, const SolarCamera& camera, const SolarCameraBasis& axes) {
    if (!finite(position)) throw std::invalid_argument("solar position must be finite");
    const Vec3 relative{position.x - camera.target.x, position.y - camera.target.y,
                        position.z - camera.target.z};
    return {dot(relative, axes.right), dot(relative, axes.up),
            camera.distance_au - dot(relative, axes.outward)};
}

std::optional<SolarProjection> project_point(Vec3 point, double near, double width, double height) {
    if (!finite(point) || point.z < near) return std::nullopt;
    const double scale = (height / 2) / tangent_half_fov / point.z;
    const double x = width / 2 + point.x * scale;
    const double y = height / 2 - point.y * scale;
    if (!std::isfinite(x) || !std::isfinite(y)) return std::nullopt;
    return SolarProjection{x, y, point.z};
}
} // namespace

SolarCameraBasis solar_camera_basis(const SolarCamera& camera) {
    validate(camera);
    return basis(camera);
}

Vec3 solar_camera_ray(const SolarCamera& camera, double x, double y, double width, double height) {
    validate(camera);
    dimensions(width, height);
    deltas(x, y);
    const auto axes = basis(camera);
    const double horizontal = ((x - width / 2) / height) * (2 * tangent_half_fov);
    const double vertical = ((height / 2 - y) / height) * (2 * tangent_half_fov);
    const Vec3 ray{-axes.outward.x + horizontal * axes.right.x + vertical * axes.up.x,
                   -axes.outward.y + horizontal * axes.right.y + vertical * axes.up.y,
                   -axes.outward.z + horizontal * axes.right.z + vertical * axes.up.z};
    const double length = std::hypot(ray.x, ray.y, ray.z);
    if (!finite(ray) || !std::isfinite(length))
        throw std::invalid_argument("solar ray exceeds finite coordinate range");
    return {ray.x / length, ray.y / length, ray.z / length};
}

void SolarCamera::orbit(double dx_points, double dy_points) {
    validate(*this);
    deltas(dx_points, dy_points);
    auto next = basis(*this);
    const double yaw = -std::remainder(dx_points, 360 / 0.35) * 0.35 * radians_per_degree;
    const double pitch = -std::remainder(dy_points, 360 / 0.35) * 0.35 * radians_per_degree;
    next.outward = rotate(next.outward, next.up, yaw);
    next.right = rotate(next.right, next.up, yaw);
    next.outward = rotate(next.outward, next.right, pitch);
    next.up = cross(next.outward, next.right);
    if (frame) {
        frame = next;
        return;
    }
    // 通常視点は既存の pitch 制限を維持しつつ、画面基底からロールを復元する。
    yaw_deg = std::atan2(next.outward.y, next.outward.x) / radians_per_degree;
    pitch_deg = std::clamp(std::asin(std::clamp(next.outward.z, -1.0, 1.0)) / radians_per_degree,
                           -89.0, 89.0);
    roll_deg = 0;
    const auto unrolled = basis(*this);
    roll_deg = std::atan2(dot(next.right, unrolled.up), dot(next.right, unrolled.right)) / radians_per_degree;
}

void SolarCamera::roll(double degrees) {
    validate(*this);
    deltas(degrees, 0);
    if (!frame) {
        roll_deg = std::remainder(std::remainder(roll_deg, 360) + std::remainder(degrees, 360), 360);
        return;
    }
    auto next = basis(*this);
    const double angle = std::remainder(degrees, 360) * radians_per_degree;
    next.right = rotate(next.right, next.outward, angle);
    next.up = cross(next.outward, next.right);
    frame = next;
}

void SolarCamera::pan(double dx_points, double dy_points, double width, double height) {
    validate(*this);
    dimensions(width, height);
    deltas(dx_points, dy_points);
    const auto axes = basis(*this);
    const double scale = 2 * distance_au * tangent_half_fov / height;
    const double horizontal = dx_points * scale, vertical = dy_points * scale;
    const Vec3 next{target.x - axes.right.x * horizontal + axes.up.x * vertical,
                    target.y - axes.right.y * horizontal + axes.up.y * vertical,
                    target.z - axes.right.z * horizontal + axes.up.z * vertical};
    if (!finite(next)) throw std::invalid_argument("solar pan exceeds finite coordinate range");
    target = next;
}

void SolarCamera::zoom(double logarithmic_delta) {
    validate(*this);
    deltas(logarithmic_delta, 0);
    const double next_log = std::log(distance_au) + std::clamp(logarithmic_delta, -100.0, 100.0);
    if (next_log <= std::log(minimum(*this))) distance_au = minimum(*this);
    else if (next_log >= std::log(maximum_distance)) distance_au = maximum_distance;
    else distance_au = std::exp(next_log);
}

std::optional<SolarProjection> project_solar(Vec3 position, const SolarCamera& camera,
                                            double width, double height) {
    validate(camera);
    dimensions(width, height);
    return project_point(camera_point(position, camera, basis(camera)),
                         near_plane(camera), width, height);
}

std::optional<std::array<SolarProjection, 2>> project_solar_segment(
    Vec3 begin, Vec3 end, const SolarCamera& camera, double width, double height) {
    validate(camera);
    dimensions(width, height);
    const auto axes = basis(camera);
    auto a = camera_point(begin, camera, axes);
    auto b = camera_point(end, camera, axes);
    const double near = near_plane(camera);
    if (!finite(a) || !finite(b) || (a.z < near && b.z < near)) return std::nullopt;
    if (a.z < near || b.z < near) {
        const double span = b.z - a.z;
        if (!std::isfinite(span)) return std::nullopt;
        const double t = (near - a.z) / span;
        const Vec3 clipped{a.x * (1 - t) + b.x * t, a.y * (1 - t) + b.y * t, near};
        if (a.z < near) a = clipped;
        else b = clipped;
    }
    const auto projected_a = project_point(a, near, width, height);
    const auto projected_b = project_point(b, near, width, height);
    if (!projected_a || !projected_b) return std::nullopt;
    return std::array<SolarProjection, 2>{*projected_a, *projected_b};
}

} // namespace mitaka::gui
