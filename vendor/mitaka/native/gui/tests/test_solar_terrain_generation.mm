#import "../src/SolarSystemViewInternal.h"

#include "shared_camera.hpp"
#include <atomic>
#include <iostream>

using namespace mitaka;
using namespace mitaka::gui;
using Snapshot = std::shared_ptr<const TerrainSurfaceSnapshot>;
using TerrainEvaluator = std::function<Snapshot(const TerrainSurfaceRequest&, std::uint64_t, const std::function<bool()>&)>;

namespace {
unsigned checks = 0;
void require(bool value, const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
template<class F> void waitFor(F condition, const char* message) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:10];
    while (!condition() && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.002]];
    require(condition(), message);
}
struct Probe {
    std::array<std::atomic<unsigned>, 4> started{};
    std::array<std::atomic<unsigned>, 4> finished{};
    std::array<std::atomic<unsigned>, 4> cancelled{};
    std::array<dispatch_semaphore_t, 4> permit;
    std::atomic<bool> failMoon{false};
    Probe() {
        for (auto& item : permit) item = dispatch_semaphore_create(0);
    }
};
struct Finished {
    std::shared_ptr<Probe> probe;
    std::size_t slot;
    ~Finished() { ++probe->finished[slot]; }
};
struct Observed {
    double date;
    double yaw;
    std::string root;
    bool coherent;
    bool earthReady;
    bool moonMissing;
    bool failureDiagnostic;
    int width;
};
}

@interface GenerationTerrainController : TerrainSurfaceController
- (instancetype)initWithProbe:(std::shared_ptr<Probe>)probe slot:(std::size_t)slot;
- (TerrainEvaluator)terrainEvaluator;
@end
@implementation GenerationTerrainController {
    std::shared_ptr<Probe> _probe;
    std::size_t _slot;
}
- (instancetype)initWithProbe:(std::shared_ptr<Probe>)probe slot:(std::size_t)slot {
    if ((self = [super init])) { _probe = std::move(probe); _slot = slot; }
    return self;
}
- (TerrainEvaluator)terrainEvaluator {
    const auto probe = _probe;
    const auto slot = _slot;
    return [probe, slot](const TerrainSurfaceRequest& request, std::uint64_t ticket,
                         const std::function<bool()>& cancelled) -> Snapshot {
        ++probe->started[slot];
        Finished finished{probe, slot};
        if (dispatch_semaphore_wait(probe->permit[slot], dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC)))
            throw std::runtime_error("test evaluator permit timed out");
        if (cancelled()) { ++probe->cancelled[slot]; throw TerrainSurfaceCancelled(); }
        if (slot == 1 && probe->failMoon) throw std::runtime_error("injected moon failure");
        auto value = std::make_shared<TerrainSurfaceSnapshot>();
        value->request = request;
        value->generation = ticket;
        value->status = TerrainSnapshotStatus::ready;
        value->frame.mode = TerrainSurfaceMode::none;
        return value;
    };
}
@end

@interface GenerationSolarView : SolarSystemView
- (void)setProbe:(std::shared_ptr<Probe>)probe;
- (std::vector<Observed>)observations;
@end
@implementation GenerationSolarView {
    std::shared_ptr<Probe> _probe;
    std::vector<Observed> _observations;
}
- (void)setProbe:(std::shared_ptr<Probe>)probe { _probe = std::move(probe); }
- (std::vector<Observed>)observations { return _observations; }
- (NSArray<TerrainSurfaceController *> *)makeTerrainControllers {
    NSMutableArray<TerrainSurfaceController *> *controllers = [NSMutableArray array];
    for (std::size_t slot = 0; slot < 4; ++slot)
        [controllers addObject:[[GenerationTerrainController alloc] initWithProbe:_probe slot:slot]];
    return controllers;
}
- (void)redrawPublishedScene {
    const auto scene = [self displayedScene];
    const auto earth = scene.terrain ? (*scene.terrain)[3] : nullptr;
    const auto moon = scene.terrain ? (*scene.terrain)[10] : nullptr;
    const bool coherent = earth && moon && solar_terrain_frame(scene, 3) && solar_terrain_frame(scene, 10) &&
        earth->request.julian_date == scene.julian_date && moon->request.julian_date == scene.julian_date &&
        earth->request.camera.yaw_deg == scene.camera.yaw_deg && moon->request.camera.yaw_deg == scene.camera.yaw_deg &&
        earth->request.data_directory == moon->request.data_directory;
    const auto diagnostics = [self terrainDiagnostics];
    const bool failureDiagnostic = std::any_of(diagnostics.begin(), diagnostics.end(), [](const std::string& diagnostic) {
        return diagnostic.find("injected moon failure") != std::string::npos;
    });
    _observations.push_back({scene.julian_date, scene.camera.yaw_deg,
        earth ? earth->request.data_directory.string() : "", coherent,
        earth && solar_terrain_frame(scene, 3) && earth->request.julian_date == scene.julian_date &&
            earth->request.camera.yaw_deg == scene.camera.yaw_deg,
        !moon, failureDiagnostic, earth ? earth->request.width : 0});
    [super redrawPublishedScene];
}
@end

@interface PickSceneView : SolarSystemView
@property(nonatomic) unsigned publications;
@end
@implementation PickSceneView
- (void)redrawPublishedScene { ++_publications; [super redrawPublishedScene]; }
@end

namespace {
void drawView(SolarSystemView *view) {
    NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:512 pixelsHigh:512 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
        isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:image];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    [view drawRect:view.bounds];
    [NSGraphicsContext restoreGraphicsState];
}
void clearSelectionWithoutGalaxyModel() {
    PickSceneView *view = [[PickSceneView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    SolarBodies bodies{};
    [view setBodies:bodies];
    [view selectBody:0];
    drawView(view);
    require([view displayedScene].selection == std::optional<std::size_t>{0},
        "initial body selection must be published");
    const auto map = [view mapRect];
    [view pickBodyAtPoint:NSMakePoint(NSMinX(map) + 1, NSMinY(map) + 1)];
    require(view.selectedBodyIndex == NSNotFound, "blank click clears live body selection without galaxy model");
    drawView(view);
    require(![view displayedScene].selection, "blank click publishes cleared selection without galaxy model");
}
void spatialPickAcrossScenePublication(bool hip) {
    PickSceneView *view = [[PickSceneView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    SolarBodies bodies{};
    [view setBodies:bodies];
    view.planetDisplayOptions = {false, false, false, false};
    const GalaxyCameraPc galaxyCamera{{0, 0, 0}, 0, 0, 10};
    [view setCameraState:solar_camera_from_shared(shared_camera_from_galaxy(galaxyCamera))];
    NativeEclipticPositionPc position{0, 0, 0};
    if (hip) {
        auto model = std::make_shared<HipSpatialModel>();
        model->points.push_back({0, 1, position});
        [view setHipModel:model];
    } else {
        auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
            std::vector<SdssSpatialSource>{{SdssKind::galaxy, "fixture", {{{0, 0}, 1, 0}}}}));
        auto model = std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{GalaxySdssSource{snapshot, 0}});
        position = *model->row({GalaxySpatialFamily::sdss_galaxy, 0, 0}).position;
        [view setGalaxyModel:model];
    }
    waitFor([&] { drawView(view); return [view galaxyOverlayDiagnostics].display == GalaxyOverlayDisplay::complete; },
        "spatial fixture did not finish drawing");
    const auto map = [view mapRect];
    const auto projected = GalaxyProjector(galaxyCamera, map.size.width, map.size.height).project(position);
    require(projected.has_value(), "spatial fixture has a visible point");
    const NSPoint click = NSMakePoint(map.origin.x + projected->x, map.origin.y + projected->y);
    [view pickBodyAtPoint:click];
    const auto oldPublications = view.publications;
    [view setObservationSite:{35, 139} julianDate:2451546];
    drawView(view);
    require(view.publications > oldPublications, "same camera scene published while pick was pending");
    waitFor([&] { return hip ? [view selectedHipIndex].has_value() : [view selectedGalaxyRecord].has_value(); },
        "spatial selection was lost across same camera publication");
    require(hip ? [view selectedHipIndex] == std::optional<std::size_t>{0}
                : [view selectedGalaxyRecord] == std::optional<GalaxySpatialRecordId>{{GalaxySpatialFamily::sdss_galaxy, 0, 0}},
        "spatial pick retained the correct identity");

    [view pickBodyAtPoint:click];
    [view orbitByX:30 y:0];
    drawView(view);
    waitFor([&] { drawView(view); return [view galaxyOverlayDiagnostics].display == GalaxyOverlayDisplay::complete; },
        "changed camera did not finish drawing");
    require(![view selectedHipIndex] && ![view selectedGalaxyRecord], "changed camera must discard the old spatial pick");
}
void release(const std::shared_ptr<Probe>& probe) {
    dispatch_semaphore_signal(probe->permit[0]);
    dispatch_semaphore_signal(probe->permit[1]);
}
void start_count(const std::shared_ptr<Probe>& probe, unsigned value) {
    waitFor([&] { return probe->started[0] == value && probe->started[1] == value; },
        "both selected terrain workers should start");
}
void advance(GenerationSolarView *view, double date) {
    [view beginSceneUpdate];
    [view setObservationSite:{35, 139} julianDate:date];
    [view orbitByX:15 y:0];
    [view endSceneUpdate];
    [view refreshTerrain];
}
void tests() {
    const auto probe = std::make_shared<Probe>();
    GenerationSolarView *view = [[GenerationSolarView alloc] initWithFrame:NSMakeRect(0, 0, 320, 240)];
    [view setProbe:probe];
    SolarBodies bodies{};
    const std::array<Body, 11> ids{Body::sun, Body::mercury, Body::venus, Body::earth, Body::mars,
        Body::jupiter, Body::saturn, Body::uranus, Body::neptune, Body::pluto, Body::moon};
    for (std::size_t i = 0; i < bodies.size(); ++i) {
        bodies[i].id = ids[i];
        bodies[i].position_au = {1, 100 + double(i), 0};
    }
    bodies[0].position_au = {0, 0, 0};
    bodies[3].position_au = {1, 0, 0};
    bodies[10].position_au = {1.0026, 0, 0};
    [view setBodies:bodies];
    view.planetDisplayOptions = {true, false, false, false};
    [view setTerrainDataDirectory:@"/selected/old"];
    [view showEarthMoon];
    [view setObservationSite:{35, 139} julianDate:2451545];
    const auto firstCamera = [view cameraState];
    [view refreshTerrain];
    start_count(probe, 1);
    advance(view, 2451546);
    advance(view, 2451547);
    const auto latestCamera = [view cameraState];
    require(firstCamera.yaw_deg != latestCamera.yaw_deg && [view observations].empty(), "A is held while B and C input accumulates");
    dispatch_semaphore_signal(probe->permit[1]);
    waitFor([&] { return probe->finished[1] == 1; }, "moon completed");
    require([view observations].empty(), "one body cannot publish a partial scene");
    dispatch_semaphore_signal(probe->permit[0]);
    waitFor([&] { return [view observations].size() == 1; }, "A publishes while input remains active");
    auto observed = [view observations];
    require(observed[0].date == 2451545 && observed[0].yaw == firstCamera.yaw_deg && observed[0].coherent,
        "A terrain, camera and date are one scene");
    start_count(probe, 2);
    require([view displayedScene].camera.yaw_deg == firstCamera.yaw_deg, "A remains displayed during C preparation");
    release(probe);
    waitFor([&] { return [view observations].size() == 2; }, "C publishes");
    observed = [view observations];
    require(observed[1].date == 2451547 && observed[1].yaw == latestCamera.yaw_deg && observed[1].coherent,
        "C is latest input, with matching terrain and camera");
    require(probe->started[0] == 2 && probe->started[1] == 2, "B was coalesced");

    advance(view, 2451548);
    start_count(probe, 3);
    [view setTerrainDataDirectory:@"/selected/new"];
    advance(view, 2451549);
    release(probe);
    start_count(probe, 4);
    require(probe->cancelled[0] == 1 && probe->cancelled[1] == 1 && [view observations].size() == 2,
        "source change cancels and suppresses old callbacks");
    release(probe);
    waitFor([&] { return [view observations].size() == 3; }, "new source publishes");
    observed = [view observations];
    require(observed[2].date == 2451549 && observed[2].root == "/selected/new" && observed[2].coherent,
        "new source publishes only its matching scene");
    probe->failMoon = true;
    advance(view, 2451550);
    start_count(probe, 5);
    release(probe);
    waitFor([&] { return [view observations].size() == 4; }, "failed body still completes its scene");
    observed = [view observations];
    require(observed[3].date == 2451550 && observed[3].earthReady && observed[3].moonMissing &&
        observed[3].failureDiagnostic, "one failed body and the other successful body publish together with diagnostic");
    probe->failMoon = false;

    advance(view, 2451551);
    start_count(probe, 6);
    [view setFrameSize:NSMakeSize(640, 480)];
    advance(view, 2451552);
    release(probe);
    start_count(probe, 7);
    require(probe->cancelled[0] == 2 && probe->cancelled[1] == 2 && [view observations].size() == 4,
        "viewport change cancels and suppresses old callbacks");
    release(probe);
    waitFor([&] { return [view observations].size() == 5; }, "resized viewport publishes");
    observed = [view observations];
    require(observed[4].date == 2451552 && observed[4].coherent && observed[4].width != observed[2].width,
        "resized viewport publishes its matching scene and terrain");
    [view cancelTerrain];
}
}
int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            tests();
            clearSelectionWithoutGalaxyModel();
            spatialPickAcrossScenePublication(true);
            spatialPickAcrossScenePublication(false);
            std::cout << "solar terrain generation: " << checks << " checks passed\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "solar terrain generation: " << error.what() << '\n';
            return 1;
        }
    }
}
