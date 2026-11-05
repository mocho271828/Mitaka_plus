#import "SolarSystemView.h"
#import "SolarSceneRenderer.h"
#import "SatelliteRenderer.h"
#include <algorithm>
#include <cmath>
#include <functional>
#include <iostream>
#include <limits>
#include <stdexcept>

// 実イベントの代わりに、同じビューのクリック入口を合成配置で検証する。
@interface SolarSystemView (SatelliteTests)
- (void)pickBodyAtPoint:(NSPoint)point;
@end

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
void require(bool value, const char *message) { ++checks; if (!value) throw std::runtime_error(message); }
bool same(Vec3 a, Vec3 b) { return std::hypot(a.x-b.x, a.y-b.y, a.z-b.z) < 1e-12; }
template<class Function> void rejects(Function function, const char* message) {
    try { function(); } catch (const std::invalid_argument&) { require(true, message); return; }
    require(false, message);
}
std::shared_ptr<const SatelliteBrowserModel> model() {
    SatelliteDataset dataset;
    dataset.sources.push_back({"ssystem.dat",{},SatelliteSourceKind::system_definition,"source A",true,true,true,3});
    dataset.sources.push_back({"ssystem_jp.dat",{},SatelliteSourceKind::system_definition,"source B",true,true,true,3});
    for (std::size_t i = 0; i < 3; ++i) {
        SatelliteDefinition definition;
        definition.id = {i == 2 ? "ssystem_jp.dat" : "ssystem.dat", i};
        definition.kind = SatelliteDefinitionKind::satellite;
        SatelliteField name;
        name.key = "Name";
        name.value_bytes = i == 1 ? "Missing Unresolved" : "Duplicate Test satellite";
        definition.fields.push_back(std::move(name));
        dataset.definitions.push_back(std::move(definition));
    }
    return std::make_shared<const SatelliteBrowserModel>(std::make_shared<const SatelliteModel>(std::move(dataset)));
}
std::shared_ptr<SatelliteSnapshot> snapshot(std::shared_ptr<const SatelliteBrowserModel> source) {
    auto frame = std::make_shared<SatelliteSnapshot>();
    frame->model = std::move(source);
    frame->julian_date = 2451545;
    frame->positions = {Vec3{0.31, 0.27, 0.13}, std::nullopt, Vec3{0.31, 0.27, 0.13}};
    frame->positioned_count = 2;
    return frame;
}
using Pixels = std::vector<unsigned char>;
Pixels render(const std::function<void(CGContextRef)>& draw) {
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:400 pixelsHigh:300 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:1600 bitsPerPixel:32];
    if (!bitmap) throw std::runtime_error("bitmap allocation failed");
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    const auto context = NSGraphicsContext.currentContext.CGContext;
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, 400, 300));
    draw(context);
    [NSGraphicsContext restoreGraphicsState];
    return {bitmap.bitmapData, bitmap.bitmapData + bitmap.bytesPerRow * bitmap.pixelsHigh};
}
void renderingTests(const SatelliteSnapshot& frame) {
    SolarCamera camera;
    camera.distance_au = 7;
    const NSRect map = NSMakeRect(18, 40, 364, 220);
    const auto projected = visible_satellites(frame, camera, map);
    require(projected.size() == 2 && projected[0].index == 0 && projected[1].index == 2,
        "evaluated duplicate and language rows retain original order");
    const auto direct = *project_solar(*frame.positions[0], camera, map.size.width, map.size.height);
    require(std::abs(projected[0].point.x-direct.x-map.origin.x) < 1e-12 &&
        std::abs(projected[0].point.y-direct.y-map.origin.y) < 1e-12,
        "projection uses absolute ecliptic position without extra parent or rotation");
    require(pick_satellite(frame, camera, map, NSMakePoint(projected[0].point.x, projected[0].point.y)) == 2,
        "overlapping records retain deterministic picking while every row remains addressable");
    require(!pick_satellite(frame, camera, map, NSZeroPoint), "outside map cannot pick satellites");
    require(visible_satellites(frame, camera, NSZeroRect).empty(), "empty viewport has no markers");
    SolarBodies bodies{};
    SolarOrbits orbits{};
    std::vector<Vec3> lunar;
    SolarScene scene{bodies, orbits, lunar, camera, nullptr, std::nullopt, map, 1, false, std::nullopt, std::nullopt};
    scene.planet_display.visible = false;
    scene.grid_display.circle_scales = false;
    const auto draw = [&] { return render([&](CGContextRef context) { draw_solar_scene(context, scene); }); };
    const auto empty = draw();
    scene.satellites = &frame;
    const auto points = draw();
    require(points != empty, "solar scene draws satellite markers");
    scene.renderer_display.point_smoothing = false;
    const auto hard = draw();
    require(hard != points, "satellite point quality changes actual pixels");
    scene.renderer_display = {false, true, true, true};
    require(draw() == hard, "master antialias gate applies to satellite points");
    scene.renderer_display = {};
    scene.satellite_selection = 0;
    const auto selected = draw();
    require(selected != points, "selected satellite draws ring and label");
    scene.renderer_display.line_smoothing = false;
    require(draw() != selected, "satellite ring uses line quality");
    scene.renderer_display = {true, true, true, false};
    require(draw() != selected, "satellite label uses text quality");
    SatelliteDisplayModel display(std::shared_ptr<const SatelliteModel>(frame.model,&frame.model->model()));
    scene.satellite_display = &display;
    scene.satellite_selection.reset();
    scene.renderer_display = {};
    require(draw() == points,"explicit native default renders the same markers");
    display.set_options({true,true,false,false});
    require(draw() != points,"label flag displays names without clicked selection");
    display.set_options({true,false,true,false});
    SatelliteOrbitGeometry paths;
    paths.snapshot = std::shared_ptr<const SatelliteSnapshot>(&frame,[](const SatelliteSnapshot*) {});
    paths.rows.resize(frame.positions.size());
    paths.rows[0].points_au = {{-1,-1,0},{-1,1,0},{1,1,0},{1,-1,0},{-1,-1,0}};
    scene.satellite_orbits = &paths;
    const auto withOrbits = draw();
    require(withOrbits != points,"instantaneous orbit flag draws a path through the scene");
    display.set_options({true,false,false,false});
    require(draw() == points,"orbit flag alone controls path pixels");
    display.set_options({true,false,true,true});
    display.set_selected_ids({display.id_at(1)});
    require(draw() == empty,"unpositioned membership creates no markers or unrelated orbit");
    display.set_selected_ids({display.id_at(0)});
    require(draw() != empty,"exact selected member restores its marker and orbit");
    display.set_options({false,true,true,false});
    require(draw() == empty,"master visibility suppresses marker label and orbit");
    display.set_options({true,false,true,false});
    paths.snapshot = snapshot(frame.model);
    require(draw() == points,"cache from another snapshot never draws stale orbit");
    paths.snapshot = std::shared_ptr<const SatelliteSnapshot>(&frame,[](const SatelliteSnapshot*) {});
    paths.rows.pop_back();
    require(draw() == points,"incomplete orbit cache is rejected without hiding valid markers");
    for (unsigned variant = 0; variant < 8; ++variant) {
        auto invalid = frame;
        NSRect invalidMap = map;
        const auto nan = std::numeric_limits<double>::quiet_NaN();
        switch (variant) {
            case 0: invalid.positions.push_back(Vec3{}); break;
            case 1: invalid.positions.pop_back(); break;
            case 2: invalid.julian_date = nan; break;
            case 3: invalid.model.reset(); break;
            case 4: invalidMap.origin.x = nan; break;
            case 5: invalidMap.size.height = std::numeric_limits<double>::infinity(); break;
            case 6: invalidMap.size.width = -1; break;
            case 7: invalidMap.origin.y = invalidMap.size.height = std::numeric_limits<double>::max(); break;
        }
        require(visible_satellites(invalid,camera,invalidMap,&display).empty(),"invalid render input has no visible rows");
        const auto blank = render([&](CGContextRef context) {
            draw_satellites(context,invalid,camera,invalidMap,{},RendererDisplayOptions{},&display,&paths);
        });
        require(blank == render([](CGContextRef) {}),"invalid render input does not draw");
    }
    draw_satellites(nullptr,frame,camera,map,{},RendererDisplayOptions{},&display,&paths);
    require(!pick_satellite(frame,camera,map,NSMakePoint(NAN,0),&display),"nonfinite pick location rejected");
}
void viewTests(std::shared_ptr<const SatelliteBrowserModel> source) {
    auto frame = snapshot(source);
    SolarCamera camera;
    camera.distance_au = 7;
    SolarSystemView *view = [[SolarSystemView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    SolarBodies bodies{};
    for (std::size_t i = 0; i < bodies.size(); ++i) bodies[i].position_au = {20*double(i), 0, 0};
    [view setBodies:bodies];
    [view setCameraState:camera];
    [view setSatelliteSnapshot:frame];
    require(view.visibleSatelliteCount == 2, "solar view retains both positioned duplicate rows");
    auto display = std::make_shared<SatelliteDisplayModel>(std::shared_ptr<const SatelliteModel>(source,&source->model()));
    display->set_selected_ids({display->id_at(2)});
    display->set_options({true,true,true,true});
    [view setSatelliteDisplayModel:display];
    require(view.visibleSatelliteCount == 1,"selected-only display filters the scene without merging same-name rows");
    const auto memberProjection = project_solar(frame->positions[2].value(),camera,800,600);
    require(memberProjection && pick_satellite(*frame,camera,NSMakeRect(0,0,800,600),NSMakePoint(memberProjection->x,memberProjection->y),display.get()) == 2,
        "picking uses the exact same display membership as rendering");
    auto hidden = std::make_shared<SatelliteDisplayModel>(*display); hidden->set_options({false,true,true,true});
    [view setSatelliteDisplayModel:hidden];
    require(view.visibleSatelliteCount == 0 && !pick_satellite(*frame,camera,NSMakeRect(0,0,800,600),NSMakePoint(memberProjection->x,memberProjection->y),hidden.get()),
        "hidden display cannot remain clickable");
    [view setSatelliteDisplayModel:display];
    const auto wrongModel = model();
    auto wrongDisplay = std::make_shared<SatelliteDisplayModel>(std::shared_ptr<const SatelliteModel>(wrongModel,&wrongModel->model()));
    rejects([&] { [view setSatelliteDisplayModel:wrongDisplay]; },"display from another dataset is atomically rejected");
    require([view satelliteDisplayModel] == display && view.visibleSatelliteCount == 1,"failed display preserves current source and flags");
    display = std::make_shared<SatelliteDisplayModel>(*display); display->set_options({true,false,false,false});
    [view setSatelliteDisplayModel:display];
    __block NSString *description = nil;
    __block NSString *cameraDescription = nil;
    __block NSUInteger callbackIndex = NSNotFound;
    __block NSUInteger selectionCallbacks = 0;
    __block BOOL runningSyntheticSmoke = NO;
    __weak SolarSystemView *weakView = view;
    view.satelliteSelectionChanged = ^(NSUInteger index) {
        callbackIndex = index;
        ++selectionCallbacks;
        // App 側と同じ親位置更新で選択通知が再帰しないことも確認する。
        [weakView setBodies:bodies];
    };
    view.selectionChanged = ^(NSString *text) {
        description = text;
        require(runningSyntheticSmoke || callbackIndex == weakView.selectedSatelliteIndex,
            "parent-source callback precedes selection description notification");
    };
    view.cameraChanged = ^(NSString *text) { cameraDescription = text; };
    [view selectSatellite:0];
    require(selectionCallbacks == 1 && callbackIndex == 0, "satellite selection invokes parent-source callback once");
    [view selectSatellite:0];
    [view setBodies:bodies];
    require(selectionCallbacks == 1, "same-index selection and parent position updates do not repeat callback");
    require(view.selectedSatelliteIndex == 0 && view.selectedBodyIndex == NSNotFound && view.selectedSmallBodyIndex == NSNotFound,
        "satellite indices are distinct from planet and small-body indices");
    [view focusSelection];
    require(same([view cameraState].target, *frame->positions[0]), "focus uses absolute position directly");
    auto later = snapshot(source);
    later->julian_date += 10;
    later->positions[0] = Vec3{0.4, 0.3, 0.2};
    [view setSatelliteSnapshot:later];
    require(same([view cameraState].target, *later->positions[0]), "following tracks same-model Julian date updates");
    require(selectionCallbacks == 1, "same-model time update does not signal a selection change");
    auto staged = snapshot(source);
    staged->julian_date = later->julian_date + 1;
    staged->positions[0] = Vec3{0.6, 0.4, 0.1};
    const auto oldGeometry = [view satelliteOrbitGeometry];
    const auto oldCamera = [view cameraState];
    const auto prepared = prepare_satellite_scene(staged, display);
    require(prepared.orbits() && prepared.orbits()->snapshot == staged && prepared.display() == display,
        "preparation constructs geometry with the candidate snapshot and display");
    require([view satelliteOrbitGeometry] == oldGeometry && same([view cameraState].target, oldCamera.target),
        "preparation does not publish candidate geometry or move the camera");
    rejects([&] { (void)prepare_satellite_scene(staged, wrongDisplay); }, "preparation rejects a mismatched display");
    auto badPrepared = snapshot(source); badPrepared->positions.pop_back();
    rejects([&] { (void)prepare_satellite_scene(badPrepared, display); }, "preparation rejects an invalid snapshot");
    require([view satelliteOrbitGeometry] == oldGeometry && [view satelliteDisplayModel] == display &&
        view.selectedSatelliteIndex == 0 && same([view cameraState].target, oldCamera.target),
        "failed preparation leaves the published satellite scene unchanged");
    const auto callbacksBeforeCommit = selectionCallbacks;
    const BOOL needsNotification = [view commitPreparedSatelliteScene:prepared];
    require([view satelliteOrbitGeometry] == prepared.orbits() && [view satelliteDisplayModel] == display &&
        same([view cameraState].target, oldCamera.target) && selectionCallbacks == callbacksBeforeCommit,
        "commit reuses prepared geometry and defers tracking and notifications");
    [view finishSatelliteSceneUpdate:needsNotification];
    require(same([view cameraState].target, *staged->positions[0]) && selectionCallbacks == callbacksBeforeCommit,
        "finishing the update tracks the staged position without a selection change");
    [view setSatelliteSnapshot:later];
    const auto validCamera = [view cameraState];
    [view selectSatellite:1];
    [view focusSelection];
    require(same([view cameraState].target, validCamera.target) && [view cameraState].distance_au == validCamera.distance_au,
        "unresolved row focus leaves current camera unchanged");
    require([description containsString:@"位置を表示できません"] && [cameraDescription containsString:@"現在の視点を維持"],
        "unresolved row visibly explains retained camera");
    [view showSurface]; [view landAtLatitude:0 longitude:0]; [view takeOff]; [view startJourneyAtLatitude:0 longitude:0];
    require(!view.surfaceNavigationActive && !view.journeyActive && same([view cameraState].target, validCamera.target),
        "unsupported surface and flight operations do not fall back to a planet");
    const auto callbacksBeforeInvalid = selectionCallbacks;
    [view selectSatellite:9999];
    require(view.selectedSatelliteIndex == 1, "invalid index leaves current selection intact");
    require(selectionCallbacks == callbacksBeforeInvalid, "invalid index does not invoke parent-source callback");
    [view selectBody:3];
    require(view.selectedSatelliteIndex == NSNotFound && view.selectedBodyIndex == 3, "planet selection clears satellite selection");
    require(callbackIndex == NSNotFound && selectionCallbacks == callbacksBeforeInvalid + 1,
        "planet selection signals one satellite deselection before description");
    [view selectBody:4];
    require(selectionCallbacks == callbacksBeforeInvalid + 1, "planet-to-planet selection does not repeat satellite deselection");
    auto smallData = std::make_shared<SmallBodyDataset>();
    smallData->sources.push_back({"test.dat", {}, "test source", 1, true});
    SmallBodyRecord smallRecord;
    smallRecord.id = {"test.dat", 0};
    smallData->records.push_back(smallRecord);
    auto small = std::make_shared<SmallBodySnapshot>();
    small->model = std::make_shared<SmallBodyModel>(smallData);
    small->positions = {std::nullopt};
    [view setSmallBodySnapshot:small];
    [view selectSatellite:0];
    const auto callbacksBeforeSmall = selectionCallbacks;
    [view selectSmallBody:0];
    require(view.selectedSatelliteIndex == NSNotFound && view.selectedSmallBodyIndex == 0, "small-body selection clears satellite selection");
    require(callbackIndex == NSNotFound && selectionCallbacks == callbacksBeforeSmall + 1,
        "small-body selection signals one satellite deselection before description");
    [view selectSatellite:2];
    require(view.selectedSmallBodyIndex == NSNotFound && view.selectedSatelliteIndex == 2,
        "satellite selection clears small-body selection and selects distinct duplicate row");
    hidden = std::make_shared<SatelliteDisplayModel>(*display); hidden->set_options({false,false,false,false});
    [view setSatelliteDisplayModel:hidden];
    require(view.visibleSatelliteCount == 0 && view.selectedSatelliteIndex == 2, "hidden satellite rows and selection remain intact");
    [view focusSelection];
    require(![view satelliteDisplayModel]->options().visible && view.visibleSatelliteCount == 0,
        "focus preserves the independent display flags");
    [view setSatelliteDisplayModel:display];
    const auto callbacksBeforeSmoke = selectionCallbacks;
    runningSyntheticSmoke = YES;
    const BOOL cameraSmoke = [view runCameraSmokeTest];
    runningSyntheticSmoke = NO;
    require(cameraSmoke && view.selectedSatelliteIndex == 2 && [view satelliteDisplayModel] == display,
        "synthetic camera smoke isolates and restores satellite selection");
    [view setBodies:bodies];
    require(selectionCallbacks == callbacksBeforeSmoke && callbackIndex == 2,
        "synthetic smoke restores notification state without exposing temporary selection resets");
    auto invalid = snapshot(source);
    invalid->positions.pop_back();
    rejects([&] { [view setSatelliteSnapshot:invalid]; }, "mismatched row count rejected before mutation");
    invalid = snapshot(source); invalid->positions[0]->x = std::numeric_limits<double>::quiet_NaN();
    rejects([&] { [view setSatelliteSnapshot:invalid]; }, "nonfinite position rejected before mutation");
    invalid = snapshot(source); invalid->julian_date = std::numeric_limits<double>::infinity();
    rejects([&] { [view setSatelliteSnapshot:invalid]; }, "nonfinite Julian date rejected before mutation");
    invalid = snapshot(source); invalid->model.reset();
    rejects([&] { [view setSatelliteSnapshot:invalid]; }, "snapshot without a model rejected before mutation");
    require(view.selectedSatelliteIndex == 2 && same([view cameraState].target, *later->positions[2]), "invalid snapshot preserves selection and camera");
    auto lost = snapshot(source); lost->positions[2].reset();
    [view setSatelliteSnapshot:lost];
    const auto retained = [view cameraState];
    auto recovered = snapshot(source);
    recovered->positions[2] = Vec3{0.8, 0.9, 0.2};
    [view setSatelliteSnapshot:recovered];
    require(same([view cameraState].target, retained.target), "lost position stops following instead of moving camera on later recovery");
    [view showEarthMoon];
    require(view.visibleSatelliteCount == 0, "physical Earth-Moon mode suppresses overview markers");
    [view resetCamera];
    [view setCameraState:camera];
    auto planets = view.planetDisplayOptions;
    planets.visible = false;
    view.planetDisplayOptions = planets;
    const NSRect map = NSInsetRect(view.bounds, 18, 40);
    auto projected = visible_satellites(*recovered, [view cameraState], map);
    const auto callbacksBeforeClick = selectionCallbacks;
    [view pickBodyAtPoint:NSMakePoint(projected[0].point.x, projected[0].point.y)];
    require(view.selectedSatelliteIndex != NSNotFound, "view click path selects a satellite marker");
    require(selectionCallbacks == callbacksBeforeClick + 1 && callbackIndex == view.selectedSatelliteIndex,
        "marker click uses the same parent-source callback as list selection");
    const auto callbacksBeforeEmpty = selectionCallbacks;
    [view setSatelliteDisplayModel:hidden];
    [view pickBodyAtPoint:NSMakePoint(projected[0].point.x, projected[0].point.y)];
    require(view.selectedSatelliteIndex == NSNotFound, "hidden satellite cannot be selected by click");
    require(callbackIndex == NSNotFound && selectionCallbacks == callbacksBeforeEmpty + 1,
        "empty-space click signals one satellite deselection before description");
    [view pickBodyAtPoint:NSMakePoint(projected[0].point.x, projected[0].point.y)];
    require(selectionCallbacks == callbacksBeforeEmpty + 1, "repeated empty-space click does not repeat deselection");
    [view selectSatellite:0]; [view focusSelection];
    const auto callbacksBeforeReplacement = selectionCallbacks;
    const auto previous = [view cameraState];
    auto replacement = snapshot(model()); replacement->positions[0] = Vec3{1, 2, 3};
    [view setSatelliteSnapshot:replacement];
    require(view.selectedSatelliteIndex == NSNotFound && same([view cameraState].target, previous.target),
        "model replacement clears stale index and following without moving camera");
    require(![description containsString:@"Test satellite"], "model replacement clears old description");
    require(callbackIndex == NSNotFound && selectionCallbacks == callbacksBeforeReplacement + 1,
        "model replacement signals one deselection for the old model");
    [view selectSatellite:0];
    require(callbackIndex == 0 && selectionCallbacks == callbacksBeforeReplacement + 2,
        "selecting the same numeric index in a replacement model is a new selection");
    [view setSatelliteSnapshot:nullptr];
    require(view.selectedSatelliteIndex == NSNotFound && view.visibleSatelliteCount == 0, "unload clears stale satellite selection");
    require(callbackIndex == NSNotFound && selectionCallbacks == callbacksBeforeReplacement + 3,
        "unload signals one deselection");
    [view setSatelliteSnapshot:nullptr];
    require(selectionCallbacks == callbacksBeforeReplacement + 3, "repeated unload does not repeat deselection");
}
}
int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try { const auto source = model(); renderingTests(*snapshot(source)); viewTests(source);
            std::cout << "Solar satellite tests passed: " << checks << " checks\n"; return 0; }
        catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
