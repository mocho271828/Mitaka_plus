#pragma once

#include "small_body_display.hpp"
#include "small_body_model.hpp"
#include "spacecraft_browser_model.hpp"
#include "mitaka/observation.hpp"

namespace mitaka::gui {

struct HorizonObject {
    std::size_t index;
    EquatorialCoordinates coordinates;
    double distance_au;
    bool body;
    bool label;
};

// 球面地球上の地点から、地心基準の J2000 赤道 AU ベクトルを求める。
Vec3 horizon_observer_position(const ObservationFrame& frame);
std::optional<EquatorialCoordinates> horizon_heliocentric_coordinates(
    Vec3 ecliptic_au, Vec3 earth_equatorial_au, Vec3 observer_equatorial_au);

// Earth は julian_date と同時刻の日心 J2000 赤道座標 AU。
// 観測者ベクトルは同一 JD・地点の地心 J2000 赤道 AU。結果は測心幾何方向。
// 球面地球・標高 0 の日周視差のみを含み、光行時間などは含まない。
// モデル・日時・行数が一致しない snapshot は全体を表示しない。
std::vector<HorizonObject> horizon_small_body_objects(
    const SmallBodySnapshot& snapshot, const SmallBodyDisplayModel& display,
    double julian_date, Vec3 earth_equatorial_au, Vec3 observer_equatorial_au);

// position は 3D 描画と同じ検証済み PTH 位置を返す関数。
// 探査機の端点固定・無効値の扱いはその関数に従う。
std::vector<HorizonObject> horizon_spacecraft_objects(
    const SpacecraftSnapshot& snapshot, bool points, bool labels,
    double julian_date, Vec3 earth_equatorial_au, Vec3 observer_equatorial_au,
    const std::function<std::optional<Vec3>(const SpacecraftSnapshot&, std::size_t)>& position);

} // namespace mitaka::gui
