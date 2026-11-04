#include "observer_places.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <iomanip>
#include <locale>
#include <map>
#include <sstream>
#include <utility>

namespace mitaka::gui {
namespace {

// 原版の全別名解決は未確定なので、既知の正規名と単一地点suffixだけを更新対象にする。
bool has_canonical_place_id(const std::string& target) {
    constexpr std::array<const char*, 9> bodies = {
        "Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune", "Pluto"};
    for (const auto* body : bodies) {
        const std::string prefix = std::string("Planet.") + body + ".";
        if (target.compare(0, prefix.size(), prefix) == 0 && target.size() > prefix.size() &&
            target.find('.', prefix.size()) == std::string::npos) return true;
    }
    return false;
}

} // namespace

ObserverPlaces load_observer_places(const std::filesystem::path& data_directory,
                                   CatalogLoadLimits limits, ObserverPlacesLanguage language) {
    ObserverPlaces result;
    constexpr std::array<const char*, 4> names = {
        "places_jp.dat", "places.dat", "defaultplaces_jp.dat", "defaultplaces.dat"};
    std::array<std::optional<std::size_t>, 4> source_indices;
    for (std::size_t index = 0; index < names.size(); ++index) {
        const auto path = data_directory / names[index];
        std::error_code error;
        const bool exists = std::filesystem::exists(path, error);
        if (!exists && !error) {
            result.missing_files.push_back(names[index]);
            continue;
        }
        source_indices[index] = result.sources.size();
        try {
            if (error) throw CatalogError(path, 0, "cannot inspect place catalog: " + error.message());
            result.sources.push_back(load_plus_place_source(path, limits));
        } catch (const CatalogError& failure) {
            // 存在確認・読取失敗を不存在に変えず、原版と同じ選択先で失敗を報告する。
            result.sources.push_back({path, {}, {}, failure});
            result.warnings.push_back(failure.what());
        }
        const auto& source = result.sources.back();
        if (source.catalog) result.source_place_count += source.catalog->places.size();
    }
    const bool japanese = language == ObserverPlacesLanguage::japanese;
    const auto user = japanese && source_indices[0] ? source_indices[0] : source_indices[1];
    const auto defaults = japanese && source_indices[2] ? source_indices[2] : source_indices[3];
    result.selected_source = user ? user : defaults;
    if (!result.selected_source) return result;
    const auto& source = result.sources[*result.selected_source];
    if (!source.catalog) {
        if (source.error && std::find(result.warnings.begin(), result.warnings.end(), source.error->what()) ==
                            result.warnings.end()) result.warnings.push_back(source.error->what());
        return result;
    }
    std::map<std::string, std::size_t> positions;
    for (std::size_t index = 0; index < source.catalog->places.size(); ++index) {
        const auto& place = source.catalog->places[index];
        const ObserverPlaceOrigin origin{*result.selected_source, index};
        if (!has_canonical_place_id(place.target_name)) {
            result.places.push_back(place);
            result.origins.push_back(origin);
            result.warnings.push_back(source.path.filename().string() + ": unresolved place target: " +
                                      place.target_name);
            continue;
        }
        const auto [position, inserted] = positions.emplace(place.target_name, result.places.size());
        if (inserted) {
            result.places.push_back(place);
            result.origins.push_back(origin);
        } else {
            result.places[position->second] = place;
            result.origins[position->second] = origin;
        }
    }
    return result;
}

bool observer_place_is_earth(const PlaceRecord& place) {
    constexpr char prefix[] = "Planet.Earth.";
    return place.target_name.compare(0, sizeof(prefix) - 1, prefix) == 0 &&
           has_canonical_place_id(place.target_name);
}

bool observer_place_matches(const PlaceRecord& place, double latitude, double longitude) {
    if (!observer_place_is_earth(place) || !std::isfinite(latitude) || !std::isfinite(longitude) ||
        !std::isfinite(place.latitude_degrees) || !std::isfinite(place.longitude_degrees) ||
        std::abs(latitude) > 90 || std::abs(longitude) > 180) return false;
    const auto displayed = [](double value) {
        std::ostringstream text;
        text.imbue(std::locale::classic());
        // JSONの十進数往復で最下位bitが変わっても、UIの同じ12桁表示を同一とする。
        text << std::setprecision(12) << (value == 0 ? 0.0 : value);
        return text.str();
    };
    const auto displayed_longitude = [&](double value) {
        const auto text = displayed(std::remainder(value, 360.0));
        return text == "-180" ? std::string("180") : text;
    };
    return displayed(latitude) == displayed(place.latitude_degrees) &&
        displayed_longitude(longitude) == displayed_longitude(place.longitude_degrees);
}

} // namespace mitaka::gui
