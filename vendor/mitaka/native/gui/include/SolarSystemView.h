#import <AppKit/AppKit.h>
#include "sky_model.hpp"
#include "solar_camera.hpp"
#include "plus_camera_orientation.hpp"
#include "surface_navigation.hpp"
#include "planet_textures.hpp"
#include "small_body_model.hpp"
#include "satellite_browser_model.hpp"
#import "SpacecraftRenderer.h"
#include "small_body_display.hpp"
#include "satellite_display.hpp"
#include "satellite_scene_update.hpp"
#include "display_options.hpp"
#include "extended_catalogs.hpp"
#include "radius_display.hpp"
#include "renderer_options.hpp"
#include "atmosphere_renderer.hpp"
#include "eclipse_display.hpp"
#include "terrain_amplification.hpp"
#include "constellation_display.hpp"
#include "constellation_art_model.hpp"
#include "sky_background.hpp"
#include "galaxy_spatial_scene.hpp"
#include "mitaka/observation.hpp"
#include <memory>
#include <set>
namespace mitaka { struct OurGalaxyModel; }
namespace mitaka::gui { struct SmallBodyOrbitSnapshot; struct SatelliteOrbitGeometry; struct GalaxySpatialVisibility; class GalaxySpatialModel; struct HipSpatialModel; }

@interface SolarSystemView : NSView
@property(nonatomic) mitaka::gui::PlanetDisplayOptions planetDisplayOptions;
@property(nonatomic) mitaka::gui::RadiusDisplayOptions radiusDisplayOptions;
@property(nonatomic) mitaka::gui::TerrainAmplification terrainAmplification;
@property(nonatomic) mitaka::gui::RendererDisplayOptions rendererDisplayOptions;
@property(nonatomic) mitaka::gui::GridDisplayOptions gridDisplayOptions;
@property(nonatomic) mitaka::gui::EarthLayerOptions earthLayerOptions;
@property(nonatomic) mitaka::gui::AtmosphereDisplayOptions atmosphereDisplayOptions;
@property(nonatomic) mitaka::gui::EclipseDisplayOptions eclipseDisplayOptions;
- (void)setObservationSite:(mitaka::ObserverSite)site julianDate:(double)julianDate;
@property(nonatomic, copy) void (^selectionChanged)(NSString *description);
// 選択の変更時に親惑星の出典を同期する。解除は NSNotFound、同 index の再選択は通知しない。
@property(nonatomic, copy) void (^satelliteSelectionChanged)(NSUInteger index);
@property(nonatomic, copy) void (^cameraChanged)(NSString *description);
@property(nonatomic, readonly) NSUInteger visibleBodyCount;
@property(nonatomic, readonly) NSUInteger selectedBodyIndex;
@property(nonatomic, readonly) BOOL surfaceNavigationActive;
@property(nonatomic, readonly) BOOL scriptPlanetariumMode;
@property(nonatomic, readonly) BOOL journeyActive;
@property(nonatomic, readonly) BOOL flightAnimating;
@property(nonatomic) BOOL showsTimeInfo;
@property(nonatomic, copy) void (^navigationChanged)(void);
@property(nonatomic, copy) void (^userSurfaceViewChange)(void);
// 全体表示と地球・月／地表／飛行表示の切替後に通知する。カメラ移動だけでは通知しない。
@property(nonatomic, copy) void (^overviewVisibilityChanged)(BOOL visible);
- (std::shared_ptr<const mitaka::OurGalaxyModel>)ourGalaxyModel;
- (std::shared_ptr<const mitaka::gui::HipSpatialModel>)hipModel;
- (void)setHipModel:(std::shared_ptr<const mitaka::gui::HipSpatialModel>)model;
- (void)setOurGalaxyModel:(std::shared_ptr<const mitaka::OurGalaxyModel>)model;
- (void)setGalaxyModel:(std::shared_ptr<const mitaka::gui::GalaxySpatialModel>)model;
- (void)setGalaxyVisibility:(mitaka::gui::GalaxySpatialVisibility)visibility;
- (void)setHipVisible:(BOOL)visible;
- (void)setSurfaceStarModel:(std::shared_ptr<const mitaka::gui::SkyModel>)model
                  catalogs:(std::shared_ptr<const mitaka::gui::ExtendedCatalogs>)catalogs;
- (void)setSurfaceStarDisplayOptions:(mitaka::gui::StarDisplayOptions)options;
@property(nonatomic) mitaka::gui::ConstellationDisplayOptions surfaceConstellationDisplayOptions;
- (void)setSurfaceConstellationArt:(std::shared_ptr<const mitaka::gui::ConstellationArtModel>)art;
@property(nonatomic) mitaka::gui::MilkyWayMode surfaceMilkyWayMode;
- (void)setSurfaceSkyBackgrounds:(std::shared_ptr<const mitaka::gui::SkyBackgrounds>)backgrounds;
- (void)setSurfaceMagnitudeLimit:(double)limit;
- (void)setSurfaceSelectedStarNameHIPs:(const std::set<std::int32_t>&)hips;
- (void)setOurGalaxyVisible:(BOOL)visible;
- (void)setTextures:(std::shared_ptr<const mitaka::gui::PlanetTextures>)textures;
- (void)setBodies:(const mitaka::gui::SolarBodies&)bodies;
- (void)setBodies:(const mitaka::gui::SolarBodies&)bodies
           orbits:(const mitaka::gui::SolarOrbits&)orbits;
- (void)setLunarOrbit:(const std::vector<mitaka::Vec3>&)orbit;
// 日時更新時の複数の setter を一つの表示場面として捕捉する。
- (void)beginSceneUpdate;
- (void)endSceneUpdate;
- (void)selectBody:(NSUInteger)index;
- (void)resetCamera;
- (void)showInnerPlanets;
- (void)zoomIn;
- (void)zoomOut;
- (void)focusSelection;
- (void)showOurGalaxyOverview;
- (void)showSurface;
- (NSString *)cameraStateDescription;
- (mitaka::gui::SolarCamera)cameraState;
- (void)setCameraState:(const mitaka::gui::SolarCamera&)camera;
// 検証に失敗した場合は、視点・追従・飛行状態を変更しない。
- (BOOL)applyCameraState:(const mitaka::gui::SolarCamera&)camera error:(NSString **)error;
@end

@interface SolarSystemView (ScriptTargets)
- (std::optional<double>)scriptTargetRadiusAU;
- (void)applyScriptZoomMode:(int)mode previousRadius:(std::optional<double>)previousRadius initialDistance:(double)initialDistance;
- (void)stopScriptTargetTransition;
- (void)animateScriptTargetFrom:(const mitaka::gui::SolarCamera&)initial duration:(double)duration;
- (void)animateScriptPlaceTargetFrom:(const mitaka::gui::SolarCamera&)initial duration:(double)duration;
- (BOOL)selectScriptEarthPlaceLatitude:(double)latitude longitude:(double)longitude surface:(BOOL)surface error:(NSString **)error;
- (BOOL)moveScriptEarthSurfaceLatitude:(double)latitude longitude:(double)longitude;
- (void)setScriptEarthPlaceTarget:(const std::string&)target;
- (const std::string&)scriptEarthPlaceTarget;
- (const std::string&)scriptOverviewTarget;
- (BOOL)selectScriptOverviewTarget:(const std::string&)target error:(NSString **)error;
- (BOOL)selectScriptStarTarget:(const std::string&)target error:(NSString **)error;
- (std::optional<std::int32_t>)selectedScriptStarHIP;
- (std::optional<mitaka::gui::GalaxySpatialRecordId>)selectedScriptGalaxyRecord;
- (BOOL)isScriptOurGalaxySelected;
- (BOOL)selectScriptGalaxyRecord:(mitaka::gui::GalaxySpatialRecordId)record error:(NSString **)error;
- (BOOL)selectScriptOurGalaxyOverview:(BOOL)overview error:(NSString **)error;
@end

@interface SolarSystemView (SmallBodies)
@property(nonatomic) BOOL smallBodiesVisible;
@property(nonatomic, readonly) NSUInteger selectedSmallBodyIndex;
@property(nonatomic, readonly) NSUInteger visibleSmallBodyCount;
- (BOOL)smallBodiesSceneVisible;
- (void)setSmallBodySnapshot:(std::shared_ptr<const mitaka::gui::SmallBodySnapshot>)snapshot;
- (void)selectSmallBody:(NSUInteger)index;
- (void)setSmallBodyDisplayModel:(std::shared_ptr<const mitaka::gui::SmallBodyDisplayModel>)display;
- (std::shared_ptr<const mitaka::gui::SmallBodyDisplayModel>)smallBodyDisplayModel;
- (void)setSmallBodyOrbitSnapshot:(std::shared_ptr<const mitaka::gui::SmallBodyOrbitSnapshot>)snapshot;
@end

@interface SolarSystemView (Satellites)
@property(nonatomic, readonly) NSUInteger selectedSatelliteIndex;
@property(nonatomic, readonly) NSUInteger visibleSatelliteCount;
- (void)setSatelliteSnapshot:(std::shared_ptr<const mitaka::gui::SatelliteSnapshot>)snapshot;
// commit は事前計算済みの値だけを交換し、通知・追従更新は finish で行う。
- (BOOL)commitPreparedSatelliteScene:(const mitaka::gui::PreparedSatelliteScene&)scene;
- (void)finishSatelliteSceneUpdate:(BOOL)notifySelection;
- (void)selectSatellite:(NSUInteger)index;
- (void)setSatelliteDisplayModel:(std::shared_ptr<const mitaka::gui::SatelliteDisplayModel>)display;
- (std::shared_ptr<const mitaka::gui::SatelliteDisplayModel>)satelliteDisplayModel;
- (std::shared_ptr<const mitaka::gui::SatelliteOrbitGeometry>)satelliteOrbitGeometry;
@end

@interface SolarSystemView (Spacecraft)
@property(nonatomic) BOOL spacecraftVisible;
@property(nonatomic) mitaka::gui::SpacecraftDisplayOptions spacecraftDisplayOptions;
@property(nonatomic, readonly) NSUInteger selectedSpacecraftIndex;
@property(nonatomic, readonly) NSUInteger visibleSpacecraftCount;
- (void)setSpacecraftSnapshot:(std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>)snapshot;
- (void)selectSpacecraft:(NSUInteger)index;
@end

@interface SolarSystemView (Navigation)
- (void)startJourneyAtLatitude:(double)latitude longitude:(double)longitude;
- (void)resumeJourney;
- (void)showEarthMoon;
- (void)landAtLatitude:(double)latitude longitude:(double)longitude;
- (void)takeOff;
- (void)takeOffFromEarthAtLatitude:(double)latitude longitude:(double)longitude;
- (BOOL)takeOffFromHorizon:(mitaka::gui::SurfaceSite)site error:(NSString **)error;
- (BOOL)takeOffFromHorizon:(mitaka::gui::SurfaceSite)site duration:(double)duration error:(NSString **)error;
- (BOOL)forceSpaceFromHorizon:(mitaka::gui::SurfaceSite)site error:(NSString **)error;
- (BOOL)descendToHorizon:(NSString **)error;
- (BOOL)descendToHorizonWithDuration:(double)duration error:(NSString **)error;
- (BOOL)descendToSelectedSurfaceWithDuration:(double)duration error:(NSString **)error;
- (BOOL)ascendFromEarthWithDuration:(double)duration error:(NSString **)error;
- (BOOL)ascendFromSurfaceWithDuration:(double)duration error:(NSString **)error;
- (BOOL)earthSurfaceSite:(mitaka::gui::SurfaceSite *)site;
- (BOOL)scriptSurfaceSite:(mitaka::gui::SurfaceSite *)site;
- (BOOL)scriptSetSurfaceAzimuth:(double)azimuth altitude:(double)altitude;
- (BOOL)scriptBodyEclipticPosition:(NSUInteger)index result:(mitaka::Vec3 *)result;
- (BOOL)scriptSurfaceLookVector:(mitaka::Vec3)vector position:(BOOL)isPosition result:(mitaka::gui::SurfaceSite *)result;
- (BOOL)forceSurfaceMode:(BOOL)surface bodyIndex:(NSUInteger *)bodyIndex error:(NSString **)error;
- (void)interruptFlight;
@end

@interface SolarSystemView (SmokeTests)
- (BOOL)runContinuousFlightSmokeTest;
- (BOOL)runSurfaceNavigationSmokeTest;
- (BOOL)runCameraSmokeTest;
- (BOOL)runTextureSmokeTest;
- (BOOL)runRotationSmokeTest:(const mitaka::BodyOrientation&)laterEarthOrientation;
@end

@interface SolarSystemView (Terrain)
- (void)setTerrainDataDirectory:(NSString *)directory;
- (void)cancelTerrain;
- (void)reloadTerrain;
@end

@interface SolarSystemView (ScriptOrientation)
- (void)stopScriptOrientation;
- (BOOL)scriptCameraOrientationAvailable;
- (mitaka::gui::PlusOrientationQuaternion)scriptCameraOrientation;
- (BOOL)scriptSetCameraOrientation:(mitaka::gui::PlusOrientationQuaternion)orientation duration:(double)duration smooth:(BOOL)smooth error:(NSString **)error;
- (BOOL)scriptSetCameraEuler:(mitaka::gui::PlusOrientationEuler)euler relative:(BOOL)relative duration:(double)duration smooth:(BOOL)smooth error:(NSString **)error;
@end
