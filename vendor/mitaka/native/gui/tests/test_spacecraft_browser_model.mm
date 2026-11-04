#import <Foundation/Foundation.h>
#include "spacecraft_browser_model.hpp"
#include <chrono>
#include <cmath>
#include <cstring>
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
        ("mitaka-spacecraft-browser-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() { std::filesystem::create_directories(root / "data"); std::filesystem::create_directory(root / "spacecraft"); }
    ~Fixture() { std::error_code error; std::filesystem::remove_all(root, error); }
    void write(const std::string& name, const std::string& bytes) const {
        std::ofstream file(root / "spacecraft" / name, std::ios::binary);
        file.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
        if (!file) throw std::runtime_error("fixture write failed");
    }
};
void appendDouble(std::string& bytes, double value) {
    std::uint64_t bits = 0;
    std::memcpy(&bits, &value, sizeof(bits));
    for (unsigned i = 0; i < 8; ++i) bytes.push_back(static_cast<char>((bits >> (i * 8)) & 255));
}
void syntheticTests() {
    Fixture fixture;
    const std::string legacy = "Name: Duplicate\nDisplayName: \x83\x65\x83\x58\x83\x67\nOrbit: ./sample.pth\nUnknown: custom bytes\n";
    fixture.write("a.dat", legacy);
    fixture.write("b.dat", "KEY: Duplicate\nTRAJECTORY: ./sample.pth\n[default]\nNAME: Probe\n[ja]\nNAME: はやぶさ\n");
    fixture.write("c.dat", "Name: Duplicate\nOrbit: missing.pth\n");
    std::string samples;
    for (double value : {10., 1., 2., 3., 20., 3., 6., 9.}) appendDouble(samples, value);
    fixture.write("sample.pth", samples);
    auto model = load_spacecraft_browser_model(fixture.root / "data");
    const auto& dataset = model->model().dataset();
    require(dataset.definitions.size() == 3, "all definitions retained");
    require(dataset.sources.front().bytes == legacy, "CP932 and unknown source fields retained byte-for-byte");
    require(model->title(0) == "テスト", "legacy CP932 decoded");
    require(model->title(1) == "はやぶさ", "modern Japanese section decoded as UTF8");
    require(model->sources().size() == 3, "separate sources retained");
    require(model->search("DUPLICATE", {}, 0, 500).total_matches == 3, "duplicate IDs remain searchable");
    require(model->search("probe", {}, 0, 500).rows == std::vector<std::size_t>{1}, "alternate language remains searchable");
    require(model->search("custom bytes", {}, 0, 500).rows == std::vector<std::size_t>{0}, "custom fields searchable");
    require(model->search("", "spacecraft/b.dat", 0, 500).rows == std::vector<std::size_t>{1}, "source filter retains original index");
    require(model->search("", {}, 1, 1).rows == std::vector<std::size_t>{1}, "pagination preserves source order");
    require(model->search("", {}, 9, 1).rows.empty(), "out of range page empty");
    require(model->search("", {}, 0, 500, [] { return true; }).cancelled, "superseded search cancelled");
    rejects<std::invalid_argument>([&] { model->search("", {}, 0, 0); }, "zero page rejected");
    rejects<std::invalid_argument>([] { SpacecraftBrowserModel invalid(nullptr); }, "null model rejected");
    rejects<std::out_of_range>([&] { model->title(3); }, "invalid row rejected");
    auto snapshot = evaluate_spacecraft_snapshot(model, 15);
    require(snapshot->positions.size() == 3 && snapshot->evaluations.size() == 3, "unresolved rows retained in snapshots");
    require(snapshot->positioned_count == 2 && !snapshot->positions[2], "missing reference never supplies coordinates");
    require(snapshot->positions[0]->x == 2 && snapshot->positions[0]->y == 4 && snapshot->positions[0]->z == 6,
        "confirmed PTH coordinates use requested numeric JD");
    require(snapshot->evaluations[0]->legacy_julian_date == snapshot->julian_date, "same JD flows to evaluator");
    const auto description = spacecraft_description(*model, 0, snapshot.get());
    require(description.find("線形補間") != std::string::npos && description.find("Unknown = custom bytes") != std::string::npos,
        "sampling and unknown fields visible");
    require(description.find("物理時系・精度保証期間は不明") != std::string::npos, "unverified physical time scale visible");
    require(spacecraft_description(*model, 2, snapshot.get()).find("軌跡参照が未解決") != std::string::npos,
        "unresolved row diagnostic visible");
    auto before = evaluate_spacecraft_snapshot(model, 1);
    require(spacecraft_description(*model, 0, before.get()).find("先頭位置に固定") != std::string::npos,
        "clamping not presented as extrapolation");
    SpacecraftSnapshot other = *snapshot;
    other.model = load_spacecraft_browser_model(fixture.root / "data");
    require(spacecraft_description(*model, 0, &other).find("位置未評価") != std::string::npos,
        "other model cannot supply coincident row coordinates");
    rejects<std::invalid_argument>([&] { evaluate_spacecraft_snapshot(model, std::numeric_limits<double>::quiet_NaN()); }, "NaN rejected");
    rejects<std::invalid_argument>([] { evaluate_spacecraft_snapshot({}, 15); }, "null snapshot model rejected");
    fixture.write("sample.pth", "changed");
    require(evaluate_spacecraft_snapshot(model, 15)->positions[0]->x == 2, "immutable source snapshot survives replacement");
    Fixture empty;
    require(load_spacecraft_browser_model(empty.root / "data")->search("", {}, 0, 10).rows.empty(), "empty data remains usable");
}
void ppiTests() {
    Fixture fixture;
    fixture.write("probe.dat", "KEY: Probe\nTRAJECTORY: probe.ppi\nORIGIN: EARTH\n");
    std::string bytes;
    for (double time : {10., 11., 12., 13.}) appendDouble(bytes, time);
    for (unsigned axis = 1; axis <= 3; ++axis)
        for (double time : {10., 11., 12., 13.}) appendDouble(bytes, axis * time);
    fixture.write("probe.ppi", bytes);
    const auto model = load_spacecraft_browser_model(fixture.root / "data");
    const auto snapshot = evaluate_spacecraft_snapshot(model, 11.5);
    require(snapshot->positions.size() == 1 && !snapshot->positions[0] && snapshot->positioned_count == 0,
        "PPI remains inspectable without inferred display coordinates");
    require(snapshot->evaluations[0].has_value(), "unsupported PPI retains evaluation diagnostics");
    bool spatialDiagnostic = false;
    for (const auto& diagnostic : snapshot->evaluations[0]->diagnostics)
        spatialDiagnostic |= diagnostic.code == SpacecraftDiagnosticCode::unresolved_spatial_contract;
    require(spatialDiagnostic, "PPI spatial uncertainty is explicit");
    const auto description = spacecraft_description(*model, 0, snapshot.get());
    require(description.find("PPI 原区間数: 1") != std::string::npos
        && description.find("PTH 原記録数") == std::string::npos, "PPI uses its own source kind in details");
    require(description.find("ORIGIN = EARTH") != std::string::npos, "PPI origin field preserved for inspection");
    require(model->model().dataset().sources[1].bytes == bytes, "PPI source bytes remain unchanged");
}
void localTests(const std::filesystem::path& directory) {
    const auto model = load_spacecraft_browser_model(directory);
    const auto snapshot = evaluate_spacecraft_snapshot(model, 2451545);
    const auto& dataset = model->model().dataset();
    require(snapshot->positions.size() == dataset.definitions.size(), "local definitions all evaluated or diagnosed");
    require(model->search("", {}, 0, 500).total_matches == dataset.definitions.size(), "all local definitions searchable");
    std::size_t count = 0;
    for (std::size_t i = 0; i < dataset.definitions.size(); ++i) {
        const auto& position = snapshot->positions[i];
        if (position) {
            ++count;
            require(std::isfinite(position->x) && std::isfinite(position->y) && std::isfinite(position->z), "local position finite");
            require(snapshot->evaluations[i]->contract == spacecraft_pth_position_contract, "local coordinates have explicit contract");
        }
        const auto text = spacecraft_description(*model, i, snapshot.get());
        require(text.find(model->provenance(i)) != std::string::npos, "local source and ordinal visible");
        require(!text.empty(), "local unsupported definition remains inspectable");
    }
    require(count == snapshot->positioned_count, "local position count accurate");
    std::cout << "Local spacecraft definitions=" << dataset.definitions.size() << " positioned=" << count << '\n';
}
}
int main(int argc, char** argv) {
    @autoreleasepool {
        try {
            syntheticTests();
            ppiTests();
            if (argc > 1) localTests(argv[1]);
            std::cout << "Spacecraft browser model: " << checks << " checks PASS\n";
            return 0;
        } catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
