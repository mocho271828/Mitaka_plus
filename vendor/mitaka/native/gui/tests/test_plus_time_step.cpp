#include "plus_time_step.hpp"
#include "plus_time_playback.hpp"
#include "calendar_time.hpp"
#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
int checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template <typename Error, typename Operation> void rejects(Operation operation) {
    bool rejected = false;
    try { operation(); } catch (const Error&) { rejected = true; }
    check(rejected, "invalid Plus time input was accepted");
}
void equal_date(double actual, const GregorianDateTime& expected) {
    check(std::abs(actual - julian_date(expected)) <= 1e-9, "Plus step produced an unexpected calendar date");
}

void test_registration_and_value() {
    const std::array<PlusTimeStep, 12> steps{{
        PlusTimeStep::second, PlusTimeStep::ten_seconds, PlusTimeStep::minute,
        PlusTimeStep::ten_minutes, PlusTimeStep::hour, PlusTimeStep::day,
        PlusTimeStep::week, PlusTimeStep::month, PlusTimeStep::year,
        PlusTimeStep::ten_years, PlusTimeStep::hundred_years, PlusTimeStep::value
    }};
    const std::array<double, 12> seconds{{1, 10, 60, 600, 3600, 86400, 604800,
                                        2678400, 31536000, 315360000, 3153600000, 0}};
    for (std::size_t index = 0; index < steps.size(); ++index) {
        check(static_cast<int>(steps[index]) == static_cast<int>(index), "Plus step registration value changed");
        const PlusTimeStepState state(steps[index]);
        check(state.step() == steps[index] && state.value_days() == seconds[index] / 86400,
              "Plus step duration differs from the original table");
    }
    PlusTimeStepState state(PlusTimeStep::hour);
    const double jd = julian_date({2024, 1, 2, 0, 0, 0});
    for (double days : {-1.25, -0.0, 0.0, 0.5, 1.25}) {
        state.set_value_days(days);
        check(state.step() == PlusTimeStep::value && state.value_days() == days,
              "custom days did not select VALUE or changed the supplied value");
        for (int direction : {-1, 1})
            check(state.stepped_julian_date(jd, direction) == jd + direction * days,
                  "custom value was converted to seconds or lost its sign");
    }
    state.select(PlusTimeStep::value);
    check(state.value_days() == 0 && state.stepped_julian_date(jd, 1) == jd,
          "selecting VALUE retained an earlier custom value");
    state.set_value_days(0.5);
    state.select(PlusTimeStep::month);
    check(state.value_days() == 31, "selecting a predefined step retained a custom duration");
    // 連続再生用の 31 日と、月の成分を変える 1 step は同じ演算ではない。
    equal_date(state.stepped_julian_date(jd, 1), {2024, 2, 2, 0, 0, 0});
    const double february = julian_date({2024, 2, 2, 0, 0, 0});
    equal_date(state.stepped_julian_date(february, 1), {2024, 3, 2, 0, 0, 0});
    check(state.stepped_julian_date(february, 1) != february + state.value_days(),
          "one calendar step was replaced by the continuous-playback duration");
}

void test_navigation() {
    PlusTimeStepState state(PlusTimeStep::second);
    state.previous();
    check(state.step() == PlusTimeStep::second, "previous escaped the smallest step");
    state.next();
    check(state.step() == PlusTimeStep::ten_seconds && state.value_days() == 1.0 / 86400,
          "next skipped ten seconds or recalculated the stored value");
    state.select(PlusTimeStep::month);
    state.previous();
    check(state.step() == PlusTimeStep::week && state.value_days() == 31,
          "previous recalculated the stored step value");
    const double january = julian_date({2024, 1, 1, 0, 0, 0});
    equal_date(state.stepped_julian_date(january, 1), {2024, 1, 8, 0, 0, 0});
    equal_date(state.stepped_julian_date(january, -1), {2023, 12, 25, 0, 0, 0});
    for (auto step : {PlusTimeStep::year, PlusTimeStep::ten_years,
                      PlusTimeStep::hundred_years, PlusTimeStep::value}) {
        state.select(step);
        const double saved_days = state.value_days();
        state.next();
        check(state.step() == PlusTimeStep::ten_years && state.value_days() == saved_days,
              "next differs from the original ceiling or recalculated the stored value");
    }
    state.set_value_days(-0.25);
    state.previous();
    check(state.step() == PlusTimeStep::hundred_years && state.value_days() == -0.25,
          "previous from VALUE did not reach a hundred years");
}

void test_fixed_steps() {
    const std::array<double, 7> seconds{{1, 10, 60, 600, 3600, 86400, 604800}};
    const double jd = julian_date({2024, 2, 29, 23, 59, 59.25});
    for (std::size_t index = 0; index < seconds.size(); ++index) {
        const PlusTimeStepState state(static_cast<PlusTimeStep>(index));
        for (int direction : {-1, 1}) {
            const double moved = state.stepped_julian_date(jd, direction);
            check(std::abs((moved - jd) * 86400 - direction * seconds[index]) < 0.00005,
                  "fixed step interval is incorrect");
            check(std::abs(state.stepped_julian_date(moved, -direction) - jd) <= 1e-9,
                  "fixed step round trip is incorrect");
        }
    }
    equal_date(PlusTimeStepState(PlusTimeStep::second).stepped_julian_date(jd, 1), {2024, 3, 1, 0, 0, 0.25});
}

void test_calendar_rollover() {
    struct Example { GregorianDateTime start, expected; PlusTimeStep step; int direction; };
    const std::array<Example, 14> examples{{
        {{2023, 1, 31, 12, 34, 56.25}, {2023, 3, 3, 12, 34, 56.25}, PlusTimeStep::month, 1},
        {{2024, 1, 31, 0, 0, 0}, {2024, 3, 2, 0, 0, 0}, PlusTimeStep::month, 1},
        {{2023, 3, 31, 0, 0, 0}, {2023, 3, 3, 0, 0, 0}, PlusTimeStep::month, -1},
        {{2024, 3, 31, 0, 0, 0}, {2024, 3, 2, 0, 0, 0}, PlusTimeStep::month, -1},
        {{2024, 12, 31, 0, 0, 0}, {2025, 1, 31, 0, 0, 0}, PlusTimeStep::month, 1},
        {{0, 1, 31, 0, 0, 0}, {-1, 12, 31, 0, 0, 0}, PlusTimeStep::month, -1},
        {{-1, 12, 31, 0, 0, 0}, {0, 1, 31, 0, 0, 0}, PlusTimeStep::month, 1},
        {{0, 1, 31, 0, 0, 0}, {0, 3, 2, 0, 0, 0}, PlusTimeStep::month, 1},
        {{2024, 2, 29, 0, 0, 0}, {2025, 3, 1, 0, 0, 0}, PlusTimeStep::year, 1},
        {{2024, 2, 29, 0, 0, 0}, {2023, 3, 1, 0, 0, 0}, PlusTimeStep::year, -1},
        {{0, 2, 29, 0, 0, 0}, {-1, 3, 1, 0, 0, 0}, PlusTimeStep::year, -1},
        {{2024, 2, 29, 0, 0, 0}, {2014, 3, 1, 0, 0, 0}, PlusTimeStep::ten_years, -1},
        {{2000, 2, 29, 0, 0, 0}, {2100, 3, 1, 0, 0, 0}, PlusTimeStep::hundred_years, 1},
        {{2000, 2, 29, 0, 0, 0}, {1900, 3, 1, 0, 0, 0}, PlusTimeStep::hundred_years, -1}
    }};
    for (const auto& example : examples)
        equal_date(PlusTimeStepState(example.step).stepped_julian_date(julian_date(example.start), example.direction),
                   example.expected);
    const PlusTimeStepState month(PlusTimeStep::month);
    const double january = julian_date({2023, 1, 31, 0, 0, 0});
    equal_date(month.stepped_julian_date(month.stepped_julian_date(january, 1), -1), {2023, 2, 3, 0, 0, 0});
    // 旧 Lua の繰り越しを追加しても、既存 UI の月末へ収める契約は変えない。
    equal_date(step_julian_date(january, {TimeStep::month, 3600, 0}, 1), {2023, 2, 28, 0, 0, 0});
}

void test_rejection_and_boundaries() {
    PlusTimeStepState state(PlusTimeStep::month);
    state.set_value_days(0.25);
    for (int invalid : {-1, 12, std::numeric_limits<int>::max()}) {
        rejects<std::invalid_argument>([&] { PlusTimeStepState bad(static_cast<PlusTimeStep>(invalid)); });
        rejects<std::invalid_argument>([&] { state.select(static_cast<PlusTimeStep>(invalid)); });
        check(state.step() == PlusTimeStep::value && state.value_days() == 0.25,
              "invalid step changed the previous state");
    }
    const double jd = julian_date({2024, 1, 1, 0, 0, 0});
    for (double invalid : {std::numeric_limits<double>::infinity(),
                           -std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()}) {
        rejects<std::invalid_argument>([&] { state.set_value_days(invalid); });
        rejects<std::invalid_argument>([&] { state.stepped_julian_date(invalid, 1); });
        check(state.step() == PlusTimeStep::value && state.value_days() == 0.25,
              "non-finite input changed the previous state");
    }
    for (int direction : {0, -2, 2, std::numeric_limits<int>::min()})
        rejects<std::invalid_argument>([&] { state.stepped_julian_date(jd, direction); });
    state.set_value_days(std::numeric_limits<double>::max());
    for (int direction : {-1, 1})
        rejects<std::out_of_range>([&] { state.stepped_julian_date(jd, direction); });
    const double first = julian_date({-4712, 1, 1, 0, 0, 0});
    const double last = julian_date({9999, 12, 31, 23, 59, 59});
    for (auto step : {PlusTimeStep::second, PlusTimeStep::month, PlusTimeStep::year,
                      PlusTimeStep::ten_years, PlusTimeStep::hundred_years}) {
        state.select(step);
        rejects<std::exception>([&] { state.stepped_julian_date(first, -1); });
        rejects<std::exception>([&] { state.stepped_julian_date(last, 1); });
    }
    state.select(PlusTimeStep::value);
    check(state.stepped_julian_date(first, 1) == first && state.stepped_julian_date(last, -1) == last,
          "zero custom step could not retain a valid boundary date");
    rejects<std::out_of_range>([&] { state.stepped_julian_date(first - 1, 1); });
    rejects<std::out_of_range>([&] { state.stepped_julian_date(last + 1, -1); });
}

void test_calendar_input_and_playback_state() {
    equal_date(plus_julian_date({2024, 2, 31, 0, 0, 0}), {2024, 3, 2, 0, 0, 0});
    equal_date(plus_julian_date({2024, 0, 0, 24, 60, 60}), {2023, 12, 1, 1, 1, 0});
    equal_date(plus_julian_date({2024, 13, 1, -1, -1, -1}), {2024, 12, 31, 22, 58, 59});
    for (const auto& invalid : std::array<GregorianDateTime, 9>{{
        {-4713,1,1,0,0,0}, {10000,1,1,0,0,0}, {2000,-129,1,0,0,0},
        {2000,1,128,0,0,0}, {2000,1,1,128,0,0}, {2000,1,1,0,-129,0},
        {2000,1,1,0,0,0.5}, {2000,1,1,0,0,2147483648.0},
        {2000,1,1,0,0,std::numeric_limits<double>::quiet_NaN()}}})
        rejects<std::invalid_argument>([&] { (void)plus_julian_date(invalid); });
    rejects<std::exception>([] { (void)plus_julian_date({9999,13,1,0,0,0}); });
    PlusTimeState state;
    state.step = PlusTimeStepState(PlusTimeStep::month, -0.25);
    check(state.step.step() == PlusTimeStep::month && state.step.value_days() == -0.25,
          "snapshot constructor changed independent step and value");
    state.speed = 2;
    check(plus_time_rate(state) == -43200, "continuous rate did not use stored days and signed speed");
    state.step.set_value_days(0);
    check(plus_time_rate(state) == 0 && state.speed == 2, "zero custom duration discarded nonzero speed");
    for (const auto& pair : std::array<std::pair<double, std::int32_t>, 8>{{
        {0,0}, {-0.9,0}, {0.9,0}, {2.9,2}, {-2.9,-2}, {2147483647.9,2147483647},
        {-2147483648.9, std::numeric_limits<std::int32_t>::min()}, {1,1}}})
        check(plus_time_speed(pair.first) == pair.second, "speed did not truncate toward zero to int32");
    for (double value : {2147483648.0, -2147483649.0, std::numeric_limits<double>::infinity(),
                         std::numeric_limits<double>::quiet_NaN()})
        rejects<std::invalid_argument>([&] { (void)plus_time_speed(value); });
    state.step.set_value_days(std::numeric_limits<double>::max());
    rejects<std::invalid_argument>([&] { (void)plus_time_rate(state); });
    state.speed = 0;
    check(plus_time_rate(state) == 0, "stopped finite custom value cannot be retained");
    rejects<std::invalid_argument>([] { PlusTimeStepState state(PlusTimeStep::day,
        std::numeric_limits<double>::infinity()); });
}
}

int main() {
    try {
        test_registration_and_value();
        test_navigation();
        test_fixed_steps();
        test_calendar_rollover();
        test_rejection_and_boundaries();
        test_calendar_input_and_playback_state();
        std::cout << "Plus time step tests passed: " << checks << " checks\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Plus time step test failed: " << error.what() << '\n';
        return 1;
    }
}
