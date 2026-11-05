#pragma once

#include "galaxy_camera.hpp"

namespace mitaka::gui {

// 旧公式 1.3.1 の M_G2E と R_gal=8000 pc を使用。
// 旧 Plus の一致、および raw 点群が native 日心黄道系と一致することは未検証。
// origin は呼び出し側が採用する「太陽原点」の native 座標を明示する。
struct OurGalaxyPlacement {
    NativeEclipticPositionPc sun_origin;
};

NativeEclipticPositionPc our_galaxy_center(OurGalaxyPlacement placement);
NativeEclipticPositionPc our_galaxy_label_position(OurGalaxyPlacement placement);

// 公式 mtk_our_galaxy.cpp の扁平楕円体との視線交差を再現する。
// 銀河やラベルの表示状態・他の天体との選択優先順位は呼び出し側が管理する。
bool hit_our_galaxy(OurGalaxyPlacement placement, GalaxyCameraPc camera,
                    double x, double y, double width, double height);

// 向きと距離を維持して中心を注視する。旧 Plus の移動演出ではない。
GalaxyCameraPc center_our_galaxy(OurGalaxyPlacement placement, GalaxyCameraPc camera);

// 指定半径の球が viewport に入る最小距離で中心を注視する汎用近似。
// visible_radius_pc は呼び出し側が明示する。旧 Plus の全景距離は未確認。
GalaxyCameraPc frame_our_galaxy(OurGalaxyPlacement placement, GalaxyCameraPc camera,
                                double visible_radius_pc, double width, double height);

} // namespace mitaka::gui
