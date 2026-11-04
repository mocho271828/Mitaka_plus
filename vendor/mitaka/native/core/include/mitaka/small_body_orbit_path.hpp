#pragma once

#include "mitaka/small_body_catalog.hpp"

#include <array>

namespace mitaka {

// 表示用の有限軌跡。精度保証期間や原版 Plus の標本化規則ではない。
struct SmallBodyOrbitSampling {
    double first_jd;
    double last_jd;
    std::size_t sample_count;
};

inline constexpr std::size_t maximum_small_body_orbit_samples = 4096;

struct SmallBodyOrbitSample {
    double julian_date;
    SmallBodyEvaluation evaluation;
};

struct SmallBodyOrbitPath {
    SmallBodyId id;
    // 全標本を順番どおり保持する。欠損の前後を直結せず、終始点も閉じない。
    // 成功位置の単位・参照面・時系は evaluate_small_body と同じ。
    std::vector<SmallBodyOrbitSample> samples;
};

// 有限で strictly increasing な TDB JD と、2..maximum の標本数を要求する。
// JD の丸めで隣接時刻を区別できない要求も invalid_argument で拒否する。
// 元行の未解明・評価失敗は各標本の診断として保持する。
void validate_small_body_orbit_sampling(SmallBodyOrbitSampling sampling);

SmallBodyOrbitPath sample_small_body_orbit_path(const SmallBodyRecord& record,
                                              SmallBodyOrbitSampling sampling);

// 隣接する成功標本の index 組だけを返す。閉曲線・欠損越しの線分は作らない。
std::vector<std::array<std::size_t, 2>> small_body_orbit_segments(const SmallBodyOrbitPath& path);

} // namespace mitaka
