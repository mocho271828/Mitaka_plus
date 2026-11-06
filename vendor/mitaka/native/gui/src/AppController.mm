#import "AppControllerInternal.h"
#import "SolarDateUpdate.h"
#include "satellite_scene.hpp"
#include "HipSpatialRenderer.h"
#include "radius_display_validation.hpp"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <stdexcept>

using namespace mitaka::gui;

template <typename Action>
static bool finishDatePresentation(const char *name, Action&& action) {
    try { action(); return true; }
    catch (const std::exception& error) {
        std::fprintf(stderr, "date presentation %s failed: %s\n", name, error.what());
        return false;
    }
}

@implementation AppController

- (instancetype)initWithDataRoot:(NSString *)path smokeTest:(BOOL)smokeTest {
    if ((self = [super init])) {
        _initialPath = [path copy];
        _smokeTest = smokeTest;
        _jd = 2451545.0;
        _timeInfoVisible = YES;
        _scriptCameraDuration = 9.0;
        _scriptCameraZoomMode = 2;
        _radiusScaleMode = RadiusScaleMode::keep_orbit;
        _observerLatitude = 35.68;
        _observerLongitude = 139.76;
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    [self buildWindow];
    [self buildMenu];
    [self restorePreferences];
    [self configureScripts];
    [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(systemWillSleep:)
        name:NSWorkspaceWillSleepNotification object:nil];
    [NSWorkspace.sharedWorkspace.notificationCenter addObserver:self selector:@selector(systemDidWake:)
        name:NSWorkspaceDidWakeNotification object:nil];
    [_window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    if (_initialPath) [self loadData:_initialPath];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    (void)sender;
    return YES;
}

- (void)dealloc {
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self];
    [_horizonProjectionTimer invalidate];
    [self invalidateSmallBodyOrbits];
    [self invalidateGalaxy];
    [_solar cancelTerrain];
    [_playback invalidate];
    [_scripts invalidate];
    [_starBrightness invalidate];
    [_displayOutput invalidate];
    [_mediaBrowser invalidate];
}
- (void)applicationWillTerminate:(NSNotification *)notification {
    (void)notification;
    [self savePreferences];
    _terminating = YES;
    [self cancelHorizonProjection];
    [self invalidateSmallBodyOrbits];
    [self invalidateGalaxy];
    [_solar cancelTerrain];
    [_solar interruptFlight];
    [_playback invalidate];
    [_scripts invalidate];
    [_starBrightness invalidate];
    [_displayOutput invalidate];
    [_mediaBrowser invalidate];
}
- (void)windowWillMiniaturize:(NSNotification *)notification {
    (void)notification;
    [_solar interruptFlight];
    [_playback suspendForHiddenWindow];
}
- (void)windowDidDeminiaturize:(NSNotification *)notification {
    (void)notification;
    [_playback resumeAfterHiddenWindow];
}
- (void)windowWillClose:(NSNotification *)notification {
    (void)notification;
    _terminating = YES;
    [self invalidateSmallBodyOrbits];
    [self invalidateGalaxy];
    [_solar cancelTerrain];
    [_solar interruptFlight];
    [_playback invalidate];
    [_scripts invalidate];
    [_starBrightness invalidate];
    [_displayOutput invalidate];
    [_mediaBrowser invalidate];
}

- (BOOL)readRadiusDisplayOptions:(RadiusDisplayOptions *)options mode:(RadiusScaleMode *)mode error:(NSString **)error {
    if (![NSThread isMainThread] || !_model || _loading || _terminating || !options || !mode) {
        if (error) *error = @"天文データの読込完了後に表示半径を操作してください。";
        return NO;
    }
    *options = _radiusDisplayOptions;
    *mode = _radiusScaleMode;
    return YES;
}

- (BOOL)validateRadiusDisplayOptions:(RadiusDisplayOptions)options mode:(RadiusScaleMode)mode error:(NSString **)error {
    try {
        validate_radius_display_state(options, mode);
        return YES;
    } catch (const std::exception& exception) {
        if (error) *error = [NSString stringWithUTF8String:exception.what()];
        return NO;
    }
}

- (void)restoreRadiusDisplayOptions:(RadiusDisplayOptions)options mode:(RadiusScaleMode)mode {
    _solar.radiusDisplayOptions = options;
    _sky.radiusDisplayOptions = options;
    _horizon.radiusDisplayOptions = options;
    _radiusDisplayOptions = options;
    _radiusScaleMode = mode;
}

- (BOOL)applyRadiusDisplayOptions:(RadiusDisplayOptions)options mode:(RadiusScaleMode)mode error:(NSString **)error {
    RadiusDisplayOptions previous;
    RadiusScaleMode previousMode;
    if (![self readRadiusDisplayOptions:&previous mode:&previousMode error:error] ||
        ![self validateRadiusDisplayOptions:options mode:mode error:error]) return NO;
    // 旧版の距離補正と native の追従・地表・航行の対応は未確定。
    if (mode == RadiusScaleMode::keep_radius &&
        (options.space_planet != previous.space_planet || options.space_sun != previous.space_sun)) {
        if (error) *error = @"半径維持モードでの宇宙空間の倍率変更は、カメラ距離の補正が未対応です。軌道維持モードを選んでください。";
        return NO;
    }
    [self restoreRadiusDisplayOptions:options mode:mode];
    return YES;
}
- (void)systemWillSleep:(NSNotification *)notification {
    (void)notification;
    [_solar interruptFlight];
    [_playback suspendForSystemSleep];
    [_scripts cancel];
    [_solar stopScriptOrientation];
    [_solar stopScriptTargetTransition];
    [_starBrightness cancel];
    [self stopScriptCameraAnimation];
    [self stopScriptPlaceTransition];
}
- (void)systemDidWake:(NSNotification *)notification {
    (void)notification;
    [_playback resumeAfterSystemSleep];
}

- (void)updateEnabled {
    const BOOL enabled = _model && !_loading;
    _jdField.enabled = enabled && !_playback.playing && !_playback.clockTracking && !_playback.timeAnimating;
    _magnitudeSlider.enabled = enabled && _mode.selectedSegment != 1;
    _mode.enabled = !_loading;
    for (NSButton *item in _cameraButtons) item.enabled = enabled;
    _cameraButtons[1].enabled = _cameraButtons[5].enabled = enabled && _mode.selectedSegment == 1;
    for (NSButton *item in _travelButtons) item.enabled = enabled && _mode.selectedSegment == 1;
    const BOOL canLand = _solar.selectedBodyIndex > 0 && _solar.selectedBodyIndex < _solarBodies.size();
    _travelButtons[1].enabled = enabled && _mode.selectedSegment == 1 && canLand && !_solar.journeyActive;
    _travelButtons[2].enabled = enabled && _mode.selectedSegment == 1 && _solar.surfaceNavigationActive && !_solar.journeyActive;
    _travelButtons[3].enabled = enabled && _mode.selectedSegment == 1 && !_solar.journeyActive;
    _travelButtons[4].enabled = enabled && (_solar.flightAnimating || _horizonProjectionTimer != nil);
    _travelButtons[5].enabled = enabled && _mode.selectedSegment == 2 && !_solar.journeyActive && !_horizonProjectionTimer;
    _travelButtons[6].enabled = enabled && _mode.selectedSegment == 1 && !_solar.journeyActive && !_solar.flightAnimating;
    _journeyButton.enabled = enabled && _mode.selectedSegment == 1 && canLand && !_solar.journeyActive && !_solar.flightAnimating;
    _resumeJourneyButton.enabled = enabled && _mode.selectedSegment == 1 && _solar.journeyActive && !_solar.flightAnimating;
    _cameraButtons[2].enabled = _cameraButtons[3].enabled = enabled && (_mode.selectedSegment != 1 || !_solar.journeyActive);
    _latitudeField.enabled = _longitudeField.enabled = enabled && _mode.selectedSegment == 1;
    for (NSButton *item in _timeButtons) item.enabled = enabled;
    for (NSButton *item in _bodyButtons) item.enabled = enabled;
}

- (void)configurePlayback {
    [_playback configureWithJulianDate:_jd range:(_model ? _model->time_range() : std::pair<double, double>{0, 1})
        enabled:(_model && !_loading)];
}

- (void)refreshOrbits {
    if (!_model || _loading) return;
    try {
        const auto orbits = _model->solar_orbits(_jd);
        const auto lunarOrbit = _model->lunar_orbit(_jd);
        [_solar setBodies:_solarBodies orbits:orbits];
        [_solar setLunarOrbit:lunarOrbit];
    } catch (const std::exception& error) {
        [self showError:[NSString stringWithFormat:@"軌道線を更新できません: %s", error.what()]];
    }
}

- (NSOpenPanel *)dataPanel {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    // 新しい SDK は選択可否を content type から再計算するため、フォルダ型を明示する。
    panel.treatsFilePackagesAsDirectories = YES;
    panel.allowedContentTypes = @[UTTypeDirectory];
    panel.canChooseFiles = NO;
    panel.canChooseDirectories = YES;
    panel.allowsMultipleSelection = NO;
    panel.message = @"hip.dat と cf96.dat が直下にある data フォルダを選択してください。";
    if (_activePath) panel.directoryURL = [NSURL fileURLWithPath:_activePath isDirectory:YES];
    return panel;
}

- (void)openData:(id)sender {
    (void)sender;
    [_solar interruptFlight];
    [_playback pause];
    NSOpenPanel *panel = [self dataPanel];
    [panel beginSheetModalForWindow:_window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) [self loadData:panel.URL.path];
    }];
}

- (void)showError:(NSString *)message {
    _status.textColor = NSColor.systemOrangeColor;
    _status.stringValue = message;
    _status.toolTip = message;
    if (_smokeTest) {
        std::fprintf(stderr, "%s\n", message.UTF8String);
        std::exit(EXIT_FAILURE);
    }
}

- (void)loadData:(NSString *)path {
    const BOOL reloadPlusGalaxy = _galaxyUsesPlusCatalogs && [_activePath isEqualToString:path];
    [self invalidateSmallBodyOrbits];
    [self cancelGalaxyLoading];
    [_solar cancelTerrain];
    [_scripts cancel];
    [_starBrightness cancel];
    [_solar interruptFlight];
    [_playback interruptWithMessage:@"データ読み込みのため一時停止"];
    _loading = YES;
    [self configurePlayback];
    const NSUInteger generation = ++_loadGeneration;
    [self updateEnabled];
    _status.textColor = NSColor.secondaryLabelColor;
    _status.stringValue = [NSString stringWithFormat:@"読み込み中: %@", path];
    // 古い要求の完了で新しい選択を上書きしない。コアの I/O は UI スレッドから分離する。
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        std::shared_ptr<const SkyModel> loaded;
        std::shared_ptr<const HipSpatialModel> hipModel;
        std::shared_ptr<const PlanetTextures> textures;
        std::shared_ptr<const SkyBackgrounds> backgrounds;
        std::shared_ptr<const SmallBodyModel> smallBodies;
        std::shared_ptr<const SatelliteBrowserModel> satellites;
        std::shared_ptr<const SpacecraftBrowserModel> spacecraft;
        std::shared_ptr<const ExtendedCatalogs> extended;
        std::shared_ptr<const ConstellationArtModel> constellationArt;
        std::shared_ptr<const ObserverPlaces> observerPlaces;
        std::shared_ptr<const EarthLandscapes> earthLandscapes;
        NSString *failure = nil;
        try {
            loaded = std::make_shared<const SkyModel>(SkyModel::load(path.fileSystemRepresentation));
            hipModel = build_hip_spatial_model(loaded->stars());
            textures = std::make_shared<const PlanetTextures>(load_planet_textures(path.fileSystemRepresentation));
            backgrounds = std::make_shared<const SkyBackgrounds>(load_sky_backgrounds(path.fileSystemRepresentation));
            extended = std::make_shared<const ExtendedCatalogs>(load_extended_catalogs(path.fileSystemRepresentation));
            constellationArt = std::make_shared<const ConstellationArtModel>(
                ConstellationArtModel::load(path.fileSystemRepresentation, loaded->constellations()));
            observerPlaces = std::make_shared<const ObserverPlaces>(load_observer_places(path.fileSystemRepresentation));
            earthLandscapes = std::make_shared<const EarthLandscapes>(
                EarthLandscapes::load(path.fileSystemRepresentation, *observerPlaces));
            satellites = load_satellite_browser_model(path.fileSystemRepresentation);
            spacecraft = load_spacecraft_browser_model(path.fileSystemRepresentation);
            smallBodies = std::make_shared<const SmallBodyModel>(
                std::make_shared<const mitaka::SmallBodyDataset>(mitaka::load_small_body_dataset(path.fileSystemRepresentation)));
        } catch (const std::exception& error) {
            failure = [NSString stringWithUTF8String:error.what()];
            if (!failure) failure = @"読み込み失敗（UTF-8 以外のエラーメッセージ）";
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation != self->_loadGeneration) return;
            self->_loading = NO;
            if (failure) {
                [self configurePlayback];
                [self updateEnabled];
                [self refreshSmallBodyOrbits];
                if (!self->_galaxyModel) [self loadGalaxyIncludingPlus:NO];
                [self showError:[NSString stringWithFormat:@"読み込み失敗（%@）: %@%@", path, failure,
                    self->_model ? @"\n直前に読み込めたデータの表示を継続しています。" : @""]];
                return;
            }
            const auto range = loaded->time_range();
            const double initialJD = self->_jd >= range.first && self->_jd <= range.second ? self->_jd : range.first;
            try {
                const auto bodies = loaded->bodies(initialJD);
                const auto satelliteSnapshot = evaluate_satellite_snapshot(satellites, loaded->ephemeris(), initialJD);
                const auto spacecraftSnapshot = evaluate_spacecraft_snapshot(spacecraft, initialJD);
                const auto solarBodies = apply_satellite_parent_positions(loaded->solar_bodies(initialJD), *satelliteSnapshot);
                const auto orbits = loaded->solar_orbits(initialJD);
                const auto lunarOrbit = loaded->lunar_orbit(initialJD);
                const auto smallBodySnapshot = evaluate_small_body_snapshot(smallBodies, initialJD,
                    (self->_mode.selectedSegment == 1 || self->_mode.selectedSegment == 2) && self->_solar.smallBodiesVisible);
                self->_model = loaded;
                self->_textures = textures;
                self->_skyBackgrounds = backgrounds;
                self->_smallBodyModel = smallBodies;
                self->_satelliteModel = satellites;
                self->_spacecraftModel = spacecraft;
                self->_extendedCatalogs = extended;
                self->_constellationArt = constellationArt;
                self->_observerPlaces = observerPlaces;
                self->_earthLandscapes = earthLandscapes;
                [self rebindConstellationDisplay];
                [self rebindStarNameSelection];
                double magnitudeMaximum = 9;
                for (const auto& star : loaded->stars()) magnitudeMaximum = std::max(magnitudeMaximum, static_cast<double>(star.apparent_v_magnitude));
                for (const auto& nebula : extended->ngc) magnitudeMaximum = std::max(magnitudeMaximum, static_cast<double>(nebula.magnitude));
                self->_magnitudeSlider.maxValue = magnitudeMaximum;
                self->_bodies = bodies;
                self->_solarBodies = solarBodies;
                self->_jd = initialJD;
                [self resetSmallBodyDisplayForCurrentModel];
                [self prepareGalaxyForDataRoot:path];
                self->_activePath = [path copy];
                [self loadGalaxyIncludingPlus:reloadPlusGalaxy];
                [self->_mediaBrowser loadDataDirectory:[NSURL fileURLWithPath:path isDirectory:YES]];
                self->_pathLabel.stringValue = path;
                self->_pathLabel.toolTip = path;
                [self->_sky setModel:loaded bodies:bodies];
                [self->_sky setExtendedCatalogs:extended];
                [self->_sky setConstellationArt:constellationArt];
                [self->_sky setSkyBackgrounds:backgrounds];
                [self->_horizon setSkyBackgrounds:backgrounds];
                [self->_solar setSurfaceSkyBackgrounds:backgrounds];
                self->_solar.surfaceMilkyWayMode = self->_horizon.milkyWayMode;
                [self->_horizon setEarthLandscapes:earthLandscapes];
                [self->_horizon setObserverPlaceIdentifier:std::string{}];
                [self->_horizon setModel:loaded bodies:bodies];
                [self->_horizon setExtendedCatalogs:extended];
                [self->_solar setSurfaceStarModel:loaded catalogs:extended];
                [self->_solar setSurfaceConstellationArt:constellationArt];
                self->_solar.surfaceConstellationDisplayOptions = self->_horizon.constellationDisplayOptions;
                [self->_solar setSurfaceSelectedStarNameHIPs:[self selectedStarNameHIPs]];
                [self->_solar setSurfaceStarDisplayOptions:self->_sky.starDisplayOptions];
                [self->_solar setSurfaceMagnitudeLimit:self->_sky.magnitudeLimit];
                [self->_horizon setConstellationArt:constellationArt];
                [self->_horizon setBodies:bodies julianDate:initialJD earthPosition:loaded->solar_bodies(initialJD)[3].position_au
                    smallBodies:smallBodySnapshot smallBodyDisplay:self->_smallBodyDisplay spacecraft:spacecraftSnapshot];
                self->_horizon.smallBodiesVisible = self->_solar.smallBodiesVisible;
                self->_horizon.spacecraftVisible = self->_solar.spacecraftVisible;
                self->_horizon.spacecraftDisplayOptions = self->_solar.spacecraftDisplayOptions;
                [self rebuildBrowser];
                [self rebuildObserverPlaces];
                [self->_solar setHipModel:hipModel];
                [self->_solar setTextures:textures];
                [self->_solar setTerrainDataDirectory:path];
                [self->_solar setBodies:solarBodies orbits:orbits];
                [self->_solar setLunarOrbit:lunarOrbit];
                [self->_smallBodyBrowser setModel:smallBodies snapshot:smallBodySnapshot];
                [self applySmallBodySnapshot:smallBodySnapshot];
                [self->_satelliteBrowser setModel:satellites snapshot:satelliteSnapshot];
                [self applySatelliteSnapshot:satelliteSnapshot];
                [self->_spacecraftBrowser setModel:spacecraft snapshot:spacecraftSnapshot];
                [self applySpacecraftSnapshot:spacecraftSnapshot];
                [self applyPendingDisplayPreferences];
                [self refresh];
                [self configurePlayback];
                [self updateEnabled];
                if (self->_smokeTest) [self runSmokeTest];
            } catch (const std::exception& error) {
                [self configurePlayback];
                [self updateEnabled];
                [self showError:[NSString stringWithFormat:@"惑星計算に失敗: %s", error.what()]];
            }
        });
    });
}

- (void)refresh {
    [_sky setObservationSite:{_observerLatitude, _observerLongitude} julianDate:_jd];
    [_solar setObservationSite:{_observerLatitude, _observerLongitude} julianDate:_jd];
    [self refreshPresentation];
}

- (void)refreshPresentation {
    _jdField.stringValue = [NSString stringWithFormat:@"%.6f", _jd];
    _dateLabel.stringValue = [self timeDisplayDescription];
    [self refreshBodyButtons];
    const auto range = _model->time_range();
    const BOOL hasWarnings = (_textures && !_textures->warnings.empty()) ||
        (_skyBackgrounds && !_skyBackgrounds->warnings.empty()) ||
        (_extendedCatalogs && !_extendedCatalogs->warnings.empty()) ||
        (_constellationArt && !_constellationArt->warnings().empty()) ||
        (_smallBodyModel && !_smallBodyModel->dataset().diagnostics.empty()) ||
        (_observerPlaces && !_observerPlaces->warnings.empty()) ||
        (_earthLandscapes && !_earthLandscapes->warnings().empty()) || !_model->constellation_warning().empty();
    _status.textColor = hasWarnings ? NSColor.systemOrangeColor : NSColor.secondaryLabelColor;
    NSString *display = _mode.selectedSegment == 1 ? @"太陽系 3D · 11 天体 · 距離は太陽中心 AU" :
        [NSString stringWithFormat:@"%@ · 恒星表示 %lu 件", _mode.selectedSegment == 2 ? @"地平図" : @"全天図",
            static_cast<unsigned long>(_mode.selectedSegment == 2 ? _horizon.visibleStarCount : _sky.visibleStarCount)];
    _status.stringValue = [NSString stringWithFormat:@"%@ · HIP %zu 件を保持\n有効範囲 JD %.1f–%.1f · 読み取り専用 · 表面画像 %zu/11%@",
        display, _model->stars().size(), range.first, range.second, _textures ? _textures->loaded_count() : 0,
        hasWarnings ? @" · 読込警告あり（詳細はここにカーソルを重ねて確認）" : @""];
    NSMutableString *details = [_status.stringValue mutableCopy];
    if (_extendedCatalogs) {
        [details appendFormat:@"\nNGC/IC %zu · SDSS銀河 %zu · QSO %zu · 恒星名 %zu · 系外惑星リスト %zu",
            _extendedCatalogs->ngc.size(), _extendedCatalogs->galaxies.size(), _extendedCatalogs->quasars.size(),
            _extendedCatalogs->star_names.size(), _extendedCatalogs->exoplanet_hosts.size()];
        for (const auto& warning : _extendedCatalogs->warnings) [details appendFormat:@"\n%s", warning.c_str()];
    }
    if (_textures) for (const auto& warning : _textures->warnings) [details appendFormat:@"\n%s", warning.c_str()];
    if (_constellationArt) {
        [details appendFormat:@"\n星座絵 %zu 件を保持", _constellationArt->records().size()];
        for (const auto& warning : _constellationArt->warnings()) [details appendFormat:@"\n%s", warning.c_str()];
    }
    if (_skyBackgrounds) {
        [details appendFormat:@"\n天の川画像 %zu/3", _skyBackgrounds->loaded_count()];
        for (const auto& warning : _skyBackgrounds->warnings) [details appendFormat:@"\n%s", warning.c_str()];
    }
    if (_smallBodyModel) {
        [details appendFormat:@"\n小天体 %zu 行を保持 · 描画 %lu 件 · 二体近似 / 原データごとの数値 JD 契約 / 時系変換なし",
            _smallBodyModel->dataset().records.size(), (unsigned long)_solar.visibleSmallBodyCount];
        for (const auto& warning : _smallBodyModel->dataset().diagnostics)
            [details appendFormat:@"\n%s: %s", warning.source_key.c_str(), warning.message.c_str()];
    }
    if (_satelliteModel) {
        [details appendFormat:@"\n衛星 %zu 行を保持 · 位置計算 %zu 件 · 描画 %lu 件 · 出典ごとの独立登録",
            _satelliteModel->model().records().size(), _satelliteSnapshot ? _satelliteSnapshot->positioned_count : 0,
            (unsigned long)_solar.visibleSatelliteCount];
        [details appendString:@"\n衛星の時系・精度保証期間は不明。計算できない行の理由は衛星ブラウザで確認できます。"];
    }
    if (_spacecraftModel) {
        [details appendFormat:@"\n探査機 %zu 定義を保持 · 位置計算 %zu 件 · 描画 %lu 件",
            _spacecraftModel->model().dataset().definitions.size(),
            _spacecraftSnapshot ? _spacecraftSnapshot->positioned_count : 0, (unsigned long)_solar.visibleSpacecraftCount];
        [details appendString:@"\n確認済み PTH 軌跡だけを描画します。位置を評価できない定義も探査機ブラウザに保持しています。"];
    }
    if (_observerPlaces) {
        [details appendFormat:@"\n観測地点 %zu 件（読込元 %zu 行）", _observerPlaces->places.size(), _observerPlaces->source_place_count];
        for (const auto& warning : _observerPlaces->warnings) [details appendFormat:@"\n%s", warning.c_str()];
        for (const auto& missing : _observerPlaces->missing_files) [details appendFormat:@"\n任意の観測地点ファイルなし: %s", missing.c_str()];
    }
    if (_earthLandscapes) {
        [details appendFormat:@"\n風景 %zu 定義を保持（地平図に地球の風景を適用）", _earthLandscapes->definitions().landscapes().size()];
        for (const auto& warning : _earthLandscapes->warnings()) [details appendFormat:@"\n%s", warning.c_str()];
    }
    if (!_model->constellation_warning().empty()) [details appendFormat:@"\n%s", _model->constellation_warning().c_str()];
    _status.toolTip = details;
}

- (BOOL)setDate:(double)jd {
    [_solar interruptFlight];
    [_playback interruptWithMessage:@"日時操作により一時停止"];
    const BOOL success = [self updateDate:jd refreshOrbits:YES];
    [self configurePlayback];
    return success;
}

- (BOOL)updateDate:(double)jd refreshOrbits:(BOOL)refreshOrbits {
    // AppKit の状態と地形 controller の公開・取消はメインスレッドに限定する。
    if (![NSThread isMainThread]) {
        std::fprintf(stderr, "date update must run on the main thread\n");
        return NO;
    }
    if (!_model || _loading) return NO;
    SkyBodies bodies;
    SolarBodies solarBodies;
    std::shared_ptr<const SmallBodySnapshot> smallBodies;
    std::shared_ptr<const SatelliteSnapshot> satellites;
    std::shared_ptr<const SpacecraftSnapshot> spacecraft;
    std::shared_ptr<const SatelliteDisplayModel> satelliteDisplay;
    std::shared_ptr<const SatelliteOrbitGeometry> satelliteOrbits;
    std::optional<PreparedSkyDate> skyDate;
    std::optional<HorizonPreparedDate> horizonDate;
    std::shared_ptr<PreparedSolarDate> solarDate;
    std::optional<SmallBodyBrowserDate> smallBodyBrowserDate;
    std::optional<SatellitePreparedDate> satelliteBrowserDate;
    std::shared_ptr<const SpacecraftSnapshot> spacecraftBrowserDate;
    NSString *dateLabel = nil;
    NSString *dateField = nil;
    try {
        dateLabel = [self timeDisplayDescriptionForJulianDate:jd];
        dateField = [NSString stringWithFormat:@"%.6f", jd];
        bodies = _model->bodies(jd);
        satellites = [self satelliteSnapshotAtDate:jd];
        const NSUInteger selectedSatellite = _solar.selectedSatelliteIndex;
        const auto source = _satelliteModel && selectedSatellite < _satelliteModel->model().records().size()
            ? std::optional<std::string>{_satelliteModel->source(selectedSatellite)} : std::nullopt;
        const auto unadjustedSolarBodies = _model->solar_bodies(jd);
        solarBodies = satellites
            ? apply_satellite_parent_positions(unadjustedSolarBodies, *satellites, source)
            : unadjustedSolarBodies;
        // 再生中は軌道線の標本を保持し、位置と姿勢だけを同一 JD で更新する。
        auto orbits = refreshOrbits ? _model->solar_orbits(jd) : SolarOrbits{};
        auto lunarOrbit = refreshOrbits ? _model->lunar_orbit(jd) : std::vector<mitaka::Vec3>{};
        smallBodies = [self smallBodySnapshotAtDate:jd];
        spacecraft = [self spacecraftSnapshotAtDate:jd];
        satelliteDisplay = _satelliteDisplay;
        if (satellites && satellites->model) {
            auto model = std::shared_ptr<const mitaka::SatelliteModel>(satellites->model, &satellites->model->model());
            if (!satelliteDisplay) satelliteDisplay = std::make_shared<SatelliteDisplayModel>(model);
            else if (satelliteDisplay->model() != model) {
                auto replacement = std::make_shared<SatelliteDisplayModel>(*satelliteDisplay);
                replacement->rebind(model);
                satelliteDisplay = std::move(replacement);
            }
        } else satelliteDisplay.reset();
        auto satelliteDate = prepare_satellite_scene(satellites, satelliteDisplay);
        satelliteDisplay = satelliteDate.display();
        satelliteOrbits = satelliteDate.orbits();
        if (_smallBodyBrowser) smallBodyBrowserDate.emplace(
            [_smallBodyBrowser prepareSnapshot:smallBodies display:_smallBodyDisplay]);
        if (_satelliteBrowser) satelliteBrowserDate.emplace(
            [_satelliteBrowser prepareSnapshot:satellites display:satelliteDisplay orbitGeometry:satelliteOrbits]);
        if (_spacecraftBrowser) spacecraftBrowserDate = [_spacecraftBrowser prepareSnapshot:spacecraft];
        const mitaka::ObserverSite site{_observerLatitude, _observerLongitude};
        skyDate.emplace([_sky prepareBodies:bodies observationSite:site julianDate:jd]);
        horizonDate.emplace([_horizon prepareBodies:bodies julianDate:jd
            earthPosition:unadjustedSolarBodies[3].position_au smallBodies:smallBodies
            smallBodyDisplay:_smallBodyDisplay spacecraft:spacecraft]);
        SolarDateInput input{jd, site, solarBodies, bool(refreshOrbits), std::move(orbits),
            std::move(lunarOrbit), smallBodies, _smallBodyDisplay, std::move(satelliteDate), spacecraft};
        solarDate = [_solar prepareDateUpdate:input];
    } catch (const std::exception& error) {
        [_solar invalidatePendingDateTerrain];
        [self showError:[NSString stringWithFormat:@"時刻を適用できません: %s\n現在の表示時刻は JD %.6f です。", error.what(), _jd]];
        return NO;
    }
    // 全候補が揃うまで公開も通知も行わない。各 commit は確保や callback を含まない。
    _bodies = bodies;
    _solarBodies = solarBodies;
    _jd = jd;
    _smallBodySnapshot = std::move(smallBodies);
    _satelliteSnapshot = std::move(satellites);
    _satelliteDisplay = std::move(satelliteDisplay);
    _spacecraftSnapshot = std::move(spacecraft);
    [_sky commitPreparedDate:std::move(*skyDate)];
    [_horizon commitPreparedDate:std::move(*horizonDate)];
    [_solar commitDateUpdate:std::move(solarDate)];
    if (_smallBodyBrowser) [_smallBodyBrowser commitPreparedDate:std::move(*smallBodyBrowserDate)];
    if (_satelliteBrowser) [_satelliteBrowser commitPreparedDate:std::move(*satelliteBrowserDate)];
    if (_spacecraftBrowser) [_spacecraftBrowser commitPreparedDate:std::move(spacecraftBrowserDate)];
    _dateLabel.stringValue = dateLabel;
    _jdField.stringValue = dateField;
    // 表示補助が失敗しても、すでに全ビューへ公開した日時を失敗と誤報しない。
    bool presentationOK = true;
    presentationOK &= finishDatePresentation("sky", [&] { [_sky finishDateUpdate]; });
    presentationOK &= finishDatePresentation("horizon", [&] { [_horizon finishDateUpdate]; });
    presentationOK &= finishDatePresentation("solar", [&] { [_solar finishDateUpdate]; });
    presentationOK &= finishDatePresentation("small body browser", [&] { [_smallBodyBrowser finishDateUpdate]; });
    presentationOK &= finishDatePresentation("satellite browser", [&] { [_satelliteBrowser finishDateUpdate]; });
    presentationOK &= finishDatePresentation("spacecraft browser", [&] { [_spacecraftBrowser finishDateUpdate]; });
    presentationOK &= finishDatePresentation("small body orbits", [&] { [self refreshSmallBodyOrbits]; });
    presentationOK &= finishDatePresentation("status", [&] { [self refreshPresentation]; });
    if (!presentationOK) [self showError:@"日時は更新されましたが、表示情報の更新に失敗しました。詳細はログを確認してください。"];
    return YES;
}

- (void)applyDate:(id)sender {
    (void)sender;
    NSScanner *scanner = [NSScanner scannerWithString:_jdField.stringValue];
    [_playback interruptWithMessage:@"日時操作により一時停止"];
    scanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    double value = 0;
    if (![scanner scanDouble:&value] || !scanner.isAtEnd || !std::isfinite(value)) {
        _jdField.stringValue = [NSString stringWithFormat:@"%.6f", _jd];
        [self showError:[NSString stringWithFormat:@"JD は有限の数値で入力してください。現在の表示時刻は JD %.6f です。", _jd]];
        return;
    }
    if (![self setDate:value]) _jdField.stringValue = [NSString stringWithFormat:@"%.6f", _jd];
}
- (void)stepDate:(NSButton *)sender { [self setDate:_jd + sender.tag]; }
- (void)stepHour:(NSButton *)sender { [self setDate:_jd + sender.tag / 24.0]; }
- (void)resetDate:(id)sender { (void)sender; [self setDate:2451545.0]; }
- (void)changeMagnitude:(id)sender {
    (void)sender;
    _sky.magnitudeLimit = _horizon.magnitudeLimit = std::round(_magnitudeSlider.doubleValue * 10) / 10;
    [_solar setSurfaceMagnitudeLimit:_sky.magnitudeLimit];
    _magnitudeLabel.stringValue = [NSString stringWithFormat:@"V 等級 ≤ %.1f", _sky.magnitudeLimit];
    if (_model) [self refresh];
}
- (void)refreshBodyButtons {
    for (NSUInteger index = 0; index < _bodyButtons.count; ++index) {
        NSButton *item = _bodyButtons[index];
        item.hidden = _mode.selectedSegment != 1 && index == 3;
        if (!_model) continue;
        const auto& body = _solarBodies[index];
        if (_mode.selectedSegment == 1) {
            const auto p = body.position_au;
            item.title = [NSString stringWithFormat:@"%@  %.3f AU", bodyName(body.id), std::hypot(p.x, p.y, p.z)];
        } else {
            for (const auto& skyBody : _bodies)
                if (skyBody.id == body.id) item.title = [NSString stringWithFormat:@"%@  %.3f AU", bodyName(body.id), skyBody.distance_au];
        }
    }
}
- (void)changeMode:(id)sender {
    if (_scriptPlaceTransition && _scriptPlaceTransition->mode != _mode.selectedSegment)
        [self stopScriptPlaceTransition];
    if (sender) [self cancelHorizonProjection];
    const BOOL solar = _mode.selectedSegment == 1;
    if (_mode.selectedSegment != 2) [self stopScriptCameraAnimation];
    if (!solar) { [_solar stopScriptTargetTransition]; [_solar stopScriptOrientation]; [_solar interruptFlight]; }
    _sky.hidden = _mode.selectedSegment != 0;
    _horizon.hidden = _mode.selectedSegment != 2;
    _solar.hidden = !solar;
    _displayOutput.sourceView = [self activeView];
    _cameraLabel.hidden = !solar;
    _magnitudeLabel.textColor = solar ? NSColor.disabledControlTextColor : NSColor.labelColor;
    _note.stringValue = solar ? @"太陽中心 / J2000 黄道\n再生中は飛行先も公転・自転\n\n天体と着陸地点を選び「選択天体へ飛行」。地表・上空の現在地から連続移動します。\n「着陸」は上空への即時移動と降下です。\n地表ではドラッグで見回し、スクロールで高度変更。\nガス惑星は基準面。地形・大気・重力航法は未対応。" :
        @"地球中心からの概略位置\nJ2000 赤道座標 / 距離 AU\n\n固有運動・光行差・光行時間・歳差章動の補正は含みません。円の大きさは模式表示です。";
    if (_mode.selectedSegment == 2) _note.stringValue = @"観測地点から見た方位・高度\n北0° / 東90°、地平線は高度0°\n\n地球の姿勢と指定した緯度・東経から計算します。大気差・日周視差は補正していません。\nドラッグで見回し、スクロールで拡大します。";
    NSString *description = solar ? _solarSelection : _mode.selectedSegment == 0 ? _skySelection : _horizonSelection;
    _selectionLabel.stringValue = description ? description : @"天体をクリックして選択できます。";
    _cameraLabel.stringValue = [_solar cameraStateDescription];
    [self refreshSmallBodies];
    [self updateEnabled];
    [self refreshBodyButtons];
    if (_model) [self refresh];
}
- (void)selectBody:(NSButton *)sender {
    if (!_model || sender.tag < 0 || (NSUInteger)sender.tag >= _solarBodies.size()) return;
    if (_mode.selectedSegment == 1) { [_solar selectBody:sender.tag]; return; }
    const Body id = _solarBodies[sender.tag].id;
    for (NSUInteger index = 0; index < _bodies.size(); ++index)
        if (_bodies[index].id == id) {
            if (_mode.selectedSegment == 2) [_horizon selectBody:index];
            else [_sky selectBody:index];
            break;
        }
}
- (void)resetCamera:(id)sender {
    (void)sender;
    if (_mode.selectedSegment == 1) [_solar resetCamera];
    else if (_mode.selectedSegment == 2) [_horizon resetView];
    else [_sky resetView];
}
- (void)innerPlanets:(id)sender { (void)sender; [_solar showInnerPlanets]; }
- (void)zoomIn:(id)sender {
    (void)sender;
    if (_mode.selectedSegment == 1) [_solar zoomIn];
    else if (_mode.selectedSegment == 2) [_horizon zoomIn];
    else [_sky zoomIn];
}
- (void)zoomOut:(id)sender {
    (void)sender;
    if (_mode.selectedSegment == 1) [_solar zoomOut];
    else if (_mode.selectedSegment == 2) [_horizon zoomOut];
    else [_sky zoomOut];
}
- (void)focusSelection:(id)sender {
    (void)sender;
    if (_mode.selectedSegment == 1) [_solar focusSelection];
    else if (_mode.selectedSegment == 2) [_horizon focusSelection];
    else [_sky focusSelection];
}
- (void)showSurface:(id)sender { (void)sender; [_solar showSurface]; }
- (void)earthMoon:(id)sender { (void)sender; [_solar showEarthMoon]; }
- (BOOL)readLandingLatitude:(double *)latitude longitude:(double *)longitude {
    NSScanner *lat = [NSScanner scannerWithString:_latitudeField.stringValue];
    NSScanner *lon = [NSScanner scannerWithString:_longitudeField.stringValue];
    lat.locale = lon.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    if (![lat scanDouble:latitude] || !lat.isAtEnd || ![lon scanDouble:longitude] || !lon.isAtEnd
        || !std::isfinite(*latitude) || !std::isfinite(*longitude)
        || std::abs(*latitude) > 90 || std::abs(*longitude) > 180) {
        [self showError:@"着陸地点は緯度 −90〜90°、東経 −180〜180°の数値で指定してください。"];
        return NO;
    }
    [self refresh];
    return YES;
}
- (void)land:(id)sender {
    (void)sender;
    double latitude = 0, longitude = 0;
    if ([self readLandingLatitude:&latitude longitude:&longitude])
        [_solar landAtLatitude:latitude longitude:longitude];
}
- (void)takeOff:(id)sender { (void)sender; [_solar takeOff]; }
- (void)takeOffFromEarth:(id)sender {
    (void)sender;
    double latitude = 0, longitude = 0;
    if ([self readLandingLatitude:&latitude longitude:&longitude])
        [_solar takeOffFromEarthAtLatitude:latitude longitude:longitude];
}
- (void)cancelHorizonProjection {
    [_horizonProjectionTimer invalidate];
    _horizonProjectionTimer = nil;
    if (_horizon) {
        auto viewport = [_horizon viewport];
        if (viewport.perspective_blend != 0) {
            viewport.perspective_blend = 0;
            [_horizon setViewport:viewport];
        }
    }
    [self updateEnabled];
}
- (void)advanceHorizonProjection {
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    const double progress = _horizonProjectionDuration <= 0 ? 1
        : std::clamp((now - _horizonProjectionStartTime) / _horizonProjectionDuration, 0.0, 1.0);
    const double smooth = progress * progress * (3 - 2 * progress);
    auto viewport = [_horizon viewport];
    viewport.perspective_blend = _horizonProjectionStart + (_horizonProjectionTarget - _horizonProjectionStart) * smooth;
    [_horizon setViewport:viewport];
    if (progress < 1) return;
    [_horizonProjectionTimer invalidate];
    _horizonProjectionTimer = nil;
    if (_horizonProjectionTarget == 1) {
        SurfaceSite site;
        site.latitude_deg = _observerLatitude;
        site.longitude_deg = _observerLongitude;
        site.heading_deg = viewport.center_azimuth_deg;
        site.elevation_deg = viewport.center_altitude_deg;
        site.roll_deg = viewport.roll_deg;
        NSString *error = nil;
        if (![_solar takeOffFromHorizon:site duration:_horizonAscentDuration error:&error]) {
            [self cancelHorizonProjection];
            [self showError:error ? error : @"地平図から離陸できません。"]; return;
        }
        _mode.selectedSegment = 1;
        [self changeMode:nil];
    }
    [self updateEnabled];
}
- (void)startHorizonProjectionTo:(double)target duration:(double)duration {
    [_horizonProjectionTimer invalidate];
    _horizonProjectionTimer = nil;
    _horizonProjectionStart = [_horizon viewport].perspective_blend;
    _horizonProjectionTarget = target;
    _horizonProjectionDuration = duration;
    _horizonProjectionStartTime = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    if (duration <= 0 || _horizonProjectionStart == target) {
        [self advanceHorizonProjection];
        return;
    }
    __weak AppController *weakSelf = self;
    _horizonProjectionTimer = [NSTimer timerWithTimeInterval:1.0 / 30 repeats:YES block:^(NSTimer *timer) {
        (void)timer;
        [weakSelf advanceHorizonProjection];
    }];
    [[NSRunLoop mainRunLoop] addTimer:_horizonProjectionTimer forMode:NSRunLoopCommonModes];
    [self updateEnabled];
}
- (BOOL)setEarthSurfaceMode:(BOOL)surface duration:(double)duration error:(NSString **)error {
    return [self setEarthSurfaceMode:surface duration:duration force:NO selectedSurface:NO error:error];
}
- (BOOL)setEarthSurfaceMode:(BOOL)surface duration:(double)duration force:(BOOL)force error:(NSString **)error {
    return [self setEarthSurfaceMode:surface duration:duration force:force selectedSurface:YES error:error];
}
- (BOOL)setEarthSurfaceMode:(BOOL)surface duration:(double)duration force:(BOOL)force selectedSurface:(BOOL)selectedSurface error:(NSString **)error {
    if (!std::isfinite(duration) || duration < 0) {
        if (error) *error = @"移動時間は 0 以上の有限数で指定してください。";
        return NO;
    }
    if (force && _mode.selectedSegment == 1) {
        NSUInteger body = NSNotFound;
        const BOOL pending = _pendingEarthDescent;
        _pendingEarthDescent = NO;
        if (![_solar forceSurfaceMode:surface bodyIndex:&body error:error]) {
            _pendingEarthDescent = pending;
            return NO;
        }
        _pendingEarthDescent = surface && body == 3;
        if (_pendingEarthDescent) {
            _earthDescentProjectionDuration = 0;
            [self surfaceNavigationChanged];
        }
        return YES;
    }
    if (surface) {
        if (_mode.selectedSegment == 1 && _solar.scriptPlanetariumMode) return YES;
        if (_mode.selectedSegment == 2) {
            if (_horizonProjectionTimer) [self startHorizonProjectionTo:0 duration:duration];
            return YES;
        }
        if (_mode.selectedSegment != 1) {
            if (error) *error = @"地球付近の太陽系表示が必要です。";
            return NO;
        }
        const NSUInteger selectedBody = _solar.selectedBodyIndex;
        if (selectedSurface && selectedBody != NSNotFound && selectedBody != 0 && selectedBody != 3) {
            if (![_solar descendToSelectedSurfaceWithDuration:duration error:error]) return NO;
            _pendingEarthDescent = NO;
            [self surfaceNavigationChanged];
            return YES;
        }
        _earthDescentProjectionDuration = duration * 0.4;
        if (![_solar descendToHorizonWithDuration:duration * 0.6 error:error]) return NO;
        _pendingEarthDescent = YES;
        [self surfaceNavigationChanged];
        return YES;
    }
    if (_mode.selectedSegment == 1) {
        if (!_pendingEarthDescent) {
            if (_solar.scriptPlanetariumMode)
                return [_solar ascendFromSurfaceWithDuration:duration error:error];
            return YES;
        }
        if (![_solar ascendFromEarthWithDuration:duration error:error]) return NO;
        _pendingEarthDescent = NO;
        return YES;
    }
    if (_mode.selectedSegment != 2) {
        if (error) *error = @"地平図からのみ離陸できます。";
        return NO;
    }
    if (!_model || _solar.journeyActive) {
        if (error) *error = @"地平図から離陸できません。";
        return NO;
    }
    if (duration == 0) {
        const auto viewport = [_horizon viewport];
        SurfaceSite site;
        site.latitude_deg = _observerLatitude;
        site.longitude_deg = _observerLongitude;
        site.heading_deg = viewport.center_azimuth_deg;
        site.elevation_deg = viewport.center_altitude_deg;
        site.roll_deg = viewport.roll_deg;
        if (force) {
            if (![_solar forceSpaceFromHorizon:site error:error]) return NO;
        } else if (![_solar takeOffFromHorizon:site duration:0 error:error]) return NO;
        [self cancelHorizonProjection];
        _mode.selectedSegment = 1;
        [self changeMode:nil];
        return YES;
    }
    _horizonAscentDuration = duration * 0.6;
    [self startHorizonProjectionTo:1 duration:duration * 0.4];
    return YES;
}
- (void)takeOffFromHorizon:(id)sender {
    (void)sender;
    NSString *error = nil;
    if (![self setEarthSurfaceMode:NO duration:3 error:&error]) {
        [self showError:error ? error : @"地平図から離陸できません。"]; return;
    }
}
- (void)descendToHorizon:(id)sender {
    (void)sender;
    NSString *error = nil;
    if (![self setEarthSurfaceMode:YES duration:3 error:&error]) {
        [self showError:error ? error : @"地平図へ降下できません。"]; return;
    }
}
- (void)surfaceNavigationChanged {
    if (_pendingEarthDescent && !_solar.flightAnimating) {
        _pendingEarthDescent = NO;
        SurfaceSite site;
        if (_mode.selectedSegment == 1 && [_solar earthSurfaceSite:&site]
            && site.height_km <= minimum_surface_height_km + 1e-9) {
            const std::string identifier = [_horizon observerPlaceIdentifier];
            const BOOL samePlace = _observerPlaces && std::any_of(_observerPlaces->places.begin(), _observerPlaces->places.end(),
                [&](const auto& place) { return place.target_name == identifier && observer_place_matches(place, site.latitude_deg, site.longitude_deg); });
            _observerLatitude = site.latitude_deg;
            _observerLongitude = site.longitude_deg;
            [_horizon setObserverSite:{site.latitude_deg, site.longitude_deg}];
            if (!samePlace) [_horizon setObserverPlaceIdentifier:std::string{}];
            [_sky setObservationSite:{site.latitude_deg, site.longitude_deg} julianDate:_jd];
            [self stopScriptCameraAnimation];
            [_horizon setViewport:{site.heading_deg, site.elevation_deg, [_horizon viewport].zoom, 1, site.roll_deg}];
            _mode.selectedSegment = 2;
            [self changeMode:nil];
            [self startHorizonProjectionTo:0 duration:_earthDescentProjectionDuration];
        }
    }
    [self updateEnabled];
}
- (void)stopFlight:(id)sender { (void)sender; [self cancelHorizonProjection]; [_solar interruptFlight]; }
- (void)startJourney:(id)sender {
    (void)sender;
    double latitude = 0, longitude = 0;
    if ([self readLandingLatitude:&latitude longitude:&longitude])
        [_solar startJourneyAtLatitude:latitude longitude:longitude];
}
- (void)resumeJourney:(id)sender { (void)sender; [_solar resumeJourney]; }

@end
