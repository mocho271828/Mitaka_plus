#pragma once
#import <AppKit/AppKit.h>
#include "constellation_art_model.hpp"
#include "constellation_art_projection.hpp"
#include "constellation_display.hpp"
#include "renderer_options.hpp"

namespace mitaka::gui {
struct ConstellationArtRenderStats {
    std::size_t artworks = 0, segments = 0, omitted_intervals = 0;
};
ConstellationArtRenderStats draw_sky_constellation_art(CGContextRef context,
    const ConstellationArtModel& model, const ConstellationDisplayOptions& options,
    const RendererDisplayOptions& quality, const SkyViewport& viewport, NSRect map);
ConstellationArtRenderStats draw_horizon_constellation_art(CGContextRef context,
    const ConstellationArtModel& model, const ConstellationDisplayOptions& options,
    const RendererDisplayOptions& quality, const ObservationFrame& frame,
    const HorizonViewport& viewport, NSRect map);
}
