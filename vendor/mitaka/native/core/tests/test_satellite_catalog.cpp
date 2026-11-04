#include "mitaka/satellite_catalog.hpp"

#include <algorithm>
#include <chrono>
#include <fstream>
#include <iostream>
#include <map>
#include <set>

namespace {
using namespace mitaka;
int checks = 0;
void expect(bool value, const std::string& label) {
    ++checks;
    if (!value) throw std::runtime_error(label);
}

struct Fixture {
    std::filesystem::path root = std::filesystem::temp_directory_path() /
        ("mitaka-satellite-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() { std::filesystem::create_directories(root / "data/orbits/asteroids"); }
    ~Fixture() { std::error_code error; std::filesystem::remove_all(root, error); }
    std::filesystem::path data() const { return root / "data"; }
    void write(const std::string& key, const std::string& bytes) const {
        std::ofstream output(data() / key, std::ios::binary);
        output.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
        if (!output) throw std::runtime_error("fixture write failed");
    }
};

const std::string orbit = "# arbitrary name\r\nPlanet: Mars\r\nEpoch: 2451545.0\r\na: 9380\r\ne: .0151\r\n"
    "w: 150.247\r\nM0: 92.474\r\ni: 1.075\r\nnode: 164.931\r\nn: 1128.8444155\r\n"
    "P: .319\r\nPw: 1.131\r\nPnode: 2.262\r\nRA: 317.724\r\nDecl: 52.924\r\nRefPlane: L\r\n";
const std::string system = "# source\r\nSsystem\r\n{\r\nSun\r\n{\r\nName: Sun\r\nPlanet\r\n{\r\nName: Mars\r\n"
    "Satellite\r\n{\r\nName: Custom\r\nOrbit: ./data/orbits/custom.dat\r\nRadius: 1 2 3\r\n}\r\n"
    "Satellite\r\n{\r\nName: Custom\r\nOrbit: ./data/orbits/custom.dat\r\n}\r\n}\r\n}\r\n}\r\n";

const SatelliteSource& source(const SatelliteDataset& data, const std::string& key) {
    const auto found = std::find_if(data.sources.begin(), data.sources.end(), [&](const auto& s) { return s.key == key; });
    if (found == data.sources.end()) throw std::runtime_error("missing test source: " + key);
    return *found;
}

bool diagnostic(const SatelliteDataset& data, SatelliteDiagnosticCode code) {
    return std::any_of(data.diagnostics.begin(), data.diagnostics.end(), [=](const auto& d) { return d.code == code; });
}

void preservation() {
    Fixture f;
    f.write("ssystem.dat", system);
    f.write("ssystem_jp.dat", system);
    f.write("orbits/custom.dat", orbit);
    f.write("orbits/custom.extension", "Planet: Custom\nRefPlane: Z\nExtra: opaque: bytes\n");
    f.write("orbits/asteroids/ignored.dat", "not part of satellite catalog");
    const auto data = load_satellite_dataset(f.data());
    expect(data.sources.size() == 4, "all root files regardless of extension; no subdirectories");
    expect(data.definitions.size() == 10 && data.orbits.size() == 2, "duplicate and language definitions retained");
    expect(source(data, "ssystem.dat").bytes == system, "exact CRLF source bytes");
    expect(source(data, "orbits/custom.dat").bytes == orbit, "exact orbit bytes");
    std::set<std::pair<std::string, std::size_t>> ids;
    for (const auto& record : data.definitions) {
        expect(ids.emplace(record.id.source_key, record.id.record_ordinal).second, "stable unique source ordinal ID");
        const auto& original = source(data, record.id.source_key).bytes;
        expect(record.source_offset + record.source_size <= original.size(), "definition exact source slice bounds");
        expect(original.substr(record.source_offset, record.block_name_bytes.size()) == record.block_name_bytes,
               "definition slice starts at block label");
        if (record.kind == SatelliteDefinitionKind::satellite) {
            expect(record.parent_ordinal == 2 && record.orbit_index == 0, "parent ordinal and reference resolution");
        }
        for (const auto& field : record.fields) {
            expect(original.substr(field.source_offset, field.source_size).find(field.key + ":") != std::string::npos,
                   "field source location retained");
        }
    }
    expect(satellite_scalar(data.orbits[0].fields, "node") == 164.931, "raw Mars node not corrected by loader");
    expect(satellite_scalar(data.orbits[0].fields, "a") == 9380, "raw km not silently converted");
    expect(!satellite_scalar(data.orbits[0].fields, "Planet"), "string field is not numeric");
    expect(diagnostic(data, SatelliteDiagnosticCode::unknown_field), "unknown key diagnosed");
    expect(diagnostic(data, SatelliteDiagnosticCode::unresolved_reference_plane), "unknown reference plane diagnosed");
    f.write("ssystem_custom.dat", "CustomBlock\n{\nName: \x83\x5c\x94\x5c\nOpaque: \x83\x5c\n}\n");
    auto custom = load_satellite_dataset(f.data());
    const auto found = std::find_if(custom.definitions.begin(), custom.definitions.end(),
        [](const auto& r) { return r.id.source_key == "ssystem_custom.dat"; });
    expect(found != custom.definitions.end() && found->kind == SatelliteDefinitionKind::unknown, "custom unknown block retained");
    expect(unique_satellite_field(found->fields, "Name")->value_bytes == "\x83\x5c\x94\x5c", "CP932 trail backslash remains literal");
    expect(diagnostic(custom, SatelliteDiagnosticCode::unknown_block), "unknown block diagnosed");
    std::string added;
    for (int i = 0; i < 401; ++i) added += "Satellite\n{\nName: Extra\nOrbit: ./data/orbits/custom.dat\n}\n";
    f.write("ssystem_additional.dat", added);
    custom = load_satellite_dataset(f.data());
    expect(custom.definitions.size() == 412, "custom definitions are not capped at known satellite counts");
}

void invalid_values_and_structure() {
    Fixture f;
    f.write("orbits/valid.dat", orbit);
    f.write("orbits/duplicate.dat", orbit + "a: 42\n");
    f.write("orbits/unknown.dat", "Planet: Other\nRefPlane: ?\n");
    f.write("ssystem.dat", system + "Satellite\n{\n");
    auto data = load_satellite_dataset(f.data());
    expect(!source(data, "ssystem.dat").parsed && source(data, "ssystem.dat").bytes == system + "Satellite\n{\n",
           "unbalanced source bytes retained but no partial definitions");
    expect(data.definitions.empty() && data.orbits.size() == 3, "bad definition does not discard other sources");
    expect(source(data, "orbits/duplicate.dat").parsed && !source(data, "orbits/duplicate.dat").valid,
           "duplicate fields retained with invalid validation status");
    expect(!satellite_scalar(data.orbits[0].fields, "a"), "ambiguous duplicate scalar is unavailable");
    expect(diagnostic(data, SatelliteDiagnosticCode::duplicate_field), "duplicate diagnosis");
    expect(!unique_satellite_field(data.orbits[0].fields, "a"), "duplicate field lookup is ambiguous");
    const auto invalid = std::find_if(data.diagnostics.begin(), data.diagnostics.end(),
        [](const auto& d) { return d.source_key == "ssystem.dat"; });
    expect(invalid != data.diagnostics.end() && invalid->source_offset > 0 && invalid->source_line > 1,
           "invalid syntax has path, offset, line");
    for (const auto* value : {"nan", "inf", "-inf", "1e999", "1 1e999", "1 junk", "1.0.0", "", "1 2"}) {
        f.write("orbits/number.dat", std::string("Epoch: ") + value + "\n");
        data = load_satellite_dataset(f.data());
        const auto& bad = source(data, "orbits/number.dat");
        expect(bad.parsed && !bad.valid, std::string("invalid number status: ") + value);
        const auto record = std::find_if(data.orbits.begin(), data.orbits.end(),
            [](const auto& r) { return r.id.source_key == "orbits/number.dat"; });
        expect(!satellite_scalar(record->fields, "Epoch"), "invalid number never replaced with zero");
    }
    f.write("orbits/binary.dat", std::string("a: 1\0x", 6));
    f.write("orbits/syntax.dat", "a 1\n");
    data = load_satellite_dataset(f.data());
    expect(!source(data, "orbits/binary.dat").parsed && !source(data, "orbits/syntax.dat").parsed, "NUL and non-keyed syntax rejected");
    f.write("ssystem.dat", "Satellite\n{\nOrbit: ./data/orbits/valid.dat\nOrbit: ./data/orbits/unknown.dat\n}\n");
    data = load_satellite_dataset(f.data());
    expect(data.definitions.size() == 1 && !data.definitions.front().orbit_index, "duplicate Orbit reference never silently chooses a target");
}

void limits_and_references() {
    Fixture f;
    f.write("ssystem.dat", system);
    f.write("orbits/custom.dat", orbit);
    f.write("orbits/empty.dat", "# empty source\n");
    SatelliteLoadLimits limits;
    limits.catalog.max_records = 1;
    auto data = load_satellite_dataset(f.data(), limits);
    expect(data.definitions.empty() && data.orbits.size() == 1, "source atomic record limit does not block later source");
    expect(source(data, "orbits/empty.dat").parsed && source(data, "orbits/empty.dat").record_count == 0, "empty source accepted");
    limits = {}; limits.catalog.max_file_bytes = 1;
    data = load_satellite_dataset(f.data(), limits);
    expect(data.definitions.empty() && data.orbits.empty(), "per file byte limit");
    expect(!source(data, "orbits/custom.dat").read_complete, "byte limit is not complete raw input");
    limits = {}; limits.max_total_bytes = system.size();
    data = load_satellite_dataset(f.data(), limits);
    expect(data.definitions.size() == 5 && data.orbits.empty(), "aggregate bytes limited across sources");
    limits = {}; limits.max_fields = 2;
    data = load_satellite_dataset(f.data(), limits);
    expect(data.definitions.empty() && data.orbits.empty(), "aggregate field limit");
    limits = {}; limits.max_block_depth = 3;
    data = load_satellite_dataset(f.data(), limits);
    expect(data.definitions.empty() && data.orbits.size() == 1, "block depth limit");
    limits = {}; limits.max_line_bytes = 10;
    data = load_satellite_dataset(f.data(), limits);
    expect(data.definitions.empty() && data.orbits.empty(), "line length limit");
    limits = {}; limits.max_sources = 1;
    data = load_satellite_dataset(f.data(), limits);
    expect(data.sources.size() == 1 && diagnostic(data, SatelliteDiagnosticCode::limit_exceeded), "source count limit visible");
    limits.max_sources = 0;
    expect(load_satellite_dataset(f.data(), limits).sources.empty(), "zero source limit");
    f.write("ssystem.dat", "Satellite\n{\nOrbit: ../external.dat\n}\nSatellite\n{\nOrbit: /external.dat\n}\n");
    data = load_satellite_dataset(f.data());
    expect(data.definitions.size() == 2 && !data.definitions[0].orbit_index && !data.definitions[1].orbit_index,
           "external references retained but never followed");
    std::filesystem::create_symlink(f.data() / "orbits/custom.dat", f.data() / "orbits/link.dat");
    data = load_satellite_dataset(f.data());
    expect(!source(data, "orbits/link.dat").parsed && source(data, "orbits/link.dat").bytes.empty(), "symlink not followed");
    expect(!source(data, "orbits/link.dat").read_complete, "symlink is not a successful original read");
    f.write("ssystem.dat", system);
    data = load_satellite_dataset(f.data() / "");
    expect(data.definitions[3].orbit_index.has_value(), "trailing directory separator preserves reference base");
    const auto old = data;
    f.write("orbits/custom.dat", "a: 42\n");
    data = load_satellite_dataset(f.data());
    expect(source(old, "orbits/custom.dat").bytes == orbit && source(data, "orbits/custom.dat").bytes == "a: 42\n",
           "reload creates independent source snapshots");
}

void raw_read_status() {
    Fixture f;
    f.write("ssystem.dat", "Planet\n{\nOrbit: ./data/orbits/empty.dat\n}\n"
        "Satellite\n{\nOrbit: ./data/orbits/bad.dat\n}\n");
    f.write("orbits/empty.dat", "");
    f.write("orbits/bad.dat", "not native keyed syntax\n");
    const auto data = load_satellite_dataset(f.data());
    expect(source(data, "orbits/empty.dat").read_complete && source(data, "orbits/empty.dat").parsed,
           "empty file completed reading without an orbit record");
    expect(source(data, "orbits/bad.dat").read_complete && !source(data, "orbits/bad.dat").parsed,
           "raw read success survives parser rejection");
    for (const auto& definition : data.definitions) {
        expect(!definition.orbit_index && definition.orbit_source_index.has_value(),
               "source link survives empty or invalid orbit record");
        expect(data.sources[*definition.orbit_source_index].read_complete, "source link has complete bytes");
    }
}

void real_data(const std::filesystem::path& path) {
    const auto data = load_satellite_dataset(path);
    std::map<SatelliteDefinitionKind, std::size_t> kinds;
    std::map<std::string, std::size_t> planes;
    std::size_t references = 0, satellite_orbits = 0;
    for (const auto& record : data.definitions) {
        ++kinds[record.kind];
        if (unique_satellite_field(record.fields, "Orbit")) {
            expect(record.orbit_index.has_value(), "real orbit reference resolved");
            ++references;
        }
        const auto& original = source(data, record.id.source_key).bytes;
        expect(record.source_offset + record.source_size <= original.size(), "real block source slice");
    }
    for (const auto& record : data.orbits) {
        if (const auto* plane = unique_satellite_field(record.fields, "RefPlane")) ++planes[plane->value_bytes];
        if (unique_satellite_field(record.fields, "Planet")) ++satellite_orbits;
    }
    if (kinds[SatelliteDefinitionKind::satellite]) {
        expect(data.diagnostics.empty(), "real Plus sources have no load diagnostics");
        expect(data.sources.size() == 179 && data.orbits.size() == 177 && satellite_orbits == 168, "all real sources retained");
        expect(kinds[SatelliteDefinitionKind::satellite] == 340 && kinds[SatelliteDefinitionKind::planet] == 18,
               "all bilingual definitions including duplicates retained");
        expect(planes == std::map<std::string, std::size_t>{{"C", 2}, {"E", 38}, {"I", 1}, {"L", 96}, {"Q", 31}},
               "raw reference plane distribution");
        expect(references == 358, "duplicate orbit links retained");
        for (const auto& item : data.sources) expect(item.parsed && item.valid, "real source valid");
    } else {
        expect(data.sources.empty() && data.definitions.empty() && data.orbits.empty(), "regular bundle not substituted");
        expect(diagnostic(data, SatelliteDiagnosticCode::missing_source), "regular absence diagnosed");
    }
    std::cout << "satellite real data: sources=" << data.sources.size() << " definitions=" << data.definitions.size()
              << " orbits=" << data.orbits.size() << " diagnostics=" << data.diagnostics.size() << '\n';
}

} // namespace

int main(int argc, char** argv) {
    try {
        preservation(); invalid_values_and_structure(); limits_and_references(); raw_read_status();
        if (argc == 2) real_data(argv[1]);
        std::cout << "satellite catalog: " << checks << " checks passed\n";
    } catch (const std::exception& error) {
        std::cerr << "satellite catalog failure: " << error.what() << '\n';
        return 1;
    }
}
