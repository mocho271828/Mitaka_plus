#pragma once

#include "observer_places.hpp"

#include <string_view>

namespace mitaka::gui {

struct PlaceDefinitionOrigin {
    std::size_t source;
    std::size_t row; // 対応する label_groups または landscapes 内のゼロ始まり位置。
};

struct EffectivePlaceLabelGroup {
    PlaceLabelGroup definition;
    PlaceDefinitionOrigin origin;
};

struct EffectivePlaceLandscape {
    std::string qualified_name;
    PlaceLandscape definition;
    PlaceDefinitionOrigin origin;
};

// 地点一覧と同じ選択元から表示定義を作る immutable snapshot。
// 原 bytes・全行は observer_places() に残し、実効値の上書きとは分離する。
// 群名 / target + "." + name は bytes 完全一致、後勝ち・初出位置維持。
// 数値は原単位のまま。画像を開かず、組込 Default 群や観測者への適用を推測しない。
class PlaceDisplayModel {
public:
    // 不正な selected_source は invalid_argument。解析失敗した選択元は実効値ゼロ。
    explicit PlaceDisplayModel(ObserverPlaces places);

    const ObserverPlaces& observer_places() const noexcept { return places_; }
    const std::vector<EffectivePlaceLabelGroup>& label_groups() const noexcept { return label_groups_; }
    const std::vector<EffectivePlaceLandscape>& landscapes() const noexcept { return landscapes_; }

    // 完全一致だけを返す。空・未知の名前に組込群 / 既定風景を補わない。
    std::optional<std::size_t> find_label_group(std::string_view name) const noexcept;
    std::optional<std::size_t> find_landscape(std::string_view qualified_name) const noexcept;

private:
    ObserverPlaces places_;
    std::vector<EffectivePlaceLabelGroup> label_groups_;
    std::vector<EffectivePlaceLandscape> landscapes_;
};

} // namespace mitaka::gui
