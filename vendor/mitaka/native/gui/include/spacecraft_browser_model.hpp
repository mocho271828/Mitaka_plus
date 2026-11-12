#pragma once

#include "mitaka/spacecraft_position.hpp"
#include <functional>
#include <memory>

namespace mitaka::gui {

struct SpacecraftSearchPage {
    std::vector<std::size_t> rows;
    std::size_t total_matches = 0;
    std::size_t offset = 0;
    bool cancelled = false;
};

class SpacecraftBrowserModel {
public:
    explicit SpacecraftBrowserModel(std::shared_ptr<const SpacecraftPositionModel> model);
    const SpacecraftPositionModel& model() const noexcept { return *model_; }
    const std::vector<std::string>& sources() const noexcept { return sources_; }
    const std::string& title(std::size_t index) const;
    const std::string& source(std::size_t index) const;
    std::string provenance(std::size_t index) const;
    SpacecraftSearchPage search(const std::string& query, const std::optional<std::string>& source,
        std::size_t offset, std::size_t page_size,
        const std::function<bool()>& cancelled = {}) const;
private:
    std::shared_ptr<const SpacecraftPositionModel> model_;
    std::vector<std::string> titles_, search_text_, source_keys_, sources_;
    std::vector<std::size_t> ordinals_;
};

std::shared_ptr<const SpacecraftBrowserModel> load_spacecraft_browser_model(
    const std::filesystem::path& data_directory);

struct SpacecraftSnapshot {
    std::shared_ptr<const SpacecraftBrowserModel> model;
    double julian_date = 0;
    // 定義と同数・同順。未解決定義も残し、PPI を推定座標で投影しない。
    std::vector<std::optional<Vec3>> positions;
    std::vector<std::optional<SpacecraftPositionEvaluation>> evaluations;
    std::size_t positioned_count = 0;
};

std::shared_ptr<const SpacecraftSnapshot> evaluate_spacecraft_snapshot(
    std::shared_ptr<const SpacecraftBrowserModel> model, double legacy_julian_date);
std::string spacecraft_catalog_description(const SpacecraftBrowserModel& model);
std::string spacecraft_description(const SpacecraftBrowserModel& model, std::size_t index,
                                   const SpacecraftSnapshot* snapshot = nullptr);

} // namespace mitaka::gui
