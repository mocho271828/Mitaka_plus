#pragma once
#include "mitaka/small_body_catalog.hpp"
#include <functional>
#include <memory>

namespace mitaka::gui {

struct SmallBodySearchPage {
    std::vector<std::size_t> rows;
    std::size_t total_matches = 0;
    std::size_t offset = 0;
    bool cancelled = false;
};

enum class SmallBodyEvaluationMode { unresolved, comet_tdb, packed36_legacy_jd, element_text_legacy_jd };

class SmallBodyModel {
public:
    explicit SmallBodyModel(std::shared_ptr<const SmallBodyDataset> dataset);
    const SmallBodyDataset& dataset() const { return *dataset_; }
    // 評価器を選ぶ分類。要素の妥当性・指定時刻の評価成功は保証しない。
    SmallBodyEvaluationMode evaluation_mode(std::size_t index) const;
    const std::vector<std::size_t>& evaluable_indices() const { return evaluable_; }
    const std::string& title(std::size_t index) const;
    std::string provenance(std::size_t index) const;
    SmallBodySearchPage search(const std::string& query, std::optional<SmallBodyKind> kind,
        std::size_t offset, std::size_t page_size,
        const std::function<bool()>& cancelled = {}) const;
private:
    std::shared_ptr<const SmallBodyDataset> dataset_;
    std::vector<std::string> titles_, search_text_;
    std::vector<std::size_t> evaluable_;
};

struct SmallBodySnapshot {
    std::shared_ptr<const SmallBodyModel> model;
    double julian_date = 0;
    bool evaluated_all = false;
    std::optional<std::size_t> evaluated_selection;
    // 原本の index と同じ長さ。表示不能・非表示時に省略した行も削除しない。
    std::vector<std::optional<Vec3>> positions;
    std::vector<SmallBodyDiagnostic> diagnostics;
    std::size_t positioned_count = 0;
};

// 同じ数値 JD を各契約へ渡す。彗星は TDB、packed36・個別小天体は物理時系未確定。
// 出力は日心 J2000 黄道 AU。非表示中は選択行のみ評価できる。
std::shared_ptr<const SmallBodySnapshot> evaluate_small_body_snapshot(
    std::shared_ptr<const SmallBodyModel> model, double julian_date,
    bool evaluate_all = true, std::optional<std::size_t> selection = {});
std::string small_body_summary(const SmallBodyModel& model);
std::string small_body_description(const SmallBodyModel& model, std::size_t index,
                                  const SmallBodySnapshot* snapshot = nullptr);

} // namespace mitaka::gui
