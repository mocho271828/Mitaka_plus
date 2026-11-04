#include "distance_scales.hpp"
#include "grid_geometry.hpp"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
int checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
double length(Vec3 value) { return std::hypot(value.x, value.y, value.z); }
Vec3 subtract(Vec3 a, Vec3 b) { return {a.x - b.x, a.y - b.y, a.z - b.z}; }
double dot(Vec3 a, Vec3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
template<class Operation> void rejects(Operation operation) {
    bool rejected = false;
    try { operation(); } catch (const std::invalid_argument&) { rejected = true; }
    check(rejected, "invalid distance scale input accepted");
}
void circle_tests() {
    const auto& circles = circle_distance_scales();
    check(circles.size() == 21, "original circle scale inventory changed");
    check(circles[0].radius_au == 1 && circles[4].radius_au == 10000,
          "solar circle units must be AU");
    check(std::abs(circles[5].radius_au - 63241.07708426628) < 1e-8,
          "Julian light year conversion is incorrect");
    check(circles.back().label_value == 1.38e10, "largest original circle was omitted");
    for (std::size_t index = 0; index < circles.size(); ++index) {
        const auto& circle = circles[index];
        check(circle.galactic_plane == (index >= 5), "circle plane does not match its physical unit");
        const auto point = circle_distance_scale_point(circle, 90);
        const auto closure = subtract(circle_distance_scale_point(circle, 0), circle_distance_scale_point(circle, 360));
        check(length(closure) == 0, "circle is not closed at 360 degrees");
        if (circle.galactic_plane) {
            const auto galactic = j2000_equatorial_to_galactic(j2000_ecliptic_to_equatorial(point));
            check(std::abs(galactic.z) < circle.radius_au * 1e-14,
                  "light year circle escaped the galactic plane");
            check(std::abs(galactic.y / circle.radius_au - 1) < 1e-14,
                  "galactic circle radius changed during coordinate conversion");
        } else {
            check(point.z == 0 && std::abs(point.y - circle.radius_au) < 1e-10,
                  "AU circle escaped the ecliptic plane");
        }
    }
    check(circle_distance_scale_opacity(1, 1) == 0, "inside circle boundary must fade out");
    check(circle_distance_scale_opacity(3, 1) == 0.5, "near fade midpoint incorrect");
    check(circle_distance_scale_opacity(5, 1) == 1 && circle_distance_scale_opacity(14, 1) == 1,
          "circle central visibility interval changed");
    check(circle_distance_scale_opacity(42, 1) == 0.5, "far fade midpoint incorrect");
    check(circle_distance_scale_opacity(70, 1) == 0 && circle_distance_scale_opacity(1000, 1) == 0,
          "distant circles must fade out");
    for (double invalid : {0.0, -1.0, std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()}) {
        rejects([&] { circle_distance_scale_opacity(invalid, 1); });
        rejects([&] { circle_distance_scale_opacity(1, invalid); });
        rejects([&] { circle_distance_scale_point({invalid, 1, false, 45}, 0); });
    }
    rejects([&] { circle_distance_scale_point(circles[0], std::numeric_limits<double>::quiet_NaN()); });
}
void square_tests() {
    SolarCamera camera;
    camera.target = {3, -7, 2};
    camera.distance_au = 10;
    const auto axes = solar_camera_basis(camera);
    const auto squares = square_distance_scales(camera);
    check(!squares.empty(), "normal camera has no distance scale");
    for (const auto& square : squares) {
        check(square.opacity > 0 && square.opacity <= 0.9, "square opacity is outside its display range");
        const double side = std::pow(10.0, square.meter_exponent) / 149597870700.0;
        check(length(subtract(square.vertices[0], square.vertices[4])) == 0, "square is not closed");
        Vec3 center{};
        for (std::size_t index = 0; index < 4; ++index) {
            const auto point = square.vertices[index];
            center.x += point.x / 4; center.y += point.y / 4; center.z += point.z / 4;
            check(std::abs(dot(subtract(point, camera.target), axes.outward)) < 1e-12,
                  "square is not perpendicular to the viewing direction");
            check(std::abs(length(subtract(point, square.vertices[index + 1])) - side) < 1e-12,
                  "square physical side length changed");
        }
        check(length(subtract(center, camera.target)) < 1e-12, "square must be centered on the camera target");
    }
    camera.frame = SolarCameraBasis{{0, 0, 1}, {1, 0, 0}, {0, 1, 0}};
    camera.distance_au = 1e-10;
    const auto small = square_distance_scales(camera);
    check(std::any_of(small.begin(), small.end(), [](const auto& square) { return square.meter_exponent == 0; }),
          "meter scale was omitted for a close surface camera");
    camera.distance_au = 0;
    rejects([&] { square_distance_scales(camera); });
    camera.distance_au = 10;
    camera.target.x = std::numeric_limits<double>::quiet_NaN();
    rejects([&] { square_distance_scales(camera); });
}
}
int main() {
    try {
        circle_tests(); square_tests();
        std::cout << "distance scale tests passed (" << checks << " checks)\n";
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
