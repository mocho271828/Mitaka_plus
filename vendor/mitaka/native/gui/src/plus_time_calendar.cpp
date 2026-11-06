#include "plus_time_calendar.hpp"
#include "plus_time_step.hpp"
#include <algorithm>
#include <array>
#include <charconv>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
bool ascii_space(char value) {
    return value == ' ' || value == '\t' || value == '\n' || value == '\r' || value == '\f' || value == '\v';
}

std::int32_t read_integer(std::string_view& text) {
    while (!text.empty() && ascii_space(text.front())) text.remove_prefix(1);
    bool negative = false;
    if (!text.empty() && (text.front() == '-' || text.front() == '+')) {
        negative = text.front() == '-';
        text.remove_prefix(1);
    }
    int base = 10;
    if (!text.empty() && text.front() == '0') {
        base = 8;
        if (text.size() >= 2 && (text[1] == 'x' || text[1] == 'X')) {
            base = 16;
            text.remove_prefix(2);
        }
    }
    if (text.empty()) throw std::invalid_argument("Plus time: missing integer component");
    std::uint32_t magnitude = 0;
    const auto parsed = std::from_chars(text.data(), text.data() + text.size(), magnitude, base);
    const std::uint32_t limit = negative ? 2147483648u : 2147483647u;
    if (parsed.ec != std::errc{} || magnitude > limit)
        throw std::invalid_argument("Plus time: component must be a valid int32 integer");
    text.remove_prefix(static_cast<std::size_t>(parsed.ptr - text.data()));
    // INT32_MIN の絶対値を signed int に変換してから符号反転しない。
    if (negative && magnitude == 2147483648u) return std::numeric_limits<std::int32_t>::min();
    return negative ? -static_cast<std::int32_t>(magnitude) : static_cast<std::int32_t>(magnitude);
}

double ulp(double value) {
    return std::nextafter(value, std::numeric_limits<double>::infinity()) - value;
}

double calendar_allowance(double jd, double source_jd) {
    return jd == source_jd ? ulp(jd) : 2 * std::max(ulp(jd), ulp(source_jd));
}

GregorianDateTime integer_calendar(double jd, double source_jd) {
    // JD の量子化と地方時オフセットの加減算に伴う誤差幅では、整数秒の
    // 直前の値と厳密な整数秒を区別できない。範囲内では整数秒と扱う。
    // それ以外の小数秒は切り捨てる。遠い UTC からの桁落ちも考慮する。
    (void)gregorian_date_time(jd);
    const double allowance = calendar_allowance(jd, source_jd);
    const double adjusted = jd + allowance;
    auto result = adjusted < 5373484.5 ? gregorian_date_time(adjusted) : gregorian_date_time(jd);
    result.second = std::trunc(result.second);
    return result;
}

double offset_days(PlusTimeZone zone) {
    // 原版 adapter と同じ順序。INI の時間単位や UI の分単位へ丸めない。
    return static_cast<double>(zone.seconds_west_of_utc) / 24.0 / 3600.0;
}
}

GregorianDateTime plus_local_time(double utc_jd, PlusTimeZone zone) {
    (void)gregorian_date_time(utc_jd);
    return integer_calendar(utc_jd - offset_days(zone), utc_jd);
}

double plus_local_julian_date(const GregorianDateTime& local, PlusTimeZone zone) {
    const double result = plus_julian_date(local) + offset_days(zone);
    (void)gregorian_date_time(result);
    return result;
}

std::optional<double> plus_local_component_julian_date(double utc_jd, PlusTimeZone zone,
    PlusTimeComponent component, std::int32_t value) {
    (void)gregorian_date_time(utc_jd);
    const double local_jd = utc_jd - offset_days(zone);
    auto date = gregorian_date_time(local_jd);
    const auto integer_date = integer_calendar(local_jd, utc_jd);
    // getter が量子化誤差内とみなす整数秒は setter でも同じ値とする。
    // 十分離れた小数秒は保持し、明示的な秒の変更でのみ切り捨てる。
    if (std::abs(local_jd - plus_julian_date(integer_date)) <= calendar_allowance(local_jd, utc_jd))
        date = integer_date;
    switch (component) {
        case PlusTimeComponent::year: if (date.year == value) return std::nullopt; date.year = value; break;
        case PlusTimeComponent::month: if (date.month == value) return std::nullopt; date.month = value; break;
        case PlusTimeComponent::day: if (date.day == value) return std::nullopt; date.day = value; break;
        case PlusTimeComponent::hour: if (date.hour == value) return std::nullopt; date.hour = value; break;
        case PlusTimeComponent::minute: if (date.minute == value) return std::nullopt; date.minute = value; break;
        case PlusTimeComponent::second: if (date.second == value) return std::nullopt; date.second = value; break;
        default: throw std::invalid_argument("Plus time: unknown calendar component");
    }
    // 六成分 setter の整数検証を再利用し、個別 setter が保持する小数秒だけを戻す。
    const double fraction = date.second - std::trunc(date.second);
    date.second = std::trunc(date.second);
    const double result = plus_julian_date(date) + fraction / 86400.0 + offset_days(zone);
    (void)gregorian_date_time(result);
    return result;
}

std::string plus_time_string(double jd) {
    const auto date = integer_calendar(jd, jd);
    const std::array<int, 6> components{{date.year, date.month, date.day, date.hour, date.minute,
                                       static_cast<int>(date.second)}};
    std::string result;
    for (int component : components) {
        if (!result.empty()) result += ',';
        std::array<char, 12> buffer{};
        const auto converted = std::to_chars(buffer.data(), buffer.data() + buffer.size(), component);
        if (converted.ec != std::errc{}) throw std::logic_error("Plus time: integer formatting failed");
        result.append(buffer.data(), converted.ptr);
    }
    return result;
}

double plus_julian_date_from_string(std::string_view text) {
    if (text.find('\0') != std::string_view::npos)
        throw std::invalid_argument("Plus time: embedded NUL in calendar string");
    std::array<std::int32_t, 6> components{};
    for (std::size_t index = 0; index < components.size(); ++index) {
        components[index] = read_integer(text);
        if (index + 1 != components.size()) {
            if (text.empty() || text.front() != ',')
                throw std::invalid_argument("Plus time: calendar components require literal commas");
            text.remove_prefix(1);
        }
    }
    return plus_julian_date({components[0], components[1], components[2], components[3], components[4],
                             static_cast<double>(components[5])});
}

} // namespace mitaka::gui
