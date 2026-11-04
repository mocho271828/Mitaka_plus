#pragma once

#include "mitaka/astronomy.hpp"
#include "mitaka/catalog.hpp"

namespace mitaka {

enum class DeepSkyKind : std::uint8_t {
    unspecified, galaxy, open_cluster, globular_cluster, emission_or_reflection_nebula,
    planetary_nebula, cluster_with_nebulosity, asterism, extragalactic_knot,
    triple_star, double_star, single_star
};

struct NgcRecord {
    std::int16_t number;
    bool is_ngc;
    // 原典の J2000 赤道座標。角度は degree。
    EquatorialCoordinates coordinates;
    DeepSkyKind kind;
    float angular_size_arcminutes;
    // 元データの 0 は未記載も含むため、表示側で実測等級と断定しない。
    float magnitude;
    bool is_photographic_magnitude;
};

enum class SdssKind { galaxy, quasar };

struct SdssRecord {
    EquatorialCoordinates coordinates;
    float distance_parsecs;
    // galaxy は eClass、quasar は赤方偏移 z。値を分類・丸めず保持する。
    float classification_value;
};

struct StarNameRecord {
    std::int32_t hip;
    bool is_featured;
    std::string name_bytes;
    // star_names_jp.dat / star_names_HIP.dat の第2名称。CP932のまま返す。
    std::string localized_name_bytes;
};

// 固定幅 little-endian の ngc.dat / SDSS_GAL.dat / SDSS_QSO.dat を読み込む。
// 不正な数値・切れたレコード・容量または件数超過は CatalogError。
std::vector<NgcRecord> load_ngc_catalog(
    const std::filesystem::path& path, CatalogLoadLimits limits = {});
std::vector<SdssRecord> load_sdss_catalog(
    const std::filesystem::path& path, SdssKind kind, CatalogLoadLimits limits = {});

// % / # で始まるコメントと空行を除き、全レコードを検証する。
// 名称は原本のバイト列として保持し、言語・文字コード変換はGUIに任せる。
std::vector<StarNameRecord> load_star_names(
    const std::filesystem::path& path, CatalogLoadLimits limits = {});
// 元の系外惑星一覧は同じ恒星を複数回含む。重複も原本の行として保持する。
std::vector<std::int32_t> load_exoplanet_host_hips(
    const std::filesystem::path& path, CatalogLoadLimits limits = {});

} // namespace mitaka
