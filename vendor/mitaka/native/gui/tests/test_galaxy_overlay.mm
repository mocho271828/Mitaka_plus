#import "../src/GalaxyOverlay.h"
#include "our_galaxy_navigation.hpp"
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
void check(bool ok, const char* message) { if (!ok) throw std::runtime_error(message); }
struct PickResult { bool called = false; std::optional<GalaxySpatialRecordId> picked; };

std::shared_ptr<const GalaxySpatialModel> fixture() {
    std::vector<SdssRecord> rows(12001, {{0, 0}, 1, 0});
    rows[1] = {{150, 0}, 1, 0}; // 出典内の間引きで除外される原行。
    auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
        std::vector<SdssSpatialSource>{{SdssKind::galaxy, "gal", rows},
            {SdssKind::quasar, "qso", {{{30, 0}, 1, 0}}}}));
    PlusGlobularClusterCatalog clusters{{"gc", {1}}, {}};
    PlusGlobularClusterRecord cluster; cluster.right_ascension_degrees = 60; cluster.distance_pc = 1;
    clusters.records.push_back(cluster);
    PlusNearbyGalaxyCatalog galaxies{{"nbg", {1}}, {}};
    PlusNearbyGalaxyRecord galaxy; galaxy.right_ascension_degrees = 90; galaxy.distance_pc = 1;
    galaxies.records.push_back(galaxy);
    return std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{
        GalaxySdssSource{snapshot, 0}, GalaxySdssSource{snapshot, 1}, clusters, galaxies});
}
void draw(GalaxyOverlay *overlay, const GalaxyCameraPc& camera) {
    NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:512 pixelsHigh:512 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
        isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:image];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    [overlay drawInRect:NSMakeRect(0, 0, 512, 512) camera:camera quality:{} scale:1];
    [NSGraphicsContext restoreGraphicsState];
}
void spin() { [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]; }
template<class F> void waitFor(F condition, const char *message) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:10];
    while (!condition() && [deadline timeIntervalSinceNow] > 0) spin();
    check(condition(), message);
}
NSPoint position(const GalaxySpatialModel& model, GalaxySpatialRecordId id, const GalaxyCameraPc& camera) {
    const auto row = model.row(id);
    check(row.position.has_value(), "fixture position missing");
    const auto point = GalaxyProjector(camera, 512, 512).project(*row.position);
    check(point.has_value(), "fixture projection missing");
    return NSMakePoint(point->x, point->y);
}
void radiativeFailureKeepsOtherLayers() {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
    const auto galaxy = fixture();
    auto hip = std::make_shared<HipSpatialModel>();
    hip->points.push_back({0, 1, {0, 0, 0}});
    // 実際の放射モデルは 512×512 の二つの map を必須とする。
    auto invalidRadiative = std::make_shared<OurGalaxyModel>();
    invalidRadiative->groups[0].positions = {
        {std::numeric_limits<float>::quiet_NaN(), 0, 0},
        {std::numeric_limits<float>::infinity(), 0, 0},
        {std::numeric_limits<float>::max(), 0, 0},
        {0, 0, 0}};
    [overlay setModel:galaxy];
    [overlay setHipModel:hip];
    [overlay setOurGalaxyModel:invalidRadiative];
    const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
    draw(overlay, camera);
    const auto preview = [overlay diagnostics];
    check(preview.display == GalaxyOverlayDisplay::preview && preview.our_galaxy_drawn == 1 &&
          preview.hip_drawn > 0 && preview.displayed_drawn > 0,
          "invalid OurGalaxy points prevented valid preview layers");
    check([overlay isHipDisplayed:0] && [overlay isRecordDisplayed:{GalaxySpatialFamily::sdss_galaxy, 0, 0}],
          "invalid OurGalaxy points made surviving preview layers unselectable");
    waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "radiative failure prevented other layers from completing");
    const auto state = [overlay diagnostics];
    check(state.displayed_drawn > 0 && state.hip_drawn > 0, "radiative failure hid HIP or galaxy");
    check([overlay isHipDisplayed:0] && [overlay isRecordDisplayed:{GalaxySpatialFamily::sdss_galaxy, 0, 0}],
          "surviving layers must remain selectable");
    check([[overlay status] containsString:@"天の川"] && [[overlay status] containsString:@"radiative maps must be 512 by 512"],
          "radiative failure reason must remain visible");
    // callback が設定する needsDisplay を監視し、同じ失敗要求の再投入を検出する。
    view.needsDisplay = NO;
    for (int i = 0; i < 40; ++i) {
        draw(overlay, camera);
        spin();
        check([overlay diagnostics].display == GalaxyOverlayDisplay::complete && !view.needsDisplay,
              "failed layer retried the same request");
    }
}
void visibilityControls() {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
    const auto galaxy = fixture();
    auto hip = std::make_shared<HipSpatialModel>();
    hip->points.push_back({0, 1, {0, 0, 0}});
    [overlay setModel:galaxy];
    [overlay setHipModel:hip];
    const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
    waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "visible HIP did not finish rendering");
    check([overlay isHipDisplayed:0], "visible HIP must be displayed");
    const auto stale = std::make_shared<bool>(false);
    [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection) { *stale = true; }];
    [overlay setHipVisible:NO];
    draw(overlay, camera);
    check([overlay diagnostics].display == GalaxyOverlayDisplay::preview &&
          [overlay diagnostics].hip_drawn == 0 && ![overlay isHipDisplayed:0], "hidden HIP appeared in preview");
    waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "hidden HIP prevented SDSS rendering");
    check([overlay diagnostics].displayed_drawn > 0 && [overlay diagnostics].hip_drawn == 0 &&
          ![overlay isHipDisplayed:0] && !*stale, "hidden HIP rendered or stale pick survived");
    const auto hidden = std::make_shared<bool>(false);
    const auto selectedHidden = std::make_shared<GalaxyOverlaySelection>();
    [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection selection) {
        *selectedHidden = selection; *hidden = true;
    }];
    waitFor([&] { return *hidden; }, "hidden HIP pick did not finish");
    check(!selectedHidden->hip, "hidden HIP was selectable");
    [overlay setHipVisible:YES];
    draw(overlay, camera);
    check([overlay isHipDisplayed:0], "re-enabled HIP missing from preview");

    GalaxyOverlay *ourOverlay = [[GalaxyOverlay alloc] initWithView:view];
    auto our = std::make_shared<OurGalaxyModel>();
    const auto center = our_galaxy_center({{0, 0, 0}});
    our->groups[0].positions.push_back({static_cast<float>(center.x_pc), static_cast<float>(center.y_pc), static_cast<float>(center.z_pc)});
    [ourOverlay setOurGalaxyModel:our];
    const auto wide = frame_our_galaxy({{0, 0, 0}}, camera, 8000, 512, 512);
    draw(ourOverlay, wide);
    check([ourOverlay diagnostics].our_galaxy_drawn > 0, "visible OurGalaxy missing from preview");
    const auto visible = std::make_shared<bool>(false);
    const auto selectedVisible = std::make_shared<GalaxyOverlaySelection>();
    [ourOverlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:wide completion:^(GalaxyOverlaySelection selection) {
        *selectedVisible = selection; *visible = true;
    }];
    waitFor([&] { return *visible; }, "visible OurGalaxy pick did not finish");
    check(selectedVisible->our_galaxy, "visible OurGalaxy was not selectable");
    [ourOverlay setOurGalaxyVisible:NO];
    draw(ourOverlay, wide);
    check([ourOverlay diagnostics].our_galaxy_drawn == 0, "hidden OurGalaxy appeared in preview");
    const auto hiddenOur = std::make_shared<bool>(false);
    const auto selectedOur = std::make_shared<GalaxyOverlaySelection>();
    [ourOverlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:wide completion:^(GalaxyOverlaySelection selection) {
        *selectedOur = selection; *hiddenOur = true;
    }];
    waitFor([&] { return *hiddenOur; }, "hidden OurGalaxy pick did not finish");
    check(!selectedOur->our_galaxy, "hidden OurGalaxy was selectable");
    waitFor([&] { draw(ourOverlay, wide); return [ourOverlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "all hidden layers never reached a complete frame");
    check([ourOverlay diagnostics].our_galaxy_drawn == 0, "hidden OurGalaxy appeared in complete frame");
}
void tests() {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
    const auto model = fixture();
    [overlay setModel:model];
    check([overlay model] == model, "model injection");
    GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
    draw(overlay, camera);
    auto state = [overlay diagnostics];
    check(state.display == GalaxyOverlayDisplay::preview && state.displayed && state.requested,
          "first draw must be current preview");
    check(state.preview_rows > 0 && state.preview_rows <= 6000, "preview row budget");
    check(state.displayed_drawn > 0, "preview drawn count");

    for (GalaxySpatialRecordId id : {GalaxySpatialRecordId{GalaxySpatialFamily::sdss_galaxy, 0, 0},
             {GalaxySpatialFamily::sdss_quasar, 1, 0}, {GalaxySpatialFamily::globular_cluster, 2, 0},
             {GalaxySpatialFamily::nearby_galaxy, 3, 0}}) {
        check([overlay isRecordDisplayed:id], "sampled source must be displayed");
        const auto result = std::make_shared<PickResult>();
        [overlay pickAtPoint:position(*model, id, camera) camera:camera completion:^(std::optional<GalaxySpatialRecordId> selection) {
            result->picked = selection; result->called = true;
        }];
        waitFor([&] { return result->called; }, "preview pick did not finish");
        if (!result->picked || !(*result->picked == id)) {
            std::cerr << "failed source " << id.source_index << " at " << position(*model, id, camera).x << "," << position(*model, id, camera).y << '\n';
            if (result->picked) std::cerr << "picked source " << result->picked->source_index << " ordinal " << result->picked->ordinal << '\n';
            check(false, "preview must include each source");
        }
    }
    const GalaxySpatialRecordId omitted{GalaxySpatialFamily::sdss_galaxy, 0, 1};
    check(![overlay isRecordDisplayed:omitted], "unsampled row is not displayed");
    const auto result = std::make_shared<PickResult>();
    [overlay pickAtPoint:position(*model, omitted, camera) camera:camera completion:^(std::optional<GalaxySpatialRecordId> selection) {
        result->picked = selection; result->called = true;
    }];
    waitFor([&] { return result->called; }, "preview omitted pick did not finish");
    check(!result->picked || !(*result->picked == omitted), "preview picked an undisplayed row");

    auto next = camera; next.yaw_deg = 5;
    const auto stale = std::make_shared<PickResult>();
    [overlay pickAtPoint:NSMakePoint(256, 256) camera:camera completion:^(std::optional<GalaxySpatialRecordId> ignored) { (void)ignored; stale->called = true; }];
    draw(overlay, next);
    state = [overlay diagnostics];
    check(state.display == GalaxyOverlayDisplay::preview && state.displayed->camera.yaw_deg == 5,
          "new camera should display its own preview");
    waitFor([&] { draw(overlay, next); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "latest full image did not converge");
    state = [overlay diagnostics];
    check(state.displayed && state.displayed->camera.yaw_deg == 5 && state.preview_rows == 0,
          "full image camera must match latest request");
    check(!stale->called, "camera change must discard stale pick");
    check(state.displayed_drawn > 0 && [overlay isRecordDisplayed:omitted], "full image includes omitted row");
    const auto fullPick = std::make_shared<PickResult>();
    [overlay pickAtPoint:position(*model, omitted, next) camera:next completion:^(std::optional<GalaxySpatialRecordId> selection) {
        fullPick->picked = selection; fullPick->called = true;
    }];
    waitFor([&] { return fullPick->called; }, "full pick did not finish");
    check(fullPick->picked && *fullPick->picked == omitted, "full pick must include unsampled row");

    const auto staleVisibility = std::make_shared<PickResult>();
    [overlay pickAtPoint:NSMakePoint(256, 256) camera:next completion:^(std::optional<GalaxySpatialRecordId> ignored) { (void)ignored; staleVisibility->called = true; }];
    GalaxySpatialVisibility visibility; visibility.globular_clusters = false;
    [overlay setVisibility:visibility];
    check([overlay diagnostics].display == GalaxyOverlayDisplay::none, "visibility change invalidates display");
    draw(overlay, next);
    const GalaxySpatialRecordId hidden{GalaxySpatialFamily::globular_cluster, 2, 0};
    check(![overlay isRecordDisplayed:hidden], "hidden source excluded from preview");
    const auto hiddenPick = std::make_shared<PickResult>();
    [overlay pickAtPoint:position(*model, hidden, next) camera:next completion:^(std::optional<GalaxySpatialRecordId> selection) {
        hiddenPick->picked = selection; hiddenPick->called = true;
    }];
    waitFor([&] { return hiddenPick->called; }, "hidden pick did not finish");
    check(!hiddenPick->picked || !(*hiddenPick->picked == hidden), "hidden source must not be pickable");
    check(!staleVisibility->called, "visibility change must discard stale pick");
    waitFor([&] { draw(overlay, next); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "visibility change did not converge");
    check(![overlay isRecordDisplayed:hidden], "hidden source excluded from full image");

    auto freshModel = fixture();
    [overlay setModel:freshModel];
    check([overlay diagnostics].display == GalaxyOverlayDisplay::none, "model replacement clears display");
    draw(overlay, camera);
    check([overlay diagnostics].display == GalaxyOverlayDisplay::preview, "new model must not reuse old image");
    waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "replacement model did not converge");
    radiativeFailureKeepsOtherLayers();
    visibilityControls();
}
} // namespace
int main() {
    @autoreleasepool {
        try { tests(); std::cout << "Galaxy overlay: PASS\n"; }
        catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
    }
}
