#include "our_galaxy_navigation.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double radius_pc = 8000.0;
constexpr double pi = 3.14159265358979323846;

Vec3 add(Vec3 a, Vec3 b) { return {a.x+b.x, a.y+b.y, a.z+b.z}; }
Vec3 sub(Vec3 a, Vec3 b) { return {a.x-b.x, a.y-b.y, a.z-b.z}; }
Vec3 mul(Vec3 a, double s) { return {a.x*s, a.y*s, a.z*s}; }
double dot(Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }
Vec3 cross(Vec3 a, Vec3 b) {
    return {a.y*b.z-a.z*b.y, a.z*b.x-a.x*b.z, a.x*b.y-a.y*b.x};
}
Vec3 checked_origin(OurGalaxyPlacement p) {
    const Vec3 result{p.sun_origin.x_pc, p.sun_origin.y_pc, p.sun_origin.z_pc};
    if (!std::isfinite(result.x) || !std::isfinite(result.y) || !std::isfinite(result.z) ||
        std::abs(result.x) > maximum_galaxy_coordinate_pc ||
        std::abs(result.y) > maximum_galaxy_coordinate_pc ||
        std::abs(result.z) > maximum_galaxy_coordinate_pc)
        throw std::invalid_argument("invalid OurGalaxy origin");
    return result;
}
Vec3 direction(double ra_deg, double dec_deg) {
    const double ra = ra_deg*pi/180, dec = dec_deg*pi/180;
    // 原版は get_dirc_vec() を vector3f に変換してから行列を作る。
    return {static_cast<float>(std::cos(dec)*std::cos(ra)),
            static_cast<float>(std::cos(dec)*std::sin(ra)),
            static_cast<float>(std::sin(dec))};
}
Vec3 to_ecliptic(Vec3 v) {
    const double obliquity = 23.43870583*pi/180;
    const double c = std::cos(obliquity), s = std::sin(obliquity);
    return {v.x, c*v.y+s*v.z, -s*v.y+c*v.z};
}
struct GalacticAxes { Vec3 x, y, z; };
GalacticAxes official_axes() {
    const Vec3 gc = direction((17+45.0/60+40.0383/3600)*15, -(29+28.069/3600));
    const Vec3 gn = direction((12+51.0/60+24.0/3600)*15, 27+8.0/60);
    // 原版の外積と代入も float で実行する。
    const float gx = static_cast<float>(gc.x), gy = static_cast<float>(gc.y), gz = static_cast<float>(gc.z);
    const float nx = static_cast<float>(gn.x), ny = static_cast<float>(gn.y), nz = static_cast<float>(gn.z);
    const Vec3 go{ny*gz-nz*gy, nz*gx-nx*gz, nx*gy-ny*gx};
    return {to_ecliptic(gc), to_ecliptic(go), to_ecliptic(gn)};
}
NativeEclipticPositionPc position(Vec3 v) { return {v.x,v.y,v.z}; }
Vec3 galaxy_vector(Vec3 v, GalacticAxes axes) {
    return {dot(v,axes.x), dot(v,axes.y), dot(v,axes.z)};
}
void viewport(double width, double height) {
    if (!std::isfinite(width) || !std::isfinite(height) || width <= 0 || height <= 0 ||
        width > 1e7 || height > 1e7)
        throw std::invalid_argument("invalid OurGalaxy viewport");
}
} // namespace

NativeEclipticPositionPc our_galaxy_center(OurGalaxyPlacement placement) {
    return position(add(checked_origin(placement), mul(official_axes().x, radius_pc)));
}
NativeEclipticPositionPc our_galaxy_label_position(OurGalaxyPlacement placement) {
    const auto axes = official_axes();
    return position(add(checked_origin(placement), add(mul(axes.x,2*radius_pc),mul(axes.y,radius_pc))));
}
bool hit_our_galaxy(OurGalaxyPlacement placement, GalaxyCameraPc camera,
                    double x, double y, double width, double height) {
    camera = checked_galaxy_camera(camera);
    viewport(width, height);
    if (!std::isfinite(x) || !std::isfinite(y)) throw std::invalid_argument("invalid OurGalaxy click");
    const auto center = our_galaxy_center(placement);
    if (x < 0 || x > width || y < 0 || y > height) return false;
    SolarCamera direction_camera;
    direction_camera.yaw_deg = camera.yaw_deg;
    direction_camera.pitch_deg = camera.pitch_deg;
    direction_camera.frame = camera.frame;
    direction_camera.roll_deg = camera.roll_deg;
    direction_camera.vertical_fov_deg = camera.vertical_fov_deg;
    const auto axes = solar_camera_basis(direction_camera);
    const Vec3 delta = add(sub({camera.target.x_pc,camera.target.y_pc,camera.target.z_pc},
                               {center.x_pc,center.y_pc,center.z_pc}),
                           mul(camera.target_offset_au, 1 / astronomical_units_per_parsec));
    const Vec3 r0 = add(delta, mul(axes.outward,camera.distance_pc));
    if (dot(r0,r0) < 2*radius_pc*radius_pc) return false;
    const double tangent_half_fov = solar_camera_tangent(direction_camera);
    const double horizontal = (x-width/2)/height * (2*tangent_half_fov);
    const double vertical = (height/2-y)/height * (2*tangent_half_fov);
    const auto galactic = official_axes();
    auto flatten = [galactic](Vec3 v) {
        auto result = galaxy_vector(v,galactic);
        result.z /= .2;
        return result;
    };
    const Vec3 transformed_delta = flatten(delta);
    const Vec3 transformed_outward = flatten(axes.outward);
    // 分解後に視線との外積を計算し、遠距離での二乗の差の桁落ちを避ける。
    const Vec3 ray = add(mul(transformed_outward,-1),
                         add(mul(flatten(axes.right),horizontal),mul(flatten(axes.up),vertical)));
    const double length = std::hypot(ray.x,ray.y,ray.z);
    const Vec3 ray_unit = mul(ray,1/length);
    const Vec3 cross_value = mul(add(cross(transformed_delta,ray),
                                     mul(cross(transformed_outward,ray),camera.distance_pc)),1/length);
    const double discriminant = radius_pc*radius_pc-dot(cross_value,cross_value);
    const Vec3 r = add(transformed_delta,mul(transformed_outward,camera.distance_pc));
    const double b = dot(r,ray_unit);
    return discriminant > 0 && -b-std::sqrt(discriminant) >= 0;
}
GalaxyCameraPc center_our_galaxy(OurGalaxyPlacement placement, GalaxyCameraPc camera) {
    camera = checked_galaxy_camera(camera);
    camera.target = our_galaxy_center(placement);
    camera.target_offset_au = {};
    return checked_galaxy_camera(camera);
}
GalaxyCameraPc frame_our_galaxy(OurGalaxyPlacement placement, GalaxyCameraPc camera,
                                double visible_radius_pc, double width, double height) {
    viewport(width,height);
    if (!std::isfinite(visible_radius_pc) || visible_radius_pc <= 0)
        throw std::invalid_argument("invalid OurGalaxy framing radius");
    camera = center_our_galaxy(placement,camera);
    SolarCamera direction_camera;
    direction_camera.vertical_fov_deg = camera.vertical_fov_deg;
    const double tangent = solar_camera_tangent(direction_camera) * std::min(1.0,width/height);
    camera.distance_pc = visible_radius_pc*std::hypot(1.0,tangent)/tangent;
    return checked_galaxy_camera(camera);
}
} // namespace mitaka::gui
