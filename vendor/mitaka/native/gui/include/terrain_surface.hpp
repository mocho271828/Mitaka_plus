#pragma once

#include "terrain_mesh.hpp"
#include "solar_camera.hpp"
#include "mitaka/rotation.hpp"

#include <limits>
#include <functional>
#include <stdexcept>

namespace mitaka::gui {

struct TerrainSurfaceBinding {
    TerrainFile& source;
    Vec3 center_au;
    BodyOrientation orientation;
    // 基準球の表示半径。物理半径・data headerを変更せず、(1+factor*h/Rdata)へ乗算する。
    double display_radius_au;
    double elevation_factor = 1;
    bool low_resolution = false;
};

struct TerrainSurfaceLimits {
    std::size_t frame_bytes = 64 * 1024 * 1024;
    std::size_t mesh_bytes = 8 * 1024 * 1024;
    std::size_t triangles = 8 * 1024 * 1024;
    std::size_t pixel_tests = 64 * 1024 * 1024;
};

struct TerrainSurfaceSample {
    // 単位視線に沿う正距離AU。未被覆は+infinity。camera forwardのzとは異なる。
    double distance_au = std::numeric_limits<double>::infinity();
    Vec3 normal_local{0, 0, 0};
    double u = 0, v = 0;
};

struct TerrainSurfaceFrame {
    TerrainSurfaceMode mode = TerrainSurfaceMode::none;
    int width = 0, height = 0;
    std::vector<TerrainSurfaceSample> samples;
    std::size_t patches_read = 0, triangles_visited = 0, pixel_tests = 0;
};

class TerrainSurfaceCancelled : public std::runtime_error {
public:
    TerrainSurfaceCancelled() : std::runtime_error("terrain surface request cancelled") {}
};

// 同editionの明示sourceだけを使う純CPU描画。terrain以外ではsamplesは空。
// terrainでは画錐外と確定できないpatchを1個ずつ読み、投影/near切断は既存SolarCamera APIに委譲する。
// 出力は三角形面のperspective-correct depth/normal/UV。透明度・照明・textureは別責務。
// 負標高を保持するため、統合側は同天体のanalytic datum sphereをopaque passから除く。
// その上で他天体/地形の最短正距離と比較し、確定depthを大気・雲へ引き渡す。
// 全処理/末尾のsource検証成功後だけ値を返す。上限超過/不正値はinvalid_argument、
// I/O/変更検出はCatalogError。失敗時に部分frameや黙ったsphere fallbackを公開しない。
TerrainSurfaceFrame render_terrain_surface(const TerrainSurfaceBinding& binding,
    const SolarCamera& camera, int width, int height, const TerrainSurfaceLimits& limits = {},
    const std::function<bool()>& cancelled = {});

} // namespace mitaka::gui
