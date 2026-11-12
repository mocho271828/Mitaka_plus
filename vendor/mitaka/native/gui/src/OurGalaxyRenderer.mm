#include "OurGalaxyRenderer.h"
#include "OurGalaxyRadiativeRenderer.h"
#include "RendererQuality.h"
#include <algorithm>
#include <cctype>
#include <cmath>
#include <stdexcept>
#include <vector>

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

std::size_t our_galaxy_preview_step(std::size_t count) noexcept {
    return std::max<std::size_t>(1, count / 1500 + (count % 1500 != 0));
}

std::optional<NativeEclipticPositionPc> our_galaxy_transformed_position(
    mitaka::OurGalaxyRawPositionPc raw, const OurGalaxyTransform& transform) {
    const auto p = position(raw, transform);
    const auto valid = [](double value) {
        return std::isfinite(value) && std::abs(value) <= maximum_galaxy_coordinate_pc;
    };
    if (!valid(p.x_pc) || !valid(p.y_pc) || !valid(p.z_pc)) return std::nullopt;
    return p;
}

std::optional<NativeEclipticPositionPc> our_galaxy_point_position(
    const mitaka::OurGalaxyModel& model, OurGalaxyPointId id,
    OurGalaxyPointDisplay display, const OurGalaxyTransform& transform) {
    const auto group = static_cast<std::size_t>(id.group);
    if (group >= model.groups.size()) return std::nullopt;
    const auto& positions = model.groups[group].positions;
    if (id.ordinal >= positions.size()) return std::nullopt;
    const auto raw = positions[id.ordinal];
    if (display == OurGalaxyPointDisplay::complete)
        return our_galaxy_transformed_position(raw, transform);
    if (display != OurGalaxyPointDisplay::preview ||
        id.ordinal % our_galaxy_preview_step(positions.size()) != 0) return std::nullopt;
    const NativeEclipticPositionPc p{raw.x_pc, raw.y_pc, raw.z_pc};
    if (!std::isfinite(p.x_pc) || !std::isfinite(p.y_pc) || !std::isfinite(p.z_pc) ||
        std::abs(p.x_pc) > maximum_galaxy_coordinate_pc ||
        std::abs(p.y_pc) > maximum_galaxy_coordinate_pc ||
        std::abs(p.z_pc) > maximum_galaxy_coordinate_pc) return std::nullopt;
    return p;
}

bool our_galaxy_point_visible(const mitaka::OurGalaxyModel& model, OurGalaxyPointId id,
    const OurGalaxyTransform& transform, OurGalaxyPointDisplay display, GalaxyCameraPc camera,
    double width, double height, const mitaka::OurGalaxyRadiativeModel* radiative) {
    const auto p = our_galaxy_point_position(model, id, display, transform);
    if (!p || (display == OurGalaxyPointDisplay::complete && !radiative)) return false;
    const GalaxyProjector projector(camera, width, height);
    const auto projected = projector.project(*p);
    if (!projected || !projector.contains(*projected)) return false;
    return display == OurGalaxyPointDisplay::preview ||
        radiative->point_extinction(our_galaxy_camera_origin(camera),
                                   our_galaxy_galactic_position(*p)).visible;
}

std::optional<OurGalaxyPointPick> pick_our_galaxy_point(
    const mitaka::OurGalaxyModel& model, const OurGalaxyTransform& transform,
    const OurGalaxyStyles& styles, OurGalaxyPointDisplay display, GalaxyCameraPc camera, double width, double height,
    double x, double y, double radius, std::function<bool()> should_cancel,
    const mitaka::OurGalaxyRadiativeModel* radiative) {
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(radius) || radius < 0 || radius > 1e7)
        throw std::invalid_argument("our galaxy: invalid pick position or radius");
    if (display != OurGalaxyPointDisplay::preview && display != OurGalaxyPointDisplay::complete)
        throw std::invalid_argument("our galaxy: invalid display mode");
    const GalaxyProjector projector(camera, width, height);
    if (!projector.contains({x, y, 0}) || (should_cancel && should_cancel())) return std::nullopt;
    struct Candidate { OurGalaxyPointPick pick; bool painted; };
    std::vector<Candidate> candidates;
    for (std::size_t group = 0; group < model.groups.size(); ++group) {
        const auto& style = styles[group];
        if (!std::isfinite(style.alpha) || style.alpha < 0 || style.alpha > 1 ||
            !std::isfinite(style.radius_points) || style.radius_points <= 0 || style.radius_points > 100)
            throw std::invalid_argument("our galaxy: invalid point style");
        if (style.alpha == 0) continue;
        const auto count = model.groups[group].positions.size();
        const auto step = display == OurGalaxyPointDisplay::preview ? our_galaxy_preview_step(count) : 1;
        std::size_t checked = 0;
        for (std::size_t index = 0; index < count;) {
            if (checked++ % 256 == 0 && should_cancel && should_cancel()) return std::nullopt;
            const OurGalaxyPointId id{static_cast<mitaka::OurGalaxyPointGroup>(group), index};
            const auto p = our_galaxy_point_position(model, id, display, transform);
            if (p) {
                const auto point = projector.project(*p);
                if (point && projector.contains(*point)) {
                    const auto dx = point->x - x, dy = point->y - y;
                    const auto distance = std::hypot(dx, dy);
                    const bool painted = display == OurGalaxyPointDisplay::preview
                        ? std::abs(dx) <= .75 && std::abs(dy) <= .75
                        : distance <= style.radius_points;
                    if (painted || distance <= radius) candidates.push_back({{id, *p, distance, point->depth_pc}, painted});
                }
            }
            if (step > count - index - 1) break;
            index += step;
        }
    }
    if ((should_cancel && should_cancel()) || candidates.empty()) return std::nullopt;
    std::sort(candidates.begin(), candidates.end(), [](const auto& a, const auto& b) {
        if (a.painted != b.painted) return a.painted;
        if (a.painted) {
            if (a.pick.id.group != b.pick.id.group) return a.pick.id.group > b.pick.id.group;
            return a.pick.id.ordinal > b.pick.id.ordinal;
        }
        if (a.pick.distance_points != b.pick.distance_points) return a.pick.distance_points < b.pick.distance_points;
        if (a.pick.depth_pc != b.pick.depth_pc) return a.pick.depth_pc < b.pick.depth_pc;
        if (a.pick.id.group != b.pick.id.group) return a.pick.id.group < b.pick.id.group;
        return a.pick.id.ordinal < b.pick.id.ordinal;
    });
    if (should_cancel && should_cancel()) return std::nullopt;
    if (display == OurGalaxyPointDisplay::preview) return candidates.front().pick;
    std::optional<mitaka::OurGalaxyRadiativeModel> owned_radiative;
    if (!radiative) {
        owned_radiative.emplace(model);
        radiative = &*owned_radiative;
    }
    const auto observer = our_galaxy_camera_origin(camera);
    for (const auto& candidate : candidates) {
        if (should_cancel && should_cancel()) return std::nullopt;
        if (radiative->point_extinction(observer, our_galaxy_galactic_position(candidate.pick.position)).visible)
            return should_cancel && should_cancel() ? std::nullopt : std::optional<OurGalaxyPointPick>(candidate.pick);
    }
    return std::nullopt;
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
            const auto p = our_galaxy_transformed_position(positions[index], settings.transform);
            if (!p) {
                ++counts.invalid;
                continue;
            }
            const auto point = projector.project(*p);
            if (!point || !projector.contains(*point)) { ++counts.outside; continue; }
            const double radius = style.radius_points;
            if (radiative) {
                const auto extinction = radiative->point_extinction(observer, our_galaxy_galactic_position(*p));
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
