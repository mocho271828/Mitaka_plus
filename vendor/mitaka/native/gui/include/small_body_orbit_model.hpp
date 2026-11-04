#pragma once

#include "small_body_display.hpp"
#include "small_body_model.hpp"
#include "mitaka/small_body_orbit_path.hpp"

namespace mitaka::gui {

// 原本の件数制限ではなく、一度の軌跡計算に対する作業量の上限。
inline constexpr std::size_t maximum_small_body_orbit_total_samples = 524288;

struct SmallBodyOrbitSnapshot {
    std::shared_ptr<const SmallBodyModel> model;
    std::shared_ptr<const SmallBodyDisplayModel> display;
    SmallBodyOrbitSampling sampling{};
    // 原行と同じ長さ。非要求・取消による未処理行は nullopt のまま保持する。
    std::vector<std::optional<SmallBodyOrbitPath>> paths;
    std::size_t requested_count = 0;
    std::size_t completed_count = 0;
    // 処理済み要求行のうち、一つ以上の標本で位置を得られなかった行数。
    std::size_t unresolved_count = 0;
    bool cancelled = false;
};

// dataset 同一性、日時の丸め、総標本上限を先に検証し、原行順の要求を返す。
// invalid_argument / length_error では既存の表示状態を変更しない。
std::vector<std::size_t> small_body_orbit_requested_rows(
    const SmallBodyModel& model, const SmallBodyDisplayModel& display,
    SmallBodyOrbitSampling sampling);

// TDB evaluator のみを用いる。legacy numeric JD の位置評価とは混用しない。
// 取消は行間で確認し、部分結果には必ず cancelled を付ける。
std::shared_ptr<const SmallBodyOrbitSnapshot> evaluate_small_body_orbit_snapshot(
    std::shared_ptr<const SmallBodyModel> model,
    std::shared_ptr<const SmallBodyDisplayModel> display,
    SmallBodyOrbitSampling sampling, std::function<bool()> cancelled = {});

} // namespace mitaka::gui
