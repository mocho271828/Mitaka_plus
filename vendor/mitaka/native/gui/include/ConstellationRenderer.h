#pragma once
#import <AppKit/AppKit.h>
#include "constellation_display.hpp"
#include "horizon_segments.hpp"
#include "renderer_options.hpp"

namespace mitaka::gui {
struct ConstellationRenderStats {
    std::size_t line_segments = 0, boundary_segments = 0, labels = 0, omitted_intervals = 0;
};
// 同じ元カタログと表示集合を両投影で使う。未知 HIP の隣同士は結ばない。
ConstellationRenderStats draw_sky_constellations(CGContextRef context, const SkyModel& model,
    const ConstellationDisplayOptions& options, const RendererDisplayOptions& quality,
    const SkyViewport& viewport, NSRect map);
ConstellationRenderStats draw_horizon_constellations(CGContextRef context, const SkyModel& model,
    const ConstellationDisplayOptions& options, const RendererDisplayOptions& quality,
    const ObservationFrame& frame, const HorizonViewport& viewport, NSRect map);
}
