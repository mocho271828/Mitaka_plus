#pragma once

#include "small_body_display.hpp"
#include "small_body_model.hpp"
#include "spacecraft_browser_model.hpp"

namespace mitaka::gui {

struct HorizonObject {
    std::size_t index;
    EquatorialCoordinates coordinates;
    double distance_au;
    bool body;
    bool label;
};

// Earth は julian_date と同時刻の日心 J2000 赤道座標 AU。
// 結果は地心幾何方向であり、視差・光行時間を含まない。
// モデル・日時・行数が一致しない snapshot は全体を表示しない。
std::vector<HorizonObject> horizon_small_body_objects(
    const SmallBodySnapshot& snapshot, const SmallBodyDisplayModel& display,
    double julian_date, Vec3 earth_equatorial_au);

// position は 3D 描画と同じ検証済み PTH 位置を返す関数。
// 探査機の端点固定・無効値の扱いはその関数に従う。
std::vector<HorizonObject> horizon_spacecraft_objects(
    const SpacecraftSnapshot& snapshot, bool points, bool labels,
    double julian_date, Vec3 earth_equatorial_au,
    const std::function<std::optional<Vec3>(const SpacecraftSnapshot&, std::size_t)>& position);

} // namespace mitaka::gui
