#import "SolarSystemViewInternal.h"
#include <exception>

using namespace mitaka::gui;

namespace {
constexpr std::array<std::size_t, 4> terrainBodies{3, 10, 1, 4};
}

@implementation SolarSystemView (Terrain)
- (void)setTerrainDataDirectory:(NSString *)directory {
    [self cancelTerrain];
    _terrainDataDirectory = [directory copy];
    self.needsDisplay = YES;
}
- (void)cancelTerrain {
    for (TerrainSurfaceController *controller in _terrainControllers) [controller cancel];
    _terrainRequests = {};
    _terrainSnapshots = {};
    _terrainErrors = {};
}
- (void)reloadTerrain {
    [self cancelTerrain];
    self.needsDisplay = YES;
}
- (void)refreshTerrain {
    const auto scene = [self scene];
    if (!_hasData || !_terrainDataDirectory || !scene.planet_display.visible ||
        (!scene.physical_navigation && !scene.earth_moon && !scene.surface_body)) {
        [self cancelTerrain];
        return;
    }
    if (!_terrainControllers) {
        _terrainControllers = @[[TerrainSurfaceController new], [TerrainSurfaceController new],
            [TerrainSurfaceController new], [TerrainSurfaceController new]];
    }
    for (std::size_t slot = 0; slot < terrainBodies.size(); ++slot) {
        const auto index = terrainBodies[slot];
        TerrainSurfaceController *controller = _terrainControllers[slot];
        try {
            const auto request = solar_terrain_request(scene, index, _terrainDataDirectory.fileSystemRepresentation);
            if (!request) {
                [controller cancel];
                _terrainRequests[index].reset();
                _terrainSnapshots[index].reset();
                _terrainErrors[index].clear();
                continue;
            }
            // 描画のたびに同じI/Oを再発行しない。明示再読込ではこのkeyも取り消す。
            if (_terrainRequests[index] && terrain_surface_request_matches(*request, *_terrainRequests[index])) continue;
            _terrainRequests[index] = request;
            _terrainSnapshots[index].reset();
            _terrainErrors[index].clear();
            __weak SolarSystemView *weakSelf = self;
            [controller requestSurface:*request completion:^(std::shared_ptr<const TerrainSurfaceSnapshot> snapshot, NSString *error) {
                SolarSystemView *strongSelf = weakSelf;
                if (!strongSelf || !strongSelf->_terrainRequests[index] ||
                    !terrain_surface_request_matches(*request, *strongSelf->_terrainRequests[index])) return;
                strongSelf->_terrainSnapshots[index] = std::move(snapshot);
                strongSelf->_terrainErrors[index] = error ? error.UTF8String : "";
                strongSelf.needsDisplay = YES;
            }];
        } catch (const std::exception& error) {
            [controller cancel];
            _terrainRequests[index].reset();
            _terrainSnapshots[index].reset();
            _terrainErrors[index] = error.what();
        }
    }
}
- (std::vector<std::string>)terrainDiagnostics {
    std::vector<std::string> result;
    for (const auto index : terrainBodies) {
        if (!_terrainErrors[index].empty()) result.push_back("Terrain: " + _terrainErrors[index] + "（基準球面を表示）");
        else if (const auto& snapshot = _terrainSnapshots[index]) {
            if (!snapshot->diagnostic.empty()) result.push_back("Terrain: " +
                terrain_source_relative_path(snapshot->request.body).string() + ": " + snapshot->diagnostic +
                (snapshot->status == TerrainSnapshotStatus::ready ? "" : "（基準球面を表示）"));
        } else if (_terrainRequests[index]) {
            result.push_back("Terrain: " + terrain_source_relative_path(_terrainRequests[index]->body).string() +
                " を計算中（基準球面を表示）");
        }
    }
    return result;
}
@end
