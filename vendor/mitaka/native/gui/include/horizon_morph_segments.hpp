#pragma once

#include "horizon_segments.hpp"
#include <array>
#include <cmath>

namespace mitaka::gui {

enum class HorizonMorphDecision { accepted, outside, subdivide };

// 共通投影は非線形なので、画面座標の中間点誤差から描画線分を決める。
inline HorizonMorphDecision project_morph_interval(
    const std::array<EquatorialCoordinates, 5>& points, const SkyViewport& viewport,
    double width, double height, double source_span, const HorizonSamplingLimits& limits,
    HorizonSegmentProjection& result) {
    if (source_span > limits.max_source_step_deg) return HorizonMorphDecision::subdivide;
    std::array<std::optional<ScreenPoint>, 5> projected;
    std::size_t visible = 0;
    const SkyViewport centered{0, 0, viewport.zoom, viewport.perspective_blend};
    for (std::size_t i = 0; i < points.size(); ++i) {
        projected[i] = project_horizon(points[i], centered, width, height);
        visible += projected[i].has_value();
    }
    if (visible == 0) return HorizonMorphDecision::outside;
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
