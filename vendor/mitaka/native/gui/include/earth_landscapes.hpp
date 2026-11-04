#pragma once

#include "local_image.hpp"
#include "place_display_model.hpp"
#include <memory>

namespace mitaka::gui {

// 原版の地球上での選択順。指定地点→Planet.Earth.Default→Planet.Default。
// 読込可否は選択条件に含めず、失敗した画像を別定義へ置き換えない。
std::optional<std::size_t> select_earth_landscape(const PlaceDisplayModel& model,
                                                std::string_view place_identifier);

class EarthLandscapes {
public:
    // 選択元の全 bytes/行を保持。画像は選択 data の親フォルダ内だけを参照する。
    // Earth と Planet.Default の実効画像を最大128MiBまで読み、超過・未対応も警告する。
    static EarthLandscapes load(const std::filesystem::path& data_directory, ObserverPlaces places);
    const PlaceDisplayModel& definitions() const noexcept { return definitions_; }
    const std::vector<std::string>& warnings() const noexcept { return warnings_; }
    std::optional<std::size_t> selection(std::string_view identifier) const;
    const TextureImage* image(std::size_t index) const;

private:
    explicit EarthLandscapes(ObserverPlaces places);
    PlaceDisplayModel definitions_;
    std::vector<std::shared_ptr<const TextureImage>> images_;
    std::vector<std::string> warnings_;
};

} // namespace mitaka::gui
