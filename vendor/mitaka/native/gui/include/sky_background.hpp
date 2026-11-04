#pragma once

#include "local_image.hpp"
#include "sky_model.hpp"
#include "horizon_viewport.hpp"
#include "mitaka/observation.hpp"
#include <array>
#include <optional>
#include <string>

namespace mitaka::gui {

enum class MilkyWayMode { none, normal, bright, infrared };

struct SkyBackgrounds {
    // Normal、Bright、Infrared。欠損・破損した画像のslotは空にする。
    std::array<std::optional<TextureImage>, 3> images;
    std::vector<std::string> warnings;
    std::size_t loaded_count() const noexcept;
    const TextureImage* image(MilkyWayMode mode) const;
};

// dataの兄弟texturesを毎回読み直す。他のvariantやデータセットへ代用しない。
// IRはローカルPlusのMilkyWay_IR.jpgを優先し、無い場合だけ公式名milkyway_IR.jpg。
SkyBackgrounds load_sky_backgrounds(const std::filesystem::path& data_directory);

// 公式1.3.1の球面UV・銀河基底に由来。旧Plusとの厳密な一致は未確認。
// UVは左上原点、水平周期[0,1)、垂直[0,1]。極の水平座標は不定。
ScreenPoint sky_background_uv(EquatorialCoordinates coordinates);
// 水平座標は周期化し、垂直座標は[0,1]。不正値はinvalid_argument。
EquatorialCoordinates sky_background_coordinates(ScreenPoint uv);

// SkyViewと同じ赤経左向き・赤緯上向きの投影。出力長辺は1..1024px。
// 入力はload_local_imageの寸法/byte数契約、viewportは正規化して描く。
// 水平repeat・垂直clampの双線形補間。照明・距離減衰は加えない。
TextureImage render_sky_background(const TextureImage& texture, SkyViewport viewport,
                                   std::size_t width, std::size_t height);
// 地平図と同じ方位右向き・高度上向きの円筒投影。出力は左上原点の RGBA。
TextureImage render_horizon_background(const TextureImage& texture, HorizonViewport viewport,
                                       const ObservationFrame& frame,
                                       std::size_t width, std::size_t height);

} // namespace mitaka::gui
