#pragma once
#import <AppKit/AppKit.h>
#include "satellite_browser_model.hpp"
#include "solar_camera.hpp"
#include "satellite_display.hpp"
#include "satellite_orbit_geometry.hpp"
#include "renderer_options.hpp"

namespace mitaka::gui {
struct VisibleSatellite { std::size_t index; SolarProjection point; };
// display 未指定は全原行を対象にする。App 経路では必ず現在の表示モデルを渡す。
// 不整合な snapshot・表示モデル・描画領域は描画／選択対象を返さない。
std::vector<VisibleSatellite> visible_satellites(const SatelliteSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, const SatelliteDisplayModel* display = nullptr);
std::optional<std::size_t> pick_satellite(const SatelliteSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, NSPoint point, const SatelliteDisplayModel* display = nullptr);
void draw_satellites(CGContextRef context, const SatelliteSnapshot& snapshot,
    const SolarCamera& camera, NSRect map, std::optional<std::size_t> selection,
    const RendererDisplayOptions& quality, const SatelliteDisplayModel* display = nullptr,
    const SatelliteOrbitGeometry* orbits = nullptr);
}
