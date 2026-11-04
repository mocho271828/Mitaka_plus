/*
Derived from Mitaka 1.3.1: common/JulianDate.cpp, common/astro/cele_mech.cpp,
common/astro/astrometry.cpp, common/math/vector3.h,
Mitaka/mtk_orbital_element.cpp and Mitaka/mtk_planet_position.cpp.

Copyright (c) 2007   Tsunehiko Kato
Copyright (c) 2007-2012   Tsunehiko Kato
Copyright (c) 2007-2014   Tsunehiko Kato
Copyright (c) 2013   Tsunehiko Kato
Copyright (c) 2007, 2014   Tsunehiko Kato and 4D2U Project, National Astronomical Observatory of Japan
Copyright (c) 2007-2015   Tsunehiko Kato and 4D2U Project, National Astronomical Observatory of Japan

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
#include "mitaka/astronomy.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <limits>
#include <stdexcept>

namespace mitaka {
namespace {
constexpr double pi = 3.141592653589793238462643383279502884;
constexpr double radians = pi / 180.0;
constexpr double seconds_per_day = 86400.0;

void require_finite(double value) {
    if (!std::isfinite(value)) throw std::invalid_argument("astronomy: non-finite input");
}

void require_finite(Vec3 value) {
    require_finite(value.x);
    require_finite(value.y);
    require_finite(value.z);
}

Vec3 finite_result(Vec3 value) {
    if (!std::isfinite(value.x) || !std::isfinite(value.y) || !std::isfinite(value.z)) {
        throw std::out_of_range("astronomy: coordinate overflow");
    }
    return value;
}

bool leap_year(int year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
}

Vec3 rotate_x(Vec3 v, double angle) {
    const double c = std::cos(angle), s = std::sin(angle);
    return {v.x, c * v.y - s * v.z, s * v.y + c * v.z};
}

Vec3 rotate_z(Vec3 v, double angle) {
    const double c = std::cos(angle), s = std::sin(angle);
    return {c * v.x - s * v.y, s * v.x + c * v.y, v.z};
}

Vec3 orbital_to_reference(Vec3 v, const OrbitalElements& e) {
    v = rotate_z(v, std::remainder(e.argument_of_periapsis_deg, 360.0) * radians);
    v = rotate_x(v, std::remainder(e.inclination_deg, 360.0) * radians);
    return rotate_z(v, std::remainder(e.ascending_node_deg, 360.0) * radians);
}

// 単調な方程式を二分法で解き、近放物線軌道で Newton 法が停滞する場合も反復を有界にする。
double eccentric_anomaly(double eccentricity, double mean_anomaly) {
    const bool elliptic = eccentricity < 1.0;
    const double m = elliptic ? std::remainder(mean_anomaly, 2.0 * pi) : mean_anomaly;
    if (m == 0.0) return 0.0;
    const double target = std::abs(m);
    double lower = 0.0;
    double upper = elliptic ? pi : std::asinh(target / eccentricity) + 1.0;
    double x = (lower + upper) / 2.0;
    for (int iteration = 0; iteration < 160; ++iteration) {
        const double residual = elliptic ? x - eccentricity * std::sin(x) - target
                                         : eccentricity * std::sinh(x) - x - target;
        if (residual == 0.0) return std::copysign(x, m);
        if (residual > 0.0) upper = x;
        else lower = x;
        if (upper - lower <= 4.0 * std::numeric_limits<double>::epsilon() * std::max(x, 1e-12)) {
            return std::copysign((lower + upper) / 2.0, m);
        }
        x = (lower + upper) / 2.0;
    }
    throw std::runtime_error("astronomy: Kepler equation did not converge");
}

struct MeanElements { double a, e, inclination, node, perihelion, longitude; };
constexpr std::array<MeanElements, 9> mean_elements{{
    {0.38710, 0.20563, 7.0050, 48.3665, 77.5028, 55.4500},
    {0.72333, 0.00677, 3.3947, 76.7069, 131.6058, 137.1556},
    {1.00000, 0.01671, 0.0000, 0.0000, 102.9889, 100.2431},
    {1.52368, 0.09340, 1.8497, 49.5812, 336.1155, 209.5529},
    {5.20260, 0.04850, 1.3031, 100.4950, 14.3796, 125.4198},
    {9.55491, 0.05554, 2.4888, 113.6918, 93.1161, 86.7744},
    {19.21845, 0.04638, 0.7732, 74.0216, 173.0499, 326.9480},
    {30.11039, 0.00946, 1.7697, 131.8171, 48.1631, 310.9437},
    {39.54044, 0.24901, 17.1449, 110.3587, 224.1833, 242.8665}
}};
} // namespace

double julian_date(const GregorianDateTime& date) {
    require_finite(date.second);
    constexpr std::array<int, 12> month_days{{31,28,31,30,31,30,31,31,30,31,30,31}};
    constexpr std::array<int, 12> prior_days{{0,31,59,90,120,151,181,212,243,273,304,334}};
    if (date.year < -4712 || date.year > 9999 || date.month < 1 || date.month > 12) {
        throw std::invalid_argument("astronomy: Gregorian year/month out of range");
    }
    const bool leap = leap_year(date.year);
    const int days = month_days[date.month - 1] + (date.month == 2 && leap ? 1 : 0);
    if (date.day < 1 || date.day > days || date.hour < 0 || date.hour > 23 ||
        date.minute < 0 || date.minute > 59 || date.second < 0 || date.second >= 60) {
        throw std::invalid_argument("astronomy: invalid Gregorian date/time");
    }
    const double year = date.year - 1.0;
    const double start = std::floor(365.25 * year) - std::floor(year / 100.0) +
                         std::floor(year / 400.0) + 1721425.0;
    const int prior = prior_days[date.month - 1] + (leap && date.month > 2 ? 1 : 0);
    return start + prior + date.day - 0.5 +
           (date.hour * 3600.0 + date.minute * 60.0 + date.second) / seconds_per_day;
}

GregorianDateTime gregorian_date_time(double jd) {
    require_finite(jd);
    if (jd < julian_date({-4712,1,1,0,0,0}) || jd >= 5373484.5) {
        throw std::out_of_range("astronomy: Julian date outside Gregorian year -4712..9999");
    }
    const auto day_number = static_cast<std::int64_t>(std::floor(jd + 0.5));
    std::int64_t l = day_number + 68569;
    const std::int64_t n = 4 * l / 146097;
    l -= (146097 * n + 3) / 4;
    const std::int64_t i = 4000 * (l + 1) / 1461001;
    l = l - 1461 * i / 4 + 31;
    const std::int64_t j = 80 * l / 2447;
    const int day = static_cast<int>(l - 2447 * j / 80);
    l = j / 11;
    const int month = static_cast<int>(j + 2 - 12 * l);
    const int year = static_cast<int>(100 * (n - 49) + i + l);
    double seconds = (jd - (static_cast<double>(day_number) - 0.5)) * seconds_per_day;
    const int hour = static_cast<int>(seconds / 3600.0);
    seconds -= hour * 3600.0;
    const int minute = static_cast<int>(seconds / 60.0);
    return {year, month, day, hour, minute, seconds - minute * 60.0};
}

OrbitalState orbital_state(const OrbitalElements& e, double jd) {
    for (double value : {e.epoch_jd, e.semi_major_axis_au, e.eccentricity,
                         e.mean_anomaly_deg, e.mean_motion_deg_per_day,
                         e.ascending_node_deg, e.inclination_deg,
                         e.argument_of_periapsis_deg, jd}) require_finite(value);
    if (e.semi_major_axis_au <= 0 || e.eccentricity < 0 || e.eccentricity == 1) {
        throw std::invalid_argument("astronomy: require a > 0 and e >= 0, e != 1");
    }
    const double mean_anomaly = std::fma(e.mean_motion_deg_per_day, jd - e.epoch_jd,
                                       e.mean_anomaly_deg) * radians;
    if (!std::isfinite(mean_anomaly)) throw std::out_of_range("astronomy: anomaly overflow");
    const double anomaly = eccentric_anomaly(e.eccentricity, mean_anomaly);
    const double a = e.semi_major_axis_au, eccentricity = e.eccentricity;
    Vec3 position{}, velocity{};
    if (eccentricity < 1) {
        const double c = std::cos(anomaly), s = std::sin(anomaly);
        const double minor = std::sqrt((1.0 - eccentricity) * (1.0 + eccentricity));
        const double rate = e.mean_motion_deg_per_day * radians / (1.0 - eccentricity * c);
        position = {a * (c - eccentricity), a * minor * s, 0};
        velocity = {-a * s * rate, a * minor * c * rate, 0};
    } else {
        const double c = std::cosh(anomaly), s = std::sinh(anomaly);
        const double minor = std::sqrt(eccentricity - 1) * std::sqrt(eccentricity + 1);
        const double rate = e.mean_motion_deg_per_day * radians / (eccentricity * c - 1.0);
        position = {a * (eccentricity - c), a * minor * s, 0};
        velocity = {-a * s * rate, a * minor * c * rate, 0};
    }
    const OrbitalState result{orbital_to_reference(position, e), orbital_to_reference(velocity, e)};
    for (double value : {result.position_au.x, result.position_au.y, result.position_au.z,
                         result.velocity_au_per_day.x, result.velocity_au_per_day.y,
                         result.velocity_au_per_day.z}) {
        if (!std::isfinite(value)) throw std::out_of_range("astronomy: orbital state overflow");
    }
    return result;
}

OrbitalElements mean_planet_elements(Planet planet) {
    const auto index = static_cast<unsigned int>(planet);
    if (index >= mean_elements.size()) throw std::invalid_argument("astronomy: invalid planet");
    const auto& e = mean_elements[index];
    return {2452640.5, e.a, e.e, e.longitude - e.perihelion,
            0.985607669 / std::pow(e.a, 1.5), e.node, e.inclination, e.perihelion - e.node};
}

OrbitalState mean_planet_state(Planet planet, double jd) {
    return orbital_state(mean_planet_elements(planet), jd);
}

Vec3 equatorial_direction(EquatorialCoordinates coordinates) {
    require_finite(coordinates.right_ascension_deg);
    require_finite(coordinates.declination_deg);
    if (std::abs(coordinates.declination_deg) > 90) {
        throw std::invalid_argument("astronomy: declination outside [-90,90]");
    }
    const double ra = std::remainder(coordinates.right_ascension_deg, 360.0) * radians;
    const double dec = coordinates.declination_deg * radians;
    return {std::cos(dec) * std::cos(ra), std::cos(dec) * std::sin(ra), std::sin(dec)};
}

EquatorialCoordinates equatorial_coordinates(Vec3 direction) {
    require_finite(direction);
    if (direction.x == 0 && direction.y == 0 && direction.z == 0) {
        throw std::invalid_argument("astronomy: zero direction vector");
    }
    // 正規化してから hypot を使い、非常に大きい入力でも中間結果を有限に保つ。
    const double scale = std::max({std::abs(direction.x), std::abs(direction.y), std::abs(direction.z)});
    direction = {direction.x / scale, direction.y / scale, direction.z / scale};
    double ra = std::atan2(direction.y, direction.x) / radians;
    if (ra < 0) ra += 360.0;
    if (ra >= 360.0) ra = 0.0;
    return {ra, std::atan2(direction.z, std::hypot(direction.x, direction.y)) / radians};
}

Vec3 j2000_ecliptic_to_equatorial(Vec3 vector) {
    require_finite(vector);
    return finite_result(rotate_x(vector, j2000_obliquity_deg * radians));
}

Vec3 j2000_equatorial_to_ecliptic(Vec3 vector) {
    require_finite(vector);
    return finite_result(rotate_x(vector, -j2000_obliquity_deg * radians));
}

EquatorialCoordinates b1950_to_j2000(EquatorialCoordinates coordinates, B1950Motion motion) {
    const Vec3 x0 = equatorial_direction(coordinates);
    for (double value : {motion.ra_seconds_per_century, motion.dec_arcseconds_per_century,
                         motion.radial_velocity_km_per_second, motion.parallax_arcseconds}) require_finite(value);
    const double ra = std::remainder(coordinates.right_ascension_deg, 360.0) * radians;
    const double dec = coordinates.declination_deg * radians;
    const double radial = 21.094502 * motion.parallax_arcseconds * motion.radial_velocity_km_per_second;
    const double pmra = 15.0 * motion.ra_seconds_per_century;
    const double pmdec = motion.dec_arcseconds_per_century;
    const Vec3 v0{-pmdec * std::sin(dec) * std::cos(ra) - pmra * x0.y + radial * x0.x,
                  -pmdec * std::sin(dec) * std::sin(ra) + pmra * x0.x + radial * x0.y,
                  pmdec * std::cos(dec) + radial * x0.z};
    const double q = -1.62557 * x0.x - 0.31919 * x0.y - 0.13843 * x0.z;
    const double dq = 1.245 * x0.x - 1.580 * x0.y - 0.659 * x0.z;
    const Vec3 x1{x0.x + 1e-6 * (1.62557 + q * x0.x),
                  x0.y + 1e-6 * (0.31919 + q * x0.y),
                  x0.z + 1e-6 * (0.13843 + q * x0.z)};
    const Vec3 v1{v0.x + 1e-3 * (-1.245 + dq * x0.x),
                  v0.y + 1e-3 * (1.580 + dq * x0.y),
                  v0.z + 1e-3 * (0.659 + dq * x0.z)};
    const Vec3 result{
        0.9999256782*x1.x - 0.0111820610*x1.y - 0.0048579477*x1.z +
        0.0000024239502*v1.x - 0.0000000271066*v1.y - 0.0000000117766*v1.z,
        0.0111820609*x1.x + 0.9999374784*x1.y - 0.0000271765*x1.z +
        0.0000000271066*v1.x + 0.0000024239788*v1.y - 0.0000000000659*v1.z,
        0.0048579479*x1.x - 0.0000271474*x1.y + 0.9999881997*x1.z +
        0.0000000117766*v1.x - 0.0000000000658*v1.y + 0.0000024241017*v1.z};
    return equatorial_coordinates(finite_result(result));
}

} // namespace mitaka
