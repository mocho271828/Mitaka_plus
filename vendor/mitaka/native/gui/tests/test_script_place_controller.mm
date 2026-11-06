#import "AppControllerInternal.h"
#import "../src/SolarSystemViewInternal.h"
#include <chrono>
#include <cmath>
#include <cstdio>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
static void require(bool ok, const char *message) { if (!ok) throw std::runtime_error(message); }

@interface SolarSystemView (SurfaceSkySelection)
- (void)applySurfaceSkyStar:(std::optional<std::size_t>)star constellation:(std::optional<std::size_t>)constellation;
@end

@interface SolarSystemView (PlaceIntegration)
- (void)fixtureSurface:(std::size_t)body;
- (BOOL)fixtureSkySelectionState:(int)kind;
@end
@implementation SolarSystemView (PlaceIntegration)
- (void)fixtureSurface:(std::size_t)body {
    _navigation.set_site(SurfaceSite{body, 0, 0, minimum_surface_height_km, 0, 0});
    _surfaceActive = YES; _physicalSpaceActive = NO; _journeyActive = NO;
    _camera = _navigation.camera(_bodies); _selection = body;
}
- (BOOL)fixtureSkySelectionState:(int)kind {
    _selection = 4; _smallBodySelection = 5; _satelliteSelection = 6; _spacecraftSelection = 7;
    _following = YES;
    [self setScriptEarthPlaceTarget:std::string("Planet.Mars.OlympusMons")];
    const std::optional<std::size_t> star = kind == 1 ? std::optional<std::size_t>(0) : std::nullopt;
    const std::optional<std::size_t> constellation = kind == 2 ? std::optional<std::size_t>(0) : std::nullopt;
    [self applySurfaceSkyStar:star constellation:constellation];
    if ([self selectedScriptConstellationInModel:nullptr]) return NO;
    if (constellation && [self selectedScriptConstellationInModel:_surfaceSkyModel] != constellation) return NO;
    return !_selection && !_smallBodySelection && !_satelliteSelection && !_spacecraftSelection && !_following &&
        [self scriptEarthPlaceTarget].empty() && _surfaceStarSelection == star && _surfaceConstellationSelection == constellation;
}
@end

@interface AppController (LookIntegrationMethods)
- (HorizonViewport)scriptCameraViewport;
- (BOOL)scriptLookViewport:(const ScriptLookTarget&)target result:(HorizonViewport *)result;
@end

@interface AppController (PlaceIntegration)
- (void)prepareFixture:(NSString *)root;
- (ScriptController *)fixtureScripts:(NSString *)helper;
- (void)fixtureSurface:(std::size_t)body;
- (void)fixtureDefaultPlaces:(NSString *)path;
- (void)fixtureHalfTransition;
- (BOOL)fixtureRetargeted;
- (std::int32_t)fixtureSkySelection:(int)kind;
- (HorizonViewport)fixtureExpectedLook;
- (HorizonViewport)fixtureLookStart;
- (void)fixturePauseLookAndAdvanceDate;
- (void)fixtureAdvanceLook:(double)seconds;
- (BOOL)fixtureIsLooking:(BOOL)animated;
- (SurfaceSite)fixtureSurfaceSite;
@end
@implementation AppController (PlaceIntegration)
- (void)prepareFixture:(NSString *)root {
    _model = std::make_shared<const SkyModel>(SkyModel::load(root.fileSystemRepresentation));
    _observerPlaces = std::make_shared<const ObserverPlaces>(load_observer_places(root.fileSystemRepresentation));
    _solarBodies = _model->solar_bodies(_jd);
    _mode = [NSSegmentedControl segmentedControlWithLabels:@[@"sky", @"space", @"horizon"] trackingMode:NSSegmentSwitchTrackingSelectOne target:nil action:NULL];
    _mode.selectedSegment = 1;
    _solar = [[SolarSystemView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    _sky = [[SkyView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    _horizon = [[HorizonView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    [_solar setBodies:_solarBodies];
    [_solar setSurfaceStarModel:_model catalogs:nullptr];
    [self configureScripts];
}
- (ScriptController *)fixtureScripts:(NSString *)helper {
    ScriptController *scripts = [[ScriptController alloc] initWithHelperURL:[NSURL fileURLWithPath:helper]];
    scripts.snapshot = _scripts.snapshot; scripts.applyAction = _scripts.applyAction;
    return scripts;
}
- (void)fixtureSurface:(std::size_t)body {
    [self stopScriptPlaceTransition]; [self stopScriptCameraAnimation]; [_solar fixtureSurface:body];
}
- (void)fixtureDefaultPlaces:(NSString *)path { _observerPlaces = std::make_shared<const ObserverPlaces>(load_observer_places(path.fileSystemRepresentation)); }
- (std::int32_t)fixtureSkySelection:(int)kind {
    require(!_model->stars().empty(), "real stars required");
    require([_solar fixtureSkySelectionState:kind], "sky selection must replace old target and stop following");
    return _model->stars().front().hip;
}
- (void)fixtureHalfTransition { require(_scriptPlaceTransition.has_value(), "transition missing"); _scriptPlaceTransition->start_time -= 50; }
- (BOOL)fixtureRetargeted {
    if (!_scriptPlaceTransition) return NO;
    SurfaceSite site;
    if (![_solar scriptSurfaceSite:&site]) return NO;
    const auto p = _scriptPlaceTransition->start;
    const double r = 3.14159265358979323846/180;
    return std::hypot(p.x-std::cos(site.latitude_deg*r)*std::cos(site.longitude_deg*r),
                      p.y-std::cos(site.latitude_deg*r)*std::sin(site.longitude_deg*r),
                      p.z-std::sin(site.latitude_deg*r)) < 0.0005
        && std::abs(site.latitude_deg) > 10 && std::abs(site.latitude_deg) < 80;
}
- (HorizonViewport)fixtureExpectedLook {
    HorizonViewport result;
    require(_scriptLookTarget && [self scriptLookViewport:*_scriptLookTarget result:&result], "look target unavailable");
    return result;
}
- (HorizonViewport)fixtureLookStart {
    require(_scriptAzimuthAnimation && _scriptAltitudeAnimation, "look animation missing");
    require(_scriptAzimuthAnimation->duration == 100 && _scriptAltitudeAnimation->duration == 100,
            "lookTo must use Camera.duration when omitted");
    auto result = [self scriptCameraViewport];
    result.center_azimuth_deg = _scriptAzimuthAnimation->start;
    result.center_altitude_deg = _scriptAltitudeAnimation->start;
    return result;
}
- (void)fixturePauseLookAndAdvanceDate {
    // メインループがまだ timer を処理していない状態で、天体の自転だけを進める。
    [_scriptCameraTimer invalidate]; _scriptCameraTimer = nil;
    _jd += 0.125;
    _solarBodies = _model->solar_bodies(_jd);
    [_solar setBodies:_solarBodies];
}
- (void)fixtureAdvanceLook:(double)seconds {
    [_scriptCameraTimer invalidate]; _scriptCameraTimer = nil;
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    if (_scriptAzimuthAnimation) _scriptAzimuthAnimation->start_time = now - seconds;
    if (_scriptAltitudeAnimation) _scriptAltitudeAnimation->start_time = now - seconds;
    [self updateScriptCameraAnimations];
}
- (BOOL)fixtureIsLooking:(BOOL)animated {
    return _scriptLookTarget.has_value() &&
        _scriptAzimuthAnimation.has_value() == static_cast<bool>(animated) &&
        _scriptAltitudeAnimation.has_value() == static_cast<bool>(animated);
}
- (SurfaceSite)fixtureSurfaceSite {
    SurfaceSite site;
    require([_solar scriptSurfaceSite:&site], "surface site missing");
    return site;
}
@end

static void run(ScriptController *scripts, NSString *source) {
    __block bool done = false, succeeded = false;
    __block NSString *failure = nil;
    scripts.completion = ^(BOOL ok, NSString *message) { succeeded = ok; failure = message; done = true; };
    NSError *error = nil;
    require([scripts runSource:source error:&error], error ? error.localizedDescription.UTF8String : "launch failed");
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:20];
    while (!done && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    require(done, "Lua timeout");
    require(succeeded, failure ? failure.UTF8String : "Lua failed");
}
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        try {
            require(argc == 3, "helper and data root required");
            [NSApplication sharedApplication];
            NSString *root = [NSString stringWithUTF8String:argv[2]];
            AppController *app = [[AppController alloc] initWithDataRoot:root smokeTest:NO];
            [app prepareFixture:root];
            NSString *helper = [NSString stringWithUTF8String:argv[1]];
            ScriptController *scripts = [app fixtureScripts:helper];
            run(scripts, @R"lua(
                Camera.target='Planet.Earth.Place_2'; assert(Camera.target=='Planet.Earth.Place_2')
                local ok=pcall(function() Camera.target='Planet.Mars.NorthPole' end)
                assert(not ok); assert(Camera.target=='Planet.Earth.Place_2')
            )lua");
            NSString *temporary = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
            NSFileManager *files = NSFileManager.defaultManager;
            require([files createDirectoryAtPath:temporary withIntermediateDirectories:YES attributes:nil error:nil], "temporary directory");
            NSString *source = [root stringByAppendingPathComponent:@"defaultplaces_jp.dat"];
            require([files createSymbolicLinkAtPath:[temporary stringByAppendingPathComponent:@"defaultplaces_jp.dat"] withDestinationPath:source error:nil], "read-only catalog link");
            [app fixtureDefaultPlaces:temporary];
            run(scripts, @R"lua(
                Camera.target='Planet.Earth.NorthPole'; assert(Camera.target=='Planet.Earth.NorthPole')
                Camera.target='Planet.Mars.OlympusMons'; assert(Camera.target=='Planet.Mars.OlympusMons')
                Camera.target='Satellite.Moon.NorthPole'; assert(Camera.target=='Satellite.Moon.NorthPole')
            )lua");
            [app fixtureSurface:4];
            run(scripts, @R"lua(
                Camera.target='Planet.Mars.OlympusMons'; assert(Camera.target=='Planet.Mars.OlympusMons')
                local ok=pcall(function() Camera.target='Satellite.Moon.NorthPole' end)
                assert(not ok); assert(Camera.target=='Planet.Mars.OlympusMons')
                Camera:setTargetTo('Planet.Mars.NorthPole', 100)
                assert(Camera.target=='Planet.Mars.NorthPole')
            )lua");
            [app fixtureHalfTransition];
            run(scripts, @"Camera:setTargetTo('Planet.Mars.OlympusMons', 100); assert(Camera.target=='Planet.Mars.OlympusMons')");
            require([app fixtureRetargeted], "retarget must start at intermediate position");
            [app fixtureSurface:3];
            run(scripts, @R"lua(
                Camera.target='Planet.Earth.SouthPole'; assert(Camera.target=='Planet.Earth.SouthPole')
                local ok=pcall(function() Camera.target='Planet.Mars.NorthPole' end)
                assert(not ok); assert(Camera.target=='Planet.Earth.SouthPole')
            )lua");
            [app fixtureSurface:10];
            run(scripts, @R"lua(
                Camera.target='Satellite.Moon.SouthPole'; assert(Camera.target=='Satellite.Moon.SouthPole')
                local ok=pcall(function() Camera.target='Planet.Earth.NorthPole' end)
                assert(not ok); assert(Camera.target=='Satellite.Moon.SouthPole')
            )lua");
            run(scripts, @"Targets.selectMode=mtk.SELECT_MOUSEOVER");
            const auto selectedHIP = [app fixtureSkySelection:1];
            run(scripts, [NSString stringWithFormat:@"assert(Camera.target=='Star.%d'); "
                 "Targets.selectMode=mtk.SELECT_NONE; assert(Camera.target=='Star.%d'); "
                 "Targets.selectMode=mtk.SELECT_MOUSECLICK; assert(Camera.target=='Star.%d')",
                 selectedHIP, selectedHIP, selectedHIP]);
            [app fixtureSkySelection:2];
            run(scripts, @R"lua(
                assert(Camera.target=='Constel.And')
                Camera:look(Camera.target)
                assert(Camera.target=='Constel.And')
                local ok=pcall(function() Camera.target='Constel.And' end)
                assert(not ok and Camera.target=='Constel.And')
            )lua");
            [app fixtureSkySelection:0];
            run(scripts, @"assert(Camera.target=='')");
            for (const auto body : {4u, 10u}) {
                [app fixtureSurface:body];
                [app fixtureSkySelection:2];
                const auto originalSite = [app fixtureSurfaceSite];
                run(scripts, @R"lua(
                    Camera.duration=100
                    Camera:lookTo('Constel.And',0)
                    assert(Camera.target=='Constel.And' and Camera.mode==mtk.PLANETARIUM)
                )lua");
                require([app fixtureIsLooking:NO], "zero-duration lookTo should retain tracking");
                [app fixturePauseLookAndAdvanceDate];
                const auto stale = [app scriptCameraViewport];
                const auto expectedStart = [app fixtureExpectedLook];
                require(std::abs(stale.center_altitude_deg - expectedStart.center_altitude_deg) > 0.01 ||
                        std::abs(std::remainder(stale.center_azimuth_deg - expectedStart.center_azimuth_deg, 360.0)) > 0.01,
                        "date update must move tracked constellation in the surface frame");
                run(scripts, @R"lua(
                    local az,alt,fov=Camera.azimuth,Camera.altitude,Camera.fov
                    for _,f in ipairs({
                        function() Camera:lookTo('Constel.DoesNotExist',100) end,
                        function() Camera:lookTo('Constel.and',100) end,
                        function() Camera:lookTo('Constel.Orion',-1) end,
                        function() Camera.target='Constel.Orion' end,
                        function() Camera:setTargetTo('Constel.Orion',100) end
                    }) do
                        assert(not pcall(f))
                        assert(Camera.target=='Constel.And' and Camera.mode==mtk.PLANETARIUM)
                        assert(Camera.azimuth==az and Camera.altitude==alt and Camera.fov==fov)
                    end
                )lua");
                require([app fixtureIsLooking:NO], "invalid requests must preserve constellation tracking");
                run(scripts, @"Camera:lookTo('Constel.Orion'); assert(Camera.target=='Constel.And')");
                const auto start = [app fixtureLookStart];
                require(std::abs(std::remainder(start.center_azimuth_deg - expectedStart.center_azimuth_deg, 360.0)) < 1e-8 &&
                        std::abs(start.center_altitude_deg - expectedStart.center_altitude_deg) < 1e-8,
                        "lookTo retarget must advance pending tracking before capturing its start");
                [app fixtureAdvanceLook:50];
                require([app fixtureIsLooking:YES], "lookTo must animate before the duration elapses");
                const auto destination = [app fixtureExpectedLook];
                const auto midpoint = [app scriptCameraViewport];
                const double azimuthSpan = std::remainder(destination.center_azimuth_deg - start.center_azimuth_deg, 360.0);
                require(std::abs(std::remainder(midpoint.center_azimuth_deg - start.center_azimuth_deg, 360.0) - azimuthSpan / 2) < 0.1 &&
                        std::abs(midpoint.center_altitude_deg - (start.center_altitude_deg + destination.center_altitude_deg) / 2) < 0.1,
                        "lookTo midpoint must interpolate toward the requested constellation");
                [app fixtureAdvanceLook:100];
                require([app fixtureIsLooking:NO], "completed lookTo should retain tracking");
                const auto finish = [app scriptCameraViewport];
                require(std::abs(std::remainder(finish.center_azimuth_deg - destination.center_azimuth_deg, 360.0)) < 1e-8 &&
                        std::abs(finish.center_altitude_deg - destination.center_altitude_deg) < 1e-8,
                        "completed lookTo must reach the constellation center");
                const auto finalSite = [app fixtureSurfaceSite];
                require(finalSite.body_index == originalSite.body_index && finalSite.latitude_deg == originalSite.latitude_deg &&
                        finalSite.longitude_deg == originalSite.longitude_deg && finalSite.height_km == originalSite.height_km,
                        "lookTo must preserve the surface observer");
                run(scripts, @"assert(Camera.target=='Constel.And'); Camera.azimuth=25");
                require(![app fixtureIsLooking:NO] && ![app fixtureIsLooking:YES], "manual orientation must stop look tracking");
            }
            [scripts invalidate];
            require([files removeItemAtPath:temporary error:nil], "remove temporary directory");
            std::puts("Lua place controller integration passed");
            return 0;
        } catch (const std::exception& e) { std::fprintf(stderr, "%s\n", e.what()); return 1; }
    }
}
