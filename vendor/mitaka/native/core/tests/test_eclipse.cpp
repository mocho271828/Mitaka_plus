#include "mitaka/eclipse.hpp"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
constexpr double pi = 3.141592653589793238462643383279502884;
int checks = 0;
void expect(bool value, const char* message) { ++checks; if (!value) throw std::runtime_error(message); }
void near(double actual, double wanted, double tolerance, const char* message) {
    if (!std::isfinite(actual) || std::abs(actual-wanted)>tolerance) {
        std::cerr.precision(17); std::cerr << message << ": " << actual << " != " << wanted << '\n';
    }
    expect(std::isfinite(actual) && std::abs(actual-wanted)<=tolerance, message);
}
void point(Vec3 actual, Vec3 wanted, double tolerance) {
    near(actual.x,wanted.x,tolerance,"point x"); near(actual.y,wanted.y,tolerance,"point y");
    near(actual.z,wanted.z,tolerance,"point z");
}
template<class Exception, class Function> void rejects(Function function, const char* message) {
    bool caught=false;
    try { function(); } catch (const Exception&) { caught=true; }
    expect(caught,message);
}
// 円弧の解析式を使わず、共通の縦断面長を中点積分する独立検算。
double quadrature(double radius, double distance) {
    constexpr int subdivisions=200000;
    const double left=std::max(-1.0,distance-radius), right=std::min(1.0,distance+radius);
    if (left>=right) return 0;
    const double width=(right-left)/subdivisions;
    double sum=0;
    for (int i=0;i<subdivisions;++i) {
        const double x=left+(i+.5)*width;
        const double a=std::sqrt(std::max(0.0,1-x*x));
        const double b=std::sqrt(std::max(0.0,(radius-(x-distance))*(radius+(x-distance))));
        sum+=2*std::min(a,b);
    }
    return sum*width/pi;
}
void disks() {
    near(eclipse_obscured_fraction(0,0),0,0,"zero radius");
    near(eclipse_obscured_fraction(1,0),1,0,"equal concentric disks");
    near(eclipse_obscured_fraction(.5,0),.25,0,"annular concentric disks");
    near(eclipse_obscured_fraction(2,0),1,0,"total concentric disks");
    near(eclipse_obscured_fraction(1,1),2.0/3-std::sqrt(3.0)/(2*pi),2e-15,"known equal-circle lens");
    for (double radius : {.1,.5,1.,2.,10.}) {
        const double inner=std::abs(1-radius), outer=1+radius;
        near(eclipse_obscured_fraction(radius,inner),std::min(1.0,radius*radius),2e-15,"internal tangent");
        near(eclipse_obscured_fraction(radius,outer),0,0,"external tangent");
        near(eclipse_obscured_fraction(radius,std::nextafter(outer,std::numeric_limits<double>::infinity())),0,0,"outside external tangent");
        near(eclipse_obscured_fraction(radius,std::nextafter(outer,0.0)),0,5e-8,"inside external tangent");
        near(eclipse_obscured_fraction(radius,std::nextafter(inner,std::numeric_limits<double>::infinity())),
             std::min(1.0,radius*radius),5e-8,"outside internal tangent");
        for (double fraction : {.1,.3,.5,.7,.9}) {
            const double distance=inner+(outer-inner)*fraction;
            near(eclipse_obscured_fraction(radius,distance),quadrature(radius,distance),2e-7,"independent vertical integral");
        }
        double previous=1;
        for (int i=0;i<=1000;++i) {
            const double value=eclipse_obscured_fraction(radius,outer*i/1000);
            expect(value>=0&&value<=1,"disk overlap bounds");
            expect(value<=previous+2e-12,"disk overlap decreases with separation");
            previous=value;
        }
    }
    const double nan=std::numeric_limits<double>::quiet_NaN(), infinity=std::numeric_limits<double>::infinity();
    for (double invalid : {-1.,nan,infinity}) {
        rejects<std::invalid_argument>([=]{ eclipse_obscured_fraction(invalid,1); },"invalid radius ratio");
        rejects<std::invalid_argument>([=]{ eclipse_obscured_fraction(1,invalid); },"invalid separation ratio");
    }
    near(eclipse_obscured_fraction(std::numeric_limits<double>::max(),0),1,0,"large complete containment");
    near(eclipse_obscured_fraction(std::numeric_limits<double>::max(),std::numeric_limits<double>::max()),
         .5,2e-15,"large equal radius and separation keep half disk");
    near(eclipse_obscured_fraction(1e-20,1),.5e-40,1e-55,"tiny occluder at solar limb");
    for (double distance : {999.1,999.5,1000.,1000.5,1000.9})
        near(eclipse_obscured_fraction(1000,distance),quadrature(1000,distance),2e-7,"large ratio independent integral");
}
void surface() {
    const EclipseSphere sun{{0,0,0},2}, occluder{{10,0,0},1};
    const auto total=eclipse_surface_sample(sun,occluder,{14,0,0});
    near(total.obscured_fraction,1,0,"aligned total eclipse");
    near(total.sun_angular_radius_rad,std::asin(2./14),1e-16,"solar angular radius");
    near(total.occluder_angular_radius_rad,std::asin(1./4),1e-16,"occluder angular radius");
    near(total.separation_rad,0,0,"aligned separation");
    const auto annular=eclipse_surface_sample(sun,occluder,{30,0,0});
    const double ratio=std::asin(1./20)/std::asin(2./30);
    near(annular.obscured_fraction,ratio*ratio,2e-15,"annular angular disk ratio");
    near(eclipse_surface_sample(sun,occluder,{5,0,0}).obscured_fraction,0,0,"opposite directions");
    near(eclipse_surface_sample(sun,occluder,{-10,0,0}).obscured_fraction,0,0,"occluder beyond sun");
    const auto angled=eclipse_surface_sample(sun,occluder,{14,1.5,0});
    expect(angled.obscured_fraction>0&&angled.obscured_fraction<1,"partial eclipse");
    // 正規直交変換・平行移動・一様スケールは視角を変えない。
    for (double scale : {1e-6,1.,1e6}) {
        const auto transformed=eclipse_surface_sample({{2*scale,3*scale,4*scale},2*scale},
            {{2*scale,13*scale,4*scale},scale},{.5*scale,17*scale,4*scale});
        near(transformed.obscured_fraction,angled.obscured_fraction,2e-14,"surface geometry invariance");
    }
    rejects<std::invalid_argument>([&]{ eclipse_surface_sample(sun,occluder,{2,0,0}); },"point on sun");
    rejects<std::invalid_argument>([&]{ eclipse_surface_sample(sun,occluder,{10,0,0}); },"point inside occluder");
    rejects<std::invalid_argument>([&]{ eclipse_surface_sample(sun,{{3,0,0},1},{10,0,0}); },"touching source and occluder");
    rejects<std::out_of_range>([]{ eclipse_surface_sample({{0,0,0},std::numeric_limits<double>::denorm_min()},
        {{10,0,0},1},{30,0,0}); },"underflowed angular radius");
    rejects<std::out_of_range>([]{ eclipse_surface_sample({{0,0,0},std::numeric_limits<double>::denorm_min()},
        {{.5,0,0},.1},{.7,0,0}); },"overflowed angular ratio");
}
EclipseGeometry base_geometry() { return {{{0,0,0},2},{{10,0,0},1},{{14,0,0},.5}}; }
void cones_and_axis() {
    const auto geometry=base_geometry();
    const auto cones=eclipse_shadow_cones(geometry);
    expect(cones.has_value(),"receiver intersects penumbra candidate");
    point(cones->umbra.apex_au,{20,0,0},1e-14);
    point(cones->penumbra.apex_au,{20./3,0,0},2e-15);
    point(cones->shadow_axis_unit,{1,0,0},0);
    point(cones->umbra.axis_unit,{-1,0,0},0);
    point(cones->penumbra.axis_unit,{1,0,0},0);
    near(cones->umbra.sin_half_angle,.1,1e-16,"umbra angle");
    near(cones->penumbra.sin_half_angle,.3,1e-16,"penumbra angle");
    near(std::hypot(cones->umbra.sin_half_angle,cones->umbra.cos_half_angle),1,2e-16,"unit umbra angle");
    near(std::hypot(cones->penumbra.sin_half_angle,cones->penumbra.cos_half_angle),1,2e-16,"unit penumbra angle");
    const auto independent=eclipse_occluder_cones(geometry.sun,geometry.occluder);
    point(independent.umbra.apex_au,cones->umbra.apex_au,0);
    point(independent.penumbra.apex_au,cones->penumbra.apex_au,0);
    near(independent.penumbra.sin_half_angle,cones->penumbra.sin_half_angle,0,"shared cone formula");
    rejects<std::invalid_argument>([]{ eclipse_occluder_cones({{0,0,0},2},{{3,0,0},1}); },"cone touching sources");
    rejects<std::invalid_argument>([]{ eclipse_occluder_cones({{0,0,0},2},{{std::nextafter(3.,0.),0,0},1}); },"cone overlapping sources");
    expect(eclipse_occluder_cones({{0,0,0},2},{{std::nextafter(3.,4.),0,0},1}).penumbra.sin_half_angle<1,"cone nextafter separated sources");
    rejects<std::invalid_argument>([]{ eclipse_occluder_cones({{0,0,0},1},{{10,0,0},1}); },"cone cylindrical boundary");
    rejects<std::invalid_argument>([]{ eclipse_occluder_cones({{0,0,0},std::nextafter(1.,0.)},{{10,0,0},1}); },"cone inverted-radius boundary");
    expect(eclipse_occluder_cones({{0,0,0},std::nextafter(1.,2.)},{{10,0,0},1}).umbra.sin_half_angle>0,"cone nextafter larger sun");
    const auto hit=eclipse_shadow_axis_hit(geometry);
    expect(hit.has_value(),"shadow axis hit"); point(*hit,{13.5,0,0},0);
    auto changed=geometry;
    changed.receiver.center_au={3,0,0};
    expect(!eclipse_shadow_cones(changed),"receiver nearer sun skipped");
    expect(!eclipse_shadow_axis_hit(changed),"receiver behind forward ray skipped");
    changed.receiver.center_au={14,10,0};
    expect(!eclipse_shadow_cones(changed),"receiver outside penumbra skipped");
    expect(!eclipse_shadow_axis_hit(changed),"axis misses receiver");
    changed.receiver.center_au={14,.5,0};
    expect(eclipse_shadow_axis_hit(changed).has_value(),"axis tangent preserved");
    point(*eclipse_shadow_axis_hit(changed),{14,0,0},0);
    changed.receiver.center_au.y=std::nextafter(.5,1.);
    expect(!eclipse_shadow_axis_hit(changed),"axis outside tangent");
    changed.receiver.center_au.y=std::nextafter(.5,0.);
    expect(eclipse_shadow_axis_hit(changed).has_value(),"axis inside tangent");
    for (double scale : {1e-6,1.,1e6}) {
        const EclipseGeometry transformed{{{2*scale,3*scale,4*scale},2*scale},
            {{2*scale,13*scale,4*scale},scale},{{2*scale,17*scale,4*scale},.5*scale}};
        const auto transformed_cones=eclipse_shadow_cones(transformed);
        expect(transformed_cones.has_value(),"transformed cones available");
        point(transformed_cones->umbra.apex_au,{2*scale,23*scale,4*scale},1e-14*scale);
        point(*eclipse_shadow_axis_hit(transformed),{2*scale,16.5*scale,4*scale},1e-14*scale);
        near(transformed_cones->penumbra.sin_half_angle,cones->penumbra.sin_half_angle,1e-16,"cone scale invariance");
    }
    changed=geometry; changed.sun.radius_au=1;
    rejects<std::invalid_argument>([&]{ eclipse_shadow_cones(changed); },"equal radii unsupported cylindrical cone");
    changed.sun.radius_au=.5;
    rejects<std::invalid_argument>([&]{ eclipse_shadow_cones(changed); },"larger occluder cone unsupported");
    changed=geometry; changed.receiver.center_au={10,0,0};
    rejects<std::invalid_argument>([&]{ eclipse_shadow_cones(changed); },"intersecting receiver rejected");
    changed=geometry; changed.receiver.radius_au=0;
    rejects<std::invalid_argument>([&]{ eclipse_shadow_axis_hit(changed); },"zero sphere rejected");
    changed=geometry; changed.sun.center_au.x=std::numeric_limits<double>::quiet_NaN();
    rejects<std::invalid_argument>([&]{ eclipse_shadow_axis_hit(changed); },"nonfinite center rejected");
    changed=geometry; changed.sun.center_au.x=-std::numeric_limits<double>::max();
    changed.occluder.center_au.x=std::numeric_limits<double>::max();
    rejects<std::out_of_range>([&]{ eclipse_shadow_cones(changed); },"overflowed distance rejected");
    changed={{{0,0,0},std::nextafter(1.,2.)},{{1e300,0,0},1},{{1.5e300,0,0},.5}};
    rejects<std::out_of_range>([&]{ eclipse_shadow_cones(changed); },"unrepresentable cone apex rejected");
    for (double invalid : {-1.,std::numeric_limits<double>::infinity()}) {
        changed=geometry; changed.receiver.radius_au=invalid;
        rejects<std::invalid_argument>([&]{ eclipse_shadow_cones(changed); },"invalid sphere radius");
    }
}
void colour() {
    const auto total=eclipse_shadow_multiplier(1,{.3,0,0});
    near(total[0],.3,1e-16,"red lunar total shadow"); near(total[1],0,0,"green lunar total shadow");
    near(total[2],0,0,"blue lunar total shadow");
    const auto half=eclipse_shadow_multiplier(.5,{.3,0,0});
    near(half[0],.65,1e-16,"red partial shadow"); near(half[1],.5,0,"green partial shadow");
    near(half[2],.5,0,"blue partial shadow");
    for (double channel : eclipse_shadow_multiplier(0,{.3,0,0})) near(channel,1,0,"no shadow");
    for (double invalid : {-1.,1.01,std::numeric_limits<double>::quiet_NaN(),std::numeric_limits<double>::infinity()}) {
        rejects<std::invalid_argument>([=]{ eclipse_shadow_multiplier(invalid,{0,0,0}); },"invalid fraction");
        rejects<std::invalid_argument>([=]{ eclipse_shadow_multiplier(1,{0,invalid,0}); },"invalid shadow color");
    }
}
} // namespace
int main() {
    try { disks(); surface(); cones_and_axis(); colour(); std::cout << "eclipse: " << checks << " checks PASS\n"; }
    catch (const std::exception& error) { std::cerr << "eclipse: " << error.what() << '\n'; return 1; }
}
