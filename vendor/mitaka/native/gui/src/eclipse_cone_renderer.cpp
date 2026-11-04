#include "eclipse_cone_renderer.hpp"
#include "planet_surface.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
bool finite(Vec3 a) { return std::isfinite(a.x)&&std::isfinite(a.y)&&std::isfinite(a.z); }
Vec3 subtract(Vec3 a,Vec3 b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
Vec3 scale(Vec3 a,double s) { return {a.x*s,a.y*s,a.z*s}; }
double dot(Vec3 a,Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
double length(Vec3 a) { return std::hypot(a.x,a.y,a.z); }
Vec3 relative_eye(const SolarCamera& c,const SolarCameraBasis& b,Vec3 center) {
    return {(c.target.x-center.x)+b.outward.x*c.distance_au,
            (c.target.y-center.y)+b.outward.y*c.distance_au,
            (c.target.z-center.z)+b.outward.z*c.distance_au};
}
void validate_sphere(const EclipseSphere& sphere) {
    if (!finite(sphere.center_au)||!std::isfinite(sphere.radius_au)||sphere.radius_au<=0)
        throw std::invalid_argument("invalid eclipse opaque sphere");
}
// 距離を far に正規化して二次方程式を解く。巨大な絶対 AU の平方を避ける。
std::array<double,2> intersections(const EclipseDisplayCone& cone,Vec3 eye,Vec3 direction) {
    eye=scale(eye,1/cone.far_axial_au);
    const double k=1+cone.radial_slope*cone.radial_slope;
    const double axial=dot(eye,cone.axis_unit), axial_ray=dot(direction,cone.axis_unit);
    const double a=1-k*axial_ray*axial_ray;
    const double b=2*(dot(eye,direction)-k*axial*axial_ray);
    const double c=dot(eye,eye)-k*axial*axial;
    constexpr double missing=std::numeric_limits<double>::infinity();
    if (!std::isfinite(a)||!std::isfinite(b)||!std::isfinite(c))
        throw std::out_of_range("eclipse ray exceeds numerical range");
    std::array<double,2> roots{missing,missing};
    if (a==0) { if (b!=0) roots[0]=-c/b; }
    else {
        const double discriminant=b*b-4*a*c;
        if (!std::isfinite(discriminant)) throw std::out_of_range("eclipse discriminant exceeds numerical range");
        if (discriminant<0) return roots;
        if (discriminant==0) roots[0]=-b/(2*a);
        else {
            const double q=-.5*(b+std::copysign(std::sqrt(discriminant),b));
            roots={q/a,c/q};
        }
    }
    for (double& root:roots) {
        const double z=axial+root*axial_ray;
        if (root<=0||!std::isfinite(root)) { root=missing; continue; }
        double end=cone.far_axial_au;
        if (cone.receiver_clip && z!=0) {
            Vec3 radial=subtract({eye.x+root*direction.x,eye.y+root*direction.y,
                                  eye.z+root*direction.z},scale(cone.axis_unit,z));
            const double radius=length(radial);
            if (!(radius>0)) { root=missing; continue; }
            // 負の切断距離では原版 fan が頂点の反対側へ伸びる。同じ母線の
            // radial は負の軸距離とともに反転するため、絶対値だけで選ばない。
            radial=scale(radial,std::copysign(1.0,z)/radius);
            end=eclipse_cone_end_axial(cone,radial);
        }
        const double near=cone.receiver_clip ? std::min(0.0,end) : cone.near_axial_au;
        const double far=cone.receiver_clip ? std::max(0.0,end) : end;
        if (z<near/cone.far_axial_au||z>far/cone.far_axial_au||near==far) root=missing;
        else root*=cone.far_axial_au;
    }
    return roots;
}
} // namespace
double eclipse_cone_end_axial(const EclipseDisplayCone& cone,Vec3 radial) {
    if (!finite(radial)||std::abs(length(radial)-1)>1e-8||std::abs(dot(radial,cone.axis_unit))>1e-8)
        throw std::invalid_argument("eclipse cone radial must be perpendicular and unit length");
    if (!cone.receiver_clip) return cone.far_axial_au;
    const auto& clip=*cone.receiver_clip;
    const double norm=std::hypot(1.0,cone.radial_slope);
    const Vec3 generator{cone.axis_unit.x/norm+radial.x*(cone.radial_slope/norm),
                         cone.axis_unit.y/norm+radial.y*(cone.radial_slope/norm),
                         cone.axis_unit.z/norm+radial.z*(cone.radial_slope/norm)};
    const double along=dot(clip.center_from_apex_au,generator);
    const double perpendicular=length(subtract(clip.center_from_apex_au,scale(generator,along)));
    if (!std::isfinite(along)||!std::isfinite(perpendicular))
        throw std::out_of_range("eclipse cone receiver clipping exceeds numerical range");
    return along>=0&&perpendicular<clip.radius_au ? clip.replacement_axial_au : cone.far_axial_au;
}
std::vector<EclipseDisplayCone> eclipse_display_cones(const EclipseGeometry& g,EclipseDisplayOptions o) {
    // core が同じ二球の接触・半径・有限値を検証し、頂点を一意にする。
    const auto physical=eclipse_occluder_cones(g.sun,g.occluder);
    validate_sphere(g.receiver);
    const Vec3 receiver=subtract(g.receiver.center_au,g.sun.center_au);
    const double receiver_distance=length(receiver);
    if (!std::isfinite(receiver_distance)) throw std::out_of_range("eclipse receiver distance exceeds numerical range");
    if (receiver_distance<=g.receiver.radius_au+g.sun.radius_au ||
        length(subtract(g.receiver.center_au,g.occluder.center_au))<=g.receiver.radius_au+g.occluder.radius_au)
        throw std::invalid_argument("eclipse receiver spheres must be disjoint");
    const double distance=length(subtract(g.occluder.center_au,g.sun.center_au));
    const double umbra_length=length(subtract(physical.umbra.apex_au,g.sun.center_au));
    const double penumbra_length=length(subtract(physical.penumbra.apex_au,g.sun.center_au));
    std::vector<EclipseDisplayCone> result;
    if(o.shadow_umbra) {
        const double a=g.sun.radius_au*(g.sun.radius_au/distance);
        const double b=g.sun.radius_au*std::sqrt(1-std::pow(g.sun.radius_au/distance,2));
        const double far=umbra_length-a;
        const double q=1-receiver_distance/umbra_length;
        const double along=dot(receiver,physical.shadow_axis_unit);
        const double perpendicular=length(subtract(receiver,scale(physical.shadow_axis_unit,along)));
        const double near=q>=0&&q<1&&along>=0&&perpendicular<g.receiver.radius_au ? q*far : 0;
        result.push_back({physical.umbra.apex_au,physical.umbra.axis_unit,b/far,near,far,.5,0,std::nullopt});
    }
    if(o.shadow_penumbra) {
        // 0x4c8c76: a=Rsun^2/Lpen, b=sqrt(Rsun^2-a^2), endRadius=endLength*a/b。
        const double ratio=g.sun.radius_au/penumbra_length;
        if (!(ratio>0&&ratio<1)) throw std::invalid_argument("eclipse penumbra display tangent is undefined");
        const double slope=ratio/std::sqrt(1-ratio*ratio);
        const double far=std::max(umbra_length,receiver_distance)-penumbra_length;
        const double sunward_far=penumbra_length-g.sun.radius_au*ratio;
        result.push_back({physical.penumbra.apex_au,scale(physical.penumbra.axis_unit,-1),
                          slope,0,sunward_far,.5,0,std::nullopt});
        result.push_back({physical.penumbra.apex_au,physical.penumbra.axis_unit,slope,0,far,.5,.5,
                          EclipseConeReceiverClip{subtract(g.receiver.center_au,physical.penumbra.apex_au),
                                                  g.receiver.radius_au,receiver_distance-penumbra_length}});
    }
    for(const auto& c:result) if(!finite(c.apex_au)||!finite(c.axis_unit)||
        !std::isfinite(c.radial_slope)||c.radial_slope<=0||!std::isfinite(c.far_axial_au)||
        c.far_axial_au<=0||!std::isfinite(c.near_axial_au)||c.near_axial_au<0||c.near_axial_au>=c.far_axial_au||
        (c.receiver_clip&&(!finite(c.receiver_clip->center_from_apex_au)||!std::isfinite(c.receiver_clip->replacement_axial_au))))
        throw std::out_of_range("eclipse display cone exceeds numerical range");
    return result;
}
TextureImage render_eclipse_cones(const EclipseGeometry& geometry,EclipseDisplayOptions options,
    const std::vector<EclipseSphere>& opaque,const SolarCamera& camera,std::size_t width,std::size_t height) {
    if(width==0||height==0||width>1024||height>1024)
        throw std::invalid_argument("eclipse viewport dimensions must be in 1..1024");
    const auto axes=solar_camera_basis(camera);
    const auto cones=eclipse_display_cones(geometry,options);
    bool inside=false;
    for(const auto& sphere:opaque) {
        validate_sphere(sphere);
        const double distance=length(relative_eye(camera,axes,sphere.center_au));
        if(!std::isfinite(distance)) throw std::out_of_range("eclipse viewpoint exceeds numerical range");
        inside=inside||distance<=sphere.radius_au;
    }
    TextureImage image{width,height,std::vector<std::uint8_t>(width*height*4,0)};
    if(inside||cones.empty()) return image;
    std::vector<Vec3> eyes;
    for(const auto& cone:cones) eyes.push_back(relative_eye(camera,axes,cone.apex_au));
    for(std::size_t y=0;y<height;++y) for(std::size_t x=0;x<width;++x) {
        const auto ray=solar_camera_ray(camera,x+.5,y+.5,width,height);
        double transmission=1;
        std::optional<double> opaque_distance;
        bool depth_checked=false;
        for(std::size_t i=0;i<cones.size();++i) for(double distance:intersections(cones[i],eyes[i],ray)) {
            if(!std::isfinite(distance)) continue;
            if(!depth_checked) {
                for(const auto& sphere:opaque) {
                    const auto hit=sphere_hit_distance(camera,sphere.center_au,sphere.radius_au,x+.5,y+.5,width,height);
                    if(hit&&(!opaque_distance||*hit<*opaque_distance)) opaque_distance=hit;
                }
                depth_checked=true;
            }
            if(opaque_distance&&distance>=*opaque_distance) continue;
            const auto& cone=cones[i];
            const double z=dot(eyes[i],cone.axis_unit)+distance*dot(ray,cone.axis_unit);
            const double weight=std::clamp((z-cone.near_axial_au)/(cone.far_axial_au-cone.near_axial_au),0.0,1.0);
            const double alpha=cone.near_alpha+(cone.far_alpha-cone.near_alpha)*weight;
            // 全面が同じ赤なので、SourceOver の最終 alpha は順序に依存しない。
            transmission*=1-alpha;
        }
        const auto alpha=static_cast<std::uint8_t>(std::lround((1-transmission)*255));
        if(alpha) { const auto offset=(y*width+x)*4; image.rgba[offset]=255;image.rgba[offset+3]=alpha; }
    }
    return image;
}
} // namespace mitaka::gui
