#include "plus_camera_orientation.hpp"

#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka::gui;
namespace {
void check(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
}
void close(double actual, double expected, const char* message) {
    check(std::isfinite(actual) && std::abs(actual - expected) < 1e-12, message);
}
template<class F> void rejects(F action) {
    try { action(); } catch (const std::invalid_argument&) { return; }
    throw std::runtime_error("invalid quaternion was accepted");
}
void normalization_extremes() {
    for (const double magnitude : {std::numeric_limits<double>::max(), 1.0,
                                   std::numeric_limits<double>::denorm_min()}) {
        const auto q = plus_orientation_normalized({magnitude, -magnitude, magnitude, -magnitude});
        close(q.x, .5, "normalization lost x");
        close(q.y, -.5, "normalization lost y");
        close(q.z, .5, "normalization lost z");
        close(q.w, -.5, "normalization lost w");
        const auto basis = plus_orientation_basis(q);
        close(std::hypot(basis.right.x, basis.right.y, basis.right.z), 1, "right is not a unit vector");
        close(std::hypot(basis.up.x, basis.up.y, basis.up.z), 1, "up is not a unit vector");
        close(std::hypot(basis.outward.x, basis.outward.y, basis.outward.z), 1, "outward is not a unit vector");
    }
    rejects([] { (void)plus_orientation_normalized({0, 0, 0, 0}); });
    rejects([] { (void)plus_orientation_normalized({1, 0, 0, std::numeric_limits<double>::infinity()}); });
    rejects([] { (void)plus_orientation_normalized({1, std::numeric_limits<double>::quiet_NaN(), 0, 0}); });
}
void interpolation_extremes() {
    const double large = std::numeric_limits<double>::max();
    const auto initial = plus_orientation_normalized({large, large, large, large});
    const auto target = plus_orientation_normalized({-large, -large, -large, -large});
    for (const auto t : {0.0, .25, .5, 1.0}) {
        const auto q = plus_orientation_normalized(plus_orientation_interpolate(initial, target, t, false));
        close(std::abs(q.x), .5, "equivalent-sign interpolation changed the orientation");
        close(std::abs(q.w), .5, "equivalent-sign interpolation changed the orientation");
    }
}
}
int main() {
    try {
        normalization_extremes(); interpolation_extremes();
        std::cout << "Plus camera orientation: PASS\n";
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n'; return 1;
    }
}
