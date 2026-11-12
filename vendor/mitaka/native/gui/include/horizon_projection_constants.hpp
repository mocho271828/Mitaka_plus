#pragma once

#include <algorithm>
#include <cmath>

namespace mitaka::gui {
inline constexpr double horizon_minimum_render_fov_deg = 1e-9;
inline double horizon_perspective_scale(double fov_deg) {
    return std::tan(std::max(fov_deg, horizon_minimum_render_fov_deg) * (3.14159265358979323846 / 360));
}
}
