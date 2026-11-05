#import "SolarSceneRenderer.h"
#import "TerrainSurfaceController.h"
#include "surface_navigation.hpp"
#include <cmath>
#include <iostream>
#include <stdexcept>
using namespace mitaka;
using namespace mitaka::gui;

static void require(bool c, const char *message) { if (!c) throw std::runtime_error(message); }
static std::vector<unsigned char> render(const SolarScene &scene) {
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr pixelsWide:81 pixelsHigh:81 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:324 bitsPerPixel:32];
    require(bitmap != nil, "bitmap allocation failed");
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    const auto context = NSGraphicsContext.currentContext.CGContext;
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, 81, 81));
    auto diagnostics = draw_solar_scene(context, scene);
    [NSGraphicsContext restoreGraphicsState];
    require(diagnostics.empty(), "solar scene reported drawing diagnostic");
    return {bitmap.bitmapData, bitmap.bitmapData + 81 * 81 * 4};
}
static void run(std::size_t index, const char *root) {
    SolarBodies bodies{}; SolarOrbits orbits{}; std::vector<Vec3> lunar; PlanetTextures textures;
    const std::array<Body,11> ids{Body::sun,Body::mercury,Body::venus,Body::earth,Body::mars,Body::jupiter,Body::saturn,Body::uranus,Body::neptune,Body::pluto,Body::moon};
    for (std::size_t i=0;i<bodies.size();++i) { bodies[i].id=ids[i]; bodies[i].position_au={1,100+double(i),0}; textures.images[i]=TextureImage{1,1,{200,200,200,255}}; }
    bodies[0].position_au={0,0,0}; bodies[index].position_au={1,0,0};
    SolarCamera camera{{1,0,0},180,0,3*surface_body_info(index).radius_km / astronomical_unit_km};
    std::array<std::shared_ptr<const TerrainSurfaceSnapshot>,11> snapshots{};
    SolarScene scene{bodies,orbits,lunar,camera,&textures,{},NSMakeRect(0,0,81,81),1,false,{},{}};
    scene.physical_navigation=true; scene.planet_display={true,false,false,false}; scene.grid_display.circle_scales=false;
    scene.earth_layers={false,false}; scene.atmosphere.mode=AtmosphereMode::none; scene.eclipse_options={false,false,false,false}; scene.terrain=&snapshots;
    auto baseline=render(scene);
    auto req=solar_terrain_request(scene,index,root); require(bool(req), "terrain request absent");
    TerrainSurfaceController *controller=[TerrainSurfaceController new];
    __block bool done=false; __block std::shared_ptr<const TerrainSurfaceSnapshot> snapshot; __block NSString *failure=nil;
    [controller requestSurface:*req completion:^(std::shared_ptr<const TerrainSurfaceSnapshot> result, NSString *error) { snapshot=std::move(result); failure=[error copy]; done=true; }];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:60];
    while (!done && deadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    require(done, "controller timed out");
    if (failure) throw std::runtime_error(failure.UTF8String);
    require(snapshot && snapshot->status==TerrainSnapshotStatus::ready, snapshot ? snapshot->diagnostic.c_str() : "missing snapshot");
    require(snapshot->frame.mode==TerrainSurfaceMode::terrain, "not terrain mode");
    std::size_t hits=0; for (const auto &v:snapshot->frame.samples) if (std::isfinite(v.distance_au)) ++hits;
    require(hits>0 && snapshot->frame.patches_read>0, "terrain has no real intersections");
    snapshots[index]=snapshot; require(solar_terrain_frame(scene,index)==&snapshot->frame, "scene rejected snapshot");
    auto actual=render(scene); std::size_t changed=0;
    for(std::size_t i=0;i<actual.size();i+=4) if(actual[i]!=baseline[i] || actual[i+1]!=baseline[i+1] || actual[i+2]!=baseline[i+2]) ++changed;
    require(changed>0, "terrain image did not change");
    std::cout << (index==3 ? "Earth" : "Mars") << ": status=ready mode=terrain patches=" << snapshot->frame.patches_read << " hits=" << hits << " differing_pixels=" << changed << " path=" << snapshot->source_path << std::endl;
}
int main(int argc,char **argv) { @autoreleasepool { [NSApplication sharedApplication]; try { require(argc==2,"expected data root"); run(3,argv[1]); run(4,argv[1]); return 0; } catch(const std::exception &e) { std::cerr << e.what() << std::endl; return 1; } } }
