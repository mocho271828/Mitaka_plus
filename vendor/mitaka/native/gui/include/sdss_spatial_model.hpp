#pragma once

#include "mitaka/extended_catalog.hpp"

#include <functional>
#include <memory>
#include <optional>
#include <string_view>

namespace mitaka::gui {

// AU の Vec3 と暗黙に交換できないよう、座標系と単位を型に含める。
struct EquatorialPositionPc { double x_pc, y_pc, z_pc; };
struct NativeEclipticPositionPc { double x_pc, y_pc, z_pc; };

struct SdssSpatialPositionPc {
    EquatorialPositionPc equatorial;
    NativeEclipticPositionPc native_ecliptic;
};

struct SdssSpatialSource {
    SdssKind kind = SdssKind::galaxy;
    // 呼出し側が実際に読み取った出典。モデルは再読込・正規化しない。
    std::filesystem::path path;
    std::vector<SdssRecord> records;
};

struct SdssSpatialRecordId {
    // モデル内だけで有効。再読込後の同一性をパス一致から推定しない。
    std::size_t source_index = 0;
    std::size_t ordinal = 0;
};

class SdssSpatialModel {
public:
    // 出典順・原行順・重複・不正な行の原値を値所有で保持する。
    // 空パス/未知 kind は invalid_argument、総件数 overflow は length_error。
    explicit SdssSpatialModel(std::vector<SdssSpatialSource> sources);
    SdssSpatialModel(const SdssSpatialModel&) = default;
    SdssSpatialModel(SdssSpatialModel&&) = delete;
    SdssSpatialModel& operator=(const SdssSpatialModel&) = delete;
    SdssSpatialModel& operator=(SdssSpatialModel&&) = delete;
    const std::vector<SdssSpatialSource>& sources() const noexcept { return sources_; }
    std::size_t size() const noexcept { return row_count_; }
    SdssSpatialRecordId record_id(std::size_t row) const;
    std::size_t row_index(SdssSpatialRecordId id) const;
    const SdssRecord& record(SdssSpatialRecordId id) const;

private:
    std::vector<SdssSpatialSource> sources_;
    std::vector<std::size_t> source_offsets_;
    std::size_t row_count_ = 0;
};

enum class SdssSpatialIssue : std::uint16_t {
    none = 0,
    not_evaluated = 1 << 0,
    zero_distance = 1 << 1,
    nonfinite_right_ascension = 1 << 2,
    right_ascension_out_of_range = 1 << 3,
    nonfinite_declination = 1 << 4,
    declination_out_of_range = 1 << 5,
    nonfinite_distance = 1 << 6,
    negative_distance = 1 << 7,
    nonfinite_classification = 1 << 8
};

using SdssSpatialIssues = std::uint16_t;
bool has_sdss_spatial_issue(SdssSpatialIssues issues, SdssSpatialIssue issue) noexcept;
// 単一の理由を返す。組合せ/未知 enum は invalid_argument。
std::string_view sdss_spatial_issue_message(SdssSpatialIssue issue);

struct SdssSpatialRow {
    std::optional<SdssSpatialPositionPc> position;
    SdssSpatialIssues issues = static_cast<SdssSpatialIssues>(SdssSpatialIssue::not_evaluated);
};

struct SdssSpatialSnapshot {
    std::shared_ptr<const SdssSpatialModel> model;
    // 常に全原行数。取消後の未処理行も not_evaluated として残す。
    std::vector<SdssSpatialRow> rows;
    std::size_t completed_count = 0;
    std::size_t positioned_count = 0;
    std::size_t invalid_count = 0;
    // 処理済みの距離 0 行数。他の列が不正な行も含む。
    std::size_t zero_distance_count = 0;
    bool cancelled = false;
};

// pc の赤道位置と既存 native J2000 黄道位置を別に生成する。
// 黄道傾斜は j2000_obliquity_deg。公式 1.3.1 の 23.43870583 度とは別契約。
// 0 距離は原点として計算可能。不正列は原値と全理由を残し位置を生成しない。
// I/O・AU 変換・宇宙論/赤方偏移からの距離再計算・時刻変換は行わない。
// 取消は各行の前で検査する。呼出し側は cancelled の結果を完成品として採用しない。
std::shared_ptr<const SdssSpatialSnapshot> evaluate_sdss_spatial_snapshot(
    std::shared_ptr<const SdssSpatialModel> model,
    std::function<bool()> should_cancel = {});

} // namespace mitaka::gui
