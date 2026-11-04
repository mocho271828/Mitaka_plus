/*
Derived from Mitaka 1.3.1: Mitaka/mtk_planet_orientation.cpp.

Copyright (c) 2007-2015   Tsunehiko Kato  and  4D2U Project, National Astronomical Observatory of Japan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
#include "mitaka/rotation.hpp"

#include <cmath>
#include <stdexcept>

namespace mitaka {
namespace {
constexpr double degrees_to_radians = 3.141592653589793238462643383279502884 / 180.0;

// 多数の自転を含む JD でも、三角関数へ渡す角度を一周以内に抑える。
double radians(double degrees) {
    return std::remainder(degrees, 360.0) * degrees_to_radians;
}

double sin_deg(double degrees) { return std::sin(radians(degrees)); }
double cos_deg(double degrees) { return std::cos(radians(degrees)); }

BodyOrientation rotate_x(BodyOrientation basis, double degrees) {
    const double c = cos_deg(degrees), s = sin_deg(degrees);
    const auto rotate = [c, s](Vec3 v) -> Vec3 {
        return {v.x, c * v.y - s * v.z, s * v.y + c * v.z};
    };
    return {rotate(basis.x_axis), rotate(basis.y_axis), rotate(basis.north_axis)};
}

BodyOrientation rotate_z(BodyOrientation basis, double degrees) {
    const double c = cos_deg(degrees), s = sin_deg(degrees);
    const auto rotate = [c, s](Vec3 v) -> Vec3 {
        return {c * v.x - s * v.y, s * v.x + c * v.y, v.z};
    };
    return {rotate(basis.x_axis), rotate(basis.y_axis), rotate(basis.north_axis)};
}

struct RotationAngles {
    double pole_ra_deg, pole_dec_deg, prime_meridian_deg;
};

RotationAngles rotation_angles(Planet planet, double d, double T) {
    switch (planet) {
    case Planet::mercury: {
        const double M1 = 174.791086 + 4.092335 * d;
        const double M2 = 349.582171 + 8.184670 * d;
        const double M3 = 164.373257 + 12.277005 * d;
        const double M4 = 339.164343 + 16.369340 * d;
        const double M5 = 153.955429 + 20.461675 * d;
        return {281.0097 - 0.0328 * T, 61.4143 - 0.0049 * T,
                329.5469 + 6.1385025 * d + 0.00993822 * sin_deg(M1)
                - 0.00104581 * sin_deg(M2) - 0.00010280 * sin_deg(M3)
                - 0.00002364 * sin_deg(M4) - 0.00000532 * sin_deg(M5)};
    }
    case Planet::venus:
        return {272.76, 67.16, 160.20 - 1.4813688 * d};
    case Planet::mars:
        return {317.68143 - 0.1061 * T, 52.88650 - 0.0609 * T,
                176.630 + 350.89198226 * d};
    case Planet::jupiter: {
        const double Ja = 99.360714 + 4850.4046 * T;
        const double Jb = 175.895369 + 1191.9605 * T;
        const double Jc = 300.323162 + 262.5475 * T;
        const double Jd = 114.012305 + 6070.2476 * T;
        const double Je = 49.511251 + 64.3000 * T;
        return {
            268.056595 - 0.006499 * T + 0.000117 * sin_deg(Ja)
            + 0.000938 * sin_deg(Jb) + 0.001432 * sin_deg(Jc)
            + 0.000030 * sin_deg(Jd) + 0.002150 * sin_deg(Je),
            64.495303 + 0.002413 * T + 0.000050 * cos_deg(Ja)
            + 0.000404 * cos_deg(Jb) + 0.000617 * cos_deg(Jc)
            - 0.000013 * cos_deg(Jd) + 0.000926 * cos_deg(Je),
            284.95 + 870.5360000 * d};
    }
    case Planet::saturn:
        return {40.589 - 0.036 * T, 83.537 - 0.004 * T,
                38.90 + 810.7939024 * d};
    case Planet::uranus:
        return {257.311, -15.175, 203.81 - 501.1600928 * d};
    case Planet::neptune: {
        const double N = 357.85 + 52.316 * T;
        return {299.36 + 0.70 * sin_deg(N), 43.46 - 0.51 * cos_deg(N),
                253.18 + 536.3128492 * d - 0.48 * sin_deg(N)};
    }
    case Planet::pluto:
        return {132.993, -6.163, 302.695 + 56.3625225 * d};
    default:
        throw std::invalid_argument("rotation: invalid planet");
    }
}

BodyOrientation earth_orientation(double d, double T) {
    const double T2 = T * T, T3 = T * T2, T4 = T2 * T2, T5 = T4 * T;
    // 原本は歳差の eps0 と J2000 黄道変換の傾斜角に別の値を使う。
    constexpr double eps0 = 84381.406 / 3600.0;
    const double phi = (5038.481507 * T - 1.0790069 * T2 - 0.00114045 * T3
                        + 0.000132851 * T4 - 0.0000000951 * T5) / 3600.0;
    const double omega = eps0 + (-0.025754 * T + 0.0512623 * T2 - 0.00772503 * T3
                                - 0.000000467 * T4 + 0.0000003337 * T5) / 3600.0;
    const double chi = (10.556403 * T - 2.3814292 * T2 - 0.00121197 * T3
                        + 0.000170663 * T4 - 0.0000000560 * T5) / 3600.0;
    // 原本で GMST と呼ばれる線形式を保持する。UT1 等への変換は行わない。
    const double spin = 360.0 * (0.7790572732640 + 1.00273781191135448 * d);
    BodyOrientation basis = rotate_z({}, spin);
    basis = rotate_z(basis, chi);
    basis = rotate_x(basis, -omega);
    basis = rotate_z(basis, -phi);
    basis = rotate_x(basis, eps0);
    return rotate_x(basis, -j2000_obliquity_deg);
}
} // namespace

BodyOrientation planet_orientation(Planet planet, double julian_date) {
    if (!std::isfinite(julian_date)) {
        throw std::invalid_argument("rotation: non-finite Julian date");
    }
    const double minimum_jd = mitaka::julian_date({-4712, 1, 1, 0, 0, 0});
    constexpr double end_jd = 5373484.5; // Gregorian 10000-01-01 00:00、上端を含まない。
    if (julian_date < minimum_jd || julian_date >= end_jd) {
        throw std::out_of_range("rotation: Julian date outside Gregorian year -4712..9999");
    }
    const double d = julian_date - 2451545.0;
    const double T = d / 36525.0;
    if (planet == Planet::earth) return earth_orientation(d, T);
    const auto angles = rotation_angles(planet, d, T);
    // 公式の黄道→惑星行列を転置し、惑星固定軸を黄道座標へ戻す順序で回転する。
    BodyOrientation basis = rotate_z({}, angles.prime_meridian_deg);
    basis = rotate_x(basis, 90.0 - angles.pole_dec_deg);
    basis = rotate_z(basis, 90.0 + angles.pole_ra_deg);
    return rotate_x(basis, -j2000_obliquity_deg);
}
} // namespace mitaka
