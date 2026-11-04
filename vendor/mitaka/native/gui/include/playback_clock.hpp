#pragma once

#include <utility>

namespace mitaka::gui {

enum class PlaybackEvent { advanced, end_of_range, interrupted };

struct PlaybackSample {
    double julian_date;
    PlaybackEvent event;
};

// OS 時計の取得は呼び出し側で行い、同一の単調時計の秒数を渡す。
// rate は実時間 1 秒あたりのシミュレーション秒。負数は逆再生、既定値は 3600。
// 引数不正による例外では再生状態・時刻・速度を変更しない。
class PlaybackClock {
public:
    // 停止中のみ開始可能（再生中は logic_error）。range は有限の low < high。
    // JD は順再生で [low, high)、逆再生で (low, high]。進行側の端点では out_of_range。
    // 単調時計は有限なら負の原点も許可する。
    // 非有限値・不正 range は invalid_argument、範囲外 JD は out_of_range。
    void start(double julian_date, std::pair<double, double> range, double monotonic_seconds);
    void stop() noexcept;
    bool is_playing() const noexcept { return playing_; }

    // 停止中のみ変更可能。有限かつ絶対値 [1,2592000] を受け付ける。0 は停止操作の代用にしない。
    // 再生中は logic_error、不正な速度は invalid_argument。
    void set_rate(double simulation_seconds_per_second);
    // Plus 専用境界で検証済みの有限速度。native の速度範囲とは別で、0 も許可する。
    void set_plus_rate(double simulation_seconds_per_second);
    double rate() const noexcept { return rate_; }

    // 再生中のみ。停止中は logic_error、非有限時計は invalid_argument。
    // 開始時刻からの絶対経過で計算し、標本ごとの JD 加算は行わない。
    // 前回から >1 秒の空白か時計逆行では、直前の返却 JD を保って interrupted 停止。
    // 初回の「前回」は start の時計と JD。進行側の端点到達では厳密にその端点へ揃えて停止する。
    // 同一時計や JD の丸め未満の進みでも advanced を返し、JD が同値のことがある。
    PlaybackSample sample(double monotonic_seconds);

private:
    bool playing_ = false;
    double rate_ = 3600;
    double anchor_jd_ = 0;
    double anchor_seconds_ = 0;
    double range_begin_ = 0;
    double range_end_ = 0;
    double previous_seconds_ = 0;
    double previous_jd_ = 0;
};

} // namespace mitaka::gui
