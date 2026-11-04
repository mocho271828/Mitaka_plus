#pragma once

#include "mitaka/small_body_catalog.hpp"

#include <string_view>

namespace mitaka {

inline constexpr std::string_view minor_planet_packed_position_contract =
    "mitaka-plus-1.5.4-packed36-legacy-jd-native-au-v1";

struct MinorPlanetPositionEvaluation {
    SmallBodyId id;
    double legacy_julian_date = 0;
    std::optional<Vec3> heliocentric_j2000_ecliptic_au;
    // 位置成功時のみ設定。元 record の frame / time_scale は書き換えない。
    std::string_view contract;
    std::vector<SmallBodyDiagnostic> diagnostics;
};

// load_small_body_dataset が保持した packed_36 の小惑星・TNO を二体近似する。
// 数値 JD を元期と同じ尺度でそのまま使う。UTC / TT / TDB の変換・認定はしない。
// 日心 J2000 黄道 AU。原版の pc 換算や solver の丸めまで含む数値一致は主張しない。
// 有限な a>0, n>0, 0<=e<1 のみ。packed_37 / 個別 text / 彗星は位置を返さない。
// 宣言済み期間は両端を含む。期間未宣言は成功時にも精度保証不明の診断を残す。
// 原 bytes / 重複 / source / ordinal は呼出側 dataset が不変で保持する。
MinorPlanetPositionEvaluation evaluate_minor_planet_position(
    const SmallBodyRecord& record, double legacy_julian_date);

} // namespace mitaka
