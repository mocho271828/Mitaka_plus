#pragma once
#include "mitaka/astronomy.hpp"

namespace mitaka::gui {

// Plus 1.5.4 build101013 の登録値。native UI の TimeStep とは共有しない。
enum class PlusTimeStep {
    second = 0, ten_seconds = 1, minute = 2, ten_minutes = 3, hour = 4,
    day = 5, week = 6, month = 7, year = 8, ten_years = 9,
    hundred_years = 10, value = 11
};

// 原版の step と stepValue は一組の状態。stepValue の実装単位は日であり、
// 説明書の「秒」と異なる。初期値は推測せず呼び出し側が明示する。
class PlusTimeStepState {
public:
    explicit PlusTimeStepState(PlusTimeStep step);
    // prev/next が保つ独立の日数を、そのまま状態復元する。
    PlusTimeStepState(PlusTimeStep step, double value_days);
    PlusTimeStep step() const noexcept { return step_; }
    double value_days() const noexcept { return value_days_; }

    // 列挙選択で日数表へ置換する。VALUE の選択は 0 日へ戻る。
    // 不正な enum / 非有限値を拒否し、失敗時は状態を変えない。
    void select(PlusTimeStep step);
    void set_value_days(double days);
    // 原版は前後移動で列挙値だけを変え、stepValue は再計算しない。
    void previous();
    // 原版の上限比較に従い、9 / 10 / 11 からは 9（10 年）になる。
    void next();

    // direction は -1 または +1。月年の 1 step は暦の成分を変更し、
    // 存在しない日は翌月へ繰り越す。連続再生の固定日数とは区別する。
    // 入出力は core の先発 Gregorian 年 -4712..9999 で検証する。
    // 暦表の共通期間と手動操作時の停止は呼び出し側で検証・適用する。
    double stepped_julian_date(double julian_date, int direction) const;

private:
    PlusTimeStep step_;
    double value_days_;
};

// 原版の UTC 成分代入。月・日・時分秒の範囲超過を暦へ繰り越す。
// month/day/hour/minute は原版 signed byte で表現可能な値のみ受け付ける。
// 安全な変換のため年は core 範囲、秒は有限 int32 整数に限定する。
double plus_julian_date(const mitaka::GregorianDateTime& date);

} // namespace mitaka::gui
