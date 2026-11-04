#pragma once

#include "mitaka/astronomy.hpp"
#include "mitaka/catalog.hpp"
#include <array>

namespace mitaka {

// Plus CAB の原順・原数値を保持する。数値対は画像ではなく平面上の線画の頂点。
struct ConstellationArt {
    std::filesystem::path source_path;
    std::vector<std::uint8_t> source_bytes;
    std::array<float, 5> header{};
    std::vector<std::array<float, 2>> points;
    // 負値は線の切れ目。自動で始点へ閉じない。未参照頂点も points に残す。
    std::vector<std::int32_t> indices;
};

// little-endian CAB。有限・非零の中心、有限数値、件数、全index、末尾を検証する。
// 空頂点/空indexは許す。読取失敗は CatalogError、部分結果は返さない。
ConstellationArt load_constellation_art(const std::filesystem::path& path,
                                       CatalogLoadLimits limits = {});

// 原版の原点観測者・正距離の線画を J2000 赤道方向に変換する。
// CAB固有 -23.4f 度と原版の赤道黄道行列23.43870583度の差を保持する。
// 旧空間モードの距離・観測者平行移動、SSEの丸め、画素一致は再現しない。
// 返値は未正規化。線分内部は両端の線形補間を正規化して投影する。
// 不正header/pointは invalid_argument、範囲外indexは out_of_range。
Vec3 constellation_art_direction(const ConstellationArt& art, std::size_t point_index);

} // namespace mitaka
