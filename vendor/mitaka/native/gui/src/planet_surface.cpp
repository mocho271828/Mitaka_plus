#include "planet_surface.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double pi = 3.14159265358979323846;

double dot(Vec3 a, Vec3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }

struct SphereView { Vec3 eye; double distance; };
struct SphereHit { Vec3 normal; double distance; };

SphereView sphere_view(const SolarCamera& camera, const SolarCameraBasis& axes,
                       Vec3 body, double radius) {
    if (!std::isfinite(radius) || radius <= 0 || !std::isfinite(body.x)
        || !std::isfinite(body.y) || !std::isfinite(body.z))
        throw std::invalid_argument("sphere radius must be positive and geometry must be finite");
    // 天体中心との差を先に取り、AU座標に比べて小さい地表高度の桁落ちを抑える。
    const Vec3 eye{((camera.target.x - body.x) + axes.outward.x * camera.distance_au) / radius,
                   ((camera.target.y - body.y) + axes.outward.y * camera.distance_au) / radius,
                   ((camera.target.z - body.z) + axes.outward.z * camera.distance_au) / radius};
    const double distance = std::hypot(eye.x, eye.y, eye.z);
    if (!std::isfinite(distance) || distance <= 1)
        throw std::invalid_argument("surface viewpoint must be outside the sphere at a finite distance");
    return {eye, distance};
}

std::optional<SphereHit> intersect_sphere(const SphereView& view, Vec3 ray) {
    const double b = dot(view.eye, ray);
    if (b >= 0) return std::nullopt;
    const Vec3 perpendicular{view.eye.y * ray.z - view.eye.z * ray.y,
                             view.eye.z * ray.x - view.eye.x * ray.z,
                             view.eye.x * ray.y - view.eye.y * ray.x};
    const double discriminant = 1 - dot(perpendicular, perpendicular);
    // 理想的な接線を内積の丸めだけで取り落とさない。
    if (discriminant < -8 * std::numeric_limits<double>::epsilon()) return std::nullopt;
    // ray×(eye×ray)は球中心への最近接点。遠方/小高度でも
    // 大きなeyeと交点距離を直接差し引かず、近い交点の法線を得る。
    const double along = std::sqrt(std::max(0.0, discriminant));
    Vec3 normal{ray.y * perpendicular.z - ray.z * perpendicular.y - along * ray.x,
                 ray.z * perpendicular.x - ray.x * perpendicular.z - along * ray.y,
                 ray.x * perpendicular.y - ray.y * perpendicular.x - along * ray.z};
    const double length = std::hypot(normal.x, normal.y, normal.z);
    normal = {normal.x / length, normal.y / length, normal.z / length};
    // 二次式の根の積を使い、小高度で-b-alongが相殺するのを避ける。
    const double distance = (view.distance - 1) * ((view.distance + 1) / (-b + along));
    return SphereHit{normal, distance};
}

void validate_orientation(const BodyOrientation& orientation) {
    constexpr double tolerance = 1e-8;
    const std::array<Vec3, 3> axes{orientation.x_axis, orientation.y_axis, orientation.north_axis};
    for (const auto axis : axes)
        if (!std::isfinite(axis.x) || !std::isfinite(axis.y) || !std::isfinite(axis.z)
            || std::abs(dot(axis, axis) - 1) > tolerance)
            throw std::invalid_argument("planet orientation axes must be finite unit vectors");
    if (std::abs(dot(axes[0], axes[1])) > tolerance
        || std::abs(dot(axes[1], axes[2])) > tolerance
        || std::abs(dot(axes[2], axes[0])) > tolerance)
        throw std::invalid_argument("planet orientation axes must be orthogonal");
    const Vec3 cross{axes[0].y * axes[1].z - axes[0].z * axes[1].y,
                     axes[0].z * axes[1].x - axes[0].x * axes[1].z,
                     axes[0].x * axes[1].y - axes[0].y * axes[1].x};
    if (dot(cross, axes[2]) <= 0)
        throw std::invalid_argument("planet orientation axes must form a right-handed basis");
}

void validate_texture(const TextureImage& texture) {
    const auto maximum = std::numeric_limits<std::size_t>::max();
    if (texture.width == 0 || texture.height == 0
        || texture.width > maximum / texture.height
        || texture.width * texture.height > maximum / 4
        || texture.rgba.size() != texture.width * texture.height * 4)
        throw std::invalid_argument("invalid planet texture dimensions or RGBA byte count");
}

Vec3 sun_direction(Vec3 body, bool emissive) {
    if (!std::isfinite(body.x) || !std::isfinite(body.y) || !std::isfinite(body.z))
        throw std::invalid_argument("planet position must be finite");
    const double scale = std::max({std::abs(body.x), std::abs(body.y), std::abs(body.z)});
    if (emissive) return {};
    if (scale == 0) throw std::invalid_argument("non-emissive planet must be away from the Sun");
    // 大きな有限座標でも長さの計算をoverflowさせない。
    const Vec3 scaled{-body.x / scale, -body.y / scale, -body.z / scale};
    const double length = std::hypot(scaled.x, scaled.y, scaled.z);
    return {scaled.x / length, scaled.y / length, scaled.z / length};
}

std::array<double, 3> sample(const TextureImage& texture, Vec3 normal, double longitude_offset) {
    const double longitude = std::atan2(normal.y, normal.x) / (2 * pi) + longitude_offset;
    const double u = longitude - std::floor(longitude);
    const double v = std::acos(std::clamp(normal.z, -1.0, 1.0)) / pi;
    // texel中心に合わせ、経度の継ぎ目では最終列と先頭列を補間する。
    const double x = u * texture.width - 0.5;
    const double y = std::clamp(v * texture.height - 0.5, 0.0, double(texture.height - 1));
    const double floor_x = std::floor(x), floor_y = std::floor(y);
    const auto x0 = floor_x < 0 ? texture.width - 1 : std::size_t(floor_x);
    const auto x1 = (x0 + 1) % texture.width;
    const auto y0 = std::size_t(floor_y), y1 = std::min(y0 + 1, texture.height - 1);
    const double tx = x - floor_x, ty = y - floor_y;
    std::array<double, 3> color{};
    for (std::size_t channel = 0; channel < color.size(); ++channel) {
        const auto pixel = [&](std::size_t column, std::size_t row) {
            return double(texture.rgba[(row * texture.width + column) * 4 + channel]);
        };
        const double top = pixel(x0, y0) * (1 - tx) + pixel(x1, y0) * tx;
        const double bottom = pixel(x0, y1) * (1 - tx) + pixel(x1, y1) * tx;
        color[channel] = top * (1 - ty) + bottom * ty;
    }
    return color;
}

struct PreparedEarthLayers {
    const EarthLayerBinding* binding = nullptr;
    const TextureImage* clouds = nullptr;
    double night_gain = 0;
    double cloud_factor = 1;
};

PreparedEarthLayers prepare_earth_layers(const EarthLayerBinding* binding,
    const SolarCamera& camera, const SolarCameraBasis& axes, Vec3 body, Vec3 light,
    bool emissive, std::optional<double> physical_radius, TextureImage* additive_output) {
    if (!binding) return {};
    validate_earth_layer_view(binding->view);
    if (emissive) throw std::invalid_argument("Earth layers require a non-emissive surface");
    const auto& view = binding->view;
    const Vec3 relative{(camera.target.x - body.x) + axes.outward.x * camera.distance_au,
                        (camera.target.y - body.y) + axes.outward.y * camera.distance_au,
                        (camera.target.z - body.z) + axes.outward.z * camera.distance_au};
    const Vec3 difference{relative.x - view.earth_to_camera_ecliptic_au.x,
                          relative.y - view.earth_to_camera_ecliptic_au.y,
                          relative.z - view.earth_to_camera_ecliptic_au.z};
    const double distance = std::hypot(relative.x, relative.y, relative.z);
    const double discrepancy = std::hypot(difference.x, difference.y, difference.z);
    if (!std::isfinite(distance) || !std::isfinite(discrepancy)
        || discrepancy > 1e-8 * distance
        || dot(light, view.earth_to_sun_ecliptic_unit) < 1 - 1e-8
        || (physical_radius && std::abs(view.display_radius_au / *physical_radius - 1) > 1e-10))
        throw std::invalid_argument("Earth layer geometry must match the rendered surface and camera");
    for (const auto* image : {&binding->assets.clouds, &binding->assets.night_lights})
        if (*image) validate_texture(**image);
    PreparedEarthLayers prepared{binding, nullptr, earth_night_gain(view, binding->options.city_lights),
                                  earth_cloud_radius_factor(view.topography_scale)};
    const auto eye = view.earth_to_camera_ecliptic_au;
    if (binding->options.clouds && binding->assets.clouds
        && std::hypot(eye.x, eye.y, eye.z) > view.display_radius_au * prepared.cloud_factor) {
        if (!additive_output)
            throw std::invalid_argument("visible Earth clouds require a separate additive output image");
        prepared.clouds = &*binding->assets.clouds;
    }
    return prepared;
}

Vec3 texture_normal(Vec3 normal, const BodyOrientation& orientation) {
    return {dot(normal, orientation.x_axis), dot(normal, orientation.y_axis),
            dot(normal, orientation.north_axis)};
}

void add_pixel(TextureImage& image, std::size_t offset, const TextureImage& texture,
    Vec3 normal, const BodyOrientation& orientation, double longitude_offset, double brightness) {
    auto color = sample(texture, texture_normal(normal, orientation), longitude_offset);
    for (auto& channel : color) channel *= brightness;
    const auto added = earth_add_rgb({double(image.rgba[offset]), double(image.rgba[offset + 1]),
                                      double(image.rgba[offset + 2])}, color);
    for (std::size_t channel = 0; channel < added.size(); ++channel)
        image.rgba[offset + channel] = static_cast<std::uint8_t>(std::lround(added[channel]));
    image.rgba[offset + 3] = 255;
}

void shade_pixel(TextureImage& image, std::size_t offset, const TextureImage& texture,
                 Vec3 normal, Vec3 light, const BodyOrientation& orientation,
                 double longitude_offset, bool emissive, const PreparedEarthLayers& layers) {
    const double brightness = emissive ? 1 : 0.3 + 0.7 * std::max(0.0, dot(normal, light));
    // 正規直交基底の転置で天体固定系へ戻す。照明の法線は回転させない。
    const Vec3 body_normal{dot(normal, orientation.x_axis), dot(normal, orientation.y_axis),
                           dot(normal, orientation.north_axis)};
    const auto color = sample(texture, body_normal, longitude_offset);
    for (std::size_t channel = 0; channel < color.size(); ++channel)
        image.rgba[offset + channel] = std::uint8_t(std::clamp(
            std::lround(color[channel] * brightness), 0L, 255L));
    image.rgba[offset + 3] = 255;
    if (layers.binding && layers.binding->assets.night_lights)
        add_pixel(image, offset, *layers.binding->assets.night_lights, normal, orientation,
            longitude_offset, earth_night_brightness(normal, light, layers.night_gain));
}

void validate_eclipse(const EclipseSurfaceBinding* binding, Vec3 center,
                      bool emissive, std::optional<double> radius) {
    if (!binding) return;
    const auto& receiver = binding->receiver();
    const double tolerance = 128 * std::numeric_limits<double>::epsilon() *
        std::max({1.0, std::hypot(center.x, center.y, center.z),
                  std::hypot(receiver.center_au.x, receiver.center_au.y, receiver.center_au.z)});
    if (emissive || std::hypot(center.x-receiver.center_au.x, center.y-receiver.center_au.y,
                               center.z-receiver.center_au.z) > tolerance ||
        (radius && std::abs(receiver.radius_au / *radius - 1) > 1e-10))
        throw std::invalid_argument("eclipse receiver must match the non-emissive rendered sphere");
}
void apply_eclipse(TextureImage& image, std::size_t offset, Vec3 normal,
                   const EclipseSurfaceBinding* binding, double footprint, bool borders) {
    if (!binding || !binding->active()) return;
    const auto effect = binding->effect(normal, footprint);
    for (std::size_t c=0; c<3; ++c)
        image.rgba[offset+c] = static_cast<std::uint8_t>(std::lround(
            borders && effect.border_rgb ? (*effect.border_rgb)[c]*255 :
            image.rgba[offset+c]*effect.multiplier[c]));
}

struct PixelBounds { std::size_t left, top, right, bottom; };

PixelBounds sphere_bounds(const SphereView& view, const SolarCameraBasis& axes,
                          std::size_t width, std::size_t height, double focal) {
    // 半径1のカメラ相対座標。中心のnear-plane判定で地平線の縁を落とさない。
    const double forward = dot(view.eye, axes.outward);
    if (forward <= -1) return {};
    if (forward <= 1) return {0, 0, width, height};
    const auto limits = [forward, focal](double coordinate, double midpoint, std::size_t extent) {
        const double angle = std::atan2(coordinate, forward);
        const double radius = std::asin(1 / std::hypot(coordinate, forward));
        const double low = midpoint + focal * std::tan(angle - radius);
        const double high = midpoint + focal * std::tan(angle + radius);
        // 画素中心と境界の丸めを保守的に含めてから整数へ変換する。
        return std::array<std::size_t, 2>{
            static_cast<std::size_t>(std::clamp(std::floor(low) - 1, 0.0, double(extent))),
            static_cast<std::size_t>(std::clamp(std::ceil(high) + 1, 0.0, double(extent)))};
    };
    const auto x = limits(-dot(view.eye, axes.right), double(width) / 2, width);
    const auto y = limits(dot(view.eye, axes.up), double(height) / 2, height);
    return {x[0], y[0], x[1], y[1]};
}
} // namespace

TextureImage render_planet_surface(const TextureImage& texture, const SolarCamera& camera,
                                  Vec3 body_ecliptic, const BodyOrientation& orientation,
                                  std::size_t diameter, bool emissive,
                                  double longitude_offset_turns, const EarthLayerBinding* earth_layers,
                                  TextureImage* additive_output, const EclipseSurfaceBinding* eclipse) {
    validate_texture(texture);
    validate_orientation(orientation);
    if (diameter == 0 || diameter > 512)
        throw std::invalid_argument("planet surface diameter must be in [1, 512]");
    if (!std::isfinite(longitude_offset_turns))
        throw std::invalid_argument("planet longitude offset must be finite");
    const double longitude_offset = std::remainder(longitude_offset_turns, 1);
    const auto axes = solar_camera_basis(camera);
    const auto light = sun_direction(body_ecliptic, emissive);
    const auto layers = prepare_earth_layers(earth_layers, camera, axes, body_ecliptic, light,
                                             emissive, std::nullopt, additive_output);
    validate_eclipse(eclipse, body_ecliptic, emissive, std::nullopt);
    const double extent = earth_layers ? earth_layer_extent(*earth_layers) : 1;
    const double footprint = eclipse ? 2 * eclipse->receiver().radius_au * extent / diameter : 0;
    TextureImage result{diameter, diameter, std::vector<std::uint8_t>(diameter * diameter * 4)};
    TextureImage additive{diameter, diameter, std::vector<std::uint8_t>(additive_output ? diameter * diameter * 4 : 0)};
    const auto normal_at = [&](double right, double up, double radius) {
        right /= radius;
        up /= radius;
        const double outward = std::sqrt(std::max(0.0, 1 - right * right - up * up));
        return Vec3{right * axes.right.x + up * axes.up.x + outward * axes.outward.x,
                    right * axes.right.y + up * axes.up.y + outward * axes.outward.y,
                    right * axes.right.z + up * axes.up.z + outward * axes.outward.z};
    };
    for (std::size_t y = 0; y < diameter; ++y) {
        const double up = (1 - (2.0 * y + 1) / diameter) * extent;
        for (std::size_t x = 0; x < diameter; ++x) {
            const double right = ((2.0 * x + 1) / diameter - 1) * extent;
            const double radius_squared = right * right + up * up;
            const auto offset = (y * diameter + x) * 4;
            if (radius_squared <= 1) {
                const auto normal = normal_at(right, up, 1);
                shade_pixel(result, offset, texture, normal, light,
                            orientation, longitude_offset, emissive, layers);
                apply_eclipse(result, offset, normal, eclipse, footprint, true);
            }
            if (layers.clouds && radius_squared <= layers.cloud_factor * layers.cloud_factor) {
                const auto normal = normal_at(right, up, layers.cloud_factor);
                add_pixel(additive, offset, *layers.clouds, normal, orientation, longitude_offset,
                          earth_cloud_brightness(normal, light));
                apply_eclipse(additive, offset, normal, eclipse, footprint, false);
            }
        }
    }
    if (additive_output) *additive_output = std::move(additive);
    return result;
}

TextureImage render_surface_view(const TextureImage& texture, const SolarCamera& camera,
                                 Vec3 body_ecliptic, const BodyOrientation& orientation,
                                 double radius_au, std::size_t width, std::size_t height,
                                 double longitude_offset_turns, const EarthLayerBinding* earth_layers,
                                 TextureImage* additive_output, const EclipseSurfaceBinding* eclipse) {
    return render_surface_scene({{texture, body_ecliptic, orientation, radius_au,
                                  false, longitude_offset_turns, earth_layers, eclipse}}, camera, width, height,
                                  additive_output);
}

TextureImage render_surface_scene(const std::vector<SurfaceSphere>& spheres,
                                  const SolarCamera& camera,
                                  std::size_t width, std::size_t height,
                                  TextureImage* additive_output) {
    if (width == 0 || width > 1024 || height == 0 || height > 1024)
        throw std::invalid_argument("surface viewport dimensions must be in [1, 1024]");
    const auto axes = solar_camera_basis(camera);
    // 投影側から画面端の視線を求め、同じ45度視野を画素ループで再利用する。
    const auto right_ray = solar_camera_ray(camera, double(width), double(height) / 2, width, height);
    const auto up_ray = solar_camera_ray(camera, double(width) / 2, 0, width, height);
    const double right_scale = dot(right_ray, axes.right) / -dot(right_ray, axes.outward);
    const double up_scale = dot(up_ray, axes.up) / -dot(up_ray, axes.outward);
    TextureImage result{width, height, std::vector<std::uint8_t>(width * height * 4)};
    std::vector<double> depth(width * height, std::numeric_limits<double>::infinity());
    TextureImage additive{width, height, std::vector<std::uint8_t>(additive_output ? width * height * 4 : 0)};
    std::vector<PreparedEarthLayers> earth_layers;
    earth_layers.reserve(spheres.size());
    const auto ray_at = [&](std::size_t x, std::size_t y) {
        const double up = (1 - (2.0 * y + 1) / height) * up_scale;
        const double right = ((2.0 * x + 1) / width - 1) * right_scale;
        Vec3 ray{-axes.outward.x + right * axes.right.x + up * axes.up.x,
                  -axes.outward.y + right * axes.right.y + up * axes.up.y,
                  -axes.outward.z + right * axes.right.z + up * axes.up.z};
        const double length = std::hypot(ray.x, ray.y, ray.z);
        return Vec3{ray.x / length, ray.y / length, ray.z / length};
    };
    for (const auto& sphere : spheres) {
        validate_texture(sphere.texture);
        validate_orientation(sphere.orientation);
        if (!std::isfinite(sphere.longitude_offset_turns))
            throw std::invalid_argument("surface longitude offset must be finite");
        const auto light = sun_direction(sphere.center, sphere.emissive);
        const auto view = sphere_view(camera, axes, sphere.center, sphere.radius_au);
        validate_eclipse(sphere.eclipse, sphere.center, sphere.emissive, sphere.radius_au);
        earth_layers.push_back(prepare_earth_layers(sphere.earth_layers, camera, axes, sphere.center,
            light, sphere.emissive, sphere.radius_au, additive_output));
        const auto& layers = earth_layers.back();
        const auto bounds = sphere_bounds(view, axes, width, height, double(height) / (2 * up_scale));
        const double longitude_offset = std::remainder(sphere.longitude_offset_turns, 1);
        for (std::size_t y = bounds.top; y < bounds.bottom; ++y) {
            for (std::size_t x = bounds.left; x < bounds.right; ++x) {
                const auto ray = ray_at(x, y);
                const auto hit = intersect_sphere(view, ray);
                const auto offset = y * width + x;
                if (!hit || hit->distance * sphere.radius_au >= depth[offset]) continue;
                depth[offset] = hit->distance * sphere.radius_au;
                shade_pixel(result, offset * 4, sphere.texture, hit->normal, light,
                            sphere.orientation, longitude_offset, sphere.emissive, layers);
                apply_eclipse(result, offset * 4, hit->normal, sphere.eclipse,
                    hit->distance * sphere.radius_au * 2 * up_scale / height, true);
            }
        }
    }
    // 全不透明球の深度確定後に合成する。雲殻は深度を書き換えない。
    // 地表未命中の画素も独立画像へ出し、星空をSourceOverで黒く覆わない。
    for (std::size_t index = 0; index < spheres.size(); ++index) {
        const auto& layers = earth_layers[index];
        if (!layers.clouds) continue;
        const auto& sphere = spheres[index];
        const double radius = sphere.radius_au * layers.cloud_factor;
        const auto view = sphere_view(camera, axes, sphere.center, radius);
        const auto bounds = sphere_bounds(view, axes, width, height, double(height) / (2 * up_scale));
        const auto light = layers.binding->view.earth_to_sun_ecliptic_unit;
        const double longitude_offset = std::remainder(sphere.longitude_offset_turns, 1);
        for (std::size_t y = bounds.top; y < bounds.bottom; ++y) {
            for (std::size_t x = bounds.left; x < bounds.right; ++x) {
                const auto hit = intersect_sphere(view, ray_at(x, y));
                const auto offset = y * width + x;
                if (!hit || hit->distance * radius > depth[offset]) continue;
                add_pixel(additive, offset * 4, *layers.clouds, hit->normal, sphere.orientation,
                          longitude_offset, earth_cloud_brightness(hit->normal, light));
                apply_eclipse(additive, offset * 4, hit->normal, sphere.eclipse,
                    hit->distance * radius * 2 * up_scale / height, false);
            }
        }
    }
    if (additive_output) *additive_output = std::move(additive);
    return result;
}

std::optional<double> sphere_hit_distance(const SolarCamera& camera, Vec3 body_ecliptic,
                                          double radius_au, double x, double y,
                                          double width, double height) {
    const auto ray = solar_camera_ray(camera, x, y, width, height);
    const auto view = sphere_view(camera, solar_camera_basis(camera), body_ecliptic, radius_au);
    const auto hit = intersect_sphere(view, ray);
    if (!hit) return std::nullopt;
    const double distance = hit->distance * radius_au;
    if (!std::isfinite(distance) || distance <= 0)
        throw std::invalid_argument("sphere intersection distance must be positive and finite");
    return distance;
}

} // namespace mitaka::gui
