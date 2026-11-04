#include "plus_time_animation.hpp"
#include "mitaka/astronomy.hpp"
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double pi = 3.141592653589793238462643383279502884;

void require_finite_seconds(double seconds) {
    if (!std::isfinite(seconds))
        throw std::invalid_argument("Plus time animation: seconds must be finite");
}
}

bool PlusTimeAnimation::start(double current_jd, double target_jd, double duration_seconds,
                              double now_seconds, PlusTimeAnimationCurve curve,
                              PlusTimeAnimationSameTarget same_target) {
    (void)gregorian_date_time(current_jd);
    (void)gregorian_date_time(target_jd);
    require_finite_seconds(duration_seconds);
    require_finite_seconds(now_seconds);
    if (curve != PlusTimeAnimationCurve::half_cosine && curve != PlusTimeAnimationCurve::linear)
        throw std::invalid_argument("Plus time animation: unknown curve");
    if (same_target != PlusTimeAnimationSameTarget::preserve && same_target != PlusTimeAnimationSameTarget::replace)
        throw std::invalid_argument("Plus time animation: unknown same-target policy");
    if (same_target == PlusTimeAnimationSameTarget::preserve && current_jd == target_jd) return false;
    state_ = State{current_jd, target_jd, duration_seconds, now_seconds, curve};
    return true;
}

std::optional<PlusTimeAnimationSample> PlusTimeAnimation::sample(double now_seconds) const {
    require_finite_seconds(now_seconds);
    if (!state_) return std::nullopt;
    const auto& state = *state_;
    // 原版は duration 0 を経過時刻より先に判定し、除去 queue には入れない。
    if (state.duration_seconds == 0) return PlusTimeAnimationSample{state.target_jd, false};
    if (now_seconds < state.start_seconds) return PlusTimeAnimationSample{state.current_jd, false};
    const double elapsed = now_seconds - state.start_seconds;
    if (elapsed > state.duration_seconds) return PlusTimeAnimationSample{state.target_jd, true};
    const double progress = elapsed / state.duration_seconds;
    // 端点では補間式による丸めを挟まない。負 duration は上の超過分岐に入る。
    if (progress == 1) return PlusTimeAnimationSample{state.target_jd, false};
    if (progress == 0) return PlusTimeAnimationSample{state.current_jd, false};
    const double weight = state.curve == PlusTimeAnimationCurve::half_cosine ?
        0.5 - 0.5 * std::cos(pi * progress) : progress;
    const double result = state.current_jd + weight * (state.target_jd - state.current_jd);
    (void)gregorian_date_time(result);
    return PlusTimeAnimationSample{result, false};
}

} // namespace mitaka::gui
