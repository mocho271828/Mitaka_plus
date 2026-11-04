#include "constellation_display.hpp"

#include <stdexcept>
#include <utility>

namespace mitaka::gui {

ConstellationDisplayModel::ConstellationDisplayModel(const std::vector<ConstellationRecord>& records) {
    rows_.reserve(records.size());
    for (const auto& record : records) {
        rows_.push_back(record.abbreviation);
        abbreviations_.insert(record.abbreviation);
    }
}

void ConstellationDisplayModel::set_options(ConstellationDisplayOptions options) {
    for (const auto& abbreviation : options.exceptions)
        if (abbreviations_.find(abbreviation) == abbreviations_.end())
            throw std::invalid_argument("constellation display contains unknown abbreviation");
    options_ = std::move(options);
}

void ConstellationDisplayModel::set_all_visible(bool visible) noexcept {
    options_.default_visible = visible;
    options_.exceptions.clear();
}

void ConstellationDisplayModel::set_visible(const std::vector<std::string>& abbreviations, bool visible) {
    // 途中の未知 ID やメモリ確保失敗でも、呼出前の表示設定を残す。
    auto next = options_;
    for (const auto& abbreviation : abbreviations) {
        if (abbreviations_.find(abbreviation) == abbreviations_.end())
            throw std::invalid_argument("constellation display contains unknown abbreviation");
        if (visible == next.default_visible) next.exceptions.erase(abbreviation);
        else next.exceptions.insert(abbreviation);
    }
    options_ = std::move(next);
}

bool ConstellationDisplayModel::membership(const std::string& abbreviation) const {
    if (abbreviations_.find(abbreviation) == abbreviations_.end())
        throw std::invalid_argument("constellation display contains unknown abbreviation");
    return options_.default_visible != (options_.exceptions.find(abbreviation) != options_.exceptions.end());
}

ConstellationLayerVisibility ConstellationDisplayModel::visibility(std::size_t original_row) const {
    if (original_row >= rows_.size()) throw std::out_of_range("constellation display row is out of range");
    const bool visible = membership(rows_[original_row]);
    return {visible && options_.lines, visible && options_.boundaries, visible && options_.labels, visible && options_.illustrations};
}

ConstellationDisplayRebind ConstellationDisplayModel::rebind(const std::vector<ConstellationRecord>& records) {
    ConstellationDisplayModel next(records);
    next.options_ = options_;
    ConstellationDisplayRebind report;
    for (const auto& abbreviation : options_.exceptions) {
        if (next.abbreviations_.find(abbreviation) == next.abbreviations_.end()) {
            next.options_.exceptions.erase(abbreviation);
            report.removed_exceptions.push_back(abbreviation);
        }
    }
    *this = std::move(next);
    return report;
}

} // namespace mitaka::gui
