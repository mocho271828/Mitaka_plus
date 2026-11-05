#pragma once
#import "SolarSystemView.h"
#import "SolarSceneRenderer.h"
#import "GridRenderer.h"
#import "TerrainSurfaceController.h"
#include "surface_navigation.hpp"
#include "interplanetary_flight.hpp"
#import "GalaxyOverlay.h"
@class GalaxyOverlay;

@interface SolarSystemView () {
    mitaka::gui::SolarBodies _bodies;
    mitaka::gui::PlanetDisplayOptions _planetDisplayOptions;
    mitaka::gui::RadiusDisplayOptions _radiusDisplayOptions;
    mitaka::gui::TerrainAmplification _terrainAmplification;
    mitaka::gui::RendererDisplayOptions _rendererDisplayOptions;
    mitaka::gui::GridDisplayOptions _gridDisplayOptions;
    mitaka::gui::EarthLayerOptions _earthLayerOptions;
    mitaka::gui::AtmosphereDisplayOptions _atmosphereDisplayOptions;
    mitaka::gui::EclipseDisplayOptions _eclipseDisplayOptions;
    mitaka::gui::GridGeometryCache _gridCache;
    double _julianDate;
    mitaka::gui::SolarOrbits _orbits;
    mitaka::gui::SolarCamera _camera;
    std::optional<mitaka::gui::SolarCamera> _lastNotifiedCamera;
    GalaxyOverlay *_galaxyOverlay;
    std::optional<mitaka::gui::GalaxySpatialRecordId> _galaxySelection;
    std::optional<std::size_t> _hipSelection;
    BOOL _ourGalaxySelected;
    std::vector<mitaka::Vec3> _lunarOrbit;
    mitaka::gui::SurfaceNavigation _navigation;
    mitaka::gui::InterplanetaryFlight _journey;
    BOOL _journeyActive;
    NSTimer *_flightTimer;
    NSString *_flightNotice;
    BOOL _surfaceActive;
    BOOL _surfacePreview;
    BOOL _earthMoonMode;
    BOOL _earthMoonFollowing;
    BOOL _notifiedOverviewVisible;
    double _lastFlightTime;
    std::shared_ptr<const mitaka::gui::PlanetTextures> _textures;
    std::optional<std::size_t> _selection;
    std::shared_ptr<const mitaka::gui::SmallBodySnapshot> _smallBodySnapshot;
    std::optional<std::size_t> _smallBodySelection;
    BOOL _smallBodiesVisible;
    std::shared_ptr<const mitaka::gui::SatelliteSnapshot> _satelliteSnapshot;
    std::optional<std::size_t> _satelliteSelection;
    std::optional<std::size_t> _notifiedSatelliteSelection;
    std::shared_ptr<const mitaka::gui::SpacecraftSnapshot> _spacecraftSnapshot;
    std::optional<std::size_t> _spacecraftSelection;
    mitaka::gui::SpacecraftDisplayOptions _spacecraftDisplayOptions;
    BOOL _spacecraftVisible;
    std::shared_ptr<const mitaka::gui::SmallBodyDisplayModel> _smallBodyDisplay;
    std::shared_ptr<const mitaka::gui::SmallBodyOrbitSnapshot> _smallBodyOrbits;
    std::shared_ptr<const mitaka::gui::SatelliteDisplayModel> _satelliteDisplay;
    std::shared_ptr<const mitaka::gui::SatelliteOrbitGeometry> _satelliteOrbits;
    BOOL _showsTimeInfo;
    BOOL _hasData;
    NSString *_terrainDataDirectory;
    NSArray<TerrainSurfaceController *> *_terrainControllers;
    std::array<std::optional<mitaka::gui::TerrainSurfaceRequest>, 11> _terrainRequests;
    std::array<std::shared_ptr<const mitaka::gui::TerrainSurfaceSnapshot>, 11> _terrainSnapshots;
    std::array<std::string, 11> _terrainErrors;
    BOOL _following;
    BOOL _dragged;
    NSPoint _lastDrag;
    NSPoint _mouseStart;
}
@end

@interface SolarSystemView (Internal)
- (void)refreshTerrain;
- (std::vector<std::string>)terrainDiagnostics;
- (NSRect)mapRect;
- (mitaka::Vec3)displayPosition:(NSUInteger)index;
- (SolarScene)scene;
- (CGFloat)radiusForBody:(NSUInteger)index depth:(double)depth;
- (void)updateTrackedCamera;
- (void)notifySelection;
- (void)notifyCamera;
- (void)zoomBy:(double)delta;
- (void)orbitByX:(double)dx y:(double)dy;
- (void)panByX:(double)dx y:(double)dy;
- (void)pickBodyAtPoint:(NSPoint)click;
- (void)clearGalaxySelection;
- (std::optional<mitaka::gui::GalaxySpatialRecordId>)selectedGalaxyRecord;
- (std::optional<std::size_t>)selectedHipIndex;
- (BOOL)isOurGalaxySelected;
- (mitaka::gui::GalaxyOverlayDiagnostics)galaxyOverlayDiagnostics;
- (void)reportNavigationError:(const char *)message;
- (void)invalidateFlightTimer;
- (void)leaveNavigation;
- (void)advanceFlightAtTime:(double)time;
- (void)updateJourneyAtTime:(double)time;
- (void)startFlightTimer;
- (void)beginFlightAtSite:(mitaka::gui::SurfaceSite)site ascending:(BOOL)ascending;
- (void)changeSurfaceByX:(double)dx y:(double)dy zoom:(double)zoom;
- (BOOL)smallBodiesSceneVisible;
- (void)focusSmallBodySelection;
- (NSString *)smallBodySelectionDescription;
- (BOOL)rejectSmallBodySurfaceNavigation;
- (BOOL)satellitesSceneVisible;
- (void)focusSatelliteSelection;
- (NSString *)satelliteSelectionDescription;
- (BOOL)rejectSatelliteSurfaceNavigation;
- (BOOL)spacecraftSceneVisible;
- (void)focusSpacecraftSelection;
- (NSString *)spacecraftSelectionDescription;
- (BOOL)rejectSpacecraftSurfaceNavigation;
@end
