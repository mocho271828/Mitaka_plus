#pragma once

#include "local_image.hpp"
#include "earth_layers.hpp"
#include "mitaka/atmosphere.hpp"
#include <array>
#include <filesystem>
#include <optional>
#include <string>
#include <vector>

namespace mitaka::gui {

struct PlanetTextures {
    // SolarBodies と同じ、太陽・水金地火木土天海冥・月の順。月は末尾の index 10。
    std::array<std::optional<TextureImage>, 11> images;
    std::vector<std::string> warnings;
    EarthLayerAssets earth_layers;
    // 読込要求時は欠損/不正でも出典を保持。mapの有無が利用可能性を表す。
    std::optional<AtmosphereEmissionSource> atmosphere_emission;
    std::size_t loaded_count() const noexcept;
};

// 選択された data の兄弟 textures だけを読み取り専用で参照する。
// 11個の .jpg のJPEG / PNG内容を最大1024pxのRGBAへ変換。同名 .png は代用しない。
// 欠損・破損・終端マーカーの欠落は天体別warningsとして返す。
// ファイル上限64MiB、原画像64M画素・各辺32768px。過去の読込結果は再利用しない。
// 地球2層は同じtextures、emmap.datはdata直下から独立に読み込み、各診断を保持。
PlanetTextures load_planet_textures(const std::filesystem::path& data_directory);

} // namespace mitaka::gui
