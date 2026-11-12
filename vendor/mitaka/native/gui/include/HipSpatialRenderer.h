#pragma once

#include "GalaxyRenderer.h"
#include "mitaka/catalog.hpp"

namespace mitaka::gui {

struct HipSpatialPoint {
    std::size_t source_index;
    std::int32_t hip;
    NativeEclipticPositionPc position;
};
struct HipSpatialModel {
    std::vector<HipSpatialPoint> points;
    std::size_t total = 0;
    std::size_t no_positive_parallax = 0;
    std::size_t invalid = 0;
};

struct HipSpatialPick {
    std::size_t index;
    double distance_points;
    double depth_pc;
};

// 画面点の図形寸法を描画と選択で共有する。
constexpr double hip_spatial_point_radius = .75;
constexpr double hip_spatial_preview_size = 1.5;
bool hip_spatial_point_contains(double center_x, double center_y, double x, double y, bool preview) noexcept;
// preview は描画と同じ最大約 6000 件の間引きを使う。
std::size_t hip_spatial_preview_step(std::size_t count) noexcept;
std::optional<HipSpatialPick> pick_hip_spatial_point(
    const HipSpatialModel& model, const GalaxyProjector& projector,
    double x, double y, double radius, bool preview,
    std::function<bool()> should_cancel = {});

// HIP の RA/Dec を J2000 赤道方向とし、正の視差から距離 1000/parallax_mas pc を求める。
// 非有限・負・ゼロ視差は位置を決定できないため表示しない。正視差でも不正座標や
// カメラ表現範囲外は除外する。固有運動、年周視差、測光・原版の表示規則は含まない。
// ソース行は保持し、入力カタログは変更しない。取消時は部分モデルを公開しない。
std::shared_ptr<const HipSpatialModel> build_hip_spatial_model(
    const std::vector<mitaka::HipparcosRecord>& stars, std::function<bool()> should_cancel = {});

// 同一カメラの透明 bitmap。白色・一定サイズは識別用表示であり、恒星光度の再現ではない。
// 取消時は部分 bitmap を公開しない。
std::shared_ptr<const GalaxyBitmap> render_hip_spatial_bitmap(
    const HipSpatialModel& model, GalaxyCameraPc camera, RendererDisplayOptions quality,
    double width_points, double height_points, double backing_scale,
    std::function<bool()> should_cancel = {});

} // namespace mitaka::gui
