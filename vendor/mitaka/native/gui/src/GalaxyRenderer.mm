#include "GalaxyRenderer.h"
#include "RendererQuality.h"
#include <algorithm>
#include <cmath>
#include <optional>
#include <stdexcept>

namespace mitaka::gui {
namespace {
struct ContextRelease { void operator()(CGContextRef value) const { CGContextRelease(value); } };
using Context = std::unique_ptr<CGContext, ContextRelease>;
void set_family_color(CGContextRef context, GalaxySpatialFamily family) {
    switch (family) {
    case GalaxySpatialFamily::sdss_galaxy: CGContextSetRGBFillColor(context, 0.60, 0.80, 1.00, 1); break;
    case GalaxySpatialFamily::sdss_quasar: CGContextSetRGBFillColor(context, 1.00, 0.55, 0.75, 1); break;
    case GalaxySpatialFamily::globular_cluster: CGContextSetRGBFillColor(context, 1.00, 0.85, 0.40, 1); break;
    case GalaxySpatialFamily::nearby_galaxy: CGContextSetRGBFillColor(context, 0.50, 1.00, 0.70, 1); break;
    }
}
}
GalaxyRasterSize galaxy_raster_size(double width, double height, double scale) {
    if (!std::isfinite(width) || !std::isfinite(height) || width <= 0 || height <= 0 ||
        width > 1e7 || height > 1e7 || !std::isfinite(scale) || scale <= 0 || scale > 16)
        throw std::invalid_argument("galaxy bitmap: invalid viewport or backing scale");
    const double effective = std::min(scale, double(maximum_galaxy_bitmap_dimension) / std::max(width, height));
    return {std::max<std::size_t>(1, std::min(maximum_galaxy_bitmap_dimension,
                static_cast<std::size_t>(std::ceil(width * effective)))),
            std::max<std::size_t>(1, std::min(maximum_galaxy_bitmap_dimension,
                static_cast<std::size_t>(std::ceil(height * effective))))};
}
GalaxyBitmap::GalaxyBitmap(CGImageRef image, GalaxyRenderCounts counts) : image_(image), counts_(counts) {
    if (!image_) throw std::invalid_argument("galaxy bitmap: missing image");
    CGImageRetain(image_);
}
GalaxyBitmap::~GalaxyBitmap() { CGImageRelease(image_); }

std::shared_ptr<const GalaxyBitmap> render_galaxy_bitmap(
    const GalaxySpatialModel& model, GalaxyCameraPc camera, GalaxySpatialVisibility visibility,
    RendererDisplayOptions quality, double width, double height, double scale,
    std::function<bool()> should_cancel, GalaxyBackground background) {
    const GalaxyProjector projector(camera, width, height);
    const auto raster = galaxy_raster_size(width, height, scale);
    if (!std::isfinite(double(raster.width) / width) || !std::isfinite(double(raster.height) / height))
        throw std::invalid_argument("galaxy bitmap: viewport produces a nonfinite drawing transform");
    if (should_cancel && should_cancel()) return {};
    CGColorSpaceRef colors = CGColorSpaceCreateDeviceRGB();
    Context context(CGBitmapContextCreate(nullptr, raster.width, raster.height, 8, raster.width * 4,
        colors, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big));
    CGColorSpaceRelease(colors);
    if (!context) throw std::runtime_error("galaxy bitmap: cannot allocate image context");
    const CGRect bounds = CGRectMake(0, 0, raster.width, raster.height);
    if (background == GalaxyBackground::transparent) {
        CGContextClearRect(context.get(), bounds);
    } else {
        CGContextSetRGBFillColor(context.get(), 0.015, 0.02, 0.035, 1);
        CGContextFillRect(context.get(), bounds);
    }
    CGContextTranslateCTM(context.get(), 0, raster.height);
    CGContextScaleCTM(context.get(), double(raster.width) / width, -double(raster.height) / height);
    RendererQualityScope general(context.get(), quality);
    RendererQualityScope points(context.get(), quality, RendererPrimitive::point);
    CGContextClipToRect(context.get(), CGRectMake(0, 0, width, height));
    GalaxyRenderCounts counts; counts.total = model.size();
    for (std::size_t source = 0; source < model.sources().size(); ++source) {
        const auto family = model.family(source);
        const auto count = model.source_size(source);
        if (should_cancel && should_cancel()) return {};
        if (!visibility.visible(family)) { counts.hidden += count; continue; }
        set_family_color(context.get(), family);
        // Path の一時メモリは固定サイズに抑える。次の batch でも全原行を続ける。
        std::size_t pending = 0;
        std::optional<CGPoint> previous;
        CGContextBeginPath(context.get());
        for (std::size_t ordinal = 0; ordinal < count; ++ordinal) {
            if (ordinal % 256 == 0 && should_cancel && should_cancel()) return {};
            const auto row = model.row({family, source, ordinal});
            if (!row.position) { ++counts.invalid; continue; }
            const auto projected = projector.project(*row.position);
            if (!projected || !projector.contains(*projected)) { ++counts.outside; continue; }
            const double radius = family == GalaxySpatialFamily::globular_cluster ? 2.0 : 1.25;
            // 同一 path 内の連続する同形状は非ゼロ winding の塗り領域を変えない。
            // 元の行数で batch を区切り、次の塗りとの重ね合わせは維持する。
            const CGPoint position{projected->x, projected->y};
            if (!previous || !CGPointEqualToPoint(*previous, position))
                CGContextAddEllipseInRect(context.get(), CGRectMake(projected->x - radius,
                    projected->y - radius, radius * 2, radius * 2));
            previous = position;
            ++counts.drawn;
            if (++pending == 512) {
                CGContextFillPath(context.get()); CGContextBeginPath(context.get());
                pending = 0; previous.reset();
            }
        }
        if (pending) CGContextFillPath(context.get());
    }
    if (should_cancel && should_cancel()) return {};
    CGImageRef image = CGBitmapContextCreateImage(context.get());
    if (!image) throw std::runtime_error("galaxy bitmap: cannot create output image");
    try {
        auto result = std::make_shared<const GalaxyBitmap>(image, counts);
        CGImageRelease(image);
        return result;
    } catch (...) { CGImageRelease(image); throw; }
}
} // namespace mitaka::gui
