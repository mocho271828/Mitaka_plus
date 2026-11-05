#import "RendererQuality.h"
#import "GridRenderer.h"
#import "SolarSceneRenderer.h"
#include "distance_scales.hpp"
#include "horizon_segments.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
constexpr std::array<GridCoordinateSystem, 4> systems{{GridCoordinateSystem::equatorial,
    GridCoordinateSystem::ecliptic, GridCoordinateSystem::galactic, GridCoordinateSystem::horizontal}};

bool enabled(const GridDisplayOptions& options, GridCoordinateSystem system) {
    switch (system) {
        case GridCoordinateSystem::equatorial: return options.equatorial;
        case GridCoordinateSystem::ecliptic: return options.ecliptic;
        case GridCoordinateSystem::galactic: return options.galactic;
        case GridCoordinateSystem::horizontal: return options.horizontal;
    }
    throw std::invalid_argument("invalid coordinate grid system");
}
NSColor *color(GridCoordinateSystem system) {
    switch (system) {
        case GridCoordinateSystem::equatorial: return [NSColor colorWithSRGBRed:0.45 green:0.66 blue:0.85 alpha:0.65];
        case GridCoordinateSystem::ecliptic: return [NSColor colorWithSRGBRed:0.85 green:0.69 blue:0.35 alpha:0.75];
        case GridCoordinateSystem::galactic: return [NSColor colorWithSRGBRed:0.72 green:0.51 blue:0.81 alpha:0.65];
        case GridCoordinateSystem::horizontal: return [NSColor colorWithSRGBRed:0.43 green:0.76 blue:0.57 alpha:0.65];
    }
    throw std::invalid_argument("invalid coordinate grid system");
}
NSString *name(GridCoordinateSystem system) {
    switch (system) {
        case GridCoordinateSystem::equatorial: return @"赤道";
        case GridCoordinateSystem::ecliptic: return @"黄道";
        case GridCoordinateSystem::galactic: return @"銀河";
        case GridCoordinateSystem::horizontal: return @"地平（観測地点・地球）";
    }
    throw std::invalid_argument("invalid coordinate grid system");
}
void text(NSString *label, NSPoint point, NSColor *ink, const RendererDisplayOptions& quality) {
    RendererQualityScope textQuality(NSGraphicsContext.currentContext.CGContext, quality, RendererPrimitive::text);
    [label drawAtPoint:point withAttributes:@{
        NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:10 weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: ink}];
}
void legend(NSRect map, const GridDisplayOptions& options, const RendererDisplayOptions& quality) {
    CGFloat x = NSMinX(map) + 5;
    for (const auto system : systems) {
        if (!enabled(options, system)) continue;
        text(name(system), NSMakePoint(x, NSMinY(map) + 4), color(system), quality);
        x += system == GridCoordinateSystem::horizontal ? 150 : 36;
    }
}
void solarLine(CGContextRef context, NSRect map, const SolarCamera& camera, Vec3 start, Vec3 end) {
    const auto line = project_solar_segment(start, end, camera, map.size.width, map.size.height);
    if (!line) return;
    const auto a = (*line)[0], b = (*line)[1];
    const double dx = b.x - a.x, dy = b.y - a.y;
    double enter = 0, leave = 1;
    const auto clip = [&](double direction, double distance) {
        if (direction == 0) return distance >= 0;
        const double ratio = distance / direction;
        if (direction < 0) enter = std::max(enter, ratio);
        else leave = std::min(leave, ratio);
        return enter <= leave;
    };
    // near 面付近の投影は巨大になるため、Core Graphics に渡す前にも範囲を切る。
    // CGContext の clip だけでは巨大な座標を含む path 全体が描かれないことがある。
    if (!clip(-dx, a.x) || !clip(dx, map.size.width - a.x)
        || !clip(-dy, a.y) || !clip(dy, map.size.height - a.y)) return;
    CGContextMoveToPoint(context, map.origin.x + a.x + enter * dx, map.origin.y + a.y + enter * dy);
    CGContextAddLineToPoint(context, map.origin.x + a.x + leave * dx, map.origin.y + a.y + leave * dy);
}
void solarText(NSString *label, Vec3 position, const SolarScene& scene, NSColor *ink) {
    const auto point = project_solar(position, scene.camera, scene.map.size.width, scene.map.size.height);
    if (point) text(label, NSMakePoint(scene.map.origin.x + point->x + 3, scene.map.origin.y + point->y + 3), ink, scene.renderer_display);
}
void drawDistanceScales(CGContextRef context, const SolarScene& scene) {
    if (scene.grid_display.circle_scales) {
        for (const auto& scale : circle_distance_scales()) {
            const double opacity = circle_distance_scale_opacity(scene.camera.distance_au, scale.radius_au);
            if (opacity <= 0) continue;
            NSColor *ink = [NSColor colorWithSRGBRed:0.47 green:0.65 blue:0.76 alpha:opacity * 0.65];
            CGContextSetStrokeColorWithColor(context, ink.CGColor);
            Vec3 previous = circle_distance_scale_point(scale, 0);
            for (int angle = 2; angle <= 360; angle += 2) {
                const Vec3 current = circle_distance_scale_point(scale, angle);
                solarLine(context, scene.map, scene.camera, previous, current);
                previous = current;
            }
            CGContextStrokePath(context);
            solarText([NSString stringWithFormat:@"%.4g %@", scale.label_value, scale.galactic_plane ? @"光年" : @"AU"],
                      circle_distance_scale_point(scale, scale.label_angle_deg), scene, ink);
        }
    }
    if (scene.grid_display.square_scales) {
        for (const auto& scale : square_distance_scales(scene.camera)) {
            NSColor *ink = [NSColor colorWithSRGBRed:0.76 green:0.71 blue:0.52 alpha:scale.opacity];
            CGContextSetStrokeColorWithColor(context, ink.CGColor);
            for (std::size_t index = 1; index < scale.vertices.size(); ++index)
                solarLine(context, scene.map, scene.camera, scale.vertices[index - 1], scale.vertices[index]);
            CGContextStrokePath(context);
            solarText([NSString stringWithFormat:@"10^%d m", scale.meter_exponent], scale.vertices[2], scene, ink);
        }
    }
}
} // namespace

namespace mitaka::gui {
GridGeometryCache::GridGeometryCache() = default;
void GridGeometryCache::set_observation(ObserverSite site, double julian_date) {
    if (site.latitude_deg == site_.latitude_deg && site.longitude_deg == site_.longitude_deg && julian_date == julian_date_) return;
    const ObservationFrame frame(site, julian_date);
    site_ = site;
    julian_date_ = julian_date;
    frame_ = frame;
    horizontal_.reset();
}
const CoordinateGrid& GridGeometryCache::grid(GridCoordinateSystem system) const {
    if (system == GridCoordinateSystem::horizontal) {
        if (!horizontal_) horizontal_ = make_coordinate_grid(system, frame_);
        return *horizontal_;
    }
    static const std::array<CoordinateGrid, 3> fixed{{
        make_coordinate_grid(GridCoordinateSystem::equatorial, frame_),
        make_coordinate_grid(GridCoordinateSystem::ecliptic, frame_),
        make_coordinate_grid(GridCoordinateSystem::galactic, frame_)}};
    const auto index = static_cast<std::size_t>(system);
    if (index >= fixed.size()) throw std::invalid_argument("invalid coordinate grid system");
    return fixed[index];
}

void draw_sky_grids(CGContextRef context, NSRect map, SkyViewport viewport,
                    const GridDisplayOptions& options, const GridGeometryCache& cache, bool horizontal_projection,
                    const RendererDisplayOptions& quality) {
    if (map.size.width <= 0 || map.size.height <= 0) return;
    RendererQualityScope lines(context, quality, RendererPrimitive::line);
    CGContextClipToRect(context, map);
    CGContextSetLineWidth(context, 0.6);
    for (const auto system : systems) {
        if (!enabled(options, system)) continue;
        CGContextSetStrokeColorWithColor(context, color(system).CGColor);
        for (const auto& line : cache.grid(system)) {
            auto previous = line.front();
            for (std::size_t index = 1; index < line.size(); ++index) {
                const auto current = line[index];
                auto start = previous, end = current;
                // 天球図の極では赤経が未定義なので、隣接点の値を引き継ぐ。
                // 地平図は適応分割器が回転後の極を処理する。
                if (std::abs(std::abs(start.declination_deg) - 90) < 1e-8)
                    start.right_ascension_deg = end.right_ascension_deg;
                if (std::abs(std::abs(end.declination_deg) - 90) < 1e-8)
                    end.right_ascension_deg = start.right_ascension_deg;
                const auto segments = horizontal_projection
                    ? project_equatorial_segment_to_horizon(line[index - 1], line[index], cache.frame(),
                        {360 - viewport.center_ra_deg, viewport.center_dec_deg, viewport.zoom, viewport.perspective_blend},
                        map.size.width, map.size.height).segments
                    : project_sky_segment(start, end, viewport, map.size.width, map.size.height);
                for (const auto& segment : segments) {
                    CGContextMoveToPoint(context, map.origin.x + segment.start.x, map.origin.y + segment.start.y);
                    CGContextAddLineToPoint(context, map.origin.x + segment.end.x, map.origin.y + segment.end.y);
                }
                previous = current;
            }
        }
        CGContextStrokePath(context);
    }
    // 投影軸の読み取り値は、その座標格子を表示している場合だけ添える。
    if (horizontal_projection ? options.horizontal : options.equatorial) {
        for (int latitude = -75; latitude <= 75; latitude += 15) {
            const EquatorialCoordinates coordinate{viewport.center_ra_deg, static_cast<double>(latitude)};
            const auto point = horizontal_projection
                ? project_horizon(coordinate, viewport, map.size.width, map.size.height)
                : project_sky(coordinate, viewport, map.size.width, map.size.height);
            if (point) text([NSString stringWithFormat:@"%+d°", latitude], NSMakePoint(horizontal_projection ? NSMinX(map) + point->x + 3 : NSMinX(map) + 3, NSMinY(map) + point->y + 1), NSColor.secondaryLabelColor, quality);
        }
        for (int longitude = 0; longitude < 360; longitude += horizontal_projection ? 45 : 30) {
            const EquatorialCoordinates coordinate{static_cast<double>(horizontal_projection ? 360 - longitude : longitude), horizontal_projection ? 0.0 : viewport.center_dec_deg};
            const auto point = horizontal_projection
                ? project_horizon(coordinate, viewport, map.size.width, map.size.height)
                : project_sky(coordinate, viewport, map.size.width, map.size.height);
            if (!point) continue;
            NSString *label = horizontal_projection ? [NSString stringWithFormat:@"%@ %d°", @[@"北", @"北東", @"東", @"南東", @"南", @"南西", @"西", @"北西"][longitude / 45], longitude]
                                                   : [NSString stringWithFormat:@"%dh", longitude / 15];
            text(label, NSMakePoint(NSMinX(map) + point->x + 2, horizontal_projection ? NSMinY(map) + point->y + 2 : NSMaxY(map) - 15), NSColor.secondaryLabelColor, quality);
        }
    }
    legend(map, options, quality);
}
} // namespace mitaka::gui

void draw_solar_grid(CGContextRef context, const SolarScene& scene) {
    if (scene.map.size.width <= 0 || scene.map.size.height <= 0) return;
    static const GridGeometryCache fallback;
    const auto& cache = scene.grid_cache ? *scene.grid_cache : fallback;
    RendererQualityScope lines(context, scene.renderer_display, RendererPrimitive::line);
    CGContextClipToRect(context, scene.map);
    CGContextSetLineWidth(context, 0.6);
    // 単位球をカメラ位置へ置くことで距離や注視点から独立した方向格子にする。
    SolarCamera directional;
    directional.distance_au = 1;
    directional.frame = solar_camera_basis(scene.camera);
    const auto directionPoint = [&](EquatorialCoordinates point) {
        const auto direction = j2000_equatorial_to_ecliptic(equatorial_direction(point));
        const auto eye = directional.frame->outward;
        return Vec3{eye.x + direction.x, eye.y + direction.y, eye.z + direction.z};
    };
    for (const auto system : systems) {
        if (system == GridCoordinateSystem::ecliptic || !enabled(scene.grid_display, system)) continue;
        CGContextSetStrokeColorWithColor(context, color(system).CGColor);
        for (const auto& line : cache.grid(system))
            for (std::size_t index = 1; index < line.size(); ++index)
                solarLine(context, scene.map, directional, directionPoint(line[index - 1]), directionPoint(line[index]));
        CGContextStrokePath(context);
    }
    if (scene.grid_display.ecliptic) {
        CGContextSetStrokeColorWithColor(context, color(GridCoordinateSystem::ecliptic).CGColor);
        const std::array<Vec3, 5> boundary{{{-100, -100, 0}, {100, -100, 0}, {100, 100, 0}, {-100, 100, 0}, {-100, -100, 0}}};
        for (std::size_t index = 1; index < boundary.size(); ++index)
            solarLine(context, scene.map, scene.camera, boundary[index - 1], boundary[index]);
        solarLine(context, scene.map, scene.camera, {-100, 0, 0}, {100, 0, 0});
        solarLine(context, scene.map, scene.camera, {0, -100, 0}, {0, 100, 0});
        CGContextStrokePath(context);
    }
    drawDistanceScales(context, scene);
    legend(scene.map, scene.grid_display, scene.renderer_display);
}
