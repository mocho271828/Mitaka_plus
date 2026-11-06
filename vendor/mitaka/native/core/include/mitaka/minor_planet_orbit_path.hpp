#pragma once

#include "mitaka/minor_planet_position.hpp"
#include "mitaka/small_body_orbit_path.hpp"

#include <array>
#include <functional>

namespace mitaka {

struct MinorPlanetOrbitSample {
    // 要素の元期と同じ legacy numeric JD。物理時系は未確認。
    double julian_date;
    std::optional<Vec3> position; // 日心 J2000 黄道 AU
};

struct MinorPlanetOrbitFailure {
    std::size_t sample_index;
    // この点の評価診断を path.diagnostics の index で保持する。
    std::vector<std::size_t> diagnostic_indices;
};

struct MinorPlanetOrbitPath {
    SmallBodyId id;
    std::vector<MinorPlanetOrbitSample> samples;
    // 同じ診断の百万回の複製を避け、異なる診断はすべて保持する。
    std::vector<SmallBodyDiagnostic> diagnostics;
    std::vector<MinorPlanetOrbitFailure> failures;
    bool cancelled = false;
};

// packed_36 と a 指定の個別小惑星・TNO。元期から 360/n 日を離心近点角の等間隔で標本化する。
// 時刻を区別できない場合は等時間に戻す。
// この期間は native の表示方針であり、原版の標本則や科学的精度の保証ではない。
// 個々の位置は evaluate_minor_planet_position の検証と診断に従う。
// 標本数の不正は invalid_argument。行の不正や表現できない周期は診断を返す。
// 途中取消の部分結果は cancelled=true とし、完成結果として公開してはいけない。
MinorPlanetOrbitPath sample_minor_planet_orbit_path(
    const SmallBodyRecord& record, std::size_t sample_count,
    std::function<bool()> cancelled = {});

// 実際の隣接成功点のみを結ぶ。欠損越しの接続や追加の終始接続は行わない。
std::vector<std::array<std::size_t, 2>> minor_planet_orbit_segments(
    const MinorPlanetOrbitPath& path);

} // namespace mitaka
