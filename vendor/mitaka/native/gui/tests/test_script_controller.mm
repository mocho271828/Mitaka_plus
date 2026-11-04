#import <Foundation/Foundation.h>
#import "ScriptController.h"
#include "star_brightness.hpp"
#include <cmath>
#include <cstdio>
#include <stdexcept>
#include <string>

using namespace mitaka::gui;
namespace {
void check(bool condition, const char *message) { if (!condition) throw std::runtime_error(message); }
struct Outcome { bool succeeded; std::string message; };
Outcome run(ScriptController *controller, NSURL *file, NSString *source, bool cancel = false, bool inlineSource = false) {
    NSError *error = nil;
    check([source writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:&error], "write fixture");
    __block bool finished = false;
    __block Outcome result{};
    controller.completion = ^(BOOL succeeded, NSString *message) {
        check(NSThread.isMainThread, "completion must be on main thread");
        result = {static_cast<bool>(succeeded), message.UTF8String};
        finished = true;
    };
    check(inlineSource ? [controller runSource:source error:&error] : [controller runFile:file error:&error], error ? error.localizedDescription.UTF8String : "launch script");
    check(controller.running, "running state during script");
    if (cancel) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{ [controller cancel]; });
    const auto deadline = [NSDate dateWithTimeIntervalSinceNow:5];
    while (!finished && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    if (!finished) [controller cancel];
    check(finished, "script should complete without blocking main run loop");
    check(!controller.running, "running state after completion");
    return result;
}
}
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        try {
            check(argc == 2, "pass MitakaScript helper path");
            NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
            NSURL *directory = [NSURL fileURLWithPath:path isDirectory:YES];
            check([NSFileManager.defaultManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:nil], "create fixture directory");
            NSURL *file = [directory URLByAppendingPathComponent:@"test.lua"];
            ScriptController *controller = [[ScriptController alloc] initWithHelperURL:[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]]];
            __block ScriptSnapshot state;
            __block NSMutableArray<NSString *> *logs = [NSMutableArray array];
            __block int applied = 0;
            __block int imageDialogs = 0;
            __block bool rejectClockTracking = false;
            __block bool rejectRenderer = false, rejectFullScreen = false;
            __block int fullScreenToggles = 0, aboutDialogs = 0;
            __block bool rejectBrightness = false;
            __block bool rejectNameSelection = false;
            __block bool rejectEarthLayers = false, rejectTime = false;
            __block bool rejectEclipseLandscape = false;
            __block bool rejectTerrain = false;
            __block bool rejectRadius = false;
            __block double brightnessTarget = 0, brightnessDuration = 0;
            controller.snapshot = ^{ check(NSThread.isMainThread, "snapshot thread"); return state; };
            controller.applyAction = ^BOOL(const ScriptAction& action, NSString **error) {
                check(NSThread.isMainThread, "apply thread");
                ++applied;
                if (rejectNameSelection && action.kind >= ScriptActionKind::set_constellation_illustrations &&
                    action.kind <= ScriptActionKind::set_all_star_names_selected) {
                    *error = @"Name selection unavailable"; return NO;
                }
                if (rejectBrightness && action.kind >= ScriptActionKind::set_star_brightness &&
                    action.kind <= ScriptActionKind::animate_star_brightness) {
                    *error = @"Star brightness unavailable"; return NO;
                }
                if (rejectRenderer && action.kind >= ScriptActionKind::set_antialias &&
                    action.kind <= ScriptActionKind::set_text_smoothing) {
                    *error = @"Renderer unavailable"; return NO;
                }
                if (rejectFullScreen && (action.kind == ScriptActionKind::set_full_screen ||
                    action.kind == ScriptActionKind::toggle_full_screen)) {
                    *error = @"Full screen transition in progress"; return NO;
                }
                if (rejectEarthLayers && action.kind >= ScriptActionKind::set_earth_clouds &&
                    action.kind <= ScriptActionKind::set_atmosphere_mode) {
                    *error = @"Earth layers unavailable"; return NO;
                }
                if (rejectTime && action.kind >= ScriptActionKind::set_time_step &&
                    action.kind <= ScriptActionKind::step_time_rewind) {
                    *error = @"Time update unavailable"; return NO;
                }
                switch (action.kind) {
                    case ScriptActionKind::set_radius_scale:
                        if (rejectRadius) { *error = @"Radius unavailable"; return NO; }
                        state.radius_display = action.radius_display; break;
                    case ScriptActionKind::set_radius_scale_mode:
                        if (rejectRadius) { *error = @"Radius unavailable"; return NO; }
                        state.radius_scale_mode = action.radius_scale_mode; break;
                    case ScriptActionKind::set_terrain_amplification:
                        if (rejectTerrain) { *error = @"Terrain amplification unavailable"; return NO; }
                        state.terrain_amplification = action.terrain_amplification; break;
                    case ScriptActionKind::set_shadows:
                    case ScriptActionKind::set_shadow_borders:
                    case ScriptActionKind::set_shadow_umbra:
                    case ScriptActionKind::set_shadow_penumbra:
                    case ScriptActionKind::set_landscape:
                        if (rejectEclipseLandscape) { *error = @"Eclipse and landscape unavailable"; return NO; }
                        if (action.kind == ScriptActionKind::set_shadows) state.eclipse.shadows = action.enabled;
                        else if (action.kind == ScriptActionKind::set_shadow_borders) state.eclipse.shadow_borders = action.enabled;
                        else if (action.kind == ScriptActionKind::set_shadow_umbra) state.eclipse.shadow_umbra = action.enabled;
                        else if (action.kind == ScriptActionKind::set_shadow_penumbra) state.eclipse.shadow_penumbra = action.enabled;
                        else state.landscape = action.enabled;
                        break;
                    case ScriptActionKind::set_earth_clouds: state.earth_clouds = action.enabled; break;
                    case ScriptActionKind::set_earth_city_lights: state.earth_city_lights = action.enabled; break;
                    case ScriptActionKind::set_atmosphere_mode: state.atmosphere_mode = static_cast<int>(action.number); break;
                    case ScriptActionKind::set_constellation_illustrations: state.constellation_illustrations = action.enabled; break;
                    case ScriptActionKind::set_selected_star_labels: state.stars.selected_proper_names_only = action.enabled; break;
                    case ScriptActionKind::set_star_name_membership:
                        for (const auto hip : action.hips) {
                            if (hip != 1 && hip != 2 && hip != 3) continue;
                            if (action.enabled) state.selected_star_names.insert(hip);
                            else state.selected_star_names.erase(hip);
                        }
                        break;
                    case ScriptActionKind::set_all_star_names_selected:
                        state.selected_star_names = action.enabled ? std::set<std::int32_t>{1,2,3} : std::set<std::int32_t>{}; break;
                    case ScriptActionKind::set_star_brightness:
                        state.stars.brightness = checked_star_brightness(action.number); break;
                    case ScriptActionKind::brighten_stars:
                        state.stars.brightness = brighter_star_brightness(state.stars.brightness); break;
                    case ScriptActionKind::darken_stars:
                        state.stars.brightness = darker_star_brightness(state.stars.brightness); break;
                    case ScriptActionKind::default_star_brightness: state.stars.brightness = 1; break;
                    case ScriptActionKind::animate_star_brightness:
                        brightnessTarget = action.number; brightnessDuration = action.duration_seconds; break;
                    case ScriptActionKind::set_asteroids_visible: state.asteroids.visible = action.enabled; break;
                    case ScriptActionKind::set_asteroids_labels: state.asteroids.labels = action.enabled; break;
                    case ScriptActionKind::set_asteroids_orbits: state.asteroids.orbits = action.enabled; break;
                    case ScriptActionKind::set_asteroids_selected_only: state.asteroids.selected_only = action.enabled; break;
                    case ScriptActionKind::set_tnobjects_visible: state.tnobjects.visible = action.enabled; break;
                    case ScriptActionKind::set_tnobjects_labels: state.tnobjects.labels = action.enabled; break;
                    case ScriptActionKind::set_tnobjects_orbits: state.tnobjects.orbits = action.enabled; break;
                    case ScriptActionKind::set_tnobjects_selected_only: state.tnobjects.selected_only = action.enabled; break;
                    case ScriptActionKind::set_comets_visible: state.comets.visible = action.enabled; break;
                    case ScriptActionKind::set_comets_labels: state.comets.labels = action.enabled; break;
                    case ScriptActionKind::set_comets_orbits: state.comets.orbits = action.enabled; break;
                    case ScriptActionKind::set_comets_selected_only: state.comets.selected_only = action.enabled; break;
                    case ScriptActionKind::set_satellites_visible: state.satellites.visible = action.enabled; break;
                    case ScriptActionKind::set_satellites_labels: state.satellites.labels = action.enabled; break;
                    case ScriptActionKind::set_satellites_orbits: state.satellites.orbits = action.enabled; break;
                    case ScriptActionKind::set_satellites_selected_only: state.satellites.selected_only = action.enabled; break;
                    case ScriptActionKind::set_antialias: state.renderer.antialias = action.enabled; break;
                    case ScriptActionKind::set_point_smoothing: state.renderer.point_smoothing = action.enabled; break;
                    case ScriptActionKind::set_line_smoothing: state.renderer.line_smoothing = action.enabled; break;
                    case ScriptActionKind::set_text_smoothing: state.renderer.text_smoothing = action.enabled; break;
                    case ScriptActionKind::set_full_screen: state.full_screen = action.enabled; break;
                    // 非同期の受付を模し、toggle を受けても snapshot の実表示はまだ変えない。
                    case ScriptActionKind::toggle_full_screen: ++fullScreenToggles; break;
                    case ScriptActionKind::show_about: ++aboutDialogs; break;
                    case ScriptActionKind::set_time_step:
                        state.plus_time.step.select(static_cast<PlusTimeStep>(static_cast<int>(action.number))); break;
                    case ScriptActionKind::set_time_step_value: state.plus_time.step.set_value_days(action.number); break;
                    case ScriptActionKind::set_time_speed:
                        state.plus_time.speed = plus_time_speed(action.number);
                        state.playing = state.plus_time.speed != 0; break;
                    case ScriptActionKind::previous_time_step: state.plus_time.step.previous(); break;
                    case ScriptActionKind::next_time_step: state.plus_time.step.next(); break;
                    case ScriptActionKind::step_time_forward:
                    case ScriptActionKind::step_time_rewind:
                        state.julian_date = state.plus_time.step.stepped_julian_date(state.julian_date,
                            action.kind == ScriptActionKind::step_time_forward ? 1 : -1);
                        state.playing = false; state.plus_time.speed = 0; break;
                    case ScriptActionKind::set_time_animation_jd:
                    case ScriptActionKind::set_time_animation_calendar:
                    case ScriptActionKind::set_date:
                        state.julian_date = action.number; state.playing = false; state.plus_time.speed = 0; break;
                    case ScriptActionKind::set_rate: state.rate_seconds_per_second = action.number; state.playing = true; break;
                    case ScriptActionKind::stop: state.playing = false; state.plus_time.speed = 0; break;
                    case ScriptActionKind::select_target:
                        if (action.text != "Planet.Earth" && action.text != "Satellite.Moon" && action.text != "Sun") {
                            *error = @"Unknown target"; return NO;
                        }
                        state.target = action.text; break;
                    case ScriptActionKind::set_camera_distance: state.camera_distance_au = action.number; break;
                    case ScriptActionKind::set_constellation_lines: state.constellation_lines = action.enabled; break;
                    case ScriptActionKind::set_constellation_boundaries: state.constellation_boundaries = action.enabled; break;
                    case ScriptActionKind::set_constellation_labels: state.constellation_labels = action.enabled; break;
                    case ScriptActionKind::set_star_labels: state.stars.proper_names = action.enabled; break;
                    case ScriptActionKind::set_stars_visible: state.stars.visible = action.enabled; break;
                    case ScriptActionKind::set_bayer_labels: state.stars.bayer_labels = action.enabled; break;
                    case ScriptActionKind::set_flamsteed_labels: state.stars.flamsteed_labels = action.enabled; break;
                    case ScriptActionKind::set_hip_labels: state.stars.hip_labels = action.enabled; break;
                    case ScriptActionKind::set_star_marking:
                        state.stars.marking = action.text == "None" ? StarMarking::none :
                            action.text == "Binary" ? StarMarking::binary : StarMarking::exoplanets;
                        break;
                    case ScriptActionKind::set_planets_visible: state.planets.visible = action.enabled; break;
                    case ScriptActionKind::set_planet_labels: state.planets.labels = action.enabled; break;
                    case ScriptActionKind::set_planet_orbits: state.planets.orbits = action.enabled; break;
                    case ScriptActionKind::set_planet_axes: state.planets.axes = action.enabled; break;
                    case ScriptActionKind::set_equatorial_grid: state.grids.equatorial = action.enabled; break;
                    case ScriptActionKind::set_ecliptic_grid: state.grids.ecliptic = action.enabled; break;
                    case ScriptActionKind::set_galactic_grid: state.grids.galactic = action.enabled; break;
                    case ScriptActionKind::set_horizontal_grid: state.grids.horizontal = action.enabled; break;
                    case ScriptActionKind::set_circle_scales: state.grids.circle_scales = action.enabled; break;
                    case ScriptActionKind::set_square_scales: state.grids.square_scales = action.enabled; break;
                    case ScriptActionKind::set_milky_way_type: state.milky_way_type = action.text; break;
                    case ScriptActionKind::set_time_info: state.time_info = action.enabled; break;
                    case ScriptActionKind::set_clock_tracking:
                        if (rejectClockTracking) { *error = @"Clock source unavailable"; return NO; }
                        state.clock_tracking = action.enabled; break;
                    case ScriptActionKind::set_nebulae: state.nebulae = action.enabled; break;
                    case ScriptActionKind::set_distant_galaxies: state.distant_galaxies = action.enabled; break;
                    case ScriptActionKind::set_quasars: state.quasars = action.enabled; break;
                    case ScriptActionKind::set_camera_azimuth: state.camera_azimuth_deg = std::remainder(action.number, 360); break;
                    case ScriptActionKind::set_target_browser: state.target_browser = action.enabled; break;
                    case ScriptActionKind::set_time_setting: state.time_setting = action.enabled; break;
                    case ScriptActionKind::set_place_setting: state.place_setting = action.enabled; break;
                    case ScriptActionKind::set_script_output: state.script_output = action.enabled; break;
                    case ScriptActionKind::set_dual_screen: state.dual_screen = action.enabled; break;
                    case ScriptActionKind::save_image_dialog:
                        if (imageDialogs) { *error = @"An image dialog is already open"; return NO; }
                        ++imageDialogs; break;
                }
                return YES;
            };
            controller.output = ^(NSString *text) { check(NSThread.isMainThread, "output thread"); [logs addObject:text]; };
            auto outcome = run(controller, file, @R"lua(
                Time:setTime(2009,7,22,0,30,0)
                local y,m,d,h,n,s=Time:getTime()
                assert(y==2009 and m==7 and d==22 and h==0 and n==30 and s==0)
                Time:setTime(2024,2,29,23,59,59)
                assert(Time.second==59 and Time.day==29)
                Time.step=STEP_MIN; Time.speed=-2; assert(Time.speed==-2)
                Time.step=STEP_HOUR; assert(Time.speed==-2)
                Time:stop(); assert(Time.speed==0)
                Time.step=STEP_VALUE; Time.stepValue=1/86400
                Time:forward()
                y,m,d,h,n,s=Time:getTime()
                assert(y==2024 and m==3 and d==1 and h==0 and n==0 and s==0)
                Time:rewind(); assert(Time.day==29 and Time.sec==59)
                Time.year=2020; Time.min=25; assert(Time.year==2020 and Time.minute==25)
                Camera.target='Planet.Earth'; assert(Camera.target=='Planet.Earth')
                Camera.zoom=2*mtk.UNIT_AU; assert(math.abs(Camera.zoom-2*UNIT_AU)<1e-16)
                Constels.lines=true; Constels:toggleBounds(); Constels:toggleLabels()
                assert(Constels.lines and Constels.bounds and Constels.labels)
                Stars.labels=true; assert(Stars.labels); Stars:toggleLabels(); assert(not Stars.labels)
                Galaxies.NGCs=true; Galaxies:toggleNGCs(); assert(not Galaxies.NGCs)
                Galaxies.distantGalaxies=true; assert(Galaxies.SDSS)
                Galaxies:toggleSDSS(); assert(not Galaxies.distantGalaxies)
                Galaxies.SDSS=true; Galaxies:toggleDistantGalaxies(); assert(not Galaxies.SDSS)
                Galaxies.quasars=true; assert(Galaxies.QSOs)
                Galaxies:toggleQSOs(); assert(not Galaxies.quasars)
                Galaxies.QSOs=true; Galaxies:toggleQuasars(); assert(not Galaxies.QSOs)
                Camera.azimuth=-90; assert(Camera.azimuth==-90)
                for _, window in ipairs({'targetBrowser','timeSetting','placeSetting','scriptOutput'}) do
                    GUI[window]=true; assert(GUI[window])
                    GUI[window]=false; assert(not GUI[window])
                end
                GUI:toggleTargetBrowser(); GUI:toggleTimeSetting(); GUI:togglePlaceSetting(); GUI:toggleScriptOutput()
                assert(GUI.targetBrowser and GUI.timeSetting and GUI.placeSetting and GUI.scriptOutput)
                assert(not GUI.dualScreen); GUI:toggleDualScreen(); assert(GUI.dualScreen)
                GUI:toggleDualScreen(); assert(not GUI.dualScreen)
                assert(GUI:saveImageDialog()==nil)
                local out=assert(io.open('local-output.txt','w')); out:write('trusted'); out:close()
                retained=assert(io.open('flushed-output.txt','w')); retained:write('flushed')
                local nested=assert(io.open('nested.lua','w')); nested:write('return 42'); nested:close()
                assert(dofile('nested.lua')==42)
                waitTime(0.01)
                print('host ok',Time.year)
            )lua");
            check(outcome.succeeded, outcome.message.c_str());
            check(!state.playing && state.plus_time.speed == 0 && state.rate_seconds_per_second == 1, "step/speed semantics");
            check(std::abs(state.camera_distance_au - 2) < 1e-12, "parsecs converted to AU");
            check(logs.count == 1 && [logs[0] containsString:@"host ok"], "script output");
            check([[NSString stringWithContentsOfURL:[directory URLByAppendingPathComponent:@"local-output.txt"] encoding:NSUTF8StringEncoding error:nil] isEqualToString:@"trusted"], "trusted local I/O");
            check([[NSString stringWithContentsOfURL:[directory URLByAppendingPathComponent:@"flushed-output.txt"] encoding:NSUTF8StringEncoding error:nil] isEqualToString:@"flushed"], "Lua close must flush files before completion");
            check(imageDialogs == 1, "image dialog dispatch");
            outcome = run(controller, file, @R"lua(
                assert(Planets.topoAmplification==1)
                for n=1,5 do
                    Planets.topoAmplification=n
                    assert(Planets.topoAmplification==n)
                end
                for _,v in ipairs({0,6,-1,1.5,math.huge,-math.huge,0/0,'1',true}) do
                    local previous=Planets.topoAmplification
                    local ok=pcall(function() Planets.topoAmplification=v end)
                    assert(not ok and Planets.topoAmplification==previous)
                end
            )lua");
            check(outcome.succeeded, outcome.message.c_str());
            check(state.terrain_amplification == TerrainAmplification::x20, "terrain action must carry typed value");
            state.terrain_amplification = TerrainAmplification::x2;
            outcome = run(controller, file, @"assert(Planets.topoAmplification==2)");
            check(outcome.succeeded, outcome.message.c_str());
            rejectTerrain = true;
            outcome = run(controller, file, @R"lua(
                local ok,err=pcall(function() Planets.topoAmplification=3 end)
                assert(not ok and string.find(err,'Terrain amplification unavailable',1,true))
                assert(Planets.topoAmplification==2)
            )lua");
            check(outcome.succeeded, outcome.message.c_str());
            rejectTerrain = false;
            outcome = run(controller, file, @R"lua(
                assert(Planets.scaleMode==mtk.KEEP_ORBIT)
                local a,b,c,d=Planets:getScale()
                assert(a==1 and b==1 and c==1 and d==1)
                assert(select('#',Planets:getScale())==4)
                Planets:setScale(500,2,20,5)
                a,b,c,d=Planets:getScale()
                assert(a==500 and b==2 and c==20 and d==5)
                Planets.scaleMode=mtk.KEEP_RADIUS; assert(Planets.scaleMode==mtk.KEEP_RADIUS)
                assert(Planets:getScaleMode()==mtk.KEEP_RADIUS)
                Planets:setScaleMode(mtk.KEEP_ORBIT); assert(Planets.scaleMode==mtk.KEEP_ORBIT)
                Planets:setScaleMode(mtk.KEEP_RADIUS)
                for _,v in ipairs({0,-1,math.huge,-math.huge,0/0,'1',true,1e100,1e-100}) do
                    for i=1,4 do
                        local args={2,3,4,5}; args[i]=v
                        assert(not pcall(function() Planets:setScale(table.unpack(args)) end))
                        a,b,c,d=Planets:getScale(); assert(a==500 and b==2 and c==20 and d==5)
                    end
                end
                for _,v in ipairs({-1,2,0.5,'1',true,math.huge}) do
                    assert(not pcall(function() Planets.scaleMode=v end))
                    assert(Planets.scaleMode==mtk.KEEP_RADIUS)
                end
                assert(not pcall(function() Planets:setScale(1,2,3) end))
                assert(not pcall(function() Planets:getScale(1) end))
                assert(not pcall(function() Planets.setScale(Stars,1,2,3,4) end))
            )lua");
            check(outcome.succeeded, outcome.message.c_str());
            check(state.radius_display.space_planet == 500 && state.radius_display.space_sun == 2 &&
                state.radius_display.planetarium_planet == 20 && state.radius_display.planetarium_sun_moon == 5 &&
                state.radius_scale_mode == RadiusScaleMode::keep_radius, "radius action preserves order and mode");
            state.radius_display = checked_radius_display_options(7, 8, 9, 10);
            outcome = run(controller, file, @"local a,b,c,d=Planets:getScale(); assert(a==7 and b==8 and c==9 and d==10)");
            check(outcome.succeeded, outcome.message.c_str());
            rejectRadius = true;
            outcome = run(controller, file, @R"lua(
                local ok,err=pcall(function() Planets:setScale(1,1,1,1) end)
                assert(not ok and string.find(err,'Radius unavailable',1,true))
                ok,err=pcall(function() Planets.scaleMode=mtk.KEEP_ORBIT end)
                assert(not ok and string.find(err,'Radius unavailable',1,true))
                local a,b,c,d=Planets:getScale()
                assert(a==7 and b==8 and c==9 and d==10 and Planets.scaleMode==mtk.KEEP_RADIUS)
            )lua");
            check(outcome.succeeded, outcome.message.c_str());
            rejectRadius = false;
            outcome = run(controller, file, @R"lua(
                local constants={STEP_SEC,STEP_10SEC,STEP_MIN,STEP_10MIN,STEP_HOUR,STEP_DAY,
                    STEP_WEEK,STEP_MONTH,STEP_YEAR,STEP_10YEAR,STEP_100YEAR,STEP_VALUE}
                local days={1/86400,10/86400,60/86400,600/86400,3600/86400,1,7,31,365,3650,36500,0}
                for i,value in ipairs(constants) do
                    assert(value==i-1); Time.step=value
                    assert(Time.step==value and math.abs(Time.stepValue-days[i])<=4*2^-52*math.abs(days[i]))
                end
                Time.stepValue=-0.25; assert(Time.step==STEP_VALUE and Time.stepValue==-0.25)
                Time:prevStep(); assert(Time.step==STEP_100YEAR and Time.stepValue==-0.25)
                Time:nextStep(); assert(Time.step==STEP_10YEAR and Time.stepValue==-0.25)
                Time.step=STEP_SEC; Time:prevStep(); assert(Time.step==STEP_SEC)
                Time:setTime(2024,1,31,12,30,0); Time.step=STEP_MONTH; Time:forward()
                assert(Time.year==2024 and Time.month==3 and Time.day==2 and Time.hour==12)
                Time:rewind(); assert(Time.month==2 and Time.day==2)
                Time:setTime(2024,2,29,0,0,0); Time.step=STEP_YEAR; Time:forward()
                assert(Time.year==2025 and Time.month==3 and Time.day==1)
                Time.month=0; assert(Time.year==2024 and Time.month==12 and Time.day==1)
                Time.day=0; assert(Time.month==11 and Time.day==30)
                Time:setTime(2000,1,1,0,0,2147483647)
                assert(Time.year==2068 and Time.month==1 and Time.day==19)
                Time:setTime(2000,1,1,0,0,0); Time.stepValue=0.5; Time:forward()
                assert(Time.hour==12); Time:rewind(); assert(Time.hour==0)
                Time.stepValue=0; Time.speed=2.9
                assert(Time.step==STEP_VALUE and Time.stepValue==0 and Time.speed==2)
                Time.speed=-2.9; assert(Time.speed==-2)
                Time.speed=-0.9; assert(Time.speed==0)
                for _,bad in ipairs({function() Time.step=12 end, function() Time.step=-1 end,
                    function() Time.step=0.5 end, function() Time.speed=2147483648 end,
                    function() Time.speed=-2147483649 end, function() Time.speed=true end,
                    function() Time.stepValue=0/0 end, function() Time.stepValue='1' end,
                    function() Time:setTime(2000,128,1,0,0,0) end,
                    function() Time:setTime(2000,1,1,0,0,0.5) end,
                    function() Time:setTime(2000,1,1,0,0,2147483648) end,
                    function() Time:forward(1) end, function() Time.forward(Stars) end,
                    function() Time:backward() end}) do
                    local jd=Time.JD; local step=Time.step; local value=Time.stepValue; local speed=Time.speed
                    assert(not pcall(bad))
                    assert(Time.JD==jd and Time.step==step and Time.stepValue==value and Time.speed==speed)
                end
                Time.stepValue=0.125; Time.speed=-3
            )lua");
            check(outcome.succeeded, outcome.message.c_str());
            outcome = run(controller, file, @"assert(Time.step==STEP_VALUE and Time.stepValue==0.125 and Time.speed==-3)");
            check(outcome.succeeded, "Time state must persist across worker processes");
            state.plus_time.step.select(PlusTimeStep::week); state.plus_time.speed = 7;
            outcome = run(controller, file, @"assert(Time.step==STEP_WEEK and Time.stepValue==7 and Time.speed==7)");
            check(outcome.succeeded, "Time getter must read current host state");
            rejectTime = true;
            outcome = run(controller, file, @R"lua(
                for _,attempt in ipairs({function() Time.step=STEP_DAY end,
                    function() Time.stepValue=1 end,function() Time.speed=1 end,
                    function() Time:prevStep() end,function() Time:nextStep() end,
                    function() Time:forward() end,function() Time:rewind() end}) do
                    local ok,err=pcall(attempt); assert(not ok and string.find(err,'Time update unavailable'))
                    assert(Time.step==STEP_WEEK and Time.stepValue==7 and Time.speed==7)
                end
            )lua");
            check(outcome.succeeded, outcome.message.c_str());
            rejectTime = false; state.plus_time.speed = 0; state.playing = false;
            outcome = run(controller,file,@R"lua(
                local bindings={
                    {Asteroids,'visible','toggle'},
                    {Asteroids,'labels','toggleLabels'},
                    {Asteroids,'orbits','toggleOrbits'},
                    {Asteroids,'selectedOnly','toggleSelectedOnly'},
                    {TNObjects,'visible','toggle'},
                    {TNObjects,'labels','toggleLabels'},
                    {TNObjects,'orbits','toggleOrbits'},
                    {TNObjects,'selectedOnly','toggleSelectedOnly'},
                    {Comets,'visible','toggle'},
                    {Comets,'labels','toggleLabels'},
                    {Comets,'orbits','toggleOrbits'},
                    {Comets,'selectedOnly','toggleSelectedOnly'},
                    {Satellites,'visible','toggle'},
                    {Satellites,'labels','toggleLabels'},
                    {Satellites,'orbits','toggleOrbits'},
                    {Satellites,'selectedOnly','toggleSelectedOnly'},
                    {Time,'realtime','toggleRealtime'}, {Time,'timeInfo','toggleTimeInfo'},
                    {Stars,'visible','toggle'}, {Stars,'labels','toggleLabels'},
                    {Stars,'bayerLabels','toggleBayerLabels'}, {Stars,'flamsteedLabels','toggleFlamsteedLabels'},
                    {Stars,'hipLabels','toggleHipLabels'},
                    {Planets,'visible','toggle'}, {Planets,'labels','toggleLabels'},
                    {Planets,'orbits','toggleOrbits'}, {Planets,'axes','toggleAxes'},
                    {Grids,'equatorial','toggleEquatorial'}, {Grids,'ecliptic','toggleEcliptic'},
                    {Grids,'galactic','toggleGalactic'}, {Grids,'horizontal','toggleHorizontal'},
                    {Grids,'circleScales','toggleCircleScales'}, {Grids,'squareScales','toggleSquareScales'},
                    {Renderer,'antialias','toggleAntialias'}, {Renderer,'pointSmooth','togglePointSmooth'},
                    {Renderer,'lineSmooth','toggleLineSmooth'}, {Renderer,'textSmooth','toggleTextSmooth'}
                }
                for _, binding in ipairs(bindings) do
                    local object,key,method=table.unpack(binding)
                    object[key]=true; assert(object[key])
                    assert(object[method](object)==nil); assert(not object[key])
                    assert(object[method](object)==nil); assert(object[key])
                    assert(not pcall(function() object[key]=1 end)); assert(object[key])
                    assert(not pcall(function() object[method](object,true) end)); assert(object[key])
                    object[key]=false; assert(not object[key])
                end
                for _, mode in ipairs({'Normal','Bright','Infrared','None'}) do
                    Milkyway.type=mode; assert(Milkyway.type==mode)
                end
                for _, mode in ipairs({'Binary','ExoPlanets','None'}) do
                    Stars.markingType=mode; assert(Stars.markingType==mode)
                end
            )lua");
            check(outcome.succeeded, outcome.message.c_str());
            outcome = run(controller,file,@R"lua(
                assert(Stars.brightness==1)
                Stars.brightness=2; assert(Stars.brightness==2)
                assert(Stars:brighten()==nil)
                assert(math.abs(Stars.brightness-2*10^(-0.2))<1e-6)
                assert(Stars:darken()==nil); assert(math.abs(Stars.brightness-2)<1e-6)
                assert(Stars:defaultBrightness()==nil); assert(Stars.brightness==1)
                assert(Stars:setBrightnessTo(4,2.5)==nil)
                assert(Stars.brightness==1)
            )lua");
            check(outcome.succeeded && brightnessTarget == 4 && brightnessDuration == 2.5,
                "brightness property, factors, default and timed action transport");
            state.stars.brightness = 3;
            outcome = run(controller,file,@"assert(Stars.brightness==3); Stars:setBrightnessTo(1,0)");
            check(outcome.succeeded && brightnessTarget == 1 && brightnessDuration == 0,
                "brightness getter reads host state and zero duration is preserved");
            const int beforeInvalidBrightness = applied;
            outcome = run(controller,file,@R"lua(
                local cases={
                    function() Stars.brightness=0 end, function() Stars.brightness=-1 end,
                    function() Stars.brightness=0/0 end, function() Stars.brightness=math.huge end,
                    function() Stars.brightness=1e100 end, function() Stars.brightness=1e-100 end,
                    function() Stars.brightness='1' end, function() Stars.brightness=true end,
                    function() Stars:setBrightnessTo(2,-1) end,
                    function() Stars:setBrightnessTo(2,math.huge) end,
                    function() Stars:setBrightnessTo(2,0/0) end,
                    function() Stars:setBrightnessTo(2,'1') end,
                    function() Stars:setBrightnessTo(0,1) end,
                    function() Stars:setBrightnessTo(2) end,
                    function() Stars:setBrightnessTo(2,1,true) end,
                    function() Stars.setBrightnessTo(Camera,2,1) end,
                    function() Stars:brighten(true) end,
                    function() Stars.darken(Camera) end,
                    function() Stars:defaultBrightness(1) end,
                    function() Stars:setBrightness(2,1) end
                }
                for _,call in ipairs(cases) do assert(not pcall(call)); assert(Stars.brightness==3) end
            )lua");
            check(outcome.succeeded && applied == beforeInvalidBrightness,
                "invalid brightness arguments must not dispatch or mutate host");
            rejectBrightness = true;
            for (NSString *source : @[@"Stars.brightness=2", @"Stars:brighten()", @"Stars:darken()",
                @"Stars:defaultBrightness()", @"Stars:setBrightnessTo(2,1)"]) {
                outcome = run(controller,file,source);
                check(!outcome.succeeded && outcome.message.find("Star brightness unavailable") != std::string::npos &&
                    state.stars.brightness == 3, "brightness host refusal reaches Lua without mutation");
            }
            rejectBrightness = false;
            outcome = run(controller,file,@R"lua(
                assert(not Constels.illusts and not Stars.selectedLabels)
                Constels.illusts=true; Stars.selectedLabels=true
                assert(Constels.illusts and Stars.selectedLabels)
                assert(Constels:toggleIllusts()==nil and Stars:toggleSelectedLabels()==nil)
                assert(not Constels.illusts and not Stars.selectedLabels)
                Stars.labels=false; Stars.visible=false
                assert(Stars:select(' 1  2 1 ')==nil)
                assert(Stars:isSelected('1') and Stars:isSelected('2') and not Stars:isSelected('3'))
                assert(Stars:select('3 999')==nil)
                assert(Stars:isSelected('3') and not Stars:isSelected('999'))
                assert(Stars:deselect('1 999')==nil)
                assert(not Stars:isSelected('1') and Stars:isSelected('2') and Stars:isSelected('3'))
                assert(Stars:deselect('All')==nil)
                assert(not Stars:isSelected('1') and not Stars:isSelected('2') and not Stars:isSelected('3'))
                assert(Stars:select('All')==nil)
                assert(Stars:isSelected('1') and Stars:isSelected('2') and Stars:isSelected('3'))
            )lua");
            check(outcome.succeeded && state.selected_star_names == std::set<std::int32_t>({1,2,3}),
                "star-name membership is additive, ignores unknown HIP, and remains independent of display flags");
            state.selected_star_names = {2}; state.constellation_illustrations = true;
            state.stars.selected_proper_names_only = true;
            outcome = run(controller,file,@"assert(not Stars:isSelected('1') and Stars:isSelected('2')); assert(Constels.illusts and Stars.selectedLabels)");
            check(outcome.succeeded, "selection and art getters read latest host state");
            const int beforeInvalidSelection = applied;
            outcome = run(controller,file,@R"lua(
                local cases={
                    function() Stars:select() end, function() Stars:deselect('1','2') end,
                    function() Stars:isSelected('1','2') end, function() Stars:select(1) end,
                    function() Stars:select('') end, function() Stars:select('   ') end,
                    function() Stars:select('1 bad') end, function() Stars:select('1\t2') end,
                    function() Stars:select('All 1') end, function() Stars:select('all') end,
                    function() Stars:select('0') end, function() Stars:select('-1') end,
                    function() Stars:select('+1') end, function() Stars:select('1.0') end,
                    function() Stars:select('2147483648') end, function() Stars:select('1e2') end,
                    function() Stars:select('1'..string.char(0)..'2') end,
                    function() Stars:isSelected('All') end, function() Stars:isSelected('1 2') end,
                    function() Stars.select(Constels,'1') end, function() Stars.isSelected(Constels,'2') end,
                    function() Constels.illusts=1 end, function() Stars.selectedLabels='true' end,
                    function() Constels:toggleIllusts(true) end, function() Stars.toggleSelectedLabels(Constels) end
                }
                for _,call in ipairs(cases) do assert(not pcall(call)) end
            )lua");
            check(outcome.succeeded && applied == beforeInvalidSelection && state.selected_star_names == std::set<std::int32_t>({2}),
                "invalid selection inputs never dispatch a partial mutation");
            rejectNameSelection = true;
            for (NSString *source : @[@"Constels.illusts=false", @"Stars.selectedLabels=false", @"Stars:select('1')",
                @"Stars:deselect('2')", @"Stars:select('All')", @"Stars:deselect('All')"]) {
                outcome = run(controller,file,source);
                check(!outcome.succeeded && outcome.message.find("Name selection unavailable") != std::string::npos &&
                    state.selected_star_names == std::set<std::int32_t>({2}), "selection host rejection reaches Lua without mutation");
            }
            rejectNameSelection = false;
            outcome = run(controller,file,@"assert(mtk.KEEP_RADIUS==0 and mtk.KEEP_ORBIT==1)");
            check(outcome.succeeded, "legacy radius scale mode constants are available to Lua");
            outcome = run(controller,file,@R"lua(
                assert(mtk.ATMOS_NONE==0 and mtk.ATMOS_SINGLE==1 and mtk.ATMOS_MULTIPLE==2)
                Planets.clouds=false; Planets.cityLights=true
                assert(not Planets.clouds and Planets.cityLights)
                assert(Planets:toggleClouds()==nil and Planets:toggleCityLights()==nil)
                assert(Planets.clouds and not Planets.cityLights)
                Planets.atmosphere=mtk.ATMOS_NONE; assert(Planets.atmosphere==mtk.ATMOS_NONE)
                assert(Planets:toggleAtmosphere()==nil); assert(Planets.atmosphere==mtk.ATMOS_SINGLE)
                Planets:toggleAtmosphere(); assert(Planets.atmosphere==mtk.ATMOS_MULTIPLE)
                Planets:toggleAtmosphere(); assert(Planets.atmosphere==mtk.ATMOS_NONE)
                Planets.atmosphere=mtk.ATMOS_MULTIPLE
            )lua");
            check(outcome.succeeded && state.earth_clouds && !state.earth_city_lights && state.atmosphere_mode == 2,
                "Earth layer flags and documented atmosphere constants and cycle dispatch");
            state.earth_clouds = false; state.earth_city_lights = true; state.atmosphere_mode = 1;
            outcome = run(controller,file,@"assert(not Planets.clouds and Planets.cityLights and Planets.atmosphere==mtk.ATMOS_SINGLE)");
            check(outcome.succeeded, "Earth layer getters read latest host state");
            const int beforeInvalidEarth = applied;
            outcome = run(controller,file,@R"lua(
                local cases={
                    function() Planets.clouds=1 end, function() Planets.cityLights='false' end,
                    function() Planets.atmosphere='1' end, function() Planets.atmosphere=true end,
                    function() Planets.atmosphere=-1 end, function() Planets.atmosphere=3 end,
                    function() Planets.atmosphere=1.5 end, function() Planets.atmosphere=0/0 end,
                    function() Planets.atmosphere=math.huge end, function() Planets.atmosphere=-math.huge end,
                    function() Planets:toggleAtmosphere(1) end, function() Planets.toggleAtmosphere(Stars) end,
                    function() Planets:toggleClouds(false) end, function() Planets.toggleCityLights(Stars) end,
                    function() Planets.intensity=6 end
                }
                for _,call in ipairs(cases) do assert(not pcall(call)) end
            )lua");
            check(outcome.succeeded && applied == beforeInvalidEarth,
                "invalid Earth layer and atmosphere inputs never dispatch");
            rejectEarthLayers = true;
            for (NSString *source : @[@"Planets.clouds=true", @"Planets.cityLights=false",
                @"Planets:toggleClouds()", @"Planets:toggleCityLights()", @"Planets.atmosphere=mtk.ATMOS_NONE",
                @"Planets:toggleAtmosphere()"]) {
                outcome = run(controller,file,source);
                check(!outcome.succeeded && outcome.message.find("Earth layers unavailable") != std::string::npos &&
                    !state.earth_clouds && state.earth_city_lights && state.atmosphere_mode == 1,
                    "Earth layer host rejection reaches Lua without mutation");
            }
            rejectEarthLayers = false;
            outcome = run(controller,file,@R"lua(
                local bindings={{Planets,'shadows','toggleShadows'},
                    {Planets,'shadowBorders','toggleShadowBorders'}, {Planets,'shadowUmbra','toggleShadowUmbra'},
                    {Planets,'shadowPenumbra','toggleShadowPenumbra'}, {Places,'landscape','toggleLandscape'}}
                for _,b in ipairs(bindings) do
                    local object,key,method=table.unpack(b)
                    object[key]=false; assert(not object[key])
                    assert(object[method](object)==nil and object[key])
                    object[method](); assert(not object[key])
                end
            )lua");
            check(outcome.succeeded && !state.eclipse.shadows && !state.eclipse.shadow_borders &&
                !state.eclipse.shadow_umbra && !state.eclipse.shadow_penumbra && !state.landscape,
                "independent eclipse and landscape properties and toggles dispatch");
            state.eclipse = {true,false,true,false}; state.landscape = true;
            outcome = run(controller,file,@"assert(Planets.shadows and not Planets.shadowBorders and Planets.shadowUmbra and not Planets.shadowPenumbra and Places.landscape)");
            check(outcome.succeeded, "eclipse and landscape getters observe external changes");
            const int beforeInvalidEclipse = applied;
            outcome = run(controller,file,@R"lua(
                local cases={function() Planets.shadows=1 end, function() Planets.shadowBorders='false' end,
                    function() Planets.shadowUmbra=nil end, function() Planets.shadowPenumbra={} end,
                    function() Places.landscape=0 end, function() Planets:toggleShadows(false) end,
                    function() Planets.toggleShadowBorders(Places) end, function() Planets:toggleShadowUmbra(1) end,
                    function() Planets.toggleShadowPenumbra(Stars) end, function() Places:toggleLandscape(true) end,
                    function() Places.toggleLandscape(Planets) end}
                for _,call in ipairs(cases) do assert(not pcall(call)) end
            )lua");
            check(outcome.succeeded && applied == beforeInvalidEclipse, "invalid eclipse and landscape inputs do not dispatch");
            rejectEclipseLandscape = true;
            for (NSString *source : @[@"Planets.shadows=false", @"Planets:toggleShadowBorders()",
                @"Planets.shadowUmbra=false", @"Planets:toggleShadowPenumbra()", @"Places:toggleLandscape()"]) {
                outcome = run(controller,file,source);
                check(!outcome.succeeded && outcome.message.find("Eclipse and landscape unavailable") != std::string::npos &&
                    state.eclipse.shadows && !state.eclipse.shadow_borders && state.eclipse.shadow_umbra &&
                    !state.eclipse.shadow_penumbra && state.landscape, "rejected eclipse and landscape action retains state");
            }
            rejectEclipseLandscape = false;
            outcome = run(controller,file,@R"lua(
                GUI.fullScreen=true; assert(GUI.fullScreen)
                GUI.fullScreen=false; assert(not GUI.fullScreen)
                assert(GUI:toggleFullScreen()==nil); assert(not GUI.fullScreen)
                assert(GUI:aboutDialog()==nil)
            )lua");
            check(outcome.succeeded && fullScreenToggles == 1 && aboutDialogs == 1,
                "dedicated asynchronous fullscreen toggle and About dispatch");
            rejectRenderer = true;
            for (NSString *source : @[@"Renderer.antialias=true", @"Renderer:toggleAntialias()",
                @"Renderer.pointSmooth=true", @"Renderer:togglePointSmooth()", @"Renderer.lineSmooth=true",
                @"Renderer:toggleLineSmooth()", @"Renderer.textSmooth=true", @"Renderer:toggleTextSmooth()"]) {
                outcome = run(controller,file,source);
                check(!outcome.succeeded && outcome.message.find("Renderer unavailable") != std::string::npos &&
                    !state.renderer.antialias && !state.renderer.point_smoothing &&
                    !state.renderer.line_smoothing && !state.renderer.text_smoothing,
                    "renderer host refusal must preserve state and reach Lua");
            }
            rejectRenderer = false;
            rejectFullScreen = true;
            for (NSString *source : @[@"GUI.fullScreen=true", @"GUI:toggleFullScreen()"]) {
                outcome = run(controller,file,source);
                check(!outcome.succeeded && outcome.message.find("transition in progress") != std::string::npos &&
                    !state.full_screen && fullScreenToggles == 1, "fullscreen host refusal must reach Lua");
            }
            rejectFullScreen = false;
            rejectClockTracking = true;
            outcome = run(controller,file,@"Time.realtime=true");
            check(!outcome.succeeded && outcome.message.find("Clock source unavailable") != std::string::npos &&
                !state.clock_tracking, "clock tracking failure must reach Lua");
            rejectClockTracking = false;
            outcome = run(controller,file,@"GUI:saveImageDialog()");
            check(!outcome.succeeded && outcome.message.find("already open") != std::string::npos, "image dialog host failure");
            // Lua が保持したフラグではなく、UIで変更された実状態を次の取得で反映する。
            state.stars.proper_names = true; state.nebulae = true; state.distant_galaxies = true;
            state.stars.marking = StarMarking::binary; state.milky_way_type = "Infrared";
            state.renderer = RendererDisplayOptions{}; state.full_screen = true;
            state.planets.axes = true; state.grids.galactic = true; state.time_info = true;
            state.quasars = true; state.target_browser = false; state.time_setting = false;
            state.place_setting = false; state.script_output = false; state.dual_screen = true;
            outcome = run(controller,file,@R"lua(
                assert(Stars.labels and Galaxies.NGCs and Galaxies.SDSS and Galaxies.QSOs)
                assert(not GUI.targetBrowser and not GUI.timeSetting and not GUI.placeSetting and not GUI.scriptOutput)
                assert(GUI.dualScreen and GUI.fullScreen)
                assert(Renderer.antialias and Renderer.pointSmooth and Renderer.lineSmooth and Renderer.textSmooth)
                assert(Stars.markingType=='Binary' and Milkyway.type=='Infrared')
                assert(Planets.axes and Grids.galactic and Time.timeInfo)
            )lua");
            check(outcome.succeeded, "live host snapshot");
            const int beforeInvalid = applied;
            outcome = run(controller,file,@"Constels.lines = 1");
            check(!outcome.succeeded && outcome.message.find("boolean") != std::string::npos, "invalid host argument");
            check(applied == beforeInvalid, "invalid arguments must not mutate host");
            for (NSString *invalid : @[@"Stars.labels='true'", @"Galaxies.NGCs=1", @"GUI.timeSetting=0",
                @"Camera.azimuth=0/0", @"GUI:toggleTargetBrowser(true)", @"GUI:saveImageDialog('file.png')",
                @"GUI.toggleTargetBrowser(io.stdout)", @"GUI.toggleTargetBrowser(Stars)", @"GUI.saveImageDialog(Camera)",
                @"GUI.dualScreen=true", @"GUI.projection=false", @"Stars.markingType='unknown'",
                @"Stars.markingType=true", @"Milkyway.type='normal'", @"Milkyway.type=1",
                @"Stars:toggleMarkingType()", @"Milkyway:toggleType()", @"Grids.surfacePointer=true",
                @"Galaxies.nearbyGalaxies=true", @"Renderer.antialias='true'", @"Renderer.pointSmooth=nil",
                @"Renderer.lineSmooth={}", @"Renderer.textSmooth=function() end", @"Renderer:toggleAntialias(1)",
                @"Renderer.togglePointSmooth(Stars)", @"Renderer.stereo=true", @"MitakaRenderer.antialias=false",
                @"GUI.fullScreen=1", @"GUI.fullScreen='false'", @"GUI.fullScreen=nil",
                @"GUI:toggleFullScreen(true)", @"GUI.toggleFullScreen(Renderer)",
                @"GUI:aboutDialog('title')", @"GUI.aboutDialog(Camera)"]) {
                outcome = run(controller,file,invalid);
                check(!outcome.succeeded && applied == beforeInvalid, "invalid or unsupported extension must not mutate host");
            }
            outcome = run(controller,file,@"Camera.target = 'not-a-target'");
            check(!outcome.succeeded && outcome.message.find("Unknown target") != std::string::npos && state.target == "Planet.Earth", "host rejects target");
            outcome = run(controller,file,@"Constels.unknown = true");
            check(!outcome.succeeded && outcome.message.find("Unsupported") != std::string::npos, "unsupported API cannot succeed");
            outcome = run(controller,file,@"this is not lua");
            check(!outcome.succeeded && outcome.message.find("test.lua") != std::string::npos, "syntax error with source location");
            outcome = run(controller,file,@"error({detail='not a string'})");
            check(!outcome.succeeded, "non-string Lua error");
            outcome = run(controller,file,@"while true do end");
            check(!outcome.succeeded && outcome.message.find("budget") != std::string::npos, "infinite loop instruction budget");
            outcome = run(controller,file,@"local s=string.rep('x', 100000000)");
            check(!outcome.succeeded, "Lua allocation budget");
            outcome = run(controller,file,@"os.execute('sleep 30')",true);
            check(!outcome.succeeded, "blocking subprocess cancellation");
            outcome = run(controller,file,@"waitTime(30)",true);
            check(!outcome.succeeded, "waitTime cancellation");
            outcome = run(controller,file,@"os.exit(0)");
            check(!outcome.succeeded, "os.exit terminates helper only");
            outcome = run(controller,file,@"Time.JD=2451545; print('recovered')");
            check(outcome.succeeded && state.julian_date == 2451545, "restart after failed scripts");
            check([[NSMutableData dataWithLength:1024*1024+1] writeToURL:file atomically:YES], "oversized fixture");
            NSError *error = nil;
            check(![controller runFile:file error:&error] && error != nil, "reject oversized source");
            check(![controller runFile:[NSURL URLWithString:@"https://example.com/a.lua"] error:&error], "reject network source");
            outcome = run(controller, file, @"Time.JD=2451546; print('html source')", false, true);
            check(outcome.succeeded && state.julian_date == 2451546, "inline source uses same host bridge");
            for (int iteration = 0; iteration < 12; ++iteration) {
                outcome = run(controller, file, @"print(debug.getinfo(1).source:sub(2))", false, true);
                check(outcome.succeeded, "short inline source completes");
                check(![NSFileManager.defaultManager fileExistsAtPath:logs.lastObject.stringByDeletingLastPathComponent], "inline temporary directory removed before completion");
            }
            outcome = run(controller, file, @"this is not Lua", false, true);
            check(!outcome.succeeded && outcome.message.find("html-link.lua") != std::string::npos, "inline source diagnostic");
            outcome = run(controller, file, @"waitTime(30)", true, true);
            check(!outcome.succeeded, "inline source cancellation");
            check(![controller runSource:@"" error:&error], "empty inline source rejected");
            check(![controller runSource:[@"x" stringByPaddingToLength:1024*1024+1 withString:@"x" startingAtIndex:0] error:&error], "oversized inline source rejected");
            [controller invalidate];
            check(![controller runSource:@"print('closed')" error:&error], "invalidated inline source rejected");
            [NSFileManager.defaultManager removeItemAtURL:directory error:nil];
            std::puts("Script controller tests passed");
            return 0;
        } catch (const std::exception& error) {
            std::fprintf(stderr, "Script controller tests failed: %s\n", error.what());
            return 1;
        }
    }
}
