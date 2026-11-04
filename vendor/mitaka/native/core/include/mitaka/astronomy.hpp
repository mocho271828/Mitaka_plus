#pragma once

namespace mitaka {

struct Vec3 { double x, y, z; };

// 先発グレゴリオ暦。年 0 は紀元前 1 年。閏秒は扱わない。
struct GregorianDateTime {
    int year, month, day, hour, minute;
    double second;
};

// 対応年は -4712..9999。時系は呼び出し側が統一する（UTC/TT/TDB の変換はしない）。
double julian_date(const GregorianDateTime& date);
GregorianDateTime gregorian_date_time(double jd);

struct OrbitalElements {
    double epoch_jd;
    double semi_major_axis_au; // 双曲線でも正の絶対値。
    double eccentricity;
    double mean_anomaly_deg;
    double mean_motion_deg_per_day;
    double ascending_node_deg;
    double inclination_deg;
    double argument_of_periapsis_deg;
};

struct OrbitalState {
    Vec3 position_au;
    Vec3 velocity_au_per_day;
};

// 参照面は軌道要素に従う。引力の楕円・双曲線を扱い、放物線と斥力は拒否する。
// 不正入力は std::invalid_argument、範囲超過は std::out_of_range、非収束は std::runtime_error。
OrbitalState orbital_state(const OrbitalElements& elements, double jd);

enum class Planet { mercury, venus, earth, mars, jupiter, saturn, uranus, neptune, pluto };

// 公式 1.3.1 の平均軌道近似。日心黄道座標、元期 JD 2452640.5。
// 摂動・月・重心補正を含まない。高精度暦としては使わない。
OrbitalElements mean_planet_elements(Planet planet);
OrbitalState mean_planet_state(Planet planet, double jd);

struct EquatorialCoordinates { double right_ascension_deg, declination_deg; };

// RA は [0,360)、DEC は [-90,90]。単位ベクトルでない入力も受け付ける。
Vec3 equatorial_direction(EquatorialCoordinates coordinates);
EquatorialCoordinates equatorial_coordinates(Vec3 direction);

inline constexpr double j2000_obliquity_deg = 84381.448 / 3600.0;
Vec3 j2000_ecliptic_to_equatorial(Vec3 vector);
Vec3 j2000_equatorial_to_ecliptic(Vec3 vector);

struct B1950Motion {
    double ra_seconds_per_century = 0;
    double dec_arcseconds_per_century = 0;
    double radial_velocity_km_per_second = 0;
    double parallax_arcseconds = 0;
};

// 公式 astrometry.cpp の B1950→J2000 変換。固有運動の世紀は Bessel 年 100 年。
EquatorialCoordinates b1950_to_j2000(EquatorialCoordinates coordinates,
                                    B1950Motion motion = {});

} // namespace mitaka
