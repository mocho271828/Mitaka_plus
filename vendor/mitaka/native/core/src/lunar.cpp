/*
Derived from Mitaka 1.3.1: Mitaka/mtk_lunar_pos.cpp and mtk_satellite_orientation.cpp.

Copyright (c) 2007   Tsunehiko Kato  and  4D2U Project, National Astronomical Observatory of Japan

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
#include "mitaka/lunar.hpp"

#include <cmath>
#include <stdexcept>

namespace mitaka {
namespace {
struct Term { double amplitude, phase_deg, rate_deg_per_year; };

// 係数は公式原本と同じ順序・桁数を保つ。
constexpr Term longitude_terms[] = {
    {6.2887, 338.915, 4771.9886},
    {1.2740, 107.248, -4133.3536},
    {0.6583, 51.668, 8905.3422},
    {0.2136, 317.831, 9543.9773},
    {0.1856, 176.531, 359.9905},
    {0.1143, 292.463, 9664.0404},
    {0.0588, 86.16, 638.635},
    {0.0572, 103.78, -3773.363},
    {0.0533, 30.58, 13677.331},
    {0.0459, 124.86, -8545.352},
    {0.0410, 342.38, 4411.998},
    {0.0348, 25.83, 4452.671},
    {0.0305, 155.45, 5131.979},
    {0.0153, 240.79, 758.698},
    {0.0125, 271.38, 14436.029},
    {0.0110, 226.45, -4892.052},
    {0.0107, 55.58, -13038.696},
    {0.0100, 296.75, 14315.966},
    {0.0085, 34.5, -8266.71},
    {0.0079, 290.7, -4493.34},
    {0.0068, 228.2, 9265.33},
    {0.0052, 133.1, 319.32},
    {0.0050, 202.4, 4812.66},
    {0.0048, 68.6, -19.34},
    {0.0040, 34.1, 13317.34},
    {0.0040, 9.5, 18449.32},
    {0.0040, 93.8, -1.33},
    {0.0039, 103.3, 17810.68},
    {0.0037, 65.1, 5410.62},
    {0.0027, 321.3, 9183.99},
    {0.0026, 174.8, -13797.39},
    {0.0024, 82.7, 998.63},
    {0.0024, 4.7, 9224.66},
    {0.0022, 121.4, -8185.36},
    {0.0021, 134.4, 9903.97},
    {0.0021, 173.1, 719.98},
    {0.0021, 100.3, -3413.37},
    {0.0020, 248.6, -19.34},
    {0.0018, 98.1, 4013.29},
    {0.0016, 344.1, 18569.38},
    {0.0012, 52.1, -12678.71},
    {0.0011, 250.3, 19208.02},
    {0.0009, 81.0, -8586.0},
    {0.0008, 207.0, 14037.3},
    {0.0008, 31.0, -7906.7},
    {0.0007, 346.0, 4052.0},
    {0.0007, 294.0, -4853.3},
    {0.0007, 90.0, 278.6},
    {0.0006, 237.0, 1118.7},
    {0.0005, 82.0, 22582.7},
    {0.0005, 276.0, 19088.0},
    {0.0005, 73.0, -17450.7},
    {0.0005, 112.0, 5091.3},
    {0.0004, 116.0, -398.7},
    {0.0004, 25.0, -120.1},
    {0.0004, 181.0, 9584.7},
    {0.0004, 18.0, 720.0},
    {0.0003, 60.0, -3814.0},
    {0.0003, 13.0, -3494.7},
    {0.0003, 13.0, 18089.3},
    {0.0003, 152.0, 5492.0},
    {0.0003, 317.0, -40.7},
    {0.0003, 348.0, 23221.3},
};

constexpr Term longitude_phase_terms[] = {
    {0.0040, 93.8, -1.33},
    {0.0020, 248.6, -19.34},
    {0.0006, 66.0, 0.2},
    {0.0006, 249.0, -19.3},
};

constexpr Term latitude_terms[] = {
    {5.1282, 236.231, 4832.0202},
    {0.2806, 215.147, 9604.0088},
    {0.2777, 77.316, 60.0316},
    {0.1732, 4.563, -4073.3220},
    {0.0554, 308.98, 8965.374},
    {0.0463, 343.48, 698.667},
    {0.0326, 287.90, 13737.362},
    {0.0172, 194.06, 14375.997},
    {0.0093, 25.6, -8845.31},
    {0.0088, 98.4, -4711.96},
    {0.0082, 1.1, -3713.33},
    {0.0043, 322.4, 5470.66},
    {0.0042, 266.8, 18509.35},
    {0.0034, 188.0, -4433.31},
    {0.0025, 312.5, 8605.38},
    {0.0022, 291.4, 13377.37},
    {0.0021, 340.0, 1058.66},
    {0.0019, 218.6, 9244.02},
    {0.0018, 291.8, -8206.68},
    {0.0018, 52.8, 5192.01},
    {0.0017, 168.7, 14496.06},
    {0.0016, 73.8, 420.02},
    {0.0015, 262.1, 9284.69},
    {0.0015, 31.7, 9964.00},
    {0.0014, 260.8, -299.96},
    {0.0013, 239.7, 4472.03},
    {0.0013, 30.4, 379.35},
    {0.0012, 304.9, 4812.68},
    {0.0012, 12.4, -4851.36},
    {0.0011, 173.0, 19147.99},
    {0.0010, 312.9, -12978.66},
    {0.0008, 1.0, 17870.7},
    {0.0008, 190.0, 9724.1},
    {0.0007, 22.0, 13098.7},
    {0.0006, 117.0, 5590.7},
    {0.0006, 47.0, -13617.3},
    {0.0005, 22.0, -8485.3},
    {0.0005, 150.0, 4193.4},
    {0.0004, 119.0, -9483.9},
    {0.0004, 246.0, 23281.3},
    {0.0004, 301.0, 10242.6},
    {0.0004, 126.0, 9325.4},
    {0.0004, 104.0, 14097.4},
    {0.0003, 340.0, 22642.7},
    {0.0003, 270.0, 18149.4},
    {0.0003, 358.0, -3353.3},
    {0.0003, 148.0, 19268.0},
};

constexpr Term latitude_phase_terms[] = {
    {0.0267, 68.64, -19.341},
    {0.0043, 342.0, -19.36},
    {0.0040, 93.8, -1.33},
    {0.0020, 248.6, -19.34},
    {0.0005, 358.0, -19.4},
};

constexpr Term parallax_terms[] = {
    {0.0518, 338.92, 4771.989},
    {0.0095, 287.2, -4133.35},
    {0.0078, 51.7, 8905.34},
    {0.0028, 317.8, 9543.98},
    {0.0009, 31.0, 13677.3},
    {0.0005, 305.0, -8545.4},
    {0.0004, 284.0, -3773.4},
    {0.0003, 342.0, 4412.0},
};

constexpr double degrees_to_radians = 3.141592653589793238462643383279502884 / 180.0;
// 公式の位置級数が使う pi は、行列用 D2R より桁数が少ない。
constexpr double position_degrees_to_radians = 3.14159265358979 / 180.0;
constexpr double astronomical_unit_km = 299792458.0 * 499.0047838061 * 1e-3;

void validate_date(double jd) {
    if (!std::isfinite(jd)) throw std::invalid_argument("lunar: non-finite Julian date");
    if (jd < lunar_minimum_jd || jd > lunar_maximum_jd) {
        throw std::out_of_range("lunar: Julian date outside [2415020.5, 2487980.5]");
    }
}

double sin_deg(double degrees) {
    return std::sin(std::remainder(degrees, 360.0) * degrees_to_radians);
}

double cos_deg(double degrees) {
    return std::cos(std::remainder(degrees, 360.0) * degrees_to_radians);
}

Vec3 rotate_x(Vec3 v, double degrees) {
    const double c = cos_deg(degrees), s = sin_deg(degrees);
    return {v.x, c*v.y - s*v.z, s*v.y + c*v.z};
}

Vec3 rotate_z(Vec3 v, double degrees) {
    const double c = cos_deg(degrees), s = sin_deg(degrees);
    return {c*v.x - s*v.y, s*v.x + c*v.y, v.z};
}

double sine_term(Term term, double years, double phase_shift_deg = 0) {
    return term.amplitude * std::sin(position_degrees_to_radians *
        (term.phase_deg + term.rate_deg_per_year * years + phase_shift_deg));
}

Vec3 ecliptic_position_km(double jd) {
    const double dt = (jd - (2442413.0 - 0.5)) / 365.25;
    // 公式の経験的補正式であり、UTC/TT 等を変換する時系モデルではない。
    const double years = dt + (0.0317*dt + 1.43) * 1e-6;
    double A = 0, B = 0;
    for (const auto term : longitude_phase_terms) A += sine_term(term, years);
    for (const auto term : latitude_phase_terms) B += sine_term(term, years);

    double longitude = 124.8754 + 4812.67881 * years;
    bool first = true;
    for (const auto term : longitude_terms) {
        longitude += sine_term(term, years, first ? A : 0);
        first = false;
    }
    double latitude = 0;
    first = true;
    for (const auto term : latitude_terms) {
        latitude += sine_term(term, years, first ? B : 0);
        first = false;
    }
    double parallax = 0.9507;
    for (const auto term : parallax_terms) {
        parallax += term.amplitude * std::cos(position_degrees_to_radians *
            (term.phase_deg + term.rate_deg_per_year * years));
    }
    longitude *= position_degrees_to_radians;
    latitude *= position_degrees_to_radians;
    parallax *= position_degrees_to_radians;
    // 原本の sinpi は既に視差の正弦を近似した量。ここへ sin を追加しない。
    const double distance = 6378.140 / parallax;
    const double cos_latitude = std::cos(latitude);
    Vec3 position{distance*cos_latitude*std::cos(longitude),
                  distance*cos_latitude*std::sin(longitude), distance*std::sin(latitude)};

    // 日付の黄道から J2000 黄道へ戻す。eps0 と公開変換の傾斜角は原本でも別値。
    const double t1 = (jd - 2451545.0) / 36525.0;
    const double t2 = t1*t1, t3 = t2*t1, t4 = t3*t1, t5 = t4*t1;
    constexpr double eps0 = 84381.406 / 3600.0;
    const double zeta = (2.650545 + 2306.083227*t1 + 0.2988499*t2 + 0.01801828*t3
                        - 0.000005971*t4 - 0.0000003173*t5) / 3600.0;
    const double z = (-2.650545 + 2306.077181*t1 + 1.0927348*t2 + 0.01826837*t3
                     - 0.000028596*t4 - 0.0000002904*t5) / 3600.0;
    const double theta = (2004.191903*t1 - 0.4294934*t2 - 0.04182264*t3
                         - 0.000007089*t4 - 0.0000001274*t5) / 3600.0;
    const double eps = (84381.406 - 46.836769*t1 - 0.0001831*t2 + 0.00200340*t3
                       - 0.000000576*t4 - 0.0000000434*t5) / 3600.0;
    position = rotate_x(position, eps);
    position = rotate_z(position, -90.0-z);
    position = rotate_x(position, theta);
    position = rotate_z(position, 90.0-zeta);
    return rotate_x(position, -eps0);
}
} // namespace

Vec3 lunar_position(double julian_date) {
    validate_date(julian_date);
    const Vec3 position = j2000_ecliptic_to_equatorial(ecliptic_position_km(julian_date));
    return {position.x/astronomical_unit_km, position.y/astronomical_unit_km,
            position.z/astronomical_unit_km};
}

BodyOrientation lunar_orientation(double julian_date) {
    validate_date(julian_date);
    const double d = julian_date - 2451545.0, T = d / 36525.0;
    const double E1 = 125.045 - 0.0529921*d;
    const double E2 = 250.089 - 0.1059842*d;
    const double E3 = 260.008 + 13.0120009*d;
    const double E4 = 176.625 + 13.3407154*d;
    const double E5 = 357.529 + 0.9856003*d;
    const double E6 = 311.589 + 26.4057084*d;
    const double E7 = 134.963 + 13.0649930*d;
    const double E8 = 276.617 + 0.3287146*d;
    const double E9 = 34.226 + 1.7484877*d;
    const double E10 = 15.134 - 0.1589763*d;
    const double E11 = 119.743 + 0.0036096*d;
    const double E12 = 239.961 + 0.1643573*d;
    const double E13 = 25.053 + 12.9590088*d;
    const double ra = 269.9949 + 0.0031*T - 3.8787*sin_deg(E1) - 0.1204*sin_deg(E2)
        + 0.0700*sin_deg(E3) - 0.0172*sin_deg(E4) + 0.0072*sin_deg(E6)
        - 0.0052*sin_deg(E10) + 0.0043*sin_deg(E13);
    const double dec = 66.5392 + 0.0130*T + 1.5419*cos_deg(E1) + 0.0239*cos_deg(E2)
        - 0.0278*cos_deg(E3) + 0.0068*cos_deg(E4) - 0.0029*cos_deg(E6)
        + 0.0009*cos_deg(E7) + 0.0008*cos_deg(E10) - 0.0009*cos_deg(E13);
    const double W = 38.3213 + 13.17635815*d - 1.4e-12*d*d + 3.5610*sin_deg(E1)
        + 0.1208*sin_deg(E2) - 0.0642*sin_deg(E3) + 0.0158*sin_deg(E4)
        + 0.0252*sin_deg(E5) - 0.0066*sin_deg(E6) - 0.0047*sin_deg(E7)
        - 0.0046*sin_deg(E8) + 0.0028*sin_deg(E9) + 0.0052*sin_deg(E10)
        + 0.0040*sin_deg(E11) + 0.0019*sin_deg(E12) - 0.0044*sin_deg(E13);
    // 公式の黄道→月固定行列を転置し、月固定軸を J2000 黄道へ戻す。
    const auto to_ecliptic = [ra, dec, W](Vec3 axis) {
        axis = rotate_z(axis, W);
        axis = rotate_x(axis, 90.0-dec);
        axis = rotate_z(axis, 90.0+ra);
        return rotate_x(axis, -j2000_obliquity_deg);
    };
    return {to_ecliptic({1,0,0}), to_ecliptic({0,1,0}), to_ecliptic({0,0,1})};
}
} // namespace mitaka
