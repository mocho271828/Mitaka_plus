#pragma once

#include <optional>

namespace mitaka::gui {

// 旧 Plus の公開値は光量の分母 L_ref。保存可能な正の有限 float にだけ変換する。
float checked_star_brightness(double value);
float brighter_star_brightness(float value);
float darker_star_brightness(float value);

struct StarPointAppearance {
    double radius;
    double opacity;
};

// 現行の点描画用。L_ref=1 の既存表示を保ち、半径上限までは面積×alpha を 1/L_ref 倍にする。
// 半径上限は native の描画予算であり、旧テクスチャとの画素一致を意味しない。
StarPointAppearance star_point_appearance(double magnitude, float brightness);

class StarBrightnessTransition {
public:
    // 同じ current/target への要求は進行中の補間を取り消さない。
    // 0 秒は次の sample で即時完了する native 契約。
    bool begin(float current, double target, double duration_seconds, double now);
    std::optional<float> sample(double now);
    bool active() const noexcept { return active_; }
    void cancel() noexcept { active_ = false; }

private:
    float from_ = 1, target_ = 1;
    double duration_ = 0, started_ = 0, sampled_ = 0;
    bool active_ = false;
};

} // namespace mitaka::gui
