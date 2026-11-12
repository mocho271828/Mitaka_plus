#include "terrain_landing.hpp"
#include "terrain_mesh.hpp"
#include "terrain_source_lease.hpp"
#include "surface_navigation.hpp"

#include <algorithm>

#include <cmath>
#include <system_error>

namespace mitaka::gui {
namespace {
bool inside(const std::filesystem::path& path,const std::filesystem::path& root) {
    auto p=path.begin();
    for (auto r=root.begin();r!=root.end();++r,++p) if(p==path.end()||*p!=*r) return false;
    return p!=path.end();
}
void check_cancelled(const std::function<bool()>& cancelled) {
    if(cancelled && cancelled()) throw TerrainSurfaceCancelled();
}
}
void validate_terrain_landing_request(const TerrainLandingRequest& request) {
    (void)terrain_source_relative_path(request.body);
    const auto& l=request.load_limits;
    if(!request.data_directory.is_absolute() || request.data_directory.native().find('\0')!=std::string::npos ||
       !std::isfinite(request.latitude_deg) || std::abs(request.latitude_deg)>90 ||
       !std::isfinite(request.longitude_deg) || !std::isfinite(request.display_radius_km) ||
       request.display_radius_km<=0 || !std::isfinite(request.elevation_factor) || request.elevation_factor<0 ||
       l.max_file_bytes==0 || l.max_patches==0 || l.max_index_bytes==0 || l.max_grid_bytes==0)
        throw std::invalid_argument("invalid terrain landing request");
}
TerrainLandingResult prepare_terrain_landing(const TerrainLandingRequest& request,
                                            const std::function<bool()>& cancelled) {
    validate_terrain_landing_request(request);
    check_cancelled(cancelled);
    TerrainLandingResult result;
    try {
        const auto root=std::filesystem::canonical(request.data_directory);
        std::error_code error;
        const auto source_path=std::filesystem::canonical(root/terrain_source_relative_path(request.body),error);
        if(error==std::errc::no_such_file_or_directory) {
            result.status=TerrainSnapshotStatus::unavailable;
            result.diagnostic="terrain source is absent from the selected data directory";
            return result;
        }
        if(error) throw std::filesystem::filesystem_error("terrain source resolution failed",root,error);
        if(!inside(source_path,root)) {
            result.diagnostic="terrain source resolves outside the selected data directory";
            return result;
        }
        const TerrainSourceLease lease(root,source_path);
        auto source=TerrainFile::open(lease.descriptor_path(),request.load_limits);
        check_cancelled(cancelled);
        result.radius_km=terrain_landing_radius_km(source,request.latitude_deg,request.longitude_deg,
                                                   request.display_radius_km,request.elevation_factor,cancelled);
        source.verify_source_unchanged();
        check_cancelled(cancelled);
        // 視点が扱えない半径をメインキューへ成功として渡さない。
        if (result.radius_km) {
            SurfaceNavigation navigation;
            navigation.update_terrain_offset(*result.radius_km-request.display_radius_km);
        }
        result.status=TerrainSnapshotStatus::ready;
    } catch(const TerrainSurfaceCancelled&) { throw;
    } catch(const CatalogError& error) { result.diagnostic=error.what();
    } catch(const std::filesystem::filesystem_error& error) { result.diagnostic=error.what();
    } catch(const std::invalid_argument& error) { result.diagnostic=error.what(); }
    return result;
}
} // namespace mitaka::gui
