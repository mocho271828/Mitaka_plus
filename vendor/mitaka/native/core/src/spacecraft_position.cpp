#include "mitaka/spacecraft_position.hpp"

#include <cmath>
#include <utility>

namespace mitaka {
namespace {
using Code = SpacecraftDiagnosticCode;
using Kind = SpacecraftSamplingKind;

SpacecraftDiagnostic diagnostic(Code code, const std::string& key, std::string message,
                                 std::optional<std::size_t> ordinal = {}) {
    return {code, key, ordinal, ordinal ? *ordinal * 32ULL : 0, std::move(message)};
}

std::optional<SpacecraftDiagnostic> validate(const SpacecraftDataset& dataset,
                                            const SpacecraftTrajectoryRecord& record) {
    if (record.source_index >= dataset.sources.size())
        return diagnostic(Code::invalid_record_index, {}, "trajectory source index is outside the snapshot");
    const auto& source = dataset.sources[record.source_index];
    if (!source.parsed || !source.valid)
        return diagnostic(Code::invalid_source, source.key, "trajectory source did not pass loading validation");
    if (source.kind == SpacecraftSourceKind::ppi_segments)
        return diagnostic(Code::unresolved_spatial_contract, source.key,
            "PPI origin and coordinate basis are not verified for heliocentric J2000 ecliptic display");
    if (source.kind != SpacecraftSourceKind::pth_samples || record.ppi)
        return diagnostic(Code::invalid_source, source.key, "trajectory does not contain an unambiguous PTH sample source");
    const auto& samples = record.path_samples;
    if (samples.empty() || source.bytes.size() % 32 != 0 ||
        source.bytes.size() / 32 != samples.size() || source.record_count != samples.size())
        return diagnostic(Code::invalid_source, source.key, "PTH snapshot has empty or inconsistent record storage");
    for (std::size_t i = 0; i < samples.size(); ++i) {
        const auto& sample = samples[i];
        if (!std::isfinite(sample.time_value))
            return diagnostic(Code::invalid_number, source.key, "PTH sample time is not finite", i);
        for (const auto value : sample.coordinate_values)
            if (!std::isfinite(value))
                return diagnostic(Code::invalid_number, source.key, "PTH sample coordinate is not finite", i);
        if (i && sample.time_value < samples[i - 1].time_value)
            return diagnostic(Code::invalid_source, source.key, "PTH sample times decrease in original record order", i);
    }
    return {};
}

SpacecraftPositionSampling locate(const std::vector<SpacecraftPathSample>& samples, double time) {
    // 端点を先に検査するため、先頭・末尾の重複や全件同時刻も原版の採用順になる。
    if (time <= samples.front().time_value)
        return {time == samples.front().time_value ? Kind::exact_record : Kind::clamped_before, 0, 0, 0};
    const auto last = samples.size() - 1;
    if (time >= samples.back().time_value)
        return {time == samples.back().time_value ? Kind::exact_record : Kind::clamped_after, last, last, 0};
    std::size_t low = 0, high = last;
    while (high - low > 1) {
        const auto mid = low + (high - low) / 2;
        if (time == samples[mid].time_value) return {Kind::exact_record, mid, mid, 0};
        if (samples[mid].time_value > time) high = mid;
        else low = mid;
    }
    // 重複群の最初の binary-search mid を採る契約なので lower/upper_bound に置換しない。
    return {Kind::interpolated, low, high, 0};
}
} // namespace

SpacecraftPositionModel::SpacecraftPositionModel(SpacecraftDataset dataset)
    : dataset_(std::move(dataset)) {
    validation_errors_.reserve(dataset_.trajectories.size());
    for (const auto& record : dataset_.trajectories)
        validation_errors_.push_back(validate(dataset_, record));
}

SpacecraftPositionEvaluation SpacecraftPositionModel::evaluate(std::size_t index, double time) const {
    SpacecraftPositionEvaluation result;
    result.trajectory_index = index;
    result.legacy_julian_date = time;
    if (index >= dataset_.trajectories.size()) {
        result.diagnostics.push_back(diagnostic(Code::invalid_record_index, {}, "trajectory index is outside the snapshot"));
        return result;
    }
    const auto& record = dataset_.trajectories[index];
    const auto* source = record.source_index < dataset_.sources.size() ? &dataset_.sources[record.source_index] : nullptr;
    const std::string key = source ? source->key : std::string{};
    if (source) result.source_index = record.source_index;
    if (!std::isfinite(time)) {
        result.diagnostics.push_back(diagnostic(Code::invalid_time, key, "requested legacy numeric JD is not finite"));
        return result;
    }
    if (validation_errors_[index]) {
        result.diagnostics.push_back(*validation_errors_[index]);
        if (source && source->kind == SpacecraftSourceKind::ppi_segments)
            result.diagnostics.push_back(diagnostic(Code::unresolved_time_scale, key, "PPI physical time scale is not verified"));
        return result;
    }

    const auto& samples = record.path_samples;
    auto sampling = locate(samples, time);
    const auto& first = samples[sampling.first_record_index];
    auto position = first.coordinate_values;
    if (sampling.kind == Kind::interpolated) {
        const auto& second = samples[sampling.second_record_index];
        const double span = second.time_value - first.time_value;
        const double elapsed = time - first.time_value;
        if (!std::isfinite(span) || span <= 0 || !std::isfinite(elapsed)) {
            result.diagnostics.push_back(diagnostic(Code::numerical_range, key,
                "PTH interpolation time difference is outside the finite numeric range", sampling.first_record_index));
            return result;
        }
        sampling.u = elapsed / span;
        if (!std::isfinite(sampling.u) || sampling.u < 0 || sampling.u > 1) {
            result.diagnostics.push_back(diagnostic(Code::numerical_range, key,
                "PTH interpolation weight is outside [0,1]", sampling.first_record_index));
            return result;
        }
        for (std::size_t axis = 0; axis < position.size(); ++axis) {
            position[axis] = first.coordinate_values[axis] * (1 - sampling.u) +
                             second.coordinate_values[axis] * sampling.u;
            if (!std::isfinite(position[axis])) {
                result.diagnostics.push_back(diagnostic(Code::numerical_range, key,
                    "PTH interpolated coordinate is outside the finite numeric range", sampling.first_record_index));
                return result;
            }
        }
    }
    result.heliocentric_j2000_ecliptic_au = Vec3{position[0], position[1], position[2]};
    result.sampling = sampling;
    result.contract = spacecraft_pth_position_contract;
    result.diagnostics.push_back(diagnostic(Code::unresolved_time_scale, key,
        "PTH uses the requested legacy numeric JD unchanged; physical UTC/TT/TDB is not verified"));
    return result;
}
} // namespace mitaka
