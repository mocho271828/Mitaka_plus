#include "sky_model.hpp"
#include "solar_camera.hpp"
#include "mitaka/lunar.hpp"

#include <unistd.h>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <vector>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
using Bytes = std::vector<char>;

void check(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
void near(double actual, double expected, double tolerance = 1e-9) {
    check(std::abs(actual - expected) <= tolerance, "numeric mismatch");
}
void same(Vec3 a, Vec3 b) { near(a.x, b.x); near(a.y, b.y); near(a.z, b.z); }
void check_earth_moon(const SolarBodies& bodies, Vec3 barycenter, double date) {
    const auto earth = bodies[3].position_au;
    const auto moon = bodies[10].position_au;
    // 表示位置から質量重心を再構成し、CF96 の値が保存されることを確認する。
    const double total_mass = earth_moon_mass_ratio + 1;
    same({(earth.x * earth_moon_mass_ratio + moon.x) / total_mass,
          (earth.y * earth_moon_mass_ratio + moon.y) / total_mass,
          (earth.z * earth_moon_mass_ratio + moon.z) / total_mass}, barycenter);
    const Vec3 relative{moon.x - earth.x, moon.y - earth.y, moon.z - earth.z};
    same(relative, lunar_position(date));
    check(std::hypot(relative.x, relative.y, relative.z) > 0.002
          && std::hypot(relative.x, relative.y, relative.z) < 0.003,
          "Moon must stay close to the Earth");
    check(std::hypot(earth.x - barycenter.x, earth.y - barycenter.y,
                     earth.z - barycenter.z) > 1e-5, "Earth must differ from the barycenter");
}
void check_orientations(const SolarBodies& bodies, double date) {
    constexpr std::array<Planet, 9> planets{Planet::mercury, Planet::venus, Planet::earth,
        Planet::mars, Planet::jupiter, Planet::saturn, Planet::uranus, Planet::neptune, Planet::pluto};
    same(bodies[0].orientation.x_axis, {1, 0, 0});
    same(bodies[0].orientation.y_axis, {0, 1, 0});
    same(bodies[0].orientation.north_axis, {0, 0, 1});
    for (std::size_t index = 0; index < planets.size(); ++index) {
        const auto expected = planet_orientation(planets[index], date);
        const auto& actual = bodies[index + 1].orientation;
        same(actual.x_axis, expected.x_axis);
        same(actual.y_axis, expected.y_axis);
        same(actual.north_axis, expected.north_axis);
    }
    const auto moon = lunar_orientation(date);
    same(bodies.back().orientation.x_axis, moon.x_axis);
    same(bodies.back().orientation.y_axis, moon.y_axis);
    same(bodies.back().orientation.north_axis, moon.north_axis);
}
template<typename Exception, typename Function>
void rejects(Function operation) {
    try { operation(); } catch (const Exception&) { return; }
    throw std::runtime_error("expected exception was not raised");
}
void integer(Bytes& bytes, std::uint64_t value, unsigned width = 4) {
    for (unsigned i = 0; i < width; ++i) bytes.push_back(static_cast<char>((value >> (8 * i)) & 255));
}
void real(Bytes& bytes, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(value));
    integer(bytes, bits, 8);
}
void write(const std::filesystem::path& path, const Bytes& bytes) {
    std::ofstream output(path, std::ios::binary);
    output.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
    check(static_cast<bool>(output), "fixture write failed");
}
void fixture(const std::filesystem::path& directory) {
    write(directory / "hip.dat", Bytes(45, 0));
    Bytes bytes{'C', 'F', '9', '6'};
    integer(bytes, 9);
    for (unsigned planet = 0; planet < 9; ++planet) {
        real(bytes, 2451544); real(bytes, 2);
        integer(bytes, 0); integer(bytes, 1); integer(bytes, 1); integer(bytes, 0);
        for (unsigned axis = 0; axis < 3; ++axis) {
            integer(bytes, 2);
            real(bytes, (planet + 1.0) * (axis + 1.0) * 1e10);
            real(bytes, 0.1e10 * (axis + 1));
            integer(bytes, 1); integer(bytes, 0);
        }
    }
    write(directory / "cf96.dat", bytes);
}

void test_camera() {
    SolarCamera rotated;
    const auto before_roll = solar_camera_basis(rotated);
    rotated.roll(90);
    const auto after_roll = solar_camera_basis(rotated);
    same(after_roll.outward, before_roll.outward);
    same(after_roll.right, before_roll.up);
    check(!rotated.frame, "rolling an orbit camera must retain its projection limits");
    auto framed = rotated;
    framed.frame = after_roll;
    rotated.orbit(10, 5);
    framed.orbit(10, 5);
    const auto orbit_basis = solar_camera_basis(rotated);
    const auto framed_basis = solar_camera_basis(framed);
    same(orbit_basis.outward, framed_basis.outward);
    same(orbit_basis.right, framed_basis.right);
    same(orbit_basis.up, framed_basis.up);
    SolarCamera camera{{0, 0, 0}, 0, 0, 10};
    const auto at = [&](Vec3 point) {
        const auto result = project_solar(point, camera, 800, 600);
        check(result.has_value(), "expected visible point");
        return *result;
    };
    near(at({0, 0, 0}).x, 400); near(at({0, 0, 0}).y, 300);
    near(at({0, 0, 0}).depth, 10);
    check(at({0, 1, 0}).x > 400 && at({0, 0, 1}).y < 300, "camera handedness");
    check(!project_solar({11, 0, 0}, camera, 800, 600), "behind camera must clip");
    check(!project_solar({9.9995, 0, 0}, camera, 800, 600), "near plane must clip");
    const double offset = at({0, 1, 0}).x - 400;
    camera.zoom(std::log(2)); near(camera.distance_au, 20);
    near(at({0, 1, 0}).x - 400, offset / 2);
    camera.pan(24, -15, 800, 600);
    near(at({0, 0, 0}).x, 424); near(at({0, 0, 0}).y, 285);
    near(at(camera.target).x, 400); near(at(camera.target).y, 300);
    camera.orbit(-90 / 0.35, 0); near(camera.yaw_deg, 90);
    camera.orbit(0, 10); near(camera.pitch_deg, 3.5);
    camera.zoom(-1e100); near(camera.distance_au, 0.000005, 1e-15);
    camera.zoom(1e100); camera.zoom(1e100); near(camera.distance_au, maximum_solar_distance_au);
    camera.orbit(1e300, 0);
    check(std::isfinite(at(camera.target).depth), "large finite orbit input");

    camera = {{0, 0, 0}, 0, 0, 10};
    const auto line = project_solar_segment({0, 0, 0}, {11, 1, 0}, camera, 800, 600);
    check(line.has_value(), "line crossing near plane must clip and remain visible");
    near((*line)[0].depth, 10); near((*line)[1].depth, 0.001);
    const auto reverse = project_solar_segment({11, 1, 0}, {0, 0, 0}, camera, 800, 600);
    check(reverse.has_value(), "reversed clipped line");
    near((*line)[1].x, (*reverse)[0].x, 1e-6);
    check(!project_solar_segment({11, 0, 0}, {12, 1, 0}, camera, 800, 600), "hidden line");
    const auto on_screen = project_solar_segment({0, 0, 0}, {0, 1, 1}, camera, 800, 600);
    check(on_screen.has_value(), "ordinary line");
    near((*on_screen)[1].x, at({0, 1, 1}).x);

    const double nan = std::numeric_limits<double>::quiet_NaN();
    rejects<std::invalid_argument>([&] { camera.orbit(nan, 0); });
    rejects<std::invalid_argument>([&] { camera.zoom(nan); });
    rejects<std::invalid_argument>([&] { camera.pan(0, nan, 800, 600); });
    rejects<std::invalid_argument>([&] { camera.pan(1, 1, 0, 600); });
    rejects<std::invalid_argument>([&] { project_solar({nan, 0, 0}, camera, 800, 600); });
    rejects<std::invalid_argument>([&] { project_solar({}, camera, 800, -1); });
    rejects<std::invalid_argument>([&] { project_solar_segment({}, {0, nan, 0}, camera, 800, 600); });
    camera.pitch_deg = 90;
    rejects<std::invalid_argument>([&] { camera.zoom(0); });
    camera.pitch_deg = 0; camera.distance_au = 0;
    rejects<std::invalid_argument>([&] { project_solar({}, camera, 800, 600); });
}

void test_fixture(const std::filesystem::path& directory) {
    fixture(directory);
    const auto model = SkyModel::load(directory);
    const auto bodies = model.solar_bodies(2451545);
    check_orientations(bodies, 2451545);
    const auto later = model.solar_bodies(2451545.25);
    check_orientations(later, 2451545.25);
    const auto a = bodies[3].orientation.x_axis;
    const auto b = later[3].orientation.x_axis;
    // 6時間後の地球は約1/4回転。位置更新だけで姿勢が固定される退行を検出する。
    check(std::abs(a.x * b.x + a.y * b.y + a.z * b.z) < 0.01, "Earth must rotate with date");
    const std::array<Body, 11> order{Body::sun, Body::mercury, Body::venus,
        Body::earth, Body::mars, Body::jupiter, Body::saturn,
        Body::uranus, Body::neptune, Body::pluto, Body::moon};
    same(bodies[0].position_au, {});
    for (std::size_t i = 0; i < bodies.size(); ++i) {
        check(bodies[i].id == order[i], "solar body order");
        if (i != 3 && i != 10)
            same(bodies[i].position_au, {double(i), double(i) * 2, double(i) * 3});
    }
    check_earth_moon(bodies, {3, 6, 9}, 2451545);
    check_earth_moon(later, {3.025, 6.05, 9.075}, 2451545.25);
    const auto begin = model.solar_bodies(2451544);
    const auto end = model.solar_bodies(2451546);
    near(begin[1].position_au.x, 0.9); near(end[1].position_au.x, 1.1);
    for (const double date : {2451544.0, 2451545.0, 2451546.0}) {
        const auto orbits = model.solar_orbits(date);
        for (std::size_t planet = 0; planet < orbits.size(); ++planet) {
            check(orbits[planet].size() == 181, "orbit sample count");
            same(orbits[planet].front(), begin[planet + 1].position_au);
            same(orbits[planet].back(), end[planet + 1].position_au);
            check(orbits[planet].front().x != orbits[planet].back().x, "do not close cropped orbit");
        }
        const auto lunar_path = model.lunar_orbit(date);
        check(lunar_path.size() == 181, "lunar orbit sample count");
        same(lunar_path.front(), lunar_position(2451544));
        same(lunar_path[90], lunar_position(2451545));
        same(lunar_path.back(), lunar_position(2451546));
        check(lunar_path.front().x != lunar_path.back().x, "do not close cropped lunar orbit");
        // 地球位置を加えるだけで、相対軌道がその日時の月に重なる。
        const auto earth = bodies[3].position_au;
        const auto relative = lunar_path[90];
        same({earth.x + relative.x, earth.y + relative.y, earth.z + relative.z},
             bodies[10].position_au);
    }
    rejects<std::out_of_range>([&] { model.solar_bodies(2451543); });
    rejects<std::out_of_range>([&] { model.solar_orbits(2451547); });
    rejects<std::out_of_range>([&] { model.lunar_orbit(2451547); });
    const double nan = std::numeric_limits<double>::quiet_NaN();
    rejects<std::invalid_argument>([&] { model.solar_bodies(nan); });
    rejects<std::invalid_argument>([&] { model.solar_orbits(nan); });
    rejects<std::invalid_argument>([&] { model.lunar_orbit(nan); });
}

void test_real_data(const std::filesystem::path& directory) {
    const auto model = SkyModel::load(directory);
    const auto ephemeris = Cf96Ephemeris::load(directory / "cf96.dat");
    const auto range = model.time_range();
    for (const double date : {range.first, (range.first + range.second) / 2, range.second}) {
        const auto bodies = model.solar_bodies(date);
        check_orientations(bodies, date);
        same(bodies[0].position_au, {});
        for (std::size_t i = 1; i < 10; ++i) {
            const auto expected = ephemeris.state(i - 1, date).position_au;
            if (i == 3) check_earth_moon(bodies, {expected[0], expected[1], expected[2]}, date);
            else same(bodies[i].position_au, {expected[0], expected[1], expected[2]});
        }
        const auto paths = model.solar_orbits(date);
        for (const auto& path : paths) for (const auto& point : path) {
            check(std::isfinite(point.x) && std::isfinite(point.y) && std::isfinite(point.z),
                  "orbit coordinates must be finite");
            check(project_solar(point, {}, 1200, 800).has_value(), "default camera sees solar orbits");
        }
        const auto lunar_path = model.lunar_orbit(date);
        check(lunar_path.size() == 181, "existing lunar orbit sample count");
        same(lunar_path.front(), lunar_position(std::max(range.first, date - 27.321661 / 2)));
        same(lunar_path.back(), lunar_position(std::min(range.second, date + 27.321661 / 2)));
        for (const auto point : lunar_path)
            check(std::hypot(point.x, point.y, point.z) > 0.002
                  && std::hypot(point.x, point.y, point.z) < 0.003,
                  "lunar orbit must remain geocentric, not heliocentric");
    }
    std::cout << "solar integration passed: " << directory
              << ", bodies=11 orbits=9 lunar_orbits=1 rotations=10\n";
}
} // namespace

int main(int argc, char** argv) {
    auto pattern = (std::filesystem::temp_directory_path() / "mitaka-solar-model-XXXXXX").string();
    if (!mkdtemp(pattern.data())) { std::cerr << "cannot create test directory\n"; return 1; }
    const std::filesystem::path directory(pattern);
    try {
        test_camera(); test_fixture(directory);
        for (int i = 1; i < argc; ++i) test_real_data(argv[i]);
        std::filesystem::remove_all(directory);
        std::cout << "solar model tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::filesystem::remove_all(directory);
        std::cerr << error.what() << '\n';
        return 1;
    }
}
