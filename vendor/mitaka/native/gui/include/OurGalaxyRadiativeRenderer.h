#pragma once

#include "galaxy_camera.hpp"
#include "mitaka/our_galaxy_radiative.hpp"
#include <CoreGraphics/CoreGraphics.h>
#include <functional>
#include <memory>

namespace mitaka::gui {

// 公式 1.3.1 の転置変換と太陽位置 8000 pc に基づく暫定変換。
// 旧 Plus との同一性は未検証。範囲外・非有限値は例外を返す。
OurGalaxyGalacticVector our_galaxy_galactic_position(NativeEclipticPositionPc position);
OurGalaxyGalacticVector our_galaxy_camera_origin(GalaxyCameraPc camera);
// 公式 camera_base は現行ビューに存在せず、GC 距離は eye で代用する。
float our_galaxy_alpha(GalaxyCameraPc camera);

class OurGalaxyRadiativeImages {
public:
    OurGalaxyRadiativeImages(CGImageRef multiplier, CGImageRef emission, float alpha);
    ~OurGalaxyRadiativeImages();
    OurGalaxyRadiativeImages(const OurGalaxyRadiativeImages&) = delete;
    OurGalaxyRadiativeImages& operator=(const OurGalaxyRadiativeImages&) = delete;
    CGImageRef multiplier() const noexcept { return multiplier_; }
    CGImageRef emission() const noexcept { return emission_; }
    float alpha() const noexcept { return alpha_; }
private:
    CGImageRef multiplier_;
    CGImageRef emission_;
    float alpha_;
};

// 320px 以下の低解像度・8bit 画像。RGB 透過は multiply、放射は plusLighter
// で背景へ合成する。色空間と旧 Plus 画面との一致は未検証。
// 中断時は null、範囲外・特異点・画像作成失敗は例外。モデルは変更しない。
std::shared_ptr<const OurGalaxyRadiativeImages> render_our_galaxy_radiative(
    const OurGalaxyRadiativeModel& model, GalaxyCameraPc camera,
    double width_points, double height_points, std::function<bool()> should_cancel = {});

} // namespace mitaka::gui
