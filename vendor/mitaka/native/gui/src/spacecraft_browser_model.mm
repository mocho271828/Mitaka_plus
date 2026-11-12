#import <Foundation/Foundation.h>
#include "spacecraft_browser_model.hpp"
#include <algorithm>
#include <cmath>
#include <iomanip>
#include <map>
#include <sstream>
#include <stdexcept>

namespace mitaka::gui {
namespace {
std::string utf8(NSString *text) { return text ? std::string(text.UTF8String) : std::string{}; }
bool modern_definition(const SpacecraftDefinition& definition) {
    return std::any_of(definition.fields.begin(), definition.fields.end(), [](const auto& field) {
        return field.key == "KEY" || field.key == "TRAJECTORY" || !field.section_bytes.empty();
    });
}
std::string decode(const std::string& bytes, bool modern) {
    const auto japanese = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese);
    NSString *text = [[NSString alloc] initWithBytes:bytes.data() length:bytes.size()
        encoding:modern ? NSUTF8StringEncoding : japanese];
    if (!text) text = [[NSString alloc] initWithBytes:bytes.data() length:bytes.size()
        encoding:modern ? japanese : NSUTF8StringEncoding];
    return text ? utf8(text) : "[文字コードを解釈できません]";
}
std::string folded(const std::string& text) {
    NSString *value = [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
    return utf8([value lowercaseStringWithLocale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]]);
}
std::string definition_title(const SpacecraftDefinition& definition) {
    const bool modern = modern_definition(definition);
    const auto* name = modern ? unique_spacecraft_field(definition, "NAME", "ja")
                              : unique_spacecraft_field(definition, "DisplayName");
    if (!name || name->value_bytes.empty()) name = modern
        ? unique_spacecraft_field(definition, "NAME", "default") : unique_spacecraft_field(definition, "Name");
    if ((!name || name->value_bytes.empty()) && modern) name = unique_spacecraft_field(definition, "KEY");
    return name && !name->value_bytes.empty() ? decode(name->value_bytes, modern) : "名称未解決";
}
// バイナリ読込単独の制約は元データに残す。ブラウザでは位置評価器が返す現在の契約を使う。
bool show_loader_diagnostic(const SpacecraftDiagnostic& diagnostic) {
    return diagnostic.code != SpacecraftDiagnosticCode::unresolved_pth_contract;
}
const char* sampling_title(SpacecraftSamplingKind kind) {
    switch (kind) {
        case SpacecraftSamplingKind::exact_record: return "原記録に一致";
        case SpacecraftSamplingKind::interpolated: return "原記録間の線形補間";
        case SpacecraftSamplingKind::clamped_before: return "記録期間前のため先頭位置に固定";
        case SpacecraftSamplingKind::clamped_after: return "記録期間後のため末尾位置に固定";
    }
    throw std::logic_error("unknown spacecraft sampling kind");
}
}

SpacecraftBrowserModel::SpacecraftBrowserModel(std::shared_ptr<const SpacecraftPositionModel> model)
    : model_(std::move(model)) {
    if (!model_) throw std::invalid_argument("spacecraft model is null");
    std::map<std::size_t, std::size_t> ordinals;
    for (const auto& definition : model_->dataset().definitions) {
        const auto& source = model_->dataset().sources.at(definition.source_index);
        titles_.push_back(definition_title(definition));
        source_keys_.push_back(source.key);
        ordinals_.push_back(ordinals[definition.source_index]++);
        if (std::find(sources_.begin(), sources_.end(), source.key) == sources_.end()) sources_.push_back(source.key);
        const bool modern = modern_definition(definition);
        std::string search = titles_.back() + " " + source.key + " #" + std::to_string(ordinals_.back());
        for (const auto& field : definition.fields)
            search += " " + field.key + " " + decode(field.value_bytes, modern);
        search_text_.push_back(folded(search));
    }
}
const std::string& SpacecraftBrowserModel::title(std::size_t index) const { return titles_.at(index); }
const std::string& SpacecraftBrowserModel::source(std::size_t index) const { return source_keys_.at(index); }
std::string SpacecraftBrowserModel::provenance(std::size_t index) const {
    return source_keys_.at(index) + " #" + std::to_string(ordinals_.at(index));
}
SpacecraftSearchPage SpacecraftBrowserModel::search(const std::string& query,
    const std::optional<std::string>& source_filter, std::size_t offset, std::size_t page_size,
    const std::function<bool()>& cancelled) const {
    if (page_size == 0) throw std::invalid_argument("spacecraft page size must be positive");
    SpacecraftSearchPage page;
    page.offset = offset;
    const auto needle = folded(query);
    for (std::size_t index = 0; index < titles_.size(); ++index) {
        if (cancelled && cancelled()) { page.cancelled = true; page.rows.clear(); return page; }
        if (source_filter && *source_filter != source_keys_[index]) continue;
        if (!needle.empty() && search_text_[index].find(needle) == std::string::npos) continue;
        if (page.total_matches++ >= offset && page.rows.size() < page_size) page.rows.push_back(index);
    }
    return page;
}

std::shared_ptr<const SpacecraftBrowserModel> load_spacecraft_browser_model(const std::filesystem::path& directory) {
    return std::make_shared<const SpacecraftBrowserModel>(
        std::make_shared<const SpacecraftPositionModel>(load_spacecraft_dataset(directory)));
}

std::shared_ptr<const SpacecraftSnapshot> evaluate_spacecraft_snapshot(
    std::shared_ptr<const SpacecraftBrowserModel> model, double jd) {
    if (!model) throw std::invalid_argument("spacecraft browser model is null");
    if (!std::isfinite(jd)) throw std::invalid_argument("spacecraft Julian date must be finite");
    auto snapshot = std::make_shared<SpacecraftSnapshot>();
    snapshot->model = std::move(model);
    snapshot->julian_date = jd;
    const auto& definitions = snapshot->model->model().dataset().definitions;
    snapshot->positions.resize(definitions.size());
    snapshot->evaluations.resize(definitions.size());
    for (std::size_t index = 0; index < definitions.size(); ++index) {
        if (!definitions[index].trajectory_index) continue;
        auto evaluation = snapshot->model->model().evaluate(*definitions[index].trajectory_index, jd);
        const auto position = evaluation.heliocentric_j2000_ecliptic_au;
        if (position && (!std::isfinite(position->x) || !std::isfinite(position->y) || !std::isfinite(position->z)))
            throw std::runtime_error("spacecraft evaluator returned a non-finite position");
        snapshot->positions[index] = position;
        if (position) ++snapshot->positioned_count;
        snapshot->evaluations[index] = std::move(evaluation);
    }
    return snapshot;
}

std::string spacecraft_catalog_description(const SpacecraftBrowserModel& model) {
    std::ostringstream output;
    output << "同名の探査機と未解決の定義もすべて保持します。PTH は旧版の数値 JD で評価し、PPI の座標は推定しません。行を選ぶと原定義・位置・診断を表示します。";
    for (const auto& diagnostic : model.model().dataset().diagnostics)
        if (show_loader_diagnostic(diagnostic)) output << "\n" << diagnostic.source_key << ": " << diagnostic.message;
    return output.str();
}

std::string spacecraft_description(const SpacecraftBrowserModel& model, std::size_t index,
                                   const SpacecraftSnapshot* snapshot) {
    const auto& dataset = model.model().dataset();
    const auto& definition = dataset.definitions.at(index);
    std::ostringstream output;
    output << model.title(index) << "\n" << model.provenance(index);
    std::optional<std::string> trajectory_source;
    if (definition.trajectory_index && *definition.trajectory_index < dataset.trajectories.size()) {
        const auto& trajectory = dataset.trajectories[*definition.trajectory_index];
        if (trajectory.source_index < dataset.sources.size()) {
            const auto& source = dataset.sources[trajectory.source_index];
            trajectory_source = source.key;
            output << "\n軌跡出典: " << *trajectory_source;
            if (source.kind == SpacecraftSourceKind::pth_samples)
                output << "\nPTH 原記録数: " << trajectory.path_samples.size();
            else if (source.kind == SpacecraftSourceKind::ppi_segments)
                output << "\nPPI 原区間数: " << source.record_count;
        }
    }
    if (snapshot && snapshot->model.get() == &model && index < snapshot->positions.size()
        && index < snapshot->evaluations.size()) {
        output << "\nJD " << std::fixed << std::setprecision(8) << snapshot->julian_date
               << " (旧版の数値入力・時系変換なし)";
        if (snapshot->positions[index]) {
            const auto p = *snapshot->positions[index];
            output << "\n日心 J2000 黄道 AU\nX " << p.x << " / Y " << p.y << " / Z " << p.z;
        } else output << "\n位置を表示できません";
        if (snapshot->evaluations[index]) {
            const auto& evaluation = *snapshot->evaluations[index];
            if (evaluation.sampling) {
                const auto& sampling = *evaluation.sampling;
                output << "\n" << sampling_title(sampling.kind) << " (#" << sampling.first_record_index
                       << " / #" << sampling.second_record_index << ", u=" << sampling.u << ")";
            }
            for (const auto& diagnostic : evaluation.diagnostics) output << "\n" << diagnostic.message;
        } else output << "\n軌跡参照が未解決です";
    } else output << "\n位置未評価";
    const bool modern = modern_definition(definition);
    output << "\n\n原定義の全フィールド";
    for (const auto& field : definition.fields) {
        output << "\n";
        if (!field.section_bytes.empty()) output << "[" << decode(field.section_bytes, true) << "] ";
        output << field.key << " = " << decode(field.value_bytes, modern);
    }
    for (const auto& diagnostic : dataset.diagnostics)
        if (show_loader_diagnostic(diagnostic) && (diagnostic.source_key == model.source(index)
            || (trajectory_source && diagnostic.source_key == *trajectory_source)))
            output << "\n読込時の診断: " << diagnostic.message;
    output << "\n物理時系・精度保証期間は不明";
    return output.str();
}
} // namespace mitaka::gui
