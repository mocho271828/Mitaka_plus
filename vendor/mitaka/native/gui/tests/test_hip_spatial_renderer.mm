#include "HipSpatialRenderer.h"
#include "mitaka/astronomy.hpp"
#include <cmath>
#include <cstring>
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
bool near(double left, double right) { return std::abs(left - right) < 1e-8; }
HipparcosRecord star(int hip, float ra, float dec, float parallax) {
    HipparcosRecord result{};
    result.hip = hip; result.right_ascension_degrees = ra;
    result.declination_degrees = dec; result.parallax_mas = parallax;
    return result;
}
void positions() {
    const auto nan = std::numeric_limits<float>::quiet_NaN();
    const std::vector<HipparcosRecord> stars{
        star(1, 0, 0, 100), star(2, 90, 0, 50), star(3, 0, 90, 1000),
        star(4, 0, 0, 0), star(5, 0, 0, -1), star(6, 0, 0, nan),
        star(7, 360, 0, 1), star(8, 0, 91, 1), star(9, nan, 0, 1),
        star(10, 0, 0, std::numeric_limits<float>::denorm_min())};
    const auto model = build_hip_spatial_model(stars);
    check(model && model->total == 10 && model->points.size() == 3 &&
          model->no_positive_parallax == 3 && model->invalid == 4, "input accounting");
    check(model->points[0].source_index == 0 && model->points[0].hip == 1, "source identity");
    const auto p = model->points[0].position;
    check(near(p.x_pc, 10) && near(p.y_pc, 0) && near(p.z_pc, 0), "zero RA/Dec and distance");
    const auto q = model->points[1].position;
    const double obliquity = j2000_obliquity_deg * std::acos(-1) / 180;
    check(near(q.x_pc, 0) && near(q.y_pc, 20 * std::cos(obliquity)) &&
          near(q.z_pc, -20 * std::sin(obliquity)), "equatorial to ecliptic sign");
    const auto r = model->points[2].position;
    check(near(r.x_pc, 0) && near(r.y_pc, std::sin(obliquity)) &&
          near(r.z_pc, std::cos(obliquity)), "equatorial north pole");
    check(stars[0].hip == 1 && stars.size() == 10, "source unchanged");
    check(!build_hip_spatial_model(stars, [] { return true; }), "model cancellation");
}
void render() {
    const auto model = build_hip_spatial_model({star(1, 0, 0, 1000)});
    const GalaxyCameraPc camera{{1, 0, 0}, 0, 0, 10};
    const auto image = render_hip_spatial_bitmap(*model, camera, {}, 128, 128, 1);
    check(image && image->counts().total == 1 && image->counts().drawn == 1, "visible star count");
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(image->image()));
    check(data != nullptr, "image data");
    const auto bytes = CFDataGetBytePtr(data);
    const auto projection = GalaxyProjector(camera, 128, 128).project(model->points[0].position);
    check(projection && near(projection->x, 64) && near(projection->y, 64), "same camera projection");
    const auto offset = (std::size_t(projection->y) * 128 + std::size_t(projection->x)) * 4;
    check(bytes[offset+3] > 0 && bytes[3] == 0, "projected pixel and transparent background");
    CFRelease(data);
    const GalaxyCameraPc away{{1, 0, 0}, 0, 0, 10, SolarCameraBasis{{0,1,0},{0,0,1},{1,0,0}}};
    const auto second = render_hip_spatial_bitmap(*model, away, {}, 128, 128, 1);
    check(second && second->counts().drawn == 1, "arbitrary camera basis accepted");
    check(!render_hip_spatial_bitmap(*model, camera, {}, 128, 128, 1, [] { return true; }), "render cancellation");
    bool invalid_scale = false;
    try { (void)render_hip_spatial_bitmap(*model, camera, {}, 1e-310, 128, 1); }
    catch (const std::invalid_argument&) { invalid_scale = true; }
    check(invalid_scale, "non-finite device transform rejected before allocating a bitmap");
}
// 512 個ずつ元順に直接塗った Quartz 画像と、密集・疎・最後の端数を含む描画を照合する。
void compare_dense_compositing(double scale, bool smoothing) {
    const GalaxyCameraPc camera{{0,0,0}, 0,0,10};
    constexpr double width = 120.5, height = 95.25;
    const GalaxyProjector projector(camera, width, height);
    const auto raster = galaxy_raster_size(width, height, scale);
    HipSpatialModel model;
    for (int i = 0; i < 1537; ++i) {
        const bool dense = i < 1024;
        model.points.push_back({std::size_t(i), i,
            {0, dense ? 2.4 + (i % 17) * .0003 : ((i % 61) - 30) * .2,
                dense ? 1.3 + (i % 31) * .0004 : ((i % 13) - 6) * .6}});
    }
    RendererDisplayOptions quality;
    quality.point_smoothing = smoothing;
    const auto image = render_hip_spatial_bitmap(model, camera, quality, width, height, scale);
    const auto colors = CGColorSpaceCreateDeviceRGB();
    const auto ctx = CGBitmapContextCreate(nullptr, raster.width, raster.height, 8, 4 * raster.width,
        colors, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colors);
    check(ctx != nullptr, "reference bitmap");
    CGContextTranslateCTM(ctx, 0, raster.height);
    CGContextScaleCTM(ctx, raster.width / width, -double(raster.height) / height);
    CGContextSetShouldAntialias(ctx, smoothing);
    CGContextClipToRect(ctx, CGRectMake(0,0,width,height));
    CGContextSetRGBFillColor(ctx, 1,1,1,.8);
    std::size_t drawn = 0;
    for (const auto& star : model.points) {
        const auto point = projector.project(star.position);
        if (!point || !projector.contains(*point)) continue;
        constexpr double r = hip_spatial_point_radius;
        CGContextAddEllipseInRect(ctx, CGRectMake(point->x-r, point->y-r, 2*r, 2*r));
        if (++drawn % 512 == 0) CGContextFillPath(ctx);
    }
    if (drawn % 512) CGContextFillPath(ctx);
    const auto bytes = CGDataProviderCopyData(CGImageGetDataProvider(image->image()));
    const bool identical = bytes && std::memcmp(CFDataGetBytePtr(bytes), CGBitmapContextGetData(ctx),
        raster.width * raster.height * 4) == 0;
    if (bytes) CFRelease(bytes);
    CGContextRelease(ctx);
    check(image->counts().drawn == drawn && drawn > 1024 && drawn < model.points.size(), "all projected HIP source counts");
    check(identical, "dense batches and sparse stars preserve the direct Quartz RGBA image");
    // 開始時と256原行ごとの取消照会を通し、並列描画後の合成で一度だけ取消を返す。
    const auto initial_queries = 1 + (model.points.size() + 255) / 256;
    std::size_t calls = 0;
    check(!render_hip_spatial_bitmap(model, camera, quality, width, height, scale,
          [&] { return ++calls == initial_queries + 1; }), "cancellation never publishes a partial dense frame");
}
void picking() {
    const GalaxyProjector projector(GalaxyCameraPc{{0,0,0}, 0,0,10}, 128, 128);
    HipSpatialModel model;
    model.points = {{0, 1, {0,0,0}}, {1, 2, {1,0,0}}, {2, 3, {0,100,0}}};
    auto selected = pick_hip_spatial_point(model, projector, 64, 64, 8, false);
    check(selected && selected->index == 1 && near(selected->distance_points, 0), "nearer overlapping HIP selected");
    check(hip_spatial_point_contains(64, 64, 64.7, 64, false) &&
          !hip_spatial_point_contains(64, 64, 64.8, 64, false) &&
          hip_spatial_point_contains(64, 64, 65.4, 65.4, true) &&
          !hip_spatial_point_contains(64, 64, 63.9, 64, true), "drawn ellipse and preview rectangle geometry");
    HipSpatialModel partial;
    partial.points = {{0, 1, {0,0,0}}, {1, 2, {0,-0.01,0}}};
    const auto first = projector.project(partial.points[0].position);
    const auto second = projector.project(partial.points[1].position);
    check(first && second && std::hypot(first->x-second->x, first->y-second->y) < .75 &&
          std::hypot(first->x-second->x, first->y-second->y) > 0, "partial overlap fixture");
    selected = pick_hip_spatial_point(partial, projector, first->x, first->y, 8, false);
    check(selected && selected->index == 1, "last painted HIP wins over nearer HIP center");
    check(!pick_hip_spatial_point(model, projector, 0, 0, 1, false), "outside pick radius");
    check(!pick_hip_spatial_point(model, projector, -1, 64, 100, false), "outside viewport");
    check(!pick_hip_spatial_point(model, projector, 64, 64, 8, false, [] { return true; }), "pick cancellation");
    model.points.assign(6001, {0, 1, {0,100,0}});
    model.points[1] = {1, 2, {0,0,0}};
    check(hip_spatial_preview_step(model.points.size()) == 2, "preview stride");
    check(!pick_hip_spatial_point(model, projector, 64, 64, 8, true), "omitted preview point cannot be picked");
    selected = pick_hip_spatial_point(model, projector, 64, 64, 8, false);
    check(selected && selected->index == 1, "full image point can be picked");
    bool rejected = false;
    try { (void)pick_hip_spatial_point(model, projector, 64, 64, -1, false); }
    catch (const std::invalid_argument&) { rejected = true; }
    check(rejected, "invalid radius rejected");
}
}
int main(int argc, char** argv) {
    try {
        positions(); render(); picking();
        compare_dense_compositing(1, false); compare_dense_compositing(2, true);
        if (argc > 1) {
            const auto stars = load_hipparcos(argv[1]);
            const auto model = build_hip_spatial_model(stars);
            check(model && model->points.size() > 1000 && model->total == stars.size() &&
                  model->points.size() + model->no_positive_parallax + model->invalid == model->total,
                  "real HIP records accounted for");
            const auto image = render_hip_spatial_bitmap(*model, GalaxyCameraPc{{0,0,0}, 0,0,100}, {}, 256,256,1);
            check(image && image->counts().drawn > 0 &&
                  image->counts().drawn + image->counts().outside == model->points.size(),
                  "real HIP stars projected and accounted for");
        }
    }
    catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
    std::cout << "HIP spatial renderer: " << checks << " checks passed\n";
}
