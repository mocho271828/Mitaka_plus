#import "AppControllerInternal.h"
#include "star_brightness.hpp"
#import "HtmlBrowserController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <array>
#include <algorithm>
#include <stdexcept>

static constexpr std::array<const char *, 11> scriptBodyNames = {
    "Sun", "Planet.Mercury", "Planet.Venus", "Planet.Earth", "Planet.Mars", "Planet.Jupiter",
    "Planet.Saturn", "Planet.Uranus", "Planet.Neptune", "Planet.Pluto", "Satellite.Moon"};

static NSString *const scriptCompatibilityNote =
    @"対応: Time の日時・速度・時計追従、Camera の target・zoom・azimuth、星座・恒星・惑星・座標線・天の川の対応済み表示設定、Renderer の描画品質、GUI の既存ウィンドウ・全画面・情報表示。\n"
     "未対応の API はエラーを表示して停止します。\n";

@implementation AppController (Scripting)
- (void)configureScripts {
    if (_scripts) return;
    _scripts = [[ScriptController alloc] init];
    __weak AppController *weakSelf = self;
    _scripts.snapshot = ^ScriptSnapshot {
        AppController *controller = weakSelf;
        ScriptSnapshot state;
        if (!controller) return state;
        [controller fillScriptTimeSnapshot:state];
        const NSUInteger selected = controller->_solar.selectedBodyIndex;
        if (selected < scriptBodyNames.size()) state.target = scriptBodyNames[selected];
        state.camera_distance_au = [controller->_solar cameraState].distance_au;
        state.constellation_lines = controller->_sky.showsConstellationLines;
        state.constellation_boundaries = controller->_sky.showsConstellationBoundaries;
        state.constellation_labels = controller->_sky.showsConstellationNames;
        state.constellation_illustrations = [controller constellationDisplayOptions].illustrations;
        state.asteroids = [controller smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::asteroid];
        state.tnobjects = [controller smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::trans_neptunian];
        state.comets = [controller smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::comet];
        state.satellites = [controller satelliteDisplayOptions];
        state.planets = [controller planetDisplayOptions];
        // 共通 snapshot はロード中にも GUI の状態取得に使われる。
        state.radius_display = controller->_radiusDisplayOptions;
        state.radius_scale_mode = controller->_radiusScaleMode;
        state.terrain_amplification = [controller terrainAmplification];
        state.eclipse = [controller eclipseDisplayOptions];
        state.landscape = controller->_horizon.showsLandscapeImage;
        const auto earthLayers = [controller earthLayerOptions];
        state.earth_clouds = earthLayers.clouds;
        state.earth_city_lights = earthLayers.city_lights;
        switch ([controller atmosphereDisplayOptions].mode) {
            case AtmosphereMode::none: state.atmosphere_mode = 0; break;
            case AtmosphereMode::single: state.atmosphere_mode = 1; break;
            case AtmosphereMode::multiple: state.atmosphere_mode = 2; break;
        }
        state.stars = [controller starDisplayOptions];
        state.selected_star_names = [controller selectedStarNameHIPs];
        state.grids = [controller gridDisplayOptions];
        state.renderer = [controller rendererDisplayOptions];
        state.full_screen = [controller fullScreen];
        switch (controller->_sky.milkyWayMode) {
            case MilkyWayMode::none: state.milky_way_type = "None"; break;
            case MilkyWayMode::normal: state.milky_way_type = "Normal"; break;
            case MilkyWayMode::bright: state.milky_way_type = "Bright"; break;
            case MilkyWayMode::infrared: state.milky_way_type = "Infrared"; break;
        }
        state.nebulae = controller->_sky.showsNebulae;
        state.distant_galaxies = controller->_sky.showsGalaxies;
        state.quasars = controller->_sky.showsQuasars;
        const double azimuth = [controller->_horizon viewport].center_azimuth_deg;
        state.camera_azimuth_deg = azimuth > 180 ? azimuth - 360 : azimuth;
        state.target_browser = controller->_browser.window.visible;
        state.time_setting = controller->_calendarWindow.visible;
        state.place_setting = controller->_observerWindow.visible;
        state.script_output = controller->_scriptWindow.visible;
        state.dual_screen = controller->_displayOutput.projectionVisible;
        return state;
    };
    _scripts.applyAction = ^BOOL(const ScriptAction& action, NSString **error) {
        return [weakSelf applyScriptAction:action error:error];
    };
    _scripts.output = ^(NSString *text) {
        AppController *controller = weakSelf;
        if (!controller) return;
        NSTextStorage *storage = controller->_scriptLog.textStorage;
        // output は print 一回ごとのレコード。文字列内の改行も保持して Lua の行出力に合わせる。
        [storage appendAttributedString:[[NSAttributedString alloc] initWithString:[text stringByAppendingString:@"\n"]]];
        // 長時間動くスクリプトの出力でウィンドウのメモリが増え続けることを防ぐ。
        constexpr NSUInteger limit = 1024 * 1024;
        if (storage.length > limit) [storage deleteCharactersInRange:NSMakeRange(0, storage.length - limit)];
        [controller->_scriptLog scrollRangeToVisible:NSMakeRange(storage.length, 0)];
    };
    _scripts.completion = ^(BOOL succeeded, NSString *message) {
        AppController *controller = weakSelf;
        if (!controller) return;
        controller->_scripts.output(message);
        if (!succeeded) [controller showError:message];
    };
}
- (void)showScriptConsole:(id)sender {
    (void)sender;
    if (!_scriptWindow) {
        _scriptWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 740, 420)
            styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
            backing:NSBackingStoreBuffered defer:NO];
        _scriptWindow.releasedWhenClosed = NO;
        _scriptWindow.title = @"ローカル Lua スクリプト";
        NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:_scriptWindow.contentView.bounds];
        scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        scroll.hasVerticalScroller = YES;
        _scriptLog = [[NSTextView alloc] initWithFrame:scroll.bounds];
        _scriptLog.editable = NO;
        _scriptLog.string = scriptCompatibilityNote;
        _scriptLog.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
        _scriptLog.autoresizingMask = NSViewWidthSizable;
        scroll.documentView = _scriptLog;
        [_scriptWindow.contentView addSubview:scroll];
        [_scriptWindow center];
    }
    [_scriptWindow makeKeyAndOrderFront:nil];
}
- (void)runScript:(id)sender {
    (void)sender;
    if (!_model || _loading || _scripts.running) return;
    [self configureScripts];
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    UTType *luaType = [UTType typeWithFilenameExtension:@"lua"];
    panel.allowedContentTypes = @[luaType ? luaType : UTTypePlainText];
    panel.message = @"信頼したローカル Lua ファイルを選択してください。ファイルの読み書きとコマンド実行を許可して実行します。";
    [panel beginSheetModalForWindow:_window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK || !self->_model || self->_loading) return;
        [self showScriptConsole:nil];
        self->_scriptLog.string = [NSString stringWithFormat:@"実行: %@\n%@", panel.URL.path, scriptCompatibilityNote];
        self->_scripts.workingDirectoryURL = [NSURL fileURLWithPath:self->_activePath.stringByDeletingLastPathComponent isDirectory:YES];
        NSError *error = nil;
        if (![self->_scripts runFile:panel.URL error:&error]) [self showError:error.localizedDescription];
    }];
}
- (void)showHtmlBrowser:(id)sender {
    (void)sender;
    if (!_htmlBrowser) {
        _htmlBrowser = [HtmlBrowserController new];
        __weak AppController *weakSelf = self;
        _htmlBrowser.scriptRequested = ^BOOL(NSString *source, NSURL *file, NSString **failure) {
            AppController *controller = weakSelf;
            if (!controller || !controller->_model || controller->_loading) {
                if (failure) *failure = @"天文データが使用できません。";
                return NO;
            }
            [controller configureScripts];
            if (controller->_scripts.running) {
                if (failure) *failure = @"実行中の Lua を停止してからリンクを押してください。";
                return NO;
            }
            [controller showScriptConsole:nil];
            controller->_scripts.workingDirectoryURL = [NSURL fileURLWithPath:controller->_activePath.stringByDeletingLastPathComponent isDirectory:YES];
            NSError *error = nil;
            if (![controller->_scripts runSource:source error:&error]) {
                if (failure) *failure = error.localizedDescription;
                return NO;
            }
            controller->_scripts.output([NSString stringWithFormat:@"ローカル HTML から実行: %@", file.path]);
            return YES;
        };
    }
    if (_activePath.length) _htmlBrowser.defaultDirectoryURL = [[NSURL fileURLWithPath:_activePath.stringByDeletingLastPathComponent isDirectory:YES] URLByAppendingPathComponent:@"ui" isDirectory:YES];
    [_htmlBrowser showWindow:nil];
}
- (void)cancelScript:(id)sender { (void)sender; [_scripts cancel]; }
- (BOOL)applyScriptAction:(const ScriptAction&)action error:(NSString **)error {
    const bool windowAction = action.kind == ScriptActionKind::set_full_screen ||
        action.kind == ScriptActionKind::toggle_full_screen || action.kind == ScriptActionKind::show_about;
    if (!windowAction && (!_model || _loading)) { if (error) *error = @"天文データが使用できません。"; return NO; }
    try {
        switch (action.kind) {
            case ScriptActionKind::set_satellites_visible:
            case ScriptActionKind::set_satellites_labels:
            case ScriptActionKind::set_satellites_orbits:
            case ScriptActionKind::set_satellites_selected_only: {
                auto options = [self satelliteDisplayOptions];
                if (action.kind == ScriptActionKind::set_satellites_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_satellites_labels) options.labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_satellites_orbits) options.orbits = action.enabled;
                else options.selected_only = action.enabled;
                [self setSatelliteDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_full_screen: return [self setFullScreen:action.enabled error:error];
            case ScriptActionKind::toggle_full_screen: return [self toggleFullScreenWithError:error];
            case ScriptActionKind::show_about: [self showAbout:nil]; return YES;
            case ScriptActionKind::set_antialias:
            case ScriptActionKind::set_point_smoothing:
            case ScriptActionKind::set_line_smoothing:
            case ScriptActionKind::set_text_smoothing: {
                auto options = [self rendererDisplayOptions];
                if (action.kind == ScriptActionKind::set_antialias) options.antialias = action.enabled;
                else if (action.kind == ScriptActionKind::set_point_smoothing) options.point_smoothing = action.enabled;
                else if (action.kind == ScriptActionKind::set_line_smoothing) options.line_smoothing = action.enabled;
                else options.text_smoothing = action.enabled;
                [self setRendererDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_time_step:
            case ScriptActionKind::set_time_step_value:
            case ScriptActionKind::set_time_speed:
            case ScriptActionKind::previous_time_step:
            case ScriptActionKind::next_time_step:
            case ScriptActionKind::step_time_forward:
            case ScriptActionKind::step_time_rewind:
            case ScriptActionKind::set_date:
            case ScriptActionKind::set_rate:
            case ScriptActionKind::stop:
            case ScriptActionKind::set_clock_tracking:
            case ScriptActionKind::set_time_info:
            case ScriptActionKind::set_time_animation_jd:
            case ScriptActionKind::set_time_animation_calendar:
                return [self applyScriptTimeAction:action error:error];
            case ScriptActionKind::select_target: {
                const auto found = std::find(scriptBodyNames.begin(), scriptBodyNames.end(), action.text);
                if (found == scriptBodyNames.end()) throw std::invalid_argument("Unsupported Camera.target: " + action.text);
                [_solar selectBody:static_cast<NSUInteger>(found - scriptBodyNames.begin())];
                _mode.selectedSegment = 1;
                [self changeMode:nil];
                [_solar focusSelection];
                break;
            }
            case ScriptActionKind::set_camera_distance: {
                auto camera = [_solar cameraState];
                camera.distance_au = action.number;
                return [_solar applyCameraState:camera error:error];
            }
            case ScriptActionKind::set_constellation_lines:
            case ScriptActionKind::set_constellation_boundaries:
            case ScriptActionKind::set_constellation_illustrations:
            case ScriptActionKind::set_constellation_labels: {
                auto options = [self constellationDisplayOptions];
                if (action.kind == ScriptActionKind::set_constellation_lines) options.lines = action.enabled;
                else if (action.kind == ScriptActionKind::set_constellation_boundaries) options.boundaries = action.enabled;
                else if (action.kind == ScriptActionKind::set_constellation_illustrations) options.illustrations = action.enabled;
                else options.labels = action.enabled;
                [self setConstellationDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_star_labels:
            case ScriptActionKind::set_stars_visible:
            case ScriptActionKind::set_bayer_labels:
            case ScriptActionKind::set_flamsteed_labels:
            case ScriptActionKind::set_selected_star_labels:
            case ScriptActionKind::set_hip_labels: {
                auto options = [self starDisplayOptions];
                if (action.kind == ScriptActionKind::set_star_labels) options.proper_names = action.enabled;
                else if (action.kind == ScriptActionKind::set_stars_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_bayer_labels) options.bayer_labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_flamsteed_labels) options.flamsteed_labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_selected_star_labels) options.selected_proper_names_only = action.enabled;
                else options.hip_labels = action.enabled;
                [self setStarDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_star_name_membership: {
                if (!_starNameSelection) throw std::invalid_argument("star name catalog is not loaded");
                std::vector<std::int32_t> known;
                for (const auto hip : action.hips)
                    if (_starNameSelection->known_hips().count(hip)) known.push_back(hip);
                [self setStarNameMembership:known selected:action.enabled];
                break;
            }
            case ScriptActionKind::set_all_star_names_selected:
                [self setAllStarNamesSelected:action.enabled];
                break;
            case ScriptActionKind::set_star_brightness:
                [self setStarBrightness:action.number cancelTransition:YES];
                break;
            case ScriptActionKind::brighten_stars:
                [self setStarBrightness:brighter_star_brightness([self starDisplayOptions].brightness) cancelTransition:NO];
                break;
            case ScriptActionKind::darken_stars:
                [self setStarBrightness:darker_star_brightness([self starDisplayOptions].brightness) cancelTransition:NO];
                break;
            case ScriptActionKind::default_star_brightness:
                [self setStarBrightness:1 cancelTransition:NO];
                break;
            case ScriptActionKind::animate_star_brightness:
                return [self animateStarBrightness:action.number duration:action.duration_seconds error:error];
            case ScriptActionKind::set_star_marking: {
                auto options = [self starDisplayOptions];
                if (action.text == "None") options.marking = StarMarking::none;
                else if (action.text == "Binary") options.marking = StarMarking::binary;
                else if (action.text == "ExoPlanets") options.marking = StarMarking::exoplanets;
                else throw std::invalid_argument("Unsupported Stars.markingType: " + action.text);
                [self setStarDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_shadows:
            case ScriptActionKind::set_shadow_borders:
            case ScriptActionKind::set_shadow_umbra:
            case ScriptActionKind::set_shadow_penumbra: {
                auto options = [self eclipseDisplayOptions];
                if (action.kind == ScriptActionKind::set_shadows) options.shadows = action.enabled;
                else if (action.kind == ScriptActionKind::set_shadow_borders) options.shadow_borders = action.enabled;
                else if (action.kind == ScriptActionKind::set_shadow_umbra) options.shadow_umbra = action.enabled;
                else options.shadow_penumbra = action.enabled;
                [self setEclipseDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_landscape:
                _horizon.showsLandscapeImage = action.enabled;
                [NSApp.mainMenu update];
                break;
            case ScriptActionKind::set_terrain_amplification:
                [self setTerrainAmplification:action.terrain_amplification];
                break;
            case ScriptActionKind::set_radius_scale:
            case ScriptActionKind::set_radius_scale_mode: {
                RadiusDisplayOptions options;
                RadiusScaleMode mode;
                if (![self readRadiusDisplayOptions:&options mode:&mode error:error]) return NO;
                if (action.kind == ScriptActionKind::set_radius_scale) options = action.radius_display;
                else mode = action.radius_scale_mode;
                return [self applyRadiusDisplayOptions:options mode:mode error:error];
            }
            case ScriptActionKind::set_earth_clouds:
            case ScriptActionKind::set_earth_city_lights: {
                auto options = [self earthLayerOptions];
                if (action.kind == ScriptActionKind::set_earth_clouds) options.clouds = action.enabled;
                else options.city_lights = action.enabled;
                [self setEarthLayerOptions:options];
                break;
            }
            case ScriptActionKind::set_atmosphere_mode: {
                auto options = [self atmosphereDisplayOptions];
                if (action.number == 0) options.mode = AtmosphereMode::none;
                else if (action.number == 1) options.mode = AtmosphereMode::single;
                else if (action.number == 2) options.mode = AtmosphereMode::multiple;
                else throw std::invalid_argument("Unsupported Planets.atmosphere mode");
                [self setAtmosphereDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_planets_visible:
            case ScriptActionKind::set_planet_labels:
            case ScriptActionKind::set_planet_orbits:
            case ScriptActionKind::set_planet_axes: {
                auto options = [self planetDisplayOptions];
                if (action.kind == ScriptActionKind::set_planets_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_planet_labels) options.labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_planet_orbits) options.orbits = action.enabled;
                else options.axes = action.enabled;
                [self setPlanetDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_asteroids_visible:
            case ScriptActionKind::set_asteroids_labels:
            case ScriptActionKind::set_asteroids_orbits:
            case ScriptActionKind::set_asteroids_selected_only:
            {
                auto options = [self smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::asteroid];
                if (action.kind == ScriptActionKind::set_asteroids_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_asteroids_labels) options.labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_asteroids_orbits) options.orbits = action.enabled;
                else options.selected_only = action.enabled;
                [self setSmallBodyDisplayOptions:options forKind:mitaka::SmallBodyKind::asteroid];
                break;
            }
            case ScriptActionKind::set_tnobjects_visible:
            case ScriptActionKind::set_tnobjects_labels:
            case ScriptActionKind::set_tnobjects_orbits:
            case ScriptActionKind::set_tnobjects_selected_only:
            {
                auto options = [self smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::trans_neptunian];
                if (action.kind == ScriptActionKind::set_tnobjects_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_tnobjects_labels) options.labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_tnobjects_orbits) options.orbits = action.enabled;
                else options.selected_only = action.enabled;
                [self setSmallBodyDisplayOptions:options forKind:mitaka::SmallBodyKind::trans_neptunian];
                break;
            }
            case ScriptActionKind::set_comets_visible:
            case ScriptActionKind::set_comets_labels:
            case ScriptActionKind::set_comets_orbits:
            case ScriptActionKind::set_comets_selected_only:
            {
                auto options = [self smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::comet];
                if (action.kind == ScriptActionKind::set_comets_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_comets_labels) options.labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_comets_orbits) options.orbits = action.enabled;
                else options.selected_only = action.enabled;
                [self setSmallBodyDisplayOptions:options forKind:mitaka::SmallBodyKind::comet];
                break;
            }
            case ScriptActionKind::set_equatorial_grid:
            case ScriptActionKind::set_ecliptic_grid:
            case ScriptActionKind::set_galactic_grid:
            case ScriptActionKind::set_horizontal_grid:
            case ScriptActionKind::set_circle_scales:
            case ScriptActionKind::set_square_scales: {
                auto options = [self gridDisplayOptions];
                if (action.kind == ScriptActionKind::set_equatorial_grid) options.equatorial = action.enabled;
                else if (action.kind == ScriptActionKind::set_ecliptic_grid) options.ecliptic = action.enabled;
                else if (action.kind == ScriptActionKind::set_galactic_grid) options.galactic = action.enabled;
                else if (action.kind == ScriptActionKind::set_horizontal_grid) options.horizontal = action.enabled;
                else if (action.kind == ScriptActionKind::set_circle_scales) options.circle_scales = action.enabled;
                else options.square_scales = action.enabled;
                [self setGridDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_milky_way_type:
                if (action.text == "None") [self setMilkyWayMode:MilkyWayMode::none];
                else if (action.text == "Normal") [self setMilkyWayMode:MilkyWayMode::normal];
                else if (action.text == "Bright") [self setMilkyWayMode:MilkyWayMode::bright];
                else if (action.text == "Infrared") [self setMilkyWayMode:MilkyWayMode::infrared];
                else throw std::invalid_argument("Unsupported Milkyway.type: " + action.text);
                break;
            case ScriptActionKind::set_nebulae: _sky.showsNebulae = action.enabled; break;
            case ScriptActionKind::set_distant_galaxies: _sky.showsGalaxies = action.enabled; break;
            case ScriptActionKind::set_quasars: _sky.showsQuasars = action.enabled; break;
            case ScriptActionKind::set_camera_azimuth: {
                if (!std::isfinite(action.number)) throw std::invalid_argument("Camera.azimuth must be finite");
                auto viewport = [_horizon viewport];
                viewport.center_azimuth_deg = std::remainder(action.number, 360.0);
                [_horizon setViewport:viewport];
                _mode.selectedSegment = 2;
                [self changeMode:nil];
                break;
            }
            case ScriptActionKind::set_target_browser:
                if (action.enabled) [self showBrowser:nil]; else [_browser.window orderOut:nil];
                break;
            case ScriptActionKind::set_time_setting:
                if (action.enabled) [self showCalendar:nil]; else [_calendarWindow orderOut:nil];
                break;
            case ScriptActionKind::set_place_setting:
                if (action.enabled) [self showObserver:nil]; else [_observerWindow orderOut:nil];
                break;
            case ScriptActionKind::set_script_output:
                if (action.enabled) [self showScriptConsole:nil]; else [_scriptWindow orderOut:nil];
                break;
            case ScriptActionKind::set_dual_screen:
                if (action.enabled) [[self displayOutput] showProjection]; else [_displayOutput closeProjection];
                break;
            case ScriptActionKind::save_image_dialog:
                return [self beginImageSaveDialog:DisplayImageFormatPNG error:error];
        }
        return YES;
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
}
@end
