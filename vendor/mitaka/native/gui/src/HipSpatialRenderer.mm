#include "HipSpatialRenderer.h"
#include "RendererQuality.h"
#include "mitaka/astronomy.hpp"
#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
struct ContextRelease { void operator()(CGContextRef value) const { CGContextRelease(value); } };
using Context = std::unique_ptr<CGContext, ContextRelease>;
}
std::size_t hip_spatial_preview_step(std::size_t count) noexcept {
    return std::max<std::size_t>(1, count / 6000 + (count % 6000 != 0));
}

bool hip_spatial_point_contains(double center_x, double center_y, double x, double y, bool preview) noexcept {
    const auto dx = x - center_x, dy = y - center_y;
    if (preview) return dx >= 0 && dx <= hip_spatial_preview_size && dy >= 0 && dy <= hip_spatial_preview_size;
    return dx * dx + dy * dy <= hip_spatial_point_radius * hip_spatial_point_radius;
}

std::optional<HipSpatialPick> pick_hip_spatial_point(
    const HipSpatialModel& model, const GalaxyProjector& projector,
    double x, double y, double radius, bool preview, std::function<bool()> should_cancel) {
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(radius) || radius < 0 || radius > 1e7)
        throw std::invalid_argument("HIP spatial: invalid pick position or radius");
    if (!projector.contains({x, y, 0})) return std::nullopt;
    std::optional<HipSpatialPick> nearest, painted;
    const auto step = preview ? hip_spatial_preview_step(model.points.size()) : 1;
    std::size_t checked = 0;
    for (std::size_t index = 0; index < model.points.size(); index += step) {
        if (checked++ % 256 == 0 && should_cancel && should_cancel()) return std::nullopt;
        const auto projected = projector.project(model.points[index].position);
        if (!projected || !projector.contains(*projected)) continue;
        const double distance = std::hypot(projected->x - x, projected->y - y);
        if (distance <= radius && hip_spatial_point_contains(projected->x, projected->y, x, y, preview))
            painted = HipSpatialPick{index, distance, projected->depth_pc};
        if (distance > radius || (nearest && (distance > nearest->distance_points ||
            (distance == nearest->distance_points && projected->depth_pc >= nearest->depth_pc)))) continue;
        nearest = HipSpatialPick{index, distance, projected->depth_pc};
    }
    return should_cancel && should_cancel() ? std::nullopt : painted ? painted : nearest;
}

std::shared_ptr<const HipSpatialModel> build_hip_spatial_model(
    const std::vector<mitaka::HipparcosRecord>& stars, std::function<bool()> should_cancel) {
    auto result = std::make_shared<HipSpatialModel>();
    result->total = stars.size();
    result->points.reserve(stars.size());
    for (std::size_t index = 0; index < stars.size(); ++index) {
        if (index % 256 == 0 && should_cancel && should_cancel()) return {};
        const auto& star = stars[index];
        if (!std::isfinite(star.parallax_mas) || star.parallax_mas <= 0) {
            ++result->no_positive_parallax;
            continue;
        }
        const double ra = star.right_ascension_degrees, dec = star.declination_degrees;
        const double distance = 1000.0 / double(star.parallax_mas);
        if (!std::isfinite(ra) || ra < 0 || ra >= 360 || !std::isfinite(dec) || dec < -90 || dec > 90 ||
            !std::isfinite(distance) || distance > maximum_galaxy_coordinate_pc) {
            ++result->invalid;
            continue;
        }
        const auto direction = mitaka::j2000_equatorial_to_ecliptic(mitaka::equatorial_direction({ra, dec}));
        result->points.push_back({index, star.hip,
            {direction.x * distance, direction.y * distance, direction.z * distance}});
    }
    if (should_cancel && should_cancel()) return {};
    return result;
}

std::shared_ptr<const GalaxyBitmap> render_hip_spatial_bitmap(
    const HipSpatialModel& model, GalaxyCameraPc camera, RendererDisplayOptions quality,
    double width, double height, double scale, std::function<bool()> should_cancel) {
    const GalaxyProjector projector(camera, width, height);
    const auto raster = galaxy_raster_size(width, height, scale);
    if (should_cancel && should_cancel()) return {};
    CGColorSpaceRef colors = CGColorSpaceCreateDeviceRGB();
    if (!colors) throw std::runtime_error("HIP spatial: cannot allocate color space");
    Context context(CGBitmapContextCreate(nullptr, raster.width, raster.height, 8, raster.width * 4,
        colors, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big));
    CGColorSpaceRelease(colors);
    if (!context) throw std::runtime_error("HIP spatial: cannot allocate bitmap");
    CGContextClearRect(context.get(), CGRectMake(0, 0, raster.width, raster.height));
    CGContextTranslateCTM(context.get(), 0, raster.height);
    CGContextScaleCTM(context.get(), double(raster.width) / width, -double(raster.height) / height);
    RendererQualityScope general(context.get(), quality);
    RendererQualityScope points(context.get(), quality, RendererPrimitive::point);
    CGContextClipToRect(context.get(), CGRectMake(0, 0, width, height));
    CGContextSetRGBFillColor(context.get(), 1, 1, 1, .8);
    GalaxyRenderCounts counts;
    counts.total = model.points.size();
    std::size_t pending = 0;
    CGContextBeginPath(context.get());
    for (std::size_t index = 0; index < model.points.size(); ++index) {
        if (index % 256 == 0 && should_cancel && should_cancel()) return {};
        const auto point = projector.project(model.points[index].position);
        if (!point || !projector.contains(*point)) { ++counts.outside; continue; }
        constexpr double radius = hip_spatial_point_radius;
        CGContextAddEllipseInRect(context.get(), CGRectMake(point->x-radius, point->y-radius, 2*radius, 2*radius));
        ++counts.drawn;
        if (++pending == 512) { CGContextFillPath(context.get()); CGContextBeginPath(context.get()); pending = 0; }
    }
    if (pending) CGContextFillPath(context.get());
    if (should_cancel && should_cancel()) return {};
    CGImageRef image = CGBitmapContextCreateImage(context.get());
    if (!image) throw std::runtime_error("HIP spatial: cannot create image");
    try {
        auto result = std::make_shared<const GalaxyBitmap>(image, counts);
        CGImageRelease(image);
        return result;
    } catch (...) { CGImageRelease(image); throw; }
}
} // namespace mitaka::gui
