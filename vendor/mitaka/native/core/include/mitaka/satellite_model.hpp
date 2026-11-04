#pragma once

#include "mitaka/satellite_catalog.hpp"
#include "mitaka/satellite_position.hpp"

namespace mitaka {

enum class SatelliteRegistrationOrigin { verified_legacy_container, isolated_native_source };

// 他の出典を含まない登録コンテナ全体の成功順を、確認できた場合だけ指定する。
// ordinal は同一 source 内の定義 ordinal。言語別出典を連結しない。
// 元アプリの初期 clear / 言語選択は未確定。native 独立コンテナとは origin で区別する。
struct VerifiedSatelliteRegistration {
    std::string source_key;
    std::vector<std::size_t> planet_definition_ordinals;
    std::vector<std::size_t> satellite_definition_ordinals;
    std::string evidence;
    SatelliteRegistrationOrigin origin = SatelliteRegistrationOrigin::verified_legacy_container;
};

enum class SatelliteModelDiagnosticCode {
    missing_field, invalid_field, unresolved_parent, conflicting_parent,
    unresolved_charon, invalid_registration, unresolved_registration,
    unregistered_parent, unregistered_satellite, shadowed_identifier,
    unsupported_moon, invalid_context
};

struct SatelliteModelDiagnostic {
    SatelliteModelDiagnosticCode code;
    std::optional<std::size_t> definition_index;
    std::string field;
    std::string message;
};

struct SatelliteRegistrationEvaluation {
    std::optional<VerifiedSatelliteRegistration> registration;
    std::vector<SatelliteModelDiagnostic> diagnostics;
};

// 読取済み snapshot だけから、出典ごとに空の native 登録コンテナを作る。
// 全 Planet / Satellite の Orbit を EOF まで読めた場合に限る。未読を失敗扱いしない。
// 原版の起動順・言語選択・初期 clear が同じだったという証拠にはしない。
SatelliteRegistrationEvaluation make_isolated_satellite_registration(
    const SatelliteDataset& dataset, const std::string& source_key);

struct SatelliteRegisteredPlanet {
    std::size_t definition_index;
    std::string identifier_bytes;
    LegacyPlanetRegistrationIndex registration_index;
};

struct SatelliteRegistrationContext {
    std::string source_key;
    SatelliteRegistrationOrigin origin;
    std::string evidence;
    // 成功登録順。同名も残す。名前参照は完全な場合だけ先頭の一致を使う。
    std::vector<SatelliteRegisteredPlanet> planets;
    std::vector<std::size_t> satellite_record_indices;
    bool planet_identifiers_complete = true;
    bool satellite_identifiers_complete = true;
};

struct SatelliteModelRecord {
    std::size_t definition_index;
    std::string identifier_bytes;
    std::optional<std::size_t> parent_definition_index;
    std::optional<LegacyPlanetRegistrationIndex> parent_registration_index;
    std::optional<std::size_t> registration_index;
    // false は明示した登録証拠がその定義を除外した場合。nullopt は未確定。
    std::optional<bool> parent_registered;
    std::optional<bool> registered;
    std::optional<SatellitePositionElements> position_elements;
    SatelliteRotationInput rotation_input;
    std::vector<SatelliteModelDiagnostic> diagnostics;
};

struct SatelliteModelParentPole {
    std::size_t parent_definition_index;
    SatelliteParentPole pole;
};

struct SatelliteModelPosition {
    std::size_t definition_index;
    std::optional<Vec3> relative_position_km;
    std::vector<SatelliteModelDiagnostic> diagnostics;
    std::vector<SatelliteRotationDiagnostic> rotation_diagnostics;
    std::vector<SatellitePositionDiagnostic> position_diagnostics;
    std::vector<SatelliteParentPoleDiagnostic> parent_pole_diagnostics;
    // 同日時に成功した相対位置で使った基底。未評価行に恒等回転を補わない。
    std::optional<SatelliteRotation> rotation;
};

struct SatelliteModelEvaluation {
    double legacy_julian_date;
    // records() と同数・同順。失敗した行も消さない。
    std::vector<SatelliteModelPosition> positions;
    std::vector<SatelliteModelDiagnostic> diagnostics;
};

class SatelliteModel {
public:
    // dataset を所有し、全 source bytes・全定義・重複を保持する。
    // records() は Satellite ブロックを原順で全件保持する。Name の ID は先頭 token。
    // 未確定の登録順を Planet enum や構文 ordinal から補完しない。
    explicit SatelliteModel(SatelliteDataset dataset,
        std::vector<VerifiedSatelliteRegistration> registrations = {});

    const SatelliteDataset& dataset() const noexcept { return dataset_; }
    const std::vector<SatelliteModelRecord>& records() const noexcept { return records_; }
    const std::vector<SatelliteModelDiagnostic>& diagnostics() const noexcept { return diagnostics_; }
    const std::vector<VerifiedSatelliteRegistration>& registrations() const noexcept { return registrations_; }
    // 検証に成功したコンテキストだけ。registrations() の未検証入力と区別する。
    const std::vector<SatelliteRegistrationContext>& registration_contexts() const noexcept { return registration_contexts_; }

    // 通常衛星の補正前親に対する相対 km のみ。Moon は専用解析未接続として位置なし。
    // Q は明示した同日親極を優先し、なければ検証済み登録 index の式を使用する。
    // C は検証済み登録順の最初の Charon に接続する。失敗行・後続の同名行も残る。
    // 絶対位置、Earth/Moon・Pluto/Charon 後処理、J2000/時系変換は実行しない。
    SatelliteModelEvaluation evaluate(double legacy_julian_date,
        const std::vector<SatelliteModelParentPole>& parent_poles = {}) const;

private:
    SatelliteDataset dataset_;
    std::vector<VerifiedSatelliteRegistration> registrations_;
    std::vector<SatelliteRegistrationContext> registration_contexts_;
    std::vector<SatelliteModelRecord> records_;
    std::vector<SatelliteModelDiagnostic> diagnostics_;
};

} // namespace mitaka
