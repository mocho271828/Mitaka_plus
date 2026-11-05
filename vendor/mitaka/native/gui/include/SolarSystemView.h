#import <AppKit/AppKit.h>
#include "sky_model.hpp"
#include "solar_camera.hpp"
#include "planet_textures.hpp"
#include "small_body_model.hpp"
#include "satellite_browser_model.hpp"
#import "SpacecraftRenderer.h"
#include "small_body_display.hpp"
#include "satellite_display.hpp"
#include "display_options.hpp"
#include "radius_display.hpp"
#include "renderer_options.hpp"
#include "atmosphere_renderer.hpp"
#include "eclipse_display.hpp"
#include "terrain_amplification.hpp"
#include "mitaka/observation.hpp"
#include <memory>
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
@property(nonatomic, readonly) BOOL journeyActive;
@property(nonatomic, readonly) BOOL flightAnimating;
@property(nonatomic) BOOL showsTimeInfo;
@property(nonatomic, copy) void (^navigationChanged)(void);
// 全体表示と地球・月／地表／飛行表示の切替後に通知する。カメラ移動だけでは通知しない。
@property(nonatomic, copy) void (^overviewVisibilityChanged)(BOOL visible);
- (std::shared_ptr<const mitaka::OurGalaxyModel>)ourGalaxyModel;
- (std::shared_ptr<const mitaka::gui::HipSpatialModel>)hipModel;
- (void)setHipModel:(std::shared_ptr<const mitaka::gui::HipSpatialModel>)model;
- (void)setOurGalaxyModel:(std::shared_ptr<const mitaka::OurGalaxyModel>)model;
- (void)setGalaxyModel:(std::shared_ptr<const mitaka::gui::GalaxySpatialModel>)model;
- (void)setGalaxyVisibility:(mitaka::gui::GalaxySpatialVisibility)visibility;
- (void)setHipVisible:(BOOL)visible;
- (void)setOurGalaxyVisible:(BOOL)visible;
- (void)setTextures:(std::shared_ptr<const mitaka::gui::PlanetTextures>)textures;
- (void)setBodies:(const mitaka::gui::SolarBodies&)bodies;
- (void)setBodies:(const mitaka::gui::SolarBodies&)bodies
           orbits:(const mitaka::gui::SolarOrbits&)orbits;
- (void)setLunarOrbit:(const std::vector<mitaka::Vec3>&)orbit;
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
