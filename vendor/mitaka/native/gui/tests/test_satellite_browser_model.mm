#import <Foundation/Foundation.h>
#include "satellite_browser_model.hpp"
#include <chrono>
#include <cmath>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
void require(bool value, const char* message) { ++checks; if (!value) throw std::runtime_error(message); }
template<class Exception, class Function> void rejects(Function function, const char* message) {
    try { function(); } catch (const Exception&) { require(true, message); return; }
    require(false, message);
}
struct Fixture {
    std::filesystem::path root = std::filesystem::temp_directory_path() /
        ("mitaka-satellite-browser-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() { std::filesystem::create_directories(root / "data/orbits"); }
    ~Fixture() { std::error_code error; std::filesystem::remove_all(root, error); }
    void write(const std::string& key, const std::string& bytes) const {
        std::ofstream file(root / "data" / key, std::ios::binary);
        file.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
        if (!file) throw std::runtime_error("fixture write failed");
    }
};
void syntheticTests() {
    Fixture fixture;
    fixture.write("orbits/parent.dat", "");
    fixture.write("orbits/e.dat", "Epoch: 2451545\na: 100\ne: 0\nM0: 0\nn: 90\nw: 0\ni: 0\nnode: 0\nPw: 0\nPnode: 0\nRefPlane: E\n");
    const std::string source = "Ssystem\n{\nSun\n{\nName: Sun\nPlanet\n{\nName: Mars Parent\nOrbit: ./data/orbits/parent.dat\n"
        "Satellite\n{\nName: Duplicate \x83\x65\x83\x58\x83\x67\nOrbit: ./data/orbits/e.dat\n}\n"
        "Satellite\n{\nName: Duplicate Second\nOrbit: ./data/orbits/missing.dat\n}\n}\n}\n}\n";
    fixture.write("ssystem.dat", source);
    fixture.write("ssystem_jp.dat", source);
    const auto model = load_satellite_browser_model(fixture.root / "data");
    require(model->model().records().size() == 4, "all duplicate and language source rows retained");
    require(model->model().dataset().sources.front().bytes == source, "source bytes unchanged");
    require(model->title(0) == "テスト", "CP932 display text decoded");
    require(model->parent_title(0) == "Parent", "structural parent label shown");
    require(model->source(0) == "ssystem.dat" && model->sources().size() == 2, "source identity kept");
    require(model->search("DUPLICATE", {}, 0, 500).total_matches == 4, "ID search retains duplicates");
    require(model->search("テスト", {}, 0, 500).rows == std::vector<std::size_t>({0, 2}), "Japanese search uses display text");
    require(model->search("parent", {}, 0, 500).total_matches == 4, "parent text searchable");
    require(model->search("", "ssystem_jp.dat", 0, 500).rows == std::vector<std::size_t>({2, 3}), "source filter keeps original indices");
    auto page = model->search("", {}, 1, 2);
    require(page.total_matches == 4 && page.rows == std::vector<std::size_t>({1, 2}), "page spans source boundary without merging");
    require(model->search("", {}, 9, 1).rows.empty(), "out-of-range page empty");
    require(model->search("", {}, 0, 500, [] { return true; }).cancelled, "superseded search cancelled");
    rejects<std::invalid_argument>([&] { model->search("", {}, 0, 0); }, "zero page rejected");
    rejects<std::invalid_argument>([] { SatelliteBrowserModel model(nullptr); }, "null model rejected");
    rejects<std::out_of_range>([&] { model->title(4); }, "invalid index rejected");
    require(!model->registration_diagnostics().empty(), "unread orbit leaves registration diagnostic");
    const auto description = satellite_description(*model, 1);
    require(description.find("位置未評価") != std::string::npos && description.find("精度保証期間は不明") != std::string::npos,
        "missing evaluation and accuracy stated");
    require(description.find("unread") != std::string::npos || description.find("Orbit") != std::string::npos,
        "unresolved orbit diagnostic visible");
    SatelliteSnapshot wrong;
    wrong.model = load_satellite_browser_model(fixture.root / "data");
    wrong.julian_date = 123;
    wrong.positions.resize(4, Vec3{1, 2, 3});
    require(satellite_description(*model, 0, &wrong).find("位置未評価") != std::string::npos,
        "other model snapshot cannot supply positions by coincident index");
    fixture.write("ssystem.dat", "");
    require(model->model().dataset().sources.front().bytes == source, "immutable snapshot survives source replacement");
    Fixture empty;
    const auto noRecords = load_satellite_browser_model(empty.root / "data");
    require(noRecords->search("", {}, 0, 500).rows.empty(), "missing optional data remains empty");
}
void localTests(const std::filesystem::path& directory) {
    const auto model = load_satellite_browser_model(directory);
    const auto ephemeris = Cf96Ephemeris::load(directory / "cf96.dat");
    auto snapshot = evaluate_satellite_snapshot(model, ephemeris, 2451545);
    require(snapshot->positions.size() == model->model().records().size(), "local evaluation retains every row");
    require(model->search("", {}, 0, 500).total_matches == snapshot->positions.size(), "all local rows searchable");
    std::size_t counted = 0;
    for (std::size_t i = 0; i < snapshot->positions.size(); ++i) {
        const auto p = snapshot->positions[i];
        if (p) {
            ++counted;
            require(std::isfinite(p->x) && std::isfinite(p->y) && std::isfinite(p->z), "position finite");
        }
        const auto description = satellite_description(*model, i, snapshot.get());
        require(description.find(model->provenance(i)) != std::string::npos, "local row provenance visible");
        for (const auto& evaluation : snapshot->evaluations) {
            if (evaluation.context.source_key != model->source(i)) continue;
            for (const auto& diagnostic : evaluation.relative.positions.at(i).rotation_diagnostics)
                require(description.find(diagnostic.message) != std::string::npos,
                    "rotation failure reason remains visible, including missing L-plane RA/Decl");
        }
    }
    require(snapshot->positioned_count == counted, "position count matches rows");
    rejects<std::invalid_argument>([&] { evaluate_satellite_snapshot(model, ephemeris, std::numeric_limits<double>::quiet_NaN()); }, "NaN date rejected");
    rejects<std::invalid_argument>([&] { evaluate_satellite_snapshot({}, ephemeris, 2451545); }, "null model evaluation rejected");
    if (!snapshot->positions.empty()) {
        require(model->search("", {}, snapshot->positions.size() - 1, 500).rows.back() == snapshot->positions.size() - 1,
            "last local record reachable");
        const auto next = evaluate_satellite_snapshot(model, ephemeris, 2451546);
        bool changed = false;
        for (std::size_t i = 0; i < snapshot->positions.size(); ++i)
            if (snapshot->positions[i] && next->positions[i]) {
                const auto a = *snapshot->positions[i], b = *next->positions[i];
                changed = changed || std::hypot(a.x-b.x, a.y-b.y, a.z-b.z) > 1e-10;
            }
        require(changed, "date change moves computed satellite positions");
    }
    std::cout << "Local satellite rows=" << snapshot->positions.size() << " positioned=" << counted << '\n';
}
}
int main(int argc, char** argv) {
    @autoreleasepool {
        try {
            syntheticTests();
            if (argc > 1) localTests(argv[1]);
            std::cout << "Satellite browser model: " << checks << " checks PASS\n";
            return 0;
        } catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
