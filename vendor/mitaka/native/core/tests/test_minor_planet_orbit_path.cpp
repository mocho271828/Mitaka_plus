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
void full_period(SmallBodyEncoding encoding) {
    for (const auto kind : {SmallBodyKind::asteroid, SmallBodyKind::trans_neptunian}) {
        auto record = asteroid();
        record.kind = kind;
        record.encoding = encoding;
        if (encoding == SmallBodyEncoding::element_text) {
            record.id = {"orbits/asteroids/custom.dat", 0};
            record.raw_record_bytes = "Name: Custom\r\na: 1\r\n";
            std::get<OrbitalElements>(record.orbit).mean_motion_deg_per_day = 0.985607669;
        }
        const auto& orbit = std::get<OrbitalElements>(record.orbit);
        const auto original = record.raw_record_bytes;
        const auto path = sample_minor_planet_orbit_path(record, 129);
        expect(path.id.source_key == record.id.source_key && path.id.record_ordinal == record.id.record_ordinal, "identity");
        expect(path.samples.size() == 129 && path.failures.empty() && !path.cancelled, "whole period");
        expect(path.samples.front().julian_date == orbit.epoch_jd - 30.0 / orbit.mean_motion_deg_per_day
               && path.samples.back().julian_date == orbit.epoch_jd + 330.0 / orbit.mean_motion_deg_per_day,
               "period starts and ends at perihelion and includes the element epoch");
        expect(diagnostic(path, SmallBodyDiagnosticCode::unknown_accuracy_range), "accuracy unknown");
        expect(diagnostic(path, SmallBodyDiagnosticCode::unresolved_time_scale), "time scale unresolved");
        for (const auto& sample : path.samples) {
            const auto expected = evaluate_minor_planet_position(record, sample.julian_date);
            expect(sample.position && expected.heliocentric_j2000_ecliptic_au, "position present");
            const auto a = *sample.position, b = *expected.heliocentric_j2000_ecliptic_au;
            expect(a.x == b.x && a.y == b.y && a.z == b.z, "coordinates use same evaluation");
        }
        expect(minor_planet_orbit_segments(path).size() == 128, "no implicit extra closure");
        expect(record.raw_record_bytes == original, "source preserved");
        const auto first = *path.samples.front().position, last = *path.samples.back().position;
        expect(std::hypot(first.x-last.x, std::hypot(first.y-last.y, first.z-last.z)) < 1e-10,
               "full period returns to initial position");
        std::size_t calls = 0;
        const auto cancelled = sample_minor_planet_orbit_path(record, 129, [&] { return ++calls == 8; });
        expect(cancelled.cancelled && minor_planet_orbit_segments(cancelled).empty(),
               "each supported encoding cancels without exposing partial segments");
    }
}
void explicit_motion_period() {
    auto record = asteroid();
    record.id = {"orbits/asteroids/explicit.dat", 0};
    record.encoding = SmallBodyEncoding::element_text;
    record.raw_record_bytes = "a: 2\r\nn: 90\r\n";
    record.fields = {{"a", "2"}, {"n", "90"}};
    record.orbit = OrbitalElements{2451545, 2, 0, 0, 90, 0, 0, 0};
    const auto original = record.raw_record_bytes;
    const auto path = sample_minor_planet_orbit_path(record, 5);
    expect(path.samples.size() == 5 && path.failures.empty(), "explicit n orbit sampled");
    const Vec3 expected[]{{2,0,0},{0,2,0},{-2,0,0},{0,-2,0},{2,0,0}};
    for (std::size_t i = 0; i < 5; ++i) {
        expect(path.samples[i].julian_date == 2451545 + i && path.samples[i].position,
               "explicit n gives four-day period");
        const auto p = *path.samples[i].position;
        expect(std::hypot(p.x-expected[i].x, std::hypot(p.y-expected[i].y, p.z)) < 1e-12,
               "explicit n orbit follows analytic circular positions");
    }
    expect(record.raw_record_bytes == original && minor_planet_orbit_segments(path).size() == 4,
           "explicit n path retains source and has no extra closure");
    auto invalid = record;
    invalid.fields[1].value_bytes = "0";
    const auto invalid_path = sample_minor_planet_orbit_path(invalid, 5);
    expect(invalid_path.samples.empty() && diagnostic(invalid_path, SmallBodyDiagnosticCode::invalid_source),
           "retained invalid n cannot yield an orbit path");
    auto mismatch = record;
    std::get<OrbitalElements>(mismatch.orbit).mean_motion_deg_per_day = 45;
    const auto mismatch_path = sample_minor_planet_orbit_path(mismatch, 5);
    expect(mismatch_path.samples.empty() && diagnostic(mismatch_path, SmallBodyDiagnosticCode::invalid_source),
           "inconsistent n cannot yield an orbit path");
}
void high_eccentricity_sampling(SmallBodyEncoding encoding) {
    auto record = asteroid();
    record.encoding = encoding;
    if (encoding == SmallBodyEncoding::element_text) record.raw_record_bytes = "a: 1\n";
    auto& orbit = std::get<OrbitalElements>(record.orbit);
    orbit.eccentricity = 0.99;
    orbit.mean_anomaly_deg = 0;
    auto path = sample_minor_planet_orbit_path(record, 129);
    expect(path.samples.size() == 129 && path.failures.empty(), "high-e full sample count");
    expect(path.samples.front().julian_date == orbit.epoch_jd &&
           path.samples.back().julian_date == orbit.epoch_jd + 360, "high-e full period");
    expect(path.samples[1].julian_date - orbit.epoch_jd < 0.1, "periapsis receives denser samples");
    for (std::size_t i = 1; i < path.samples.size(); ++i)
        expect(path.samples[i].julian_date > path.samples[i-1].julian_date, "dates increase");
    orbit.eccentricity = 0.9999999999;
    orbit.mean_motion_deg_per_day = 360.0 / 0.00001;
    path = sample_minor_planet_orbit_path(record, 129);
    expect(path.samples.size() == 129, "short period falls back instead of duplicating times");
    expect(path.samples[1].julian_date == orbit.epoch_jd +
           (path.samples.back().julian_date - orbit.epoch_jd) / 128, "short period uses equal-time fallback");
    for (std::size_t i = 1; i < path.samples.size(); ++i)
        expect(path.samples[i].julian_date > path.samples[i-1].julian_date, "fallback dates increase");
}
void large_mean_anomaly_sampling(SmallBodyEncoding encoding) {
    auto record = asteroid();
    record.encoding = encoding;
    if (encoding == SmallBodyEncoding::element_text) record.raw_record_bytes = "a: 1\n";
    auto& orbit = std::get<OrbitalElements>(record.orbit);
    orbit.eccentricity = 0.99;
    orbit.ascending_node_deg = orbit.inclination_deg = orbit.argument_of_periapsis_deg = 0;
    for (double mean : {1e18, -30.0, 330.0, 720.0}) {
        orbit.mean_anomaly_deg = mean;
        const auto path = sample_minor_planet_orbit_path(record, default_small_body_orbit_samples);
        expect(path.samples.size() == 201 && path.failures.empty(), "200 intervals and closing vertex");
        expect(path.samples.front().julian_date <= orbit.epoch_jd && orbit.epoch_jd < path.samples.back().julian_date,
               "the two perihelion passages bracket the epoch");
        const double minor = std::sqrt(1 - orbit.eccentricity * orbit.eccentricity);
        for (std::size_t i = 0; i < path.samples.size(); ++i) {
            const double anomaly = 2 * 3.14159265358979323846 * i / 200;
            const auto p = path.samples[i].position.value();
            expect(std::hypot(p.x - (std::cos(anomaly) - orbit.eccentricity),
                              p.y - minor * std::sin(anomaly)) < 2e-9,
                   "projected orbit obeys equal eccentric anomaly steps measured from perihelion");
        }
    }
}
void failures_and_gaps() {
    auto record = asteroid();
    std::get<OrbitalElements>(record.orbit).eccentricity = 0;
    std::get<OrbitalElements>(record.orbit).mean_anomaly_deg = 0;
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
    for (const auto encoding : {SmallBodyEncoding::packed_37, SmallBodyEncoding::comet_fixed_width}) {
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
    std::size_t rows = 0, individual = 0, points = 0;
    for (const auto& record : dataset.records) {
        const bool text = record.encoding == SmallBodyEncoding::element_text
            && record.kind != SmallBodyKind::comet;
        if (record.encoding != SmallBodyEncoding::packed_36 && !text) continue;
        const auto path = sample_minor_planet_orbit_path(record, default_small_body_orbit_samples);
        expect(path.samples.size() == default_small_body_orbit_samples && path.failures.empty() && !path.cancelled,
               "real supported row fully sampled");
        if (text) ++individual;
        rows++; points += path.samples.size();
        const auto& orbit = std::get<OrbitalElements>(record.orbit);
        expect(path.id.source_key == record.id.source_key && path.id.record_ordinal == record.id.record_ordinal,
               "real orbit retains independent source identity");
        const double start = path.samples.front().julian_date, end = path.samples.back().julian_date;
        const double period = 360 / orbit.mean_motion_deg_per_day;
        expect(start <= orbit.epoch_jd && orbit.epoch_jd <= end &&
               std::abs(end - start - period) <= std::max(1e-9, 2e-15 * period),
               "real orbit covers a period bracketing the element epoch");
        const auto peri = path.samples.front().position.value();
        expect(std::abs(std::hypot(peri.x, peri.y, peri.z) - orbit.semi_major_axis_au * (1 - orbit.eccentricity))
               < 2e-12 * orbit.semi_major_axis_au, "real first vertex lies at perihelion");
        for (const auto& sample : path.samples) {
            expect(sample.position && std::isfinite(sample.position->x) && std::isfinite(sample.position->y)
                   && std::isfinite(sample.position->z), "real point finite");
            const auto p = *sample.position;
            const double radius = std::hypot(p.x, std::hypot(p.y, p.z));
            const double tolerance = 2e-12 * orbit.semi_major_axis_au;
            expect(radius >= orbit.semi_major_axis_au * (1-orbit.eccentricity)-tolerance
                   && radius <= orbit.semi_major_axis_au * (1+orbit.eccentricity)+tolerance,
                   "real orbit stays between perihelion and aphelion");
        }
        expect(minor_planet_orbit_segments(path).size() == default_small_body_orbit_samples - 1, "real orbit does not add a duplicate closing segment");
    }
    expect(rows > 0, "real catalog has packed rows");
    std::cout << "real packed rows=" << rows-individual << " individual rows=" << individual
              << " points=" << points << '\n';
}
}
int main(int argc, char** argv) {
    try {
        full_period(SmallBodyEncoding::packed_36); full_period(SmallBodyEncoding::element_text);
        for (const auto encoding : {SmallBodyEncoding::packed_36, SmallBodyEncoding::element_text}) {
            high_eccentricity_sampling(encoding); large_mean_anomaly_sampling(encoding);
        }
        explicit_motion_period(); failures_and_gaps(); cancellation_and_count();
        if (argc == 2) local_data(argv[1]);
        else if (argc != 1) throw std::invalid_argument("usage: test_minor_planet_orbit_path [data_directory]");
        std::cout << "minor_planet_orbit_path: " << checks << " checks passed\n";
    } catch (const std::exception& e) {
        std::cerr << "minor_planet_orbit_path: " << e.what() << '\n';
        return 1;
    }
}
