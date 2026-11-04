#pragma once

#include "mitaka/satellite_rotation.hpp"

namespace mitaka {

struct SatellitePositionElements {
    double epoch_jd;
    double semi_major_axis_km;
    double eccentricity;
    double mean_anomaly_deg;
    double mean_motion_deg_per_day;
    double periapsis_period_years;
    double node_period_years;
};

struct SatelliteTimedRotation {
    double legacy_julian_date;
    SatelliteRotation rotation;
};

enum class SatellitePositionDiagnosticCode {
    invalid_time, mismatched_rotation_time, invalid_elements, unsupported_orbit,
    invalid_rotation, numerical_range, convergence_failure
};

struct SatellitePositionDiagnostic {
    SatellitePositionDiagnosticCode code;
    std::string message;
};

struct SatellitePositionEvaluation {
    std::optional<Vec3> relative_position_km;
    std::vector<SatellitePositionDiagnostic> diagnostics;
};

// 通常衛星の楕円軌道のみ。Moon の別解析経路を呼出側で除外する。
// 回転と同じ数値 JD を使い、M=M0+(n-dw-dn)*(t-epoch) を既存 Kepler で評価する。
// 方向は SatelliteRotation と同じ legacy 出力方向。原点は補正前の親位置に対する相対。
// km で直接返すため旧版の km→AU→pc 中間 float 丸めを再現しない。
// UTC/TT/TDB 変換、天体中心補正、精度保証期間、J2000 座標への対応は含まない。
SatellitePositionEvaluation evaluate_satellite_relative_position(
    const SatellitePositionElements& elements, const SatelliteTimedRotation& rotation,
    double legacy_julian_date);

} // namespace mitaka
