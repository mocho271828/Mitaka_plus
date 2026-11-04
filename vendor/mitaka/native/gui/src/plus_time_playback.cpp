#include "plus_time_playback.hpp"
#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {

std::int32_t plus_time_speed(double value) {
    const double truncated = std::trunc(value);
    if (!std::isfinite(value) || truncated < std::numeric_limits<std::int32_t>::min() ||
        truncated > std::numeric_limits<std::int32_t>::max())
        throw std::invalid_argument("Plus time: speed must fit a signed 32-bit integer");
    return static_cast<std::int32_t>(truncated);
}

double plus_time_rate(const PlusTimeState& state) {
    const double rate = state.step.value_days() * state.speed * 86400.0;
    if (!std::isfinite(rate)) throw std::invalid_argument("Plus time: playback rate overflow");
    return rate;
}

} // namespace mitaka::gui
