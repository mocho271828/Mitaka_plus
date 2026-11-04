#import "SpacecraftRenderer.h"
#import "RendererQuality.h"

#include <algorithm>
#include <cmath>

namespace mitaka::gui {
namespace {
bool finite(Vec3 position) {
    return std::isfinite(position.x) && std::isfinite(position.y) && std::isfinite(position.z);
}
bool usable_map(NSRect map) {
    return std::isfinite(map.origin.x) && std::isfinite(map.origin.y)
        && std::isfinite(map.size.width) && std::isfinite(map.size.height)
        && map.size.width > 0 && map.size.height > 0
        && std::isfinite(NSMaxX(map)) && std::isfinite(NSMaxY(map));
}

const SpacecraftTrajectoryRecord* confirmed_trajectory(const SpacecraftSnapshot& snapshot, std::size_t index) {
    if (!snapshot.model || !std::isfinite(snapshot.julian_date)
        || index >= snapshot.positions.size() || index >= snapshot.evaluations.size()
        || !snapshot.positions[index] || !snapshot.evaluations[index]) return nullptr;
    const auto& data = snapshot.model->model().dataset();
    if (index >= data.definitions.size()) return nullptr;
    const auto reference = data.definitions[index].trajectory_index;
    if (!reference || *reference >= data.trajectories.size()) return nullptr;
    const auto& trajectory = data.trajectories[*reference];
    if (trajectory.source_index >= data.sources.size() || trajectory.ppi) return nullptr;
    const auto& source = data.sources[trajectory.source_index];
    const auto& evaluation = *snapshot.evaluations[index];
    // 同じ日時・参照先の位置 snapshot だけを使い、PPI の数値を推定空間へ持ち込まない。
    if (source.kind != SpacecraftSourceKind::pth_samples || !source.parsed || !source.valid
        || evaluation.contract != spacecraft_pth_position_contract
        || evaluation.legacy_julian_date != snapshot.julian_date
        || evaluation.trajectory_index != *reference || evaluation.source_index != trajectory.source_index
        || !evaluation.heliocentric_j2000_ecliptic_au) return nullptr;
    const auto a = *snapshot.positions[index], b = *evaluation.heliocentric_j2000_ecliptic_au;
    if (!finite(a) || !finite(b) || a.x != b.x || a.y != b.y || a.z != b.z) return nullptr;
    return &trajectory;
}

std::optional<SolarProjection> project(Vec3 position, const SolarCamera& camera, NSRect map) {
    if (!finite(position)) return {};
    auto point = project_solar(position, camera, map.size.width, map.size.height);
    if (point) {
        point->x += map.origin.x;
        point->y += map.origin.y;
        if (!std::isfinite(point->x) || !std::isfinite(point->y)) return {};
    }
    return point;
}
} // namespace

std::optional<Vec3> spacecraft_scene_position(const SpacecraftSnapshot& snapshot, std::size_t index) {
    return confirmed_trajectory(snapshot, index) ? snapshot.positions[index] : std::nullopt;
}

std::vector<VisibleSpacecraft> visible_spacecraft(const SpacecraftSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, const SpacecraftDisplayOptions& options) {
    std::vector<VisibleSpacecraft> visible;
    if ((!options.points && !options.labels) || !usable_map(map) || !snapshot.model) return visible;
    for (std::size_t index = 0; index < snapshot.model->model().dataset().definitions.size(); ++index) {
        const auto position = spacecraft_scene_position(snapshot, index);
        if (!position) continue;
        const auto point = project(*position, camera, map);
        if (point && NSPointInRect(NSMakePoint(point->x, point->y), map)) visible.push_back({index, *point});
    }
    std::stable_sort(visible.begin(), visible.end(), [](const auto& a, const auto& b) { return a.point.depth > b.point.depth; });
    return visible;
}

std::optional<std::size_t> pick_spacecraft(const SpacecraftSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, NSPoint point, const SpacecraftDisplayOptions& options) {
    if (!options.points || !usable_map(map) || !std::isfinite(point.x) || !std::isfinite(point.y)
        || !NSPointInRect(point, map)) return {};
    std::optional<std::size_t> selection;
    double nearest = 8;
    for (const auto& probe : visible_spacecraft(snapshot, camera, map, options)) {
        const double distance = std::hypot(probe.point.x - point.x, probe.point.y - point.y);
        // 同位置・同名を統合せず、画面で重なるものは手前優先、同じ深度は後の原行。
        if (distance <= nearest) { nearest = distance; selection = probe.index; }
    }
    return selection;
}

void visit_spacecraft_path_segments(const SpacecraftSnapshot& snapshot, const SolarCamera& camera,
    NSRect map, const SpacecraftDisplayOptions& options,
    const std::function<void(const SpacecraftPathSegment&)>& visitor) {
    if (!options.orbits || !visitor || !usable_map(map) || !snapshot.model) return;
    for (std::size_t index = 0; index < snapshot.model->model().dataset().definitions.size(); ++index) {
        const auto* trajectory = confirmed_trajectory(snapshot, index);
        if (!trajectory) continue;
        std::optional<SolarProjection> previous;
        for (std::size_t ordinal = 0; ordinal < trajectory->path_samples.size(); ++ordinal) {
            const auto& sample = trajectory->path_samples[ordinal];
            const auto& xyz = sample.coordinate_values;
            const auto point = std::isfinite(sample.time_value) ? project({xyz[0], xyz[1], xyz[2]}, camera, map)
                                                               : std::nullopt;
            if (previous && point) visitor({index, ordinal - 1, ordinal, *previous, *point});
            // near 平面・裏面・不正値を挟んだ線は作らない。同時刻も原標本の隣接関係を保つ。
            previous = point;
        }
    }
}

void draw_spacecraft(CGContextRef context, const SpacecraftSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, std::optional<std::size_t> selection,
    const SpacecraftDisplayOptions& options, const RendererDisplayOptions& quality) {
    if (!context || !snapshot.model || !usable_map(map) || (!options.points && !options.labels && !options.orbits)) return;
    RendererQualityScope state(context, quality);
    CGContextClipToRect(context, NSRectToCGRect(map));
    if (options.orbits) {
        RendererQualityScope lines(context, quality, RendererPrimitive::line);
        CGContextSetRGBStrokeColor(context, 0.64, 0.84, 0.98, 0.35);
        CGContextSetLineWidth(context, 0.8);
        CGContextBeginPath(context);
        std::size_t pending = 0;
        visit_spacecraft_path_segments(snapshot, camera, map, options, [&](const auto& segment) {
            CGContextMoveToPoint(context, segment.first.x, segment.first.y);
            CGContextAddLineToPoint(context, segment.second.x, segment.second.y);
            // 描画のバッチ上限だけを区切り、後続の標本・出典は省略しない。
            if (++pending == 1024) { CGContextStrokePath(context); CGContextBeginPath(context); pending = 0; }
        });
        if (pending) CGContextStrokePath(context);
    }
    const auto visible = visible_spacecraft(snapshot, camera, map, options);
    if (options.points) {
        RendererQualityScope points(context, quality, RendererPrimitive::point);
        CGContextSetRGBFillColor(context, 0.64, 0.84, 0.98, 0.85);
        for (const auto& probe : visible) {
            const CGFloat radius = selection == probe.index ? 3 : 1.7;
            CGContextFillEllipseInRect(context, CGRectMake(probe.point.x-radius, probe.point.y-radius, 2*radius, 2*radius));
            if (selection != probe.index) continue;
            RendererQualityScope lines(context, quality, RendererPrimitive::line);
            CGContextSetRGBStrokeColor(context, 1, 0.87, 0.40, 1);
            CGContextSetLineWidth(context, 1.5);
            CGContextStrokeEllipseInRect(context, CGRectMake(probe.point.x-7, probe.point.y-7, 14, 14));
        }
    }
    if (options.labels) {
        RendererQualityScope text(context, quality, RendererPrimitive::text);
        for (const auto& probe : visible) {
            const auto& title = snapshot.model->title(probe.index);
            NSString* name = [[NSString alloc] initWithBytes:title.data() length:title.size() encoding:NSUTF8StringEncoding];
            [name drawAtPoint:NSMakePoint(probe.point.x+10, probe.point.y+6) withAttributes:@{
                NSFontAttributeName: [NSFont systemFontOfSize:11], NSForegroundColorAttributeName: NSColor.labelColor}];
        }
    }
}
} // namespace mitaka::gui
