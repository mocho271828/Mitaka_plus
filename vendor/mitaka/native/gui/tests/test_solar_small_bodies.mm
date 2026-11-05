#import "SolarSystemView.h"
#import "SmallBodyRenderer.h"
#include <cmath>
#include <iostream>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
@interface SolarSystemView (SmallBodyPickingTests)
- (void)pickBodyAtPoint:(NSPoint)point;
@end
namespace {
unsigned checks = 0;
void require(bool value, const char *message) { ++checks; if (!value) throw std::runtime_error(message); }
bool same(Vec3 a, Vec3 b) { return std::hypot(a.x-b.x, a.y-b.y, a.z-b.z) < 1e-12; }
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
    auto later = evaluate_small_body_snapshot(model, 2451555);
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
        try { minor_planet_orbit_tests(); tests(); std::cout << "Solar small-body tests passed: " << checks << " checks\n"; return 0; }
        catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
