#include "mitaka/lunar.hpp"
#include "vector3.h"
#include "astro_const.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <stdexcept>
#include <string_view>

// 位置は原本を直接コンパイルし、姿勢の二関数は本文を変えず取り出す。
vector3d calc_lunar_pos(const double& jd);
void calc_moon_orientation_angle(const double& jd, double& ra, double& dec, double& meridian);
void calc_satellite_ec_to_sat_matrix(int id, const double& jd, matrix3d& unspun, matrix3d& spun);

// 原本の SAT_ORI_MOON=0 の分岐だけを代行する。数式は原本の関数に任せる。
void calc_satellite_orientation_angle(int id, const double& jd,
                                      double& ra, double& dec, double& meridian) {
    if (id != 0) throw std::invalid_argument("lunar reference supports only the Moon");
    calc_moon_orientation_angle(jd, ra, dec, meridian);
}

namespace {
struct Comparison {
    std::size_t components = 0;
    double maximum_difference = 0;
};

vector3d reference_position(double jd) {
    // 原本の double 定数を使う。描画用 float の _1AU_km は精度を失う。
    const double au_km = speed_of_light * _1AU_sec / 1000.0;
    const auto equatorial_km = Rx3deg(epsJ2000) * calc_lunar_pos(jd);
    return vector3d(equatorial_km.x / au_km,
                    equatorial_km.y / au_km,
                    equatorial_km.z / au_km);
}

void compare_component(double actual, double expected, double tolerance, double jd,
                       std::string_view label, std::size_t component, Comparison& result) {
    const double difference = std::abs(actual - expected);
    ++result.components;
    result.maximum_difference = std::max(result.maximum_difference, difference);
    if (!std::isfinite(actual) || !std::isfinite(expected) || difference > tolerance) {
        std::ostringstream message;
        message << std::setprecision(17) << "lunar reference mismatch: " << label
                << ", JD=" << jd << ", component=" << component
                << ", actual=" << actual << ", expected=" << expected
                << ", difference=" << difference << ", tolerance=" << tolerance;
        throw std::runtime_error(message.str());
    }
}

void compare_date(double jd, double position_tolerance, double orientation_tolerance,
                  Comparison& positions, Comparison& orientations) {
    const auto expected = reference_position(jd);
    const auto actual = mitaka::lunar_position(jd);
    const std::array<double, 3> actual_coordinates{actual.x, actual.y, actual.z};
    const std::array<double, 3> expected_coordinates{expected.x, expected.y, expected.z};
    for (std::size_t i = 0; i < actual_coordinates.size(); ++i) {
        compare_component(actual_coordinates[i], expected_coordinates[i], position_tolerance,
                          jd, "position AU", i, positions);
    }

    matrix3d unspun;
    matrix3d spun;
    calc_satellite_ec_to_sat_matrix(0, jd, unspun, spun);
    const auto orientation = mitaka::lunar_orientation(jd);
    // 元行列は黄道→月固定座標。その行が J2000 黄道で表した月の基底になる。
    const std::array<mitaka::Vec3, 3> axes{
        orientation.x_axis, orientation.y_axis, orientation.north_axis
    };
    for (std::size_t row = 0; row < axes.size(); ++row) {
        const std::array<double, 3> coordinates{axes[row].x, axes[row].y, axes[row].z};
        for (std::size_t column = 0; column < coordinates.size(); ++column) {
            compare_component(coordinates[column], spun(static_cast<int>(row), static_cast<int>(column)),
                              orientation_tolerance, jd, "orientation", row * 3 + column, orientations);
        }
    }
}

void dump_reference_values() {
    std::cout << std::setprecision(17);
    // 期待値の生成は新コアの計算や座標変換を呼び出さない。
    for (const double jd : {2415020.5, 2451545.0, 2461342.5, 2487980.5}) {
        const auto position = reference_position(jd);
        double ra, dec, meridian;
        calc_moon_orientation_angle(jd, ra, dec, meridian);
        matrix3d unspun;
        matrix3d spun;
        calc_satellite_ec_to_sat_matrix(0, jd, unspun, spun);
        std::cout << "JD " << jd << "\nposition J2000 equatorial AU {"
                  << position.x << ',' << position.y << ',' << position.z << "}\n"
                  << "RA/DEC/W degrees {" << ra << ',' << dec << ',' << meridian << "}\n"
                  << "basis J2000 ecliptic {{" << spun.m11 << ',' << spun.m12 << ',' << spun.m13
                  << "},{" << spun.m21 << ',' << spun.m22 << ',' << spun.m23
                  << "},{" << spun.m31 << ',' << spun.m32 << ',' << spun.m33 << "}}\n";
    }
}
} // namespace

int main(int argc, char** argv) {
    try {
        if (argc == 2 && std::string_view(argv[1]) == "--dump") {
            dump_reference_values();
            return 0;
        }
        if (argc != 1) {
            std::cerr << "Usage: test_lunar_upstream [--dump]\n";
            return 2;
        }

        Comparison positions;
        Comparison orientations;
        compare_date(2451545.0, 2e-17, 2e-14, positions, orientations);
        // 角度還元と演算順による丸め差を許す。モデルの観測精度を示す値ではない。
        constexpr double position_tolerance = 2e-15;
        constexpr double orientation_tolerance = 1e-11;
        for (int sample = 0; sample <= 1000; ++sample) {
            const double jd = sample == 1000 ? mitaka::lunar_maximum_jd
                : mitaka::lunar_minimum_jd
                    + (mitaka::lunar_maximum_jd - mitaka::lunar_minimum_jd) * (sample / 1000.0);
            compare_date(jd, position_tolerance, orientation_tolerance, positions, orientations);
        }
        for (const double jd : {
                 std::nextafter(mitaka::lunar_minimum_jd, mitaka::lunar_maximum_jd),
                 std::nextafter(mitaka::lunar_maximum_jd, mitaka::lunar_minimum_jd),
                 2451545.0 - 1.0 / 86400.0, 2451545.0 + 1.0 / 86400.0,
                 2451545.0 - 1.0, 2451545.0 + 1.0, 2461342.5}) {
            compare_date(jd, position_tolerance, orientation_tolerance, positions, orientations);
        }

        std::cout << std::setprecision(12) << "lunar reference: "
                  << positions.components + orientations.components << " components passed; "
                  << "maximum position difference AU=" << positions.maximum_difference
                  << ", maximum orientation difference=" << orientations.maximum_difference << '\n';
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
