#pragma once

#include <stdexcept>

namespace mitaka::gui {

// 旧 Plus の Lua 値は実倍率ではなく、1 から始まる段階番号。
enum class TerrainAmplification { x1 = 1, x2 = 2, x5 = 3, x10 = 4, x20 = 5 };

inline TerrainAmplification terrain_amplification_from_lua(double value) {
    if (value == 1) return TerrainAmplification::x1;
    if (value == 2) return TerrainAmplification::x2;
    if (value == 3) return TerrainAmplification::x5;
    if (value == 4) return TerrainAmplification::x10;
    if (value == 5) return TerrainAmplification::x20;
    throw std::invalid_argument("Planets.topoAmplification must be an integer from 1 to 5");
}

inline double terrain_amplification_factor(TerrainAmplification mode) {
    switch (mode) {
        case TerrainAmplification::x1: return 1;
        case TerrainAmplification::x2: return 2;
        case TerrainAmplification::x5: return 5;
        case TerrainAmplification::x10: return 10;
        case TerrainAmplification::x20: return 20;
    }
    throw std::invalid_argument("invalid terrain amplification mode");
}

inline void validate_terrain_amplification(TerrainAmplification mode) {
    (void)terrain_amplification_factor(mode);
}

} // namespace mitaka::gui
