#pragma once

#include "solar_camera.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {

// Camera.setOrient/getOrient の x, y, z, w の並び。
struct PlusOrientationQuaternion {
    double x, y, z, w;
};

struct PlusOrientationEuler {
    double heading, pitch, roll;
};

inline PlusOrientationQuaternion plus_orientation_normalized(PlusOrientationQuaternion q) {
    const double length = std::hypot(std::hypot(q.x, q.y), std::hypot(q.z, q.w));
    if (!std::isfinite(length) || length == 0)
        throw std::invalid_argument("camera orientation must be a finite nonzero quaternion");
    return {q.x / length, q.y / length, q.z / length, q.w / length};
}

// Hamilton 積。addEuler は現在の姿勢に増分を右から掛ける。
inline PlusOrientationQuaternion plus_orientation_multiply(PlusOrientationQuaternion a,
                                                             PlusOrientationQuaternion b) {
    return {a.w*b.x + a.x*b.w + a.y*b.z - a.z*b.y,
            a.w*b.y - a.x*b.z + a.y*b.w + a.z*b.x,
            a.w*b.z + a.x*b.y - a.y*b.x + a.z*b.w,
            a.w*b.w - a.x*b.x - a.y*b.y - a.z*b.z};
}

// Euler の回転順は qY(-heading) * qX(pitch) * qZ(roll)。
inline PlusOrientationQuaternion plus_orientation_from_euler(double heading, double pitch, double roll) {
    if (!std::isfinite(heading) || !std::isfinite(pitch) || !std::isfinite(roll))
        throw std::invalid_argument("camera Euler angles must be finite");
    constexpr double half_radians_per_degree = 3.14159265358979323846 / 360;
    // quaternion 自体は 720 度周期なので、360 度回転時の符号も保持する。
    const double h = -std::remainder(heading, 720) * half_radians_per_degree;
    const double p = std::remainder(pitch, 720) * half_radians_per_degree;
    const double r = std::remainder(roll, 720) * half_radians_per_degree;
    const PlusOrientationQuaternion qh{0, std::sin(h), 0, std::cos(h)};
    const PlusOrientationQuaternion qp{std::sin(p), 0, 0, std::cos(p)};
    const PlusOrientationQuaternion qr{0, 0, std::sin(r), std::cos(r)};
    return plus_orientation_normalized(plus_orientation_multiply(plus_orientation_multiply(qh, qp), qr));
}

// setEulerTo は quaternion ではなく、Euler 各成分を補間する。
inline double plus_orientation_easing(double fraction, bool smooth) {
    if (!std::isfinite(fraction)) throw std::invalid_argument("camera animation fraction must be finite");
    const double t = std::clamp(fraction, 0.0, 1.0);
    return smooth ? (1 - std::cos(3.14159265358979323846 * t)) / 2 : t;
}

inline PlusOrientationEuler plus_orientation_interpolate_euler(PlusOrientationEuler from,
                                                               PlusOrientationEuler to,
                                                               double fraction, bool smooth) {
    const double t = plus_orientation_easing(fraction, smooth);
    return {from.heading + (to.heading - from.heading) * t,
            from.pitch + (to.pitch - from.pitch) * t,
            from.roll + (to.roll - from.roll) * t};
}

// 同じ姿勢を表す quaternion の符号を揃え、短い経路を補間する。
inline PlusOrientationQuaternion plus_orientation_interpolate(PlusOrientationQuaternion from,
                                                              PlusOrientationQuaternion to,
                                                              double fraction, bool smooth) {
    from = plus_orientation_normalized(from);
    to = plus_orientation_normalized(to);
    const double t = plus_orientation_easing(fraction, smooth);
    double dot = from.x*to.x + from.y*to.y + from.z*to.z + from.w*to.w;
    if (dot < 0) {
        to = {-to.x, -to.y, -to.z, -to.w};
        dot = -dot;
    }
    dot = std::clamp(dot, 0.0, 1.0);
    double a = 1 - t, b = t;
    if (1 - dot > 1e-5) {
        const double angle = std::acos(dot);
        const double scale = std::sin(angle);
        a = std::sin((1 - t) * angle) / scale;
        b = std::sin(t * angle) / scale;
    }
    // 正規化は補間結果をカメラへ適用するときに行う。
    return {a*from.x + b*to.x, a*from.y + b*to.y,
            a*from.z + b*to.z, a*from.w + b*to.w};
}

// setEuler の回転行列から Euler を復元し、極点では heading をゼロにする。
inline PlusOrientationEuler plus_orientation_to_euler(PlusOrientationQuaternion orientation) {
    const auto normalized = plus_orientation_normalized(orientation);
    const double x = normalized.x, y = normalized.y, z = normalized.z, w = normalized.w;
    const double scale = 2 / (x*x + y*y + z*z + w*w);
    const double r02 = scale*(x*z + w*y), r22 = 1 - scale*(x*x + y*y);
    const double horizontal = std::hypot(r02, r22);
    const double pitch = std::atan2(scale*(w*x - y*z), horizontal);
    constexpr double degrees_per_radian = 180 / 3.14159265358979323846;
    if (horizontal <= 1e-12) {
        const double r01 = scale*(x*y - w*z), r00 = 1 - scale*(y*y + z*z);
        return {0, pitch * degrees_per_radian, -std::atan2(r01, r00) * degrees_per_radian};
    }
    return {-std::atan2(r02, r22) * degrees_per_radian,
            pitch * degrees_per_radian,
            std::atan2(scale*(x*y + w*z), 1 - scale*(x*x + z*z)) * degrees_per_radian};
}

// 単位 quaternion で基準の右・上・視線を回す。
inline SolarCameraBasis plus_orientation_basis(PlusOrientationQuaternion orientation) {
    const auto q = plus_orientation_normalized(orientation);
    const auto x = q.x, y = q.y, z = q.z, w = q.w;
    return {{2*(x*z + w*y), 2*(y*z - w*x), 1 - 2*(x*x + y*y)},
            {1 - 2*(y*y + z*z), 2*(x*y + w*z), 2*(x*z - w*y)},
            {2*(x*y - w*z), 1 - 2*(x*x + z*z), 2*(y*z + w*x)}};
}

// 基底は solar_camera_basis など、検証済みの右手正規直交基底を渡す。
inline PlusOrientationQuaternion plus_orientation_from_basis(const SolarCameraBasis& basis) {
    const auto& x = basis.right;
    const auto& y = basis.up;
    const auto& z = basis.outward;
    const double trace = x.x + y.y + z.z;
    PlusOrientationQuaternion q{};
    if (trace > 0) {
        const double s = 2 * std::sqrt(trace + 1);
        q = {(y.z - z.y) / s, (z.x - x.z) / s, (x.y - y.x) / s, s / 4};
    } else if (x.x > y.y && x.x > z.z) {
        const double s = 2 * std::sqrt(1 + x.x - y.y - z.z);
        q = {s / 4, (y.x + x.y) / s, (z.x + x.z) / s, (y.z - z.y) / s};
    } else if (y.y > z.z) {
        const double s = 2 * std::sqrt(1 + y.y - x.x - z.z);
        q = {(y.x + x.y) / s, s / 4, (z.y + y.z) / s, (z.x - x.z) / s};
    } else {
        const double s = 2 * std::sqrt(1 + z.z - x.x - y.y);
        q = {(z.x + x.z) / s, (z.y + y.z) / s, s / 4, (x.y - y.x) / s};
    }
    return plus_orientation_normalized(q);
}

} // namespace mitaka::gui
