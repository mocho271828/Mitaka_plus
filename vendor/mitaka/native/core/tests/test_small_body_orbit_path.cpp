#include "mitaka/small_body_orbit_path.hpp"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
int checks = 0;
void expect(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class Function> void invalid(Function action) {
    bool rejected = false;
    try { action(); } catch (const std::invalid_argument&) { rejected = true; }
    expect(rejected, "invalid sampling request rejected");
}
bool diagnostic(const SmallBodyEvaluation& evaluation, SmallBodyDiagnosticCode code) {
    return std::any_of(evaluation.diagnostics.begin(), evaluation.diagnostics.end(),
                       [=](const auto& item) { return item.code == code; });
}
SmallBodyRecord comet(double eccentricity) {
    SmallBodyRecord result;
    result.id = {"comets.dat", 12};
    result.kind = SmallBodyKind::comet;
    result.encoding = SmallBodyEncoding::comet_fixed_width;
    result.raw_record_bytes = "original\r\n";
    result.frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
    result.time_scale = SmallBodyTimeScale::tdb;
    result.orbit = PerihelionElements{1, eccentricity, 2451545, 0, 0, 0};
    return result;
}
void finite_paths() {
    for (double eccentricity : {0.0, 0.5, 1.0, 1.5}) {
        const auto record = comet(eccentricity);
        const auto path = sample_small_body_orbit_path(record, {2451543, 2451547, 5});
        expect(path.id.source_key == record.id.source_key && path.id.record_ordinal == 12,
               "source identity retained");
        expect(path.samples.size() == 5, "requested samples retained");
        for (std::size_t index = 0; index < path.samples.size(); ++index) {
            const auto& sample = path.samples[index];
            expect(sample.julian_date == 2451543 + index, "time order and endpoints");
            expect(sample.evaluation.state.has_value(), "all conic types evaluated");
            expect(diagnostic(sample.evaluation, SmallBodyDiagnosticCode::unknown_accuracy_range),
                   "drawing interval is not scientific accuracy range");
        }
        const auto& perihelion = path.samples[2].evaluation.state->position_au;
        expect(std::abs(perihelion.x - 1) < 1e-14 && std::abs(perihelion.y) < 1e-14
               && std::abs(perihelion.z) < 1e-14, "perihelion has unrotated AU coordinates");
        expect(path.samples.front().evaluation.state->position_au.y < 0
               && path.samples.back().evaluation.state->position_au.y > 0,
               "sampling crosses perihelion in time order");
        const auto segments = small_body_orbit_segments(path);
        expect(segments == std::vector<std::array<std::size_t, 2>>{{0,1},{1,2},{2,3},{3,4}},
               "finite path remains open for every conic");
        expect(record.raw_record_bytes == "original\r\n", "source row never modified");
    }
}
void missing_samples() {
    auto record = comet(1);
    record.declared_time_range = SmallBodyTimeRange{2451544, 2451546};
    auto path = sample_small_body_orbit_path(record, {2451543, 2451547, 5});
    expect(path.samples.size() == 5, "failed samples remain in original positions");
    expect(!path.samples.front().evaluation.state && !path.samples.back().evaluation.state,
           "out of range samples have no invented coordinates");
    expect(diagnostic(path.samples.front().evaluation, SmallBodyDiagnosticCode::outside_time_range),
           "out of range reason retained");
    expect(small_body_orbit_segments(path)
           == std::vector<std::array<std::size_t, 2>>{{1,2},{2,3}}, "range boundaries included");
    path.samples[2].evaluation.state.reset();
    expect(small_body_orbit_segments(path).empty(), "interior gap never bridged");
    expect(small_body_orbit_segments({record.id, {}}).empty(), "empty path has no segments");
    path.samples.resize(1);
    expect(small_body_orbit_segments(path).empty(), "single point has no segments");

    for (bool unknown_frame : {false, true}) {
        record = comet(1);
        if (unknown_frame) record.frame = SmallBodyFrame::unresolved;
        else record.time_scale = SmallBodyTimeScale::unresolved;
        record.diagnostics.push_back({SmallBodyDiagnosticCode::unknown_field, "comets.dat", 12,
                                      "original", "retained diagnostic"});
        path = sample_small_body_orbit_path(record, {2451543, 2451547, 5});
        for (const auto& sample : path.samples) {
            expect(!sample.evaluation.state, "legacy frame or time scale never guessed");
            expect(diagnostic(sample.evaluation, unknown_frame ? SmallBodyDiagnosticCode::unresolved_frame
                                                              : SmallBodyDiagnosticCode::unresolved_time_scale),
                   "unresolved contract diagnosed");
            expect(sample.evaluation.diagnostics.front().message == "retained diagnostic",
                   "original diagnostic retained");
        }
        expect(small_body_orbit_segments(path).empty(), "unresolved rows have no segments");
    }
    record = comet(1);
    record.orbit = std::monostate{};
    path = sample_small_body_orbit_path(record, {2451543, 2451547, 2});
    expect(!path.samples.front().evaluation.state && !path.samples.back().evaluation.state,
           "unknown elements are not converted to an orbit");
    record.orbit = PerihelionElements{-1, 1, 2451545, 0, 0, 0};
    path = sample_small_body_orbit_path(record, {2451543, 2451547, 2});
    expect(diagnostic(path.samples.front().evaluation, SmallBodyDiagnosticCode::calculation_failed),
           "evaluator failure retained without replacing coordinates");
}
void limits() {
    const auto record = comet(1);
    for (std::size_t count : {std::size_t{0}, std::size_t{1}, maximum_small_body_orbit_samples + 1})
        invalid([&] { sample_small_body_orbit_path(record, {2451543, 2451547, count}); });
    for (auto sampling : {SmallBodyOrbitSampling{1,1,2}, SmallBodyOrbitSampling{2,1,2},
                          SmallBodyOrbitSampling{-std::numeric_limits<double>::max(),
                                                 std::numeric_limits<double>::max(),2}})
        invalid([&] { sample_small_body_orbit_path(record, sampling); });
    for (double bad : {std::numeric_limits<double>::quiet_NaN(),
                       std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity()}) {
        invalid([&] { sample_small_body_orbit_path(record, {bad,2451547,2}); });
        invalid([&] { sample_small_body_orbit_path(record, {2451543,bad,2}); });
    }
    const double next = std::nextafter(2451545.0, std::numeric_limits<double>::infinity());
    invalid([&] { sample_small_body_orbit_path(record, {2451545,next,3}); });
    const auto smallest = sample_small_body_orbit_path(record, {2451545,next,2});
    expect(smallest.samples.front().julian_date == 2451545
           && smallest.samples.back().julian_date == next, "distinct adjacent double endpoints retained");
    const auto maximum = sample_small_body_orbit_path(record, {2451543,2451547,maximum_small_body_orbit_samples});
    expect(maximum.samples.size() == maximum_small_body_orbit_samples, "documented sample cap inclusive");
    expect(small_body_orbit_segments(maximum).size() == maximum_small_body_orbit_samples - 1,
           "maximum path remains open");
}
void local_data(const std::filesystem::path& root) {
    const auto dataset = load_small_body_dataset(root);
    std::size_t rows = 0, resolved = 0, unresolved = 0;
    for (const auto& record : dataset.records) {
        if (record.kind != SmallBodyKind::comet) continue;
        ++rows;
        const auto path = sample_small_body_orbit_path(record, {2451544,2451546,3});
        expect(path.samples.size() == 3, "every local comet row sampled without filtering");
        const bool confirmed = record.frame == SmallBodyFrame::heliocentric_j2000_ecliptic
                            && record.time_scale == SmallBodyTimeScale::tdb;
        if (path.samples[1].evaluation.state) ++resolved;
        else ++unresolved;
        for (const auto& sample : path.samples) {
            expect(confirmed || !sample.evaluation.state, "unconfirmed local contract never evaluated");
            if (sample.evaluation.state) {
                const auto p = sample.evaluation.state->position_au;
                expect(std::isfinite(p.x) && std::isfinite(p.y) && std::isfinite(p.z),
                       "local rendered coordinate finite");
            } else expect(!sample.evaluation.diagnostics.empty(), "local unavailable row has diagnostics");
        }
    }
    expect(rows > 0 && resolved > 0, "local comet source exercised");
    std::cout << "local comet rows=" << rows << " resolved=" << resolved
              << " unresolved=" << unresolved << '\n';
}
} // namespace

int main(int argc, char** argv) {
    try {
        finite_paths(); missing_samples(); limits();
        if (argc == 2) local_data(argv[1]);
        else if (argc != 1) throw std::invalid_argument("usage: test_small_body_orbit_path [data_directory]");
        std::cout << "small_body_orbit_path: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "small_body_orbit_path: " << error.what() << '\n';
        return 1;
    }
}
