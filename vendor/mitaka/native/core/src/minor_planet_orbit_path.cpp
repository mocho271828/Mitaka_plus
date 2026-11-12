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
    const auto at_epoch = evaluate_minor_planet_position(record, epoch);
    // 元期が宣言期間外でも、期間内の別の標本は評価できる。
    if (at_epoch.status == MinorPlanetPositionStatus::invalid_record || !orbit || orbit->eccentricity > 1) {
        for (const auto& diagnostic : at_epoch.diagnostics) retain_diagnostic(path, diagnostic);
        if (orbit && orbit->eccentricity > 1 && at_epoch.status != MinorPlanetPositionStatus::invalid_record)
            retain_diagnostic(path, {SmallBodyDiagnosticCode::invalid_time, path.id.source_key,
                path.id.record_ordinal, "orbit_period", "a hyperbolic orbit has no period to sample"});
        return path;
    }
    const double motion = orbit->mean_motion_deg_per_day;
    const double mean = std::remainder(orbit->mean_anomaly_deg, 360.0);
    // 位相が同じ複数の近日点のうち、元期を一周の区間に含む直前の通過を代表JDにする。
    const double start = epoch - (mean < 0 ? 360.0 + mean : mean) / motion;
    const double end = epoch + (mean < 0 ? -mean : 360.0 - mean) / motion;
    try {
        validate_small_body_orbit_sampling({start, end, sample_count});
    } catch (const std::invalid_argument&) {
        for (const auto& diagnostic : at_epoch.diagnostics) retain_diagnostic(path, diagnostic);
        add_period_failure(path);
        return path;
    }
    constexpr double tau = 6.283185307179586476925286766559;
    std::vector<double> dates(sample_count);
    dates.front() = start;
    dates.back() = end;
    bool distinct = true;
    for (std::size_t i = 1; i + 1 < sample_count; ++i) {
        if (cancelled && cancelled()) { path.cancelled = true; return path; }
        const double anomaly = tau * (static_cast<double>(i) / (sample_count - 1));
        dates[i] = start + (end - start) * ((anomaly - orbit->eccentricity * std::sin(anomaly)) / tau);
        if (!std::isfinite(dates[i]) || dates[i] <= dates[i - 1] || dates[i] >= end)
            distinct = false;
    }
    // 高離心率・短周期で近日点付近のJDを区別できない場合は、検証済みの等時間格子を使う。
    if (!distinct) {
        for (std::size_t i = 1; i + 1 < sample_count; ++i)
            dates[i] = start + (end - start) * (static_cast<double>(i) / (sample_count - 1));
    }
    path.samples.reserve(sample_count);
    for (std::size_t i = 0; i < sample_count; ++i) {
        if (cancelled && cancelled()) { path.cancelled = true; return path; }
        const double date = dates[i];
        retain_evaluation(path, evaluate_minor_planet_position(record, date));
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
