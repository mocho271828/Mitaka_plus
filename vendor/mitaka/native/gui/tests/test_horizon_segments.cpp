#include "horizon_segments.hpp"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
void check(bool condition, const char* message) { ++checks; if (!condition) throw std::runtime_error(message); }
template<class Action> void rejects(Action action) {
    try { action(); } catch (const std::invalid_argument&) { ++checks; return; }
    throw std::runtime_error("expected invalid argument");
}
double distance(ScreenPoint point, ScreenSegment segment) {
    const double dx = segment.end.x - segment.start.x, dy = segment.end.y - segment.start.y;
    const double square = dx * dx + dy * dy;
    const double t = square == 0 ? 0 : std::clamp(((point.x - segment.start.x) * dx + (point.y - segment.start.y) * dy) / square, 0.0, 1.0);
    return std::hypot(point.x - segment.start.x - t * dx, point.y - segment.start.y - t * dy);
}
void curve(EquatorialCoordinates start, EquatorialCoordinates end, const ObservationFrame& frame, HorizonViewport viewport) {
    const double width = 1200, height = 700;
    const auto result = project_equatorial_segment_to_horizon(start, end, frame, viewport, width, height);
    check(result.evaluations <= 8193 && result.omitted_intervals == 0, "ordinary curve must finish within sampling budget");
    for (const auto& segment : result.segments) {
        for (const auto point : {segment.start, segment.end}) check(std::isfinite(point.x) && std::isfinite(point.y)
            && point.x >= -1e-8 && point.x <= width + 1e-8 && point.y >= -1e-8 && point.y <= height + 1e-8, "segments must be finite and clipped");
        check(viewport.zoom > 1 || std::abs(segment.end.x - segment.start.x) < width / 2, "azimuth seam or pole was bridged");
    }
    const double delta = std::fmod(end.right_ascension_deg - start.right_ascension_deg + 540, 360) - 180;
    for (unsigned index = 0; index <= 4000; ++index) {
        const double fraction = index / 4000.0;
        const auto horizontal = frame.to_horizontal({start.right_ascension_deg + delta * fraction,
            start.declination_deg + (end.declination_deg - start.declination_deg) * fraction});
        // 極そのものの方位は定義できないため、任意の az=0 を描画の正解にしない。
        if (std::abs(horizontal.altitude_deg) > 89.99999) continue;
        const auto point = project_sky({360 - horizontal.azimuth_deg, horizontal.altitude_deg},
            {360 - viewport.center_azimuth_deg, viewport.center_altitude_deg, viewport.zoom}, width, height);
        if (!point) continue;
        double nearest = std::numeric_limits<double>::infinity();
        for (const auto& segment : result.segments) {
            nearest = std::min(nearest, distance(*point, segment));
            // 全天の左右端は同じ方向。極近傍の丸めによる 0/360 の選択差を誤差に含めない。
            if (viewport.zoom == 1) for (double offset : {-width, width})
                nearest = std::min(nearest, distance({point->x + offset, point->y}, segment));
        }
        check(nearest <= 0.3, "dense reference is outside the subpixel sampling envelope");
    }
}
void tests() {
    for (const ObserverSite site : {ObserverSite{0,0}, {35,139}, {90,0}, {-90,40}})
        for (const double jd : {2451545.0, 2460000.25}) {
            const ObservationFrame frame(site, jd);
            curve({350,-35}, {10,45}, frame, {});
            curve({35,15}, {175,-10}, frame, {});
            const auto center = frame.to_horizontal({90,0});
            curve({88,-1}, {92,1}, frame, {center.azimuth_deg, center.altitude_deg,180});
        }
    const ObservationFrame frame({35,139}, 2451545);
    curve({0,0}, {180,0}, frame, {});
    curve({359.9,10}, {0.1,10}, frame, {});
    const auto zenith = frame.to_equatorial({0,90});
    curve({zenith.right_ascension_deg, zenith.declination_deg - 10}, {zenith.right_ascension_deg, zenith.declination_deg + 10}, frame, {});
    curve(zenith, {zenith.right_ascension_deg, zenith.declination_deg - 20}, frame, {});
    const auto nadir = frame.to_equatorial({0,-90});
    curve({nadir.right_ascension_deg, nadir.declination_deg - 10}, {nadir.right_ascension_deg, nadir.declination_deg + 10}, frame, {});
    HorizonSamplingLimits limits; limits.max_evaluations = 5;
    const auto limited = project_equatorial_segment_to_horizon({0,0}, {150,60}, frame, {}, 1200,700,limits);
    check(limited.evaluations <= 5 && limited.omitted_intervals > 0 && limited.segments.empty(), "budget exhaustion must not invent a long chord");
    limits = {}; limits.max_depth = 1;
    const auto shallow = project_equatorial_segment_to_horizon({0,0}, {150,60}, frame, {},1200,700,limits);
    check(shallow.omitted_intervals > 0, "depth exhaustion must be explicit");
    const auto below = frame.to_equatorial({180,-45});
    const auto low = project_equatorial_segment_to_horizon(below, {below.right_ascension_deg + 1,below.declination_deg},frame,{},1200,700);
    check(!low.segments.empty() && low.segments.front().start.y > 350, "lower hemisphere was silently discarded");
    const double nan = std::numeric_limits<double>::quiet_NaN();
    for (const auto bad : {EquatorialCoordinates{nan,0}, {0,nan}, {0,91}, {std::numeric_limits<double>::infinity(),0}})
        rejects([&] { project_equatorial_segment_to_horizon(bad,{0,0},frame,{},1200,700); });
    for (const auto bad : {HorizonViewport{nan,0,1}, {0,91,1}, {0,0,181}, {0,0,0}})
        rejects([&] { project_equatorial_segment_to_horizon({0,0},{1,1},frame,bad,1200,700); });
    rejects([&] { project_equatorial_segment_to_horizon({0,0},{1,1},frame,{},0,700); });
    rejects([&] { project_equatorial_segment_to_horizon({0,0},{1,1},frame,{0,0,180},std::numeric_limits<double>::max(),700); });
    limits = {}; limits.max_evaluations = 4;
    rejects([&] { project_equatorial_segment_to_horizon({0,0},{1,1},frame,{},1200,700,limits); });
    limits = {}; limits.screen_tolerance = nan;
    rejects([&] { project_equatorial_segment_to_horizon({0,0},{1,1},frame,{},1200,700,limits); });
}
}
int main() {
    try { tests(); std::cout << "Horizon segment tests passed: " << checks << " checks\n"; }
    catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
}
