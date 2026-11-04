#import "AppControllerInternal.h"
#include "small_body_orbit_model.hpp"

#include <cstdio>

@implementation AppController (ScriptSmokeTests)
- (void)runScriptSmokeTestWithCompletion:(void (^)(void))completion {
    [self configureScripts];
    if (_scripts.running || !_model || !_smallBodyModel || !_smallBodyDisplay ||
        _smallBodyOrbitSampling.sample_count == 0 || _loading) {
        [self showError:@"smoke: script host is not ready"];
        return;
    }
    const SessionState original = [self sessionState];
    const ScriptSnapshot originalScriptState = _scripts.snapshot();
    const HorizonViewport originalHorizon = [_horizon viewport];
    const auto range = _model->time_range();
    auto date = mitaka::gregorian_date_time((range.first + range.second) / 2);
    date.hour = 12; date.minute = 34; date.second = 56;
    const double expectedJD = mitaka::julian_date(date);
    std::size_t asteroidRows = 0;
    for (const auto& record : _smallBodyModel->dataset().records)
        if (record.kind == mitaka::SmallBodyKind::asteroid) ++asteroidRows;
    const bool asteroidBudgetExceeded = asteroidRows >
        maximum_small_body_orbit_total_samples / _smallBodyOrbitSampling.sample_count;
    const std::int32_t knownHIP = _starNameSelection && !_starNameSelection->known_hips().empty()
        ? *_starNameSelection->known_hips().begin() : 0;
    NSString *source = [NSString stringWithFormat:
        @"Time.realtime = false; Time:toggleRealtime(); assert(Time.realtime)\n"
         "Time.timeInfo = false; assert(not Time.timeInfo and Time.realtime)\n"
         "print('__smoke_time_info')\n"
         "Time:toggleTimeInfo(); assert(Time.timeInfo and Time.realtime)\n"
         "Time:toggleRealtime(); assert(not Time.realtime)\n"
         "Time.step = STEP_MIN\n"
         "Time.speed = -2\n"
         "assert(Time.speed == -2)\n"
         "Time:stop()\n"
         "assert(Time.speed == 0)\n"
         "Time:setTime(%d, %d, %d, 12, 34, 56)\n"
         "local y, m, d, h, n, s = Time:getTime()\n"
         "assert(y == %d and m == %d and d == %d and h == 12 and n == 34 and s == 56)\n"
         "Camera.azimuth = 450; assert(Camera.azimuth == 90)\n"
         "Camera.azimuth = -90; assert(Camera.azimuth == -90)\n"
         "assert(not pcall(function() Camera.altitude = 30 end))\n"
         "assert(not pcall(function() Camera:look('unknown') end))\n"
         "print('__smoke_azimuth')\n"
         "Camera.target = 'Planet.Earth'\n"
         "assert(Camera.target == 'Planet.Earth')\n"
         "Camera.target = 'Satellite.Moon'\n"
         "assert(Camera.target == 'Satellite.Moon')\n"
         "Camera.zoom = 2 * mtk.UNIT_AU\n"
         "assert(math.abs(Camera.zoom - 2 * UNIT_AU) < 1e-16)\n"
         "for _, distance in ipairs({1, 1e-15 * UNIT_AU, math.huge, 0/0}) do\n"
         "  local before = Camera.zoom\n"
         "  local ok, failure = pcall(function() Camera.zoom = distance end)\n"
         "  assert(not ok and type(failure) == 'string' and #failure > 0)\n"
         "  assert(Camera.zoom == before and Camera.target == 'Satellite.Moon')\n"
         "end\n"
         "for _, object in ipairs({Asteroids,TNObjects,Comets,Satellites}) do\n"
         " object.orbits=false\n"
         " for _, binding in ipairs({{'selectedOnly','toggleSelectedOnly'},\n"
         " {'visible','toggle'},{'labels','toggleLabels'},{'orbits','toggleOrbits'}}) do\n"
         "  local key,method=table.unpack(binding)\n"
         "  object[key]=false; assert(not object[key]); object[method](object); assert(object[key])\n"
         "  assert(not pcall(function() object[key]=1 end)); assert(object[key])\n"
         " end\n"
         " assert(not pcall(function() object:show('All') end))\n"
         " assert(not pcall(function() object:hide('All') end))\n"
         " assert(not pcall(function() object:isVisible('All') end))\n"
         "end\n"
         "if %@ then\n"
         " local ok,failure=pcall(function() Asteroids.selectedOnly=false end)\n"
         " assert(not ok and type(failure)=='string' and string.find(failure,'total sample limit',1,true))\n"
         " assert(Asteroids.selectedOnly and Asteroids.orbits and Asteroids.visible and Asteroids.labels)\n"
         "end\n"
         "print('__smoke_small_satellite')\n"
         "assert(not Asteroids.labels and not TNObjects.orbits and not Comets.selectedOnly and not Comets.orbits and not Satellites.labels)\n"
         "Constels.lines = false; Constels.bounds = false; Constels.labels = false; Constels.illusts = false\n"
         "print('__smoke_constellations_off')\n"
         "Constels:toggleLines(); Constels:toggleBounds(); Constels:toggleLabels(); Constels:toggleIllusts()\n"
         "assert(Constels.lines and Constels.bounds and Constels.labels and Constels.illusts)\n"
         "print('__smoke_constellations_on')\n"
         "Stars.labels = false; Stars:toggleLabels(); assert(Stars.labels)\n"
         "Stars:deselect('All'); local knownHIP = %d\n"
         "if knownHIP > 0 then\n"
         " local hip = tostring(knownHIP)\n"
         " assert(not Stars:isSelected(hip)); Stars:select(hip)\n"
         " assert(Stars:isSelected(hip)); Stars:deselect(hip)\n"
         " assert(not Stars:isSelected(hip))\n"
         "end\n"
         "Stars:select('All'); Stars.selectedLabels = false; Stars:toggleSelectedLabels()\n"
         "assert(Stars.selectedLabels)\n"
         "Stars.brightness = 0.5; assert(Stars.brightness == 0.5)\n"
         "Stars:brighten(); assert(Stars.brightness < 0.5)\n"
         "Stars:darken(); assert(math.abs(Stars.brightness - 0.5) < 1e-6)\n"
         "Stars:defaultBrightness(); assert(Stars.brightness == 1)\n"
         "Stars:setBrightnessTo(0.375, 0); assert(Stars.brightness == 0.375)\n"
         "local rs1,rs2,rs3,rs4=Planets:getScale(); local rsm=Planets:getScaleMode()\n"
         "Planets.scaleMode=mtk.KEEP_ORBIT; Planets:setScale(2,3,4,5)\n"
         "local a,b,c,d=Planets:getScale(); assert(a==2 and b==3 and c==4 and d==5)\n"
         "assert(Planets:getScaleMode()==mtk.KEEP_ORBIT)\n"
         "print('__smoke_radius')\n"
         "Planets.scaleMode=mtk.KEEP_RADIUS\n"
         "local ok,err=pcall(function() Planets:setScale(6,3,4,5) end)\n"
         "assert(not ok and type(err)=='string' and #err>0)\n"
         "a,b,c,d=Planets:getScale(); assert(a==2 and b==3 and c==4 and d==5)\n"
         "assert(Planets.scaleMode==mtk.KEEP_RADIUS)\n"
         "Planets.scaleMode=mtk.KEEP_ORBIT\n"
         "Planets:setScale(rs1,rs2,rs3,rs4); Planets:setScaleMode(rsm)\n"
         "for _, mode in ipairs({mtk.ATMOS_NONE, mtk.ATMOS_SINGLE, mtk.ATMOS_MULTIPLE}) do\n"
         " Planets.atmosphere = mode; assert(Planets.atmosphere == mode)\n"
         "end\n"
         "Planets:toggleAtmosphere(); assert(Planets.atmosphere == mtk.ATMOS_NONE)\n"
         "Planets:toggleAtmosphere(); assert(Planets.atmosphere == mtk.ATMOS_SINGLE)\n"
         "local layers = {{Stars,'visible','toggle'}, {Stars,'bayerLabels','toggleBayerLabels'},\n"
         " {Stars,'flamsteedLabels','toggleFlamsteedLabels'}, {Stars,'hipLabels','toggleHipLabels'},\n"
         " {Planets,'visible','toggle'}, {Planets,'labels','toggleLabels'},\n"
         " {Planets,'orbits','toggleOrbits'}, {Planets,'axes','toggleAxes'},\n"
         " {Planets,'clouds','toggleClouds'}, {Planets,'cityLights','toggleCityLights'},\n"
         " {Planets,'shadows','toggleShadows'}, {Planets,'shadowBorders','toggleShadowBorders'},\n"
         " {Planets,'shadowUmbra','toggleShadowUmbra'}, {Planets,'shadowPenumbra','toggleShadowPenumbra'},\n"
         " {Places,'landscape','toggleLandscape'},\n"
         " {Grids,'equatorial','toggleEquatorial'}, {Grids,'ecliptic','toggleEcliptic'},\n"
         " {Grids,'galactic','toggleGalactic'}, {Grids,'horizontal','toggleHorizontal'},\n"
         " {Grids,'circleScales','toggleCircleScales'}, {Grids,'squareScales','toggleSquareScales'}}\n"
         "for _, binding in ipairs(layers) do\n"
         " local object,key,method=table.unpack(binding)\n"
         " object[key]=false; assert(not object[key]); object[method](object); assert(object[key])\n"
         "end\n"
         "for _, kind in ipairs({'None','Normal','Bright','Infrared'}) do\n"
         " Milkyway.type=kind; assert(Milkyway.type==kind)\n"
         "end\n"
         "for _, kind in ipairs({'None','Binary','ExoPlanets'}) do\n"
         " Stars.markingType=kind; assert(Stars.markingType==kind)\n"
         "end\n"
         "local quality = {{'antialias','toggleAntialias'}, {'pointSmooth','togglePointSmooth'},\n"
         " {'lineSmooth','toggleLineSmooth'}, {'textSmooth','toggleTextSmooth'}}\n"
         "for _, binding in ipairs(quality) do\n"
         " Renderer[binding[1]]=false; assert(not Renderer[binding[1]])\n"
         " Renderer[binding[2]](Renderer); assert(Renderer[binding[1]])\n"
         "end\n"
         "print('__smoke_renderer')\n"
         "assert(not Renderer.antialias and not Renderer.pointSmooth and Renderer.lineSmooth and Renderer.textSmooth)\n"
         "assert(type(GUI.fullScreen)=='boolean'); GUI.fullScreen=GUI.fullScreen\n"
         "print('__smoke_display_options')\n"
         "assert(not Stars.hipLabels and not Planets.axes and not Grids.galactic)\n"
         "assert(Stars.markingType=='Binary' and Milkyway.type=='Normal')\n"
         "assert(not Stars.selectedLabels and Stars.brightness == 0.75)\n"
         "assert(not Planets.clouds and not Planets.cityLights and Planets.atmosphere == mtk.ATMOS_MULTIPLE)\n"
         "assert(not Planets.shadows and Planets.shadowBorders and not Planets.shadowUmbra and Planets.shadowPenumbra and not Places.landscape)\n"
         "Galaxies.NGCs = false; Galaxies:toggleNGCs(); assert(Galaxies.NGCs)\n"
         "Galaxies.SDSS = false; Galaxies:toggleDistantGalaxies()\n"
         "assert(Galaxies.SDSS and Galaxies.distantGalaxies)\n"
         "Galaxies.QSOs = false; Galaxies:toggleQuasars()\n"
         "assert(Galaxies.QSOs and Galaxies.quasars)\n"
         "GUI.targetBrowser = false; GUI:toggleTargetBrowser()\n"
         "GUI.timeSetting = false; GUI:toggleTimeSetting()\n"
         "GUI.placeSetting = false; GUI:togglePlaceSetting()\n"
         "GUI.scriptOutput = false; GUI:toggleScriptOutput()\n"
         "if GUI.dualScreen then GUI:toggleDualScreen() end\n"
         "GUI:toggleDualScreen()\n"
         "assert(GUI.targetBrowser and GUI.timeSetting and GUI.placeSetting and GUI.scriptOutput and GUI.dualScreen)\n"
         "print('__smoke_close_windows')\n"
         "assert(not GUI.targetBrowser and not GUI.timeSetting and not GUI.placeSetting and not GUI.scriptOutput and not GUI.dualScreen)\n"
         "assert(GUI:saveImageDialog() == nil)\n"
         "assert(not pcall(function() GUI:saveImageDialog() end))\n"
         "print('__smoke_cancel_image')\n"
         "local data = assert(io.open('data/hip.dat', 'rb')); assert(data:read(1)); data:close()\n"
         "print('native-script-first')\n"
         "print('native-script-second\\n')\n",
        date.year, date.month, date.day, date.year, date.month, date.day,
        asteroidBudgetExceeded ? @"true" : @"false", knownHIP];
    NSURL *directory = [NSURL fileURLWithPath:[NSTemporaryDirectory()
        stringByAppendingPathComponent:[@"mitaka-script-smoke-" stringByAppendingString:NSUUID.UUID.UUIDString]]
        isDirectory:YES];
    NSURL *successFile = [directory URLByAppendingPathComponent:@"host.lua"];
    NSURL *unsupportedFile = [directory URLByAppendingPathComponent:@"unsupported.lua"];
    NSError *error = nil;
    NSFileManager *files = NSFileManager.defaultManager;
    if (![files createDirectoryAtURL:directory withIntermediateDirectories:NO attributes:nil error:&error] ||
        ![source writeToURL:successFile atomically:YES encoding:NSUTF8StringEncoding error:&error] ||
        ![@"Constels.nativeSmokeUnsupported = true\nerror('unreachable')\n" writeToURL:unsupportedFile
            atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        [files removeItemAtURL:directory error:nil];
        [self showError:[NSString stringWithFormat:@"smoke: script fixture creation failed: %@", error.localizedDescription]];
        return;
    }

    void (^originalCompletion)(BOOL, NSString *) = _scripts.completion;
    void (^originalOutput)(NSString *) = _scripts.output;
    NSURL *originalWorkingDirectory = _scripts.workingDirectoryURL;
    const BOOL consoleWasVisible = _scriptWindow.visible;
    [self showScriptConsole:nil];
    _scriptLog.string = @"";
    // 元アプリの相対パス契約を、外部データへの読み取りだけで確認する。
    _scripts.workingDirectoryURL = [NSURL fileURLWithPath:_activePath.stringByDeletingLastPathComponent isDirectory:YES];
    __block BOOL finished = NO;
    __block BOOL imagePanelOpened = NO;
    __block NSString *interactionFailure = nil;
    __weak AppController *weakSelf = self;
    void (^finish)(NSString *) = ^(NSString *failure) {
        if (finished) return;
        finished = YES;
        AppController *controller = weakSelf;
        if (controller) {
            [controller->_scripts cancel];
            controller->_scripts.completion = originalCompletion;
            controller->_scripts.output = originalOutput;
            controller->_scripts.workingDirectoryURL = originalWorkingDirectory;
            if ([controller->_window.attachedSheet isKindOfClass:NSSavePanel.class])
                [(NSSavePanel *)controller->_window.attachedSheet cancel:nil];
            if (originalScriptState.target_browser) [controller showBrowser:nil];
            else [controller->_browser.window orderOut:nil];
            if (originalScriptState.time_setting) [controller showCalendar:nil];
            else [controller->_calendarWindow orderOut:nil];
            if (originalScriptState.place_setting) [controller showObserver:nil];
            else [controller->_observerWindow orderOut:nil];
            if (originalScriptState.dual_screen) [[controller displayOutput] showProjection];
            else [controller->_displayOutput closeProjection];
        }
        NSError *cleanupError = nil;
        if (![files removeItemAtURL:directory error:&cleanupError] && !failure)
            failure = [NSString stringWithFormat:@"smoke: script fixture cleanup failed: %@", cleanupError.localizedDescription];
        if (!controller) return;
        if (consoleWasVisible) [controller showScriptConsole:nil];
        else [controller->_scriptWindow orderOut:nil];
        if (failure) { [controller showError:failure]; return; }
        if (![controller applySessionState:original]) return;
        std::printf("Script AppKit smoke passed: legacy targets,date,speed,realtime,time-info,camera,invalid-zoom,azimuth,radius,display-options,small-body-satellite-flags,renderer,fullscreen-state,markings,milky-way,window-state,image-dialog,relative-data,log-lines,unsupported-API; orbit-budget=%s\n",
            asteroidBudgetExceeded ? "rejection-tested" : "no-local-over-budget-asteroids");
        completion();
    };
    // RPC の出力境界で通常のウィンドウ操作を行い、次の Lua 読み取りが実表示を参照することを確かめる。
    _scripts.output = ^(NSString *text) {
        AppController *controller = weakSelf;
        if (!controller) return;
        if ([text isEqualToString:@"__smoke_time_info"]) {
            if ([controller timeInfoVisible] || !controller->_dateLabel.hidden ||
                controller->_horizon.showsTimeInfo || controller->_solar.showsTimeInfo ||
                !controller->_playback.clockTracking)
                interactionFailure = @"smoke: Time.timeInfo did not update displays independently of clock tracking";
        } else if ([text isEqualToString:@"__smoke_radius"]) {
            mitaka::gui::RadiusDisplayOptions options;
            mitaka::gui::RadiusScaleMode mode;
            NSString *error = nil;
            if (![controller readRadiusDisplayOptions:&options mode:&mode error:&error] ||
                options.space_planet != 2 || options.space_sun != 3 ||
                options.planetarium_planet != 4 || options.planetarium_sun_moon != 5 ||
                mode != mitaka::gui::RadiusScaleMode::keep_orbit)
                interactionFailure = @"smoke: Lua radius options did not reach shared display state";
        } else if ([text isEqualToString:@"__smoke_small_satellite"]) {
            for (const auto kind : {mitaka::SmallBodyKind::asteroid, mitaka::SmallBodyKind::trans_neptunian, mitaka::SmallBodyKind::comet}) {
                const auto options = [controller smallBodyDisplayOptionsForKind:kind];
                if (!options.visible || !options.labels || !options.orbits || !options.selected_only)
                    interactionFailure = @"smoke: small-body Lua flags did not reach shared display state";
            }
            auto satellites = [controller satelliteDisplayOptions];
            const auto solar = [controller->_solar satelliteDisplayModel]->options();
            if (!satellites.visible || !satellites.labels || !satellites.orbits || !satellites.selected_only ||
                !solar.visible || !solar.labels || !solar.orbits || !solar.selected_only)
                interactionFailure = @"smoke: satellite Lua flags did not reach shared display state";
            auto asteroids = [controller smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::asteroid];
            auto tnobjects = [controller smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::trans_neptunian];
            auto comets = [controller smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::comet];
            asteroids.labels = false; tnobjects.orbits = false;
            comets.orbits = false; comets.selected_only = false;
            satellites.labels = false;
            [controller setSmallBodyDisplayOptions:asteroids forKind:mitaka::SmallBodyKind::asteroid];
            [controller setSmallBodyDisplayOptions:tnobjects forKind:mitaka::SmallBodyKind::trans_neptunian];
            [controller setSmallBodyDisplayOptions:comets forKind:mitaka::SmallBodyKind::comet];
            [controller setSatelliteDisplayOptions:satellites];
        } else if ([text isEqualToString:@"__smoke_constellations_off"] ||
                   [text isEqualToString:@"__smoke_constellations_on"]) {
            const bool expected = [text isEqualToString:@"__smoke_constellations_on"];
            for (const auto& options : {controller->_sky.constellationDisplayOptions,
                    controller->_horizon.constellationDisplayOptions}) {
                if (options.lines != expected || options.boundaries != expected || options.labels != expected ||
                    options.illustrations != expected ||
                    options.default_visible != original.constellations.default_visible ||
                    options.exceptions != original.constellations.exceptions || controller->_mode.selectedSegment != 1)
                    interactionFailure = @"smoke: Constels flags desynchronized views or changed membership or view mode";
            }
        } else if ([text isEqualToString:@"__smoke_renderer"]) {
            auto options = [controller rendererDisplayOptions];
            for (const auto& viewOptions : {options, [controller->_sky rendererDisplayOptions],
                    [controller->_horizon rendererDisplayOptions], [controller->_solar rendererDisplayOptions]}) {
                if (!viewOptions.antialias || !viewOptions.point_smoothing ||
                    !viewOptions.line_smoothing || !viewOptions.text_smoothing)
                    interactionFailure = @"smoke: Renderer settings did not reach all views";
            }
            options.antialias = false;
            options.point_smoothing = false;
            [controller setRendererDisplayOptions:options];
            // 天文データのロード中でも、実ウィンドウへの同一状態要求は受け付ける。
            const BOOL loading = controller->_loading;
            controller->_loading = YES;
            NSString *failure = nil;
            const bool fullScreen = [controller fullScreen];
            ScriptAction fullScreenAction{};
            fullScreenAction.kind = ScriptActionKind::set_full_screen;
            fullScreenAction.enabled = fullScreen;
            const ScriptSnapshot loadingState = controller->_scripts.snapshot();
            if (![controller applyScriptAction:fullScreenAction error:&failure] ||
                loadingState.full_screen != fullScreen ||
                loadingState.radius_display.space_planet != controller->_radiusDisplayOptions.space_planet ||
                loadingState.radius_scale_mode != controller->_radiusScaleMode)
                interactionFailure = @"smoke: fullscreen state was model-dependent or did not read the actual window";
            ScriptAction radiusAction{};
            radiusAction.kind = ScriptActionKind::set_radius_scale;
            radiusAction.radius_display = loadingState.radius_display;
            radiusAction.radius_display.space_planet = 2;
            failure = nil;
            if ([controller applyScriptAction:radiusAction error:&failure] || !failure ||
                controller->_radiusDisplayOptions.space_planet != loadingState.radius_display.space_planet)
                interactionFailure = @"smoke: radius mutation was accepted while loading";
            controller->_loading = loading;
        } else if ([text isEqualToString:@"__smoke_display_options"]) {
            auto stars = [controller starDisplayOptions];
            auto planets = [controller planetDisplayOptions];
            auto grids = [controller gridDisplayOptions];
            auto earthLayers = [controller earthLayerOptions];
            auto atmosphere = [controller atmosphereDisplayOptions];
            const auto eclipse = [controller eclipseDisplayOptions];
            if (!stars.visible || !stars.proper_names || !stars.bayer_labels || !stars.flamsteed_labels ||
                !stars.hip_labels || stars.marking != StarMarking::exoplanets ||
                !planets.visible || !planets.labels || !planets.orbits || !planets.axes ||
                !grids.equatorial || !grids.ecliptic || !grids.galactic || !grids.horizontal ||
                !grids.circle_scales || !grids.square_scales || controller->_sky.milkyWayMode != MilkyWayMode::infrared ||
                controller->_horizon.milkyWayMode != MilkyWayMode::infrared ||
                !stars.selected_proper_names_only || stars.brightness != 0.375f ||
                [controller selectedStarNameHIPs] != controller->_starNameSelection->known_hips() ||
                !earthLayers.clouds || !earthLayers.city_lights || atmosphere.mode != AtmosphereMode::single ||
                !eclipse.shadows || !eclipse.shadow_borders || !eclipse.shadow_umbra || !eclipse.shadow_penumbra ||
                !controller->_horizon.showsLandscapeImage)
                interactionFailure = @"smoke: Lua display options did not reach the shared GUI state";
            stars.hip_labels = false;
            stars.marking = StarMarking::binary;
            stars.selected_proper_names_only = false;
            stars.brightness = 0.75f;
            earthLayers.clouds = false;
            earthLayers.city_lights = false;
            atmosphere.mode = AtmosphereMode::multiple;
            planets.axes = false;
            grids.galactic = false;
            [controller setStarDisplayOptions:stars];
            [controller setPlanetDisplayOptions:planets];
            [controller setGridDisplayOptions:grids];
            [controller setEarthLayerOptions:earthLayers];
            [controller setAtmosphereDisplayOptions:atmosphere];
            [controller setEclipseDisplayOptions:EclipseDisplayOptions{false,true,false,true}];
            controller->_horizon.showsLandscapeImage = NO;
            [controller setMilkyWayMode:MilkyWayMode::normal];
        } else if ([text isEqualToString:@"__smoke_azimuth"]) {
            const auto viewport = [controller->_horizon viewport];
            if (controller->_mode.selectedSegment != 2 || viewport.center_azimuth_deg != 270 ||
                viewport.center_altitude_deg != originalHorizon.center_altitude_deg || viewport.zoom != originalHorizon.zoom)
                interactionFailure = @"smoke: azimuth changed other viewport state or did not select the horizon view";
        } else if ([text isEqualToString:@"__smoke_close_windows"]) {
            [controller->_browser.window performClose:nil];
            [controller->_calendarWindow performClose:nil];
            [controller->_observerWindow performClose:nil];
            [controller->_scriptWindow performClose:nil];
            [controller->_displayOutput closeProjection];
        } else if ([text isEqualToString:@"__smoke_cancel_image"]) {
            NSWindow *sheet = controller->_window.attachedSheet;
            imagePanelOpened = [sheet isKindOfClass:NSSavePanel.class];
            if (imagePanelOpened) [(NSSavePanel *)sheet cancel:nil];
            else interactionFailure = @"smoke: GUI:saveImageDialog did not present a save panel";
        } else originalOutput(text);
    };
    _scripts.completion = ^(BOOL succeeded, NSString *message) {
        if (finished) return;
        AppController *controller = weakSelf;
        if (!controller) { finish(@"smoke: script host was released"); return; }
        if (!succeeded) {
            finish([NSString stringWithFormat:@"smoke: script GUI execution failed: %@", message]);
            return;
        }
        if (interactionFailure) { finish(interactionFailure); return; }
        const auto state = controller->_scripts.snapshot();
        const auto camera = [controller->_solar cameraState];
        const auto moon = mitaka::j2000_equatorial_to_ecliptic(controller->_solarBodies[10].position_au);
        NSMutableArray<NSString *> *mismatches = [NSMutableArray array];
        const auto check = [mismatches](bool condition, NSString *name) {
            if (!condition) [mismatches addObject:name];
        };
        check(!controller->_scripts.running, @"script running");
        check(!state.playing && state.plus_time.speed == 0 && state.plus_time.step.step() == PlusTimeStep::minute &&
            state.plus_time.step.value_days() == 1.0 / 1440, @"time controls");
        check(std::abs(controller->_jd - expectedJD) <= 1e-9, @"date");
        check(state.target == "Satellite.Moon" && controller->_solar.selectedBodyIndex == 10 &&
            controller->_mode.selectedSegment == 1, @"target and mode");
        check(std::abs(camera.distance_au - 2) <= 1e-12, @"camera distance");
        check(std::hypot(camera.target.x - moon.x, camera.target.y - moon.y, camera.target.z - moon.z) <= 1e-10,
            @"camera target");
        check(state.constellation_lines && state.constellation_boundaries && state.constellation_labels &&
            state.constellation_illustrations, @"constellations");
        check(!state.stars.selected_proper_names_only && state.stars.brightness == 0.75f &&
            state.stars.proper_names && !state.stars.hip_labels && state.stars.marking == StarMarking::binary,
            @"stars");
        check(!state.earth_clouds && !state.earth_city_lights && state.atmosphere_mode == 2, @"Earth layers");
        check(!state.eclipse.shadows && state.eclipse.shadow_borders && !state.eclipse.shadow_umbra &&
            state.eclipse.shadow_penumbra && !state.landscape, @"eclipse and landscape");
        check(state.nebulae && state.distant_galaxies && state.quasars, @"galaxies");
        check(!state.clock_tracking && state.time_info, @"time display");
        check(!state.planets.axes && !state.grids.galactic && state.milky_way_type == "Normal", @"display options");
        check(!state.renderer.antialias && !state.renderer.point_smoothing && state.renderer.line_smoothing &&
            state.renderer.text_smoothing, @"renderer");
        check(!state.target_browser && !state.time_setting && !state.place_setting && !state.script_output &&
            !state.dual_screen, @"windows");
        check(imagePanelOpened, @"image panel");
        check([controller->_scriptLog.string isEqualToString:@"native-script-first\nnative-script-second\n\n"], @"script output");
        if (mismatches.count) {
            finish([@"smoke: script GUI state mismatch: " stringByAppendingString:
                [mismatches componentsJoinedByString:@", "]]);
            return;
        }
        void (^continueAfterSheet)(void) = ^{
            AppController *active = weakSelf;
            if (!active) { finish(@"smoke: script host was released"); return; }
            [active showScriptConsole:nil];
            active->_scripts.completion = ^(BOOL accepted, NSString *failure) {
                if (finished) return;
                AppController *current = weakSelf;
                if (!current) { finish(@"smoke: script host was released"); return; }
                current->_scripts.output(failure);
                if (accepted || current->_scripts.running || ![failure containsString:@"Unsupported"] ||
                    ![failure containsString:@"nativeSmokeUnsupported"] || ![failure containsString:@"unsupported.lua"] ||
                    !current->_scriptWindow.visible ||
                    ![current->_scriptLog.string containsString:failure]) {
                    finish(@"smoke: unsupported script API did not produce a visible error");
                    return;
                }
                finish(nil);
            };
            NSError *runError = nil;
            if (![active->_scripts runFile:unsupportedFile error:&runError])
                finish([NSString stringWithFormat:@"smoke: script restart failed: %@", runError.localizedDescription]);
        };
        if (!controller->_window.attachedSheet) {
            continueAfterSheet();
            return;
        }
        // cancel: はシートの終了を同期的には保証しない。実際に外れるまで待ち、
        // 終了しない場合は失敗にする。他の状態は待機前にすべて検証済み。
        NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5];
        NSTimer *timer = [NSTimer timerWithTimeInterval:0.01 repeats:YES block:^(NSTimer *timer) {
            if (finished) { [timer invalidate]; return; }
            AppController *active = weakSelf;
            if (!active) {
                [timer invalidate];
                finish(@"smoke: script host was released");
            } else if (!active->_window.attachedSheet) {
                [timer invalidate];
                continueAfterSheet();
            } else if (deadline.timeIntervalSinceNow <= 0) {
                [timer invalidate];
                finish(@"smoke: cancelled image panel did not close within 5 seconds");
            }
        }];
        [NSRunLoop.mainRunLoop addTimer:timer forMode:NSRunLoopCommonModes];
    };
    // API の真偽値試験では空の表示集合を使い、原本全行への軌道要求を意図せず作らない。
    // 超過拒否は上の Lua で別途検査し、終了時には保存済み session の集合へ戻す。
    auto display = std::make_shared<SmallBodyDisplayModel>(*_smallBodyDisplay);
    display->set_selected_ids({});
    for (const auto kind : {mitaka::SmallBodyKind::asteroid, mitaka::SmallBodyKind::trans_neptunian,
            mitaka::SmallBodyKind::comet}) {
        auto options = display->kind_options(kind);
        options.orbits = false;
        display->set_kind_options(kind, options);
    }
    [self setSmallBodyDisplayModel:std::move(display)];
    if (![_scripts runFile:successFile error:&error]) {
        finish([NSString stringWithFormat:@"smoke: script launch failed: %@", error.localizedDescription]);
        return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30LL * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (!finished) finish(@"smoke: script GUI execution timed out");
    });
}
@end
