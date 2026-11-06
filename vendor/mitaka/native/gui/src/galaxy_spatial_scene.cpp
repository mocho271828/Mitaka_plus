#include "galaxy_spatial_scene.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <set>
#include <stdexcept>
#include <type_traits>

namespace mitaka::gui {
namespace {
const SdssSpatialSource& sdss_source(const GalaxySdssSource& source) {
    if (!source.snapshot || !source.snapshot->model)
        throw std::invalid_argument("galaxy scene: missing SDSS snapshot model");
    return source.snapshot->model->sources().at(source.source_index);
}
void validate_snapshot(const SdssSpatialSnapshot& snapshot) {
    if (snapshot.cancelled || !snapshot.model || snapshot.rows.size() != snapshot.model->size() ||
        snapshot.completed_count != snapshot.rows.size())
        throw std::invalid_argument("galaxy scene: incomplete SDSS snapshot");
    std::size_t positioned = 0, zero = 0;
    for (const auto& row : snapshot.rows) {
        constexpr auto zero_bit = static_cast<std::uint16_t>(SdssSpatialIssue::zero_distance);
        if ((row.issues & ~std::uint16_t{0x1fe}) != 0 ||
            row.position.has_value() != ((row.issues & ~zero_bit) == 0))
            throw std::invalid_argument("galaxy scene: inconsistent SDSS row state");
        if (row.issues & zero_bit) ++zero;
        if (!row.position) continue;
        ++positioned;
        const auto& p = *row.position;
        for (const double value : {p.equatorial.x_pc, p.equatorial.y_pc, p.equatorial.z_pc,
                                  p.native_ecliptic.x_pc, p.native_ecliptic.y_pc, p.native_ecliptic.z_pc})
            if (!std::isfinite(value) || std::abs(value) > maximum_galaxy_coordinate_pc)
                throw std::invalid_argument("galaxy scene: invalid SDSS position in parsecs");
    }
    if (snapshot.positioned_count != positioned || snapshot.invalid_count != snapshot.rows.size() - positioned ||
        snapshot.zero_distance_count != zero)
        throw std::invalid_argument("galaxy scene: inconsistent SDSS snapshot counts");
}
} // namespace

bool operator==(GalaxySpatialRecordId left, GalaxySpatialRecordId right) noexcept {
    return left.family == right.family && left.source_index == right.source_index && left.ordinal == right.ordinal;
}

GalaxySpatialModel::GalaxySpatialModel(std::vector<GalaxySpatialSource> sources)
    : sources_(std::move(sources)) {
    std::set<const SdssSpatialSnapshot*> validated;
    offsets_.reserve(sources_.size());
    for (std::size_t source = 0; source < sources_.size(); ++source) {
        if (const auto* sdss = std::get_if<GalaxySdssSource>(&sources_[source])) {
            (void)sdss_source(*sdss);
            if (validated.insert(sdss->snapshot.get()).second) validate_snapshot(*sdss->snapshot);
        }
        if (source_path(source).empty()) throw std::invalid_argument("galaxy scene: empty source path");
        const auto count = source_size(source);
        if (count > std::numeric_limits<std::size_t>::max() - row_count_)
            throw std::length_error("galaxy scene: total row count overflow");
        offsets_.push_back(row_count_);
        row_count_ += count;
    }
}
std::size_t GalaxySpatialModel::source_size(std::size_t source) const {
    return std::visit([](const auto& value) {
        if constexpr (std::is_same_v<std::decay_t<decltype(value)>, GalaxySdssSource>)
            return sdss_source(value).records.size();
        else return value.records.size();
    }, sources_.at(source));
}
GalaxySpatialFamily GalaxySpatialModel::family(std::size_t source) const {
    return std::visit([](const auto& value) {
        using T = std::decay_t<decltype(value)>;
        if constexpr (std::is_same_v<T, GalaxySdssSource>)
            return sdss_source(value).kind == SdssKind::galaxy ? GalaxySpatialFamily::sdss_galaxy
                                                            : GalaxySpatialFamily::sdss_quasar;
        else if constexpr (std::is_same_v<T, PlusGlobularClusterCatalog>)
            return GalaxySpatialFamily::globular_cluster;
        else return GalaxySpatialFamily::nearby_galaxy;
    }, sources_.at(source));
}
const std::filesystem::path& GalaxySpatialModel::source_path(std::size_t source) const {
    return std::visit([](const auto& value) -> const std::filesystem::path& {
        if constexpr (std::is_same_v<std::decay_t<decltype(value)>, GalaxySdssSource>)
            return sdss_source(value).path;
        else return value.source.path;
    }, sources_.at(source));
}
GalaxySpatialRecordId GalaxySpatialModel::record_id(std::size_t row) const {
    if (row >= row_count_) throw std::out_of_range("galaxy scene: row out of range");
    const auto after = std::upper_bound(offsets_.begin(), offsets_.end(), row);
    const auto source = static_cast<std::size_t>(after - offsets_.begin() - 1);
    return {family(source), source, row - offsets_[source]};
}
std::size_t GalaxySpatialModel::row_index(GalaxySpatialRecordId id) const {
    if (id.source_index >= sources_.size() || id.ordinal >= source_size(id.source_index) ||
        id.family != family(id.source_index))
        throw std::out_of_range("galaxy scene: record ID out of range or wrong family");
    return offsets_[id.source_index] + id.ordinal;
}
GalaxySpatialRow GalaxySpatialModel::row(GalaxySpatialRecordId id) const {
    (void)row_index(id);
    return std::visit([&](const auto& source) -> GalaxySpatialRow {
        if constexpr (std::is_same_v<std::decay_t<decltype(source)>, GalaxySdssSource>) {
            const auto offset = source.snapshot->model->row_index({source.source_index, id.ordinal});
            const auto& row = source.snapshot->rows.at(offset);
            return {id, row.position ? std::optional{row.position->native_ecliptic} : std::nullopt,
                    GalaxyIssueDomain::sdss, row.issues};
        } else {
            const auto& record = source.records.at(id.ordinal);
            auto declination = record.declination_degrees;
            if constexpr (std::is_same_v<std::decay_t<decltype(source)>, PlusNearbyGalaxyCatalog>) {
                // Plus NBG.dat は南天の赤緯を 270〜360 度で保持する。
                if (declination >= 270 && declination < 360) declination -= 360;
            }
            const auto result = evaluate_galaxy_position_pc(record.right_ascension_degrees,
                declination, record.distance_pc);
            std::optional<NativeEclipticPositionPc> position;
            if (result.position) {
                const auto& p = result.position->native_ecliptic;
                position = NativeEclipticPositionPc{p.x_pc, p.y_pc, p.z_pc};
            }
            return {id, position, GalaxyIssueDomain::galaxy_catalog, result.issues};
        }
    }, sources_.at(id.source_index));
}

bool GalaxySpatialVisibility::visible(GalaxySpatialFamily family) const {
    switch (family) {
    case GalaxySpatialFamily::sdss_galaxy: return sdss_galaxies;
    case GalaxySpatialFamily::sdss_quasar: return sdss_quasars;
    case GalaxySpatialFamily::globular_cluster: return globular_clusters;
    case GalaxySpatialFamily::nearby_galaxy: return nearby_galaxies;
    }
    throw std::invalid_argument("galaxy scene: unknown display family");
}

std::optional<GalaxySpatialRecordId> pick_galaxy_spatial_row(
    const GalaxySpatialModel& model, const GalaxyProjector& projector,
    GalaxySpatialVisibility visibility, double x, double y, double radius,
    std::function<bool()> should_cancel) {
    if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(radius) || radius < 0 || radius > 1e7)
        throw std::invalid_argument("galaxy scene: invalid pick position or radius");
    if (!projector.contains({x, y, 0})) return std::nullopt;
    std::optional<GalaxySpatialRecordId> nearest;
    double nearest_distance = radius, nearest_depth = std::numeric_limits<double>::infinity();
    double nearest_x = 0, nearest_y = 0;
    for (std::size_t source = 0; source < model.sources().size(); ++source) {
        if (should_cancel && should_cancel()) return std::nullopt;
        const auto family = model.family(source);
        if (!visibility.visible(family)) continue;
        const auto count = model.source_size(source);
        for (std::size_t ordinal = 0; ordinal < count; ++ordinal) {
            if (ordinal % 256 == 0 && should_cancel && should_cancel()) return std::nullopt;
            const GalaxySpatialRecordId id{family, source, ordinal};
            const auto row = model.row(id);
            if (!row.position) continue;
            const auto point = projector.project(*row.position);
            if (!point || !projector.contains(*point)) continue;
            const double distance = std::hypot(point->x - x, point->y - y);
            if (distance > nearest_distance || (nearest && distance == nearest_distance &&
                point->depth_pc >= nearest_depth &&
                (point->x != nearest_x || point->y != nearest_y))) continue;
            nearest = id;
            nearest_distance = distance;
            nearest_depth = point->depth_pc;
            nearest_x = point->x; nearest_y = point->y;
        }
    }
    return should_cancel && should_cancel() ? std::nullopt : nearest;
}

void GalaxySpatialScene::set_model(std::shared_ptr<const GalaxySpatialModel> model) {
    if (model == model_) return;
    model_ = std::move(model);
    selection_.reset();
}
void GalaxySpatialScene::select(std::optional<GalaxySpatialRecordId> id) {
    if (id) {
        if (!model_) throw std::invalid_argument("galaxy scene: cannot select without a model");
        (void)model_->row_index(*id);
    }
    selection_ = id;
}
bool GalaxySpatialScene::focus_selection(GalaxyCameraPc& camera) const {
    (void)checked_galaxy_camera(camera);
    if (!selection_ || !model_) return false;
    const auto row = model_->row(*selection_);
    if (!row.position) return false;
    auto next = camera;
    next.target = *row.position;
    next.target_offset_au = {};
    camera = checked_galaxy_camera(next);
    return true;
}

} // namespace mitaka::gui
