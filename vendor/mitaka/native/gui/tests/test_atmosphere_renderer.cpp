#include "atmosphere_renderer.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <type_traits>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
int checks=0;
void expect(bool value,const char* label) { ++checks; if(!value) throw std::runtime_error(label); }
template<class Function> void rejects(Function action,const char* label) {
    try { action(); } catch(const std::invalid_argument&) { ++checks;return; }
    throw std::runtime_error(label);
}
bool black(const TextureImage& image) {
    return std::all_of(image.rgba.begin(),image.rgba.end(),[](auto c){return c==0;});
}
template<class Value> void put(std::string& bytes,std::size_t offset,Value value) {
    using Bits=std::conditional_t<sizeof(Value)==4,std::uint32_t,std::uint64_t>;
    Bits bits; std::memcpy(&bits,&value,sizeof(bits));
    for(std::size_t i=0;i<sizeof(bits);++i) bytes[offset+i]=static_cast<char>((bits>>(i*8))&255);
}
AtmosphereEmissionMap emission() {
    std::string bytes(48+12*6,'\0');
    put(bytes,0,std::int32_t(2));put(bytes,4,std::int32_t(3));
    put(bytes,8,6378000.0);put(bytes,16,6442000.0);put(bytes,24,8000.0);
    put(bytes,32,0.0);put(bytes,40,3.141592653589793);
    for(std::size_t i=48;i<bytes.size();i+=4)put(bytes,i,1e-8f);
    return AtmosphereEmissionMap::parse(bytes,"renderer-emmap");
}
void test_rendering() {
    const TextureImage texture{1,1,{255,255,255,255}};
    const BodyOrientation orientation{{1,0,0},{0,1,0},{0,0,1}};
    constexpr double radius=4e-5;
    const SurfaceSphere earth{texture,{1,0,0},orientation,radius};
    SolarCamera camera;camera.target=earth.center;camera.yaw_deg=180;camera.pitch_deg=0;camera.distance_au=4*radius;
    auto parameters=earth_atmosphere_parameters();
    const auto mars=mars_atmosphere_parameters(3396190);
    expect(parameters.outer_radius_m-parameters.ground_radius_m==48000 && parameters.scale_height_m==8000 &&
        parameters.surface_number_density_per_m3==2.69e25,"Earth official parameters");
    expect(mars.outer_radius_m-mars.ground_radius_m==88000 && mars.scale_height_m==11000 &&
        mars.surface_number_density_per_m3==4e23,"Mars official parameters");
    const auto map=emission();
    const std::vector<SurfaceSphere> spheres{earth};
    const std::vector<AtmosphereLayer> layers{{0,parameters,&map}};
    const AtmosphereDisplayOptions single{AtmosphereMode::single,1};
    const AtmosphereDisplayOptions multiple{AtmosphereMode::multiple,1};
    const auto image=render_atmosphere_scene(spheres,layers,camera,65,65,single);
    // 奇数の3倍解像度では各3×3区画の中央が同じ視線。全行を照合して帯の境界も検証する。
    const auto full=render_atmosphere_scene(spheres,layers,camera,195,195,single);
    for (std::size_t y=0;y<65;++y) for (std::size_t x=0;x<65;++x) {
        const auto first=image.rgba.begin()+4*(y*65+x);
        expect(std::equal(first,first+4,full.rgba.begin()+4*((3*y+1)*195+3*x+1)),
            "parallel atmosphere bands match serial rays");
    }
    // 全体の深度検査を通る有限距離でも、画素内のメートル換算で桁あふれし得る。
    auto hugeDepth=make_surface_depth_frame(spheres,camera,195,195,
        std::vector<double>(195*195,std::numeric_limits<double>::max()));
    rejects([&]{render_atmosphere_scene(spheres,layers,camera,195,195,single,&hugeDepth);},
        "parallel worker reports invalid ray distance to caller");
    expect(image.width==65 && image.height==65 && image.rgba.size()==65*65*4,"viewport shape");
    expect(!black(image),"physical daylight atmosphere emits");
    expect(image.rgba[0]==0 && image.rgba[3]==0,"off-sphere empty corner");
    for(std::size_t i=0;i<image.rgba.size();i+=4) {
        const bool rgb=image.rgba[i] || image.rgba[i+1] || image.rgba[i+2];
        expect(image.rgba[i+3]==(rgb?255:0),"additive alpha never dims RGB twice");
    }
    const auto center=render_atmosphere_scene(spheres,layers,camera,1,1,single);
    const auto direction=solar_camera_ray(camera,.5,.5,1,1);
    const auto axes=solar_camera_basis(camera);
    const double metres=parameters.ground_radius_m/radius;
    const auto eye=Vec3{axes.outward.x*camera.distance_au*metres,axes.outward.y*camera.distance_au*metres,
                        axes.outward.z*camera.distance_au*metres};
    parameters.incident_intensity=1;
    const auto hit=sphere_hit_distance(camera,earth.center,radius,.5,.5,1,1);
    expect(hit.has_value(),"center opaque intersection");
    const auto direct=atmosphere_single_scattering(parameters,{eye,direction,{-1,0,0},*hit*metres});
    const auto to_byte=[](double value){return std::lround(std::clamp(value,0.0,1.0)*255);};
    expect(center.rgba[0]==to_byte(direct.r) && center.rgba[1]==to_byte(direct.g) &&
        center.rgba[2]==to_byte(direct.b),"RGB follows physical core ray without alpha weight");
    const auto with_multiple=render_atmosphere_scene(spheres,layers,camera,1,1,multiple);
    expect(with_multiple.rgba[0]>center.rgba[0],"valid local map adds emission");
    expect(render_atmosphere_scene(spheres,{{0,parameters,nullptr}},camera,65,65,multiple).rgba==image.rgba,
        "missing map keeps single scattering");
    expect(black(render_atmosphere_scene(spheres,layers,camera,65,65,{AtmosphereMode::none,1})),"none mode");
    expect(black(render_atmosphere_scene(spheres,layers,camera,65,65,{AtmosphereMode::multiple,0})),"zero intensity");
    expect(black(render_atmosphere_scene(spheres,{},camera,65,65,multiple)),"no bound atmosphere");
    const SurfaceSphere blocker{texture,{1-2*radius,0,0},orientation,.5*radius};
    expect(black(render_atmosphere_scene({earth,blocker},layers,camera,1,1,multiple)),"near opaque body hides atmosphere behind it");
    expect(black(render_atmosphere_scene({blocker,earth},{{1,parameters,&map}},camera,1,1,multiple)),"occlusion independent of array order");
    const SurfaceSphere behind{texture,{1+2*radius,0,0},orientation,.5*radius};
    expect(render_atmosphere_scene({earth,behind},layers,camera,1,1,multiple).rgba==with_multiple.rgba,
        "far opaque body does not hide front emission");
    auto ground=camera;ground.distance_au=radius;
    expect(black(render_atmosphere_scene(spheres,layers,ground,5,5,multiple)),"surface boundary zero");
    ground.distance_au=radius*.9;
    expect(black(render_atmosphere_scene(spheres,layers,ground,5,5,multiple)),"inside solid zero");
    auto backside=camera;backside.yaw_deg=0;
    expect(black(render_atmosphere_scene(spheres,layers,backside,1,1,single)),"night side is shadowed");
    auto shifted=camera;shifted.target.y+=radius*4;
    expect(black(render_atmosphere_scene(spheres,layers,shifted,1,1,single)),"camera ray miss");
    auto scaled_camera=camera;scaled_camera.distance_au*=2;
    auto scaled_earth=earth;scaled_earth.radius_au*=2;
    expect(render_atmosphere_scene({scaled_earth},layers,scaled_camera,65,65,single).rgba==image.rgba,
        "display scale transforms to same physical atmosphere");
    rejects([&]{render_atmosphere_scene(spheres,{{1,parameters}},camera,1,1);},"unknown surface index");
    rejects([&]{render_atmosphere_scene(spheres,{{0,parameters},{0,parameters}},camera,1,1);},"duplicate surface binding");
    rejects([&]{render_atmosphere_scene(spheres,layers,camera,0,1);},"zero viewport");
    rejects([&]{render_atmosphere_scene(spheres,layers,camera,1,1025);},"oversized viewport");
    auto invalid=parameters;invalid.scale_height_m=0;
    rejects([&]{render_atmosphere_scene(spheres,{{0,invalid}},camera,1,1,{AtmosphereMode::none,0});},"invisible invalid layer rejected");
    auto invalid_sphere=earth;invalid_sphere.radius_au=-1;
    rejects([&]{render_atmosphere_scene({invalid_sphere},layers,camera,1,1);},"invalid occluder rejected");
    auto emissive=earth;emissive.emissive=true;
    rejects([&]{render_atmosphere_scene({emissive},layers,camera,1,1);},"emissive atmosphere rejected");
    auto no_sun=earth;no_sun.center={0,0,0};
    rejects([&]{render_atmosphere_scene({no_sun},layers,camera,1,1);},"undefined sunlight rejected");
    for(double value:{-1.0,std::numeric_limits<double>::quiet_NaN(),std::numeric_limits<double>::infinity(),1e300})
        rejects([&]{validate_atmosphere_display({AtmosphereMode::multiple,value});},"invalid display intensity");
    rejects([]{validate_atmosphere_display({static_cast<AtmosphereMode>(3),6});},"invalid display mode");
    rejects([]{mars_atmosphere_parameters(0);},"invalid Mars radius");
}
} // namespace
int main() {
    try { test_rendering();std::cout<<"atmosphere renderer: "<<checks<<" checks passed\n"; }
    catch(const std::exception& error) {std::cerr<<"atmosphere renderer failure: "<<error.what()<<'\n';return 1;}
}
