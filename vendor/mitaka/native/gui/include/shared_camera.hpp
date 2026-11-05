#pragma once

#include "galaxy_camera.hpp"

namespace mitaka::gui {

// 暫定前提: 太陽系の AU 座標と native J2000 黄道 pc 座標は原点・軸が共通。
// 通常版 Mitaka の mtk_galaxies.cpp は SDSS 座標を日心黄道座標と記すが、
// 旧 Plus バイナリでも同一かは未確認。原点オフセットは適用しない。
constexpr double astronomical_units_per_parsec = 648000.0 / 3.14159265358979323846;
constexpr double minimum_shared_distance_au = 1e-12;
constexpr double maximum_shared_distance_au = maximum_galaxy_coordinate_pc * astronomical_units_per_parsec;

// 両空間の移行用。frame は地表視点のロールを含む完全な姿勢を保持する。
// frame がない場合は yaw/pitch が姿勢を指定する。座標・距離は AU。
struct SharedCamera {
    Vec3 target_au;
    double yaw_deg;
    double pitch_deg;
    double distance_au;
    std::optional<SolarCameraBasis> frame;

    // 値域は 1e-12 AU から 1e40 pc 相当。無効な値や操作は invalid_argument。
    // 各描画系への変換時にはその描画系固有の距離制限が別途適用される。
    void orbit(double dx_points, double dy_points);
    void pan(double dx_points, double dy_points, double width, double height);
    void zoom(double logarithmic_delta);
};

SharedCamera shared_camera_from_solar(const SolarCamera& camera);
SharedCamera shared_camera_from_galaxy(const GalaxyCameraPc& camera);

// 各描画系の値域を超える場合は既存のカメラ検証と同様に invalid_argument。
SolarCamera solar_camera_from_shared(const SharedCamera& camera);
GalaxyCameraPc galaxy_camera_from_shared(const SharedCamera& camera);

} // namespace mitaka::gui
