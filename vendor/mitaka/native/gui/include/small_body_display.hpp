#pragma once

#include "mitaka/small_body_catalog.hpp"

#include <map>
#include <memory>
#include <set>

namespace mitaka::gui {

// 旧 Plus の初期値とは区別する native の静的設定。
struct SmallBodyKindDisplayOptions {
    bool visible = true;
    bool labels = false;
    bool orbits = false;
    bool selected_only = false;
};

struct SmallBodyLayerVisibility { bool body, label, orbit; };

struct SmallBodyIdLess {
    bool operator()(const SmallBodyId& lhs, const SmallBodyId& rhs) const noexcept;
};

struct SmallBodyDisplayRebind {
    std::size_t retained_count = 0;
    std::vector<SmallBodyId> removed_ids;
};

// 描画設定と複数行の表示集合。クリック選択・検索・位置評価は所有しない。
// 呼出側は別途 scene/位置の有効性を判定し、描画と pick へ同じ結果を使う。
class SmallBodyDisplayModel {
public:
    explicit SmallBodyDisplayModel(std::shared_ptr<const SmallBodyDataset> dataset);

    const std::shared_ptr<const SmallBodyDataset>& dataset() const noexcept { return dataset_; }
    SmallBodyKindDisplayOptions kind_options(SmallBodyKind kind) const;
    void set_kind_options(SmallBodyKind kind, SmallBodyKindDisplayOptions options);

    // 未登録 ID・重複 ID は全体を拒否し、既存集合を変更しない。
    void set_selected_ids(const std::vector<SmallBodyId>& ids);
    std::vector<SmallBodyId> selected_ids() const;
    bool contains(const SmallBodyId& id) const;
    SmallBodyLayerVisibility visibility(std::size_t row) const;

    // source bytes と元 ID/kind が一致する行だけ保持する。変更・欠損は明示して返す。
    // new dataset 自体が不正なら例外とし、元状態を維持する。
    SmallBodyDisplayRebind rebind(std::shared_ptr<const SmallBodyDataset> dataset);

private:
    SmallBodyKindDisplayOptions& options(SmallBodyKind kind);
    const SmallBodyKindDisplayOptions& options(SmallBodyKind kind) const;

    std::shared_ptr<const SmallBodyDataset> dataset_;
    std::map<SmallBodyId, std::size_t, SmallBodyIdLess> rows_;
    std::map<std::string, std::size_t> sources_;
    std::set<SmallBodyId, SmallBodyIdLess> selected_;
    SmallBodyKindDisplayOptions asteroid_, trans_neptunian_, comet_;
};

} // namespace mitaka::gui
