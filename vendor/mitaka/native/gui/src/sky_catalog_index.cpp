#include "sky_catalog_index.hpp"

#include <algorithm>
#include <cmath>

namespace mitaka::gui {

SkyCatalogIndex::SkyCatalogIndex(std::vector<EquatorialCoordinates> coordinates)
    : coordinates_(std::move(coordinates)) {
    for (std::size_t index = 0; index < coordinates_.size(); ++index) {
        auto& coordinate = coordinates_[index];
        project_sky(coordinate, {}, 1, 1);
        coordinate.right_ascension_deg = std::fmod(coordinate.right_ascension_deg, 360);
        if (coordinate.right_ascension_deg < 0) coordinate.right_ascension_deg += 360;
        const auto ra_bin = static_cast<std::size_t>(coordinate.right_ascension_deg / 5);
        const auto dec_bin = std::min<std::size_t>(35, static_cast<std::size_t>((coordinate.declination_deg + 90) / 5));
        bins_[dec_bin * 72 + ra_bin].push_back(index);
    }
}

std::vector<ProjectedCatalogPoint> SkyCatalogIndex::project(SkyViewport viewport, double width, double height) const {
    project_sky({0, 0}, viewport, width, height);
    const double center_ra = normalize_sky_viewport(viewport).center_ra_deg;
    std::vector<ProjectedCatalogPoint> result;
    for (std::size_t dec_bin = 0; dec_bin < 36; ++dec_bin) {
        const double declination = -87.5 + dec_bin * 5;
        if (std::abs(declination - viewport.center_dec_deg) > 90 / viewport.zoom + 2.5) continue;
        for (std::size_t ra_bin = 0; ra_bin < 72; ++ra_bin) {
            const double ra_delta = std::fmod(ra_bin * 5 + 2.5 - center_ra + 540, 360) - 180;
            if (std::abs(ra_delta) > 180 / viewport.zoom + 2.5) continue;
            for (const auto index : bins_[dec_bin * 72 + ra_bin]) {
                const auto point = project_sky(coordinates_[index], viewport, width, height);
                if (point) result.push_back({index, *point});
            }
        }
    }
    return result;
}

} // namespace mitaka::gui
