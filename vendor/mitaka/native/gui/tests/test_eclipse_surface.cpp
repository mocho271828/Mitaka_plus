#include "planet_surface.hpp"
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
std::size_t checks=0;
void check(bool condition,const char* message) { ++checks; if(!condition) throw std::runtime_error(message); }
template<class F> void rejects(F function) {
    try { function(); } catch(const std::invalid_argument&) { ++checks; return; }
    throw std::runtime_error("expected invalid_argument");
}
std::array<unsigned,3> pixel(const TextureImage& image,std::size_t x,std::size_t y) {
    const auto p=4*(y*image.width+x); return {image.rgba[p],image.rgba[p+1],image.rgba[p+2]};
}
void run() {
    const EclipseSphere sun{{0,0,0},2},caster{{10,0,0},1},receiver{{14,0,0},.5};
    const EclipseDisplayOptions shadows{true,false,false,false},off{false,false,false,false};
    const EclipseSurfaceBinding dark(sun,receiver,{caster},shadows);
    const EclipseSurfaceBinding red(sun,receiver,{caster},shadows,{.3,0,0});
    const EclipseSurfaceBinding disabled(sun,receiver,{caster},off);
    check(dark.active() && !disabled.active(),"surface flag independence");
    check(dark.effect({-1,0,0},0).multiplier==std::array<double,3>{0,0,0},"central total eclipse");
    const auto red_factor=red.effect({-1,0,0},0).multiplier;
    check(std::abs(red_factor[0]-.3)<1e-15 && red_factor[1]==0 && red_factor[2]==0,"Moon red multiplier");
    check(dark.effect({1,0,0},0).multiplier==std::array<double,3>{1,1,1},"night hemisphere unchanged");
    check(disabled.effect({-1,0,0},0).multiplier==std::array<double,3>{1,1,1},"disabled eclipse identity");
    const TextureImage white{1,1,{200,200,200,255}};
    const SolarCamera camera{{14,0,0},180,0,3};
    const auto base=render_planet_surface(white,camera,receiver.center_au,{},3);
    const auto disk=render_planet_surface(white,camera,receiver.center_au,{},3,false,.5,nullptr,nullptr,&dark);
    check(pixel(base,1,1)==std::array<unsigned,3>{200,200,200},"fixture sunlit center");
    check(pixel(disk,1,1)==std::array<unsigned,3>{0,0,0},"schematic uses physical eclipse geometry");
    const auto lunar=render_surface_view(white,camera,receiver.center_au,{},.5,65,65,.5,nullptr,nullptr,&red);
    check(pixel(lunar,32,32)==std::array<unsigned,3>{60,0,0},"physical surface red eclipse");
    const SurfaceSphere sphere{white,receiver.center_au,{},.5,false,.5,nullptr,&red};
    check(render_surface_scene({sphere},camera,65,65).rgba==lunar.rgba,"scene and single physical surface agree");
    auto bad=sphere; bad.radius_au=.6;
    rejects([&]{render_surface_scene({bad},camera,5,5);});
    auto moved=sphere; moved.center.y=.001;
    rejects([&]{render_surface_scene({moved},camera,5,5);});
    rejects([&]{render_planet_surface(white,camera,receiver.center_au,{},5,true,.5,nullptr,nullptr,&dark);});
    rejects([&]{dark.effect({2,0,0},0);});
    rejects([&]{dark.effect({-1,0,0},-1);});
    rejects([&]{dark.effect({-1,0,0},std::numeric_limits<double>::quiet_NaN());});
    rejects([&]{EclipseSurfaceBinding(sun,receiver,{},shadows);});
    rejects([&]{EclipseSurfaceBinding(sun,receiver,{sun},shadows);});
    const EclipseSurfaceBinding border(sun,{{14,0,0},2.5},{caster},{false,true,false,false});
    bool umbra=false,penumbra=false;
    for(int i=0;i<=1000;++i) {
        const double angle=i*1.5707963267948966/1000;
        const auto effect=border.effect({-std::cos(angle),std::sin(angle),0},.01);
        check(effect.multiplier==std::array<double,3>{1,1,1},"borders must not enable shadows");
        if(effect.border_rgb==std::optional<std::array<double,3>>{{1,.5,0}}) umbra=true;
        if(effect.border_rgb==std::optional<std::array<double,3>>{{1,0,0}}) penumbra=true;
    }
    check(umbra && penumbra,"independent umbra orange and penumbra red boundary");
    const EclipseSurfaceBinding inactive(sun,{{14,8,0},.5},{caster},shadows);
    check(!inactive.active(),"no cone receiver intersection is inactive");
    const EclipseSurfaceBinding duplicate(sun,{{14,1,0},.5},{caster,caster},shadows);
    const EclipseSurfaceBinding single(sun,{{14,1,0},.5},{caster},shadows);
    const double factor=single.effect({-1,0,0},0).multiplier[0];
    check(std::abs(duplicate.effect({-1,0,0},0).multiplier[0]-factor*factor)<1e-14,
          "multiple retained occluders multiply in source order");
}
}
int main() { try {run();std::cout<<"eclipse surface: "<<checks<<" checks PASS\n";return 0;}
catch(const std::exception& error) {std::cerr<<error.what()<<'\n';return 1;} }
