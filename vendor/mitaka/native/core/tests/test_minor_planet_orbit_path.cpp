#include "mitaka/minor_planet_orbit_path.hpp"

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
bool diagnostic(const MinorPlanetOrbitPath& path, SmallBodyDiagnosticCode code) {
    return std::any_of(path.diagnostics.begin(), path.diagnostics.end(),
                       [=](const auto& d) { return d.code == code; });
}
SmallBodyRecord asteroid() {
    SmallBodyRecord r;
    r.id = {"mp.dat", 42};
    r.kind = SmallBodyKind::asteroid;
    r.encoding = SmallBodyEncoding::packed_36;
    r.raw_record_bytes = std::string(36, '\0');
    r.orbit = OrbitalElements{2451545, 1, 0.2, 30, 1, 20, 10, 40};
    return r;
}
void full_period() {
    for (const auto kind : {SmallBodyKind::asteroid, SmallBodyKind::trans_neptunian}) {
        auto record = asteroid();
        record.kind = kind;
        const auto path = sample_minor_planet_orbit_path(record, 129);
        expect(path.id.source_key == "mp.dat" && path.id.record_ordinal == 42, "identity");
        expect(path.samples.size() == 129 && path.failures.empty() && !path.cancelled, "whole period");
        expect(path.samples.front().julian_date == 2451545 && path.samples.back().julian_date == 2451905,
               "full period endpoints");
        expect(diagnostic(path, SmallBodyDiagnosticCode::unknown_accuracy_range), "accuracy unknown");
        expect(diagnostic(path, SmallBodyDiagnosticCode::unresolved_time_scale), "time scale unresolved");
        for (const auto& sample : path.samples) {
            const auto expected = evaluate_minor_planet_position(record, sample.julian_date);
            expect(sample.position && expected.heliocentric_j2000_ecliptic_au, "position present");
            const auto a = *sample.position, b = *expected.heliocentric_j2000_ecliptic_au;
            expect(a.x == b.x && a.y == b.y && a.z == b.z, "coordinates use same evaluation");
        }
        expect(minor_planet_orbit_segments(path).size() == 128, "no implicit extra closure");
        expect(record.raw_record_bytes == std::string(36, '\0'), "source preserved");
    }
}
void failures_and_gaps() {
    auto record = asteroid();
    record.declared_time_range = SmallBodyTimeRange{2451635, 2451815};
    auto path = sample_minor_planet_orbit_path(record, 5);
    expect(path.samples.size() == 5 && path.failures.size() == 2, "range failures retained");
    expect(!path.samples.front().position && !path.samples.back().position, "out of range absent");
    for (const auto& failure : path.failures) {
        bool found = false;
        for (const auto i : failure.diagnostic_indices) {
            expect(i < path.diagnostics.size(), "diagnostic index valid");
            found |= path.diagnostics[i].code == SmallBodyDiagnosticCode::outside_time_range;
        }
        expect(found, "failure reason retained per sample");
    }
    expect(minor_planet_orbit_segments(path) == std::vector<std::array<std::size_t, 2>>{{1,2},{2,3}},
           "range endpoints included");
    for (const auto code : {SmallBodyDiagnosticCode::invalid_source, SmallBodyDiagnosticCode::invalid_time,
                            SmallBodyDiagnosticCode::calculation_failed}) {
        auto with_prior_diagnostic = record;
        with_prior_diagnostic.diagnostics.push_back({code, record.id.source_key,
            record.id.record_ordinal, "prior", "diagnostic from source loading"});
        const auto recovered = sample_minor_planet_orbit_path(with_prior_diagnostic, 5);
        expect(recovered.samples.size() == 5 && recovered.failures.size() == 2,
               "prior diagnostic does not discard valid later samples");
        expect(minor_planet_orbit_segments(recovered) == std::vector<std::array<std::size_t, 2>>{{1,2},{2,3}},
               "prior diagnostic does not hide valid segments");
        expect(diagnostic(recovered, code), "prior diagnostic retained");
    }
    auto repeated_diagnostic = record;
    repeated_diagnostic.diagnostics.push_back({SmallBodyDiagnosticCode::outside_time_range,
        record.id.source_key, record.id.record_ordinal, "legacy_julian_date", "prior range warning"});
    const auto first_evaluation = evaluate_minor_planet_position(repeated_diagnostic, 2451545);
    expect(first_evaluation.status == MinorPlanetPositionStatus::unavailable_at_time,
           "time failure status is independent of prior diagnostics");
    expect(std::count_if(first_evaluation.diagnostics.begin(), first_evaluation.diagnostics.end(),
        [](const auto& d) { return d.code == SmallBodyDiagnosticCode::outside_time_range; }) == 2,
        "distinct prior and current range diagnostics retained");
    repeated_diagnostic.encoding = SmallBodyEncoding::packed_37;
    repeated_diagnostic.diagnostics.push_back({SmallBodyDiagnosticCode::invalid_source,
        record.id.source_key, record.id.record_ordinal, "encoding", "prior encoding warning"});
    const auto unsupported = evaluate_minor_planet_position(repeated_diagnostic, 2451545);
    expect(unsupported.status == MinorPlanetPositionStatus::invalid_record,
           "unsupported record status is independent of prior diagnostics");
    expect(std::count_if(unsupported.diagnostics.begin(), unsupported.diagnostics.end(),
        [](const auto& d) { return d.code == SmallBodyDiagnosticCode::invalid_source && d.field == "encoding"; }) == 2,
        "distinct prior and current encoding diagnostics retained");
    path.samples[2].position.reset();
    expect(minor_planet_orbit_segments(path).empty(), "interior missing point is not bridged");
    for (const auto encoding : {SmallBodyEncoding::packed_37, SmallBodyEncoding::element_text}) {
        record = asteroid(); record.encoding = encoding;
        path = sample_minor_planet_orbit_path(record, 129);
        expect(path.samples.empty() && diagnostic(path, SmallBodyDiagnosticCode::invalid_source),
               "unsupported format remains unresolved");
    }
    record = asteroid(); record.kind = SmallBodyKind::comet;
    path = sample_minor_planet_orbit_path(record, 129);
    expect(path.samples.empty() && diagnostic(path, SmallBodyDiagnosticCode::invalid_source), "wrong kind");
    record = asteroid(); std::get<OrbitalElements>(record.orbit).eccentricity = 1;
    path = sample_minor_planet_orbit_path(record, 129);
    expect(path.samples.empty() && diagnostic(path, SmallBodyDiagnosticCode::calculation_failed), "non ellipse");
    record = asteroid(); std::get<OrbitalElements>(record.orbit).mean_motion_deg_per_day = 1e-320;
    path = sample_minor_planet_orbit_path(record, 129);
    expect(path.samples.empty() && (diagnostic(path, SmallBodyDiagnosticCode::invalid_time) || diagnostic(path, SmallBodyDiagnosticCode::calculation_failed)), "overflow period");
    record = asteroid(); std::get<OrbitalElements>(record.orbit).mean_motion_deg_per_day = 1e300;
    path = sample_minor_planet_orbit_path(record, 129);
    expect(path.samples.empty() && (diagnostic(path, SmallBodyDiagnosticCode::invalid_time) || diagnostic(path, SmallBodyDiagnosticCode::calculation_failed)), "undistinguishable dates");
}
void cancellation_and_count() {
    auto record = asteroid();
    for (std::size_t n : {std::size_t{0}, std::size_t{1}, maximum_small_body_orbit_samples + 1}) {
        bool rejected = false;
        try { (void)sample_minor_planet_orbit_path(record, n); }
        catch (const std::invalid_argument&) { rejected = true; }
        expect(rejected, "invalid count rejected");
    }
    std::size_t calls = 0;
    const auto partial = sample_minor_planet_orbit_path(record, 129, [&] { return ++calls == 8; });
    expect(partial.cancelled && partial.samples.size() < 129, "per-sample cancellation");
    expect(minor_planet_orbit_segments(partial).empty(), "cancelled path is not drawable");
    const auto before = sample_minor_planet_orbit_path(record, 129, [] { return true; });
    expect(before.cancelled && before.samples.empty(), "cancel before work");
}
void local_data(const std::filesystem::path& root) {
    const auto dataset = load_small_body_dataset(root);
    std::size_t rows = 0, points = 0;
    for (const auto& record : dataset.records) {
        if (record.encoding != SmallBodyEncoding::packed_36) continue;
        const auto path = sample_minor_planet_orbit_path(record, 129);
        expect(path.samples.size() == 129 && path.failures.empty(), "real packed row fully sampled");
        rows++; points += path.samples.size();
        for (const auto& sample : path.samples)
            expect(sample.position && std::isfinite(sample.position->x) && std::isfinite(sample.position->y)
                   && std::isfinite(sample.position->z), "real point finite");
    }
    expect(rows > 0, "real catalog has packed rows");
    std::cout << "real packed rows=" << rows << " points=" << points << '\n';
}
}
int main(int argc, char** argv) {
    try {
        full_period(); failures_and_gaps(); cancellation_and_count();
        if (argc == 2) local_data(argv[1]);
        else if (argc != 1) throw std::invalid_argument("usage: test_minor_planet_orbit_path [data_directory]");
        std::cout << "minor_planet_orbit_path: " << checks << " checks passed\n";
    } catch (const std::exception& e) {
        std::cerr << "minor_planet_orbit_path: " << e.what() << '\n';
        return 1;
    }
}
