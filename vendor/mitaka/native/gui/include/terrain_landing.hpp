#pragma once

#include "terrain_snapshot.hpp"

namespace mitaka::gui {

struct TerrainLandingRequest {
    std::filesystem::path data_directory;
    TerrainBody body = TerrainBody::earth;
    double latitude_deg = 0;
    double longitude_deg = 0;
    double display_radius_km = 0;
    double elevation_factor = 1;
    TerrainLoadLimits load_limits;
};

struct TerrainLandingResult {
    TerrainSnapshotStatus status = TerrainSnapshotStatus::failed;
    // No intersection means that no terrain offset is applied.
    std::optional<double> radius_km;
    std::string diagnostic;
};

void validate_terrain_landing_request(const TerrainLandingRequest& request);
TerrainLandingResult prepare_terrain_landing(const TerrainLandingRequest& request,
                                            const std::function<bool()>& cancelled = {});

} // namespace mitaka::gui
