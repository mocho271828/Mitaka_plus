#include "playback_clock.hpp"

#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka::gui;

int checks = 0;
constexpr double epoch = 2451545;
constexpr std::pair<double, double> range{epoch, epoch + 10000};

void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}

void near(double actual, double expected) {
    check(std::isfinite(actual) && std::abs(actual - expected) <= 1e-9, "numeric mismatch");
}

template<typename Exception, typename Function>
void rejects(Function operation) {
    ++checks;
    try { operation(); } catch (const Exception&) { return; }
    throw std::runtime_error("expected exception was not raised");
}

void test_initial_state_and_normal_progress() {
    PlaybackClock clock;
    check(!clock.is_playing(), "initially stopped");
    check(clock.rate() == 3600, "default is one simulated hour per second");
    static_assert(noexcept(clock.stop()));
    clock.stop();
    clock.stop();
    rejects<std::logic_error>([&] { clock.sample(0); });
    clock.start(epoch, range, 100);
    check(clock.is_playing(), "start begins playback");
    const auto unchanged = clock.sample(100);
    check(unchanged.event == PlaybackEvent::advanced && unchanged.julian_date == epoch,
          "same clock value is valid");
    const auto half = clock.sample(100.5);
    check(half.event == PlaybackEvent::advanced, "normal progress event");
    near(half.julian_date, epoch + 0.5 / 24);
    const auto next = clock.sample(101.5);
    check(next.event == PlaybackEvent::advanced, "exactly one second gap is allowed");
    near(next.julian_date, epoch + 1.5 / 24);
    clock.stop();
    check(!clock.is_playing() && clock.rate() == 3600, "stop retains rate");
}

void test_frame_independence() {
    for (double rate : std::array<double, 12>{1, 60, 3600, 86400, 864000, 2592000,
                                             -1, -60, -3600, -86400, -864000, -2592000}) {
        const double initial = rate > 0 ? range.first : range.second;
        PlaybackClock coarse;
        PlaybackClock fine;
        coarse.set_rate(rate);
        fine.set_rate(rate);
        coarse.start(initial, range, 0);
        fine.start(initial, range, 0);
        PlaybackSample coarse_result{};
        PlaybackSample fine_result{};
        for (int step = 1; step <= 10; ++step) coarse_result = coarse.sample(step);
        for (int step = 1; step <= 600; ++step) fine_result = fine.sample(step / 60.0);
        check(coarse_result.event == PlaybackEvent::advanced &&
              fine_result.event == PlaybackEvent::advanced, "both frame rates keep playing");
        check(coarse_result.julian_date == fine_result.julian_date,
              "same absolute time must not depend on frame count");
        near(coarse_result.julian_date, initial + 10 * (rate / 86400));
    }

    // JD の 1 ULP 未満の更新を多数行い、細かな進みが失われないことを確認する。
    PlaybackClock tiny_steps;
    PlaybackClock single_step;
    tiny_steps.set_rate(1);
    single_step.set_rate(1);
    tiny_steps.start(epoch, range, 0);
    single_step.start(epoch, range, 0);
    check(tiny_steps.sample(1e-6).julian_date == epoch, "sub-ULP JD may stay unchanged");
    double previous = epoch;
    for (int step = 2; step <= 10000; ++step) {
        const auto result = tiny_steps.sample(step / 1000000.0);
        check(result.event == PlaybackEvent::advanced && result.julian_date >= previous,
              "tiny samples stay monotonic");
        previous = result.julian_date;
    }
    check(previous > epoch, "small advances accumulate from the original anchor");
    check(previous == single_step.sample(0.01).julian_date, "tiny and direct updates agree");

    PlaybackClock large_origin;
    large_origin.set_rate(86400);
    large_origin.start(epoch, range, 1e9);
    near(large_origin.sample(1e9 + 0.25).julian_date, epoch + 0.25);
}

void test_rate_change_and_pause() {
    PlaybackClock clock;
    clock.start(epoch, range, 0);
    const double committed = clock.sample(0.5).julian_date;
    rejects<std::logic_error>([&] { clock.set_rate(86400); });
    check(clock.is_playing() && clock.rate() == 3600, "running rate change is atomic");
    clock.stop();
    clock.set_rate(86400);
    clock.start(committed, range, 0.5);
    check(clock.sample(0.5).julian_date == committed, "rate change reanchor has no jump");
    const double advanced = clock.sample(1).julian_date;
    near(advanced, committed + 0.5);
    clock.stop();
    rejects<std::logic_error>([&] { clock.sample(10000); });
    clock.start(advanced, range, 10000);
    check(clock.sample(10000).julian_date == advanced, "pause duration is not simulated");
    near(clock.sample(10000.5).julian_date, advanced + 0.5);
}

void test_interruptions() {
    PlaybackClock clock;
    clock.start(epoch, range, 0);
    auto result = clock.sample(std::nextafter(1.0, 2.0));
    check(result.event == PlaybackEvent::interrupted && result.julian_date == epoch,
          "gap just beyond one second interrupts at start JD");
    check(!clock.is_playing(), "interruption stops playback");
    rejects<std::logic_error>([&] { clock.sample(2); });

    clock.set_rate(86400);
    clock.start(epoch, {epoch, epoch + 0.5}, 0);
    const double last = clock.sample(0.25).julian_date;
    result = clock.sample(std::nextafter(1.25, 2.0));
    check(result.event == PlaybackEvent::interrupted && result.julian_date == last,
          "gap interruption preserves last JD even if elapsed time crosses range end");

    clock.start(epoch, range, 0);
    const double last_before_reverse = clock.sample(0.5).julian_date;
    result = clock.sample(0.4);
    check(result.event == PlaybackEvent::interrupted &&
          result.julian_date == last_before_reverse, "reverse since previous sample interrupts");
    clock.start(epoch, range, 0);
    result = clock.sample(-1);
    check(result.event == PlaybackEvent::interrupted && result.julian_date == epoch,
          "reverse before start interrupts");

    clock.start(epoch, range, -2);
    near(clock.sample(-1).julian_date, epoch + 1);
    clock.stop();
    const double largest = std::numeric_limits<double>::max();
    clock.start(epoch, range, -largest);
    result = clock.sample(-largest);
    check(result.event == PlaybackEvent::advanced && result.julian_date == epoch,
          "large finite clock origin is valid");
    result = clock.sample(largest);
    check(result.event == PlaybackEvent::interrupted && result.julian_date == epoch,
          "overflowing clock difference interrupts without changing JD");
}

void test_endpoints() {
    PlaybackClock clock;
    clock.set_rate(86400);
    clock.start(100, {100, 101}, 0);
    check(clock.sample(0.75).event == PlaybackEvent::advanced, "before end keeps playing");
    auto result = clock.sample(1);
    check(result.event == PlaybackEvent::end_of_range && result.julian_date == 101,
          "exact end returns exact boundary");
    check(!clock.is_playing(), "range end stops playback");
    rejects<std::logic_error>([&] { clock.sample(1); });

    clock.set_rate(2592000);
    clock.start(100, {100, 100.5}, 0);
    result = clock.sample(0.1);
    check(result.event == PlaybackEvent::end_of_range && result.julian_date == 100.5,
          "overshoot is clamped to exact boundary");

    const double narrow_end = std::nextafter(epoch, epoch + 1);
    clock.set_rate(1);
    clock.start(epoch, {epoch, narrow_end}, 0);
    result = clock.sample(1);
    check(result.event == PlaybackEvent::end_of_range && result.julian_date == narrow_end,
          "one ULP range is clamped exactly");
    clock.start(std::nextafter(101.0, 100.0), {100, 101}, 0);
    result = clock.sample(1);
    check(result.event == PlaybackEvent::end_of_range && result.julian_date == 101,
          "nearest representable start below end is accepted");
}

void test_reverse_playback() {
    PlaybackClock clock;
    clock.set_rate(-86400);
    clock.start(101, {100, 101}, 0);
    near(clock.sample(0.25).julian_date, 100.75);
    const double before_change = clock.sample(0.5).julian_date;
    clock.stop();
    clock.set_rate(86400);
    clock.start(before_change, {100, 101}, 0.5);
    near(clock.sample(0.5).julian_date, before_change);
    near(clock.sample(0.75).julian_date, 100.75);
    clock.stop();

    clock.set_rate(-86400);
    clock.start(101, {100, 101}, 0);
    auto result = clock.sample(1);
    check(result.event == PlaybackEvent::end_of_range && result.julian_date == 100,
          "reverse playback reaches exact lower boundary");
    check(!clock.is_playing(), "lower range boundary stops reverse playback");
    rejects<std::out_of_range>([&] { clock.start(100, {100, 101}, 0); });
    rejects<std::out_of_range>([&] { clock.start(99, {100, 101}, 0); });
    rejects<std::out_of_range>([&] { clock.start(102, {100, 101}, 0); });

    clock.set_rate(-2592000);
    clock.start(100.5, {100, 100.5}, 0);
    result = clock.sample(0.1);
    check(result.event == PlaybackEvent::end_of_range && result.julian_date == 100,
          "reverse overshoot clamps to lower boundary");
    const double narrow_begin = std::nextafter(epoch, epoch - 1);
    clock.set_rate(-1);
    clock.start(epoch, {narrow_begin, epoch}, 0);
    result = clock.sample(1);
    check(result.event == PlaybackEvent::end_of_range && result.julian_date == narrow_begin,
          "one ULP reverse range clamps exactly");

    clock.start(epoch + 1, range, 0);
    const double committed = clock.sample(0.25).julian_date;
    result = clock.sample(2);
    check(result.event == PlaybackEvent::interrupted && result.julian_date == committed,
          "reverse gap interruption preserves last committed JD");
    clock.start(committed, range, 100);
    check(clock.sample(100).julian_date == committed, "reverse resume ignores pause duration");
    const double resumed = clock.sample(100.5).julian_date;
    check(resumed < committed, "reverse playback continues after resume");
    result = clock.sample(100.4);
    check(result.event == PlaybackEvent::interrupted && result.julian_date == resumed,
          "reverse playback still requires a forward monotonic clock");
}

void test_invalid_inputs_are_atomic() {
    PlaybackClock clock;
    const double infinity = std::numeric_limits<double>::infinity();
    const double nan = std::numeric_limits<double>::quiet_NaN();
    for (double rate : {0.0, -0.0, std::nextafter(1.0, 0.0), std::nextafter(-1.0, 0.0),
                        std::nextafter(2592000.0, infinity), std::nextafter(-2592000.0, -infinity),
                        infinity, -infinity, nan}) {
        rejects<std::invalid_argument>([&] { clock.set_rate(rate); });
        check(clock.rate() == 3600 && !clock.is_playing(), "invalid rate leaves state intact");
    }
    for (double value : {infinity, -infinity, nan}) {
        rejects<std::invalid_argument>([&] { clock.start(value, range, 0); });
        rejects<std::invalid_argument>([&] { clock.start(epoch, {value, range.second}, 0); });
        rejects<std::invalid_argument>([&] { clock.start(epoch, {range.first, value}, 0); });
        rejects<std::invalid_argument>([&] { clock.start(epoch, range, value); });
        check(clock.rate() == 3600 && !clock.is_playing(), "non-finite start leaves state intact");
    }
    rejects<std::invalid_argument>([&] { clock.start(epoch, {epoch, epoch}, 0); });
    rejects<std::invalid_argument>([&] { clock.start(epoch, {epoch + 1, epoch}, 0); });
    rejects<std::out_of_range>([&] { clock.start(range.first - 1, range, 0); });
    rejects<std::out_of_range>([&] { clock.start(range.second, range, 0); });
    rejects<std::out_of_range>([&] { clock.start(range.second + 1, range, 0); });
    check(!clock.is_playing() && clock.rate() == 3600, "invalid range/start is atomic");

    clock.start(epoch, range, 0);
    rejects<std::logic_error>([&] { clock.start(epoch + 5, range, 100); });
    for (double value : {infinity, -infinity, nan}) {
        rejects<std::invalid_argument>([&] { clock.sample(value); });
        check(clock.is_playing() && clock.rate() == 3600, "invalid sample retains running state");
    }
    const auto result = clock.sample(0.5);
    check(result.event == PlaybackEvent::advanced, "valid sample works after invalid operations");
    near(result.julian_date, epoch + 0.5 / 24);
}

void test_plus_rates() {
    PlaybackClock clock;
    clock.set_plus_rate(0);
    for (double start : {range.first, range.second}) {
        clock.start(start, range, 0);
        check(clock.sample(0.5).julian_date == start && clock.is_playing(),
              "zero custom playback must remain active without moving");
        rejects<std::logic_error>([&] { clock.set_plus_rate(1); });
        const auto gap = clock.sample(2);
        check(gap.event == PlaybackEvent::interrupted && gap.julian_date == start,
              "zero custom playback bypassed interruption handling");
    }
    for (double rate : {-0.5, 0.5, -1e12, 1e12}) {
        clock.set_plus_rate(rate);
        clock.start(epoch + 1, range, 0);
        const auto sample = clock.sample(0.5);
        if (std::abs(rate) < 1)
            check((sample.julian_date - epoch - 1) * rate > 0, "fractional Plus rate did not advance");
        else
            check(sample.event == PlaybackEvent::end_of_range && sample.julian_date ==
                (rate > 0 ? range.second : range.first), "large Plus rate did not clamp at range edge");
        clock.stop();
    }
    rejects<std::invalid_argument>([&] { clock.set_plus_rate(std::numeric_limits<double>::infinity()); });
    check(clock.rate() == 1e12, "invalid Plus rate changed state");
}
} // namespace

int main() {
    try {
        test_initial_state_and_normal_progress();
        test_frame_independence();
        test_rate_change_and_pause();
        test_interruptions();
        test_endpoints();
        test_reverse_playback();
        test_invalid_inputs_are_atomic();
        test_plus_rates();
        std::cout << "playback clock: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "playback clock: " << error.what() << '\n';
        return 1;
    }
}
