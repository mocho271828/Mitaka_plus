#import "../src/SolarSystemViewInternal.h"
#import "SmallBodyRenderer.h"
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
@interface SolarSystemView (SmallBodyPickingPrivate)
- (void)pickBodyAtPoint:(NSPoint)point;
- (void)updateScriptZoomAtTime:(double)now;
@end
@interface SolarSystemView (SmallBodyPickingTests)
- (BOOL)zoomNavigationRegression;
- (BOOL)zoomCollisionRegression;
- (BOOL)scriptOtherBodyPlaceRegression;
@end
@implementation SolarSystemView (SmallBodyPickingTests)
- (BOOL)zoomNavigationRegression {
    NSString *error = nil;
    _camera = SolarCamera{};
    _camera.frame = solar_camera_basis(_camera);
    _camera.frame_is_orbit = false;
    _physicalSpaceActive = YES;
    _camera.distance_au = 1e-8;
    const BOOL rejectedInitial = ![self animateScriptZoomTo:1 duration:0 logarithmic:NO error:&error]
        && _physicalSpaceActive && _camera.distance_au == 1e-8 && error.length > 0;
    _camera.distance_au = 1;
    error = nil;
    const BOOL rejectedTarget = ![self animateScriptZoomTo:1e-11 duration:0 logarithmic:NO error:&error]
        && _physicalSpaceActive && _camera.distance_au == 1 && error.length > 0;
    const auto before = solar_camera_basis(_camera);
    const auto target = _camera.target;
    const BOOL accepted = [self animateScriptZoomTo:2 duration:0 logarithmic:NO error:&error];
    const auto after = solar_camera_basis(_camera);
    const BOOL preserved = accepted && !_physicalSpaceActive && _camera.frame_is_orbit && _camera.distance_au == 2
        && std::hypot(before.outward.x-after.outward.x, before.outward.y-after.outward.y, before.outward.z-after.outward.z) < 1e-12
        && std::hypot(target.x-_camera.target.x, target.y-_camera.target.y, target.z-_camera.target.z) < 1e-12;
    _surfaceActive = YES;
    error = nil;
    const BOOL rejectedSurface = ![self animateScriptZoomTo:3 duration:0 logarithmic:NO error:&error]
        && _surfaceActive && _camera.distance_au == 2 && error.length > 0;
    _surfaceActive = NO;
    return rejectedInitial && rejectedTarget && preserved && rejectedSurface;
}
- (BOOL)scriptOtherBodyPlaceRegression {
    NSString *error = nil;
    for (const std::size_t body : {std::size_t(4), std::size_t(10)}) {
        if (![self selectScriptPlaceBody:body latitude:17 longitude:23 surface:NO error:&error]
            || !_scriptSpacePlace || _scriptSpacePlace->body_index != body || !_following) return NO;
        const auto oldTarget = _camera.target;
        auto moved = _bodies;
        moved[body].position_au.x += 1;
        [self setBodies:moved];
        if (std::abs(_camera.target.x - oldTarget.x - 1) > 1e-9) return NO;
        _navigation.set_site(SurfaceSite{body, 4, 6, minimum_surface_height_km, 0, 0});
        _surfaceActive = YES;
        _camera = _navigation.camera(_bodies);
        if (![self selectScriptPlaceBody:body latitude:-8 longitude:179 surface:YES error:&error]) return NO;
        SurfaceSite result;
        if (![self scriptSurfaceSite:&result] || result.body_index != body
            || result.latitude_deg != -8 || result.longitude_deg != 179) return NO;
        if ([self selectScriptPlaceBody:3 latitude:0 longitude:0 surface:YES error:&error]) return NO;
        SurfaceSite after;
        if (![self scriptSurfaceSite:&after] || after.body_index != body || after.latitude_deg != -8) return NO;
        if (![self moveScriptSurfaceBody:body latitude:10 longitude:-179]) return NO;
        if ([self moveScriptSurfaceBody:3 latitude:20 longitude:0]) return NO;
        if (![self scriptSurfaceSite:&after] || after.latitude_deg != 10 || after.longitude_deg != -179) return NO;
        if ([self selectScriptPlaceBody:body latitude:91 longitude:0 surface:YES error:&error]) return NO;
        if (![self scriptSurfaceSite:&after] || after.latitude_deg != 10) return NO;
        _surfaceActive = NO;
    }
    return YES;
}
- (BOOL)zoomCollisionRegression {
    _earthMoonMode = YES;
    _camera = SolarCamera{};
    _camera.target = [self displayPosition:3];
    _camera.distance_au = 0.001;
    NSString *error = nil;
    const BOOL instant = [self animateScriptZoomTo:0.000005 duration:0 logarithmic:NO error:&error]
        && _camera.distance_au > 0.000005;
    _camera.distance_au = 0.001;
    const BOOL started = [self animateScriptZoomTo:0.000005 duration:1 logarithmic:NO error:&error];
    [self updateScriptZoomAtTime:1e12];
    const BOOL animated = _camera.distance_au > 0.000005 && !_zoomAnimation;
    _earthMoonMode = NO;
    return instant && started && animated;
}
@end
namespace {
unsigned checks = 0;
void require(bool value, const char *message) { ++checks; if (!value) throw std::runtime_error(message); }
bool same(Vec3 a, Vec3 b) { return std::hypot(a.x-b.x, a.y-b.y, a.z-b.z) < 1e-12; }
void nearby_galaxy_radius_tests() {
    PlusNearbyGalaxyCatalog catalog{{"NBG fixture", {}}, {}};
    for (const float diameter : {120.0f, 0.0f, -1.0f, std::numeric_limits<float>::quiet_NaN(),
                                 std::numeric_limits<float>::infinity(), 10800.0f}) {
        PlusNearbyGalaxyRecord record;
        record.distance_pc = 100.0f;
        record.angular_diameter_arcminutes = diameter;
        catalog.records.push_back(record);
    }
    auto model = std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{catalog});
    SolarSystemView *view = [[SolarSystemView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    [view setGalaxyModel:model];
    NSString *error = nil;
    require([view selectScriptGalaxyRecord:{GalaxySpatialFamily::nearby_galaxy, 0, 0} error:&error],
        "valid nearby galaxy can be selected");
    constexpr double pi = 3.14159265358979323846;
    const double expected = 100.0 * (pi / 180.0) * astronomical_units_per_parsec;
    const auto radius = [view scriptTargetRadiusAU];
    require(radius && std::abs(*radius / expected - 1.0) < 1e-12,
        "120 arcminute diameter yields one degree angular radius");
    [view applyScriptZoomMode:2 previousRadius:std::nullopt initialDistance:1.0];
    require(std::abs([view cameraState].distance_au / (9.0 * expected) - 1.0) < 1e-12,
        "always zoom uses nine times nearby galaxy radius");
    [view applyScriptZoomMode:1 previousRadius:expected / 2.0 initialDistance:42.0];
    require(std::abs([view cameraState].distance_au / (9.0 * expected) - 1.0) < 1e-12,
        "auto zoom expands when the new target is larger");
    [view applyScriptZoomMode:1 previousRadius:expected * 2.0 initialDistance:42.0];
    require([view cameraState].distance_au == 42.0, "auto zoom preserves distance for a smaller target");
    for (std::size_t row = 1; row < catalog.records.size(); ++row) {
        require([view selectScriptGalaxyRecord:{GalaxySpatialFamily::nearby_galaxy, 0, row} error:&error],
            "boundary fixture with valid position can be selected");
        require(![view scriptTargetRadiusAU], "invalid diameter has no known radius");
        [view applyScriptZoomMode:2 previousRadius:std::nullopt initialDistance:42.0];
        require([view cameraState].distance_au == 42.0, "unknown radius retains initial distance");
    }
}
void galaxy_identity_tests() {
    PlusGlobularClusterCatalog gc{{"globular_cluster.dat", {}}, {}};
    PlusGlobularClusterRecord cluster;
    constexpr char name[] = "NGC 6205";
    std::copy(name, name + sizeof(name) - 1, cluster.name_bytes.begin());
    cluster.distance_pc = 100;
    gc.records.push_back(cluster);
    PlusNearbyGalaxyCatalog nbg{{"NBG.dat", {}}, {}};
    PlusNearbyGalaxyRecord galaxy;
    galaxy.distance_pc = 710000;
    galaxy.catalog_code = 'N';
    galaxy.catalog_number = 224;
    nbg.records.push_back(galaxy);
    auto model = std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{gc, nbg});
    SolarSystemView *view = [[SolarSystemView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    [view setGalaxyModel:model];
    __block NSString *description = nil;
    view.selectionChanged = ^(NSString *text) { description = text; };
    NSString *error = nil;
    require([view selectScriptGalaxyRecord:{GalaxySpatialFamily::globular_cluster, 0, 0} error:&error] &&
        [description containsString:@"NGC 6205"] && [description containsString:@"原行 1"],
        "GC selection displays its original name and source row");
    require([view selectScriptGalaxyRecord:{GalaxySpatialFamily::nearby_galaxy, 1, 0} error:&error] &&
        [description containsString:@"原 ID N224"] && [description containsString:@"出典 2"],
        "nearby galaxy selection displays its original code, number and source");
}
void minor_planet_orbit_tests() {
    auto dataset = std::make_shared<SmallBodyDataset>();
    SmallBodyRecord asteroid;
    asteroid.id = {"mp.dat", 0};
    asteroid.kind = SmallBodyKind::asteroid;
    asteroid.encoding = SmallBodyEncoding::packed_36;
    dataset->records.push_back(asteroid);
    auto tno = asteroid;
    tno.id = {"TNO.dat", 0};
    tno.kind = SmallBodyKind::trans_neptunian;
    dataset->records.push_back(tno);
    dataset->sources.push_back({"mp.dat", {}, "asteroid-fixture", 1, true});
    dataset->sources.push_back({"TNO.dat", {}, "tno-fixture", 1, true});
    auto model = std::make_shared<SmallBodyModel>(dataset);
    auto display = std::make_shared<SmallBodyDisplayModel>(dataset);
    display->set_kind_options(SmallBodyKind::asteroid, {true, false, true, false});
    display->set_kind_options(SmallBodyKind::trans_neptunian, {true, false, true, false});
    SmallBodySnapshot frame;
    frame.model = model;
    frame.positions.resize(dataset->records.size());
    SmallBodyOrbitSnapshot orbits;
    orbits.model = model;
    orbits.display = display;
    orbits.paths.resize(dataset->records.size());
    orbits.minor_planet_paths.resize(dataset->records.size());
    MinorPlanetOrbitPath path;
    path.id = asteroid.id;
    path.samples = {{1, Vec3{0.1, 0.2, 0.1}}, {2, Vec3{0.3, 0.4, 0.2}},
                    {3, std::nullopt}, {4, Vec3{0.5, 0.6, 0.3}}, {5, Vec3{0.7, 0.8, 0.4}}};
    orbits.minor_planet_paths[0] = path;
    path.id = tno.id;
    orbits.minor_planet_paths[1] = path;
    SolarCamera camera;
    camera.distance_au = 7;
    const NSRect map = NSMakeRect(18, 40, 760, 520);
    std::vector<SmallBodyProjectedOrbitSegment> segments;
    const auto collect = [&] {
        segments.clear();
        visit_small_body_orbit_segments(frame, *display, &orbits, camera, map,
            [&](const auto& segment) { segments.push_back(segment); });
    };
    collect();
    require(segments.size() == 4 && segments[0].index == 0 && segments[2].index == 1,
        "asteroid and TNO use their original rows and do not bridge missing samples");
    const auto expected = project_solar_segment(*path.samples[0].position, *path.samples[1].position,
        camera, map.size.width, map.size.height);
    require(expected && std::abs(segments[0].first.x - (*expected)[0].x - map.origin.x) < 1e-10
        && std::abs(segments[0].second.y - (*expected)[1].y - map.origin.y) < 1e-10,
        "packed36 orbit lines use the shared heliocentric projection");
    display->set_kind_options(SmallBodyKind::asteroid, {true, false, false, false});
    collect();
    require(segments.size() == 2 && segments[0].index == 1, "asteroid orbit toggle leaves TNO lines visible");
    display->set_kind_options(SmallBodyKind::asteroid, {true, false, true, false});
    orbits.minor_planet_paths[0]->id.record_ordinal = 2;
    collect();
    require(segments.size() == 2 && segments[0].index == 1, "packed36 path rejects incorrect original row identity");
    orbits.minor_planet_paths[0]->id = asteroid.id;
    orbits.minor_planet_paths[0]->cancelled = true;
    collect();
    require(segments.size() == 2 && segments[0].index == 1, "cancelled partial packed36 paths are not drawn");
    orbits.cancelled = true;
    collect();
    require(segments.empty(), "cancelled whole snapshot is not drawn");
}
void tests() {
    auto dataset = std::make_shared<SmallBodyDataset>();
    SmallBodyRecord record;
    record.id = {"comets.dat", 0};
    record.kind = SmallBodyKind::comet;
    record.frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
    record.time_scale = SmallBodyTimeScale::tdb;
    record.name_bytes = "test comet";
    record.orbit = PerihelionElements{1, 0.5, 2451545, 0, 0, 0};
    dataset->records.push_back(record);
    record.id.record_ordinal = 1;
    record.frame = SmallBodyFrame::unresolved;
    dataset->records.push_back(record);
    dataset->sources.push_back({"comets.dat", {}, "two-original-comet-records", 2, true});
    auto model = std::make_shared<SmallBodyModel>(dataset);
    auto display = std::make_shared<SmallBodyDisplayModel>(dataset);
    auto frame = evaluate_small_body_snapshot(model, 2451545);
    SolarCamera camera;
    camera.distance_au = 7;
    const NSRect map = NSMakeRect(18, 40, 760, 520);
    auto projected = visible_small_bodies(*frame, *display, camera, map);
    require(projected.size() == 1 && projected[0].index == 0, "only evaluated original rows are projected");
    const auto point = projected[0].point;
    auto picked = pick_small_body(*frame, *display, camera, map, NSMakePoint(point.x, point.y));
    require(picked == 0, "render and picking share the same projection");
    require(!pick_small_body(*frame, *display, camera, map, NSMakePoint(0, 0)), "outside map cannot select hidden records");
    require(visible_small_bodies(*frame, *display, camera, NSZeroRect).empty(), "empty viewport has no projected rows");
    display->set_kind_options(SmallBodyKind::comet, {true, true, true, true});
    require(visible_small_bodies(*frame, *display, camera, map).empty()
        && !pick_small_body(*frame, *display, camera, map, NSMakePoint(point.x, point.y)),
        "empty display membership suppresses both markers and picking");
    display->set_selected_ids({dataset->records[0].id});
    require(visible_small_bodies(*frame, *display, camera, map).size() == 1,
        "explicit display membership makes the original row visible");
    auto orbits = std::make_shared<SmallBodyOrbitSnapshot>(*evaluate_small_body_orbit_snapshot(
        model, display, {2451540, 2451550, 5}));
    std::vector<SmallBodyProjectedOrbitSegment> segments;
    const auto collect = [&] {
        segments.clear();
        visit_small_body_orbit_segments(*frame, *display, orbits.get(), camera, map,
            [&](const auto& segment) { segments.push_back(segment); });
    };
    collect();
    require(segments.size() == 4, "five adjacent TDB samples produce four open path segments");
    const auto expected = project_solar_segment(orbits->paths[0]->samples[0].evaluation.state->position_au,
        orbits->paths[0]->samples[1].evaluation.state->position_au, camera, map.size.width, map.size.height);
    require(expected && std::abs(segments[0].first.x - (*expected)[0].x - map.origin.x) < 1e-10
        && std::abs(segments[0].second.y - (*expected)[1].y - map.origin.y) < 1e-10,
        "orbit lines use absolute heliocentric AU directly through the common projection");
    orbits->paths[0]->samples[2].evaluation.state.reset();
    collect();
    require(segments.size() == 2, "missing orbit sample splits the path without bridging or closing it");
    display->set_kind_options(SmallBodyKind::comet, {true, true, false, true});
    collect(); require(segments.empty(), "orbit switch suppresses lines without removing source rows");
    display->set_kind_options(SmallBodyKind::comet, {false, true, true, true});
    collect(); require(segments.empty() && visible_small_bodies(*frame, *display, camera, map).empty(),
        "kind visibility gates all layers even when label and orbit flags remain enabled");
    display->set_kind_options(SmallBodyKind::comet, {true, true, true, true});
    orbits->paths[0]->id.record_ordinal = 1;
    collect(); require(segments.empty(), "orbit path with a different original row identity is rejected");
    orbits->paths[0]->id.record_ordinal = 0;
    SolarSystemView *view = [[SolarSystemView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    SolarBodies bodies{};
    for (std::size_t index = 0; index < bodies.size(); ++index) bodies[index].position_au = {20 * double(index), 0, 0};
    [view setBodies:bodies];
    SolarSystemView *zoomFixture = [[SolarSystemView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    [zoomFixture setBodies:bodies];
    require([zoomFixture scriptOtherBodyPlaceRegression], "Mars and Moon places track their body and reject invalid surface moves");
    [zoomFixture setBodies:bodies];
    require([zoomFixture zoomNavigationRegression], "zoom validates the post-navigation frame and preserves state on rejection");
    require([zoomFixture zoomCollisionRegression], "instant and animated zoom stay outside Earth");
    [view setCameraState:camera];
    [view setSmallBodySnapshot:frame];
    [view setSmallBodyDisplayModel:display];
    [view setSmallBodyOrbitSnapshot:orbits];
    auto malformedOrbits = std::make_shared<SmallBodyOrbitSnapshot>(*orbits);
    malformedOrbits->minor_planet_paths.clear();
    bool rejectedMalformedOrbits = false;
    try { [view setSmallBodyOrbitSnapshot:malformedOrbits]; }
    catch (const std::invalid_argument&) { rejectedMalformedOrbits = true; }
    require(rejectedMalformedOrbits, "orbit snapshot rejects mismatched minor-planet path count");
    require(view.visibleSmallBodyCount == 1, "solar view displays valid small body positions");
    const auto viewMap = NSInsetRect(view.bounds, 18, 40);
    const auto viewPoints = visible_small_bodies(*frame, *display, camera, viewMap);
    require(viewPoints.size() == 1, "click fixture has a visible small body");
    const auto click = NSMakePoint(viewPoints[0].point.x, viewPoints[0].point.y);
    const NSPoint eventPoint = [view convertPoint:click toView:nil];
    NSEvent *clickEvent = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp location:eventPoint modifierFlags:0
        timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:1 pressure:0];
    NSEvent *hoverEvent = [NSEvent mouseEventWithType:NSEventTypeMouseMoved location:eventPoint modifierFlags:0
        timestamp:0 windowNumber:0 context:nil eventNumber:0 clickCount:0 pressure:0];
    [view selectBody:1];
    view.targetSelectionMode = 0;
    [view mouseUp:clickEvent]; [view mouseMoved:hoverEvent];
    require(view.selectedBodyIndex == 1, "none mode ignores click and hover");
    view.targetSelectionMode = 1;
    [view mouseUp:clickEvent];
    require(view.selectedBodyIndex == 1, "hover mode ignores click");
    [view mouseMoved:hoverEvent];
    require(view.selectedSmallBodyIndex == 0, "hover mode selects the displayed small body");
    [view selectBody:1];
    view.targetSelectionMode = 2;
    [view mouseMoved:hoverEvent];
    require(view.selectedBodyIndex == 1, "click mode ignores hover");
    [view mouseUp:clickEvent];
    require(view.selectedSmallBodyIndex == 0, "click mode selects the same displayed small body");
    [view pickBodyAtPoint:click];
    require(view.selectedSmallBodyIndex == 0, "visible small body is selected through the view");
    view.smallBodiesVisible = NO;
    [view pickBodyAtPoint:click];
    require(view.selectedSmallBodyIndex == NSNotFound, "hidden small body cannot be selected through the view");
    view.smallBodiesVisible = YES;
    __block NSString *description = nil;
    __block NSString *cameraDescription = nil;
    view.selectionChanged = ^(NSString *text) { description = text; };
    view.cameraChanged = ^(NSString *text) { cameraDescription = text; };
    [view selectSmallBody:0];
    require(view.selectedSmallBodyIndex == 0 && view.selectedBodyIndex == NSNotFound, "small-body selection is separate from planet indices");
    [view focusSelection];
    require(same([view cameraState].target, *frame->positions[0]), "focus uses core heliocentric ecliptic position directly");
    NSString *zoomError = nil;
    const auto beforeZoom = [view cameraState];
    const auto beforeBasis = solar_camera_basis(beforeZoom);
    require([view animateScriptZoomTo:beforeZoom.distance_au * 2 duration:0 logarithmic:NO error:&zoomError], "instant zoom accepted");
    const auto afterZoom = [view cameraState];
    require(afterZoom.distance_au == beforeZoom.distance_au * 2 && same(afterZoom.target, beforeZoom.target)
        && same(solar_camera_basis(afterZoom).right, beforeBasis.right), "instant zoom keeps target and orientation");
    auto afterTimeAdvance = evaluate_small_body_snapshot(model, 2451555);
    [view setSmallBodySnapshot:afterTimeAdvance];
    require(same([view cameraState].target, *afterTimeAdvance->positions[0]), "zoom preserves selected object tracking as time advances");
    require([view animateScriptZoomTo:beforeZoom.distance_au duration:10 logarithmic:YES error:&zoomError], "animated zoom accepted");
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:3];
    while ([view cameraState].distance_au == afterZoom.distance_au && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    const double middle = [view cameraState].distance_au;
    require(middle < afterZoom.distance_au && middle > beforeZoom.distance_au, "timer advances logarithmic zoom");
    auto duringZoom = evaluate_small_body_snapshot(model, 2451565);
    require(!same(*duringZoom->positions[0], *afterTimeAdvance->positions[0]), "test body moves during animated zoom");
    [view setSmallBodySnapshot:duringZoom];
    require(same([view cameraState].target, *duringZoom->positions[0]), "animated zoom preserves tracking as time advances");
    require(![view animateScriptZoomTo:0 duration:0.1 logarithmic:NO error:&zoomError] && zoomError.length, "invalid zoom rejected");
    require([view animateScriptZoomTo:middle * 2 duration:10 logarithmic:NO error:&zoomError], "zoom can restart");
    const double restart = [view cameraState].distance_au;
    require(restart <= middle && restart > beforeZoom.distance_au, "restart samples in-flight zoom");
    [view zoomOut];
    const double manual = [view cameraState].distance_au;
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.16]];
    require([view cameraState].distance_au == manual, "manual zoom cancels animation");
    auto restored = [view cameraState];
    require([view animateScriptZoomTo:manual * 2 duration:0.12 logarithmic:NO error:&zoomError], "zoom starts before restore");
    restored.distance_au = manual * 1.5;
    require([view applyCameraState:restored error:&zoomError], "camera restore accepted");
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.16]];
    require([view cameraState].distance_au == restored.distance_au, "restored camera is not overwritten by old timer");
    auto initialTarget = restored;
    initialTarget.distance_au *= 0.8;
    initialTarget.target.x += 1;
    [view animateScriptTargetFrom:initialTarget duration:0.12];
    require([view animateScriptZoomTo:manual duration:0 logarithmic:NO error:&zoomError], "instant zoom starts during target transition");
    NSDate *targetDeadline = [NSDate dateWithTimeIntervalSinceNow:3];
    while (!same([view cameraState].target, *duringZoom->positions[0]) && targetDeadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    require([view cameraState].distance_au == manual && same([view cameraState].target, *duringZoom->positions[0]),
        "target transition completes without overwriting instant zoom");
    auto afterTarget = evaluate_small_body_snapshot(model, 2451570);
    [view setSmallBodySnapshot:afterTarget];
    require(!same(*afterTarget->positions[0], *duringZoom->positions[0]) &&
        same([view cameraState].target, *afterTarget->positions[0]), "target transition resumes tracking after instant zoom");
    initialTarget = [view cameraState];
    initialTarget.target.x += 1;
    [view animateScriptTargetFrom:initialTarget duration:0.12];
    const double concurrentDistance = manual * 1.4;
    require([view animateScriptZoomTo:concurrentDistance duration:0.2 logarithmic:NO error:&zoomError],
        "animated zoom starts during target transition");
    NSDate *concurrentDeadline = [NSDate dateWithTimeIntervalSinceNow:3];
    while ([view cameraState].distance_au != concurrentDistance && concurrentDeadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    require([view cameraState].distance_au == concurrentDistance && same([view cameraState].target, *afterTarget->positions[0]),
        "target transition and animated zoom complete independently");
    require([view animateScriptZoomTo:manual * 2 duration:0.12 logarithmic:NO error:&zoomError], "zoom starts before target transition");
    auto targetStart = [view cameraState];
    [view animateScriptTargetFrom:targetStart duration:0.12];
    [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.16]];
    require([view cameraState].distance_au == targetStart.distance_au, "target transition cancels old zoom");
    const double completedZoom = targetStart.distance_au * 1.25;
    require([view animateScriptZoomTo:completedZoom duration:0.1 logarithmic:NO error:&zoomError], "zoom starts before invalid restore");
    auto invalidRestore = [view cameraState];
    invalidRestore.distance_au = 0;
    require(![view applyCameraState:invalidRestore error:&zoomError], "invalid camera restore rejected");
    deadline = [NSDate dateWithTimeIntervalSinceNow:3];
    while ([view cameraState].distance_au != completedZoom && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.02]];
    require([view cameraState].distance_au == completedZoom, "zoom completes after rejected restore");
    auto later = evaluate_small_body_snapshot(model, 2451575);
    require(!same(*later->positions[0], *duringZoom->positions[0]), "test body moves before the follow check");
    [view setSmallBodySnapshot:later];
    require(same([view cameraState].target, *later->positions[0]), "follow selection tracks the new common Julian date");
    const auto validCamera = [view cameraState];
    [view selectSmallBody:1];
    require(display->selected_ids().size() == 1 && display->contains(dataset->records[0].id),
        "single-object click selection does not mutate the separate display set");
    [view focusSelection];
    require(same([view cameraState].target, validCamera.target) && [view cameraState].distance_au == validCamera.distance_au,
        "unresolved record focus leaves current camera unchanged");
    require([description containsString:@"位置を表示できません"] && [cameraDescription containsString:@"現在の視点を維持"],
        "unresolved selection visibly explains retained camera");
    [view showSurface]; [view landAtLatitude:0 longitude:0]; [view takeOff]; [view startJourneyAtLatitude:0 longitude:0];
    require(!view.surfaceNavigationActive && !view.journeyActive && same([view cameraState].target, validCamera.target),
        "surface and flight operations reject small bodies without falling back to Earth or Moon");
    [view selectSmallBody:9999];
    require(view.selectedSmallBodyIndex == 1, "invalid selection index leaves current selection intact");
    [view selectBody:3];
    require(view.selectedBodyIndex == 3 && view.selectedSmallBodyIndex == NSNotFound, "planet selection clears small-body selection");
    [view selectSmallBody:0];
    view.smallBodiesVisible = NO;
    require(view.visibleSmallBodyCount == 0, "display toggle suppresses small-body drawing without deleting source rows");
    [view focusSelection];
    require(view.smallBodiesVisible && view.visibleSmallBodyCount == 1, "focus makes selected small body visible");
    require([view runCameraSmokeTest] && view.selectedSmallBodyIndex == 0 && view.smallBodiesVisible,
        "synthetic camera scene isolates and restores small-body selection and visibility");
    auto hidden = std::make_shared<SmallBodyDisplayModel>(*display);
    hidden->set_kind_options(SmallBodyKind::comet, {false, true, true, true});
    const auto cameraBeforeOptions = [view cameraState];
    [view setSmallBodyDisplayModel:hidden];
    require(view.visibleSmallBodyCount == 0 && view.selectedSmallBodyIndex == 0
        && same([view cameraState].target, cameraBeforeOptions.target),
        "kind toggle preserves single selection and navigation state while hiding markers");
    [view setSmallBodyDisplayModel:display];
    auto unrelatedDataset = std::make_shared<SmallBodyDataset>(*dataset);
    auto unrelated = std::make_shared<SmallBodyDisplayModel>(unrelatedDataset);
    bool rejected = false;
    try { [view setSmallBodyDisplayModel:unrelated]; } catch (const std::invalid_argument&) { rejected = true; }
    require(rejected && view.visibleSmallBodyCount == 1 && view.selectedSmallBodyIndex == 0,
        "mismatched display model is rejected without partial state changes");
    __block std::vector<bool> overviewChanges;
    __weak SolarSystemView *weakView = view;
    view.overviewVisibilityChanged = ^(BOOL visible) {
        overviewChanges.push_back(visible);
        require([weakView smallBodiesSceneVisible] == visible,
            "overview callback observes the final navigation flags");
    };
    [view showEarthMoon];
    require(view.visibleSmallBodyCount == 0, "physical Earth-Moon mode suppresses schematic small-body markers");
    require(overviewChanges == std::vector<bool>{false}, "Earth-Moon transition cancels overview work once");
    [view showEarthMoon];
    require(overviewChanges.size() == 1, "repeating Earth-Moon mode does not publish an intermediate overview");
    [view resetCamera];
    require(overviewChanges == std::vector<bool>({false, true}), "reset resumes overview work once");
    [view showEarthMoon];
    [view showInnerPlanets];
    require(overviewChanges == std::vector<bool>({false, true, false, true}),
        "inner-planet navigation resumes overview work after Earth-Moon mode");
    [view selectBody:3];
    [view showEarthMoon];
    const auto beforeSurface = overviewChanges.size();
    [view showSurface];
    require(![view smallBodiesSceneVisible] && overviewChanges.size() == beforeSurface,
        "Earth-Moon to surface transition never resumes overview work in an intermediate state");
    [view resetCamera];
    require(overviewChanges.size() == beforeSurface + 1 && overviewChanges.back(),
        "leaving surface mode resumes overview work once");
    view.overviewVisibilityChanged = nil;
    [view setSmallBodySnapshot:nullptr];
    require(view.selectedSmallBodyIndex == NSNotFound && view.visibleSmallBodyCount == 0, "unloading source clears stale small-body selection");
    require(![description containsString:@"test comet"], "unloading source clears stale selection description");
}
}
int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try { galaxy_identity_tests(); nearby_galaxy_radius_tests(); minor_planet_orbit_tests(); tests(); std::cout << "Solar small-body tests passed: " << checks << " checks\n"; return 0; }
        catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
