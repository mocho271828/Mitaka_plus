#include "atmosphere_renderer.hpp"
#include "terrain_snapshot_test_fixture.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
std::size_t checks=0;
void check(bool value,const char* message) { ++checks;if(!value)throw std::runtime_error(message); }
template<class F> void rejects(F function) {
    try { function(); } catch(const std::invalid_argument&) { ++checks;return; }
    throw std::runtime_error("expected invalid_argument");
}
const TextureImage white{1,1,{200,200,200,255}},black{1,1,{0,0,0,255}};
const TextureImage colors{2,2,{200,0,0,255, 0,200,0,255, 0,0,200,255, 200,200,0,255}};
const BodyOrientation identity{};
const Vec3 center{-1,0,0};
SolarCamera camera(double radius=.001) { return {center,0,0,3*radius}; }
TerrainSurfaceFrame frame(double distance=.0021,Vec3 normal={1,0,0},double u=.25,double v=.25) {
    TerrainSurfaceFrame result;result.mode=TerrainSurfaceMode::terrain;result.width=1;result.height=1;
    result.samples.push_back({distance,normal,u,v});return result;
}
SurfaceSphere sphere(const TextureImage& texture,const TerrainSurfaceFrame* terrain=nullptr) {
    return {texture,center,identity,.001,false,0,nullptr,nullptr,terrain};
}
std::array<unsigned,3> rgb(const TextureImage& image) {
    return {image.rgba[0],image.rgba[1],image.rgba[2]};
}
bool empty(const TextureImage& image) {
    return std::all_of(image.rgba.begin(),image.rgba.end(),[](auto value){return value==0;});
}

void test_geometry_uv_and_lighting() {
    auto terrain=frame();auto body=sphere(colors,&terrain);const auto view=camera();
    SurfaceDepthFrame depth;
    check(rgb(render_surface_scene({body},view,1,1,nullptr,&depth))==std::array<unsigned,3>{200,0,0},
          "terrain uses saved UV instead of deriving UV from slope normal");
    check(depth.distances_au==std::vector<double>{.0021},"negative terrain depth replaces nearer datum");
    terrain.samples[0].normal_local={0,1,0};
    check(rgb(render_surface_scene({body},view,1,1))==std::array<unsigned,3>{60,0,0},
          "slope changes light but not texture location");
    terrain.samples[0].normal_local={1,0,0};body.longitude_offset_turns=.5;
    check(rgb(render_surface_scene({body},view,1,1))==std::array<unsigned,3>{0,200,0},"longitude offset applies to terrain UV");
    body.longitude_offset_turns=0;terrain.samples[0].u=2.25;terrain.samples[0].v=.75;
    check(rgb(render_surface_scene({body},view,1,1))==std::array<unsigned,3>{0,0,200},"unwrapped U and north-to-south V");
    body.orientation={{0,1,0},{-1,0,0},{0,0,1}};
    check(rgb(render_surface_scene({body},view,1,1))==std::array<unsigned,3>{0,0,60},"local slope rotates into inertial lighting");
    body.orientation=identity;
    terrain.samples[0].distance_au=INFINITY;
    check(empty(render_surface_scene({body},view,1,1,nullptr,&depth)) && std::isinf(depth.distances_au[0]),
          "uncovered terrain is not filled by datum sphere");
    terrain.mode=TerrainSurfaceMode::sphere;terrain.samples.clear();
    check(render_surface_scene({body},view,1,1).rgba==render_surface_scene({sphere(colors)},view,1,1).rgba,
          "sphere LOD preserves previous sphere rendering");
    terrain.mode=TerrainSurfaceMode::none;
    check(empty(render_surface_scene({body},view,1,1)),"none LOD has no opaque surface");

    terrain=frame();
    auto nearer=sphere(white);nearer.center.x+=.001;nearer.radius_au=.0002;
    const auto front=render_surface_scene({body,nearer},view,1,1,nullptr,&depth);
    check(rgb(front)==std::array<unsigned,3>{200,200,200},"near sphere occludes terrain");
    check(front.rgba==render_surface_scene({nearer,body},view,1,1).rgba,"near sphere order independence");
    check(depth.distances_au[0]<terrain.samples[0].distance_au,"shared depth takes nearest sphere");
    auto behind=nearer;behind.center.x-=.003;
    const auto back=render_surface_scene({body,behind},view,1,1);
    check(rgb(back)==std::array<unsigned,3>{200,0,0} &&
          back.rgba==render_surface_scene({behind,body},view,1,1).rgba,"terrain occludes farther sphere in either order");
}

void test_real_negative_mesh() {
    terrain_test::Temporary temporary;const auto path=temporary.root/"terrain.dat";
    const auto bytes=terrain_test::bytes(-100);
    { std::ofstream out(path,std::ios::binary);out.write(bytes.data(),bytes.size()); }
    auto source=TerrainFile::open(path);
    const auto view=camera();
    const auto terrain=render_terrain_surface({source,center,identity,.001},view,33,33);
    check(terrain.mode==TerrainSurfaceMode::terrain,"fixture selects terrain LOD");
    auto body=sphere(white,&terrain);SurfaceDepthFrame depth;
    const auto rendered=render_surface_scene({body},view,33,33,nullptr,&depth);
    const std::size_t middle=16*33+16;
    const auto datum=sphere_hit_distance(view,center,.001,16.5,16.5,33,33);
    check(datum && depth.distances_au[middle]>*datum,"real negative-height raster is behind datum");
    check(depth.distances_au[middle]==terrain.samples[middle].distance_au && rendered.rgba[middle*4+3]==255,
          "real mesh depth is retained by textured opaque pass");
    for(std::size_t i=0;i<depth.distances_au.size();++i) {
        check(depth.distances_au[i]==terrain.samples[i].distance_au,"no datum pixels overwrite mesh or empty patch");
        check(rendered.rgba[4*i+3]==(std::isfinite(depth.distances_au[i])?255:0),"opaque coverage matches final depth");
    }
}

void test_earth_layers() {
    auto terrain=frame();auto body=sphere(black,&terrain);auto view=camera();
    const EarthLayerAssets assets{white,colors,{}};
    EarthLayerBinding layers{assets,{true,true},{{.003,0,0},{1,0,0},.001,1}};
    body.earth_layers=&layers;
    TextureImage clouds;SurfaceDepthFrame depth;
    (void)render_surface_scene({body},view,1,1,&clouds,&depth);
    check(!empty(clouds),"cloud shell appears above negative terrain");
    check(depth.distances_au[0]==.0021,"cloud pass does not write depth");
    terrain.samples[0].distance_au=.0019;
    (void)render_surface_scene({body},view,1,1,&clouds,&depth);
    check(empty(clouds) && depth.distances_au[0]==.0019,"positive terrain above cloud shell occludes cloud");
    view.distance_au=.002;layers.view.earth_to_camera_ecliptic_au={.002,0,0};
    terrain.samples[0].distance_au=.0011;terrain.samples[0].normal_local={-1,0,0};
    layers.options.clouds=false;layers.options.city_lights=false;
    const auto night=render_surface_scene({body},view,1,1);
    check(night.rgba[0]>0 && night.rgba[1]==0 && night.rgba[2]==0,"night map uses saved UV on dark slope");
    terrain.samples[0].u=.75;
    const auto green=render_surface_scene({body},view,1,1);
    check(green.rgba[0]==0 && green.rgba[1]>0 && green.rgba[2]==0,"night map location independent of normal");
    terrain.samples[0].normal_local={1,0,0};
    check(rgb(render_surface_scene({body},view,1,1))==std::array<unsigned,3>{0,0,0},"night layer absent on sunlit slope");
}

void test_atmosphere_and_depth_validation() {
    constexpr double radius=4e-5;
    auto view=camera(radius);view.distance_au=4*radius;
    auto terrain=frame(3*radius-radius*.004);auto body=sphere(white,&terrain);body.radius_au=radius;
    auto params=earth_atmosphere_parameters();params.incident_intensity=1;
    const std::vector<AtmosphereLayer> layers{{0,params,nullptr}};
    const AtmosphereDisplayOptions options{AtmosphereMode::single,1};
    SurfaceDepthFrame depth;
    (void)render_surface_scene({body},view,1,1,nullptr,&depth);
    const auto supplied=render_atmosphere_scene({body},layers,view,1,1,options,&depth);
    const auto computed=render_atmosphere_scene({body},layers,view,1,1,options);
    check(supplied.rgba==computed.rgba,"atmosphere shared and independently computed terrain depth agree");
    const auto core=atmosphere_single_scattering(params,{{4*params.ground_radius_m,0,0},{-1,0,0},{1,0,0},
                                                       terrain.samples[0].distance_au*params.ground_radius_m/radius});
    const auto byte=[](double value){return std::lround(std::clamp(value,0.0,1.0)*255);};
    check(supplied.rgba[0]==byte(core.r)&&supplied.rgba[1]==byte(core.g)&&supplied.rgba[2]==byte(core.b),
          "terrain endpoint reaches physical core scattering unchanged");
    auto datum=body;datum.terrain=nullptr;
    check(supplied.rgba!=render_atmosphere_scene({datum},layers,view,1,1,options).rgba,
          "positive terrain shortens atmosphere compared with datum");
    terrain.samples[0].distance_au=2*radius;
    (void)render_surface_scene({body},view,1,1,nullptr,&depth);
    check(empty(render_atmosphere_scene({body},layers,view,1,1,options,&depth)),"opaque terrain before atmosphere hides emission");
    terrain.samples[0].distance_au=3.001*radius;
    (void)render_surface_scene({body},view,1,1,nullptr,&depth);
    const auto negative=render_atmosphere_scene({body},layers,view,1,1,options,&depth);
    const auto negative_core=atmosphere_single_scattering(params,{{4*params.ground_radius_m,0,0},{-1,0,0},{1,0,0},
        terrain.samples[0].distance_au*params.ground_radius_m/radius});
    check(negative.rgba[0]==byte(negative_core.r)&&negative.rgba[1]==byte(negative_core.g)&&
          negative.rgba[2]==byte(negative_core.b),"negative terrain keeps core reference-ground cutoff");
    auto changed=view;changed.yaw_deg=.1;
    rejects([&]{render_atmosphere_scene({body},layers,changed,1,1,options,&depth);});
    rejects([&]{render_atmosphere_scene({body},layers,view,2,1,options,&depth);});
    auto moved=body;moved.center.y=.00001;
    rejects([&]{render_atmosphere_scene({moved},layers,view,1,1,options,&depth);});
    auto copied=terrain;auto replaced=body;replaced.terrain=&copied;
    rejects([&]{render_atmosphere_scene({replaced},layers,view,1,1,options,&depth);});
    for(double invalid:{0.0,-1.0,-std::numeric_limits<double>::infinity(),std::numeric_limits<double>::quiet_NaN()}) {
        auto bad=depth;bad.distances_au[0]=invalid;
        rejects([&]{render_atmosphere_scene({body},layers,view,1,1,options,&bad);});
    }
}

void test_replaced_datum_interior() {
    auto terrain=frame(.0001);auto body=sphere(white,&terrain);auto view=camera();
    view.distance_au=.0009;
    check(!empty(render_surface_scene({body},view,1,1)),"terrain inside datum is not rejected as a sphere");
    terrain.mode=TerrainSurfaceMode::none;terrain.samples.clear();
    check(empty(render_surface_scene({body},view,1,1)),"none frame inside datum has no opaque surface");

    const auto params=earth_atmosphere_parameters();
    constexpr double radius=4e-5;
    auto remote=sphere(white);remote.radius_au=radius;view=camera(radius);view.distance_au=4*radius;
    const auto axes=solar_camera_basis(view);
    body.center={view.target.x+axes.outward.x*view.distance_au,0,0};
    body.radius_au=radius;
    const std::vector<AtmosphereLayer> layers{{0,params,nullptr}};
    const auto reference=render_atmosphere_scene({remote},layers,view,1,1);
    check(!empty(reference),"remote atmosphere is visible in regression fixture");
    check(render_atmosphere_scene({remote,body},layers,view,1,1).rgba==reference.rgba,
          "none datum around camera does not hide unrelated atmosphere");
    terrain=frame(INFINITY);
    check(render_atmosphere_scene({remote,body},layers,view,1,1).rgba==reference.rgba,
          "terrain datum around camera does not hide unrelated atmosphere");
    check(render_atmosphere_scene({remote,body},{{0,params,nullptr},{1,params,nullptr}},view,1,1).rgba==reference.rgba,
          "below-ground layer is skipped without hiding another atmosphere");
    SurfaceDepthFrame depth;
    (void)render_surface_scene({remote,body},view,1,1,nullptr,&depth);
    check(render_atmosphere_scene({remote,body},layers,view,1,1,{},&depth).rgba==reference.rgba,
          "shared depth preserves replaced-datum interior behavior");
}

void test_atomicity_and_eclipse() {
    auto terrain=frame();auto body=sphere(white,&terrain);const auto view=camera();
    TextureImage additive{1,1,{1,2,3,4}};SurfaceDepthFrame depth;depth.width=19;
    auto reject_frame=[&]{ rejects([&]{render_surface_scene({sphere(white),body},view,1,1,&additive,&depth);});
        check(additive.rgba==std::vector<std::uint8_t>({1,2,3,4})&&depth.width==19,"failed render retains both output objects"); };
    for(double value:{0.0,-1.0,-std::numeric_limits<double>::infinity(),std::numeric_limits<double>::quiet_NaN()}) { terrain.samples[0].distance_au=value;reject_frame(); }
    terrain=frame();terrain.samples[0].normal_local={0,0,0};reject_frame();
    terrain=frame();terrain.samples[0].u=NAN;reject_frame();
    terrain=frame();terrain.samples[0].v=1.01;reject_frame();
    terrain=frame();terrain.width=2;reject_frame();
    terrain=frame();terrain.samples.clear();reject_frame();
    terrain=frame();terrain.mode=static_cast<TerrainSurfaceMode>(999);reject_frame();

    // datumが影円錐外でも、借用した地形の実交点が影の中なら減光する。
    const EclipseSurfaceBinding eclipse({{0,0,0},2},{{14,8,0},.5},{{{10,0,0},1}},{true,false,false,false});
    check(!eclipse.active(),"eclipse fixture excludes datum sphere");
    SolarCamera eclipse_camera{{14,0,0},180,0,3};
    auto shadow_terrain=frame(2.5,{-1,0,0});
    SurfaceSphere shadow{white,{14,8,0},identity,.5,false,0,nullptr,&eclipse,&shadow_terrain};
    check(rgb(render_surface_scene({shadow},eclipse_camera,1,1))==std::array<unsigned,3>{0,0,0},
          "terrain uses actual point eclipse even when datum binding is inactive");
    shadow.eclipse=nullptr;
    check(render_surface_scene({shadow},eclipse_camera,1,1).rgba[0]>0,"same terrain without shadow remains lit");
}
} // namespace
int main() { try {
    test_geometry_uv_and_lighting();test_real_negative_mesh();test_earth_layers();
    test_atmosphere_and_depth_validation();test_replaced_datum_interior();test_atomicity_and_eclipse();
    std::cout<<"terrain compositing: "<<checks<<" checks PASS\n";return 0;
} catch(const std::exception& error) { std::cerr<<"terrain compositing: "<<error.what()<<'\n';return 1; } }
