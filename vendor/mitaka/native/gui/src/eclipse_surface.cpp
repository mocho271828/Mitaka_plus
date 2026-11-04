#include "eclipse_display.hpp"
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
Vec3 subtract(Vec3 a, Vec3 b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
double dot(Vec3 a, Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
bool finite(Vec3 a) { return std::isfinite(a.x)&&std::isfinite(a.y)&&std::isfinite(a.z); }
bool on_border(const EclipseCone& cone, Vec3 point, double footprint) {
    const auto v=subtract(point,cone.apex_au);
    const double axial=dot(v,cone.axis_unit);
    const Vec3 cross{v.y*cone.axis_unit.z-v.z*cone.axis_unit.y,
                     v.z*cone.axis_unit.x-v.x*cone.axis_unit.z,
                     v.x*cone.axis_unit.y-v.y*cone.axis_unit.x};
    return axial>=0 && std::abs(std::hypot(cross.x,cross.y,cross.z)*cone.cos_half_angle-
                                axial*cone.sin_half_angle)<=footprint;
}
} // namespace

EclipseSurfaceBinding::EclipseSurfaceBinding(EclipseSphere sun, EclipseSphere receiver,
    std::vector<EclipseSphere> occluders, EclipseDisplayOptions options, std::array<double,3> colour)
    : sun_(sun), receiver_(receiver), options_(options), shadow_rgb_(colour) {
    (void)eclipse_shadow_multiplier(0,colour);
    if (occluders.empty()) throw std::invalid_argument("eclipse surface binding requires an occluder");
    for (const auto& occluder : occluders) {
        const auto cones=eclipse_shadow_cones({sun,occluder,receiver});
        if (options.shadows||options.shadow_borders) {
            point_casters_.push_back({occluder,eclipse_occluder_cones(sun,occluder)});
            if (cones) casters_.push_back({occluder,*cones});
        }
    }
}

EclipseSurfaceBinding::Effect EclipseSurfaceBinding::effect(Vec3 normal, double footprint) const {
    if (!finite(normal)||std::abs(dot(normal,normal)-1)>1e-8 || !std::isfinite(footprint)||footprint<0)
        throw std::invalid_argument("eclipse surface requires a unit normal and nonnegative footprint");
    const Vec3 point{receiver_.center_au.x+receiver_.radius_au*normal.x,
                     receiver_.center_au.y+receiver_.radius_au*normal.y,
                     receiver_.center_au.z+receiver_.radius_au*normal.z};
    return active() ? effect_at(point,normal,footprint) : Effect{};
}

EclipseSurfaceBinding::Effect EclipseSurfaceBinding::effect_at(Vec3 point, Vec3 normal, double footprint) const {
    if (!finite(point)||!finite(normal)||std::abs(dot(normal,normal)-1)>1e-8 ||
        !std::isfinite(footprint)||footprint<0)
        throw std::invalid_argument("eclipse surface requires a finite point, unit normal and nonnegative footprint");
    Effect result;
    if (dot(normal,subtract(sun_.center_au,point))<=0) return result;
    for (const auto& caster : point_casters_) {
        if (options_.shadows) {
            const auto factor=eclipse_shadow_multiplier(
                eclipse_surface_sample(sun_,caster.sphere,point).obscured_fraction,shadow_rgb_);
            for (std::size_t c=0;c<3;++c) result.multiplier[c]*=factor[c];
        }
        if (options_.shadow_borders) {
            if (on_border(caster.cones.penumbra,point,footprint)) result.border_rgb={{1,0,0}};
            if (on_border(caster.cones.umbra,point,footprint)) result.border_rgb={{1,.5,0}};
        }
    }
    return result;
}

} // namespace mitaka::gui
