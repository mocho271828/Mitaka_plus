#include "horizon_objects.hpp"
#include "surface_navigation.hpp"

#include <cmath>

namespace mitaka::gui {
namespace {
bool finite(Vec3 v) {
    return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z);
}

std::optional<HorizonObject> make_object(std::size_t index, Vec3 ecliptic,
                                         Vec3 earth, Vec3 observer, bool body, bool label) {
    if (!finite(ecliptic) || !finite(observer)) return std::nullopt;
    const Vec3 equatorial = j2000_ecliptic_to_equatorial(ecliptic);
    const Vec3 geocentric{(equatorial.x - earth.x) - observer.x,
                          (equatorial.y - earth.y) - observer.y,
                          (equatorial.z - earth.z) - observer.z};
    if (!finite(geocentric)) return std::nullopt;
    const double distance = std::hypot(geocentric.x, geocentric.y, geocentric.z);
    if (!std::isfinite(distance) || distance <= 0) return std::nullopt;
    return HorizonObject{index, equatorial_coordinates(geocentric), distance, body, label};
}

bool matching_date(double snapshot_date, double julian_date, Vec3 earth) {
    return std::isfinite(julian_date) && snapshot_date == julian_date && finite(earth);
}
} // namespace

Vec3 horizon_observer_position(const ObservationFrame& frame) {
    const auto direction = equatorial_direction(frame.to_equatorial({0, 90}));
    const double radius = earth_reference_radius_km / astronomical_unit_km;
    return {direction.x * radius, direction.y * radius, direction.z * radius};
}

std::optional<EquatorialCoordinates> horizon_heliocentric_coordinates(Vec3 ecliptic, Vec3 earth, Vec3 observer) {
    const auto object = make_object(0, ecliptic, earth, observer, true, false);
    return object ? std::optional<EquatorialCoordinates>(object->coordinates) : std::nullopt;
}

std::vector<HorizonObject> horizon_small_body_objects(
    const SmallBodySnapshot& snapshot, const SmallBodyDisplayModel& display,
    double julian_date, Vec3 earth, Vec3 observer) {
    std::vector<HorizonObject> result;
    if (!snapshot.model || !matching_date(snapshot.julian_date, julian_date, earth)
        || display.dataset().get() != &snapshot.model->dataset()
        || snapshot.positions.size() != snapshot.model->dataset().records.size()) return result;
    for (std::size_t index = 0; index < snapshot.positions.size(); ++index) {
        const auto visibility = display.visibility(index);
        if (!visibility.body || !snapshot.positions[index]) continue;
        auto object = make_object(index, *snapshot.positions[index], earth, observer, true, visibility.label);
        if (object) result.push_back(*object);
    }
    return result;
}

std::vector<HorizonObject> horizon_spacecraft_objects(
    const SpacecraftSnapshot& snapshot, bool points, bool labels,
    double julian_date, Vec3 earth, Vec3 observer,
    const std::function<std::optional<Vec3>(const SpacecraftSnapshot&, std::size_t)>& position) {
    std::vector<HorizonObject> result;
    if ((!points && !labels) || !snapshot.model || !position
        || !matching_date(snapshot.julian_date, julian_date, earth)
        || snapshot.positions.size() != snapshot.model->model().dataset().definitions.size()
        || snapshot.evaluations.size() != snapshot.positions.size()) return result;
    for (std::size_t index = 0; index < snapshot.positions.size(); ++index) {
        const auto coordinate = position(snapshot, index);
        if (!coordinate) continue;
        auto object = make_object(index, *coordinate, earth, observer, points, labels);
        if (object) result.push_back(*object);
    }
    return result;
}
} // namespace mitaka::gui
