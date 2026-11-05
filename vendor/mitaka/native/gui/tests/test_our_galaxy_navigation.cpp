#include "our_galaxy_navigation.hpp"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
void check(bool condition, const char* reason) { if (!condition) throw std::runtime_error(reason); }
void near(double a, double b, double tolerance = 1e-7) {
    check(std::abs(a-b) <= tolerance*std::max({1.0,std::abs(a),std::abs(b)}), "values differ");
}
template<class F> void rejects(F f) {
    try { f(); } catch (const std::invalid_argument&) { return; }
    throw std::runtime_error("expected invalid_argument");
}
constexpr double pi = 3.14159265358979323846;
void run() {
    const OurGalaxyPlacement origin{{0,0,0}}, shifted{{2,-4,7}};
    const auto center = our_galaxy_center(origin), moved = our_galaxy_center(shifted);
    near(std::hypot(center.x_pc,center.y_pc,center.z_pc),8000,1e-6);
    near(center.x_pc,-437.2588317,1e-6); near(center.y_pc,-7949.6905898,1e-6);
    near(center.z_pc,-781.8083143,1e-6);
    near(moved.x_pc-center.x_pc,2); near(moved.y_pc-center.y_pc,-4); near(moved.z_pc-center.z_pc,7);
    const auto label = our_galaxy_label_position(origin);
    // 固定ラベルは銀河の中心とは別の位置に置かれている。
    check(std::hypot(label.x_pc-center.x_pc,label.y_pc-center.y_pc,label.z_pc-center.z_pc) > 11000,
          "label must not coincide with center");
    GalaxyCameraPc camera;
    camera.target = center;
    camera.distance_pc = 30000;
    camera.frame = SolarCameraBasis{{1,0,0},{0,1,0},{0,0,1}};
    check(hit_our_galaxy(origin,camera,400,300,800,600), "center ray must intersect");
    check(!hit_our_galaxy(origin,camera,0,0,800,600), "corner ray must miss");
    camera.distance_pc = 1e30;
    check(hit_our_galaxy(origin,camera,400,300,800,600), "far center ray must intersect");
    check(!hit_our_galaxy(origin,camera,401,300,800,600), "far offset ray must miss");
    check(!hit_our_galaxy(origin,camera,-1,300,800,600), "outside viewport");
    camera.distance_pc = 10000;
    check(!hit_our_galaxy(origin,camera,400,300,800,600), "official near-distance exclusion");
    camera.target = {0,0,0}; camera.distance_pc = 13500;
    const auto focused = center_our_galaxy(origin,camera);
    near(focused.target.x_pc,center.x_pc); near(focused.target.y_pc,center.y_pc);
    near(focused.target.z_pc,center.z_pc); near(focused.distance_pc,camera.distance_pc);
    check(focused.frame && focused.frame->right.y == 1, "focus must preserve roll");
    const auto framed = frame_our_galaxy(origin,camera,17600,800,600);
    check(framed.distance_pc > 17600, "framing must place camera outside bounding sphere");
    near(framed.distance_pc, 17600/std::sin(pi/8));
    const auto portrait = frame_our_galaxy(origin,camera,17600,300,600);
    check(portrait.distance_pc > framed.distance_pc, "portrait frame needs greater distance");
    check(hit_our_galaxy(origin,framed,400,300,800,600), "framed galaxy must be selectable");
    rejects([&]{ (void)frame_our_galaxy(origin,camera,0,800,600); });
    rejects([&]{ (void)hit_our_galaxy(origin,camera,0,0,0,600); });
    rejects([&]{ (void)hit_our_galaxy(origin,camera,std::numeric_limits<double>::quiet_NaN(),0,800,600); });
    rejects([&]{ (void)our_galaxy_center({{std::numeric_limits<double>::infinity(),0,0}}); });
}
}
int main() {
    try { run(); std::cout << "OurGalaxy navigation tests passed\n"; }
    catch (const std::exception& e) { std::cerr << e.what() << '\n'; return 1; }
}
