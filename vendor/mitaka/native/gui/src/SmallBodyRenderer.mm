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
// 画面の実位置を、一周期分の原標本と同じ位相の日時に対応付ける。
std::optional<double> orbit_sample_date(const SmallBodyRecord& record,const MinorPlanetOrbitPath& path,double jd) {
    const auto* elements=std::get_if<OrbitalElements>(&record.orbit);
    if (!elements || path.samples.size()<3) return std::nullopt;
    const double first=path.samples.front().julian_date,last=path.samples.back().julian_date;
    if (jd>=first && jd<=last) return jd;
    const double period=360.0/elements->mean_motion_deg_per_day;
    double delta=std::fmod(jd-first,period);
    if (delta<0) delta+=period;
    return first+delta;
}
bool near_chord(const SolarProjection& point,Vec3 a,Vec3 b,const SolarCamera& camera,NSSize size) {
    const auto line=project_solar_segment(a,b,camera,size.width,size.height);
    if (!line) return false;
    const auto& p=(*line)[0]; const auto& q=(*line)[1];
    const double dx=q.x-p.x,dy=q.y-p.y,length=std::hypot(dx,dy);
    if (length==0) return std::hypot(point.x-p.x,point.y-p.y)<=0.25;
    const double along=std::clamp((point.x-p.x)*(dx/length)+(point.y-p.y)*(dy/length),0.0,length);
    return std::hypot(point.x-p.x-along*(dx/length),point.y-p.y-along*(dy/length))<=0.25;
}
template<class Emit> void draw_local_arc(const SmallBodyRecord& record,const MinorPlanetOrbitSample& a,
    const MinorPlanetOrbitSample& b,const SolarCamera& camera,NSSize size,unsigned depth,const Emit& emit) {
    const double middle=a.julian_date+(b.julian_date-a.julian_date)*0.5;
    // 近クリップ面や極端な拡大でも一弦当たりの描画量を制限する。
    if (depth>=6 || !(a.julian_date<middle && middle<b.julian_date)) {
        emit(*a.position,*b.position); return;
    }
    const auto position=evaluate_minor_planet_position(record,middle).heliocentric_j2000_ecliptic_au;
    if (!position) return; // 評価不能な区間を結ばない。
    const auto screen=project_solar(*position,camera,size.width,size.height);
    if (screen && near_chord(*screen,*a.position,*b.position,camera,size)) {
        emit(*a.position,*b.position); return;
    }
    const MinorPlanetOrbitSample mid{middle,position};
    draw_local_arc(record,a,mid,camera,size,depth+1,emit);
    draw_local_arc(record,mid,b,camera,size,depth+1,emit);
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
        || orbits->model != snapshot.model || orbits->paths.size() != snapshot.positions.size()
        || orbits->minor_planet_paths.size() != snapshot.positions.size()) return;
    for (std::size_t row = 0; row < orbits->paths.size(); ++row) {
        if (!display.visibility(row).orbit) continue;
        const auto& id = snapshot.model->dataset().records[row].id;
        const auto emit = [&](Vec3 a, Vec3 b) {
            auto line=project_solar_segment(a,b,camera,map.size.width,map.size.height);
            if (!line) return;
            for (auto& p:*line) { p.x+=map.origin.x; p.y+=map.origin.y; }
            visitor({row,(*line)[0],(*line)[1]});
        };
        if (const auto& path=orbits->paths[row]; path && path->id.source_key==id.source_key &&
            path->id.record_ordinal==id.record_ordinal) {
            for (std::size_t i=1;i<path->samples.size();++i) {
                const auto& a=path->samples[i-1].evaluation.state;
                const auto& b=path->samples[i].evaluation.state;
                if (a && b) emit(a->position_au,b->position_au);
            }
        }
        const auto& path=orbits->minor_planet_paths[row];
        if (!path || path->cancelled || path->id.source_key!=id.source_key ||
            path->id.record_ordinal!=id.record_ordinal) continue;
        const auto& record=snapshot.model->dataset().records[row];
        const auto marker=snapshot.positions[row];
        const auto screen=marker ? project_solar(*marker,camera,map.size.width,map.size.height) : std::nullopt;
        const auto phase=screen && screen->x>=0 && screen->x<map.size.width && screen->y>=0 && screen->y<map.size.height
            ? orbit_sample_date(record,*path,snapshot.julian_date) : std::nullopt;
        const auto edges=path->samples.size() ? path->samples.size()-1 : 0;
        std::size_t edge=0;
        if (phase && edges) {
            const auto next=std::upper_bound(path->samples.begin(),path->samples.end(),*phase,
                [](double jd,const auto& sample){return jd<sample.julian_date;});
            edge=next==path->samples.end() || next==path->samples.begin() ? 0 :
                static_cast<std::size_t>(next-path->samples.begin()-1);
        }
        for (std::size_t i=0;i<edges;++i) {
            const auto& a=path->samples[i]; const auto& b=path->samples[i+1];
            if (!a.position || !b.position) continue;
            // 標本時刻ちょうどでも弦の内側は曲がる。一周期の境界をまたぐ両隣も同じ条件で確認する。
            if (!phase || (i!=edge && i!=(edge+edges-1)%edges && i!=(edge+1)%edges)) {
                emit(*a.position,*b.position); continue;
            }
            if (i==edge && a.julian_date<*phase && *phase<b.julian_date &&
                !near_chord(*screen,*a.position,*b.position,camera,map.size)) {
                const MinorPlanetOrbitSample live{*phase,marker};
                draw_local_arc(record,a,live,camera,map.size,0,emit);
                draw_local_arc(record,live,b,camera,map.size,0,emit);
            } else draw_local_arc(record,a,b,camera,map.size,0,emit);
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
