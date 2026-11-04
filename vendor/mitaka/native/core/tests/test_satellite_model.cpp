#include "mitaka/satellite_model.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <fstream>
#include <iostream>
#include <limits>

namespace {
using namespace mitaka;
constexpr double jd = 2451545;
int checks = 0;
void expect(bool value, const std::string& label) {
    ++checks;
    if (!value) throw std::runtime_error(label);
}
void near(double actual, double expected, const std::string& label) {
    expect(std::isfinite(actual) && std::abs(actual-expected) < 1e-9, label);
}

struct Fixture {
    std::filesystem::path root = std::filesystem::temp_directory_path() /
        ("mitaka-satellite-model-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() { std::filesystem::create_directories(root / "data/orbits"); }
    ~Fixture() { std::error_code error; std::filesystem::remove_all(root, error); }
    void write(const std::string& key, const std::string& bytes) const {
        std::ofstream output(root / "data" / key, std::ios::binary);
        output.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
        if (!output) throw std::runtime_error("fixture write failed");
    }
    SatelliteDataset load() const { return load_satellite_dataset(root / "data"); }
};

std::string orbit(char plane = 'E', double node = 0) {
    return "Epoch: 2451545\na: 100\ne: 0\nM0: 0\nn: 90\nw: 0\ni: 0\nnode: " +
        std::to_string(node) + "\nPw: 0\nPnode: 0\nRefPlane: " + plane + "\n";
}
std::string satellite(const std::string& name, const std::string& key) {
    return "Satellite\n{\nName: " + name + "\nOrbit: ./data/orbits/" + key + "\n}\n";
}
std::string planet(const std::string& name, const std::string& children, const std::string& key = "parent.dat") {
    return "Planet\n{\nName: " + name + "\nOrbit: ./data/orbits/" + key + "\n" + children + "}\n";
}
std::string system(const std::string& planets) { return "Ssystem\n{\nSun\n{\nName: Sun\n" + planets + "}\n}\n"; }

// テストが作る独立コンテナに限る。元アプリの起動状態をこの関数で推定しない。
VerifiedSatelliteRegistration fixture_registration(const SatelliteDataset& data, const std::string& source) {
    VerifiedSatelliteRegistration result{source, {}, {}, "test-controlled independent source container"};
    for (const auto& definition : data.definitions) {
        if (definition.id.source_key != source || !definition.orbit_source_index) continue;
        if (definition.kind == SatelliteDefinitionKind::planet)
            result.planet_definition_ordinals.push_back(definition.id.record_ordinal);
        if (definition.kind == SatelliteDefinitionKind::satellite)
            result.satellite_definition_ordinals.push_back(definition.id.record_ordinal);
    }
    return result;
}
bool has(const std::vector<SatelliteModelDiagnostic>& diagnostics, SatelliteModelDiagnosticCode code) {
    return std::any_of(diagnostics.begin(), diagnostics.end(), [=](const auto& d) { return d.code == code; });
}
void position(const SatelliteModelPosition& evaluated, Vec3 expected, const std::string& label) {
    expect(evaluated.relative_position_km.has_value(), label + " position available");
    expect(evaluated.rotation.has_value(), label + " successful position exposes the same-date rotation");
    near(evaluated.relative_position_km->x, expected.x, label + " x");
    near(evaluated.relative_position_km->y, expected.y, label + " y");
    near(evaluated.relative_position_km->z, expected.z, label + " z");
}

void structure_and_preservation() {
    Fixture f;
    f.write("orbits/parent.dat", "");
    f.write("orbits/e.dat", orbit() + "Planet: deliberately wrong\n");
    const auto bytes = system(planet("Mars localized label", satellite("Custom \x83\x5c", "e.dat")));
    f.write("ssystem.dat", bytes);
    f.write("ssystem_jp.dat", bytes);
    auto data = f.load();
    const SatelliteModel model(data);
    expect(model.records().size() == 2 && model.dataset().definitions.size() == 8, "all languages and blocks retained");
    expect(model.dataset().sources[0].bytes == bytes, "model owns exact definition bytes");
    for (const auto& record : model.records()) {
        expect(record.identifier_bytes == "Custom", "Name ID is first byte token");
        expect(record.parent_definition_index.has_value(), "structural parent resolved without orbit metadata");
        expect(!record.rotation_input.apply_mars_node_correction, "new ssystem load never applies Mars node correction");
        expect(!record.parent_registration_index && !record.registration_index && !record.registered,
               "original registration order not inferred from valid data");
        expect(has(record.diagnostics, SatelliteModelDiagnosticCode::conflicting_parent), "ignored metadata conflict remains visible");
    }
    const auto evaluated = model.evaluate(jd);
    expect(evaluated.positions.size() == model.records().size(), "evaluation preserves row count");
    position(evaluated.positions[0], {100,0,0}, "structural Mars no guessed +43");
    position(evaluated.positions[1], {100,0,0}, "separate language source");
    position(model.evaluate(jd+1).positions[0], {0,100,0}, "same date advanced once");
    f.write("orbits/e.dat", orbit());
    f.write("ssystem.dat", system(planet("\x83\x5c\x94\x5c", satellite("\x83\x5c\x94\x5c alias", "e.dat"))));
    const SatelliteModel cp932(f.load());
    expect(cp932.records()[0].identifier_bytes == "\x83\x5c\x94\x5c", "CP932 byte tokens are unchanged");
    expect(!has(cp932.records()[0].diagnostics, SatelliteModelDiagnosticCode::conflicting_parent), "Planet metadata may be absent");
    position(cp932.evaluate(jd).positions[0], {100,0,0}, "no Planet metadata required");
    expect(model.dataset().sources[0].bytes == bytes, "model snapshot survives independent reload");
}

void rejected_and_retained() {
    Fixture f;
    f.write("orbits/parent.dat", ""); f.write("orbits/e.dat", orbit());
    f.write("orbits/l.dat", orbit('L')); f.write("orbits/z.dat", orbit('Z'));
    f.write("orbits/duplicate.dat", orbit() + "a: 2\n");
    f.write("ssystem.dat", system(planet("Parent", satellite("Moon", "e.dat") + satellite("moon", "e.dat") +
        satellite("NoPole", "l.dat") + satellite("Unknown", "z.dat") + satellite("Duplicate", "duplicate.dat") +
        satellite("Missing", "missing.dat"))) + satellite("Orphan", "e.dat"));
    const SatelliteModel model(f.load());
    const auto evaluation = model.evaluate(jd);
    expect(evaluation.positions.size() == 7, "invalid records never disappear");
    expect(!evaluation.positions[0].relative_position_km && has(evaluation.positions[0].diagnostics,
        SatelliteModelDiagnosticCode::unsupported_moon), "Moon never uses generic Kepler");
    position(evaluation.positions[1], {100,0,0}, "Moon comparison is case sensitive");
    for (const auto index : {2,3,4,5,6}) {
        expect(!evaluation.positions[index].relative_position_km, "invalid input not a zero position");
        expect(!evaluation.positions[index].rotation, "failed position exposes no usable rotation");
    }
    expect(!evaluation.positions[2].rotation_diagnostics.empty(), "missing Laplace pole diagnostic");
    expect(!evaluation.positions[3].rotation_diagnostics.empty(), "unknown plane diagnostic");
    expect(has(evaluation.positions[4].diagnostics, SatelliteModelDiagnosticCode::invalid_field), "duplicate scalar diagnostic");
    expect(has(evaluation.positions[6].diagnostics, SatelliteModelDiagnosticCode::unresolved_parent), "orphan diagnostic");
    expect(has(model.evaluate(std::numeric_limits<double>::infinity()).diagnostics,
        SatelliteModelDiagnosticCode::invalid_context), "nonfinite evaluation date diagnosed");
    f.write("ssystem.dat", system(planet("Parent", "Satellite\n{\nName: A\nName: B\nOrbit: ./data/orbits/e.dat\n}\n")));
    const SatelliteModel ambiguous(f.load());
    expect(ambiguous.records()[0].identifier_bytes.empty() && !ambiguous.evaluate(jd).positions[0].relative_position_km,
        "duplicate Name cannot silently select an identifier");
}

void registration_and_q() {
    Fixture f;
    f.write("orbits/empty.dat", ""); f.write("orbits/bad.dat", "invalid native syntax\n");
    f.write("orbits/q.dat", orbit('Q'));
    f.write("ssystem.dat", system(planet("Missing", {}, "missing.dat") +
        planet("CustomA", satellite("Qa", "q.dat"), "empty.dat") +
        planet("CustomB", satellite("Qb", "q.dat"), "bad.dat")));
    const auto data = f.load();
    auto proof = fixture_registration(data, "ssystem.dat");
    const SatelliteModel unresolved(data);
    for (const auto& row : unresolved.evaluate(jd).positions)
        expect(!row.relative_position_km && has(row.diagnostics, SatelliteModelDiagnosticCode::unresolved_registration),
               "Q requires registration proof or explicit same-date pole");
    const SatelliteModel model(data, {proof});
    expect(model.diagnostics().empty(), "read-complete empty and invalid parent orbits are registration evidence");
    expect(model.records()[0].parent_registration_index->value == 0 && model.records()[1].parent_registration_index->value == 1,
           "successful order skips failed Planet and counts empty or malformed orbit");
    for (const auto& row : model.evaluate(jd).positions) expect(row.relative_position_km.has_value(), "Q uses index coefficients without name enum");
    const auto parent = *model.records()[0].parent_definition_index;
    const auto explicit_result = unresolved.evaluate(jd, {{parent, {jd,-90,90}}});
    position(explicit_result.positions[0], {100,0,0}, "explicit parent pole");
    expect(!explicit_result.positions[1].relative_position_km, "explicit pole does not leak across parents");
    const auto mismatch = model.evaluate(jd, {{parent, {jd+1,-90,90}}});
    expect(!mismatch.positions[0].relative_position_km && !mismatch.positions[0].rotation_diagnostics.empty(), "wrong-time pole blocks index fallback");
    const auto duplicate = model.evaluate(jd, {{parent, {jd,-90,90}}, {parent, {jd,0,90}}});
    expect(!duplicate.positions[0].relative_position_km && has(duplicate.diagnostics, SatelliteModelDiagnosticCode::invalid_context),
           "duplicate poles are diagnosed and never last-wins");
    expect(has(model.evaluate(jd, {{9999, {jd,0,90}}}).diagnostics, SatelliteModelDiagnosticCode::invalid_context), "invalid parent index diagnosed");
    proof.evidence.clear();
    expect(has(SatelliteModel(data,{proof}).diagnostics(), SatelliteModelDiagnosticCode::invalid_registration), "evidence is required");
    proof = fixture_registration(data, "ssystem.dat");
    proof.planet_definition_ordinals.pop_back();
    expect(has(SatelliteModel(data,{proof}).diagnostics(), SatelliteModelDiagnosticCode::invalid_registration), "cannot omit known successful Planet");
    proof = fixture_registration(data, "ssystem.dat");
    std::reverse(proof.planet_definition_ordinals.begin(), proof.planet_definition_ordinals.end());
    expect(has(SatelliteModel(data,{proof}).diagnostics(), SatelliteModelDiagnosticCode::invalid_registration), "registration must be in original order");
    proof = fixture_registration(data, "ssystem.dat");
    expect(has(SatelliteModel(data,{proof,proof}).diagnostics(), SatelliteModelDiagnosticCode::invalid_registration), "conflicting proof sources rejected");
}

void charon_and_failed_parent() {
    Fixture f;
    f.write("orbits/parent.dat", ""); f.write("orbits/e.dat", orbit());
    f.write("orbits/rotated.dat", orbit('E',90)); f.write("orbits/c.dat", orbit('C'));
    f.write("ssystem.dat", system(planet("Pluto", satellite("Charon", "e.dat") +
        satellite("Charon", "rotated.dat") + satellite("Nix", "c.dat"))));
    auto data = f.load();
    SatelliteModel model(data, {fixture_registration(data, "ssystem.dat")});
    expect(model.records().size() == 3 && model.records()[2].rotation_input.charon_rotation_index == 0,
           "C uses first registered Charon and keeps duplicates");
    expect(has(model.records()[1].diagnostics, SatelliteModelDiagnosticCode::shadowed_identifier), "shadowed name diagnosed");
    position(model.evaluate(jd).positions[2], {100,0,0}, "first Charon basis");
    expect(!SatelliteModel(data).evaluate(jd).positions[2].relative_position_km, "no assumed global Charon lookup without evidence");
    f.write("ssystem.dat", system(planet("Pluto", satellite("Charon", "missing.dat") +
        satellite("Charon", "rotated.dat") + satellite("Nix", "c.dat"))));
    data = f.load(); model = SatelliteModel(data, {fixture_registration(data, "ssystem.dat")});
    expect(model.records()[2].rotation_input.charon_rotation_index == 1, "unregistered Charon does not shadow a registered one");
    expect(!model.evaluate(jd).positions[0].relative_position_km, "unregistered satellite retained without position");
    position(model.evaluate(jd).positions[2], {0,100,0}, "successful Charon lookup");
    f.write("ssystem.dat", system(planet("Pluto", satellite("Charon", "c.dat") + satellite("Nix", "c.dat"))));
    data = f.load(); model = SatelliteModel(data, {fixture_registration(data, "ssystem.dat")});
    for (const auto& row : model.evaluate(jd).positions)
        expect(!row.relative_position_km && !row.rotation_diagnostics.empty(), "Charon dependency cycle retained and rejected");
    f.write("ssystem.dat", system(planet("Failed", satellite("A", "e.dat"), "missing.dat") +
        planet("Success", satellite("B", "e.dat"))));
    data = f.load(); model = SatelliteModel(data, {fixture_registration(data, "ssystem.dat")});
    expect(model.records()[0].registered == true && model.records()[0].parent_registered == false,
           "satellite registration may precede parent failure");
    expect(!model.evaluate(jd).positions[0].relative_position_km &&
        has(model.records()[0].diagnostics, SatelliteModelDiagnosticCode::unregistered_parent), "numeric parent collision is not remapped");
    expect(model.records()[1].parent_registration_index->value == 0, "next successful parent reuses numeric count");
    position(model.evaluate(jd).positions[1], {100,0,0}, "remaining valid parent unaffected");
}

void isolated_registration() {
    Fixture f;
    f.write("orbits/parent.dat", "");
    f.write("orbits/q.dat", orbit('Q'));
    f.write("ssystem.dat", system(planet("First", satellite("A", "q.dat")) +
        planet("Second", satellite("A", "q.dat"))));
    auto data = f.load();
    auto registration = make_isolated_satellite_registration(data, "ssystem.dat");
    expect(registration.registration.has_value() && registration.diagnostics.empty(), "native independent registration available");
    SatelliteModel model(data, {*registration.registration});
    expect(model.registration_contexts().size() == 1, "validated context exposed once");
    const auto& context = model.registration_contexts()[0];
    expect(context.origin == SatelliteRegistrationOrigin::isolated_native_source && !context.evidence.empty(),
        "native context distinguished from legacy startup evidence");
    expect(context.planets.size() == 2 && context.satellite_record_indices == std::vector<std::size_t>{0,1},
        "context contains all successful planets and satellite record indices");
    expect(context.planets[0].identifier_bytes == "First" && context.planets[1].identifier_bytes == "Second" &&
        context.planets[0].registration_index.value == 0 && context.planets[1].registration_index.value == 1,
        "planet context preserves registration order and byte identifiers");
    expect(context.planet_identifiers_complete && context.satellite_identifiers_complete, "duplicate names remain complete");
    auto invalid = *registration.registration; invalid.evidence.clear();
    expect(SatelliteModel(data, {invalid}).registration_contexts().empty(), "invalid proof does not leak context");
    invalid = *registration.registration;
    invalid.origin = static_cast<SatelliteRegistrationOrigin>(99);
    expect(SatelliteModel(data, {invalid}).registration_contexts().empty(), "unknown origin cannot become verified context");
    expect(!make_isolated_satellite_registration(data, "absent.dat").registration, "unknown source cannot register");
    f.write("ssystem.dat", system(planet("First", satellite("A", "missing.dat"))));
    expect(!make_isolated_satellite_registration(f.load(), "ssystem.dat").registration, "unread file not inferred to be failed legacy fopen");
    f.write("ssystem.dat", satellite("Orphan", "q.dat"));
    expect(!make_isolated_satellite_registration(f.load(), "ssystem.dat").registration, "unsupported hierarchy is not legacy registration evidence");
    f.write("ssystem.dat", system(planet("", satellite("", "q.dat"))));
    data = f.load(); registration = make_isolated_satellite_registration(data, "ssystem.dat");
    model = SatelliteModel(data, {*registration.registration});
    expect(!model.registration_contexts()[0].planet_identifiers_complete &&
        !model.registration_contexts()[0].satellite_identifiers_complete, "unknown names prohibit first-name lookup proof");
    f.write("ssystem.dat", system(planet("First", satellite("A", "link.dat"))));
    std::filesystem::create_symlink(f.root / "data/orbits/q.dat", f.root / "data/orbits/link.dat");
    expect(!make_isolated_satellite_registration(f.load(), "ssystem.dat").registration, "symlink rejection is not registration failure evidence");
    f.write("ssystem.dat", system(planet("First", satellite("A", "q.dat"))));
    SatelliteLoadLimits limits; limits.catalog.max_file_bytes = 20;
    expect(!make_isolated_satellite_registration(load_satellite_dataset(f.root / "data", limits), "ssystem.dat").registration,
        "bounded reads cannot fabricate registration evidence");
}

void real_data(const std::filesystem::path& directory) {
    auto data = load_satellite_dataset(directory);
    const auto expected_records = static_cast<std::size_t>(std::count_if(data.definitions.begin(), data.definitions.end(),
        [](const auto& definition) { return definition.kind == SatelliteDefinitionKind::satellite; }));
    std::vector<VerifiedSatelliteRegistration> proofs;
    for (const auto& source : data.sources) {
        if (source.kind != SatelliteSourceKind::system_definition) continue;
        auto registration = make_isolated_satellite_registration(data, source.key);
        if (registration.registration) proofs.push_back(std::move(*registration.registration));
        else expect(!registration.diagnostics.empty(), "incomplete native registration remains diagnosed");
    }
    SatelliteModel model(std::move(data), std::move(proofs));
    const auto evaluation = model.evaluate(jd);
    std::size_t calculated = 0, moons = 0, shadows = 0, unresolved = 0;
    for (std::size_t i = 0; i < model.records().size(); ++i) {
        const auto& record = model.records()[i];
        const auto& row = evaluation.positions[i];
        expect(row.definition_index == record.definition_index, "real record identity and order preserved");
        expect(!record.rotation_input.apply_mars_node_correction, "real new-load Mars condition remains false");
        if (record.identifier_bytes == "Moon") {
            ++moons; expect(!row.relative_position_km, "real Moon remains dedicated unresolved position");
        } else if (row.relative_position_km) {
            ++calculated;
        } else {
            ++unresolved;
            expect(!row.diagnostics.empty() || !row.rotation_diagnostics.empty() ||
                   !row.position_diagnostics.empty(), "unresolved real row has diagnostics");
        }
        if (has(record.diagnostics, SatelliteModelDiagnosticCode::shadowed_identifier)) ++shadows;
    }
    expect(model.records().size() == expected_records && calculated + unresolved + moons == expected_records,
           "all input Satellite definitions retained and classified without a fixed catalog count");
    for (const double date : {jd - 36525, jd + 36525}) {
        const auto at_date = model.evaluate(date);
        expect(at_date.positions.size() == expected_records, "all local modes preserve rows at other dates");
        for (std::size_t i = 0; i < at_date.positions.size(); ++i) {
            const auto& row = at_date.positions[i];
            expect(row.definition_index == model.records()[i].definition_index, "dated evaluation preserves identity");
            if (row.relative_position_km) {
                const auto p = *row.relative_position_km;
                expect(std::isfinite(p.x) && std::isfinite(p.y) && std::isfinite(p.z), "all computed local modes remain finite");
            } else expect(!row.diagnostics.empty() || !row.rotation_diagnostics.empty() ||
                          !row.position_diagnostics.empty() || !row.parent_pole_diagnostics.empty(),
                          "unavailable local modes retain a reason at each sampled date");
        }
    }
    std::cout << "satellite model real: retained=" << model.records().size() << " calculated=" << calculated
              << " dedicated_moon=" << moons << " unresolved=" << unresolved << " shadowed=" << shadows << '\n';
}
} // namespace

int main(int argc, char** argv) {
    try {
        structure_and_preservation(); rejected_and_retained(); registration_and_q(); charon_and_failed_parent(); isolated_registration();
        if (argc == 2) real_data(argv[1]);
        std::cout << "satellite model: " << checks << " checks passed\n";
    } catch (const std::exception& error) {
        std::cerr << "satellite model failure: " << error.what() << '\n';
        return 1;
    }
}
