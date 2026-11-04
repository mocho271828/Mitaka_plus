#include "grid_geometry.hpp"

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
void expect(bool condition, const char* message) {
    if (!condition) { std::cerr << message << '\n'; std::exit(1); }
}
void near(double actual, double expected, double tolerance, const char* message) {
    expect(std::isfinite(actual) && std::abs(actual - expected) <= tolerance, message);
}
void near_vector(Vec3 actual, Vec3 expected, const char* message) {
    near(actual.x, expected.x, 2e-12, message);
    near(actual.y, expected.y, 2e-12, message);
    near(actual.z, expected.z, 2e-12, message);
}
template<class Exception = std::invalid_argument, class Callable>
void rejects(Callable action) {
    try { action(); }
    catch (const Exception&) { return; }
    expect(false, "expected the documented exception");
}
void grid_contract(const CoordinateGrid& grid, std::size_t meridians) {
    expect(grid.size() == (meridians ? meridians + 11 : 1), "missing or duplicate grid lines");
    for (std::size_t index = 0; index < grid.size(); ++index) {
        const auto& line = grid[index];
        expect(line.size() == (index < meridians ? 91 : 181), "incorrect 2-degree sampling");
        for (const auto point : line) {
            expect(std::isfinite(point.right_ascension_deg) && point.right_ascension_deg >= 0
                   && point.right_ascension_deg < 360, "invalid right ascension in grid");
            expect(std::isfinite(point.declination_deg) && std::abs(point.declination_deg) <= 90,
                   "invalid declination in grid");
        }
        if (index >= meridians) {
            expect(line.front().right_ascension_deg == line.back().right_ascension_deg
                   && line.front().declination_deg == line.back().declination_deg,
                   "closed grid circle has an open seam");
            const auto previous = equatorial_direction(line[line.size() - 2]);
            const auto closure = equatorial_direction(line.back());
            const double chord = std::hypot(std::hypot(previous.x - closure.x, previous.y - closure.y),
                                            previous.z - closure.z);
            expect(chord > 0.001 && chord < 0.036, "seam must close with one ordinary sampling step");
        }
    }
}

void equatorial_and_ecliptic_tests(const ObservationFrame& frame) {
    const auto equatorial = make_coordinate_grid(GridCoordinateSystem::equatorial, frame);
    grid_contract(equatorial, 12);
    near(equatorial[3][45].right_ascension_deg, 90, 0, "RA meridians must be 30 degrees apart");
    near(equatorial[3][45].declination_deg, 0, 0, "meridian must pass through the equator");
    near(equatorial[12].front().declination_deg, -75, 0, "southern latitude missing");
    near(equatorial.back().front().declination_deg, 75, 0, "northern latitude missing");
    for (std::size_t index = 0; index < 12; ++index) {
        near_vector(equatorial_direction(equatorial[index].front()), {0, 0, -1}, "south pole missing");
        near_vector(equatorial_direction(equatorial[index].back()), {0, 0, 1}, "north pole missing");
    }

    const auto ecliptic = make_coordinate_grid(GridCoordinateSystem::ecliptic, frame);
    grid_contract(ecliptic, 0);
    near(ecliptic[0][0].right_ascension_deg, 0, 1e-12, "vernal equinox RA mismatch");
    near(ecliptic[0][0].declination_deg, 0, 1e-12, "vernal equinox DEC mismatch");
    near(ecliptic[0][45].right_ascension_deg, 90, 1e-12, "northern solstice RA mismatch");
    near(ecliptic[0][45].declination_deg, j2000_obliquity_deg, 1e-12, "J2000 obliquity mismatch");
    near(ecliptic[0][90].right_ascension_deg, 180, 1e-12, "autumnal equinox RA mismatch");
    near(ecliptic[0][135].declination_deg, -j2000_obliquity_deg, 1e-12, "southern solstice DEC mismatch");
    for (const auto point : ecliptic[0])
        near(j2000_equatorial_to_ecliptic(equatorial_direction(point)).z, 0, 1e-12,
             "ecliptic grid must stay on one great circle");
}

void galactic_tests(const ObservationFrame& frame) {
    const EquatorialCoordinates center{266.41682625, -29.007796944444443};
    const EquatorialCoordinates north{192.85, 27.133333333333333};
    near_vector(galactic_to_j2000_equatorial({1, 0, 0}), equatorial_direction(center),
                "Galactic origin must share the Milky Way image center");
    near_vector(galactic_to_j2000_equatorial({0, 0, 1}), equatorial_direction(north),
                "Galactic pole must share the Milky Way image pole");
    near_vector(j2000_equatorial_to_galactic(equatorial_direction(center)), {1, 0, 0},
                "inverse Galactic origin mismatch");
    near_vector(j2000_equatorial_to_galactic(equatorial_direction(north)), {0, 0, 1},
                "inverse Galactic pole requires the actual inverse, not the transpose");
    for (const Vec3 vector : {Vec3{0, 0, 0}, Vec3{1, 2, -3}, Vec3{-4, 0.5, 2}}) {
        near_vector(j2000_equatorial_to_galactic(galactic_to_j2000_equatorial(vector)), vector,
                    "non-unit vector round trip must preserve scale and direction");
        near_vector(galactic_to_j2000_equatorial(j2000_equatorial_to_galactic(vector)), vector,
                    "reverse Galactic round trip failed");
    }
    const auto galactic = make_coordinate_grid(GridCoordinateSystem::galactic, frame);
    grid_contract(galactic, 12);
    near(galactic[0][45].right_ascension_deg, center.right_ascension_deg, 1e-10, "Galactic grid center RA mismatch");
    near(galactic[0][45].declination_deg, center.declination_deg, 1e-10, "Galactic grid center DEC mismatch");
    for (std::size_t index = 0; index < 12; ++index)
        near_vector(equatorial_direction(galactic[index].back()), equatorial_direction(north),
                    "Galactic meridians must meet at the Galactic north pole");
}

void horizontal_tests() {
    for (const ObserverSite site : {ObserverSite{35.68, 139.76}, ObserverSite{90, -180}, ObserverSite{-90, 180}}) {
        for (const double jd : {2451545.0, 2461041.5}) {
            const ObservationFrame frame(site, jd);
            const auto horizontal = make_coordinate_grid(GridCoordinateSystem::horizontal, frame);
            grid_contract(horizontal, 8);
            for (std::size_t index = 0; index < 8; ++index) {
                const auto cardinal = frame.to_horizontal(horizontal[index][45]);
                near(std::remainder(cardinal.azimuth_deg - index * 45.0, 360), 0, 1e-10,
                     "horizontal meridian has the wrong true-north/east orientation");
                near(cardinal.altitude_deg, 0, 1e-10, "horizontal meridian must cross the horizon");
                near(frame.to_horizontal(horizontal[index].front()).altitude_deg, -90, 1e-10, "nadir missing");
                near(frame.to_horizontal(horizontal[index].back()).altitude_deg, 90, 1e-10, "zenith missing");
            }
            for (std::size_t index = 8; index < horizontal.size(); ++index)
                for (const auto point : horizontal[index])
                    near(frame.to_horizontal(point).altitude_deg, -75 + (index - 8) * 15.0, 1e-10,
                         "altitude circles must use the supplied observation frame");
        }
    }
    const ObservationFrame first({35, 135}, 2451545), later({35, 135}, 2451545.25);
    const auto before = make_coordinate_grid(GridCoordinateSystem::horizontal, first)[0][45];
    const auto after = make_coordinate_grid(GridCoordinateSystem::horizontal, later)[0][45];
    expect(std::abs(std::remainder(after.right_ascension_deg - before.right_ascension_deg, 360)) > 10,
           "horizontal grid must change with time");
    for (const auto system : {GridCoordinateSystem::equatorial, GridCoordinateSystem::ecliptic, GridCoordinateSystem::galactic}) {
        const auto a = make_coordinate_grid(system, first), b = make_coordinate_grid(system, later);
        for (std::size_t line = 0; line < a.size(); ++line)
            for (std::size_t point = 0; point < a[line].size(); ++point)
                expect(a[line][point].right_ascension_deg == b[line][point].right_ascension_deg
                       && a[line][point].declination_deg == b[line][point].declination_deg,
                       "fixed J2000 grids must not precess with the observing date");
    }
}

void invalid_tests(const ObservationFrame& frame) {
    rejects([&] { make_coordinate_grid(static_cast<GridCoordinateSystem>(99), frame); });
    const double nan = std::numeric_limits<double>::quiet_NaN(), inf = std::numeric_limits<double>::infinity();
    for (const Vec3 vector : {Vec3{nan, 0, 0}, Vec3{0, inf, 0}, Vec3{0, 0, -inf}}) {
        rejects([&] { galactic_to_j2000_equatorial(vector); });
        rejects([&] { j2000_equatorial_to_galactic(vector); });
    }
    const double large = std::numeric_limits<double>::max();
    rejects<std::out_of_range>([&] { galactic_to_j2000_equatorial({large, -large, -large}); });
}
} // namespace

int main() {
    const ObservationFrame frame({35.68, 139.76}, 2451545);
    equatorial_and_ecliptic_tests(frame);
    galactic_tests(frame);
    horizontal_tests();
    invalid_tests(frame);
    std::cout << "grid geometry tests passed\n";
}
