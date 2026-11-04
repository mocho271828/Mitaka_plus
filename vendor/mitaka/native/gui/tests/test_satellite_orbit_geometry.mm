#import <Foundation/Foundation.h>
#include "satellite_orbit_geometry.hpp"
#include <chrono>
#include <cmath>
#include <fstream>
#include <iostream>
#include <limits>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
void require(bool value, const char* message) { ++checks; if (!value) throw std::runtime_error(message); }
bool near(Vec3 a, Vec3 b) { return std::hypot(a.x-b.x,a.y-b.y,a.z-b.z) < 1e-12; }
template<class Function> void rejects(Function function) {
    try { function(); } catch (const std::invalid_argument&) { require(true,"invalid snapshot rejected"); return; }
    require(false,"invalid snapshot accepted");
}
struct Fixture {
    std::filesystem::path root = std::filesystem::temp_directory_path() /
        ("mitaka-satellite-orbit-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() {
        std::filesystem::create_directories(root / "data/orbits");
        write("orbits/parent.dat", "");
        write("orbits/e.dat", "Epoch: 2451545\na: 100000\ne: 0.5\nM0: 0\nn: 90\nw: 0\ni: 0\nnode: 90\nPw: 0\nPnode: 0\nRefPlane: E\n");
        write("ssystem.dat", "Ssystem\n{\nSun\n{\nName: Sun\nPlanet\n{\nName: Pluto\nOrbit: ./data/orbits/parent.dat\n"
            "Satellite\n{\nName: Charon\nOrbit: ./data/orbits/e.dat\n}\n"
            "Satellite\n{\nName: Moon\nOrbit: ./data/orbits/e.dat\n}\n}\n}\n}\n");
    }
    ~Fixture() { std::error_code error; std::filesystem::remove_all(root,error); }
    void write(const std::string& key, const std::string& bytes) {
        std::ofstream output(root / "data" / key,std::ios::binary);
        output.write(bytes.data(),static_cast<std::streamsize>(bytes.size()));
        if (!output) throw std::runtime_error("fixture write failed");
    }
};
void synthetic() {
    Fixture fixture;
    auto frame = std::make_shared<SatelliteSnapshot>();
    frame->model = load_satellite_browser_model(fixture.root / "data");
    frame->julian_date = 2451545;
    const auto& model = frame->model->model();
    require(model.records().size() == 2,"synthetic rows retained");
    SatelliteAbsoluteEvaluation evaluation{};
    evaluation.legacy_julian_date = frame->julian_date;
    evaluation.context = {"ssystem.dat","test-controlled parent placement",{}};
    evaluation.registration = SatelliteAbsoluteRegistrationEvidence{
        SatelliteRegistrationOrigin::isolated_native_source,"test-controlled registration"};
    evaluation.relative = model.evaluate(frame->julian_date);
    const Vec3 origin{1,2,3};
    evaluation.planets.push_back({*model.records()[0].parent_definition_index,{0},"Pluto",origin,origin,false,{}});
    for (std::size_t row = 0; row < model.records().size(); ++row) {
        std::optional<Vec3> position;
        if (const auto relative = evaluation.relative.positions[row].relative_position_km)
            position = Vec3{origin.x+relative->x/satellite_km_per_au,
                origin.y+relative->y/satellite_km_per_au,origin.z+relative->z/satellite_km_per_au};
        evaluation.positions.push_back({model.records()[row].definition_index,position,false,{}});
        frame->positions.push_back(position);
    }
    frame->evaluations.push_back(evaluation);
    const auto geometry = satellite_orbit_geometry(frame);
    require(geometry->snapshot == frame && geometry->rows.size() == 2,"geometry owns its exact source snapshot");
    const auto& points = geometry->rows[0].points_au;
    require(points.size() == 257 && near(points.front(),points.back()),"ellipse has bounded closed segments");
    require(near(points.front(),{1,2+50000/satellite_km_per_au,3}),"rotated periapsis is measured from the focus");
    require(near(points[128],{1,2-150000/satellite_km_per_au,3}),"apoapsis preserves eccentric offset");
    require(near(points[64],{1-100000*std::sqrt(0.75)/satellite_km_per_au,2-50000/satellite_km_per_au,3}),
        "quadrature uses semi-minor axis and same-date rotation");
    require(near(points.front(),*frame->positions[0]),"current periapsis marker lies on the instantaneous path");
    require(geometry->rows[1].points_au.empty() && !geometry->rows[1].diagnostic.empty(),"Moon remains diagnosed without guessed ellipse");
    auto corrected = std::make_shared<SatelliteSnapshot>(*frame);
    const double factor = 1-legacy_pluto_charon_mass_fraction;
    const auto relative = *evaluation.relative.positions[0].relative_position_km;
    corrected->positions[0] = Vec3{origin.x+relative.x*factor/satellite_km_per_au,
        origin.y+relative.y*factor/satellite_km_per_au,origin.z+relative.z*factor/satellite_km_per_au};
    corrected->evaluations[0].positions[0].position_au = corrected->positions[0];
    corrected->evaluations[0].positions[0].pair_correction_applied = true;
    const auto correctedGeometry = satellite_orbit_geometry(corrected);
    const auto& correctedPoints = correctedGeometry->rows[0].points_au;
    require(correctedPoints.size() == 257 && correctedGeometry->rows[0].diagnostic.empty(),
        "verified Charon pair correction produces a bounded orbit");
    require(near(correctedPoints.front(),*corrected->positions[0]) &&
        near(correctedPoints[128],{1,2-150000*factor/satellite_km_per_au,3}),
        "Charon orbit applies the pair factor to both apsides around the uncorrected parent");
    for (unsigned variant = 0; variant < 11; ++variant) {
        auto bad = std::make_shared<SatelliteSnapshot>(*frame);
        auto& value = bad->evaluations[0];
        switch (variant) {
            case 0: value.relative.positions[0].rotation.reset(); break;
            case 1: value.legacy_julian_date += 1; break;
            case 2: value.relative.legacy_julian_date += 1; break;
            case 3: value.registration->evidence.clear(); break;
            case 4: value.context.cf96_binding_evidence.clear(); break;
            case 5: value.positions[0].position_au->x += 1; break;
            case 6: value.relative.positions[0].relative_position_km->x += 1; break;
            case 7: value.planets[0].uncorrected_position_au.reset(); break;
            case 8: value.positions[0].pair_correction_applied = true; break;
            case 9: value.relative.positions[0].rotation->x_axis.x = 5; break;
            case 10: bad->evaluations.push_back(value); break;
        }
        const auto rejected = satellite_orbit_geometry(bad);
        require(rejected->rows[0].points_au.empty() && !rejected->rows[0].diagnostic.empty(),
            "inconsistent or unverified evaluation produces a diagnostic, never a plausible orbit");
    }
    rejects([] { satellite_orbit_geometry({}); });
    auto bad = std::make_shared<SatelliteSnapshot>(*frame); bad->positions.pop_back();
    rejects([&] { satellite_orbit_geometry(bad); });
    bad = std::make_shared<SatelliteSnapshot>(*frame); bad->julian_date = std::numeric_limits<double>::quiet_NaN();
    rejects([&] { satellite_orbit_geometry(bad); });
}
void local(const std::filesystem::path& directory) {
    const auto model = load_satellite_browser_model(directory);
    const auto ephemeris = Cf96Ephemeris::load(directory / "cf96.dat");
    for (const double jd : {2451545.0,2451546.0}) {
        const auto frame = evaluate_satellite_snapshot(model,ephemeris,jd);
        const auto geometry = satellite_orbit_geometry(frame);
        require(geometry->rows.size() == model->model().records().size(),"local orbit rows retain every source record");
        std::size_t available = 0, expected = 0;
        for (std::size_t row = 0; row < geometry->rows.size(); ++row) {
            const auto& orbit = geometry->rows[row];
            const auto& record = model->model().records()[row];
            if (record.identifier_bytes != "Moon" && record.position_elements && frame->positions[row]) ++expected;
            if (orbit.points_au.empty()) {
                require(!orbit.diagnostic.empty(),"every unavailable local orbit has a reason");
                continue;
            }
            ++available;
            require(record.identifier_bytes != "Moon" && frame->positions[row].has_value(),"only evaluated Kepler rows produce paths");
            require(orbit.diagnostic.empty() && orbit.points_au.size() == 257 && near(orbit.points_au.front(),orbit.points_au.back()),
                "local path is finite, bounded and closed");
            for (const auto p : orbit.points_au)
                require(std::isfinite(p.x) && std::isfinite(p.y) && std::isfinite(p.z),"every local path point is finite");
        }
        require(available == expected,"every evaluated local Kepler row has an orbit, including an empty optional catalog");
        std::cout << "Local satellite orbit rows=" << geometry->rows.size() << " paths=" << available << " jd=" << jd << '\n';
    }
}
}
int main(int argc, char** argv) {
    @autoreleasepool {
        try {
            synthetic();
            if (argc > 1) local(argv[1]);
            std::cout << "Satellite orbit geometry: " << checks << " checks PASS\n";
            return 0;
        } catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
