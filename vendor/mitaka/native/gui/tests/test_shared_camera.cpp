#include "shared_camera.hpp"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
void check(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
void close(double actual, double expected) {
    check(std::isfinite(actual) && std::abs(actual - expected) <=
          1e-12 * std::max({1.0, std::abs(actual), std::abs(expected)}), "values differ");
}
template<class F> void rejects(F action) {
    try { action(); } catch (const std::invalid_argument&) { return; }
    throw std::runtime_error("expected invalid_argument");
}
void same_axis(Vec3 actual, Vec3 expected) {
    close(actual.x, expected.x); close(actual.y, expected.y); close(actual.z, expected.z);
}
void same_frame(const SolarCameraBasis& actual, const SolarCameraBasis& expected) {
    same_axis(actual.outward, expected.outward);
    same_axis(actual.right, expected.right);
    same_axis(actual.up, expected.up);
}
void conversion_and_projection() {
    for (bool rolled : {false, true}) for (double fov : {10., 45., 90.}) {
        SolarCamera solar{{3, -2, 5}, 20, -30, 10};
        solar.vertical_fov_deg = fov;
        if (rolled) solar.frame = SolarCameraBasis{{1, 0, 0}, {0, 0, 1}, {0, -1, 0}};
        else solar.roll(37);
        const auto shared = shared_camera_from_solar(solar);
        const auto galaxy = galaxy_camera_from_shared(shared);
        const auto roundtrip = solar_camera_from_shared(shared_camera_from_galaxy(galaxy));
        check(shared.vertical_fov_deg == fov && galaxy.vertical_fov_deg == fov &&
              roundtrip.vertical_fov_deg == fov, "camera conversion lost FOV");
        same_axis(roundtrip.target, solar.target);
        close(roundtrip.distance_au, solar.distance_au);
        check(roundtrip.frame.has_value() == rolled, "frame presence changed");
        same_frame(solar_camera_basis(roundtrip), solar_camera_basis(solar));
        for (const Vec3 p : {Vec3{3, -2, 5}, {3.2, -1.9, 4.7}, {2, -3, 6}}) {
            const auto a = project_solar(p, solar, 1024, 600);
            const auto b = GalaxyProjector(galaxy, 1024, 600).project(
                {p.x / astronomical_units_per_parsec, p.y / astronomical_units_per_parsec,
                 p.z / astronomical_units_per_parsec});
            check(a.has_value() && b.has_value(), "point should be visible");
            close(a->x, b->x); close(a->y, b->y);
            close(a->depth, b->depth_pc * astronomical_units_per_parsec);
        }
        if (rolled) {
            const auto old_frame = *galaxy.frame;
            auto moved = galaxy;
            moved.pan(30, -10, 1024, 600);
            same_frame(*moved.frame, old_frame);
            moved.orbit(23, -11);
            check(moved.frame.has_value(), "orbit lost frame");
            check(std::abs(moved.frame->outward.z - old_frame.outward.z) > 1e-3,
                  "orbit did not rotate frame");
            const auto moved_solar = solar_camera_from_shared(shared_camera_from_galaxy(moved));
            same_frame(solar_camera_basis(moved_solar), *moved.frame);
        }
    }
}
void limits_and_validation() {
    const GalaxyCameraPc far{{1e20, -1e20, 3}, 35, 35, 1e20};
    const auto shared = shared_camera_from_galaxy(far);
    const auto roundtrip = galaxy_camera_from_shared(shared);
    close(roundtrip.target.x_pc, far.target.x_pc);
    close(roundtrip.target.y_pc, far.target.y_pc);
    close(roundtrip.distance_pc, far.distance_pc);
    close(solar_camera_from_shared(shared).distance_au, shared.distance_au);
    auto invalid = shared;
    invalid.target_au.x = std::numeric_limits<double>::infinity();
    rejects([&] { (void)galaxy_camera_from_shared(invalid); });
    invalid = shared; invalid.distance_au = 0;
    rejects([&] { (void)galaxy_camera_from_shared(invalid); });
    invalid = shared; invalid.vertical_fov_deg = 0;
    rejects([&] { (void)galaxy_camera_from_shared(invalid); });
    invalid = shared; invalid.vertical_fov_deg = std::numeric_limits<double>::quiet_NaN();
    rejects([&] { (void)solar_camera_from_shared(invalid); });
    GalaxyCameraPc bad;
    bad.frame = SolarCameraBasis{{1, 0, 0}, {0, 1, 0}, {0, 0, -1}};
    rejects([&] { (void)checked_galaxy_camera(bad); });
    rejects([&] { (void)shared_camera_from_galaxy(bad); });
    rejects([&] { (void)GalaxyProjector(bad, 1024, 600); });
}
void movement_across_scales() {
    SolarCamera source{{3, -2, 5}, 20, -30, 10};
    source.frame = SolarCameraBasis{{1, 0, 0}, {0, 0, 1}, {0, -1, 0}};
    auto camera = shared_camera_from_solar(source);
    const auto initial_frame = *camera.frame;
    camera.zoom(std::log(200));
    close(camera.distance_au, 2000);
    same_axis(camera.target_au, source.target);
    same_frame(*camera.frame, initial_frame);
    close(solar_camera_from_shared(camera).distance_au, 2000);
    const auto galaxy = galaxy_camera_from_shared(camera);
    close(galaxy.distance_pc * astronomical_units_per_parsec, 2000);
    same_frame(*galaxy.frame, initial_frame);

    camera.zoom(1e300); camera.zoom(1e300);
    check(camera.distance_au == maximum_shared_distance_au, "maximum distance");
    check(solar_camera_from_shared(camera).distance_au == maximum_shared_distance_au,
          "solar maximum distance");
    (void)galaxy_camera_from_shared(camera);
    camera.orbit(13, 7);
    check(camera.frame.has_value(), "far orbit lost frame");
    const auto rotated = *camera.frame;
    check(std::abs(rotated.outward.z - initial_frame.outward.z) > 1e-3, "far orbit did not rotate");
    camera.pan(10, -20, 1024, 600);
    same_frame(*camera.frame, rotated);
    check(std::hypot(camera.target_au.x, camera.target_au.y, camera.target_au.z) > 1e40,
          "far pan did not use shared distance");

    camera.zoom(-1e300); camera.zoom(-1e300);
    check(camera.distance_au == minimum_shared_distance_au, "minimum distance");
    same_frame(*camera.frame, rotated);
    check(galaxy_camera_from_shared(camera).distance_pc == minimum_galaxy_projection_distance_pc,
          "shared minimum projection distance");
    check(solar_camera_from_shared(camera).distance_au == minimum_shared_distance_au,
          "solar fixed frame minimum");

    const auto before = camera;
    rejects([&] { camera.zoom(std::numeric_limits<double>::quiet_NaN()); });
    rejects([&] { camera.orbit(std::numeric_limits<double>::infinity(), 0); });
    rejects([&] { camera.pan(1, 1, 800, 0); });
    rejects([&] { camera.pan(1e308, 1e308, 800, std::numeric_limits<double>::denorm_min()); });
    same_axis(camera.target_au, before.target_au);
    same_frame(*camera.frame, *before.frame);
    check(camera.distance_au == before.distance_au, "rejected movement changed camera");

    auto invalid = camera;
    invalid.distance_au = 0;
    rejects([&] { invalid.zoom(1); });
    invalid = camera; invalid.pitch_deg = 90;
    rejects([&] { invalid.orbit(1, 1); });
}
void close_solar_projection() {
    // 地球付近から旧表示境界の前後と太陽系カメラ最小距離まで、同じ恒星を投影する。
    std::optional<GalaxyProjectionPc> previous;
    for (const double distance : {0.207, 0.205, 0.001, minimum_shared_distance_au}) {
        const SolarCamera solar{{1, 0, 0}, 0, 0, distance,
            SolarCameraBasis{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}}};
        const auto galaxy = galaxy_camera_from_shared(shared_camera_from_solar(solar));
        const GalaxyProjector projector(galaxy, 1024, 600);
        const auto star = projector.project({-10, 1, 0});
        check(star && projector.contains(*star), "star visible near planet and shared minimum");
        if (previous) {
            check(std::abs(star->x - previous->x) < 0.001 && std::abs(star->y - previous->y) < 0.001,
                  "distant star jumps across old threshold");
        }
        const auto center = projector.project(galaxy.target);
        check(center && center->x == 512 && center->y == 300, "camera target remains centered");
        previous = star;
    }
}
void far_source_pan_and_roundtrip() {
    // 同梱 SDSS GAL の座標規模では単一 AU double の 1 ULP が 1 point pan より大きい。
    const NativeEclipticPositionPc source{-1003390485.606666, 0, 0};
    SolarCamera solar;
    solar.set_target_pc({source.x_pc, source.y_pc, source.z_pc});
    solar.distance_au = 1;
    solar.yaw_deg = 90;
    auto shared = shared_camera_from_solar(solar);
    auto projection = [&] {
        return GalaxyProjector(galaxy_camera_from_shared(shared), 1024, 600).project(source);
    };
    const auto before = projection();
    check(before.has_value(), "far source initially visible");
    shared.pan(1, 0, 1024, 600);
    const auto after = projection();
    check(after.has_value() && std::abs(std::abs(after->x - before->x) - 1) < 1e-9,
          "far source did not move by one point");
    solar = solar_camera_from_shared(shared_camera_from_galaxy(galaxy_camera_from_shared(shared)));
    const auto recovered = GalaxyProjector(galaxy_camera_from_shared(shared_camera_from_solar(solar)), 1024, 600).project(source);
    check(recovered && std::abs(recovered->x - after->x) < 1e-9, "far position lost in bridge");
    shared.pan(-1, 0, 1024, 600);
    const auto reversed = projection();
    check(reversed && std::abs(reversed->x - before->x) < 1e-9, "inverse pan lost precision");
    auto inconsistent = shared;
    inconsistent.target_au.x += 1;
    rejects([&] { (void)galaxy_camera_from_shared(inconsistent); });
    solar.set_target_au({1, 2, 3});
    check(!solar.precise_target, "near target retained stale residual");
}
void pan_at_shared_minimum() {
    const NativeEclipticPositionPc source{-1003390485.606666, 0, 0};
    SolarCamera solar;
    solar.set_target_pc({source.x_pc, source.y_pc, source.z_pc});
    auto initial = shared_camera_from_solar(solar);
    initial.distance_au = minimum_shared_distance_au;
    for (int frame_mode = 0; frame_mode < 3; ++frame_mode) {
        auto camera = initial;
        if (frame_mode != 0) {
            camera.frame = SolarCameraBasis{{1, 0, 0}, {0, 1, 0}, {0, 0, 1}};
            camera.frame_is_orbit = frame_mode == 1;
        }
        if (frame_mode != 2) rejects([&] { (void)solar_camera_from_shared(camera); });
        else (void)solar_camera_from_shared(camera);
        auto projection = [&] {
            return GalaxyProjector(galaxy_camera_from_shared(camera), 1024, 600).project(source);
        };
        const auto before = projection();
        check(before.has_value(), "minimum-distance source initially visible");
        camera.pan(1, 0, 1024, 600);
        const auto after = projection();
        check(after && std::abs(std::abs(after->x - before->x) - 1) < 1e-9,
              "minimum-distance pan lost one point");
        camera.pan(-1, 0, 1024, 600);
        const auto reversed = projection();
        check(reversed && std::abs(reversed->x - before->x) < 1e-9,
              "minimum-distance inverse pan lost precision");
    }
}
} // namespace

int main() {
    try {
        conversion_and_projection(); limits_and_validation(); movement_across_scales(); close_solar_projection(); far_source_pan_and_roundtrip(); pan_at_shared_minimum();
        std::cout << "Shared camera: PASS\n";
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n'; return 1;
    }
}
