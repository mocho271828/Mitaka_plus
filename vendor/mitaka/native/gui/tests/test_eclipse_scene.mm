#import "SolarSceneRenderer.h"
#include "surface_navigation.hpp"
#include <array>
#include <iostream>
#include <stdexcept>
using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks=0;constexpr std::size_t size=121;using Pixels=std::vector<std::uint8_t>;
void check(bool value,const char* message){++checks;if(!value)throw std::runtime_error(message);}
Pixels render(const SolarScene& scene,std::vector<std::string>* diagnostics=nullptr){
    NSBitmapImageRep* bitmap=[[NSBitmapImageRep alloc]initWithBitmapDataPlanes:nullptr pixelsWide:size pixelsHigh:size
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:size*4 bitsPerPixel:32];
    if(!bitmap)throw std::runtime_error("bitmap allocation failed");[NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext=[NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    const auto context=NSGraphicsContext.currentContext.CGContext;CGContextSetRGBFillColor(context,0,0,0,1);CGContextFillRect(context,CGRectMake(0,0,size,size));
    const auto result=draw_solar_scene(context,scene);if(diagnostics)*diagnostics=result;[NSGraphicsContext restoreGraphicsState];
    return {bitmap.bitmapData,bitmap.bitmapData+bitmap.bytesPerRow*bitmap.pixelsHigh};
}
std::array<unsigned,3> center(const Pixels& pixels){const auto i=(size*(size/2)+size/2)*4;return {pixels[i],pixels[i+1],pixels[i+2]};}
struct Fixture{
    SolarBodies bodies{};SolarOrbits orbits{};std::vector<Vec3> lunar;PlanetTextures textures;
    SolarCamera camera{{1,0,0},180,0,3*radius()};
    SolarScene scene{bodies,orbits,lunar,camera,&textures,{},NSMakeRect(0,0,size,size),1,false,3,{}};
    static double radius(){return surface_body_info(3).radius_km/astronomical_unit_km;}
    Fixture(){const std::array<Body,11> ids{Body::sun,Body::mercury,Body::venus,Body::earth,Body::mars,Body::jupiter,Body::saturn,Body::uranus,Body::neptune,Body::pluto,Body::moon};
        for(std::size_t i=0;i<bodies.size();++i){bodies[i].id=ids[i];bodies[i].position_au={1,100+double(i),0};textures.images[i]=TextureImage{1,1,{200,200,200,255}};}
        bodies[0].position_au={0,0,0};bodies[3].position_au={1,0,0};bodies[10].position_au={.999,0,0};
        scene.grid_display.circle_scales=false;scene.planet_display={true,false,false,false};scene.atmosphere.mode=AtmosphereMode::none;
        scene.earth_layers={false,false};scene.eclipse_options={false,false,false,false};}
    void path(unsigned i,std::size_t body=3){scene.preview_body=i==0?std::optional<std::size_t>(body):std::nullopt;
        scene.earth_moon=i==1;scene.physical_navigation=i==2;scene.surface_body=i==3?std::optional<std::size_t>(body):std::nullopt;}
};
void shadow_paths(){Fixture f;
    for(unsigned path=0;path<4;++path){f.path(path);f.scene.eclipse_options.shadows=false;const auto bright=center(render(f.scene));
        f.scene.eclipse_options.shadows=true;const auto dark=center(render(f.scene));check(bright[0]>150,"day surface not lit");
        check(dark[0]<bright[0]/4,"eclipse absent from rendering path");f.scene.planet_display.visible=false;
        check(center(render(f.scene))[0]==0,"hidden planet retained shadow surface");f.scene.planet_display.visible=true;}
    f.path(0);f.scene.textures=nullptr;f.scene.eclipse_options.shadows=false;const auto fallback=center(render(f.scene));
    f.scene.eclipse_options.shadows=true;check(center(render(f.scene))[0]<fallback[0],"missing texture disabled shadow");
    f.scene.textures=&f.textures;f.bodies[10].position_au={1.001,0,0};f.camera.target={1.001,0,0};
    f.camera.distance_au=3*surface_body_info(10).radius_km/astronomical_unit_km;
    for(unsigned path:{0u,2u,3u}){f.path(path,10);const auto red=center(render(f.scene));check(red[0]>20&&red[1]==0&&red[2]==0,"Moon shadow not red");}
    f.path(0);f.scene.eclipse_options={false,false,false,false};check(draw_solar_scene(nullptr,f.scene).empty(),"null context diagnostics");
    f.scene.eclipse_options.shadows=true;f.bodies[10].position_au=f.bodies[3].position_au;f.camera.target={1,0,0};
    std::vector<std::string> diagnostics;render(f.scene,&diagnostics);check(!diagnostics.empty(),"invalid geometry has no diagnostic");
}
void cone_paths(){Fixture f;
    // 受光球で切られる半影を 121 px でも解像する。製品側の物理半径は広げない。
    f.camera={{.9995,0,0},90,0,.0015};f.path(0);f.scene.preview_body.reset();
    const auto base=render(f.scene);f.scene.eclipse_options.shadow_umbra=true;const auto umbra=render(f.scene);check(umbra!=base,"scene umbra not connected");
    f.scene.eclipse_options.shadow_umbra=false;f.scene.eclipse_options.shadow_penumbra=true;const auto penumbra=render(f.scene);
    check(penumbra!=base&&penumbra!=umbra,"scene penumbra not independent");f.scene.planet_display.visible=false;
    f.scene.eclipse_options.shadow_penumbra=false;const auto hidden=render(f.scene);f.scene.eclipse_options.shadow_penumbra=true;
    check(render(f.scene)==hidden,"hidden planets retained cones");}
}
int main(){@autoreleasepool{try{shadow_paths();cone_paths();std::cout<<"eclipse scene: "<<checks<<" checks PASS\n";return 0;}catch(const std::exception& e){std::cerr<<"FAIL: "<<e.what()<<'\n';return 1;}}}
