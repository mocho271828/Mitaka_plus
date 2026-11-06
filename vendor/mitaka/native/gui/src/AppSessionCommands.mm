#import "AppControllerInternal.h"
#import "gui_file_io.h"
#include "small_body_orbit_model.hpp"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <stdexcept>
#include <algorithm>

namespace {
struct PreparedDisplayLayers {
    std::shared_ptr<const SmallBodyDisplayModel> small_bodies;
    std::shared_ptr<const SatelliteDisplayModel> satellites;
};

void validate_radius_for_restore(AppController *controller, const SessionState& state) {
    NSString *failure = nil;
    if (![controller validateRadiusDisplayOptions:state.radius_display mode:state.radius_scale_mode error:&failure]) {
        const char *message = failure.UTF8String;
        throw std::invalid_argument(message ? message : "session state: invalid radius display settings");
    }
}

PreparedDisplayLayers prepare_display_layers(const SessionState& state, const SkyModel& sky,
    const SmallBodyModel& small_model, const SmallBodyDisplayModel& small_display,
    const SatelliteDisplayModel& satellite_display, const StarNameSelection& star_names) {
    auto small = prepare_small_body_session(state.small_bodies, small_display);
    auto satellites = prepare_satellite_session(state.satellites, satellite_display);
    ConstellationDisplayModel constellations(sky.constellations());
    constellations.set_options(state.constellations);
    auto names = star_names;
    names.set_selection(state.selected_star_name_hips);
    (void)small_body_orbit_requested_rows(small_model, *small, state.small_bodies.orbit_sampling);
    return {std::move(small), std::move(satellites)};
}
} // namespace

@implementation AppController (SessionCommands)
- (SessionState)sessionState {
    SessionState state = [self displayPreferences];
    state.julian_date = _jd;
    state.simulation_rate = _playback.simulationRate;
    state.plus_time = [_playback plusTimeState];
    state.plus_time_zone = [_playback plusTimeZone];
    state.observer_place_identifier = [_horizon observerPlaceIdentifier];
    state.mode = (int)_mode.selectedSegment;
    state.magnitude_limit = _sky.magnitudeLimit;
    state.sky_viewport = [_sky viewport];
    state.horizon_viewport = [_horizon viewport];
    state.solar_camera = [_solar cameraState];
    SurfaceSite surface;
    if ([_solar scriptSurfaceSite:&surface]) state.surface_site = surface;
    const NSUInteger selected = _solar.selectedBodyIndex;
    state.selected_body = selected < _solarBodies.size() ? _solarBodies[selected].id : Body::sun;
    if (_sky.selectedBodyIndex < _bodies.size()) state.sky_selected_body = _bodies[_sky.selectedBodyIndex].id;
    if (_horizon.selectedBodyIndex < _bodies.size()) state.horizon_selected_body = _bodies[_horizon.selectedBodyIndex].id;
    state.observer_latitude_deg = _observerLatitude;
    state.observer_longitude_deg = _observerLongitude;
    return state;
}
- (BOOL)applySessionState:(const SessionState&)value {
    if (!_model || _loading) { [self showError:@"先に天文データを開いてください。" ]; return NO; }
    try {
        // 全項目と日時範囲を先に検査し、不正ファイルで部分的な状態変更を起こさない。
        const auto state = decode_session_state(encode_session_state(value));
        (void)_model->bodies(state.julian_date);
        if (state.surface_site) {
            SurfaceNavigation surface;
            surface.set_site(*state.surface_site);
            (void)surface.camera(_model->solar_bodies(state.julian_date));
        }
        if (!_smallBodyModel || !_smallBodyDisplay || !_satelliteDisplay || !_starNameSelection)
            throw std::invalid_argument("session state: display catalogs are unavailable");
        (void)prepare_display_layers(state, *_model, *_smallBodyModel, *_smallBodyDisplay, *_satelliteDisplay, *_starNameSelection);
        validate_radius_for_restore(self, state);
        if (!state.observer_place_identifier.empty()) {
            if (!_observerPlaces || std::none_of(_observerPlaces->places.begin(), _observerPlaces->places.end(),
                [&](const auto& place) {
                    return place.target_name == state.observer_place_identifier &&
                        observer_place_matches(place, state.observer_latitude_deg, state.observer_longitude_deg);
                })) throw std::invalid_argument("session state: observer place identity or coordinates do not match local data");
        }
        [_scripts cancel];
        [_starBrightness cancel];
        [self stopScriptCameraAnimation];
        [self stopScriptFovAnimation];
        [self stopScriptPlaceTransition];
        if (![self setDate:state.julian_date]) return NO;
        [_playback setSimulationRate:state.simulation_rate];
        auto restored_time = state.plus_time;
        restored_time.speed = 0;
        NSString *time_error = nil;
        if (![_playback setPlusTimeState:restored_time error:&time_error]) {
            const char *message = time_error.UTF8String;
            throw std::logic_error(message != nullptr ? message : "validated Plus time could not be restored");
        }
        [_playback setPlusTimeZone:state.plus_time_zone];
        [_solar setCameraState:state.solar_camera];
        if (state.surface_site) {
            NSString *failure = nil;
            if (![_solar restoreSurfaceSite:*state.surface_site error:&failure]) {
                const char *message = failure.UTF8String;
                throw std::logic_error(message ? message : "validated surface site could not be restored");
            }
        }
        for (NSUInteger i = 0; i < _solarBodies.size(); ++i)
            if (_solarBodies[i].id == state.selected_body) [_solar selectBody:i];
        [_sky setViewport:state.sky_viewport];
        [_horizon setViewport:state.horizon_viewport];
        _sky.magnitudeLimit = _horizon.magnitudeLimit = state.magnitude_limit;
        [_solar setSurfaceMagnitudeLimit:state.magnitude_limit];
        _magnitudeSlider.minValue = std::min(_magnitudeSlider.minValue, state.magnitude_limit);
        _magnitudeSlider.maxValue = std::max(_magnitudeSlider.maxValue, state.magnitude_limit);
        _magnitudeSlider.doubleValue = state.magnitude_limit;
        _magnitudeLabel.stringValue = [NSString stringWithFormat:@"V 等級 ≤ %.1f", state.magnitude_limit];
        [self applyDisplayPreferences:state];
        _observerLatitude = state.observer_latitude_deg;
        _observerLongitude = state.observer_longitude_deg;
        [_horizon setObserverSite:{_observerLatitude, _observerLongitude}];
        [_horizon setObserverPlaceIdentifier:state.observer_place_identifier];
        [_sky setObservationSite:{_observerLatitude, _observerLongitude} julianDate:_jd];
        _mode.selectedSegment = state.mode;
        [self changeMode:nil];
        [_sky clearSelection];
        [_horizon clearSelection];
        for (NSUInteger i = 0; i < _bodies.size(); ++i) {
            if (state.sky_selected_body == _bodies[i].id) [_sky selectBody:i];
            if (state.horizon_selected_body == _bodies[i].id) [_horizon selectBody:i];
        }
        _pendingDisplayPreferences.reset();
        return YES;
    } catch (const std::exception& error) {
        [self showError:[NSString stringWithFormat:@"表示状態を復元できません: %s", error.what()]];
        return NO;
    }
}
- (BOOL)canWriteOutputURL:(NSURL *)url {
    NSMutableArray<NSURL *> *roots = [NSMutableArray array];
    for (NSString *path in @[_activePath ? _activePath : @"", _initialPath ? _initialPath : @""])
        if (path.length) [roots addObject:[NSURL fileURLWithPath:path.stringByDeletingLastPathComponent]];
    if (!canWriteUserOutput(url, roots)) {
        [self showError:@"元アプリとデータの保全のため、このフォルダには保存できません。書類など別のフォルダを選択してください。"];
        return NO;
    }
    return YES;
}
- (void)saveSession:(id)sender {
    (void)sender;
    if (!_model || _loading) return;
    [_playback pause];
    [_solar interruptFlight];
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedContentTypes = @[UTTypeJSON];
    panel.nameFieldStringValue = @"Mitaka-view.json";
    panel.message = @"日時・視点・太陽/惑星/月の選択・観測地点・表示設定を保存します。恒星名の選択と明るさ、地球の雲・夜景、大気、食と影、風景、旧Plusの時間送り、小天体と衛星の表示集合、星座絵と星座ごとの表示、探査機の設定も含みます。クリックで選んだ恒星・小天体・衛星・探査機・深宇宙天体、飛行やスクリプトの実行状態は保存しません。";
    [panel beginSheetModalForWindow:_window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK || ![self canWriteOutputURL:panel.URL]) return;
        try {
            const auto json = encode_session_state([self sessionState]);
            NSData *data = [NSData dataWithBytes:json.data() length:json.size()];
            NSError *error = nil;
            if (![data writeToURL:panel.URL options:NSDataWritingAtomic error:&error]) [self showError:error.localizedDescription];
        } catch (const std::exception& error) { [self showError:[NSString stringWithFormat:@"保存できません: %s", error.what()]]; }
    }];
}
- (void)openSession:(id)sender {
    (void)sender;
    if (!_model || _loading) return;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[UTTypeJSON];
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    [panel beginSheetModalForWindow:_window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        NSError *error = nil;
        NSData *data = boundedSessionData(panel.URL, &error);
        if (!data) { [self showError:error.localizedDescription]; return; }
        try { [self applySessionState:decode_session_state({static_cast<const char *>(data.bytes), data.length})]; }
        catch (const std::exception& failure) { [self showError:[NSString stringWithFormat:@"状態ファイルが不正です: %s", failure.what()]]; }
    }];
}
- (void)rememberSession:(id)sender {
    (void)sender;
    if (!_model || _loading) return;
    try {
        const auto json = encode_session_state([self sessionState]);
        [NSUserDefaults.standardUserDefaults setObject:[NSData dataWithBytes:json.data() length:json.size()] forKey:@"MitakaRememberedViewV9"];
        _status.stringValue = @"現在の表示状態を記憶しました。「表示状態を呼び出す」で復元できます。";
    } catch (const std::exception& failure) { [self showError:[NSString stringWithUTF8String:failure.what()]]; }
}
- (void)restoreSession:(id)sender {
    (void)sender;
    NSData *data = [NSUserDefaults.standardUserDefaults dataForKey:@"MitakaRememberedViewV9"];
    if (!data) { [self showError:@"記憶した表示状態はありません。"]; return; }
    try { [self applySessionState:decode_session_state({static_cast<const char *>(data.bytes), data.length})]; }
    catch (const std::exception& failure) { [self showError:[NSString stringWithUTF8String:failure.what()]]; }
}
- (SessionState)displayPreferences {
    SessionState state;
    state.constellations = [self constellationDisplayOptions];
    state.planets = [self planetDisplayOptions];
    // 終了処理中も保存するため UI 操作向けの受付条件を通さず live 状態を読む。
    state.radius_display = _radiusDisplayOptions;
    state.radius_scale_mode = _radiusScaleMode;
    state.terrain_amplification = [self terrainAmplification];
    state.stars = [self starDisplayOptions];
    state.selected_star_name_hips = [self selectedStarNameHIPs];
    state.earth_layers = [self earthLayerOptions];
    state.atmosphere = [self atmosphereDisplayOptions];
    state.eclipse = [self eclipseDisplayOptions];
    state.show_landscape_image = _horizon.showsLandscapeImage;
    state.grids = [self gridDisplayOptions];
    state.renderer = [self rendererDisplayOptions];
    state.show_time_info = [self timeInfoVisible];
    state.show_nebulae = _sky.showsNebulae;
    state.show_galaxies = _sky.showsGalaxies;
    state.show_quasars = _sky.showsQuasars;
    state.milky_way_mode = _sky.milkyWayMode;
    state.time_settings = _timeSettings;
    if (_smallBodyDisplay)
        state.small_bodies = capture_small_body_session(*_smallBodyDisplay, _solar.smallBodiesVisible, _smallBodyOrbitSampling);
    if (_satelliteDisplay) state.satellites = capture_satellite_session(*_satelliteDisplay);
    const auto spacecraft = _solar.spacecraftDisplayOptions;
    state.spacecraft = {_solar.spacecraftVisible != NO, spacecraft.points, spacecraft.labels, spacecraft.orbits};
    return state;
}
- (void)applyDisplayPreferences:(const SessionState&)value {
    const auto state = decode_session_state(encode_session_state(value));
    if (!_model || !_smallBodyModel || !_smallBodyDisplay || !_satelliteDisplay || !_starNameSelection)
        throw std::invalid_argument("session state: display catalogs are unavailable");
    const auto prepared = prepare_display_layers(state, *_model, *_smallBodyModel, *_smallBodyDisplay, *_satelliteDisplay, *_starNameSelection);
    validate_radius_for_restore(self, state);
    // 新しい表示集合と標本区間を一組で検証済み。旧設定との中間組合せは適用しない。
    [self invalidateSmallBodyOrbits];
    [_starBrightness cancel];
    _smallBodyOrbitSampling = state.small_bodies.orbit_sampling;
    _smallBodyDisplay = prepared.small_bodies;
    [_solar setSmallBodyDisplayModel:_smallBodyDisplay];
    [_horizon setSmallBodyDisplayModel:_smallBodyDisplay];
    [_smallBodyBrowser setDisplayModel:_smallBodyDisplay];
    [_smallBodyBrowser setOrbitSampling:_smallBodyOrbitSampling];
    _satelliteDisplay = prepared.satellites;
    [_solar setSatelliteDisplayModel:_satelliteDisplay];
    [_satelliteBrowser setDisplayModel:_satelliteDisplay];
    [self setConstellationDisplayOptions:state.constellations];
    [self setPlanetDisplayOptions:state.planets];
    [self restoreRadiusDisplayOptions:state.radius_display mode:state.radius_scale_mode];
    [self setTerrainAmplification:state.terrain_amplification];
    [self setStarDisplayOptions:state.stars];
    [self setSelectedStarNameHIPs:state.selected_star_name_hips];
    [self setEarthLayerOptions:state.earth_layers];
    [self setAtmosphereDisplayOptions:state.atmosphere];
    [self setEclipseDisplayOptions:state.eclipse];
    _horizon.showsLandscapeImage = state.show_landscape_image;
    [self setGridDisplayOptions:state.grids];
    [self setRendererDisplayOptions:state.renderer];
    [self setTimeInfoVisible:state.show_time_info];
    _sky.showsNebulae = state.show_nebulae;
    _sky.showsGalaxies = state.show_galaxies;
    _sky.showsQuasars = state.show_quasars;
    [self setMilkyWayMode:state.milky_way_mode];
    _timeSettings = state.time_settings;
    _solar.smallBodiesVisible = state.small_bodies.visible;
    _solar.spacecraftVisible = state.spacecraft.visible;
    _solar.spacecraftDisplayOptions = {state.spacecraft.points, state.spacecraft.labels, state.spacecraft.orbits};
    _horizon.smallBodiesVisible = _solar.smallBodiesVisible;
    _horizon.spacecraftVisible = _solar.spacecraftVisible;
    _horizon.spacecraftDisplayOptions = _solar.spacecraftDisplayOptions;
    [self refreshSmallBodies];
    [self updateEnabled];
}
- (void)savePreferences {
    if (_smokeTest || !_model || _pendingDisplayPreferences || _displayPreferencesLoadFailed) return;
    try {
        const auto json = encode_session_state([self displayPreferences]);
        [NSUserDefaults.standardUserDefaults setObject:[NSData dataWithBytes:json.data() length:json.size()]
            forKey:@"MitakaDisplayPreferencesV9"];
    } catch (const std::exception& error) {
        [self showError:[NSString stringWithFormat:@"表示設定を保存できません: %s", error.what()]];
    }
}
- (void)restorePreferences {
    if (_smokeTest) return;
    NSData *data = [NSUserDefaults.standardUserDefaults dataForKey:@"MitakaDisplayPreferencesV9"];
    if (!data) return;
    try {
        // 状態ファイルと共通の境界検証を使い、設定だけを適用する。
        const auto state = decode_session_state({static_cast<const char *>(data.bytes), data.length});
        _pendingDisplayPreferences = state;
        [self applyPendingDisplayPreferences];
    } catch (const std::exception& error) {
        // 読み取れない元の設定を終了時に既定値で上書きしない。
        _displayPreferencesLoadFailed = YES;
        [self showError:[NSString stringWithFormat:@"保存された表示設定が不正です: %s", error.what()]];
    }
}
- (void)applyPendingDisplayPreferences {
    if (!_pendingDisplayPreferences || !_model || _loading) return;
    try {
        [self applyDisplayPreferences:*_pendingDisplayPreferences];
        _pendingDisplayPreferences.reset();
    } catch (const std::exception& error) {
        // 元設定は保持する。別データに切り替えても部分的な集合復元や上書きをしない。
        [self showError:[NSString stringWithFormat:@"保存された表示設定を適用できません: %s", error.what()]];
    }
}
- (NSView *)activeView { return _mode.selectedSegment == 1 ? _solar : _mode.selectedSegment == 2 ? _horizon : _sky; }
- (DisplayOutputController *)displayOutput {
    if (!_displayOutput) _displayOutput = [[DisplayOutputController alloc] init];
    _displayOutput.sourceView = [self activeView];
    return _displayOutput;
}
- (void)captureImage:(NSMenuItem *)sender {
    NSString *error = nil;
    if (![self beginImageSaveDialog:static_cast<DisplayImageFormat>(sender.tag) error:&error])
        [self showError:error];
}
- (BOOL)beginImageSaveDialog:(DisplayImageFormat)format error:(NSString **)error {
    if (error) *error = nil;
    if (!_model || _loading || _window.attachedSheet) {
        if (error) *error = @"データ読み込み中、または別のダイアログを表示中のため画像を保存できません。";
        return NO;
    }
    NSArray<UTType *> *types = @[UTTypePNG, UTTypeJPEG, UTTypeBMP];
    const NSInteger index = static_cast<NSInteger>(format);
    if (index < 0 || index >= (NSInteger)types.count) {
        if (error) *error = @"画像の保存形式が不正です。";
        return NO;
    }
    NSError *captureError = nil;
    NSData *image = [[self displayOutput] captureFormat:format error:&captureError];
    if (!image) {
        if (error) *error = captureError ? captureError.localizedDescription : @"表示画像を取得できません。";
        return NO;
    }
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedContentTypes = @[types[index]];
    panel.nameFieldStringValue = [@"Mitaka" stringByAppendingPathExtension:types[index].preferredFilenameExtension];
    [panel beginSheetModalForWindow:_window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK || ![self canWriteOutputURL:panel.URL]) return;
        NSError *failure = nil;
        if (![image writeToURL:panel.URL options:NSDataWritingAtomic error:&failure]) [self showError:failure.localizedDescription];
    }];
    return YES;
}
- (void)showProjection:(id)sender { (void)sender; [[self displayOutput] showProjection]; }
- (void)toggleProjectionPointer:(id)sender {
    (void)sender;
    DisplayOutputController *output = [self displayOutput];
    output.pointerVisible = !output.pointerVisible;
}
- (void)toggleProjectionFade:(id)sender {
    (void)sender;
    DisplayOutputController *output = [self displayOutput];
    output.fadeOpacity = output.fadeOpacity > 0 ? 0 : 1;
}
@end
