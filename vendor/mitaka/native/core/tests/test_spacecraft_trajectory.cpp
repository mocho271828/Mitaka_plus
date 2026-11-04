#include "mitaka/spacecraft_trajectory.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <iterator>
#include <limits>

namespace {
using namespace mitaka;
using Code = SpacecraftDiagnosticCode;
int checks = 0;
void expect(bool condition, const std::string& message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
void near(double actual, double wanted) {
    expect(std::isfinite(actual) && std::abs(actual - wanted) < 1e-10, "native coordinate mismatch");
}
void append_real(std::string& bytes, double value) {
    std::uint64_t bits;
    static_assert(sizeof value == sizeof bits);
    std::memcpy(&bits, &value, sizeof bits);
    for (std::size_t i = 0; i < sizeof bits; ++i) bytes.push_back(static_cast<char>((bits >> (8*i)) & 255));
}
std::string sample(double time, double x, double y = 2, double z = 3) {
    std::string bytes;
    for (const auto value : {time, x, y, z}) append_real(bytes, value);
    return bytes;
}
std::string segment(double start, double offset = 0) {
    std::string bytes;
    for (int i = 0; i < 4; ++i) append_real(bytes, start + i);
    for (int axis = 0; axis < 3; ++axis) {
        for (int i = 0; i < 4; ++i) {
            const auto time = start + i;
            append_real(bytes, offset + (axis + 1)*(time*time*time - 2*time + 7));
        }
    }
    return bytes;
}
struct Fixture {
    std::filesystem::path root = std::filesystem::temp_directory_path() /
        ("mitaka-spacecraft-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() {
        std::filesystem::create_directories(root / "data");
        std::filesystem::create_directories(root / "spacecraft/nested");
    }
    ~Fixture() { std::error_code error; std::filesystem::remove_all(root, error); }
    std::filesystem::path data() const { return root / "data"; }
    void write(const std::string& key, const std::string& bytes) const {
        std::ofstream output(root / key, std::ios::binary);
        output.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
        if (!output) throw std::runtime_error("fixture write failed");
    }
};
const SpacecraftSource& source(const SpacecraftDataset& data, const std::string& key) {
    const auto found = std::find_if(data.sources.begin(), data.sources.end(), [&](const auto& s) { return s.key == key; });
    if (found == data.sources.end()) throw std::runtime_error("source not found: " + key);
    return *found;
}
std::size_t trajectory_index(const SpacecraftDataset& data, const std::string& key) {
    for (std::size_t i = 0; i < data.trajectories.size(); ++i)
        if (data.sources.at(data.trajectories[i].source_index).key == key) return i;
    throw std::runtime_error("trajectory not found: " + key);
}
bool diagnostic(const std::vector<SpacecraftDiagnostic>& diagnostics, Code code) {
    return std::any_of(diagnostics.begin(), diagnostics.end(), [=](const auto& d) { return d.code == code; });
}

void byte_reader_contract() {
    auto bytes = segment(0) + segment(3);
    const auto owned = Trajectory::load_bytes(bytes, "memory.ppi");
    bytes.clear();
    expect(owned.segment_count() == 2 && owned.time_range() == std::make_pair(0., 6.), "memory parser owns validated data after input is destroyed");
    near(owned.position_km(2.25)[0], 2.25*2.25*2.25 - 2*2.25 + 7);
    auto repeated = segment(0);
    repeated.replace(8, 8, repeated.substr(0, 8));
    auto nan = segment(0);
    std::string nonfinite;
    append_real(nonfinite, std::numeric_limits<double>::quiet_NaN());
    nan.replace(32, 8, nonfinite);
    for (const auto& invalid : {std::string{}, segment(0).substr(1), repeated, nan, segment(0)+segment(2)}) {
        bool rejected = false;
        try { (void)Trajectory::load_bytes(invalid, "invalid-memory.ppi"); }
        catch (const std::runtime_error& error) {
            rejected = true;
            expect(std::string(error.what()).find("invalid-memory.ppi: byte ") == 0, "memory diagnostics preserve source name and byte offset");
        }
        expect(rejected, "memory parser rejects the same malformed segment classes as file parser");
    }
}

void modern_definition_and_registration() {
    Fixture f;
    const std::string definition = "\xEF\xBB\xBFKEY: SCF_CUSTOM\r\nMODEL: custom.obj\r\n"
        "SCALE: 0.002\r\nOFFSET: 0,0,0\r\nTRAJECTORY: CuStOm.ppi\r\nORIGIN: EARTH\r\n"
        "// localized names\r\n[default]\r\nNAME: Custom\r\n[ja]\r\nNAME: 探査機\r\n[custom]\r\nNAME: retained\r\n";
    const std::string manifest = "\xEF\xBB\xBF// original registration order\nCUSTOM.dat\ncustom.dat\n"
        "missing.dat\n../../outside.dat\n/outside.dat\n";
    f.write("spacecraft/custom.dat", definition);
    f.write("spacecraft/custom.ppi", segment(0));
    f.write("spacecraft/spacecraft.dat", manifest);
    auto data = load_spacecraft_dataset(f.data());
    expect(data.definitions.size() == 1 && data.registration_lists.size() == 1, "registration list remains separate from definitions");
    expect(source(data, "spacecraft/custom.dat").valid && source(data, "spacecraft/custom.dat").bytes == definition,
           "modern BOM, CRLF and UTF-8 raw bytes preserved");
    const auto& record = data.definitions.front();
    expect(record.trajectory_index == trajectory_index(data, "spacecraft/custom.ppi"), "modern TRAJECTORY resolves existing snapshot");
    expect(unique_spacecraft_field(record, "NAME") == nullptr, "localized NAME is not treated as a root field");
    expect(unique_spacecraft_field(record, "NAME", "default")->value_bytes == "Custom" &&
           unique_spacecraft_field(record, "NAME", "ja")->value_bytes == "探査機" &&
           unique_spacecraft_field(record, "NAME", "custom")->value_bytes == "retained", "language sections remain independent");
    expect(unique_spacecraft_field(record, "ORIGIN")->value_bytes == "EARTH", "origin declaration retained without filename inference");
    const auto evaluation = evaluate_spacecraft_trajectory(data, *record.trajectory_index, 0);
    expect(evaluation.native_position_km && diagnostic(evaluation.diagnostics, Code::unresolved_spatial_contract),
           "ORIGIN alone does not establish a native-to-scene spatial transform");
    const auto& list = data.registration_lists.front();
    expect(list.entries.size() == 5 && source(data, "spacecraft/spacecraft.dat").bytes == manifest, "all manifest rows and raw bytes retained");
    expect(list.entries[0].definition_index == 0 && list.entries[1].definition_index == 0,
           "duplicate registration references preserved as separate rows");
    for (std::size_t i = 2; i < list.entries.size(); ++i)
        expect(!list.entries[i].definition_index, "missing and unsafe definition references remain unresolved");
    for (const auto& entry : list.entries)
        expect(manifest.substr(entry.source_offset, entry.source_size) == entry.reference_bytes + "\n", "manifest source span retains each row");
    expect(diagnostic(data.diagnostics, Code::unresolved_definition), "unresolved manifest rows diagnosed");
    f.write("spacecraft/custom.dat", definition + "NAME: duplicate\n");
    data = load_spacecraft_dataset(f.data());
    expect(!source(data, "spacecraft/custom.dat").valid && !unique_spacecraft_field(data.definitions.front(), "NAME", "custom"),
           "duplicate within a section rejected without merging other languages");
    f.write("spacecraft/custom.dat", "TRAJECTORY: custom.ppi\nOrbit: custom.ppi\n");
    data = load_spacecraft_dataset(f.data());
    expect(!data.definitions.front().trajectory_index, "mixed legacy and modern trajectory declarations are ambiguous");
    f.write("spacecraft/spacecraft.dat", std::string("custom.dat\0hidden.dat", 21));
    data = load_spacecraft_dataset(f.data());
    expect(!source(data, "spacecraft/spacecraft.dat").parsed, "NUL manifest is rejected atomically");
    f.write("spacecraft/spacecraft.dat", "custom.dat\ncustom.dat\n");
    SpacecraftLoadLimits limits;
    limits.catalog.max_records = 3; // definition + PPI segment leave only one registration row.
    data = load_spacecraft_dataset(f.data(), limits);
    expect(data.registration_lists.empty() && diagnostic(data.diagnostics, Code::limit_exceeded), "registration rows consume aggregate record budget atomically");
}

void preservation_and_evaluation() {
    Fixture f;
    const std::string definition = "# local definition\r\nName: \x83\x5c\r\nDisplayName: same\r\n"
        "Model: ignored.3ds\r\nSize: 1\r\nOrbit: pRoBe.pTh\r\nCustom: opaque:bytes\r\n";
    f.write("spacecraft/probe.dat", definition);
    f.write("spacecraft/probe_jp.dat", definition);
    const auto path = sample(1, 11) + sample(2, 21) + sample(2, 22) + sample(2, 22) + sample(3, 31);
    f.write("spacecraft/probe.pth", path);
    const auto ppi = segment(0) + segment(3, 100) + segment(8);
    f.write("spacecraft/custom.ppi", ppi);
    f.write("data/Sun.ppi", segment(0));
    f.write("spacecraft/nested/ignored.pth", sample(1, 0));
    f.write("data/ignored.dat", "not a spacecraft definition");
    auto data = load_spacecraft_dataset(f.data());
    expect(data.sources.size() == 5 && data.definitions.size() == 2 && data.trajectories.size() == 3,
           "all matching local sources, both languages, no implicit nested discovery");
    expect(source(data, "spacecraft/probe.dat").bytes == definition && source(data, "spacecraft/probe.pth").bytes == path,
           "original CRLF and binary bytes retained");
    expect(source(data, "spacecraft/custom.ppi").bytes == ppi, "complete PPI snapshot retained");
    const auto pth_index = trajectory_index(data, "spacecraft/probe.pth");
    const auto& samples = data.trajectories[pth_index].path_samples;
    expect(samples.size() == 5 && samples[1].time_value == samples[2].time_value && samples[2].time_value == samples[3].time_value,
           "all equal-time records remain in original order");
    expect(samples[1].coordinate_values[0] == 21 && samples[2].coordinate_values[0] == 22 && samples[3].coordinate_values[0] == 22,
           "equal-time different and identical coordinates both retained");
    for (const auto& definition_record : data.definitions) {
        expect(definition_record.trajectory_index == pth_index, "unique ASCII case-insensitive Orbit resolution");
        expect(unique_spacecraft_field(definition_record, "Name")->value_bytes == "\x83\x5c", "CP932 backslash byte retained");
        const auto& bytes = data.sources[definition_record.source_index].bytes;
        for (const auto& field : definition_record.fields)
            expect(bytes.substr(field.source_offset, field.source_size).find(field.key + ":") == 0,
                   "field byte offset and length retain original line");
    }
    expect(diagnostic(data.diagnostics, Code::unknown_field) && diagnostic(data.diagnostics, Code::case_insensitive_reference),
           "unknown field and case-folded reference diagnosed");
    expect(std::count_if(data.diagnostics.begin(), data.diagnostics.end(), [](const auto& d) { return d.code == Code::duplicate_time; }) == 2,
           "each retained duplicate time is identified");
    const auto pth_eval = evaluate_spacecraft_trajectory(data, pth_index, 2);
    expect(!pth_eval.native_position_km && diagnostic(pth_eval.diagnostics, Code::unresolved_pth_contract),
           "PTH sample time does not bypass unresolved units or interpolation");
    const auto ppi_index = trajectory_index(data, "spacecraft/custom.ppi");
    for (const double time : {0., 1.25, 3., 4.5, 6., 8., 10.75, 11.}) {
        const auto evaluated = evaluate_spacecraft_trajectory(data, ppi_index, time);
        expect(evaluated.native_position_km.has_value(), "PPI native evaluation available");
        for (std::size_t axis = 0; axis < 3; ++axis)
            near(evaluated.native_position_km->at(axis), (axis + 1)*(time*time*time - 2*time + 7) + (time > 3 && time <= 6 ? 100 : 0));
        expect(diagnostic(evaluated.diagnostics, Code::unresolved_spatial_contract) && diagnostic(evaluated.diagnostics, Code::unresolved_time_scale),
               "native PPI success does not infer spatial or physical time contract");
    }
    for (const double time : {-1., 7., 12.}) {
        const auto result = evaluate_spacecraft_trajectory(data, ppi_index, time);
        expect(!result.native_position_km && diagnostic(result.diagnostics, Code::outside_coverage), "no gap interpolation or endpoint clamp");
    }
    f.write("spacecraft/custom.ppi", segment(0, 999));
    near(evaluate_spacecraft_trajectory(data, ppi_index, 0).native_position_km->at(0), 7);
    expect(source(data, "spacecraft/custom.ppi").bytes == ppi, "file replacement cannot change loaded evaluator or raw snapshot");
    expect(load_spacecraft_dataset(f.data() / "").sources.size() == 5, "trailing slash retains sibling resolution");
}

void malformed_sources_and_references() {
    Fixture f;
    f.write("spacecraft/valid.pth", sample(1, 1));
    f.write("spacecraft/bad.ppi", segment(0).substr(1));
    f.write("spacecraft/bad.pth", sample(1, 1) + "x");
    f.write("spacecraft/empty.pth", {});
    f.write("spacecraft/decrease.pth", sample(2, 2) + sample(1, 1));
    f.write("spacecraft/nan.pth", sample(1, std::numeric_limits<double>::quiet_NaN()));
    f.write("spacecraft/inf.pth", sample(std::numeric_limits<double>::infinity(), 1));
    f.write("spacecraft/syntax.dat", "Name missing colon\n");
    f.write("spacecraft/nul.dat", std::string("Name: a\0b", 9));
    f.write("spacecraft/duplicate.dat", "Name: a\nName: b\nOrbit: valid.pth\nOrbit: valid.pth\n");
    f.write("spacecraft/external.dat", "Orbit: ../../outside.pth\n");
    f.write("spacecraft/absolute.dat", "Orbit: /outside.pth\n");
    f.write("spacecraft/missing.dat", "Orbit: missing.pth\n");
    f.write("spacecraft/size.dat", "Orbit: valid.pth\nSize: nan\n");
    std::filesystem::create_symlink(f.root / "spacecraft/valid.pth", f.root / "spacecraft/link.pth");
    auto data = load_spacecraft_dataset(f.data());
    expect(data.trajectories.size() == 1, "malformed sources isolated, valid neighbor survives");
    for (const auto* key : {"bad.ppi", "bad.pth", "empty.pth", "decrease.pth", "nan.pth", "inf.pth", "syntax.dat", "nul.dat", "link.pth"})
        expect(!source(data, "spacecraft/" + std::string(key)).parsed, "invalid source not accepted");
    expect(source(data, "spacecraft/bad.pth").bytes == sample(1, 1) + "x", "malformed raw bytes preserved");
    expect(source(data, "spacecraft/link.pth").bytes.empty(), "symlink target never read");
    for (const auto& definition : data.definitions) {
        const auto& key = data.sources[definition.source_index].key;
        if (key != "spacecraft/size.dat") expect(!definition.trajectory_index, "ambiguous or external references unresolved");
        if (key == "spacecraft/duplicate.dat") expect(!unique_spacecraft_field(definition, "Name"), "duplicate field is never last-wins");
    }
    expect(!source(data, "spacecraft/duplicate.dat").valid && !source(data, "spacecraft/size.dat").valid,
           "parsed definitions retain separate semantic validation status");
    expect(diagnostic(data.diagnostics, Code::duplicate_field) && diagnostic(data.diagnostics, Code::invalid_number), "typed definition diagnostics");
    for (const auto value : {"inf", "1e999", "1 2", "1 junk", ""}) {
        f.write("spacecraft/size.dat", std::string("Size: ") + value + "\n");
        data = load_spacecraft_dataset(f.data());
        expect(!source(data, "spacecraft/size.dat").valid, "invalid numeric Size retained and diagnosed");
    }
    expect(diagnostic(evaluate_spacecraft_trajectory(data, 99, 0).diagnostics, Code::invalid_record_index), "invalid trajectory index rejected");
    expect(diagnostic(evaluate_spacecraft_trajectory(data, 0, std::numeric_limits<double>::quiet_NaN()).diagnostics, Code::invalid_time), "invalid numeric time rejected");
    data.trajectories[0].source_index = data.sources.size();
    expect(diagnostic(evaluate_spacecraft_trajectory(data, 0, 0).diagnostics, Code::invalid_record_index), "invalid source index rejected");
}

void limits_and_custom_data() {
    Fixture f;
    std::string samples;
    for (int i = 0; i < 10001; ++i) samples += sample(i, i);
    f.write("spacecraft/custom.pth", samples);
    f.write("spacecraft/record.dat", "Name: Custom\nOrbit: custom.pth\n");
    auto data = load_spacecraft_dataset(f.data());
    expect(data.trajectories.size() == 1 && data.trajectories.front().path_samples.size() == 10001, "custom source is not capped at public file counts");
    for (int setting = 0; setting < 6; ++setting) {
        SpacecraftLoadLimits limits;
        if (setting == 0) limits.catalog.max_file_bytes = 1;
        if (setting == 1) limits.max_total_bytes = 1;
        if (setting == 2) limits.catalog.max_records = 0;
        if (setting == 3) limits.max_sources = 0;
        if (setting == 4) limits.max_fields = 0;
        if (setting == 5) limits.max_line_bytes = 1;
        data = load_spacecraft_dataset(f.data(), limits);
        expect(diagnostic(data.diagnostics, Code::limit_exceeded), "each resource limit has an explicit diagnostic");
        if (setting < 4) expect(data.trajectories.empty(), "binary source not partially accepted after limit rejection");
    }
    SpacecraftLoadLimits limits;
    limits.catalog.max_records = 10000;
    data = load_spacecraft_dataset(f.data(), limits);
    expect(data.trajectories.empty() && data.definitions.size() == 1, "atomic oversized source does not consume later source record budget");
    expect(source(data, "spacecraft/custom.pth").bytes == samples, "record limit preserves already read raw bytes");
    std::filesystem::remove_all(f.root / "spacecraft");
    data = load_spacecraft_dataset(f.data());
    expect(data.sources.empty() && diagnostic(data.diagnostics, Code::missing_source), "optional missing directory is diagnosed without invented sources");
}

void real_data(const std::filesystem::path& path) {
    const auto data = load_spacecraft_dataset(path);
    expect(!data.sources.empty(), "provided real data has spacecraft sources");
    std::size_t pth_count = 0, ppi_count = 0, duplicates = 0;
    for (const auto& source_record : data.sources) {
        expect(source_record.parsed && source_record.valid, "real source validation: " + source_record.key);
        std::ifstream input(source_record.path, std::ios::binary);
        const std::string original((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
        expect(original == source_record.bytes, "real original byte preservation");
    }
    for (std::size_t index = 0; index < data.trajectories.size(); ++index) {
        const auto& record = data.trajectories[index];
        if (record.ppi) {
            ppi_count += record.ppi->segment_count();
            const auto time = record.ppi->time_range().first;
            expect(evaluate_spacecraft_trajectory(data, index, time).native_position_km.has_value(), "real PPI native endpoint evaluation");
        } else {
            pth_count += record.path_samples.size();
            for (std::size_t i = 1; i < record.path_samples.size(); ++i)
                if (record.path_samples[i].time_value == record.path_samples[i-1].time_value) ++duplicates;
            expect(!evaluate_spacecraft_trajectory(data, index, record.path_samples.front().time_value).native_position_km,
                   "real PTH remains unevaluated without source contract");
        }
    }
    for (const auto& definition : data.definitions) expect(definition.trajectory_index.has_value(), "real definition trajectory resolved");
    std::size_t registrations = 0;
    for (const auto& list : data.registration_lists) {
        registrations += list.entries.size();
        for (const auto& entry : list.entries) expect(entry.definition_index.has_value(), "real registration definition resolved");
    }
    std::cout << "real spacecraft: " << data.sources.size() << " sources, " << data.definitions.size()
              << " definitions, " << registrations << " registrations, " << pth_count << " PTH samples, "
              << ppi_count << " PPI segments, " << duplicates << " equal-time pairs\n";
}
} // namespace

int main(int argc, char** argv) {
    try {
        byte_reader_contract(); preservation_and_evaluation(); modern_definition_and_registration();
        malformed_sources_and_references(); limits_and_custom_data();
        for (int i = 1; i < argc; ++i) real_data(argv[i]);
        std::cout << "spacecraft trajectory: " << checks << " checks PASS\n";
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
