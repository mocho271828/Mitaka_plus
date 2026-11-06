#pragma once

#include "horizon_segments.hpp"
#include "horizon_projection_constants.hpp"
#include <algorithm>
#include <array>
#include <cmath>

namespace mitaka::gui {

enum class HorizonMorphDecision { accepted, outside, subdivide };

// 可視点の矩形の対角線を、射影の導関数の下限から評価する。
// 真なら小区間を省略してよいが、隣接した省略区間の合計長は制限しない。
// 極や経度の継ぎ目を含む場合は推定せず、通常の細分化へ戻す。
inline bool horizon_morph_subpixel(const std::array<EquatorialCoordinates, 5>& points,
    const HorizonProjectionViewport& viewport, double width, double height, double source_span,
    double screen_tolerance) {
    constexpr double radians = 3.14159265358979323846 / 180;
    constexpr double max_extent_px = 0.25;
    if (!std::isfinite(source_span) || source_span < 0) return false;
    // 端点間の距離上限から任意の二点間の距離を囲み、座標変換の丸めに余裕を持たせる。
    const double angular_distance = 2 * (source_span + 1e-12) * radians;
    const double latitude = std::abs(points[2].declination_deg) * radians;
    if (latitude + angular_distance >= 90 * radians) return false;
    const double longitude = std::abs(std::remainder(points[2].right_ascension_deg, 360.0)) * radians;
    const double longitude_distance = angular_distance / std::cos(latitude + angular_distance);
    if (longitude + longitude_distance >= 180 * radians) return false;

    const double blend = viewport.perspective_blend;
    const double scale = horizon_perspective_scale;
    const double aspect_scale = scale * width / height;
    const double fov = std::max(viewport.vertical_fov_deg, horizon_minimum_render_fov_deg) * radians;
    // u, v が [-1, 1] の画面内での経度・緯度の導関数の下限。
    const double longitude_slope = (1 - blend) * fov
        + blend * aspect_scale / (1 + aspect_scale * aspect_scale);
    const double denominator = std::hypot(1.0, aspect_scale);
    const double latitude_slope = (1 - blend) * fov / 2
        + blend * scale * denominator / (denominator * denominator + scale * scale);
    const double screen_x_distance = longitude_distance / longitude_slope;
    const double x_extent = width * screen_x_distance / 2;
    const double y_extent = height * (angular_distance + blend * scale * aspect_scale * aspect_scale * screen_x_distance)
        / (2 * latitude_slope);
    return std::hypot(x_extent, y_extent) < std::min(max_extent_px, screen_tolerance);
}

inline bool horizon_interval_small(double source_span, const HorizonProjectionViewport& viewport, double width, double height) {
    // 狭視野では回転後の可視領域が極から離れるため、球面上の移動量から
    // 射影後の移動量を保守的に抑えられる。広視野では経度が極付近で
    // 急変するので角度だけによる打ち切りを行わない。
    if (viewport.vertical_fov_deg > 1) return false;
    return source_span <= std::max(viewport.vertical_fov_deg, 1e-9) / (8 * std::max(width, height));
}

// 元区間の各座標の変化量は source_span 以下なので、球面上の移動距離は
// その 2 倍以下。星座絵の大円弧も同じ上限に含まれる。
inline bool horizon_interval_outside(const std::array<EquatorialCoordinates, 5>& points,
    const HorizonProjectionViewport& viewport, double width, double height, double source_span) {
    if (!std::isfinite(source_span) || source_span < 0) return false;
    const HorizonProjectionViewport centered{0, 0, viewport.vertical_fov_deg, viewport.perspective_blend};
    const auto left = unproject_horizon({0, height / 2}, centered, width, height);
    const auto top = unproject_horizon({width / 2, 0}, centered, width, height);
    // 視野内のどの点も経度幅と高度幅の和以内にある。
    const double radius = std::abs(std::remainder(left.right_ascension_deg, 360.0))
        + std::abs(top.declination_deg);
    constexpr double radians = 3.14159265358979323846 / 180;
    const double longitude = std::remainder(points.front().right_ascension_deg, 360.0) * radians;
    const double latitude = points.front().declination_deg * radians;
    const double distance = std::atan2(std::hypot(std::cos(latitude) * std::sin(longitude), std::sin(latitude)),
                                       std::cos(latitude) * std::cos(longitude)) / radians;
    const double longitude_excess = std::max(0.0, std::abs(longitude)
        - std::abs(std::remainder(left.right_ascension_deg, 360.0)) * radians);
    const double longitude_distance = std::asin(std::clamp(std::cos(latitude)
        * std::sin(std::min(longitude_excess, 90 * radians)), 0.0, 1.0)) / radians;
    const double latitude_distance = std::max(0.0, std::abs(points.front().declination_deg)
        - std::abs(top.declination_deg));
    const double uncertainty = 2 * source_span + 1e-12;
    return distance > radius + uncertainty || longitude_distance > uncertainty || latitude_distance > uncertainty;
}

// 共通投影は非線形なので、画面座標の中間点誤差から描画線分を決める。
inline HorizonMorphDecision project_morph_interval(
    const std::array<EquatorialCoordinates, 5>& points, const HorizonProjectionViewport& viewport,
    double width, double height, double source_span, const HorizonSamplingLimits& limits,
    HorizonSegmentProjection& result) {
    if (source_span > limits.max_source_step_deg) return HorizonMorphDecision::subdivide;
    std::array<std::optional<ScreenPoint>, 5> projected;
    std::size_t visible = 0;
    const HorizonProjectionViewport centered{0, 0, viewport.vertical_fov_deg, viewport.perspective_blend};
    for (std::size_t i = 0; i < points.size(); ++i) {
        projected[i] = project_horizon(points[i], centered, width, height);
        visible += projected[i].has_value();
    }
    if (visible == 0) return horizon_interval_outside(points, viewport, width, height, source_span)
        ? HorizonMorphDecision::outside : HorizonMorphDecision::subdivide;
    if (visible != points.size()) return HorizonMorphDecision::subdivide;
    for (std::size_t i = 1; i < points.size(); ++i) {
        // 投影の経度継ぎ目を跨ぐ線分で画面全体を結ばない。
        if (std::abs(projected[i]->x - projected[i - 1]->x) > width / 2)
            return HorizonMorphDecision::subdivide;
    }
    for (std::size_t i = 1; i < 4; ++i) {
        const double t = static_cast<double>(i) / 4;
        const double x = (1 - t) * projected.front()->x + t * projected.back()->x;
        const double y = (1 - t) * projected.front()->y + t * projected.back()->y;
        if (std::hypot(projected[i]->x - x, projected[i]->y - y) > limits.screen_tolerance)
            return HorizonMorphDecision::subdivide;
    }
    result.segments.push_back({*projected.front(), *projected.back()});
    return HorizonMorphDecision::accepted;
}

} // namespace mitaka::gui
