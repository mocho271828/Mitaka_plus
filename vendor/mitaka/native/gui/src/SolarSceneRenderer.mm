#import "RendererQuality.h"
#import "SolarSceneRenderer.h"
#import "SkyView.h"
#import "SmallBodyRenderer.h"
#import "SatelliteRenderer.h"
#include "surface_navigation.hpp"
#include "planet_surface.hpp"
#include "eclipse_cone_renderer.hpp"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <limits>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
double physicalRadius(std::size_t index) {
    // 公式1.3.1 mtk_sun.h の R_sun_km。惑星・月は既存コア抽出値を共有する。
    return (index == 0 ? 696000.0 : surface_body_info(index).radius_km) / astronomical_unit_km;
}

bool centerIsOccluded(const SolarScene& scene, std::size_t index, const SolarProjection& point) {
    const auto target = sphere_hit_distance(scene.camera, solar_display_position(scene, index),
        physicalRadius(index), point.x, point.y, scene.map.size.width, scene.map.size.height);
    if (!target) return false;
    for (std::size_t other = 0; other < scene.bodies.size(); ++other) {
        if (other == index) continue;
        const auto distance = sphere_hit_distance(scene.camera, solar_display_position(scene, other),
            physicalRadius(other), point.x, point.y, scene.map.size.width, scene.map.size.height);
        if (distance && *distance < *target) return true;
    }
    return false;
}

NSColor *solarColor(Body body) {
    switch (body) {
        case Body::sun: return [NSColor colorWithSRGBRed:1 green:0.79 blue:0.28 alpha:1];
        case Body::mercury: return NSColor.lightGrayColor;
        case Body::venus: return [NSColor colorWithSRGBRed:1 green:0.9 blue:0.65 alpha:1];
        case Body::earth: return [NSColor colorWithSRGBRed:0.35 green:0.75 blue:1 alpha:1];
        case Body::mars: return [NSColor colorWithSRGBRed:1 green:0.47 blue:0.33 alpha:1];
        case Body::jupiter: return [NSColor colorWithSRGBRed:0.98 green:0.76 blue:0.52 alpha:1];
        case Body::saturn: return [NSColor colorWithSRGBRed:0.91 green:0.85 blue:0.57 alpha:1];
        case Body::uranus: return [NSColor colorWithSRGBRed:0.53 green:0.9 blue:0.92 alpha:1];
        case Body::neptune: return [NSColor colorWithSRGBRed:0.46 green:0.66 blue:1 alpha:1];
        case Body::pluto: return NSColor.lightGrayColor;
        case Body::moon: return [NSColor colorWithSRGBRed:0.84 green:0.83 blue:0.77 alpha:1];
    }
    return NSColor.whiteColor;
}
bool diskIntersectsViewport(const SolarProjection& point, double radius, NSSize size) {
    const double x = std::clamp(point.x, 0.0, size.width);
    const double y = std::clamp(point.y, 0.0, size.height);
    return std::hypot(point.x - x, point.y - y) <= radius;
}
NSImage *surfaceImage(const TextureImage& pixels) {
    if (pixels.width == 0 || pixels.height == 0 || pixels.rgba.empty()) return nil;
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:pixels.width pixelsHigh:pixels.height bitsPerSample:8 samplesPerPixel:4
        hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace
        bitmapFormat:NSBitmapFormatAlphaNonpremultiplied bytesPerRow:pixels.width * 4 bitsPerPixel:32];
    if (!bitmap) return nil;
    std::memcpy(bitmap.bitmapData, pixels.rgba.data(), pixels.rgba.size());
    bitmap = [bitmap bitmapImageRepByRetaggingWithColorSpace:NSColorSpace.sRGBColorSpace];
    if (!bitmap) return nil;
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(pixels.width, pixels.height)];
    [image addRepresentation:bitmap];
    return image;
}
void drawImage(NSImage *image, NSRect rect,
               NSCompositingOperation operation = NSCompositingOperationSourceOver) {
    [image drawInRect:rect fromRect:NSZeroRect operation:operation
        fraction:1 respectFlipped:YES hints:nil];
}
std::optional<EarthLayerBinding> earthBinding(const SolarScene& scene, std::size_t index) {
    if (!scene.textures || scene.bodies[index].id != Body::earth) return std::nullopt;
    const auto center = solar_display_position(scene, index);
    const auto axes = solar_camera_basis(scene.camera);
    const double distance = std::hypot(center.x, center.y, center.z);
    return EarthLayerBinding{scene.textures->earth_layers, scene.earth_layers,
        {{(scene.camera.target.x-center.x) + axes.outward.x*scene.camera.distance_au,
          (scene.camera.target.y-center.y) + axes.outward.y*scene.camera.distance_au,
          (scene.camera.target.z-center.z) + axes.outward.z*scene.camera.distance_au},
         {-center.x/distance, -center.y/distance, -center.z/distance}, physicalRadius(index), 1}};
}
NSDictionary<NSAttributedStringKey, id> *textStyle(NSColor *color) {
    return @{NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular],
             NSForegroundColorAttributeName: color};
}
void lineFrom(CGContextRef context, const SolarScene& scene, Vec3 a, Vec3 b) {
    const auto line = project_solar_segment(a, b, scene.camera, scene.map.size.width, scene.map.size.height);
    if (!line) return;
    CGContextMoveToPoint(context, scene.map.origin.x + (*line)[0].x, scene.map.origin.y + (*line)[0].y);
    CGContextAddLineToPoint(context, scene.map.origin.x + (*line)[1].x, scene.map.origin.y + (*line)[1].y);
}
void drawOrbits(CGContextRef context, const SolarScene& scene) {
    if (!scene.planet_display.orbits || scene.surface_body || scene.preview_body) return;
    RendererQualityScope lines(context, scene.renderer_display, RendererPrimitive::line);
    if (!scene.earth_moon) {
        for (std::size_t index = 0; index < scene.orbits.size(); ++index) {
            [[solarColor(scene.bodies[index + 1].id) colorWithAlphaComponent:0.4] setStroke];
            CGContextSetLineWidth(context, 0.8);
            const auto& orbit = scene.orbits[index];
            for (std::size_t point = 1; point < orbit.size(); ++point)
                lineFrom(context, scene, j2000_equatorial_to_ecliptic(orbit[point - 1]),
                         j2000_equatorial_to_ecliptic(orbit[point]));
            CGContextStrokePath(context);
        }
    }
    // 地心相対の標本へ現在の地球中心を足し、日時変更で軌道全体が取り残されないようにする。
    const Vec3 earth = solar_display_position(scene, 3);
    CGContextSetRGBStrokeColor(context, 0.72, 0.76, 0.87, 0.65);
    CGContextSetLineWidth(context, 0.8);
    for (std::size_t point = 1; point < scene.lunar_orbit.size(); ++point) {
        const Vec3 a = j2000_equatorial_to_ecliptic(scene.lunar_orbit[point - 1]);
        const Vec3 b = j2000_equatorial_to_ecliptic(scene.lunar_orbit[point]);
        lineFrom(context, scene, {earth.x + a.x, earth.y + a.y, earth.z + a.z},
                 {earth.x + b.x, earth.y + b.y, earth.z + b.z});
    }
    CGContextStrokePath(context);
}
TextureImage fallbackTexture(Body body) {
    NSColor *color = [solarColor(body) colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
    return {1, 1, {static_cast<std::uint8_t>(color.redComponent * 255),
                  static_cast<std::uint8_t>(color.greenComponent * 255),
                  static_cast<std::uint8_t>(color.blueComponent * 255), 255}};
}
void drawAtmosphere(const SolarScene& scene, const std::vector<SurfaceSphere>& spheres,
                    const std::vector<Body>& bodies, std::size_t width, std::size_t height) {
    if (scene.atmosphere.mode == AtmosphereMode::none) return;
    std::vector<AtmosphereLayer> layers;
    for (std::size_t index = 0; index < bodies.size(); ++index) {
        if (bodies[index] == Body::earth) {
            const auto* source = scene.textures && scene.textures->atmosphere_emission
                ? &*scene.textures->atmosphere_emission : nullptr;
            layers.push_back({index, earth_atmosphere_parameters(), source && source->map ? &*source->map : nullptr});
        } else if (bodies[index] == Body::mars) {
            layers.push_back({index, mars_atmosphere_parameters(spheres[index].radius_au * astronomical_unit_km * 1000), nullptr});
        }
    }
    if (!layers.empty()) drawImage(surfaceImage(render_atmosphere_scene(
        spheres, layers, scene.camera, width, height, scene.atmosphere)), scene.map, NSCompositingOperationPlusLighter);
}
void drawPhysicalSphere(const SolarScene& scene, std::size_t index, const EclipseDisplayFrame& eclipse) {
    const TextureImage fallback = fallbackTexture(scene.bodies[index].id);
    const TextureImage& texture = scene.textures && scene.textures->images[index]
        ? *scene.textures->images[index] : fallback;
    // 地平線の透視描画は長辺800pxを上限とし、Retina倍率でCPU負荷を増やさない。
    const double scale = std::min(1.0, 800.0 / std::max(scene.map.size.width, scene.map.size.height));
    const auto width = static_cast<std::size_t>(std::max(1.0, std::round(scene.map.size.width * scale)));
    const auto height = static_cast<std::size_t>(std::max(1.0, std::round(scene.map.size.height * scale)));
    const auto layers = earthBinding(scene, index);
    TextureImage clouds;
    const auto image = render_surface_view(texture, scene.camera, solar_display_position(scene, index),
        scene.bodies[index].orientation, surface_body_info(index).radius_km / astronomical_unit_km,
        width, height, scene.bodies[index].id == Body::mars ? 0.0 : 0.5,
        layers ? &*layers : nullptr, &clouds,
        eclipse.surfaces[index] ? &*eclipse.surfaces[index] : nullptr);
    drawImage(surfaceImage(image), scene.map);
    const std::vector<SurfaceSphere> spheres{{texture, solar_display_position(scene, index),
        scene.bodies[index].orientation, physicalRadius(index), false,
        scene.bodies[index].id == Body::mars ? 0.0 : 0.5, layers ? &*layers : nullptr}};
    drawAtmosphere(scene, spheres, {scene.bodies[index].id}, width, height);
    drawImage(surfaceImage(clouds), scene.map, NSCompositingOperationPlusLighter);
}
void drawPhysicalSystem(const SolarScene& scene, const EclipseDisplayFrame& eclipse, bool earthMoonOnly = false) {
    std::array<TextureImage, 11> fallbacks;
    std::array<std::optional<EarthLayerBinding>, 11> layers;
    std::vector<SurfaceSphere> spheres;
    std::vector<Body> bodies;
    spheres.reserve(scene.bodies.size());
    for (std::size_t index = 0; index < scene.bodies.size(); ++index) {
        if (earthMoonOnly && index != 3 && index != 10) continue;
        const Body id = scene.bodies[index].id;
        fallbacks[index] = fallbackTexture(id);
        const TextureImage& texture = scene.textures && scene.textures->images[index]
            ? *scene.textures->images[index] : fallbacks[index];
        if (const auto binding = earthBinding(scene, index)) layers[index].emplace(*binding);
        spheres.push_back({texture, solar_display_position(scene, index), scene.bodies[index].orientation,
            physicalRadius(index), id == Body::sun, (id == Body::mars || id == Body::sun) ? 0.0 : 0.5,
            layers[index] ? &*layers[index] : nullptr,
            eclipse.surfaces[index] ? &*eclipse.surfaces[index] : nullptr});
        bodies.push_back(id);
    }
    // 全天体を1枚へ深度合成する。投影範囲外を走査せず、地平線から遠景まで同じ球を使う。
    const double scale = std::min(1.0, 800.0 / std::max(scene.map.size.width, scene.map.size.height));
    const auto width = static_cast<std::size_t>(std::max(1.0, std::round(scene.map.size.width * scale)));
    const auto height = static_cast<std::size_t>(std::max(1.0, std::round(scene.map.size.height * scale)));
    TextureImage clouds;
    drawImage(surfaceImage(render_surface_scene(spheres, scene.camera, width, height, &clouds)), scene.map);
    drawAtmosphere(scene, spheres, bodies, width, height);
    drawImage(surfaceImage(clouds), scene.map, NSCompositingOperationPlusLighter);
}
void drawBody(const SolarScene& scene, const VisibleSolarBody& body, const EclipseDisplayFrame& eclipse) {
    const CGFloat radius = solar_scene_radius(scene, body.index, body.point.depth);
    const NSPoint center = NSMakePoint(scene.map.origin.x + body.point.x, scene.map.origin.y + body.point.y);
    const NSRect rect = NSMakeRect(center.x - radius, center.y - radius, radius * 2, radius * 2);
    NSImage *image = nil;
    // 実半径が1.5pt以下の遠景だけ、位置が読める最小記号を添える。
    if ((!scene.earth_moon && !scene.physical_navigation) || radius <= 1.5) {
        const auto layers = earthBinding(scene, body.index);
        TextureImage clouds;
        NSRect imageRect = rect;
        const auto* shadow = eclipse.surfaces[body.index] && eclipse.surfaces[body.index]->active()
            ? &*eclipse.surfaces[body.index] : nullptr;
        if ((scene.textures && scene.textures->images[body.index]) || layers || shadow) {
            const double extent = layers ? earth_layer_extent(*layers) : 1;
            imageRect = NSMakeRect(center.x-radius*extent, center.y-radius*extent, 2*radius*extent, 2*radius*extent);
            const auto diameter = static_cast<std::size_t>(std::clamp(std::ceil(2 * radius * extent * scene.backing_scale), 1.0, 512.0));
            const Body id = scene.bodies[body.index].id;
            const TextureImage fallback = fallbackTexture(id);
            const auto& texture = scene.textures && scene.textures->images[body.index]
                ? *scene.textures->images[body.index] : fallback;
            image = surfaceImage(render_planet_surface(texture, scene.camera,
                solar_display_position(scene, body.index), scene.bodies[body.index].orientation,
                diameter, id == Body::sun, (id == Body::mars || id == Body::sun) ? 0.0 : 0.5,
                layers ? &*layers : nullptr, &clouds, shadow));
        }
        if (image) {
            drawImage(image, imageRect);
            drawImage(surfaceImage(clouds), imageRect, NSCompositingOperationPlusLighter);
        }
        else {
            RendererQualityScope points(NSGraphicsContext.currentContext.CGContext, scene.renderer_display, RendererPrimitive::point);
            NSColor *color = solarColor(scene.bodies[body.index].id);
            NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[color blendedColorWithFraction:0.5 ofColor:NSColor.whiteColor]
                                                               endingColor:[color blendedColorWithFraction:0.75 ofColor:NSColor.blackColor]];
            [gradient drawInBezierPath:[NSBezierPath bezierPathWithOvalInRect:rect] angle:50];
        }
    }
    if (scene.selection && *scene.selection == body.index) {
        RendererQualityScope lines(NSGraphicsContext.currentContext.CGContext, scene.renderer_display, RendererPrimitive::line);
        [NSColor.whiteColor setStroke];
        NSBezierPath *ring = [NSBezierPath bezierPathWithOvalInRect:NSInsetRect(rect, -4, -4)];
        ring.lineWidth = 1;
        [ring stroke];
    }
}
void drawLabels(const SolarScene& scene, std::vector<VisibleSolarBody> visible) {
    std::reverse(visible.begin(), visible.end());
    std::stable_sort(visible.begin(), visible.end(), [&scene](const auto& a, const auto& b) {
        return scene.selection && a.index == *scene.selection && b.index != *scene.selection;
    });
    NSMutableArray<NSValue *> *used = [NSMutableArray array];
    for (const auto& body : visible) {
        NSString *name = bodyName(scene.bodies[body.index].id);
        NSColor *color = solarColor(scene.bodies[body.index].id);
        NSDictionary *style = textStyle(color);
        const NSSize size = [name sizeWithAttributes:style];
        const NSPoint center = NSMakePoint(scene.map.origin.x + body.point.x, scene.map.origin.y + body.point.y);
        const CGFloat radius = solar_scene_radius(scene, body.index, body.point.depth);
        std::optional<NSRect> placement;
        for (int attempt = 0; attempt < 12; ++attempt) {
            const CGFloat offset = radius + 8 + (attempt / 2) * 17;
            NSRect rect = NSMakeRect(std::clamp(center.x + radius + 8, scene.map.origin.x, NSMaxX(scene.map) - size.width),
                std::clamp(center.y + (attempt % 2 ? offset : -offset) - size.height / 2,
                           scene.map.origin.y, NSMaxY(scene.map) - size.height), size.width, size.height);
            BOOL overlaps = NO;
            for (NSValue *prior in used) if (NSIntersectsRect(NSInsetRect(rect, -3, -2), prior.rectValue)) overlaps = YES;
            if (!overlaps) { placement = rect; break; }
        }
        if (!placement) continue;
        [used addObject:[NSValue valueWithRect:*placement]];
        RendererQualityScope lines(NSGraphicsContext.currentContext.CGContext, scene.renderer_display, RendererPrimitive::line);
        [[color colorWithAlphaComponent:0.55] setStroke];
        NSBezierPath *leader = [NSBezierPath bezierPath];
        const double dx = placement->origin.x - center.x, dy = NSMidY(*placement) - center.y;
        const double length = std::hypot(dx, dy);
        [leader moveToPoint:NSMakePoint(center.x + radius * dx / std::max(length, 1.0), center.y + radius * dy / std::max(length, 1.0))];
        [leader lineToPoint:NSMakePoint(placement->origin.x, NSMidY(*placement))];
        leader.lineWidth = 0.5;
        [leader stroke];
        RendererQualityScope text(NSGraphicsContext.currentContext.CGContext, scene.renderer_display, RendererPrimitive::text);
        [name drawAtPoint:placement->origin withAttributes:style];
    }
}
} // namespace

std::optional<std::array<Vec3, 2>> solar_axis_segment(const SolarScene& scene, std::size_t index) {
    if (!scene.planet_display.visible || !scene.planet_display.axes || index == 0 || index >= scene.bodies.size())
        return std::nullopt;
    const auto center = solar_display_position(scene, index);
    const auto projected = project_solar(center, scene.camera, scene.map.size.width, scene.map.size.height);
    if (!projected) return std::nullopt;
    const double focal = (scene.map.size.height / 2) / std::tan(22.5 * 3.14159265358979323846 / 180);
    // 遠景の模式円にも同じ北軸を使う。表示半径を世界座標へ戻し、公式の±1.3半径を適用する。
    const double radius = solar_scene_radius(scene, index, projected->depth) * projected->depth / focal;
    const auto north = scene.bodies[index].orientation.north_axis;
    const Vec3 offset{1.3 * radius * north.x, 1.3 * radius * north.y, 1.3 * radius * north.z};
    return std::array<Vec3, 2>{{{center.x-offset.x, center.y-offset.y, center.z-offset.z},
                              {center.x+offset.x, center.y+offset.y, center.z+offset.z}}};
}

Vec3 solar_display_position(const SolarScene& scene, std::size_t index) {
    return j2000_equatorial_to_ecliptic(scene.bodies[index].position_au);
}
double solar_marker_radius(Body body) {
    if (body == Body::sun) return 8;
    if (body == Body::jupiter || body == Body::saturn) return 6;
    return 4.5;
}
double solar_scene_radius(const SolarScene& scene, std::size_t index, double depth) {
    const double focal = (scene.map.size.height / 2) / std::tan(22.5 * 3.14159265358979323846 / 180);
    if (scene.physical_navigation)
        return std::max(1.5, physicalRadius(index) * focal / depth);
    if ((scene.earth_moon || scene.surface_body) && index != 0)
        return std::max(1.5, surface_body_info(index).radius_km / astronomical_unit_km * focal / depth);
    const double base = solar_marker_radius(scene.bodies[index].id);
    return std::clamp(base * 0.0015 * focal / depth, base, 120.0);
}
std::vector<VisibleSolarBody> visible_solar_bodies(const SolarScene& scene) {
    std::vector<VisibleSolarBody> result;
    if (!scene.planet_display.visible || scene.map.size.width <= 0 || scene.map.size.height <= 0) return result;
    for (std::size_t index = 0; index < scene.bodies.size(); ++index) {
        if (!scene.physical_navigation) {
            if (scene.preview_body && index != *scene.preview_body) continue;
            if (scene.earth_moon && index != 3 && index != 10) continue;
            if (scene.surface_body && index == *scene.surface_body) continue;
        }
        const auto point = project_solar(solar_display_position(scene, index), scene.camera, scene.map.size.width, scene.map.size.height);
        if (point && diskIntersectsViewport(*point, solar_scene_radius(scene, index, point->depth), scene.map.size)
            && (!scene.physical_navigation || !centerIsOccluded(scene, index, *point)))
            result.push_back({index, *point});
    }
    std::sort(result.begin(), result.end(), [](const auto& a, const auto& b) { return a.point.depth > b.point.depth; });
    return result;
}
std::optional<std::size_t> pick_solar_body(const SolarScene& scene, NSPoint click) {
    if (!scene.planet_display.visible) return std::nullopt;
    std::optional<std::size_t> picked, surface;
    double nearest = 10, depth = std::numeric_limits<double>::infinity(), surfaceDepth = depth;
    if (scene.earth_moon || scene.physical_navigation) {
        for (std::size_t index = 0; index < scene.bodies.size(); ++index) {
            if (!scene.physical_navigation && index != 3 && index != 10) continue;
            const auto distance = sphere_hit_distance(scene.camera, solar_display_position(scene, index),
                physicalRadius(index),
                click.x-scene.map.origin.x, click.y-scene.map.origin.y, scene.map.size.width, scene.map.size.height);
            if (distance && *distance < surfaceDepth) { surface = index; surfaceDepth = *distance; }
        }
        if (surface) return surface;
    }
    for (const auto& body : visible_solar_bodies(scene)) {
        // 実球へ当たらなかった場合、模式的な最小記号にだけ従来のクリック余白を付ける。
        if ((scene.earth_moon || scene.physical_navigation)
            && solar_scene_radius(scene, body.index, body.point.depth) > 1.5) continue;
        const double distance = std::hypot(click.x - scene.map.origin.x - body.point.x, click.y - scene.map.origin.y - body.point.y);
        if (distance <= solar_scene_radius(scene, body.index, body.point.depth) && body.point.depth < surfaceDepth) {
            surface = body.index;
            surfaceDepth = body.point.depth;
        }
        if (distance < nearest || (distance == nearest && body.point.depth < depth)) {
            picked = body.index;
            nearest = distance;
            depth = body.point.depth;
        }
    }
    return surface ? surface : picked;
}
std::vector<std::string> draw_solar_scene(CGContextRef context, const SolarScene& scene) {
    if (!context || scene.map.size.width<=0 || scene.map.size.height<=0) return {};
    auto eclipse=make_eclipse_display_frame(scene.bodies,scene.julian_date,scene.eclipse_satellites,scene.eclipse_options);
    RendererQualityScope canvas(context, scene.renderer_display);
    CGContextClipToRect(context, scene.map);
    draw_solar_grid(context, scene);
    drawOrbits(context, scene);
    if (scene.small_bodies && scene.small_body_display)
        draw_small_bodies(context, *scene.small_bodies, *scene.small_body_display, scene.small_body_orbits,
            scene.camera, scene.map, scene.small_body_selection, scene.renderer_display);
    if (scene.satellites)
        draw_satellites(context, *scene.satellites, scene.camera, scene.map, scene.satellite_selection,
            scene.renderer_display, scene.satellite_display, scene.satellite_orbits);
    if (scene.spacecraft)
        draw_spacecraft(context, *scene.spacecraft, scene.camera, scene.map, scene.spacecraft_selection,
            scene.spacecraft_display, scene.renderer_display);
    const auto visible = visible_solar_bodies(scene);
    {
        RendererQualityScope lines(context, scene.renderer_display, RendererPrimitive::line);
        CGContextSetRGBStrokeColor(context, 0.55, 0.35, 0.2, 1);
        CGContextSetLineWidth(context, 1.5);
        for (const auto& body : visible) {
            const auto axis = solar_axis_segment(scene, body.index);
            if (axis) lineFrom(context, scene, (*axis)[0], (*axis)[1]);
        }
        CGContextStrokePath(context);
    }
    if (scene.planet_display.visible && scene.earth_moon && !scene.physical_navigation) {
        // 地球と月を同じ深度で評価し、雲殻越しの重なりも配列順に依存させない。
        drawPhysicalSystem(scene, eclipse, true);
    }
    for (const auto& body : visible) drawBody(scene, body, eclipse);
    if (scene.planet_display.labels) drawLabels(scene, visible);
    if (scene.planet_display.visible && scene.physical_navigation) drawPhysicalSystem(scene, eclipse);
    // 地表の不透明な交点を最後に合成し、地平線の向こうの天体・ラベルを隠す。
    else if (scene.planet_display.visible && scene.surface_body) drawPhysicalSphere(scene, *scene.surface_body, eclipse);
    if (scene.planet_display.visible && eclipse.earth_moon_space) {
        std::vector<EclipseSphere> opaque;
        for (std::size_t i=0;i<scene.bodies.size();++i)
            opaque.push_back({solar_display_position(scene,i),physicalRadius(i)});
        const double scale=std::min(1.0,800.0/std::max(scene.map.size.width,scene.map.size.height));
        const auto width=static_cast<std::size_t>(std::max(1.0,std::round(scene.map.size.width*scale)));
        const auto height=static_cast<std::size_t>(std::max(1.0,std::round(scene.map.size.height*scale)));
        try {
            drawImage(surfaceImage(render_eclipse_cones(*eclipse.earth_moon_space,scene.eclipse_options,
                opaque,scene.camera,width,height)),scene.map);
        } catch (const std::invalid_argument& error) {
            eclipse.diagnostics.push_back(std::string("Eclipse cone: ")+error.what());
        } catch (const std::out_of_range& error) {
            eclipse.diagnostics.push_back(std::string("Eclipse cone: ")+error.what());
        }
    }
    return eclipse.diagnostics;
}
