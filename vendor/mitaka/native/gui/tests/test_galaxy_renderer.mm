#include "GalaxyRenderer.h"
#include "RendererQuality.h"
#include <algorithm>
#include <array>
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
void local_object_size_tests() {
    PlusGlobularClusterCatalog clusters{{"gc", {1}}, {}};
    PlusGlobularClusterRecord record;
    record.distance_pc = 3;
    record.half_light_radius_pc = 0.5f;
    clusters.records.push_back(record);
    GalaxySpatialModel model({clusters});
    const GalaxySpatialRecordId id{GalaxySpatialFamily::globular_cluster, 0, 0};
    auto view = camera;
    view.target = *model.row(id).position;
    const GalaxyProjector projector(view, 512, 512);
    const auto shape = galaxy_spatial_shape(model, id, projector, false);
    check(shape && shape->radius > 10 && shape->radius < 100, "physical size yields an extended shape");
    RendererDisplayOptions quality; quality.antialias = false;
    const auto bitmap = render_galaxy_bitmap(model, view, {}, quality, 512, 512, 1,
                                              {}, GalaxyBackground::transparent);
    const auto data = pixels(*bitmap);
    const auto alpha = [&](std::size_t x, std::size_t y) { return data[(y * 512 + x) * 4 + 3]; };
    check(alpha(266, 256) != 0 && alpha(356, 256) == 0, "bitmap uses extended shape bounds");
    check(pick_galaxy_spatial_row(model, projector, {}, 266, 256, 8) == id,
          "visible extended region is selectable beyond the point radius");
    auto overlapping_clusters = clusters;
    auto larger_record = record;
    larger_record.half_light_radius_pc = 2;
    overlapping_clusters.records.push_back(larger_record);
    GalaxySpatialModel overlapping_model({overlapping_clusters});
    const auto overlapping_bitmap = render_galaxy_bitmap(overlapping_model, view, {}, quality, 512, 512, 1,
        {}, GalaxyBackground::transparent);
    const auto overlapping_pixels = pixels(*overlapping_bitmap);
    const GalaxySpatialRecordId larger_id{GalaxySpatialFamily::globular_cluster, 0, 1};
    check(overlapping_bitmap->counts().drawn == 2 && overlapping_pixels[(256 * 512 + 346) * 4 + 3] != 0 &&
          pick_galaxy_spatial_row(overlapping_model, projector, {}, 346, 256, 0) == larger_id,
          "same-center rows with different radii retain the later visible extent");

    clusters.records[0].half_light_radius_pc = 1e9f;
    GalaxySpatialModel huge_model({clusters});
    auto huge_view = camera;
    huge_view.target = *huge_model.row(id).position;
    GalaxyProjector huge_projector(huge_view, 512, 512);
    const auto huge = galaxy_spatial_shape(huge_model, id, huge_projector, false);
    check(huge && huge->radius > 1e10, "huge circle triggers safe clipping");
    auto huge_bitmap = render_galaxy_bitmap(huge_model, huge_view, {}, quality, 512, 512, 1,
                                             {}, GalaxyBackground::transparent);
    auto huge_pixels = pixels(*huge_bitmap);
    check(huge_pixels[(256 * 512 + 256) * 4 + 3] != 0 &&
          pick_galaxy_spatial_row(huge_model, huge_projector, {}, 256, 256, 0) == id,
          "huge centered circle is drawn and selected");
    huge_view.pan(huge->radius, 0, 512, 512);
    GalaxyProjector edge_projector(huge_view, 512, 512);
    const auto edge = galaxy_spatial_shape(huge_model, id, edge_projector, false);
    check(edge && !edge_projector.contains(edge->center) && edge->intersects_viewport(edge_projector),
          "huge circle intersects viewport with its center outside");
    const std::size_t inside_x = edge->center.x > 512 ? 400 : 100;
    const std::size_t outside_x = edge->center.x > 512 ? 100 : 400;
    huge_bitmap = render_galaxy_bitmap(huge_model, huge_view, {}, quality, 512, 512, 1,
                                        {}, GalaxyBackground::transparent);
    huge_pixels = pixels(*huge_bitmap);
    check(huge_pixels[(256 * 512 + inside_x) * 4 + 3] != 0 &&
          pick_galaxy_spatial_row(huge_model, edge_projector, {}, inside_x, 256, 0) == id,
          "visible portion of huge offscreen circle is drawn and selected");
    check(huge_pixels[(256 * 512 + outside_x) * 4 + 3] == 0 &&
          !pick_galaxy_spatial_row(huge_model, edge_projector, {}, outside_x, 256, 0),
          "outside huge offscreen circle stays unpainted and unselected");
    std::size_t clip_cancel_checks = 0;
    check(!render_galaxy_bitmap(huge_model, huge_view, {}, quality, 512, 512, 1,
              [&] { return ++clip_cancel_checks == 4; }, GalaxyBackground::transparent) && clip_cancel_checks == 4,
          "renderer does not publish an image after clipping cancellation");
}
void sdss_color_tests() {
    constexpr std::array<float, 7> classes{-1.0f, -0.26f, -0.09f, 0.08f, 0.25f, 0.42f, 1.0f};
    constexpr std::array<std::size_t, 7> expected_classes{0, 0, 1, 2, 3, 4, 4};
    for (std::size_t i = 0; i < classes.size(); ++i)
        check(sdss_galaxy_color_class(classes[i]) == expected_classes[i], "eClass class and clamping");
    for (int i = 1; i < 5; ++i) {
        const float boundary = -0.35f + (0.5f - (-0.35f)) * float(i) / 5;
        for (float value : {std::nextafter(boundary, -1.0f), boundary, std::nextafter(boundary, 1.0f)}) {
            const int reference = std::clamp(int((value - (-0.35f)) / (0.5f - (-0.35f)) * 5), 0, 4);
            check(sdss_galaxy_color_class(value) == std::size_t(reference), "eClass original float boundary");
        }
    }
    for (float invalid : {std::numeric_limits<float>::quiet_NaN(),
                          std::numeric_limits<float>::infinity(), -std::numeric_limits<float>::infinity()})
        rejects([&] { (void)sdss_galaxy_color_class(invalid); });

    constexpr std::array<GalaxyPointColor, 5> expected{{
        {0.99999994, 0.864829004, 0.444727212}, {0.99999994, 0.902213693, 0.608703375},
        {0.99999994, 0.931117773, 0.787465751}, {0.9641608, 0.948678792, 0.985172272},
        {0.864615917, 0.951970816, 0.99999994}}};
    std::vector<SdssRecord> rows;
    for (std::size_t i = 0; i < expected.size(); ++i)
        rows.push_back({{0, double(i) * 12 - 24}, 1, classes[i + 1]});
    rows.push_back({{0, 0}, 1, std::numeric_limits<float>::quiet_NaN()});
    rows.push_back({{0, 0}, 1, std::numeric_limits<float>::infinity()});
    rows.push_back({{0, 0}, 1, -std::numeric_limits<float>::infinity()});
    auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
        std::vector<SdssSpatialSource>{{SdssKind::galaxy, "colors", rows}}));
    GalaxySpatialModel model({GalaxySdssSource{snapshot, 0}});
    RendererDisplayOptions quality; quality.antialias = false;
    const auto bitmap = render_galaxy_bitmap(model, camera, {}, quality, 512, 512, 1,
                                              {}, GalaxyBackground::transparent);
    const auto data = pixels(*bitmap);
    check(bitmap->counts().drawn == 5 && bitmap->counts().invalid == 3,
          "invalid eClass rows do not abort the render worker");
    for (std::size_t i = 0; i < expected.size(); ++i) {
        const GalaxySpatialRecordId id{GalaxySpatialFamily::sdss_galaxy, 0, i};
        const auto color = galaxy_point_color(model, id);
        check(std::abs(color.red - expected[i].red) < 1e-6 &&
              std::abs(color.green - expected[i].green) < 1e-6 &&
              std::abs(color.blue - expected[i].blue) < 1e-6, "official eClass palette");
        const auto point = GalaxyProjector(camera, 512, 512).project(*model.row(id).position);
        check(point.has_value(), "color fixture projects");
        const auto p = (std::size_t(point->y) * 512 + std::size_t(point->x)) * 4;
        check(std::abs(int(data[p]) - int(std::round(expected[i].red * 255))) <= 1 &&
              std::abs(int(data[p + 1]) - int(std::round(expected[i].green * 255))) <= 1 &&
              std::abs(int(data[p + 2]) - int(std::round(expected[i].blue * 255))) <= 1 && data[p + 3] == 255,
              "complete image uses eClass color");
    }
}
void sdss_overlap_order_tests() {
    for (bool reverse : {false, true}) for (std::size_t prefix : {std::size_t(0), std::size_t(511), std::size_t(512)}) {
        std::vector<SdssRecord> rows(prefix, {{0, 20}, 1, 0.08f});
        rows.push_back({{0, 0}, 1, reverse ? -0.26f : 0.42f});
        rows.push_back({{0, 0}, 1, reverse ? 0.42f : -0.26f});
        auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
            std::vector<SdssSpatialSource>{{SdssKind::galaxy, "overlap", rows}}));
        GalaxySpatialModel model({GalaxySdssSource{snapshot, 0}});
        RendererDisplayOptions quality; quality.antialias = false;
        const auto bitmap = render_galaxy_bitmap(model, camera, {}, quality, 512, 512, 1,
                                                  {}, GalaxyBackground::transparent);
        const GalaxySpatialRecordId last{GalaxySpatialFamily::sdss_galaxy, 0, prefix + 1};
        const auto point = GalaxyProjector(camera, 512, 512).project(*model.row(last).position);
        check(point.has_value(), "overlapping points project");
        const auto data = pixels(*bitmap);
        const auto p = (std::size_t(point->y) * 512 + std::size_t(point->x)) * 4;
        const auto expected = galaxy_point_color(model, last);
        check(std::abs(int(data[p]) - int(std::round(expected.red * 255))) <= 1 &&
              std::abs(int(data[p + 1]) - int(std::round(expected.green * 255))) <= 1 &&
              std::abs(int(data[p + 2]) - int(std::round(expected.blue * 255))) <= 1,
              "last overlapping row determines color across batch boundaries");
    }
}
// 各点を原行順に個別描画し、色別バッチの画素順序を比較する。
std::vector<std::uint8_t> ordered_color_reference(const GalaxySpatialModel& model, GalaxyCameraPc view,
                                                   RendererDisplayOptions quality, double width, double height, double scale) {
    const auto raster = galaxy_raster_size(width, height, scale);
    CGColorSpaceRef colors = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(nullptr, raster.width, raster.height, 8, raster.width * 4,
        colors, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colors);
    if (!context) throw std::runtime_error("ordered reference allocation failed");
    CGContextClearRect(context, CGRectMake(0, 0, raster.width, raster.height));
    CGContextTranslateCTM(context, 0, raster.height);
    CGContextScaleCTM(context, double(raster.width) / width, -double(raster.height) / height);
    {
        RendererQualityScope general(context, quality);
        RendererQualityScope points(context, quality, RendererPrimitive::point);
        CGContextClipToRect(context, CGRectMake(0, 0, width, height));
        const GalaxyProjector projector(view, width, height);
        for (std::size_t i = 0; i < model.source_size(0); ++i) {
            const GalaxySpatialRecordId id{GalaxySpatialFamily::sdss_galaxy, 0, i};
            const auto row = model.row(id);
            if (!row.position) continue;
            const auto point = projector.project(*row.position);
            if (!point || !projector.contains(*point)) continue;
            const auto color = galaxy_point_color(model, id);
            CGContextSetRGBFillColor(context, color.red, color.green, color.blue, 1);
            CGContextBeginPath(context);
            CGContextAddEllipseInRect(context, CGRectMake(point->x - 1.25, point->y - 1.25, 2.5, 2.5));
            CGContextFillPath(context);
        }
    }
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    if (!image) throw std::runtime_error("ordered reference image creation failed");
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(image));
    CGImageRelease(image);
    if (!data) throw std::runtime_error("ordered reference image read failed");
    std::vector<std::uint8_t> result(CFDataGetBytePtr(data), CFDataGetBytePtr(data) + CFDataGetLength(data));
    CFRelease(data);
    return result;
}
void sdss_partial_overlap_pixel_tests() {
    struct Viewport { double width, height, scale; };
    for (const auto viewport : {Viewport{127, 97, 1}, Viewport{127, 97, 2},
                                Viewport{127, 97, 0.1}, Viewport{4096, 2048, 1}}) {
        for (bool smoothing : {false, true}) for (int edge = 0; edge < 5; ++edge) {
            // 常に部分的に重なる 2 点を作り、端に配置する場合はもう一方も画面内に置く。
            const double raStep = 700.0 / viewport.height;
            auto candidate = [&](double offset) {
                auto snapshot = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
                    std::vector<SdssSpatialSource>{{SdssKind::galaxy, "overlap pixels", {
                        {{0, 0}, 1, 0.42f}, {{offset < 0 ? 360 + offset : offset, 0}, 1, -0.26f}}}}));
                return GalaxySpatialModel({GalaxySdssSource{snapshot, 0}});
            };
            const auto initialModel = candidate(raStep);
            GalaxyCameraPc view = camera;
            GalaxyProjector initial(view, viewport.width, viewport.height);
            const auto first = initial.project(*initialModel.row({GalaxySpatialFamily::sdss_galaxy, 0, 0}).position);
            const auto second = initial.project(*initialModel.row({GalaxySpatialFamily::sdss_galaxy, 0, 1}).position);
            check(first && second, "partial-overlap fixture projects");
            const bool reverse = (edge == 1 && second->x < first->x) || (edge == 2 && second->x > first->x) ||
                (edge == 3 && second->y < first->y) || (edge == 4 && second->y > first->y);
            const auto model = candidate(reverse ? -raStep : raStep);
            const double x = edge == 1 ? 0.25 : edge == 2 ? viewport.width - 0.25 : viewport.width / 2;
            const double y = edge == 3 ? 0.25 : edge == 4 ? viewport.height - 0.25 : viewport.height / 2;
            const double panFactor = first->depth_pc / view.distance_pc;
            view.pan((x - first->x) * panFactor, (y - first->y) * panFactor, viewport.width, viewport.height);
            const GalaxyProjector projector(view, viewport.width, viewport.height);
            const auto a = projector.project(*model.row({GalaxySpatialFamily::sdss_galaxy, 0, 0}).position);
            const auto b = projector.project(*model.row({GalaxySpatialFamily::sdss_galaxy, 0, 1}).position);
            if (a && b && (!projector.contains(*a) || !projector.contains(*b)))
                std::cerr << "fixture " << viewport.width << " " << viewport.height << " edge " << edge
                          << " a " << a->x << "," << a->y << " b " << b->x << "," << b->y << "\n";
            check(a && b && projector.contains(*a) && projector.contains(*b), "overlap points stay in viewport");
            const double separation = std::hypot(a->x - b->x, a->y - b->y);
            check(separation > 0.01 && separation < 2.5, "fixture uses partial, not identical, overlap");
            RendererDisplayOptions quality; quality.antialias = smoothing;
            const auto actual = render_galaxy_bitmap(model, view, {}, quality, viewport.width, viewport.height,
                                                      viewport.scale, {}, GalaxyBackground::transparent);
            check(pixels(*actual) == ordered_color_reference(model, view, quality, viewport.width, viewport.height,
                                                               viewport.scale),
                  "ordered colors preserve every pixel at edges and raster scales");
        }
    }
}
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
            case GalaxySpatialFamily::sdss_galaxy: CGContextSetRGBFillColor(context, 0.99999994, 0.931117773, 0.787465751, 1); break;
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
        local_object_size_tests();
        sdss_color_tests(); sdss_overlap_order_tests(); sdss_partial_overlap_pixel_tests(); dimensions_tests(); counts_and_pixels_tests(); duplicate_pixel_equivalence_tests(); cancellation_tests();
        transparent_background_tests();
        std::cout << "Galaxy renderer: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Galaxy renderer: " << error.what() << '\n'; return 1;
    }
}
