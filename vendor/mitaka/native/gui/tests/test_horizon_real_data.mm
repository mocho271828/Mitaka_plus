#include "horizon_objects.hpp"
#include "SpacecraftRenderer.h"
#include "sky_model.hpp"
#include "surface_navigation.hpp"
#include "mitaka/rotation.hpp"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
constexpr double pi = 3.14159265358979323846;

Vec3 subtract(Vec3 a, Vec3 b) {
    return {a.x - b.x, a.y - b.y, a.z - b.z};
}
double magnitude(Vec3 a) {
    return std::hypot(a.x, a.y, a.z);
}
Vec3 normalized(Vec3 a) {
    const double distance = magnitude(a);
    if (!(distance > 0)) throw std::runtime_error("zero distance");
    return {a.x / distance, a.y / distance, a.z / distance};
}

// 地球固定座標から独立に観測地点のベクトルを組み立てる。
Vec3 observer_reference(ObserverSite site, double jd) {
    const auto basis = planet_orientation(Planet::earth, jd);
    const double lat = site.latitude_deg * pi / 180;
    const double lon = site.longitude_deg * pi / 180;
    constexpr double f = 1.0 / 298.257223563;
    constexpr double e2 = f * (2 - f);
    const double scale = earth_reference_radius_km / astronomical_unit_km /
        std::sqrt(1 - e2 * std::sin(lat) * std::sin(lat));
    const double x = scale * std::cos(lat) * std::cos(lon);
    const double y = scale * std::cos(lat) * std::sin(lon);
    const double z = scale * (1 - e2) * std::sin(lat);
    return j2000_ecliptic_to_equatorial({
        (x * basis.x_axis.x + y * basis.y_axis.x + z * basis.north_axis.x),
        (x * basis.x_axis.y + y * basis.y_axis.y + z * basis.north_axis.y),
        (x * basis.x_axis.z + y * basis.y_axis.z + z * basis.north_axis.z)});
}

struct Stats {
    std::size_t count = 0;
    double max_shift_arcsec = 0;
};

Stats verify(const std::vector<HorizonObject>& objects,
             const std::vector<HorizonObject>& geocentric,
             const std::vector<std::optional<Vec3>>& positions, Vec3 earth, Vec3 observer) {
    if (objects.empty() || objects.size() != geocentric.size()) {
        throw std::runtime_error("missing positioned objects");
    }
    Stats stats;
    for (std::size_t i = 0; i < objects.size(); ++i) {
        const auto& object = objects[i];
        if (object.index != geocentric[i].index || object.index >= positions.size() || !positions[object.index]) {
            throw std::runtime_error("invalid object index");
        }
        const Vec3 geo = subtract(j2000_ecliptic_to_equatorial(*positions[object.index]), earth);
        const Vec3 topo = subtract(geo, observer);
        if (magnitude(subtract(equatorial_direction(object.coordinates), normalized(topo))) > 2e-12 ||
            magnitude(subtract(equatorial_direction(geocentric[i].coordinates), normalized(geo))) > 2e-12 ||
            std::abs(object.distance_au - magnitude(topo)) > 1e-12 ||
            std::abs(geocentric[i].distance_au - magnitude(geo)) > 1e-12) {
            throw std::runtime_error("topocentric or geocentric mismatch");
        }
        const double shift = magnitude(subtract(normalized(geo), normalized(topo))) * 180 / pi * 3600;
        stats.max_shift_arcsec = std::max(stats.max_shift_arcsec, shift);
        ++stats.count;
    }
    if (!(stats.max_shift_arcsec > 0)) throw std::runtime_error("missing parallax");
    return stats;
}
} // namespace

int main(int argc, char** argv) {
    try {
        if (argc != 2) throw std::runtime_error("data root required");
        const auto sky = SkyModel::load(argv[1]);
        const auto data = std::make_shared<const SmallBodyDataset>(load_small_body_dataset(argv[1]));
        const auto small = std::make_shared<SmallBodyModel>(data);
        const SmallBodyDisplayModel display(data);
        const auto probe = load_spacecraft_browser_model(argv[1]);
        for (double jd : {2451545.0, 2454000.0, 2458000.0}) {
            const auto earth = sky.solar_bodies(jd)[3].position_au;
            const auto small_snapshot = evaluate_small_body_snapshot(small, jd);
            const auto probe_snapshot = evaluate_spacecraft_snapshot(probe, jd);
            const auto geo_bodies = horizon_small_body_objects(*small_snapshot, display, jd, earth, {});
            const auto geo_probes = horizon_spacecraft_objects(*probe_snapshot, true, false, jd, earth, {}, spacecraft_scene_position);
            if (!horizon_small_body_objects(*small_snapshot, display, jd + 1, earth, {}).empty() ||
                !horizon_spacecraft_objects(*probe_snapshot, true, false, jd + 1, earth, {}, spacecraft_scene_position).empty()) {
                throw std::runtime_error("stale snapshot accepted");
            }
            for (ObserverSite site : {ObserverSite{0, 0}, ObserverSite{35.68, 139.76}, ObserverSite{-90, -180}}) {
                const ObservationFrame frame(site, jd);
                const auto observer = observer_reference(site, jd);
                const auto actual_observer = horizon_earth_observer_position(frame, site.latitude_deg);
                if (magnitude(subtract(observer, actual_observer)) > 1e-15) {
                    throw std::runtime_error("observer basis mismatch");
                }
                const auto bodies = horizon_small_body_objects(*small_snapshot, display, jd, earth, actual_observer);
                const auto probes = horizon_spacecraft_objects(*probe_snapshot, true, false, jd, earth, actual_observer, spacecraft_scene_position);
                const auto a = verify(bodies, geo_bodies, small_snapshot->positions, earth, observer);
                const auto b = verify(probes, geo_probes, probe_snapshot->positions, earth, observer);
                std::cout << "JD=" << jd << " site=" << site.latitude_deg << ',' << site.longitude_deg
                          << " small=" << a.count << " max_arcsec=" << a.max_shift_arcsec
                          << " PTH=" << b.count << " max_arcsec=" << b.max_shift_arcsec << '\n';
            }
        }
        std::cout << "real-data topocentric checks PASS\n";
    } catch (const std::exception& e) {
        std::cerr << "FAIL: " << e.what() << '\n';
        return 1;
    }
}
