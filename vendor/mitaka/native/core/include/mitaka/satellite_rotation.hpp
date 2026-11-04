#pragma once

#include "mitaka/astronomy.hpp"

#include <cstddef>
#include <optional>
#include <string>
#include <vector>

namespace mitaka {

// 軌道平面の右手正規直交基底を、対象 Plus の出力方向で表す。
// 位置・単位・原点・物理時系の確定を意味せず、BodyOrientation とは区別する。
struct SatelliteRotation {
    Vec3 x_axis{1, 0, 0};
    Vec3 y_axis{0, 1, 0};
    Vec3 z_axis{0, 0, 1};
};

struct SatelliteRotationElements {
    double epoch_jd;
    double argument_of_periapsis_deg;
    double inclination_deg;
    double raw_ascending_node_deg;
    double periapsis_period_years;
    double node_period_years;
    // L 以外の分岐では使わない。欠損値を 0 で補完しない。
    std::optional<double> pole_right_ascension_deg;
    std::optional<double> pole_declination_deg;
};

// 原版 Q の自転を含まない親極。呼出側が根拠のある親対応を解決する。
// 現在の planet_orientation の自転込み基底を代入する API にはしない。
// 原版の歳差式は極を越え得るため、declination は有限の生角度を保持する。
struct SatelliteParentPole {
    double legacy_julian_date;
    double right_ascension_deg;
    double declination_deg;
};

// 対象 Plus で Planet の構築成功時に割り当てる登録順。Planet enum ではない。
// 呼出側が対象出典の登録順を確定できた場合のみ渡す。
struct LegacyPlanetRegistrationIndex { std::size_t value; };

enum class SatelliteParentPoleDiagnosticCode { invalid_registration_index, invalid_time };

struct SatelliteParentPoleDiagnostic {
    SatelliteParentPoleDiagnosticCode code;
    std::string message;
};

struct SatelliteParentPoleEvaluation {
    std::optional<SatelliteParentPole> pole;
    std::vector<SatelliteParentPoleDiagnostic> diagnostics;
};

// 原版内部 index 0..8 の極係数のみを評価する。名前への対応・自転・時系変換を含めない。
// 未知 index に原版のゼロ角 fallback を使わず診断を返す。
SatelliteParentPoleEvaluation evaluate_legacy_satellite_parent_pole(
    LegacyPlanetRegistrationIndex index, double legacy_julian_date);

struct SatelliteRotationInput {
    std::string name_bytes;
    char reference_plane = '\0';
    std::optional<SatelliteRotationElements> elements;
    // 原版 node 読込時の補正適用条件を確認した場合だけ true。親名だけで推定しない。
    bool apply_mars_node_correction = false;
    // C の Charon 依存。言語別名やファイル名から推測せず、呼出側が解決する。
    // 同じ vector 内の index。未解決・範囲外・循環は診断として返す。
    std::optional<std::size_t> charon_rotation_index;
    std::optional<SatelliteParentPole> parent_pole;
};

enum class SatelliteRotationDiagnosticCode {
    invalid_record_index, invalid_time, missing_elements, invalid_elements,
    numerical_range, unknown_reference_plane, unresolved_charon,
    invalid_charon_index, cyclic_dependency, unresolved_parent_pole,
    invalid_parent_pole, mismatched_parent_time
};

struct SatelliteRotationDiagnostic {
    SatelliteRotationDiagnosticCode code;
    std::size_t record_index;
    std::string field;
    std::string message;
};

struct SatelliteRotationEvaluation {
    std::optional<SatelliteRotation> rotation;
    std::vector<SatelliteRotationDiagnostic> diagnostics;
};

// Plus 1.5.4 build101013 の静的解析で確定した L/I/E/C/Q 回転を評価する。
// legacy_julian_date は原版と同じ数値日付引数。UTC/UT1/TT/TDB 変換はしない。
// Q は同時刻の明示 parent_pole がある場合のみ評価。C は各元期を使って依存先を評価。
// 原名 "Moon" は原版どおり identity。これは月の位置計算方法を決めるものではない。
// 未知 RefPlane は E に置換しない。位置や精度保証期間はこの API の対象外。
SatelliteRotationEvaluation evaluate_satellite_rotation(
    const std::vector<SatelliteRotationInput>& records, std::size_t record_index,
    double legacy_julian_date);

} // namespace mitaka
