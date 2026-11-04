#import "RendererQuality.h"
#import "SmallBodyRenderer.h"
#include <algorithm>
#include <cmath>

namespace mitaka::gui {
namespace {
bool usable(const SmallBodySnapshot& snapshot, const SmallBodyDisplayModel& display, NSRect map) {
    return snapshot.model && display.dataset().get() == &snapshot.model->dataset()
        && snapshot.positions.size() == snapshot.model->dataset().records.size()
        && std::isfinite(map.origin.x) && std::isfinite(map.origin.y)
        && std::isfinite(map.size.width) && std::isfinite(map.size.height)
        && map.size.width > 0 && map.size.height > 0
        && std::isfinite(NSMaxX(map)) && std::isfinite(NSMaxY(map));
}
std::array<CGFloat, 3> color(SmallBodyKind kind) {
    if (kind == SmallBodyKind::comet) return {0.35, 0.93, 0.83};
    if (kind == SmallBodyKind::trans_neptunian) return {0.60, 0.65, 1};
    return {0.82, 0.69, 0.48};
}
}
std::vector<VisibleSmallBody> visible_small_bodies(const SmallBodySnapshot& snapshot,
    const SmallBodyDisplayModel& display, const SolarCamera& camera, NSRect map) {
    std::vector<VisibleSmallBody> visible;
    if (!usable(snapshot, display, map)) return visible;
    for (std::size_t index = 0; index < snapshot.positions.size(); ++index) {
        if (!snapshot.positions[index] || !display.visibility(index).body) continue;
        auto projected = project_solar(*snapshot.positions[index], camera, map.size.width, map.size.height);
        if (!projected) continue;
        projected->x += map.origin.x;
        projected->y += map.origin.y;
        if (NSPointInRect(NSMakePoint(projected->x, projected->y), map)) visible.push_back({index, *projected});
    }
    std::stable_sort(visible.begin(), visible.end(), [](const auto& a, const auto& b) { return a.point.depth > b.point.depth; });
    return visible;
}
std::optional<std::size_t> pick_small_body(const SmallBodySnapshot& snapshot,
    const SmallBodyDisplayModel& display, const SolarCamera& camera, NSRect map, NSPoint point) {
    if (!std::isfinite(point.x) || !std::isfinite(point.y) || !NSPointInRect(point, map)) return {};
    std::optional<std::size_t> selected;
    double nearest = 8;
    for (const auto& body : visible_small_bodies(snapshot, display, camera, map)) {
        const double distance = std::hypot(body.point.x - point.x, body.point.y - point.y);
        // 重なる原本行も統合しない。クリックは手前優先、各行の選択は一覧から可能。
        if (distance <= nearest) { nearest = distance; selected = body.index; }
    }
    return selected;
}
void visit_small_body_orbit_segments(const SmallBodySnapshot& snapshot,
    const SmallBodyDisplayModel& display, const SmallBodyOrbitSnapshot* orbits,
    const SolarCamera& camera, NSRect map,
    const std::function<void(const SmallBodyProjectedOrbitSegment&)>& visitor) {
    if (!visitor || !usable(snapshot, display, map) || !orbits || orbits->cancelled
        || orbits->model != snapshot.model || orbits->paths.size() != snapshot.positions.size()) return;
    for (std::size_t row = 0; row < orbits->paths.size(); ++row) {
        if (!orbits->paths[row] || !display.visibility(row).orbit) continue;
        const auto& path = *orbits->paths[row];
        const auto& id = snapshot.model->dataset().records[row].id;
        if (path.id.source_key != id.source_key || path.id.record_ordinal != id.record_ordinal) continue;
        for (const auto& indices : small_body_orbit_segments(path)) {
            const auto line = project_solar_segment(path.samples[indices[0]].evaluation.state->position_au,
                path.samples[indices[1]].evaluation.state->position_au, camera, map.size.width, map.size.height);
            if (!line) continue;
            auto first = (*line)[0], second = (*line)[1];
            first.x += map.origin.x; first.y += map.origin.y;
            second.x += map.origin.x; second.y += map.origin.y;
            visitor({row, first, second});
        }
    }
}
void draw_small_bodies(CGContextRef context, const SmallBodySnapshot& snapshot,
    const SmallBodyDisplayModel& display, const SmallBodyOrbitSnapshot* orbits,
    const SolarCamera& camera, NSRect map, std::optional<std::size_t> selection,
    const RendererDisplayOptions& quality) {
    if (!context || !usable(snapshot, display, map)) return;
    RendererQualityScope state(context, quality);
    CGContextClipToRect(context, NSRectToCGRect(map));
    {
        RendererQualityScope lines(context, quality, RendererPrimitive::line);
        CGContextSetLineWidth(context, 0.8);
        visit_small_body_orbit_segments(snapshot, display, orbits, camera, map, [&](const auto& segment) {
            const auto rgb = color(snapshot.model->dataset().records[segment.index].kind);
            CGContextSetRGBStrokeColor(context, rgb[0], rgb[1], rgb[2], 0.35);
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, segment.first.x, segment.first.y);
            CGContextAddLineToPoint(context, segment.second.x, segment.second.y);
            CGContextStrokePath(context);
        });
    }
    RendererQualityScope points(context, quality, RendererPrimitive::point);
    for (const auto& body : visible_small_bodies(snapshot, display, camera, map)) {
        const auto kind = snapshot.model->dataset().records[body.index].kind;
        const auto rgb = color(kind);
        const CGFloat alpha = kind == SmallBodyKind::comet ? 0.85 : kind == SmallBodyKind::trans_neptunian ? 0.80 : 0.75;
        CGContextSetRGBFillColor(context, rgb[0], rgb[1], rgb[2], alpha);
        const CGFloat radius = selection == body.index ? 3 : 1.7;
        CGContextFillEllipseInRect(context, CGRectMake(body.point.x-radius, body.point.y-radius, 2*radius, 2*radius));
        if (selection == body.index) {
            RendererQualityScope lines(context, quality, RendererPrimitive::line);
            CGContextSetRGBStrokeColor(context, 1, 0.87, 0.40, 1);
            CGContextSetLineWidth(context, 1.5);
            CGContextStrokeEllipseInRect(context, CGRectMake(body.point.x-7, body.point.y-7, 14, 14));
        }
        if (!display.visibility(body.index).label) continue;
        const auto& title = snapshot.model->title(body.index);
        NSString *name = [[NSString alloc] initWithBytes:title.data() length:title.size() encoding:NSUTF8StringEncoding];
        RendererQualityScope text(context, quality, RendererPrimitive::text);
        [name drawAtPoint:NSMakePoint(body.point.x+10, body.point.y+6) withAttributes:@{
            NSFontAttributeName: [NSFont systemFontOfSize:11], NSForegroundColorAttributeName: NSColor.labelColor}];
    }
}
}
