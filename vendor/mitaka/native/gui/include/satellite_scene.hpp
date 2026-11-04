#pragma once

#include "satellite_browser_model.hpp"
#include "sky_model.hpp"

namespace mitaka::gui {

// native 内部の検証境界。戻り値は snapshot.model 所有で、その寿命内だけ借用できる。
// snapshot と evaluation の JD、登録根拠、9惑星の対応と配列形状を検証する。
// 個々の位置は検証しない。描画へ利用する側は位置の有限性・同一行・
// 表示中の親位置との一致も確認する。入力 bodies の JD は呼出側で揃える。
const SatelliteRegistrationContext* verified_satellite_scene_context(
    const SatelliteSnapshot& snapshot, const SatelliteAbsoluteEvaluation& evaluation);

// 同じ出典の補正後位置を既存の赤道 AU 表示へ一度だけ変換して置換する。
// 出典未指定時は最初の検証済み evaluation。未解決位置は入力を維持する。
// 入力 bodies と snapshot は呼出側で同一 JD に揃える。姿勢は変更しない。
SolarBodies apply_satellite_parent_positions(SolarBodies bodies,
    const SatelliteSnapshot& snapshot, const std::optional<std::string>& source = {});

} // namespace mitaka::gui
