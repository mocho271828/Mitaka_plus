#import <Foundation/Foundation.h>
#include "small_body_model.hpp"
#include "mitaka/minor_planet_position.hpp"
#include <algorithm>
#include <cmath>
#include <iomanip>
#include <sstream>
#include <stdexcept>

namespace mitaka::gui {
namespace {
std::string utf8(NSString *text) { return text ? std::string(text.UTF8String) : std::string{}; }
std::string decode(const std::string& bytes) {
    NSString *text = [[NSString alloc] initWithBytes:bytes.data() length:bytes.size()
        encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese)];
    if (!text) text = [[NSString alloc] initWithBytes:bytes.data() length:bytes.size() encoding:NSUTF8StringEncoding];
    return text ? utf8(text) : "[文字コードを解釈できません]";
}
std::string folded(const std::string& text) {
    NSString *value = [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
    return utf8([value lowercaseStringWithLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]]);
}
SmallBodyEvaluationMode mode(const SmallBodyRecord& record) {
    if (record.encoding == SmallBodyEncoding::packed_37) return SmallBodyEvaluationMode::unresolved;
    if ((record.kind == SmallBodyKind::asteroid || record.kind == SmallBodyKind::trans_neptunian)
        && std::holds_alternative<OrbitalElements>(record.orbit)) {
        if (record.encoding == SmallBodyEncoding::packed_36)
            return SmallBodyEvaluationMode::packed36_legacy_jd;
        if (record.encoding == SmallBodyEncoding::element_text)
            return SmallBodyEvaluationMode::element_text_legacy_jd;
    }
    if (record.kind == SmallBodyKind::comet
        && record.frame == SmallBodyFrame::heliocentric_j2000_ecliptic
        && record.time_scale == SmallBodyTimeScale::tdb
        && !std::holds_alternative<std::monostate>(record.orbit))
        return SmallBodyEvaluationMode::comet_tdb;
    return SmallBodyEvaluationMode::unresolved;
}
void append_diagnostics(std::ostringstream& output, const std::vector<SmallBodyDiagnostic>& diagnostics) {
    for (const auto& diagnostic : diagnostics) {
        output << "\n" << diagnostic.message;
    }
}
}

SmallBodyModel::SmallBodyModel(std::shared_ptr<const SmallBodyDataset> dataset)
    : dataset_(std::move(dataset)) {
    if (!dataset_) throw std::invalid_argument("small-body dataset is null");
    titles_.reserve(dataset_->records.size());
    search_text_.reserve(dataset_->records.size());
    for (std::size_t index = 0; index < dataset_->records.size(); ++index) {
        const auto& record = dataset_->records[index];
        std::string title = decode(record.display_name_bytes.empty() ? record.name_bytes : record.display_name_bytes);
        if (title.empty()) title = record.number ? "番号 " + std::to_string(*record.number) : "名称なし";
        titles_.push_back(title);
        std::string text = title + " " + decode(record.name_bytes) + " " + provenance(index);
        if (record.number) text += " " + std::to_string(*record.number);
        for (const auto& alias : record.alias_bytes) text += " " + decode(alias);
        search_text_.push_back(folded(text));
        if (mode(record) != SmallBodyEvaluationMode::unresolved) evaluable_.push_back(index);
    }
}
const std::string& SmallBodyModel::title(std::size_t index) const { return titles_.at(index); }
SmallBodyEvaluationMode SmallBodyModel::evaluation_mode(std::size_t index) const {
    return mode(dataset_->records.at(index));
}
std::string SmallBodyModel::provenance(std::size_t index) const {
    const auto& record = dataset_->records.at(index);
    return record.id.source_key + " #" + std::to_string(record.id.record_ordinal);
}
SmallBodySearchPage SmallBodyModel::search(const std::string& query, std::optional<SmallBodyKind> kind,
    std::size_t offset, std::size_t page_size, const std::function<bool()>& cancelled) const {
    if (page_size == 0) throw std::invalid_argument("small-body page size must be positive");
    SmallBodySearchPage page;
    page.offset = offset;
    const auto needle = folded(query);
    for (std::size_t index = 0; index < dataset_->records.size(); ++index) {
        if (cancelled && cancelled()) { page.cancelled = true; page.rows.clear(); return page; }
        if (kind && dataset_->records[index].kind != *kind) continue;
        if (!needle.empty() && search_text_[index].find(needle) == std::string::npos) continue;
        if (page.total_matches++ >= offset && page.rows.size() < page_size) page.rows.push_back(index);
    }
    return page;
}

std::shared_ptr<const SmallBodySnapshot> evaluate_small_body_snapshot(
    std::shared_ptr<const SmallBodyModel> model, double julian_date, bool evaluate_all,
    std::optional<std::size_t> selection) {
    if (!model) throw std::invalid_argument("small-body model is null");
    if (!std::isfinite(julian_date)) throw std::invalid_argument("small-body Julian date must be finite");
    if (selection && *selection >= model->dataset().records.size())
        throw std::out_of_range("small-body selection index");
    auto frame = std::make_shared<SmallBodySnapshot>();
    frame->model = std::move(model);
    frame->julian_date = julian_date;
    frame->evaluated_all = evaluate_all;
    frame->evaluated_selection = selection;
    frame->positions.resize(frame->model->dataset().records.size());
    const auto evaluate = [&](std::size_t index) {
        const auto& record = frame->model->dataset().records[index];
        std::optional<Vec3> position;
        std::vector<SmallBodyDiagnostic> diagnostics;
        const auto evaluationMode = frame->model->evaluation_mode(index);
        if (evaluationMode == SmallBodyEvaluationMode::packed36_legacy_jd
            || evaluationMode == SmallBodyEvaluationMode::element_text_legacy_jd) {
            auto result = evaluate_minor_planet_position(record, julian_date);
            position = result.heliocentric_j2000_ecliptic_au;
            diagnostics = std::move(result.diagnostics);
        } else {
            auto result = evaluate_small_body(record, julian_date);
            if (result.state) position = result.state->position_au;
            diagnostics = std::move(result.diagnostics);
        }
        if (position) {
            const Vec3 p = *position;
            if (!std::isfinite(p.x) || !std::isfinite(p.y) || !std::isfinite(p.z))
                throw std::runtime_error("small-body evaluator returned a non-finite position");
            frame->positions[index] = p;
            ++frame->positioned_count;
        }
        // 静的診断は model が保持する。毎フレーム同じ長文を複製しない。
        if (!position)
            frame->diagnostics.insert(frame->diagnostics.end(), diagnostics.begin(), diagnostics.end());
    };
    if (evaluate_all) {
        for (const auto index : frame->model->evaluable_indices()) evaluate(index);
    } else if (selection && frame->model->evaluation_mode(*selection) != SmallBodyEvaluationMode::unresolved)
        evaluate(*selection);
    return frame;
}

std::string small_body_summary(const SmallBodyModel& model) {
    return "原本 " + std::to_string(model.dataset().records.size())
        + " 件 · 位置評価候補（未対応を含む） " + std::to_string(model.evaluable_indices().size())
        + " 件 · 出典診断 " + std::to_string(model.dataset().diagnostics.size()) + " 件";
}

std::string small_body_description(const SmallBodyModel& model, std::size_t index, const SmallBodySnapshot* frame) {
    const auto& record = model.dataset().records.at(index);
    const auto evaluationMode = model.evaluation_mode(index);
    const bool packed = evaluationMode == SmallBodyEvaluationMode::packed36_legacy_jd;
    const bool individual = evaluationMode == SmallBodyEvaluationMode::element_text_legacy_jd;
    std::vector<SmallBodyDiagnostic> diagnostics = record.diagnostics;
    std::ostringstream output;
    output << model.title(index) << "\n" << model.provenance(index);
    if (record.number) output << "\n原番号 " << *record.number;
    if (frame && frame->model.get() == &model && index < frame->positions.size()) {
        output << "\nJD " << std::fixed << std::setprecision(5) << frame->julian_date;
        if (evaluationMode == SmallBodyEvaluationMode::comet_tdb) output << " (TDB 入力・時系変換なし)";
        else if (packed || individual) output << " (原版の数値 JD・時系変換なし)";
        else output << " (時系未確定・変換なし)";
        if (frame->positions[index]) {
            const auto p = *frame->positions[index];
            output << "\n日心 J2000 黄道 AU · 二体近似\nX " << p.x << " / Y " << p.y << " / Z " << p.z;
            if (packed || individual) diagnostics.erase(std::remove_if(diagnostics.begin(), diagnostics.end(),
                [](const auto& diagnostic) { return diagnostic.code == SmallBodyDiagnosticCode::unresolved_frame; }),
                diagnostics.end());
        } else if (!frame->evaluated_all && frame->evaluated_selection != index
                   && evaluationMode != SmallBodyEvaluationMode::unresolved)
            output << "\n非表示中のため位置評価を省略";
        else output << "\n位置を表示できません";
        for (const auto& diagnostic : frame->diagnostics) {
            if (diagnostic.source_key != record.id.source_key || diagnostic.record_ordinal != record.id.record_ordinal) continue;
            const auto duplicate = std::find_if(diagnostics.begin(), diagnostics.end(), [&](const auto& existing) {
                return existing.code == diagnostic.code && existing.field == diagnostic.field && existing.message == diagnostic.message;
            });
            if (duplicate == diagnostics.end()) diagnostics.push_back(diagnostic);
        }
    } else output << "\n位置未評価";
    if (packed) output << "\npacked 36 byte の位置契約・物理時系 UTC/TT/TDB は未確定";
    if (individual) output << "\n個別軌道の a 指定・楕円は明示 n または a から算出した平均運動を使用・物理時系 UTC/TT/TDB は未確定";
    append_diagnostics(output, diagnostics);
    if (!record.declared_time_range) output << "\n精度保証期間は不明";
    if (evaluationMode == SmallBodyEvaluationMode::unresolved && record.diagnostics.empty())
        output << "\n座標系・時系・軌道要素が未確定";
    return output.str();
}
} // namespace mitaka::gui
