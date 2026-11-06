#pragma once

#include "sdss_spatial_model.hpp"
#include "solar_camera.hpp"

namespace mitaka::gui {

// Native の独立 pc 空間。旧 Plus のカメラ上限/視野角を再現する型ではない。
// 全有限 float 距離のカタログを扱える範囲を用意し、AU カメラの上限は変えない。
constexpr double minimum_galaxy_distance_pc = 1e-6;
// 共有ビューは太陽系の最小距離まで同じ投影器を利用する。独立銀河ビューの zoom 下限は上記。
constexpr double minimum_galaxy_projection_distance_pc = 1e-12 / (648000.0 / 3.14159265358979323846);
constexpr double maximum_galaxy_coordinate_pc = 1e40;
struct GalaxyCameraPc {
    NativeEclipticPositionPc target{0, 0, 0};
    double yaw_deg = 35, pitch_deg = 35, distance_pc = 10000;
    // 地表などの任意姿勢を pc 空間でも失わず維持する。
    std::optional<SolarCameraBasis> frame = std::nullopt;
    double roll_deg = 0;
    bool frame_is_orbit = false;
    // target は pc の基準点。小さな移動は AU の差分として保持する。
    Vec3 target_offset_au{0, 0, 0};
    double vertical_fov_deg = 45;
    void orbit(double dx_points, double dy_points);
    void roll(double degrees);
    void pan(double dx_points, double dy_points, double width, double height);
    void zoom(double logarithmic_delta);
};

// 非有限値、|target 成分| > 1e40 pc、距離範囲外、|pitch| > 89 は拒否。
// 検証済みの値を返す。元の値を書き換えない。
GalaxyCameraPc checked_galaxy_camera(GalaxyCameraPc camera);

struct GalaxyProjectionPc { double x, y, depth_pc; };

// 基底/viewport を一度検証して、全原行の投影で共有する。
// 左上原点、垂直視野角はカメラの設定値、near = distance_pc * 1e-4。
// 位置は native J2000 黄道 pc。finite でない位置は拒否、near 手前は nullopt。
// viewport は (0,1e7] point。画面外も返すため描画時に clip が必要。
class GalaxyProjector {
public:
    GalaxyProjector(GalaxyCameraPc camera, double width, double height);
    std::optional<GalaxyProjectionPc> project(NativeEclipticPositionPc position) const;
    bool contains(const GalaxyProjectionPc& position) const noexcept;
    double width() const noexcept { return width_; }
    double height() const noexcept { return height_; }
    // 正面平行の半径を投影する。極端な入力の overflow は有限最大値に抑える。
    double projected_radius(double radius_pc, double depth_pc) const noexcept;
private:
    GalaxyCameraPc camera_;
    SolarCameraBasis basis_;
    double width_, height_, tangent_;
};

} // namespace mitaka::gui
