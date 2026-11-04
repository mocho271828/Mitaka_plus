#include "plus_time_animation.hpp"
#include "mitaka/astronomy.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
constexpr auto linear = PlusTimeAnimationCurve::linear;
constexpr auto cosine = PlusTimeAnimationCurve::half_cosine;
constexpr auto preserve = PlusTimeAnimationSameTarget::preserve;
constexpr auto replace = PlusTimeAnimationSameTarget::replace;
constexpr double jd = 2451545;
int checks = 0;

void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template <typename Error, typename Operation> void rejects(Operation operation) {
    bool rejected = false;
    try { operation(); } catch (const Error&) { rejected = true; }
    check(rejected, "invalid animation input was accepted");
}
PlusTimeAnimationSample at(const PlusTimeAnimation& animation, double now) {
    const auto result = animation.sample(now);
    check(result.has_value(), "active animation produced no sample");
    return *result;
}
void sample_is(const PlusTimeAnimation& animation, double now, double value, bool remove) {
    const auto result = at(animation, now);
    check(result.julian_date == value, "unexpected exact animation value");
    check(result.remove_after_dispatch == remove, "unexpected removal boundary");
}

void test_lifecycle() {
    PlusTimeAnimation animation;
    check(!animation.active() && !animation.sample(0), "new animation was active");
    animation.cancel();
    check(!animation.active(), "idle cancel changed state");
    check(animation.start(jd, jd + 4, 8, 10, linear, preserve), "new animation was skipped");
    sample_is(animation, 9, jd, false);
    sample_is(animation, 10, jd, false);
    sample_is(animation, 14, jd + 2, false);
    sample_is(animation, 18, jd + 4, false);
    sample_is(animation, std::nextafter(18.0, 19.0), jd + 4, true);
    check(animation.active(), "sampling removed animation before dispatch");
    sample_is(animation, 14, jd + 2, false);
    animation.cancel();
    check(!animation.active() && !animation.sample(20), "cancel retained animation");
    animation.cancel();
    check(!animation.active(), "repeated cancel restored animation");
}

void test_curves() {
    const long double pi = std::acos(-1.0L);
    for (const auto curve : {linear, cosine}) {
        for (double delta : {-100.0, 100.0}) {
            PlusTimeAnimation animation;
            check(animation.start(jd, jd + delta, 100, -50, curve, replace), "curve registration failed");
            double previous = jd;
            for (int tick = 0; tick <= 100; ++tick) {
                const long double progress = tick / 100.0L;
                const long double weight = curve == linear ? progress : (1 - std::cos(pi * progress)) / 2;
                const long double expected = jd + delta * weight;
                const auto result = at(animation, tick - 50);
                check(std::abs(static_cast<long double>(result.julian_date) - expected) <=
                      2 * std::numeric_limits<double>::epsilon() * std::abs(expected), "curve differs from independent oracle");
                check(!result.remove_after_dispatch, "curve removed at or before endpoint");
                check(delta > 0 ? result.julian_date >= previous : result.julian_date <= previous,
                      "curve reversed direction");
                previous = result.julian_date;
            }
            sample_is(animation, 50, jd + delta, false);
            sample_is(animation, 51, jd + delta, true);
        }
    }
    PlusTimeAnimation eased, straight;
    eased.start(jd, jd + 100, 4, 0, cosine, preserve);
    straight.start(jd, jd + 100, 4, 0, linear, preserve);
    check(at(eased, 1).julian_date < at(straight, 1).julian_date, "cosine did not ease in");
    check(at(eased, 3).julian_date > at(straight, 3).julian_date, "cosine did not ease out");
}

void test_duration_boundaries() {
    for (auto curve : {linear, cosine}) {
        for (double duration : {0.0, -0.0}) {
            PlusTimeAnimation animation;
            animation.start(jd, jd + 1, duration, 10, curve, preserve);
            for (double now : {-100.0, 10.0, 100.0, std::numeric_limits<double>::max()})
                sample_is(animation, now, jd + 1, false);
            check(animation.active(), "zero duration was removed automatically");
        }
        for (double duration : {-1.0, -std::numeric_limits<double>::denorm_min(),
                                 -std::numeric_limits<double>::max()}) {
            PlusTimeAnimation animation;
            animation.start(jd, jd - 1, duration, 10, curve, preserve);
            sample_is(animation, std::nextafter(10.0, 0.0), jd, false);
            sample_is(animation, 10, jd - 1, true);
            check(animation.active(), "negative duration removed before dispatch");
        }
    }
    PlusTimeAnimation animation;
    const double tiny = std::numeric_limits<double>::denorm_min();
    animation.start(jd, jd + 1, tiny, 0, linear, preserve);
    sample_is(animation, 0, jd, false);
    sample_is(animation, tiny, jd + 1, false);
    sample_is(animation, tiny * 2, jd + 1, true);
    const double huge = std::numeric_limits<double>::max();
    animation.start(jd, jd + 2, huge, 0, linear, preserve);
    sample_is(animation, huge / 2, jd + 1, false);
    sample_is(animation, huge, jd + 2, false);
    // 有限時計値同士の差が double を超えても、有限 duration の超過として終了する。
    animation.start(jd, jd + 2, huge, -huge, linear, preserve);
    sample_is(animation, huge, jd + 2, true);
    animation.start(jd, jd + 2, huge, huge, linear, preserve);
    sample_is(animation, -huge, jd, false);
}

void test_replacement() {
    PlusTimeAnimation animation;
    check(!animation.start(jd, jd, 1, 0, linear, preserve) && !animation.active(), "idle same-JD preserve registered");
    animation.start(jd, jd + 100, 100, 0, linear, preserve);
    check(!animation.start(jd + 25, jd + 25, 0, 25, cosine, preserve), "same-JD preserve replaced active animation");
    sample_is(animation, 50, jd + 50, false);
    check(animation.start(jd + 25, jd + 25, 0, 25, cosine, replace), "calendar same-JD replacement was skipped");
    sample_is(animation, 50, jd + 25, false);
    animation.start(jd, jd + 100, 100, 0, linear, preserve);
    const double current = at(animation, 25).julian_date;
    animation.start(current, jd - 25, 20, 25, linear, replace);
    sample_is(animation, 25, current, false);
    sample_is(animation, 35, jd, false);
    sample_is(animation, 45, jd - 25, false);
}

void test_validation_and_atomicity() {
    PlusTimeAnimation animation;
    animation.start(jd, jd + 8, 8, 10, linear, preserve);
    const auto unchanged = [&] {
        check(animation.active(), "invalid input removed existing animation");
        sample_is(animation, 12, jd + 2, false);
        sample_is(animation, 18, jd + 8, false);
    };
    for (double bad : {std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity(),
                       std::numeric_limits<double>::quiet_NaN()}) {
        rejects<std::invalid_argument>([&] { animation.start(bad, jd, 2, 0, cosine, replace); }); unchanged();
        rejects<std::invalid_argument>([&] { animation.start(jd, bad, 2, 0, cosine, replace); }); unchanged();
        rejects<std::invalid_argument>([&] { animation.start(jd, jd, bad, 0, cosine, preserve); }); unchanged();
        rejects<std::invalid_argument>([&] { animation.start(jd, jd, 2, bad, cosine, preserve); }); unchanged();
        rejects<std::invalid_argument>([&] { (void)animation.sample(bad); }); unchanged();
    }
    for (int bad : {-1, 2, std::numeric_limits<int>::max()}) {
        rejects<std::invalid_argument>([&] {
            animation.start(jd, jd, 2, 0, static_cast<PlusTimeAnimationCurve>(bad), preserve);
        }); unchanged();
        rejects<std::invalid_argument>([&] {
            animation.start(jd, jd, 2, 0, cosine, static_cast<PlusTimeAnimationSameTarget>(bad));
        }); unchanged();
    }
    const double first = julian_date({-4712,1,1,0,0,0});
    const double end = julian_date({9999,12,31,0,0,0}) + 1;
    for (double bad : {std::nextafter(first, -std::numeric_limits<double>::infinity()), end,
                       -std::numeric_limits<double>::max(), std::numeric_limits<double>::max()}) {
        rejects<std::out_of_range>([&] { animation.start(bad, jd, 2, 0, cosine, replace); }); unchanged();
        rejects<std::out_of_range>([&] { animation.start(jd, bad, 2, 0, cosine, replace); }); unchanged();
    }
    animation.cancel();
    rejects<std::invalid_argument>([&] { (void)animation.sample(std::numeric_limits<double>::quiet_NaN()); });
    check(!animation.active(), "invalid idle sample registered animation");
}

void test_calendar_boundaries() {
    const double first = julian_date({-4712,1,1,0,0,0});
    const double last = std::nextafter(julian_date({9999,12,31,0,0,0}) + 1, 0.0);
    for (auto curve : {linear, cosine}) {
        for (auto range : std::array<std::array<double, 2>, 4>{{
                {first, last}, {last, first}, {last, std::nextafter(last, 0.0)},
                {std::nextafter(first, last), first}}}) {
            PlusTimeAnimation animation;
            animation.start(range[0], range[1], 100, 0, curve, replace);
            for (int tick = 0; tick <= 100; ++tick) {
                const auto result = at(animation, tick);
                check(std::isfinite(result.julian_date) && result.julian_date >= std::min(range[0], range[1]) &&
                      result.julian_date <= std::max(range[0], range[1]), "interpolation escaped valid endpoint range");
                const auto date = gregorian_date_time(result.julian_date);
                check(date.year >= -4712 && date.year <= 9999, "interpolation escaped supported calendar");
            }
            sample_is(animation, 100, range[1], false);
        }
    }
}
}

int main() {
    try {
        test_lifecycle();
        test_curves();
        test_duration_boundaries();
        test_replacement();
        test_validation_and_atomicity();
        test_calendar_boundaries();
        std::cout << "Plus time animation tests passed: " << checks << " checks\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Plus time animation test failed: " << error.what() << '\n';
        return 1;
    }
}
