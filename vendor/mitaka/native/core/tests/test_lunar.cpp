#include "mitaka/lunar.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <iomanip>
#include <iostream>
#include <limits>
#include <sstream>
#include <stdexcept>
#include <string>

namespace {
int checks = 0;
constexpr double pi = 3.14159265358979323846;

void expect(bool condition, const std::string& label) {
    ++checks;
    if (!condition) throw std::runtime_error(label);
}

void near(double actual, double expected, double tolerance, const std::string& label) {
    if (std::isfinite(actual) && std::abs(actual-expected) <= tolerance) {
        ++checks;
        return;
    }
    std::ostringstream message;
    message << std::setprecision(17) << label << ": actual=" << actual
            << ", expected=" << expected << ", difference=" << std::abs(actual-expected)
            << ", tolerance=" << tolerance;
    expect(false, message.str());
}

void near(mitaka::Vec3 actual, mitaka::Vec3 expected, double tolerance, const std::string& label) {
    near(actual.x, expected.x, tolerance, label + ".x");
    near(actual.y, expected.y, tolerance, label + ".y");
    near(actual.z, expected.z, tolerance, label + ".z");
}

template<class Exception, class Action>
void throws(Action action, const std::string& label) {
    try { action(); }
    catch (const Exception&) { ++checks; return; }
    throw std::runtime_error(label + ": expected exception");
}

double dot(mitaka::Vec3 a, mitaka::Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }
double length(mitaka::Vec3 v) { return std::sqrt(dot(v,v)); }

mitaka::Vec3 cross(mitaka::Vec3 a, mitaka::Vec3 b) {
    return {a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x};
}

void test_range_and_basis() {
    using namespace mitaka;
    const Vec3 direction{0.25,-0.75,0.125};
    for (int sample = 0; sample <= 1000; ++sample) {
        const double jd = lunar_minimum_jd + (lunar_maximum_jd-lunar_minimum_jd)*(sample/1000.0);
        const auto position = lunar_position(jd);
        expect(length(position) > 0.0022 && length(position) < 0.0029, "geocentric distance in AU");
        const auto basis = lunar_orientation(jd);
        const auto x = basis.x_axis, y = basis.y_axis, z = basis.north_axis;
        near(dot(x,x), 1, 2e-15, "unit X");
        near(dot(y,y), 1, 2e-15, "unit Y");
        near(dot(z,z), 1, 2e-15, "unit north");
        near(dot(x,y), 0, 2e-15, "orthogonal XY");
        near(dot(y,z), 0, 2e-15, "orthogonal YZ");
        near(dot(z,x), 0, 2e-15, "orthogonal ZX");
        near(cross(x,y), z, 2e-15, "right handed");
        const Vec3 local{dot(direction,x),dot(direction,y),dot(direction,z)};
        near({local.x*x.x+local.y*y.x+local.z*z.x,
              local.x*x.y+local.y*y.y+local.z*z.y,
              local.x*x.z+local.y*y.z+local.z*z.z}, direction, 2e-15, "basis roundtrip");
        // 位置と姿勢を同時刻・同座標へそろえる。近側の X 軸が地球方向から大きく外れない。
        const auto ecliptic = j2000_equatorial_to_ecliptic(position);
        expect(-dot(ecliptic,x)/length(ecliptic) > 0.94, "near side faces Earth");
    }
}

void test_libration_and_spin() {
    using namespace mitaka;
    double minimum_longitude = 180, maximum_longitude = -180;
    double minimum_latitude = 90, maximum_latitude = -90;
    for (int day = 0; day <= 90; ++day) {
        const double jd = 2451545.0 + day;
        const auto basis = lunar_orientation(jd);
        const auto position = j2000_equatorial_to_ecliptic(lunar_position(jd));
        const double x = -dot(position,basis.x_axis), y = -dot(position,basis.y_axis);
        const double z = -dot(position,basis.north_axis);
        const double longitude = std::atan2(y,x)*180/pi;
        const double latitude = std::atan2(z,std::hypot(x,y))*180/pi;
        minimum_longitude = std::min(minimum_longitude,longitude);
        maximum_longitude = std::max(maximum_longitude,longitude);
        minimum_latitude = std::min(minimum_latitude,latitude);
        maximum_latitude = std::max(maximum_latitude,latitude);
        const auto later = lunar_orientation(jd+0.01);
        const double spin = std::atan2(dot(later.x_axis,basis.y_axis),
                                       dot(later.x_axis,basis.x_axis))*180/pi/0.01;
        expect(spin > 12 && spin < 14, "prograde lunar spin in degrees per day");
    }
    // 見かけの秤動は視線と月固定基底の合成で現れ、一定の地球向き姿勢ではない。
    expect(minimum_longitude < -4 && maximum_longitude > 4, "longitude libration varies");
    expect(minimum_latitude < -4 && maximum_latitude > 4, "latitude libration varies");
    expect(minimum_longitude > -12 && maximum_longitude < 12, "longitude libration bounded");
    expect(minimum_latitude > -10 && maximum_latitude < 10, "latitude libration bounded");
}

void test_invalid_inputs() {
    using namespace mitaka;
    for (double jd : {std::nextafter(lunar_minimum_jd,0.0),
                      std::nextafter(lunar_maximum_jd,std::numeric_limits<double>::infinity()),
                      -std::numeric_limits<double>::max(), std::numeric_limits<double>::max()}) {
        throws<std::out_of_range>([&]{lunar_position(jd);}, "position range");
        throws<std::out_of_range>([&]{lunar_orientation(jd);}, "orientation range");
    }
    for (double jd : {std::numeric_limits<double>::quiet_NaN(),
                      std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity()}) {
        throws<std::invalid_argument>([&]{lunar_position(jd);}, "position non-finite date");
        throws<std::invalid_argument>([&]{lunar_orientation(jd);}, "orientation non-finite date");
    }
    near(earth_moon_mass_ratio,81.30057,0,"official Earth Moon mass ratio");
}

void test_upstream_fixtures() {
    using namespace mitaka;
    struct Fixture { double jd; std::array<Vec3,2> positions; BodyOrientation orientation; };
    // 未変更の公式位置関数と、原本から本文のまま抽出した姿勢関数の出力。
    // 再生成方法は LUNAR_PROVENANCE.md を参照。新コアを期待値生成に使わない。
    const std::array<Fixture,4> fixtures{{
        {2415020.5,
         {{{0.00016353511842929789,-0.0022715366457242976,-0.00093358837226923503},
           {0.00016353511843153116,-0.0022715366457242377,-0.00093358837226900095}}},
         {{-0.14621818255626562,0.98922109267599878,0.0078659325477374656},
          {-0.98890318779541764,-0.14637319751815603,0.025404177144160742},
          {0.026281709571555793,-0.0040640931600847514,0.99964631489781552}}},
        {2451545.0,
         {{{-0.0019487158434038107,-0.0017826753996118328,-0.00050866105949668491},
           {-0.001948715843403804,-0.001782675399611827,-0.00050866105949668209}}},
         {{0.7842270520919169,0.61987147459511771,0.027336527769559568},
          {-0.62006191525085563,0.78455064114534268,-0.0018742288740515019},
          {-0.022608671404182476,-0.015480518780258259,0.99962453026905651}}},
        {2461342.5,
         {{{0.00068081714196286433,0.0020562891351227899,0.0011145543535771747},
           {0.00068081714196285294,0.0020562891351227543,0.0011145543535771561}}},
         {{-0.28100378937384857,-0.95937316124961902,0.02529837606349453},
          {0.95959366874833041,-0.28127755760201356,-0.0079326217334050562},
          {0.014726209819811228,0.022047064733387516,0.99964847105419252}}},
        {2487980.5,
         {{{0.0013329808753983834,0.0020144422400323317,0.0011136831814718244},
           {0.0013329808753899234,0.0020144422400365796,0.0011136831814736795}}},
         {{-0.41479082038731951,-0.90954965908181784,0.025845560287275578},
          {0.90991361367103074,-0.4146971294847267,0.0091381865407639627},
          {0.002406445208279713,0.027307663050443246,0.99962417965962735}}}
    }};
    for (const auto& fixture : fixtures) {
        const bool at_epoch = fixture.jd == 2451545.0;
        const auto position = lunar_position(fixture.jd);
        const auto maximum_error = [&](Vec3 reference) {
            return std::max({std::abs(position.x-reference.x),std::abs(position.y-reference.y),
                             std::abs(position.z-reference.z)});
        };
        // 原本の縮約積和 / 非縮約積和を独立採取した値。三成分は必ず同じ profile と比較する。
        const auto profile = maximum_error(fixture.positions[0]) <= maximum_error(fixture.positions[1]) ? 0 : 1;
        std::ostringstream label;
        label << std::setprecision(17) << "original position JD=" << fixture.jd << " profile=" << profile;
        near(position,fixture.positions[profile],at_epoch ? 2e-17 : 2e-15,label.str());
        const auto basis = lunar_orientation(fixture.jd);
        const double tolerance = at_epoch ? 2e-14 : 1e-11;
        near(basis.x_axis,fixture.orientation.x_axis,tolerance,"original X");
        near(basis.y_axis,fixture.orientation.y_axis,tolerance,"original Y");
        near(basis.north_axis,fixture.orientation.north_axis,tolerance,"original north");
    }
}
} // namespace

int main() {
    try {
        test_range_and_basis();
        test_libration_and_spin();
        test_invalid_inputs();
        test_upstream_fixtures();
        std::cout << "lunar: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
