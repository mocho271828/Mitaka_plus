#pragma once

#include "mitaka/catalog.hpp"
#include "mitaka/small_body_orbit.hpp"

#include <optional>
#include <variant>

namespace mitaka {

enum class SmallBodyKind { asteroid, trans_neptunian, comet };
enum class SmallBodyEncoding { packed_36, packed_37, element_text, comet_fixed_width };
enum class SmallBodyFrame { unresolved, heliocentric_j2000_ecliptic };
enum class SmallBodyTimeScale { unresolved, tdb };
enum class SmallBodyDiagnosticCode {
    missing_source, invalid_source, unknown_field, unresolved_frame, unresolved_time_scale,
    unresolved_perihelion_time, unresolved_historical_calendar, unknown_accuracy_range,
    outside_time_range, invalid_time, calculation_failed
};

struct SmallBodyDiagnostic {
    SmallBodyDiagnosticCode code;
    std::string source_key;
    std::optional<std::size_t> record_ordinal;
    std::string field;
    std::string message;
};

// 番号や元期は一意とは限らない。出典内の順番を失わない識別子を使う。
// 再読込をまたぐ永続化では source.bytes と比較し、変更済み出典の別行へ誤接続しない。
struct SmallBodyId {
    std::string source_key;
    std::size_t record_ordinal = 0;
};

struct SmallBodyTimeRange { double first_jd, last_jd; };
struct SmallBodyTextField { std::string key; std::string value_bytes; };

struct SmallBodyRecord {
    SmallBodyId id;
    SmallBodyKind kind = SmallBodyKind::asteroid;
    SmallBodyEncoding encoding = SmallBodyEncoding::packed_36;
    std::uint64_t source_offset = 0;
    std::string raw_record_bytes;
    // -1 もそのまま保存する。番号のない彗星は nullopt。
    std::optional<std::int32_t> number;
    std::optional<std::uint8_t> raw_flag;
    // CP932 を含む原バイト列。言語別定義を上書き統合しない。
    std::string name_bytes;
    std::string display_name_bytes;
    std::vector<std::string> alias_bytes;
    std::vector<SmallBodyTextField> fields;
    std::optional<double> epoch_value;
    std::optional<double> perihelion_time_value;
    SmallBodyFrame frame = SmallBodyFrame::unresolved;
    SmallBodyTimeScale time_scale = SmallBodyTimeScale::unresolved;
    // nullopt は精度保証期間が不明という意味。無期限の精度保証ではない。
    std::optional<SmallBodyTimeRange> declared_time_range;
    std::variant<std::monostate, OrbitalElements, PerihelionElements> orbit;
    std::vector<SmallBodyDiagnostic> diagnostics;
};

struct SmallBodySource {
    std::string key; // data_directory からの相対パス。
    std::filesystem::path path;
    // ハッシュの衝突や文字コード変換を避け、原出典を正確に比較できるよう保持する。
    std::string bytes;
    std::size_t record_count = 0;
    bool loaded = false;
};

struct SmallBodyDataset {
    std::vector<SmallBodyRecord> records;
    std::vector<SmallBodySource> sources;
    std::vector<SmallBodyDiagnostic> diagnostics;
};

// 指定 data_directory の既知ファイルと二つの個別軌道ディレクトリを読み取り専用で読む。
// 各出典は全件読込か失敗。欠損・不正な出典は diagnostics に記録して他出典を保持する。
// 同一番号・同一時刻・言語別定義・旧新ファイルを統合または間引きしない。
// max_file_bytes は各ファイル、max_records はデータセット全体の上限。
SmallBodyDataset load_small_body_dataset(const std::filesystem::path& data_directory,
                                         CatalogLoadLimits limits = {});

struct SmallBodyEvaluation {
    // 成功時のみ日心 J2000 黄道座標 AU / AU day^-1。時刻は TDB JD。
    // 未確定要素・不正時刻・計算失敗では nullopt と診断を返す。
    std::optional<OrbitalState> state;
    std::vector<SmallBodyDiagnostic> diagnostics;
};

SmallBodyEvaluation evaluate_small_body(const SmallBodyRecord& record, double julian_date);

} // namespace mitaka
