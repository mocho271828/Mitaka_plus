#import "RendererQuality.h"
#import "SatelliteRenderer.h"
#include <algorithm>
#include <cmath>

namespace mitaka::gui {
namespace {
bool usable(const SatelliteSnapshot& snapshot, const SatelliteDisplayModel* display, NSRect map) {
    return snapshot.model && std::isfinite(snapshot.julian_date)
        && snapshot.positions.size() == snapshot.model->model().records().size()
        && (!display || display->model().get() == &snapshot.model->model())
        && std::isfinite(map.origin.x) && std::isfinite(map.origin.y)
        && std::isfinite(map.size.width) && std::isfinite(map.size.height)
        && map.size.width > 0 && map.size.height > 0
        && std::isfinite(NSMaxX(map)) && std::isfinite(NSMaxY(map));
}
}
std::vector<VisibleSatellite> visible_satellites(const SatelliteSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, const SatelliteDisplayModel* display) {
    std::vector<VisibleSatellite> visible;
    if (!usable(snapshot, display, map)) return visible;
    for (std::size_t index = 0; index < snapshot.positions.size(); ++index) {
        if (!snapshot.positions[index] || (display && !display->visibility(index).body)) continue;
        // コアの絶対日心 J2000 黄道 AU をそのまま投影し、親惑星の加算や重心補正を重ねない。
        auto projected = project_solar(*snapshot.positions[index], camera, map.size.width, map.size.height);
        if (!projected) continue;
        projected->x += map.origin.x;
        projected->y += map.origin.y;
        if (NSPointInRect(NSMakePoint(projected->x, projected->y), map)) visible.push_back({index, *projected});
    }
    std::stable_sort(visible.begin(), visible.end(), [](const auto& a, const auto& b) { return a.point.depth > b.point.depth; });
    return visible;
}
std::optional<std::size_t> pick_satellite(const SatelliteSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, NSPoint point, const SatelliteDisplayModel* display) {
    if (!std::isfinite(point.x) || !std::isfinite(point.y) || !NSPointInRect(point, map)) return {};
    std::optional<std::size_t> selected;
    double nearest = 8;
    for (const auto& satellite : visible_satellites(snapshot, camera, map, display)) {
        const double distance = std::hypot(satellite.point.x - point.x, satellite.point.y - point.y);
        // 重複行を統合しない。クリックは手前優先とし、重なる全行は一覧から選べる。
        if (distance <= nearest) { nearest = distance; selected = satellite.index; }
    }
    return selected;
}
void draw_satellites(CGContextRef context, const SatelliteSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, std::optional<std::size_t> selection,
    const RendererDisplayOptions& quality, const SatelliteDisplayModel* display,
    const SatelliteOrbitGeometry* orbits) {
    if (!context || !usable(snapshot, display, map)) return;
    if (orbits && orbits->snapshot.get() == &snapshot && orbits->rows.size() == snapshot.positions.size()) {
        RendererQualityScope lines(context, quality, RendererPrimitive::line);
        CGContextClipToRect(context, NSRectToCGRect(map));
        CGContextSetRGBStrokeColor(context, 0.38, 0.64, 0.83, 0.6);
        CGContextSetLineWidth(context, 0.8);
        for (std::size_t row = 0; row < orbits->rows.size(); ++row) {
            if (display && !display->visibility(row).orbit) continue;
            bool connected = false;
            CGContextBeginPath(context);
            for (const auto& point : orbits->rows[row].points_au) {
                const auto projection = project_solar(point, camera, map.size.width, map.size.height);
                if (!projection) { connected = false; continue; }
                const double x = projection->x + map.origin.x, y = projection->y + map.origin.y;
                if (connected) CGContextAddLineToPoint(context,x,y); else CGContextMoveToPoint(context,x,y);
                connected = true;
            }
            CGContextStrokePath(context);
        }
    }
    RendererQualityScope points(context, quality, RendererPrimitive::point);
    for (const auto& satellite : visible_satellites(snapshot, camera, map, display)) {
        CGContextSetRGBFillColor(context, 0.64, 0.84, 0.98, 0.85);
        const CGFloat radius = selection == satellite.index ? 3 : 1.7;
        CGContextFillEllipseInRect(context, CGRectMake(satellite.point.x-radius, satellite.point.y-radius, 2*radius, 2*radius));
        if (selection == satellite.index) {
            RendererQualityScope lines(context, quality, RendererPrimitive::line);
            CGContextSetRGBStrokeColor(context, 1, 0.87, 0.40, 1);
            CGContextSetLineWidth(context, 1.5);
            CGContextStrokeEllipseInRect(context, CGRectMake(satellite.point.x-7, satellite.point.y-7, 14, 14));
        }
        if (display ? !display->visibility(satellite.index).label : selection != satellite.index) continue;
        const auto& title = snapshot.model->title(satellite.index);
        NSString *name = [[NSString alloc] initWithBytes:title.data() length:title.size() encoding:NSUTF8StringEncoding];
        RendererQualityScope text(context, quality, RendererPrimitive::text);
        [name drawAtPoint:NSMakePoint(satellite.point.x+10, satellite.point.y+6) withAttributes:@{
            NSFontAttributeName: [NSFont systemFontOfSize:11], NSForegroundColorAttributeName: NSColor.labelColor}];
    }
}
}
