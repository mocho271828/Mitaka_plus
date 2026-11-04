#include "satellite_display.hpp"

#include <stdexcept>
#include <utility>

namespace mitaka::gui {

bool SatelliteIdLess::operator()(const SatelliteRecordId& lhs, const SatelliteRecordId& rhs) const noexcept {
    if (lhs.source_key != rhs.source_key) return lhs.source_key < rhs.source_key;
    return lhs.record_ordinal < rhs.record_ordinal;
}

SatelliteDisplayModel::SatelliteDisplayModel(std::shared_ptr<const SatelliteModel> model)
    : model_(std::move(model)) {
    if (!model_) throw std::invalid_argument("satellite display model is null");
    const auto& data = model_->dataset();
    for (std::size_t index = 0; index < data.sources.size(); ++index) {
        const auto& source = data.sources[index];
        if (source.key.empty() || !sources_.emplace(source.key, index).second)
            throw std::invalid_argument("satellite display source identity is invalid");
    }
    std::set<SatelliteRecordId, SatelliteIdLess> definitions;
    for (const auto& definition : data.definitions) {
        const auto found = sources_.find(definition.id.source_key);
        if (found == sources_.end())
            throw std::invalid_argument("satellite display definition source is missing");
        const auto& source = data.sources[found->second];
        if (source.kind != SatelliteSourceKind::system_definition || !source.read_complete || !source.parsed
            || definition.id.record_ordinal >= source.record_count || !definitions.insert(definition.id).second)
            throw std::invalid_argument("satellite display definition identity is invalid");
    }
    for (std::size_t row = 0; row < model_->records().size(); ++row) {
        const auto index = model_->records()[row].definition_index;
        if (index >= data.definitions.size() || data.definitions[index].kind != SatelliteDefinitionKind::satellite
            || !rows_.emplace(data.definitions[index].id, row).second)
            throw std::invalid_argument("satellite display record identity is invalid");
    }
}

const SatelliteRecordId& SatelliteDisplayModel::id_at(std::size_t row) const {
    if (row >= model_->records().size()) throw std::out_of_range("satellite display row is out of range");
    return model_->dataset().definitions[model_->records()[row].definition_index].id;
}

std::optional<std::size_t> SatelliteDisplayModel::row_for_id(const SatelliteRecordId& id) const {
    const auto found = rows_.find(id);
    if (found == rows_.end()) return std::nullopt;
    return found->second;
}

void SatelliteDisplayModel::set_selected_ids(const std::vector<SatelliteRecordId>& ids) {
    std::set<SatelliteRecordId, SatelliteIdLess> next;
    for (const auto& id : ids)
        if (rows_.find(id) == rows_.end() || !next.insert(id).second)
            throw std::invalid_argument("satellite display set contains unknown or duplicate identity");
    selected_.swap(next);
}

std::vector<SatelliteRecordId> SatelliteDisplayModel::selected_ids() const {
    return {selected_.begin(), selected_.end()};
}

bool SatelliteDisplayModel::contains(const SatelliteRecordId& id) const {
    return selected_.find(id) != selected_.end();
}

SatelliteLayerVisibility SatelliteDisplayModel::visibility(std::size_t row) const {
    const auto& id = id_at(row);
    const bool visible = options_.visible && (!options_.selected_only || contains(id));
    return {visible, visible && options_.labels, visible && options_.orbits};
}

SatelliteDisplayRebind SatelliteDisplayModel::rebind(std::shared_ptr<const SatelliteModel> model) {
    SatelliteDisplayModel next(std::move(model));
    next.options_ = options_;
    std::set<std::string> unchanged_sources;
    // 原 bytes の比較は出典ごとに一度。登録順や軌道ファイルを ID の代用にしない。
    for (const auto& source : sources_) {
        const auto found = next.sources_.find(source.first);
        if (found != next.sources_.end()
            && model_->dataset().sources[source.second].bytes == next.model_->dataset().sources[found->second].bytes)
            unchanged_sources.insert(source.first);
    }
    SatelliteDisplayRebind report;
    for (const auto& id : selected_) {
        if (next.rows_.find(id) != next.rows_.end() && unchanged_sources.find(id.source_key) != unchanged_sources.end()) {
            next.selected_.insert(id);
            ++report.retained_count;
        } else report.removed_ids.push_back(id);
    }
    *this = std::move(next);
    return report;
}

} // namespace mitaka::gui
