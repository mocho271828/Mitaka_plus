#pragma once
#include "satellite_browser_model.hpp"

namespace mitaka::gui {
struct SatelliteOrbitRow {
    std::vector<Vec3> points_au;
    std::string diagnostic;
};
struct SatelliteOrbitGeometry {
    std::shared_ptr<const SatelliteSnapshot> snapshot;
    // 全原行と同数・同順。未対応・未評価行は点を持たず診断を保持する。
    std::vector<SatelliteOrbitRow> rows;
};

// 同日時の親・軌道面を固定した瞬時楕円。時刻を進める日心軌跡ではない。
// 旧版の描画標本数や線形状の同一性は主張しない。Moon 専用解析は対象外。
std::shared_ptr<const SatelliteOrbitGeometry> satellite_orbit_geometry(
    std::shared_ptr<const SatelliteSnapshot> snapshot);
} // namespace mitaka::gui
