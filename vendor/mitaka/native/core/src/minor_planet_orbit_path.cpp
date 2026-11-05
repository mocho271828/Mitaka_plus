#include "mitaka/minor_planet_orbit_path.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>
#include <utility>

namespace mitaka {
namespace {
std::size_t retain_diagnostic(MinorPlanetOrbitPath& path, const SmallBodyDiagnostic& diagnostic) {
    const auto found = std::find_if(path.diagnostics.begin(), path.diagnostics.end(),
        [&](const auto& existing) {
            return existing.code == diagnostic.code && existing.source_key == diagnostic.source_key
                && existing.record_ordinal == diagnostic.record_ordinal
                && existing.field == diagnostic.field && existing.message == diagnostic.message;
        });
    if (found != path.diagnostics.end())
        return static_cast<std::size_t>(found - path.diagnostics.begin());
    path.diagnostics.push_back(diagnostic);
    return path.diagnostics.size() - 1;
}

void retain_evaluation(MinorPlanetOrbitPath& path, MinorPlanetPositionEvaluation evaluation) {
    const auto index = path.samples.size();
    MinorPlanetOrbitFailure failure{index, {}};
    for (const auto& diagnostic : evaluation.diagnostics) {
        const auto diagnostic_index = retain_diagnostic(path, diagnostic);
        if (!evaluation.heliocentric_j2000_ecliptic_au)
            failure.diagnostic_indices.push_back(diagnostic_index);
    }
    path.samples.push_back({evaluation.legacy_julian_date, evaluation.heliocentric_j2000_ecliptic_au});
    if (!evaluation.heliocentric_j2000_ecliptic_au) path.failures.push_back(std::move(failure));
}

void add_period_failure(MinorPlanetOrbitPath& path) {
    retain_diagnostic(path, {SmallBodyDiagnosticCode::invalid_time, path.id.source_key,
        path.id.record_ordinal, "orbit_period", "full-period sample times cannot be represented"});
}
} // namespace

MinorPlanetOrbitPath sample_minor_planet_orbit_path(const SmallBodyRecord& record,
    std::size_t sample_count, std::function<bool()> cancelled) {
    if (sample_count < 2 || sample_count > maximum_small_body_orbit_samples)
        throw std::invalid_argument("invalid minor-planet orbit sample count");
    MinorPlanetOrbitPath path{record.id, {}, {}, {}, false};
    if (cancelled && cancelled()) { path.cancelled = true; return path; }
    const auto* orbit = std::get_if<OrbitalElements>(&record.orbit);
    const double epoch = orbit ? orbit->epoch_jd : 0;
    auto first = evaluate_minor_planet_position(record, epoch);
    for (const auto& diagnostic : first.diagnostics) retain_diagnostic(path, diagnostic);
    // 源行自体の不正や未対応形式は、無意味な 129 回の同一失敗に展開しない。
    if (first.status == MinorPlanetPositionStatus::invalid_record) return path;
    if (!orbit || !std::isfinite(epoch) || !std::isfinite(orbit->mean_motion_deg_per_day)
        || orbit->mean_motion_deg_per_day <= 0) { add_period_failure(path); return path; }
    const double period = 360.0 / orbit->mean_motion_deg_per_day;
    const double end = epoch + period;
    try {
        validate_small_body_orbit_sampling({epoch, end, sample_count});
    } catch (const std::invalid_argument&) {
        add_period_failure(path);
        return path;
    }
    path.samples.reserve(sample_count);
    for (std::size_t i = 0; i < sample_count; ++i) {
        if (cancelled && cancelled()) { path.cancelled = true; return path; }
        const double date = i == sample_count - 1 ? end
            : epoch + (end - epoch) * (static_cast<double>(i) / (sample_count - 1));
        retain_evaluation(path, i == 0 ? std::move(first)
                                       : evaluate_minor_planet_position(record, date));
    }
    if (cancelled && cancelled()) path.cancelled = true;
    return path;
}

std::vector<std::array<std::size_t, 2>> minor_planet_orbit_segments(const MinorPlanetOrbitPath& path) {
    std::vector<std::array<std::size_t, 2>> segments;
    if (path.samples.empty() || path.cancelled) return segments;
    segments.reserve(path.samples.size() - 1);
    for (std::size_t i = 1; i < path.samples.size(); ++i)
        if (path.samples[i - 1].position && path.samples[i].position) segments.push_back({i - 1, i});
    return segments;
}
} // namespace mitaka
