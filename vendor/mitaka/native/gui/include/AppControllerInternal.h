#pragma once
#import "AppController.h"
#import "SkyView.h"
#import "SolarSystemView.h"
#import "PlaybackController.h"
#import "CatalogBrowserController.h"
#import "HorizonView.h"
#import "ScriptController.h"
#import "DisplayOutputController.h"
#import "SmallBodyController.h"
#import "SatelliteController.h"
#import "SpacecraftController.h"
#import "MediaController.h"
#import "WindowPresentationController.h"
#import "StarBrightnessController.h"
#import "GalaxyController.h"
#import "RadiusDisplayController.h"
#include "session_state.hpp"
#include "extended_catalogs.hpp"
#include "observer_places.hpp"
#include "earth_landscapes.hpp"
#include "sky_background.hpp"
#include "calendar_time.hpp"
#include "constellation_display.hpp"
#include "constellation_art_model.hpp"
#include "star_name_selection.hpp"
#include "satellite_display.hpp"
#include "mitaka/small_body_orbit_path.hpp"
#include <cmath>
#include <memory>
#include <atomic>

@class HtmlBrowserController;
@class SmallBodyOrbitController;
namespace mitaka::gui { struct SmallBodyOrbitSnapshot; }

using namespace mitaka::gui;

inline mitaka::GregorianDateTime displayDate(double jd) {
    // JD の一時間加算には微小誤差があるため、表示だけを分単位へ丸める。
    // 日付と時分を分離して、13:00 が 12:59 に切り捨てられるのを防ぐ。
    const double minutes = std::round((jd + 0.5) * 1440.0);
    const double day = std::floor(minutes / 1440.0);
    auto date = mitaka::gregorian_date_time(day - 0.5);
    const int minuteOfDay = static_cast<int>(minutes - day * 1440.0);
    date.hour = minuteOfDay / 60;
    date.minute = minuteOfDay % 60;
    return date;
}

struct ScriptCameraAnimation {
    double start, target, start_time, duration;
    bool smooth;
};

struct ScriptPlaceTransition {
    mitaka::Vec3 start, tangent;
    double angle, start_time, duration, latitude, longitude;
    NSInteger mode;
    std::size_t body_index;
    std::string target;
};

struct HorizonOrientationAnimation {
    PlusOrientationQuaternion initial, target;
    PlusOrientationEuler initial_euler, target_euler;
    double start_time, duration;
    bool smooth, quaternion, relative;
};

struct ScriptLookTarget {
    enum class Kind { body, star, small_body, spacecraft, constellation, satellite, galaxy, our_galaxy } kind;
    std::size_t index;
    std::shared_ptr<const mitaka::gui::SkyModel> constellation_model{};
    std::shared_ptr<const mitaka::gui::GalaxySpatialModel> galaxy_model{};
};

@interface AppController () {
    NSWindow *_window;
    WindowPresentationController *_windowPresentation;
    SkyView *_sky;
    HorizonView *_horizon;
    SolarSystemView *_solar;
    PlaybackController *_playback;
    NSSegmentedControl *_mode;
    NSUInteger _modeGeneration;
    NSArray<NSButton *> *_cameraButtons, *_travelButtons;
    NSButton *_journeyButton, *_resumeJourneyButton;
    BOOL _pendingEarthDescent;
    NSTimer *_horizonProjectionTimer;
    double _horizonProjectionStartTime, _horizonProjectionDuration;
    double _horizonProjectionStart, _horizonProjectionTarget, _horizonAscentDuration;
    double _earthDescentProjectionDuration;
    NSTextField *_latitudeField, *_longitudeField;
    NSTextField *_cameraLabel, *_note;
    NSString *_skySelection, *_solarSelection, *_horizonSelection;
    NSTextField *_pathLabel, *_status, *_dateLabel, *_jdField, *_magnitudeLabel, *_selectionLabel;
    NSSlider *_magnitudeSlider;
    NSArray<NSButton *> *_timeButtons;
    NSMutableArray<NSButton *> *_bodyButtons;
    CatalogBrowserController *_browser;
    GalaxyController *_galaxyBrowser;
    std::shared_ptr<const GalaxySpatialModel> _galaxyModel;
    std::shared_ptr<std::atomic_bool> _galaxyCancellation;
    NSString *_galaxyDiagnostics;
    NSUInteger _galaxyGeneration;
    BOOL _galaxyLoading;
    BOOL _galaxyUsesPlusCatalogs;
    DisplayOutputController *_displayOutput;
    ScriptController *_scripts;
    NSTimer *_scriptCameraTimer;
    NSTimer *_scriptFovTimer;
    std::optional<ScriptCameraAnimation> _scriptFovAnimation;
    NSInteger _scriptFovMode;
    NSTimer *_scriptPlaceTimer;
    std::optional<ScriptPlaceTransition> _scriptPlaceTransition;
    std::optional<ScriptCameraAnimation> _scriptAzimuthAnimation, _scriptAltitudeAnimation;
    std::optional<HorizonOrientationAnimation> _horizonOrientationAnimation;
    std::optional<ScriptLookTarget> _scriptLookTarget;
    std::shared_ptr<const SmallBodySnapshot> _scriptLookSmallBodySnapshot;
    std::shared_ptr<const SpacecraftSnapshot> _scriptLookSpacecraftSnapshot;
    std::optional<double> _scriptCameraDuration;
    int _scriptCameraZoomMode;
    int _scriptTargetSelectionMode;
    std::optional<double> _scriptCameraModeDuration;
    std::optional<std::int32_t> _scriptStarHIP;
    std::string _scriptStarTarget;
    std::optional<std::size_t> _scriptSmallBodyIndex;
    std::string _scriptSmallBodyTarget;
    std::optional<std::size_t> _scriptSpacecraftIndex;
    std::string _scriptSpacecraftTarget;
    std::optional<mitaka::gui::GalaxySpatialRecordId> _scriptGalaxyRecord;
    std::shared_ptr<const mitaka::gui::GalaxySpatialModel> _scriptGalaxyModel;
    std::string _scriptGalaxyTarget;
    std::string _scriptOurGalaxyTarget;
    StarBrightnessController *_starBrightness;
    RadiusDisplayController *_radiusDisplayController;
    RadiusDisplayOptions _radiusDisplayOptions;
    RadiusScaleMode _radiusScaleMode;
    BOOL _terminating;
    BOOL _displayPreferencesLoadFailed;
    NSWindow *_scriptWindow;
    HtmlBrowserController *_htmlBrowser;
    NSTextView *_scriptLog;
    NSWindow *_calendarWindow;
    NSWindow *_plusTimeZoneWindow;
    NSButton *_plusTimeZoneEnabledButton;
    NSTextField *_plusTimeZoneField;
    NSArray<NSTextField *> *_calendarFields;
    NSTextField *_calendarMonthLabel;
    NSArray<NSButton *> *_calendarDayButtons;
    NSButton *_calendarPreviousButton, *_calendarNextButton;
    BOOL _timeInfoVisible;
    NSPopUpButton *_calendarOffsetPopup;
    NSTextField *_customTimeStepField;
    mitaka::gui::TimeSettings _timeSettings;
    NSWindow *_observerWindow;
    NSTextField *_observerLatitudeField, *_observerLongitudeField;
    NSPopUpButton *_observerPlacesPopup;
    NSTextField *_observerCatalogStatus;
    NSButton *_observerApplyButton;
    double _observerLatitude, _observerLongitude;
    std::shared_ptr<const ObserverPlaces> _observerPlaces;
    std::shared_ptr<const EarthLandscapes> _earthLandscapes;
    std::shared_ptr<const ExtendedCatalogs> _extendedCatalogs;
    std::shared_ptr<const ConstellationArtModel> _constellationArt;
    std::unique_ptr<StarNameSelection> _starNameSelection;
    std::shared_ptr<const SkyModel> _model;
    std::shared_ptr<const PlanetTextures> _textures;
    std::shared_ptr<const SkyBackgrounds> _skyBackgrounds;
    std::shared_ptr<const SmallBodyModel> _smallBodyModel;
    std::shared_ptr<const SmallBodySnapshot> _smallBodySnapshot;
    SmallBodyController *_smallBodyBrowser;
    std::shared_ptr<const SmallBodyDisplayModel> _smallBodyDisplay;
    std::shared_ptr<const SmallBodyOrbitSnapshot> _smallBodyOrbits;
    SmallBodyOrbitController *_smallBodyOrbitController;
    mitaka::SmallBodyOrbitSampling _smallBodyOrbitSampling;
    std::shared_ptr<const SatelliteBrowserModel> _satelliteModel;
    std::shared_ptr<const SatelliteSnapshot> _satelliteSnapshot;
    SatelliteController *_satelliteBrowser;
    std::shared_ptr<const SatelliteDisplayModel> _satelliteDisplay;
    std::shared_ptr<const SpacecraftBrowserModel> _spacecraftModel;
    std::shared_ptr<const SpacecraftSnapshot> _spacecraftSnapshot;
    SpacecraftController *_spacecraftBrowser;
    MediaController *_mediaBrowser;
    SkyBodies _bodies;
    SolarBodies _solarBodies;
    NSString *_initialPath, *_activePath;
    double _jd;
    NSUInteger _loadGeneration;
    BOOL _loading, _smokeTest;
    std::optional<SessionState> _pendingDisplayPreferences;
}

- (BOOL)setDate:(double)jd;
- (void)applyDate:(id)sender;
- (BOOL)updateDate:(double)jd refreshOrbits:(BOOL)refreshOrbits;
- (void)showError:(NSString *)message;
- (void)systemWillSleep:(NSNotification *)notification;
- (void)systemDidWake:(NSNotification *)notification;
- (void)changeMode:(id)sender;
- (void)surfaceNavigationChanged;
- (void)cancelHorizonProjection;
- (BOOL)setEarthSurfaceMode:(BOOL)surface duration:(double)duration error:(NSString **)error;
- (BOOL)setEarthSurfaceMode:(BOOL)surface duration:(double)duration force:(BOOL)force error:(NSString **)error;
- (BOOL)setEarthSurfaceMode:(BOOL)surface duration:(double)duration force:(BOOL)force selectedSurface:(BOOL)selectedSurface error:(NSString **)error;
- (void)takeOffFromHorizon:(id)sender;
- (void)descendToHorizon:(id)sender;
- (void)stepHour:(NSButton *)sender;
- (NSOpenPanel *)dataPanel;
- (void)loadData:(NSString *)path;
- (void)refresh;
- (void)refreshBodyButtons;
- (void)updateEnabled;
- (void)configurePlayback;
- (void)refreshOrbits;
- (void)selectBody:(NSButton *)sender;
- (void)focusSelection:(id)sender;
- (BOOL)readRadiusDisplayOptions:(RadiusDisplayOptions *)options mode:(RadiusScaleMode *)mode error:(NSString **)error;
- (BOOL)validateRadiusDisplayOptions:(RadiusDisplayOptions)options mode:(RadiusScaleMode)mode error:(NSString **)error;
- (BOOL)applyRadiusDisplayOptions:(RadiusDisplayOptions)options mode:(RadiusScaleMode)mode error:(NSString **)error;
- (void)restoreRadiusDisplayOptions:(RadiusDisplayOptions)options mode:(RadiusScaleMode)mode;
@end

@interface AppController (Window)
- (void)buildMenu;
- (void)buildWindow;
@end

@interface AppController (WindowCommands)
- (BOOL)fullScreen;
- (BOOL)fullScreenTransitioning;
- (BOOL)setFullScreen:(BOOL)fullScreen error:(NSString **)error;
- (BOOL)toggleFullScreenWithError:(NSString **)error;
- (void)toggleMainFullScreen:(id)sender;
- (void)showAbout:(id)sender;
- (BOOL)validateWindowMenuItem:(NSMenuItem *)item;
@end

@interface AppController (PlusCommands)
- (void)addPlusMenus:(NSMenu *)menu fileMenu:(NSMenu *)fileMenu;
- (void)showBrowser:(id)sender;
- (void)showMediaBrowser:(id)sender;
- (void)openLocalMedia:(id)sender;
- (void)rebuildBrowser;
- (void)chooseBrowserEntry:(CatalogBrowserEntry *)entry center:(BOOL)center;
- (void)selectMilkyWay:(NSMenuItem *)sender;
- (void)toggleDisplay:(NSMenuItem *)sender;
- (void)showRadiusDisplay:(id)sender;
@end

@interface AppController (GalaxyCommands)
- (void)prepareGalaxyForDataRoot:(NSString *)path;
- (void)showGalaxyBrowser:(id)sender;
- (void)showOurGalaxyOverview:(id)sender;
- (void)loadPlusGalaxyCatalogs:(id)sender;
- (void)loadGalaxyIncludingPlus:(BOOL)includePlus;
- (void)cancelGalaxyLoading;
- (void)invalidateGalaxy;
@end

@interface AppController (SmallBodyCommands)
- (void)showSmallBodyBrowser:(id)sender;
- (void)toggleSmallBodies:(id)sender;
- (void)chooseSmallBody:(NSUInteger)index center:(BOOL)center;
- (void)refreshSmallBodies;
- (std::shared_ptr<const SmallBodySnapshot>)smallBodySnapshotAtDate:(double)jd;
- (void)applySmallBodySnapshot:(std::shared_ptr<const SmallBodySnapshot>)snapshot;
- (std::shared_ptr<const SmallBodyDisplayModel>)smallBodyDisplayModel;
- (void)resetSmallBodyDisplayForCurrentModel;
- (void)setSmallBodyDisplayModel:(std::shared_ptr<const SmallBodyDisplayModel>)display;
- (SmallBodyKindDisplayOptions)smallBodyDisplayOptionsForKind:(mitaka::SmallBodyKind)kind;
- (void)setSmallBodyDisplayOptions:(SmallBodyKindDisplayOptions)options forKind:(mitaka::SmallBodyKind)kind;
- (void)setSmallBodyDisplayIds:(const std::vector<mitaka::SmallBodyId>&)ids;
- (void)setSmallBodyOrbitSampling:(mitaka::SmallBodyOrbitSampling)sampling;
- (void)refreshSmallBodyOrbits;
- (void)invalidateSmallBodyOrbits;
@end

@interface AppController (TimeCommands)
- (BOOL)timeInfoVisible;
- (void)setTimeInfoVisible:(BOOL)visible;
- (void)toggleTimeInfo:(id)sender;
- (void)refreshCalendarGrid;
- (void)calendarFieldChanged:(id)sender;
- (void)selectCalendarDay:(NSButton *)sender;
- (void)moveCalendarMonth:(NSButton *)sender;
- (void)addTimeMenu:(NSMenu *)menu;
- (void)showCalendar:(id)sender;
- (void)showPlusTimeZone:(id)sender;
- (void)changePlusTimeZoneEnabled:(id)sender;
- (void)applyPlusTimeZone:(id)sender;
- (BOOL)applyPlusTimeZoneText:(NSString *)text enabled:(BOOL)enabled error:(NSString **)error;
- (void)applyCalendar:(id)sender;
- (void)setCurrentTime:(id)sender;
- (void)stepTime:(NSMenuItem *)sender;
- (void)selectTimeStep:(NSMenuItem *)sender;
- (void)toggleClockTracking:(id)sender;
- (BOOL)validateTimeMenuItem:(NSMenuItem *)item;
- (NSString *)timeDisplayDescription;
- (NSString *)timeDisplayDescriptionForJulianDate:(double)jd;
@end

@interface AppController (DisplayCommands)
- (void)reloadTerrain:(id)sender;
- (void)setMilkyWayMode:(MilkyWayMode)mode;
- (PlanetDisplayOptions)planetDisplayOptions;
- (void)setPlanetDisplayOptions:(const PlanetDisplayOptions&)options;
- (TerrainAmplification)terrainAmplification;
- (void)setTerrainAmplification:(TerrainAmplification)value;
- (EarthLayerOptions)earthLayerOptions;
- (void)setEarthLayerOptions:(const EarthLayerOptions&)options;
- (AtmosphereDisplayOptions)atmosphereDisplayOptions;
- (EclipseDisplayOptions)eclipseDisplayOptions;
- (void)setEclipseDisplayOptions:(const EclipseDisplayOptions&)options;
- (void)toggleEclipseDisplay:(NSMenuItem *)sender;
- (void)setAtmosphereDisplayOptions:(const AtmosphereDisplayOptions&)options;
- (StarDisplayOptions)starDisplayOptions;
- (void)setStarDisplayOptions:(const StarDisplayOptions&)options;
- (GridDisplayOptions)gridDisplayOptions;
- (void)setGridDisplayOptions:(const GridDisplayOptions&)options;
- (RendererDisplayOptions)rendererDisplayOptions;
- (void)setRendererDisplayOptions:(const RendererDisplayOptions&)options;
- (void)addDisplayMenus:(NSMenu *)menu;
- (void)togglePlanetDisplay:(NSMenuItem *)sender;
- (void)selectTerrainAmplification:(NSMenuItem *)sender;
- (void)toggleEarthLayer:(NSMenuItem *)sender;
- (void)toggleLandscapeImage:(NSMenuItem *)sender;
- (void)selectAtmosphereMode:(NSMenuItem *)sender;
- (void)toggleStarDisplay:(NSMenuItem *)sender;
- (void)selectStarMarking:(NSMenuItem *)sender;
- (void)toggleGridDisplay:(NSMenuItem *)sender;
- (void)toggleRendererDisplay:(NSMenuItem *)sender;
- (BOOL)validateDisplayMenuItem:(NSMenuItem *)item;
@end

@interface AppController (StarCommands)
- (void)setStarBrightness:(double)value cancelTransition:(BOOL)cancel;
- (BOOL)animateStarBrightness:(double)value duration:(double)seconds error:(NSString **)error;
- (void)changeStarBrightness:(NSMenuItem *)sender;
@end

@interface AppController (StarNameCommands)
- (const std::set<std::int32_t>&)selectedStarNameHIPs;
- (void)setSelectedStarNameHIPs:(const std::set<std::int32_t>&)hips;
- (void)setStarNameMembership:(const std::vector<std::int32_t>&)hips selected:(BOOL)selected;
- (void)setAllStarNamesSelected:(BOOL)selected;
- (void)rebindStarNameSelection;
- (void)configureStarNameBrowser;
@end

@interface AppController (ObserverCommands)
- (void)showObserver:(id)sender;
- (void)rebuildObserverPlaces;
- (void)chooseObserverPlace:(NSPopUpButton *)sender;
- (void)applyObserver:(id)sender;
@end

@interface AppController (SessionCommands)
- (mitaka::gui::SessionState)sessionState;
- (BOOL)applySessionState:(const mitaka::gui::SessionState&)state;
- (void)saveSession:(id)sender;
- (void)openSession:(id)sender;
- (void)rememberSession:(id)sender;
- (void)restoreSession:(id)sender;
- (mitaka::gui::SessionState)displayPreferences;
- (void)applyDisplayPreferences:(const mitaka::gui::SessionState&)state;
- (void)applyPendingDisplayPreferences;
- (void)savePreferences;
- (void)restorePreferences;
- (void)captureImage:(NSMenuItem *)sender;
- (BOOL)beginImageSaveDialog:(DisplayImageFormat)format error:(NSString **)error;
- (void)showProjection:(id)sender;
- (void)toggleProjectionPointer:(id)sender;
- (void)toggleProjectionFade:(id)sender;
- (BOOL)canWriteOutputURL:(NSURL *)url;
- (NSView *)activeView;
- (DisplayOutputController *)displayOutput;
@end

@interface AppController (Scripting)
- (void)showHtmlBrowser:(id)sender;
- (void)runScript:(id)sender;
- (void)showScriptConsole:(id)sender;
- (void)cancelScript:(id)sender;
- (void)configureScripts;
- (void)stopScriptCameraAnimation;
- (void)startScriptCameraTimer;
- (void)updateScriptCameraAnimations;
- (void)stopScriptFovAnimation;
- (void)updateScriptFovAnimation;
- (void)resetViewAngle:(id)sender;
- (void)stopScriptPlaceTransition;
- (BOOL)applyScriptAction:(const mitaka::gui::ScriptAction&)action error:(NSString **)error;
@end

@interface AppController (ScriptingTime)
- (void)fillScriptTimeSnapshot:(ScriptSnapshot&)state;
- (BOOL)applyScriptTimeAction:(const ScriptAction&)action error:(NSString **)error;
@end

@interface AppController (SatelliteCommands)
- (void)showSatelliteBrowser:(id)sender;
- (void)chooseSatellite:(NSUInteger)index center:(BOOL)center;
- (void)refreshSatelliteParents;
- (std::shared_ptr<const SatelliteSnapshot>)satelliteSnapshotAtDate:(double)jd;
- (void)applySatelliteSnapshot:(std::shared_ptr<const SatelliteSnapshot>)snapshot;
- (void)toggleSatellites:(id)sender;
- (SatelliteDisplayOptions)satelliteDisplayOptions;
- (void)setSatelliteDisplayOptions:(SatelliteDisplayOptions)options;
- (void)setSatelliteDisplaySelectedIds:(const std::vector<mitaka::SatelliteRecordId>&)ids;
@end

@interface AppController (SpacecraftCommands)
- (void)showSpacecraftBrowser:(id)sender;
- (void)chooseSpacecraft:(NSUInteger)index center:(BOOL)center;
- (std::shared_ptr<const SpacecraftSnapshot>)spacecraftSnapshotAtDate:(double)jd;
- (void)applySpacecraftSnapshot:(std::shared_ptr<const SpacecraftSnapshot>)snapshot;
- (void)toggleSpacecraft:(id)sender;
- (void)toggleSpacecraftDisplay:(NSMenuItem *)sender;
@end

@interface AppController (ConstellationCommands)
- (void)configureConstellationBrowser;
- (ConstellationDisplayOptions)constellationDisplayOptions;
- (void)setConstellationDisplayOptions:(const ConstellationDisplayOptions&)options;
- (void)setConstellationMembership:(const std::vector<std::string>&)ids visible:(BOOL)visible;
- (void)setAllConstellationsVisible:(BOOL)visible;
- (void)revealConstellationRow:(NSUInteger)row center:(BOOL)center;
- (ConstellationDisplayRebind)rebindConstellationDisplay;
@end

@interface AppController (SmokeTests)
- (void)runSmokeTest;
- (void)runSceneSmokeTest;
- (void)runPlaybackSmokeTest;
- (void)runTravelSmokeTest;
@end

@interface AppController (GalaxySmokeTests)
- (void)runGalaxySmokeTestWithCompletion:(void (^)(void))completion;
@end

@interface AppController (SolarGalaxySmokeTests)
- (void)runSolarGalaxySmokeTestWithCompletion:(void (^)(void))completion;
@end

@interface AppController (ScriptSmokeTests)
- (void)runScriptSmokeTestWithCompletion:(void (^)(void))completion;
@end

@interface AppController (PlusSmokeTests)
- (BOOL)runPlusSmokeTest;
@end

@interface AppController (SessionSmokeTests)
- (BOOL)runSessionLayerSmokeTest;
@end

@interface AppController (SmallBodySmokeTests)
- (void)runSmallBodySmokeTestWithCompletion:(void (^)(void))completion;
@end

@interface AppController (SatelliteSmokeTests)
- (BOOL)runSatelliteSmokeTest;
@end

@interface AppController (ContinuousFlightSmokeTests)
- (void)runContinuousFlightSmokeTest;
@end
