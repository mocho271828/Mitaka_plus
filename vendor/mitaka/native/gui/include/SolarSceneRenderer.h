#pragma once

#import <AppKit/AppKit.h>
#include "sky_model.hpp"
#include "solar_camera.hpp"
#include "planet_textures.hpp"
#include "small_body_model.hpp"
#include "display_options.hpp"
#include "radius_display.hpp"
#include "renderer_options.hpp"
#include "atmosphere_renderer.hpp"
#include "terrain_snapshot.hpp"
#include "terrain_amplification.hpp"
#import "SpacecraftRenderer.h"
namespace mitaka::gui { class GridGeometryCache; struct SatelliteSnapshot; }
namespace mitaka::gui { class SmallBodyDisplayModel; struct SmallBodyOrbitSnapshot; class SatelliteDisplayModel; struct SatelliteOrbitGeometry; }

// 描画とクリック判定が同じ投影・半径・可視範囲を参照するための、そのフレームの状態。
struct SolarScene {
    const mitaka::gui::SolarBodies& bodies;
    const mitaka::gui::SolarOrbits& orbits;
    const std::vector<mitaka::Vec3>& lunar_orbit;
    const mitaka::gui::SolarCamera& camera;
    const mitaka::gui::PlanetTextures* textures;
    std::optional<std::size_t> selection;
    NSRect map;
    double backing_scale;
    bool earth_moon;
    std::optional<std::size_t> preview_body;
    std::optional<std::size_t> surface_body;
    bool physical_navigation = false;
    const mitaka::gui::SmallBodySnapshot* small_bodies = nullptr;
    std::optional<std::size_t> small_body_selection = std::nullopt;
    mitaka::gui::PlanetDisplayOptions planet_display{};
    mitaka::gui::GridDisplayOptions grid_display{};
    const mitaka::gui::GridGeometryCache* grid_cache = nullptr;
    mitaka::gui::RendererDisplayOptions renderer_display{};
    const mitaka::gui::SatelliteSnapshot* satellites = nullptr;
    std::optional<std::size_t> satellite_selection = std::nullopt;
    const mitaka::gui::SpacecraftSnapshot* spacecraft = nullptr;
    std::optional<std::size_t> spacecraft_selection = std::nullopt;
    mitaka::gui::SpacecraftDisplayOptions spacecraft_display{};
    const mitaka::gui::SmallBodyDisplayModel* small_body_display = nullptr;
    const mitaka::gui::SmallBodyOrbitSnapshot* small_body_orbits = nullptr;
    const mitaka::gui::SatelliteDisplayModel* satellite_display = nullptr;
    const mitaka::gui::SatelliteOrbitGeometry* satellite_orbits = nullptr;
    mitaka::gui::EarthLayerOptions earth_layers{};
    mitaka::gui::AtmosphereDisplayOptions atmosphere{};
    mitaka::gui::EclipseDisplayOptions eclipse_options{};
    double julian_date = 2451545.0;
    // 衛星マーカーの非表示でも物理的な遮蔽は維持する。
    const mitaka::gui::SatelliteSnapshot* eclipse_satellites = nullptr;
    const std::array<std::shared_ptr<const mitaka::gui::TerrainSurfaceSnapshot>, 11>* terrain = nullptr;
    mitaka::gui::TerrainAmplification terrain_amplification = mitaka::gui::TerrainAmplification::x1;
    mitaka::gui::RadiusDisplayOptions radius_display{};
};
struct VisibleSolarBody { std::size_t index; mitaka::gui::SolarProjection point; };

mitaka::Vec3 solar_display_position(const SolarScene& scene, std::size_t index);
double solar_marker_radius(mitaka::gui::Body body);
double solar_scene_radius(const SolarScene& scene, std::size_t index, double depth);
std::vector<VisibleSolarBody> visible_solar_bodies(const SolarScene& scene);
std::optional<std::size_t> pick_solar_body(const SolarScene& scene, NSPoint point);
std::vector<std::string> draw_solar_scene(CGContextRef context, const SolarScene& scene);

void draw_solar_grid(CGContextRef context, const SolarScene& scene);
std::optional<std::array<mitaka::Vec3, 2>> solar_axis_segment(const SolarScene& scene, std::size_t index);

// 描画画像と非同期地形の寸法・物理幾何を一つの要求へ揃える。
std::array<std::size_t, 2> solar_surface_raster_size(NSSize size);
std::optional<mitaka::gui::TerrainSurfaceRequest> solar_terrain_request(
    const SolarScene& scene, std::size_t index, const std::filesystem::path& data_directory);
const mitaka::gui::TerrainSurfaceFrame* solar_terrain_frame(const SolarScene& scene, std::size_t index);
