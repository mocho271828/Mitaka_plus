#pragma once

#include "solar_camera.hpp"
#include <array>
#include <vector>

namespace mitaka::gui {

struct CircleDistanceScale {
    double radius_au;
    double label_value;
    bool galactic_plane;
    double label_angle_deg;
};
struct SquareDistanceScale {
    int meter_exponent;
    double opacity;
    std::array<Vec3, 5> vertices;
};

// 公式 1.3.1 の21尺度。AU円は黄道面、光年円は共通の銀河面、中心は太陽。
const std::array<CircleDistanceScale, 21>& circle_distance_scales();
Vec3 circle_distance_scale_point(const CircleDistanceScale& scale, double angle_deg);
// カメラ距離を表示尺度として使う。旧 ds.scale と同一という保証はしない。
// 非有限・非正の距離と半径は invalid_argument。
double circle_distance_scale_opacity(double camera_distance_au, double radius_au);
// 1..10^27 m の28候補から、旧 calc_alpha の可視範囲にある枠だけを返す。
// 中心は camera.target、平面はカメラの right/up。カメラは既存契約で検証する。
std::vector<SquareDistanceScale> square_distance_scales(const SolarCamera& camera);

} // namespace mitaka::gui
