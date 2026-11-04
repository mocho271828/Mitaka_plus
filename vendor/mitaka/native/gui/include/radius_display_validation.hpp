#pragma once

#include "radius_display.hpp"
#include <initializer_list>

namespace mitaka::gui {

// 保存と UI のどちらからでも、描画で使う派生倍率まで同じ契約を適用する。
inline void validate_radius_display_state(const RadiusDisplayOptions& options, RadiusScaleMode mode) {
    validate_radius_display_options(options);
    validate_radius_scale_mode(mode);
    (void)moon_orbit_display_factor(options);
    for (const auto context : {RadiusDisplayContext::space, RadiusDisplayContext::planetarium}) {
        (void)planet_radius_display_factor(options, context);
        (void)sun_radius_display_factor(options, context);
        (void)moon_radius_display_factor(options, context);
    }
}

} // namespace mitaka::gui
