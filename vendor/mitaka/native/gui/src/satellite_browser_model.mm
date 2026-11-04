#import <Foundation/Foundation.h>
#include "satellite_browser_model.hpp"
#include "mitaka/lunar.hpp"
#include <algorithm>
#include <array>
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
std::string definition_title(const SatelliteDefinition& definition) {
    const auto* name = unique_satellite_field(definition.fields, "Name");
    if (!name || name->value_bytes.empty()) return "名称未解決";
    const auto separator = name->value_bytes.find_first_of(" \t\r\n");
    const auto display = separator == std::string::npos ? std::string::npos
        : name->value_bytes.find_first_not_of(" \t\r\n", separator);
    return decode(display == std::string::npos ? name->value_bytes : name->value_bytes.substr(display));
}
bool cf96_order_matches(const SatelliteRegistrationContext& context) {
    constexpr std::array<const char*, 9> identifiers{{"Mercury", "Venus", "Earth", "Mars", "Jupiter",
        "Saturn", "Uranus", "Neptune", "Pluto"}};
    if (!context.planet_identifiers_complete || context.planets.size() != identifiers.size()) return false;
    for (std::size_t i = 0; i < identifiers.size(); ++i)
        if (context.planets[i].identifier_bytes != identifiers[i]
            || context.planets[i].registration_index.value != i) return false;
    return true;
}
template<class Diagnostic>
void append_row_diagnostics(std::ostringstream& output, const std::vector<Diagnostic>& diagnostics,
                            std::size_t definition_index) {
    for (const auto& diagnostic : diagnostics)
        if (!diagnostic.definition_index || *diagnostic.definition_index == definition_index)
            output << "\n" << diagnostic.message;
}
}

SatelliteBrowserModel::SatelliteBrowserModel(std::shared_ptr<const SatelliteModel> model,
    std::vector<SatelliteModelDiagnostic> registration_diagnostics)
    : model_(std::move(model)), registration_diagnostics_(std::move(registration_diagnostics)) {
    if (!model_) throw std::invalid_argument("satellite model is null");
    for (const auto& record : model_->records()) {
        const auto& definition = model_->dataset().definitions.at(record.definition_index);
        titles_.push_back(definition_title(definition));
        parent_titles_.push_back(record.parent_definition_index
            ? definition_title(model_->dataset().definitions.at(*record.parent_definition_index)) : "親天体未解決");
        source_keys_.push_back(definition.id.source_key);
        if (std::find(sources_.begin(), sources_.end(), definition.id.source_key) == sources_.end())
            sources_.push_back(definition.id.source_key);
        search_text_.push_back(folded(titles_.back() + " " + parent_titles_.back() + " "
            + decode(record.identifier_bytes) + " " + definition.id.source_key + " #"
            + std::to_string(definition.id.record_ordinal)));
    }
}
const std::string& SatelliteBrowserModel::title(std::size_t index) const { return titles_.at(index); }
const std::string& SatelliteBrowserModel::parent_title(std::size_t index) const { return parent_titles_.at(index); }
const std::string& SatelliteBrowserModel::source(std::size_t index) const { return source_keys_.at(index); }
std::string SatelliteBrowserModel::provenance(std::size_t index) const {
    const auto& definition = model_->dataset().definitions.at(model_->records().at(index).definition_index);
    return definition.id.source_key + " #" + std::to_string(definition.id.record_ordinal);
}
SatelliteSearchPage SatelliteBrowserModel::search(const std::string& query,
    const std::optional<std::string>& source_filter, std::size_t offset, std::size_t page_size,
    const std::function<bool()>& cancelled) const {
    if (page_size == 0) throw std::invalid_argument("satellite page size must be positive");
    SatelliteSearchPage page;
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

std::shared_ptr<const SatelliteBrowserModel> load_satellite_browser_model(const std::filesystem::path& directory) {
    auto dataset = load_satellite_dataset(directory);
    std::vector<VerifiedSatelliteRegistration> registrations;
    std::vector<SatelliteModelDiagnostic> diagnostics;
    for (const auto& source : dataset.sources) {
        if (source.kind != SatelliteSourceKind::system_definition) continue;
        auto result = make_isolated_satellite_registration(dataset, source.key);
        if (result.registration) registrations.push_back(std::move(*result.registration));
        diagnostics.insert(diagnostics.end(), result.diagnostics.begin(), result.diagnostics.end());
    }
    return std::make_shared<const SatelliteBrowserModel>(
        std::make_shared<const SatelliteModel>(std::move(dataset), std::move(registrations)), std::move(diagnostics));
}

std::shared_ptr<const SatelliteSnapshot> evaluate_satellite_snapshot(
    std::shared_ptr<const SatelliteBrowserModel> model, const Cf96Ephemeris& ephemeris, double jd) {
    if (!model) throw std::invalid_argument("satellite browser model is null");
    if (!std::isfinite(jd)) throw std::invalid_argument("satellite Julian date must be finite");
    auto snapshot = std::make_shared<SatelliteSnapshot>();
    snapshot->model = std::move(model);
    snapshot->julian_date = jd;
    snapshot->positions.resize(snapshot->model->model().records().size());
    for (const auto& registration : snapshot->model->model().registration_contexts()) {
        if (!cf96_order_matches(registration)) {
            snapshot->diagnostics.push_back(registration.source_key + ": CF96 と同じ惑星登録順を確認できません");
            continue;
        }
        SatelliteAbsoluteContext context{registration.source_key,
            "All 9 successful registrations match the local CF96 Mercury/Venus/Earth/Mars/Jupiter/Saturn/Uranus/Neptune/Pluto order", {}};
        if (jd >= lunar_minimum_jd && jd <= lunar_maximum_jd) {
            const auto moon = j2000_equatorial_to_ecliptic(lunar_position(jd));
            context.moon = SatelliteAbsoluteMoonInput{jd,
                {moon.x * satellite_km_per_au, moon.y * satellite_km_per_au, moon.z * satellite_km_per_au},
                "Official 1.3.1 native lunar model, scale 1; old Plus lunar approximation/scale not asserted"};
        }
        auto evaluation = evaluate_satellite_absolute(snapshot->model->model(), ephemeris, jd, context);
        if (evaluation.positions.size() != snapshot->positions.size())
            throw std::runtime_error("satellite evaluation does not match model rows");
        for (const auto index : registration.satellite_record_indices) {
            const auto position = evaluation.positions.at(index).position_au;
            if (position && (!std::isfinite(position->x) || !std::isfinite(position->y) || !std::isfinite(position->z)))
                throw std::runtime_error("satellite evaluator returned a non-finite position");
            snapshot->positions.at(index) = position;
            if (position) ++snapshot->positioned_count;
        }
        snapshot->evaluations.push_back(std::move(evaluation));
    }
    return snapshot;
}

std::string satellite_description(const SatelliteBrowserModel& model, std::size_t index,
                                  const SatelliteSnapshot* snapshot) {
    const auto& record = model.model().records().at(index);
    const auto& definition = model.model().dataset().definitions.at(record.definition_index);
    std::ostringstream output;
    output << model.title(index) << "\n親天体: " << model.parent_title(index) << "\n" << model.provenance(index);
    output << "\nID: " << decode(record.identifier_bytes);
    if (snapshot && snapshot->model.get() == &model && index < snapshot->positions.size()) {
        output << "\nJD " << std::fixed << std::setprecision(8) << snapshot->julian_date << " (旧版の数値入力・時系変換なし)";
        if (snapshot->positions[index]) {
            const auto p = *snapshot->positions[index];
            output << "\n日心 J2000 黄道 AU\nX " << p.x << " / Y " << p.y << " / Z " << p.z;
        } else output << "\n位置を表示できません";
        for (const auto& diagnostic : snapshot->diagnostics) output << "\n" << diagnostic;
        for (const auto& evaluation : snapshot->evaluations) {
            if (evaluation.context.source_key != definition.id.source_key) continue;
            output << "\n出典ごとの独立登録。原版起動時の登録状態との一致は未確認。";
            if (record.identifier_bytes == "Moon" && evaluation.context.moon)
                output << "\n月位置: 公式1.3.1モデル・倍率1。旧Plusの月解析・設定倍率との一致は未確認。";
            append_row_diagnostics(output, evaluation.diagnostics, record.definition_index);
            append_row_diagnostics(output, evaluation.positions.at(index).diagnostics, record.definition_index);
            const auto& relative = evaluation.relative.positions.at(index);
            append_row_diagnostics(output, relative.diagnostics, record.definition_index);
            for (const auto& diagnostic : relative.rotation_diagnostics) output << "\n" << diagnostic.message;
            for (const auto& diagnostic : relative.position_diagnostics) output << "\n" << diagnostic.message;
            for (const auto& diagnostic : relative.parent_pole_diagnostics) output << "\n" << diagnostic.message;
        }
    } else output << "\n位置未評価";
    append_row_diagnostics(output, record.diagnostics, record.definition_index);
    append_row_diagnostics(output, model.registration_diagnostics(), record.definition_index);
    for (const auto& diagnostic : model.model().dataset().diagnostics)
        if (diagnostic.source_key == definition.id.source_key
            && (!diagnostic.record_ordinal || *diagnostic.record_ordinal == definition.id.record_ordinal))
            output << "\n" << diagnostic.message;
    output << "\n精度保証期間は不明";
    return output.str();
}
} // namespace mitaka::gui
