/**************************************************************************************************

Copyright (c) 2007, 2015-2016   Tsunehiko Kato  and  4D2U Project, National Astronomical Observatory of Japan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#include "mitaka/eclipse.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka {
namespace {
constexpr double pi = 3.141592653589793238462643383279502884;
Vec3 add(Vec3 a, Vec3 b) { return {a.x+b.x,a.y+b.y,a.z+b.z}; }
Vec3 subtract(Vec3 a, Vec3 b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
Vec3 multiply(Vec3 a, double s) { return {a.x*s,a.y*s,a.z*s}; }
double dot(Vec3 a, Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
Vec3 cross(Vec3 a, Vec3 b) { return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x}; }
bool finite(Vec3 a) { return std::isfinite(a.x)&&std::isfinite(a.y)&&std::isfinite(a.z); }
double length(Vec3 a) {
    const double result=std::hypot(a.x,a.y,a.z);
    if (!std::isfinite(result)) throw std::out_of_range("eclipse distance exceeds numerical range");
    return result;
}
Vec3 unit(Vec3 a, double distance) { return {a.x/distance,a.y/distance,a.z/distance}; }
void validate(const EclipseSphere& sphere) {
    if (!finite(sphere.center_au)||!std::isfinite(sphere.radius_au)||sphere.radius_au<=0)
        throw std::invalid_argument("eclipse sphere requires finite position and positive radius");
}
double separated(const EclipseSphere& a, const EclipseSphere& b) {
    const double distance=length(subtract(a.center_au,b.center_au));
    // 比で比較し、半径の和の overflow を避ける。
    if (distance==0 || a.radius_au/distance+b.radius_au/distance>=1)
        throw std::invalid_argument("eclipse spheres must not touch or overlap");
    return distance;
}
void validate(const EclipseGeometry& g) {
    validate(g.sun); validate(g.occluder); validate(g.receiver);
    separated(g.sun,g.occluder); separated(g.sun,g.receiver); separated(g.occluder,g.receiver);
}
} // namespace

double eclipse_obscured_fraction(double radius, double distance) {
    if (!std::isfinite(radius)||!std::isfinite(distance)||radius<0||distance<0)
        throw std::invalid_argument("eclipse angular ratios must be finite and nonnegative");
    if (radius==0) return 0;
    const double large=std::max(1.0,radius), small=std::min(1.0,radius);
    // r+1 が r に丸まる巨大な比でも、差で内外接を分類する。
    if (distance>=large && distance-large>=small) return 0;
    if (distance<=large && large-distance>=small) return radius>=1 ? 1 : radius*radius;
    // 小さい円の中心から共通弦までの符号付き距離。差の平方は因数分解する。
    // ほぼ等径で d が小さい場合と、大きく異なる半径の場合を分けて相殺を避ける。
    double chord;
    if (radius>=1) {
        chord=radius<=2 ? .5*(distance+((1-radius)/distance)*(1+radius)) :
            (distance-radius)*(.5+.5*(radius/distance))+.5/distance;
    } else {
        chord=radius>=.5 ? .5*(distance+((radius-1)/distance)*(radius+1)) :
            (distance-1)*(.5+.5/distance)+.5*radius*(radius/distance);
    }
    if (!std::isfinite(chord)) throw std::out_of_range("eclipse disk chord exceeds numerical range");
    const double relative_chord=std::clamp(chord/small,-1.0,1.0);
    const double height=small*std::sqrt((1-relative_chord)*(1+relative_chord));
    const auto segment=[](double r, double h, double a) {
        const double angle=std::atan2(h,a);
        if (angle<.01) {
            // theta-sin(theta)cos(theta) の同値級数。先に r*theta を掛けて
            // 巨大半径の r*r overflow と細い円弧の桁落ちを避ける。
            const double square=angle*angle, arc=r*angle;
            return arc*arc*angle*(2.0/3+square*(-2.0/15+square*(4.0/315+square*(-2.0/2835))));
        }
        return r*r*(angle-std::sin(angle)*std::cos(angle));
    };
    const double value=(segment(small,height,chord)+segment(large,height,distance-chord))/pi;
    const double maximum=small*small;
    if (!std::isfinite(value)||value < -1e-12||value > maximum+1e-12)
        throw std::out_of_range("eclipse disk area exceeds numerical range");
    return std::clamp(value,0.0,maximum);
}

EclipseSurfaceSample eclipse_surface_sample(const EclipseSphere& sun,
    const EclipseSphere& occluder, Vec3 point) {
    validate(sun); validate(occluder);
    if (!finite(point)) throw std::invalid_argument("eclipse surface point must be finite");
    separated(sun,occluder);
    const Vec3 to_sun=subtract(sun.center_au,point), to_occluder=subtract(occluder.center_au,point);
    const double sun_distance=length(to_sun), occluder_distance=length(to_occluder);
    if (sun_distance<=sun.radius_au||occluder_distance<=occluder.radius_au)
        throw std::invalid_argument("eclipse surface point must be outside both spheres");
    const double sun_radius=std::asin(sun.radius_au/sun_distance);
    const double occluder_radius=std::asin(occluder.radius_au/occluder_distance);
    if (sun_radius==0||occluder_radius==0)
        throw std::out_of_range("eclipse angular radius underflows");
    const Vec3 ns=unit(to_sun,sun_distance), no=unit(to_occluder,occluder_distance);
    const double separation=std::atan2(length(cross(ns,no)),dot(ns,no));
    const double radius_ratio=occluder_radius/sun_radius, separation_ratio=separation/sun_radius;
    if (!std::isfinite(radius_ratio)||!std::isfinite(separation_ratio))
        throw std::out_of_range("eclipse angular ratios exceed numerical range");
    const double fraction=occluder_distance>=sun_distance ? 0 :
        eclipse_obscured_fraction(radius_ratio,separation_ratio);
    return {fraction,sun_radius,occluder_radius,separation};
}

EclipseShadowCones eclipse_occluder_cones(const EclipseSphere& sun, const EclipseSphere& occluder) {
    validate(sun); validate(occluder); separated(sun,occluder);
    if (sun.radius_au<=occluder.radius_au)
        throw std::invalid_argument("finite eclipse cones require sun radius larger than occluder radius");
    const Vec3 sun_to_occluder=subtract(occluder.center_au,sun.center_au);
    const double distance=length(sun_to_occluder);
    const Vec3 axis=unit(sun_to_occluder,distance);
    const double umbra_sin=(sun.radius_au-occluder.radius_au)/distance;
    const double penumbra_sin=sun.radius_au/distance+occluder.radius_au/distance;
    if (!(umbra_sin>0&&umbra_sin<1&&penumbra_sin>0&&penumbra_sin<1))
        throw std::out_of_range("eclipse cone angle exceeds numerical range");
    const double umbra_length=occluder.radius_au/umbra_sin;
    const double penumbra_length=occluder.radius_au/penumbra_sin;
    const Vec3 umbra_apex=add(occluder.center_au,multiply(axis,umbra_length));
    const Vec3 penumbra_apex=subtract(occluder.center_au,multiply(axis,penumbra_length));
    if (!finite(umbra_apex)||!finite(penumbra_apex))
        throw std::out_of_range("eclipse cone apex exceeds numerical range");
    const double umbra_cos=std::sqrt((1-umbra_sin)*(1+umbra_sin));
    const double penumbra_cos=std::sqrt((1-penumbra_sin)*(1+penumbra_sin));
    return {{umbra_apex,multiply(axis,-1),umbra_sin,umbra_cos},
            {penumbra_apex,axis,penumbra_sin,penumbra_cos},axis};
}

std::optional<EclipseShadowCones> eclipse_shadow_cones(const EclipseGeometry& g) {
    validate(g);
    if (g.sun.radius_au<=g.occluder.radius_au)
        throw std::invalid_argument("finite eclipse cones require sun radius larger than occluder radius");
    const double distance=length(subtract(g.occluder.center_au,g.sun.center_au));
    if (length(subtract(g.receiver.center_au,g.sun.center_au))<=distance) return std::nullopt;
    const auto cones=eclipse_occluder_cones(g.sun,g.occluder);
    const Vec3 relative=subtract(g.receiver.center_au,cones.penumbra.apex_au);
    const double axial=dot(relative,cones.shadow_axis_unit);
    const double lateral=length(cross(relative,cones.shadow_axis_unit));
    const double signed_distance=lateral*cones.penumbra.cos_half_angle-axial*cones.penumbra.sin_half_angle;
    if (!std::isfinite(signed_distance)) throw std::out_of_range("eclipse cone distance exceeds numerical range");
    if (signed_distance>g.receiver.radius_au) return std::nullopt;
    return cones;
}

std::optional<Vec3> eclipse_shadow_axis_hit(const EclipseGeometry& g) {
    validate(g);
    const Vec3 to_occluder=subtract(g.occluder.center_au,g.sun.center_au);
    const Vec3 axis=unit(to_occluder,length(to_occluder));
    const Vec3 relative=subtract(g.receiver.center_au,g.occluder.center_au);
    const double axial=dot(relative,axis), lateral=length(cross(relative,axis));
    if (!std::isfinite(axial)) throw std::out_of_range("eclipse axis distance exceeds numerical range");
    if (axial<0||lateral>g.receiver.radius_au) return std::nullopt;
    const double ratio=lateral/g.receiver.radius_au;
    const double offset=g.receiver.radius_au*std::sqrt((1-ratio)*(1+ratio));
    const double distance=axial-offset;
    if (distance<0) return std::nullopt;
    const Vec3 point=add(g.occluder.center_au,multiply(axis,distance));
    if (!finite(point)) throw std::out_of_range("eclipse axis intersection exceeds numerical range");
    return point;
}

std::array<double,3> eclipse_shadow_multiplier(double fraction, std::array<double,3> colour) {
    if (!std::isfinite(fraction)||fraction<0||fraction>1)
        throw std::invalid_argument("eclipse obscured fraction must be in [0,1]");
    for (double& value : colour) {
        if (!std::isfinite(value)||value<0||value>1)
            throw std::invalid_argument("eclipse shadow RGB must be in [0,1]");
        value=1-(1-value)*fraction;
    }
    return colour;
}
} // namespace mitaka
