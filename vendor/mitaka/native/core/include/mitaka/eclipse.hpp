#pragma once

#include "mitaka/astronomy.hpp"
#include <array>
#include <optional>

namespace mitaka {

// 同一時刻・同一直交座標系の位置と半径。native 接続は J2000 黄道 AU を使う。
// kernel は時系変換、暦の取得、天体名からの半径補完を行わない。
struct EclipseSphere { Vec3 center_au; double radius_au; };
struct EclipseGeometry { EclipseSphere sun, occluder, receiver; };

// axis は頂点から円錐が広がる方向。本影は太陽側、半影は太陽と逆側を向く。
struct EclipseCone {
    Vec3 apex_au;
    Vec3 axis_unit;
    double sin_half_angle;
    double cos_half_angle;
};
struct EclipseShadowCones {
    EclipseCone umbra, penumbra;
    Vec3 shadow_axis_unit; // 太陽→遮蔽体の向き。
};

// 公式 1.3.1 calc_eclipse_fraction の平面円盤重なり率。
// radius_ratio=遮蔽体/太陽の視半径、separation_ratio=視中心角距離/太陽視半径。
// 非負有限値が必要。同心・内接・外接も [0,1] を返す。
// 不正入力は invalid_argument、演算範囲を超える中間値は out_of_range。
double eclipse_obscured_fraction(double radius_ratio, double separation_ratio);

struct EclipseSurfaceSample {
    double obscured_fraction;
    double sun_angular_radius_rad;
    double occluder_angular_radius_rad;
    double separation_rad;
};
// 点は両球の外側で、両球は互いに接触・交差しないこと。
// 視半径は asin(R/d)、中心角は安定した atan2(|cross|,dot) で計算する。
// 遮蔽体の中心が太陽より遠い場合は隠蔽率 0。夜側判定は受影面の責務。
EclipseSurfaceSample eclipse_surface_sample(const EclipseSphere& sun,
    const EclipseSphere& occluder, Vec3 surface_point_au);

// 受影候補の判定前に、同じ2球から有限円錐を生成する。空間コーン用。
// 太陽半径>遮蔽体半径で非接触が必要。円柱・逆半径関係は未対応。
EclipseShadowCones eclipse_occluder_cones(const EclipseSphere& sun, const EclipseSphere& occluder);

// 公式 calc_eclipse_info の有限円錐。太陽半径>遮蔽体半径、3球が非接触で必要。
// 受影体が遮蔽体より太陽に近い、または半影候補外なら nullopt。
// 円柱へ退化する等半径・逆の半径関係は invalid_argument（未対応）。
std::optional<EclipseShadowCones> eclipse_shadow_cones(const EclipseGeometry& geometry);

// 太陽→遮蔽体方向の前方半直線と受影球の最初の交点。未交差は nullopt。
// 原版の未命中原点 sentinel を使わず、接線は単一交点として保持する。
std::optional<Vec3> eclipse_shadow_axis_hit(const EclipseGeometry& geometry);

// 公式 GL_ZERO/GL_SRC_COLOR の RGB 係数。入力色・隠蔽率は [0,1]。
// 月の赤い本影など、天体ごとの色選択は呼び出し側が明示する。
std::array<double,3> eclipse_shadow_multiplier(double obscured_fraction,
    std::array<double,3> shadow_rgb);

} // namespace mitaka
