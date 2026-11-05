#include "surface_navigation.hpp"

#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>

namespace {
using namespace mitaka;
using namespace mitaka::gui;

void check(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
void near(double actual, double expected, double tolerance = 1e-11) {
    if (!(std::abs(actual - expected) <= tolerance)) {
        throw std::runtime_error("numeric mismatch: " + std::to_string(actual)
                                 + " vs " + std::to_string(expected));
    }
}
void same(Vec3 actual, Vec3 expected, double tolerance = 1e-11) {
    near(actual.x, expected.x, tolerance);
    near(actual.y, expected.y, tolerance);
    near(actual.z, expected.z, tolerance);
}
void same(const SurfaceSite& a, const SurfaceSite& b) {
    check(a.body_index == b.body_index, "body changed");
    near(a.latitude_deg, b.latitude_deg); near(a.longitude_deg, b.longitude_deg);
    near(a.height_km, b.height_km); near(a.heading_deg, b.heading_deg);
    near(a.elevation_deg, b.elevation_deg);
}
template<typename Function>
void rejects(Function operation) {
    try { operation(); } catch (const std::invalid_argument&) { return; }
    throw std::runtime_error("expected invalid_argument");
}
Vec3 add(Vec3 a, Vec3 b) { return {a.x + b.x, a.y + b.y, a.z + b.z}; }
Vec3 scaled(Vec3 a, double scale) { return {a.x * scale, a.y * scale, a.z * scale}; }
Vec3 eye(const SolarCamera& camera) {
    return add(camera.target, scaled(solar_camera_basis(camera).outward, camera.distance_au));
}

SolarBodies fixture() {
    constexpr std::array<Body, 11> ids{Body::sun, Body::mercury, Body::venus,
        Body::earth, Body::mars, Body::jupiter, Body::saturn, Body::uranus,
        Body::neptune, Body::pluto, Body::moon};
    SolarBodies bodies{};
    for (std::size_t i = 0; i < bodies.size(); ++i) {
        bodies[i].id = ids[i];
        // モデルの位置は赤道系、姿勢と地表カメラは黄道系。変換漏れを検出する。
        bodies[i].position_au = j2000_ecliptic_to_equatorial({2, 3, -4});
    }
    return bodies;
}

void test_body_radii() {
    constexpr std::array<double, 10> radii{2439.7, 6051.8, 6378.1366, 3396.19,
        71492, 60268, 25559, 24764, 1185, 1738.092};
    for (std::size_t i = 1; i <= radii.size(); ++i) {
        const auto info = surface_body_info(i);
        near(info.radius_km, radii[i - 1], 1e-8);
        check(info.gas_reference_surface == (i >= 5 && i <= 8), "gas surface classification");
    }
    rejects([] { surface_body_info(0); });
    rejects([] { surface_body_info(11); });
    rejects([] { surface_body_info(std::numeric_limits<std::size_t>::max()); });
}

void test_site_contract() {
    SurfaceNavigation navigation;
    SurfaceSite site{3, 45, 725, 10, -450, 20};
    navigation.set_site(site);
    near(navigation.site().longitude_deg, 5);
    near(navigation.site().heading_deg, 270);
    navigation.begin_ascent(0);
    const auto before = navigation.site();
    const auto invalid = [&](SurfaceSite candidate) {
        rejects([&] { navigation.set_site(candidate); });
        same(navigation.site(), before);
        check(navigation.flying(), "invalid site must preserve active flight");
    };
    for (const std::size_t index : {std::size_t{0}, std::size_t{11}}) {
        auto candidate = before; candidate.body_index = index; invalid(candidate);
    }
    for (const double latitude : {-90.001, 90.001}) {
        auto candidate = before; candidate.latitude_deg = latitude; invalid(candidate);
    }
    for (const double elevation : {-90.001, 90.001}) {
        auto candidate = before; candidate.elevation_deg = elevation; invalid(candidate);
    }
    for (const double height : {0.0, 0.001, 1e9 + 1}) {
        auto candidate = before; candidate.height_km = height; invalid(candidate);
    }
    constexpr std::array<double SurfaceSite::*, 5> numeric_fields{
        &SurfaceSite::latitude_deg, &SurfaceSite::longitude_deg, &SurfaceSite::height_km,
        &SurfaceSite::heading_deg, &SurfaceSite::elevation_deg};
    for (const auto field : numeric_fields) {
        for (const double value : {std::numeric_limits<double>::quiet_NaN(),
                                   std::numeric_limits<double>::infinity()}) {
            auto candidate = before; candidate.*field = value; invalid(candidate);
        }
    }
    for (const double latitude : {-90.0, 90.0}) {
        site.latitude_deg = latitude; site.longitude_deg = -180;
        site.elevation_deg = latitude < 0 ? -89 : 89;
        site.height_km = latitude < 0 ? minimum_surface_height_km : 1e9;
        navigation.set_site(site);
        near(navigation.site().latitude_deg, latitude);
        check(!navigation.flying(), "successful set_site must stop flight");
    }
    site = {}; site.longitude_deg = 1e300; site.heading_deg = -1e300;
    navigation.set_site(site);
    check(std::abs(navigation.site().longitude_deg) <= 180, "large longitude normalization");
    check(navigation.site().heading_deg >= 0 && navigation.site().heading_deg < 360,
          "large heading normalization");
}

void test_surface_frames() {
    SurfaceNavigation navigation;
    auto bodies = fixture();
    const auto verify = [&](SurfaceSite site, Vec3 up, Vec3 north, Vec3 east) {
        navigation.set_site(site);
        const auto camera = navigation.camera(bodies);
        check(camera.frame.has_value(), "surface camera must have local frame");
        const auto basis = solar_camera_basis(camera);
        const double distance = (surface_body_info(site.body_index).radius_km + site.height_km)
                              / astronomical_unit_km;
        same(eye(camera), add({2, 3, -4}, scaled(up, distance)), 2e-12);
        same(basis.up, up); same(basis.outward, scaled(north, -1)); same(basis.right, east);
    };
    // 独立した軸上の期待値で、東西反転と極での基底退化を確認する。
    verify({3, 0, 0}, {1, 0, 0}, {0, 0, 1}, {0, 1, 0});
    verify({3, 0, 90}, {0, 1, 0}, {0, 0, 1}, {-1, 0, 0});
    verify({3, 90, 0}, {0, 0, 1}, {-1, 0, 0}, {0, 1, 0});
    verify({3, -90, 0}, {0, 0, -1}, {1, 0, 0}, {0, 1, 0});
    verify({10, 0, 0}, {1, 0, 0}, {0, 0, 1}, {0, 1, 0});

    navigation.set_site({3, 0, 0, 10, 90, 30});
    auto basis = solar_camera_basis(navigation.camera(bodies));
    const double root3over2 = std::sqrt(3.0) / 2;
    same(basis.outward, {-0.5, -root3over2, 0});
    same(basis.right, {0, 0, -1});
    same(basis.up, {root3over2, -0.5, 0});

    navigation.set_site({3, 0, 0});
    bodies[3].orientation = {{0, 1, 0}, {-1, 0, 0}, {0, 0, 1}};
    const auto rotated = navigation.camera(bodies);
    same(solar_camera_basis(rotated).right, {-1, 0, 0});
    const double radius = (6378.1366 + minimum_surface_height_km) / astronomical_unit_km;
    same(eye(rotated), {2, 3 + radius, -4}, 2e-12);
    bodies[3].position_au = j2000_ecliptic_to_equatorial({-7, 4, 2});
    same(eye(navigation.camera(bodies)), {-7, 4 + radius, 2}, 2e-12);

    // 地表固定カメラから地上地点を復元し、降下開始時の視点が跳ばないことを確かめる。
    navigation.set_site({3, 35.68, 139.76, 1000, 125, -30});
    const auto before = navigation.camera(bodies);
    const auto recovered = surface_site_from_camera(before, bodies, 3);
    navigation.set_site(recovered);
    const auto after = navigation.camera(bodies);
    same(eye(after), eye(before), 2e-12);
    same(solar_camera_basis(after).outward, solar_camera_basis(before).outward, 2e-11);
    same(solar_camera_basis(after).up, solar_camera_basis(before).up, 2e-11);
    for (const double elevation : {-90.0, 90.0}) {
        navigation.set_site({3, 35.68, 139.76, 1000, 125, elevation});
        const auto vertical = navigation.camera(bodies);
        navigation.set_site(surface_site_from_camera(vertical, bodies, 3));
        const auto recovered_camera = navigation.camera(bodies);
        same(solar_camera_basis(recovered_camera).up, solar_camera_basis(vertical).up, 2e-8);
    }
}

void test_flights() {
    SurfaceNavigation navigation;
    navigation.begin_ascent(10);
    check(!navigation.advance(10), "same timestamp must not move");
    check(navigation.flying(), "same timestamp must keep flight");
    double previous_height = navigation.site().height_km;
    for (int i = 1; i <= 6; ++i) {
        check(navigation.advance(10 + i * 0.5), "ascent must progress at 0.5 second steps");
        check(navigation.site().height_km > previous_height, "ascent height must increase");
        previous_height = navigation.site().height_km;
        check(navigation.flying() == (i < 6), "ascent must finish at three seconds");
    }
    near(navigation.site().height_km, 8 * 6378.1366, 1e-8);
    near(navigation.site().elevation_deg, -80);
    const auto bodies = fixture();
    const auto center = project_solar(j2000_equatorial_to_ecliptic(bodies[3].position_au),
                                     navigation.camera(bodies), 640, 480);
    check(center && center->x >= 0 && center->x <= 640
                 && center->y >= 0 && center->y <= 480,
          "body center must remain inside viewport after ascent");
    check(!navigation.advance(100), "completed flight must remain still");

    navigation.begin_descent(100);
    for (int i = 1; i <= 6; ++i) {
        check(navigation.advance(100 + i * 0.5), "descent must progress");
        check(navigation.site().height_km < previous_height, "descent height must decrease");
        previous_height = navigation.site().height_km;
    }
    near(navigation.site().height_km, minimum_surface_height_km);
    near(navigation.site().elevation_deg, 0);
    check(!navigation.flying(), "descent endpoint must stop flight");

    // 1秒ちょうどのイベント間隔は中断条件に含めない。
    navigation.set_site({10, 0, 0});
    navigation.begin_ascent(0);
    for (int i = 1; i <= 3; ++i) check(navigation.advance(i), "one second boundary");
    near(navigation.site().height_km, 8 * 1738.092, 1e-8);
}

void test_flight_interruptions() {
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double infinity = std::numeric_limits<double>::infinity();
    for (const double invalid_time : {1.5001, 0.4, nan, infinity}) {
        SurfaceNavigation navigation;
        navigation.begin_ascent(0); navigation.advance(0.5);
        const auto before = navigation.site();
        check(!navigation.advance(invalid_time), "interruption must not move");
        check(!navigation.flying(), "invalid elapsed time must stop flight");
        same(navigation.site(), before);
    }
    SurfaceNavigation navigation;
    navigation.begin_ascent(0); navigation.advance(0.5);
    const auto before = navigation.site();
    for (const double invalid_time : {nan, infinity}) {
        rejects([&] { navigation.begin_ascent(invalid_time); });
        rejects([&] { navigation.begin_descent(invalid_time); });
        same(navigation.site(), before);
        check(navigation.flying(), "invalid start time must preserve active flight");
    }
    navigation.interrupt();
    check(!navigation.advance(1), "explicit interruption must hold position");
    same(navigation.site(), before);
}

void test_manual_controls() {
    SurfaceNavigation navigation;
    navigation.set_site({3, 0, 0, 100, 10, 0});
    navigation.look(40, 20);
    near(navigation.site().heading_deg, 356); near(navigation.site().elevation_deg, 7);
    navigation.zoom(std::log(2)); near(navigation.site().height_km, 200);
    navigation.look(1e300, 1e300); near(navigation.site().elevation_deg, 89);
    navigation.look(-1e300, -1e300); near(navigation.site().elevation_deg, -89);
    check(navigation.site().heading_deg >= 0 && navigation.site().heading_deg < 360,
          "look must normalize heading");
    navigation.zoom(1e300); near(navigation.site().height_km, 1e9, 1e-6);
    navigation.zoom(-1e300); near(navigation.site().height_km, minimum_surface_height_km);
    navigation.begin_ascent(0);
    const auto before = navigation.site();
    const double nan = std::numeric_limits<double>::quiet_NaN();
    rejects([&] { navigation.look(nan, 1); });
    rejects([&] { navigation.look(1, nan); });
    rejects([&] { navigation.zoom(nan); });
    same(navigation.site(), before);
    check(navigation.flying(), "invalid controls must preserve flight");
    navigation.look(1, 1); check(!navigation.flying(), "look must interrupt flight");
    navigation.begin_ascent(0);
    navigation.zoom(0.1); check(!navigation.flying(), "zoom must interrupt flight");
}

void test_camera_rays() {
    SolarCamera camera{{1, 2, 3}, 0, 0, 2};
    camera.frame = SolarCameraBasis{{0, 0, 1}, {1, 0, 0}, {0, 1, 0}};
    same(eye(camera), {1, 2, 5});
    same(solar_camera_ray(camera, 320, 240, 640, 480), {0, 0, -1});
    for (const auto pixel : std::array<std::array<double, 2>, 4>{
            {{0, 0}, {319.5, 239.5}, {640, 480}, {700, -20}}}) {
        const auto ray = solar_camera_ray(camera, pixel[0], pixel[1], 640, 480);
        near(ray.x * ray.x + ray.y * ray.y + ray.z * ray.z, 1);
        const auto projected = project_solar(add(eye(camera), scaled(ray, 3)), camera, 640, 480);
        check(projected.has_value(), "forward ray point must project");
        near(projected->x, pixel[0]); near(projected->y, pixel[1]);
    }
    for (const auto& invalid : std::array<SolarCameraBasis, 4>{{
            {{0, 0, 1}, {2, 0, 0}, {0, 1, 0}},
            {{0, 0, 1}, {1, 0, 0}, {0, -1, 0}},
            {{0, 0, 1}, {1, 0, 0}, {0.01, 1, 0}},
            {{0, 0, 0}, {1, 0, 0}, {0, 1, 0}}}}) {
        camera.frame = invalid;
        rejects([&] { solar_camera_basis(camera); });
        rejects([&] { solar_camera_ray(camera, 320, 240, 640, 480); });
    }
    camera.frame = SolarCameraBasis{{0, 0, 1}, {1, 0, 0}, {0, 1, 0}};
    rejects([&] { solar_camera_ray(camera, 0, 0, 0, 480); });
    rejects([&] { solar_camera_ray(camera, 0, std::numeric_limits<double>::quiet_NaN(), 640, 480); });

    // 地表専用nearは通常の距離比例nearと分離し、数mの視点でも切り捨てない。
    camera.target = {}; camera.distance_au = 1e-6;
    check(project_solar({0, 0, 1e-6 - 2e-12}, camera, 640, 480).has_value(),
          "surface near must preserve nearby terrain");
    check(!project_solar({0, 0, 1e-6 - 0.5e-12}, camera, 640, 480),
          "surface near must reject closer points");
    camera.zoom(-1e100); near(camera.distance_au, 1e-12, 1e-24);
    camera.frame.reset(); camera.distance_au = 1;
    camera.zoom(-1e100); near(camera.distance_au, 0.000005, 1e-17);
}
} // namespace

int main() {
    try {
        test_body_radii(); test_site_contract(); test_surface_frames(); test_flights();
        test_flight_interruptions(); test_manual_controls(); test_camera_rays();
        std::cout << "surface navigation tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
