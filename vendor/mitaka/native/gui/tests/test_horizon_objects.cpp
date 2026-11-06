#include "horizon_objects.hpp"
#include "mitaka/rotation.hpp"
#include "mitaka/lunar.hpp"

#include <cmath>
#include "surface_navigation.hpp"
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
int checks = 0;
void require(bool value, const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
bool near(double a, double b) { return std::abs(a - b) < 1e-9; }

void parallax_tests() {
    constexpr double jd = 2451545;
    const double radius = earth_reference_radius_km / astronomical_unit_km;
    const ObservationFrame frame({0, 0}, jd);
    const auto observer = horizon_earth_observer_position(frame, 0);
    require(near(std::hypot(observer.x, observer.y, observer.z), radius), "observer radius");
    const auto zenith = frame.to_horizontal(equatorial_coordinates(observer));
    require(std::abs(zenith.altitude_deg - 90) < 1e-8, "observer points to zenith");
    // 基底 API から独立に期待値を組み、地球自転と両極を検証する。
    const auto distance = [](Vec3 a, Vec3 b) {
        return std::hypot(a.x-b.x, a.y-b.y, a.z-b.z);
    };
    for (double date : {jd, jd + 0.25}) {
        const auto orientation = planet_orientation(Planet::earth, date);
        const auto x = j2000_ecliptic_to_equatorial(orientation.x_axis);
        const auto north = j2000_ecliptic_to_equatorial(orientation.north_axis);
        constexpr double flattening = 1.0 / 298.257223563;
        const double polar_radius = radius * (1 - flattening);
        const auto equator = horizon_earth_observer_position(ObservationFrame({0, 0}, date), 0);
        require(distance(equator, {radius*x.x, radius*x.y, radius*x.z}) < 1e-15,
                "equatorial observer follows independent earth axis");
        for (double longitude : {0.0, 90.0, -180.0}) {
            for (double sign : {-1.0, 1.0}) {
                const auto pole = horizon_earth_observer_position(ObservationFrame({sign*90, longitude}, date), sign*90);
                require(distance(pole, {sign*polar_radius*north.x, sign*polar_radius*north.y, sign*polar_radius*north.z}) < 1e-15,
                        "polar observer follows independent north axis");
            }
        }
    }
    // 球面との差と南北の符号を、回転軸を使う独立の楕円体座標で確認する。
    constexpr double pi = 3.14159265358979323846;
    constexpr double f = 1.0 / 298.257223563;
    constexpr double e2 = f * (2 - f);
    for (double date : {jd, jd + 0.25}) {
        const auto orientation = planet_orientation(Planet::earth, date);
        for (double latitude : {-89.999, -45.0, 0.0, 35.68, 45.0, 89.999}) {
            for (double longitude : {-180.0, 0.0, 139.76}) {
                const double lat = latitude * pi / 180, lon = longitude * pi / 180;
                const double n = radius / std::sqrt(1 - e2 * std::sin(lat) * std::sin(lat));
                const double x = n * std::cos(lat) * std::cos(lon);
                const double y = n * std::cos(lat) * std::sin(lon);
                const double z = n * (1 - e2) * std::sin(lat);
                const auto expected = j2000_ecliptic_to_equatorial({
                    x*orientation.x_axis.x + y*orientation.y_axis.x + z*orientation.north_axis.x,
                    x*orientation.x_axis.y + y*orientation.y_axis.y + z*orientation.north_axis.y,
                    x*orientation.x_axis.z + y*orientation.y_axis.z + z*orientation.north_axis.z});
                const ObservationFrame local({latitude, longitude}, date);
                const auto actual = horizon_earth_observer_position(local, latitude);
                require(distance(actual, expected) < 1e-15, "ellipsoid position follows earth orientation");
                if (latitude == 45 || latitude == -45)
                    require(distance(actual, horizon_observer_position(local, earth_reference_radius_km)) > 1e-8,
                            "ellipsoid differs from spherical observer");
            }
        }
    }
    for (double invalid : {-90.001, 90.001, std::numeric_limits<double>::quiet_NaN(),
                           std::numeric_limits<double>::infinity()}) {
        bool rejected = false;
        try { horizon_earth_observer_position(frame, invalid); }
        catch (const std::invalid_argument&) { rejected = true; }
        require(rejected, "invalid geodetic latitude rejected");
    }
    for (double date : {jd, jd + 10}) {
        for (const auto& orientation : {planet_orientation(Planet::mars,date), lunar_orientation(date)}) {
            const ObservationFrame frame({0,0}, orientation);
            const auto observer = horizon_observer_position(frame, 1737.4);
            const auto axis = j2000_ecliptic_to_equatorial(orientation.x_axis);
            const double scaled = 1737.4 / astronomical_unit_km;
            require(distance(observer, {scaled*axis.x,scaled*axis.y,scaled*axis.z}) < 1e-15,
                    "non-Earth observer follows body orientation and radius");
        }
    }
    for (double invalid : {0.0, -1.0, std::numeric_limits<double>::quiet_NaN(),
                            std::numeric_limits<double>::infinity()}) {
        bool rejected = false;
        try { horizon_observer_position(frame, invalid); }
        catch (const std::invalid_argument&) { rejected = true; }
        require(rejected, "invalid observer radius rejected");
    }
    const auto quarter_day = horizon_earth_observer_position(ObservationFrame({0, 0}, jd + 0.25), 0);
    const double cosine = (observer.x*quarter_day.x + observer.y*quarter_day.y + observer.z*quarter_day.z) / (radius*radius);
    require(cosine < -0.004 && cosine > -0.005, "quarter day rotates observer by about 90.25 degrees");
    const auto opposite = horizon_earth_observer_position(ObservationFrame({0, 180}, jd), 0);
    require(std::hypot(observer.x + opposite.x, observer.y + opposite.y, observer.z + opposite.z) < 1e-14,
            "opposite longitudes reverse observer");
    // Earth=0 and x observer: a position (2R,R,0) gives a 45-degree measured direction.
    const auto point = horizon_heliocentric_coordinates({2 * radius, radius, 0}, {0,0,0}, {radius,0,0});
    const auto expected = equatorial_coordinates(j2000_ecliptic_to_equatorial({radius, radius, 0}));
    require(point && near(point->right_ascension_deg, expected.right_ascension_deg) &&
            near(point->declination_deg, expected.declination_deg), "measured parallax direction");
    require(!horizon_heliocentric_coordinates({radius,0,0}, {0,0,0}, {radius,0,0}), "observer coincidence rejected");
    const double nan = std::numeric_limits<double>::quiet_NaN();
    require(!horizon_heliocentric_coordinates({1,0,0}, {0,0,0}, {nan,0,0}), "nonfinite observer rejected");
}

void other_surface_camera_tests() {
    for (const std::size_t index : {std::size_t{4}, std::size_t{10}}) {
        for (const double date : {2451545.0, 2460000.5}) {
            SolarBodies bodies{};
            const auto orientation = index == 4 ? planet_orientation(Planet::mars,date) : lunar_orientation(date);
            bodies[index].orientation = orientation;
            bodies[index].position_au = j2000_ecliptic_to_equatorial({1.5,-0.3,0.1});
            for (const auto& site : {SurfaceSite{index,35,139,0.1,42,23,0,-0.25},
                                    SurfaceSite{index,90,-180,0.002,0,0,0,0}}) {
                SurfaceNavigation navigation;
                navigation.set_site(site);
                const auto camera = navigation.camera(bodies);
                const auto basis = solar_camera_basis(camera);
                const Vec3 camera_eye{camera.target.x+basis.outward.x*camera.distance_au,
                                      camera.target.y+basis.outward.y*camera.distance_au,
                                      camera.target.z+basis.outward.z*camera.distance_au};
                const auto frame = ObservationFrame({site.latitude_deg,site.longitude_deg},orientation);
                const auto observer = horizon_observer_position(frame, surface_body_info(index).radius_km
                                                               + site.terrain_offset_km + site.height_km);
                const auto offset = j2000_equatorial_to_ecliptic(observer);
                const auto center = j2000_equatorial_to_ecliptic(bodies[index].position_au);
                require(std::hypot(camera_eye.x-center.x-offset.x, camera_eye.y-center.y-offset.y,
                                   camera_eye.z-center.z-offset.z) < 1e-13,
                        "surface camera and horizon observer agree");
                const auto look = j2000_ecliptic_to_equatorial({-basis.outward.x,-basis.outward.y,-basis.outward.z});
                const auto horizontal = frame.to_horizontal(equatorial_coordinates(look));
                require(std::abs(std::remainder(horizontal.azimuth_deg-site.heading_deg,360)) < 1e-8 &&
                        std::abs(horizontal.altitude_deg-site.elevation_deg) < 1e-8,
                        "surface camera and horizon look agree");
            }
        }
    }
}

void small_body_tests() {
    auto data = std::make_shared<SmallBodyDataset>();
    data->sources = {{"test.dat", "test.dat", "", 5, true}};
    for (std::size_t i = 0; i < 5; ++i) {
        SmallBodyRecord row;
        row.id = {"test.dat", i};
        row.kind = i == 1 ? SmallBodyKind::comet : SmallBodyKind::asteroid;
        row.name_bytes = "test";
        data->records.push_back(row);
    }
    auto model = std::make_shared<SmallBodyModel>(data);
    SmallBodyDisplayModel display(data);
    display.set_kind_options(SmallBodyKind::comet, {true, true, false, false});
    const double nan = std::numeric_limits<double>::quiet_NaN();
    SmallBodySnapshot snapshot;
    snapshot.model = model;
    snapshot.julian_date = 42;
    snapshot.positions = {Vec3{2,0,0}, Vec3{1,1,0}, Vec3{1,0,0}, Vec3{nan,0,0}, std::nullopt};
    auto objects = horizon_small_body_objects(snapshot, display, 42, {1,0,0}, {0,0,0});
    require(objects.size() == 2, "invalid and zero directions skipped");
    require(objects[0].index == 0 && !objects[0].label && near(objects[0].coordinates.right_ascension_deg, 0)
            && near(objects[0].coordinates.declination_deg, 0) && near(objects[0].distance_au, 1), "geocentric x direction");
    require(objects[1].index == 1 && objects[1].label && near(objects[1].coordinates.right_ascension_deg, 90)
            && near(objects[1].coordinates.declination_deg, j2000_obliquity_deg)
            && near(objects[1].distance_au, 1), "ecliptic y rotation and label");
    display.set_kind_options(SmallBodyKind::comet, {false, true, false, false});
    require(horizon_small_body_objects(snapshot, display, 42, {1,0,0}, {0,0,0}).size() == 1, "hidden kind excluded");
    display.set_kind_options(SmallBodyKind::asteroid, {true, true, false, true});
    require(horizon_small_body_objects(snapshot, display, 42, {1,0,0}, {0,0,0}).empty(), "selected only excludes unselected");
    display.set_selected_ids({data->records[0].id});
    objects = horizon_small_body_objects(snapshot, display, 42, {1,0,0}, {0,0,0});
    require(objects.size() == 1 && objects[0].index == 0 && objects[0].label, "selection and label preserved");
    require(horizon_small_body_objects(snapshot, display, 43, {1,0,0}, {0,0,0}).empty(), "stale snapshot excluded");
    require(horizon_small_body_objects(snapshot, display, nan, {1,0,0}, {0,0,0}).empty(), "nonfinite date excluded");
    require(horizon_small_body_objects(snapshot, display, 42, {nan,0,0}, {0,0,0}).empty(), "nonfinite earth excluded");
    snapshot.positions.pop_back();
    require(horizon_small_body_objects(snapshot, display, 42, {1,0,0}, {0,0,0}).empty(), "wrong row count rejected");
}

void spacecraft_tests() {
    SpacecraftDataset dataset;
    dataset.sources.push_back({"probe.dat", "probe.dat", SpacecraftSourceKind::definition, "", true, true, 3});
    dataset.definitions.resize(3);
    auto model = std::make_shared<SpacecraftBrowserModel>(std::make_shared<SpacecraftPositionModel>(std::move(dataset)));
    SpacecraftSnapshot snapshot;
    snapshot.model = model;
    snapshot.julian_date = 42;
    snapshot.positions = {Vec3{2,0,0}, std::nullopt, Vec3{1,1,0}};
    snapshot.evaluations.resize(3);
    int calls = 0;
    auto checked_position = [&](const SpacecraftSnapshot& input, std::size_t index) {
        ++calls;
        return input.positions[index];
    };
    auto objects = horizon_spacecraft_objects(snapshot, true, true, 42, {1,0,0}, {0,0,0}, checked_position);
    require(objects.size() == 2 && objects[0].index == 0 && objects[1].index == 2, "valid positions preserve indices");
    require(objects[1].label && near(objects[1].coordinates.declination_deg, j2000_obliquity_deg), "spacecraft label and rotation");
    require(calls == 3, "common position validation called for each row");
    const auto corrected = horizon_spacecraft_objects(snapshot, true, true, 42, {1,0,0}, {0.5,0,0}, checked_position);
    require(corrected.size() == 2 && near(corrected[0].distance_au, 0.5) &&
            near(corrected[0].coordinates.right_ascension_deg, 0), "spacecraft observer distance");
    calls = 0;
    objects = horizon_spacecraft_objects(snapshot, false, true, 42, {1,0,0}, {0,0,0}, checked_position);
    require(objects.size() == 2 && !objects[0].body && objects[0].label, "labels remain independently visible");
    calls = 0;
    require(horizon_spacecraft_objects(snapshot, false, false, 42, {1,0,0}, {0,0,0}, checked_position).empty() && calls == 0,
            "hidden points and labels skip validation");
    require(horizon_spacecraft_objects(snapshot, true, true, 43, {1,0,0}, {0,0,0}, checked_position).empty() && calls == 0,
            "stale spacecraft snapshot rejected");
    snapshot.evaluations.pop_back();
    require(horizon_spacecraft_objects(snapshot, true, true, 42, {1,0,0}, {0,0,0}, checked_position).empty() && calls == 0,
            "inconsistent row count rejected");
}
} // namespace

int main() {
    try {
        parallax_tests();
        other_surface_camera_tests();
        small_body_tests();
        spacecraft_tests();
        std::cout << "Horizon objects: " << checks << " checks PASS\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
