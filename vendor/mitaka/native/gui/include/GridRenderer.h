#pragma once

#import <AppKit/AppKit.h>
#include "display_options.hpp"
#include "renderer_options.hpp"
#include "grid_geometry.hpp"
#include "sky_model.hpp"

struct SolarScene;

namespace mitaka::gui {

// 地点・JD 更新時に基底だけを作り、地平格子は表示が必要になった時に生成する。
// J2000 固定格子は全ビューで共有し、カタログや選択状態を保持しない。
class GridGeometryCache {
public:
    GridGeometryCache();
    void set_observation(ObserverSite site, double julian_date);
    const ObservationFrame& frame() const noexcept { return frame_; }
    const CoordinateGrid& grid(GridCoordinateSystem system) const;
private:
    ObserverSite site_{35.68, 139.76};
    double julian_date_ = 2451545;
    ObservationFrame frame_{site_, julian_date_};
    mutable std::optional<CoordinateGrid> horizontal_;
};

// horizontal_projection は視野中心に合わせて球面を回転した地平図投影を使う。
// viewport は SkyViewport の表現（center_ra = 360 - azimuth）に統一する。
void draw_sky_grids(CGContextRef context, NSRect map, SkyViewport viewport,
                    const GridDisplayOptions& options, const GridGeometryCache& cache,
                    bool horizontal_projection, const RendererDisplayOptions& quality);

} // namespace mitaka::gui
