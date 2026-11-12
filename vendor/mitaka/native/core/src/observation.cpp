#include "mitaka/observation.hpp"
#include "mitaka/rotation.hpp"

#include <cmath>
#include <stdexcept>

namespace mitaka {
namespace {
constexpr double radians_per_degree = 3.141592653589793238462643383279502884 / 180;
constexpr double vertical_tolerance = 1e-14;

double positive_degrees(double degrees) {
    const double reduced = std::fmod(degrees, 360);
    const double positive = reduced < 0 ? reduced + 360 : reduced;
    return positive >= 360 || positive == 0 ? 0 : positive;
}

void validate_longitude(double longitude) {
    if (!std::isfinite(longitude) || std::abs(longitude) > 180)
        throw std::invalid_argument("observation: longitude must be in [-180,180] degrees");
}

double dot(Vec3 first, Vec3 second) {
    return first.x * second.x + first.y * second.y + first.z * second.z;
}

Vec3 transform(Vec3 value, const BodyOrientation& orientation) {
    return j2000_ecliptic_to_equatorial({
        value.x * orientation.x_axis.x + value.y * orientation.y_axis.x + value.z * orientation.north_axis.x,
        value.x * orientation.x_axis.y + value.y * orientation.y_axis.y + value.z * orientation.north_axis.y,
        value.x * orientation.x_axis.z + value.y * orientation.y_axis.z + value.z * orientation.north_axis.z
    });
}
} // namespace

namespace {
void validate_site(ObserverSite site) {
    validate_longitude(site.longitude_deg);
    if (!std::isfinite(site.latitude_deg) || std::abs(site.latitude_deg) > 90)
        throw std::invalid_argument("observation: latitude must be in [-90,90] degrees");
}

void validate_orientation(const BodyOrientation& orientation) {
    const auto x = orientation.x_axis, y = orientation.y_axis, z = orientation.north_axis;
    const Vec3 cross{x.y*y.z - x.z*y.y, x.z*y.x - x.x*y.z, x.x*y.y - x.y*y.x};
    const auto close = [](double value, double expected) {
        return std::isfinite(value) && std::abs(value - expected) <= 1e-10;
    };
    if (!close(dot(x, x), 1) || !close(dot(y, y), 1) || !close(dot(z, z), 1)
        || !close(dot(x, y), 0) || !close(dot(y, z), 0) || !close(dot(z, x), 0)
        || !close(dot(cross, z), 1))
        throw std::invalid_argument("observation: orientation must be a right-handed orthonormal basis");
}
} // namespace

ObservationFrame::ObservationFrame(ObserverSite site, double julian_date) {
    validate_site(site);
    initialize(site, planet_orientation(Planet::earth, julian_date));
}

ObservationFrame::ObservationFrame(ObserverSite site, const BodyOrientation& orientation) {
    validate_site(site);
    validate_orientation(orientation);
    initialize(site, orientation);
}

void ObservationFrame::initialize(ObserverSite site, const BodyOrientation& orientation) {
    const double latitude = site.latitude_deg * radians_per_degree;
    const double longitude = site.longitude_deg * radians_per_degree;
    const double sin_lat = std::sin(latitude), cos_lat = std::cos(latitude);
    const double sin_lon = std::sin(longitude), cos_lon = std::cos(longitude);
    // 極でも指定した経度の子午線を使い、東・北の基準を保持する。
    east_ = transform({-sin_lon, cos_lon, 0}, orientation);
    north_ = transform({-sin_lat * cos_lon, -sin_lat * sin_lon, cos_lat}, orientation);
    up_ = transform({cos_lat * cos_lon, cos_lat * sin_lon, sin_lat}, orientation);
}

HorizontalCoordinates ObservationFrame::to_horizontal(EquatorialCoordinates coordinates) const {
    const auto direction = equatorial_direction(coordinates);
    const double east = dot(direction, east_), north = dot(direction, north_);
    const double horizontal_length = std::hypot(east, north);
    const double azimuth = horizontal_length <= vertical_tolerance
        ? 0 : positive_degrees(std::atan2(east, north) / radians_per_degree);
    return {azimuth, std::atan2(dot(direction, up_), horizontal_length) / radians_per_degree};
}

EquatorialCoordinates ObservationFrame::to_equatorial(HorizontalCoordinates coordinates) const {
    if (!std::isfinite(coordinates.azimuth_deg) || !std::isfinite(coordinates.altitude_deg)
        || std::abs(coordinates.altitude_deg) > 90)
        throw std::invalid_argument("observation: invalid horizontal coordinates");
    const double azimuth = std::remainder(coordinates.azimuth_deg, 360) * radians_per_degree;
    const double altitude = coordinates.altitude_deg * radians_per_degree;
    const double horizontal = std::cos(altitude);
    const double east = horizontal * std::sin(azimuth), north = horizontal * std::cos(azimuth);
    const double up = std::sin(altitude);
    return equatorial_coordinates({
        east * east_.x + north * north_.x + up * up_.x,
        east * east_.y + north * north_.y + up * up_.y,
        east * east_.z + north * north_.z + up * up_.z
    });
}

HorizontalCoordinates equatorial_to_horizontal(EquatorialCoordinates coordinates,
                                                ObserverSite site, double julian_date) {
    return ObservationFrame(site, julian_date).to_horizontal(coordinates);
}

EquatorialCoordinates horizontal_to_equatorial(HorizontalCoordinates coordinates,
                                                ObserverSite site, double julian_date) {
    return ObservationFrame(site, julian_date).to_equatorial(coordinates);
}

double greenwich_mean_sidereal_time_deg(double julian_date) {
    // 暦 API と同じ検証を通し、有限だが大きすぎる JD も拒否する。
    static_cast<void>(gregorian_date_time(julian_date));
    const double midnight = std::floor(julian_date - 0.5) + 0.5;
    const double days = midnight - 2451545.0;
    const double hours = (julian_date - midnight) * 24;
    const double centuries = (julian_date - 2451545.0) / 36525;
    // USNO Computing Approximate Sidereal Time の UT1=TT の式。
    const double sidereal_hours = 6.697375 + 0.065709824279 * days + 1.0027379 * hours
                                  + 0.0000258 * centuries * centuries;
    return positive_degrees(sidereal_hours * 15);
}

double local_mean_sidereal_time_deg(double julian_date, double east_longitude_deg) {
    validate_longitude(east_longitude_deg);
    return positive_degrees(greenwich_mean_sidereal_time_deg(julian_date) + east_longitude_deg);
}

} // namespace mitaka
