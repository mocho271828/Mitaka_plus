#import "SolarSceneRenderer.h"
#include "surface_navigation.hpp"
#include <algorithm>
#include <array>
#include <chrono>
#include <cstring>
#include <iostream>
#include <stdexcept>
#include <string_view>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
constexpr std::size_t size = 181;
using Pixels = std::vector<std::uint8_t>;
void check(bool value, const char* message) { ++checks; if (!value) throw std::runtime_error(message); }
TextureImage texture(std::uint8_t value) { return {1, 1, {value, value, value, 255}}; }
Pixels render(const SolarScene& scene, std::size_t dimension=size) {
    NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:dimension pixelsHigh:dimension bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:dimension*4 bitsPerPixel:32];
    if (!bitmap) throw std::runtime_error("bitmap allocation failed");
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    const auto context = NSGraphicsContext.currentContext.CGContext;
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, dimension, dimension));
    draw_solar_scene(context, scene);
    [NSGraphicsContext restoreGraphicsState];
    return {bitmap.bitmapData, bitmap.bitmapData + bitmap.bytesPerRow*bitmap.pixelsHigh};
}
unsigned center(const Pixels& image) { return image[(size*(size/2)+size/2)*4]; }
struct Fixture {
    SolarBodies bodies{};
    SolarOrbits orbits{};
    std::vector<Vec3> lunar;
    SolarCamera camera{{1, 0, 0}, 0, 0, 4*radius()};
    PlanetTextures textures;
    SolarScene scene{bodies, orbits, lunar, camera, &textures, {}, NSMakeRect(0,0,size,size), 1, false, 3, {}};
    static double radius() { return surface_body_info(3).radius_km/astronomical_unit_km; }
    Fixture() {
        const std::array<Body,11> ids{Body::sun,Body::mercury,Body::venus,Body::earth,Body::mars,
            Body::jupiter,Body::saturn,Body::uranus,Body::neptune,Body::pluto,Body::moon};
        for (std::size_t i=0;i<bodies.size();++i) {
            bodies[i].id=ids[i];
            bodies[i].position_au={1,100+static_cast<double>(i),0};
            textures.images[i]=texture(20);
        }
        bodies[3].position_au={1,0,0};
        textures.earth_layers.clouds=texture(100);
        textures.earth_layers.night_lights=texture(100);
        scene.grid_display.circle_scales=false;
        scene.planet_display={true,false,false,false};
        scene.atmosphere.mode=AtmosphereMode::none;
    }
    void path(unsigned index) {
        scene.preview_body=index==0 ? std::optional<std::size_t>(3) : std::nullopt;
        scene.earth_moon=index==1;
        scene.physical_navigation=index==2;
        scene.surface_body=index==3 ? std::optional<std::size_t>(3) : std::nullopt;
    }
};
void layer_paths() {
    Fixture f;
    for (unsigned path=0;path<4;++path) {
        f.path(path);
        f.scene.earth_layers={false,false};
        const auto base=render(f.scene);
        f.scene.earth_layers.city_lights=true;
        const auto night=render(f.scene);
        f.scene.earth_layers.clouds=true;
        const auto both=render(f.scene);
        check(center(night)>center(base)+90,"night toggle not reflected in scene path");
        check(center(both)>center(night),"cloud toggle not reflected in scene path");
        check(center(both)<=center(night)+4,"cloud alpha applied twice or non-additive composite");
        f.scene.earth_layers={true,false};
        check(center(render(f.scene))>center(base),"cloud depends on city-light toggle");
        f.scene.planet_display.visible=false;
        const auto hidden=render(f.scene);
        check(center(hidden)==0,"hidden planet retained surface layers");
        f.scene.planet_display.visible=true;
    }
    f.path(0);
    f.scene.earth_layers={true,true};
    f.textures.images[3].reset();
    const auto fallback=render(f.scene);
    f.scene.earth_layers={false,false};
    check(center(fallback)>center(render(f.scene)),"missing base texture disabled independent Earth layers");
    f.textures.earth_layers={};
    const auto missing=render(f.scene);
    f.scene.earth_layers={true,true};
    check(render(f.scene)==missing,"missing optional layers changed base image");
}
void physical_occlusion() {
    Fixture f;
    for (unsigned path : {1u,2u}) {
        f.path(path);
        f.bodies[10].position_au={1+2*Fixture::radius(),0,0};
        f.scene.earth_layers={false,false};
        const auto base=render(f.scene);
        f.scene.earth_layers={true,true};
        check(center(render(f.scene))==center(base),"Earth layers leaked through foreground Moon");
        check(pick_solar_body(f.scene,NSMakePoint(size/2.0,size/2.0))==10,"Moon depth differs from picking");
        f.bodies[10].position_au={1-2*Fixture::radius(),0,0};
        check(center(render(f.scene))>center(base)+90,"background Moon hid Earth layers");
    }
}
void atmosphere_paths() {
    Fixture f;
    f.scene.earth_layers={false,false};
    // 昼側を見て、single / mapなしmultipleの実際の接続を検証する。
    f.camera.yaw_deg=180;
    for (unsigned path : {1u,2u,3u}) {
        f.path(path);
        f.scene.atmosphere.mode=AtmosphereMode::none;
        const auto base=render(f.scene);
        f.scene.atmosphere.mode=AtmosphereMode::single;
        const auto single=render(f.scene);
        check(single!=base,"physical scene ignored single atmosphere");
        f.scene.atmosphere.mode=AtmosphereMode::multiple;
        check(render(f.scene)==single,"missing emission map did not preserve single scattering");
        f.scene.atmosphere.intensity=0;
        check(render(f.scene)==base,"zero atmosphere intensity emitted light");
        f.scene.atmosphere.intensity=6;
        f.scene.planet_display.visible=false;
        check(center(render(f.scene))==0,"hidden planets retained atmosphere");
        f.scene.planet_display.visible=true;
    }
    f.path(0);
    f.scene.atmosphere.mode=AtmosphereMode::none;
    const auto schematic=render(f.scene);
    f.scene.atmosphere.mode=AtmosphereMode::multiple;
    check(render(f.scene)==schematic,"physical atmosphere leaked into schematic marker");
}
AtmosphereEmissionSource emission() {
    std::string bytes(48+12*6, '\0');
    const auto put=[&](std::size_t offset,auto value) {
        using T=decltype(value);
        std::array<unsigned char,sizeof(T)> raw{};
        std::memcpy(raw.data(),&value,sizeof(T));
        // この fixture は native 対象と同じ little-endian の既知ファイル形式。
        std::copy(raw.begin(),raw.end(),bytes.begin()+offset);
    };
    put(0,std::int32_t(2));put(4,std::int32_t(3));
    put(8,6378000.0);put(16,6442000.0);put(24,8000.0);
    put(32,0.0);put(40,3.141592653589793);
    for(std::size_t i=48;i<bytes.size();i+=4)put(i,1e-8f);
    return parse_atmosphere_emission_map(bytes,"scene-emmap");
}
void atmosphere_assets_and_mars() {
    Fixture f;
    f.scene.earth_layers={false,false};
    f.camera.yaw_deg=180;
    f.textures.atmosphere_emission=emission();
    check(f.textures.atmosphere_emission->map.has_value(),"valid emission fixture");
    for(unsigned path:{1u,2u,3u}) {
        f.path(path);
        f.scene.atmosphere={AtmosphereMode::single,1};
        const auto single=render(f.scene);
        f.scene.atmosphere.mode=AtmosphereMode::multiple;
        check(render(f.scene)!=single,"scene failed to bind valid Earth multiple-scattering map");
    }
    f.bodies[3].position_au={1,100,0};
    f.bodies[4].position_au={1,0,0};
    f.camera.distance_au=4*surface_body_info(4).radius_km/astronomical_unit_km;
    f.path(0);
    f.scene.preview_body=4;
    const auto mars_preview=render(f.scene);
    f.scene.earth_layers={true,true};
    check(render(f.scene)==mars_preview,"Earth additive images affected non-Earth schematic bitmap");
    f.scene.earth_layers={false,false};
    for(unsigned path:{2u,3u}) {
        f.path(path);
        if(path==3)f.scene.surface_body=4;
        f.scene.atmosphere.mode=AtmosphereMode::none;
        const auto base=render(f.scene);
        f.scene.atmosphere.mode=AtmosphereMode::single;
        const auto single=render(f.scene);
        check(single!=base,"physical Mars scene ignored atmosphere");
        f.scene.atmosphere.mode=AtmosphereMode::multiple;
        check(render(f.scene)==single,"Earth multiple map leaked into Mars atmosphere");
    }
}
void benchmark() {
    Fixture f;
    f.path(2);f.camera.yaw_deg=180;
    f.scene.map=NSMakeRect(0,0,800,800);
    f.scene.earth_layers={true,true};
    f.textures.atmosphere_emission=emission();
    for(const auto mode:{AtmosphereMode::none,AtmosphereMode::single,AtmosphereMode::multiple}) {
        f.scene.atmosphere.mode=mode;
        const auto start=std::chrono::steady_clock::now();
        const auto pixels=render(f.scene,800);
        const auto elapsed=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-start).count();
        check(pixels.size()==800*800*4,"benchmark viewport shape");
        std::cout<<"800px physical scene mode="<<static_cast<int>(mode)<<" elapsed_ms="<<elapsed<<'\n';
    }
}
}
int main(int argc,const char* argv[]) {
    @autoreleasepool {
        try {
            layer_paths(); physical_occlusion(); atmosphere_paths(); atmosphere_assets_and_mars();
            if(argc==2 && std::string_view(argv[1])=="--benchmark")benchmark();
            std::cout << "Earth scene tests passed (" << checks << " checks)\n";
        } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
    }
}
