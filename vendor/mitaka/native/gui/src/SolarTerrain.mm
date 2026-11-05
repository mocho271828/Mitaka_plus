#import "SolarSystemViewInternal.h"
#include <exception>

using namespace mitaka::gui;

namespace {
constexpr std::array<std::size_t, 4> terrainBodies{3, 10, 1, 4};
}

@implementation SolarSystemView (Terrain)
- (NSArray<TerrainSurfaceController *> *)makeTerrainControllers {
    return @[[TerrainSurfaceController new], [TerrainSurfaceController new],
        [TerrainSurfaceController new], [TerrainSurfaceController new]];
}
- (void)setTerrainDataDirectory:(NSString *)directory {
    [self cancelTerrain];
    _terrainDataDirectory = [directory copy];
    self.needsDisplay = YES;
}
- (void)cancelTerrain {
    for (TerrainSurfaceController *controller in _terrainControllers) [controller cancel];
    _terrainSceneCoordinator.invalidate();
    _publishedScene.reset();
    _hasTerrainViewport = NO;
    _submittedSceneRevision = 0;
    _terrainRequests = {};
    _terrainSnapshots = {};
    _terrainErrors = {};
}
- (void)reloadTerrain {
    [self cancelTerrain];
    self.needsDisplay = YES;
}
- (void)refreshTerrain {
    if (!_hasData || _sceneUpdateDepth) return;
    const auto live = [self scene];
    if (_hasTerrainViewport && (!NSEqualRects(_terrainViewport, live.map) || _terrainBackingScale != live.backing_scale))
        [self cancelTerrain];
    _terrainViewport = live.map;
    _terrainBackingScale = live.backing_scale;
    _hasTerrainViewport = YES;
    if (_submittedSceneRevision == _sceneRevision && _submittedSceneRevision != 0) return;
    if (!_terrainControllers) {
        _terrainControllers = [self makeTerrainControllers];
    }
    SolarSceneResources resources{_textures,
        live.small_bodies ? _smallBodySnapshot : nullptr,
        live.satellites ? _satelliteSnapshot : nullptr,
        live.spacecraft ? _spacecraftSnapshot : nullptr,
        _smallBodyDisplay, _smallBodyOrbits, _satelliteDisplay, _satelliteOrbits, _satelliteSnapshot};
    TerrainSceneCandidate candidate{SolarSceneOwner(live, std::move(resources)), {}, {}, _sceneRevision};
    candidate.owner.set_terrain({});
    TerrainSceneCoordinator::Mask requested;
    const auto scene = candidate.owner.scene();
    for (std::size_t slot = 0; slot < terrainBodies.size(); ++slot) {
        const auto index = terrainBodies[slot];
        if (!_terrainDataDirectory || !scene.planet_display.visible ||
            (!scene.physical_navigation && !scene.earth_moon && !scene.surface_body)) continue;
        try {
            candidate.requests[slot] = solar_terrain_request(scene, index, _terrainDataDirectory.fileSystemRepresentation);
            if (candidate.requests[slot]) requested.set(slot);
        } catch (const std::exception& error) {
            candidate.errors[slot] = error.what();
        }
    }
    _submittedSceneRevision = _sceneRevision;
    [self applyTerrainTransition:_terrainSceneCoordinator.submit(
        std::make_shared<const TerrainSceneCandidate>(std::move(candidate)), requested)];
}
- (SolarScene)displayedScene { return _publishedScene ? _publishedScene->scene() : [self scene]; }
- (void)applyTerrainTransition:(TerrainSceneCoordinator::Transition)transition {
    for (const auto& publication : transition.published) {
        const auto latest = _terrainSceneCoordinator.published();
        if (!latest || latest->ticket != publication->ticket) continue;
        auto owner = std::make_shared<SolarSceneOwner>(publication->scene->owner);
        SolarSceneOwner::TerrainFrames frames{};
        _terrainRequests = {};
        _terrainErrors = {};
        for (std::size_t slot = 0; slot < terrainBodies.size(); ++slot) {
            const auto index = terrainBodies[slot];
            _terrainRequests[index] = publication->scene->requests[slot];
            _terrainErrors[index] = publication->scene->errors[slot];
            if (publication->results[slot]) {
                frames[index] = publication->results[slot]->snapshot;
                _terrainErrors[index] = publication->results[slot]->error;
            }
        }
        _terrainSnapshots = frames;
        owner->set_terrain(std::move(frames));
        const auto scene = owner->scene();
        if (![self matchesDisplayedCamera:scene.camera map:scene.map]) [_galaxyOverlay invalidatePendingPicks];
        _publishedScene = std::move(owner);
        [self redrawPublishedScene];
    }
    if (!transition.start) return;
    const auto start = *transition.start;
    for (std::size_t slot = 0; slot < terrainBodies.size(); ++slot) {
        if (!start.requested.test(slot) || !_terrainSceneCoordinator.is_active(start.ticket)) continue;
        const auto request = *start.scene->requests[slot];
        __weak SolarSystemView *weakSelf = self;
        try {
            [_terrainControllers[slot] requestSurface:request completion:^(std::shared_ptr<const TerrainSurfaceSnapshot> snapshot, NSString *error) {
                SolarSystemView *strongSelf = weakSelf;
                if (!strongSelf) return;
                TerrainSceneResult result{std::move(snapshot), error ? error.UTF8String : ""};
                [strongSelf applyTerrainTransition:strongSelf->_terrainSceneCoordinator.complete(start.ticket, slot, std::move(result))];
            }];
        } catch (const std::exception& error) {
            [self applyTerrainTransition:_terrainSceneCoordinator.complete(start.ticket, slot, TerrainSceneResult{nullptr, error.what()})];
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
