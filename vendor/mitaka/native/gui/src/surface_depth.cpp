#include "surface_depth.hpp"
#include "planet_surface.hpp"

#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
bool same(Vec3 a, Vec3 b) { return a.x==b.x && a.y==b.y && a.z==b.z; }
bool same(const BodyOrientation& a,const BodyOrientation& b) {
    return same(a.x_axis,b.x_axis)&&same(a.y_axis,b.y_axis)&&same(a.north_axis,b.north_axis);
}
bool same(const SolarCamera& a,const SolarCamera& b) {
    if (!same(a.target,b.target)||a.distance_au!=b.distance_au||a.yaw_deg!=b.yaw_deg||
        a.pitch_deg!=b.pitch_deg||bool(a.frame)!=bool(b.frame)) return false;
    return !a.frame||(same(a.frame->right,b.frame->right)&&same(a.frame->up,b.frame->up)&&
                      same(a.frame->outward,b.frame->outward));
}
bool finite(Vec3 v) { return std::isfinite(v.x)&&std::isfinite(v.y)&&std::isfinite(v.z); }
void validate_viewport(std::size_t width,std::size_t height) {
    if (!width||!height||width>1024||height>1024)
        throw std::invalid_argument("surface depth viewport must be in 1..1024");
}
bool empty_distance(double value) { return value==std::numeric_limits<double>::infinity(); }
} // namespace

void validate_surface_terrain(const TerrainSurfaceFrame* terrain,std::size_t width,std::size_t height) {
    validate_viewport(width,height);
    if (!terrain) return;
    if (terrain->width!=int(width)||terrain->height!=int(height))
        throw std::invalid_argument("terrain frame viewport does not match surface scene");
    switch (terrain->mode) {
        case TerrainSurfaceMode::none: case TerrainSurfaceMode::sphere:
            if (!terrain->samples.empty()) throw std::invalid_argument("non-terrain frame contains samples");
            return;
        case TerrainSurfaceMode::terrain: break;
        default: throw std::invalid_argument("invalid terrain surface mode");
    }
    if (terrain->samples.size()!=width*height) throw std::invalid_argument("terrain frame sample count mismatch");
    for (const auto& sample:terrain->samples) {
        if (empty_distance(sample.distance_au)) continue;
        if (!std::isfinite(sample.distance_au)||sample.distance_au<=0||!finite(sample.normal_local)||
            std::abs(std::hypot(sample.normal_local.x,sample.normal_local.y,sample.normal_local.z)-1)>1e-8||
            !std::isfinite(sample.u)||!std::isfinite(sample.v)||sample.v<0||sample.v>1)
            throw std::invalid_argument("invalid terrain surface sample");
    }
}

SurfaceDepthFrame make_surface_depth_frame(const std::vector<SurfaceSphere>& spheres,
    const SolarCamera& camera,std::size_t width,std::size_t height,std::vector<double> distances) {
    SurfaceDepthFrame result{width,height,camera,{},std::move(distances)};
    result.geometry.reserve(spheres.size());
    for (const auto& sphere:spheres)
        result.geometry.push_back({sphere.center,sphere.orientation,sphere.radius_au,sphere.terrain});
    validate_surface_depth_frame(result,spheres,camera,width,height);
    return result;
}

void validate_surface_depth_frame(const SurfaceDepthFrame& frame,
    const SolarCamera& camera,std::size_t width,std::size_t height) {
    validate_viewport(width,height);
    (void)solar_camera_basis(camera);
    if (frame.width!=width||frame.height!=height||!same(frame.camera,camera)||
        frame.distances_au.size()!=width*height)
        throw std::invalid_argument("opaque depth frame does not match surface scene");
    for (const auto& key:frame.geometry) {
        if (!finite(key.center)||!std::isfinite(key.radius_au)||key.radius_au<=0)
            throw std::invalid_argument("invalid opaque depth geometry");
        validate_surface_terrain(key.terrain,width,height);
    }
    for (double value:frame.distances_au)
        if (!empty_distance(value)&&(!std::isfinite(value)||value<=0))
            throw std::invalid_argument("opaque depth must be positive finite or infinity");
}

void validate_surface_depth_frame(const SurfaceDepthFrame& frame,
    const std::vector<SurfaceSphere>& spheres,const SolarCamera& camera,std::size_t width,std::size_t height) {
    validate_surface_depth_frame(frame,camera,width,height);
    if (frame.geometry.size()!=spheres.size())
        throw std::invalid_argument("opaque depth geometry count does not match surface scene");
    for (std::size_t i=0;i<spheres.size();++i) {
        const auto& key=frame.geometry[i];const auto& sphere=spheres[i];
        if (!same(key.center,sphere.center)||!same(key.orientation,sphere.orientation)||
            key.radius_au!=sphere.radius_au||key.terrain!=sphere.terrain)
            throw std::invalid_argument("opaque depth geometry does not match surface scene");
    }
}

std::optional<double> surface_opaque_distance(const SurfaceSphere& sphere,const SolarCamera& camera,
    std::size_t x,std::size_t y,std::size_t width,std::size_t height) {
    validate_viewport(width,height);
    if (x>=width||y>=height) throw std::invalid_argument("surface depth pixel is outside viewport");
    if (sphere.terrain) {
        if (sphere.terrain->width!=int(width)||sphere.terrain->height!=int(height))
            throw std::invalid_argument("terrain frame viewport does not match surface scene");
        if (sphere.terrain->mode==TerrainSurfaceMode::none) return std::nullopt;
        if (sphere.terrain->mode==TerrainSurfaceMode::terrain) {
            if (sphere.terrain->samples.size()!=width*height)
                throw std::invalid_argument("terrain frame sample count mismatch");
            const double value=sphere.terrain->samples[y*width+x].distance_au;
            return empty_distance(value)?std::nullopt:std::optional<double>(value);
        }
    }
    return sphere_hit_distance(camera,sphere.center,sphere.radius_au,x+.5,y+.5,width,height);
}
} // namespace mitaka::gui
