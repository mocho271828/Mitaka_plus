#pragma once

#include "galaxy_spatial_scene.hpp"
#include "renderer_options.hpp"
#include <CoreGraphics/CoreGraphics.h>

namespace mitaka::gui {

constexpr std::size_t maximum_galaxy_bitmap_dimension = 2048;
struct GalaxyRasterSize { std::size_t width, height; };
// 画像解像度だけを制限する。原行件数には上限を設けない。
GalaxyRasterSize galaxy_raster_size(double width_points, double height_points, double backing_scale);
struct GalaxyRenderCounts {
    std::size_t total = 0, hidden = 0, invalid = 0, outside = 0, drawn = 0;
};
enum class GalaxyBackground { opaque, transparent };
class GalaxyBitmap final {
public:
    GalaxyBitmap(CGImageRef image, GalaxyRenderCounts counts);
    ~GalaxyBitmap();
    GalaxyBitmap(const GalaxyBitmap&) = delete;
    GalaxyBitmap& operator=(const GalaxyBitmap&) = delete;
    CGImageRef image() const noexcept { return image_; }
    const GalaxyRenderCounts& counts() const noexcept { return counts_; }
private:
    CGImageRef image_;
    GalaxyRenderCounts counts_;
};
// 独立 CGContext を所有する worker 用描画。cancel 時は部分画像を返さない。
// 色・点半径は native の識別表示であり、原版の形状や測光値を再現しない。
std::shared_ptr<const GalaxyBitmap> render_galaxy_bitmap(
    const GalaxySpatialModel& model, GalaxyCameraPc camera, GalaxySpatialVisibility visibility,
    RendererDisplayOptions quality, double width_points, double height_points, double backing_scale,
    std::function<bool()> should_cancel = {}, GalaxyBackground background = GalaxyBackground::opaque);

} // namespace mitaka::gui
