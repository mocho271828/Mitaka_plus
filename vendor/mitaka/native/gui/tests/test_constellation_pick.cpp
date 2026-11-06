#include "constellation_pick.hpp"
#include <cmath>
#include <iostream>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
void check(bool value, const char* message) { if (!value) throw std::runtime_error(message); }
void tests() {
    const ObservationFrame frame({35,139}, 2451545);
    const HorizonViewport viewport{50,35,180,1,18};
    const auto first = frame.to_equatorial({45,33});
    const auto last = frame.to_equatorial({55,37});
    const auto lookup = [&](std::int32_t hip) -> std::optional<EquatorialCoordinates> {
        if (hip == 1) return first;
        if (hip == 2) return last;
        return std::nullopt;
    };
    ConstellationRecord record{};
    record.abbreviation = "ABC";
    record.hip_lines = {{1,2}};
    const std::vector<ConstellationRecord> records{record};
    const auto segments = project_equatorial_segment_to_horizon(first,last,frame,viewport,800,600).segments;
    check(!segments.empty(), "test must project a line");
    const auto segment = segments[segments.size()/2];
    const ScreenPoint point{(segment.start.x + segment.end.x)/2, (segment.start.y + segment.end.y)/2};
    ConstellationDisplayOptions options;
    auto pick = [&](ScreenPoint p, double tolerance, const ConstellationPointVisible& visible) {
        return pick_horizon_constellation(records,lookup,options,frame,viewport,800,600,p,tolerance,visible);
    };
    const auto visible = [](ScreenPoint) { return true; };
    const auto hit = pick(point, 2, visible);
    check(hit && hit->record_index == 0 && hit->distance < 1e-7, "drawn segment must be picked");
    check(!pick({0,0},2,visible), "far point must not hit");
    check(!pick(point,2,[](ScreenPoint){return false;}), "occluded segment must not hit");
    const double dx = segment.end.x - segment.start.x, dy = segment.end.y - segment.start.y;
    const double length = std::hypot(dx, dy);
    check(length > 0, "test segment must be nonzero");
    const ScreenPoint groundClick{point.x - dy / length, point.y + dx / length};
    check(!pick(groundClick, 2, [&](ScreenPoint p) {
        return std::hypot(p.x - groundClick.x, p.y - groundClick.y) > 0.1;
    }), "occluded click must not select adjacent visible segment");
    options.exceptions.insert("ABC");
    check(!pick(point,2,visible), "hidden constellation must not hit");
    options.exceptions.clear(); options.lines = false;
    check(!pick(point,2,visible), "disabled lines must not hit");
    options.lines = true;
    auto disconnected = record;
    disconnected.hip_lines = {{1,99,2}};
    check(!pick_horizon_constellation({disconnected},lookup,options,frame,viewport,800,600,point,2,visible), "missing HIP must break line");
    check(!pick({800,1},2,visible), "outside map must not hit");
    auto boundary = record;
    boundary.hip_lines.clear();
    boundary.boundary = {{static_cast<float>(first.right_ascension_deg / 15), static_cast<float>(first.declination_deg)},
                         {static_cast<float>(last.right_ascension_deg / 15), static_cast<float>(last.declination_deg)}};
    options.lines = false; options.boundaries = true;
    const EquatorialCoordinates b0{boundary.boundary[0].right_ascension_hours * 15, boundary.boundary[0].declination_degrees};
    const EquatorialCoordinates b1{boundary.boundary[1].right_ascension_hours * 15, boundary.boundary[1].declination_degrees};
    const auto boundarySegments = project_equatorial_segment_to_horizon(b0,b1,frame,viewport,800,600).segments;
    check(!boundarySegments.empty(), "boundary must be visible");
    const auto midpoint = boundarySegments[boundarySegments.size()/2].start;
    check(pick_horizon_constellation({boundary},lookup,options,frame,viewport,800,600,midpoint,1,visible).has_value(),
          "displayed boundary must be selectable");
    // 実際の線分と選択に同じ透視画角を使用し、画角変更前の線を拾わない。
    const auto left = frame.to_equatorial({46, 38});
    const auto right = frame.to_equatorial({54, 38});
    const auto fovLookup = [&](std::int32_t hip) -> std::optional<EquatorialCoordinates> {
        if (hip == 1) return left;
        if (hip == 2) return right;
        return std::nullopt;
    };
    options.lines = true; options.boundaries = false;
    std::optional<ScreenPoint> previous;
    for (const double fov : {20., 45., 90.}) {
        const HorizonViewport current{50,35,180,1,18,fov};
        const auto projected = project_equatorial_segment_to_horizon(left,right,frame,current,800,600).segments;
        check(!projected.empty(), "FOV constellation line missing");
        const auto& middle = projected[projected.size() / 2];
        const ScreenPoint point{(middle.start.x + middle.end.x) / 2, (middle.start.y + middle.end.y) / 2};
        check(pick_horizon_constellation(records,fovLookup,options,frame,current,800,600,point,2,visible).has_value(),
              "drawn constellation line not selectable at FOV");
        if (previous)
            check(!pick_horizon_constellation(records,fovLookup,options,frame,current,800,600,*previous,2,visible),
                  "old FOV constellation line incorrectly selectable");
        previous = point;
    }
}
}
int main() {
    try { tests(); std::cout << "constellation pick tests passed\n"; }
    catch (const std::exception& e) { std::cerr << e.what() << '\n'; return 1; }
}
