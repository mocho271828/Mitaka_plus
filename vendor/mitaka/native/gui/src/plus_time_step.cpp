#include "plus_time_step.hpp"
#include "mitaka/astronomy.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <stdexcept>
#include <limits>
#include <cstdint>

namespace mitaka::gui {
namespace {
constexpr std::array<double, 12> step_days{{
    1.0 / 86400, 10.0 / 86400, 60.0 / 86400, 600.0 / 86400,
    3600.0 / 86400, 1, 7, 31, 365, 3650, 36500, 0
}};

std::size_t step_index(PlusTimeStep step) {
    const int index = static_cast<int>(step);
    if (index < 0 || index >= static_cast<int>(step_days.size()))
        throw std::invalid_argument("Plus time: unknown step");
    return static_cast<std::size_t>(index);
}
}

PlusTimeStepState::PlusTimeStepState(PlusTimeStep step) : step_(step), value_days_(step_days[step_index(step)]) {}

PlusTimeStepState::PlusTimeStepState(PlusTimeStep step, double days) : PlusTimeStepState(step) {
    if (!std::isfinite(days)) throw std::invalid_argument("Plus time: step value must be finite days");
    value_days_ = days;
}

double plus_julian_date(const mitaka::GregorianDateTime& date) {
    if (date.year < -4712 || date.year > 9999 || date.month < -128 || date.month > 127 ||
        date.day < -128 || date.day > 127 || date.hour < -128 || date.hour > 127 ||
        date.minute < -128 || date.minute > 127 || !std::isfinite(date.second) ||
        date.second != std::trunc(date.second) || date.second < std::numeric_limits<std::int32_t>::min() ||
        date.second > std::numeric_limits<std::int32_t>::max())
        throw std::invalid_argument("Plus time: calendar component outside safe source representation");
    int year = date.year, month = date.month;
    while (month < 1) { month += 12; --year; }
    while (month > 12) { month -= 12; ++year; }
    const double result = julian_date({year, month, 1, 0, 0, 0}) + (date.day - 1) +
        date.hour / 24.0 + date.minute / 1440.0 + date.second / 86400.0;
    (void)gregorian_date_time(result);
    return result;
}

void PlusTimeStepState::select(PlusTimeStep step) {
    const double days = step_days[step_index(step)];
    step_ = step;
    value_days_ = days;
}

void PlusTimeStepState::set_value_days(double days) {
    if (!std::isfinite(days)) throw std::invalid_argument("Plus time: step value must be finite days");
    step_ = PlusTimeStep::value;
    value_days_ = days;
}

void PlusTimeStepState::previous() {
    step_ = static_cast<PlusTimeStep>(std::max(static_cast<int>(step_) - 1, 0));
}

void PlusTimeStepState::next() {
    step_ = static_cast<PlusTimeStep>(std::min(static_cast<int>(step_) + 1, 9));
}

double PlusTimeStepState::stepped_julian_date(double jd, int direction) const {
    auto date = gregorian_date_time(jd);
    if (direction != -1 && direction != 1)
        throw std::invalid_argument("Plus time: step direction must be -1 or +1");
    double result;
    if (step_ >= PlusTimeStep::month && step_ <= PlusTimeStep::hundred_years) {
        if (step_ == PlusTimeStep::month) {
            date.month += direction;
            if (date.month == 0) { --date.year; date.month = 12; }
            if (date.month == 13) { ++date.year; date.month = 1; }
        } else {
            const int years = step_ == PlusTimeStep::year ? 1 :
                              step_ == PlusTimeStep::ten_years ? 10 : 100;
            date.year += direction * years;
        }
        // 日を月末へ収めず月初からの経過日数へ戻す。閏年の式は core に任せる。
        const int elapsed_days = date.day - 1;
        date.day = 1;
        result = julian_date(date) + elapsed_days;
    } else {
        const double days = step_ == PlusTimeStep::value ? value_days_ : step_days[step_index(step_)];
        result = jd + direction * days;
    }
    (void)gregorian_date_time(result);
    return result;
}

} // namespace mitaka::gui
