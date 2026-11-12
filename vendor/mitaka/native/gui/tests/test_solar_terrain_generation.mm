#import "../src/SolarSystemViewInternal.h"
#import "SolarDateUpdate.h"

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
    if (earth || moon || failureDiagnostic) _observations.push_back({scene.julian_date, scene.camera.yaw_deg,
        earth ? earth->request.data_directory.string() : "", coherent,
        earth && solar_terrain_frame(scene, 3) && earth->request.julian_date == scene.julian_date &&
            earth->request.camera.yaw_deg == scene.camera.yaw_deg,
        !moon, failureDiagnostic, earth ? earth->request.width : 0});
    [super redrawPublishedScene];
}
@end

@interface CountingGalaxyOverlay : GalaxyOverlay
@property(nonatomic) unsigned invalidations;
@end
@implementation CountingGalaxyOverlay
- (void)invalidatePendingPicks { ++_invalidations; [super invalidatePendingPicks]; }
@end

@interface SolarSystemView (OverlayFixture)
- (void)replaceOverlay:(GalaxyOverlay *)overlay;
@end
@implementation SolarSystemView (OverlayFixture)
- (void)replaceOverlay:(GalaxyOverlay *)overlay { _galaxyOverlay = overlay; }
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
void hoverInvalidatesPendingGalaxyPick() {
    PickSceneView *view = [[PickSceneView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    CountingGalaxyOverlay *overlay = [[CountingGalaxyOverlay alloc] initWithView:view];
    [view replaceOverlay:overlay];
    [view setBodies:SolarBodies{}];
    view.targetSelectionMode = 1;
    unsigned previous = overlay.invalidations;
    [view pickBodyAtPoint:NSMakePoint(-1, -1)];
    require(overlay.invalidations > previous, "outside map must invalidate a pending galaxy pick");
    previous = overlay.invalidations;
    NSEvent *exit = [NSEvent mouseEventWithType:NSEventTypeMouseMoved location:NSZeroPoint
        modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:0 pressure:0];
    [view mouseExited:exit];
    require(overlay.invalidations > previous, "leaving view must invalidate a pending hover pick");
    previous = overlay.invalidations;
    view.targetSelectionMode = 0;
    require(overlay.invalidations > previous, "mode change must invalidate a pending hover pick");
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
    SolarDateInput input{2451546, {35, 139}, bodies, false, {}, {}, nullptr, nullptr,
        prepare_satellite_scene(nullptr, nullptr), nullptr};
    auto candidate = [view prepareDateUpdate:input];
    [view commitDateUpdate:std::move(candidate)];
    [view finishDateUpdate];
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
void physicalSpaceDatePublication() {
    SolarBodies bodies{};
    const std::array<Body, 11> ids{Body::sun, Body::mercury, Body::venus, Body::earth, Body::mars,
        Body::jupiter, Body::saturn, Body::uranus, Body::neptune, Body::pluto, Body::moon};
    for (std::size_t i = 0; i < bodies.size(); ++i) {
        bodies[i].id = ids[i];
        bodies[i].position_au = {1, double(i), 0};
    }
    for (std::size_t body : {std::size_t{3}, std::size_t{4}}) {
        SolarSystemView *view = [[SolarSystemView alloc] initWithFrame:NSMakeRect(0, 0, 320, 240)];
        [view setBodies:bodies];
        view.planetDisplayOptions = {true, false, false, false};
        SurfaceSite site;
        site.body_index = body;
        NSString *error = nil;
        require([view forceSpaceFromHorizon:site error:&error], "enter physical space");
        require([view scene].physical_navigation, "live scene must use physical navigation");
        SolarDateInput input{2451546, {35, 139}, bodies, false, {}, {}, nullptr, nullptr,
            prepare_satellite_scene(nullptr, nullptr), nullptr};
        auto candidate = [view prepareDateUpdate:input];
        [view commitDateUpdate:std::move(candidate)];
        const auto published = [view displayedScene];
        require(published.julian_date == input.julian_date, "date candidate published");
        require(published.physical_navigation, "physical-space date publication must retain physical navigation");
        require(solar_terrain_request(published, body, "/tmp").has_value(),
                "physical-space date publication must retain terrain eligibility");
    }
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
    require([view displayedScene].julian_date == 2451545, "initial datum scene is published");
    advance(view, 2451546);
    require([view displayedScene].julian_date == 2451546, "manual date is visible before terrain completes");
    require(!solar_terrain_frame([view displayedScene], 3), "new date does not reuse old terrain");
    release(probe);
    start_count(probe, 2);
    require(probe->cancelled[0] == 1 && probe->cancelled[1] == 1 && [view observations].empty(),
        "late results from old date cannot publish");
    const auto dateCamera = [view cameraState];
    [view orbitByX:15 y:0]; [view refreshTerrain];
    [view orbitByX:15 y:0]; [view refreshTerrain];
    const auto latestCamera = [view cameraState];
    release(probe);
    waitFor([&] { return [view observations].size() == 1; }, "current date terrain publishes during movement");
    auto observed = [view observations];
    require(observed[0].date == 2451546 && observed[0].yaw == dateCamera.yaw_deg && observed[0].coherent,
        "terrain and camera remain coherent during movement");
    start_count(probe, 3);
    release(probe);
    waitFor([&] { return [view observations].size() == 2; }, "latest camera publishes");
    observed = [view observations];
    require(observed[1].date == 2451546 && observed[1].yaw == latestCamera.yaw_deg && observed[1].coherent,
        "latest camera and terrain match");
    require(firstCamera.yaw_deg != latestCamera.yaw_deg, "camera inputs were applied");

    [view orbitByX:15 y:0]; [view refreshTerrain];
    start_count(probe, 4);
    [view setTerrainDataDirectory:@"/selected/new"];
    [view refreshTerrain];
    release(probe);
    start_count(probe, 5);
    require(probe->cancelled[0] == 2 && probe->cancelled[1] == 2 && [view observations].size() == 2,
        "source change suppresses old callbacks");
    release(probe);
    waitFor([&] { return [view observations].size() == 3; }, "new source publishes");
    observed = [view observations];
    require(observed[2].root == "/selected/new" && observed[2].coherent, "new source matches scene");
    probe->failMoon = true;
    [view orbitByX:15 y:0]; [view refreshTerrain];
    start_count(probe, 6);
    release(probe);
    waitFor([&] { return [view observations].size() == 4; }, "failed body completes scene");
    observed = [view observations];
    require(observed[3].earthReady && observed[3].moonMissing && observed[3].failureDiagnostic,
        "failure publishes sphere and diagnostic alongside successful terrain");
    probe->failMoon = false;

    [view orbitByX:15 y:0]; [view refreshTerrain];
    start_count(probe, 7);
    [view setFrameSize:NSMakeSize(640, 480)]; [view refreshTerrain];
    require([view displayedScene].julian_date == 2451546, "resize baseline preserves date");
    release(probe);
    start_count(probe, 8);
    require(probe->cancelled[0] == 3 && probe->cancelled[1] == 3 && [view observations].size() == 4,
        "resize suppresses old callbacks");
    release(probe);
    waitFor([&] { return [view observations].size() == 5; }, "resized viewport publishes");
    observed = [view observations];
    require(observed[4].coherent && observed[4].width != observed[2].width,
        "resized viewport matches terrain");
    // 表示 A を保持したまま B が処理中に C の候補作成が失敗しても、B を後着公開しない。
    const auto beforeFailure = [view displayedScene];
    const auto beforeCamera = beforeFailure.camera;
    const double beforeDate = beforeFailure.julian_date;
    [view orbitByX:15 y:0]; [view refreshTerrain];
    start_count(probe, 9);
    auto invalid = std::make_shared<SmallBodySnapshot>();
    SolarDateInput input{2451547, {35, 139}, bodies, false, {}, {}, invalid, nullptr,
        prepare_satellite_scene(nullptr, nullptr), nullptr};
    bool failed = false;
    try { (void)[view prepareDateUpdate:input]; }
    catch (const std::invalid_argument&) { failed = true; [view invalidatePendingDateTerrain]; }
    require(failed, "invalid date candidate must fail before publication");
    release(probe);
    waitFor([&] { return probe->finished[0] == 9 && probe->finished[1] == 9; }, "cancelled workers finish");
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.02]];
    const auto afterFailure = [view displayedScene];
    require([view observations].size() == 5 && afterFailure.julian_date == beforeDate &&
        afterFailure.camera.yaw_deg == beforeCamera.yaw_deg,
        "failed date candidate cancels late result and retains published date and camera");
    start_count(probe, 10);
    release(probe);
    waitFor([&] { return [view observations].size() == 6; }, "displayed scene terrain retries after failure");
    const auto retry = [view displayedScene];
    require(retry.julian_date == beforeDate && retry.camera.yaw_deg == beforeCamera.yaw_deg &&
        solar_terrain_frame(retry, 3) && solar_terrain_frame(retry, 10),
        "retry restores terrain for the retained displayed scene");
    [view cancelTerrain];
}
}
int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            physicalSpaceDatePublication();
            tests();
            hoverInvalidatesPendingGalaxyPick();
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
