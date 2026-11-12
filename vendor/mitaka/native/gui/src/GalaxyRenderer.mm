#include "GalaxyRenderer.h"
#include "RendererQuality.h"
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <optional>
#include <stdexcept>
#include <unordered_map>

namespace mitaka::gui {
namespace {
struct ContextRelease { void operator()(CGContextRef value) const { CGContextRelease(value); } };
using Context = std::unique_ptr<CGContext, ContextRelease>;
// 通常 Mitaka 1.3.1 の mtk_galaxies.cpp と common/graphics/color.cpp を
// 参照ビルドし、correct_RGB(0.9 * blackbody_color(B_V_to_Tc(B_V))) から取得。
constexpr std::array<GalaxyPointColor, 5> sdss_colors{{
    {0.99999994, 0.864829004, 0.444727212},
    {0.99999994, 0.902213693, 0.608703375},
    {0.99999994, 0.931117773, 0.787465751},
    {0.9641608, 0.948678792, 0.985172272},
    {0.864615917, 0.951970816, 0.99999994},
}};
struct PathRelease { void operator()(CGPath* path) const { CGPathRelease(path); } };
using Path = std::unique_ptr<CGPath, PathRelease>;
} // namespace

std::size_t sdss_galaxy_color_class(float eclass) {
    if (!std::isfinite(eclass)) throw std::invalid_argument("galaxy color: nonfinite eClass");
    // 極端な入力の float→int 変換を避けたうえで、原典と同じ float 演算を使う。
    if (eclass <= -0.35f) return 0;
    if (eclass >= 0.5f) return 4;
    return std::min<std::size_t>(4, static_cast<std::size_t>((eclass - (-0.35f)) / (0.5f - (-0.35f)) * 5));
}
GalaxyPointColor galaxy_point_color(const GalaxySpatialModel& model, GalaxySpatialRecordId id) {
    (void)model.row_index(id);
    switch (id.family) {
    case GalaxySpatialFamily::sdss_galaxy: {
        const auto& source = std::get<GalaxySdssSource>(model.sources().at(id.source_index));
        return sdss_colors[sdss_galaxy_color_class(source.snapshot->model->record({source.source_index, id.ordinal}).classification_value)];
    }
    case GalaxySpatialFamily::sdss_quasar: return {1.00, 0.55, 0.75};
    case GalaxySpatialFamily::globular_cluster: return {1.00, 0.85, 0.40};
    case GalaxySpatialFamily::nearby_galaxy: return {0.50, 1.00, 0.70};
    }
    throw std::invalid_argument("galaxy color: unknown family");
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
        // 同じバッチ内を 5 色の path に分け、原行数と一時メモリを制限する。
        std::array<Path, 5> paths;
        std::array<std::optional<CGPoint>, 5> previous;
        std::unordered_map<std::uint64_t, unsigned> occupied;
        // 画素を共有し得る異色の点だけ順序を確定する。1 画素分を加えて AA の影響も含める。
        const double padding_x = width / raster.width, padding_y = height / raster.height;
        const double cell_size = 2 * (1.25 + std::max(padding_x, padding_y));
        std::size_t pending = 0;
        const auto flush = [&] {
            for (std::size_t i = 0; i < paths.size(); ++i) {
                if (!paths[i]) continue;
                const auto color = family == GalaxySpatialFamily::sdss_galaxy
                    ? sdss_colors[i] : galaxy_point_color(model, {family, source, 0});
                CGContextSetRGBFillColor(context.get(), color.red, color.green, color.blue, 1);
                CGContextAddPath(context.get(), paths[i].get());
                CGContextFillPath(context.get());
                paths[i].reset();
                previous[i].reset();
            }
            occupied.clear();
            pending = 0;
        };
        for (std::size_t ordinal = 0; ordinal < count; ++ordinal) {
            if (ordinal % 256 == 0 && should_cancel && should_cancel()) return {};
            const GalaxySpatialRecordId id{family, source, ordinal};
            const auto row = model.row(id);
            if (!row.position) { ++counts.invalid; continue; }
            const auto shape = galaxy_spatial_shape(model, row, projector, false, should_cancel);
            if (shape && shape->clipping && shape->clipping->cancelled) return {};
            if (!shape || !shape->intersects_viewport(projector)) { ++counts.outside; continue; }
            const auto& projected = shape->center;
            const double radius = shape->radius;
            const auto bucket = family == GalaxySpatialFamily::sdss_galaxy
                ? sdss_galaxy_color_class(std::get<GalaxySdssSource>(model.sources()[source]).snapshot->model->record(
                    {std::get<GalaxySdssSource>(model.sources()[source]).source_index, ordinal}).classification_value)
                : 0;
            if (family == GalaxySpatialFamily::sdss_galaxy) {
                const auto cell = [cell_size](double value) {
                    return static_cast<std::uint32_t>(std::max(0.0, std::floor(value / cell_size) + 1));
                };
                const auto x0 = cell(projected.x - radius - padding_x);
                const auto x1 = cell(projected.x + radius + padding_x);
                const auto y0 = cell(projected.y - radius - padding_y);
                const auto y1 = cell(projected.y + radius + padding_y);
                const unsigned mask = 1u << bucket;
                bool conflict = false;
                for (auto y = y0; y <= y1 && !conflict; ++y) for (auto x = x0; x <= x1; ++x) {
                    const auto found = occupied.find((std::uint64_t(y) << 32) | x);
                    if (found != occupied.end() && (found->second & ~mask)) { conflict = true; break; }
                }
                if (conflict) flush();
                for (auto y = y0; y <= y1; ++y) for (auto x = x0; x <= x1; ++x)
                    occupied[(std::uint64_t(y) << 32) | x] |= mask;
            }
            // 巨大円は一行で多数の矩形を持ち得るため、通常点の 512 行 batch と分ける。
            if (shape->clipping) flush();
            if (!paths[bucket]) paths[bucket].reset(CGPathCreateMutable());
            const CGPoint position{projected.x, projected.y};
            if (family != GalaxySpatialFamily::sdss_galaxy || !previous[bucket] || !CGPointEqualToPoint(*previous[bucket], position)) {
                if (shape->clipping) {
                    for (const auto& part : shape->clipping->rectangles)
                        CGPathAddRect(paths[bucket].get(), nullptr, CGRectMake(part.x, part.y, part.width, part.height));
                } else {
                    CGPathAddEllipseInRect(paths[bucket].get(), nullptr, CGRectMake(projected.x - radius,
                        projected.y - radius, radius * 2, radius * 2));
                }
            }
            previous[bucket] = position;
            ++counts.drawn;
            if (++pending == 512 || shape->clipping) flush();
        }
        if (pending) flush();
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
