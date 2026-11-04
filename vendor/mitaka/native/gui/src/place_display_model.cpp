#include "place_display_model.hpp"

#include <map>
#include <stdexcept>
#include <utility>

namespace mitaka::gui {

PlaceDisplayModel::PlaceDisplayModel(ObserverPlaces places) : places_(std::move(places)) {
    if (!places_.selected_source) return;
    const auto source_index = *places_.selected_source;
    if (source_index >= places_.sources.size()) {
        throw std::invalid_argument("place display source index is out of range");
    }
    const auto& source = places_.sources[source_index];
    if (!source.catalog) return;

    std::map<std::string, std::size_t> group_indices;
    for (std::size_t row = 0; row < source.catalog->label_groups.size(); ++row) {
        const auto& definition = source.catalog->label_groups[row];
        const auto inserted = group_indices.emplace(definition.name, label_groups_.size());
        EffectivePlaceLabelGroup effective{definition, {source_index, row}};
        if (inserted.second) label_groups_.push_back(std::move(effective));
        else label_groups_[inserted.first->second] = std::move(effective);
    }

    std::map<std::string, std::size_t> landscape_indices;
    for (std::size_t row = 0; row < source.catalog->landscapes.size(); ++row) {
        const auto& definition = source.catalog->landscapes[row];
        const auto key = definition.target_name + "." + definition.name;
        const auto inserted = landscape_indices.emplace(key, landscapes_.size());
        EffectivePlaceLandscape effective{key, definition, {source_index, row}};
        if (inserted.second) landscapes_.push_back(std::move(effective));
        else landscapes_[inserted.first->second] = std::move(effective);
    }
}

std::optional<std::size_t> PlaceDisplayModel::find_label_group(std::string_view name) const noexcept {
    for (std::size_t index = 0; index < label_groups_.size(); ++index) {
        if (label_groups_[index].definition.name == name) return index;
    }
    return std::nullopt;
}

std::optional<std::size_t> PlaceDisplayModel::find_landscape(std::string_view name) const noexcept {
    for (std::size_t index = 0; index < landscapes_.size(); ++index) {
        if (landscapes_[index].qualified_name == name) return index;
    }
    return std::nullopt;
}

} // namespace mitaka::gui
