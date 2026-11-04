#include "sdss_spatial_model.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>
#include <utility>

namespace mitaka::gui {
namespace {

SdssSpatialIssues issue_bits(SdssSpatialIssue issue) {
    return static_cast<SdssSpatialIssues>(issue);
}

SdssSpatialIssues record_issues(const SdssRecord& record) {
    SdssSpatialIssues issues = 0;
    const auto add = [&](SdssSpatialIssue issue) { issues |= issue_bits(issue); };
    const auto& coordinates = record.coordinates;
    if (!std::isfinite(coordinates.right_ascension_deg))
        add(SdssSpatialIssue::nonfinite_right_ascension);
    else if (coordinates.right_ascension_deg < 0 || coordinates.right_ascension_deg >= 360)
        add(SdssSpatialIssue::right_ascension_out_of_range);
    if (!std::isfinite(coordinates.declination_deg))
        add(SdssSpatialIssue::nonfinite_declination);
    else if (coordinates.declination_deg < -90 || coordinates.declination_deg > 90)
        add(SdssSpatialIssue::declination_out_of_range);
    if (!std::isfinite(record.distance_parsecs))
        add(SdssSpatialIssue::nonfinite_distance);
    else if (record.distance_parsecs < 0)
        add(SdssSpatialIssue::negative_distance);
    else if (record.distance_parsecs == 0)
        add(SdssSpatialIssue::zero_distance);
    if (!std::isfinite(record.classification_value))
        add(SdssSpatialIssue::nonfinite_classification);
    return issues;
}

SdssSpatialRow evaluate_row(const SdssRecord& record) {
    SdssSpatialRow row;
    row.issues = record_issues(record);
    if ((row.issues & ~issue_bits(SdssSpatialIssue::zero_distance)) != 0) return row;
    const Vec3 direction = equatorial_direction(record.coordinates);
    const double distance_pc = record.distance_parsecs;
    // float の距離を double で掛けるため、有限な原距離で積が overflow しない。
    const Vec3 equatorial{direction.x * distance_pc, direction.y * distance_pc,
                          direction.z * distance_pc};
    const Vec3 ecliptic = j2000_equatorial_to_ecliptic(equatorial);
    row.position = SdssSpatialPositionPc{
        {equatorial.x, equatorial.y, equatorial.z}, {ecliptic.x, ecliptic.y, ecliptic.z}};
    return row;
}

} // namespace

SdssSpatialModel::SdssSpatialModel(std::vector<SdssSpatialSource> sources)
    : sources_(std::move(sources)) {
    source_offsets_.reserve(sources_.size());
    for (const auto& source : sources_) {
        if (source.kind != SdssKind::galaxy && source.kind != SdssKind::quasar)
            throw std::invalid_argument("SDSS spatial model: unknown source kind");
        if (source.path.empty())
            throw std::invalid_argument("SDSS spatial model: empty source path");
        if (source.records.size() > std::numeric_limits<std::size_t>::max() - row_count_)
            throw std::length_error("SDSS spatial model: total row count overflow");
        source_offsets_.push_back(row_count_);
        row_count_ += source.records.size();
    }
}

SdssSpatialRecordId SdssSpatialModel::record_id(std::size_t row) const {
    if (row >= row_count_) throw std::out_of_range("SDSS spatial model: row out of range");
    const auto after = std::upper_bound(source_offsets_.begin(), source_offsets_.end(), row);
    const auto source = static_cast<std::size_t>(after - source_offsets_.begin() - 1);
    return {source, row - source_offsets_[source]};
}

std::size_t SdssSpatialModel::row_index(SdssSpatialRecordId id) const {
    if (id.source_index >= sources_.size() ||
        id.ordinal >= sources_[id.source_index].records.size())
        throw std::out_of_range("SDSS spatial model: record ID out of range");
    return source_offsets_[id.source_index] + id.ordinal;
}

const SdssRecord& SdssSpatialModel::record(SdssSpatialRecordId id) const {
    (void)row_index(id);
    return sources_[id.source_index].records[id.ordinal];
}

bool has_sdss_spatial_issue(SdssSpatialIssues issues, SdssSpatialIssue issue) noexcept {
    return (issues & issue_bits(issue)) != 0;
}

std::string_view sdss_spatial_issue_message(SdssSpatialIssue issue) {
    switch (issue) {
    case SdssSpatialIssue::none: return "position available";
    case SdssSpatialIssue::not_evaluated: return "row not evaluated";
    case SdssSpatialIssue::zero_distance: return "zero catalog distance; position is the origin";
    case SdssSpatialIssue::nonfinite_right_ascension: return "non-finite right ascension";
    case SdssSpatialIssue::right_ascension_out_of_range: return "right ascension outside [0,360) degrees";
    case SdssSpatialIssue::nonfinite_declination: return "non-finite declination";
    case SdssSpatialIssue::declination_out_of_range: return "declination outside [-90,90] degrees";
    case SdssSpatialIssue::nonfinite_distance: return "non-finite distance in parsecs";
    case SdssSpatialIssue::negative_distance: return "negative distance in parsecs";
    case SdssSpatialIssue::nonfinite_classification: return "non-finite classification value";
    }
    throw std::invalid_argument("SDSS spatial model: unknown issue");
}

std::shared_ptr<const SdssSpatialSnapshot> evaluate_sdss_spatial_snapshot(
    std::shared_ptr<const SdssSpatialModel> model, std::function<bool()> should_cancel) {
    if (!model) throw std::invalid_argument("SDSS spatial model: missing model");
    auto snapshot = std::make_shared<SdssSpatialSnapshot>();
    snapshot->model = std::move(model);
    snapshot->rows.resize(snapshot->model->size());
    for (const auto& source : snapshot->model->sources()) {
        for (const auto& record : source.records) {
            if (should_cancel && should_cancel()) {
                snapshot->cancelled = true;
                return snapshot;
            }
            auto& row = snapshot->rows[snapshot->completed_count];
            row = evaluate_row(record);
            ++snapshot->completed_count;
            if (row.position) ++snapshot->positioned_count;
            else ++snapshot->invalid_count;
            if (has_sdss_spatial_issue(row.issues, SdssSpatialIssue::zero_distance))
                ++snapshot->zero_distance_count;
        }
    }
    return snapshot;
}

} // namespace mitaka::gui
