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

double plus_flight_weight(double progress) {
    return 0.5 - 0.5 * std::cos(180 * radians_per_degree * progress);
}

double earth_horizon_look_weight(double datum_height_km) {
    // 旧Plusの地平線モードは、地心距離が2Rから1.002Rに近づくにつれ
    // 天底から元の地平視線へ戻る。途中では地平線の見かけの角度で補間する。
    constexpr double inner_radius = 1.002, outer_radius = 2.0;
    const double radius = 1 + datum_height_km / earth_reference_radius_km;
    if (radius <= inner_radius) return 1;
    if (radius >= outer_radius) return 0;
    const double outer_angle = std::asin(inner_radius / outer_radius);
    const double phase = (std::asin(inner_radius / radius) - outer_angle) /
        (90 * radians_per_degree - outer_angle);
    return phase < 0.5 ? 2 * phase * phase : 1 - 2 * (1 - phase) * (1 - phase);
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
        {2439.7, false}, {6051.8, false}, {earth_reference_radius_km, false}, {3396.19, false},
        {71492, true}, {60268, true}, {25559, true}, {24764, true},
        {1185, false}, {1738.092, false}
    }};
    if (body_index == 0 || body_index > bodies.size())
        throw std::invalid_argument("surface body index must be in [1, 10]");
    return bodies[body_index - 1];
}

static SurfaceSite surface_site_from_camera_impl(const SolarCamera& camera, const SolarBodies& bodies,
                                                 std::size_t body_index, bool preserve_roll,
                                                 double terrain_offset_km = 0) {
    const auto info = surface_body_info(body_index);
    const auto& body = bodies.at(body_index);
    const auto basis = solar_camera_basis(camera);
    const auto center = j2000_equatorial_to_ecliptic(body.position_au);
    const Vec3 offset{camera.target.x + basis.outward.x * camera.distance_au - center.x,
                      camera.target.y + basis.outward.y * camera.distance_au - center.y,
                      camera.target.z + basis.outward.z * camera.distance_au - center.z};
    const double distance = std::hypot(offset.x, offset.y, offset.z);
    double height = distance * astronomical_unit_km - info.radius_km - terrain_offset_km;
    // AU 座標の減算で 2 m の境界をわずかに下回る丸め誤差を補う。
    if (height >= minimum_surface_height_km - 1e-6) height = std::max(height, minimum_surface_height_km);
    if (!std::isfinite(height) || height < minimum_surface_height_km || height > maximum_height_km)
        throw std::invalid_argument("camera height cannot be represented by surface navigation");
    const auto dot = [](Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; };
    const Vec3 up{offset.x / distance, offset.y / distance, offset.z / distance};
    const double x = dot(up, body.orientation.x_axis), y = dot(up, body.orientation.y_axis);
    const double latitude = std::atan2(dot(up, body.orientation.north_axis), std::hypot(x, y));
    const double longitude = std::atan2(y, x);
    const double clat = std::cos(latitude), slat = std::sin(latitude);
    const double clon = std::cos(longitude), slon = std::sin(longitude);
    const auto east = transform({-slon, clon, 0}, body.orientation);
    const auto north = transform({-slat * clon, -slat * slon, clat}, body.orientation);
    const Vec3 forward{-basis.outward.x, -basis.outward.y, -basis.outward.z};
    const double elevation = std::asin(std::clamp(dot(forward, up), -1.0, 1.0)) / radians_per_degree;
    // 天頂・天底では視線の水平成分が消えるため、右方向から方位を復元する。
    const double northward = dot(forward, north), eastward = dot(forward, east);
    const double azimuth = preserve_roll && std::hypot(northward, eastward) > 1e-12
        ? std::atan2(eastward, northward) / radians_per_degree
        : std::atan2(-dot(basis.right, north), dot(basis.right, east)) / radians_per_degree;
    SurfaceSite site{body_index, latitude / radians_per_degree, longitude / radians_per_degree,
                     height, azimuth, elevation};
    site.terrain_offset_km = terrain_offset_km;
    SurfaceNavigation candidate;
    candidate.set_site(site);
    const auto restored = solar_camera_basis(candidate.camera(bodies));
    if (preserve_roll) {
        site.roll_deg = std::atan2(dot(basis.right, restored.up), dot(basis.right, restored.right)) / radians_per_degree;
        candidate.set_site(site);
    } else if (dot(restored.right, basis.right) < 1.0 - 1e-10 || dot(restored.up, basis.up) < 1.0 - 1e-10)
        throw std::invalid_argument("camera roll cannot be represented by surface navigation");
    return candidate.site();
}

SurfaceSite surface_site_from_camera(const SolarCamera& camera, const SolarBodies& bodies,
                                     std::size_t body_index) {
    return surface_site_from_camera_impl(camera, bodies, body_index, false);
}

SurfaceSite surface_site_from_camera_with_roll(const SolarCamera& camera, const SolarBodies& bodies,
                                               std::size_t body_index) {
    return surface_site_from_camera_impl(camera, bodies, body_index, true);
}

std::optional<SurfaceSite> surface_site_from_camera_with_known_terrain(
    const SolarCamera& camera, const SolarBodies& bodies, std::size_t body_index,
    const SurfaceSite& known_site) {
    if (known_site.body_index != body_index || known_site.terrain_offset_km >= 0) return std::nullopt;
    SurfaceNavigation previous;
    previous.set_site(known_site);
    const auto previous_camera = previous.camera(bodies);
    const auto eye = [](const SolarCamera& c) {
        const auto outward = solar_camera_basis(c).outward;
        return Vec3{c.target.x + outward.x * c.distance_au,
                    c.target.y + outward.y * c.distance_au,
                    c.target.z + outward.z * c.distance_au};
    };
    const auto a = eye(camera), b = eye(previous_camera);
    // AU 座標の丸めを許す一方、約 1.5 mm 以上離れた地点には古い地形高を使わない。
    if (!(std::hypot(a.x - b.x, a.y - b.y, a.z - b.z) <= 1e-14)) return std::nullopt;
    return surface_site_from_camera_impl(camera, bodies, body_index, true, known_site.terrain_offset_km);
}

SurfaceSite forced_surface_site_from_camera(const SolarCamera& camera, const SolarBodies& bodies,
                                            std::size_t body_index) {
    surface_body_info(body_index);
    const auto& body = bodies.at(body_index);
    const auto basis = solar_camera_basis(camera);
    const auto center = j2000_equatorial_to_ecliptic(body.position_au);
    const Vec3 offset{camera.target.x + basis.outward.x * camera.distance_au - center.x,
                      camera.target.y + basis.outward.y * camera.distance_au - center.y,
                      camera.target.z + basis.outward.z * camera.distance_au - center.z};
    const double distance = std::hypot(offset.x, offset.y, offset.z);
    if (!std::isfinite(distance)) throw std::invalid_argument("invalid camera position");
    // 中心にいる場合は経度・緯度 0 を基準とする。
    const Vec3 up = distance > 1e-15 ? Vec3{offset.x / distance, offset.y / distance, offset.z / distance}
                                     : body.orientation.x_axis;
    const auto dot = [](Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; };
    const double x = dot(up, body.orientation.x_axis), y = dot(up, body.orientation.y_axis);
    const double latitude = std::atan2(dot(up, body.orientation.north_axis), std::hypot(x, y));
    const double longitude = std::atan2(y, x);
    const double clat = std::cos(latitude), slat = std::sin(latitude);
    const double clon = std::cos(longitude), slon = std::sin(longitude);
    const auto east = transform({-slon, clon, 0}, body.orientation);
    const auto north = transform({-slat * clon, -slat * slon, clat}, body.orientation);
    const Vec3 forward{-basis.outward.x, -basis.outward.y, -basis.outward.z};
    const double elevation = std::asin(std::clamp(dot(forward, up), -1.0, 1.0)) / radians_per_degree;
    const double northward = dot(forward, north), eastward = dot(forward, east);
    // 天頂・天底では方位が定まらないので、元の右方向を用いる。
    const double azimuth = std::hypot(northward, eastward) > 1e-12
        ? std::atan2(eastward, northward) / radians_per_degree
        : std::atan2(-dot(basis.right, north), dot(basis.right, east)) / radians_per_degree;
    SurfaceSite site{body_index, latitude / radians_per_degree, longitude / radians_per_degree,
                     minimum_surface_height_km, azimuth, elevation};
    SurfaceNavigation candidate;
    candidate.set_site(site);
    return candidate.site();
}

void SurfaceNavigation::set_site(SurfaceSite site) {
    surface_body_info(site.body_index);
    if (!std::isfinite(site.latitude_deg) || std::abs(site.latitude_deg) > 90
        || !std::isfinite(site.longitude_deg) || !std::isfinite(site.heading_deg)
        || !std::isfinite(site.elevation_deg) || std::abs(site.elevation_deg) > 90
        || !std::isfinite(site.roll_deg)
        || !std::isfinite(site.terrain_offset_km) || site.terrain_offset_km <= -surface_body_info(site.body_index).radius_km || site.terrain_offset_km > maximum_height_km
        || !std::isfinite(site.height_km) || site.height_km < minimum_surface_height_km
        || site.height_km > maximum_height_km)
        throw std::invalid_argument("invalid surface site");
    site.longitude_deg = std::remainder(site.longitude_deg, 360);
    site.heading_deg = heading(site.heading_deg);
    site.roll_deg = std::remainder(site.roll_deg, 360);
    site_ = site;
    interrupt();
}

void SurfaceNavigation::update_terrain_offset(double offset_km) {
    if (!std::isfinite(offset_km) || offset_km <= -surface_body_info(site_.body_index).radius_km || offset_km > maximum_height_km)
        throw std::invalid_argument("invalid terrain offset");
    if (offset_km == site_.terrain_offset_km) return;

    const double old_offset = site_.terrain_offset_km;
    // 地表に立っている場合は新地形に追従する。上空では可能な限り
    // 半径を維持するが、新たな地形の内部に入る場合は安全な地上へ戻す。
    const double height = site_.height_km == minimum_surface_height_km
        ? minimum_surface_height_km
        : std::clamp(site_.height_km + old_offset - offset_km,
                     minimum_surface_height_km, maximum_height_km);
    if (flight_) {
        auto& flight = *flight_;
        const double progress = std::clamp((flight.previous_time - flight.start_time) / flight.duration, 0.0, 1.0);
        // 着陸は地上2mを目標に保ち、離陸は可能な限り元の半径を保つ。
        if (flight.end_height != minimum_surface_height_km)
            flight.end_height = std::clamp(flight.end_height + old_offset - offset_km,
                                           minimum_surface_height_km, maximum_height_km);
        if (flight.height_curve == HeightCurve::plus_earth) {
            // 地形の受領時にも離着陸の時計を進め、同じ余弦位相で現在高と到着高を結ぶ。
            const double remaining_weight = plus_flight_weight(1 - progress);
            if (remaining_weight > 0)
                flight.start_height = flight.end_height + (height - flight.end_height) / remaining_weight;
        } else {
            flight.start_time = flight.previous_time;
            flight.duration *= 1.0 - progress;
            flight.start_height = height;
            flight.start_elevation = site_.elevation_deg;
            flight.start_roll = site_.roll_deg;
            flight.start_heading = site_.heading_deg;
        }
    }
    site_.terrain_offset_km = offset_km;
    site_.height_km = height;
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
    SolarCameraBasis frame{
        {-forward.x, -forward.y, -forward.z},
        {east.x * ch - north.x * sh, east.y * ch - north.y * sh, east.z * ch - north.z * sh},
        {up.x * ce - horizontal.x * se, up.y * ce - horizontal.y * se, up.z * ce - horizontal.z * se}
    };
    const double roll = site_.roll_deg * radians_per_degree;
    const double cr = std::cos(roll), sr = std::sin(roll);
    const auto right = frame.right, cameraUp = frame.up;
    frame.right = {right.x * cr + cameraUp.x * sr, right.y * cr + cameraUp.y * sr, right.z * cr + cameraUp.z * sr};
    frame.up = {cameraUp.x * cr - right.x * sr, cameraUp.y * cr - right.y * sr, cameraUp.z * cr - right.z * sr};
    const double distance = (info.radius_km + site_.terrain_offset_km + site_.height_km) / astronomical_unit_km;
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

void SurfaceNavigation::begin_flight(double time, double height, double elevation, double roll,
                                     double duration, std::optional<double> arrival_heading, HeightCurve height_curve) {
    if (!std::isfinite(time)) throw std::invalid_argument("flight time must be finite");
    if (!std::isfinite(duration) || duration < 0) throw std::invalid_argument("flight duration must be nonnegative and finite");
    const double end_heading = arrival_heading.value_or(site_.heading_deg);
    if (duration == 0) {
        site_.height_km = height;
        site_.elevation_deg = elevation;
        site_.roll_deg = roll;
        site_.heading_deg = end_heading;
        interrupt();
        return;
    }
    if (site_.height_km == height && site_.elevation_deg == elevation && site_.roll_deg == roll
        && site_.heading_deg == end_heading) {
        interrupt();
        return;
    }
    flight_ = Flight{time, time, site_.height_km, height, site_.elevation_deg, elevation,
                     site_.roll_deg, roll, duration, site_.heading_deg, end_heading, height_curve};
}

void SurfaceNavigation::begin_ascent(double monotonic_seconds, double duration_seconds) {
    // 読み込みの前後で地形 offset が変わっても、到達先は基準球から同じ距離にする。
    const double target_height = surface_body_info(site_.body_index).radius_km * 8 - site_.terrain_offset_km;
    begin_flight(monotonic_seconds, std::max(site_.height_km, target_height),
                 -80, site_.roll_deg, duration_seconds);
}

void SurfaceNavigation::begin_earth_horizon_ascent(double time, double duration) {
    if (site_.body_index != 3) throw std::invalid_argument("Earth horizon takeoff requires an Earth site");
    // 旧Plusの既定zoomは地球半径の7.5倍。物理高度には同梱設定の
    // (ObjZ + ScreenZ) / (ScreenW / 180 × 2000) を掛ける。
    constexpr double takeoff_scale = 7.5;
    constexpr double height_per_zoom = (400.0 + 217.3) / 2000.0;
    const double height = earth_reference_radius_km * takeoff_scale * height_per_zoom - site_.terrain_offset_km;
    begin_flight(time, std::max(site_.height_km, height), -90, site_.roll_deg, duration,
                 std::nullopt, HeightCurve::plus_earth);
}

void SurfaceNavigation::begin_descent(double monotonic_seconds, double duration_seconds) {
    begin_flight(monotonic_seconds, minimum_surface_height_km, 0, site_.roll_deg, duration_seconds);
}

void SurfaceNavigation::begin_descent_preserving_look(double monotonic_seconds, double duration_seconds,
                                                      bool level_roll) {
    begin_flight(monotonic_seconds, minimum_surface_height_km, site_.elevation_deg,
                 level_roll ? 0 : site_.roll_deg, duration_seconds);
}

void SurfaceNavigation::begin_descent_to_view(double time, double duration, const SurfaceSite& ground_view) {
    SurfaceNavigation destination;
    destination.set_site(ground_view);
    const auto& view = destination.site();
    begin_flight(time, minimum_surface_height_km, view.elevation_deg, view.roll_deg, duration, view.heading_deg,
                 site_.body_index == 3 ? HeightCurve::plus_earth : HeightCurve::logarithmic);
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
    const double old_height = site_.height_km, old_elevation = site_.elevation_deg, old_roll = site_.roll_deg;
    const double old_heading = site_.heading_deg;
    double height, look_progress = smooth;
    if (flight.height_curve == HeightCurve::plus_earth) {
        const double weight = plus_flight_weight(t);
        height = flight.start_height * (1 - weight) + flight.end_height * weight;
        const double start = earth_horizon_look_weight(flight.start_height + site_.terrain_offset_km);
        const double end = earth_horizon_look_weight(flight.end_height + site_.terrain_offset_km);
        if (start != end)
            look_progress = std::clamp((earth_horizon_look_weight(height + site_.terrain_offset_km) - start)
                                       / (end - start), 0.0, 1.0);
    } else {
        height = std::exp(std::log(flight.start_height) * (1 - smooth) + std::log(flight.end_height) * smooth);
    }
    site_.height_km = std::clamp(height, minimum_surface_height_km, maximum_height_km);
    site_.elevation_deg = flight.start_elevation * (1 - look_progress) + flight.end_elevation * look_progress;
    site_.roll_deg = std::remainder(flight.start_roll + smooth * std::remainder(flight.end_roll - flight.start_roll, 360.0), 360.0);
    site_.heading_deg = heading(flight.start_heading + smooth * std::remainder(flight.end_heading - flight.start_heading, 360.0));
    if (t == 1) {
        site_.height_km = flight.end_height;
        site_.elevation_deg = flight.end_elevation;
        site_.roll_deg = flight.end_roll;
        site_.heading_deg = flight.end_heading;
        interrupt();
    }
    return site_.height_km != old_height || site_.elevation_deg != old_elevation || site_.roll_deg != old_roll
        || site_.heading_deg != old_heading;
}

void SurfaceNavigation::look(double dx_points, double dy_points) {
    if (!std::isfinite(dx_points) || !std::isfinite(dy_points))
        throw std::invalid_argument("surface look movement must be finite");
    auto next = site_;
    next.heading_deg = heading(next.heading_deg - std::remainder(dx_points, 360 / 0.35) * 0.35);
    next.elevation_deg = std::clamp(next.elevation_deg + std::clamp(dy_points, -1000.0, 1000.0) * 0.35,
                                  -90.0, 90.0);
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
