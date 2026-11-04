#include "mitaka/astronomy.hpp"

#include <array>
#include <cmath>
#include <iostream>
#include <limits>
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
    expect(std::isfinite(actual) && std::abs(actual - expected) <= tolerance,
           label + ": actual=" + std::to_string(actual) + ", expected=" + std::to_string(expected));
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

double norm(mitaka::Vec3 v) { return std::hypot(std::hypot(v.x, v.y), v.z); }

void test_calendar() {
    using namespace mitaka;
    near(julian_date({2000,1,1,12,0,0}), 2451545.0, 0, "J2000 noon");
    near(julian_date({1970,1,1,0,0,0}), 2440587.5, 0, "Unix epoch");
    near(julian_date({1,1,1,0,0,0}), 1721425.5, 0, "year one");
    near(julian_date({2000,3,1,0,0,0}) - julian_date({2000,2,28,0,0,0}), 2, 0, "Gregorian leap");
    near(julian_date({1900,3,1,0,0,0}) - julian_date({1900,2,28,0,0,0}), 1, 0, "Gregorian century");
    for (int year : {-4712, -4000, -1, 0, 1, 1582, 1900, 2000, 2026, 9999}) {
        for (int month = 1; month <= 12; ++month) {
            for (int day : {1, 15, 28}) {
                const GregorianDateTime input{year,month,day,23,59,12.345};
                const double jd = julian_date(input);
                const auto date = gregorian_date_time(jd);
                expect(date.year == year && date.month == month && date.day == day &&
                       date.hour == 23 && date.minute == 59, "calendar roundtrip fields");
                near(date.second, input.second, 1e-4, "calendar roundtrip second");
                near(julian_date(date), jd, 1e-9, "calendar JD roundtrip");
            }
        }
    }
    throws<std::invalid_argument>([]{julian_date({1900,2,29,0,0,0});}, "invalid leap day");
    throws<std::invalid_argument>([]{julian_date({2000,1,1,0,0,60});}, "leap second unsupported");
    throws<std::invalid_argument>([]{julian_date({2000,13,1,0,0,0});}, "invalid month");
    throws<std::out_of_range>([]{gregorian_date_time(5373484.5);}, "upper date boundary");
}

void test_orbits() {
    using namespace mitaka;
    OrbitalElements orbit{2451545.0, 1, 0, 0, 360.0 / 365.25, 0, 0, 0};
    const auto start = orbital_state(orbit, orbit.epoch_jd);
    near(start.position_au, {1,0,0}, 1e-14, "circular start");
    near(start.velocity_au_per_day, {0,2*pi/365.25,0}, 1e-14, "circular velocity");
    near(orbital_state(orbit, orbit.epoch_jd + 365.25/4).position_au, {0,1,0}, 1e-14, "quarter orbit");
    near(orbital_state(orbit, orbit.epoch_jd - 365.25/4).position_au, {0,-1,0}, 1e-14, "negative time");
    near(orbital_state(orbit, orbit.epoch_jd + 365.25*100000).position_au, {1,0,0}, 1e-10, "many revolutions");
    orbit.inclination_deg = 90;
    near(orbital_state(orbit, orbit.epoch_jd + 365.25/4).position_au, {0,0,1}, 1e-14, "reference rotation");
    orbit = {2451545, 2, 0.7, 0, 1, 12, 34, 56};
    for (double eccentricity : {0.0, 0.7, 0.999999, 1.000001, 1.5, 10.0}) {
        orbit.eccentricity = eccentricity;
        for (double days : {-1000.0, -0.0001, 0.0, 0.0001, 1000.0}) {
            const auto state = orbital_state(orbit, orbit.epoch_jd + days);
            const double radius = norm(state.position_au);
            const double speed = norm(state.velocity_au_per_day);
            const double mu = std::pow(orbit.mean_motion_deg_per_day * pi / 180, 2) *
                              std::pow(orbit.semi_major_axis_au, 3);
            const double expected_energy = (eccentricity < 1 ? -1 : 1) * mu / (2 * orbit.semi_major_axis_au);
            near(speed*speed/2 - mu/radius, expected_energy, 2e-7, "Kepler energy invariant");
            const double step = 0.001;
            if (std::abs(eccentricity-1.0) > 0.01) {
                const auto before = orbital_state(orbit, orbit.epoch_jd + days - step).position_au;
                const auto after = orbital_state(orbit, orbit.epoch_jd + days + step).position_au;
                const Vec3 difference{(after.x-before.x)/(2*step), (after.y-before.y)/(2*step),
                                      (after.z-before.z)/(2*step)};
                near(state.velocity_au_per_day, difference, 2e-8, "position derivative");
            }
        }
    }
    orbit.eccentricity = 1;
    throws<std::invalid_argument>([&]{orbital_state(orbit, 2451545);}, "parabolic rejection");
    orbit.eccentricity = -2;
    throws<std::invalid_argument>([&]{orbital_state(orbit, 2451545);}, "repulsive rejection");
    orbit.eccentricity = 0;
    orbit.semi_major_axis_au = 0;
    throws<std::invalid_argument>([&]{orbital_state(orbit, 2451545);}, "zero axis rejection");
    throws<std::invalid_argument>([]{mean_planet_state(Planet::earth, std::numeric_limits<double>::quiet_NaN());}, "NaN rejection");
    throws<std::invalid_argument>([]{mean_planet_elements(static_cast<Planet>(9));}, "invalid planet");
}

void test_official_regression() {
    using namespace mitaka;
    // 原本の cele_mech.cpp と vector3.h を Apple Clang で実行した JD 2451545.0 の値。
    // 元の solver の停止誤差を許容する。生成元とライセンスは ASTRONOMY_PROVENANCE.md 参照。
    const std::array<OrbitalState, 9> original{{
        {{-0.12962828415225977,-0.447425225125201,-0.024619780233975885},{0.021373395519738887,-0.0064244796918684075,-0.0024873055004190473}},
        {{-0.71829521537928842,-0.03316175044972796,0.041014009848419741},{0.00081172890823552341,-0.02029424056729465,-0.00032365662868294416}},
        {{-0.17793284951440785,0.96707338544324861,0},{-0.017200614156988869,-0.0031778336941527294,0}},
        {{1.3905982988872569,-0.013029059851099917,-0.03446301834957332},{0.00066776334712844799,0.015188637299404666,0.00030161413718311151}},
        {{3.9942178369330144,2.9509510923075735,-0.10156474334750508},{-0.0045762259808869521,0.0064283168032557075,7.5720175853228057e-05}},
        {{6.4094111433661958,6.562597235409477,-0.36972227039581756},{-0.0042931981130227741,0.0038797251064844108,0.00010311786973980014}},
        {{14.649333934561666,-13.507102811751665,-0.24024422325124412},{0.0026404535657149953,0.0027072314718711767,-2.4200607082707681e-05}},
        {{16.597328492922582,-25.206773081953653,0.1370937134940205},{0.0025953214979455514,0.0017426926014729816,-9.566249302225359e-05}},
        {{-10.231361825453279,-27.817664942553595,5.9447304208544169},{0.0030190712834633417,-0.0015758161566637357,-0.00070407256596811605}}
    }};
    for (std::size_t index = 0; index < original.size(); ++index) {
        const auto state = mean_planet_state(static_cast<Planet>(index), 2451545.0);
        near(state.position_au, original[index].position_au, 4e-7, "official mean position");
        near(state.velocity_au_per_day, original[index].velocity_au_per_day, 1e-9, "official mean velocity");
    }
    const auto transformed = b1950_to_j2000({123.4,-35.6}, {0.1,-0.4,25,0.02});
    near(transformed.right_ascension_deg, 123.87442016601562, 2e-5, "official B1950 RA");
    // 原本 RA_DEC::set_dirc_vec は南天の DEC に 360 度を加えるため、契約に合わせて正規化。
    near(transformed.declination_deg, 324.24575805664062 - 360, 2e-5, "official B1950 DEC");
}

void test_coordinates() {
    using namespace mitaka;
    for (const auto coordinates : {EquatorialCoordinates{0,0}, {120,-35}, {270,89.9}, {45,-89.9}}) {
        const auto converted = equatorial_coordinates(equatorial_direction(coordinates));
        near(converted.right_ascension_deg, coordinates.right_ascension_deg, 1e-12, "RA roundtrip");
        near(converted.declination_deg, coordinates.declination_deg, 1e-12, "DEC roundtrip");
    }
    const Vec3 ecliptic{1,2,-3};
    near(j2000_equatorial_to_ecliptic(j2000_ecliptic_to_equatorial(ecliptic)), ecliptic, 1e-14, "J2000 rotation inverse");
    const auto solstice = equatorial_coordinates(j2000_ecliptic_to_equatorial({0,1,0}));
    near(solstice.declination_deg, j2000_obliquity_deg, 1e-12, "obliquity sign");
    const double maximum = std::numeric_limits<double>::max();
    throws<std::out_of_range>([=]{j2000_ecliptic_to_equatorial({0,maximum,maximum});}, "rotation overflow");
    throws<std::out_of_range>([=]{j2000_equatorial_to_ecliptic({0,maximum,maximum});}, "inverse rotation overflow");
    near(equatorial_coordinates({1,-1e-30,0}).right_ascension_deg, 0, 0, "RA upper boundary rounding");
    throws<std::invalid_argument>([]{equatorial_direction({0,91});}, "invalid DEC");
    throws<std::invalid_argument>([]{equatorial_coordinates({0,0,0});}, "zero direction");
}
} // namespace

int main() {
    try {
        test_calendar();
        test_orbits();
        test_official_regression();
        test_coordinates();
        std::cout << "astronomy: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "astronomy test failure: " << error.what() << '\n';
        return 1;
    }
}
