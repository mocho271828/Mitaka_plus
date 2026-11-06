#pragma once
#import "SolarSystemView.h"
#import "SolarSceneRenderer.h"
#import "GridRenderer.h"
#import "TerrainSurfaceController.h"
#import "TerrainLandingController.h"
#import "TerrainSceneState.h"
#include "surface_navigation.hpp"
#include "script_zoom_transition.hpp"
#include "interplanetary_flight.hpp"
#import "GalaxyOverlay.h"
#import "StarRenderer.h"
@class GalaxyOverlay;

enum class ScriptOrientationInterpolation { quaternion, euler, relative_euler };

struct ScriptOrientationAnimation {
    mitaka::gui::PlusOrientationQuaternion initial;
    mitaka::gui::PlusOrientationQuaternion target;
    mitaka::gui::PlusOrientationEuler initial_euler;
    mitaka::gui::PlusOrientationEuler target_euler;
    double start_time, duration;
    bool smooth;
    ScriptOrientationInterpolation interpolation;
};

struct ScriptTargetAnimation {
    mitaka::gui::SolarCamera initial, target;
    double initial_distance, target_distance, start_time, duration;
    std::optional<std::size_t> body, small_body, spacecraft, satellite;
    std::optional<mitaka::gui::GalaxySpatialRecordId> galaxy;
    bool our_galaxy;
    std::optional<mitaka::gui::PlusOrientationQuaternion> initial_orientation, target_orientation;
    bool updates_distance = true;
};

struct LandingKey {
    std::filesystem::path root;
    std::size_t body;
    double latitude, longitude, factor;
    bool operator==(const LandingKey& other) const {
        return root == other.root && body == other.body && latitude == other.latitude &&
            longitude == other.longitude && factor == other.factor;
    }
};

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
    StarRenderer *_surfaceStarRenderer;
    std::shared_ptr<const mitaka::gui::SkyModel> _surfaceSkyModel;
    std::shared_ptr<const mitaka::gui::ConstellationArtModel> _surfaceConstellationArt;
    mitaka::gui::ConstellationDisplayOptions _surfaceConstellationOptions;
    std::shared_ptr<const mitaka::gui::SkyBackgrounds> _surfaceBackgrounds;
    mitaka::gui::MilkyWayMode _surfaceMilkyWayMode;
    NSImage *_surfaceBackgroundImage;
    std::optional<std::array<double, 11>> _surfaceBackgroundKey;
    mitaka::gui::StarDisplayOptions _surfaceStarOptions;
    double _surfaceMagnitudeLimit;
    BOOL _hipVisible;
    std::optional<mitaka::gui::GalaxySpatialRecordId> _galaxySelection;
    std::optional<std::size_t> _hipSelection;
    std::optional<mitaka::gui::OurGalaxyPointId> _ourGalaxyPointSelection;
    BOOL _ourGalaxySelected;
    std::vector<mitaka::Vec3> _lunarOrbit;
    mitaka::gui::SurfaceNavigation _navigation;
    mitaka::gui::InterplanetaryFlight _journey;
    BOOL _journeyActive;
    BOOL _dateJourneyFinished;
    NSTimer *_flightTimer;
    NSTimer *_orientationTimer;
    std::optional<ScriptOrientationAnimation> _orientationAnimation;
    NSTimer *_zoomTimer;
    std::optional<mitaka::gui::ScriptZoomTransition> _zoomAnimation;
    NSTimer *_targetTimer;
    std::optional<ScriptTargetAnimation> _targetAnimation;
    std::optional<mitaka::gui::PlusOrientationQuaternion> _scriptOrientation;
    std::optional<mitaka::gui::PlusOrientationQuaternion> _flightOrientation;
    NSString *_flightNotice;
    BOOL _surfaceActive;
    BOOL _physicalSpaceActive;
    BOOL _exitSurfaceAfterAscent;
    BOOL _surfacePreview;
    BOOL _earthMoonMode;
    BOOL _earthMoonFollowing;
    BOOL _notifiedOverviewVisible;
    double _lastFlightTime;
    std::shared_ptr<const mitaka::gui::PlanetTextures> _textures;
    std::optional<std::size_t> _selection;
    std::string _scriptEarthPlaceTarget;
    std::string _scriptOverviewTarget;
    std::optional<mitaka::gui::SurfaceSite> _scriptSpacePlace;
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
    std::uint64_t _sceneRevision;
    unsigned _sceneUpdateDepth;
    std::uint64_t _submittedSceneRevision;
    TerrainSceneCoordinator _terrainSceneCoordinator;
    std::shared_ptr<SolarSceneOwner> _publishedScene;
    NSRect _terrainViewport;
    double _terrainBackingScale;
    BOOL _hasTerrainViewport;
    TerrainLandingController *_landingController;
    std::optional<LandingKey> _landingKey;
    std::optional<mitaka::gui::TerrainLandingResult> _landingResult;
    std::optional<std::size_t> _landingSuppressedBody;
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
- (NSString *)suspendTerrainForFlightSmoke;
- (void)refreshTerrain;
- (void)refreshLanding;
- (void)resetLanding;
- (NSArray<TerrainSurfaceController *> *)makeTerrainControllers;
- (void)applyTerrainTransition:(TerrainSceneCoordinator::Transition)transition;
- (SolarScene)displayedScene;
- (BOOL)matchesDisplayedCamera:(const mitaka::gui::SolarCamera&)camera map:(NSRect)map;
- (void)redrawPublishedScene;
- (std::vector<std::string>)terrainDiagnostics;
- (NSRect)mapRect;
- (mitaka::Vec3)displayPosition:(NSUInteger)index;
- (mitaka::Vec3)scriptSpacePlacePositionForBodies:(const mitaka::gui::SolarBodies&)bodies;
- (SolarScene)scene;
- (CGFloat)radiusForBody:(NSUInteger)index depth:(double)depth;
- (void)updateTrackedCamera;
- (void)keepCameraOutsideBodies:(mitaka::gui::SolarCamera&)camera;
- (void)notifySelection;
- (void)notifyCamera;
- (void)changeCamera:(void (^)(mitaka::gui::SolarCamera&))change;
- (void)zoomBy:(double)delta;
- (void)orbitByX:(double)dx y:(double)dy;
- (void)panByX:(double)dx y:(double)dy;
- (void)pickBodyAtPoint:(NSPoint)click;
- (void)clearGalaxySelection;
- (std::optional<mitaka::gui::GalaxySpatialRecordId>)selectedGalaxyRecord;
- (std::optional<std::size_t>)selectedHipIndex;
- (std::optional<mitaka::gui::OurGalaxyPointId>)selectedOurGalaxyPoint;
- (BOOL)isOurGalaxySelected;
- (mitaka::gui::GalaxyOverlayDiagnostics)galaxyOverlayDiagnostics;
- (void)reportNavigationError:(const char *)message;
- (void)invalidateFlightTimer;
- (void)leaveNavigation;
- (void)advanceFlightAtTime:(double)time;
- (void)updateJourneyAtTime:(double)time;
- (void)restoreFlightOrientation;
- (void)startFlightTimer;
- (BOOL)beginFlightAtSite:(mitaka::gui::SurfaceSite)site ascending:(BOOL)ascending preserveLook:(BOOL)preserveLook duration:(double)duration error:(NSString **)error;
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
