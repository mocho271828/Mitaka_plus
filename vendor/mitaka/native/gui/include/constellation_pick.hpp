#pragma once

#include "constellation_display.hpp"
#include "horizon_segments.hpp"
#include <functional>
#include <optional>

namespace mitaka::gui {

struct ConstellationHit {
    std::size_t record_index;
    ScreenPoint point;
    double distance;
};

using ConstellationStarLookup = std::function<std::optional<EquatorialCoordinates>(std::int32_t)>;
using ConstellationPointVisible = std::function<bool(ScreenPoint)>;

// 描画と同じ分割・clip 済みの線だけが候補。point は map 左上基準。
// visibility は描画後に重なる不透明面を判定し、closest point に対して呼ぶ。
std::optional<ConstellationHit> pick_horizon_constellation(
    const std::vector<ConstellationRecord>& records, const ConstellationStarLookup& star,
    const ConstellationDisplayOptions& options, const ObservationFrame& frame,
    const HorizonViewport& viewport, double width, double height, ScreenPoint point,
    double tolerance, const ConstellationPointVisible& visible);
}
