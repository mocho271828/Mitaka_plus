#include "OurGalaxyRenderer.h"
#include "OurGalaxyRadiativeRenderer.h"
#include "RendererQuality.h"
#include <algorithm>
#include <cctype>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
struct ContextRelease { void operator()(CGContextRef value) const { CGContextRelease(value); } };
using Context = std::unique_ptr<CGContext, ContextRelease>;

void validate(const OurGalaxyRenderSettings& settings) {
    const auto meaningful = [](const std::string& text) {
        return std::any_of(text.begin(), text.end(), [](unsigned char c) { return !std::isspace(c); });
    };
    if (!meaningful(settings.coordinate_provenance) || !meaningful(settings.color_provenance))
        throw std::invalid_argument("our galaxy: coordinate and color provenance required");
    const auto& transform = settings.transform;
    for (const auto& row : transform.matrix)
        for (double value : row)
            if (!std::isfinite(value)) throw std::invalid_argument("our galaxy: invalid transform");
    if (!std::isfinite(transform.offset.x_pc) || !std::isfinite(transform.offset.y_pc) ||
        !std::isfinite(transform.offset.z_pc)) throw std::invalid_argument("our galaxy: invalid offset");
    for (const auto& style : settings.styles) {
        const auto valid_color = [](double value) { return std::isfinite(value) && value >= 0 && value <= 1; };
        if (!valid_color(style.red) || !valid_color(style.green) || !valid_color(style.blue) ||
            !valid_color(style.alpha) || !std::isfinite(style.radius_points) ||
            style.radius_points <= 0 || style.radius_points > 100)
            throw std::invalid_argument("our galaxy: invalid point style");
    }
}

NativeEclipticPositionPc position(const mitaka::OurGalaxyRawPositionPc& p, const OurGalaxyTransform& t) {
    const double xyz[] = {p.x_pc, p.y_pc, p.z_pc};
    double result[] = {t.offset.x_pc, t.offset.y_pc, t.offset.z_pc};
    for (std::size_t i = 0; i < 3; ++i)
        for (std::size_t j = 0; j < 3; ++j) result[i] += t.matrix[i][j] * xyz[j];
    return {result[0], result[1], result[2]};
}
}

std::shared_ptr<const GalaxyBitmap> render_our_galaxy_points(
    const mitaka::OurGalaxyModel& model, const OurGalaxyRenderSettings& settings,
    GalaxyCameraPc camera, RendererDisplayOptions quality,
    double width, double height, double scale, std::function<bool()> should_cancel,
    const mitaka::OurGalaxyRadiativeModel* radiative, float galaxy_alpha) {
    validate(settings);
    if (!std::isfinite(galaxy_alpha) || galaxy_alpha < 0 || galaxy_alpha > 1)
        throw std::invalid_argument("our galaxy: invalid galaxy alpha");
    const GalaxyProjector projector(camera, width, height);
    const auto raster = galaxy_raster_size(width, height, scale);
    if (!std::isfinite(double(raster.width) / width) || !std::isfinite(double(raster.height) / height))
        throw std::invalid_argument("our galaxy: invalid viewport transform");
    if (should_cancel && should_cancel()) return {};
    CGColorSpaceRef colors = CGColorSpaceCreateDeviceRGB();
    if (!colors) throw std::runtime_error("our galaxy: cannot allocate color space");
    Context context(CGBitmapContextCreate(nullptr, raster.width, raster.height, 8, raster.width * 4,
        colors, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big));
    CGColorSpaceRelease(colors);
    if (!context) throw std::runtime_error("our galaxy: cannot allocate bitmap");
    CGContextClearRect(context.get(), CGRectMake(0, 0, raster.width, raster.height));
    CGContextTranslateCTM(context.get(), 0, raster.height);
    CGContextScaleCTM(context.get(), double(raster.width) / width, -double(raster.height) / height);
    RendererQualityScope general(context.get(), quality);
    RendererQualityScope points(context.get(), quality, RendererPrimitive::point);
    CGContextClipToRect(context.get(), CGRectMake(0, 0, width, height));
    GalaxyRenderCounts counts;
    const auto observer = radiative ? our_galaxy_camera_origin(camera) : mitaka::OurGalaxyGalacticVector{};
    if (radiative) CGContextSetBlendMode(context.get(), kCGBlendModePlusLighter);
    for (std::size_t group = 0; group < model.groups.size(); ++group) {
        const auto& positions = model.groups[group].positions;
        const auto& style = settings.styles[group];
        counts.total += positions.size();
        CGContextSetRGBFillColor(context.get(), style.red, style.green, style.blue, style.alpha);
        std::size_t pending = 0;
        CGContextBeginPath(context.get());
        for (std::size_t index = 0; index < positions.size(); ++index) {
            if (index % (radiative ? 16 : 256) == 0 && should_cancel && should_cancel()) return {};
            const auto p = position(positions[index], settings.transform);
            const auto valid_coordinate = [](double value) {
                return std::isfinite(value) && std::abs(value) <= maximum_galaxy_coordinate_pc;
            };
            if (!valid_coordinate(p.x_pc) || !valid_coordinate(p.y_pc) || !valid_coordinate(p.z_pc)) {
                ++counts.invalid;
                continue;
            }
            const auto point = projector.project(p);
            if (!point || !projector.contains(*point)) { ++counts.outside; continue; }
            const double radius = style.radius_points;
            if (radiative) {
                const auto extinction = radiative->point_extinction(observer, our_galaxy_galactic_position(p));
                if (!extinction.visible) { ++counts.hidden; continue; }
                CGContextSetRGBFillColor(context.get(), style.red * extinction.transmittance.r,
                    style.green * extinction.transmittance.g, style.blue * extinction.transmittance.b,
                    style.alpha * galaxy_alpha);
                CGContextFillEllipseInRect(context.get(), CGRectMake(point->x - radius, point->y - radius,
                    2 * radius, 2 * radius));
                ++counts.drawn;
                continue;
            }
            CGContextAddEllipseInRect(context.get(), CGRectMake(point->x - radius, point->y - radius,
                2 * radius, 2 * radius));
            ++counts.drawn;
            if (++pending == 512) { CGContextFillPath(context.get()); CGContextBeginPath(context.get()); pending = 0; }
        }
        if (pending) CGContextFillPath(context.get());
    }
    if (should_cancel && should_cancel()) return {};
    CGImageRef image = CGBitmapContextCreateImage(context.get());
    if (!image) throw std::runtime_error("our galaxy: cannot create image");
    try {
        auto result = std::make_shared<const GalaxyBitmap>(image, counts);
        CGImageRelease(image);
        return result;
    } catch (...) { CGImageRelease(image); throw; }
}
} // namespace mitaka::gui
