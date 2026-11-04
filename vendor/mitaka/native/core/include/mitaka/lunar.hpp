#pragma once

#include "mitaka/rotation.hpp"

namespace mitaka {

inline constexpr double earth_moon_mass_ratio = 81.30057;
inline constexpr double lunar_minimum_jd = 2415020.5;
inline constexpr double lunar_maximum_jd = 2487980.5;

// 公式 1.3.1 の月位置近似。地心 J2000 赤道座標、単位 AU。
// 対応範囲は上記 JD の両端を含む。精度保証範囲を意味しない。
// 単一 JD を位置・姿勢で共用し、UTC/UT1/TT/TDB の変換は行わない。
// 非有限値は std::invalid_argument、対応範囲外は std::out_of_range。
Vec3 lunar_position(double julian_date);

// 公式の月 RA/DEC/W と周期項による月固定軸。J2000 黄道の右手正規直交基底。
// X は経度 0、Y は東経 90 度、Z は北極。画像経度オフセットを含まない。
// 日付・例外の契約は lunar_position と共通。
BodyOrientation lunar_orientation(double julian_date);

} // namespace mitaka
