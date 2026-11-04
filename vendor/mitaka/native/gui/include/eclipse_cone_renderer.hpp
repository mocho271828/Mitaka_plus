#pragma once

#include "eclipse_display.hpp"
#include "local_image.hpp"
#include "solar_camera.hpp"
#include <optional>
#include <vector>

namespace mitaka::gui {
// 下流半影は母線が受光球の内側を通ると太陽距離の平面で終端を置き換える。
// 厳密な球交点による切断ではなく、負の切断距離も原式のまま保持する。
struct EclipseConeReceiverClip {
    Vec3 center_from_apex_au;
    double radius_au, replacement_axial_au;
};
// 旧 Plus の有限表示面。連続円錐面を使い、旧 GL の 64 分割による画素一致は
// 主張しない。本影と太陽側半影は .5→0、下流半影は両端 .5。
struct EclipseDisplayCone {
    Vec3 apex_au, axis_unit;
    double radial_slope, near_axial_au, far_axial_au;
    double near_alpha, far_alpha;
    std::optional<EclipseConeReceiverClip> receiver_clip;
};
// eclipse_display_cones が返した円錐と、axis に直交する単位 radial を受ける。
// 下流半影の原版母線ごとの再切断を返す。その他は far_axial_au を返す。
double eclipse_cone_end_axial(const EclipseDisplayCone& cone, Vec3 radial_unit);
// 受光球による本影の切断は原版の「太陽距離による平面」の式を保つ。
// 太陽半径 <= 遮蔽半径、接触球、不正な接線根号・非有限値は拒否する。
std::vector<EclipseDisplayCone> eclipse_display_cones(const EclipseGeometry& geometry,
    EclipseDisplayOptions options);
// 同じ物理 AU / カメラの最近不透明交点までを描く straight RGBA。
// points の模式拡大半径は使わない。全 opaque 球の外側の視点が必要で、
// 球内視点では透明画像になる。寸法 1..1024、非有限入力は拒否する。
TextureImage render_eclipse_cones(const EclipseGeometry& geometry, EclipseDisplayOptions options,
    const std::vector<EclipseSphere>& opaque, const SolarCamera& camera,
    std::size_t width, std::size_t height);
} // namespace mitaka::gui
