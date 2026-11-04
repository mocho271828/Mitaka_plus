#include "sky_catalog_index.hpp"

#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <unordered_set>

using namespace mitaka::gui;

int main() {
    try {
        std::vector<mitaka::EquatorialCoordinates> coordinates;
        for (double ra = 0; ra < 360; ++ra)
            for (double dec = -90; dec <= 90; dec += 10) coordinates.push_back({ra, dec});
        coordinates.push_back({-1, 0});
        coordinates.push_back({721, 0});
        coordinates.push_back({0, 0});
        const SkyCatalogIndex index(coordinates);
        for (const SkyViewport viewport : {SkyViewport{}, {359, 0, 18}, {1, 0, 180},
                                             {180, 89.5, 180}, {180, -89.5, 180}}) {
            std::unordered_set<std::size_t> visible;
            for (const auto& point : index.project(viewport, 1000, 500)) {
                const auto expected = project_sky(coordinates[point.index], viewport, 1000, 500);
                if (!expected || std::hypot(expected->x - point.point.x, expected->y - point.point.y) > 1e-9)
                    throw std::runtime_error("indexed projection differs from direct projection");
                if (!visible.insert(point.index).second) throw std::runtime_error("index returned duplicate record");
            }
            for (std::size_t record = 0; record < coordinates.size(); ++record)
                if (visible.count(record) != project_sky(coordinates[record], viewport, 1000, 500).has_value())
                    throw std::runtime_error("index lost a visible record at seam or pole");
        }
        if (!SkyCatalogIndex{}.project({}, 100, 100).empty()) throw std::runtime_error("empty catalog is not empty");
        bool rejected = false;
        try { SkyCatalogIndex invalid({{std::numeric_limits<double>::quiet_NaN(), 0}}); }
        catch (const std::invalid_argument&) { rejected = true; }
        if (!rejected) throw std::runtime_error("invalid catalog coordinate accepted");
        std::cout << "sky catalog index tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
