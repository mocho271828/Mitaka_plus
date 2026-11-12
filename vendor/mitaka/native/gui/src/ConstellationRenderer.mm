#import "ConstellationRenderer.h"
#import "RendererQuality.h"
#include <functional>

namespace mitaka::gui {
namespace {
NSString *catalogName(const ConstellationRecord& record) {
    for (const auto* bytes : {&record.japanese_hiragana_bytes, &record.english_name, &record.abbreviation}) {
        NSString *name = [[NSString alloc] initWithBytes:bytes->data() length:bytes->size()
            encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese)];
        if (name.length && ![name isEqualToString:@"*"]) return name;
    }
    return @"（名称なし）";
}
using SegmentProjector = std::function<HorizonSegmentProjection(EquatorialCoordinates, EquatorialCoordinates)>;
using PointProjector = std::function<std::optional<ScreenPoint>(EquatorialCoordinates)>;

ConstellationRenderStats draw(CGContextRef context, const SkyModel& model,
    const ConstellationDisplayOptions& options, const RendererDisplayOptions& quality, NSRect map,
    const SegmentProjector& segmentProjector, const PointProjector& pointProjector) {
    ConstellationRenderStats stats;
    if (!options.lines && !options.boundaries && !options.labels) return stats;
    RendererQualityScope clipped(context, quality);
    CGContextClipToRect(context, map);
    const auto segment = [&](EquatorialCoordinates start, EquatorialCoordinates end, std::size_t& count) {
        auto projected = segmentProjector(start, end);
        stats.omitted_intervals += projected.omitted_intervals;
        count += projected.segments.size();
        for (const auto& piece : projected.segments) {
            CGContextMoveToPoint(context, map.origin.x + piece.start.x, map.origin.y + piece.start.y);
            CGContextAddLineToPoint(context, map.origin.x + piece.end.x, map.origin.y + piece.end.y);
        }
    };
    for (const auto& record : model.constellations()) {
        if (options.default_visible == (options.exceptions.count(record.abbreviation) != 0)) continue;
        if (options.lines) {
            RendererQualityScope lines(context, quality, RendererPrimitive::line);
            CGContextSetRGBStrokeColor(context, 0.26, 0.54, 0.77, 0.75);
            CGContextSetLineWidth(context, 0.8);
            for (const auto& line : record.hip_lines) {
                std::optional<EquatorialCoordinates> previous;
                for (const auto hip : line) {
                    const auto index = model.star_index(hip);
                    // 特殊天体 ID・欠落 HIP の両隣を推測で結ばない。
                    if (!index) { previous.reset(); continue; }
                    const auto& star = model.stars()[*index];
                    const EquatorialCoordinates point{star.right_ascension_degrees, star.declination_degrees};
                    if (previous) segment(*previous, point, stats.line_segments);
                    previous = point;
                }
            }
            CGContextStrokePath(context);
        }
        if (options.boundaries && record.boundary.size() > 1) {
            RendererQualityScope lines(context, quality, RendererPrimitive::line);
            CGContextSetRGBStrokeColor(context, 0.52, 0.45, 0.29, 0.7);
            CGContextSetLineWidth(context, 0.6);
            for (std::size_t index = 0; index < record.boundary.size(); ++index) {
                const auto& start = record.boundary[index];
                const auto& end = record.boundary[(index + 1) % record.boundary.size()];
                segment({start.right_ascension_hours * 15, start.declination_degrees},
                    {end.right_ascension_hours * 15, end.declination_degrees}, stats.boundary_segments);
            }
            CGContextStrokePath(context);
        }
        if (options.labels) {
            const auto point = pointProjector({record.right_ascension_degrees, record.declination_degrees});
            if (!point) continue;
            ++stats.labels;
            RendererQualityScope text(context, quality, RendererPrimitive::text);
            [catalogName(record) drawAtPoint:NSMakePoint(map.origin.x + point->x, map.origin.y + point->y)
                withAttributes:@{NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular],
                    NSForegroundColorAttributeName: [NSColor colorWithSRGBRed:0.54 green:0.72 blue:0.88 alpha:0.85]}];
        }
    }
    return stats;
}
}
ConstellationRenderStats draw_sky_constellations(CGContextRef context, const SkyModel& model,
    const ConstellationDisplayOptions& options, const RendererDisplayOptions& quality,
    const SkyViewport& viewport, NSRect map) {
    return draw(context, model, options, quality, map,
        [&](EquatorialCoordinates start, EquatorialCoordinates end) {
            return HorizonSegmentProjection{project_sky_segment(start, end, viewport, map.size.width, map.size.height), 0, 0};
        }, [&](EquatorialCoordinates point) { return project_sky(point, viewport, map.size.width, map.size.height); });
}
ConstellationRenderStats draw_horizon_constellations(CGContextRef context, const SkyModel& model,
    const ConstellationDisplayOptions& options, const RendererDisplayOptions& quality,
    const ObservationFrame& frame, const HorizonViewport& viewport, NSRect map) {
    return draw(context, model, options, quality, map,
        [&](EquatorialCoordinates start, EquatorialCoordinates end) {
            return project_equatorial_segment_to_horizon(start, end, frame, viewport, map.size.width, map.size.height);
        }, [&](EquatorialCoordinates point) {
            const auto horizontal = frame.to_horizontal(point);
            return project_horizon({360 - horizontal.azimuth_deg, horizontal.altitude_deg},
                {360 - viewport.center_azimuth_deg, viewport.center_altitude_deg, viewport.vertical_fov_deg, viewport.perspective_blend, viewport.roll_deg, viewport.perspective_fov_deg}, map.size.width, map.size.height);
        });
}
}
