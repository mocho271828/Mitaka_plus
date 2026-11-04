#pragma once

#include "sky_model.hpp"

namespace mitaka::gui {

enum class SkyCatalogKind { nebula, galaxy, quasar };
struct ProjectedCatalogPoint { std::size_t index; ScreenPoint point; };

// 5度区画から可視域だけを投影する。元カタログの添字・全件を保持する。
class SkyCatalogIndex {
public:
    SkyCatalogIndex() = default;
    explicit SkyCatalogIndex(std::vector<EquatorialCoordinates> coordinates);
    std::vector<ProjectedCatalogPoint> project(SkyViewport viewport, double width, double height) const;
private:
    std::vector<EquatorialCoordinates> coordinates_;
    std::array<std::vector<std::size_t>, 72 * 36> bins_;
};

} // namespace mitaka::gui
