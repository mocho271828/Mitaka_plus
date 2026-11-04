#include "mitaka/rotation.hpp"
#include "vector3.h"
#include "astro_const.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <limits>
#include <sstream>
#include <stdexcept>
#include <string_view>

// 原本からビルド時に取り出した関数。ライブラリ本体にはリンクしない。
void calc_planet_ec_to_pl_matrix(int index, const double& jd, matrix3d& unspun, matrix3d& spun);

namespace {
struct Comparison {
    std::size_t components = 0;
    double maximum_difference = 0;
};

void compare_date(double jd, double tolerance, Comparison& result) {
    for (int planet = 0; planet < 9; ++planet) {
        matrix3d unspun;
        matrix3d spun;
        calc_planet_ec_to_pl_matrix(planet, jd, unspun, spun);
        const auto orientation = mitaka::planet_orientation(static_cast<mitaka::Planet>(planet), jd);
        // 元行列は黄道→天体であり、その行が黄道座標で表した天体の基底になる。
        const std::array<mitaka::Vec3, 3> axes{
            orientation.x_axis, orientation.y_axis, orientation.north_axis
        };
        for (std::size_t row = 0; row < axes.size(); ++row) {
            const std::array<double, 3> actual{axes[row].x, axes[row].y, axes[row].z};
            for (std::size_t column = 0; column < actual.size(); ++column) {
                const double expected = spun(static_cast<int>(row), static_cast<int>(column));
                const double difference = std::abs(actual[column] - expected);
                ++result.components;
                result.maximum_difference = std::max(result.maximum_difference, difference);
                if (!std::isfinite(actual[column]) || !std::isfinite(expected) || difference > tolerance) {
                    std::ostringstream message;
                    message << std::setprecision(17) << "rotation reference mismatch: planet=" << planet
                            << ", JD=" << jd << ", row=" << row << ", column=" << column
                            << ", actual=" << actual[column] << ", expected=" << expected
                            << ", difference=" << difference << ", tolerance=" << tolerance;
                    throw std::runtime_error(message.str());
                }
            }
        }
    }
}

void compare_interval(double first, double last, double tolerance, Comparison& result) {
    for (int sample = 0; sample <= 200; ++sample) {
        // 最後の値を直接渡し、丸めで API の上端を越えないようにする。
        const double jd = sample == 200 ? last : first + (last - first) * (sample / 200.0);
        compare_date(jd, tolerance, result);
    }
}

void dump_basis(const matrix3d& basis) {
    std::cout << "{{" << basis.m11 << ',' << basis.m12 << ',' << basis.m13 << "},{"
              << basis.m21 << ',' << basis.m22 << ',' << basis.m23 << "},{"
              << basis.m31 << ',' << basis.m32 << ',' << basis.m33 << "}}\n";
}

void dump_reference_values() {
    std::cout << std::setprecision(17);
    for (int planet = 0; planet < 9; ++planet) {
        matrix3d unspun;
        matrix3d spun;
        calc_planet_ec_to_pl_matrix(planet, 2451545.0, unspun, spun);
        // 基準値の生成は新コアの回転・座標変換に依存させない。
        const auto north = Rx3deg(epsJ2000) * vector3d(spun.m31, spun.m32, spun.m33);
        double ra = std::atan2(north.y, north.x) * R2D;
        if (ra < 0) ra += 360;
        const double dec = std::atan2(north.z, std::hypot(north.x, north.y)) * R2D;
        std::cout << "J2000 planet " << planet << " north RA/DEC {" << ra << ',' << dec << '}';
        if (planet == 2) std::cout << " (RA is indeterminate at the pole)";
        std::cout << "\nbasis ";
        dump_basis(spun);
    }

    constexpr double date = 2461342.5; // 2026-10-29 00:00。
    matrix3d unspun;
    matrix3d spun;
    calc_planet_ec_to_pl_matrix(2, date, unspun, spun);
    std::cout << "2026-10-29 JD " << date << " Earth basis ";
    dump_basis(spun);
}
} // namespace

int main(int argc, char** argv) {
    try {
        if (argc == 2 && std::string_view(argv[1]) == "--dump") {
            dump_reference_values();
            return 0;
        }
        if (argc != 1) {
            std::cerr << "Usage: test_rotation_upstream [--dump]\n";
            return 2;
        }
        Comparison epoch;
        compare_date(2451545.0, 2e-14, epoch);

        // 元実装は巨大な角度を度から rad に直接変換する。新実装での 360 度還元と
        // 演算順の違いを許容する値であり、姿勢モデルの観測精度を表してはいない。
        Comparison modern;
        compare_interval(mitaka::julian_date({1700,1,1,0,0,0}),
                         mitaka::julian_date({2100,1,1,0,0,0}), 2e-9, modern);

        Comparison supported;
        const double first = mitaka::julian_date({-4712,1,1,0,0,0});
        const double last = std::nextafter(5373484.5, -std::numeric_limits<double>::infinity());
        compare_interval(first, last, 5e-8, supported);
        for (const double offset : {-36525.25, -1.0, -1.0 / 86400.0, 1.0 / 86400.0, 1.0, 36525.25}) {
            compare_date(2451545.0 + offset, 2e-9, modern);
        }

        std::cout << std::setprecision(12)
                  << "rotation reference: " << epoch.components + modern.components + supported.components
                  << " components passed; maximum differences: J2000=" << epoch.maximum_difference
                  << ", 1700..2100=" << modern.maximum_difference
                  << ", supported range=" << supported.maximum_difference << '\n';
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
