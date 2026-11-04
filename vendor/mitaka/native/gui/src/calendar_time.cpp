#include "calendar_time.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
void validate_offset(int offset) {
    if (offset < -840 || offset > 840)
        throw std::invalid_argument("calendar: fixed UTC offset must be within -840..840 minutes");
}

int days_in_month(int year, int month) {
    constexpr std::array<int, 12> days{{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}};
    const bool leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    return days.at(month - 1) + (month == 2 && leap ? 1 : 0);
}
}

CalendarMonth calendar_month(int year, int month) {
    const double first = julian_date({year, month, 1, 0, 0, 0});
    const double earliest = julian_date({-4712, 1, 1, 0, 0, 0});
    const double latest = julian_date({9999, 12, 31, 0, 0, 0});
    const int weekday = static_cast<int>(std::floor(first + 1.5));
    CalendarMonth result{year, month, (weekday % 7 + 7) % 7, {}, first > earliest, false};
    for (int index = result.first_weekday; index < static_cast<int>(result.days.size()); ++index) {
        const double jd = first + index - result.first_weekday;
        if (jd > latest) break;
        const auto date = gregorian_date_time(jd);
        if (date.month != month || date.year != year) {
            result.next_enabled = true;
            break;
        }
        result.days[index] = date.day;
    }
    return result;
}

void validate_time_settings(const TimeSettings& settings) {
    if (settings.step < TimeStep::ten_seconds || settings.step > TimeStep::custom)
        throw std::invalid_argument("calendar: unknown time step");
    if (settings.custom_seconds < 1 || settings.custom_seconds > 2592000)
        throw std::invalid_argument("calendar: custom step must be within 1..2592000 seconds");
    validate_offset(settings.utc_offset_minutes);
}

GregorianDateTime calendar_at_offset(double jd, int utc_offset_minutes) {
    validate_offset(utc_offset_minutes);
    // 元の JD も検証し、時差を足すことで範囲外入力が紛れ込むことを防ぐ。
    (void)gregorian_date_time(jd);
    return gregorian_date_time(jd + utc_offset_minutes / 1440.0);
}

double julian_date_at_offset(const GregorianDateTime& date, int utc_offset_minutes) {
    validate_offset(utc_offset_minutes);
    const double jd = julian_date(date) - utc_offset_minutes / 1440.0;
    (void)gregorian_date_time(jd);
    return jd;
}

double step_julian_date(double jd, const TimeSettings& settings, int direction) {
    validate_time_settings(settings);
    if (direction != -1 && direction != 1)
        throw std::invalid_argument("calendar: step direction must be -1 or +1");
    auto date = calendar_at_offset(jd, settings.utc_offset_minutes);
    if (settings.step >= TimeStep::month && settings.step <= TimeStep::hundred_years) {
        if (settings.step == TimeStep::month) {
            const int month_index = date.year * 12 + date.month - 1 + direction;
            // C++ の負数除算はゼロに丸めるため、紀元前も月が 1..12 になるよう補正する。
            date.year = (month_index >= 0 ? month_index : month_index - 11) / 12;
            date.month = month_index - date.year * 12 + 1;
        } else {
            const int years = settings.step == TimeStep::year ? 1 :
                              settings.step == TimeStep::ten_years ? 10 : 100;
            date.year += direction * years;
        }
        date.day = std::min(date.day, days_in_month(date.year, date.month));
        return julian_date_at_offset(date, settings.utc_offset_minutes);
    }
    constexpr std::array<int, 6> seconds{{10, 60, 600, 3600, 86400, 604800}};
    const int interval = settings.step == TimeStep::custom ? settings.custom_seconds :
        seconds.at(static_cast<std::size_t>(settings.step));
    const double result = jd + direction * interval / 86400.0;
    (void)calendar_at_offset(result, settings.utc_offset_minutes);
    return result;
}

} // namespace mitaka::gui
