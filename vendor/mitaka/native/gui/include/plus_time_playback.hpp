#pragma once
#include "plus_time_step.hpp"
#include <cstdint>

namespace mitaka::gui {

struct PlusTimeState {
    // 新 GUI の初期値。原版の起動時設定を推測した値ではない。
    PlusTimeStepState step{PlusTimeStep::hour};
    std::int32_t speed = 0;
};

// 原版 speed は数値を int32 へ切捨て変換する。未定義の範囲外変換は拒否する。
std::int32_t plus_time_speed(double value);
// stepValue（日）× speed（step/秒）を既存単調時計の秒単位へ渡す。
// 0 日の連続再生も許可する。積が非有限なら適用前に拒否する。
double plus_time_rate(const PlusTimeState& state);

} // namespace mitaka::gui
