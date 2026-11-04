#pragma once
#include <optional>

namespace mitaka::gui {

enum class PlusTimeAnimationCurve { half_cosine, linear };
enum class PlusTimeAnimationSameTarget { preserve, replace };

struct PlusTimeAnimationSample {
    double julian_date;
    bool remove_after_dispatch;
};

// Plus の数値 Time:*To 補間。時計・再生・実時計追従の管理は呼出し側に置く。
class PlusTimeAnimation {
public:
    // 時刻と duration は秒、JD は core の対応暦範囲。全引数の検証後だけ状態を置換する。
    // preserve の同一 JD は既存補間を残し false、replace は同一 JD でも登録して true。
    bool start(double current_jd, double target_jd, double duration_seconds, double now_seconds,
               PlusTimeAnimationCurve curve, PlusTimeAnimationSameTarget same_target);
    bool active() const noexcept { return state_.has_value(); }

    // 評価だけでは除去しない。呼出し側は目標値を dispatch した後に cancel する。
    // duration 0 は目標を返し続け、正の duration は経過秒が厳密に超過したときだけ除去する。
    std::optional<PlusTimeAnimationSample> sample(double now_seconds) const;
    void cancel() noexcept { state_.reset(); }

private:
    struct State {
        double current_jd, target_jd, duration_seconds, start_seconds;
        PlusTimeAnimationCurve curve;
    };
    std::optional<State> state_;
};

} // namespace mitaka::gui
