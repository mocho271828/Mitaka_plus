#include "eclipse_cone_renderer.hpp"
#include "planet_surface.hpp"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks=0;
void check(bool value,const char* message){++checks;if(!value)throw std::runtime_error(message);}
void close(double actual,double expected,const char* message){check(std::abs(actual-expected)<1e-12,message);}
template<class F>void reject(F fn,const char* message){bool failed=false;try{fn();}catch(const std::invalid_argument&){failed=true;}catch(const std::out_of_range&){failed=true;}check(failed,message);}
EclipseGeometry geometry(){return {{{0,0,0},2},{{10,0,0},1},{{14,0,0},.5}};}
EclipseDisplayOptions options(){return {false,false,true,true};}
std::size_t pixels(const TextureImage& image){std::size_t count=0;for(std::size_t i=3;i<image.rgba.size();i+=4)count+=image.rgba[i]!=0;return count;}
void contract(){
    const auto g=geometry();const auto both=eclipse_display_cones(g,options());
    check(both.size()==3,"independent cone count");const auto& u=both[0];const auto& s=both[1];const auto& p=both[2];
    close(u.apex_au.x,20,"umbra apex");close(u.axis_unit.x,-1,"umbra orientation");
    close(u.far_axial_au,19.6,"umbra rim uses Docc rather than apex distance");
    close(u.radial_slope,std::sqrt(3.84)/19.6,"umbra original rim");
    close(u.near_axial_au,.3*19.6,"umbra radial receiver clipping");
    close(s.apex_au.x,20.0/3,"sunward penumbra apex");close(s.axis_unit.x,-1,"sunward penumbra orientation");
    close(s.far_axial_au,20.0/3-.6,"sunward tangent rim axial length");
    close(s.radial_slope*s.far_axial_au,std::sqrt(4-.36),"sunward tangent rim radius");
    close(s.near_alpha,.5,"sunward apex alpha");close(s.far_alpha,0,"sunward rim alpha");
    close(p.near_alpha,.5,"downstream apex alpha");close(p.far_alpha,.5,"downstream rim alpha");
    check(!s.receiver_clip&&p.receiver_clip.has_value(),"receiver clip attached to wrong fan");
    close(p.apex_au.x,20.0/3,"penumbra apex");close(p.axis_unit.x,1,"penumbra orientation");
    close(p.far_axial_au,40.0/3,"penumbra maximum receiver or umbra extent");
    close(p.radial_slope,3/std::sqrt(91.0),"penumbra original tangent correction");
    for(unsigned mask=0;mask<16;++mask){const EclipseDisplayOptions o{bool(mask&1),bool(mask&2),bool(mask&4),bool(mask&8)};
        check(eclipse_display_cones(g,o).size()==std::size_t(bool(mask&4)+2*bool(mask&8)),"surface flags coupled to cone flags");}
    auto changed=g;changed.receiver.center_au={14,.6,0};
    close(eclipse_display_cones(changed,options())[0].near_axial_au,0,"outside cylinder retains full fan");
    changed.receiver.center_au={30,0,0};
    close(eclipse_display_cones(changed,options())[2].far_axial_au,30-20.0/3,"far receiver extends penumbra");
    close(eclipse_display_cones(changed,options())[0].near_axial_au,0,"beyond apex retains full fan");
    changed.receiver.center_au={-14,0,0};close(eclipse_display_cones(changed,options())[0].near_axial_au,0,"receiver behind Sun retains fan");
    changed=g;changed.occluder.radius_au=2;reject([&]{eclipse_display_cones(changed,options());},"cylinder accepted");
    changed=g;changed.receiver.center_au.x=10;reject([&]{eclipse_display_cones(changed,options());},"receiver overlap accepted");
    changed=g;changed.receiver.radius_au=0;reject([&]{eclipse_display_cones(changed,options());},"zero receiver accepted");
}
void clipping(){
    auto g=geometry();const double slope=3/std::sqrt(91.0),apex=20.0/3;
    g.receiver={{apex+6,6*slope,0},.1};
    const auto cone=eclipse_display_cones(g,options())[2];
    const double cut=std::hypot(apex+6,6*slope)-apex;
    close(eclipse_cone_end_axial(cone,{0,1,0}),cut,"receiver generator not recut by solar radial distance");
    check(cut>6,"recut incorrectly uses receiver axis projection");
    close(eclipse_cone_end_axial(cone,{0,-1,0}),cone.far_axial_au,"missing generator recut");
    auto tangent=cone;tangent.receiver_clip=EclipseConeReceiverClip{{0,0,.5},.5,2};
    close(eclipse_cone_end_axial(tangent,{0,1,0}),cone.far_axial_au,"tangent receiver recut");
    tangent.receiver_clip->radius_au=std::nextafter(.5,1.0);
    close(eclipse_cone_end_axial(tangent,{0,1,0}),2,"inside receiver boundary not recut");
    tangent.receiver_clip->center_from_apex_au={-10,0,0};tangent.receiver_clip->radius_au=100;
    close(eclipse_cone_end_axial(tangent,{0,1,0}),cone.far_axial_au,"backward generator recut");
    // 原式が負距離を返す有効な分離球。絶対値やゼロで置換しない。
    g.receiver={{6.4*std::sqrt(.91),6.4*.3,0},2.1};
    const auto negative=eclipse_display_cones(g,options())[2];
    close(eclipse_cone_end_axial(negative,{0,1,0}),6.4-apex,"negative recut lost");
    SolarCamera camera{{apex-.1,-.99*.1*slope,0},0,0,1,
        SolarCameraBasis{{0,0,1},{1,0,0},{0,1,0}}};
    const EclipseDisplayOptions penumbra{false,false,false,true};
    const auto with_negative=render_eclipse_cones(g,penumbra,{},camera,1,1).rgba[3];
    g.receiver.radius_au=.1;
    check(with_negative>render_eclipse_cones(g,penumbra,{},camera,1,1).rgba[3],"negative recut sheet absent from raster");
    for(Vec3 radial: {Vec3{1,0,0},Vec3{0,2,0},Vec3{0,std::numeric_limits<double>::quiet_NaN(),0}})
        reject([&]{eclipse_cone_end_axial(cone,radial);},"invalid radial accepted");
}
void raster(){
    const auto g=geometry();SolarCamera c{{12,0,0},90,0,20};
    const auto both=render_eclipse_cones(g,options(),{},c,97,97);check(pixels(both)>100,"cone raster empty");
    for(std::size_t i=0;i<both.rgba.size();i+=4){check(both.rgba[i+1]==0&&both.rgba[i+2]==0,"cone is not red");
        check(both.rgba[i+3]<=251,"alpha outside six-intersection source-over range");check(both.rgba[i]==(both.rgba[i+3]?255:0),"not straight alpha");}
    auto o=options();o.shadow_penumbra=false;const auto umbra=render_eclipse_cones(g,o,{},c,97,97);check(pixels(umbra)>0,"umbra invisible");
    o.shadow_umbra=false;o.shadow_penumbra=true;const auto penumbra=render_eclipse_cones(g,o,{},c,97,97);
    check(pixels(penumbra)>pixels(umbra),"cone options not distinct");
    SolarCamera downstream{{12,0,0},90,0,20};
    check(render_eclipse_cones(g,o,{},downstream,1,1).rgba[3]==191,"downstream fan not constant half alpha on each face");
    SolarCamera sunward{{3,0,0},90,0,20};
    check(render_eclipse_cones(g,o,{},sunward,1,1).rgba[3]>0,"sunward penumbra fan absent");
    o={true,true,false,false};check(pixels(render_eclipse_cones(g,o,{},c,97,97))==0,"surface flags create cones");
    check(pixels(render_eclipse_cones(g,options(),{{{12,10,0},5}},c,97,97))<pixels(both),"opaque depth ignored");
    check(pixels(render_eclipse_cones(g,options(),{{{12,20,0},1}},c,97,97))==0,"inside opaque drew cones");
    auto translated=g;for(auto* sphere:{&translated.sun,&translated.occluder,&translated.receiver}){sphere->center_au.x+=100;sphere->center_au.y-=20;sphere->center_au.z+=5;}
    auto translated_camera=c;translated_camera.target={112,-20,5};
    check(render_eclipse_cones(translated,options(),{},translated_camera,97,97).rgba==both.rgba,"translation changed geometry");
    auto away=c;away.target={12,-40,0};check(pixels(render_eclipse_cones(g,options(),{},away,97,97))==0,"behind camera cone drew");
    for(auto dimension:{0u,1025u})reject([&]{render_eclipse_cones(g,options(),{},c,dimension,1);},"invalid viewport accepted");
    c.distance_au=std::numeric_limits<double>::quiet_NaN();reject([&]{render_eclipse_cones(g,options(),{},c,1,1);},"invalid camera accepted");
}
void terrain_depth(){
    const auto g=geometry();const SolarCamera camera{{12,0,0},90,0,20};
    const TextureImage white{1,1,{255,255,255,255}};
    TerrainSurfaceFrame terrain;terrain.width=1;terrain.height=1;terrain.mode=TerrainSurfaceMode::terrain;
    terrain.samples.push_back({30,{0,1,0},.5,.5});
    const SurfaceSphere surface{white,{12,10,0},{},5,false,0,nullptr,nullptr,&terrain};
    const std::vector<EclipseSphere> opaque{{surface.center,surface.radius_au}};
    auto depth=make_surface_depth_frame({surface},camera,1,1,{30});
    const auto fallback=render_eclipse_cones(g,options(),opaque,camera,1,1);
    const auto distant=render_eclipse_cones(g,options(),opaque,camera,1,1,&depth);
    check(pixels(fallback)==0&&pixels(distant)==1,"terrain depth did not replace nearer datum occlusion");
    check(distant.rgba==render_eclipse_cones(g,options(),{},camera,1,1).rgba,"distant terrain changed visible cone");
    depth.distances_au[0]=1;
    check(pixels(render_eclipse_cones(g,options(),opaque,camera,1,1,&depth))==0,"near terrain did not occlude cone");
    depth.distances_au[0]=std::numeric_limits<double>::infinity();
    check(render_eclipse_cones(g,options(),opaque,camera,1,1,&depth).rgba==distant.rgba,"terrain hole refilled by datum sphere");
    terrain.mode=TerrainSurfaceMode::none;terrain.samples.clear();
    auto interior=surface;interior.center={12,20,0};
    const std::vector<EclipseSphere> interior_opaque{{interior.center,interior.radius_au}};
    auto missing=make_surface_depth_frame({interior},camera,1,1,{std::numeric_limits<double>::infinity()});
    check(render_eclipse_cones(g,options(),interior_opaque,camera,1,1,&missing).rgba==distant.rgba,
          "non-opaque terrain datum around camera erased cone");
    terrain.mode=TerrainSurfaceMode::sphere;
    check(pixels(render_eclipse_cones(g,options(),interior_opaque,camera,1,1,&missing))==0,
          "fallback sphere interior contract lost");
    auto changed=camera;changed.yaw_deg+=1;
    reject([&]{render_eclipse_cones(g,options(),opaque,changed,1,1,&depth);},"stale camera accepted");
    reject([&]{render_eclipse_cones(g,options(),opaque,camera,2,1,&depth);},"stale viewport accepted");
    reject([&]{render_eclipse_cones(g,options(),{},camera,1,1,&depth);},"wrong opaque count accepted");
    auto wrong=opaque;wrong[0].center_au.x+=1;
    reject([&]{render_eclipse_cones(g,options(),wrong,camera,1,1,&depth);},"wrong opaque center accepted");
    wrong=opaque;wrong[0].radius_au+=1;
    reject([&]{render_eclipse_cones(g,options(),wrong,camera,1,1,&depth);},"wrong opaque radius accepted");
    for(double value:{0.0,-1.0,-std::numeric_limits<double>::infinity(),std::numeric_limits<double>::quiet_NaN()}) {
        depth.distances_au[0]=value;
        reject([&]{render_eclipse_cones(g,options(),opaque,camera,1,1,&depth);},"invalid shared depth accepted");
    }
}
}
int main(){try{contract();clipping();raster();terrain_depth();std::cout<<"eclipse cone renderer: "<<checks<<" checks PASS\n";return 0;}catch(const std::exception& e){std::cerr<<"FAIL: "<<e.what()<<'\n';return 1;}}
