#import "GridRenderer.h"
#import "SolarSceneRenderer.h"
#include <functional>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
int checks = 0;
constexpr int width = 480, height = 360;
const NSRect map = NSMakeRect(40, 40, width - 80, height - 80);
using Pixels = std::vector<unsigned char>;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
Pixels render(const std::function<void(CGContextRef)>& draw) {
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:width * 4 bitsPerPixel:32];
    check(bitmap != nil, "bitmap allocation failed");
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    const auto context = NSGraphicsContext.currentContext.CGContext;
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, width, height));
    draw(context);
    [NSGraphicsContext restoreGraphicsState];
    return {bitmap.bitmapData, bitmap.bitmapData + bitmap.bytesPerRow * bitmap.pixelsHigh};
}
void clipped(const Pixels& image, const Pixels& blank) {
    bool unchanged = true;
    for (int y = 0; y < height; ++y) for (int x = 0; x < width; ++x) {
        if (x >= 40 && x < width - 40 && y >= 40 && y < height - 40) continue;
        for (int channel = 0; channel < 4; ++channel) {
            const auto offset = (y * width + x) * 4 + channel;
            unchanged &= image[offset] == blank[offset];
        }
    }
    check(unchanged, "grid or label drew outside the map rectangle");
}
bool has_grid_pixels(const Pixels& image) {
    // 凡例や座標ラベルだけが描かれた場合を、格子の描画成功と扱わない。
    for (int y = 80; y < height - 80; ++y) for (int x = 80; x < width - 80; ++x)
        for (int channel = 0; channel < 3; ++channel)
            if (image[(y * width + x) * 4 + channel] != 0) return true;
    return false;
}
GridDisplayOptions only(int index) {
    GridDisplayOptions options{false, false, false, false, false, false};
    switch (index) {
        case 0: options.equatorial = true; break;
        case 1: options.ecliptic = true; break;
        case 2: options.galactic = true; break;
        case 3: options.horizontal = true; break;
        case 4: options.circle_scales = true; break;
        case 5: options.square_scales = true; break;
    }
    return options;
}
void sky_tests(const Pixels& blank) {
    GridGeometryCache cache;
    SkyViewport viewport{};
    RendererDisplayOptions quality;
    const auto draw = [&](const GridDisplayOptions& options, bool horizontal) {
        return render([&](CGContextRef context) { draw_sky_grids(context, map, viewport, options, cache, horizontal, quality); });
    };
    check(draw(only(-1), false) == blank, "disabled sky grids drew pixels");
    for (bool horizontal : {false, true}) {
        for (int index = 0; index < 4; ++index) {
            const auto image = draw(only(index), horizontal);
            check(has_grid_pixels(image), "enabled sky coordinate grid drew no lines");
            clipped(image, blank);
        }
        check(draw(only(4), horizontal) == blank && draw(only(5), horizontal) == blank,
              "physical distance scales must not appear on a direction-only sky map");
    }
    const auto smooth = draw(only(2), false);
    quality.line_smoothing = false;
    check(draw(only(2), false) != smooth, "sky grid ignored line quality");
    quality = {true, true, true, false};
    check(draw(only(2), false) != smooth, "sky grid legend ignored text quality");
    quality = {true, false, true, true};
    check(draw(only(2), false) == smooth, "point quality changed the sky grid");
    quality = {};
    const auto equatorial = draw(only(0), false);
    const auto horizontal = draw(only(3), false);
    cache.set_observation({35.68, 139.76}, 2451545.25);
    check(draw(only(0), false) == equatorial, "fixed J2000 grid changed with observing time");
    check(draw(only(3), false) != horizontal, "horizontal sky grid ignored observing time");
    const auto before_invalid = draw(only(3), false);
    bool rejected = false;
    try { cache.set_observation({91, 0}, 2451545); } catch (const std::invalid_argument&) { rejected = true; }
    check(rejected && draw(only(3), false) == before_invalid, "invalid site mutated the cached grid");
    rejected = false;
    try { cache.set_observation({0, 0}, std::numeric_limits<double>::quiet_NaN()); }
    catch (const std::invalid_argument&) { rejected = true; }
    check(rejected && draw(only(3), false) == before_invalid, "invalid date mutated the cached grid");
    for (double altitude : {-89.0, 89.0}) {
        viewport = {270, altitude, 90};
        const auto near_pole = draw(only(3), true);
        int vertical_rows = 0;
        for (int y = 65; y < height - 65; ++y) {
            bool colored = false;
            for (int x = width / 2 - 1; x <= width / 2 + 1; ++x)
                for (int channel = 0; channel < 3; ++channel)
                    colored |= near_pole[(y * width + x) * 4 + channel] != 0;
            vertical_rows += colored;
        }
        check(vertical_rows == height - 130,
              "horizontal meridian veered away from its azimuth near the zenith or nadir");
    }
    for (double latitude : {-90.0, 90.0}) {
        cache.set_observation({latitude, 180}, 2451545);
        for (double declination : {-89.5, 0.0, 89.5}) {
            viewport = {359.5, declination, 180};
            clipped(draw({true, true, true, true, false, false}, true), blank);
        }
    }
}
void solar_tests(const Pixels& blank) {
    SolarBodies bodies{}; SolarOrbits orbits{}; std::vector<Vec3> lunar;
    SolarCamera camera; camera.distance_au = 10;
    GridGeometryCache cache;
    SolarScene scene{bodies, orbits, lunar, camera, nullptr, std::nullopt, map, 1,
        false, std::nullopt, std::nullopt};
    scene.grid_cache = &cache;
    const auto draw = [&] { return render([&](CGContextRef context) { draw_solar_grid(context, scene); }); };
    scene.grid_display = only(-1);
    check(draw() == blank, "disabled solar grids drew pixels");
    for (int index = 0; index < 6; ++index) {
        scene.grid_display = only(index);
        const auto image = draw();
        check(has_grid_pixels(image), "enabled solar grid or distance scale drew no lines");
        clipped(image, blank);
    }
    const auto smooth = draw();
    scene.renderer_display.line_smoothing = false;
    check(draw() != smooth, "solar distance scale ignored line quality");
    scene.renderer_display = {true, true, true, false};
    check(draw() != smooth, "solar distance label ignored text quality");
    scene.renderer_display = {true, false, true, true};
    check(draw() == smooth, "point quality changed solar distance scales");
    scene.renderer_display = {};
    scene.grid_display = {true, false, true, true, false, false};
    const auto directions = draw();
    camera.target = {41, -7, 13}; camera.distance_au = 1000;
    check(draw() == directions, "direction grids moved with camera position or distance");
    cache.set_observation({-33, 151}, 2451545.25);
    check(draw() != directions, "solar horizontal grid ignored site or time");
    scene.grid_display = {true, true, true, true, true, true};
    camera.frame = SolarCameraBasis{{0, 0, 1}, {1, 0, 0}, {0, 1, 0}};
    camera.distance_au = 1e-10;
    clipped(draw(), blank);
}
}
int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            const auto blank = render([](CGContextRef) {});
            sky_tests(blank); solar_tests(blank);
            std::cout << "grid renderer tests passed (" << checks << " checks)\n";
        } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
    }
}
