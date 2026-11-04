#import "StarRenderer.h"
#import "SolarSceneRenderer.h"
#import "SkyView.h"
#import "HorizonView.h"
#import "SmallBodyRenderer.h"
#import "SkyCatalogRenderer.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
void check(bool value, const char* message) { ++checks; if (!value) throw std::runtime_error(message); }
using Pixels = std::vector<unsigned char>;
Pixels render(const std::function<void(CGContextRef)>& draw) {
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:400 pixelsHigh:300 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:1600 bitsPerPixel:32];
    check(bitmap != nil, "bitmap allocation failed");
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    const auto context = NSGraphicsContext.currentContext.CGContext;
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, 400, 300));
    draw(context);
    [NSGraphicsContext restoreGraphicsState];
    return {bitmap.bitmapData, bitmap.bitmapData + bitmap.bytesPerRow * bitmap.pixelsHigh};
}

void solar_tests() {
    SolarBodies bodies{};
    const std::array<Body, 11> ids{{Body::sun, Body::mercury, Body::venus, Body::earth,
        Body::mars, Body::jupiter, Body::saturn, Body::uranus, Body::neptune, Body::pluto, Body::moon}};
    for (std::size_t index = 0; index < bodies.size(); ++index) {
        bodies[index].id = ids[index];
        bodies[index].position_au = {index * 0.2, index * 0.1, 0};
        bodies[index].orientation.north_axis = {0, 0, 1};
    }
    SolarOrbits orbits{};
    orbits[0] = {{-1, -1, 0}, {1, -1, 0}};
    std::vector<Vec3> lunar;
    SolarCamera camera{};
    camera.distance_au = 10;
    SolarScene scene{bodies, orbits, lunar, camera, nullptr, std::nullopt,
        NSMakeRect(0, 0, 400, 300), 1, false, std::nullopt, std::nullopt};
    // この試験は勾配の代替ディスクを対象とし、食による表面画像への切替を含めない。
    scene.eclipse_options = {false, false, false, false};
    scene.grid_display.circle_scales = false;
    scene.planet_display = {true, false, false, false};
    const auto visible = visible_solar_bodies(scene);
    check(!visible.empty(), "fixture body is not visible");
    const auto& point = visible.back().point;
    const NSPoint click = NSMakePoint(point.x, point.y);
    check(pick_solar_body(scene, click).has_value(), "visible body cannot be picked");
    const auto draw = [&] { return render([&](CGContextRef context) { draw_solar_scene(context, scene); }); };
    const auto disks = draw();
    scene.renderer_display.point_smoothing = false;
    const auto hard_disks = draw();
    check(hard_disks != disks, "solar fallback disk ignored point quality");
    scene.renderer_display = {false, true, true, true};
    check(draw() == hard_disks, "solar master gate did not disable fallback disk edges");
    scene.renderer_display = {true, true, false, false};
    check(draw() == disks, "line or text quality leaked into solar point drawing");
    scene.renderer_display = {};
    scene.planet_display.labels = true;
    const auto labels = render([&](CGContextRef context) { draw_solar_scene(context, scene); });
    check(labels != disks, "planet labels toggle did not change rendering");
    scene.renderer_display.text_smoothing = false;
    check(draw() != labels, "solar planet labels ignored text quality");
    scene.renderer_display = {};
    scene.planet_display.labels = false;
    scene.planet_display.axes = true;
    check(!solar_axis_segment(scene, 0), "fixed Sun orientation must not be presented as a modeled axis");
    check(!solar_axis_segment(scene, bodies.size()), "invalid body index accepted");
    for (std::size_t index = 1; index < bodies.size(); ++index) {
        const auto axis = solar_axis_segment(scene, index);
        check(axis.has_value(), "planet or lunar axis missing");
        const auto center = solar_display_position(scene, index);
        check(std::abs((*axis)[0].x - center.x) < 1e-12 && std::abs((*axis)[1].y - center.y) < 1e-12,
              "J2000 ecliptic axis was transformed a second time");
        check((*axis)[1].z > center.z && std::abs((*axis)[0].z + (*axis)[1].z - 2 * center.z) < 1e-12,
              "axis endpoints must be symmetric about the center and follow north");
    }
    check(render([&](CGContextRef context) { draw_solar_scene(context, scene); }) != disks,
          "axis toggle did not change rendering");
    bodies[3].orientation.north_axis = {0, 0.6, 0.8};
    const auto tilted_axis = *solar_axis_segment(scene, 3);
    check(std::abs((tilted_axis[1].y - tilted_axis[0].y)
        / (tilted_axis[1].z - tilted_axis[0].z) - 0.75) < 1e-12,
        "inclined north axis lost its J2000 ecliptic direction");
    bodies[3].orientation.north_axis = {0, 0, 1};
    scene.planet_display = {false, true, false, true};
    check(visible_solar_bodies(scene).empty() && !pick_solar_body(scene, click) && !solar_axis_segment(scene, 3),
          "hidden planets leaked into drawing or hit testing");
    const auto hidden = render([&](CGContextRef context) { draw_solar_scene(context, scene); });
    check(hidden != disks, "visible toggle left body disks");
    scene.planet_display.orbits = true;
    check(render([&](CGContextRef context) { draw_solar_scene(context, scene); }) != hidden,
          "orbits must be independently visible when body disks are hidden");
    const auto smooth_orbits = draw();
    scene.renderer_display.line_smoothing = false;
    const auto hard_orbits = draw();
    check(hard_orbits != smooth_orbits, "solar orbits ignored line quality");
    scene.renderer_display = {true, false, true, false};
    check(draw() == smooth_orbits, "point or text quality leaked into solar orbit drawing");
    scene.renderer_display = {false, true, true, true};
    check(draw() == hard_orbits, "solar master gate did not disable line edges");
    scene.renderer_display = {};
    scene.planet_display.orbits = false;
    for (bool physical : {false, true}) {
        scene.earth_moon = !physical;
        scene.physical_navigation = physical;
        check(!pick_solar_body(scene, click) && visible_solar_bodies(scene).empty(),
              "physical picking bypassed visibility");
        const auto physical_hidden = render([&](CGContextRef context) { draw_solar_scene(context, scene); });
        if (!physical) check(physical_hidden == render([](CGContextRef) {}),
            "hidden Earth/Moon physical spheres were still composited");
        scene.planet_display.visible = true;
        check(render([&](CGContextRef context) { draw_solar_scene(context, scene); }) != physical_hidden,
              "physical composite did not respond to visibility");
        scene.planet_display.visible = false;
    }
}

void small_body_quality_tests() {
    auto dataset = std::make_shared<SmallBodyDataset>();
    SmallBodyRecord record;
    record.id = {"fixture.dat", 0};
    record.name_bytes = "Local asteroid";
    record.kind = SmallBodyKind::asteroid;
    dataset->records.push_back(record);
    dataset->sources.push_back({"fixture.dat", {}, "original-quality-fixture", 1, true});
    SmallBodyDisplayModel display(dataset);
    SmallBodySnapshot snapshot;
    snapshot.model = std::make_shared<SmallBodyModel>(dataset);
    snapshot.positions.push_back(Vec3{0.12, 0.34, 0.56});
    SolarCamera camera;
    RendererDisplayOptions quality;
    std::optional<std::size_t> selection;
    const auto draw = [&] { return render([&](CGContextRef context) {
        draw_small_bodies(context, snapshot, display, nullptr, camera, NSMakeRect(0, 0, 400, 300), selection, quality);
    }); };
    const auto point = draw();
    check(point != render([](CGContextRef) {}), "small-body quality fixture is offscreen");
    quality.point_smoothing = false;
    check(draw() != point, "small-body point ignored quality");
    quality = {true, true, false, false};
    check(draw() == point, "small-body point received line or text quality");
    quality = {};
    selection = 0;
    display.set_kind_options(SmallBodyKind::asteroid, {true, true, false, false});
    const auto selected = draw();
    quality.line_smoothing = false;
    check(draw() != selected, "small-body selection ring ignored line quality");
    quality = {true, true, true, false};
    check(draw() != selected, "small-body label ignored text quality");
    quality = {};
    const auto null_context = render([&](CGContextRef) {
        draw_small_bodies(nullptr, snapshot, display, nullptr, camera,
                         NSMakeRect(0, 0, 400, 300), selection, quality);
    });
    check(null_context == render([](CGContextRef) {}),
          "null small-body context drew into the current AppKit context");
}

void small_body_orbit_rendering_tests() {
    auto dataset = std::make_shared<SmallBodyDataset>();
    SmallBodyRecord record;
    record.id = {"comet-quality.dat", 0};
    record.kind = SmallBodyKind::comet;
    record.frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
    record.time_scale = SmallBodyTimeScale::tdb;
    record.orbit = PerihelionElements{1, 0.5, 2451545, 23, 31, 47};
    dataset->records.push_back(record);
    dataset->sources.push_back({record.id.source_key, {}, "original-comet-orbit", 1, true});
    auto display = std::make_shared<SmallBodyDisplayModel>(dataset);
    display->set_kind_options(SmallBodyKind::comet, {true, false, true, false});
    SmallBodySnapshot snapshot;
    snapshot.model = std::make_shared<SmallBodyModel>(dataset);
    // 現在位置の marker を除き、サンプリングした線だけの実画素を比較する。
    snapshot.positions.push_back(std::nullopt);
    const auto orbits = evaluate_small_body_orbit_snapshot(snapshot.model, display, {2451362, 2451728, 129});
    SolarCamera camera;
    camera.distance_au = 7;
    RendererDisplayOptions quality;
    const NSRect map = NSMakeRect(20, 30, 360, 240);
    const auto draw = [&] { return render([&](CGContextRef context) {
        draw_small_bodies(context, snapshot, *display, orbits.get(), camera, map, {}, quality);
    }); };
    const auto blank = render([](CGContextRef) {});
    const auto smooth = draw();
    check(smooth != blank, "sampled comet orbit produced no visible pixels");
    quality.line_smoothing = false;
    const auto hard = draw();
    check(hard != smooth, "comet orbit ignored line smoothing");
    quality = {false, true, true, true};
    check(draw() == hard, "master antialias did not gate comet orbit lines");
    quality = {true, false, true, false};
    check(draw() == smooth, "point or text smoothing leaked into comet orbit lines");
    quality = {};
    display->set_kind_options(SmallBodyKind::comet, {false, false, true, false});
    check(draw() == blank, "hidden comet kind leaked orbit pixels");
    display->set_kind_options(SmallBodyKind::comet, {true, false, true, true});
    check(draw() == blank, "empty display set leaked orbit pixels");
    display->set_selected_ids({record.id});
    check(draw() == smooth, "original-row display membership did not restore orbit pixels");
    // 拡大して線を描画領域の境界に交差させ、隣接 UI への漏れを検出する。
    camera.distance_au = 2;
    const auto clipped = draw();
    check(clipped != blank, "clipping fixture has no orbit pixels");
    bool outsideIsBlank = true;
    for (std::size_t y = 0; y < 300; ++y) for (std::size_t x = 0; x < 400; ++x) {
        if (x >= 20 && x < 380 && y >= 30 && y < 270) continue;
        for (std::size_t channel = 0; channel < 4; ++channel) {
            const auto offset = (y * 400 + x) * 4 + channel;
            outsideIsBlank &= clipped[offset] == blank[offset];
        }
    }
    check(outsideIsBlank, "comet orbit escaped its drawing rectangle");
}

void star_tests(const char* directory) {
    auto model = std::make_shared<SkyModel>(SkyModel::load(directory));
    const auto binary = std::find_if(model->stars().begin(), model->stars().end(),
        [](const auto& star) { return star.is_double && star.apparent_v_magnitude < 6; });
    check(binary != model->stars().end(), "local HIP data has no bright binary fixture");
    auto catalogs = std::make_shared<ExtendedCatalogs>();
    catalogs->exoplanet_hosts.push_back(binary->hip);
    catalogs->star_names.push_back({binary->hip, false, "LOCAL_NAME", "*"});
    StarRenderer *renderer = [[StarRenderer alloc] initWithModel:model catalogs:catalogs];
    const StarProjector projector = [&](EquatorialCoordinates coordinates) -> std::optional<StarProjection> {
        if (coordinates.right_ascension_deg != binary->right_ascension_degrees
            || coordinates.declination_deg != binary->declination_degrees) return std::nullopt;
        return StarProjection{{100, 150}, 1};
    };
    StarDisplayOptions options{};
    RendererDisplayOptions quality{};
    const auto draw = [&] { return render([&](CGContextRef) {
        [renderer drawInRect:NSMakeRect(0, 0, 400, 300) magnitudeLimit:6 options:options quality:quality projector:projector];
    }); };
    const auto plain = draw();
    const auto rgb_sum = [](const auto& pixels) {
        std::uint64_t sum = 0;
        for (std::size_t offset = 0; offset < pixels.size(); offset += 4)
            sum += pixels[offset] + pixels[offset + 1] + pixels[offset + 2];
        return sum;
    };
    options.brightness = 0.5f;
    const auto brighter = draw();
    options.brightness = 2;
    const auto darker = draw();
    check(rgb_sum(brighter) > rgb_sum(plain) && rgb_sum(plain) > rgb_sum(darker),
          "star brightness did not change the rendered point in the documented direction");
    options.brightness = 1;
    check(draw() == plain, "default star brightness changed the existing point pixels");
    quality.point_smoothing = false;
    const auto hard_points = draw();
    check(hard_points != plain, "star disks ignored point quality");
    quality = {false, true, true, true};
    check(draw() == hard_points, "star master gate did not disable point edges");
    quality = {true, true, false, false};
    check(draw() == plain, "star point quality leaked from line or text flags");
    quality = {};
    options.marking = StarMarking::binary;
    const auto binary_mark = draw();
    quality.line_smoothing = false;
    check(draw() != binary_mark, "star binary ring ignored line quality");
    quality = {};
    options.marking = StarMarking::exoplanets;
    const auto host_mark = draw();
    check(binary_mark != plain && host_mark != plain && binary_mark != host_mark,
          "binary and exoplanet marks must be visible and distinct");
    renderer = [[StarRenderer alloc] initWithModel:model catalogs:std::make_shared<ExtendedCatalogs>()];
    check(draw() == plain, "catalog reload retained the prior host marking");
    renderer = [[StarRenderer alloc] initWithModel:model catalogs:catalogs];
    options.marking = StarMarking::none;
    options.proper_names = true;
    const auto named = draw();
    check(named != plain, "local proper name was not rendered");
    options.marking = StarMarking::binary;
    const auto named_marked = draw();
    options.brightness = 2;
    const auto darker_named_marked = draw();
    bool decorations_unchanged = true;
    for (std::size_t y = 0; y < 300; ++y) for (std::size_t x = 0; x < 400; ++x) {
        if (x >= 95 && x <= 105 && y >= 144 && y <= 155) continue;
        for (std::size_t channel = 0; channel < 4; ++channel) {
            const auto offset = (y * 400 + x) * 4 + channel;
            decorations_unchanged &= named_marked[offset] == darker_named_marked[offset];
        }
    }
    check(decorations_unchanged && named_marked != darker_named_marked,
          "star brightness changed the name or selection marking");
    options.marking = StarMarking::none;
    options.brightness = 1;
    quality.text_smoothing = false;
    check(draw() != named, "star name ignored text quality");
    quality = {};
    renderer = [[StarRenderer alloc] initWithModel:model catalogs:std::make_shared<ExtendedCatalogs>()];
    check(draw() == plain, "catalog reload retained the prior proper name");
    options.hip_labels = true;
    check(draw() != plain, "HIP name was not rendered");
    options.visible = false;
    check(draw() == render([](CGContextRef) {}), "hidden stars retained names or markings");

    catalogs->ngc.push_back({});
    catalogs->ngc.back().coordinates = {180.25, 0.75};
    catalogs->ngc.back().angular_size_arcminutes = 600;
    SkyCatalogRenderer *catalogRenderer = [[SkyCatalogRenderer alloc] initWithModel:model catalogs:catalogs];
    const auto draw_catalog = [&](RendererDisplayOptions display) { return render([&](CGContextRef) {
        [catalogRenderer drawInRect:NSMakeRect(0, 0, 400, 300) viewport:SkyViewport{} magnitudeLimit:6
            options:SkyCatalogDisplay{true, false, false} quality:display];
    }); };
    const auto smooth_catalog = draw_catalog({});
    check(draw_catalog({true, true, false, true}) != smooth_catalog, "nebula outline ignored line quality");
    check(draw_catalog({true, false, true, false}) == smooth_catalog, "nebula outline received point or text quality");

    const auto bodies = model->bodies(2451545);
    SkyView *sky = [[SkyView alloc] initWithFrame:NSMakeRect(0, 0, 800, 480)];
    HorizonView *horizon = [[HorizonView alloc] initWithFrame:sky.frame];
    [sky setModel:model bodies:bodies];
    [horizon setModel:model bodies:bodies];
    for (id view in @[sky, horizon]) {
        [view setHidden:YES];
        [view selectBody:0];
        [view setRendererDisplayOptions:RendererDisplayOptions{false, true, false, true}];
        const auto restored = [view rendererDisplayOptions];
        check(!restored.antialias && restored.point_smoothing && !restored.line_smoothing && restored.text_smoothing,
              "hidden sky or horizon view did not retain renderer options");
        check([view selectedBodyIndex] == 0, "quality change discarded view selection");
        [view setRendererDisplayOptions:RendererDisplayOptions{}];
        const NSUInteger count = [view visibleStarCount];
        check(count > 0, "view must initially contain visible stars");
        [view setStarDisplayOptions:options];
        check([view visibleStarCount] == 0, "hidden stars included in visible count");
        options.visible = true;
        [view setStarDisplayOptions:options];
        check([view visibleStarCount] == count, "restoring visibility changed the star count");
        options.brightness = 0.25f;
        [view setStarDisplayOptions:options];
        check([view visibleStarCount] == count && [view selectedBodyIndex] == 0,
              "star brightness changed filtering or navigation selection");
        auto invalid_brightness = options; invalid_brightness.brightness = 0;
        bool brightness_rejected = false;
        try { [view setStarDisplayOptions:invalid_brightness]; }
        catch (const std::invalid_argument&) { brightness_rejected = true; }
        check(brightness_rejected && [view starDisplayOptions].brightness == 0.25f,
              "invalid brightness must preserve the view state");
        options.brightness = 1;
        [view setStarDisplayOptions:options];
        auto invalid = options; invalid.marking = static_cast<StarMarking>(99);
        bool rejected = false;
        try { [view setStarDisplayOptions:invalid]; }
        catch (const std::invalid_argument&) { rejected = true; }
        check(rejected && [view starDisplayOptions].marking == options.marking,
              "invalid marking must preserve the view state");
        options.visible = false;
        [view selectBody:0];
        [view setPlanetDisplayOptions:PlanetDisplayOptions{false, false, false, false}];
        check([view selectedBodyIndex] == 0, "hiding planets discarded navigation selection");
    }
}
}
int main(int argc, char** argv) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            solar_tests();
            small_body_quality_tests();
            small_body_orbit_rendering_tests();
            if (argc == 2) star_tests(argv[1]);
            std::cout << "display rendering tests passed (" << checks << " checks)\n";
        } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
    }
}
