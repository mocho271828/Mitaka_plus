#include "terrain_snapshot.hpp"
#include "terrain_source_lease.hpp"

#include <cmath>
#include <system_error>

namespace mitaka::gui {
namespace {
bool finite(Vec3 p) { return std::isfinite(p.x)&&std::isfinite(p.y)&&std::isfinite(p.z); }
bool equal(Vec3 a,Vec3 b) { return a.x==b.x&&a.y==b.y&&a.z==b.z; }
double dot(Vec3 a,Vec3 b) { return a.x*b.x+a.y*b.y+a.z*b.z; }
Vec3 cross(Vec3 a,Vec3 b) { return {a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x}; }
bool equal(const BodyOrientation& a,const BodyOrientation& b) {
    return equal(a.x_axis,b.x_axis)&&equal(a.y_axis,b.y_axis)&&equal(a.north_axis,b.north_axis);
}
bool equal(const SolarCamera& a,const SolarCamera& b) {
    if (!equal(a.target,b.target)||a.yaw_deg!=b.yaw_deg||a.pitch_deg!=b.pitch_deg||
        a.roll_deg!=b.roll_deg||a.frame_is_orbit!=b.frame_is_orbit||
        a.distance_au!=b.distance_au||a.vertical_fov_deg!=b.vertical_fov_deg||bool(a.frame)!=bool(b.frame)||
        bool(a.precise_target)!=bool(b.precise_target)) return false;
    if (a.precise_target && (!equal(a.precise_target->anchor_pc,b.precise_target->anchor_pc)||
        !equal(a.precise_target->offset_au,b.precise_target->offset_au))) return false;
    return !a.frame || (equal(a.frame->outward,b.frame->outward)&&equal(a.frame->right,b.frame->right)&&
        equal(a.frame->up,b.frame->up));
}
bool inside(const std::filesystem::path& path,const std::filesystem::path& root) {
    auto p=path.begin();
    for (auto r=root.begin();r!=root.end();++r,++p) if(p==path.end()||*p!=*r) return false;
    return p!=path.end();
}
void check_cancelled(const std::function<bool()>& cancelled) {
    if (cancelled&&cancelled()) throw TerrainSurfaceCancelled();
}
} // namespace

std::filesystem::path terrain_source_relative_path(TerrainBody body) {
    switch(body) {
    case TerrainBody::earth:return "earth_topo/earth_topo.dat";
    case TerrainBody::moon:return "moon_topo.dat";
    case TerrainBody::mercury:return "mercury_topo.dat";
    case TerrainBody::mars:return "mars_topo/mars_topo.dat";
    }
    throw std::invalid_argument("unknown terrain body");
}

void validate_terrain_surface_request(const TerrainSurfaceRequest& r) {
    (void)terrain_source_relative_path(r.body);
    if (!r.data_directory.is_absolute() || r.data_directory.native().find('\0')!=std::string::npos ||
        !std::isfinite(r.julian_date)||!finite(r.center_au)||!std::isfinite(r.display_radius_au)||
        r.display_radius_au<=0||!std::isfinite(r.elevation_factor)||r.elevation_factor<0||
        r.width<1||r.height<1||r.width>1024||r.height>1024)
        throw std::invalid_argument("invalid terrain snapshot request");
    (void)solar_camera_basis(r.camera);
    const auto& o=r.orientation;
    for(const auto axis:{o.x_axis,o.y_axis,o.north_axis})
        if(!finite(axis)||std::abs(dot(axis,axis)-1)>1e-8)
            throw std::invalid_argument("terrain snapshot requires unit orientation axes");
    if(std::abs(dot(o.x_axis,o.y_axis))>1e-8||std::abs(dot(o.x_axis,o.north_axis))>1e-8||
       std::abs(dot(o.y_axis,o.north_axis))>1e-8||dot(cross(o.x_axis,o.y_axis),o.north_axis)<1-1e-8)
        throw std::invalid_argument("terrain snapshot requires a right-handed orthogonal orientation");
    const auto& l=r.load_limits;const auto& s=r.surface_limits;
    if(l.max_file_bytes==0||l.max_patches==0||l.max_index_bytes==0||l.max_grid_bytes==0||
       s.frame_bytes==0||s.mesh_bytes==0||s.triangles==0||s.pixel_tests==0||
       std::size_t(r.width)*r.height>s.frame_bytes/sizeof(TerrainSurfaceSample))
        throw std::invalid_argument("invalid terrain snapshot resource limits");
}

bool terrain_surface_request_matches(const TerrainSurfaceRequest& a,const TerrainSurfaceRequest& b) {
    const auto& al=a.load_limits;const auto& bl=b.load_limits;
    const auto& as=a.surface_limits;const auto& bs=b.surface_limits;
    return a.data_directory==b.data_directory&&a.body==b.body&&a.julian_date==b.julian_date&&
        equal(a.center_au,b.center_au)&&equal(a.orientation,b.orientation)&&a.display_radius_au==b.display_radius_au&&
        a.elevation_factor==b.elevation_factor&&a.low_resolution==b.low_resolution&&equal(a.camera,b.camera)&&
        a.width==b.width&&a.height==b.height&&al.max_file_bytes==bl.max_file_bytes&&al.max_patches==bl.max_patches&&
        al.max_index_bytes==bl.max_index_bytes&&al.max_grid_bytes==bl.max_grid_bytes&&
        as.frame_bytes==bs.frame_bytes&&as.mesh_bytes==bs.mesh_bytes&&as.triangles==bs.triangles&&as.pixel_tests==bs.pixel_tests;
}

std::shared_ptr<const TerrainSurfaceSnapshot> prepare_terrain_surface_snapshot(
    const TerrainSurfaceRequest& request,std::uint64_t generation,const std::function<bool()>& cancelled) {
    validate_terrain_surface_request(request);
    check_cancelled(cancelled);
    auto result=std::make_shared<TerrainSurfaceSnapshot>();
    result->generation=generation;result->request=request;
    result->source_path=request.data_directory/terrain_source_relative_path(request.body);
    try {
        result->resolved_data_directory=std::filesystem::canonical(request.data_directory);
        std::error_code error;
        const auto resolved=std::filesystem::canonical(result->source_path,error);
        if(error==std::errc::no_such_file_or_directory) {
            result->status=TerrainSnapshotStatus::unavailable;
            result->diagnostic="terrain source is absent from the selected data directory";
            return result;
        }
        if(error) throw std::filesystem::filesystem_error("terrain source resolution failed",result->source_path,error);
        if(!inside(resolved,result->resolved_data_directory)) {
            result->diagnostic="terrain source resolves outside the selected data directory";
            return result;
        }
        result->source_path=resolved;
        const TerrainSourceLease lease(result->resolved_data_directory,resolved);
        auto source=TerrainFile::open(lease.descriptor_path(),request.load_limits);
        result->source_identity=source.identity();result->source_header=source.header();
        check_cancelled(cancelled);
        result->frame=render_terrain_surface({source,request.center_au,request.orientation,
            request.display_radius_au,request.elevation_factor,request.low_resolution},request.camera,
            request.width,request.height,request.surface_limits,cancelled);
        source.verify_source_unchanged();
        check_cancelled(cancelled);
        result->status=TerrainSnapshotStatus::ready;
    } catch(const TerrainSurfaceCancelled&) { throw;
    } catch(const CatalogError& error) { result->diagnostic=error.what();
    } catch(const std::filesystem::filesystem_error& error) { result->diagnostic=error.what();
    } catch(const std::invalid_argument& error) { result->diagnostic=error.what(); }
    if(result->status!=TerrainSnapshotStatus::ready) result->frame={};
    return result;
}

} // namespace mitaka::gui
