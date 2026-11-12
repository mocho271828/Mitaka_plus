#include "terrain_surface.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <type_traits>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
int checks=0;
void expect(bool condition,const char* label) {
    ++checks; if (!condition) throw std::runtime_error(label);
}
void near(double a,double b,double tolerance,const char* label) {
    if (!(std::isfinite(a) && std::isfinite(b) && std::abs(a-b)<=tolerance))
        std::cerr<<label<<": actual="<<a<<" expected="<<b<<" difference="<<a-b<<'\n';
    expect(std::isfinite(a) && std::isfinite(b) && std::abs(a-b)<=tolerance,label);
}
template<class Exception=std::invalid_argument,class F> void rejects(F f,const char* label) {
    try { f(); } catch (const Exception&) { ++checks; return; }
    throw std::runtime_error(label);
}
template<class T> void append(std::string& bytes,T value) {
    using Bits=std::conditional_t<sizeof(T)==2,std::uint16_t,std::uint32_t>;
    Bits bits; std::memcpy(&bits,&value,sizeof(bits));
    for (std::size_t i=0;i<sizeof(bits);++i) bytes+=char((bits>>(8*i))&255);
}
struct Patch { float lon0=-30,lon1=30,lat0=30,lat1=-30; int levels=1; };
std::string fixture(const std::vector<Patch>& patches,int height,bool slope=false,int coarse_bias=0) {
    std::string bytes;
    append(bytes,1.0f); append(bytes,1000.0f);
    append(bytes,std::int32_t(patches.size())); append(bytes,std::int32_t(1));
    for (const auto& p:patches) {
        append(bytes,p.lon0);append(bytes,p.lon1);append(bytes,p.lat0);append(bytes,p.lat1);
        append(bytes,std::int32_t(p.levels-1));
        for (int level=0;level<p.levels;++level) {
            const int n=4<<level;
            append(bytes,std::int32_t(-123)); append(bytes,std::int32_t(n)); append(bytes,std::int32_t(n));
            for (int y=-1;y<=n+1;++y) for (int x=-1;x<=n+1;++x)
                append(bytes,std::int16_t(height+(slope?3*x-2*y:0)+(level==0?coarse_bias:0)));
        }
    }
    return bytes;
}
struct Temporary {
    std::filesystem::path dir=std::filesystem::temp_directory_path()/
        ("mitaka-terrain-surface-"+std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Temporary() { if (!std::filesystem::create_directory(dir)) throw std::runtime_error("temp directory"); }
    ~Temporary() { std::error_code ignored; std::filesystem::remove_all(dir,ignored); }
    std::filesystem::path write(const char* name,const std::string& bytes) {
        const auto p=dir/name; std::ofstream out(p,std::ios::binary); out.write(bytes.data(),bytes.size());
        if (!out) throw std::runtime_error("fixture write"); return p;
    }
};
Vec3 sub(Vec3 a,Vec3 b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
Vec3 mul(Vec3 a,double s) { return {a.x*s,a.y*s,a.z*s}; }
Vec3 cross(Vec3 a,Vec3 b) { return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x}; }
double dot(Vec3 a,Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
Vec3 direction(double lon,double lat) {
    const double r=std::acos(-1.0)/180;
    return {std::cos(lat*r)*std::cos(lon*r),std::cos(lat*r)*std::sin(lon*r),std::sin(lat*r)};
}
SolarCamera camera(double distance=.003) {
    SolarCamera result; result.distance_au=distance; result.yaw_deg=0; result.pitch_deg=0; return result;
}
double triangle_hit(Vec3 eye,Vec3 ray,Vec3 a,Vec3 b,Vec3 c) {
    // 画面の辺関数とは独立したMöller–Trumbore交点。backfaceは同じく両面扱い。
    const auto ab=sub(b,a),ac=sub(c,a),p=cross(ray,ac);
    const double determinant=dot(ab,p);
    if (std::abs(determinant)<1e-24) return INFINITY;
    const auto origin=sub(eye,a),q=cross(origin,ab);
    const double u=dot(origin,p)/determinant,v=dot(ray,q)/determinant;
    if (u<-1e-12 || v<-1e-12 || u+v>1+1e-12) return INFINITY;
    const double t=dot(ac,q)/determinant;
    return t>0?t:INFINITY;
}
void mesh_tests(Temporary& temp) {
    auto source=TerrainFile::open(temp.write("mesh.dat",fixture({{}},-100,true)));
    const auto mesh=make_terrain_patch_mesh(source,0,0,2);
    expect(mesh.columns()==4 && mesh.rows()==4 && mesh.vertices().size()==25,"mesh dimensions");
    expect(mesh.triangle_count()==32 && mesh.triangle(0)==std::array<std::size_t,3>{0,5,1} &&
        mesh.triangle(1)==std::array<std::size_t,3>{1,5,6},"original strip diagonals and winding");
    rejects<std::out_of_range>([&]{mesh.triangle(32);},"triangle ordinal bound");
    for (int y=0;y<=4;++y) for (int x=0;x<=4;++x) {
        const auto& v=mesh.vertices()[std::size_t(y)*5+x];
        const double radius=1+2.0*(-100+3*x-2*y)/1000;
        const auto n=direction(-30+15*x,30-15*y);
        near(v.position.x,radius*n.x,2e-15,"data radius normalized x");
        near(v.position.y,radius*n.y,2e-15,"data radius normalized y");
        near(v.position.z,radius*n.z,2e-15,"data radius normalized z");
        near(std::hypot(v.normal.x,v.normal.y,v.normal.z),1,2e-15,"halo unit normal");
        expect(dot(v.normal,n)>.95,"halo normal outward");
        const auto point=[&](int xx,int yy) {
            return mul(direction(-30+15*xx,30-15*yy),1+2.0*(-100+3*xx-2*yy)/1000);
        };
        const auto normal=cross(sub(point(x,y+1),point(x,y-1)),sub(point(x+1,y),point(x-1,y)));
        const double length=std::hypot(normal.x,normal.y,normal.z);
        near(v.normal.x,normal.x/length,2e-15,"independent halo normal x");
        near(v.normal.y,normal.y/length,2e-15,"independent halo normal y");
        near(v.normal.z,normal.z/length,2e-15,"independent halo normal z");
        near(v.u,(-30+15*x)/360.0,1e-15,"unwrapped longitude UV");
        near(v.v,.5-(30-15*y)/180.0,1e-15,"north-top UV");
    }
    const auto zero=make_terrain_patch_mesh(source,0,0,0);
    for (const auto& v:zero.vertices()) near(std::hypot(v.position.x,v.position.y,v.position.z),1,2e-15,"factor zero datum vertices");
    rejects([&]{make_terrain_patch_mesh(source,0,0,-1);},"negative amplification");
    rejects([&]{make_terrain_patch_mesh(source,0,0,INFINITY);},"infinite amplification");
    rejects([&]{make_terrain_patch_mesh(source,0,0,1,1);},"mesh memory bound");
    rejects([&]{make_terrain_patch_mesh(source,0,0,20);},"nonpositive elevation radius");
    auto poles=TerrainFile::open(temp.write("poles.dat",fixture({{350,370,90,75,1},{-10,10,-75,-90,1}},0)));
    for (std::size_t p=0;p<2;++p) {
        const auto pole=make_terrain_patch_mesh(poles,p,0);
        const auto start=p==0?0:20;
        for (std::size_t x=0;x<5;++x) {
            const auto& v=pole.vertices()[start+x];
            near(v.normal.z,p==0?1:-1,1e-15,"pole radial normals");
        }
    }
    const auto seam=make_terrain_patch_mesh(poles,0,0);
    expect(seam.vertices().front().u<1 && seam.vertices()[4].u>1,"UV seam remains unwrapped");
    expect(terrain_surface_mode({1,0,0})==TerrainSurfaceMode::terrain,"datum camera boundary");
    expect(terrain_surface_mode({.9,0,0})==TerrainSurfaceMode::terrain,"inside camera boundary");
    expect(terrain_surface_mode({0,0,0})==TerrainSurfaceMode::none,"center camera boundary");
    expect(terrain_surface_mode({2,0,0})==TerrainSurfaceMode::terrain,"near terrain selection");
    expect(terrain_surface_mode({10,0,0})==TerrainSurfaceMode::sphere,"far six-degree selection");
    rejects([&]{terrain_surface_mode({NAN,0,0});},"nonfinite eye");
    auto patch=source.patches()[0]; patch.maximum_level_index=9;
    const double diameter=2*std::acos(-1.0)/180*60;
    const double limit=std::ldexp(.13*std::acos(-1.0)/180,5);
    const Vec3 lower{1+diameter/limit*1.00001,0,0},upper{1+diameter/limit*.99999,0,0};
    expect(terrain_level_index(patch,lower)==4 && terrain_level_index(patch,upper)==5,"LOD strict threshold");
    expect(terrain_level_index(patch,upper,true)==4,"low-resolution one ordinal reduction");
    expect(terrain_level_index(patch,{1e9,0,0},true)==0,"LOD floor zero");
}
void rendering_tests(Temporary& temp) {
    auto source=TerrainFile::open(temp.write("surface.dat",fixture({{}},-100)));
    TerrainSurfaceBinding binding{source,{0,0,0},{},.001};
    const auto view=camera();
    const auto frame=render_terrain_surface(binding,view,65,65);
    expect(frame.mode==TerrainSurfaceMode::terrain && frame.samples.size()==4225,"terrain frame shape");
    expect(frame.patches_read==1 && frame.triangles_visited==32,"bounded mesh streaming statistics");
    const auto& center=frame.samples[32*65+32];
    near(center.distance_au,.0021,2e-15,"negative elevation exact mesh depth");
    expect(center.distance_au>.002,"datum sphere must not obscure negative terrain");
    near(center.u,0,1e-15,"center longitude"); near(center.v,.5,1e-15,"center latitude");
    const auto mesh=make_terrain_patch_mesh(source,0,0);
    int covered=0;
    for (int y=0;y<65;++y) for (int x=0;x<65;++x) {
        const auto ray=solar_camera_ray(view,x+.5,y+.5,65,65);
        double expected=INFINITY;
        for (std::size_t t=0;t<mesh.triangle_count();++t) {
            const auto id=mesh.triangle(t);
            expected=std::min(expected,triangle_hit({.003,0,0},ray,mul(mesh.vertices()[id[0]].position,.001),
                mul(mesh.vertices()[id[1]].position,.001),mul(mesh.vertices()[id[2]].position,.001)));
        }
        const auto& sample=frame.samples[y*65+x];
        expect(std::isfinite(sample.distance_au)==std::isfinite(expected),"independent triangle oracle coverage");
        if (std::isfinite(expected)) {
            ++covered; near(sample.distance_au,expected,2e-14,"independent ray triangle depth");
            near(std::hypot(sample.normal_local.x,sample.normal_local.y,sample.normal_local.z),1,2e-15,"interpolated normal normalized");
        }
    }
    expect(covered>100,"nonempty negative terrain");
    for (double fov : {10., 90.}) {
        auto adjusted=view; adjusted.vertical_fov_deg=fov;
        const auto rendered=render_terrain_surface(binding,adjusted,33,33);
        for (int y=0;y<33;++y) for (int x=0;x<33;++x) {
            const auto ray=solar_camera_ray(adjusted,x+.5,y+.5,33,33);
            double expected=INFINITY;
            for (std::size_t t=0;t<mesh.triangle_count();++t) {
                const auto id=mesh.triangle(t);
                expected=std::min(expected,triangle_hit({.003,0,0},ray,mul(mesh.vertices()[id[0]].position,.001),
                    mul(mesh.vertices()[id[1]].position,.001),mul(mesh.vertices()[id[2]].position,.001)));
            }
            const auto depth=rendered.samples[y*33+x].distance_au;
            expect(std::isfinite(depth)==std::isfinite(expected),"FOV terrain oracle coverage");
            if (std::isfinite(expected)) near(depth,expected,2e-14,"FOV terrain oracle depth");
        }
    }

    auto displaced=view; displaced.target={123,-3,5}; binding.center_au=displaced.target;
    const auto translated=render_terrain_surface(binding,displaced,65,65);
    near(translated.samples[32*65+32].distance_au,center.distance_au,1e-15,"large world translation invariant");
    binding.center_au={0,0,0}; binding.display_radius_au=.002;
    const auto doubled=render_terrain_surface(binding,camera(.006),65,65);
    near(doubled.samples[32*65+32].distance_au,2*center.distance_au,2e-15,"display scale independent data radius");
    expect(source.header().radius_m==1000,"data radius immutable");
    binding.display_radius_au=.001;
    binding.orientation={{0,1,0},{-1,0,0},{0,0,1}};
    auto rotated_camera=view; rotated_camera.yaw_deg=90;
    const auto rotated=render_terrain_surface(binding,rotated_camera,65,65);
    near(rotated.samples[32*65+32].distance_au,center.distance_au,2e-15,"body orientation rotates position only");
    binding.orientation={};
    expect(render_terrain_surface(binding,camera(.01),8,8).mode==TerrainSurfaceMode::sphere,"far explicit sphere mode");
    const auto inside=render_terrain_surface(binding,camera(.00095),65,65);
    expect(inside.mode==TerrainSurfaceMode::terrain,"inside datum terrain remains visible");
    near(inside.samples[32*65+32].distance_au,.00005,2e-15,"inside datum negative terrain depth");
    TerrainSurfaceFrame unchanged=frame;
    for (int kind=0;kind<4;++kind) {
        TerrainSurfaceLimits limits;
        if(kind==0) limits.frame_bytes=1;
        if(kind==1) limits.mesh_bytes=1;
        if(kind==2) limits.triangles=1;
        if(kind==3) limits.pixel_tests=1;
        rejects([&]{unchanged=render_terrain_surface(binding,view,65,65,limits);},"resource budget rejects atomically");
        near(unchanged.samples[32*65+32].distance_au,center.distance_au,0,"failed frame assignment preserves previous output");
    }
    TerrainSurfaceLimits projected_limit;
    // 投影頂点の余裕がない場合は、従来の逐次投影で同じframeを生成する。
    projected_limit.mesh_bytes=25*sizeof(TerrainVertex)+3*7*sizeof(Vec3);
    const auto streamed=render_terrain_surface(binding,view,65,65,projected_limit);
    for(std::size_t i=0;i<frame.samples.size();++i) {
        const auto& a=frame.samples[i];const auto& b=streamed.samples[i];
        expect(a.distance_au==b.distance_au && a.normal_local.x==b.normal_local.x &&
            a.normal_local.y==b.normal_local.y && a.normal_local.z==b.normal_local.z && a.u==b.u && a.v==b.v,
            "cached and streamed projection are identical");
    }
    int cancellation_checks=0;
    rejects<TerrainSurfaceCancelled>([&]{render_terrain_surface(binding,view,65,65,{},[&]{
        return ++cancellation_checks==3;
    });},"vertex projection observes cancellation");
    auto dense_source=TerrainFile::open(temp.write("dense.dat",fixture({{-30,30,30,-30,4}},-100)));
    cancellation_checks=0;
    rejects<TerrainSurfaceCancelled>([&]{render_terrain_surface({dense_source,{0,0,0},{},.001},view,65,65,{},[&]{
        return ++cancellation_checks==4;
    });},"long vertex projection observes cancellation before triangles");
    rejects([&]{render_terrain_surface(binding,view,1025,1);},"viewport upper bound");
    rejects([&]{render_terrain_surface(binding,view,0,1);},"viewport empty bound");
    binding.display_radius_au=0; rejects([&]{render_terrain_surface(binding,view,8,8);},"nonpositive display radius");
    binding.display_radius_au=NAN; rejects([&]{render_terrain_surface(binding,view,8,8);},"nan display radius");
    binding.display_radius_au=.001; binding.orientation.y_axis={0,-1,0};
    rejects([&]{render_terrain_surface(binding,view,8,8);},"left-handed orientation");
    binding.orientation={};
    temp.write("surface.dat",fixture({{}},200));
    rejects<CatalogError>([&]{render_terrain_surface(binding,view,8,8);},"source replacement detected before publish");
}
void interpolated_attributes_test(Temporary& temp) {
    auto source=TerrainFile::open(temp.write("slope.dat",fixture({{}},-100,true)));
    const auto view=camera();
    const auto frame=render_terrain_surface({source,{0,0,0},{},.001},view,53,53);
    const auto mesh=make_terrain_patch_mesh(source,0,0);
    std::size_t covered=0;
    for(int y=0;y<53;++y) for(int x=0;x<53;++x) {
        const auto ray=solar_camera_ray(view,x+.5,y+.5,53,53);
        double nearest=INFINITY;
        std::array<std::size_t,3> nearest_ids{};
        for(std::size_t t=0;t<mesh.triangle_count();++t) {
            const auto ids=mesh.triangle(t);
            const auto distance=triangle_hit({.003,0,0},ray,mul(mesh.vertices()[ids[0]].position,.001),
                mul(mesh.vertices()[ids[1]].position,.001),mul(mesh.vertices()[ids[2]].position,.001));
            if(distance<nearest) { nearest=distance; nearest_ids=ids; }
        }
        const auto& sample=frame.samples[std::size_t(y)*53+x];
        expect(std::isfinite(sample.distance_au)==std::isfinite(nearest),"sloped mesh independent coverage");
        if(!std::isfinite(nearest)) continue;
        ++covered;
        near(sample.distance_au,nearest,2e-14,"sloped mesh independent depth");
        const auto& a=mesh.vertices()[nearest_ids[0]];
        const auto& b=mesh.vertices()[nearest_ids[1]];
        const auto& c=mesh.vertices()[nearest_ids[2]];
        const auto ab=mul(sub(b.position,a.position),.001),ac=mul(sub(c.position,a.position),.001);
        const auto q=sub({.003+nearest*ray.x,nearest*ray.y,nearest*ray.z},mul(a.position,.001));
        const double d00=dot(ab,ab),d01=dot(ab,ac),d11=dot(ac,ac),d20=dot(q,ab),d21=dot(q,ac);
        const double denominator=d00*d11-d01*d01;
        const double wb=(d11*d20-d01*d21)/denominator,wc=(d00*d21-d01*d20)/denominator,wa=1-wb-wc;
        const Vec3 normal{wa*a.normal.x+wb*b.normal.x+wc*c.normal.x,
            wa*a.normal.y+wb*b.normal.y+wc*c.normal.y,wa*a.normal.z+wb*b.normal.z+wc*c.normal.z};
        const double length=std::hypot(normal.x,normal.y,normal.z);
        near(sample.normal_local.x,normal.x/length,1e-11,"sloped mesh independent normal x");
        near(sample.normal_local.y,normal.y/length,1e-11,"sloped mesh independent normal y");
        near(sample.normal_local.z,normal.z/length,1e-11,"sloped mesh independent normal z");
        near(sample.u,wa*a.u+wb*b.u+wc*c.u,1e-11,"sloped mesh independent longitude");
        near(sample.v,wa*a.v+wb*b.v+wc*c.v,1e-11,"sloped mesh independent latitude");
    }
    expect(covered>100,"sloped mesh visible samples");
}
void view_culling_tests(Temporary& temp) {
    const std::vector<Patch> patches{{-1,1,1,-1,1},{89,91,1,-1,1},{-91,-89,1,-1,1}};
    for (const int elevation : {-32768,32767}) {
        auto all=TerrainFile::open(temp.write("cull-all.dat",fixture(patches,elevation)));
        auto front=TerrainFile::open(temp.write("cull-front.dat",fixture({patches[0]},elevation)));
        const TerrainSurfaceBinding a{all,{0,0,0},{},.001,.001};
        const TerrainSurfaceBinding b{front,{0,0,0},{},.001,.001};
        const auto actual=render_terrain_surface(a,camera(.002),65,65);
        const auto expected=render_terrain_surface(b,camera(.002),65,65);
        expect(actual.patches_read==1 && actual.triangles_visited==32,"offscreen patches do not consume triangle budget");
        for (std::size_t i=0;i<actual.samples.size();++i) {
            expect(actual.samples[i].distance_au==expected.samples[i].distance_au,"culling preserves visible extreme elevations");
        }
    }
    for (const auto large : {Patch{100169,100171,1,-1,1},Patch{-100171,-100169,1,-1,1}}) {
        auto unusual=TerrainFile::open(temp.write("cull-large-longitude.dat",fixture({large},0)));
        const auto frame=render_terrain_surface({unusual,{0,0,0},{},.001,0},camera(.002),65,65);
        expect(frame.patches_read==1,"large longitude falls back to full mesh evaluation");
    }
    // 標高が常にゼロなので倍率による形状の差はなく、倍率1は境界を
    // 保証できず選別を無効にする。全patchと描いた結果を全画素で比較する。
    std::vector<Patch> globe;
    for (int lat=90;lat>-90;lat-=15) for (int lon=-180;lon<180;lon+=15)
        globe.push_back({float(lon),float(lon+15),float(lat),float(lat-15),1});
    auto full=TerrainFile::open(temp.write("cull-globe.dat",fixture(globe,0)));
    const double angle=.4, c=std::cos(angle), s=std::sin(angle);
    const BodyOrientation orientation{{c,s,0},{-s,c,0},{0,0,1+1e-9}};
    for (int scenario=0;scenario<3;++scenario) {
        auto view=camera(.0018);
        int width=65, height=65;
        if (scenario==1) { width=80; height=45; view.yaw_deg=37; view.pitch_deg=16; }
        if (scenario==2) {
            width=45; height=80;
            // 既存APIが許す範囲で厳密には直交しないカメラ基底。
            view.frame=SolarCameraBasis{{1,0,0},{1e-9,1,0},{0,0,1}};
        }
        const auto culled=render_terrain_surface({full,{0,0,0},orientation,.001,0},view,width,height);
        const auto unculled=render_terrain_surface({full,{0,0,0},orientation,.001,1},view,width,height);
        expect(culled.patches_read<unculled.patches_read && unculled.patches_read==globe.size(),
            "comparison must exercise culling and full patch traversal");
        std::size_t visible=0;
        for (std::size_t i=0;i<culled.samples.size();++i) {
            const auto& a=culled.samples[i]; const auto& b=unculled.samples[i];
            if (std::isfinite(a.distance_au)) ++visible;
            expect(a.distance_au==b.distance_au && a.normal_local.x==b.normal_local.x &&
                a.normal_local.y==b.normal_local.y && a.normal_local.z==b.normal_local.z && a.u==b.u && a.v==b.v,
                "culling preserves all sample attributes for rotated views and viewport boundaries");
        }
        expect(visible>0,"comparison fixture must cover visible pixels");
    }
    // 経度を二周ずらすと同じメッシュをカリングせず描ける。大きい標高幅の
    // 一部だけを実際に使うパッチで、正負両方の地形を独立に全画素照合する。
    const std::vector<Patch> relief_patches{{-1,1,1,-1,1},{24,26,1,-1,1},{-26,-24,1,-1,1}};
    std::vector<Patch> shifted=relief_patches;
    for (auto& patch:shifted) { patch.lon0+=720; patch.lon1+=720; }
    for (int height:{-1000,1000}) {
        auto raw=TerrainFile::open(temp.write("cull-relief.dat",fixture(relief_patches,height,true)));
        auto control=TerrainFile::open(temp.write("full-relief.dat",fixture(shifted,height,true)));
        auto view=camera(.0015);
        const auto visible=render_terrain_surface({raw,{0,0,0},{},.001,.02},view,81,81);
        const auto all=render_terrain_surface({control,{0,0,0},{},.001,.02},view,81,81);
        expect(visible.patches_read<all.patches_read,"actual relief bounds remove offscreen patches");
        std::size_t hits=0;
        for (std::size_t pixel=0;pixel<all.samples.size();++pixel) {
            const auto& a=visible.samples[pixel];const auto& b=all.samples[pixel];
            expect(a.distance_au==b.distance_au,"real relief bounds preserve drawn depths");
            if (!std::isfinite(a.distance_au)) continue;
            ++hits;
            near(a.u+2,b.u,1e-12,"culling preserves wrapped UV");
            expect(a.normal_local.x==b.normal_local.x && a.normal_local.y==b.normal_local.y &&
                   a.normal_local.z==b.normal_local.z && a.v==b.v,"culling preserves normals and latitude");
        }
        expect(hits>0,"relief fixture must draw terrain");
    }
    // 倍率が大きく安全な正半径を保証できないときは選別しない。
    auto uncertain=TerrainFile::open(temp.write("cull-uncertain.dat",fixture({patches[1]},0)));
    const auto fallback=render_terrain_surface({uncertain,{0,0,0},{},.001,1},camera(),65,65);
    expect(fallback.patches_read==1,"uncertain elevation range must not be culled");
}
void landing_radius_tests(Temporary& temp) {
    auto source=TerrainFile::open(temp.write("landing.dat",fixture({{-30,30,30,-30,3},{25,65,30,-30,2}},200,true,150)));
    for (double factor : {0.0,1.0,2.0}) for (const auto& location : std::array<std::array<double,2>,4>{{
        {{0,0}},{{14,13}},{{26,4}},{{-30,30}}}}) {
        const auto ray=direction(location[0],location[1]);
        double outer=0;
        for(std::size_t p=0;p<source.patches().size();++p) {
            const auto level=terrain_level_index(source.patches()[p],ray);
            const auto mesh=make_terrain_patch_mesh(source,p,level,factor);
            for(std::size_t t=0;t<mesh.triangle_count();++t) {
                const auto ids=mesh.triangle(t);
                const double hit=triangle_hit({0,0,0},ray,mesh.vertices()[ids[0]].position,
                    mesh.vertices()[ids[1]].position,mesh.vertices()[ids[2]].position);
                if(std::isfinite(hit)) outer=std::max(outer,hit);
            }
        }
        const auto actual=terrain_landing_radius_km(source,location[1],location[0],1000,factor);
        expect(bool(actual)==(outer>0),"landing intersection coverage");
        if(actual) near(*actual,1000*outer,1e-7,"landing follows rendered LOD even when unused coarse terrain is higher");
    }
    expect(!terrain_landing_radius_km(source,0,180,1000,1),"outside mesh has no landing surface");
    rejects([&]{terrain_landing_radius_km(source,91,0,1000,1);},"invalid landing latitude");
    rejects([&]{terrain_landing_radius_km(source,0,0,1000,-1);},"invalid landing factor");
    rejects<TerrainSurfaceCancelled>([&]{terrain_landing_radius_km(source,0,0,1000,1,[]{return true;});},"landing cancellation");
    unsigned mesh_polls=0;
    rejects<TerrainSurfaceCancelled>([&]{make_terrain_patch_mesh(source,0,0,1,8*1024*1024,[&]{
        return ++mesh_polls==3;
    });},"mesh generation observes cancellation within its rows");
    unsigned landing_polls=0;
    // 選択した16×16格子の生成後、三角形256個を走査した時点で中断する。
    rejects<TerrainSurfaceCancelled>([&]{terrain_landing_radius_km(source,0,0,1000,1,[&]{
        return ++landing_polls==20;
    });},"landing triangle traversal observes cancellation");
    expect(landing_polls==20,"landing cancellation occurs after mesh generation");
    auto seam=TerrainFile::open(temp.write("landing_seam.dat",fixture({{350,370,90,75,2}},10)));
    const auto a=terrain_landing_radius_km(seam,80,0,1000,1);
    const auto b=terrain_landing_radius_km(seam,80,360,1000,1);
    expect(a&&b,"landing wraps seam");
    near(*a,*b,1e-9,"landing longitude periodic");
}
void real_data(const std::filesystem::path& path) {
    auto source=TerrainFile::open(path);
    const auto begin=std::chrono::steady_clock::now();
    const auto frame=render_terrain_surface({source,{0,0,0},{},.001},camera(),64,64);
    expect(frame.patches_read>0 && frame.patches_read<=source.patches().size(),"visible real-source patches consumed");
    std::size_t covered=0;
    for (const auto& s:frame.samples) if (std::isfinite(s.distance_au)) {
        ++covered; expect(s.distance_au>0,"real positive depth");
        near(std::hypot(s.normal_local.x,s.normal_local.y,s.normal_local.z),1,2e-15,"real normalized normal");
    }
    expect(covered>0,"real mesh nonempty");
    std::cout<<"real source patches="<<frame.patches_read<<" triangles="<<frame.triangles_visited
        <<" pixel_tests="<<frame.pixel_tests<<" grid_bytes="<<source.resident_grid_bytes()
        <<" elapsed_ms="<<std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-begin).count()<<'\n';
}
void clipping_and_order_tests(Temporary& temp) {
    auto source=TerrainFile::open(temp.write("near.dat",fixture({{}},200)));
    auto extreme=camera(); extreme.target={1.7e308,0,0};
    rejects([&]{render_terrain_surface({source,{0,0,0},{},1e308,10},extreme,8,8);},
        "overflowing world vertices must not become an empty successful frame");
    auto view=camera();
    view.frame=SolarCameraBasis{{0,0,1},{1,0,0},{0,1,0}};
    view.target={.0011,0,-.003};
    const auto frame=render_terrain_surface({source,{0,0,0},{},.001},view,31,31);
    TerrainSurfaceLimits projected_limit;
    projected_limit.mesh_bytes=25*sizeof(TerrainVertex)+3*7*sizeof(Vec3);
    const auto streamed=render_terrain_surface({source,{0,0,0},{},.001},view,31,31,projected_limit);
    for(std::size_t i=0;i<frame.samples.size();++i) {
        const auto& a=frame.samples[i];const auto& b=streamed.samples[i];
        expect(a.distance_au==b.distance_au && a.normal_local.x==b.normal_local.x &&
            a.normal_local.y==b.normal_local.y && a.normal_local.z==b.normal_local.z && a.u==b.u && a.v==b.v,
            "near-clipped cached and streamed projections are identical");
    }
    const auto mesh=make_terrain_patch_mesh(source,0,0);
    std::size_t crossing=0,covered=0;
    for (std::size_t t=0;t<mesh.triangle_count();++t) {
        const auto ids=mesh.triangle(t);
        int visible=0;
        for(const auto id:ids) visible+=bool(project_solar(mul(mesh.vertices()[id].position,.001),view,31,31));
        if(visible>0 && visible<3) ++crossing;
    }
    expect(crossing>0,"fixture crosses existing camera near plane");
    for(int y=0;y<31;++y) for(int x=0;x<31;++x) {
        const auto ray=solar_camera_ray(view,x+.5,y+.5,31,31);
        double expected=INFINITY;
        for(std::size_t t=0;t<mesh.triangle_count();++t) {
            const auto ids=mesh.triangle(t);
            expected=std::min(expected,triangle_hit({.0011,0,0},ray,
                mul(mesh.vertices()[ids[0]].position,.001),mul(mesh.vertices()[ids[1]].position,.001),
                mul(mesh.vertices()[ids[2]].position,.001)));
        }
        const auto depth=frame.samples[y*31+x].distance_au;
        expect(std::isfinite(depth)==std::isfinite(expected),"near-clipped independent coverage");
        if(std::isfinite(depth)) { ++covered; near(depth,expected,2e-14,"near-clipped independent depth"); }
    }
    expect(covered>0,"near-clipped visible samples");
    // 重なる別patchは元順で処理し、最短正距離で選ぶ。datum球の深度は与えない。
    const std::vector<Patch> order{{-40,0,30,-30,1},{0,40,30,-30,1},{150,210,30,-30,1}};
    auto first=TerrainFile::open(temp.write("order1.dat",fixture(order,-100)));
    auto reverse=order; std::reverse(reverse.begin(),reverse.end());
    auto second=TerrainFile::open(temp.write("order2.dat",fixture(reverse,-100)));
    const auto a=render_terrain_surface({first,{0,0,0},{},.001},camera(),64,64);
    const auto b=render_terrain_surface({second,{0,0,0},{},.001},camera(),64,64);
    expect(a.patches_read==3 && b.patches_read==3,"all ordered patches consumed");
    for(std::size_t i=0;i<a.samples.size();++i) {
        expect(std::isfinite(a.samples[i].distance_au)==std::isfinite(b.samples[i].distance_au),"patch order independent coverage");
        if(std::isfinite(a.samples[i].distance_au))
            near(a.samples[i].distance_au,b.samples[i].distance_au,2e-15,"patch order independent depth");
    }
}
}
int main(int argc,char** argv) {
    try {
        Temporary temp; landing_radius_tests(temp); mesh_tests(temp); rendering_tests(temp); interpolated_attributes_test(temp); clipping_and_order_tests(temp); view_culling_tests(temp);
        for(int i=1;i<argc;++i) real_data(argv[i]);
        std::cout<<"terrain surface: "<<checks<<" checks passed\n";
        return 0;
    } catch(const std::exception& e) { std::cerr<<"terrain surface: "<<e.what()<<'\n'; return 1; }
}
