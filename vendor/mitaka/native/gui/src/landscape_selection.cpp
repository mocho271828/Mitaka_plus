#include "earth_landscapes.hpp"

namespace mitaka::gui {

std::optional<std::size_t> select_earth_landscape(const PlaceDisplayModel& model,
                                                std::string_view identifier) {
    for (const auto& place : model.observer_places().places) {
        if (place.target_name != identifier || !observer_place_is_earth(place)) continue;
        const auto selected = model.find_landscape("Planet.Earth." + place.landscape);
        if (selected) return selected;
        break;
    }
    const auto earth_default = model.find_landscape("Planet.Earth.Default");
    return earth_default ? earth_default : model.find_landscape("Planet.Default");
}

} // namespace mitaka::gui
