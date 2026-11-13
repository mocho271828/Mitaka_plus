#include "mitaka/rotation.hpp"

#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>

namespace {
int checks = 0;
constexpr double pi = 3.14159265358979323846;
constexpr double epoch = 2451545.0;

void expect(bool condition, const std::string& label) {
    ++checks;
    if (!condition) throw std::runtime_error(label);
}

void near(double actual, double expected, double tolerance, const std::string& label) {
    expect(std::isfinite(actual) && std::abs(actual - expected) <= tolerance,
           label + ": actual=" + std::to_string(actual) + ", expected=" + std::to_string(expected));
}

void near(mitaka::Vec3 actual, mitaka::Vec3 expected, double tolerance, const std::string& label) {
    near(actual.x, expected.x, tolerance, label + ".x");
    near(actual.y, expected.y, tolerance, label + ".y");
    near(actual.z, expected.z, tolerance, label + ".z");
}

void near(mitaka::BodyOrientation actual, mitaka::BodyOrientation expected,
          double tolerance, const std::string& label) {
    near(actual.x_axis, expected.x_axis, tolerance, label + ".X");
    near(actual.y_axis, expected.y_axis, tolerance, label + ".Y");
    near(actual.north_axis, expected.north_axis, tolerance, label + ".north");
}

template<class Exception, class Action>
void throws(Action action, const std::string& label) {
    try { action(); }
    catch (const Exception&) { ++checks; return; }
    throw std::runtime_error(label + ": expected exception");
}

double dot(mitaka::Vec3 a, mitaka::Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }

mitaka::Vec3 cross(mitaka::Vec3 a, mitaka::Vec3 b) {
    return {a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x};
}

void test_orthonormality() {
    using namespace mitaka;
    const double first = julian_date({-4712,1,1,0,0,0});
    const double last = std::nextafter(5373484.5, 0.0);
    const Vec3 direction{0.25, -0.75, 0.125};
    for (int sample = 0; sample <= 100; ++sample) {
        const double jd = sample == 100 ? last : first + (last - first) * (sample / 100.0);
        for (int index = 0; index < 9; ++index) {
            const auto basis = planet_orientation(static_cast<Planet>(index), jd);
            const Vec3 x = basis.x_axis, y = basis.y_axis, z = basis.north_axis;
            near(dot(x,x), 1, 2e-15, "unit X");
            near(dot(y,y), 1, 2e-15, "unit Y");
            near(dot(z,z), 1, 2e-15, "unit north");
            near(dot(x,y), 0, 2e-15, "orthogonal XY");
            near(dot(y,z), 0, 2e-15, "orthogonal YZ");
            near(dot(z,x), 0, 2e-15, "orthogonal ZX");
            near(cross(x,y), z, 2e-15, "right handed");
            const Vec3 local{dot(direction,x), dot(direction,y), dot(direction,z)};
            const Vec3 restored{x.x*local.x + y.x*local.y + z.x*local.z,
                                x.y*local.x + y.y*local.y + z.y*local.z,
                                x.z*local.x + y.z*local.y + z.z*local.z};
            near(restored, direction, 2e-15, "body to world roundtrip");
        }
    }
}

void test_epoch_poles() {
    using namespace mitaka;
    // 公式原本から独立に得た J2000 の値。極の RA が不定な地球はベクトルで確認する。
    const std::array<EquatorialCoordinates, 9> poles{{
        {281.0097, 61.4143}, {272.76, 67.16}, {0, 90}, {317.68143, 52.8865},
        {268.05720404270755, 64.495809953395721}, {40.589, 83.537},
        {257.311, -15.175}, {299.33373895877264, 42.950359021844854}, {132.993, -6.163}
    }};
    for (std::size_t index = 0; index < poles.size(); ++index) {
        const auto basis = planet_orientation(static_cast<Planet>(index), epoch);
        near(j2000_ecliptic_to_equatorial(basis.north_axis),
             equatorial_direction(poles[index]), 2e-15, "J2000 pole");
    }
    const auto earth = planet_orientation(Planet::earth, epoch);
    const double obliquity = j2000_obliquity_deg * pi / 180;
    const double spin = 280.46061837504 * pi / 180;
    near(earth.north_axis, {0, std::sin(obliquity), std::cos(obliquity)}, 1e-15, "Earth tilt");
    near(earth.x_axis, {std::cos(spin), std::sin(spin)*std::cos(obliquity),
                       -std::sin(spin)*std::sin(obliquity)}, 2e-15, "Earth Greenwich at J2000");
}

void test_rotation_direction() {
    using namespace mitaka;
    const std::array<double, 9> rates{6.1385025, -1.4813688, 360.985612288,
        350.89198226, 870.536, 810.7939024, -501.1600928, 536.3128492, 56.3625225};
    for (double jd : {epoch - 36525.0, epoch, epoch + 36525.0}) {
        const double next_jd = jd + 0.02;
        for (std::size_t index = 0; index < rates.size(); ++index) {
            const auto planet = static_cast<Planet>(index);
            const auto before = planet_orientation(planet, jd);
            const auto after = planet_orientation(planet, next_jd);
            const double angle = std::atan2(dot(after.x_axis, before.y_axis),
                                            dot(after.x_axis, before.x_axis));
            const double rate = angle * 180 / pi / (next_jd - jd);
            // 極の歳差・周期項も含む差分なので、W の線形係数には有限の許容差を置く。
            near(rate, rates[index], 0.002, "signed spin rate");
            expect((rate > 0) == (rates[index] > 0), "prograde or retrograde direction");
        }
    }
}

void test_upstream_golden() {
    using namespace mitaka;
    // 公式 Mitaka 1.3.1 の関数を単独でコンパイルして得た固定値。出典は docs/core/ROTATION_PROVENANCE.md を参照。
    near(planet_orientation(Planet::mercury, epoch),
         {{0.93117860203937042,-0.34621274992544016,-0.11420657990268573},
          {0.35292600127964935,0.93459867465463853,0.04436840040558538},
          {0.091376412299678425,-0.081621376629275613,0.99246576875597126}},
         2e-15, "Mercury J2000 original");
    near(planet_orientation(Planet::uranus, epoch),
         {{-0.86933172626840671,0.12398413122896486,-0.47842479545545169},
          {0.44645103553580279,-0.21823204953180667,-0.86778813395099874},
          {-0.21199958153779777,-0.96798900187995207,0.13436320056939968}},
         2e-15, "Uranus J2000 original");
    near(planet_orientation(Planet::earth, julian_date({2026,10,29,0,0,0})),
         {{0.80225950948157476,0.54688107881287729,-0.23937578215610381},
          {-0.59696975389181539,0.73668258033196143,-0.31768835164951925},
          {0.0026062203913662083,0.39776860292374344,0.91748206856775405}},
         2e-11, "Earth precession original");
    const auto past = planet_orientation(Planet::earth, epoch - 36525.0);
    const auto future = planet_orientation(Planet::earth, epoch + 36525.0);
    expect(past.north_axis.x < -0.009 && future.north_axis.x > 0.009, "Earth pole precesses");
}

void test_invalid_inputs() {
    using namespace mitaka;
    const double first = julian_date({-4712,1,1,0,0,0});
    throws<std::out_of_range>([&]{planet_orientation(Planet::earth, std::nextafter(first, -1.0));}, "lower bound");
    throws<std::out_of_range>([]{planet_orientation(Planet::earth, 5373484.5);}, "exclusive upper bound");
    for (double jd : {std::numeric_limits<double>::max(), -std::numeric_limits<double>::max()}) {
        throws<std::out_of_range>([&]{planet_orientation(Planet::neptune, jd);}, "finite out of range");
    }
    for (double jd : {std::numeric_limits<double>::quiet_NaN(),
                      std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity()}) {
        throws<std::invalid_argument>([&]{planet_orientation(Planet::earth, jd);}, "non-finite date");
    }
    for (int planet : {-1, 9, std::numeric_limits<int>::max()}) {
        throws<std::invalid_argument>([&]{planet_orientation(static_cast<Planet>(planet), epoch);}, "invalid planet");
    }
}
} // namespace

int main() {
    try {
        test_orthonormality();
        test_epoch_poles();
        test_rotation_direction();
        test_upstream_golden();
        test_invalid_inputs();
        std::cout << "rotation: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
