#pragma once

#include "mitaka/ephemeris.hpp"
#include "mitaka/satellite_model.hpp"

namespace mitaka {

// native GUI と同じ AU。原版の中間 binary32 km/AU/pc 丸めは再現しない。
inline constexpr double satellite_km_per_au = 149597870.7;
inline constexpr double legacy_earth_moon_mass_fraction = 0.012150584133256915;
inline constexpr double legacy_pluto_charon_mass_fraction = 0.07407407407407407;
inline constexpr double legacy_satellite_cf96_minimum_jd = 2415020.5;
inline constexpr double legacy_satellite_cf96_maximum_jd = 2487980.5;

struct SatelliteAbsoluteMoonInput {
    double legacy_julian_date;
    Vec3 geocentric_j2000_ecliptic_km;
    // 旧解析/設定倍率か、明示した native 月モデルかを呼出側で記録する。
    std::string evidence;
};

struct SatelliteAbsoluteContext {
    std::string source_key;
    // 成功 Planet 登録 index と選択 CF96 の index が対応する確認根拠。
    // 名前→現代 Planet enum の暗黙対応づけは行わない。
    std::string cf96_binding_evidence;
    std::optional<SatelliteAbsoluteMoonInput> moon;
};

enum class SatelliteAbsoluteDiagnosticCode {
    invalid_context, unselected_source, unresolved_registration,
    unresolved_parent, unavailable_relative_position, outside_ephemeris, unverified_ephemeris_branch,
    unresolved_special_lookup, unavailable_moon, unavailable_pair_correction,
    invalid_moon, numerical_range, unresolved_time_scale, unknown_accuracy_range
};

struct SatelliteAbsoluteDiagnostic {
    SatelliteAbsoluteDiagnosticCode code;
    std::optional<std::size_t> definition_index;
    std::string message;
};

struct SatelliteAbsolutePlanet {
    std::size_t definition_index;
    LegacyPlanetRegistrationIndex registration_index;
    std::string identifier_bytes;
    std::optional<Vec3> uncorrected_position_au;
    std::optional<Vec3> position_au;
    bool pair_correction_applied = false;
    std::vector<SatelliteAbsoluteDiagnostic> diagnostics;
};

struct SatelliteAbsolutePosition {
    std::size_t definition_index;
    std::optional<Vec3> position_au;
    bool pair_correction_applied = false;
    std::vector<SatelliteAbsoluteDiagnostic> diagnostics;
};

struct SatelliteAbsoluteRegistrationEvidence {
    SatelliteRegistrationOrigin origin;
    std::string evidence;
};

struct SatelliteAbsoluteEvaluation {
    double legacy_julian_date;
    SatelliteAbsoluteContext context;
    std::optional<SatelliteAbsoluteRegistrationEvidence> registration;
    // 全 model 行の相対評価・診断をそのまま保持する。
    SatelliteModelEvaluation relative;
    std::vector<SatelliteAbsolutePlanet> planets;
    // model.records() と同数・同順。他 source・未解決行も削除しない。
    std::vector<SatelliteAbsolutePosition> positions;
    std::vector<SatelliteAbsoluteDiagnostic> diagnostics;
};

// 同日 raw CF96 赤道 AU → J2000 黄道 AU を補正前親に使い、相対 km を加える。
// 全衛星の加算後、登録順の最初の Earth/Moon と Pluto/Charon だけを対で補正する。
// Nix/Hydra や同名の後続衛星を補正後の親へ付け替えない。Moon は明示入力が必須。
// 旧 CF96 分岐と実暦表の共通期間だけを使い、範囲外は別暦表へ置換せず診断。
// 物理時系変換はしない。
// 引数は呼出中のみ借用し、結果は値を所有する。位置 index はこの model snapshot の
// records() index であり、別のデータ再読込へは source/record の同一性を確認して使う。
SatelliteAbsoluteEvaluation evaluate_satellite_absolute(const SatelliteModel& model,
    const Cf96Ephemeris& ephemeris, double legacy_julian_date,
    const SatelliteAbsoluteContext& context);

} // namespace mitaka
