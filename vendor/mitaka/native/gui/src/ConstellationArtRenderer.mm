#import "ConstellationArtRenderer.h"
#import "RendererQuality.h"
#include <functional>

namespace mitaka::gui {
namespace {
using Projector = std::function<HorizonSegmentProjection(Vec3, Vec3)>;
ConstellationArtRenderStats draw(CGContextRef context, const ConstellationArtModel& model,
    const ConstellationDisplayOptions& options, const RendererDisplayOptions& quality,
    NSRect map, const Projector& project) {
    ConstellationArtRenderStats stats;
    if (!context || !options.illustrations) return stats;
    RendererQualityScope lines(context, quality, RendererPrimitive::line);
    CGContextClipToRect(context, map);
    CGContextSetRGBStrokeColor(context, .50, .61, .76, .65);
    CGContextSetLineWidth(context, .7);
    for (const auto& record : model.records()) {
        if (!record.abbreviation || options.default_visible == (options.exceptions.count(*record.abbreviation) != 0)) continue;
        ++stats.artworks;
        std::optional<std::int32_t> previous;
        for (const auto index : record.art.indices) {
            // 負値は原版の線分終端。未参照点、重複点、末尾を補正しない。
            if (index < 0) { previous.reset(); continue; }
            if (previous) {
                HorizonSegmentProjection projected;
                try { projected = project(record.directions.at(*previous), record.directions.at(index)); }
                catch (const std::invalid_argument&) { ++stats.omitted_intervals; previous = index; continue; }
                stats.omitted_intervals += projected.omitted_intervals;
                stats.segments += projected.segments.size();
                for (const auto& segment : projected.segments) {
                    CGContextMoveToPoint(context, map.origin.x + segment.start.x, map.origin.y + segment.start.y);
                    CGContextAddLineToPoint(context, map.origin.x + segment.end.x, map.origin.y + segment.end.y);
                }
            }
            previous = index;
        }
    }
    CGContextStrokePath(context);
    return stats;
}
}
ConstellationArtRenderStats draw_sky_constellation_art(CGContextRef context,
    const ConstellationArtModel& model, const ConstellationDisplayOptions& options,
    const RendererDisplayOptions& quality, const SkyViewport& viewport, NSRect map) {
    return draw(context, model, options, quality, map, [&](Vec3 start, Vec3 end) {
        return project_sky_constellation_art_segment(start, end, viewport, map.size.width, map.size.height);
    });
}
ConstellationArtRenderStats draw_horizon_constellation_art(CGContextRef context,
    const ConstellationArtModel& model, const ConstellationDisplayOptions& options,
    const RendererDisplayOptions& quality, const ObservationFrame& frame,
    const HorizonViewport& viewport, NSRect map) {
    return draw(context, model, options, quality, map, [&](Vec3 start, Vec3 end) {
        return project_horizon_constellation_art_segment(start, end, frame, viewport, map.size.width, map.size.height);
    });
}
}
