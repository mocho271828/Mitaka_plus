#include "terrain_surface.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
bool finite(Vec3 p) { return std::isfinite(p.x) && std::isfinite(p.y) && std::isfinite(p.z); }
double dot(Vec3 a, Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
Vec3 scale(Vec3 p, double f) { return {p.x*f,p.y*f,p.z*f}; }
Vec3 add(Vec3 a, Vec3 b) { return {a.x+b.x,a.y+b.y,a.z+b.z}; }
Vec3 subtract(Vec3 a, Vec3 b) { return {a.x-b.x,a.y-b.y,a.z-b.z}; }
Vec3 cross(Vec3 a, Vec3 b) { return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x}; }
Vec3 world(Vec3 p, const BodyOrientation& o) {
    return add(add(scale(o.x_axis,p.x),scale(o.y_axis,p.y)),scale(o.north_axis,p.z));
}
Vec3 local(Vec3 p, const BodyOrientation& o) {
    return {dot(p,o.x_axis),dot(p,o.y_axis),dot(p,o.north_axis)};
}
void validate(const TerrainSurfaceBinding& b, int width, int height) {
    if (width<1 || height<1 || width>1024 || height>1024 || !finite(b.center_au) ||
        !std::isfinite(b.display_radius_au) || b.display_radius_au<=0 ||
        !std::isfinite(b.elevation_factor) || b.elevation_factor<0)
        throw std::invalid_argument("invalid terrain surface geometry or viewport");
    const auto& o=b.orientation;
    for (const auto axis:{o.x_axis,o.y_axis,o.north_axis})
        if (!finite(axis) || std::abs(dot(axis,axis)-1)>1e-8)
            throw std::invalid_argument("terrain orientation must contain unit vectors");
    if (std::abs(dot(o.x_axis,o.y_axis))>1e-8 || std::abs(dot(o.x_axis,o.north_axis))>1e-8 ||
        std::abs(dot(o.y_axis,o.north_axis))>1e-8 || dot(cross(o.x_axis,o.y_axis),o.north_axis)<1-1e-8)
        throw std::invalid_argument("terrain orientation must be right-handed and orthogonal");
}
// 全int16標高と球面区画を包む球を用い、画錐外が確実な場合だけ省く。
// 球は凸なので、各頂点を結ぶ三角形もこの境界の内側にある。
bool outside_view(const TerrainPatch& patch, const TerrainHeader& header, double elevation_factor,
    Vec3 target, double distance, const BodyOrientation& orientation,
    const std::array<Vec3,4>& planes, const std::array<double,4>& slopes) {
    constexpr double radians=3.14159265358979323846/180;
    // メッシュの経度補間と剰余計算との丸め差が拡大する範囲は判定しない。
    if (patch.longitude_begin_deg < -360 || patch.longitude_end_deg > 360) return false;
    const double factor=double(header.elevation_unit_m)/header.radius_m*elevation_factor;
    const double radial_margin=32768*factor;
    // この場合は不正な頂点の検出も従来どおりメッシュ生成に任せる。
    if (!std::isfinite(radial_margin) || radial_margin>=1) return false;
    const double lon=std::remainder((double(patch.longitude_begin_deg)+patch.longitude_end_deg)*.5,360.0)*radians;
    const double lat=(double(patch.latitude_begin_deg)+patch.latitude_end_deg)*.5*radians;
    const double angle=std::min(3.14159265358979323846,
        (double(patch.longitude_end_deg)-patch.longitude_begin_deg+
         double(patch.latitude_begin_deg)-patch.latitude_end_deg)*.5*radians);
    const Vec3 center{std::cos(lat)*std::cos(lon),std::cos(lat)*std::sin(lon),std::sin(lat)};
    const double radius=radial_margin+2*(1+radial_margin)*std::sin(angle*.5);
    const auto relative=subtract(world(center,orientation),target);
    if (!finite(relative) || !std::isfinite(radius)) return false;
    for (std::size_t i=0;i<planes.size();++i) {
        const auto plane=planes[i];
        const double signed_distance=dot(relative,plane)+slopes[i]*distance;
        // orientation は単位直交の検査に 1e-8 の許容差がある。
        const double bound=radius*(1+3e-8)*std::hypot(plane.x,plane.y,plane.z);
        // 丸め誤差の境界は捨てない。
        const double tolerance=1e-12*(1+std::hypot(relative.x,relative.y,relative.z)+bound);
        if (std::isfinite(signed_distance) && std::isfinite(bound) && signed_distance < -bound-tolerance) return true;
    }
    return false;
}
struct ScreenPoint { double x,y; };
struct Vertex { Vec3 position,normal; double u,v; std::optional<SolarProjection> screen; };
ScreenPoint projected(const Vertex& v) { return {v.screen->x,v.screen->y}; }
ScreenPoint cut(const Vertex& a, const Vertex& b, const SolarCamera& camera,
    int width, int height) {
    const auto segment=project_solar_segment(a.position,b.position,camera,width,height);
    if (!segment) throw std::invalid_argument("terrain near clipping exceeds finite projection range");
    const auto p=(*segment)[a.screen?1:0];
    return {p.x,p.y};
}
double edge(const ScreenPoint& a, const ScreenPoint& b, double x, double y) {
    return (b.x-a.x)*(y-a.y)-(b.y-a.y)*(x-a.x);
}
void raster(const std::array<ScreenPoint,3>& t, const std::array<Vertex,3>& original, const SolarCamera& camera,
    const SolarCameraBasis& axes, const TerrainSurfaceLimits& limits, TerrainSurfaceFrame& frame) {
    const double area=edge(t[0],t[1],t[2].x,t[2].y);
    if (!std::isfinite(area)) throw std::invalid_argument("terrain projected triangle exceeds finite range");
    if (area==0) return;
    const double left=std::max(0.0,std::ceil(std::min({t[0].x,t[1].x,t[2].x})-.5));
    const double right=std::min(double(frame.width-1),std::floor(std::max({t[0].x,t[1].x,t[2].x})-.5));
    const double top=std::max(0.0,std::ceil(std::min({t[0].y,t[1].y,t[2].y})-.5));
    const double bottom=std::min(double(frame.height-1),std::floor(std::max({t[0].y,t[1].y,t[2].y})-.5));
    if (left>right || top>bottom) return;
    const auto tests=std::size_t(right-left+1)*std::size_t(bottom-top+1);
    if (frame.pixel_tests>limits.pixel_tests || tests>limits.pixel_tests-frame.pixel_tests)
        throw std::invalid_argument("terrain pixel test limit exceeded");
    frame.pixel_tests+=tests;
    const auto ab=subtract(original[1].position,original[0].position);
    const auto ac=subtract(original[2].position,original[0].position);
    const auto plane=cross(ab,ac);
    const double plane_square=dot(plane,plane);
    if (!std::isfinite(plane_square)) throw std::invalid_argument("terrain face exceeds finite range");
    if (plane_square==0) return;
    const auto eye=add(camera.target,scale(axes.outward,camera.distance_au));
    const double numerator=dot(plane,subtract(original[0].position,eye));
    for (int y=int(top);y<=int(bottom);++y) for (int x=int(left);x<=int(right);++x) {
        const double a=edge(t[1],t[2],x+.5,y+.5)/area;
        const double b=edge(t[2],t[0],x+.5,y+.5)/area;
        const double c=edge(t[0],t[1],x+.5,y+.5)/area;
        if (a<0 || b<0 || c<0) continue;
        // nearで巨大な投影座標から属性を逆算すると桁落ちするため、元の面と視線で補間する。
        const auto ray=solar_camera_ray(camera,x+.5,y+.5,frame.width,frame.height);
        const double distance=numerator/dot(plane,ray);
        if (!std::isfinite(distance) || distance<=0)
            throw std::invalid_argument("terrain sample depth exceeds finite positive range");
        auto& output=frame.samples[std::size_t(y)*frame.width+x];
        if (distance>=output.distance_au) continue;
        const auto q=subtract(add(eye,scale(ray,distance)),original[0].position);
        const double wb=dot(cross(q,ac),plane)/plane_square;
        const double wc=dot(cross(ab,q),plane)/plane_square,wa=1-wb-wc;
        const auto normal=add(add(scale(original[0].normal,wa),scale(original[1].normal,wb)),scale(original[2].normal,wc));
        const double length=std::hypot(normal.x,normal.y,normal.z);
        if (!finite(normal) || !std::isfinite(length) || length==0)
            throw std::invalid_argument("terrain interpolated normal is degenerate");
        const double u=wa*original[0].u+wb*original[1].u+wc*original[2].u;
        const double v=wa*original[0].v+wb*original[1].v+wc*original[2].v;
        if (!std::isfinite(u) || !std::isfinite(v))
            throw std::invalid_argument("terrain texture coordinate exceeds finite range");
        output={distance,scale(normal,1/length),u,v};
    }
}
ScreenPoint screen_cut(const ScreenPoint& a, const ScreenPoint& b, int axis, double bound) {
    const double av=axis==0?a.x:a.y, bv=axis==0?b.x:b.y;
    const double t=(bound-av)/(bv-av), s=1-t;
    return {axis==0?bound:s*a.x+t*b.x,axis==1?bound:s*a.y+t*b.y};
}
void triangle(const std::array<Vertex,3>& input, const SolarCamera& camera,
    const SolarCameraBasis& axes, const TerrainSurfaceLimits& limits, TerrainSurfaceFrame& frame) {
    std::array<ScreenPoint,8> polygon{};
    std::size_t count=0;
    for (std::size_t i=0;i<3;++i) {
        const auto& a=input[i]; const auto& b=input[(i+1)%3];
        if (a.screen) polygon[count++]=projected(a);
        if (bool(a.screen)!=bool(b.screen)) polygon[count++]=cut(a,b,camera,frame.width,frame.height);
    }
    // nearで巨大になる投影をviewportで切り、辺関数の桁落ちと無駄な画素走査を抑える。
    for(int side=0;side<4 && count>0;++side) {
        std::array<ScreenPoint,8> clipped{};
        std::size_t next=0;
        const int axis=side/2;
        const double bound=side%2==0?0:double(axis==0?frame.width:frame.height);
        const auto inside=[&](const ScreenPoint& v) {
            const double coordinate=axis==0?v.x:v.y;
            return side%2==0?coordinate>=bound:coordinate<=bound;
        };
        for(std::size_t i=0;i<count;++i) {
            const auto& a=polygon[i]; const auto& b=polygon[(i+1)%count];
            if(inside(a)) clipped[next++]=a;
            if(inside(a)!=inside(b)) clipped[next++]=screen_cut(a,b,axis,bound);
        }
        polygon=clipped;count=next;
    }
    for (std::size_t i=1;i+1<count;++i) raster({polygon[0],polygon[i],polygon[i+1]},input,camera,axes,limits,frame);
}
} // namespace

TerrainSurfaceFrame render_terrain_surface(const TerrainSurfaceBinding& binding,
    const SolarCamera& camera, int width, int height, const TerrainSurfaceLimits& limits,
    const std::function<bool()>& cancelled) {
    const auto check_cancelled=[&] { if (cancelled && cancelled()) throw TerrainSurfaceCancelled(); };
    check_cancelled();
    validate(binding,width,height);
    const auto axes=solar_camera_basis(camera);
    // 大きい世界原点を各頂点に加えてから引く精度損失を避ける。
    auto relative_camera=camera;
    relative_camera.target=subtract(camera.target,binding.center_au);
    const auto eye=add(relative_camera.target,scale(axes.outward,camera.distance_au));
    const auto local_eye=scale(local(eye,binding.orientation),1/binding.display_radius_au);
    TerrainSurfaceFrame result;
    result.width=width; result.height=height; result.mode=terrain_surface_mode(local_eye);
    binding.source.verify_source_unchanged();
    if (result.mode!=TerrainSurfaceMode::terrain) return result;
    const auto count=std::size_t(width)*std::size_t(height);
    if (count>limits.frame_bytes/sizeof(TerrainSurfaceSample))
        throw std::invalid_argument("terrain frame memory limit exceeded");
    result.samples.resize(count);
    // 投影と同じ視野角係数を使用。camera frame の丸めを仮定しない。
    const double horizontal=solar_camera_tangent_half_fov*width/height;
    const double vertical=solar_camera_tangent_half_fov;
    const auto forward=scale(axes.outward,-1);
    const std::array<Vec3,4> planes{
        add(axes.right,scale(forward,horizontal)),
        add(scale(axes.right,-1),scale(forward,horizontal)),
        add(axes.up,scale(forward,vertical)),
        add(scale(axes.up,-1),scale(forward,vertical))};
    const std::array<double,4> slopes{horizontal,horizontal,vertical,vertical};
    for (std::size_t p=0;p<binding.source.patches().size();++p) {
        check_cancelled();
        if (outside_view(binding.source.patches()[p],binding.source.header(),binding.elevation_factor,scale(relative_camera.target,1/binding.display_radius_au),
            camera.distance_au/binding.display_radius_au,binding.orientation,planes,slopes)) continue;
        const auto level=terrain_level_index(binding.source.patches()[p],local_eye,binding.low_resolution);
        const auto mesh=make_terrain_patch_mesh(binding.source,p,level,binding.elevation_factor,limits.mesh_bytes);
        ++result.patches_read;
        if (result.triangles_visited>limits.triangles || mesh.triangle_count()>limits.triangles-result.triangles_visited)
            throw std::invalid_argument("terrain triangle limit exceeded");
        result.triangles_visited+=mesh.triangle_count();
        // 投影結果は隣接する三角形で共有する。所有中のmeshと合わせて同じ上限に収める。
        const auto vertex_count=mesh.vertices().size();
        const bool cache_projection=vertex_count<=limits.mesh_bytes/(sizeof(TerrainVertex)+sizeof(Vertex));
        const auto project_vertex=[&](const TerrainVertex& v) {
            const auto position=world(scale(v.position,binding.display_radius_au),binding.orientation);
            if (!finite(position)) throw std::invalid_argument("terrain world position exceeds finite range");
            return Vertex{position,v.normal,v.u,v.v,project_solar(position,relative_camera,width,height)};
        };
        std::vector<Vertex> projected_vertices;
        if (cache_projection) {
            projected_vertices.reserve(vertex_count);
            for (std::size_t i=0;i<vertex_count;++i) {
                if (i%256==0) check_cancelled();
                projected_vertices.push_back(project_vertex(mesh.vertices()[i]));
            }
        }
        for (std::size_t t=0;t<mesh.triangle_count();++t) {
            if (t%256==0) check_cancelled();
            const auto indices=mesh.triangle(t);
            std::array<Vertex,3> input{};
            for (std::size_t i=0;i<3;++i)
                input[i]=cache_projection?projected_vertices[indices[i]]:project_vertex(mesh.vertices()[indices[i]]);
            triangle(input,relative_camera,axes,limits,result);
        }
    }
    binding.source.verify_source_unchanged();
    check_cancelled();
    return result;
}

} // namespace mitaka::gui
