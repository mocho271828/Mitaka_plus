#pragma once

#include "mitaka/astronomy.hpp"
#include "mitaka/catalog.hpp"

#include <array>
#include <optional>

namespace mitaka {

// 原本の bytes と出典を値所有する。未知形式もこの型で保全できる。
struct GalaxyCatalogSource {
    std::filesystem::path path;
    std::vector<std::uint8_t> bytes;
};
GalaxyCatalogSource load_galaxy_catalog_source(
    const std::filesystem::path& path, CatalogLoadLimits limits = {});

struct PlusGlobularClusterRecord {
    // NUL 後にも原値があるため、C string に切り詰めない。
    std::array<std::uint8_t, 12> name_bytes{};
    float right_ascension_degrees = 0, declination_degrees = 0;
    float distance_pc = 0, core_radius_pc = 0, half_light_radius_pc = 0;
    float color_b_minus_v = 0, color_v_minus_r = 0;
};
struct PlusGlobularClusterCatalog {
    GalaxyCatalogSource source;
    std::vector<PlusGlobularClusterRecord> records;
};

struct PlusNearbyGalaxyRecord {
    float right_ascension_degrees = 0, declination_degrees = 0;
    float distance_pc = 0, angular_diameter_arcminutes = 0, minor_major_axis_ratio = 0;
    // 通常版の形態番号/bar と一致しない。原 byte の意味を補完しない。
    std::uint8_t render_class_code = 0, auxiliary_code = 0, catalog_code = 0;
    std::int32_t catalog_number = 0;
};
struct PlusNearbyGalaxyCatalog {
    GalaxyCatalogSource source;
    std::vector<PlusNearbyGalaxyRecord> records;
};

// Plus 1.5.4 の明示形式。通常版テキスト/gc.dat/NBG2.dat の自動判定はしない。
// 構造不正は CatalogError で全体を拒否。NaN/範囲外などの原行は削除しない。
PlusGlobularClusterCatalog load_plus_globular_clusters(
    const std::filesystem::path& path, CatalogLoadLimits limits = {});
PlusNearbyGalaxyCatalog load_plus_nearby_galaxies(
    const std::filesystem::path& path, CatalogLoadLimits limits = {});

// AU 型と交換できない単位付き位置。原赤道と native J2000 黄道を別に返す。
struct GalaxyEquatorialPositionPc { double x_pc, y_pc, z_pc; };
struct GalaxyNativeEclipticPositionPc { double x_pc, y_pc, z_pc; };
struct GalaxyPositionPc {
    GalaxyEquatorialPositionPc equatorial;
    GalaxyNativeEclipticPositionPc native_ecliptic;
};
enum class GalaxyPositionIssue : std::uint16_t {
    none = 0, nonfinite_ra = 1, ra_out_of_range = 2,
    nonfinite_dec = 4, dec_out_of_range = 8,
    nonfinite_distance = 16, negative_distance = 32, zero_distance = 64
};
using GalaxyPositionIssues = std::uint16_t;
struct GalaxyPositionResult {
    std::optional<GalaxyPositionPc> position;
    GalaxyPositionIssues issues = 0;
};
// 位置と無関係な色/分類/形状の不正値は位置計算を妨げない。
// 黄道傾斜は既存 j2000_obliquity_deg。旧 Plus の逐値再現ではない。
GalaxyPositionResult evaluate_galaxy_position_pc(float ra_deg, float dec_deg, float distance_pc);

enum class GalaxyNameLineKind { blank, comment, entry, unresolved };
struct GalaxyNameLine {
    std::size_t physical_line = 0, byte_offset = 0;
    // 改行を除く原行。CRLF の CR も保持。英名/日本語の境界を推測しない。
    std::string raw_bytes, key_bytes, payload_bytes;
    GalaxyNameLineKind kind = GalaxyNameLineKind::unresolved;
    bool featured = false;
    std::string diagnostic;
};
struct GalaxyNameTable {
    GalaxyCatalogSource source;
    std::vector<GalaxyNameLine> lines;
};
// key と任意 '*' の後ろを未正規化 payload として保持する native 読取契約。
// 全物理行/重複/未知キーを保持し、表間の優先順位や名前解決は行わない。
GalaxyNameTable load_galaxy_name_table(
    const std::filesystem::path& path, CatalogLoadLimits limits = {});

} // namespace mitaka
