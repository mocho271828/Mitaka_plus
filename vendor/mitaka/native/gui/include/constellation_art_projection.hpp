#pragma once
#include "horizon_segments.hpp"

namespace mitaka::gui {
// CAB の変換済み空間直線を標本化する。端点 RA/Dec の線形補間ではない。
// 既存の円筒投影、地平変換、clip を再利用する。極や予算超過の区間は接続しない。
// limits の範囲は horizon_segments と同じ。端点は有限・非零、原点を通る直線は拒否。
HorizonSegmentProjection project_sky_constellation_art_segment(Vec3 start, Vec3 end,
    const SkyViewport& viewport, double width, double height, HorizonSamplingLimits limits = {});
HorizonSegmentProjection project_horizon_constellation_art_segment(Vec3 start, Vec3 end,
    const ObservationFrame& frame, const HorizonViewport& viewport,
    double width, double height, HorizonSamplingLimits limits = {});
}
