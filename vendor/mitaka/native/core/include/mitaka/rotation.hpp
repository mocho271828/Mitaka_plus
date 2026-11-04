#pragma once

#include "mitaka/astronomy.hpp"

namespace mitaka {

// 惑星固定座標の X=東経0度、Y=東経90度、Z=北極を J2000 黄道座標で表す。
// 右手正規直交基底。北極は公式の地図上の北で、逆行惑星の角運動量方向とは異なる。
struct BodyOrientation {
    Vec3 x_axis{1, 0, 0};
    Vec3 y_axis{0, 1, 0};
    Vec3 north_axis{0, 0, 1};
};

// 公式 Mitaka 1.3.1 の表示用近似。地球は公式の専用歳差・自転計算を使う。
// 単一の JD を用い、UT1/TT/TDB 変換、閏秒、章動、極運動、光行時間は補正しない。
// 数値上の対応範囲は日付 API と同じ先発 Gregorian 年 -4712..9999。
// この範囲は天文学的な精度保証ではない。太陽・月・衛星と画像経度差分は対象外。
// 非有限 JD・不正 Planet は std::invalid_argument、範囲外 JD は std::out_of_range。
BodyOrientation planet_orientation(Planet planet, double julian_date);

} // namespace mitaka
