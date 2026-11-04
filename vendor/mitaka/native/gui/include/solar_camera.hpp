#pragma once

#include "mitaka/astronomy.hpp"
#include <array>
#include <optional>

namespace mitaka::gui {

// outwardは視線の逆方向。right/up/outwardは右手正規直交基底。
struct SolarCameraBasis { Vec3 outward, right, up; };

// Z-up の透視投影カメラ。入力座標・target・距離の単位は AU。
// yaw は XY 面の +X からの角度。垂直視野角は45度。
// 正常範囲を外れた公開値や非有限入力は invalid_argument。
struct SolarCamera {
    Vec3 target{0, 0, 0};
    double yaw_deg = 35;
    double pitch_deg = 35;
    double distance_au = 100;
    // 地表視点では天体固定の局所鉛直を使うため、yaw/pitchの代わりに基底を指定する。
    std::optional<SolarCameraBasis> frame = std::nullopt;

    // 左上原点のドラッグ量。orbitは0.35度/point。通常のpitchは±89度で制限。
    void orbit(double dx_points, double dy_points);
    // 画面上の物体がドラッグ方向へ動くよう、注視点を平行移動する。
    void pan(double dx_points, double dy_points, double width, double height);
    // 正値で遠ざかる。通常は0.000005..1000AU、frame指定時は1e-12..1000AU。
    void zoom(double logarithmic_delta);
};

struct SolarProjection { double x, y, depth; };

// カメラ座標系の単位ベクトル。outwardは注視点からカメラへ向く。
SolarCameraBasis solar_camera_basis(const SolarCamera& camera);

// カメラから画素座標を通る単位視線。地表描画と通常投影で同じ視野角を使用する。
Vec3 solar_camera_ray(const SolarCamera& camera, double x, double y, double width, double height);

// 左上原点の画素座標とカメラ前方の奥行AU。nearより手前はnullopt。
// 画面外の座標も返すので、描画側で矩形クリップする。
std::optional<SolarProjection> project_solar(Vec3 position, const SolarCamera& camera,
                                            double width, double height);

// 線分をnear平面で切断してから投影する。両端が手前ならnullopt。
std::optional<std::array<SolarProjection, 2>> project_solar_segment(
    Vec3 begin, Vec3 end, const SolarCamera& camera, double width, double height);

} // namespace mitaka::gui
