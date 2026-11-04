#pragma once
#import <AppKit/AppKit.h>
#include "small_body_model.hpp"
#include "small_body_display.hpp"
#include "small_body_orbit_model.hpp"
#include "solar_camera.hpp"
#include "renderer_options.hpp"
#include <functional>

namespace mitaka::gui {
struct VisibleSmallBody { std::size_t index; SolarProjection point; };
struct SmallBodyProjectedOrbitSegment { std::size_t index; SolarProjection first, second; };
std::vector<VisibleSmallBody> visible_small_bodies(const SmallBodySnapshot& snapshot,
    const SmallBodyDisplayModel& display, const SolarCamera& camera, NSRect map);
std::optional<std::size_t> pick_small_body(const SmallBodySnapshot& snapshot,
    const SmallBodyDisplayModel& display, const SolarCamera& camera, NSRect map, NSPoint point);
void visit_small_body_orbit_segments(const SmallBodySnapshot& snapshot,
    const SmallBodyDisplayModel& display, const SmallBodyOrbitSnapshot* orbits,
    const SolarCamera& camera, NSRect map,
    const std::function<void(const SmallBodyProjectedOrbitSegment&)>& visitor);
void draw_small_bodies(CGContextRef context, const SmallBodySnapshot& snapshot,
    const SmallBodyDisplayModel& display, const SmallBodyOrbitSnapshot* orbits,
    const SolarCamera& camera, NSRect map, std::optional<std::size_t> selection,
    const RendererDisplayOptions& quality);
}
