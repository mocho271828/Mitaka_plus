#include "star_name_selection.hpp"
#include <stdexcept>
#include <utility>

namespace mitaka::gui {
StarNameSelection::StarNameSelection(const std::vector<StarNameRecord>& records) {
    for (const auto& record : records) {
        if (record.hip <= 0 || !known_.insert(record.hip).second)
            throw std::invalid_argument("star name selection requires unique positive HIP IDs");
        if (record.is_featured) selected_.insert(record.hip);
    }
}
void StarNameSelection::set_selection(std::set<std::int32_t> hips) {
    for (const auto hip : hips)
        if (!known_.count(hip)) throw std::invalid_argument("unknown star name HIP");
    selected_ = std::move(hips);
}
void StarNameSelection::set_selected(const std::vector<std::int32_t>& hips, bool selected) {
    auto next = selected_;
    for (const auto hip : hips) {
        if (!known_.count(hip)) throw std::invalid_argument("unknown star name HIP");
        if (selected) next.insert(hip); else next.erase(hip);
    }
    selected_ = std::move(next);
}
void StarNameSelection::set_all(bool selected) { selected_ = selected ? known_ : std::set<std::int32_t>{}; }
bool StarNameSelection::membership(std::int32_t hip) const noexcept { return selected_.count(hip) != 0; }
StarNameSelectionRebind StarNameSelection::rebind(const std::vector<StarNameRecord>& records) {
    StarNameSelection next(records);
    StarNameSelectionRebind report;
    for (const auto hip : known_) {
        if (next.known_.count(hip)) {
            if (selected_.count(hip)) next.selected_.insert(hip); else next.selected_.erase(hip);
        } else if (selected_.count(hip)) report.removed_selected_hips.insert(hip);
    }
    *this = std::move(next);
    return report;
}
}
