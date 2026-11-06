#include "sky_model.hpp"
#include "horizon_projection_constants.hpp"
#include "mitaka/lunar.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>
#include <string>
#include <unordered_set>

namespace mitaka::gui {
namespace {

// CF96 の格納順は水・金・地月重心・火・木・土・天・海・冥王星系重心。
constexpr std::size_t earth_moon_barycenter_index = 2;
constexpr std::array<std::pair<Body, std::size_t>, 8> planet_indices{{
    {Body::mercury, 0}, {Body::venus, 1}, {Body::mars, 3}, {Body::jupiter, 4},
    {Body::saturn, 5}, {Body::uranus, 6}, {Body::neptune, 7}, {Body::pluto, 8}
}};
constexpr std::array<Body, 9> solar_order{Body::mercury, Body::venus,
    Body::earth, Body::mars, Body::jupiter, Body::saturn,
    Body::uranus, Body::neptune, Body::pluto};
constexpr std::array<Planet, 9> rotation_order{Planet::mercury, Planet::venus,
    Planet::earth, Planet::mars, Planet::jupiter, Planet::saturn,
    Planet::uranus, Planet::neptune, Planet::pluto};

// 軌跡を切り取る表示用の近似公転日数。位置計算には使用しない。
constexpr std::array<double, 9> display_period_days{
    87.97, 224.70, 365.26, 686.98, 4332.59, 10759.22, 30688.5, 60182, 90560};
constexpr double lunar_display_period_days = 27.321661;

Vec3 earth_center(const std::array<double, 3>& barycenter, Vec3 geocentric_moon) {
    constexpr double mass_factor = 1 / (earth_moon_mass_ratio + 1);
    return {barycenter[0] - geocentric_moon.x * mass_factor,
            barycenter[1] - geocentric_moon.y * mass_factor,
            barycenter[2] - geocentric_moon.z * mass_factor};
}

template<typename Position>
std::vector<Vec3> sample_orbit(double julian_date, double period,
                              std::pair<double, double> range, Position position) {
    constexpr std::size_t sample_count = 181;
    const double begin = std::max(range.first, julian_date - period / 2);
    const double end = std::min(range.second, julian_date + period / 2);
    std::vector<Vec3> path;
    path.reserve(sample_count);
    for (std::size_t sample = 0; sample < sample_count; ++sample) {
        const double date = sample == sample_count - 1 ? end
            : begin + (end - begin) * static_cast<double>(sample) / (sample_count - 1);
        path.push_back(position(date));
    }
    return path;
}

bool valid_declination(double declination) {
    return std::isfinite(declination) && declination >= -90 && declination <= 90;
}

void validate_viewport(const SkyViewport& viewport, double width, double height) {
    if (!std::isfinite(viewport.center_ra_deg) || !valid_declination(viewport.center_dec_deg)
        || !std::isfinite(viewport.zoom) || viewport.zoom < 1
        || !std::isfinite(viewport.roll_deg) || !std::isfinite(viewport.perspective_blend) || viewport.perspective_blend < 0
        || viewport.perspective_blend > 1
        || !std::isfinite(width) || width <= 0 || !std::isfinite(height) || height <= 0)
        throw std::invalid_argument("invalid sky viewport or dimensions");
}

void validate_viewport(const HorizonProjectionViewport& viewport, double width, double height) {
    if (!std::isfinite(viewport.center_ra_deg) || !valid_declination(viewport.center_dec_deg)
        || !std::isfinite(viewport.vertical_fov_deg) || viewport.vertical_fov_deg <= 0
        || viewport.vertical_fov_deg > 180 || !std::isfinite(viewport.roll_deg)
        || !std::isfinite(viewport.perspective_blend) || viewport.perspective_blend < 0
        || viewport.perspective_blend > 1 || !std::isfinite(width) || width <= 0
        || !std::isfinite(height) || height <= 0)
        throw std::invalid_argument("invalid horizon viewport or dimensions");
}

double normalized_ra(double ra) {
    const double result = std::fmod(ra, 360);
    return result < 0 ? result + 360 : result;
}

std::optional<ScreenPoint> project_validated(EquatorialCoordinates coordinates,
                                            const SkyViewport& viewport,
                                            double width, double height) {
    if (!std::isfinite(coordinates.right_ascension_deg)
        || !valid_declination(coordinates.declination_deg))
        throw std::invalid_argument("invalid sky coordinates");
    const double ra_delta = std::fmod(normalized_ra(coordinates.right_ascension_deg)
                                     - normalized_ra(viewport.center_ra_deg) + 540, 360) - 180;
    const double dec_delta = coordinates.declination_deg - viewport.center_dec_deg;
    const double half_width = 180 / viewport.zoom;
    const double half_height = 90 / viewport.zoom;
    if (std::abs(ra_delta) > half_width || std::abs(dec_delta) > half_height)
        return std::nullopt;
    return ScreenPoint{(0.5 - 0.5 * ra_delta / half_width) * width,
                       (0.5 - 0.5 * dec_delta / half_height) * height};
}

SkyBody body_from_position(Body id, Vec3 position) {
    const double distance = std::hypot(position.x, position.y, position.z);
    if (!std::isfinite(distance) || distance <= 0)
        throw std::runtime_error("body has no finite nonzero geocentric distance");
    return {id, equatorial_coordinates(position), distance};
}

} // namespace

SkyModel::SkyModel(std::vector<HipparcosRecord> stars,
                   std::vector<ConstellationRecord> constellations, Cf96Ephemeris ephemeris,
                   std::pair<double, double> time_range, std::string constellation_warning)
    : stars_(std::move(stars)), constellations_(std::move(constellations)),
      constellation_warning_(std::move(constellation_warning)),
      ephemeris_(std::move(ephemeris)), time_range_(time_range) {
    for (std::size_t index = 0; index < stars_.size(); ++index)
        star_indices_.emplace(stars_[index].hip, index);
    std::unordered_set<std::int32_t> missing;
    for (const auto& constellation : constellations_)
        for (const auto& line : constellation.hip_lines)
            for (const auto hip : line)
                if (!star_index(hip)) missing.insert(hip);
    if (!missing.empty())
        constellation_warning_ = std::to_string(missing.size())
            + " constellation HIP references unavailable; affected segments are omitted";
}

std::optional<std::size_t> SkyModel::star_index(std::int32_t hip) const noexcept {
    const auto found = star_indices_.find(hip);
    return found == star_indices_.end() ? std::nullopt
                                       : std::optional<std::size_t>{found->second};
}

SkyModel SkyModel::load(const std::filesystem::path& data_directory) {
    if (data_directory.empty())
        throw std::invalid_argument("data_directory must be specified");
    auto stars = load_hipparcos(data_directory / "hip.dat");
    for (std::size_t index = 0; index < stars.size(); ++index) {
        if (!valid_declination(stars[index].declination_degrees))
            throw CatalogError(data_directory / "hip.dat", index * 45 + 8,
                               "declination must be within [-90, 90] degrees");
    }
    const auto constellation_path = data_directory / "constellation_HIP.dat";
    std::vector<ConstellationRecord> constellations;
    std::string constellation_warning;
    if (std::filesystem::exists(constellation_path)) {
        constellations = load_constellations(constellation_path);
        for (const auto& constellation : constellations) {
            if (!valid_declination(constellation.declination_degrees))
                throw CatalogError(constellation_path, 0, "invalid constellation label declination");
            for (const auto& point : constellation.boundary)
                if (!valid_declination(point.declination_degrees))
                    throw CatalogError(constellation_path, 0, "invalid constellation boundary declination");
        }
    } else {
        constellation_warning = "constellation_HIP.dat is absent; constellation overlays unavailable";
    }
    auto ephemeris = Cf96Ephemeris::load(data_directory / "cf96.dat");
    if (ephemeris.planet_count() != 9)
        throw std::runtime_error((data_directory / "cf96.dat").string()
                                 + ": sky display requires all 9 CF96 planets");
    auto range = ephemeris.time_range(0);
    for (std::size_t index = 1; index < ephemeris.planet_count(); ++index) {
        const auto planet_range = ephemeris.time_range(index);
        range.first = std::max(range.first, planet_range.first);
        range.second = std::min(range.second, planet_range.second);
    }
    range.first = std::max(range.first, lunar_minimum_jd);
    range.second = std::min(range.second, lunar_maximum_jd);
    if (range.first > range.second)
        throw std::runtime_error((data_directory / "cf96.dat").string()
                                 + ": CF96 planets and lunar model have no common time range");
    return SkyModel(std::move(stars), std::move(constellations), std::move(ephemeris),
                    range, std::move(constellation_warning));
}

void SkyModel::validate_date(double julian_date) const {
    if (!std::isfinite(julian_date))
        throw std::invalid_argument("julian_date must be finite");
    if (julian_date < time_range_.first || julian_date > time_range_.second)
        throw std::out_of_range("julian_date outside common CF96 and lunar coverage");
}

SkyBodies SkyModel::bodies(double julian_date) const {
    validate_date(julian_date);
    const auto moon = lunar_position(julian_date);
    const auto earth = earth_center(
        ephemeris_.state(earth_moon_barycenter_index, julian_date).position_au, moon);
    SkyBodies result{};
    result[0] = body_from_position(Body::sun, {-earth.x, -earth.y, -earth.z});
    for (std::size_t index = 0; index < planet_indices.size(); ++index) {
        const auto [id, cf96_index] = planet_indices[index];
        const auto planet = ephemeris_.state(cf96_index, julian_date).position_au;
        result[index + 1] = body_from_position(id, {planet[0] - earth.x,
                                                  planet[1] - earth.y,
                                                  planet[2] - earth.z});
    }
    result.back() = body_from_position(Body::moon, moon);
    return result;
}

SolarBodies SkyModel::solar_bodies(double julian_date) const {
    validate_date(julian_date);
    const auto moon = lunar_position(julian_date);
    SolarBodies result{};
    result[0] = {Body::sun, {0, 0, 0}};
    for (std::size_t planet = 0; planet < solar_order.size(); ++planet) {
        const auto point = ephemeris_.state(planet, julian_date).position_au;
        result[planet + 1] = {solar_order[planet], {point[0], point[1], point[2]},
                             planet_orientation(rotation_order[planet], julian_date)};
        if (planet == earth_moon_barycenter_index)
            result[planet + 1].position_au = earth_center(point, moon);
    }
    const auto earth = result[earth_moon_barycenter_index + 1].position_au;
    result.back() = {Body::moon, {earth.x + moon.x, earth.y + moon.y, earth.z + moon.z},
                     lunar_orientation(julian_date)};
    return result;
}

SolarOrbits SkyModel::solar_orbits(double julian_date) const {
    validate_date(julian_date);
    SolarOrbits result;
    for (std::size_t planet = 0; planet < result.size(); ++planet) {
        result[planet] = sample_orbit(julian_date, display_period_days[planet], time_range_,
          [&](double date) -> Vec3 {
            const auto point = ephemeris_.state(planet, date).position_au;
            if (planet == earth_moon_barycenter_index)
                return earth_center(point, lunar_position(date));
            return {point[0], point[1], point[2]};
          });
    }
    return result;
}

std::vector<Vec3> SkyModel::lunar_orbit(double julian_date) const {
    validate_date(julian_date);
    return sample_orbit(julian_date, lunar_display_period_days, time_range_, lunar_position);
}

SkyViewport normalize_sky_viewport(SkyViewport viewport, bool allow_pole_center) {
    if (!std::isfinite(viewport.center_ra_deg) || !std::isfinite(viewport.center_dec_deg)
        || !std::isfinite(viewport.zoom) || viewport.zoom <= 0
        || !std::isfinite(viewport.roll_deg) || !std::isfinite(viewport.perspective_blend) || viewport.perspective_blend < 0
        || viewport.perspective_blend > 1)
        throw std::invalid_argument("invalid sky viewport");
    viewport.zoom = std::clamp(viewport.zoom, 1.0, 180.0);
    viewport.center_ra_deg = normalized_ra(viewport.center_ra_deg);
    const double limit = allow_pole_center ? 90 : 90 - 90 / viewport.zoom;
    viewport.center_dec_deg = std::clamp(viewport.center_dec_deg, -limit, limit);
    return viewport;
}

SkyViewport pan_sky(SkyViewport viewport, double delta_x, double delta_y,
                    double width, double height, bool allow_pole_center) {
    validate_viewport(viewport, width, height);
    if (!std::isfinite(delta_x) || !std::isfinite(delta_y))
        throw std::invalid_argument("invalid sky pan distance");
    const double horizontal = delta_x / width * (360 / viewport.zoom);
    const double vertical = delta_y / height * (180 / viewport.zoom);
    const double roll = viewport.roll_deg * std::acos(-1.0) / 180.0;
    viewport.center_ra_deg += horizontal * std::cos(roll) + vertical * std::sin(roll);
    viewport.center_dec_deg += vertical * std::cos(roll) - horizontal * std::sin(roll);
    return normalize_sky_viewport(viewport, allow_pole_center);
}

SkyViewport zoom_sky(SkyViewport viewport, double factor, ScreenPoint anchor,
                     double width, double height, bool allow_pole_center) {
    validate_viewport(viewport, width, height);
    if (!std::isfinite(factor) || factor <= 0 || !std::isfinite(anchor.x)
        || !std::isfinite(anchor.y)) throw std::invalid_argument("invalid sky zoom parameters");
    const double zoom = std::clamp(viewport.zoom * factor, 1.0, 180.0);
    const double span_change = 1 / viewport.zoom - 1 / zoom;
    viewport.center_ra_deg += (0.5 - std::clamp(anchor.x / width, 0.0, 1.0)) * 360 * span_change;
    viewport.center_dec_deg += (0.5 - std::clamp(anchor.y / height, 0.0, 1.0)) * 180 * span_change;
    viewport.zoom = zoom;
    return normalize_sky_viewport(viewport, allow_pole_center);
}

std::optional<ScreenPoint> project_sky(EquatorialCoordinates coordinates,
                                     const SkyViewport& viewport,
                                     double width, double height) {
    validate_viewport(viewport, width, height);
    return project_validated(coordinates, viewport, width, height);
}

std::vector<ScreenSegment> project_sky_segment(EquatorialCoordinates start,
                                              EquatorialCoordinates end,
                                              const SkyViewport& viewport,
                                              double width, double height) {
    validate_viewport(viewport, width, height);
    project_validated(start, viewport, width, height);
    project_validated(end, viewport, width, height);
    const double ra_start = std::fmod(normalized_ra(start.right_ascension_deg)
        - normalized_ra(viewport.center_ra_deg) + 540, 360) - 180;
    const double ra_span = std::fmod(normalized_ra(end.right_ascension_deg)
        - normalized_ra(start.right_ascension_deg) + 540, 360) - 180;
    const double dx = -ra_span / 360 * viewport.zoom * width;
    const double dy = -(end.declination_deg - start.declination_deg) / 180 * viewport.zoom * height;
    std::vector<ScreenSegment> segments;
    for (const double wrap : {-360.0, 0.0, 360.0}) {
        const double x = (0.5 - (ra_start + wrap) / 360 * viewport.zoom) * width;
        const double y = (0.5 - (start.declination_deg - viewport.center_dec_deg)
                                   / 180 * viewport.zoom) * height;
        double enter = 0, leave = 1;
        const auto clip = [&](double direction, double distance) {
            if (direction == 0) return distance >= 0;
            const double ratio = distance / direction;
            if (direction < 0) enter = std::max(enter, ratio);
            else leave = std::min(leave, ratio);
            return enter <= leave;
        };
        if (clip(-dx, x) && clip(dx, width - x) && clip(-dy, y) && clip(dy, height - y))
            segments.push_back({{x + enter * dx, y + enter * dy},
                                {x + leave * dx, y + leave * dy}});
    }
    return segments;
}

namespace {
constexpr double horizon_radians = 3.14159265358979323846 / 180;
// 方向を絶対角 double で保持するため、これ未満の描画は区別できない。
// 保存・取得値は変更せず、射影計算の安定化だけに使う。
constexpr double minimum_render_fov_deg = horizon_minimum_render_fov_deg;
constexpr double perspective_scale = horizon_perspective_scale;

double horizon_longitude(double u, double fov, double aspect, double blend) {
    return (1 - blend) * (-u * fov * horizon_radians)
        + blend * std::atan2(-u * perspective_scale * aspect, 1.0);
}

double horizon_latitude(double v, double fov, double denominator, double blend) {
    return (1 - blend) * (v * fov * horizon_radians / 2)
        + blend * std::atan2(v * perspective_scale, denominator);
}

double perspective_denominator(double u, double aspect) {
    return std::hypot(1.0, u * perspective_scale * aspect);
}

EquatorialCoordinates inverse_horizon(double center_ra, double cos_tilt, double sin_tilt,
                                     double cos_longitude, double sin_longitude,
                                     double cos_latitude, double sin_latitude, double cos_roll, double sin_roll) {
    const double x = cos_latitude * cos_longitude;
    const double rolled_y = cos_latitude * sin_longitude;
    const double y = rolled_y * cos_roll + sin_latitude * sin_roll;
    const double z = sin_latitude * cos_roll - rolled_y * sin_roll;
    const double horizontal_x = x * cos_tilt - z * sin_tilt;
    const double vertical = z * cos_tilt + x * sin_tilt;
    return {normalized_ra(center_ra + std::atan2(y, horizontal_x) / horizon_radians),
            std::atan2(vertical, std::hypot(horizontal_x, y)) / horizon_radians};
}
}

HorizonProjectionViewport normalize_horizon_viewport(HorizonProjectionViewport viewport) {
    if (!std::isfinite(viewport.center_ra_deg) || !std::isfinite(viewport.center_dec_deg)
        || !std::isfinite(viewport.vertical_fov_deg) || viewport.vertical_fov_deg <= 0
        || viewport.vertical_fov_deg > 180 || !std::isfinite(viewport.roll_deg)
        || !std::isfinite(viewport.perspective_blend) || viewport.perspective_blend < 0
        || viewport.perspective_blend > 1)
        throw std::invalid_argument("invalid horizon viewport");
    viewport.center_ra_deg = normalized_ra(viewport.center_ra_deg);
    viewport.center_dec_deg = std::clamp(viewport.center_dec_deg, -90.0, 90.0);
    return viewport;
}

HorizonProjectionViewport pan_horizon(HorizonProjectionViewport viewport, double delta_x, double delta_y,
                                      double width, double height) {
    validate_viewport(viewport, width, height);
    if (!std::isfinite(delta_x) || !std::isfinite(delta_y))
        throw std::invalid_argument("invalid horizon pan distance");
    const double fov = std::max(viewport.vertical_fov_deg, minimum_render_fov_deg);
    const double horizontal = delta_x / width * (2 * fov);
    const double vertical = delta_y / height * fov;
    const double roll = viewport.roll_deg * horizon_radians;
    viewport.center_ra_deg += horizontal * std::cos(roll) + vertical * std::sin(roll);
    viewport.center_dec_deg += vertical * std::cos(roll) - horizontal * std::sin(roll);
    return normalize_horizon_viewport(viewport);
}

EquatorialCoordinates rotate_horizon(EquatorialCoordinates point, const HorizonProjectionViewport& viewport) {
    if (!std::isfinite(point.right_ascension_deg) || !valid_declination(point.declination_deg))
        throw std::invalid_argument("invalid horizon coordinates");
    const double longitude = (point.right_ascension_deg - viewport.center_ra_deg) * horizon_radians;
    const double latitude = point.declination_deg * horizon_radians;
    const double tilt = viewport.center_dec_deg * horizon_radians;
    const double x = std::cos(latitude) * std::cos(longitude);
    const double y = std::cos(latitude) * std::sin(longitude);
    const double z = std::sin(latitude);
    const double forward = x * std::cos(tilt) + z * std::sin(tilt);
    const double vertical = z * std::cos(tilt) - x * std::sin(tilt);
    const double roll = viewport.roll_deg * horizon_radians;
    const double right = y * std::cos(roll) - vertical * std::sin(roll);
    const double up = vertical * std::cos(roll) + y * std::sin(roll);
    return {normalized_ra(std::atan2(right, forward) / horizon_radians),
            std::atan2(up, std::hypot(forward, right)) / horizon_radians};
}

std::optional<ScreenPoint> project_horizon(EquatorialCoordinates coordinates,
                                         const HorizonProjectionViewport& viewport,
                                         double width, double height) {
    validate_viewport(viewport, width, height);
    const auto rotated = rotate_horizon(coordinates, viewport);
    const double blend = viewport.perspective_blend;
    const double fov = std::max(viewport.vertical_fov_deg, minimum_render_fov_deg);
    const double aspect = width / height;
    const double longitude = std::remainder(rotated.right_ascension_deg, 360.0) * horizon_radians;
    const double latitude = rotated.declination_deg * horizon_radians;
    if (longitude > horizon_longitude(-1, fov, aspect, blend)
        || longitude < horizon_longitude(1, fov, aspect, blend)) return std::nullopt;
    double left = -1, right = 1;
    double u = -longitude / horizon_longitude(-1, fov, aspect, blend);
    for (int iteration = 0; iteration < 32; ++iteration) {
        const double error = horizon_longitude(u, fov, aspect, blend) - longitude;
        if (std::abs(error) <= 1e-12 * std::abs(horizon_longitude(-1, fov, aspect, blend))) break;
        if (error > 0) left = u;
        else right = u;
        const double scale = perspective_scale * aspect;
        const double slope = -(1 - blend) * fov * horizon_radians
            - blend * scale / (1 + u * u * scale * scale);
        const double candidate = u - error / slope;
        u = candidate > left && candidate < right ? candidate : (left + right) / 2;
    }
    const double denominator = perspective_denominator(u, aspect);
    if (latitude < horizon_latitude(-1, fov, denominator, blend)
        || latitude > horizon_latitude(1, fov, denominator, blend)) return std::nullopt;
    double bottom = -1, top = 1;
    double v = latitude / horizon_latitude(1, fov, denominator, blend);
    for (int iteration = 0; iteration < 32; ++iteration) {
        const double error = horizon_latitude(v, fov, denominator, blend) - latitude;
        if (std::abs(error) <= 1e-12 * std::abs(horizon_latitude(1, fov, denominator, blend))) break;
        if (error < 0) bottom = v;
        else top = v;
        const double vertical = v * perspective_scale;
        const double slope = (1 - blend) * fov * horizon_radians / 2
            + blend * perspective_scale * denominator / (denominator * denominator + vertical * vertical);
        const double candidate = v - error / slope;
        v = candidate > bottom && candidate < top ? candidate : (bottom + top) / 2;
    }
    return ScreenPoint{(u + 1) * width / 2, (1 - v) * height / 2};
}

EquatorialCoordinates unproject_horizon(ScreenPoint point, const HorizonProjectionViewport& viewport,
                                        double width, double height) {
    validate_viewport(viewport, width, height);
    if (!std::isfinite(point.x) || !std::isfinite(point.y) || point.x < 0 || point.x > width ||
        point.y < 0 || point.y > height)
        throw std::invalid_argument("invalid horizon screen point");
    const double u = 2 * point.x / width - 1;
    const double v = 1 - 2 * point.y / height;
    const double longitude = horizon_longitude(u, std::max(viewport.vertical_fov_deg, minimum_render_fov_deg), width / height, viewport.perspective_blend);
    const double latitude = horizon_latitude(v, std::max(viewport.vertical_fov_deg, minimum_render_fov_deg), perspective_denominator(u, width / height),
                                             viewport.perspective_blend);
    const double tilt = viewport.center_dec_deg * horizon_radians;
    return inverse_horizon(viewport.center_ra_deg, std::cos(tilt), std::sin(tilt),
                           std::cos(longitude), std::sin(longitude),
                           std::cos(latitude), std::sin(latitude),
                           std::cos(viewport.roll_deg * horizon_radians), std::sin(viewport.roll_deg * horizon_radians));
}

HorizonRasterProjection::HorizonRasterProjection(const HorizonProjectionViewport& viewport,
                                                 std::size_t width, std::size_t height)
    : center_ra_deg_(viewport.center_ra_deg),
      cos_tilt_(std::cos(viewport.center_dec_deg * horizon_radians)),
      sin_tilt_(std::sin(viewport.center_dec_deg * horizon_radians)),
      cos_roll_(std::cos(viewport.roll_deg * horizon_radians)),
      sin_roll_(std::sin(viewport.roll_deg * horizon_radians)),
      perspective_blend_(viewport.perspective_blend), vertical_fov_deg_(std::max(viewport.vertical_fov_deg, minimum_render_fov_deg)) {
    validate_viewport(viewport, width, height);
    longitudes_.reserve(width);
    latitudes_.reserve(height);
    perspective_denominators_.reserve(width);
    vertical_coordinates_.reserve(height);
    for (std::size_t x = 0; x < width; ++x) {
        const double u = 2 * (x + 0.5) / width - 1;
        const double aspect = static_cast<double>(width) / height;
        const double angle = horizon_longitude(u, std::max(viewport.vertical_fov_deg, minimum_render_fov_deg), aspect, perspective_blend_);
        longitudes_.push_back({std::cos(angle), std::sin(angle)});
        perspective_denominators_.push_back(perspective_denominator(u, aspect));
    }
    for (std::size_t y = 0; y < height; ++y) {
        const double v = 1 - 2 * (y + 0.5) / height;
        const double angle = v * std::max(viewport.vertical_fov_deg, minimum_render_fov_deg) * horizon_radians / 2;
        latitudes_.push_back({std::cos(angle), std::sin(angle)});
        vertical_coordinates_.push_back(v);
    }
}

EquatorialCoordinates HorizonRasterProjection::direction(std::size_t x, std::size_t y) const {
    const auto& longitude = longitudes_[x];
    if (perspective_blend_ != 0) {
        const double angle = horizon_latitude(vertical_coordinates_[y], vertical_fov_deg_,
                                              perspective_denominators_[x], perspective_blend_);
        return inverse_horizon(center_ra_deg_, cos_tilt_, sin_tilt_, longitude[0], longitude[1],
                               std::cos(angle), std::sin(angle), cos_roll_, sin_roll_);
    }
    const auto& latitude = latitudes_[y];
    return inverse_horizon(center_ra_deg_, cos_tilt_, sin_tilt_,
                           longitude[0], longitude[1], latitude[0], latitude[1], cos_roll_, sin_roll_);
}

HorizonProjectionViewport zoom_horizon(HorizonProjectionViewport viewport, double factor, ScreenPoint anchor,
                         double width, double height) {
    validate_viewport(viewport, width, height);
    if (!std::isfinite(factor) || factor <= 0 || !std::isfinite(anchor.x) || !std::isfinite(anchor.y))
        throw std::invalid_argument("invalid horizon zoom parameters");
    if (factor == 1) return viewport;
    anchor.x = std::clamp(anchor.x, 0.0, width);
    anchor.y = std::clamp(anchor.y, 0.0, height);
    const auto target = unproject_horizon(anchor, viewport, width, height);
    // 縮小は描画下限から始め、拡大では保存値を増やさない。
    const double start_fov = factor < 1 ? std::max(viewport.vertical_fov_deg, minimum_render_fov_deg)
                                        : viewport.vertical_fov_deg;
    const double fov = std::clamp(start_fov / factor,
                                  std::numeric_limits<double>::denorm_min(), 180.0);
    if (fov == viewport.vertical_fov_deg) return viewport;
    const double latitude = target.declination_deg * horizon_radians;
    const double u = 2 * anchor.x / width - 1;
    const double v = 1 - 2 * anchor.y / height;
    const double longitude_screen = horizon_longitude(u, std::max(fov, minimum_render_fov_deg), width / height, viewport.perspective_blend);
    const double latitude_screen = horizon_latitude(v, std::max(fov, minimum_render_fov_deg), perspective_denominator(u, width / height),
                                                     viewport.perspective_blend);
    const double qx = std::cos(latitude_screen) * std::cos(longitude_screen);
    const double rolled_y = std::cos(latitude_screen) * std::sin(longitude_screen);
    const double rolled_z = std::sin(latitude_screen);
    const double roll = viewport.roll_deg * horizon_radians;
    const double qy = rolled_y * std::cos(roll) + rolled_z * std::sin(roll);
    const double qz = rolled_z * std::cos(roll) - rolled_y * std::sin(roll);
    const double cos_latitude = std::cos(latitude);
    viewport.vertical_fov_deg = fov;
    if (std::abs(cos_latitude) < 1e-12 || std::abs(qy) > cos_latitude + 1e-12)
        return normalize_horizon_viewport(viewport);
    const double first = std::asin(std::clamp(qy / cos_latitude, -1.0, 1.0));
    double best_distance = std::numeric_limits<double>::infinity();
    auto result = normalize_horizon_viewport(viewport);
    for (const double delta : {first, 3.14159265358979323846 - first}) {
        const double tilt = std::remainder(std::atan2(std::sin(latitude), cos_latitude * std::cos(delta))
                                           - std::atan2(qz, qx), 2 * 3.14159265358979323846);
        if (std::abs(tilt) > 3.14159265358979323846 / 2 + 1e-12) continue;
        const double center_ra = normalized_ra(target.right_ascension_deg - delta / horizon_radians);
        const double center_dec = tilt / horizon_radians;
        const double distance = std::hypot(std::remainder(center_ra - viewport.center_ra_deg, 360.0)
                                           * std::cos(viewport.center_dec_deg * horizon_radians),
                                           center_dec - viewport.center_dec_deg);
        if (distance < best_distance) {
            best_distance = distance;
            result = normalize_horizon_viewport({center_ra, center_dec, fov, viewport.perspective_blend, viewport.roll_deg});
        }
    }
    return result;
}

std::optional<Selection> pick_object(const SkyModel& model, const SkyBodies& bodies,
                                     const SkyViewport& viewport,
                                     double width, double height, double x, double y,
                                     double magnitude_limit, double radius,
                                     bool stars_visible, bool bodies_visible) {
    validate_viewport(viewport, width, height);
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(magnitude_limit)
        || !std::isfinite(radius) || radius < 0)
        throw std::invalid_argument("invalid sky selection parameters");
    if (x < 0 || y < 0 || x > width || y > height) return std::nullopt;
    std::optional<Selection> result;
    double nearest_distance = radius;
    const auto consider = [&](EquatorialCoordinates coordinates, Selection selection) {
        const auto point = project_validated(coordinates, viewport, width, height);
        if (!point) return;
        const double distance = std::hypot(point->x - x, point->y - y);
        const bool body_tie = selection.kind == ObjectKind::body
                             && result && result->kind == ObjectKind::star;
        if (distance < nearest_distance
            || (distance == nearest_distance && (!result || body_tie))) {
            result = selection;
            nearest_distance = distance;
        }
    };
    for (std::size_t index = 0; stars_visible && index < model.stars().size(); ++index) {
        const auto& star = model.stars()[index];
        if (star.apparent_v_magnitude > magnitude_limit) continue;
        consider({star.right_ascension_degrees, star.declination_degrees},
                 {ObjectKind::star, index});
    }
    for (std::size_t index = 0; bodies_visible && index < bodies.size(); ++index)
        consider(bodies[index].coordinates, {ObjectKind::body, index});
    return result;
}

} // namespace mitaka::gui
