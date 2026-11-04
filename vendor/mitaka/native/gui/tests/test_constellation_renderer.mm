#import "ConstellationRenderer.h"
#include <algorithm>
#include <functional>
#include <iostream>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
constexpr int width = 720, height = 460;
const NSRect map = NSMakeRect(30, 30, width - 60, height - 60);
using Pixels = std::vector<unsigned char>;
void check(bool value, const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
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
    for (int y = 0; y < height; ++y) for (int x = 0; x < width; ++x) {
        if (x >= 30 && x < width - 30 && y >= 30 && y < height - 30) continue;
        for (int channel = 0; channel < 4; ++channel)
            check(image[(y * width + x) * 4 + channel] == blank[(y * width + x) * 4 + channel],
                  "constellation content escaped the map clip");
    }
}
void tests(const std::filesystem::path& data) {
    const auto model = SkyModel::load(data);
    const auto blank = render([](CGContextRef) {});
    ConstellationDisplayOptions options;
    RendererDisplayOptions quality;
    ObservationFrame frame({35,139}, 2451545);
    const auto draw = [&](bool horizon, ConstellationRenderStats& stats) {
        return render([&](CGContextRef context) {
            stats = horizon ? draw_horizon_constellations(context, model, options, quality, frame, {}, map)
                : draw_sky_constellations(context, model, options, quality, {}, map);
        });
    };
    if (model.constellations().empty()) {
        if (!std::filesystem::exists(data / "constellation_HIP.dat"))
            check(!model.constellation_warning().empty(), "missing optional catalog was not reported");
        for (bool horizon : {false, true}) for (unsigned mask = 0; mask < 8; ++mask) {
            options = {bool(mask & 1), bool(mask & 2), bool(mask & 4), true, {}};
            ConstellationRenderStats stats;
            check(draw(horizon, stats) == blank && !stats.line_segments && !stats.boundary_segments
                && !stats.labels && !stats.omitted_intervals, "empty optional catalog drew content");
        }
        std::cout << "Local source rows: 0 (optional constellation catalog has no records)\n";
        return;
    }
    for (bool horizon : {false,true}) {
        ConstellationRenderStats stats;
        options = {true,true,true,false,{}};
        check(draw(horizon, stats) == blank && !stats.line_segments && !stats.boundary_segments && !stats.labels,
              "empty membership drew content");
        for (unsigned mask = 0; mask < 8; ++mask) {
            options = {bool(mask & 1),bool(mask & 2),bool(mask & 4),true,{}};
            const auto pixels = draw(horizon, stats);
            check((stats.line_segments > 0) == options.lines, "line master does not control constellation lines");
            check((stats.boundary_segments > 0) == options.boundaries, "boundary master does not control constellation boundaries");
            check(stats.labels == (options.labels ? model.constellations().size() : 0), "label master dropped or deduplicated source rows");
            check((pixels != blank) == (mask != 0), "layer switches did not change actual pixels");
            check(stats.omitted_intervals == 0, "ordinary local geometry exhausted sampling budget");
            clipped(pixels, blank);
        }
        const auto ser_rows = std::count_if(model.constellations().begin(), model.constellations().end(),
            [](const auto& row) { return row.abbreviation == "Ser"; });
        if (ser_rows) {
            options = {true,true,true,false,{"Ser"}};
            check(draw(horizon, stats) != blank && stats.labels == static_cast<std::size_t>(ser_rows),
                  "one Ser membership must keep all original figures");
            options.lines = options.labels = options.boundaries = false;
            check(draw(horizon, stats) == blank, "membership overrode disabled layer masters");
        }
        options = {true,true,true,true,{}};
        quality = {};
        const auto smooth = draw(horizon, stats);
        quality.line_smoothing = false;
        check(draw(horizon, stats) != smooth, "line smoothing did not reach constellation paths");
        quality = {}; quality.text_smoothing = false;
        check(draw(horizon, stats) != smooth, "text smoothing did not reach constellation labels");
        quality = {}; quality.point_smoothing = false;
        check(draw(horizon, stats) == smooth, "point smoothing changed constellation lines or labels");
        quality = {}; quality.antialias = false;
        const auto master_off = draw(horizon, stats);
        quality = {true,false,false,false};
        check(draw(horizon, stats) == master_off, "quality master differs from disabled primitive smoothing");
        quality = {};
    }
    ConstellationRenderStats stats;
    options = {true,true,true,true,{}};
    const auto sky = draw(false, stats), horizon = draw(true, stats);
    frame = ObservationFrame({-35,-40}, 2460000.25);
    check(draw(false, stats) == sky, "sky constellations changed with observing site/date");
    check(draw(true, stats) != horizon && stats.omitted_intervals == 0, "horizon constellations ignored observing site/date");
    std::cout << "Local source rows: " << model.constellations().size() << '\n';
}
}
int main(int argc, char** argv) {
    @autoreleasepool {
        if (argc != 2) { std::cerr << "usage: test_constellation_renderer DATA_ROOT\n"; return 2; }
        try {
            tests(argv[1]);
            std::cout << "Constellation renderer tests passed: " << checks << " checks\n";
        } catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
