#pragma once

#include "mitaka/catalog.hpp"
#include "mitaka/ephemeris.hpp"

#include <optional>
#include <string_view>

namespace mitaka {

enum class SpacecraftSourceKind { definition, registration_list, pth_samples, ppi_segments };
enum class SpacecraftDiagnosticCode {
    missing_source, invalid_source, limit_exceeded,
    unknown_field, duplicate_field, invalid_number, unresolved_orbit, unresolved_definition,
    case_insensitive_reference, duplicate_time, unresolved_pth_contract,
    unresolved_spatial_contract, unresolved_time_scale, invalid_record_index,
    invalid_time, outside_coverage, numerical_range
};

struct SpacecraftDiagnostic {
    SpacecraftDiagnosticCode code;
    std::string source_key;
    std::optional<std::size_t> record_ordinal;
    std::uint64_t source_offset = 0;
    std::string message;
};

struct SpacecraftSource {
    std::string key; // 選択された data の親ディレクトリからの相対パス。
    std::filesystem::path path;
    SpacecraftSourceKind kind;
    std::string bytes;
    bool parsed = false;
    bool valid = false; // 構文・数値・重複キーの検査。位置評価の可否を意味しない。
    std::size_t record_count = 0;
};

struct SpacecraftField {
    std::string key;
    std::string value_bytes; // CP932 を含む原バイト列。文字コードを変換しない。
    std::uint64_t source_offset = 0;
    std::uint64_t source_size = 0;
    std::size_t source_line = 0;
    std::string section_bytes; // 通常版の言語 section。Plus と通常版の共通項は空文字。
};

struct SpacecraftDefinition {
    std::size_t source_index = 0;
    std::vector<SpacecraftField> fields;
    std::optional<std::size_t> trajectory_index;
};

// 重複したキーを後勝ちにしない。欠損・重複はいずれも nullptr。
const SpacecraftField* unique_spacecraft_field(const SpacecraftDefinition& definition,
    std::string_view key, std::string_view section = {}) noexcept;

struct SpacecraftRegistrationEntry {
    std::string reference_bytes;
    std::uint64_t source_offset = 0;
    std::uint64_t source_size = 0;
    std::size_t source_line = 0;
    std::optional<std::size_t> definition_index;
};

struct SpacecraftRegistrationList {
    std::size_t source_index = 0;
    std::vector<SpacecraftRegistrationEntry> entries; // 原登録順。重複や未解決参照も残す。
};

struct SpacecraftPathSample {
    double time_value = 0; // 原単位・原時系の値。UTC/TDB や JD を自動付与しない。
    std::array<double, 3> coordinate_values{};
};

struct SpacecraftTrajectoryRecord {
    std::size_t source_index = 0;
    // 配列 index が原ファイルの record ordinal。等時刻・異なる座標も全件残す。
    std::vector<SpacecraftPathSample> path_samples;
    std::optional<Trajectory> ppi;
};

struct SpacecraftLoadLimits {
    CatalogLoadLimits catalog;
    std::uint64_t max_total_bytes = 512ULL * 1024 * 1024;
    std::size_t max_sources = 10'000;
    std::size_t max_fields = 1'000'000;
    std::size_t max_line_bytes = 65'536;
};

struct SpacecraftDataset {
    std::vector<SpacecraftSource> sources;
    std::vector<SpacecraftDefinition> definitions;
    std::vector<SpacecraftRegistrationList> registration_lists;
    std::vector<SpacecraftTrajectoryRecord> trajectories;
    std::vector<SpacecraftDiagnostic> diagnostics;
};

// data 直下の .ppi と隣接 spacecraft 直下の .dat/.pth/.ppi を名前順に読む。
// 原 bytes と行順を保持し、言語別定義・同名・同時刻を統合しない。
// symlink・下位ディレクトリ・外部 Orbit 参照を追跡しない。欠損や不正 source は隔離する。
// max_records は定義数＋登録行数＋PTH sample 数＋PPI segment 数の総数へ適用する。
SpacecraftDataset load_spacecraft_dataset(const std::filesystem::path& data_directory,
                                          SpacecraftLoadLimits limits = {});

struct SpacecraftTrajectoryEvaluation {
    // PPI 作成元の原点・面における km。太陽中心 J2000 黄道座標ではない。
    // 成功時にも未確定の原点・面・物理時系の診断を返し、そのまま GUI へ投影しない。
    std::optional<std::array<double, 3>> native_position_km;
    std::vector<SpacecraftDiagnostic> diagnostics;
};

// 数値 JD のみを既存 Trajectory へ渡す。PTH の補間・単位換算は仕様未確定で行わない。
// PPI の範囲外・空隙を端点固定せず、位置なしと診断を返す。
SpacecraftTrajectoryEvaluation evaluate_spacecraft_trajectory(
    const SpacecraftDataset& dataset, std::size_t trajectory_index, double legacy_julian_date);

} // namespace mitaka
