#pragma once

#include "mitaka/astronomy.hpp"
#include "mitaka/terrain.hpp"

#include <array>
#include <functional>
#include <optional>
#include <vector>

namespace mitaka::gui {

struct TerrainVertex {
    // Rdataで正規化した位置。Rdisplayの乗算・天体回転・平行移動は描画境界で行う。
    Vec3 position;
    Vec3 normal;
    // u=東経/360（継ぎ目でwrapしない）、v=.5-北緯/180（画像の上が北）。
    // 画像固有の経度offsetは位置を回転せず、texture標本化時だけ適用する。
    double u = 0, v = 0;
};

class TerrainPatchMesh {
public:
    std::size_t patch_index() const noexcept { return patch_; }
    std::size_t level_index() const noexcept { return level_; }
    std::size_t columns() const noexcept { return columns_; }
    std::size_t rows() const noexcept { return rows_; }
    const std::vector<TerrainVertex>& vertices() const noexcept { return vertices_; }
    std::size_t triangle_count() const noexcept { return columns_ * rows_ * 2; }
    // 原版の行方向triangle stripと同じ対角線・外向き順序。極の退化三角形も保持する。
    std::array<std::size_t, 3> triangle(std::size_t ordinal) const;

private:
    friend TerrainPatchMesh make_terrain_patch_mesh(TerrainFile&, std::size_t, std::size_t, double, std::size_t);
    std::size_t patch_ = 0, level_ = 0, columns_ = 0, rows_ = 0;
    std::vector<TerrainVertex> vertices_;
};

// 原版の半径式とhalo法線をdoubleで評価する。元float演算とのbit一致は主張しない。
// 対応header/gridはsourceから一緒に取得し、callerが別出典を組み合わせる余地をなくす。
// 所有量は1mesh＋halo3行。max_working_bytesはその合計（sourceの索引/gridは別）。
// 不正値/非正半径/法線退化/上限超過はinvalid_argument。原本のI/OエラーはCatalogError。
TerrainPatchMesh make_terrain_patch_mesh(TerrainFile& source, std::size_t patch_index,
    std::size_t level_index, double elevation_factor = 1,
    std::size_t max_working_bytes = 8 * 1024 * 1024);

enum class TerrainSurfaceMode { none, sphere, terrain };

// eyeは天体固定座標、Rdisplay単位。datum内/上はnone、遠方は原版6度規則でsphere。
TerrainSurfaceMode terrain_surface_mode(Vec3 eye);
// .13度×2^levelの原版閾値。格子寸法やstored_levelではなく原ordinalを返す。
std::size_t terrain_level_index(const TerrainPatch& patch, Vec3 eye, bool low_resolution = false);

} // namespace mitaka::gui

namespace mitaka::gui {
// 各LODの三角形と中心からの視線の交点のうち、最も外側の半径を返す。
// 描画倍率・display_radiusは描画と同じ値。交点なしはnullopt。
// 地形ソースは呼出側が安全に開き、専有している必要がある。
std::optional<double> terrain_landing_radius_km(TerrainFile& source,
    double latitude_deg, double longitude_deg, double display_radius_km, double elevation_factor,
    const std::function<bool()>& cancelled = {});
} // namespace mitaka::gui
