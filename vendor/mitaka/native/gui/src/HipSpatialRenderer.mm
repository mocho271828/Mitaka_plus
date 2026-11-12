#include "HipSpatialRenderer.h"
#include "RendererQuality.h"
#include "mitaka/astronomy.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <dispatch/dispatch.h>
#include <stdexcept>

namespace mitaka::gui {
namespace {
struct ContextRelease { void operator()(CGContextRef value) const { CGContextRelease(value); } };
using Context = std::unique_ptr<CGContext, ContextRelease>;

constexpr std::size_t hip_batch_size = 512;
constexpr std::size_t max_parallel_batches = 6;
constexpr std::size_t scratch_budget = 64 * 1024 * 1024;

struct HipBatch {
    std::array<CGPoint, hip_batch_size> centers;
    std::size_t count = 0, adjacent_overlaps = 0;
    CGRect bounds = CGRectNull;
    Context bitmap;

    void add(const GalaxyProjectionPc& point) {
        constexpr double radius = hip_spatial_point_radius;
        if (count && std::abs(point.x - centers[count - 1].x) < 2 * radius &&
                     std::abs(point.y - centers[count - 1].y) < 2 * radius) ++adjacent_overlaps;
        centers[count++] = {point.x, point.y};
        bounds = CGRectUnion(bounds, CGRectMake(point.x-radius, point.y-radius, 2*radius, 2*radius));
    }
    bool dense() const { return count >= 128 && adjacent_overlaps >= count / 2; }
};

Context hip_context(CGColorSpaceRef colors, GalaxyRasterSize raster, double width, double height) {
    Context context(CGBitmapContextCreate(nullptr, raster.width, raster.height, 8, raster.width * 4,
        colors, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big));
    if (context) {
        CGContextClearRect(context.get(), CGRectMake(0, 0, raster.width, raster.height));
        // 小領域に原点を移すと Quartz の曲線の丸めが変わる。全バッチに同じ変換を使う。
        CGContextTranslateCTM(context.get(), 0, raster.height);
        CGContextScaleCTM(context.get(), double(raster.width) / width, -double(raster.height) / height);
        CGContextClipToRect(context.get(), CGRectMake(0, 0, width, height));
        CGContextSetRGBFillColor(context.get(), 1, 1, 1, .8);
    }
    return context;
}

void draw_hip_batch(CGContextRef context, const HipBatch& batch, RendererDisplayOptions quality) {
    RendererQualityScope points(context, quality, RendererPrimitive::point);
    constexpr double radius = hip_spatial_point_radius;
    CGContextBeginPath(context);
    for (std::size_t i = 0; i < batch.count; ++i) {
        const auto p = batch.centers[i];
        CGContextAddEllipseInRect(context, CGRectMake(p.x-radius, p.y-radius, 2*radius, 2*radius));
    }
    CGContextFillPath(context);
}

void composite_hip_batch(CGContextRef dest, const HipBatch& batch, GalaxyRasterSize raster,
                         double width, double height) {
    const CGAffineTransform to_pixels = CGAffineTransformMakeScale(raster.width / width, raster.height / height);
    const auto visible = CGRectIntersection(batch.bounds, CGRectMake(0, 0, width, height));
    if (CGRectIsEmpty(visible)) return;
    const auto bounds = CGRectIntersection(CGRectMake(0, 0, raster.width, raster.height),
        CGRectIntegral(CGRectInset(CGRectApplyAffineTransform(visible, to_pixels), -1, -1)));
    const auto src = static_cast<const std::uint8_t*>(CGBitmapContextGetData(batch.bitmap.get()));
    auto dst = static_cast<std::uint8_t*>(CGBitmapContextGetData(dest));
    for (std::size_t y = CGRectGetMinY(bounds); y < CGRectGetMaxY(bounds); ++y) {
        for (std::size_t x = CGRectGetMinX(bounds); x < CGRectGetMaxX(bounds); ++x) {
            const auto offset = (y * raster.width + x) * 4;
            const unsigned alpha = src[offset + 3];
            if (!alpha) continue;
            // 白一色の premultiplied RGBA では4成分が等しい。バッチごとの source-over を原順で合成する。
            const auto result = std::uint8_t(alpha + (dst[offset + 3] * (255 - alpha) + 127) / 255);
            std::fill_n(dst + offset, 4, result);
        }
    }
}

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
    if (!std::isfinite(raster.width / width) || !std::isfinite(raster.height / height))
        throw std::invalid_argument("HIP spatial: non-finite bitmap transform");
    if (should_cancel && should_cancel()) return {};
    CGColorSpaceRef colors = CGColorSpaceCreateDeviceRGB();
    if (!colors) throw std::runtime_error("HIP spatial: cannot allocate color space");
    Context context = hip_context(colors, raster, width, height);
    CGColorSpaceRelease(colors);
    if (!context) throw std::runtime_error("HIP spatial: cannot allocate bitmap");
    colors = CGBitmapContextGetColorSpace(context.get());
    GalaxyRenderCounts counts;
    counts.total = model.points.size();
    const auto workers = std::clamp<std::size_t>(scratch_budget / (raster.width * raster.height * 4),
                                                  1, max_parallel_batches);
    std::array<HipBatch, max_parallel_batches> batches;
    std::size_t current = 0;
    const auto flush = [&](std::size_t size) {
        auto* group = batches.data();
        // 疎な星野には従来の直接描画を使う。密集した合成パスの交差計算だけを並列化する。
        if (std::count_if(group, group + size, [](const HipBatch& b) { return b.dense(); }) > 1) {
            dispatch_apply(size, dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^(std::size_t i) {
                if (!group[i].dense()) return;
                group[i].bitmap = hip_context(colors, raster, width, height);
                if (group[i].bitmap) draw_hip_batch(group[i].bitmap.get(), group[i], quality);
            });
        }
        for (std::size_t i = 0; i < size; ++i) {
            if (should_cancel && should_cancel()) return false;
            auto& batch = group[i];
            if (batch.bitmap) composite_hip_batch(context.get(), batch, raster, width, height);
            else draw_hip_batch(context.get(), batch, quality);
            batch.bitmap.reset();
            batch.count = batch.adjacent_overlaps = 0;
            batch.bounds = CGRectNull;
        }
        return true;
    };
    for (std::size_t index = 0; index < model.points.size(); ++index) {
        if (index % 256 == 0 && should_cancel && should_cancel()) return {};
        const auto point = projector.project(model.points[index].position);
        if (!point || !projector.contains(*point)) { ++counts.outside; continue; }
        ++counts.drawn;
        auto& batch = batches[current];
        batch.add(*point);
        if (batch.count == hip_batch_size && ++current == workers) {
            if (!flush(current)) return {};
            current = 0;
        }
    }
    if (batches[current].count) ++current;
    if (current && !flush(current)) return {};
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
