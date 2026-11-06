#import "AppControllerInternal.h"
#import "../src/SolarSystemViewInternal.h"
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

@interface AppController (PlaceIntegration)
- (void)prepareFixture:(NSString *)root;
- (ScriptController *)fixtureScripts:(NSString *)helper;
- (void)fixtureSurface:(std::size_t)body;
- (void)fixtureDefaultPlaces:(NSString *)path;
- (void)fixtureHalfTransition;
- (BOOL)fixtureRetargeted;
- (std::int32_t)fixtureSkySelection:(int)kind;
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
- (void)fixtureSurface:(std::size_t)body { [self stopScriptPlaceTransition]; [_solar fixtureSurface:body]; }
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
            [scripts invalidate];
            require([files removeItemAtPath:temporary error:nil], "remove temporary directory");
            std::puts("Lua place controller integration passed");
            return 0;
        } catch (const std::exception& e) { std::fprintf(stderr, "%s\n", e.what()); return 1; }
    }
}
