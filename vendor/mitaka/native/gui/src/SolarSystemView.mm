#include "surface_star_pick.hpp"
#include "constellation_pick.hpp"
#import "RendererQuality.h"
#import "SolarSystemViewInternal.h"
bool solar_scene_opaque_at(const SolarScene& scene, NSPoint point);
#import "SkyView.h"
#import "SolarSceneRenderer.h"
#import "SmallBodyRenderer.h"
#import "SatelliteRenderer.h"
#import "GalaxyOverlay.h"
#import "ConstellationRenderer.h"
#import "ConstellationArtRenderer.h"
#include "shared_camera.hpp"
#include "surface_sky_site.hpp"
#include "our_galaxy_navigation.hpp"
#include "mitaka/astronomy.hpp"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <exception>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

static NSDictionary<NSAttributedStringKey, id> *textStyle(NSColor *color, CGFloat size) {
    return @{ NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:size weight:NSFontWeightRegular],
              NSForegroundColorAttributeName: color };
}

using CameraChange = void (^)(SolarCamera&);

static bool sameCamera(const SolarCamera& a, const SolarCamera& b) {
    const auto sameVector = [](Vec3 x, Vec3 y) { return x.x == y.x && x.y == y.y && x.z == y.z; };
    if (a.precise_target.has_value() != b.precise_target.has_value() ||
        (a.precise_target && (!sameVector(a.precise_target->anchor_pc, b.precise_target->anchor_pc) ||
                              !sameVector(a.precise_target->offset_au, b.precise_target->offset_au))) ||
        !sameVector(a.target, b.target) || a.distance_au != b.distance_au || a.frame_is_orbit != b.frame_is_orbit ||
        a.vertical_fov_deg != b.vertical_fov_deg) return false;
    const auto x = solar_camera_basis(a), y = solar_camera_basis(b);
    return sameVector(x.outward, y.outward) && sameVector(x.right, y.right) && sameVector(x.up, y.up);
}

@implementation SolarSystemView

- (void)setTargetSelectionMode:(NSInteger)mode {
    if (_targetSelectionMode == mode) return;
    _targetSelectionMode = mode;
    [_galaxyOverlay invalidatePendingPicks];
    [self updateTrackingAreas];
}
- (void)updateTrackingAreas {
    if (_targetSelectionTrackingArea) [self removeTrackingArea:_targetSelectionTrackingArea];
    _targetSelectionTrackingArea = nil;
    if (_targetSelectionMode == 1) {
        _targetSelectionTrackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
            options:NSTrackingMouseMoved | NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect owner:self userInfo:nil];
        [self addTrackingArea:_targetSelectionTrackingArea];
        self.window.acceptsMouseMovedEvents = YES;
    }
    [super updateTrackingAreas];
}
- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    if (_targetSelectionMode == 1) self.window.acceptsMouseMovedEvents = YES;
}
- (void)mouseMoved:(NSEvent *)event {
    if (_targetSelectionMode == 1 && !self.hidden)
        [self pickBodyAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
}

- (void)mouseExited:(NSEvent *)event {
    (void)event;
    if (_targetSelectionMode == 1) [_galaxyOverlay invalidatePendingPicks];
}

- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _targetSelectionMode = 2;
        _galaxyOverlay = [[GalaxyOverlay alloc] initWithView:self];
        _hipVisible = YES;
        _surfaceMagnitudeLimit = 6;
        _smallBodiesVisible = YES;
        _terrainAmplification = TerrainAmplification::x1;
        _spacecraftVisible = YES;
        _showsTimeInfo = YES;
        _julianDate = 2451545.0;
        _notifiedOverviewVisible = YES;
        self.accessibilityElement = YES;
        self.accessibilityRole = NSAccessibilityImageRole;
        self.accessibilityLabel = @"太陽系の3D表示。ドラッグで回転、Optionドラッグでロール、Shiftドラッグで移動、スクロールで拡大縮小。";
    }
    return self;
}
- (RendererDisplayOptions)rendererDisplayOptions { return _rendererDisplayOptions; }
- (void)setRendererDisplayOptions:(RendererDisplayOptions)options {
    _rendererDisplayOptions = options;
    self.needsDisplay = YES;
}
- (RadiusDisplayOptions)radiusDisplayOptions { return _radiusDisplayOptions; }
- (void)setRadiusDisplayOptions:(RadiusDisplayOptions)options {
    validate_radius_display_options(options);
    moon_orbit_display_factor(options);
    const BOOL lunarPositionChanged = _radiusDisplayOptions.space_planet != options.space_planet &&
        _hasData && _selection && *_selection == 10 &&
        !_journeyActive && !_surfaceActive && !_surfacePreview && !_earthMoonMode;
    _radiusDisplayOptions = options;
    if (lunarPositionChanged) {
        if (_following) { [self updateTrackedCamera]; [self notifyCamera]; }
        [self notifySelection];
    }
    self.needsDisplay = YES;
}
- (PlanetDisplayOptions)planetDisplayOptions { return _planetDisplayOptions; }
- (TerrainAmplification)terrainAmplification { return _terrainAmplification; }
- (void)setTerrainAmplification:(TerrainAmplification)value {
    validate_terrain_amplification(value);
    if (_terrainAmplification == value) return;
    _terrainAmplification = value;
    [self cancelTerrain];
    self.needsDisplay = YES;
}
- (void)setPlanetDisplayOptions:(PlanetDisplayOptions)options {
    _planetDisplayOptions = options;
    self.needsDisplay = YES;
}
- (GridDisplayOptions)gridDisplayOptions { return _gridDisplayOptions; }
- (EarthLayerOptions)earthLayerOptions { return _earthLayerOptions; }
- (void)setEarthLayerOptions:(EarthLayerOptions)options {
    _earthLayerOptions = options;
    self.needsDisplay = YES;
}
- (AtmosphereDisplayOptions)atmosphereDisplayOptions { return _atmosphereDisplayOptions; }
- (EclipseDisplayOptions)eclipseDisplayOptions { return _eclipseDisplayOptions; }
- (void)setEclipseDisplayOptions:(EclipseDisplayOptions)options {
    _eclipseDisplayOptions = options;
    self.needsDisplay = YES;
}
- (void)setAtmosphereDisplayOptions:(AtmosphereDisplayOptions)options {
    validate_atmosphere_display(options);
    _atmosphereDisplayOptions = options;
    self.needsDisplay = YES;
}
- (void)setGridDisplayOptions:(GridDisplayOptions)options {
    _gridDisplayOptions = options;
    self.needsDisplay = YES;
}
- (void)setObservationSite:(ObserverSite)site julianDate:(double)julianDate {
    _gridCache.set_observation(site, julianDate);
    _julianDate = julianDate;
    self.needsDisplay = YES;
}
- (void)dealloc { [_landingController invalidate]; [_flightTimer invalidate]; [_orientationTimer invalidate]; [_targetTimer invalidate]; [_zoomTimer invalidate]; [self cancelTerrain]; }
- (BOOL)surfaceNavigationActive { return _surfaceActive; }
- (BOOL)scriptPlanetariumMode {
    return _surfaceActive && !_navigation.flying()
        && _navigation.site().height_km <= minimum_surface_height_km + 1e-9;
}
- (BOOL)setScriptSurfaceFov:(double)degrees {
    if (![self scriptPlanetariumMode] || !std::isfinite(degrees) || degrees <= 0 || degrees > 90) return NO;
    _camera.vertical_fov_deg = degrees;
    [self notifyCamera];
    self.needsDisplay = YES;
    return YES;
}
- (BOOL)journeyActive { return _journeyActive; }
- (BOOL)flightAnimating { return _navigation.flying() || (_journeyActive && _journey.flying()); }
- (BOOL)showsTimeInfo { return _showsTimeInfo; }
- (void)setShowsTimeInfo:(BOOL)visible { _showsTimeInfo = visible; self.needsDisplay = YES; }
- (NSUInteger)selectedBodyIndex { return _selection ? *_selection : NSNotFound; }
- (BOOL)isFlipped { return YES; }
- (BOOL)isOpaque { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (void)setNeedsDisplay:(BOOL)needsDisplay {
    if (needsDisplay) ++_sceneRevision;
    [super setNeedsDisplay:needsDisplay];
}
- (void)redrawPublishedScene { [super setNeedsDisplay:YES]; }
- (BOOL)matchesDisplayedCamera:(const SolarCamera&)camera map:(NSRect)map {
    const auto displayed = [self displayedScene];
    return NSEqualRects(map, displayed.map) && sameCamera(camera, displayed.camera);
}
- (void)beginSceneUpdate { ++_sceneUpdateDepth; }
- (void)endSceneUpdate {
    if (!_sceneUpdateDepth) throw std::logic_error("unbalanced scene update");
    --_sceneUpdateDepth;
    if (!_sceneUpdateDepth) {
        self.needsDisplay = YES;
        // 日時は他ビューと同期して適用されるため、非表示中も即座に新 JD を公開する。
        if (_publishedScene && _publishedScene->scene().julian_date != _julianDate)
            [self refreshTerrain];
    }
}
- (NSRect)mapRect { return NSInsetRect(self.bounds, 18, 40); }
- (Vec3)displayPosition:(NSUInteger)index {
    return solar_display_position([self scene], index);
}
- (std::shared_ptr<const mitaka::OurGalaxyModel>)ourGalaxyModel { return [_galaxyOverlay ourGalaxyModel]; }
- (std::shared_ptr<const HipSpatialModel>)hipModel { return [_galaxyOverlay hipModel]; }
- (void)setHipVisible:(BOOL)visible {
    _hipVisible = visible;
    if (!visible && _hipSelection) {
        _hipSelection.reset(); _following = NO; [self notifySelection]; [self notifyCamera];
    }
    self.needsDisplay = YES;
}
- (void)setSurfaceStarModel:(std::shared_ptr<const SkyModel>)model
                  catalogs:(std::shared_ptr<const ExtendedCatalogs>)catalogs {
    _surfaceStarSelection.reset();
    _surfaceConstellationSelection.reset();
    _surfaceSkyPickModel.reset();
    _surfaceSkyModel = model;
    _surfaceStarRenderer = [[StarRenderer alloc] initWithModel:std::move(model) catalogs:std::move(catalogs)];
    self.needsDisplay = YES;
}
- (ConstellationDisplayOptions)surfaceConstellationDisplayOptions { return _surfaceConstellationOptions; }
- (void)setSurfaceConstellationDisplayOptions:(ConstellationDisplayOptions)options {
    _surfaceConstellationOptions = std::move(options);
    self.needsDisplay = YES;
}
- (void)setSurfaceConstellationArt:(std::shared_ptr<const ConstellationArtModel>)art {
    _surfaceConstellationArt = std::move(art);
    self.needsDisplay = YES;
}
- (MilkyWayMode)surfaceMilkyWayMode { return _surfaceMilkyWayMode; }
- (void)setSurfaceMilkyWayMode:(MilkyWayMode)mode {
    if (_surfaceMilkyWayMode == mode) return;
    _surfaceMilkyWayMode = mode;
    _surfaceBackgroundKey.reset();
    self.needsDisplay = YES;
}
- (void)setSurfaceSkyBackgrounds:(std::shared_ptr<const SkyBackgrounds>)backgrounds {
    _surfaceBackgrounds = std::move(backgrounds);
    _surfaceBackgroundKey.reset();
    self.needsDisplay = YES;
}
- (void)setSurfaceStarDisplayOptions:(StarDisplayOptions)options {
    validate_star_display(options);
    _surfaceStarOptions = options;
    self.needsDisplay = YES;
}
- (void)setSurfaceMagnitudeLimit:(double)limit {
    _surfaceMagnitudeLimit = limit;
    self.needsDisplay = YES;
}
- (void)setSurfaceSelectedStarNameHIPs:(const std::set<std::int32_t>&)hips {
    [_surfaceStarRenderer setSelectedNameHIPs:hips];
    self.needsDisplay = YES;
}
- (void)setOurGalaxyVisible:(BOOL)visible {
    [_galaxyOverlay setOurGalaxyVisible:visible];
    if (!visible && (_ourGalaxySelected || _ourGalaxyPointSelection)) {
        [self stopScriptTargetTransition];
        _ourGalaxySelected = NO; _ourGalaxyPointSelection.reset(); _following = NO; [self notifySelection]; [self notifyCamera];
    }
    self.needsDisplay = YES;
}
- (void)setHipModel:(std::shared_ptr<const HipSpatialModel>)model {
    if ([_galaxyOverlay hipModel] != model && _hipSelection) {
        _hipSelection.reset(); _following = NO; [self notifySelection]; [self notifyCamera];
    }
    [_galaxyOverlay setHipModel:std::move(model)];
    self.needsDisplay = YES;
}
- (void)setOurGalaxyModel:(std::shared_ptr<const mitaka::OurGalaxyModel>)model {
    if ([_galaxyOverlay ourGalaxyModel] != model && (_ourGalaxySelected || _ourGalaxyPointSelection)) {
        [self stopScriptTargetTransition];
        _ourGalaxySelected = NO; _ourGalaxyPointSelection.reset(); _following = NO; [self notifySelection]; [self notifyCamera];
    }
    [_galaxyOverlay setOurGalaxyModel:std::move(model)];
    self.needsDisplay = YES;
}
- (void)setGalaxyModel:(std::shared_ptr<const GalaxySpatialModel>)model {
    if ([_galaxyOverlay model] != model && _galaxySelection) {
        _galaxySelection.reset(); _following = NO; [self notifyCamera];
    }
    [_galaxyOverlay setModel:std::move(model)];
    [self notifySelection];
    self.needsDisplay = YES;
}
- (void)clearGalaxySelection {
    _surfaceStarSelection.reset();
    _surfaceConstellationSelection.reset();
    [self stopScriptTargetTransition];
    _scriptOverviewTarget.clear();
    _scriptEarthPlaceTarget.clear();
    _scriptSpacePlace.reset();
    [_galaxyOverlay invalidatePendingPicks]; _galaxySelection.reset(); _hipSelection.reset(); _ourGalaxyPointSelection.reset(); _ourGalaxySelected = NO;
}
- (void)setGalaxyVisibility:(GalaxySpatialVisibility)visibility {
    [_galaxyOverlay setVisibility:visibility];
    if (_galaxySelection && !visibility.visible(_galaxySelection->family)) {
        _galaxySelection.reset(); _following = NO; [self notifySelection]; [self notifyCamera];
    }
    self.needsDisplay = YES;
}
- (std::optional<GalaxySpatialRecordId>)selectedGalaxyRecord { return _galaxySelection; }
- (std::optional<std::size_t>)selectedHipIndex { return _hipSelection; }
- (std::optional<OurGalaxyPointId>)selectedOurGalaxyPoint { return _ourGalaxyPointSelection; }
- (BOOL)isOurGalaxySelected { return _ourGalaxySelected; }
- (GalaxyOverlayDiagnostics)galaxyOverlayDiagnostics { return [_galaxyOverlay diagnostics]; }
- (void)setTextures:(std::shared_ptr<const PlanetTextures>)textures {
    _textures = std::move(textures);
    [self notifySelection];
    self.needsDisplay = YES;
}
- (SolarScene)scene {
    return {_bodies, _orbits, _lunarOrbit, _camera, _textures.get(), _selection,
        [self mapRect], self.window ? self.window.backingScaleFactor : 1, static_cast<bool>(_earthMoonMode), _surfacePreview ? _selection : std::nullopt,
        _surfaceActive ? std::optional<std::size_t>(_navigation.site().body_index) : std::nullopt,
        static_cast<bool>(_journeyActive || _surfaceActive || _physicalSpaceActive),
        [self smallBodiesSceneVisible] ? _smallBodySnapshot.get() : nullptr,
        !_selection ? _smallBodySelection : std::nullopt, _planetDisplayOptions, _gridDisplayOptions, &_gridCache, _rendererDisplayOptions,
        [self satellitesSceneVisible] ? _satelliteSnapshot.get() : nullptr,
        !_selection ? _satelliteSelection : std::nullopt,
        [self spacecraftSceneVisible] ? _spacecraftSnapshot.get() : nullptr,
        !_selection ? _spacecraftSelection : std::nullopt, _spacecraftDisplayOptions,
        _smallBodyDisplay.get(), _smallBodyOrbits.get(), _satelliteDisplay.get(), _satelliteOrbits.get(),
        _earthLayerOptions, _atmosphereDisplayOptions, _eclipseDisplayOptions, _julianDate,
        _satelliteSnapshot.get(), &_terrainSnapshots, _terrainAmplification, _radiusDisplayOptions};
}
- (CGFloat)radiusForBody:(NSUInteger)index depth:(double)depth {
    return solar_scene_radius([self scene], index, depth);
}
- (void)setLunarOrbit:(const std::vector<Vec3>&)orbit { _lunarOrbit = orbit; self.needsDisplay = YES; }
- (void)keepCameraOutsideBodies:(SolarCamera&)next {
    if (!_earthMoonMode) return;
    const auto basis = solar_camera_basis(next);
    for (const std::size_t index : {std::size_t(3), std::size_t(10)}) {
        const Vec3 center = [self displayPosition:index];
        const Vec3 offset{next.target.x-center.x, next.target.y-center.y, next.target.z-center.z};
        const double radius = (surface_body_info(index).radius_km + minimum_surface_height_km) / astronomical_unit_km;
        const Vec3 eye{offset.x + basis.outward.x*next.distance_au,
            offset.y + basis.outward.y*next.distance_au, offset.z + basis.outward.z*next.distance_au};
        if (std::hypot(eye.x, eye.y, eye.z) <= radius) {
            const double along = offset.x*basis.outward.x + offset.y*basis.outward.y + offset.z*basis.outward.z;
            const double squared = offset.x*offset.x + offset.y*offset.y + offset.z*offset.z;
            next.distance_au = -along + std::sqrt(std::max(0.0, along*along - squared + radius*radius)) + 1e-10;
        }
    }
}
- (void)updateTrackedCamera {
    if (_journeyActive) {
        if (_journey.flying()) [self updateJourneyAtTime:_lastFlightTime];
    } else if (_surfaceActive) {
        const double fov = _camera.vertical_fov_deg;
        _camera = _navigation.camera(_bodies);
        _camera.vertical_fov_deg = fov;
        if (_navigation.flying()) [self restoreFlightOrientation];
    }
    else if (_earthMoonMode && _earthMoonFollowing) {
        const Vec3 earth = [self displayPosition:3], moon = [self displayPosition:10];
        _camera.set_target_au({(earth.x + moon.x) / 2, (earth.y + moon.y) / 2, (earth.z + moon.z) / 2});
    } else if (_following && _selection) {
        _camera.set_target_au(_scriptSpacePlace && *_selection == _scriptSpacePlace->body_index
            ? [self scriptSpacePlacePositionForBodies:_bodies] : [self displayPosition:*_selection]);
    }
    else if (_following && _smallBodySelection && _smallBodySnapshot) {
        const auto& position = _smallBodySnapshot->positions[*_smallBodySelection];
        if (position) _camera.set_target_au(*position);
        else _following = NO;
    }
    else if (_following && _satelliteSelection && _satelliteSnapshot) {
        const auto& position = _satelliteSnapshot->positions[*_satelliteSelection];
        if (position) _camera.set_target_au(*position);
        else _following = NO;
    }
    else if (_following && _spacecraftSelection && _spacecraftSnapshot) {
        const auto position = spacecraft_scene_position(*_spacecraftSnapshot, *_spacecraftSelection);
        if (position) _camera.set_target_au(*position);
        else _following = NO;
    }
    [self keepCameraOutsideBodies:_camera];
}
- (void)setBodies:(const SolarBodies&)bodies orbits:(const SolarOrbits&)orbits {
    _orbits = orbits;
    [self setBodies:bodies];
}

- (void)setBodies:(const SolarBodies&)bodies {
    _bodies = bodies;
    _hasData = YES;
    try { [self updateTrackedCamera]; }
    catch (const std::exception& error) { [self interruptFlight]; [self reportNavigationError:error.what()]; }
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (void)selectBody:(NSUInteger)index {
    if (!_hasData || index >= _bodies.size()) return;
    [self clearGalaxySelection];
    _surfaceStarSelection.reset();
    _selection = index;
    _smallBodySelection.reset();
    _satelliteSelection.reset();
    _spacecraftSelection.reset();
    if (_following && !_surfaceActive && !_earthMoonMode) _camera.set_target_au([self displayPosition:index]);
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (void)notifySelection {
    const auto satelliteSelection = !_selection ? _satelliteSelection : std::nullopt;
    if (_notifiedSatelliteSelection != satelliteSelection) {
        // 親位置更新の setBodies: から再入しても、同じ変更を重複通知しない。
        _notifiedSatelliteSelection = satelliteSelection;
        if (self.satelliteSelectionChanged)
            self.satelliteSelectionChanged(satelliteSelection ? *satelliteSelection : NSNotFound);
    }
    NSString *description = @"天体をクリックして選択します。\n「選択を中心」で視点の中心に移動します。";
    if (_surfaceActive && _surfaceConstellationSelection && _surfaceSkyModel &&
        *_surfaceConstellationSelection < _surfaceSkyModel->constellations().size()) {
        const auto& constellation = _surfaceSkyModel->constellations()[*_surfaceConstellationSelection];
        NSString *name = [[NSString alloc] initWithBytes:constellation.japanese_hiragana_bytes.data()
            length:constellation.japanese_hiragana_bytes.size()
            encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese)];
        if (!name.length || [name isEqualToString:@"*"])
            name = [NSString stringWithUTF8String:constellation.abbreviation.c_str()];
        description = [NSString stringWithFormat:@"星座: %@", name ? name : @"（名称なし）"];
    } else if (_surfaceActive && _surfaceStarSelection && _surfaceSkyModel && *_surfaceStarSelection < _surfaceSkyModel->stars().size()) {
        const auto& star = _surfaceSkyModel->stars()[*_surfaceStarSelection];
        description = [NSString stringWithFormat:@"HIP %d\nV 等級 %.2f", star.hip, star.apparent_v_magnitude];
    } else if (_hasData && _selection) {
        const auto& body = _bodies[*_selection];
        const Vec3 p = [self displayPosition:*_selection];
        NSString *surface = _textures && _textures->images[*_selection] ? @"表面画像あり" : @"表面画像なし（色で表示）";
        description = [NSString stringWithFormat:@"%@\n太陽から %.5f AU\n黄道 X %+.5f AU\n黄道 Y %+.5f AU\n黄道 Z %+.5f AU\n%@", bodyName(body.id),
            std::hypot(p.x, p.y, p.z), p.x, p.y, p.z, surface];
    } else if (_smallBodySelection) description = [self smallBodySelectionDescription];
    else if (_satelliteSelection) description = [self satelliteSelectionDescription];
    else if (_spacecraftSelection) description = [self spacecraftSelectionDescription];
    else if (_hipSelection && [_galaxyOverlay hipModel]) {
        const auto& star = [_galaxyOverlay hipModel]->points[*_hipSelection];
        description = [NSString stringWithFormat:@"HIP %d\n正の視差から推定した位置 · 固有運動なし\n黄道 X %+.6g pc\n黄道 Y %+.6g pc\n黄道 Z %+.6g pc",
            star.hip, star.position.x_pc, star.position.y_pc, star.position.z_pc];
    } else if (_ourGalaxyPointSelection) {
        const auto id = *_ourGalaxyPointSelection;
        const auto position = [_galaxyOverlay ourGalaxyPointPosition:id];
        if (position) {
            NSArray<NSString *> *groups = @[@"disk1", @"disk2", @"disk_ob", @"bulge"];
            description = [NSString stringWithFormat:@"天の川点群 · %@ · 出典内番号 %lu\n日心黄道 X %+.6g pc\n日心黄道 Y %+.6g pc\n日心黄道 Z %+.6g pc\n実在天体との対応は未確認",
                groups[static_cast<NSUInteger>(id.group)], id.ordinal + 1,
                position->x_pc, position->y_pc, position->z_pc];
        }
    } else if (_ourGalaxySelected) {
        description = @"天の川銀河\n公式 1.3.1 の銀河中心と楕円体を使用\n座標の配置と旧 Plus の一致は未検証";
    } else if (_galaxySelection && [_galaxyOverlay model]) {
        const auto model = [_galaxyOverlay model];
        const auto id = *_galaxySelection;
        const auto row = model->row(id);
        NSArray<NSString *> *families = @[@"SDSS 銀河", @"SDSS クエーサー", @"球状星団", @"近傍銀河"];
        if (row.position) description = [NSString stringWithFormat:@"%@ · 出典 %lu · 原行 %lu\n日心黄道 X %+.6g pc\n日心黄道 Y %+.6g pc\n日心黄道 Z %+.6g pc",
            families[static_cast<NSUInteger>(id.family)], id.source_index + 1, id.ordinal + 1,
            row.position->x_pc, row.position->y_pc, row.position->z_pc];
        // 元の ID だけを表示する。座標や近接する描画点から天体名を推定しない。
        NSString *identity = nil;
        const auto& source = model->sources().at(id.source_index);
        if (const auto* catalog = std::get_if<PlusGlobularClusterCatalog>(&source)) {
            const auto& bytes = catalog->records.at(id.ordinal).name_bytes;
            const auto end = std::find(bytes.begin(), bytes.end(), 0);
            identity = [[NSString alloc] initWithBytes:bytes.data() length:std::distance(bytes.begin(), end)
                                             encoding:NSUTF8StringEncoding];
        } else if (const auto* catalog = std::get_if<PlusNearbyGalaxyCatalog>(&source)) {
            const auto& record = catalog->records.at(id.ordinal);
            if (record.catalog_code >= 33 && record.catalog_code <= 126)
                identity = [NSString stringWithFormat:@"原 ID %c%d", record.catalog_code, record.catalog_number];
            else
                identity = [NSString stringWithFormat:@"原 code %u · 番号 %d", unsigned(record.catalog_code), record.catalog_number];
        }
        if (identity.length) description = [NSString stringWithFormat:@"%@\n%@", identity, description];
    }
    if (self.selectionChanged) self.selectionChanged(description);
    if (self.navigationChanged) self.navigationChanged();
}
- (NSString *)cameraInputDescription {
    if (_journeyActive) {
        NSString *phase = @"停止中";
        switch (_journey.phase()) {
            case FlightPhase::ascent: phase = @"離陸中"; break;
            case FlightPhase::cruise: phase = @"航行中"; break;
            case FlightPhase::descent: phase = @"着陸中"; break;
            default: break;
        }
        const auto& site = _journey.destination();
        return [NSString stringWithFormat:@"%@へ %@ · %.0f%% · 着陸地点 %+.2f° / %+.2f°%@",
            bodyName(_bodies[site.body_index].id), phase, 100*_journey.progress(), site.latitude_deg, site.longitude_deg,
            _flightNotice.length ? [@" · " stringByAppendingString:_flightNotice] : @""];
    }
    if (_surfaceActive) {
        const auto& site = _navigation.site();
        const BOOL reference = surface_body_info(site.body_index).gas_reference_surface;
        return [NSString stringWithFormat:@"%@ %@ · 緯度 %+.2f° / 経度 %+.2f° · 高度 %.3f km · 方位 %.1f° / 仰角 %.1f°%@",
            bodyName(_bodies[site.body_index].id), reference ? @"基準球面" : @"地表視点",
            site.latitude_deg, site.longitude_deg, site.height_km, site.heading_deg, site.elevation_deg,
            _flightNotice.length ? [@" · " stringByAppendingString:_flightNotice] : @""];
    }
    if (_earthMoonMode) {
        const Vec3 earth = [self displayPosition:3], moon = [self displayPosition:10];
        return [NSString stringWithFormat:@"地球–月 距離 %.0f km · 視点距離 %.0f km%@",
            std::hypot(moon.x-earth.x, moon.y-earth.y, moon.z-earth.z) * astronomical_unit_km,
            _camera.distance_au * astronomical_unit_km, _earthMoonFollowing ? @" · 地球と月を追従" : @""];
    }
    if (_camera.distance_au >= astronomical_units_per_parsec)
        return [NSString stringWithFormat:@"視点距離 %.6g pc  ·  方位 %.1f° / 仰角 %.1f°%@",
            _camera.distance_au / astronomical_units_per_parsec, _camera.yaw_deg, _camera.pitch_deg,
            _following ? @"  ·  選択天体を追従" : @""];
    return [NSString stringWithFormat:@"視点距離 %.3f AU  ·  方位 %.1f° / 仰角 %.1f°%@", _camera.distance_au,
        _camera.yaw_deg, _camera.pitch_deg, _following ? @"  ·  選択天体を追従" : @""];
}
- (NSString *)cameraStateDescription {
    return [@"操作値 · " stringByAppendingString:[self cameraInputDescription]];
}
- (void)notifyCamera {
    if (!_lastNotifiedCamera || !sameCamera(*_lastNotifiedCamera, _camera)) {
        [_galaxyOverlay invalidatePendingPicks];
        _lastNotifiedCamera = _camera;
    }
    const BOOL overviewVisible = !_earthMoonMode && !_surfacePreview && !_surfaceActive && !_journeyActive;
    if (_notifiedOverviewVisible != overviewVisible) {
        _notifiedOverviewVisible = overviewVisible;
        if (self.overviewVisibilityChanged) self.overviewVisibilityChanged(overviewVisible);
    }
    if (self.cameraChanged) self.cameraChanged([self cameraStateDescription]);
}
- (SolarCamera)cameraState { return _camera; }
- (void)changeCamera:(CameraChange)change {
    if (_journeyActive) return;
    try {
        SolarCamera next = _camera;
        change(next);
        [self keepCameraOutsideBodies:next];
        // 公開カメラ値の検証を投影境界に集約し、不正値を表示状態へ反映しない。
        (void)project_solar(next.target, next, 1, 1);
        [self stopScriptZoomAnimation];
        [self stopScriptOrientation];
        [self stopScriptTargetTransition];
        _camera = next;
        [self notifyCamera];
        self.needsDisplay = YES;
    } catch (const std::exception& error) {
        if (self.cameraChanged) self.cameraChanged([NSString stringWithFormat:@"視点を変更できません: %s", error.what()]);
    }
}
- (void)setCameraState:(const SolarCamera&)camera {
    NSString *error = nil;
    if (![self applyCameraState:camera error:&error] && self.cameraChanged)
        self.cameraChanged([@"視点を変更できません: " stringByAppendingString:error]);
}
- (BOOL)applyCameraState:(const SolarCamera&)camera error:(NSString **)error {
    const SolarCamera next = camera;
    try {
        // 飛行の中断や frame の解除より先に、表示側と同じ規則で全候補を検証する。
        (void)solar_camera_basis(next);
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
    [self stopScriptZoomAnimation];
    [self leaveNavigation];
    [_galaxyOverlay invalidatePendingPicks];
    _scriptOrientation.reset();
    _camera = next;
    _following = NO;
    if (_ourGalaxyPointSelection) { _ourGalaxyPointSelection.reset(); [self notifySelection]; }
    [self notifyCamera];
    self.needsDisplay = YES;
    return YES;
}
- (void)stopScriptZoomAnimation {
    [_zoomTimer invalidate];
    _zoomTimer = nil;
    _zoomAnimation.reset();
}
- (void)updateScriptZoomAtTime:(double)now {
    if (!_zoomAnimation) return;
    const auto animation = *_zoomAnimation;
    auto camera = _camera;
    camera.distance_au = animation.value(now);
    try {
        (void)solar_camera_basis(camera);
        [self keepCameraOutsideBodies:camera];
        _camera = camera;
        [self notifyCamera];
        self.needsDisplay = YES;
        if (now - animation.start_time >= animation.duration) [self stopScriptZoomAnimation];
    } catch (const std::exception& failure) {
        [self stopScriptZoomAnimation];
        if (self.cameraChanged) self.cameraChanged([NSString stringWithUTF8String:failure.what()]);
    }
}
- (BOOL)animateScriptZoomTo:(double)distance duration:(double)duration logarithmic:(BOOL)logarithmic error:(NSString **)error {
    if (_surfaceActive && !_navigation.flying()) {
        if (error) *error = @"Camera zoom animation is unavailable on the surface";
        return NO;
    }
    const bool leavingNavigation = _journeyActive || _physicalSpaceActive || (_surfaceActive && _navigation.flying());
    auto initial = _camera;
    if (leavingNavigation && initial.frame) initial.frame_is_orbit = true;
    auto candidate = initial;
    candidate.distance_au = distance;
    try {
        if (!std::isfinite(duration) || duration < 0) throw std::invalid_argument("Invalid zoom duration");
        (void)solar_camera_basis(initial);
        (void)solar_camera_basis(candidate);
        [self keepCameraOutsideBodies:candidate];
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
    if (leavingNavigation) {
        // 航行を中断しても、現在の視点と姿勢を新しい軌道視点の始点として維持する。
        const auto orientation = _scriptOrientation;
        [self leaveNavigation];
        _camera = initial;
        _scriptOrientation = orientation;
    }
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    if (_zoomAnimation) [self updateScriptZoomAtTime:now];
    [self stopScriptZoomAnimation];
    if (_targetAnimation) _targetAnimation->updates_distance = false;
    if (duration == 0) {
        _camera.distance_au = candidate.distance_au;
        [self notifyCamera];
        self.needsDisplay = YES;
        return YES;
    }
    _zoomAnimation = ScriptZoomTransition{_camera.distance_au, distance, now, duration, static_cast<bool>(logarithmic)};
    __weak SolarSystemView *weakSelf = self;
    _zoomTimer = [NSTimer timerWithTimeInterval:1.0/30 repeats:YES block:^(NSTimer *timer) {
        (void)timer;
        [weakSelf updateScriptZoomAtTime:std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count()];
    }];
    [NSRunLoop.mainRunLoop addTimer:_zoomTimer forMode:NSRunLoopCommonModes];
    return YES;
}
- (void)resetCamera {
    [self leaveNavigation];
    _following = NO;
    [self changeCamera:^(SolarCamera& next) { next = SolarCamera{}; }];
}
- (void)showInnerPlanets {
    [self leaveNavigation];
    _following = NO;
    [self changeCamera:^(SolarCamera& next) { next = SolarCamera{}; next.distance_au = 7; }];
}
- (void)zoomBy:(double)delta {
    if (_journeyActive) return;
    if (_surfaceActive) { [self changeSurfaceByX:0 y:0 zoom:delta]; return; }
    [self changeCamera:^(SolarCamera& next) { next.zoom(delta); if (self->_earthMoonMode) next.distance_au = std::max(next.distance_au, 0.0002); }];
}
- (void)zoomIn { [self zoomBy:-0.25]; }
- (void)zoomOut { [self zoomBy:0.25]; }
- (void)showOurGalaxyOverview {
    if (![_galaxyOverlay ourGalaxyModel] || ![_galaxyOverlay isOurGalaxyVisible]) return;
    [self showGalaxyOverviewSelectingOurGalaxy:YES];
}
- (void)showGalaxyCatalogOverview {
    [self showGalaxyOverviewSelectingOurGalaxy:NO];
}
- (void)showGalaxyOverviewSelectingOurGalaxy:(BOOL)selectOurGalaxy {
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    try {
        const auto camera = frame_our_galaxy({{0, 0, 0}}, galaxy_camera_from_shared(shared_camera_from_solar(_camera)),
                                             8000, map.size.width, map.size.height);
        const auto solar = solar_camera_from_shared(shared_camera_from_galaxy(camera));
        [self leaveNavigation];
        [self clearGalaxySelection];
        _selection.reset(); _smallBodySelection.reset(); _satelliteSelection.reset(); _spacecraftSelection.reset();
        _ourGalaxySelected = selectOurGalaxy; _following = selectOurGalaxy;
        [self notifySelection];
        [self changeCamera:^(SolarCamera& next) { next = solar; }];
    } catch (const std::exception& error) { [self reportNavigationError:error.what()]; }
}
- (void)focusSelection {
    if (_ourGalaxyPointSelection) {
        const auto position = [_galaxyOverlay ourGalaxyPointPosition:*_ourGalaxyPointSelection];
        if (!position) return;
        const auto frame = _camera.frame;
        [self leaveNavigation]; _camera.frame = frame; _following = YES;
        const Vec3 target{position->x_pc, position->y_pc, position->z_pc};
        [self changeCamera:^(SolarCamera& next) { next.set_target_pc(target); }];
        return;
    }
    if (_ourGalaxySelected && [_galaxyOverlay ourGalaxyModel]) {
        const auto position = our_galaxy_center({{0, 0, 0}});
        const auto frame = _camera.frame;
        [self leaveNavigation]; _camera.frame = frame; _following = YES;
        const Vec3 target{position.x_pc, position.y_pc, position.z_pc};
        [self changeCamera:^(SolarCamera& next) { next.set_target_pc(target); }];
        return;
    }
    if (_hipSelection && [_galaxyOverlay hipModel]) {
        const auto position = [_galaxyOverlay hipModel]->points[*_hipSelection].position;
        const auto frame = _camera.frame;
        [self leaveNavigation]; _camera.frame = frame; _following = YES;
        const Vec3 target{position.x_pc, position.y_pc, position.z_pc};
        [self changeCamera:^(SolarCamera& next) { next.set_target_pc(target); }];
        return;
    }
    if (_galaxySelection && [_galaxyOverlay model]) {
        const auto position = [_galaxyOverlay model]->row(*_galaxySelection).position;
        if (!position) return;
        const auto frame = _camera.frame;
        [self leaveNavigation];
        _camera.frame = frame;
        _following = YES;
        const Vec3 target{position->x_pc, position->y_pc, position->z_pc};
        [self changeCamera:^(SolarCamera& next) { next.set_target_pc(target); }];
        return;
    }
    if (!_selection && _smallBodySelection) { [self focusSmallBodySelection]; return; }
    if (!_selection && _satelliteSelection) { [self focusSatelliteSelection]; return; }
    if (!_selection && _spacecraftSelection) { [self focusSpacecraftSelection]; return; }
    if (!_hasData || !_selection) return;
    [self leaveNavigation];
    _following = YES;
    const Vec3 target = [self displayPosition:*_selection];
    [self changeCamera:^(SolarCamera& next) { next.set_target_au(target); next.frame.reset(); next.distance_au = std::max(next.distance_au, 0.05); }];
}
- (void)showSurface {
    if (_galaxySelection || _hipSelection || _ourGalaxySelected || _ourGalaxyPointSelection) {
        if (self.cameraChanged) self.cameraChanged(@"銀河や星団の表面表示には対応していません。");
        return;
    }
    if ([self rejectSmallBodySurfaceNavigation] || [self rejectSatelliteSurfaceNavigation] || [self rejectSpacecraftSurfaceNavigation]) return;
    if (!_hasData) return;
    if (!_selection) [self selectBody:3];
    [self leaveNavigation];
    _following = YES;
    _surfacePreview = YES;
    const Vec3 target = [self displayPosition:*_selection];
    [self changeCamera:^(SolarCamera& next) { next.set_target_au(target); next.distance_au = 0.05; }];
}
- (void)orbitByX:(double)dx y:(double)dy {
    if (_journeyActive) return;
    if (_surfaceActive) { [self changeSurfaceByX:dx y:dy zoom:0]; return; }
    [self changeCamera:^(SolarCamera& next) { next.orbit(dx, dy); }];
}
- (void)rollByDegrees:(double)degrees {
    if (_journeyActive || _surfaceActive) return;
    [self changeCamera:^(SolarCamera& next) { next.roll(degrees); }];
}
- (void)panByX:(double)dx y:(double)dy {
    if (_journeyActive) return;
    if (_surfaceActive) { [self changeSurfaceByX:dx y:dy zoom:0]; return; }
    _earthMoonFollowing = NO;
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    _following = NO;
    [self changeCamera:^(SolarCamera& next) { next.pan(dx, dy, map.size.width, map.size.height); }];
}
- (void)mouseDown:(NSEvent *)event {
    [self.window makeFirstResponder:self];
    _lastDrag = _mouseStart = [self convertPoint:event.locationInWindow fromView:nil];
    _dragged = NO;
}
- (void)mouseDragged:(NSEvent *)event {
    const NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    if (!_dragged && std::hypot(point.x - _mouseStart.x, point.y - _mouseStart.y) < 3) return;
    _dragged = YES;
    const double dx = point.x - _lastDrag.x, dy = point.y - _lastDrag.y;
    if ((event.modifierFlags & NSEventModifierFlagShift) || event.type == NSEventTypeRightMouseDragged)
        [self panByX:dx y:dy];
    else if (event.modifierFlags & NSEventModifierFlagOption)
        [self rollByDegrees:dx * 0.35];
    else [self orbitByX:dx y:dy];
    _lastDrag = point;
}
- (void)rightMouseDown:(NSEvent *)event { [self mouseDown:event]; }
- (void)rightMouseDragged:(NSEvent *)event { [self mouseDragged:event]; }
- (void)rightMouseUp:(NSEvent *)event {
    (void)event;
    if (_dragged) { _dragged = NO; self.needsDisplay = YES; }
}
- (void)scrollWheel:(NSEvent *)event {
    const double scale = event.hasPreciseScrollingDeltas ? 0.012 : 0.1;
    [self zoomBy:event.scrollingDeltaY * scale];
}
- (void)magnifyWithEvent:(NSEvent *)event { [self zoomBy:-event.magnification]; }
- (void)rotateWithEvent:(NSEvent *)event { [self rollByDegrees:event.rotation]; }
- (void)mouseUp:(NSEvent *)event {
    if (_dragged) { _dragged = NO; self.needsDisplay = YES; return; }
    if (!_hasData || _targetSelectionMode != 2) return;
    [self pickBodyAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
}
- (void)applySurfaceSkyStar:(std::optional<std::size_t>)star constellation:(std::optional<std::size_t>)constellation {
    // 古い選択・追従を解除してから新しい表示上の選択を設定する。
    [self clearGalaxySelection];
    _selection.reset(); _smallBodySelection.reset(); _satelliteSelection.reset(); _spacecraftSelection.reset();
    _following = NO; _surfacePreview = NO;
    _surfaceStarSelection = star;
    _surfaceConstellationSelection = constellation;
    [self notifySelection]; [self notifyCamera]; self.needsDisplay = YES;
}
- (void)pickBodyAtPoint:(NSPoint)click {
    // 矩形外へのホバーも直前の非同期選択より新しい操作として扱う。
    [_galaxyOverlay invalidatePendingPicks];
    if (!_hasData || !NSPointInRect(click, [self mapRect])) return;
    try {
        const auto displayedOwner = _publishedScene;
        const auto scene = displayedOwner ? displayedOwner->scene() : [self scene];
        if (!NSEqualRects(scene.map, [self mapRect])) return;
        if (scene.surface_body) {
            // 地表と同一の描画済みフレームだけを選択する。未描画の状態には触れない。
            if (!_surfaceSkyPickScene || !_surfaceSkyPickModel || _surfaceSkyPickModel != _surfaceSkyModel) return;
            const auto skyScene = _surfaceSkyPickScene->scene();
            if (!skyScene.surface_body || !NSEqualRects(skyScene.map, [self mapRect])) return;
            const auto star = pick_surface_star(_surfaceSkyPickModel->stars(), skyScene.camera,
                skyScene.map.size.width, skyScene.map.size.height,
                {click.x - skyScene.map.origin.x, click.y - skyScene.map.origin.y},
                _surfaceSkyPickOptions.visible, _surfaceSkyPickMagnitudeLimit, [&](ScreenPoint point) {
                    return solar_scene_opaque_at(skyScene, NSMakePoint(skyScene.map.origin.x + point.x,
                                                                      skyScene.map.origin.y + point.y));
                });
            std::optional<std::size_t> constellation;
            if (!star) {
                const auto site = surface_sky_site_from_camera(skyScene.camera, skyScene.bodies, *skyScene.surface_body);
                const ObservationFrame observation({site.latitude_deg, site.longitude_deg},
                                                   skyScene.bodies[site.body_index].orientation);
                const HorizonViewport viewport{site.heading_deg, site.elevation_deg, 180, 1, site.roll_deg, skyScene.camera.vertical_fov_deg};
                const auto result = pick_horizon_constellation(_surfaceSkyPickModel->constellations(),
                    [&](std::int32_t hip) -> std::optional<EquatorialCoordinates> {
                        const auto index = _surfaceSkyPickModel->star_index(hip);
                        if (!index) return std::nullopt;
                        const auto& star = _surfaceSkyPickModel->stars()[*index];
                        return EquatorialCoordinates{star.right_ascension_degrees, star.declination_degrees};
                    }, _surfaceSkyPickConstellations, observation, viewport,
                    skyScene.map.size.width, skyScene.map.size.height,
                    {click.x - skyScene.map.origin.x, click.y - skyScene.map.origin.y}, 6,
                    [&](ScreenPoint point) {
                        return !solar_scene_opaque_at(skyScene, NSMakePoint(skyScene.map.origin.x + point.x,
                                                                          skyScene.map.origin.y + point.y));
                    });
                if (result) constellation = result->record_index;
            }
            [self applySurfaceSkyStar:star constellation:constellation];
            return;
        }
        if (scene.physical_navigation) return;
        const auto picked = pick_solar_body(scene, click);
        if (picked) [self selectBody:*picked];
        else {
            const auto small = scene.small_bodies && scene.small_body_display
                ? pick_small_body(*scene.small_bodies, *scene.small_body_display, scene.camera, scene.map, click) : std::nullopt;
            if (small) {
                if (_smallBodySnapshot && scene.small_bodies->model == _smallBodySnapshot->model)
                    [self selectSmallBody:*small];
                return;
            }
            const auto satellite = scene.satellites
                ? pick_satellite(*scene.satellites, scene.camera, scene.map, click, scene.satellite_display) : std::nullopt;
            if (satellite) {
                if (_satelliteSnapshot && scene.satellites->model == _satelliteSnapshot->model)
                    [self selectSatellite:*satellite];
                return;
            }
            const auto spacecraft = scene.spacecraft
                ? pick_spacecraft(*scene.spacecraft, scene.camera, scene.map, click, scene.spacecraft_display) : std::nullopt;
            if (spacecraft) {
                if (_spacecraftSnapshot && scene.spacecraft->model == _spacecraftSnapshot->model)
                    [self selectSpacecraft:*spacecraft];
                return;
            }
            _selection.reset(); _smallBodySelection.reset(); _satelliteSelection.reset(); _spacecraftSelection.reset();
            [self clearGalaxySelection]; _following = NO; _surfacePreview = NO;
            [self notifySelection]; [self notifyCamera]; self.needsDisplay = YES;
            const auto galaxyCamera = galaxy_camera_from_shared(shared_camera_from_solar(scene.camera));
            const SolarCamera pickedCamera = scene.camera;
            const NSRect map = scene.map;
            __weak SolarSystemView *weakSelf = self;
            [_galaxyOverlay pickSpatialAtPoint:NSMakePoint(click.x - map.origin.x, click.y - map.origin.y)
                camera:galaxyCamera completion:^(GalaxyOverlaySelection result) {
                    SolarSystemView *view = weakSelf;
                    if (!view || view.hidden || ![view matchesDisplayedCamera:pickedCamera map:map]) return;
                    view->_galaxySelection = result.galaxy;
                    view->_hipSelection = result.hip;
                    view->_ourGalaxySelected = result.our_galaxy;
                    if (result.our_galaxy_point && [view->_galaxyOverlay displayedOurGalaxyPointPosition:*result.our_galaxy_point])
                        view->_ourGalaxyPointSelection = result.our_galaxy_point;
                    [view notifySelection]; view.needsDisplay = YES;
                }];
        }
    } catch (const std::exception& error) { [self reportNavigationError:error.what()]; }
}
- (void)invalidatePendingGalaxyPicks {
    [_galaxyOverlay invalidatePendingPicks];
}
- (NSUInteger)visibleBodyCount {
    return _hasData ? visible_solar_bodies([self displayedScene]).size() : 0;
}
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    RendererQualityScope canvas(context, _rendererDisplayOptions);
    [[NSColor colorWithSRGBRed:0.025 green:0.043 blue:0.072 alpha:1] setFill];
    NSRectFill(self.bounds);
    const NSRect map = [self mapRect];
    if (map.size.width < 160 || map.size.height < 100) return;
    RendererQualityScope text(context, _rendererDisplayOptions, RendererPrimitive::text);
    if (!_hasData) {
        self.toolTip = nil;
        [@"データを開くと太陽系を表示します。" drawAtPoint:NSMakePoint(map.origin.x + 20, NSMidY(map))
                                                    withAttributes:textStyle(NSColor.labelColor, 13)];
        return;
    }
    try {
        [self refreshTerrain];
        const auto frameOwner = _publishedScene;
        const auto frame = frameOwner ? frameOwner->scene() : [self scene];
        NSString *title = @"太陽中心 · J2000 黄道座標 · 透視投影 · 天体サイズは模式表示";
        if (frame.physical_navigation && !frame.surface_body) title = @"宇宙視点 · 距離と半径は実比率 · 地形は選択データから計算";
        else if (frame.surface_body) title = @"実半径とローカル地形 · 木土天海は基準球面 · 周囲の微小天体は記号";
        else if (frame.preview_body) title = @"選択天体の表面観察 · 模式半径 · ドラッグで観察方向を変更";
        else if (frame.earth_moon) title = @"地球と月 · 距離と半径は実比率 · 1.5 pt 未満は位置の記号 · 月軌道は地心相対";
        if (_showsTimeInfo || _terrainSceneCoordinator.has_active())
            title = [title stringByAppendingFormat:@" · 表示 JD %.5f", frame.julian_date];
        if (_terrainSceneCoordinator.has_active()) title = [title stringByAppendingString:@" · 地形更新中"];
        [title drawAtPoint:NSMakePoint(18, 10) withAttributes:textStyle(NSColor.secondaryLabelColor, 11)];
        NSString *galaxyStatus = nil;
        bool galaxyDrawn = false;
        // 地表は同じ公開フレーム内の天体姿勢を使い、星・星座と3Dカメラを揃える。
        // 離陸後の宇宙視点は従来どおり地球の局所座標で表せる間だけ共有する。
        std::optional<SurfaceSite> skySite;
        if (_surfaceStarRenderer && (frame.surface_body ||
                                     (_physicalSpaceActive && frame.physical_navigation))) {
            try {
                skySite = frame.surface_body
                    ? surface_sky_site_from_camera(frame.camera, frame.bodies, *frame.surface_body)
                    : surface_site_from_camera(frame.camera, frame.bodies, 3);
            }
            catch (const std::invalid_argument&) {
                // 局所座標を復元できない場合は通常の銀河描画を使う。
            }
        }
        const bool sharedStars = skySite.has_value();
        // 同じ全天画像を宇宙視点でも使い、銀河の 3D 描画へ徐々に引き継ぐ。
        if (const auto* texture = _surfaceBackgrounds ? _surfaceBackgrounds->image(_surfaceMilkyWayMode) : nullptr) {
            const double opacity = solar_background_opacity(frame.camera);
            if (opacity > 0) {
                const double maximumDimension = (self.flightAnimating || _dragged) ? 512 : 1024;
                const double scale = std::min(1.0, maximumDimension / std::max(frame.map.size.width, frame.map.size.height));
                const auto width = static_cast<std::size_t>(std::clamp(std::ceil(frame.map.size.width * scale), 1.0, maximumDimension));
                const auto height = static_cast<std::size_t>(std::clamp(std::ceil(frame.map.size.height * scale), 1.0, maximumDimension));
                const auto axes = solar_camera_basis(frame.camera);
                const auto stable = [](double value) { return std::round(value * 1e10) / 1e10; };
                const std::array<double, 12> key{stable(axes.outward.x), stable(axes.outward.y), stable(axes.outward.z),
                    stable(axes.right.x), stable(axes.right.y), stable(axes.right.z),
                    stable(axes.up.x), stable(axes.up.y), stable(axes.up.z),
                    static_cast<double>(width), static_cast<double>(height), frame.camera.vertical_fov_deg};
                if (!_surfaceBackgroundKey || *_surfaceBackgroundKey != key) {
                    const auto pixels = render_solar_background(*texture, frame.camera, width, height);
                    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
                        pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
                        isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:NSBitmapFormatAlphaNonpremultiplied
                        bytesPerRow:width * 4 bitsPerPixel:32];
                    if (bitmap) {
                        std::memcpy(bitmap.bitmapData, pixels.rgba.data(), pixels.rgba.size());
                        bitmap = [bitmap bitmapImageRepByRetaggingWithColorSpace:NSColorSpace.sRGBColorSpace];
                    }
                    _surfaceBackgroundImage = bitmap ? [[NSImage alloc] initWithSize:frame.map.size] : nil;
                    if (bitmap) [_surfaceBackgroundImage addRepresentation:bitmap];
                    _surfaceBackgroundKey = key;
                }
                RendererQualityScope clipped(context, frame.renderer_display);
                CGContextClipToRect(context, frame.map);
                [_surfaceBackgroundImage drawInRect:frame.map fromRect:NSZeroRect operation:NSCompositingOperationPlusLighter
                    fraction:opacity respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
            }
        }
        {
            try {
                const auto galaxyCamera = galaxy_camera_from_shared(shared_camera_from_solar(frame.camera));
                [_galaxyOverlay setHipVisible:_hipVisible && !sharedStars];
                [_galaxyOverlay drawInRect:frame.map camera:galaxyCamera quality:frame.renderer_display
                                    scale:frame.backing_scale selectedRecord:_galaxySelection surfaceView:frame.surface_body.has_value()];
                galaxyDrawn = true;
                galaxyStatus = _galaxyOverlay.status;
            } catch (const std::exception& error) {
                galaxyStatus = [NSString stringWithFormat:@"銀河を表示できません: %s", error.what()];
            }
        }
        if (sharedStars) {
            // 公開済みの地形フレームと同じ視点から座標を復元し、線と星のずれを避ける。
            const auto& site = *skySite;
            const ObservationFrame observation({site.latitude_deg, site.longitude_deg},
                                               frame.bodies[site.body_index].orientation);
            const HorizonViewport viewport{site.heading_deg, site.elevation_deg, 180, 1, site.roll_deg, frame.camera.vertical_fov_deg};
            if (_surfaceConstellationArt)
                draw_horizon_constellation_art(context, *_surfaceConstellationArt, _surfaceConstellationOptions,
                    frame.renderer_display, observation, viewport, frame.map);
            if (_surfaceSkyModel)
                draw_horizon_constellations(context, *_surfaceSkyModel, _surfaceConstellationOptions,
                    frame.renderer_display, observation, viewport, frame.map);
            RendererQualityScope clipped(context, frame.renderer_display);
            CGContextClipToRect(context, frame.map);
            [_surfaceStarRenderer drawInRect:frame.map magnitudeLimit:_surfaceMagnitudeLimit
                options:_surfaceStarOptions quality:frame.renderer_display
                projector:[&](EquatorialCoordinates coordinates) -> std::optional<StarProjection> {
                    const auto point = project_surface_star(coordinates, frame.camera,
                                                            frame.map.size.width, frame.map.size.height);
                    if (!point) return std::nullopt;
                    return StarProjection{{point->x, point->y}, 1};
                }];
        }
        auto diagnostics = draw_solar_scene(context, frame);
        _surfaceSkyPickScene = sharedStars && frame.surface_body ? frameOwner : nullptr;
        _surfaceSkyPickModel = _surfaceSkyPickScene ? _surfaceSkyModel : nullptr;
        _surfaceSkyPickOptions = _surfaceStarOptions;
        _surfaceSkyPickConstellations = _surfaceConstellationOptions;
        _surfaceSkyPickMagnitudeLimit = _surfaceMagnitudeLimit;
        if (sharedStars && frame.surface_body && _surfaceStarOptions.visible && _surfaceStarSelection &&
            _surfaceSkyModel && *_surfaceStarSelection < _surfaceSkyModel->stars().size()) {
            const auto& star = _surfaceSkyModel->stars()[*_surfaceStarSelection];
            const auto point = project_surface_star({star.right_ascension_degrees, star.declination_degrees},
                                                   frame.camera, frame.map.size.width, frame.map.size.height);
            if (point && star.apparent_v_magnitude <= _surfaceMagnitudeLimit &&
                !solar_scene_opaque_at(frame, NSMakePoint(frame.map.origin.x + point->x, frame.map.origin.y + point->y))) {
                RendererQualityScope clipped(context, frame.renderer_display);
                CGContextClipToRect(context, frame.map);
                [[NSColor systemYellowColor] setStroke];
                NSBezierPath *marker = [NSBezierPath bezierPathWithOvalInRect:
                    NSMakeRect(frame.map.origin.x + point->x - 6, frame.map.origin.y + point->y - 6, 12, 12)];
                marker.lineWidth = 1; [marker stroke];
            }
        }
        if (galaxyDrawn && _ourGalaxyPointSelection) {
            const auto position = [_galaxyOverlay displayedOurGalaxyPointPosition:*_ourGalaxyPointSelection];
            if (position) {
                const auto info = [_galaxyOverlay diagnostics];
                const GalaxyProjector projector(info.displayed->camera, map.size.width, map.size.height);
                const auto projected = projector.project(*position);
                if (projected && projector.contains(*projected)) {
                    [[NSColor systemYellowColor] setStroke];
                    NSBezierPath *marker = [NSBezierPath bezierPathWithOvalInRect:
                        NSMakeRect(map.origin.x + projected->x - 5, map.origin.y + projected->y - 5, 10, 10)];
                    marker.lineWidth = 1; [marker stroke];
                }
            }
        }
        if (galaxyDrawn && _galaxySelection && [_galaxyOverlay isRecordDisplayed:*_galaxySelection]) {
            const auto info = [_galaxyOverlay diagnostics];
            const auto position = [_galaxyOverlay model]->row(*_galaxySelection).position;
            if (info.displayed && position) {
                const GalaxyProjector projector(info.displayed->camera, map.size.width, map.size.height);
                const auto projected = projector.project(*position);
                if (projected && projector.contains(*projected)) {
                    [[NSColor systemYellowColor] setStroke];
                    NSBezierPath *marker = [NSBezierPath bezierPathWithOvalInRect:
                        NSMakeRect(map.origin.x + projected->x - 5, map.origin.y + projected->y - 5, 10, 10)];
                    marker.lineWidth = 1;
                    [marker stroke];
                }
            }
        }
        if (galaxyDrawn && _hipSelection && [_galaxyOverlay isHipDisplayed:*_hipSelection]) {
            const auto info = [_galaxyOverlay diagnostics];
            const auto position = [_galaxyOverlay hipModel]->points[*_hipSelection].position;
            const GalaxyProjector projector(info.displayed->camera, map.size.width, map.size.height);
            const auto projected = projector.project(position);
            if (projected && projector.contains(*projected)) {
                [[NSColor systemYellowColor] setStroke];
                NSBezierPath *marker = [NSBezierPath bezierPathWithOvalInRect:
                    NSMakeRect(map.origin.x + projected->x - 5, map.origin.y + projected->y - 5, 10, 10)];
                marker.lineWidth = 1; [marker stroke];
            }
        }
        if (galaxyDrawn && [_galaxyOverlay hipModel]) {
            NSString *note = @"HIP: 正視差のみ・固定光度、固有運動なし";
            galaxyStatus = galaxyStatus.length ? [galaxyStatus stringByAppendingFormat:@" · %@", note] : note;
        }
        if (galaxyDrawn && [_galaxyOverlay ourGalaxyModel]) {
            NSString *note = @"天の川: 座標仮定・低解像度の放射吸収。旧 Plus との一致、星や銀河個別の吸収は未検証";
            galaxyStatus = galaxyStatus.length ? [galaxyStatus stringByAppendingFormat:@" · %@", note] : note;
        }
        if (galaxyStatus.length)
            [galaxyStatus drawAtPoint:NSMakePoint(map.origin.x + 8, NSMaxY(map) - 20)
                                withAttributes:textStyle(NSColor.secondaryLabelColor, 10)];
        const auto terrain = [self terrainDiagnostics];
        diagnostics.insert(diagnostics.end(), terrain.begin(), terrain.end());
        NSMutableArray<NSString *> *messages = [NSMutableArray arrayWithCapacity:diagnostics.size()];
        for (const auto& diagnostic : diagnostics) {
            NSString *message = [[NSString alloc] initWithBytes:diagnostic.data() length:diagnostic.size()
                encoding:NSUTF8StringEncoding];
            [messages addObject:message ? message : @"診断の文字コードを表示できません。"];
        }
        self.toolTip = messages.count ? [messages componentsJoinedByString:@"\n"] : nil;
        if (messages.count) {
            NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
            paragraph.lineBreakMode = NSLineBreakByTruncatingTail;
            NSMutableDictionary *style = [textStyle(NSColor.systemOrangeColor, 11) mutableCopy];
            style[NSParagraphStyleAttributeName] = paragraph;
            [[NSString stringWithFormat:@"描画の診断 %lu 件（詳細はポインタを置いて表示）: %@",
                messages.count, messages.firstObject]
                drawInRect:NSMakeRect(map.origin.x + 8, map.origin.y + 8, map.size.width - 16, 18)
                withAttributes:style];
        }
    }
    catch (const std::exception& error) {
        self.toolTip = [NSString stringWithUTF8String:error.what()];
        [[NSString stringWithFormat:@"描画できません: %s", error.what()] drawAtPoint:NSMakePoint(map.origin.x + 20, NSMidY(map))
            withAttributes:textStyle(NSColor.labelColor, 12)];
    }
    const auto helpOwner = _publishedScene;
    const auto helpScene = helpOwner ? helpOwner->scene() : [self scene];
    NSString *help = [NSString stringWithFormat:@"ドラッグ: 回転   Optionドラッグ: ロール   Shift / 右ドラッグ: 移動   スクロール / ピンチ: 拡縮   格子: %d AU", helpScene.camera.distance_au < 15 ? 1 : 10];
    if (_journeyActive && helpScene.physical_navigation && !helpScene.surface_body) help = @"飛行中は手動の視点操作を固定 · 一覧の選択は次の目的地 · 全体表示で飛行を終了";
    else if (helpScene.surface_body) help = @"ドラッグ: 見回す   スクロール / ピンチ: 高度変更   天体の選択: 右の一覧   操作すると飛行を中断";
    else if (helpScene.preview_body) help = @"ドラッグ: 回転   Optionドラッグ: ロール   Shift / 右ドラッグ: 移動   スクロール / ピンチ: 拡縮";
    else if (helpScene.earth_moon) help = @"ドラッグ: 回転   Optionドラッグ: ロール   Shift / 右ドラッグ: 移動   スクロール / ピンチ: 拡縮";
    [help drawAtPoint:NSMakePoint(18, NSMaxY(self.bounds) - 24) withAttributes:textStyle(NSColor.secondaryLabelColor, 10)];
    if (helpScene.small_bodies) {
        NSString *time = _showsTimeInfo ? [NSString stringWithFormat:@" · 数値 JD %.5f", helpScene.small_bodies->julian_date] : @"";
        NSString *status = [NSString stringWithFormat:@"小天体 %lu / 原本 %lu 件を位置評価 · 二体近似%@（時系変換なし）",
            helpScene.small_bodies->positioned_count, helpScene.small_bodies->positions.size(), time];
        [status drawAtPoint:NSMakePoint(18, NSMaxY(self.bounds) - 39) withAttributes:textStyle(NSColor.secondaryLabelColor, 10)];
    }
}
@end
