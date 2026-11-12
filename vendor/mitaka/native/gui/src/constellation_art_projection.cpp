#include "constellation_art_projection.hpp"
#include "horizon_morph_segments.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <deque>
#include <utility>

namespace mitaka::gui {
namespace {
double span(double a, double b) { return std::remainder(b - a, 360); }
bool pole(EquatorialCoordinates p) { return std::abs(std::abs(p.declination_deg) - 90) < 1e-8; }
Vec3 normalized(Vec3 p) {
    const double n = std::hypot(p.x, p.y, p.z);
    if (!std::isfinite(n) || n == 0) throw std::invalid_argument("invalid CAB segment direction");
    return {p.x / n, p.y / n, p.z / n};
}
class Sampler {
public:
    Sampler(Vec3 start, Vec3 end, const ObservationFrame* frame, SkyViewport viewport,
        HorizonProjectionViewport horizon_viewport,
        double width, double height, HorizonSamplingLimits limits)
        : start_(normalized(start)), end_(normalized(end)), frame_(frame), viewport_(viewport),
          horizon_viewport_(horizon_viewport), width_(width), height_(height), limits_(limits) {
        // 正の端点長は大円上の同じ弧を表すため、正規化して演算の動的範囲を抑える。
        const double dot = std::clamp(start_.x * end_.x + start_.y * end_.y + start_.z * end_.z, -1.0, 1.0);
        if (dot <= -1 + 1e-14) throw std::invalid_argument("CAB segment crosses observer origin");
        const Vec3 cross{start_.y * end_.z - start_.z * end_.y,
                         start_.z * end_.x - start_.x * end_.z,
                         start_.x * end_.y - start_.y * end_.x};
        // 端点が近い場合は内積が 1 に丸められても微小な角距離を失わない。
        cross_length_ = std::hypot(cross.x, cross.y, cross.z);
    }
    HorizonSegmentProjection run() {
        const auto a = sample(0), m = sample(.5), b = sample(1);
        pending_.push_back({0, 1, a, m, b, 0});
        while (!pending_.empty()) {
            const auto interval = pending_.front();
            pending_.pop_front();
            subdivide(interval.a, interval.b, interval.first, interval.middle, interval.last, interval.depth);
        }
        return std::move(result_);
    }
private:
    EquatorialCoordinates sample(double t) {
        ++result_.evaluations;
        const auto p = equatorial_coordinates({(1 - t) * start_.x + t * end_.x,
            (1 - t) * start_.y + t * end_.y, (1 - t) * start_.z + t * end_.z});
        if (!frame_) return p;
        const auto h = frame_->to_horizontal(p);
        return rotate_horizon({360 - h.azimuth_deg, h.altitude_deg}, horizon_viewport_);
    }
    double source_span(double a, double b) const {
        // 正規化直線は大円弧を単調に進む。全区間の最大角速度では
        // 対蹠点に近い端点で遠方まで過分割されるため、区間の角距離を使う。
        const Vec3 p{(1 - a) * start_.x + a * end_.x, (1 - a) * start_.y + a * end_.y,
                     (1 - a) * start_.z + a * end_.z};
        const Vec3 q{(1 - b) * start_.x + b * end_.x, (1 - b) * start_.y + b * end_.y,
                     (1 - b) * start_.z + b * end_.z};
        return std::atan2((b - a) * cross_length_, p.x * q.x + p.y * q.y + p.z * q.z)
            * 180 / 3.14159265358979323846;
    }
    bool accepted(std::array<EquatorialCoordinates, 5>& points, double source_span) const {
        if (source_span > limits_.max_source_step_deg) return false;
        for (std::size_t i = 1; i < 4; ++i) if (pole(points[i])) return false;
        if (pole(points.front())) points.front().right_ascension_deg = points[1].right_ascension_deg;
        if (pole(points.back())) points.back().right_ascension_deg = points[3].right_ascension_deg;
        std::array<double, 5> x{};
        for (std::size_t i = 1; i < points.size(); ++i) {
            const double dx = span(points[i - 1].right_ascension_deg, points[i].right_ascension_deg);
            if (std::abs(dx) >= 90) return false;
            x[i] = x[i - 1] + dx;
        }
        if (std::abs(x.back()) >= 180) return false;
        for (std::size_t i = 1; i < 4; ++i) {
            const double t = static_cast<double>(i) / 4;
            const double dx = (x[i] - t * x.back()) * viewport_.zoom * width_ / 360;
            const double dy = (points[i].declination_deg - ((1 - t) * points.front().declination_deg
                + t * points.back().declination_deg)) * viewport_.zoom * height_ / 180;
            if (std::hypot(dx, dy) > limits_.screen_tolerance) return false;
        }
        return true;
    }
    void subdivide(double a, double b, EquatorialCoordinates first, EquatorialCoordinates middle,
        EquatorialCoordinates last, unsigned depth) {
        if (result_.evaluations > limits_.max_evaluations - 2) { ++result_.omitted_intervals; return; }
        const double m = (a + b) / 2;
        std::array<EquatorialCoordinates, 5> points{{first, sample((a + m) / 2), middle, sample((m + b) / 2), last}};
        if (std::all_of(points.begin(), points.end(), [&](auto p) {
            return pole(p) && p.declination_deg * first.declination_deg > 0;
        })) return;
        const double interval_span = source_span(a, b);
        if (frame_) {
            if (horizon_interval_outside(points, horizon_viewport_, width_, height_, interval_span)) return;
            if (horizon_viewport_.perspective_blend > 0) {
                const auto decision = project_morph_interval(points, horizon_viewport_, width_, height_, interval_span, limits_, result_);
                if (decision != HorizonMorphDecision::subdivide) return;
                if (depth == limits_.max_depth || horizon_interval_small(interval_span, horizon_viewport_, width_, height_)
                    || horizon_morph_subpixel(points, horizon_viewport_, width_, height_, interval_span, limits_.screen_tolerance)) {
                    ++result_.omitted_intervals;
                    return;
                }
                pending_.push_back({a, m, first, points[1], middle, depth + 1});
                pending_.push_back({m, b, middle, points[3], last, depth + 1});
                return;
            }
        }
        auto adjusted = points;
        if (accepted(adjusted, interval_span)) {
            const SkyViewport projected_viewport = frame_ ? SkyViewport{0, 0, viewport_.zoom} : viewport_;
            const auto projected = project_sky_segment(adjusted.front(), adjusted.back(), projected_viewport, width_, height_);
            result_.segments.insert(result_.segments.end(), projected.begin(), projected.end());
        } else if (depth == limits_.max_depth) ++result_.omitted_intervals;
        else {
            pending_.push_back({a, m, first, points[1], middle, depth + 1});
            pending_.push_back({m, b, middle, points[3], last, depth + 1});
        }
    }
    struct Interval {
        double a, b;
        EquatorialCoordinates first, middle, last;
        unsigned depth;
    };
    std::deque<Interval> pending_;
    Vec3 start_, end_;
    const ObservationFrame* frame_;
    SkyViewport viewport_;
    HorizonProjectionViewport horizon_viewport_;
    double width_, height_, cross_length_;
    HorizonSamplingLimits limits_;
    HorizonSegmentProjection result_;
};
HorizonSegmentProjection project(Vec3 start, Vec3 end, const ObservationFrame* frame,
    SkyViewport viewport, HorizonProjectionViewport horizon_viewport,
    double width, double height, HorizonSamplingLimits limits) {
    if (!std::isfinite(viewport.center_ra_deg) || !std::isfinite(viewport.center_dec_deg)
        || std::abs(viewport.center_dec_deg) > 90 || !std::isfinite(viewport.zoom) || viewport.zoom < 1
        || (!frame && viewport.zoom > 180)
        || !std::isfinite(viewport.perspective_blend) || viewport.perspective_blend < 0 || viewport.perspective_blend > 1
        || !std::isfinite(width) || width <= 0 || !std::isfinite(height) || height <= 0
        || !std::isfinite(width * viewport.zoom) || !std::isfinite(height * viewport.zoom)
        || !std::isfinite(limits.max_source_step_deg) || limits.max_source_step_deg <= 0 || limits.max_source_step_deg > 2
        || !std::isfinite(limits.screen_tolerance) || limits.screen_tolerance <= 0 || limits.screen_tolerance > 4
        || limits.max_evaluations < 5 || limits.max_evaluations > 1048577 || limits.max_depth < 1 || limits.max_depth > 52)
        throw std::invalid_argument("invalid CAB projection parameters");
    return Sampler(start, end, frame, viewport, horizon_viewport, width, height, limits).run();
}
}
HorizonSegmentProjection project_sky_constellation_art_segment(Vec3 start, Vec3 end,
    const SkyViewport& viewport, double width, double height, HorizonSamplingLimits limits) {
    return project(start, end, nullptr, viewport, {}, width, height, limits);
}
HorizonSegmentProjection project_horizon_constellation_art_segment(Vec3 start, Vec3 end,
    const ObservationFrame& frame, const HorizonViewport& viewport,
    double width, double height, HorizonSamplingLimits limits) {
    if (!std::isfinite(viewport.center_azimuth_deg) || !std::isfinite(viewport.center_altitude_deg)
        || std::abs(viewport.center_altitude_deg) > 90 || !std::isfinite(viewport.vertical_fov_deg)
        || viewport.vertical_fov_deg <= 0 || viewport.vertical_fov_deg > 180
        || !std::isfinite(viewport.perspective_fov_deg) || viewport.perspective_fov_deg <= 0 || viewport.perspective_fov_deg > 90
        || !std::isfinite(viewport.perspective_blend) || viewport.perspective_blend < 0
        || viewport.perspective_blend > 1 || !std::isfinite(viewport.roll_deg))
        throw std::invalid_argument("invalid CAB projection parameters");
    const HorizonProjectionViewport horizon_viewport{360 - viewport.center_azimuth_deg,
        viewport.center_altitude_deg, viewport.vertical_fov_deg, viewport.perspective_blend, viewport.roll_deg, viewport.perspective_fov_deg};
    const SkyViewport sky_viewport{0, 0, 180 / std::max(viewport.vertical_fov_deg, 1e-9)};
    return project(start, end, &frame, sky_viewport, horizon_viewport, width, height, limits);
}
}
