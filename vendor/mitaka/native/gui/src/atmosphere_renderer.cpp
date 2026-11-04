#include "atmosphere_renderer.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
bool finite(Vec3 v) { return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z); }
double dot(Vec3 a, Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
Vec3 scaled(Vec3 v, double factor) { return {v.x*factor,v.y*factor,v.z*factor}; }
Vec3 relative_eye(const SolarCamera& camera, const SolarCameraBasis& axes, Vec3 center) {
    return {(camera.target.x-center.x)+axes.outward.x*camera.distance_au,
            (camera.target.y-center.y)+axes.outward.y*camera.distance_au,
            (camera.target.z-center.z)+axes.outward.z*camera.distance_au};
}
Vec3 sun_direction(Vec3 center) {
    const double length=std::hypot(center.x,center.y,center.z);
    if (!std::isfinite(length) || length==0) throw std::invalid_argument("atmosphere body must be away from the Sun");
    return scaled(center,-1/length);
}
struct PreparedLayer {
    AtmosphereParameters parameters;
    const AtmosphereEmissionMap* multiple;
    Vec3 eye_m, sun;
    double metres_per_au, outer_radius_m;
};
bool reaches_shell(const PreparedLayer& layer, Vec3 ray) {
    const Vec3 eye=scaled(layer.eye_m,1/layer.outer_radius_m);
    if (dot(eye,eye)<=1) return true;
    if (dot(eye,ray)>=0) return false;
    const Vec3 perpendicular{eye.y*ray.z-eye.z*ray.y,eye.z*ray.x-eye.x*ray.z,
                             eye.x*ray.y-eye.y*ray.x};
    return dot(perpendicular,perpendicular)<=1+8*std::numeric_limits<double>::epsilon();
}
std::uint8_t display_byte(double value) {
    return static_cast<std::uint8_t>(std::lround(std::clamp(value,0.0,1.0)*255));
}
} // namespace

void validate_atmosphere_display(const AtmosphereDisplayOptions& options) {
    switch(options.mode) {
        case AtmosphereMode::none: case AtmosphereMode::single: case AtmosphereMode::multiple: break;
        default: throw std::invalid_argument("invalid atmosphere display mode");
    }
    if (!std::isfinite(options.intensity) || options.intensity<0 ||
        options.intensity>std::numeric_limits<float>::max())
        throw std::invalid_argument("atmosphere intensity must be finite and within nonnegative float range");
}

AtmosphereParameters earth_atmosphere_parameters() { return {6378136.6,6378136.6+6*8000,8000,2.69e25,6}; }
AtmosphereParameters mars_atmosphere_parameters(double radius) {
    if (!std::isfinite(radius) || radius<=0 || !std::isfinite(radius+8*11000) || radius+8*11000<=radius)
        throw std::invalid_argument("invalid Mars atmosphere ground radius");
    return {radius,radius+8*11000,11000,4e23,6};
}

TextureImage render_atmosphere_scene(const std::vector<SurfaceSphere>& spheres,
    const std::vector<AtmosphereLayer>& layers, const SolarCamera& camera,
    std::size_t width, std::size_t height, AtmosphereDisplayOptions options) {
    validate_atmosphere_display(options);
    if (width==0 || height==0 || width>1024 || height>1024)
        throw std::invalid_argument("atmosphere viewport dimensions must be in 1..1024");
    const auto axes=solar_camera_basis(camera);
    bool inside_opaque=false;
    for (const auto& sphere:spheres) {
        if (!finite(sphere.center) || !std::isfinite(sphere.radius_au) || sphere.radius_au<=0)
            throw std::invalid_argument("invalid atmosphere occluder geometry");
        const auto eye=relative_eye(camera,axes,sphere.center);
        const double distance=std::hypot(eye.x,eye.y,eye.z);
        if (!std::isfinite(distance)) throw std::invalid_argument("non-finite atmosphere viewpoint");
        inside_opaque=inside_opaque || distance<=sphere.radius_au;
    }
    std::vector<bool> used(spheres.size(),false);
    std::vector<PreparedLayer> prepared;
    for (const auto& layer:layers) {
        if (layer.surface_index>=spheres.size() || used[layer.surface_index])
            throw std::invalid_argument("atmosphere surface index must be valid and unique");
        used[layer.surface_index]=true;
        const auto& sphere=spheres[layer.surface_index];
        if (sphere.emissive) throw std::invalid_argument("emissive surface cannot have an atmosphere layer");
        auto parameters=layer.single;
        parameters.incident_intensity=options.intensity;
        // 非表示でも設定値を検査する。実視点が地表以下の場合は検査用の外向き光線。
        const AtmosphereRay validation{{0,0,parameters.outer_radius_m},{0,0,1},{0,0,1}};
        (void)atmosphere_single_scattering(parameters,validation);
        const double scale=parameters.ground_radius_m/sphere.radius_au;
        const auto eye=scaled(relative_eye(camera,axes,sphere.center),scale);
        if (!std::isfinite(scale) || !finite(eye)) throw std::out_of_range("atmosphere metre conversion exceeds numerical range");
        const auto* map=options.mode==AtmosphereMode::multiple ? layer.multiple : nullptr;
        prepared.push_back({parameters,map,eye,sun_direction(sphere.center),scale,
            std::max(parameters.outer_radius_m,map ? map->grid().outer_radius_m : 0)});
    }
    TextureImage image{width,height,std::vector<std::uint8_t>(width*height*4,0)};
    if (inside_opaque || options.mode==AtmosphereMode::none || options.intensity==0 || prepared.empty()) return image;
    for (std::size_t y=0;y<height;++y) for (std::size_t x=0;x<width;++x) {
        const auto direction=solar_camera_ray(camera,x+.5,y+.5,width,height);
        if (std::none_of(prepared.begin(),prepared.end(),[&](const auto& layer){return reaches_shell(layer,direction);})) continue;
        std::optional<double> opaque_distance;
        for (const auto& sphere:spheres) {
            const auto hit=sphere_hit_distance(camera,sphere.center,sphere.radius_au,x+.5,y+.5,width,height);
            if (hit && (!opaque_distance || *hit<*opaque_distance)) opaque_distance=hit;
        }
        std::array<double,3> rgb{};
        for (const auto& layer:prepared) {
            if (!reaches_shell(layer,direction)) continue;
            AtmosphereRay ray{layer.eye_m,direction,layer.sun};
            if (opaque_distance) ray.maximum_distance_m=*opaque_distance*layer.metres_per_au;
            const auto single=atmosphere_single_scattering(layer.parameters,ray);
            AtmosphereRgb multiple;
            if (layer.multiple && std::hypot(ray.observer_position_m.x,ray.observer_position_m.y,
                ray.observer_position_m.z)>=layer.multiple->grid().ground_radius_m)
                multiple=atmosphere_multiple_scattering(*layer.multiple,ray);
            const auto color=compose_atmosphere_display(single,multiple,options.intensity).rgb;
            rgb[0]+=color.r; rgb[1]+=color.g; rgb[2]+=color.b;
        }
        const auto offset=(y*width+x)*4;
        for (std::size_t channel=0;channel<3;++channel) image.rgba[offset+channel]=display_byte(rgb[channel]);
        if (image.rgba[offset] || image.rgba[offset+1] || image.rgba[offset+2]) image.rgba[offset+3]=255;
    }
    return image;
}
} // namespace mitaka::gui
