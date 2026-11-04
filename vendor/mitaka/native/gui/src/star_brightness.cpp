#include "star_brightness.hpp"
#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double pi = 3.141592653589793238462643383279502884;
constexpr double maximum_radius = 32;

void validate_clock(double now) {
    if (!std::isfinite(now)) throw std::invalid_argument("star brightness clock must be finite");
}
}

float checked_star_brightness(double value) {
    if (!std::isfinite(value) || value <= 0 || value > std::numeric_limits<float>::max())
        throw std::invalid_argument("star brightness must be a positive finite float");
    const float rounded = static_cast<float>(value);
    if (rounded <= 0) throw std::invalid_argument("star brightness rounds to zero");
    return rounded;
}

float brighter_star_brightness(float value) {
    // 旧呼出しの exponent は float。積は検証してから float へ戻す。
    return checked_star_brightness(static_cast<double>(checked_star_brightness(value)) *
        std::pow(10.0f, -0.2f));
}

float darker_star_brightness(float value) {
    return checked_star_brightness(static_cast<double>(checked_star_brightness(value)) *
        std::pow(10.0f, 0.2f));
}

StarPointAppearance star_point_appearance(double magnitude, float brightness) {
    checked_star_brightness(brightness);
    if (!std::isfinite(magnitude)) throw std::invalid_argument("star magnitude must be finite");
    const double radius = std::clamp(2.8 - magnitude * 0.32, 0.55, 3.6);
    const double scaled_opacity = std::clamp(1.2 - magnitude * 0.07, 0.3, 1.0) /
        static_cast<double>(brightness);
    return {std::min(maximum_radius, radius * std::sqrt(std::max(1.0, scaled_opacity))),
        std::min(1.0, scaled_opacity)};
}

bool StarBrightnessTransition::begin(float current, double target, double duration_seconds, double now) {
    const float start = checked_star_brightness(current);
    const float end = checked_star_brightness(target);
    if (!std::isfinite(duration_seconds) || duration_seconds < 0)
        throw std::invalid_argument("star brightness duration must be finite and nonnegative");
    validate_clock(now);
    if (start == end) return false;
    from_ = start;
    target_ = end;
    duration_ = duration_seconds;
    started_ = sampled_ = now;
    active_ = true;
    return true;
}

std::optional<float> StarBrightnessTransition::sample(double now) {
    validate_clock(now);
    if (!active_) return std::nullopt;
    if (now < sampled_) throw std::invalid_argument("star brightness clock moved backwards");
    const double elapsed = now - started_;
    if (duration_ == 0 || elapsed >= duration_) {
        active_ = false;
        sampled_ = now;
        return target_;
    }
    const double weight = 0.5 - 0.5 * std::cos(pi * (elapsed / duration_));
    // 凸結合なら極端な正の端点でも有限・正値を保てる。
    const float value = checked_star_brightness((1 - weight) * from_ + weight * target_);
    sampled_ = now;
    return value;
}
} // namespace mitaka::gui
