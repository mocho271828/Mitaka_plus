#include "horizon_objects.hpp"

#include <cmath>

namespace mitaka::gui {
namespace {
bool finite(Vec3 v) {
    return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z);
}

std::optional<HorizonObject> make_object(std::size_t index, Vec3 ecliptic,
                                         Vec3 earth, bool body, bool label) {
    if (!finite(ecliptic)) return std::nullopt;
    const Vec3 equatorial = j2000_ecliptic_to_equatorial(ecliptic);
    const Vec3 geocentric{equatorial.x - earth.x, equatorial.y - earth.y,
                          equatorial.z - earth.z};
    if (!finite(geocentric)) return std::nullopt;
    const double distance = std::hypot(geocentric.x, geocentric.y, geocentric.z);
    if (!std::isfinite(distance) || distance <= 0) return std::nullopt;
    return HorizonObject{index, equatorial_coordinates(geocentric), distance, body, label};
}

bool matching_date(double snapshot_date, double julian_date, Vec3 earth) {
    return std::isfinite(julian_date) && snapshot_date == julian_date && finite(earth);
}
} // namespace

std::optional<EquatorialCoordinates> horizon_heliocentric_coordinates(Vec3 ecliptic, Vec3 earth) {
    const auto object = make_object(0, ecliptic, earth, true, false);
    return object ? std::optional<EquatorialCoordinates>(object->coordinates) : std::nullopt;
}

std::vector<HorizonObject> horizon_small_body_objects(
    const SmallBodySnapshot& snapshot, const SmallBodyDisplayModel& display,
    double julian_date, Vec3 earth) {
    std::vector<HorizonObject> result;
    if (!snapshot.model || !matching_date(snapshot.julian_date, julian_date, earth)
        || display.dataset().get() != &snapshot.model->dataset()
        || snapshot.positions.size() != snapshot.model->dataset().records.size()) return result;
    for (std::size_t index = 0; index < snapshot.positions.size(); ++index) {
        const auto visibility = display.visibility(index);
        if (!visibility.body || !snapshot.positions[index]) continue;
        auto object = make_object(index, *snapshot.positions[index], earth, true, visibility.label);
        if (object) result.push_back(*object);
    }
    return result;
}

std::vector<HorizonObject> horizon_spacecraft_objects(
    const SpacecraftSnapshot& snapshot, bool points, bool labels,
    double julian_date, Vec3 earth,
    const std::function<std::optional<Vec3>(const SpacecraftSnapshot&, std::size_t)>& position) {
    std::vector<HorizonObject> result;
    if ((!points && !labels) || !snapshot.model || !position
        || !matching_date(snapshot.julian_date, julian_date, earth)
        || snapshot.positions.size() != snapshot.model->model().dataset().definitions.size()
        || snapshot.evaluations.size() != snapshot.positions.size()) return result;
    for (std::size_t index = 0; index < snapshot.positions.size(); ++index) {
        const auto coordinate = position(snapshot, index);
        if (!coordinate) continue;
        auto object = make_object(index, *coordinate, earth, points, labels);
        if (object) result.push_back(*object);
    }
    return result;
}
} // namespace mitaka::gui
