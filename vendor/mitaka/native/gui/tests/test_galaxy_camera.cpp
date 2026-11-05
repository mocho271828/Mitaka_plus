#include "galaxy_camera.hpp"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <type_traits>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
std::size_t checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class F> void rejects(F action) {
    try { action(); } catch (const std::invalid_argument&) { ++checks; return; }
    throw std::runtime_error("expected invalid argument");
}
bool same(const GalaxyCameraPc& a, const GalaxyCameraPc& b) {
    return a.target.x_pc == b.target.x_pc && a.target.y_pc == b.target.y_pc && a.target.z_pc == b.target.z_pc &&
           a.yaw_deg == b.yaw_deg && a.pitch_deg == b.pitch_deg && a.distance_pc == b.distance_pc;
}
void close(double actual, long double expected, long double scale) {
    check(std::isfinite(actual) && std::abs(actual - expected) <=
        128 * std::numeric_limits<double>::epsilon() * std::max(1.0L, scale), "projection oracle");
}
void projection_tests() {
    static_assert(!std::is_convertible_v<NativeEclipticPositionPc, Vec3>);
    static_assert(!std::is_convertible_v<GalaxyCameraPc, SolarCamera>);
    // 単位方向を除き製品 helper を呼ばない long double の透視投影式。
    const long double rad = std::acos(-1.0L) / 180;
    for (double distance : {1e-6, 1.0, 10000.0, 1e20, 1e40})
        for (double yaw : {-179.0, 0.0, 35.0, 180.0, 725.0})
            for (double pitch : {-89.0, -35.0, 0.0, 35.0, 89.0})
                for (const auto p : {NativeEclipticPositionPc{0, 0, 0}, {0.2, -0.4, 0.1}, {-0.3, 0.1, -0.2}}) {
                    GalaxyCameraPc camera{{distance * 0.1, 0, 0}, yaw, pitch, distance};
                    const auto result = GalaxyProjector(camera, 1024, 600).project(
                        {p.x_pc * distance, p.y_pc * distance, p.z_pc * distance});
                    check(result.has_value(), "front hemisphere projects");
                    const long double cy = std::cos(std::remainder(yaw, 360) * rad);
                    const long double sy = std::sin(std::remainder(yaw, 360) * rad);
                    const long double cp = std::cos(pitch * rad), sp = std::sin(pitch * rad);
                    const long double x = static_cast<long double>(p.x_pc * distance) - camera.target.x_pc;
                    const long double y = p.y_pc * distance, z = p.z_pc * distance;
                    const long double depth = distance - (x * cp * cy + y * cp * sy + z * sp);
                    const long double scale = 300 / std::tan(22.5L * rad) / depth;
                    close(result->x, 512 + (-x * sy + y * cy) * scale, 1024);
                    close(result->y, 300 - (-x * sp * cy - y * sp * sy + z * cp) * scale, 600);
                    close(result->depth_pc, depth, distance);
                }
    GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
    const GalaxyProjector projector(camera, 800, 600);
    check(!projector.project({10, 0, 0}) && !projector.project({11, 0, 0}), "at or behind eye");
    // 深度と閾値が厳密に表せる距離で、境界の比較演算を確認する。
    const GalaxyProjector near_projector({{0, 0, 0}, 0, 0, 10000}, 800, 600);
    check(near_projector.project({9999, 0, 0}).has_value(), "near boundary included");
    check(!near_projector.project({std::nextafter(9999.0, 10000.0), 0, 0}), "near predecessor rejected");
    const auto right = projector.project({0, 1, 0}), up = projector.project({0, 0, 1});
    check(right->x > 400 && right->y == 300 && up->x == 400 && up->y < 300, "right up orientation");
    const auto outside = projector.project({0, 100, 0});
    check(outside && !projector.contains(*outside), "offscreen returned for clip");
    check(projector.contains({0, 0, 1}) && projector.contains({800, 600, 1}), "viewport edge inclusive");
    for (double bad : {std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN(), 1e41})
        rejects([&] { (void)projector.project({bad, 0, 0}); });
}
void boundary_and_operation_tests() {
    GalaxyCameraPc camera;
    const auto original = camera;
    for (double bad : {0.0, -1.0, 1e8, std::numeric_limits<double>::infinity(),
                       std::numeric_limits<double>::quiet_NaN()}) {
        rejects([&] { (void)GalaxyProjector(camera, bad, 600); });
        rejects([&] { (void)GalaxyProjector(camera, 800, bad); });
        rejects([&] { camera.pan(1, 1, bad, 600); });
        check(same(camera, original), "invalid dimensions preserve camera");
    }
    for (double bad : {std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()}) {
        rejects([&] { camera.orbit(bad, 1); });
        rejects([&] { camera.pan(1, bad, 800, 600); });
        rejects([&] { camera.zoom(bad); });
        check(same(camera, original), "invalid movements preserve camera");
    }
}
void movement_tests() {
    GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10000};
    const auto before = camera;
    rejects([&] { camera.pan(1e300, 1, 800, 600); });
    check(same(camera, before), "overflow pan rejected atomically");
    rejects([&] { camera.pan(1, 0, 800, std::numeric_limits<double>::denorm_min()); });
    check(same(camera, before), "tiny viewport overflow rejected atomically");
    const GalaxyProjector prior(camera, 800, 600);
    const auto old = prior.project({0, 0, 0});
    camera.pan(27, -19, 800, 600);
    const auto after = GalaxyProjector(camera, 800, 600).project({0, 0, 0});
    close(after->x - old->x, 27, 800); close(after->y - old->y, -19, 600);
    camera.orbit(1e300, -1e300);
    check(std::isfinite(camera.yaw_deg) && camera.pitch_deg == -89, "huge finite orbit bounded");
    camera.zoom(1e300); camera.zoom(1e300);
    check(camera.distance_pc == maximum_galaxy_coordinate_pc, "zoom maximum");
    camera.zoom(-1e300); camera.zoom(-1e300);
    check(camera.distance_pc == minimum_galaxy_distance_pc, "zoom minimum");
    for (int kind = 0; kind < 6; ++kind) {
        auto invalid = before;
        switch (kind) {
        case 0: invalid.target.x_pc = 1e41; break;
        case 1: invalid.target.y_pc = std::numeric_limits<double>::quiet_NaN(); break;
        case 2: invalid.distance_pc = 0; break;
        case 3: invalid.distance_pc = 1e41; break;
        case 4: invalid.pitch_deg = 90; break;
        case 5: invalid.yaw_deg = std::numeric_limits<double>::infinity(); break;
        }
        rejects([&] { (void)checked_galaxy_camera(invalid); });
        rejects([&] { (void)GalaxyProjector(invalid, 800, 600); });
    }
    // AU camera は pc 空間と同じ距離上限を共有する。
    SolarCamera solar; solar.distance_au = std::nextafter(maximum_solar_distance_au,
                                                         std::numeric_limits<double>::infinity());
    rejects([&] { (void)solar_camera_basis(solar); });
}
} // namespace
int main() {
    try {
        projection_tests(); boundary_and_operation_tests(); movement_tests();
        std::cout << "Galaxy camera: " << checks << " checks PASS\n";
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
