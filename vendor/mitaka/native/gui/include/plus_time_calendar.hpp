#pragma once
#include "mitaka/astronomy.hpp"
#include <cstdint>
#include <string>
#include <optional>
#include <string_view>

namespace mitaka::gui {

// 原版 Lua の地方時は CRT __timezone（UTC より西へ正の秒数）を使う。
// INI の TimeZone.DT や native UI の表示時差とは別で、初期値を推測しない。
struct PlusTimeZone {
    explicit PlusTimeZone(std::int32_t seconds_west) : seconds_west_of_utc(seconds_west) {}
    std::int32_t seconds_west_of_utc;
};

// 日付ごとの夏時間補正を行わず、呼び出し側が渡した固定 CRT 時差を使う。
// 入出力は core の先発 Gregorian 範囲で検証し、getter の秒は切り捨てる。
mitaka::GregorianDateTime plus_local_time(double utc_julian_date, PlusTimeZone zone);
double plus_local_julian_date(const mitaka::GregorianDateTime& local, PlusTimeZone zone);

enum class PlusTimeComponent { year, month, day, hour, minute, second };
// 個別 setter は残りの成分と小数秒を保持する。同成分が同値なら更新しない。
// month/day/hour/minute の低位 byte 切捨ては行わず安全範囲外を拒否する。
std::optional<double> plus_local_component_julian_date(double utc_julian_date, PlusTimeZone zone,
    PlusTimeComponent component, std::int32_t value);

// 原版の "%i,%i,%i,%i,%i,%i"。出力は十進数でゼロ埋めせず秒を切り捨てる。
// 入力は符号・十進/先頭 0 の八進/0x の十六進を扱い、6 成分後の接尾辞は無視する。
// 読取不足・int32 overflow・埋込み NUL を拒否する。暦成分の安全範囲と繰越は
// plus_julian_date と共通。原版の未初期化値使用・byte wrap は再現しない。
std::string plus_time_string(double utc_julian_date);
double plus_julian_date_from_string(std::string_view text);

} // namespace mitaka::gui
