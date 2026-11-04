#import "SolarSystemView.h"
#include <cmath>
#include <cstring>
#include <functional>
#include <iostream>
#include <limits>
#include <stdexcept>

// 実イベントと同じ選択入口を、ウィンドウを開かずに検証する。
@interface SolarSystemView (SpacecraftTests)
- (void)pickBodyAtPoint:(NSPoint)point;
@end

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
void require(bool condition, const char* message) { ++checks; if (!condition) throw std::runtime_error(message); }
bool same(Vec3 a, Vec3 b) { return std::hypot(a.x-b.x, a.y-b.y, a.z-b.z) < 1e-12; }
bool same(const SolarCamera& a, const SolarCamera& b) {
    if (!same(a.target, b.target) || a.distance_au != b.distance_au || a.yaw_deg != b.yaw_deg
        || a.pitch_deg != b.pitch_deg || a.frame.has_value() != b.frame.has_value()) return false;
    return !a.frame || (same(a.frame->right, b.frame->right) && same(a.frame->up, b.frame->up)
        && same(a.frame->outward, b.frame->outward));
}
void append_double(std::string& bytes, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof bits);
    for (unsigned shift = 0; shift < 64; shift += 8) bytes.push_back(static_cast<char>(bits >> shift));
}
std::shared_ptr<const SpacecraftBrowserModel> model() {
    SpacecraftDataset data;
    const std::vector<SpacecraftPathSample> path{{100, {0, 0.3, 0.2}}, {102, {0, 1.3, 0.4}}};
    std::string bytes;
    for (const auto& sample : path) {
        append_double(bytes, sample.time_value);
        for (double value : sample.coordinate_values) append_double(bytes, value);
    }
    data.sources.push_back({"spacecraft/probe.pth", {}, SpacecraftSourceKind::pth_samples, bytes, true, true, path.size()});
    data.trajectories.push_back({0, path, {}});
    data.sources.push_back({"spacecraft/probe.dat", {}, SpacecraftSourceKind::definition, "Name: Probe\n", true, true, 1});
    data.definitions.push_back({1, {{"Name", "Probe", 0, 0, 1, {}}}, 0});
    // 同じ軌跡を参照する別言語の定義も、別の選択対象として残す。
    data.sources.push_back({"spacecraft/probe_jp.dat", {}, SpacecraftSourceKind::definition, "Name: Duplicate\n", true, true, 1});
    data.definitions.push_back({2, {{"Name", "Duplicate", 0, 0, 1, {}}}, 0});
    data.sources.push_back({"spacecraft/unconfirmed.ppi", {}, SpacecraftSourceKind::ppi_segments, {}, true, true, 0});
    data.trajectories.push_back({3, {}, {}});
    data.sources.push_back({"spacecraft/unconfirmed.dat", {}, SpacecraftSourceKind::definition, "Name: PPI\n", true, true, 1});
    data.definitions.push_back({4, {{"Name", "PPI", 0, 0, 1, {}}}, 1});
    data.sources.push_back({"spacecraft/missing.dat", {}, SpacecraftSourceKind::definition, "Name: Missing\n", true, true, 1});
    data.definitions.push_back({5, {{"Name", "Missing", 0, 0, 1, {}}}, {}});
    return std::make_shared<const SpacecraftBrowserModel>(std::make_shared<const SpacecraftPositionModel>(std::move(data)));
}
SolarCamera camera() { SolarCamera c; c.yaw_deg = c.pitch_deg = 0; c.distance_au = 7; return c; }
SolarSystemView* view() {
    SolarSystemView* result = [[SolarSystemView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    SolarBodies bodies{};
    for (std::size_t i = 0; i < bodies.size(); ++i) bodies[i].position_au = {20 * double(i), 0, 0};
    [result setBodies:bodies];
    [result setCameraState:camera()];
    return result;
}
void exclusive(SolarSystemView* view, NSUInteger planet, NSUInteger small, NSUInteger satellite, NSUInteger spacecraft) {
    require(view.selectedBodyIndex == planet && view.selectedSmallBodyIndex == small
        && view.selectedSatelliteIndex == satellite && view.selectedSpacecraftIndex == spacecraft,
        "planet, small-body, satellite and spacecraft selection must be mutually exclusive");
}

void focus_follow_and_unresolved() {
    const auto source = model();
    const auto initial = evaluate_spacecraft_snapshot(source, 100.5);
    SolarSystemView* solar = view();
    [solar setSpacecraftSnapshot:initial];
    require(solar.visibleSpacecraftCount == 2, "both PTH definitions visible while PPI and missing remain unpositioned");
    __block NSString* description = nil;
    __block NSString* camera_description = nil;
    solar.selectionChanged = ^(NSString* text) { description = text; };
    solar.cameraChanged = ^(NSString* text) { camera_description = text; };
    const auto before_selection = [solar cameraState];
    [solar selectSpacecraft:0];
    exclusive(solar, NSNotFound, NSNotFound, NSNotFound, 0);
    require(same([solar cameraState], before_selection), "selection alone preserves camera");
    [solar focusSelection];
    require(same([solar cameraState].target, Vec3{0, 0.55, 0.25}), "focus uses independently interpolated heliocentric AU without extra rotation");
    require([description containsString:@"100.50000000"] && [description containsString:@"時系変換なし"]
        && [description containsString:@"線形補間"], "selection details expose snapshot date and sampling contract");
    const auto later = evaluate_spacecraft_snapshot(source, 101.5);
    [solar setSpacecraftSnapshot:later];
    require(same([solar cameraState].target, Vec3{0, 1.05, 0.35}), "follow moves to same-model snapshot at new Julian date");
    require([description containsString:@"101.50000000"], "follow updates displayed common date");
    [solar setSpacecraftSnapshot:evaluate_spacecraft_snapshot(source, 103)];
    require(same([solar cameraState].target, Vec3{0, 1.3, 0.4}) && [description containsString:@"末尾位置に固定"],
        "outside coverage uses explicit PTH endpoint clamp and displays it");
    const auto saved = [solar cameraState];
    for (NSUInteger index : {NSUInteger(2), NSUInteger(3)}) {
        [solar selectSpacecraft:index];
        [solar focusSelection];
        require(same([solar cameraState], saved), "PPI and missing trajectory focus preserve whole camera");
        require([description containsString:@"位置を表示できません"] && [camera_description containsString:@"現在の視点を維持"],
            "unresolved selection explains why camera is retained");
    }
    [solar showSurface]; [solar landAtLatitude:0 longitude:0]; [solar takeOff]; [solar startJourneyAtLatitude:0 longitude:0];
    require(!solar.surfaceNavigationActive && !solar.journeyActive && !solar.flightAnimating && same([solar cameraState], saved),
        "spacecraft surface and flight operations cannot silently select a planet");
    [solar selectSpacecraft:NSNotFound];
    require(solar.selectedSpacecraftIndex == 3, "invalid row leaves original selection intact");

    // 一致しない時刻や PPI に偽装した位置は、描画だけでなく focus/follow も拒む。
    auto forged = std::make_shared<SpacecraftSnapshot>(*initial);
    forged->positions[2] = initial->positions[0];
    forged->evaluations[2] = initial->evaluations[0];
    [solar setSpacecraftSnapshot:forged];
    [solar selectSpacecraft:2]; [solar focusSelection];
    require(same([solar cameraState], saved) && solar.visibleSpacecraftCount == 2, "forged PPI position is withheld from focus and drawing");
    [solar setSpacecraftSnapshot:initial]; [solar selectSpacecraft:0]; [solar focusSelection];
    const auto focused = [solar cameraState];
    forged = std::make_shared<SpacecraftSnapshot>(*later);
    forged->julian_date += 1;
    [solar setSpacecraftSnapshot:forged];
    require(same([solar cameraState], focused) && solar.visibleSpacecraftCount == 0, "inconsistent evaluation date stops tracking without moving camera");
    [solar setSpacecraftSnapshot:later];
    require(same([solar cameraState], focused), "failed tracking does not silently resume on a later snapshot");
    [solar focusSelection];
    require(same([solar cameraState].target, *later->positions[0]), "explicit focus can resume valid tracking");
}

void atomic_snapshot_rejection() {
    const auto source = model();
    const auto initial = evaluate_spacecraft_snapshot(source, 100.5);
    const auto later = evaluate_spacecraft_snapshot(source, 101.5);
    SolarSystemView* solar = view();
    __block unsigned notifications = 0;
    solar.selectionChanged = ^(NSString*) { ++notifications; };
    solar.cameraChanged = ^(NSString*) { ++notifications; };
    const std::vector<std::function<void(SpacecraftSnapshot&)>> corruptions{
        [](auto& state) { state.model.reset(); },
        [](auto& state) { state.positions.pop_back(); },
        [](auto& state) { state.evaluations.pop_back(); },
        [](auto& state) { state.julian_date = std::numeric_limits<double>::quiet_NaN(); },
        [](auto& state) { state.positions[0]->x = std::numeric_limits<double>::infinity(); },
        [](auto& state) { state.positions[0]->z = std::numeric_limits<double>::quiet_NaN(); }
    };
    for (const auto& corrupt : corruptions) {
        [solar setSpacecraftSnapshot:initial]; [solar selectSpacecraft:0]; [solar focusSelection];
        const auto saved = [solar cameraState];
        const auto count = notifications;
        auto bad = std::make_shared<SpacecraftSnapshot>(*initial);
        corrupt(*bad);
        bool rejected = false;
        try { [solar setSpacecraftSnapshot:bad]; } catch (const std::invalid_argument&) { rejected = true; }
        require(rejected, "invalid snapshot is rejected before state mutation");
        require(same([solar cameraState], saved) && solar.selectedSpacecraftIndex == 0 && solar.visibleSpacecraftCount == 2,
            "invalid snapshot preserves camera, selected row and prior snapshot");
        require(notifications == count, "invalid snapshot emits no partial state notifications");
        [solar setSpacecraftSnapshot:later];
        require(same([solar cameraState].target, *later->positions[0]), "invalid snapshot leaves original follow state operational");
    }
}

void selection_reload_and_picking() {
    const auto source = model();
    const auto frame = evaluate_spacecraft_snapshot(source, 100.5);
    SolarSystemView* solar = view();
    [solar setSpacecraftSnapshot:frame];
    auto small_data = std::make_shared<SmallBodyDataset>();
    SmallBodyRecord small; small.id = {"comets.dat", 0}; small_data->records.push_back(small);
    small_data->sources.push_back({"comets.dat", {}, "unresolved original row", 1, true});
    [solar setSmallBodySnapshot:evaluate_small_body_snapshot(std::make_shared<SmallBodyModel>(small_data), 100.5)];
    SatelliteDataset satellite_data;
    // 表示モデルは行 ID だけでなく、読み取り済み定義出典との対応も検証する。
    satellite_data.sources.push_back({"ssystem.dat", {}, SatelliteSourceKind::system_definition,
        "Satellite {}\n", true, true, true, 1});
    SatelliteDefinition satellite; satellite.id = {"ssystem.dat", 0}; satellite.kind = SatelliteDefinitionKind::satellite;
    satellite_data.definitions.push_back(satellite);
    auto satellite_frame = std::make_shared<SatelliteSnapshot>();
    satellite_frame->model = std::make_shared<SatelliteBrowserModel>(std::make_shared<SatelliteModel>(std::move(satellite_data)));
    satellite_frame->julian_date = 100.5; satellite_frame->positions.resize(1);
    [solar setSatelliteSnapshot:satellite_frame];
    [solar selectSpacecraft:0]; [solar selectBody:3]; exclusive(solar, 3, NSNotFound, NSNotFound, NSNotFound);
    [solar selectSpacecraft:0]; exclusive(solar, NSNotFound, NSNotFound, NSNotFound, 0);
    [solar selectSmallBody:0]; exclusive(solar, NSNotFound, 0, NSNotFound, NSNotFound);
    [solar selectSpacecraft:0]; exclusive(solar, NSNotFound, NSNotFound, NSNotFound, 0);
    [solar selectSatellite:0]; exclusive(solar, NSNotFound, NSNotFound, 0, NSNotFound);
    [solar selectSpacecraft:1]; exclusive(solar, NSNotFound, NSNotFound, NSNotFound, 1);
    PlanetDisplayOptions planets; planets.visible = false;
    solar.planetDisplayOptions = planets;
    const NSRect map = NSInsetRect(solar.bounds, 18, 40);
    const auto p = project_solar(*frame->positions[0], [solar cameraState], map.size.width, map.size.height);
    require(p.has_value(), "fixture spacecraft projects inside solar map");
    const NSPoint click = NSMakePoint(map.origin.x+p->x, map.origin.y+p->y);
    solar.spacecraftDisplayOptions = {false, true, true};
    [solar pickBodyAtPoint:click];
    require(solar.selectedSpacecraftIndex == NSNotFound && solar.visibleSpacecraftCount == 2, "labels and orbits do not enable point picking");
    solar.spacecraftDisplayOptions = {true, false, false};
    [solar pickBodyAtPoint:click];
    require(solar.selectedSpacecraftIndex == 1, "actual view picking retains distinct overlapping source row identity");
    solar.spacecraftVisible = NO;
    require(solar.selectedSpacecraftIndex == 1 && solar.visibleSpacecraftCount == 0, "master hiding preserves selection while suppressing drawing");
    [solar pickBodyAtPoint:click];
    require(solar.selectedSpacecraftIndex == NSNotFound, "master hiding suppresses picking");
    [solar selectSpacecraft:0]; [solar focusSelection];
    require(solar.spacecraftVisible && solar.visibleSpacecraftCount == 2, "focus reenables master visibility");

    __block NSString* description = nil;
    solar.selectionChanged = ^(NSString* text) { description = text; };
    const auto focused = [solar cameraState];
    const auto replacement = model();
    [solar setSpacecraftSnapshot:evaluate_spacecraft_snapshot(replacement, 100.5)];
    require(solar.selectedSpacecraftIndex == NSNotFound && same([solar cameraState], focused), "reloading equal content with a new model clears stale selection and keeps camera");
    require(![description containsString:@"Probe"], "reloading removes stale selection description");
    [solar setSpacecraftSnapshot:evaluate_spacecraft_snapshot(replacement, 101.5)];
    require(same([solar cameraState], focused), "reloading also cancels stale follow state");
    [solar selectSpacecraft:1];
    [solar setSpacecraftSnapshot:nullptr];
    require(solar.selectedSpacecraftIndex == NSNotFound && solar.visibleSpacecraftCount == 0, "unloading clears selection and drawable snapshot");
    [solar selectSpacecraft:0];
    require(solar.selectedSpacecraftIndex == NSNotFound, "unloaded data cannot be selected");
}

void synthetic_smoke_restores_spacecraft() {
    const auto source = model();
    const auto frame = evaluate_spacecraft_snapshot(source, 100.5);
    SolarSystemView* solar = view();
    [solar setSpacecraftSnapshot:frame]; [solar selectSpacecraft:1]; [solar focusSelection];
    solar.spacecraftDisplayOptions = {false, true, true};
    for (BOOL visible : {NO, YES}) {
        solar.spacecraftVisible = visible;
        const auto before = [solar cameraState];
        require([solar runCameraSmokeTest], "synthetic camera smoke succeeds with active spacecraft selection");
        require(same([solar cameraState], before) && solar.selectedSpacecraftIndex == 1 && solar.spacecraftVisible == visible,
            "synthetic camera smoke restores spacecraft camera, selection and master visibility");
        const auto options = solar.spacecraftDisplayOptions;
        require(!options.points && options.labels && options.orbits, "synthetic scene preserves independent display settings");
    }
    const auto later = evaluate_spacecraft_snapshot(source, 101.5);
    [solar setSpacecraftSnapshot:later];
    require(same([solar cameraState].target, *later->positions[1]), "synthetic smoke restores live follow state and source identity");
    [solar showEarthMoon];
    require(solar.visibleSpacecraftCount == 0, "physical Earth-Moon mode suppresses spacecraft overview markers");
}
}
int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            focus_follow_and_unresolved(); atomic_snapshot_rejection(); selection_reload_and_picking(); synthetic_smoke_restores_spacecraft();
            std::cout << "Solar spacecraft tests passed: " << checks << " checks\n";
            return 0;
        } catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
