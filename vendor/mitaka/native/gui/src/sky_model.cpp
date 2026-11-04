#include "sky_model.hpp"
#include "mitaka/lunar.hpp"

#include <algorithm>
#include <cmath>
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
        || !std::isfinite(width) || width <= 0 || !std::isfinite(height) || height <= 0)
        throw std::invalid_argument("invalid sky viewport or dimensions");
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

SkyViewport normalize_sky_viewport(SkyViewport viewport) {
    if (!std::isfinite(viewport.center_ra_deg) || !std::isfinite(viewport.center_dec_deg)
        || !std::isfinite(viewport.zoom) || viewport.zoom <= 0)
        throw std::invalid_argument("invalid sky viewport");
    viewport.zoom = std::clamp(viewport.zoom, 1.0, 180.0);
    viewport.center_ra_deg = normalized_ra(viewport.center_ra_deg);
    const double limit = 90 - 90 / viewport.zoom;
    viewport.center_dec_deg = std::clamp(viewport.center_dec_deg, -limit, limit);
    return viewport;
}

SkyViewport pan_sky(SkyViewport viewport, double delta_x, double delta_y,
                    double width, double height) {
    validate_viewport(viewport, width, height);
    if (!std::isfinite(delta_x) || !std::isfinite(delta_y))
        throw std::invalid_argument("invalid sky pan distance");
    viewport.center_ra_deg += delta_x / width * (360 / viewport.zoom);
    viewport.center_dec_deg += delta_y / height * (180 / viewport.zoom);
    return normalize_sky_viewport(viewport);
}

SkyViewport zoom_sky(SkyViewport viewport, double factor, ScreenPoint anchor,
                     double width, double height) {
    validate_viewport(viewport, width, height);
    if (!std::isfinite(factor) || factor <= 0 || !std::isfinite(anchor.x)
        || !std::isfinite(anchor.y)) throw std::invalid_argument("invalid sky zoom parameters");
    const double zoom = std::clamp(viewport.zoom * factor, 1.0, 180.0);
    const double span_change = 1 / viewport.zoom - 1 / zoom;
    viewport.center_ra_deg += (0.5 - std::clamp(anchor.x / width, 0.0, 1.0)) * 360 * span_change;
    viewport.center_dec_deg += (0.5 - std::clamp(anchor.y / height, 0.0, 1.0)) * 180 * span_change;
    viewport.zoom = zoom;
    return normalize_sky_viewport(viewport);
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
