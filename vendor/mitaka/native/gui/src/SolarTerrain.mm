#import "SolarSystemViewInternal.h"
#include <exception>
#include <cmath>
#include <stdexcept>

using namespace mitaka::gui;

namespace {
constexpr std::array<std::size_t, 4> terrainBodies{3, 10, 1, 4};
bool sameLandingSite(const LandingKey& a, const LandingKey& b) {
    if (a.root != b.root || a.body != b.body || a.factor != b.factor) return false;
    constexpr double radians = 3.14159265358979323846 / 180;
    const double lat1 = a.latitude * radians, lat2 = b.latitude * radians;
    const double lon1 = a.longitude * radians, lon2 = b.longitude * radians;
    const double c1 = std::cos(lat1), c2 = std::cos(lat2);
    // 視点の往復変換の丸めを吸収し、極で不定の経度を同一地点と扱う。
    return std::hypot(c1 * std::cos(lon1) - c2 * std::cos(lon2),
                      c1 * std::sin(lon1) - c2 * std::sin(lon2),
                      std::sin(lat1) - std::sin(lat2)) <= 2e-11;
}
}

@implementation SolarSystemView (Terrain)
- (NSArray<TerrainSurfaceController *> *)makeTerrainControllers {
    return @[[TerrainSurfaceController new], [TerrainSurfaceController new],
        [TerrainSurfaceController new], [TerrainSurfaceController new]];
}
- (void)setTerrainDataDirectory:(NSString *)directory {
    [self resetLanding];
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
    [self resetLanding];
    [self cancelTerrain];
    self.needsDisplay = YES;
}
- (void)resetLanding {
    [_landingController cancel];
    _landingKey.reset();
    _landingResult.reset();
    _landingSuppressedBody.reset();
    _landingParked = NO;
}
- (void)refreshLanding {
    // 地形を非表示にして基準球を描く間は、視点もその球面に合わせる。
    // 惑星間飛行中は移動元の経路を変えない。
    const auto useReferenceSurface = [&] {
        if (!_surfaceActive || _journeyActive || _navigation.site().terrain_offset_km == 0) return;
        _navigation.update_terrain_offset(0);
        _camera = _navigation.camera(_bodies);
        if (_navigation.flying()) [self restoreFlightOrientation];
        [self notifyCamera];
    };
    if ((!_surfaceActive && !_journeyActive) || !_terrainDataDirectory) {
        if (_landingKey && _physicalSpaceActive && _terrainDataDirectory) {
            if (!_landingParked) {
                _landingParked = YES;
                _landingSuppressedBody.reset();
                [self cancelTerrain];
            }
        } else if (_landingKey) { [self resetLanding]; [self cancelTerrain]; }
        if (!_terrainDataDirectory) useReferenceSurface();
        return;
    }
    const BOOL wasParked = _landingParked;
    _landingParked = NO;
    const auto site = _journeyActive ? _journey.destination() : _navigation.site();
    TerrainBody body;
    switch (site.body_index) {
        case 1: body = TerrainBody::mercury; break;
        case 3: body = TerrainBody::earth; break;
        case 4: body = TerrainBody::mars; break;
        case 10: body = TerrainBody::moon; break;
        default:
            if (_landingKey) { [self resetLanding]; [self cancelTerrain]; }
            useReferenceSurface();
            return;
    }
    LandingKey key{_terrainDataDirectory.fileSystemRepresentation, site.body_index,
        site.latitude_deg, site.longitude_deg, terrain_amplification_factor(_terrainAmplification)};
    if (wasParked && _landingKey && sameLandingSite(*_landingKey, key) &&
        (!_landingResult || _landingResult->status == TerrainSnapshotStatus::failed))
        _landingSuppressedBody = key.body;
    if (!_landingKey || !sameLandingSite(*_landingKey, key)) {
        if (!_landingController) _landingController = [TerrainLandingController new];
        _landingKey = key;
        _landingResult.reset();
        _landingSuppressedBody = key.body;
        useReferenceSurface();
        [self cancelTerrain];
        TerrainLandingRequest request;
        request.data_directory = key.root;
        request.body = body;
        request.latitude_deg = key.latitude;
        request.longitude_deg = key.longitude;
        request.display_radius_km = surface_body_info(key.body).radius_km;
        request.elevation_factor = key.factor;
        __weak SolarSystemView *weakSelf = self;
        try {
            [_landingController requestLanding:request completion:^(TerrainLandingResult result, NSString *error) {
                SolarSystemView *strongSelf = weakSelf;
                if (!strongSelf || !strongSelf->_landingKey || !sameLandingSite(*strongSelf->_landingKey, key)) return;
                if (error) result.diagnostic = error.UTF8String ? error.UTF8String : "terrain landing failed";
                strongSelf->_landingResult = std::move(result);
                [strongSelf refreshLanding];
                strongSelf.needsDisplay = YES;
            }];
        } catch (const std::exception& error) {
            // 不正なデータルート等の同期検証失敗も球面表示と診断に変換する。
            TerrainLandingResult result;
            result.diagnostic = error.what();
            _landingResult = std::move(result);
        }
    }
    // 惑星間飛行は終端が確定するまで地形を隠し、既存の補間経路を変えない。
    if (_journeyActive || !_landingResult) return;
    if (_landingResult->status == TerrainSnapshotStatus::failed) return;
    const double base = surface_body_info(key.body).radius_km;
    const double radius = _landingResult->radius_km.value_or(base);
    double offset;
    const double previousOffset = _navigation.site().terrain_offset_km;
    try {
        if (!std::isfinite(radius)) throw std::invalid_argument("non-finite terrain landing radius");
        offset = radius - base;
        _navigation.update_terrain_offset(offset);
    } catch (const std::invalid_argument& error) {
        _landingResult->status = TerrainSnapshotStatus::failed;
        _landingResult->diagnostic = error.what();
        return;
    }
    if (previousOffset != offset) {
        _camera = _navigation.camera(_bodies);
        if (_navigation.flying()) [self restoreFlightOrientation];
        [self notifyCamera];
    }
    if (_landingSuppressedBody) {
        _landingSuppressedBody.reset();
        [self cancelTerrain];
    }
}
- (void)refreshTerrain {
    if (!_hasData || _sceneUpdateDepth) return;
    [self refreshLanding];
    const auto live = [self scene];
    const BOOL cameraChanged = _publishedScene && ![self matchesDisplayedCamera:live.camera map:live.map];
    if (_hasTerrainViewport && (!NSEqualRects(_terrainViewport, live.map) || _terrainBackingScale != live.backing_scale))
        [self cancelTerrain];
    if (_publishedScene && _publishedScene->scene().julian_date != live.julian_date)
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
    if (!_publishedScene) {
        // 未完成の古い地形が後から新しい日時を上書きしない基準フレーム。
        if (cameraChanged) [_galaxyOverlay invalidatePendingPicks];
        _publishedScene = std::make_shared<SolarSceneOwner>(candidate.owner);
        [self redrawPublishedScene];
    }
    TerrainSceneCoordinator::Mask requested;
    const auto scene = candidate.owner.scene();
    for (std::size_t slot = 0; slot < terrainBodies.size(); ++slot) {
        const auto index = terrainBodies[slot];
        if (_landingSuppressedBody == index || !_terrainDataDirectory || !scene.planet_display.visible ||
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
    if (_landingSuppressedBody && _landingResult && !_landingResult->diagnostic.empty())
        result.push_back("Terrain: " + _landingResult->diagnostic + "（基準球面または不透明な代替表示）");
    for (const auto index : terrainBodies) {
        if (!_terrainErrors[index].empty()) result.push_back("Terrain: " + _terrainErrors[index] + "（基準球面または不透明な代替表示）");
        else if (const auto& snapshot = _terrainSnapshots[index]) {
            if (!snapshot->diagnostic.empty()) result.push_back("Terrain: " +
                terrain_source_relative_path(snapshot->request.body).string() + ": " + snapshot->diagnostic +
                (snapshot->status == TerrainSnapshotStatus::ready ? "" : "（基準球面または不透明な代替表示）"));
        } else if (_terrainRequests[index]) {
            result.push_back("Terrain: " + terrain_source_relative_path(_terrainRequests[index]->body).string() +
                " を計算中（基準球面または不透明な代替表示）");
        }
    }
    return result;
}
@end

#import "SolarDateUpdate.h"
#include <cmath>
#include <stdexcept>
#include <type_traits>

namespace mitaka::gui {
static_assert(std::is_nothrow_swappable_v<SolarBodies> && std::is_nothrow_swappable_v<SolarOrbits> &&
    std::is_nothrow_swappable_v<GridGeometryCache> && std::is_nothrow_swappable_v<SurfaceNavigation> &&
    std::is_nothrow_swappable_v<InterplanetaryFlight>, "date commit swaps must not throw");

struct PreparedSolarDate {
    SolarBodies bodies;
    SolarOrbits orbits;
    std::vector<Vec3> lunar_orbit;
    GridGeometryCache grid;
    double julian_date;
    SolarCamera camera;
    SurfaceNavigation navigation;
    InterplanetaryFlight journey;
    bool journey_active, surface_active, following, journey_finished = false;
    std::optional<std::size_t> small_selection, satellite_selection, spacecraft_selection;
    std::shared_ptr<const SmallBodySnapshot> small;
    std::shared_ptr<const SmallBodyDisplayModel> small_display;
    std::shared_ptr<const SmallBodyOrbitSnapshot> small_orbits;
    std::shared_ptr<const SatelliteSnapshot> satellites;
    std::shared_ptr<const SatelliteDisplayModel> satellite_display;
    std::shared_ptr<const SatelliteOrbitGeometry> satellite_orbits;
    std::shared_ptr<const SpacecraftSnapshot> spacecraft;
    std::shared_ptr<SolarSceneOwner> scene;
};
}

@implementation SolarSystemView (DateUpdate)
- (std::shared_ptr<PreparedSolarDate>)prepareDateUpdate:(const SolarDateInput&)input {
    using namespace mitaka;
    auto p = std::make_shared<PreparedSolarDate>();
    p->bodies = input.bodies;
    p->orbits = input.refresh_orbits ? input.orbits : _orbits;
    p->lunar_orbit = input.refresh_orbits ? input.lunar_orbit : _lunarOrbit;
    p->grid = _gridCache; p->grid.set_observation(input.site, input.julian_date);
    p->julian_date = input.julian_date; p->camera = _camera;
    p->navigation = _navigation; p->journey = _journey;
    p->journey_active = _journeyActive; p->surface_active = _surfaceActive; p->following = _following;
    p->small_selection = _smallBodySelection; p->satellite_selection = _satelliteSelection; p->spacecraft_selection = _spacecraftSelection;
    p->small = input.small_bodies; p->small_display = input.small_body_display; p->small_orbits = _smallBodyOrbits;
    p->satellites = input.satellites.snapshot(); p->satellite_display = input.satellites.display(); p->satellite_orbits = input.satellites.orbits(); p->spacecraft = input.spacecraft;
    if (p->small && (!p->small->model || p->small->positions.size() != p->small->model->dataset().records.size()))
        throw std::invalid_argument("small-body snapshot does not match its dataset");
    if (p->small_display && p->small && p->small_display->dataset().get() != &p->small->model->dataset())
        throw std::invalid_argument("small-body display/model mismatch");
    if (p->spacecraft) {
        if (!p->spacecraft->model || p->spacecraft->positions.size() != p->spacecraft->model->model().dataset().definitions.size() ||
            p->spacecraft->evaluations.size() != p->spacecraft->positions.size() || !std::isfinite(p->spacecraft->julian_date))
            throw std::invalid_argument("spacecraft snapshot does not match its dataset");
        for (const auto& pos : p->spacecraft->positions)
            if (pos && (!std::isfinite(pos->x) || !std::isfinite(pos->y) || !std::isfinite(pos->z)))
                throw std::invalid_argument("spacecraft snapshot position must be finite");
    }
    if (!p->small || !_smallBodySnapshot || p->small->model != _smallBodySnapshot->model) {
        if (p->small_selection && !_selection) p->following = false;
        p->small_selection.reset();
    }
    if (p->small_display != _smallBodyDisplay) p->small_orbits.reset();
    if (!p->satellites || !_satelliteSnapshot || p->satellites->model != _satelliteSnapshot->model) {
        if (p->satellite_selection && !_selection) p->following = false;
        p->satellite_selection.reset();
    }
    if (!p->spacecraft || !_spacecraftSnapshot || p->spacecraft->model != _spacecraftSnapshot->model) {
        if (p->spacecraft_selection && !_selection) p->following = false;
        p->spacecraft_selection.reset();
    }
    if (p->journey_active && p->journey.flying()) {
        p->journey.advance(_lastFlightTime, p->bodies); p->camera = p->journey.camera();
        if (!p->journey.flying()) {
            p->journey_finished = true;
            if (p->journey.completed()) {
                p->navigation.set_site(p->journey.destination()); p->surface_active = true; p->journey_active = false;
            }
        }
    } else if (!p->journey_active && p->surface_active) p->camera = p->navigation.camera(p->bodies);
    auto old = [self scene];
    SolarScene next{p->bodies, p->orbits, p->lunar_orbit, p->camera, old.textures, old.selection, old.map, old.backing_scale,
        old.earth_moon, old.preview_body, p->surface_active ? std::optional<std::size_t>(p->navigation.site().body_index) : std::nullopt,
        p->journey_active || p->surface_active || static_cast<bool>(_physicalSpaceActive), nullptr, !_selection ? p->small_selection : std::nullopt,
        old.planet_display, old.grid_display, &p->grid, old.renderer_display, nullptr,
        !_selection ? p->satellite_selection : std::nullopt, nullptr, !_selection ? p->spacecraft_selection : std::nullopt,
        old.spacecraft_display, p->small_display.get(), p->small_orbits.get(), p->satellite_display.get(), p->satellite_orbits.get(),
        old.earth_layers, old.atmosphere, old.eclipse_options, p->julian_date, p->satellites.get(), nullptr, old.terrain_amplification, old.radius_display};
    if (!p->journey_active && !p->surface_active) {
        if (_earthMoonMode && _earthMoonFollowing) {
            const auto earth = solar_display_position(next, 3), moon = solar_display_position(next, 10);
            p->camera.set_target_au({(earth.x + moon.x)/2, (earth.y + moon.y)/2, (earth.z + moon.z)/2});
        } else if (p->following && _selection) {
            p->camera.set_target_au(_scriptSpacePlace && *_selection == 3
                ? [self scriptSpacePlacePositionForBodies:p->bodies] : solar_display_position(next, *_selection));
        }
        else if (p->following && p->small_selection && p->small) {
            const auto& pos = p->small->positions.at(*p->small_selection); if (pos) p->camera.set_target_au(*pos); else p->following = false;
        } else if (p->following && p->satellite_selection && p->satellites) {
            const auto& pos = p->satellites->positions.at(*p->satellite_selection); if (pos) p->camera.set_target_au(*pos); else p->following = false;
        } else if (p->following && p->spacecraft_selection && p->spacecraft) {
            const auto pos = spacecraft_scene_position(*p->spacecraft, *p->spacecraft_selection); if (pos) p->camera.set_target_au(*pos); else p->following = false;
        }
    }
    if (_earthMoonMode) {
        const auto basis = solar_camera_basis(p->camera);
        for (const std::size_t index : {std::size_t(3), std::size_t(10)}) {
            const Vec3 center = solar_display_position(next, index);
            const Vec3 offset{p->camera.target.x-center.x, p->camera.target.y-center.y, p->camera.target.z-center.z};
            const double radius = (surface_body_info(index).radius_km + minimum_surface_height_km) / astronomical_unit_km;
            const Vec3 eye{offset.x + basis.outward.x*p->camera.distance_au, offset.y + basis.outward.y*p->camera.distance_au, offset.z + basis.outward.z*p->camera.distance_au};
            if (std::hypot(eye.x, eye.y, eye.z) <= radius) {
                const double along = offset.x*basis.outward.x + offset.y*basis.outward.y + offset.z*basis.outward.z;
                const double squared = offset.x*offset.x + offset.y*offset.y + offset.z*offset.z;
                p->camera.distance_au = -along + std::sqrt(std::max(0.0, along*along - squared + radius*radius)) + 1e-10;
            }
        }
    }
    const bool general = !_earthMoonMode && !_surfacePreview && !p->surface_active && !p->journey_active;
    next.small_bodies = general && _smallBodiesVisible && p->small && p->small_display ? p->small.get() : nullptr;
    next.satellites = general && p->satellites && p->satellite_display && p->satellite_display->options().visible ? p->satellites.get() : nullptr;
    next.spacecraft = general && _spacecraftVisible && p->spacecraft ? p->spacecraft.get() : nullptr;
    SolarSceneResources resources{_textures, next.small_bodies ? p->small : nullptr, next.satellites ? p->satellites : nullptr,
        next.spacecraft ? p->spacecraft : nullptr, p->small_display, p->small_orbits, p->satellite_display, p->satellite_orbits, p->satellites};
    p->scene = std::make_shared<SolarSceneOwner>(next, std::move(resources)); p->scene->set_terrain({});
    return p;
}
- (void)commitDateUpdate:(std::shared_ptr<PreparedSolarDate>)p {
    const auto next = p->scene->scene();
    const BOOL cameraChanged = ![self matchesDisplayedCamera:next.camera map:next.map];
    [self cancelTerrain];
    if (cameraChanged) [_galaxyOverlay invalidatePendingPicks];
    using std::swap;
    swap(_bodies, p->bodies); swap(_orbits, p->orbits); swap(_lunarOrbit, p->lunar_orbit); swap(_gridCache, p->grid);
    _julianDate = p->julian_date; _camera = p->camera; swap(_navigation, p->navigation); swap(_journey, p->journey);
    _journeyActive = p->journey_active; _surfaceActive = p->surface_active; _following = p->following;
    _smallBodySelection = p->small_selection; _satelliteSelection = p->satellite_selection; _spacecraftSelection = p->spacecraft_selection;
    _smallBodySnapshot.swap(p->small); _smallBodyDisplay.swap(p->small_display); _smallBodyOrbits.swap(p->small_orbits);
    _satelliteSnapshot.swap(p->satellites); _satelliteDisplay.swap(p->satellite_display); _satelliteOrbits.swap(p->satellite_orbits);
    _spacecraftSnapshot.swap(p->spacecraft); _publishedScene.swap(p->scene); _hasData = YES;
    _dateJourneyFinished = p->journey_finished;
    if (p->journey_finished) {
        [self invalidateFlightTimer];
        if (_journey.completed()) _flightNotice = @"連続飛行完了";
        else switch (_journey.stop_reason()) {
            case FlightStopReason::clock_discontinuity: _flightNotice = @"飛行を停止（時間の空白）"; break;
            case FlightStopReason::collision: _flightNotice = @"飛行を停止（経路上の天体）"; break;
            default: _flightNotice = @"飛行を停止 · 現在位置から再開できます"; break;
        }
    }
}
- (void)finishDateUpdate {
    if (_dateJourneyFinished) {
        _dateJourneyFinished = NO;
        if (self.navigationChanged) self.navigationChanged();
    }
    [self notifySelection]; [self notifyCamera]; self.needsDisplay = YES;
}
- (void)invalidatePendingDateTerrain {
    for (TerrainSurfaceController *controller in _terrainControllers) [controller cancel];
    _terrainSceneCoordinator.invalidate();
    _submittedSceneRevision = _sceneRevision;
    const auto displayed = _publishedScene;
    const auto revision = _sceneRevision;
    if (!displayed) return;
    __weak SolarSystemView *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        SolarSystemView *strongSelf = weakSelf;
        if (!strongSelf || strongSelf->_publishedScene != displayed || strongSelf->_sceneRevision != revision) return;
        try { [strongSelf retryDisplayedTerrain:displayed revision:revision]; }
        catch (const std::exception& error) { NSLog(@"Terrain retry failed: %s", error.what()); }
    });
}
- (void)retryDisplayedTerrain:(const std::shared_ptr<SolarSceneOwner>&)displayed revision:(std::uint64_t)revision {
    if (!_terrainControllers) _terrainControllers = [self makeTerrainControllers];
    TerrainSceneCandidate candidate{*displayed, {}, {}, revision};
    candidate.owner.set_terrain({});
    const auto scene = candidate.owner.scene();
    TerrainSceneCoordinator::Mask requested;
    for (std::size_t slot = 0; slot < terrainBodies.size(); ++slot) {
        const auto index = terrainBodies[slot];
        if (_landingSuppressedBody == index || !_terrainDataDirectory || !scene.planet_display.visible ||
            (!scene.physical_navigation && !scene.earth_moon && !scene.surface_body)) continue;
        try {
            candidate.requests[slot] = solar_terrain_request(scene, index, _terrainDataDirectory.fileSystemRepresentation);
            if (candidate.requests[slot]) requested.set(slot);
        } catch (const std::exception& error) { candidate.errors[slot] = error.what(); }
    }
    [self applyTerrainTransition:_terrainSceneCoordinator.submit(
        std::make_shared<const TerrainSceneCandidate>(std::move(candidate)), requested)];
}
@end
