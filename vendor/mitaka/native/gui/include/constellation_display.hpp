#pragma once

#include "mitaka/catalog.hpp"

#include <set>
#include <string>
#include <vector>

namespace mitaka::gui {

// native の設定。略号はカタログの原バイト列であり、大小文字変換しない。
// exceptions にある略号だけ default_visible の反対になる。
struct ConstellationDisplayOptions {
    bool lines = true;
    bool boundaries = false;
    bool labels = true;
    bool default_visible = true;
    std::set<std::string> exceptions;
    bool illustrations = false;
};

struct ConstellationLayerVisibility { bool lines, boundaries, labels, illustrations; };
struct ConstellationDisplayRebind {
    std::vector<std::string> removed_exceptions;
};

// カタログの全行と略号の対応だけを保持する。原レコードを統合・変更しない。
// Ser のような同じ略号の複数図形には同じ設定が作用する。
class ConstellationDisplayModel {
public:
    explicit ConstellationDisplayModel(const std::vector<ConstellationRecord>& records);
    const ConstellationDisplayOptions& options() const noexcept { return options_; }
    std::size_t row_count() const noexcept { return rows_.size(); }
    const std::set<std::string>& abbreviations() const noexcept { return abbreviations_; }

    // 未知の略号は全体を拒否する。空集合を含む完全な設定の原子的置換。
    void set_options(ConstellationDisplayOptions options);
    void set_all_visible(bool visible) noexcept;
    // 重複指定は冪等。All も通常の略号として扱い、特殊な文字列規則を設けない。
    void set_visible(const std::vector<std::string>& abbreviations, bool visible);
    // 未知の略号は invalid_argument。全体のレイヤー設定や画面内外とは独立。
    bool membership(const std::string& abbreviation) const;
    ConstellationLayerVisibility visibility(std::size_t original_row) const;

    // 同じ原バイト略号の例外を保持し、新規略号は default_visible を継承する。
    // 消えた例外は返値で通知する。レイヤー設定は維持する。
    ConstellationDisplayRebind rebind(const std::vector<ConstellationRecord>& records);

private:
    std::vector<std::string> rows_;
    std::set<std::string> abbreviations_;
    ConstellationDisplayOptions options_;
};

} // namespace mitaka::gui
