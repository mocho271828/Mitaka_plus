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
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template <typename Operation> void rejects(Operation operation) {
    bool rejected = false;
    try { operation(); } catch (const std::exception&) { rejected = true; }
    check(rejected, "invalid calendar input was accepted");
}
void equal_date(double actual, GregorianDateTime expected, int offset = 0) {
    check(std::abs(actual - julian_date_at_offset(expected, offset)) < 1e-9,
          "calendar date did not match expected date");
}

void test_month_grid() {
    const auto january = calendar_month(2000, 1);
    check(january.first_weekday == 6 && january.days[5] == 0 && january.days[6] == 1 &&
          january.days[36] == 31 && january.days[37] == 0, "January 2000 weekday grid is incorrect");
    check(calendar_month(1970, 1).first_weekday == 4, "Unix epoch was not placed on Thursday");
    for (const auto& example : std::array<std::array<int, 3>, 6>{{
             {{2024, 2, 29}}, {{1900, 2, 28}}, {{2000, 2, 29}},
             {{0, 2, 29}}, {{-1, 2, 28}}, {{1582, 10, 31}}}}) {
        const auto month = calendar_month(example[0], example[1]);
        for (int index = 0; index < 42; ++index) {
            const int day = index - month.first_weekday + 1;
            check(month.days[index] == (day >= 1 && day <= example[2] ? day : 0),
                  "month grid omitted a proleptic Gregorian day or populated a blank cell");
        }
        check(month.previous_enabled && month.next_enabled, "interior month navigation is disabled");
    }
    const auto first = calendar_month(-4712, 1);
    const auto last = calendar_month(9999, 12);
    check(!first.previous_enabled && first.next_enabled, "first supported month navigation is incorrect");
    check(last.previous_enabled && !last.next_enabled && last.days[last.first_weekday + 30] == 31,
          "last supported month cannot be displayed without crossing the calendar limit");
    for (const auto& invalid : std::array<std::array<int, 2>, 4>{{
             {{-4713, 1}}, {{10000, 1}}, {{2024, 0}}, {{2024, 13}}}})
        rejects([&] { calendar_month(invalid[0], invalid[1]); });
}

void test_fixed_steps() {
    constexpr std::array<int, 6> intervals{{10, 60, 600, 3600, 86400, 604800}};
    const double jd = julian_date({2024, 2, 29, 23, 59, 59.25});
    for (std::size_t i = 0; i < intervals.size(); ++i) {
        TimeSettings settings{static_cast<TimeStep>(i), 3600, 345};
        for (int direction : {-1, 1}) {
            const double stepped = step_julian_date(jd, settings, direction);
            check(std::abs((stepped - jd) * 86400 - direction * intervals[i]) < 0.00005,
                  "fixed step interval mismatch");
            check(std::abs(step_julian_date(stepped, settings, -direction) - jd) < 1e-9,
                  "fixed step round trip mismatch");
        }
    }
    for (int seconds : {1, 123, 2592000}) {
        TimeSettings settings{TimeStep::custom, seconds, -840};
        check(std::abs((step_julian_date(jd, settings, -1) - jd) * 86400 + seconds) < 0.00005,
              "custom step mismatch");
    }
}

void test_calendar_steps() {
    TimeSettings settings{TimeStep::month, 3600, 0};
    equal_date(step_julian_date(julian_date({2024, 1, 31, 12, 34, 56.25}), settings, 1),
               {2024, 2, 29, 12, 34, 56.25});
    equal_date(step_julian_date(julian_date({2023, 3, 31, 0, 0, 0}), settings, -1), {2023, 2, 28, 0, 0, 0});
    equal_date(step_julian_date(julian_date({2024, 12, 31, 0, 0, 0}), settings, 1), {2025, 1, 31, 0, 0, 0});
    equal_date(step_julian_date(julian_date({0, 1, 31, 0, 0, 0}), settings, -1), {-1, 12, 31, 0, 0, 0});
    equal_date(step_julian_date(julian_date({-1, 12, 31, 0, 0, 0}), settings, 1), {0, 1, 31, 0, 0, 0});
    settings.step = TimeStep::year;
    equal_date(step_julian_date(julian_date({2024, 2, 29, 0, 0, 0}), settings, 1), {2025, 2, 28, 0, 0, 0});
    equal_date(step_julian_date(julian_date({0, 2, 29, 0, 0, 0}), settings, -1), {-1, 2, 28, 0, 0, 0});
    settings.step = TimeStep::ten_years;
    equal_date(step_julian_date(julian_date({2024, 2, 29, 0, 0, 0}), settings, -1), {2014, 2, 28, 0, 0, 0});
    settings.step = TimeStep::hundred_years;
    equal_date(step_julian_date(julian_date({2000, 2, 29, 0, 0, 0}), settings, 1), {2100, 2, 28, 0, 0, 0});
    equal_date(step_julian_date(julian_date({1900, 3, 1, 0, 0, 0}), settings, -1), {1800, 3, 1, 0, 0, 0});
    settings = {TimeStep::month, 3600, 540};
    equal_date(step_julian_date(julian_date({2024, 1, 30, 20, 0, 0}), settings, 1), {2024, 2, 29, 5, 0, 0}, 540);
}

void test_offsets_and_rejection() {
    const GregorianDateTime local{2024, 1, 1, 0, 0, 0};
    const double utc = julian_date({2023, 12, 31, 15, 0, 0});
    equal_date(julian_date_at_offset(local, 540), {2023, 12, 31, 15, 0, 0});
    const auto converted = calendar_at_offset(utc, 540);
    check(converted.year == 2024 && converted.month == 1 && converted.day == 1 && converted.hour == 0,
          "fixed offset did not cross year boundary");
    for (int offset : {-840, -345, 0, 345, 840})
        check(std::abs(julian_date_at_offset(calendar_at_offset(utc, offset), offset) - utc) < 1e-9,
              "offset round trip mismatch");
    for (int offset : {-841, 841}) {
        rejects([&] { calendar_at_offset(utc, offset); });
        rejects([&] { julian_date_at_offset(local, offset); });
    }
    for (double value : {std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()})
        rejects([&] { step_julian_date(value, {}, 1); });
    for (int step : {-1, 11})
        rejects([&] { validate_time_settings({static_cast<TimeStep>(step), 3600, 0}); });
    for (int seconds : {0, -1, 2592001})
        rejects([&] { validate_time_settings({TimeStep::custom, seconds, 0}); });
    for (int direction : {0, -2, 2})
        rejects([&] { step_julian_date(utc, {}, direction); });
    rejects([&] { julian_date_at_offset({2023, 2, 29, 0, 0, 0}, 0); });
    rejects([&] { julian_date_at_offset({2024, 1, 1, 24, 0, 0}, 0); });
    rejects([&] { julian_date_at_offset({2024, 1, 1, 0, 0, 60}, 0); });
    const double earliest = julian_date({-4712, 1, 1, 0, 0, 0});
    rejects([&] { step_julian_date(earliest, {}, -1); });
    rejects([&] { calendar_at_offset(earliest, -1); });
    rejects([&] { julian_date_at_offset({-4712, 1, 1, 0, 0, 0}, 1); });
    rejects([&] { step_julian_date(julian_date({9999, 12, 31, 0, 0, 0}), {TimeStep::year, 3600, 0}, 1); });
    rejects([&] { step_julian_date(earliest, {TimeStep::month, 3600, 0}, -1); });
}
}

int main() {
    try {
        test_fixed_steps();
        test_month_grid();
        test_calendar_steps();
        test_offsets_and_rejection();
        std::cout << "Calendar time tests passed: " << checks << " checks\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Calendar time test failed: " << error.what() << '\n';
        return 1;
    }
}
