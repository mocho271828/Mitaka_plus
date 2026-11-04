#pragma once

#include "local_image.hpp"
#include "mitaka/astronomy.hpp"
#include <array>
#include <optional>
#include <string>
#include <vector>

namespace mitaka::gui {

struct EarthLayerOptions {
    // 公式通常版の初期値を採用。city_lights=false でも近地表では弱い夜景が残る。
    bool clouds = true;
    bool city_lights = false;
};

struct EarthLayerAssets {
    std::optional<TextureImage> clouds;
    std::optional<TextureImage> night_lights;
    std::vector<std::string> diagnostics;
};

struct EarthLayerView {
    Vec3 earth_to_camera_ecliptic_au;
    Vec3 earth_to_sun_ecliptic_unit;
    double display_radius_au;
    double topography_scale = 1;
};

// 呼出し中だけ資産を借用する。画像所有者の寿命は呼出し側が保証する。
struct EarthLayerBinding {
    const EarthLayerAssets& assets;
    EarthLayerOptions options;
    EarthLayerView view;
};

// 不正/非有限の幾何、単位でない太陽方向、負の地形倍率を拒否する。
void validate_earth_layer_view(const EarthLayerView& view);
double earth_night_gain(const EarthLayerView& view, bool city_lights);
double earth_cloud_radius_factor(double topography_scale);

// 模式球の描画矩形と画像寸法へ同じ倍率を掛け、基底の見かけ半径を保つ。
// 雲がない/無効/視点が雲殻上または内側なら1。画像の検査はrendererが行う。
double earth_layer_extent(const EarthLayerBinding& binding);

// 単位法線と太陽方向を受ける。RGBは表示値で、物理radianceではない。
// 雲のambient 0.03は公式通常照明 .1*(global .2 + light0 .1) に由来する。
double earth_night_brightness(Vec3 normal, Vec3 sun_direction, double gain);
double earth_cloud_brightness(Vec3 normal, Vec3 sun_direction);
std::array<double, 3> earth_add_rgb(std::array<double, 3> destination,
                                  std::array<double, 3> source);

} // namespace mitaka::gui
