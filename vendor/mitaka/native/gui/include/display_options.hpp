#pragma once

#include <cmath>
#include <stdexcept>

namespace mitaka::gui {

enum class StarMarking { none, binary, exoplanets };

struct PlanetDisplayOptions {
    bool visible = true;
    bool labels = true;
    bool orbits = true;
    bool axes = false;
};

struct StarDisplayOptions {
    bool visible = true;
    bool proper_names = false;
    bool bayer_labels = false;
    bool flamsteed_labels = false;
    bool hip_labels = false;
    StarMarking marking = StarMarking::none;
    bool selected_proper_names_only = false;
    float brightness = 1;
};

struct GridDisplayOptions {
    bool equatorial = false;
    bool ecliptic = false;
    bool galactic = false;
    bool horizontal = false;
    bool circle_scales = true;
    bool square_scales = false;
};

inline void validate_star_display(const StarDisplayOptions& options) {
    if (!std::isfinite(options.brightness) || options.brightness <= 0)
        throw std::invalid_argument("star brightness must be a positive finite float");
    switch (options.marking) {
        case StarMarking::none:
        case StarMarking::binary:
        case StarMarking::exoplanets: return;
    }
    throw std::invalid_argument("invalid star marking mode");
}

} // namespace mitaka::gui
