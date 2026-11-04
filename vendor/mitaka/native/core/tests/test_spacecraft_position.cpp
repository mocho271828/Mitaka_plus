#include "mitaka/spacecraft_position.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <iterator>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using Kind = SpacecraftSamplingKind;
using Code = SpacecraftDiagnosticCode;
int checks = 0;
void expect(bool condition, const std::string& message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
void near(double actual, double expected, double tolerance = 2e-14) {
    expect(std::isfinite(actual) && std::abs(actual - expected) <= tolerance, "position mismatch");
}
void vector_near(Vec3 actual, const std::array<double, 3>& expected, double tolerance = 2e-14) {
    near(actual.x, expected[0], tolerance); near(actual.y, expected[1], tolerance); near(actual.z, expected[2], tolerance);
}
bool has(const SpacecraftPositionEvaluation& result, Code code) {
    return std::any_of(result.diagnostics.begin(), result.diagnostics.end(),
                       [=](const auto& item) { return item.code == code; });
}
void append_real(std::string& bytes, double value) {
    std::uint64_t bits;
    static_assert(sizeof value == sizeof bits);
    std::memcpy(&bits, &value, sizeof bits);
    for (std::size_t i = 0; i < sizeof bits; ++i) bytes.push_back(static_cast<char>((bits >> (8*i)) & 255));
}
std::string path_bytes(const std::vector<SpacecraftPathSample>& samples) {
    std::string bytes;
    for (const auto& sample : samples) {
        append_real(bytes, sample.time_value);
        for (const auto coordinate : sample.coordinate_values) append_real(bytes, coordinate);
    }
    return bytes;
}
SpacecraftDataset dataset(std::vector<SpacecraftPathSample> samples) {
    SpacecraftDataset result;
    result.sources.push_back({"spacecraft/custom.pth", {}, SpacecraftSourceKind::pth_samples,
        path_bytes(samples), true, true, samples.size()});
    result.trajectories.push_back({0, std::move(samples), {}});
    return result;
}
void selected(const SpacecraftPositionEvaluation& result, Kind kind, std::size_t low,
              std::size_t high, double u = 0) {
    expect(result.heliocentric_j2000_ecliptic_au.has_value() && result.sampling.has_value(), "position and sampling both available");
    expect(result.sampling->kind == kind && result.sampling->first_record_index == low &&
           result.sampling->second_record_index == high, "original record selection mismatch");
    near(result.sampling->u, u);
    expect(result.contract == spacecraft_pth_position_contract, "native AU contract identified");
    expect(has(result, Code::unresolved_time_scale), "success retains physical time uncertainty");
    expect(!has(result, Code::unresolved_pth_contract) && !has(result, Code::unresolved_spatial_contract), "confirmed PTH contract is explicit");
}
void rejected(const SpacecraftPositionEvaluation& result, Code code) {
    expect(!result.heliocentric_j2000_ecliptic_au && !result.sampling && result.contract.empty(), "rejection has no displayable position or successful sampling");
    expect(has(result, code), "rejection keeps typed diagnosis");
}

void linear_and_units() {
    // 独立な一次関数の値を解析的に求め、非等間隔区間の探索と補間をまとめて確認する。
    const auto function = [](double t) { return std::array<double, 3>{2*t - 3, 7 - 0.5*t, -4*t}; };
    std::vector<SpacecraftPathSample> samples;
    for (double time : {-10., -3., 0., 1., 5., 20.}) samples.push_back({time, function(time)});
    const SpacecraftPositionModel model(dataset(samples));
    for (int i = -40; i <= 80; ++i) {
        const double time = i * 0.25;
        const auto result = model.evaluate(0, time);
        expect(result.source_index == 0 && result.trajectory_index == 0 && result.legacy_julian_date == time, "requested time and source identity retained");
        expect(result.heliocentric_j2000_ecliptic_au.has_value(), "finite linear position");
        vector_near(*result.heliocentric_j2000_ecliptic_au, function(time));
    }
    selected(model.evaluate(0, -6.5), Kind::interpolated, 0, 1, 0.5);
    selected(model.evaluate(0, 0.25), Kind::interpolated, 2, 3, 0.25);
    selected(model.evaluate(0, 8.75), Kind::interpolated, 4, 5, 0.25);
    for (std::size_t axis = 0; axis < 3; ++axis) {
        std::array<double, 3> unit{};
        unit[axis] = 1;
        const SpacecraftPositionModel basis(dataset({{2451545, unit}}));
        const auto result = basis.evaluate(0, 2451545);
        vector_near(*result.heliocentric_j2000_ecliptic_au, unit, 0);
    }
    const double precise = std::nextafter(1., 2.);
    const std::array<double, 3> values{precise, -precise, 123456789.12345679};
    const SpacecraftPositionModel precise_model(dataset({{0, values}, {1, values}}));
    for (const double time : {0., 0.5, 1.})
        vector_near(*precise_model.evaluate(0, time).heliocentric_j2000_ecliptic_au, values, 0);
}

void endpoints_and_duplicates() {
    const SpacecraftPositionModel single(dataset({{5, {3, 4, 5}}}));
    for (const auto time : {-1e100, std::nextafter(5., 0.), 5., std::nextafter(5., 10.), 1e100}) {
        const auto result = single.evaluate(0, time);
        selected(result, time < 5 ? Kind::clamped_before : time > 5 ? Kind::clamped_after : Kind::exact_record, 0, 0);
        vector_near(*result.heliocentric_j2000_ecliptic_au, {3, 4, 5}, 0);
    }
    const SpacecraftPositionModel two(dataset({{0, {0, 0, 0}}, {2, {2, 4, 6}}}));
    selected(two.evaluate(0, -1), Kind::clamped_before, 0, 0);
    selected(two.evaluate(0, 0), Kind::exact_record, 0, 0);
    selected(two.evaluate(0, 1), Kind::interpolated, 0, 1, 0.5);
    selected(two.evaluate(0, 2), Kind::exact_record, 1, 1);
    selected(two.evaluate(0, 3), Kind::clamped_after, 1, 1);
    selected(two.evaluate(0, std::nextafter(0., -1.)), Kind::clamped_before, 0, 0);
    selected(two.evaluate(0, std::nextafter(2., 3.)), Kind::clamped_after, 1, 1);
    selected(two.evaluate(0, std::nextafter(0., 1.)), Kind::interpolated, 0, 1,
             std::numeric_limits<double>::denorm_min() / 2);
    selected(two.evaluate(0, std::nextafter(2., 1.)), Kind::interpolated, 0, 1,
             std::nextafter(2., 1.) / 2);
    const auto make = [](const std::vector<double>& times) {
        std::vector<SpacecraftPathSample> samples;
        for (std::size_t i = 0; i < times.size(); ++i)
            samples.push_back({times[i], {double(i), -double(i), 2*double(i)}});
        return SpacecraftPositionModel(dataset(std::move(samples)));
    };
    // 期待 ordinal は原版の分岐を手計算した表。重複の先頭・末尾への正規化を検出する。
    struct Case { std::vector<double> times; double query; std::size_t ordinal; };
    const std::vector<Case> cases{
        {{0, 1, 1, 1, 2}, 1, 2}, {{0, 1, 1, 1, 1, 2}, 1, 2},
        {{0, 0, 0, 1, 2}, 0, 0}, {{0, 1, 2, 2, 2}, 2, 4},
        {{1, 1, 1, 1}, 1, 0}, {{0, 1, 2, 3, 4, 4, 4, 5}, 4, 5},
        {{0, 1, 2}, 1, 1}, {{0, 1, 1, 2}, 1, 1}
    };
    for (const auto& item : cases) {
        const auto model = make(item.times);
        const auto result = model.evaluate(0, item.query);
        selected(result, Kind::exact_record, item.ordinal, item.ordinal);
        vector_near(*result.heliocentric_j2000_ecliptic_au,
                    {double(item.ordinal), -double(item.ordinal), 2*double(item.ordinal)}, 0);
        expect(model.dataset().trajectories[0].path_samples.size() == item.times.size(), "duplicates remain in snapshot");
    }
    const auto same = make({1, 1, 1, 1});
    selected(same.evaluate(0, std::nextafter(1., 2.)), Kind::clamped_after, 3, 3);
    selected(same.evaluate(0, std::nextafter(1., 0.)), Kind::clamped_before, 0, 0);
    const auto duplicate = make({0, 1, 1, 1, 2});
    const double before = std::nextafter(1., 0.), after = std::nextafter(1., 2.);
    const auto left = duplicate.evaluate(0, before), right = duplicate.evaluate(0, after);
    selected(left, Kind::interpolated, 0, 1, before);
    selected(right, Kind::interpolated, 3, 4, after - 1);
    expect(left.heliocentric_j2000_ecliptic_au->x < 1 && right.heliocentric_j2000_ecliptic_au->x >= 3,
           "unequal duplicate coordinates preserve the discontinuity");
    const SpacecraftPositionModel identical(dataset({{0, {1, 2, 3}}, {1, {4, 5, 6}},
        {1, {4, 5, 6}}, {1, {4, 5, 6}}, {2, {7, 8, 9}}}));
    selected(identical.evaluate(0, 1), Kind::exact_record, 2, 2);
    expect(identical.dataset().trajectories[0].path_samples.size() == 5, "identical equal-time rows are not deduplicated");
    const SpacecraftPositionModel epoch(dataset({{2451545.5, {0, 4, -2}}, {2451547.5, {8, 0, 2}}}));
    selected(epoch.evaluate(0, 2451546), Kind::interpolated, 0, 1, 0.25);
    vector_near(*epoch.evaluate(0, 2451546).heliocentric_j2000_ecliptic_au, {2, 3, -1}, 0);
}

void invalid_snapshots_and_range() {
    const SpacecraftPositionModel empty(SpacecraftDataset{});
    rejected(empty.evaluate(0, 0), Code::invalid_record_index);
    auto base = dataset({{0, {1, 2, 3}}, {1, {4, 5, 6}}, {2, {7, 8, 9}}});
    const SpacecraftPositionModel valid(base);
    rejected(valid.evaluate(std::numeric_limits<std::size_t>::max(), 0), Code::invalid_record_index);
    for (double time : {std::numeric_limits<double>::quiet_NaN(), std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity()})
        rejected(valid.evaluate(0, time), Code::invalid_time);
    for (int failure = 0; failure < 11; ++failure) {
        auto changed = base;
        auto& source = changed.sources[0];
        auto& record = changed.trajectories[0];
        Code code = Code::invalid_source;
        if (failure == 0) { record.source_index = 2; code = Code::invalid_record_index; }
        if (failure == 1) source.parsed = false;
        if (failure == 2) source.valid = false;
        if (failure == 3) source.kind = SpacecraftSourceKind::definition;
        if (failure == 4) record.path_samples.clear();
        if (failure == 5) source.bytes += 'x';
        if (failure == 6) --source.record_count;
        if (failure == 7) record.path_samples[1].time_value = -1;
        if (failure == 8) { record.path_samples[1].time_value = std::numeric_limits<double>::infinity(); code = Code::invalid_number; }
        if (failure == 9) { record.path_samples[1].coordinate_values[2] = std::numeric_limits<double>::quiet_NaN(); code = Code::invalid_number; }
        if (failure == 10) { record.path_samples[1].coordinate_values[0] = std::numeric_limits<double>::infinity(); code = Code::invalid_number; }
        // 要求が先頭端点でも、内部に隠れた不正記録は構築時に拒否する。
        const SpacecraftPositionModel model(std::move(changed));
        const auto result = model.evaluate(0, 0);
        rejected(result, code);
        if (failure >= 7) expect(result.diagnostics[0].record_ordinal == 1 && result.diagnostics[0].source_offset == 32, "invalid sample location reported");
    }
    auto ppi = base;
    ppi.sources[0].kind = SpacecraftSourceKind::ppi_segments;
    const auto ppi_result = SpacecraftPositionModel(std::move(ppi)).evaluate(0, 0);
    rejected(ppi_result, Code::unresolved_spatial_contract);
    expect(has(ppi_result, Code::unresolved_time_scale), "PTH does not authorize PPI display");
    const double max = std::numeric_limits<double>::max();
    const SpacecraftPositionModel overflow(dataset({{-max, {1, 2, 3}}, {max, {4, 5, 6}}}));
    rejected(overflow.evaluate(0, 0), Code::numerical_range);
    selected(overflow.evaluate(0, -max), Kind::exact_record, 0, 0);
    selected(overflow.evaluate(0, max), Kind::exact_record, 1, 1);
    const double tiny = std::numeric_limits<double>::denorm_min();
    const SpacecraftPositionModel subnormal(dataset({{0, {0, 2, -4}}, {2*tiny, {2, 4, -2}}}));
    selected(subnormal.evaluate(0, tiny), Kind::interpolated, 0, 1, 0.5);
    vector_near(*subnormal.evaluate(0, tiny).heliocentric_j2000_ecliptic_au, {1, 3, -3}, 0);
    // b-a は overflow するが、監査済みの重み付き和なら正しい有限位置になる。
    const SpacecraftPositionModel extreme(dataset({{0, {-max, max, 0}}, {2, {max, max, 0}}}));
    vector_near(*extreme.evaluate(0, 1).heliocentric_j2000_ecliptic_au, {0, max, 0}, 0);
    const auto third = extreme.evaluate(0, 0.5);
    expect(third.heliocentric_j2000_ecliptic_au.has_value(), "large finite weighted sum remains valid");
    near(third.heliocentric_j2000_ecliptic_au->x / max, -0.5);
}

struct Fixture {
    std::filesystem::path root = std::filesystem::temp_directory_path() /
        ("mitaka-spacecraft-position-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() { std::filesystem::create_directories(root / "data"); std::filesystem::create_directories(root / "spacecraft"); }
    ~Fixture() { std::error_code error; std::filesystem::remove_all(root, error); }
    void write(const std::string& name, const std::string& bytes) const {
        std::ofstream output(root / "spacecraft" / name, std::ios::binary);
        output.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
        if (!output) throw std::runtime_error("fixture write failed");
    }
};
void immutable_loader_snapshot() {
    Fixture fixture;
    const auto bytes = path_bytes({{0, {0, 1, 2}}, {1, {3, 4, 5}}, {1, {6, 7, 8}}, {2, {9, 10, 11}}});
    const std::string definition = "Name: \x83\x5c\nOrbit: custom.pth\n";
    fixture.write("custom.pth", bytes);
    fixture.write("custom.dat", definition);
    fixture.write("custom_jp.dat", definition);
    auto loaded = load_spacecraft_dataset(fixture.root / "data");
    const auto definition_count = loaded.definitions.size(), source_count = loaded.sources.size();
    const SpacecraftPositionModel model(std::move(loaded));
    fixture.write("custom.pth", path_bytes({{0, {999, 999, 999}}}));
    fixture.write("custom.dat", "Name: replacement\n");
    const auto& snapshot = model.dataset();
    expect(snapshot.definitions.size() == definition_count && snapshot.sources.size() == source_count, "all language definitions and sources retained");
    for (const auto& item : snapshot.definitions) {
        expect(item.trajectory_index.has_value() && snapshot.sources[item.source_index].bytes == definition, "independent definition still refers to original trajectory");
        expect(unique_spacecraft_field(item, "Name")->value_bytes == "\x83\x5c", "CP932 name bytes retained");
        const auto result = model.evaluate(*item.trajectory_index, 1);
        selected(result, Kind::exact_record, 1, 1);
        vector_near(*result.heliocentric_j2000_ecliptic_au, {3, 4, 5}, 0);
        expect(snapshot.sources[*result.source_index].bytes == bytes, "raw bytes unchanged after file replacement");
    }
    std::vector<SpacecraftPathSample> samples;
    for (std::size_t i = 0; i < 100003; ++i) samples.push_back({double(i), {double(i), -double(i), 0}});
    auto large_dataset = dataset(std::move(samples));
    const auto start = std::chrono::steady_clock::now();
    const SpacecraftPositionModel large(std::move(large_dataset));
    const auto constructed = std::chrono::steady_clock::now();
    for (std::size_t i = 0; i < 25000; ++i) {
        const double time = 4*i + 0.25;
        vector_near(*large.evaluate(0, time).heliocentric_j2000_ecliptic_au, {time, -time, 0}, 0);
    }
    expect(large.dataset().trajectories[0].path_samples.size() == 100003, "custom sample count is not limited to shipped data");
    std::cout << "PTH benchmark: 100003 samples, construction "
              << std::chrono::duration<double, std::milli>(constructed - start).count() << " ms, 25000 queries "
              << std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - constructed).count() << " ms\n";
}

void real_data(const std::filesystem::path& directory) {
    auto data = load_spacecraft_dataset(directory);
    const auto sources = data.sources.size(), definitions = data.definitions.size(), trajectories = data.trajectories.size();
    std::size_t raw_count = 0, duplicate_count = 0, ppi_count = 0;
    for (const auto& record : data.trajectories) {
        raw_count += record.path_samples.size();
        for (std::size_t i = 1; i < record.path_samples.size(); ++i)
            if (record.path_samples[i-1].time_value == record.path_samples[i].time_value) ++duplicate_count;
    }
    const SpacecraftPositionModel model(std::move(data));
    const auto& snapshot = model.dataset();
    expect(snapshot.sources.size() == sources && snapshot.definitions.size() == definitions && snapshot.trajectories.size() == trajectories,
           "real source, definition and trajectory counts unchanged");
    std::size_t evaluated_count = 0, observed_duplicates = 0;
    for (std::size_t index = 0; index < snapshot.trajectories.size(); ++index) {
        const auto& trajectory = snapshot.trajectories[index];
        const auto& source = snapshot.sources.at(trajectory.source_index);
        if (source.kind == SpacecraftSourceKind::ppi_segments) {
            ++ppi_count;
            rejected(model.evaluate(index, trajectory.ppi->time_range().first), Code::unresolved_spatial_contract);
            expect(evaluate_spacecraft_trajectory(snapshot, index, trajectory.ppi->time_range().first).native_position_km.has_value(),
                   "existing PPI native evaluator still available independently");
            continue;
        }
        expect(path_bytes(trajectory.path_samples) == source.bytes, "every raw binary64 sample and original order preserved");
        for (std::size_t i = 0; i < trajectory.path_samples.size(); ++i) {
            const auto& sample = trajectory.path_samples[i];
            const auto result = model.evaluate(index, sample.time_value);
            expect(result.heliocentric_j2000_ecliptic_au && result.sampling && result.sampling->kind == Kind::exact_record, "every real sample time is evaluable");
            const auto ordinal = result.sampling->first_record_index;
            expect(trajectory.path_samples[ordinal].time_value == sample.time_value, "exact selected raw row has requested time");
            vector_near(*result.heliocentric_j2000_ecliptic_au, trajectory.path_samples[ordinal].coordinate_values, 0);
            ++evaluated_count;
            if (i && sample.time_value == trajectory.path_samples[i-1].time_value) ++observed_duplicates;
        }
    }
    expect(evaluated_count == raw_count && observed_duplicates == duplicate_count, "all real records and equal-time pairs remain represented");
    for (const auto& source : snapshot.sources) {
        std::ifstream input(source.path, std::ios::binary);
        const std::string original((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
        expect(original == source.bytes, "on-disk bytes still match immutable snapshot");
    }
    std::cout << "real spacecraft position: " << sources << " sources, " << definitions << " definitions, "
              << evaluated_count << " PTH rows, " << duplicate_count << " equal-time pairs, " << ppi_count << " PPI trajectories withheld\n";
}
} // namespace

int main(int argc, char** argv) {
    try {
        linear_and_units(); endpoints_and_duplicates(); invalid_snapshots_and_range(); immutable_loader_snapshot();
        for (int i = 1; i < argc; ++i) real_data(argv[i]);
        std::cout << "spacecraft position: " << checks << " checks PASS\n";
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
