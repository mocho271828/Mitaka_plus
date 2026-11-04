#pragma once

#include "mitaka/astronomy.hpp"
#include <array>

namespace mitaka::gui {

// 数値はネイティブ状態ファイル用。旧 Lua の定数値を表すものではない。
enum class TimeStep {
    ten_seconds, minute, ten_minutes, hour, day, week, month, year,
    ten_years, hundred_years, custom
};

struct TimeSettings {
    TimeStep step = TimeStep::hour;
    int custom_seconds = 3600;
    int utc_offset_minutes = 0;
};

struct CalendarMonth {
    int year;
    int month;
    int first_weekday; // 日曜 = 0。days の 0 は前後の空欄。
    std::array<int, 42> days{};
    bool previous_enabled;
    bool next_enabled;
};

// 曜日配置だけを担い、日付・対応年の検証はコアの先発グレゴリオ暦を使う。
CalendarMonth calendar_month(int year, int month);

// 固定時差は -14..+14 時間、任意ステップは 1 秒..30 日。
// 地方標準時・夏時間・UTC/UT1/TT/TDB の変換は行わない。
void validate_time_settings(const TimeSettings& settings);
GregorianDateTime calendar_at_offset(double jd, int utc_offset_minutes);
double julian_date_at_offset(const GregorianDateTime& date, int utc_offset_minutes);

// direction は -1 または +1。月・年の移動では移動先の月末に日を収める。
// 先発グレゴリオ暦の範囲を検証する。暦表の有効範囲は呼び出し側で検証する。
double step_julian_date(double jd, const TimeSettings& settings, int direction);

} // namespace mitaka::gui
