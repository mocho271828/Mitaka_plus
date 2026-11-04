#pragma once
#include "mitaka/satellite_absolute.hpp"
#include <functional>
#include <memory>

namespace mitaka::gui {

struct SatelliteSearchPage {
    std::vector<std::size_t> rows;
    std::size_t total_matches = 0;
    std::size_t offset = 0;
    bool cancelled = false;
};

class SatelliteBrowserModel {
public:
    explicit SatelliteBrowserModel(std::shared_ptr<const SatelliteModel> model,
        std::vector<SatelliteModelDiagnostic> registration_diagnostics = {});
    const SatelliteModel& model() const noexcept { return *model_; }
    const std::vector<std::string>& sources() const noexcept { return sources_; }
    const std::string& title(std::size_t index) const;
    const std::string& parent_title(std::size_t index) const;
    std::string provenance(std::size_t index) const;
    const std::string& source(std::size_t index) const;
    const std::vector<SatelliteModelDiagnostic>& registration_diagnostics() const noexcept {
        return registration_diagnostics_;
    }
    SatelliteSearchPage search(const std::string& query, const std::optional<std::string>& source,
        std::size_t offset, std::size_t page_size,
        const std::function<bool()>& cancelled = {}) const;
private:
    std::shared_ptr<const SatelliteModel> model_;
    std::vector<SatelliteModelDiagnostic> registration_diagnostics_;
    std::vector<std::string> titles_, parent_titles_, search_text_, source_keys_, sources_;
};

// 各 system source は別々の空 native コンテナへ登録する。元アプリの起動順とは区別する。
std::shared_ptr<const SatelliteBrowserModel> load_satellite_browser_model(
    const std::filesystem::path& data_directory);

struct SatelliteSnapshot {
    std::shared_ptr<const SatelliteBrowserModel> model;
    double julian_date = 0;
    // 原行と同数・同順。座標は日心 J2000 黄道 AU。未解決行・重複行も残す。
    std::vector<std::optional<Vec3>> positions;
    std::vector<SatelliteAbsoluteEvaluation> evaluations;
    std::vector<std::string> diagnostics;
    std::size_t positioned_count = 0;
};

// CF96 と同じ成功登録順を確認できた source のみ絶対位置を評価する。
// Moon は公式 1.3.1 の月モデルを倍率1で明示入力する。旧Plus解析倍率との一致は主張しない。
std::shared_ptr<const SatelliteSnapshot> evaluate_satellite_snapshot(
    std::shared_ptr<const SatelliteBrowserModel> model, const Cf96Ephemeris& ephemeris,
    double julian_date);
std::string satellite_description(const SatelliteBrowserModel& model, std::size_t index,
                                  const SatelliteSnapshot* snapshot = nullptr);

} // namespace mitaka::gui
