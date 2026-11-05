#include "surface_navigation.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double radians_per_degree = 3.14159265358979323846 / 180;
constexpr double maximum_height_km = 1e9;

double heading(double angle) {
    const double reduced = std::fmod(angle, 360);
    return reduced < 0 ? reduced + 360 : reduced;
}

Vec3 transform(Vec3 value, const BodyOrientation& orientation) {
    return {value.x * orientation.x_axis.x + value.y * orientation.y_axis.x + value.z * orientation.north_axis.x,
            value.x * orientation.x_axis.y + value.y * orientation.y_axis.y + value.z * orientation.north_axis.y,
            value.x * orientation.x_axis.z + value.y * orientation.y_axis.z + value.z * orientation.north_axis.z};
}
} // namespace

SurfaceBodyInfo surface_body_info(std::size_t body_index) {
    // 公式mtk_planets.cppの赤道半径。月はmtk_satellites.hの定数による球近似。
    // 木土天海の「着陸」は固体地表ではなく、この基準半径への移動を意味する。
    static constexpr std::array<SurfaceBodyInfo, 10> bodies{{
        {2439.7, false}, {6051.8, false}, {6378.1366, false}, {3396.19, false},
        {71492, true}, {60268, true}, {25559, true}, {24764, true},
        {1185, false}, {1738.092, false}
    }};
    if (body_index == 0 || body_index > bodies.size())
        throw std::invalid_argument("surface body index must be in [1, 10]");
    return bodies[body_index - 1];
}

SurfaceSite surface_site_from_camera(const SolarCamera& camera, const SolarBodies& bodies,
                                     std::size_t body_index) {
    const auto info = surface_body_info(body_index);
    const auto& body = bodies.at(body_index);
    const auto basis = solar_camera_basis(camera);
    const auto center = j2000_equatorial_to_ecliptic(body.position_au);
    const Vec3 offset{camera.target.x + basis.outward.x * camera.distance_au - center.x,
                      camera.target.y + basis.outward.y * camera.distance_au - center.y,
                      camera.target.z + basis.outward.z * camera.distance_au - center.z};
    const double distance = std::hypot(offset.x, offset.y, offset.z);
    double height = distance * astronomical_unit_km - info.radius_km;
    // AU 座標の減算で 2 m の境界をわずかに下回る丸め誤差を補う。
    if (height >= minimum_surface_height_km - 1e-6) height = std::max(height, minimum_surface_height_km);
    if (!std::isfinite(height) || height < minimum_surface_height_km || height > maximum_height_km)
        throw std::invalid_argument("camera height cannot be represented by surface navigation");
    const auto dot = [](Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; };
    const Vec3 up{offset.x / distance, offset.y / distance, offset.z / distance};
    const double latitude = std::asin(std::clamp(dot(up, body.orientation.north_axis), -1.0, 1.0));
    const double longitude = std::atan2(dot(up, body.orientation.y_axis), dot(up, body.orientation.x_axis));
    const double clat = std::cos(latitude), slat = std::sin(latitude);
    const double clon = std::cos(longitude), slon = std::sin(longitude);
    const auto east = transform({-slon, clon, 0}, body.orientation);
    const auto north = transform({-slat * clon, -slat * slon, clat}, body.orientation);
    const Vec3 forward{-basis.outward.x, -basis.outward.y, -basis.outward.z};
    const double elevation = std::asin(std::clamp(dot(forward, up), -1.0, 1.0)) / radians_per_degree;
    // 天頂・天底では視線の水平成分が消えるため、右方向から方位を復元する。
    const double azimuth = std::atan2(-dot(basis.right, north), dot(basis.right, east)) / radians_per_degree;
    SurfaceSite site{body_index, latitude / radians_per_degree, longitude / radians_per_degree,
                     height, azimuth, elevation};
    SurfaceNavigation candidate;
    candidate.set_site(site);
    const auto restored = solar_camera_basis(candidate.camera(bodies));
    if (dot(restored.right, basis.right) < 1.0 - 1e-10 || dot(restored.up, basis.up) < 1.0 - 1e-10)
        throw std::invalid_argument("camera roll cannot be represented by surface navigation");
    return candidate.site();
}

void SurfaceNavigation::set_site(SurfaceSite site) {
    surface_body_info(site.body_index);
    if (!std::isfinite(site.latitude_deg) || std::abs(site.latitude_deg) > 90
        || !std::isfinite(site.longitude_deg) || !std::isfinite(site.heading_deg)
        || !std::isfinite(site.elevation_deg) || std::abs(site.elevation_deg) > 90
        || !std::isfinite(site.height_km) || site.height_km < minimum_surface_height_km
        || site.height_km > maximum_height_km)
        throw std::invalid_argument("invalid surface site");
    site.longitude_deg = std::remainder(site.longitude_deg, 360);
    site.heading_deg = heading(site.heading_deg);
    site_ = site;
    interrupt();
}

SolarCamera SurfaceNavigation::camera(const SolarBodies& bodies) const {
    const auto info = surface_body_info(site_.body_index);
    const auto& body = bodies.at(site_.body_index);
    const Vec3 center = j2000_equatorial_to_ecliptic(body.position_au);
    const double latitude = site_.latitude_deg * radians_per_degree;
    const double longitude = site_.longitude_deg * radians_per_degree;
    const double clat = std::cos(latitude), slat = std::sin(latitude);
    const double clon = std::cos(longitude), slon = std::sin(longitude);
    const auto up = transform({clat * clon, clat * slon, slat}, body.orientation);
    // 極でも経度を基準に東/北が一意になり、外積のゼロ除算を避ける。
    const auto east = transform({-slon, clon, 0}, body.orientation);
    const auto north = transform({-slat * clon, -slat * slon, clat}, body.orientation);
    const double azimuth = site_.heading_deg * radians_per_degree;
    const double elevation = site_.elevation_deg * radians_per_degree;
    const double ch = std::cos(azimuth), sh = std::sin(azimuth);
    const double ce = std::cos(elevation), se = std::sin(elevation);
    const Vec3 horizontal{north.x * ch + east.x * sh, north.y * ch + east.y * sh,
                          north.z * ch + east.z * sh};
    const Vec3 forward{horizontal.x * ce + up.x * se, horizontal.y * ce + up.y * se,
                       horizontal.z * ce + up.z * se};
    const SolarCameraBasis frame{
        {-forward.x, -forward.y, -forward.z},
        {east.x * ch - north.x * sh, east.y * ch - north.y * sh, east.z * ch - north.z * sh},
        {up.x * ce - horizontal.x * se, up.y * ce - horizontal.y * se, up.z * ce - horizontal.z * se}
    };
    const double distance = (info.radius_km + site_.height_km) / astronomical_unit_km;
    SolarCamera result;
    result.distance_au = distance;
    result.target = {center.x + (up.x + forward.x) * distance,
                     center.y + (up.y + forward.y) * distance,
                     center.z + (up.z + forward.z) * distance};
    result.frame = frame;
    // 破損した姿勢も公開カメラと同じ検証で拒否し、描画へ伝播させない。
    solar_camera_basis(result);
    return result;
}

void SurfaceNavigation::begin_flight(double time, double height, double elevation, double duration) {
    if (!std::isfinite(time)) throw std::invalid_argument("flight time must be finite");
    if (!std::isfinite(duration) || duration < 0) throw std::invalid_argument("flight duration must be nonnegative and finite");
    if (duration == 0) {
        site_.height_km = height;
        site_.elevation_deg = elevation;
        interrupt();
        return;
    }
    if (site_.height_km == height && site_.elevation_deg == elevation) {
        interrupt();
        return;
    }
    flight_ = Flight{time, time, site_.height_km, height, site_.elevation_deg, elevation, duration};
}

void SurfaceNavigation::begin_ascent(double monotonic_seconds, double duration_seconds) {
    begin_flight(monotonic_seconds, std::max(site_.height_km,
                 surface_body_info(site_.body_index).radius_km * 8), -80, duration_seconds);
}

void SurfaceNavigation::begin_descent(double monotonic_seconds, double duration_seconds) {
    begin_flight(monotonic_seconds, minimum_surface_height_km, 0, duration_seconds);
}

void SurfaceNavigation::begin_descent_preserving_look(double monotonic_seconds, double duration_seconds) {
    begin_flight(monotonic_seconds, minimum_surface_height_km, site_.elevation_deg, duration_seconds);
}

bool SurfaceNavigation::advance(double monotonic_seconds) {
    if (!flight_) return false;
    if (!std::isfinite(monotonic_seconds) || monotonic_seconds < flight_->previous_time
        || monotonic_seconds - flight_->previous_time > 1) {
        interrupt();
        return false;
    }
    auto& flight = *flight_;
    flight.previous_time = monotonic_seconds;
    const double t = std::clamp((monotonic_seconds - flight.start_time) / flight.duration, 0.0, 1.0);
    if (t == 0) return false;
    const double smooth = t * t * (3 - 2 * t);
    const double old_height = site_.height_km, old_elevation = site_.elevation_deg;
    // 2mから惑星規模までの距離差を、地表付近で急激に飛ばない対数高度でつなぐ。
    site_.height_km = std::clamp(std::exp(std::log(flight.start_height) * (1 - smooth)
                              + std::log(flight.end_height) * smooth),
                              minimum_surface_height_km, maximum_height_km);
    site_.elevation_deg = flight.start_elevation * (1 - smooth) + flight.end_elevation * smooth;
    if (t == 1) {
        site_.height_km = flight.end_height;
        site_.elevation_deg = flight.end_elevation;
        interrupt();
    }
    return site_.height_km != old_height || site_.elevation_deg != old_elevation;
}

void SurfaceNavigation::look(double dx_points, double dy_points) {
    if (!std::isfinite(dx_points) || !std::isfinite(dy_points))
        throw std::invalid_argument("surface look movement must be finite");
    auto next = site_;
    next.heading_deg = heading(next.heading_deg - std::remainder(dx_points, 360 / 0.35) * 0.35);
    next.elevation_deg = std::clamp(next.elevation_deg + std::clamp(dy_points, -1000.0, 1000.0) * 0.35,
                                  -89.0, 89.0);
    set_site(next);
}

void SurfaceNavigation::zoom(double logarithmic_delta) {
    if (!std::isfinite(logarithmic_delta))
        throw std::invalid_argument("surface zoom must be finite");
    auto next = site_;
    next.height_km = std::clamp(std::exp(std::clamp(std::log(next.height_km)
                              + std::clamp(logarithmic_delta, -100.0, 100.0),
                              std::log(minimum_surface_height_km), std::log(maximum_height_km))),
                              minimum_surface_height_km, maximum_height_km);
    set_site(next);
}

} // namespace mitaka::gui
