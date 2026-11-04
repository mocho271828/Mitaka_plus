#pragma once
#include "mitaka/extended_catalog.hpp"
#include <set>

namespace mitaka::gui {
struct StarNameSelectionRebind { std::set<std::int32_t> removed_selected_hips; };

// 星名表の HIP だけを対象とする集合。恒星の可視性や主選択とは独立。
class StarNameSelection {
public:
    explicit StarNameSelection(const std::vector<StarNameRecord>& records);
    const std::set<std::int32_t>& known_hips() const noexcept { return known_; }
    const std::set<std::int32_t>& selected_hips() const noexcept { return selected_; }
    // 未知 HIP は invalid_argument。途中まで更新せず、空集合も受理する。
    void set_selection(std::set<std::int32_t> hips);
    void set_selected(const std::vector<std::int32_t>& hips, bool selected);
    void set_all(bool selected);
    // 未知 HIP は false。元 Lua の問い合わせと同じく描画条件には依存しない。
    bool membership(std::int32_t hip) const noexcept;
    // 同じ HIP の状態を保持し、新規 HIP だけ原表の is_featured で初期化する。
    StarNameSelectionRebind rebind(const std::vector<StarNameRecord>& records);
private:
    std::set<std::int32_t> known_, selected_;
};
}
