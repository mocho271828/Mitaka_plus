#include "playback_clock.hpp"

#include <cmath>
#include <stdexcept>

namespace mitaka::gui {

void PlaybackClock::start(double julian_date, std::pair<double, double> range,
                          double monotonic_seconds) {
    if (playing_) throw std::logic_error("playback: already playing");
    if (!std::isfinite(julian_date) || !std::isfinite(range.first) ||
        !std::isfinite(range.second) || !std::isfinite(monotonic_seconds)) {
        throw std::invalid_argument("playback: non-finite start argument");
    }
    if (range.first >= range.second) throw std::invalid_argument("playback: invalid time range");
    if (julian_date < range.first || julian_date > range.second ||
        (rate_ > 0 && julian_date == range.second) ||
        (rate_ < 0 && julian_date == range.first)) {
        throw std::out_of_range("playback: start Julian date outside directional playback range");
    }
    anchor_jd_ = julian_date;
    anchor_seconds_ = monotonic_seconds;
    range_begin_ = range.first;
    range_end_ = range.second;
    previous_seconds_ = monotonic_seconds;
    previous_jd_ = julian_date;
    playing_ = true;
}

void PlaybackClock::stop() noexcept { playing_ = false; }

void PlaybackClock::set_rate(double simulation_seconds_per_second) {
    if (playing_) throw std::logic_error("playback: stop before changing rate");
    const double magnitude = std::abs(simulation_seconds_per_second);
    if (!std::isfinite(simulation_seconds_per_second) || magnitude < 1 || magnitude > 2592000) {
        throw std::invalid_argument("playback: rate magnitude must be in [1,2592000] seconds per second");
    }
    rate_ = simulation_seconds_per_second;
}

void PlaybackClock::set_plus_rate(double rate) {
    if (playing_) throw std::logic_error("playback: stop before changing rate");
    if (!std::isfinite(rate)) throw std::invalid_argument("playback: Plus rate must be finite");
    rate_ = rate;
}

PlaybackSample PlaybackClock::sample(double monotonic_seconds) {
    if (!std::isfinite(monotonic_seconds)) throw std::invalid_argument("playback: non-finite clock");
    if (!playing_) throw std::logic_error("playback: sample requires active playback");
    // スリープ復帰や別の時計を渡した場合は、巨大な経過を JD へ変換する前に止める。
    if (monotonic_seconds < previous_seconds_ || monotonic_seconds - previous_seconds_ > 1.0) {
        playing_ = false;
        return {previous_jd_, PlaybackEvent::interrupted};
    }

    const double elapsed = monotonic_seconds - anchor_seconds_;
    // 各フレームの微小な加算を避け、JD の丸め未満の進みも開始時から積算する。
    const double next_jd = std::fma(elapsed, rate_ / 86400.0, anchor_jd_);
    if ((rate_ > 0 && next_jd >= range_end_) || (rate_ < 0 && next_jd <= range_begin_)) {
        previous_jd_ = rate_ > 0 ? range_end_ : range_begin_;
        previous_seconds_ = monotonic_seconds;
        playing_ = false;
        return {previous_jd_, PlaybackEvent::end_of_range};
    }
    previous_jd_ = next_jd;
    previous_seconds_ = monotonic_seconds;
    return {next_jd, PlaybackEvent::advanced};
}

} // namespace mitaka::gui
