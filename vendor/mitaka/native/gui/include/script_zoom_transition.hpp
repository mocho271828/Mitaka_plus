#pragma once
#include <algorithm>
#include <cmath>

namespace mitaka::gui {
// 時刻を外から与え、実時間の待機なしで補間と再指定を検証する。
struct ScriptZoomTransition {
    double initial, target, start_time, duration;
    bool logarithmic;
    double value(double now) const {
        const double t = std::clamp((now - start_time) / duration, 0.0, 1.0);
        if (t <= 0) return initial;
        if (t >= 1) return target;
        if (!logarithmic) return (1 - t) * initial + t * target;
        return std::clamp(std::exp((1 - t) * std::log(initial) + t * std::log(target)),
                          std::min(initial, target), std::max(initial, target));
    }
};
}
