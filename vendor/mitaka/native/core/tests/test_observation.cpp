#include "mitaka/observation.hpp"
#include "mitaka/rotation.hpp"

#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>

namespace {
int checks = 0;

void expect(bool condition, const std::string& label) {
    ++checks;
    if (!condition) throw std::runtime_error(label);
}

void near(double actual, double expected, double tolerance, const std::string& label) {
    expect(std::isfinite(actual) && std::abs(actual - expected) <= tolerance,
           label + ": actual=" + std::to_string(actual) + ", expected=" + std::to_string(expected));
}

void same_direction(mitaka::EquatorialCoordinates first, mitaka::EquatorialCoordinates second,
                    const std::string& label) {
    const auto a = mitaka::equatorial_direction(first), b = mitaka::equatorial_direction(second);
    near(a.x, b.x, 2e-14, label + ".x");
    near(a.y, b.y, 2e-14, label + ".y");
    near(a.z, b.z, 2e-14, label + ".z");
}

template<class Exception, class Action>
void throws(Action action, const std::string& label) {
    try { action(); }
    catch (const Exception&) { ++checks; return; }
    throw std::runtime_error(label + ": expected exception");
}

void test_cardinal_directions() {
    using namespace mitaka;
    // J2000 では地球姿勢の歳差が恒等変換になる。Greenwich の東方向を独立に検証。
    constexpr double spin = 360 * 0.7790572732640;
    const ObservationFrame equator({0, 0}, 2451545);
    const auto zenith = equator.to_horizontal({spin, 0});
    near(zenith.altitude_deg, 90, 1e-12, "equatorial zenith");
    near(zenith.azimuth_deg, 0, 0, "undefined zenith azimuth convention");
    const auto east = equator.to_horizontal({spin + 90, 0});
    near(east.azimuth_deg, 90, 1e-12, "east sign");
    near(east.altitude_deg, 0, 1e-12, "east horizon");
    const auto west = equator.to_horizontal({spin - 90, 0});
    near(west.azimuth_deg, 270, 1e-12, "west sign");
    near(west.altitude_deg, 0, 1e-12, "west horizon");
    const auto north = equator.to_horizontal({0, 90});
    near(north.azimuth_deg, 0, 1e-12, "celestial pole north");
    near(north.altitude_deg, 0, 1e-12, "celestial pole on equatorial horizon");
    const auto below = equator.to_horizontal({spin + 180, 0});
    near(below.altitude_deg, -90, 1e-12, "nadir retained");
    const auto east_site = equatorial_to_horizontal({spin + 135, 35}, {35, 135}, 2451545);
    near(east_site.altitude_deg, 90, 1e-12, "east longitude convention");
    const auto north_pole = equatorial_to_horizontal({0, 90}, {35, 0}, 2451545);
    near(north_pole.altitude_deg, 35, 1e-12, "pole altitude equals latitude");
}

void test_roundtrips() {
    using namespace mitaka;
    const std::array<ObserverSite, 7> sites{{{0, 0}, {35.68, 139.76}, {-33.86, 151.21},
                                          {90, 0}, {-90, 75}, {45, -180}, {45, 180}}};
    const std::array<double, 6> dates{{julian_date({-4712,1,1,0,0,0}), 2415020.5,
                                      2451545, 2460000.5, 2488069.5,
                                      julian_date({9999,12,31,0,0,0})}};
    const std::array<EquatorialCoordinates, 7> directions{{{0,0}, {359.99,45}, {90,-35},
                                                          {123,90}, {270,-90}, {180,89.9}, {27,-89.9}}};
    for (const auto site : sites) for (double date : dates) {
        const ObservationFrame frame(site, date);
        for (const auto input : directions) {
            const auto horizon = frame.to_horizontal(input);
            expect(horizon.azimuth_deg >= 0 && horizon.azimuth_deg < 360, "normalized azimuth");
            expect(horizon.altitude_deg >= -90 && horizon.altitude_deg <= 90, "bounded altitude");
            same_direction(frame.to_equatorial(horizon), input, "direction roundtrip");
        }
        for (const auto input : {HorizontalCoordinates{0, 0}, {90, 23}, {180, -45}, {270, 89.99}}) {
            const auto output = frame.to_horizontal(frame.to_equatorial(input));
            near(std::remainder(output.azimuth_deg - input.azimuth_deg, 360), 0, 2e-10,
                 "horizontal azimuth roundtrip");
            near(output.altitude_deg, input.altitude_deg, 1e-12, "horizontal altitude roundtrip");
        }
        for (double altitude : {-90.0, 90.0}) {
            const auto output = frame.to_horizontal(frame.to_equatorial({234, altitude}));
            near(output.azimuth_deg, 0, 0, "vertical azimuth stable");
            near(output.altitude_deg, altitude, 1e-12, "vertical altitude stable");
        }
        const auto pole = equatorial_coordinates(j2000_ecliptic_to_equatorial(
                                                 planet_orientation(Planet::earth, date).north_axis));
        near(frame.to_horizontal(pole).altitude_deg, site.latitude_deg, 1e-12,
             "precessed north pole tracks latitude");
    }
    same_direction(horizontal_to_equatorial({45, 30}, {35, 139}, 2460000),
                   ObservationFrame({35,139}, 2460000).to_equatorial({45,30}), "convenience API");
}

void test_sidereal_time() {
    using namespace mitaka;
    // USNO 式の J2000 UT1 12h。時刻系変換を含む観測値ではない。
    near(greenwich_mean_sidereal_time_deg(2451545), 280.4606233179075, 1e-11, "J2000 GMST");
    near(local_mean_sidereal_time_deg(2451545, 135), 55.4606233179075, 1e-11, "east local mean sidereal");
    near(local_mean_sidereal_time_deg(2451545, -135), 145.4606233179075, 1e-11, "west local mean sidereal");
    near(local_mean_sidereal_time_deg(2451545, -180),
         local_mean_sidereal_time_deg(2451545, 180), 1e-12, "date line same meridian");
    const auto before = greenwich_mean_sidereal_time_deg(2460000.5 - 1e-6);
    const auto after = greenwich_mean_sidereal_time_deg(2460000.5 + 1e-6);
    near(std::remainder(after - before, 360), 360.985647 * 2e-6, 0.00003,
         "midnight approximation continuous within formula rounding");
}

void test_invalid_input() {
    using namespace mitaka;
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double infinity = std::numeric_limits<double>::infinity();
    for (const auto site : {ObserverSite{91,0}, {-91,0}, {0,181}, {0,-181}, {nan,0}, {0,infinity}})
        throws<std::invalid_argument>([=]{ObservationFrame frame(site, 2451545);}, "invalid site");
    for (double time : {nan, infinity}) {
        throws<std::invalid_argument>([=]{ObservationFrame frame({0,0}, time);}, "invalid JD");
        throws<std::invalid_argument>([=]{greenwich_mean_sidereal_time_deg(time);}, "invalid sidereal JD");
    }
    for (double time : {-1e10, 5373484.5}) {
        throws<std::out_of_range>([=]{ObservationFrame frame({0,0}, time);}, "out of range JD");
        throws<std::out_of_range>([=]{greenwich_mean_sidereal_time_deg(time);}, "out of range sidereal JD");
    }
    const ObservationFrame frame({0,0}, 2451545);
    for (const auto value : {HorizontalCoordinates{nan,0}, {0,nan}, {0,91}, {0,-91}})
        throws<std::invalid_argument>([&]{frame.to_equatorial(value);}, "invalid horizon");
    for (const auto value : {EquatorialCoordinates{nan,0}, {0,nan}, {0,91}, {0,-91}})
        throws<std::invalid_argument>([&]{frame.to_horizontal(value);}, "invalid equatorial");
    throws<std::invalid_argument>([]{local_mean_sidereal_time_deg(2451545,181);}, "invalid sidereal longitude");
}
} // namespace

int main() {
    try {
        test_cardinal_directions();
        test_roundtrips();
        test_sidereal_time();
        test_invalid_input();
        std::cout << "observation: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "observation test failure: " << error.what() << '\n';
        return 1;
    }
}
