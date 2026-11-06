#import "../src/GalaxyOverlay.h"
#include "our_galaxy_navigation.hpp"
#include "OurGalaxyRadiativeRenderer.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

@interface GenerationAwareTestView : NSView
@property(nonatomic) NSUInteger sceneInvalidations;
@property(nonatomic) NSUInteger publishedRedraws;
@end
@implementation GenerationAwareTestView
- (void)setNeedsDisplay:(BOOL)needsDisplay {
    if (needsDisplay) ++_sceneInvalidations;
    [super setNeedsDisplay:needsDisplay];
}
- (void)redrawPublishedScene {
    ++_publishedRedraws;
    [super setNeedsDisplay:YES];
}
@end

@interface OrdinaryTestView : NSView
@property(nonatomic) NSUInteger redraws;
@end
@implementation OrdinaryTestView
- (void)setNeedsDisplay:(BOOL)needsDisplay {
    if (needsDisplay) ++_redraws;
    [super setNeedsDisplay:needsDisplay];
}
@end

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
NSBitmapImageRep *drawImage(GalaxyOverlay *overlay, const GalaxyCameraPc& camera, bool opaqueBackground = false,
                          int scale = 1, RendererDisplayOptions quality = {}, bool flipped = false) {
    NSBitmapImageRep *image = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:512 * scale pixelsHigh:512 * scale bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
        isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:image];
    if (flipped) context = [NSGraphicsContext graphicsContextWithCGContext:context.CGContext flipped:YES];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    if (flipped) {
        // 実ビューと同じ左上原点にし、NSImage の respectFlipped と preview の座標を揃える。
        CGContextTranslateCTM(context.CGContext, 0, 512 * scale);
        CGContextScaleCTM(context.CGContext, scale, -scale);
    } else CGContextScaleCTM(context.CGContext, scale, scale);
    CGContextSetShouldAntialias(context.CGContext, quality.antialias);
    if (opaqueBackground) {
        [[NSColor colorWithSRGBRed:.1 green:.2 blue:.3 alpha:1] setFill];
        NSRectFill(NSMakeRect(0, 0, 512, 512));
    }
    [overlay drawInRect:NSMakeRect(0, 0, 512, 512) camera:camera quality:quality scale:scale];
    [NSGraphicsContext restoreGraphicsState];
    return image;
}
void draw(GalaxyOverlay *overlay, const GalaxyCameraPc& camera) { (void)drawImage(overlay, camera); }
void spin() { [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]]; }
template<class F> void waitFor(F condition, const char *message) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:10];
    while (!condition() && [deadline timeIntervalSinceNow] > 0) spin();
    check(condition(), message);
}
void extendedObjectsMatchPaintedPixels() {
    constexpr double pi = 3.14159265358979323846;
    constexpr double focalLength = 256 / 0.41421356237309504880;
    std::array<bool, 4> checkedClippedBoundary{};
    for (const auto family : {GalaxySpatialFamily::globular_cluster, GalaxySpatialFamily::nearby_galaxy}) {
        PlusGlobularClusterRecord cluster;
        cluster.distance_pc = 100;
        cluster.half_light_radius_pc = 1;
        PlusNearbyGalaxyRecord galaxy;
        galaxy.distance_pc = 100;
        galaxy.angular_diameter_arcminutes = 68.7549354f;
        const double physicalRadius = family == GalaxySpatialFamily::globular_cluster ? 1 :
            double(galaxy.distance_pc) * (double(galaxy.angular_diameter_arcminutes) * pi / 21600);
        const GalaxySpatialSource source = family == GalaxySpatialFamily::globular_cluster
            ? GalaxySpatialSource(PlusGlobularClusterCatalog{{"extended-gc", {}}, {cluster}})
            : GalaxySpatialSource(PlusNearbyGalaxyCatalog{{"extended-nbg", {}}, {galaxy}});
        const auto model = std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{source});
        const GalaxySpatialRecordId id{family, 0, 0};
        struct Scenario { double radius, centerX, centerY; NSPoint inside, outside; };
        // 中心の近傍判定では拾えない画素を使い、画面外の中心と巨大円の境界も通す。
        const std::array<Scenario, 4> scenarios{{
            {64, 256, 256, {296, 256}, {336, 256}},
            {96, 576, 256, {500, 256}, {464, 256}},
            {1e12, 1e12 * std::cos(.37) + 256.17, 1e12 * std::sin(.37) + 256.31,
                {400, 400}, {100, 100}},
            {1e18, 1e18 / std::sqrt(2.0) + 256, 1e18 / std::sqrt(2.0) + 256, {480, 480}, {32, 32}}
        }};
        for (const auto& scenario : scenarios) for (int scale : {1, 2}) {
            GalaxyCameraPc camera{*model->row(id).position, 0, 0, physicalRadius * focalLength / scenario.radius};
            camera.pan(scenario.centerX - 256, scenario.centerY - 256, 512, 512);
            NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
            GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
            [overlay setModel:model];
            RendererDisplayOptions quality;
            quality.antialias = false;
            const GalaxyProjector projector(camera, 512, 512);
            const auto shape = galaxy_spatial_shape(*model, id, projector, true);
            check(shape.has_value(), "extended fixture shape is missing");
            const auto verify = [&](NSBitmapImageRep *image) {
                if ([overlay diagnostics].displayed_drawn != 1 || ![overlay isRecordDisplayed:id])
                    std::cerr << "extended display: family=" << int(family) << " radius=" << scenario.radius
                              << " scale=" << scale << " display=" << int([overlay diagnostics].display)
                              << " count=" << [overlay diagnostics].displayed_drawn
                              << " rectangles=" << (shape->clipping ? shape->clipping->rectangles.size() : 0) << '\n';
                check([overlay diagnostics].displayed_drawn == 1 && [overlay isRecordDisplayed:id],
                      "extended object must remain displayed when its center leaves the viewport");
                const auto verifyPick = [&](NSPoint point, bool painted) {
                    const auto result = std::make_shared<PickResult>();
                    [overlay pickAtPoint:point camera:camera completion:^(std::optional<GalaxySpatialRecordId> selection) {
                        result->picked = selection; result->called = true;
                    }];
                    waitFor([&] { return result->called; }, "extended object pick did not finish");
                    if (!(painted ? result->picked && *result->picked == id : !result->picked))
                        std::cerr << "extended pick: family=" << int(family) << " radius=" << scenario.radius
                                  << " scale=" << scale << " display=" << int([overlay diagnostics].display)
                                  << " point=" << point.x << ',' << point.y << " painted=" << painted
                                  << " picked=" << bool(result->picked) << " contains=" << shape->contains(point.x, point.y)
                                  << " rectangles=" << (shape->clipping ? shape->clipping->rectangles.size() : 0) << '\n';
                    check(painted ? result->picked && *result->picked == id : !result->picked,
                          "extended object pick disagrees with the painted pixel");
                };
                for (bool inside : {true, false}) {
                    auto point = inside ? scenario.inside : scenario.outside;
                    point.x += 0.5 / scale;
                    point.y += 0.5 / scale;
                    const int x = int(std::floor(point.x * scale));
                    const int y = int(std::floor(point.y * scale));
                    const double alpha = [[image colorAtX:x y:y] alphaComponent];
                    if (!(inside ? alpha > .99 : alpha == 0))
                        std::cerr << "extended pixel: family=" << int(family) << " radius=" << scenario.radius
                                  << " scale=" << scale << " display=" << int([overlay diagnostics].display)
                                  << " point=" << point.x << ',' << point.y << " alpha=" << alpha << '\n';
                    check(inside ? alpha > .99 : alpha == 0,
                          "extended object did not paint the expected interior and exterior pixels");
                    verifyPick(point, inside);
                }
                if (shape->clipping && shape->clipping->budget_exhausted) {
                    const auto* pixels = image.bitmapData;
                    bool found = false;
                    // 元の解析円と実画素が異なる境界を探し、近似前の円で選択する回帰を捕まえる。
                    for (int y = 0; y < 512 * scale && !found; ++y) for (int x = 0; x < 512 * scale; ++x) {
                        const NSPoint point{(x + .5) / scale, (y + .5) / scale};
                        const bool originalCircle = std::hypot(point.x - shape->center.x,
                            point.y - shape->center.y) <= shape->radius;
                        const auto alpha = pixels[y * image.bytesPerRow + x * 4 + 3];
                        if (alpha != 0 && alpha != 255) continue;
                        const bool painted = alpha == 255;
                        if (painted == originalCircle) continue;
                        // 端画素の rasterize 規則を除き、矩形の幾何と実画素が一致する場所を使う。
                        if (painted != shape->contains(point.x, point.y)) continue;
                        verifyPick(point, painted);
                        found = true;
                        const bool complete = [overlay diagnostics].display == GalaxyOverlayDisplay::complete;
                        checkedClippedBoundary[2 * (scale - 1) + complete] = true;
                        break;
                    }
                }
            };
            auto image = drawImage(overlay, camera, false, scale, quality, true);
            check([overlay diagnostics].display == GalaxyOverlayDisplay::preview,
                  "extended object test must begin in preview");
            verify(image);
            waitFor([&] {
                image = drawImage(overlay, camera, false, scale, quality, true);
                return [overlay diagnostics].display == GalaxyOverlayDisplay::complete;
            }, "extended object complete image did not finish");
            verify(image);
        }
    }
    if (!std::all_of(checkedClippedBoundary.begin(), checkedClippedBoundary.end(), [](bool value) { return value; }))
        std::cerr << "clipped boundary coverage: " << checkedClippedBoundary[0] << checkedClippedBoundary[1]
                  << checkedClippedBoundary[2] << checkedClippedBoundary[3] << '\n';
    check(std::all_of(checkedClippedBoundary.begin(), checkedClippedBoundary.end(), [](bool value) { return value; }),
          "fixture did not exercise a budget-limited painted boundary in every mode and backing scale");
}
void asynchronousRedrawDoesNotInvalidateScene() {
    GenerationAwareTestView *view = [[GenerationAwareTestView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
    [overlay setModel:fixture()];
    const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
    draw(overlay, camera);
    view.sceneInvalidations = 0;
    view.publishedRedraws = 0;
    view.needsDisplay = NO;
    waitFor([&] { return view.publishedRedraws > 0; }, "asynchronous image did not request a redraw");
    check(view.sceneInvalidations == 0,
          "asynchronous image invalidated the scene instead of redrawing it");
    draw(overlay, camera);
    check([overlay diagnostics].display == GalaxyOverlayDisplay::complete,
          "published redraw did not show the completed image");
    const auto stale = std::make_shared<PickResult>();
    [overlay pickAtPoint:NSMakePoint(256, 256) camera:camera completion:^(std::optional<GalaxySpatialRecordId> selection) {
        stale->picked = selection; stale->called = true;
    }];
    auto panned = camera;
    panned.pan(1, 0, 512, 512);
    draw(overlay, panned);
    auto diagnostics = [overlay diagnostics];
    check(diagnostics.requested && diagnostics.requested->camera.target_offset_au.y != 0,
          "pan residual was omitted from request");
    check(diagnostics.display == GalaxyOverlayDisplay::preview,
          "pan residual incorrectly reused the old image");
    waitFor([&] { draw(overlay, panned); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "pan residual did not produce a complete image");
    check(!stale->called, "pan residual did not invalidate an old pick");
    const auto oldFovPick = std::make_shared<PickResult>();
    [overlay pickAtPoint:NSMakePoint(256, 256) camera:panned completion:^(std::optional<GalaxySpatialRecordId> selection) {
        oldFovPick->picked = selection; oldFovPick->called = true;
    }];
    auto wider = panned;
    wider.vertical_fov_deg = 90;
    draw(overlay, wider);
    diagnostics = [overlay diagnostics];
    check(diagnostics.requested && diagnostics.requested->camera.vertical_fov_deg == 90 &&
          diagnostics.display == GalaxyOverlayDisplay::preview, "FOV reused the previous image");
    waitFor([&] { draw(overlay, wider); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "FOV did not produce a complete image");
    check(!oldFovPick->called, "FOV change did not invalidate an old pick");

    OrdinaryTestView *plainView = [[OrdinaryTestView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *plainOverlay = [[GalaxyOverlay alloc] initWithView:plainView];
    [plainOverlay setModel:fixture()];
    draw(plainOverlay, camera);
    plainView.redraws = 0;
    waitFor([&] { return plainView.redraws > 0; }, "ordinary view was not redrawn");
}
NSPoint position(const GalaxySpatialModel& model, GalaxySpatialRecordId id, const GalaxyCameraPc& camera) {
    const auto row = model.row(id);
    check(row.position.has_value(), "fixture position missing");
    const auto point = GalaxyProjector(camera, 512, 512).project(*row.position);
    check(point.has_value(), "fixture projection missing");
    return NSMakePoint(point->x, point->y);
}
void previewAndCompleteUseSameSdssColor() {
    for (bool reverse : {false, true}) {
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
        GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
        auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
            std::vector<SdssSpatialSource>{{SdssKind::galaxy, "colors", {
                {{0, 0}, reverse ? 2.0f : 1.0f, reverse ? -0.26f : 0.42f},
                {{0, 0}, reverse ? 1.0f : 2.0f, reverse ? 0.42f : -0.26f},
                {{0, 0}, 1, std::numeric_limits<float>::quiet_NaN()},
                {{0, 0}, 1, std::numeric_limits<float>::infinity()},
                {{0, 0}, 1, -std::numeric_limits<float>::infinity()}}}}));
        const auto model = std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{GalaxySdssSource{snapshot, 0}});
        [overlay setModel:model];
        const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
        const GalaxySpatialRecordId id{GalaxySpatialFamily::sdss_galaxy, 0, 0};
        const NSPoint point = position(*model, id, camera);
        const auto visibleColor = galaxy_point_color(*model, {GalaxySpatialFamily::sdss_galaxy, 0, 1});
        const auto checkPick = [&] {
            const auto picked = std::make_shared<PickResult>();
            [overlay pickAtPoint:point camera:camera completion:^(std::optional<GalaxySpatialRecordId> selection) {
                picked->picked = selection; picked->called = true;
            }];
            waitFor([&] { return picked->called; }, "color fixture pick did not finish");
            check(picked->picked && picked->picked->ordinal == 1, "visible overlapping eClass row must be selected");
        };
        const auto matchingPixel = [&](NSBitmapImageRep *image) {
            for (int y = int(point.y) - 2; y <= int(point.y) + 2; ++y)
                for (int x = int(point.x) - 2; x <= int(point.x) + 2; ++x) {
                    NSColor *pixel = [[image colorAtX:x y:y] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
                    if (pixel.alphaComponent > 0.95 && std::abs(pixel.redComponent - visibleColor.red) < 0.02 &&
                        std::abs(pixel.greenComponent - visibleColor.green) < 0.02 &&
                        std::abs(pixel.blueComponent - visibleColor.blue) < 0.02) return true;
                }
            return false;
        };
        NSBitmapImageRep *preview = drawImage(overlay, camera);
        check([overlay diagnostics].display == GalaxyOverlayDisplay::preview && matchingPixel(preview),
              "preview must draw the last overlapping eClass color");
        for (std::size_t i = 2; i < 5; ++i)
            check(![overlay isRecordDisplayed:{GalaxySpatialFamily::sdss_galaxy, 0, i}],
                  "nonfinite eClass must not appear in preview");
        checkPick();
        waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
                "color image did not complete");
        check(matchingPixel(drawImage(overlay, camera)), "complete image must match preview overlapping eClass color");
        for (std::size_t i = 2; i < 5; ++i)
            check(![overlay isRecordDisplayed:{GalaxySpatialFamily::sdss_galaxy, 0, i}],
                  "nonfinite eClass must not appear in complete image or be selectable");
        check([overlay diagnostics].displayed_drawn == 2, "nonfinite eClass must not prevent valid rows rendering");
        checkPick();
    }
}
void previewAndCompletePartialOverlapPick() {
    const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
    std::shared_ptr<const GalaxySpatialModel> model;
    NSPoint click{};
    for (double ra = -0.5; ra <= 0.5 && !model; ra += 0.05) {
        for (double dec = -0.5; dec <= 0.5 && !model; dec += 0.05) {
            auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
                std::vector<SdssSpatialSource>{{SdssKind::galaxy, "partial", {
                    {{0, 0}, 1, -0.26f}, {{ra < 0 ? 360 + ra : ra, dec}, 1, 0.42f}}}}));
            auto candidate = std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{GalaxySdssSource{snapshot, 0}});
            const auto first = position(*candidate, {GalaxySpatialFamily::sdss_galaxy, 0, 0}, camera);
            const auto second = position(*candidate, {GalaxySpatialFamily::sdss_galaxy, 0, 1}, camera);
            const NSPoint candidateClick = NSMakePoint(std::max(first.x, second.x) + .01, std::max(first.y, second.y) + .01);
            const double firstDistance = std::hypot(candidateClick.x - first.x, candidateClick.y - first.y);
            const double secondDistance = std::hypot(candidateClick.x - second.x, candidateClick.y - second.y);
            if (secondDistance > firstDistance + .1 && secondDistance < 1.0 &&
                galaxy_spatial_point_contains(GalaxySpatialFamily::sdss_galaxy, first.x, first.y, candidateClick.x, candidateClick.y, true) &&
                galaxy_spatial_point_contains(GalaxySpatialFamily::sdss_galaxy, second.x, second.y, candidateClick.x, candidateClick.y, true)) {
                model = candidate; click = candidateClick;
            }
        }
    }
    check(bool(model), "partial overlap fixture missing");
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
    [overlay setModel:model];
    const auto checkPick = [&] {
        const auto result = std::make_shared<PickResult>();
        [overlay pickAtPoint:click camera:camera completion:^(std::optional<GalaxySpatialRecordId> selected) {
            result->picked = selected; result->called = true;
        }];
        waitFor([&] { return result->called; }, "partial overlap pick did not finish");
        check(result->picked && result->picked->ordinal == 1, "last painted partial overlap row selected");
    };
    draw(overlay, camera);
    check([overlay diagnostics].display == GalaxyOverlayDisplay::preview, "partial overlap preview missing");
    checkPick();
    waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "partial overlap image did not complete");
    checkPick();
}
void previewAndCompleteLayerOrder() {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
    auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
        std::vector<SdssSpatialSource>{{SdssKind::galaxy, "layer", {{{0, 0}, 1, -0.26f}}}}));
    auto model = std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{GalaxySdssSource{snapshot, 0}});
    auto hip = std::make_shared<HipSpatialModel>();
    hip->points.push_back({0, 1, {0, 0, 0}});
    [overlay setModel:model];
    [overlay setHipModel:hip];
    const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
    const auto blueAtCenter = [](NSBitmapImageRep *image) {
        double blue = 0;
        for (int y = 254; y <= 258; ++y) for (int x = 254; x <= 258; ++x) {
            NSColor *pixel = [[image colorAtX:x y:y] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
            if (pixel.alphaComponent > .95) blue = std::max(blue, double(pixel.blueComponent));
        }
        return blue;
    };
    const auto checkHipPick = [&] {
        const auto done = std::make_shared<bool>(false);
        const auto selection = std::make_shared<GalaxyOverlaySelection>();
        [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection result) {
            *selection = result; *done = true;
        }];
        waitFor([&] { return *done; }, "layer pick did not finish");
        check(selection->hip && !selection->galaxy, "painted HIP must win over nearer galaxy");
    };
    auto preview = drawImage(overlay, camera);
    check([overlay diagnostics].display == GalaxyOverlayDisplay::preview, "must inspect preview layer order");
    checkHipPick();
    check(blueAtCenter(preview) > .65, "preview HIP must blend over the galaxy layer");
    waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "layer fixture did not complete");
    check(blueAtCenter(drawImage(overlay, camera)) > .55, "complete HIP must blend over the galaxy layer");
    checkHipPick();
    [overlay setHipVisible:NO];
    draw(overlay, camera);
    const auto done = std::make_shared<bool>(false);
    const auto selection = std::make_shared<GalaxyOverlaySelection>();
    [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection result) {
        *selection = result; *done = true;
    }];
    waitFor([&] { return *done; }, "hidden layer pick did not finish");
    check(selection->galaxy && !selection->hip, "hidden HIP cannot win over visible galaxy");
}
void additivePreviewWinsOverPaintedGalaxy() {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
    auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
        std::vector<SdssSpatialSource>{{SdssKind::galaxy, "layer", {{{0, 0}, 1, -0.26f}}}}));
    auto galaxy = std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{GalaxySdssSource{snapshot, 0}});
    auto our = std::make_shared<OurGalaxyModel>();
    for (auto& map : our->maps) { map.width = 512; map.height = 512; map.values.assign(512 * 512, 0); }
    our->groups[0].positions.push_back({0, 0, 0});
    [overlay setModel:galaxy]; [overlay setOurGalaxyModel:our];
    const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 3000};
    draw(overlay, camera);
    check([overlay diagnostics].display == GalaxyOverlayDisplay::preview && [overlay diagnostics].our_galaxy_drawn == 1,
          "additive fixture must display preview point");
    const auto done = std::make_shared<bool>(false);
    const auto selected = std::make_shared<GalaxyOverlaySelection>();
    [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection result) {
        *selected = result; *done = true;
    }];
    waitFor([&] { return *done; }, "additive preview pick did not finish");
    check(selected->our_galaxy_point && !selected->galaxy, "additive point wins painted galaxy by layer assumption");
    waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "additive image did not complete");
    *done = false; *selected = {};
    [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection result) {
        *selected = result; *done = true;
    }];
    waitFor([&] { return *done; }, "additive complete pick did not finish");
    check(selected->our_galaxy_point && !selected->galaxy, "additive complete point wins painted galaxy");
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
    const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 3000};
    draw(overlay, camera);
    const auto preview = [overlay diagnostics];
    check(preview.display == GalaxyOverlayDisplay::preview && preview.our_galaxy_drawn == 1 &&
          preview.hip_drawn > 0 && preview.displayed_drawn > 0,
          "invalid OurGalaxy points prevented valid preview layers");
    check([overlay isHipDisplayed:0] && [overlay isRecordDisplayed:{GalaxySpatialFamily::sdss_galaxy, 0, 0}],
          "invalid OurGalaxy points made surviving preview layers unselectable");
    const OurGalaxyPointId valid{OurGalaxyPointGroup::disk1, 3};
    check([overlay displayedOurGalaxyPointPosition:valid].has_value(),
          "preview selects a valid source ordinal even if the radiative model is invalid");
    waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "radiative failure prevented other layers from completing");
    const auto state = [overlay diagnostics];
    check(state.displayed_drawn > 0 && state.hip_drawn > 0, "radiative failure hid HIP or galaxy");
    check([overlay isHipDisplayed:0] && [overlay isRecordDisplayed:{GalaxySpatialFamily::sdss_galaxy, 0, 0}],
          "surviving layers must remain selectable");
    check(![overlay displayedOurGalaxyPointPosition:valid],
          "point is not selectable when complete image generation failed");
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
    check(selectedVisible->our_galaxy_point &&
          *selectedVisible->our_galaxy_point == OurGalaxyPointId{OurGalaxyPointGroup::disk1, 0},
          "visible OurGalaxy point must retain its source ordinal");
    const auto staleOur = std::make_shared<bool>(false);
    [ourOverlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:wide completion:^(GalaxyOverlaySelection) {
        *staleOur = true;
    }];
    [ourOverlay setOurGalaxyModel:std::make_shared<OurGalaxyModel>()];
    draw(ourOverlay, wide);
    waitFor([&] { draw(ourOverlay, wide); return [ourOverlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "replacement OurGalaxy model did not finish");
    check(!*staleOur, "pick from replaced OurGalaxy model must be discarded");
    [ourOverlay setOurGalaxyModel:our];
    [ourOverlay setOurGalaxyVisible:NO];
    draw(ourOverlay, wide);
    check([ourOverlay diagnostics].our_galaxy_drawn == 0, "hidden OurGalaxy appeared in preview");
    const auto hiddenOur = std::make_shared<bool>(false);
    const auto selectedOur = std::make_shared<GalaxyOverlaySelection>();
    [ourOverlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:wide completion:^(GalaxyOverlaySelection selection) {
        *selectedOur = selection; *hiddenOur = true;
    }];
    waitFor([&] { return *hiddenOur; }, "hidden OurGalaxy pick did not finish");
    check(!selectedOur->our_galaxy && !selectedOur->our_galaxy_point,
          "hidden OurGalaxy was selectable");
    waitFor([&] { draw(ourOverlay, wide); return [ourOverlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "all hidden layers never reached a complete frame");
    check([ourOverlay diagnostics].our_galaxy_drawn == 0, "hidden OurGalaxy appeared in complete frame");
}
void transparentOurGalaxyIsNotSelectable() {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
    auto model = std::make_shared<OurGalaxyModel>();
    for (auto& map : model->maps) {
        map.width = 512; map.height = 512; map.values.assign(512 * 512, 0);
    }
    model->groups[0].positions.push_back({0, 0, 0});
    [overlay setOurGalaxyModel:model];
    const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
    const OurGalaxyPointId id{OurGalaxyPointGroup::disk1, 0};
    draw(overlay, camera);
    check(![overlay displayedOurGalaxyPointPosition:id], "transparent preview point must not be selectable");
    check([overlay diagnostics].our_galaxy_drawn == 0, "transparent preview point must not be drawn");
    const auto previewDone = std::make_shared<bool>(false);
    const auto previewSelection = std::make_shared<GalaxyOverlaySelection>();
    [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection result) {
        *previewSelection = result; *previewDone = true;
    }];
    waitFor([&] { return *previewDone; }, "transparent preview point pick did not finish");
    check(!previewSelection->our_galaxy_point, "transparent preview point was picked");
    waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "transparent OurGalaxy did not finish");
    check(![overlay displayedOurGalaxyPointPosition:id], "transparent complete point must not be selectable");
    const auto done = std::make_shared<bool>(false);
    const auto selection = std::make_shared<GalaxyOverlaySelection>();
    [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection result) {
        *selection = result; *done = true;
    }];
    waitFor([&] { return *done; }, "transparent point pick did not finish");
    check(!selection->our_galaxy_point, "transparent complete point was picked");
}
void ourGalaxyOverlapSelection() {
    auto model = std::make_shared<OurGalaxyModel>();
    for (auto& map : model->maps) {
        map.width = 512; map.height = 512; map.values.assign(512 * 512, 0);
    }
    model->groups[0].positions = {{0, 0, 0}, {0, 0, 0}};
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
    [overlay setOurGalaxyModel:model];
    const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 2700};
    draw(overlay, camera);
    check([overlay diagnostics].display == GalaxyOverlayDisplay::preview, "overlap test must begin in preview");
    const auto pickLast = [&] {
        const auto done = std::make_shared<bool>(false);
        const auto selected = std::make_shared<GalaxyOverlaySelection>();
        [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection result) {
            *selected = result; *done = true;
        }];
        waitFor([&] { return *done; }, "overlap pick did not finish");
        check(selected->our_galaxy_point &&
              *selected->our_galaxy_point == OurGalaxyPointId{OurGalaxyPointGroup::disk1, 1},
              "OurGalaxy overlap must select the last painted ordinal");
    };
    pickLast();
    waitFor([&] { draw(overlay, camera); return [overlay diagnostics].display == GalaxyOverlayDisplay::complete; },
            "OurGalaxy overlap image did not finish");
    pickLast();
}
void previewOurGalaxyViewportBoundaries() {
    auto model = std::make_shared<OurGalaxyModel>();
    // 最も暗い群と距離フェード閾値直上で、境界の画素が量子化で消えないことも確かめる。
    model->groups[2].positions.push_back({0, 0, 0});
    const OurGalaxyPointId id{OurGalaxyPointGroup::disk_ob, 0};
    const double tanFov = 0.41421356237309504880;
    for (int scale : {1, 2}) for (int sx : {-1, 1}) for (int sy : {-1, 1}) {
        const double distance = 1035 / std::sqrt(1 + 2 * tanFov * tanFov);
        const GalaxyCameraPc camera{{0, -sx * tanFov * distance, sy * tanFov * distance}, 0, 0, distance};
        const auto point = GalaxyProjector(camera, 512, 512).project({0, 0, 0});
        check(point && std::abs(point->x - (sx > 0 ? 512 : 0)) < 1e-9 &&
              std::abs(point->y - (sy > 0 ? 512 : 0)) < 1e-9, "point must be at viewport corner");
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
        GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
        [overlay setOurGalaxyModel:model];
        const auto image = drawImage(overlay, camera, false, scale);
        check([overlay diagnostics].display == GalaxyOverlayDisplay::preview, "boundary test must inspect preview");
        double maxPixelAlpha = 0;
        const int x0 = sx > 0 ? 509 * scale : 0, y0 = sy > 0 ? 0 : 509 * scale;
        for (int y = y0; y < y0 + 3 * scale; ++y) for (int x = x0; x < x0 + 3 * scale; ++x)
            maxPixelAlpha = std::max(maxPixelAlpha, double([[image colorAtX:x y:y] alphaComponent]));
        check(maxPixelAlpha > 0 && [overlay displayedOurGalaxyPointPosition:id],
              "viewport corner point must be drawn and selectable");
        const auto done = std::make_shared<bool>(false);
        const auto selection = std::make_shared<GalaxyOverlaySelection>();
        [overlay pickSpatialAtPoint:NSMakePoint(point->x, point->y) camera:camera completion:^(GalaxyOverlaySelection result) {
            *selection = result; *done = true;
        }];
        waitFor([&] { return *done; }, "viewport corner pick did not finish");
        check(selection->our_galaxy_point && *selection->our_galaxy_point == id,
              "visible corner point must be selected");
    }
}
void previewOurGalaxyDistanceFade() {
    auto model = std::make_shared<OurGalaxyModel>();
    model->groups[0].positions.push_back({0, 0, 0});
    const OurGalaxyPointId id{OurGalaxyPointGroup::disk1, 0};
    for (double distance : {1000.0, 1033.0, 1035.0, 1850.0, 2700.0}) {
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
        GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
        [overlay setOurGalaxyModel:model];
        const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, distance};
        const auto image = drawImage(overlay, camera);
        check([overlay diagnostics].display == GalaxyOverlayDisplay::preview, "distance fade must inspect preview");
        const float alpha = our_galaxy_alpha(camera);
        check((alpha > 0) == (distance >= 1035), "Sun distance fade threshold changed");
        check((alpha > 0) == [overlay displayedOurGalaxyPointPosition:id].has_value(),
              "preview point visibility must follow distance alpha");
        check(([overlay diagnostics].our_galaxy_drawn > 0) == (alpha > 0),
              "preview drawn count must follow distance alpha");
        double maxPixelAlpha = 0;
        for (int y = 254; y <= 258; ++y) for (int x = 254; x <= 258; ++x) {
            NSColor *pixel = [[image colorAtX:x y:y] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
            maxPixelAlpha = std::max(maxPixelAlpha, double(pixel.alphaComponent));
        }
        check((maxPixelAlpha > 0) == (alpha > 0),
              "threshold preview must not be fully transparent");
        check(std::abs(maxPixelAlpha - .4 * alpha) < .004,
              "preview point opacity must follow distance alpha");
        const auto done = std::make_shared<bool>(false);
        const auto selection = std::make_shared<GalaxyOverlaySelection>();
        [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection result) {
            *selection = result; *done = true;
        }];
        waitFor([&] { return *done; }, "distance fade pick did not finish");
        check(selection->our_galaxy_point.has_value() == (alpha > 0),
              "preview pick must follow distance alpha");
    }
}
void previewOurGalaxyCenterFade() {
    const auto center = our_galaxy_center({{0, 0, 0}});
    auto model = std::make_shared<OurGalaxyModel>();
    model->groups[0].positions.push_back({float(center.x_pc), float(center.y_pc), float(center.z_pc)});
    const OurGalaxyPointId id{OurGalaxyPointGroup::disk1, 0};
    for (double distance : {1000.0, 1020.0, 1050.0, 2700.0}) {
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
        GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
        [overlay setOurGalaxyModel:model];
        const GalaxyCameraPc camera{center, 0, 0, distance};
        draw(overlay, camera);
        const float alpha = our_galaxy_alpha(camera);
        check((alpha > 0) == (distance >= 1050), "galactic center fade threshold changed");
        check((alpha > 0) == [overlay displayedOurGalaxyPointPosition:id].has_value(),
              "preview point visibility must follow galactic center fade");
        check(([overlay diagnostics].our_galaxy_drawn > 0) == (alpha > 0),
              "preview drawing must follow galactic center fade");
    }
}
void previewOurGalaxyPreservesOpaqueBackground() {
    auto model = std::make_shared<OurGalaxyModel>();
    model->groups[0].positions.push_back({0, 0, 0});
    for (double distance : {1035.0, 1850.0}) {
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
        GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
        [overlay setOurGalaxyModel:model];
        const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, distance};
        const auto image = drawImage(overlay, camera, true);
        check([overlay diagnostics].display == GalaxyOverlayDisplay::preview,
              "background blend test must inspect preview");
        NSColor *background = [[image colorAtX:250 y:250] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
        double maxBrightening = 0;
        for (int y = 254; y <= 258; ++y) for (int x = 254; x <= 258; ++x) {
            NSColor *pixel = [[image colorAtX:x y:y] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
            check(pixel.alphaComponent > .999, "preview must preserve opaque background alpha");
            check(pixel.redComponent + .001 >= background.redComponent &&
                  pixel.greenComponent + .001 >= background.greenComponent &&
                  pixel.blueComponent + .001 >= background.blueComponent,
                  "preview must not darken background");
            maxBrightening = std::max({maxBrightening, pixel.redComponent - background.redComponent,
                                      pixel.greenComponent - background.greenComponent,
                                      pixel.blueComponent - background.blueComponent});
        }
        check(maxBrightening >= 1.0 / 255.0, "preview point did not brighten the background");
    }
}
void outOfRangePreviewSkipsInvisibleOurGalaxy() {
    const auto center = our_galaxy_center({{0, 0, 0}});
    const GalaxyCameraPc camera{center, 0, 0, 1e8};
    check(hit_our_galaxy({{0, 0, 0}}, camera, 256, 256, 512, 512),
          "test ray must intersect the invisible galaxy fallback");
    for (bool includeHip : {false, true}) {
        NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
        GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
        auto model = std::make_shared<OurGalaxyModel>();
        for (auto& map : model->maps) {
            map.width = 512; map.height = 512; map.values.assign(512 * 512, 0);
        }
        [overlay setOurGalaxyModel:model];
        if (includeHip) {
            auto hip = std::make_shared<HipSpatialModel>();
            hip->points.push_back({0, 1, center});
            [overlay setHipModel:hip];
        }
        draw(overlay, camera);
        check([overlay diagnostics].display == GalaxyOverlayDisplay::preview,
              "out-of-range selection must inspect preview");
        const auto done = std::make_shared<bool>(false);
        const auto selection = std::make_shared<GalaxyOverlaySelection>();
        [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection result) {
            *selection = result; *done = true;
        }];
        waitFor([&] { return *done; }, "out-of-range preview pick did not finish");
        check(!selection->our_galaxy && !selection->our_galaxy_point,
              "out-of-range preview selected invisible OurGalaxy");
        check(selection->hip.has_value() == includeHip,
              "out-of-range OurGalaxy must not interfere with HIP selection");
    }
}
void ourGalaxyCompetesWithHip() {
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)];
    GalaxyOverlay *overlay = [[GalaxyOverlay alloc] initWithView:view];
    auto hip = std::make_shared<HipSpatialModel>();
    hip->points.push_back({0, 1, {0, 0, 0}});
    [overlay setHipModel:hip];
    const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 3000};
    const auto pick = [&](OurGalaxyRawPositionPc p) {
        auto model = std::make_shared<OurGalaxyModel>();
        model->groups[0].positions.push_back(p);
        [overlay setOurGalaxyModel:model];
        draw(overlay, camera);
        const auto done = std::make_shared<bool>(false);
        const auto selected = std::make_shared<GalaxyOverlaySelection>();
        [overlay pickSpatialAtPoint:NSMakePoint(256, 256) camera:camera completion:^(GalaxyOverlaySelection result) {
            *selected = result; *done = true;
        }];
        waitFor([&] { return *done; }, "preview competing point pick did not finish");
        return *selected;
    };
    const auto tied = pick({0, 0, 0});
    check(tied.hip && !tied.our_galaxy_point, "existing HIP wins exact point tie");
    const auto nearer = pick({1, 0, 0});
    check(nearer.hip && !nearer.our_galaxy_point, "painted HIP wins over the nearer additive layer");
    const auto displaced = pick({1, 0.05, 0});
    check(displaced.hip && !displaced.our_galaxy_point, "screen distance takes precedence over depth");
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

    for (GalaxySpatialRecordId id : {GalaxySpatialRecordId{GalaxySpatialFamily::sdss_galaxy, 0, 11997},
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
    previewAndCompleteLayerOrder();
    additivePreviewWinsOverPaintedGalaxy();
    radiativeFailureKeepsOtherLayers();
    visibilityControls();
    transparentOurGalaxyIsNotSelectable();
    ourGalaxyOverlapSelection();
    previewOurGalaxyViewportBoundaries();
    previewOurGalaxyDistanceFade();
    previewOurGalaxyCenterFade();
    previewOurGalaxyPreservesOpaqueBackground();
    outOfRangePreviewSkipsInvisibleOurGalaxy();
    ourGalaxyCompetesWithHip();
}
} // namespace
int main() {
    @autoreleasepool {
        try { extendedObjectsMatchPaintedPixels(); asynchronousRedrawDoesNotInvalidateScene(); previewAndCompleteUseSameSdssColor(); previewAndCompletePartialOverlapPick(); tests(); std::cout << "Galaxy overlay: PASS\n"; }
        catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
    }
}
