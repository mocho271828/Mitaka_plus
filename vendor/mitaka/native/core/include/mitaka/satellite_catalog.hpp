#pragma once

#include "mitaka/catalog.hpp"

#include <optional>
#include <string_view>

namespace mitaka {

enum class SatelliteSourceKind { system_definition, orbit };
enum class SatelliteDefinitionKind { system, sun, planet, satellite, unknown };
enum class SatelliteDiagnosticCode {
    missing_source, invalid_source, limit_exceeded, unknown_block, unknown_field,
    duplicate_field, invalid_number, unresolved_reference_plane, unresolved_orbit
};

struct SatelliteDiagnostic {
    SatelliteDiagnosticCode code;
    std::string source_key;
    std::optional<std::size_t> record_ordinal;
    std::uint64_t source_offset = 0;
    std::size_t source_line = 0; // ファイル全体の診断では 0。
    std::string field;
    std::string message;
};

struct SatelliteRecordId {
    std::string source_key;
    // 再読込後の永続参照には source.bytes も照合し、変更された行へ誤接続しない。
    std::size_t record_ordinal = 0;
};

struct SatelliteField {
    std::string key;
    std::string value_bytes;
    std::uint64_t source_offset = 0;
    std::uint64_t source_size = 0;
    std::size_t source_line = 0;
    // 既知の数値キーのみ検査する。nullopt は文字列・未解釈・不正値のいずれか。
    // 原単位を変換せず、既知でない時系・参照面・位置の原点を付与しない。
    std::optional<std::vector<double>> numbers;
};

// 重複キーは後勝ちにせず曖昧として nullptr を返す。原フィールドは全件残る。
const SatelliteField* unique_satellite_field(const std::vector<SatelliteField>& fields,
                                             std::string_view key) noexcept;
std::optional<double> satellite_scalar(const std::vector<SatelliteField>& fields,
                                       std::string_view key) noexcept;

struct SatelliteDefinition {
    SatelliteRecordId id;
    SatelliteDefinitionKind kind = SatelliteDefinitionKind::unknown;
    std::string block_name_bytes;
    // 同一 source 内の block ordinal。定義配列全体の index ではない。
    std::optional<std::size_t> parent_ordinal;
    std::uint64_t source_offset = 0;
    std::uint64_t source_size = 0;
    std::size_t source_line = 0;
    std::vector<SatelliteField> fields;
    // 唯一の Orbit フィールドを、選択された data の出典に解決できた場合のみ設定。
    // 原参照は fields に残り、失敗時に別 bundle や似た名前へ置換しない。
    std::optional<std::size_t> orbit_index;
    // 空・構文不正のファイルも、全 bytes を読めた出典には接続する。
    // 旧版の登録可否と native の数値計算可否を混同しないための別リンク。
    std::optional<std::size_t> orbit_source_index;
};

struct SatelliteOrbitRecord {
    SatelliteRecordId id;
    std::vector<SatelliteField> fields;
};

struct SatelliteSource {
    std::string key; // data_directory からの相対パス。
    std::filesystem::path path;
    SatelliteSourceKind kind;
    std::string bytes;
    // 上限内で EOF まで読み取れたか。空ファイルでも true。
    bool read_complete = false;
    // parsed は構文読取、valid は数値等の検査結果。計算可能という意味ではない。
    bool parsed = false;
    bool valid = false;
    std::size_t record_count = 0;
};

struct SatelliteLoadLimits {
    CatalogLoadLimits catalog;
    std::uint64_t max_total_bytes = 512ULL * 1024 * 1024;
    std::size_t max_sources = 10'000;
    std::size_t max_fields = 1'000'000;
    std::size_t max_line_bytes = 65'536;
    std::size_t max_block_depth = 64;
};

struct SatelliteDataset {
    std::vector<SatelliteSource> sources;
    std::vector<SatelliteDefinition> definitions;
    std::vector<SatelliteOrbitRecord> orbits;
    std::vector<SatelliteDiagnostic> diagnostics;
};

// ssystem*.dat と orbits 直下の regular file を、各ディレクトリ内で名前順に読む。
// 小天体用の下位ディレクトリ、symlink、Orbit に書かれた外部ファイルは追跡しない。
// 全原 bytes・行順・重複・未知フィールドを保持。構文失敗はその source だけ隔離する。
// max_records は全 block と orbit record、max_fields は全 field の合計に適用する。
// 計算・時系変換・名前の文字コード変換・言語別定義の統合は行わない。
SatelliteDataset load_satellite_dataset(const std::filesystem::path& data_directory,
                                        SatelliteLoadLimits limits = {});

} // namespace mitaka
