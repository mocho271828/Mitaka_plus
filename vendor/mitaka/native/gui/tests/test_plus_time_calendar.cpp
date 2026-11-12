#include "plus_time_calendar.hpp"
#include "plus_time_step.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdio>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <type_traits>

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
    check(rejected, "invalid Plus calendar input was accepted");
}
void same_jd(double actual, double expected) {
    check(actual == expected, "Plus calendar produced an unexpected Julian date");
}
void date_is(const GregorianDateTime& actual, const GregorianDateTime& expected) {
    check(actual.year == expected.year && actual.month == expected.month && actual.day == expected.day &&
          actual.hour == expected.hour && actual.minute == expected.minute && actual.second == expected.second,
          "Plus calendar produced unexpected components");
}

void test_strings() {
    struct Example { const char* input; GregorianDateTime expected; };
    const std::array<Example, 14> examples{{
        {"2000,1,2,3,4,5", {2000,1,2,3,4,5}},
        {"+2000,+1,+2,+3,+4,+5", {2000,1,2,3,4,5}},
        {" 2000,\t1,\n2,\r3,\f4,\v5", {2000,1,2,3,4,5}},
        {"0x7d0,01,02,03,04,05", {2000,1,2,3,4,5}},
        {"03720,0X1,0x2,0X3,0x4,0X5suffix", {2000,1,2,3,4,5}},
        {"-01,01,01,0,0,-0", {-1,1,1,0,0,0}},
        {"0,1,1,0,0,0 trailing text", {0,1,1,0,0,0}},
        {"2024,2,31,0,0,0,123", {2024,2,31,0,0,0}},
        {"2024,0,0,24,60,60", {2024,0,0,24,60,60}},
        {"2024,13,1,-1,-1,-1", {2024,13,1,-1,-1,-1}},
        {"2000,1,1,0,0,09", {2000,1,1,0,0,0}},
        {"2000,1,1,0,0,5.5", {2000,1,1,0,0,5}},
        {"2000,1,1,0,0,2147483647", {2000,1,1,0,0,2147483647.0}},
        {"2000,1,1,0,0,-0x80000000", {2000,1,1,0,0,-2147483648.0}}
    }};
    for (const auto& example : examples) {
        same_jd(plus_julian_date_from_string(example.input), plus_julian_date(example.expected));
        // 元の sscanf 書式を正常な int32 入力にだけ適用し、基数と区切りを照合する。
        std::array<int, 6> values{};
        check(std::sscanf(example.input, "%i,%i,%i,%i,%i,%i", &values[0], &values[1], &values[2],
                          &values[3], &values[4], &values[5]) == 6, "source format oracle rejected a valid fixture");
        same_jd(plus_julian_date_from_string(example.input), plus_julian_date({values[0], values[1], values[2],
                values[3], values[4], static_cast<double>(values[5])}));
    }
    for (int year : {-4712, -4000, -1, 0, 1, 1582, 2000, 9999}) {
        for (int month = 1; month <= 12; ++month) {
            const GregorianDateTime date{year,month,12,3,4,5.75};
            std::array<char, 100> formatted{};
            const int size = std::snprintf(formatted.data(), formatted.size(), "%i,%i,%i,%i,%i,%i",
                                            year, month, 12, 3, 4, 5);
            check(size > 0 && static_cast<std::size_t>(size) < formatted.size(), "format oracle overflow");
            const auto text = plus_time_string(julian_date(date));
            check(text == formatted.data(), "Plus date string format or second truncation changed");
            const double restored = plus_julian_date_from_string(text);
            same_jd(restored, plus_julian_date({year,month,12,3,4,5}));
            check(std::abs((julian_date(date) - restored) * 86400 - 0.75) < 0.0001,
                  "date string discarded more than its fractional second");
        }
    }
    check(plus_time_string(julian_date({0,1,1,0,0,0})) == "0,1,1,0,0,0", "astronomical year zero was reformatted");
    check(plus_time_string(julian_date({-4712,1,1,0,0,0})) == "-4712,1,1,0,0,0", "minimum year string failed");
}

void test_integer_seconds_roundtrip() {
    for (const auto& start : std::array<GregorianDateTime, 4>{{
             {2000,1,1,0,0,0}, {2024,2,29,23,59,0},
             {-1,12,31,23,59,0}, {9999,12,31,23,58,0}}}) {
        for (int second = 0; second < 60; ++second) {
            auto expected = start;
            expected.second = second;
            const double jd = plus_julian_date(expected);
            date_is(plus_local_time(jd, PlusTimeZone{0}), expected);
            same_jd(plus_julian_date_from_string(plus_time_string(jd)), jd);
            for (int offset : {-32400, 19800}) {
                if (start.year == 9999 && offset > 0) continue;
                const PlusTimeZone zone{offset};
                const auto local_jd = plus_local_julian_date(expected, zone);
                date_is(plus_local_time(local_jd, zone), expected);
            }
        }
    }
    check(plus_time_string(julian_date({2024,1,1,0,0,1.75})) == "2024,1,1,0,0,1",
          "fractional seconds must be truncated");
    check(plus_time_string(julian_date({2024,1,1,0,0,1.25})) == "2024,1,1,0,0,1",
          "fractional seconds must be truncated");
    check(plus_time_string(julian_date({2024,1,1,0,0,1.999})) == "2024,1,1,0,0,1",
          "fractional seconds outside the JD error bound must be truncated");
    date_is(plus_local_time(plus_local_julian_date({-4712,1,1,0,59,0}, PlusTimeZone{2147483647}),
                            PlusTimeZone{2147483647}), {-4712,1,1,0,59,0});
    date_is(plus_local_time(plus_local_julian_date({9999,12,31,23,59,59}, PlusTimeZone{-32400}),
                            PlusTimeZone{-32400}), {9999,12,31,23,59,59});
    check(plus_time_string(std::nextafter(5373484.5, 0.0)) == "9999,12,31,23,59,59",
          "last representable JD must remain in range");
}

void test_string_rejections() {
    const std::array<const char*, 27> invalid{{
        "", " ", "2000", "2000,1,1,0,0", "2000,1,1,0,0,", "2000,1,1,0,0,+",
        "2000 1,1,0,0,0", "2000 ,1,1,0,0,0", "2000,1 ,1,0,0,0", "2000,,1,0,0,0",
        "2000,1,1,0,0,--1", "2000,1,1,0,0,+-1", "2000,1,1,0,0,0x", "2000,1,1,0,0,NaN",
        "2000,09,1,0,0,0", "2000,1.0,1,0,0,0", "2000,1,1,0,0,2147483648",
        "2000,1,1,0,0,-2147483649", "2000,1,1,0,0,0x100000000", "2147483648,1,1,0,0,0",
        "10000,1,1,0,0,0", "-4713,1,1,0,0,0", "2000,128,1,0,0,0", "2000,1,-129,0,0,0",
        "2000,1,1,128,0,0", "2000,1,1,0,-129,0", "２０００,1,1,0,0,0"
    }};
    for (const char* text : invalid)
        rejects<std::invalid_argument>([&] { (void)plus_julian_date_from_string(text); });
    const std::string embedded = std::string("2000,1,1,0,0,0") + '\0' + "suffix";
    rejects<std::invalid_argument>([&] { (void)plus_julian_date_from_string(embedded); });
    rejects<std::invalid_argument>([] { (void)plus_julian_date_from_string("9999,13,1,0,0,0"); });
    rejects<std::out_of_range>([] { (void)plus_julian_date_from_string("-4712,1,0,0,0,0"); });
    // 長い数字も scanf に渡さず、from_chars の overflow 診断で拒否する。
    rejects<std::invalid_argument>([] { (void)plus_julian_date_from_string(std::string(100000, '9') + ",1,1,0,0,0"); });
}

void test_explicit_local_time() {
    static_assert(!std::is_default_constructible_v<PlusTimeZone>);
    const double utc = julian_date({2024,2,29,18,30,0.75});
    date_is(plus_local_time(utc, PlusTimeZone{-9 * 3600}), {2024,3,1,3,30,0});
    date_is(plus_local_time(utc, PlusTimeZone{8 * 3600}), {2024,2,29,10,30,0});
    date_is(plus_local_time(utc, PlusTimeZone{1}), {2024,2,29,18,29,59});
    date_is(plus_local_time(utc, PlusTimeZone{-1}), {2024,2,29,18,30,1});
    for (const GregorianDateTime& date : std::array<GregorianDateTime, 4>{{
            {2024,1,1,0,0,0.75}, {2024,7,1,0,0,0.75}, {0,1,1,0,0,0.75}, {-1,12,31,0,0,0.75}}}) {
        const double input = julian_date(date);
        for (std::int32_t seconds : {0, -32400, 28800, -19800, 1, -1,
                                    std::numeric_limits<std::int32_t>::min(),
                                    std::numeric_limits<std::int32_t>::max()}) {
            const PlusTimeZone zone{seconds};
            const auto local = plus_local_time(input, zone);
            const double restored = plus_local_julian_date(local, zone);
            check(input >= restored && (input - restored) * 86400 < 1.0001,
                  "fixed-second local time round trip changed its offset or gained a day");
            const double offset = static_cast<double>(seconds) / 24 / 3600;
            same_jd(restored, plus_julian_date(local) + offset);
        }
    }
    const PlusTimeZone japan{-32400};
    same_jd(plus_local_julian_date({2024,2,31,0,0,0}, japan),
            plus_julian_date({2024,3,2,0,0,0}) - 9.0 / 24);
    same_jd(plus_local_julian_date({2024,13,1,-1,0,0}, japan),
            plus_julian_date({2024,12,31,23,0,0}) - 9.0 / 24);
}

void test_jd_boundaries() {
    const PlusTimeZone zero{0};
    for (double invalid : {std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity(),
                           std::numeric_limits<double>::quiet_NaN()}) {
        rejects<std::invalid_argument>([&] { (void)plus_local_time(invalid, zero); });
        rejects<std::invalid_argument>([&] { (void)plus_time_string(invalid); });
    }
    const double first = julian_date({-4712,1,1,0,0,0});
    const double last = julian_date({9999,12,31,23,59,59.75});
    date_is(plus_local_time(first, zero), {-4712,1,1,0,0,0});
    date_is(plus_local_time(last, zero), {9999,12,31,23,59,59});
    rejects<std::out_of_range>([&] { (void)plus_local_time(first, PlusTimeZone{1}); });
    rejects<std::out_of_range>([&] { (void)plus_local_time(last, PlusTimeZone{-1}); });
    rejects<std::out_of_range>([&] { (void)plus_local_time(first - 1, PlusTimeZone{-86400}); });
    rejects<std::out_of_range>([] { (void)plus_local_julian_date({-4712,1,1,0,0,0}, PlusTimeZone{-1}); });
    rejects<std::out_of_range>([] { (void)plus_local_julian_date({9999,12,31,23,59,59}, PlusTimeZone{2}); });
    rejects<std::invalid_argument>([] { (void)plus_local_julian_date({2000,1,1,0,0,0.5}, PlusTimeZone{0}); });
}

void test_local_components() {
    for (const GregorianDateTime& input : std::array<GregorianDateTime, 6>{{
            {2000,1,2,3,4,0}, {2024,2,29,23,59,0}, {1,1,1,0,0,0},
            {-1,12,31,23,59,0}, {9999,12,30,23,59,0}, {-4712,1,2,0,0,0}}}) {
        for (std::int32_t offset : {0, -32400, 28800, -19800, 1, -1}) {
            const PlusTimeZone zone{offset};
            for (int second = 0; second < 60; ++second) {
                auto local = input; local.second = second;
                const auto instant = plus_local_julian_date(local, zone);
                const auto shown = plus_local_time(instant, zone);
                const std::array<std::int32_t, 6> values{{shown.year, shown.month, shown.day,
                    shown.hour, shown.minute, static_cast<std::int32_t>(shown.second)}};
                for (std::size_t i = 0; i < values.size(); ++i)
                    check(!plus_local_component_julian_date(instant, zone,
                        static_cast<PlusTimeComponent>(i), values[i]),
                        "getter/setter roundtrip interrupted playback or interpolation");
            }
        }
    }
    const PlusTimeZone japan{-32400};
    const double utc = julian_date({2024,1,31,3,4,5.75});
    struct Example { PlusTimeComponent component; std::int32_t value; GregorianDateTime local; };
    const std::array<Example, 6> examples{{
        {PlusTimeComponent::year, 2023, {2023,1,31,12,4,5.75}},
        {PlusTimeComponent::month, 2, {2024,3,2,12,4,5.75}},
        {PlusTimeComponent::day, 0, {2023,12,31,12,4,5.75}},
        {PlusTimeComponent::hour, 24, {2024,2,1,0,4,5.75}},
        {PlusTimeComponent::minute, -1, {2024,1,31,11,59,5.75}},
        {PlusTimeComponent::second, 60, {2024,1,31,12,5,0}}
    }};
    for (const auto& example : examples) {
        const auto result = plus_local_component_julian_date(utc, japan, example.component, example.value);
        check(result.has_value(), "changed local component was treated as a no-op");
        const double expected = julian_date(example.local) - 9.0 / 24;
        check(std::abs(*result - expected) <= 4 * std::numeric_limits<double>::epsilon() * std::abs(expected),
              "individual local setter lost fractional seconds or rollover");
    }
    const std::array<std::int32_t, 5> unchanged{{2024,1,31,12,4}};
    for (std::size_t index = 0; index < unchanged.size(); ++index)
        check(!plus_local_component_julian_date(utc, japan, static_cast<PlusTimeComponent>(index), unchanged[index]),
              "equal individual component must preserve playback and interpolation");
    check(plus_local_component_julian_date(utc, japan, PlusTimeComponent::second, 5).has_value(),
          "second setter compared its argument to the truncated getter");
    check(!plus_local_component_julian_date(julian_date({2024,1,31,3,0,0}), japan,
                                           PlusTimeComponent::second, 0), "exact equal second was not a no-op");
    for (auto component : {PlusTimeComponent::month, PlusTimeComponent::day,
                            PlusTimeComponent::hour, PlusTimeComponent::minute}) {
        rejects<std::invalid_argument>([&] { (void)plus_local_component_julian_date(utc, japan, component, 128); });
        rejects<std::invalid_argument>([&] { (void)plus_local_component_julian_date(utc, japan, component, -129); });
    }
    for (std::int32_t seconds : {std::numeric_limits<std::int32_t>::min(),
                                 std::numeric_limits<std::int32_t>::max()}) {
        check(plus_local_component_julian_date(utc, japan, PlusTimeComponent::second, seconds).has_value(),
              "valid int32 second rollover was rejected");
    }
    rejects<std::invalid_argument>([&] { (void)plus_local_component_julian_date(utc, japan,
        static_cast<PlusTimeComponent>(99), 1); });
    rejects<std::invalid_argument>([&] { (void)plus_local_component_julian_date(utc, japan,
        PlusTimeComponent::year, 10000); });
    rejects<std::invalid_argument>([&] { (void)plus_local_component_julian_date(
        std::numeric_limits<double>::quiet_NaN(), japan, PlusTimeComponent::year, 2024); });
    const double first = julian_date({-4712,1,1,0,0,0});
    rejects<std::out_of_range>([&] { (void)plus_local_component_julian_date(first, PlusTimeZone{1},
        PlusTimeComponent::year, -4712); });
    rejects<std::out_of_range>([&] { (void)plus_local_component_julian_date(first, PlusTimeZone{0},
        PlusTimeComponent::day, 0); });
}
}

int main() {
    try {
        test_strings();
        test_integer_seconds_roundtrip();
        test_string_rejections();
        test_explicit_local_time();
        test_jd_boundaries();
        test_local_components();
        std::cout << "Plus time calendar tests passed: " << checks << " checks\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Plus time calendar test failed: " << error.what() << '\n';
        return 1;
    }
}
