#include "small_body_display.hpp"

#include <stdexcept>
#include <utility>

namespace mitaka::gui {

bool SmallBodyIdLess::operator()(const SmallBodyId& lhs, const SmallBodyId& rhs) const noexcept {
    if (lhs.source_key != rhs.source_key) return lhs.source_key < rhs.source_key;
    return lhs.record_ordinal < rhs.record_ordinal;
}

SmallBodyDisplayModel::SmallBodyDisplayModel(std::shared_ptr<const SmallBodyDataset> dataset)
    : dataset_(std::move(dataset)) {
    if (!dataset_) throw std::invalid_argument("small-body display dataset is null");
    for (std::size_t index = 0; index < dataset_->sources.size(); ++index) {
        const auto& source = dataset_->sources[index];
        if (source.key.empty() || !sources_.emplace(source.key, index).second)
            throw std::invalid_argument("small-body display source identity is invalid");
    }
    for (std::size_t row = 0; row < dataset_->records.size(); ++row) {
        const auto& record = dataset_->records[row];
        (void)options(record.kind);
        const auto source = sources_.find(record.id.source_key);
        if (source == sources_.end() || !dataset_->sources[source->second].loaded
            || record.id.record_ordinal >= dataset_->sources[source->second].record_count
            || !rows_.emplace(record.id, row).second)
            throw std::invalid_argument("small-body display record identity is invalid");
    }
}

SmallBodyKindDisplayOptions& SmallBodyDisplayModel::options(SmallBodyKind kind) {
    switch (kind) {
        case SmallBodyKind::asteroid: return asteroid_;
        case SmallBodyKind::trans_neptunian: return trans_neptunian_;
        case SmallBodyKind::comet: return comet_;
    }
    throw std::invalid_argument("invalid small-body kind");
}

const SmallBodyKindDisplayOptions& SmallBodyDisplayModel::options(SmallBodyKind kind) const {
    switch (kind) {
        case SmallBodyKind::asteroid: return asteroid_;
        case SmallBodyKind::trans_neptunian: return trans_neptunian_;
        case SmallBodyKind::comet: return comet_;
    }
    throw std::invalid_argument("invalid small-body kind");
}

SmallBodyKindDisplayOptions SmallBodyDisplayModel::kind_options(SmallBodyKind kind) const {
    return options(kind);
}

void SmallBodyDisplayModel::set_kind_options(SmallBodyKind kind, SmallBodyKindDisplayOptions value) {
    options(kind) = value;
}

void SmallBodyDisplayModel::set_selected_ids(const std::vector<SmallBodyId>& ids) {
    std::set<SmallBodyId, SmallBodyIdLess> next;
    for (const auto& id : ids)
        if (rows_.find(id) == rows_.end() || !next.insert(id).second)
            throw std::invalid_argument("small-body display set contains unknown or duplicate identity");
    selected_.swap(next);
}

std::vector<SmallBodyId> SmallBodyDisplayModel::selected_ids() const {
    return {selected_.begin(), selected_.end()};
}

bool SmallBodyDisplayModel::contains(const SmallBodyId& id) const {
    return selected_.find(id) != selected_.end();
}

SmallBodyLayerVisibility SmallBodyDisplayModel::visibility(std::size_t row) const {
    if (row >= dataset_->records.size()) throw std::out_of_range("small-body display row is out of range");
    const auto& record = dataset_->records[row];
    const auto& value = options(record.kind);
    const bool visible = value.visible && (!value.selected_only || contains(record.id));
    return {visible, visible && value.labels, visible && value.orbits};
}

SmallBodyDisplayRebind SmallBodyDisplayModel::rebind(std::shared_ptr<const SmallBodyDataset> dataset) {
    SmallBodyDisplayModel next(std::move(dataset));
    next.asteroid_ = asteroid_;
    next.trans_neptunian_ = trans_neptunian_;
    next.comet_ = comet_;
    // 多数の選択行ごとに出典全体を再比較しない。原バイト比較は出典ごとに一度にする。
    std::set<std::string> unchanged_sources;
    for (const auto& source : sources_) {
        const auto found = next.sources_.find(source.first);
        if (found != next.sources_.end()
            && dataset_->sources[source.second].bytes == next.dataset_->sources[found->second].bytes)
            unchanged_sources.insert(source.first);
    }
    SmallBodyDisplayRebind report;
    for (const auto& id : selected_) {
        const auto row = next.rows_.find(id);
        if (row != next.rows_.end() && unchanged_sources.find(id.source_key) != unchanged_sources.end()
            && dataset_->records[rows_.at(id)].kind == next.dataset_->records[row->second].kind) {
            next.selected_.insert(id);
            ++report.retained_count;
        } else report.removed_ids.push_back(id);
    }
    *this = std::move(next);
    return report;
}

} // namespace mitaka::gui
