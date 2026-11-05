#include "horizon_segments.hpp"
#include "horizon_morph_segments.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <stdexcept>
#include <utility>

namespace mitaka::gui {
namespace {
constexpr double pole_tolerance_deg = 1e-8;

double positive_degrees(double value) {
    const double reduced = std::fmod(value, 360);
    return reduced < 0 ? reduced + 360 : reduced;
}
double short_span(double start, double end) {
    return std::fmod(positive_degrees(end) - positive_degrees(start) + 540, 360) - 180;
}
bool pole(EquatorialCoordinates point) {
    return std::abs(std::abs(point.declination_deg) - 90) < pole_tolerance_deg;
}

class Sampler {
public:
    Sampler(EquatorialCoordinates start, EquatorialCoordinates end, const ObservationFrame& frame,
            SkyViewport viewport, double width, double height, HorizonSamplingLimits limits)
        : start_(start), delta_{short_span(start.right_ascension_deg, end.right_ascension_deg),
                              end.declination_deg - start.declination_deg},
          frame_(frame), viewport_(viewport), width_(width), height_(height), limits_(limits) {}

    HorizonSegmentProjection run(EquatorialCoordinates first, EquatorialCoordinates last) {
        result_.evaluations = 2;
        const auto middle = sample(0.5);
        subdivide(0, 1, first, middle, last, 0);
        return std::move(result_);
    }

private:
    EquatorialCoordinates sample(double fraction) {
        ++result_.evaluations;
        const auto horizontal = frame_.to_horizontal({start_.right_ascension_deg + fraction * delta_.right_ascension_deg,
            start_.declination_deg + fraction * delta_.declination_deg});
        return rotate_horizon({360 - horizontal.azimuth_deg, horizontal.altitude_deg}, viewport_);
    }

    bool accepted(std::array<EquatorialCoordinates, 5>& points, double fraction_span) const {
        if (fraction_span * std::max(std::abs(delta_.right_ascension_deg), std::abs(delta_.declination_deg))
            > limits_.max_source_step_deg) return false;
        // 極を内側に持つ区間は二分する。端点の極だけは近傍の方位を引き継ぐ。
        // 天頂を跨いだ両側を一本の横線で結んではならない。
        for (std::size_t index = 1; index < 4; ++index)
            if (pole(points[index])) return false;
        if (pole(points.front())) points.front().right_ascension_deg = points[1].right_ascension_deg;
        if (pole(points.back())) points.back().right_ascension_deg = points[3].right_ascension_deg;
        std::array<double, 5> unwrapped{};
        for (std::size_t index = 1; index < points.size(); ++index) {
            const double span = short_span(points[index - 1].right_ascension_deg, points[index].right_ascension_deg);
            if (std::abs(span) >= 90) return false;
            unwrapped[index] = unwrapped[index - 1] + span;
        }
        if (std::abs(unwrapped.back()) >= 180) return false;
        const double x_scale = viewport_.zoom * width_ / 360;
        const double y_scale = viewport_.zoom * height_ / 180;
        for (std::size_t index = 1; index < 4; ++index) {
            const double fraction = static_cast<double>(index) / 4;
            const double dx = (unwrapped[index] - fraction * unwrapped.back()) * x_scale;
            const double interpolated = points.front().declination_deg
                + fraction * (points.back().declination_deg - points.front().declination_deg);
            const double dy = (points[index].declination_deg - interpolated) * y_scale;
            if (std::hypot(dx, dy) > limits_.screen_tolerance) return false;
        }
        return true;
    }

    void subdivide(double begin, double end, EquatorialCoordinates first,
                   EquatorialCoordinates middle, EquatorialCoordinates last, unsigned depth) {
        if (result_.evaluations > limits_.max_evaluations - 2) {
            ++result_.omitted_intervals;
            return;
        }
        const double midpoint = (begin + end) / 2;
        std::array<EquatorialCoordinates, 5> points{{first, sample((begin + midpoint) / 2), middle,
                                                   sample((midpoint + end) / 2), last}};
        if (std::all_of(points.begin(), points.end(), [&](const auto& point) {
                return pole(point) && point.declination_deg * first.declination_deg > 0;
            })) return;
        if (viewport_.perspective_blend > 0) {
            const auto decision = project_morph_interval(points, viewport_, width_, height_,
                (end - begin) * std::max(std::abs(delta_.right_ascension_deg), std::abs(delta_.declination_deg)),
                limits_, result_);
            if (decision != HorizonMorphDecision::subdivide) return;
            if (depth == limits_.max_depth) return;
            subdivide(begin, midpoint, first, points[1], middle, depth + 1);
            subdivide(midpoint, end, middle, points[3], last, depth + 1);
            return;
        }
        auto adjusted = points;
        if (accepted(adjusted, end - begin)) {
            const auto segments = project_sky_segment(adjusted.front(), adjusted.back(), {0, 0, viewport_.zoom}, width_, height_);
            result_.segments.insert(result_.segments.end(), segments.begin(), segments.end());
            return;
        }
        if (depth == limits_.max_depth) {
            ++result_.omitted_intervals;
            return;
        }
        subdivide(begin, midpoint, first, points[1], middle, depth + 1);
        subdivide(midpoint, end, middle, points[3], last, depth + 1);
    }

    EquatorialCoordinates start_, delta_;
    const ObservationFrame& frame_;
    SkyViewport viewport_;
    double width_, height_;
    HorizonSamplingLimits limits_;
    HorizonSegmentProjection result_;
};
} // namespace

HorizonSegmentProjection project_equatorial_segment_to_horizon(
    EquatorialCoordinates start, EquatorialCoordinates end, const ObservationFrame& frame,
    const HorizonViewport& viewport, double width, double height, HorizonSamplingLimits limits) {
    if (!std::isfinite(viewport.center_azimuth_deg) || !std::isfinite(viewport.center_altitude_deg)
        || std::abs(viewport.center_altitude_deg) > 90 || !std::isfinite(viewport.zoom)
        || viewport.zoom < 1 || viewport.zoom > 180
        || !std::isfinite(viewport.perspective_blend) || viewport.perspective_blend < 0 || viewport.perspective_blend > 1
        || !std::isfinite(width) || width <= 0 || !std::isfinite(height) || height <= 0
        || !std::isfinite(width * viewport.zoom) || !std::isfinite(height * viewport.zoom)
        || !std::isfinite(limits.max_source_step_deg) || limits.max_source_step_deg <= 0 || limits.max_source_step_deg > 2
        || !std::isfinite(limits.screen_tolerance) || limits.screen_tolerance <= 0 || limits.screen_tolerance > 4
        || limits.max_evaluations < 5 || limits.max_evaluations > 1048577
        || limits.max_depth < 1 || limits.max_depth > 24)
        throw std::invalid_argument("invalid horizon segment projection parameters");
    // 変換基底の既存検証を使い、無効な端点の部分描画を返さない。
    const auto first = frame.to_horizontal(start);
    const auto last = frame.to_horizontal(end);
    start.right_ascension_deg = positive_degrees(start.right_ascension_deg);
    end.right_ascension_deg = positive_degrees(end.right_ascension_deg);
    const SkyViewport sky_viewport{360 - viewport.center_azimuth_deg, viewport.center_altitude_deg,
        viewport.zoom, viewport.perspective_blend};
    return Sampler(start, end, frame, sky_viewport, width, height, limits).run(
        rotate_horizon({360 - first.azimuth_deg, first.altitude_deg}, sky_viewport),
        rotate_horizon({360 - last.azimuth_deg, last.altitude_deg}, sky_viewport));
}

} // namespace mitaka::gui
