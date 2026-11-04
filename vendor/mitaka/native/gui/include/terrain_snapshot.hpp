#pragma once

#include "terrain_surface.hpp"

#include <memory>
#include <string>

namespace mitaka::gui {

enum class TerrainBody { earth, moon, mercury, mars };

struct TerrainSurfaceRequest {
    // Appで明示選択したdataディレクトリ。別editionや既定directoryを探索しない。
    std::filesystem::path data_directory;
    TerrainBody body = TerrainBody::earth;
    double julian_date = 2451545;
    Vec3 center_au{0,0,0};
    BodyOrientation orientation;
    double display_radius_au = 1;
    double elevation_factor = 1;
    bool low_resolution = false;
    SolarCamera camera;
    int width = 0, height = 0;
    TerrainLoadLimits load_limits;
    TerrainSurfaceLimits surface_limits;
};

enum class TerrainSnapshotStatus { ready, unavailable, failed };

struct TerrainSurfaceSnapshot {
    // 世代と要求全体にsource identityを加えたkey。JDが違えば同じcameraでも別要求。
    std::uint64_t generation = 0;
    TerrainSurfaceRequest request;
    std::filesystem::path source_path, resolved_data_directory;
    std::optional<TerrainSourceIdentity> source_identity;
    std::optional<TerrainHeader> source_header;
    TerrainSnapshotStatus status = TerrainSnapshotStatus::failed;
    std::string diagnostic;
    TerrainSurfaceFrame frame;
};

// requestの数値・姿勢・viewport・予算を同期検証する。I/Oは行わない。
void validate_terrain_surface_request(const TerrainSurfaceRequest& request);
// source identityはsnapshotに別途保持する。これは全要求値の厳密比較だけを行う。
bool terrain_surface_request_matches(const TerrainSurfaceRequest& a, const TerrainSurfaceRequest& b);
// 固定body→相対名だけを解決する。未知bodyは拒否し、存在検査やfallbackは行わない。
std::filesystem::path terrain_source_relative_path(TerrainBody body);

// 最大1索引/1原格子/1派生mesh/1frameを所有して完了値だけ返す。戻り値にmutable aliasは残さない。
// 失敗にも要求と出典名を保持する。欠損=unavailable、破損/越境/上限=failed。
// 取消はTerrainSurfaceCancelled。公開snapshotは原本の全bytesコピーや暗号学的証明ではない。
std::shared_ptr<const TerrainSurfaceSnapshot> prepare_terrain_surface_snapshot(
    const TerrainSurfaceRequest& request, std::uint64_t generation,
    const std::function<bool()>& cancelled = {});

} // namespace mitaka::gui
