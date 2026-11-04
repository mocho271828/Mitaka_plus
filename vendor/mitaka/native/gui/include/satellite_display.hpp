#pragma once

#include "mitaka/satellite_model.hpp"

#include <map>
#include <memory>
#include <set>

namespace mitaka::gui {

// 旧版の初期 Visible や言語選択から推測しない、native 固有の初期値。
struct SatelliteDisplayOptions {
    bool visible = true;
    bool labels = false;
    bool orbits = false;
    bool selected_only = false;
};

struct SatelliteLayerVisibility { bool body, label, orbit; };

struct SatelliteIdLess {
    bool operator()(const SatelliteRecordId& lhs, const SatelliteRecordId& rhs) const noexcept;
};

struct SatelliteDisplayRebind {
    std::size_t retained_count = 0;
    std::vector<SatelliteRecordId> removed_ids;
};

// 全 Satellite 行を保持する表示集合。クリック選択・追尾・位置評価は所有しない。
// 描画と pick は同じ visibility に、呼出側の scene / 位置の有効性を重ねる。
class SatelliteDisplayModel {
public:
    explicit SatelliteDisplayModel(std::shared_ptr<const SatelliteModel> model);

    const std::shared_ptr<const SatelliteModel>& model() const noexcept { return model_; }
    SatelliteDisplayOptions options() const noexcept { return options_; }
    void set_options(SatelliteDisplayOptions options) noexcept { options_ = options; }

    // 名前や配列順では解決しない。ID は定義出典とその出典内の block ordinal。
    const SatelliteRecordId& id_at(std::size_t row) const;
    std::optional<std::size_t> row_for_id(const SatelliteRecordId& id) const;
    void set_selected_ids(const std::vector<SatelliteRecordId>& ids);
    std::vector<SatelliteRecordId> selected_ids() const;
    bool contains(const SatelliteRecordId& id) const;
    SatelliteLayerVisibility visibility(std::size_t row) const;

    // 定義 source bytes と ID が一致する行だけ集合を保持し、解除 ID を報告する。
    // 軌道 source の変更は天体 ID を変えない。位置と軌道線は呼出側で再評価する。
    // 新 model が不正なら全体を拒否し、元の model / 設定 / 集合を維持する。
    SatelliteDisplayRebind rebind(std::shared_ptr<const SatelliteModel> model);

private:
    std::shared_ptr<const SatelliteModel> model_;
    std::map<std::string, std::size_t> sources_;
    std::map<SatelliteRecordId, std::size_t, SatelliteIdLess> rows_;
    std::set<SatelliteRecordId, SatelliteIdLess> selected_;
    SatelliteDisplayOptions options_;
};

} // namespace mitaka::gui
