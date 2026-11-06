#import "HorizonView.h"
#include "small_body_model.hpp"
#include "small_body_display.hpp"
#include "spacecraft_browser_model.hpp"
#include "horizon_objects.hpp"
#include "surface_navigation.hpp"
#include "mitaka/rotation.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
unsigned checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template <typename Exception, typename Operation> void rejects(Operation operation) {
    try { operation(); }
    catch (const Exception&) { ++checks; return; }
    throw std::runtime_error("expected exception was not raised");
}
void near(double actual, double expected) {
    check(std::abs(actual - expected) < 1e-9, "numeric mismatch");
}
void test_state(HorizonView *view) {
    __block unsigned viewportChanges = 0;
    view.viewportChanged = ^{ ++viewportChanges; };
    [view setViewport:{725, 45, 90}];
    near([view viewport].center_azimuth_deg, 5);
    near([view viewport].center_altitude_deg, 45);
    [view zoomIn];
    near([view viewport].vertical_fov_deg, 60);
    [view zoomOut];
    near([view viewport].vertical_fov_deg, 90);
    [view resetView];
    near([view viewport].center_azimuth_deg, 180);
    near([view viewport].center_altitude_deg, 0);
    near([view viewport].vertical_fov_deg, 180);
    check(viewportChanges == 4, "viewport callback mismatch");
    [view setViewport:{180, 90, 180}];
    near([view viewport].center_altitude_deg, 90);
    [view zoomIn];
    near([view viewport].center_altitude_deg, 90);
    [view resetView];
    const double nan = std::numeric_limits<double>::quiet_NaN();
    rejects<std::invalid_argument>([&] { [view setViewport:{nan, 0, 1}]; });
    near([view viewport].center_azimuth_deg, 180);
    [view setObserverSite:{-90, -180}];
    near([view observerSite].latitude_deg, -90);
    rejects<std::invalid_argument>([&] { [view setObserverSite:{91, 0}]; });
    rejects<std::invalid_argument>([&] { [view setObserverSite:{0, nan}]; });
    near([view observerSite].latitude_deg, -90);
    SkyBodies bodies{};
    [view setBodies:bodies julianDate:2451545];
    rejects<std::invalid_argument>([&] { [view setBodies:bodies julianDate:nan]; });
    near(view.julianDate, 2451545);
    rejects<std::out_of_range>([&] { [view setBodies:bodies julianDate:1e10]; });
    near(view.julianDate, 2451545);
    view.magnitudeLimit = 7;
    rejects<std::invalid_argument>([&] { view.magnitudeLimit = nan; });
    near(view.magnitudeLimit, 7);
    check(![view selectStarHIP:32349] && view.visibleStarCount == 0, "empty model changed selection/count");
    [view focusSelection];
    [view selectBody:0];
    [view setObserverSite:{35.68, 139.76}];
    view.viewportChanged = nil;
}
void test_drawing(HorizonView *view) {
    NSBitmapImageRep *bitmap = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    check(bitmap != nil, "could not create bitmap");
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:bitmap];
    const double scaleX = bitmap.pixelsWide / view.bounds.size.width;
    const double scaleY = bitmap.pixelsHigh / view.bounds.size.height;
    const auto sky = [[bitmap colorAtX:100 * scaleX y:100 * scaleY] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
    const auto ground = [[bitmap colorAtX:100 * scaleX y:380 * scaleY] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
    check(sky && ground && ground.redComponent > sky.redComponent + 0.03, "ground was not distinguished from sky");
}

struct HorizonFixture {
    std::shared_ptr<SmallBodyDataset> data = std::make_shared<SmallBodyDataset>();
    std::shared_ptr<SmallBodyModel> small;
    std::shared_ptr<SmallBodyDisplayModel> display;
    std::shared_ptr<const SmallBodySnapshot> frame;
    std::shared_ptr<const SpacecraftSnapshot> spacecraft;
    explicit HorizonFixture(std::optional<Vec3> probe_position = std::nullopt) {
        SmallBodyRecord record;
        record.id = {"fixture.dat", 0};
        record.name_bytes = "Test comet";
        record.kind = SmallBodyKind::comet;
        record.frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
        record.time_scale = SmallBodyTimeScale::tdb;
        record.orbit = PerihelionElements{1, 0.5, 2451545, 0, 0, 0};
        data->records.push_back(record);
        record.id.record_ordinal = 1;
        record.name_bytes = "Test asteroid";
        record.kind = SmallBodyKind::asteroid;
        data->records.push_back(record);
        data->sources.push_back({"fixture.dat", {}, "fixture-data", 2, true});
        small = std::make_shared<SmallBodyModel>(data);
        display = std::make_shared<SmallBodyDisplayModel>(data);
        auto positions = std::make_shared<SmallBodySnapshot>();
        positions->model = small;
        positions->julian_date = 2451545;
        positions->evaluated_all = true;
        positions->positions = {Vec3{1, 1, 0.2}, Vec3{1, -1, 0.2}};
        positions->positioned_count = 2;
        frame = positions;

        SpacecraftDataset spacecraft_data;
        const auto probe = probe_position.value_or(Vec3{1, 0.2, 0.1});
        const std::vector<SpacecraftPathSample> samples{{2451545, {probe.x, probe.y, probe.z}},
                                                        {2451546, {1, 0.5, 0.2}}};
        std::string bytes;
        const auto append_double = [&](double value) {
            std::uint64_t bits;
            std::memcpy(&bits, &value, sizeof bits);
            for (unsigned shift = 0; shift < 64; shift += 8)
                bytes.push_back(static_cast<char>(bits >> shift));
        };
        for (const auto& sample : samples) {
            append_double(sample.time_value);
            for (double coordinate : sample.coordinate_values) append_double(coordinate);
        }
        spacecraft_data.sources.push_back({"spacecraft/probe.pth", {}, SpacecraftSourceKind::pth_samples,
                                          bytes, true, true, samples.size()});
        spacecraft_data.trajectories.push_back({0, samples, {}});
        spacecraft_data.sources.push_back({"spacecraft/probe.dat", {}, SpacecraftSourceKind::definition,
                                          "Name: Test probe\n", true, true, 1});
        spacecraft_data.definitions.push_back({1, {{"Name", "Test probe", 0, 0, 1, {}}}, 0});
        auto spacecraft_model = std::make_shared<SpacecraftBrowserModel>(
            std::make_shared<SpacecraftPositionModel>(std::move(spacecraft_data)));
        spacecraft = evaluate_spacecraft_snapshot(spacecraft_model, 2451545);
    }
};
void test_prepared_date(HorizonView *view) {
    HorizonFixture fixture;
    SkyBodies bodies{};
    const double jd = 2451545;
    [view setBodies:bodies julianDate:jd earthPosition:{0, 0, 0}
        smallBodies:fixture.frame smallBodyDisplay:fixture.display spacecraft:fixture.spacecraft];
    check([view selectSmallBody:0], "fixture selection failed");
    __block unsigned notifications = 0;
    view.selectionChanged = ^(NSString *) { ++notifications; };
    rejects<std::invalid_argument>([&] {
        (void)[view prepareBodies:bodies julianDate:std::numeric_limits<double>::quiet_NaN()
            earthPosition:{0, 0, 0} smallBodies:nullptr smallBodyDisplay:nullptr spacecraft:nullptr];
    });
    near(view.julianDate, jd);
    check(view.selectedSmallBodyIndex == 0 && notifications == 0, "failed preparation changed the published state");
    auto prepared = [view prepareBodies:bodies julianDate:jd earthPosition:{0, 0, 0}
        smallBodies:fixture.frame smallBodyDisplay:fixture.display spacecraft:fixture.spacecraft];
    check(!prepared.smallBodyObjects.empty() && !prepared.spacecraftObjects.empty(), "moving objects were not prepared");
    check(view.selectedSmallBodyIndex == 0 && notifications == 0, "preparation changed the published state");
    [view commitPreparedDate:std::move(prepared)];
    check(view.selectedSmallBodyIndex == 0 && notifications == 0, "commit notified or lost selection");
    [view finishDateUpdate];
    check(notifications == 1, "deferred notification was not sent");
    view.selectionChanged = nil;
}
NSData *rendered_bitmap(HorizonView *view) {
    NSBitmapImageRep *bitmap = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    check(bitmap != nil, "could not capture moving object rendering");
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:bitmap];
    return [NSData dataWithBytes:bitmap.bitmapData length:bitmap.bytesPerRow * bitmap.pixelsHigh];
}

// 描画と同じ投影の位置を通常のマウス操作で選択する。
void click_object(HorizonView *view, EquatorialCoordinates coordinates, double jd) {
    const auto horizontal = ObservationFrame([view observerSite], jd).to_horizontal(coordinates);
    [view setViewport:{horizontal.azimuth_deg, horizontal.altitude_deg, 45}];
    const auto viewport = [view viewport];
    const NSRect map = NSInsetRect(view.bounds, 42, 34);
    const auto point = project_horizon({360 - horizontal.azimuth_deg, horizontal.altitude_deg},
        {360 - viewport.center_azimuth_deg, viewport.center_altitude_deg, viewport.vertical_fov_deg},
        map.size.width, map.size.height);
    check(point.has_value(), "fixture object is outside viewport");
    const NSPoint location = NSMakePoint(map.origin.x + point->x, map.origin.y + point->y);
    NSEvent *down = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown location:location
        modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:1 clickCount:1 pressure:1];
    NSEvent *up = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp location:location
        modifierFlags:0 timestamp:0 windowNumber:0 context:nil eventNumber:2 clickCount:1 pressure:0];
    [view mouseDown:down];
    [view mouseUp:up];
}

void test_nearby_object_parallax(HorizonView *view, const SkyModel& model, const SkyBodies& bodies, double jd) {
    HorizonFixture fixture;
    const auto savedStars = view.starDisplayOptions;
    const auto savedPlanets = view.planetDisplayOptions;
    const auto savedSelectionChanged = view.selectionChanged;
    const ObserverSite first{0, 0};
    const auto earth = model.solar_bodies(jd)[3].position_au;
    const ObservationFrame frame(first, jd);
    const auto up = equatorial_direction(frame.to_equatorial({0, 90}));
    const auto east = equatorial_direction(frame.to_equatorial({90, 0}));
    const double radius = earth_reference_radius_km / astronomical_unit_km;
    // 独立に地心座標を作る: 測心では真東・高度45°、地心では高度約63°。
    const Vec3 equatorial{earth.x + radius * (2 * up.x + east.x),
                          earth.y + radius * (2 * up.y + east.y),
                          earth.z + radius * (2 * up.z + east.z)};
    auto snapshot = std::make_shared<SmallBodySnapshot>(*fixture.frame);
    snapshot->positions[0] = j2000_equatorial_to_ecliptic(equatorial);
    snapshot->positions[1] = std::nullopt;
    [view setObservationSite:first julianDate:jd];
    [view setBodies:bodies julianDate:jd earthPosition:earth smallBodies:snapshot
        smallBodyDisplay:fixture.display spacecraft:fixture.spacecraft];
    view.smallBodiesVisible = YES;
    view.spacecraftVisible = NO;
    auto stars = view.starDisplayOptions; stars.visible = false; view.starDisplayOptions = stars;
    auto planets = view.planetDisplayOptions; planets.visible = false; view.planetDisplayOptions = planets;
    const auto expected = frame.to_equatorial({90, 45});
    click_object(view, expected, jd);
    check(view.selectedSmallBodyIndex == 0, "near object not clickable at topocentric position");
    [view focusSelection];
    auto focused = [view viewport];
    check(std::abs(focused.center_azimuth_deg - 90) < 1e-7 && std::abs(focused.center_altitude_deg - 45) < 1e-7,
          "focus does not match topocentric drawing");
    HorizonViewport scripted{};
    check([view viewportForTopocentricHeliocentricPosition:*snapshot->positions[0] julianDate:jd result:&scripted],
          "topocentric script target unavailable");
    check(std::abs(scripted.center_azimuth_deg - 90) < 1e-7 && std::abs(scripted.center_altitude_deg - 45) < 1e-7,
          "script target differs from topocentric drawing");
    HorizonViewport geocentric{};
    check([view viewportForHeliocentricPosition:*snapshot->positions[0] julianDate:jd result:&geocentric] &&
          std::abs(geocentric.center_altitude_deg - scripted.center_altitude_deg) > 10,
          "geocentric targets unexpectedly changed or parallax absent");
    // 同じ地心位置を PTH の生サンプルとして通し、選択・注視を照合する。
    HorizonFixture probeFixture(*snapshot->positions[0]);
    [view setSpacecraftSnapshot:probeFixture.spacecraft];
    [view clearSelection];
    view.smallBodiesVisible = NO;
    view.spacecraftVisible = YES;
    click_object(view, expected, jd);
    check(view.selectedSpacecraftIndex == 0, "near PTH object not clickable at topocentric position");
    [view focusSelection];
    focused = [view viewport];
    check(std::abs(focused.center_azimuth_deg-90) < 1e-7 && std::abs(focused.center_altitude_deg-45) < 1e-7,
          "near PTH focus differs from topocentric position");
    check([view viewportForTopocentricHeliocentricPosition:*probeFixture.spacecraft->positions[0] julianDate:jd result:&scripted] &&
          std::abs(scripted.center_azimuth_deg-focused.center_azimuth_deg) < 1e-7 &&
          std::abs(scripted.center_altitude_deg-focused.center_altitude_deg) < 1e-7,
          "near PTH script viewport differs from focus");
    [view clearSelection];
    const auto withProbe = rendered_bitmap(view);
    view.spacecraftVisible = NO;
    const auto withoutProbe = rendered_bitmap(view);
    check(![withProbe isEqualToData:withoutProbe], "near PTH object was not rendered");
    // 1 km の測心距離がゼロ表示に丸められないことを実際の選択通知で確認する。
    const double kilometer = 1 / astronomical_unit_km;
    const Vec3 closeEquatorial{earth.x + radius*up.x + kilometer*east.x,
                                earth.y + radius*up.y + kilometer*east.y,
                                earth.z + radius*up.z + kilometer*east.z};
    HorizonFixture closeProbe(j2000_equatorial_to_ecliptic(closeEquatorial));
    [view setSpacecraftSnapshot:closeProbe.spacecraft];
    view.spacecraftVisible = YES;
    __block NSString *closeDescription = nil;
    view.selectionChanged = ^(NSString *value) { closeDescription = value; };
    click_object(view, frame.to_equatorial({90, 0}), jd);
    check(view.selectedSpacecraftIndex == 0 && [closeDescription containsString:@"距離 1 km"],
          "one-kilometer PTH distance was not displayed accurately");
    view.selectionChanged = savedSelectionChanged;
    view.spacecraftVisible = NO;
    view.smallBodiesVisible = YES;
    [view setSpacecraftSnapshot:fixture.spacecraft];
    const ObserverSite second{0, 30};
    [view setObservationSite:second julianDate:jd];
    const ObservationFrame secondFrame(second, jd);
    const auto secondUp = equatorial_direction(secondFrame.to_equatorial({0, 90}));
    const Vec3 relative{equatorial.x-earth.x-radius*secondUp.x, equatorial.y-earth.y-radius*secondUp.y,
                        equatorial.z-earth.z-radius*secondUp.z};
    const auto secondExpected = equatorial_coordinates(relative);
    [view clearSelection];
    click_object(view, expected, jd);
    check(view.selectedSmallBodyIndex == NSNotFound, "site change left stale click position active");
    click_object(view, secondExpected, jd);
    check(view.selectedSmallBodyIndex == 0, "site change did not rebuild object position");
    [view focusSelection];
    const auto horizontal = secondFrame.to_horizontal(secondExpected);
    focused = [view viewport];
    check(std::abs(focused.center_azimuth_deg-horizontal.azimuth_deg) < 1e-7 &&
          std::abs(focused.center_altitude_deg-horizontal.altitude_deg) < 1e-7,
          "focus after site change did not follow object");
    // 同じ物体・地心のまま時刻だけ変え、地球固定地点の自転を追跡する。
    const double later = jd + 0.25;
    const auto earthAxis = j2000_ecliptic_to_equatorial(planet_orientation(Planet::earth, later).x_axis);
    const Vec3 laterRelative{equatorial.x-earth.x-radius*earthAxis.x,
                             equatorial.y-earth.y-radius*earthAxis.y,
                             equatorial.z-earth.z-radius*earthAxis.z};
    const auto laterExpected = equatorial_coordinates(laterRelative);
    auto laterSnapshot = std::make_shared<SmallBodySnapshot>(*snapshot);
    laterSnapshot->julian_date = later;
    [view setObservationSite:first julianDate:later];
    [view setBodies:bodies julianDate:later earthPosition:earth smallBodies:laterSnapshot
        smallBodyDisplay:fixture.display spacecraft:nullptr];
    [view clearSelection];
    click_object(view, expected, later);
    check(view.selectedSmallBodyIndex == NSNotFound, "date change left stale object position");
    click_object(view, laterExpected, later);
    check(view.selectedSmallBodyIndex == 0, "date change did not rotate observer position");
    [view focusSelection];
    const auto laterHorizontal = ObservationFrame(first, later).to_horizontal(laterExpected);
    focused = [view viewport];
    check(std::abs(focused.center_azimuth_deg-laterHorizontal.azimuth_deg) < 1e-7 &&
          std::abs(focused.center_altitude_deg-laterHorizontal.altitude_deg) < 1e-7,
          "focus after date change did not follow object");
    [view setObserverSite:{35.68, 139.76}];
    view.starDisplayOptions = savedStars;
    view.planetDisplayOptions = savedPlanets;
}

void test_moving_objects(HorizonView *view, const SkyModel& model, const SkyBodies& bodies, double jd) {
    test_nearby_object_parallax(view, model, bodies, jd);
    HorizonFixture fixture;
    check(jd == fixture.frame->julian_date, "fixture requires J2000 in the ephemeris range");
    const auto earth = model.solar_bodies(jd)[3].position_au;
    [view setBodies:bodies julianDate:jd earthPosition:earth];
    [view setSmallBodySnapshot:fixture.frame];
    [view setSmallBodyDisplayModel:fixture.display];
    [view setSpacecraftSnapshot:fixture.spacecraft];
    auto stars = view.starDisplayOptions; stars.visible = false; view.starDisplayOptions = stars;
    auto planets = view.planetDisplayOptions; planets.visible = false; view.planetDisplayOptions = planets;
    view.smallBodiesVisible = YES;
    view.spacecraftVisible = NO;
    __block NSString *description;
    view.selectionChanged = ^(NSString *text) { description = text; };
    const auto objects = horizon_small_body_objects(*fixture.frame, *fixture.display, jd, earth, horizon_observer_position(ObservationFrame([view observerSite], jd)));
    check(objects.size() == 2, "small body fixture did not yield both objects");
    click_object(view, objects[0].coordinates, jd);
    check(view.selectedSmallBodyIndex == 0 && view.selectedSpacecraftIndex == NSNotFound &&
          [description containsString:@"Test comet"], "comet click did not select comet");
    click_object(view, objects[1].coordinates, jd);
    check(view.selectedSmallBodyIndex == 1 && [description containsString:@"Test asteroid"],
          "asteroid click did not replace selection");
    [view clearSelection];
    view.smallBodiesVisible = NO;
    NSData *withoutSmallBodies = rendered_bitmap(view);
    view.smallBodiesVisible = YES;
    NSData *withSmallBodies = rendered_bitmap(view);
    check(![withoutSmallBodies isEqualToData:withSmallBodies], "small body visibility did not alter drawing");
    view.smallBodiesVisible = NO;
    click_object(view, objects[0].coordinates, jd);
    check(view.selectedSmallBodyIndex == NSNotFound, "hidden small body remained clickable");
    view.smallBodiesVisible = YES;
    auto comet = fixture.display->kind_options(SmallBodyKind::comet);
    comet.visible = false;
    fixture.display->set_kind_options(SmallBodyKind::comet, comet);
    [view setSmallBodyDisplayModel:fixture.display];
    click_object(view, objects[0].coordinates, jd);
    check(view.selectedSmallBodyIndex == NSNotFound, "hidden comet kind remained clickable");
    comet.visible = true;
    fixture.display->set_kind_options(SmallBodyKind::comet, comet);
    [view setSmallBodyDisplayModel:fixture.display];
    click_object(view, objects[0].coordinates, jd);
    check(view.selectedSmallBodyIndex == 0, "restored comet was not clickable");
    [view setBodies:model.bodies(jd + 1) julianDate:jd + 1 earthPosition:model.solar_bodies(jd + 1)[3].position_au];
    click_object(view, objects[0].coordinates, jd + 1);
    check(view.selectedSmallBodyIndex == NSNotFound, "stale small body snapshot remained clickable");
    auto fresh = std::make_shared<SmallBodySnapshot>(*fixture.frame);
    fresh->julian_date = jd + 1;
    [view setSmallBodySnapshot:fresh];
    const auto freshObjects = horizon_small_body_objects(*fresh, *fixture.display, jd + 1,
                                                         model.solar_bodies(jd + 1)[3].position_au, horizon_observer_position(ObservationFrame([view observerSite], jd + 1)));
    click_object(view, freshObjects[0].coordinates, jd + 1);
    check(view.selectedSmallBodyIndex == 0, "updated small body snapshot was not clickable");
    [view setBodies:bodies julianDate:jd earthPosition:earth];
    view.smallBodiesVisible = NO;
    view.spacecraftVisible = YES;
    const auto probes = horizon_spacecraft_objects(*fixture.spacecraft, true, false, jd, earth, horizon_observer_position(ObservationFrame([view observerSite], jd)), spacecraft_scene_position);
    check(probes.size() == 1, "spacecraft fixture did not yield probe");
    click_object(view, probes[0].coordinates, jd);
    check(view.selectedSpacecraftIndex == 0 && view.selectedSmallBodyIndex == NSNotFound &&
          [description containsString:@"Test probe"] && [description containsString:@"原記録に一致"],
          "probe click or exact sample description failed");
    [view clearSelection];
    view.spacecraftVisible = NO;
    NSData *withoutProbe = rendered_bitmap(view);
    view.spacecraftVisible = YES;
    NSData *withProbe = rendered_bitmap(view);
    check(![withoutProbe isEqualToData:withProbe], "spacecraft visibility did not alter drawing");
    auto spacecraftOptions = view.spacecraftDisplayOptions;
    spacecraftOptions.points = false; spacecraftOptions.labels = true;
    view.spacecraftDisplayOptions = spacecraftOptions;
    click_object(view, probes[0].coordinates, jd);
    check(view.selectedSpacecraftIndex == NSNotFound, "label-only spacecraft remained clickable");
    spacecraftOptions.points = true; view.spacecraftDisplayOptions = spacecraftOptions;
    click_object(view, probes[0].coordinates, jd);
    check(view.selectedSpacecraftIndex == 0, "restored spacecraft was not clickable");
    view.spacecraftVisible = NO;
    click_object(view, probes[0].coordinates, jd);
    check(view.selectedSpacecraftIndex == NSNotFound, "hidden spacecraft remained clickable");
    view.spacecraftVisible = YES;
    [view setBodies:model.bodies(jd + 1) julianDate:jd + 1 earthPosition:model.solar_bodies(jd + 1)[3].position_au];
    click_object(view, probes[0].coordinates, jd + 1);
    check(view.selectedSpacecraftIndex == NSNotFound, "stale spacecraft snapshot remained clickable");
    const auto freshProbe = evaluate_spacecraft_snapshot(fixture.spacecraft->model, jd + 1);
    [view setSpacecraftSnapshot:freshProbe];
    const auto freshProbes = horizon_spacecraft_objects(*freshProbe, true, false, jd + 1,
        model.solar_bodies(jd + 1)[3].position_au, horizon_observer_position(ObservationFrame([view observerSite], jd + 1)), spacecraft_scene_position);
    check(freshProbes.size() == 1, "updated spacecraft fixture missing");
    click_object(view, freshProbes[0].coordinates, jd + 1);
    check(view.selectedSpacecraftIndex == 0 && [description containsString:@"Test probe"],
          "updated spacecraft snapshot was not clickable");
    const std::array<std::pair<double, NSString *>, 3> samplingCases{{
        {jd - 1, @"記録期間前・先頭位置に固定"},
        {jd + 0.5, @"原記録間の線形補間"},
        {jd + 2, @"記録期間後・末尾位置に固定"}
    }};
    for (const auto& samplingCase : samplingCases) {
        const double date = samplingCase.first;
        const auto position = model.solar_bodies(date)[3].position_au;
        [view setBodies:model.bodies(date) julianDate:date earthPosition:position];
        const auto sample = evaluate_spacecraft_snapshot(fixture.spacecraft->model, date);
        [view setSpacecraftSnapshot:sample];
        const auto targets = horizon_spacecraft_objects(*sample, true, false, date, position,
                                                         horizon_observer_position(ObservationFrame([view observerSite], date)), spacecraft_scene_position);
        check(targets.size() == 1, "spacecraft sampling fixture missing");
        click_object(view, targets[0].coordinates, date);
        check(view.selectedSpacecraftIndex == 0 && [description containsString:samplingCase.second],
              "spacecraft sampling description is incorrect");
    }
    __block unsigned notifications = 0;
    __block BOOL sawUnavailable = NO;
    view.selectionChanged = ^(NSString *text) {
        ++notifications;
        if ([text containsString:@"位置を表示できません"]) sawUnavailable = YES;
        description = text;
    };
    const double combinedDate = jd + 0.5;
    const auto combinedSmall = std::make_shared<SmallBodySnapshot>(*fixture.frame);
    combinedSmall->julian_date = combinedDate;
    const auto combinedProbe = evaluate_spacecraft_snapshot(fixture.spacecraft->model, combinedDate);
    [view setBodies:model.bodies(combinedDate) julianDate:combinedDate
        earthPosition:model.solar_bodies(combinedDate)[3].position_au smallBodies:combinedSmall
        smallBodyDisplay:fixture.display spacecraft:combinedProbe];
    check(notifications == 1 && !sawUnavailable && view.selectedSpacecraftIndex == 0 &&
          [description containsString:@"原記録間の線形補間"],
          "combined update exposed a stale spacecraft position to selection callback");
    view.smallBodiesVisible = YES;
    check([view selectSmallBody:0], "combined small body selection failed");
    notifications = 0; sawUnavailable = NO;
    const double nextDate = jd + 1;
    const auto nextSmall = std::make_shared<SmallBodySnapshot>(*fixture.frame);
    nextSmall->julian_date = nextDate;
    const auto nextProbe = evaluate_spacecraft_snapshot(fixture.spacecraft->model, nextDate);
    [view setBodies:model.bodies(nextDate) julianDate:nextDate
        earthPosition:model.solar_bodies(nextDate)[3].position_au smallBodies:nextSmall
        smallBodyDisplay:fixture.display spacecraft:nextProbe];
    check(notifications == 1 && !sawUnavailable && view.selectedSmallBodyIndex == 0 &&
          [description containsString:@"Test comet"] && [description containsString:@"観測地点からの距離"],
          "combined update exposed a stale small body position to selection callback");
    [view selectSpacecraft:0];
    [view selectBody:0];
    check(view.selectedSpacecraftIndex == NSNotFound && view.selectedBodyIndex == 0,
          "planet selection did not clear spacecraft selection");
    view.selectionChanged = nil;
}
void test_data(HorizonView *view, const char *directory) {
    auto model = std::make_shared<SkyModel>(SkyModel::load(directory));
    const double jd = std::clamp(2451545.0, model->time_range().first, model->time_range().second);
    const auto bodies = model->bodies(jd);
    [view setModel:model bodies:bodies];
    [view setBodies:bodies julianDate:jd];
    const auto count = view.visibleStarCount;
    check(count > 1000 && count < model->stars().size(), "full sky magnitude filter failed");
    __block NSString *description;
    view.selectionChanged = ^(NSString *text) { description = text; };
    check([view selectStarHIP:32349], "Sirius HIP could not be selected");
    check([description containsString:@"HIP 32349"] && [description containsString:@"高度"], "selection description missing horizon coordinates");
    [view focusSelection];
    check([view viewport].vertical_fov_deg <= 45 && view.visibleStarCount < count, "focus did not reduce sky extent");
    const auto& star = model->stars()[*model->star_index(32349)];
    const auto horizontal = equatorial_to_horizontal({star.right_ascension_degrees, star.declination_degrees},
                                                     [view observerSite], jd);
    near([view viewport].center_azimuth_deg, horizontal.azimuth_deg);
    check(![view selectStarHIP:-1] && [description containsString:@"HIP 32349"], "missing HIP changed selection");
    [view selectBody:0];
    check([description containsString:@"太陽"] && [description containsString:@"地心距離"], "body selection was not described");
    [view resetView];
    test_drawing(view);
    test_moving_objects(view, *model, bodies, jd);
    [view setModel:nullptr bodies:bodies];
    check(view.visibleStarCount == 0, "unloading model left stars");
    view.selectionChanged = nil;
}
}

int main(int argc, char **argv) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            HorizonView *view = [[HorizonView alloc] initWithFrame:NSMakeRect(0, 0, 800, 480)];
            test_state(view);
            test_drawing(view);
            test_prepared_date(view);
            if (argc == 2) test_data(view, argv[1]);
            std::cout << "horizon view: " << checks << " checks passed\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "horizon view: " << error.what() << '\n';
            return 1;
        }
    }
}
