#pragma once

#include "horizon_viewport.hpp"
#include "sky_model.hpp"
#include "mitaka/observation.hpp"

namespace mitaka::gui {

struct HorizonSamplingLimits {
    double max_source_step_deg = 2;
    double screen_tolerance = 0.25;
    std::size_t max_evaluations = 8193;
    unsigned max_depth = 48;
};

struct HorizonSegmentProjection {
    std::vector<ScreenSegment> segments;
    std::size_t evaluations = 0;
    // 上限まで分割しても受理できなかった区間。そこを直線で補わない。
    std::size_t omitted_intervals = 0;
};

// 天空図と同じ「短い RA 方向・線形 Dec」の線分を J2000 から地平へ変換する。
// 大円への置換はしない。元の線を分割してから同一 ObservationFrame を使う。
// 1/4・中点・3/4 点の画面誤差で分割し、有限の深さ・評価数で終了する。
// 許容値は標本点の判定値であり、曲線全体の厳密な誤差保証ではない。
// 円筒投影の極では左右を分離し、継ぎ目・画面の clip は project_sky_segment を使う。
// 下半球も返す。暗く描くかどうかは描画側の責務。
// viewport は zoom [1,180]、中心高度 [-90,90]。不正入力は invalid_argument。
// max_evaluations [5,1048577]、max_depth [1,52]、step (0,2]、tolerance (0,4]。
HorizonSegmentProjection project_equatorial_segment_to_horizon(
    EquatorialCoordinates start, EquatorialCoordinates end, const ObservationFrame& frame,
    const HorizonViewport& viewport, double width, double height,
    HorizonSamplingLimits limits = {});

} // namespace mitaka::gui
