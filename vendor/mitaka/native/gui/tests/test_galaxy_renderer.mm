#include "GalaxyRenderer.h"
#include "RendererQuality.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
std::size_t checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class F> void rejects(F action) {
    try { action(); } catch (const std::invalid_argument&) { ++checks; return; }
    throw std::runtime_error("expected invalid input rejection");
}
std::vector<std::uint8_t> pixels(const GalaxyBitmap& bitmap) {
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(bitmap.image()));
    if (!data) throw std::runtime_error("cannot inspect bitmap pixels");
    std::vector<std::uint8_t> result(CFDataGetBytePtr(data), CFDataGetBytePtr(data) + CFDataGetLength(data));
    CFRelease(data);
    return result;
}
std::shared_ptr<const GalaxySpatialModel> fixture(std::size_t repeated = 1) {
    std::vector<SdssRecord> rows(repeated, {{1.25, 0.5}, 1, 0});
    rows.push_back({{0, 0}, -1, 0});
    rows.push_back({{0, 0}, 30, 0});
    rows.push_back({{90, 0}, 30, 0});
    auto sdss = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
        std::vector<SdssSpatialSource>{{SdssKind::galaxy, "gal", rows},
            {SdssKind::quasar, "qso", {{{0, 0}, 2, 1}}}}));
    PlusGlobularClusterCatalog gc{{"gc", {1}}, {}};
    PlusGlobularClusterRecord cluster; cluster.distance_pc = 3; gc.records.push_back(cluster);
    PlusNearbyGalaxyCatalog nbg{{"nbg", {2}}, {}};
    PlusNearbyGalaxyRecord nearby; nearby.distance_pc = 4; nbg.records.push_back(nearby);
    return std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{
        GalaxySdssSource{sdss, 0}, GalaxySdssSource{sdss, 1}, gc, nbg});
}
const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
void dimensions_tests() {
    check(galaxy_raster_size(800, 600, 2).width == 1600, "retina resolution");
    const auto large = galaxy_raster_size(10000000, 5000000, 16);
    check(large.width == 2048 && large.height == 1024, "bounded dimensions preserve aspect ratio");
    const auto thin = galaxy_raster_size(0.1, 1e7, 1);
    check(thin.width == 1 && thin.height == 2048, "thin image retains one pixel");
    for (double invalid : {0.0, -1.0, 1e8, std::numeric_limits<double>::quiet_NaN(),
                           std::numeric_limits<double>::infinity()}) {
        rejects([&] { (void)galaxy_raster_size(invalid, 64, 1); });
        rejects([&] { (void)galaxy_raster_size(64, invalid, 1); });
    }
    for (double invalid : {0.0, -1.0, 17.0, std::numeric_limits<double>::quiet_NaN()})
        rejects([&] { (void)galaxy_raster_size(64, 64, invalid); });
    const auto model = fixture();
    rejects([&] { (void)render_galaxy_bitmap(*model, camera, {}, {}, std::numeric_limits<double>::denorm_min(), 64, 1); });
    rejects([&] { (void)render_galaxy_bitmap(*model, camera, {}, {}, 64, std::numeric_limits<double>::denorm_min(), 1); });
    rejects([] { GalaxyBitmap invalid(nullptr, {}); });
}
void counts_and_pixels_tests() {
    const auto model = fixture(1025);
    for (unsigned mask = 0; mask < 16; ++mask) {
        const GalaxySpatialVisibility visibility{bool(mask & 1), bool(mask & 2), bool(mask & 4), bool(mask & 8)};
        const auto bitmap = render_galaxy_bitmap(*model, camera, visibility, {}, 128, 96, 1);
        check(bitmap && CGImageGetWidth(bitmap->image()) == 128 && CGImageGetHeight(bitmap->image()) == 96,
              "bitmap dimensions");
        const auto count = bitmap->counts();
        check(count.total == model->size() && count.hidden + count.invalid + count.outside + count.drawn == count.total,
              "every original row assigned exactly one render outcome");
        check(count.drawn == ((mask & 1) ? 1025u : 0u) + ((mask & 2) ? 1u : 0u) +
            ((mask & 4) ? 1u : 0u) + ((mask & 8) ? 1u : 0u), "all families and all batches drawn");
        check(count.invalid == ((mask & 1) ? 1u : 0u) && count.outside == ((mask & 1) ? 2u : 0u),
              "invalid and offscreen rows remain counted");
        const auto data = pixels(*bitmap);
        for (std::size_t pixel = 3; pixel < data.size(); pixel += 4) check(data[pixel] == 255, "output is opaque");
    }
    const auto smooth = pixels(*render_galaxy_bitmap(*model, camera, {}, {}, 127, 97, 1));
    RendererDisplayOptions other; other.line_smoothing = other.text_smoothing = false;
    check(smooth == pixels(*render_galaxy_bitmap(*model, camera, {}, other, 127, 97, 1)),
          "point renderer independent of line and text quality");
    other.point_smoothing = false;
    const auto rough = pixels(*render_galaxy_bitmap(*model, camera, {}, other, 127, 97, 1));
    check(smooth != rough, "point quality changes actual pixels");
    other = {}; other.antialias = false;
    check(rough == pixels(*render_galaxy_bitmap(*model, camera, {}, other, 127, 97, 1)), "master AA gates point quality");
    // 単一点は投影した上下方向と一致し、同じ x の上下反転位置には描画されない。
    auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
        std::vector<SdssSpatialSource>{{SdssKind::galaxy, "oriented", {{{0, 30}, 3, 0}}}}));
    GalaxySpatialModel oriented({GalaxySdssSource{snapshot, 0}});
    const auto bitmap = render_galaxy_bitmap(oriented, camera, {}, {}, 128, 128, 1);
    const auto data = pixels(*bitmap);
    const auto position = GalaxyProjector(camera, 128, 128).project(*oriented.row(oriented.record_id(0)).position);
    check(position && position->y < 60, "test position is above center");
    const std::size_t x = std::size_t(position->x), y = std::size_t(position->y);
    check(data[(y * 128 + x) * 4 + 2] > 100, "image pixel follows top-left projection");
    check(data[((127 - y) * 128 + x) * 4 + 2] < 30, "image does not invert vertical position");
    const GalaxySpatialModel empty({});
    const auto zero = render_galaxy_bitmap(empty, camera, {}, {}, 64, 32, 1);
    check(zero && zero->counts().total == 0 && zero->counts().drawn == 0, "empty model draws background");
}

// 最適化前の 512 行単位の path 塗りを独立に再現し、CoreGraphics の実際の画素を比較する。
std::vector<std::uint8_t> reference_pixels(const GalaxySpatialModel& model, RendererDisplayOptions quality,
                                           double width, double height, double scale) {
    const auto raster = galaxy_raster_size(width, height, scale);
    CGColorSpaceRef colors = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nullptr, raster.width, raster.height, 8, raster.width * 4,
        colors, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colors);
    if (!context) throw std::runtime_error("reference bitmap allocation failed");
    CGContextSetRGBFillColor(context, 0.015, 0.02, 0.035, 1);
    CGContextFillRect(context, CGRectMake(0, 0, raster.width, raster.height));
    CGContextTranslateCTM(context, 0, raster.height);
    CGContextScaleCTM(context, double(raster.width) / width, -double(raster.height) / height);
    {
        RendererQualityScope general(context, quality);
        RendererQualityScope points(context, quality, RendererPrimitive::point);
        CGContextClipToRect(context, CGRectMake(0, 0, width, height));
        GalaxyProjector projector(camera, width, height);
        for (std::size_t source = 0; source < model.sources().size(); ++source) {
            const auto family = model.family(source);
            switch (family) {
            case GalaxySpatialFamily::sdss_galaxy: CGContextSetRGBFillColor(context, 0.60, 0.80, 1.00, 1); break;
            case GalaxySpatialFamily::sdss_quasar: CGContextSetRGBFillColor(context, 1.00, 0.55, 0.75, 1); break;
            case GalaxySpatialFamily::globular_cluster: CGContextSetRGBFillColor(context, 1.00, 0.85, 0.40, 1); break;
            case GalaxySpatialFamily::nearby_galaxy: CGContextSetRGBFillColor(context, 0.50, 1.00, 0.70, 1); break;
            }
            std::size_t pending = 0;
            CGContextBeginPath(context);
            for (std::size_t ordinal = 0; ordinal < model.source_size(source); ++ordinal) {
                const auto row = model.row({family, source, ordinal});
                if (!row.position) continue;
                const auto point = projector.project(*row.position);
                if (!point || !projector.contains(*point)) continue;
                const double radius = family == GalaxySpatialFamily::globular_cluster ? 2.0 : 1.25;
                CGContextAddEllipseInRect(context, CGRectMake(point->x - radius, point->y - radius, radius * 2, radius * 2));
                if (++pending == 512) { CGContextFillPath(context); CGContextBeginPath(context); pending = 0; }
            }
            if (pending) CGContextFillPath(context);
        }
    }
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    if (!image) throw std::runtime_error("reference image creation failed");
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(image));
    CGImageRelease(image);
    if (!data) throw std::runtime_error("reference image read failed");
    std::vector<std::uint8_t> result(CFDataGetBytePtr(data), CFDataGetBytePtr(data) + CFDataGetLength(data));
    CFRelease(data);
    return result;
}
void duplicate_pixel_equivalence_tests() {
    for (std::size_t count : {std::size_t(1), std::size_t(511), std::size_t(512),
                              std::size_t(513), std::size_t(1025)}) {
        std::vector<SdssRecord> rows;
        for (std::size_t i = 0; i < count; ++i) {
            // 同一点の連続、部分重複と画面上の異なる位置を各 batch 内へ混ぜる。
            const double ra = (i / 7 % 5) * 0.3;
            rows.push_back({{ra, (i / 13 % 3) * 0.25}, 1, 0});
            if (i % 127 == 0) rows.push_back({{0, 0}, -1, 0});
        }
        auto sdss = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
            std::vector<SdssSpatialSource>{{SdssKind::galaxy, "a", rows}, {SdssKind::quasar, "b", rows}}));
        PlusGlobularClusterCatalog gc{{"gc", {1}}, {}};
        for (int i = 0; i < 13; ++i) { PlusGlobularClusterRecord cluster; cluster.distance_pc = 1; gc.records.push_back(cluster); }
        GalaxySpatialModel model({GalaxySdssSource{sdss, 0}, GalaxySdssSource{sdss, 1}, gc});
        for (double scale : {1.0, 2.0}) for (bool smoothing : {false, true}) {
            RendererDisplayOptions quality; quality.antialias = smoothing;
            auto actual = render_galaxy_bitmap(model, camera, {}, quality, 127, 97, scale);
            check(pixels(*actual) == reference_pixels(model, quality, 127, 97, scale),
                  "duplicate optimization preserves every pixel and batch compositing");
            check(actual->counts().total == model.size() && actual->counts().drawn + actual->counts().invalid == model.size(),
                  "duplicate optimization counts each original row");
        }
    }
}
void cancellation_tests() {
    const auto model = fixture(1025);
    std::size_t calls = 0;
    check(!render_galaxy_bitmap(*model, camera, {}, {}, 64, 64, 1, [&] { return ++calls == 1; }) && calls == 1,
          "cancel before allocating output");
    calls = 0;
    check(!render_galaxy_bitmap(*model, camera, {}, {}, 64, 64, 1, [&] { return ++calls == 5; }) && calls == 5,
          "mid-walk cancellation discards partial bitmap");
    calls = 0;
    check(bool(render_galaxy_bitmap(*model, camera, {}, {}, 64, 64, 1, [&] { ++calls; return false; })),
          "uncancelled callback preserves render");
    const auto completion = calls;
    calls = 0;
    check(!render_galaxy_bitmap(*model, camera, {}, {}, 64, 64, 1, [&] { return ++calls == completion; }),
          "completion cancellation discards finished bitmap");
}
void transparent_background_tests() {
    const GalaxySpatialModel empty({});
    const auto blank = render_galaxy_bitmap(empty, camera, {}, {}, 64, 64, 1, {}, GalaxyBackground::transparent);
    const auto blank_pixels = pixels(*blank);
    check(std::all_of(blank_pixels.begin(), blank_pixels.end(), [](std::uint8_t value) { return value == 0; }),
          "empty transparent image contains no color or alpha");

    auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
        std::vector<SdssSpatialSource>{{SdssKind::galaxy, "point", {{{0, 0}, 1, 0}}}}));
    GalaxySpatialModel model({GalaxySdssSource{snapshot, 0}});
    const auto bitmap = render_galaxy_bitmap(model, camera, {}, {}, 64, 64, 1, {}, GalaxyBackground::transparent);
    const auto data = pixels(*bitmap);
    check(bitmap->counts().drawn == 1, "transparent rendering retains projected objects");
    check(data[3] == 0, "uncovered pixel remains transparent");
    const auto position = GalaxyProjector(camera, 64, 64).project(*model.row(model.record_id(0)).position);
    check(bool(position), "test object projects into the viewport");
    const auto pixel = (std::size_t(position->y) * 64 + std::size_t(position->x)) * 4;
    check(data[pixel + 3] > 0 && data[pixel + 2] > 0, "projected pixel contains visible color and alpha");
    for (std::size_t i = 0; i < data.size(); i += 4)
        check(data[i] <= data[i + 3] && data[i + 1] <= data[i + 3] && data[i + 2] <= data[i + 3],
              "transparent image uses premultiplied alpha");
}
}
int main() {
    try {
        dimensions_tests(); counts_and_pixels_tests(); duplicate_pixel_equivalence_tests(); cancellation_tests();
        transparent_background_tests();
        std::cout << "Galaxy renderer: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Galaxy renderer: " << error.what() << '\n'; return 1;
    }
}
