#pragma once

#import "SolarSceneOwner.h"
#include "terrain_generation_coordinator.hpp"
#include "terrain_snapshot.hpp"

struct TerrainSceneCandidate {
    SolarSceneOwner owner;
    std::array<std::optional<mitaka::gui::TerrainSurfaceRequest>, 4> requests;
    std::array<std::string, 4> errors;
    std::uint64_t revision;
};

struct TerrainSceneResult {
    std::shared_ptr<const mitaka::gui::TerrainSurfaceSnapshot> snapshot;
    std::string error;
};

using TerrainSceneCoordinator = mitaka::gui::TerrainGenerationCoordinator<TerrainSceneCandidate, TerrainSceneResult, 4>;
