#include "horizon_segments.hpp"
#include "horizon_morph_segments.hpp"
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
        check(viewport.vertical_fov_deg < 180 || std::abs(segment.end.x - segment.start.x) < width / 2, "azimuth seam or pole was bridged");
    }
    const double delta = std::fmod(end.right_ascension_deg - start.right_ascension_deg + 540, 360) - 180;
    for (unsigned index = 0; index <= 4000; ++index) {
        const double fraction = index / 4000.0;
        const auto horizontal = frame.to_horizontal({start.right_ascension_deg + delta * fraction,
            start.declination_deg + (end.declination_deg - start.declination_deg) * fraction});
        const HorizonProjectionViewport sky_viewport{360 - viewport.center_azimuth_deg, viewport.center_altitude_deg,
            viewport.vertical_fov_deg, viewport.perspective_blend, viewport.roll_deg};
        const EquatorialCoordinates coordinates{360 - horizontal.azimuth_deg, horizontal.altitude_deg};
        // 回転後の極では経度が定義できず、任意の経度を描画上の正解にできない。
        if (std::abs(rotate_horizon(coordinates, sky_viewport).declination_deg) > 89.99999) continue;
        const auto point = project_horizon(coordinates, sky_viewport, width, height);
        if (!point) continue;
        double nearest = std::numeric_limits<double>::infinity();
        for (const auto& segment : result.segments) {
            nearest = std::min(nearest, distance(*point, segment));
            // 全天の左右端は同じ方向。極近傍の丸めによる 0/360 の選択差を誤差に含めない。
            if (viewport.vertical_fov_deg == 180) for (double offset : {-width, width})
                nearest = std::min(nearest, distance({point->x + offset, point->y}, segment));
        }
        check(nearest <= 0.3, "dense reference is outside the subpixel sampling envelope");
    }
}
void seam_coverage(HorizontalCoordinates first, HorizontalCoordinates last,
                   const ObservationFrame& frame, double blend) {
    const auto start = frame.to_equatorial(first), end = frame.to_equatorial(last);
    const HorizonViewport viewport{0, 0, 179, blend};
    const auto result = project_equatorial_segment_to_horizon(start, end, frame, viewport, 1200, 700);
    check(result.evaluations <= 8193, "seam sampling must respect its evaluation budget");
    const double delta = std::fmod(end.right_ascension_deg - start.right_ascension_deg + 540, 360) - 180;
    const HorizonProjectionViewport projection{360, 0, 179, blend};
    unsigned visible = 0;
    for (unsigned i = 0; i <= 2000; ++i) {
        const double t = i / 2000.0;
        const auto horizontal = frame.to_horizontal({start.right_ascension_deg + t * delta,
            start.declination_deg + t * (end.declination_deg - start.declination_deg)});
        const auto point = project_horizon({360 - horizontal.azimuth_deg, horizontal.altitude_deg}, projection, 1200, 700);
        if (!point) continue;
        ++visible;
        double nearest = std::numeric_limits<double>::infinity();
        for (const auto& segment : result.segments) nearest = std::min(nearest, distance(*point, segment));
        check(nearest < 1, "visible seam segment must not disappear on either side");
    }
    check(visible > 10, "seam reference must contain visible points");
}
void outside_oracle() {
    constexpr double width = 1200, height = 700;
    unsigned excluded = 0, visible = 0;
    for (const ObserverSite site : {ObserverSite{35,139}, {90,0}}) {
        const ObservationFrame frame(site, 2451545);
        for (double fov : {1e-6, 1., 45., 120., 179.})
        for (double blend : {0., 0.01, 0.5, 1.})
        for (double roll : {0., 47., 135.}) {
            const HorizonProjectionViewport viewport{250, 30, fov, blend, roll};
            for (double x : {120., 600., 1080.})
            for (double y : {0., 700.}) {
                const auto direction = unproject_horizon({x, y}, viewport, width, height);
                const auto anchor = frame.to_equatorial({360 - direction.right_ascension_deg, direction.declination_deg});
                const double step = std::min(0.05, std::max(fov, 0.01) * 0.01);
                for (int dx : {-2, 0, 2}) for (int dy : {-2, 0, 2}) {
                    EquatorialCoordinates start{anchor.right_ascension_deg + dx * step,
                        std::clamp(anchor.declination_deg + dy * step, -90., 90.)};
                    EquatorialCoordinates end{start.right_ascension_deg + step,
                        std::clamp(start.declination_deg + step * 0.5, -90., 90.)};
                    const double ra_delta = end.right_ascension_deg - start.right_ascension_deg;
                    const double dec_delta = end.declination_deg - start.declination_deg;
                    const double source_span = std::max(std::abs(ra_delta), std::abs(dec_delta));
                    auto sample = [&](double t) {
                        const auto horizontal = frame.to_horizontal({start.right_ascension_deg + t * ra_delta,
                            start.declination_deg + t * dec_delta});
                        return EquatorialCoordinates{360 - horizontal.azimuth_deg, horizontal.altitude_deg};
                    };
                    std::array<EquatorialCoordinates, 5> samples;
                    for (unsigned i = 0; i < samples.size(); ++i)
                        samples[i] = rotate_horizon(sample(i / 4.), viewport);
                    const bool outside = horizon_interval_outside(samples, viewport, width, height, source_span);
                    if (outside) ++excluded;
                    for (unsigned i = 0; i <= 256; ++i) {
                        if (!project_horizon(sample(i / 256.), viewport, width, height)) continue;
                        ++visible;
                        check(!outside, "conservative boundary rejection removed a visible sample");
                    }
                }
            }
        }
    }
    check(excluded > 100 && visible > 100, "outside oracle must exercise rejection and visibility");
}
void subpixel_oracle() {
    unsigned accepted = 0, visible_intervals = 0, clipped_intervals = 0, strict_intervals = 0;
    const std::array<ScreenPoint, 5> locations{{{0.5, 0.5}, {0, 0.5}, {1, 0.5},
                                                {0.5, 0}, {0.5, 1}}};
    for (const ObserverSite site : {ObserverSite{35,139}, {90,0}}) {
        const ObservationFrame frame(site, 2451545);
        for (double fov : {1e-9, 1e-6, 0.01, 1., 45., 90., 179.})
        for (double blend : {0., 1e-12, 1e-6, 0.01, 0.5, 1.})
        for (const ScreenPoint size : {ScreenPoint{1200,700}, {300,1200}, {3000,200}, {300,300}})
        for (double roll : {0., 47., 135.}) {
            const HorizonProjectionViewport viewport{250, 30, fov, blend, roll};
            for (const auto location : locations) {
                const auto direction = unproject_horizon({location.x * size.x, location.y * size.y},
                                                         viewport, size.x, size.y);
                const auto anchor = frame.to_equatorial({360 - direction.right_ascension_deg, direction.declination_deg});
                for (double factor : {0.01, 0.1, 1.}) {
                    const double step = fov / std::max(size.x, size.y) * factor;
                    const EquatorialCoordinates start{anchor.right_ascension_deg - step / 2,
                        std::clamp(anchor.declination_deg - step / 4, -90., 90.)};
                    const EquatorialCoordinates end{anchor.right_ascension_deg + step / 2,
                        std::clamp(anchor.declination_deg + step / 4, -90., 90.)};
                    // 実際に丸められた端点を基準に補間する。意図した step を使うと微小画角で契約が変わる。
                    const double ra_delta = end.right_ascension_deg - start.right_ascension_deg;
                    const double dec_delta = end.declination_deg - start.declination_deg;
                    const double source_span = std::max(std::abs(ra_delta), std::abs(dec_delta));
                    if (source_span == 0) continue;
                    auto sample = [&](double t) {
                        const auto horizontal = frame.to_horizontal({start.right_ascension_deg + t * ra_delta,
                            start.declination_deg + t * dec_delta});
                        return EquatorialCoordinates{360 - horizontal.azimuth_deg, horizontal.altitude_deg};
                    };
                    std::array<EquatorialCoordinates, 5> rotated;
                    for (unsigned i = 0; i < rotated.size(); ++i)
                        rotated[i] = rotate_horizon(sample(i / 4.), viewport);
                    const std::array<double, 4> tolerances{{0.01, 0.1, 0.25, 1.}};
                    double accepted_tolerance = 1.;
                    bool is_accepted = false;
                    for (double tolerance : tolerances) {
                        if (!horizon_morph_subpixel(rotated, viewport, size.x, size.y, source_span, tolerance)) continue;
                        is_accepted = true;
                        accepted_tolerance = std::min(accepted_tolerance, tolerance);
                    }
                    if (!is_accepted) continue;
                    ++accepted;
                    double min_x = size.x, max_x = 0, min_y = size.y, max_y = 0;
                    unsigned visible = 0;
                    for (unsigned i = 0; i <= 1024; ++i) {
                        const auto point = project_horizon(sample(i / 1024.), viewport, size.x, size.y);
                        if (!point) continue;
                        ++visible;
                        min_x = std::min(min_x, point->x); max_x = std::max(max_x, point->x);
                        min_y = std::min(min_y, point->y); max_y = std::max(max_y, point->y);
                    }
                    if (visible == 0) continue;
                    ++visible_intervals;
                    if (visible < 1025) ++clipped_intervals;
                    if (accepted_tolerance == 0.01) ++strict_intervals;
                    check(std::hypot(max_x - min_x, max_y - min_y) <= std::min(0.25, accepted_tolerance) + 0.000001,
                          "subpixel interval exceeds its screen tolerance in the dense reference");
                }
            }
        }
    }
    check(accepted > 100 && visible_intervals > 100 && clipped_intervals > 10 && strict_intervals > 10,
          "subpixel oracle must cover visible, clipped and strict-tolerance intervals");
    const HorizonProjectionViewport viewport{0, 0, 179, 0.5};
    for (const EquatorialCoordinates singular : {EquatorialCoordinates{0,90}, {180,0}}) {
        std::array<EquatorialCoordinates, 5> rotated;
        rotated.fill(singular);
        check(!horizon_morph_subpixel(rotated, viewport, 1200, 700, 0, 0.25),
              "subpixel optimization must not cross a pole or longitude seam");
    }
}
void tests() {
    outside_oracle();
    subpixel_oracle();
    for (const ObserverSite site : {ObserverSite{0,0}, {35,139}, {90,0}, {-90,40}})
        for (const double jd : {2451545.0, 2460000.25}) {
            const ObservationFrame frame(site, jd);
            curve({350,-35}, {10,45}, frame, {});
            curve({35,15}, {175,-10}, frame, {});
            const auto center = frame.to_horizontal({90,0});
            curve({88,-1}, {92,1}, frame, {center.azimuth_deg, center.altitude_deg,1});
        }
    const ObservationFrame frame({35,139}, 2451545);
    seam_coverage({185,89.499}, {175,89.499}, frame, 1e-12);
    seam_coverage({175,89.499}, {185,89.499}, frame, 1e-12);
    seam_coverage({270,45}, {90,45}, frame, 1e-6);
    seam_coverage({90,45}, {270,45}, frame, 1e-6);
    for (double blend : {0.01, 0.5}) {
        seam_coverage({269,0}, {91,0}, frame, blend);
        seam_coverage({91,0}, {269,0}, frame, blend);
    }
    const HorizonViewport wide_morph{0, 0, 179, 1e-12};
    const auto high_start = frame.to_equatorial({181.1, 89.499});
    const auto high_end = frame.to_equatorial({180.9, 89.499});
    const auto high_crossing = project_equatorial_segment_to_horizon(high_start, high_end, frame,
        wide_morph, 1200, 700);
    check(!high_crossing.segments.empty(), "wide field edge crossing near pole disappeared");
    check(high_crossing.evaluations <= 8193, "wide field edge crossing exceeded sampling budget");
    const auto narrow_center = frame.to_horizontal({90, 0});
    for (double blend : {0.0, 0.5, 1.0})
        curve({89.9, -0.1}, {90.1, 0.1}, frame,
              {narrow_center.azimuth_deg, narrow_center.altitude_deg, 0.5, blend});
    const auto crossing = project_equatorial_segment_to_horizon({88.9, 0}, {90.9, 0}, frame,
        {narrow_center.azimuth_deg, narrow_center.altitude_deg, 0.001, 0.000001}, 1200, 700);
    check(!crossing.segments.empty(), "narrow field crossing between sample points disappeared");
    check(crossing.evaluations <= 8193, "narrow field crossing exceeded sampling budget");
    const auto tiny_crossing = project_equatorial_segment_to_horizon({88.9, 0}, {90.9, 0}, frame,
        {narrow_center.azimuth_deg, narrow_center.altitude_deg, 1e-9, 1e-12}, 1200, 700);
    check(!tiny_crossing.segments.empty(), "tiny field crossing disappeared at the default depth");
    check(tiny_crossing.evaluations <= 8193, "tiny field crossing exceeded sampling budget");
    const HorizonProjectionViewport tiny_viewport{360 - narrow_center.azimuth_deg,
        narrow_center.altitude_deg, 1e-9, 1e-12};
    unsigned tiny_visible = 0;
    for (unsigned i = 0; i <= 400; ++i) {
        const auto horizontal = frame.to_horizontal({90 + (static_cast<double>(i) - 200) * 1e-11, 0});
        const auto point = project_horizon({360 - horizontal.azimuth_deg, horizontal.altitude_deg},
                                           tiny_viewport, 1200, 700);
        if (!point) continue;
        ++tiny_visible;
        double nearest = std::numeric_limits<double>::infinity();
        for (const auto& segment : tiny_crossing.segments) nearest = std::min(nearest, distance(*point, segment));
        check(nearest < 2, "tiny field crossing must cover the center and visible boundary");
    }
    check(tiny_visible > 10, "tiny field reference must include visible points");
    const ObservationFrame polar_frame({90, 0}, 2451545);
    const auto polar_center = polar_frame.to_horizontal({90, 0});
    const auto polar_crossing = project_equatorial_segment_to_horizon({88.9, 0}, {90.9, 0}, polar_frame,
        {polar_center.azimuth_deg, polar_center.altitude_deg + 4.5e-10, 1e-9, 1e-12}, 1200, 700);
    check(!polar_crossing.segments.empty(), "tiny field crossing near edge disappeared");
    check(polar_crossing.evaluations <= 8193, "tiny field edge crossing exceeded sampling budget");
    const auto polar_outside = project_equatorial_segment_to_horizon({88.9, 0}, {90.9, 0}, polar_frame,
        {polar_center.azimuth_deg, polar_center.altitude_deg + 5.5e-10, 1e-9, 1e-12}, 1200, 700);
    check(polar_outside.segments.empty() && polar_outside.evaluations < 8193 && polar_outside.omitted_intervals == 0,
          "nearby outside segment must be rejected without exhausting the budget");
    for (double fov : {1e-7, std::numeric_limits<double>::denorm_min()})
        for (double blend : {0.0, 0.000001}) {
            const auto outside = project_equatorial_segment_to_horizon({120, 10}, {122, 11}, frame,
                {narrow_center.azimuth_deg, narrow_center.altitude_deg, fov, blend}, 1200, 700);
            check(outside.segments.empty() && outside.evaluations == 5 && outside.omitted_intervals == 0,
                  "distant narrow-field segment must be rejected within one sample interval");
        }
    curve({0,0}, {180,0}, frame, {});
    curve({359.9,10}, {0.1,10}, frame, {});
    const auto zenith = frame.to_equatorial({0,90});
    curve({zenith.right_ascension_deg, zenith.declination_deg - 10}, {zenith.right_ascension_deg, zenith.declination_deg + 10}, frame, {});
    curve(zenith, {zenith.right_ascension_deg, zenith.declination_deg - 20}, frame, {});
    curve({zenith.right_ascension_deg, zenith.declination_deg - 10},
          {zenith.right_ascension_deg, zenith.declination_deg + 10}, frame, {0, 90, 90});
    const auto nadir = frame.to_equatorial({0,-90});
    curve({nadir.right_ascension_deg, nadir.declination_deg - 10}, {nadir.right_ascension_deg, nadir.declination_deg + 10}, frame, {});
    curve({nadir.right_ascension_deg, nadir.declination_deg - 10},
          {nadir.right_ascension_deg, nadir.declination_deg + 10}, frame, {0, -90, 90});
    HorizonSamplingLimits limits; limits.max_evaluations = 5;
    const auto limited = project_equatorial_segment_to_horizon({0,0}, {150,60}, frame, {}, 1200,700,limits);
    check(limited.evaluations <= 5 && limited.omitted_intervals > 0 && limited.segments.empty(), "budget exhaustion must not invent a long chord");
    limits = {}; limits.max_depth = 1;
    const auto shallow = project_equatorial_segment_to_horizon({0,0}, {150,60}, frame, {},1200,700,limits);
    check(shallow.omitted_intervals > 0, "depth exhaustion must be explicit");
    const auto shallow_morph = project_equatorial_segment_to_horizon({88.9, 0}, {90.9, 0}, frame,
        {narrow_center.azimuth_deg, narrow_center.altitude_deg, 1e-9, 1e-12}, 1200, 700, limits);
    check(shallow_morph.omitted_intervals > 0, "morph depth exhaustion must be explicit");
    const auto below = frame.to_equatorial({180,-45});
    const auto low = project_equatorial_segment_to_horizon(below, {below.right_ascension_deg + 1,below.declination_deg},frame,{},1200,700);
    check(!low.segments.empty() && low.segments.front().start.y > 350, "lower hemisphere was silently discarded");
    const double nan = std::numeric_limits<double>::quiet_NaN();
    for (const auto bad : {EquatorialCoordinates{nan,0}, {0,nan}, {0,91}, {std::numeric_limits<double>::infinity(),0}})
        rejects([&] { project_equatorial_segment_to_horizon(bad,{0,0},frame,{},1200,700); });
    for (const auto bad : {HorizonViewport{nan,0,1}, {0,91,1}, {0,0,181}, {0,0,0}})
        rejects([&] { project_equatorial_segment_to_horizon({0,0},{1,1},frame,bad,1200,700); });
    rejects([&] { project_equatorial_segment_to_horizon({0,0},{1,1},frame,{},0,700); });
    rejects([&] { project_equatorial_segment_to_horizon({0,0},{1,1},frame,{0,0,1},std::numeric_limits<double>::max(),700); });
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
