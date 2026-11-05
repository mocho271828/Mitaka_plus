#include "horizon_objects.hpp"

#include <cmath>
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
    auto objects = horizon_small_body_objects(snapshot, display, 42, {1,0,0});
    require(objects.size() == 2, "invalid and zero directions skipped");
    require(objects[0].index == 0 && !objects[0].label && near(objects[0].coordinates.right_ascension_deg, 0)
            && near(objects[0].coordinates.declination_deg, 0) && near(objects[0].distance_au, 1), "geocentric x direction");
    require(objects[1].index == 1 && objects[1].label && near(objects[1].coordinates.right_ascension_deg, 90)
            && near(objects[1].coordinates.declination_deg, j2000_obliquity_deg)
            && near(objects[1].distance_au, 1), "ecliptic y rotation and label");
    display.set_kind_options(SmallBodyKind::comet, {false, true, false, false});
    require(horizon_small_body_objects(snapshot, display, 42, {1,0,0}).size() == 1, "hidden kind excluded");
    display.set_kind_options(SmallBodyKind::asteroid, {true, true, false, true});
    require(horizon_small_body_objects(snapshot, display, 42, {1,0,0}).empty(), "selected only excludes unselected");
    display.set_selected_ids({data->records[0].id});
    objects = horizon_small_body_objects(snapshot, display, 42, {1,0,0});
    require(objects.size() == 1 && objects[0].index == 0 && objects[0].label, "selection and label preserved");
    require(horizon_small_body_objects(snapshot, display, 43, {1,0,0}).empty(), "stale snapshot excluded");
    require(horizon_small_body_objects(snapshot, display, nan, {1,0,0}).empty(), "nonfinite date excluded");
    require(horizon_small_body_objects(snapshot, display, 42, {nan,0,0}).empty(), "nonfinite earth excluded");
    snapshot.positions.pop_back();
    require(horizon_small_body_objects(snapshot, display, 42, {1,0,0}).empty(), "wrong row count rejected");
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
    auto objects = horizon_spacecraft_objects(snapshot, true, true, 42, {1,0,0}, checked_position);
    require(objects.size() == 2 && objects[0].index == 0 && objects[1].index == 2, "valid positions preserve indices");
    require(objects[1].label && near(objects[1].coordinates.declination_deg, j2000_obliquity_deg), "spacecraft label and rotation");
    require(calls == 3, "common position validation called for each row");
    calls = 0;
    objects = horizon_spacecraft_objects(snapshot, false, true, 42, {1,0,0}, checked_position);
    require(objects.size() == 2 && !objects[0].body && objects[0].label, "labels remain independently visible");
    calls = 0;
    require(horizon_spacecraft_objects(snapshot, false, false, 42, {1,0,0}, checked_position).empty() && calls == 0,
            "hidden points and labels skip validation");
    require(horizon_spacecraft_objects(snapshot, true, true, 43, {1,0,0}, checked_position).empty() && calls == 0,
            "stale spacecraft snapshot rejected");
    snapshot.evaluations.pop_back();
    require(horizon_spacecraft_objects(snapshot, true, true, 42, {1,0,0}, checked_position).empty() && calls == 0,
            "inconsistent row count rejected");
}
} // namespace

int main() {
    try {
        small_body_tests();
        spacecraft_tests();
        std::cout << "Horizon objects: " << checks << " checks PASS\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
