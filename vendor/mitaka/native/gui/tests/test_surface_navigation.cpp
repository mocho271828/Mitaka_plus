#include "surface_navigation.hpp"
#include "surface_sky_site.hpp"
#include "surface_star_pick.hpp"
#include "mitaka/observation.hpp"
#include "mitaka/lunar.hpp"

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

void test_surface_star_pick() {
    auto bodies = fixture();
    bodies[4].orientation = planet_orientation(Planet::mars, 2460000.5);
    SurfaceNavigation nav;
    nav.set_site({4, 35, 139, 0.002, 42, 23, 0, 0});
    const auto camera = nav.camera(bodies);
    const ObservationFrame observation({35, 139}, bodies[4].orientation);
    const auto direction = observation.to_equatorial({42, 23});
    HipparcosRecord star{};
    star.hip = 123;
    star.right_ascension_degrees = direction.right_ascension_deg;
    star.declination_degrees = direction.declination_deg;
    star.apparent_v_magnitude = 1;
    const auto point = project_surface_star({star.right_ascension_degrees, star.declination_degrees}, camera, 800, 600);
    check(point.has_value(), "projected star missing");
    std::vector<HipparcosRecord> stars{star};
    const ScreenPoint click{point->x, point->y};
    const auto visible = [](ScreenPoint) { return false; };
    const auto occluded = [](ScreenPoint) { return true; };
    check(pick_surface_star(stars,camera,800,600,click,true,2,visible) == 0, "visible star not selected");
    check(!pick_surface_star(stars,camera,800,600,click,false,2,visible), "hidden stars selected");
    check(!pick_surface_star(stars,camera,800,600,click,true,0,visible), "faint star selected");
    check(!pick_surface_star(stars,camera,800,600,click,true,2,occluded), "occluded star selected");
    const ScreenPoint groundClick{point->x + 4, point->y};
    const auto ground = [&](ScreenPoint p) { return std::abs(p.x - groundClick.x) < 0.1; };
    check(!pick_surface_star(stars,camera,800,600,groundClick,true,2,ground), "occluded click selected adjacent visible star");
    check(!pick_surface_star(stars,camera,800,600,{point->x+9,point->y},true,2,visible), "distant star selected");
    check(!pick_surface_star(stars,camera,800,600,{-1,0},true,2,visible), "outside click selected");
}

void test_surface_sky_below_datum() {
    const auto bodies = fixture();
    SurfaceNavigation nav;
    nav.set_site({3, 35, 139, 0.002, 123, -20, 37});
    const auto reference = nav.camera(bodies);
    const auto expected = surface_site_from_camera_with_roll(reference, bodies, 3);
    auto below = reference;
    const auto center = j2000_equatorial_to_ecliptic(bodies[3].position_au);
    const auto position = eye(reference);
    const Vec3 radial{position.x-center.x, position.y-center.y, position.z-center.z};
    const auto radius = std::hypot(radial.x, radial.y, radial.z);
    below.translate_target_au(scaled(radial, -1.0 / astronomical_unit_km / radius));
    rejects([&] { surface_site_from_camera_with_roll(below, bodies, 3); });
    const auto actual = surface_sky_site_from_camera(below, bodies, 3);
    near(actual.latitude_deg, expected.latitude_deg, 1e-6);
    near(actual.longitude_deg, expected.longitude_deg, 1e-6);
    near(actual.heading_deg, expected.heading_deg, 1e-6);
    near(actual.elevation_deg, expected.elevation_deg, 1e-6);
    near(actual.roll_deg, expected.roll_deg, 1e-6);
    const auto unchanged = eye(below);
    surface_sky_site_from_camera(below, bodies, 3);
    same(eye(below), unchanged);
}

void test_non_earth_sky_projection() {
    for (const std::size_t body : {std::size_t{4},std::size_t{10}}) {
        for (const double date : {2451545.0, 2460000.5}) {
            auto bodies = fixture();
            bodies[body].orientation = body == 4 ? planet_orientation(Planet::mars,date) : lunar_orientation(date);
            for (const auto& site : {SurfaceSite{body,35,139,0.002,42,23,0,-0.25},
                                    SurfaceSite{body,-60,-70,1,110,-12,25,0},
                                    SurfaceSite{body,90,90,0.002,0,0,0,0}}) {
                SurfaceNavigation nav;
                nav.set_site(site);
                const auto camera = nav.camera(bodies);
                const auto recovered = surface_sky_site_from_camera(camera,bodies,body);
                const ObservationFrame observation({recovered.latitude_deg,recovered.longitude_deg},
                                                   bodies[body].orientation);
                const HorizonProjectionViewport viewport{360-recovered.heading_deg,recovered.elevation_deg,
                                                           180,1,recovered.roll_deg};
                for (const auto angles : {HorizontalCoordinates{recovered.heading_deg,recovered.elevation_deg},
                                          {recovered.heading_deg+5,recovered.elevation_deg+3},
                                          {recovered.heading_deg-8,recovered.elevation_deg-5}}) {
                    const auto equatorial = observation.to_equatorial(angles);
                    const auto horizontal = observation.to_horizontal(equatorial);
                    const auto projected = project_horizon({360-horizontal.azimuth_deg,horizontal.altitude_deg},
                                                           viewport,800,600);
                    const auto direction = j2000_equatorial_to_ecliptic(equatorial_direction(equatorial));
                    constexpr double distance = 1e6;
                    const Vec3 point{camera.target.x+direction.x*distance,camera.target.y+direction.y*distance,
                                     camera.target.z+direction.z*distance};
                    const auto solar = project_solar(point,camera,800,600);
                    check(projected && solar, "non-Earth star and constellation must be visible");
                    near(projected->x,solar->x,1e-5);
                    near(projected->y,solar->y,1e-5);
                }
            }
        }
    }
}

void test_terrain_offset() {
    const auto bodies=fixture();
    SurfaceNavigation nav;
    SurfaceSite site{3,45,10,100,30,-20,0,1.25};
    nav.set_site(site);
    nav.begin_descent(0,0);
    near(nav.site().height_km,minimum_surface_height_km);
    near(nav.site().terrain_offset_km,1.25);
    const auto position=eye(nav.camera(bodies));
    const auto center=j2000_equatorial_to_ecliptic(bodies[3].position_au);
    near(std::hypot(position.x-center.x,position.y-center.y,position.z-center.z)*astronomical_unit_km,
         surface_body_info(3).radius_km+1.25+minimum_surface_height_km,1e-6);
    nav.zoom(-100);
    near(nav.site().terrain_offset_km,1.25);
    nav.look(10,10);
    near(nav.site().terrain_offset_km,1.25);
    nav.begin_ascent(0,3);
    nav.advance(.5);
    nav.interrupt();
    near(nav.site().terrain_offset_km,1.25);
    auto bad=nav.site(); bad.terrain_offset_km=-surface_body_info(3).radius_km;
    rejects([&]{nav.set_site(bad);});
    near(nav.site().terrain_offset_km,1.25);
}
void test_negative_terrain() {
    const auto bodies=fixture();
    SurfaceNavigation nav;
    nav.set_site({3,31.5,135,minimum_surface_height_km,0,0,0,-1.43853});
    const auto pos=eye(nav.camera(bodies));
    const auto center=j2000_equatorial_to_ecliptic(bodies[3].position_au);
    near(std::hypot(pos.x-center.x,pos.y-center.y,pos.z-center.z)*astronomical_unit_km,
         surface_body_info(3).radius_km-1.43853+minimum_surface_height_km,1e-6);
    nav.begin_ascent(0,3); nav.advance(.5); nav.update_terrain_offset(-2);
    check(nav.flying(),"negative terrain update interrupted ascent");
    for (int i=2;i<=6;++i) nav.advance(i*.5);
    nav.begin_descent(4,3);
    for (int i=1;i<=6;++i) nav.advance(4+i*.5);
    near(nav.site().height_km,minimum_surface_height_km);
    near(nav.site().terrain_offset_km,-2);
}
void test_terrain_offset_updates() {
    SurfaceNavigation nav;
    nav.set_site({3,45,10,100,30,-20,0,1});
    nav.begin_descent(0,3);
    nav.advance(.5);
    const auto before=nav.site();
    nav.update_terrain_offset(2);
    check(nav.flying(), "terrain update interrupted descent");
    near(nav.site().height_km + nav.site().terrain_offset_km,
         before.height_km + before.terrain_offset_km);
    near(nav.site().elevation_deg,before.elevation_deg);
    for (int i=2;i<=6;++i) nav.advance(i*.5);
    check(!nav.flying(), "updated descent failed to finish on schedule");
    near(nav.site().height_km,minimum_surface_height_km);
    near(nav.site().terrain_offset_km,2);
    nav.update_terrain_offset(3);
    near(nav.site().height_km,minimum_surface_height_km);
    nav.update_terrain_offset(1);
    near(nav.site().height_km,minimum_surface_height_km);

    nav.begin_ascent(10,3);
    nav.advance(10.5);
    nav.advance(11);
    nav.advance(11.5);
    const auto during_ascent=nav.site();
    nav.update_terrain_offset(2);
    check(nav.flying(), "terrain update interrupted ascent");
    near(nav.site().height_km + nav.site().terrain_offset_km,
         during_ascent.height_km + during_ascent.terrain_offset_km);
    for (int i=4;i<=6;++i) nav.advance(10+i*.5);
    check(!nav.flying(), "updated ascent failed to finish on schedule");
    near(nav.site().height_km + nav.site().terrain_offset_km,
         surface_body_info(3).radius_km * 8, 1e-8);

    nav.set_site({3,0,0,1,0,0,0,0});
    nav.begin_descent(20,3);
    nav.advance(20.5);
    nav.update_terrain_offset(10);
    check(nav.flying(), "terrain collision interrupted flight");
    near(nav.site().height_km,minimum_surface_height_km);
    for (int i=2;i<=6;++i) nav.advance(20+i*.5);
    check(!nav.flying(), "terrain-clamped flight failed to finish");
    near(nav.site().height_km,minimum_surface_height_km);

    nav.begin_ascent(30,3);
    const auto saved=nav.site();
    rejects([&]{nav.update_terrain_offset(-surface_body_info(3).radius_km);});
    rejects([&]{nav.update_terrain_offset(std::numeric_limits<double>::infinity());});
    rejects([&]{nav.update_terrain_offset(1e10);});
    same(nav.site(),saved);
    near(nav.site().terrain_offset_km,saved.terrain_offset_km);
    check(nav.flying(), "invalid offset changed flight");
    nav.advance(30.5);
    nav.interrupt();
    nav.update_terrain_offset(11);
    check(!nav.flying(), "terrain update resumed interrupted flight");
}
void test_ascent_datum_endpoint() {
    const double target = surface_body_info(3).radius_km * 8;
    for (int timing = 0; timing < 3; ++timing) {
        SurfaceNavigation nav;
        nav.set_site({3, 35.68, 139.76, minimum_surface_height_km, 0, 0, 0,
                      timing == 0 ? 2.0 : 0.0});
        nav.begin_ascent(0, 3);
        nav.advance(.5);
        if (timing != 0) nav.update_terrain_offset(2);
        if (timing == 2) {
            nav.interrupt();
            nav.begin_ascent(.5, 3);
            for (int i = 1; i <= 6; ++i) nav.advance(.5 + i * .5);
        } else {
            for (int i = 2; i <= 6; ++i) nav.advance(i * .5);
        }
        check(!nav.flying(), "ascent with terrain update did not finish");
        near(nav.site().height_km + nav.site().terrain_offset_km, target, 1e-8);
        near(nav.camera(fixture()).distance_au, 9 * surface_body_info(3).radius_km / astronomical_unit_km, 1e-12);
    }
    // 既に目標より遠い場所からは、離陸操作によって下降しない。
    SurfaceNavigation nav;
    nav.set_site({3, 0, 0, target + 5, 0, 0, 0, 2});
    nav.begin_ascent(0, 0);
    near(nav.site().height_km, target + 5);
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
    navigation.look(1e300, 1e300); near(navigation.site().elevation_deg, 90);
    navigation.look(-1e300, -1e300); near(navigation.site().elevation_deg, -90);
    check(navigation.site().heading_deg >= 0 && navigation.site().heading_deg < 360,
          "look must normalize heading");
    for (double elevation : {-90.0, 90.0}) {
        navigation.set_site({3, 23, 45, 100, 10, elevation});
        const auto before = navigation.camera(fixture());
        navigation.look(10, 0);
        near(navigation.site().elevation_deg, elevation);
        const auto after = navigation.camera(fixture());
        same(eye(before), eye(after));
        same(solar_camera_ray(before, 320, 240, 640, 480),
             solar_camera_ray(after, 320, 240, 640, 480));
        navigation.look(0, elevation > 0 ? -1 : 1);
        near(navigation.site().elevation_deg, elevation + (elevation > 0 ? -0.35 : 0.35));
    }
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
        test_surface_star_pick(); test_non_earth_sky_projection(); test_surface_sky_below_datum(); test_terrain_offset();
        test_terrain_offset_updates(); test_negative_terrain(); test_ascent_datum_endpoint(); test_body_radii(); test_site_contract(); test_surface_frames(); test_flights();
        test_flight_interruptions(); test_manual_controls(); test_camera_rays();
        std::cout << "surface navigation tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
