#pragma once

#import "SolarSceneRenderer.h"
#import "GridRenderer.h"

#include <stdexcept>
#include <utility>

// 可視衛星を非表示にしても食計算には衛星が必要なため、所有元を別々に渡す。
// shared_ptr の生成元に可変の別名を残さず、公開中は参照先を変更しない。
struct SolarSceneResources {
    std::shared_ptr<const mitaka::gui::PlanetTextures> textures;
    std::shared_ptr<const mitaka::gui::SmallBodySnapshot> small_bodies;
    std::shared_ptr<const mitaka::gui::SatelliteSnapshot> satellites;
    std::shared_ptr<const mitaka::gui::SpacecraftSnapshot> spacecraft;
    std::shared_ptr<const mitaka::gui::SmallBodyDisplayModel> small_body_display;
    std::shared_ptr<const mitaka::gui::SmallBodyOrbitSnapshot> small_body_orbits;
    std::shared_ptr<const mitaka::gui::SatelliteDisplayModel> satellite_display;
    std::shared_ptr<const mitaka::gui::SatelliteOrbitGeometry> satellite_orbits;
    std::shared_ptr<const mitaka::gui::SatelliteSnapshot> eclipse_satellites;
};

// scene() の返り値は借用 view であり、owner が同じ場所で生存する間だけ有効。
// owner のコピーや移動後は、新しい owner から view を作り直す。
class SolarSceneOwner {
public:
    using TerrainFrames = std::array<std::shared_ptr<const mitaka::gui::TerrainSurfaceSnapshot>, 11>;

    SolarSceneOwner(const SolarScene& scene, SolarSceneResources resources)
        : bodies_(scene.bodies), orbits_(scene.orbits), lunar_orbit_(scene.lunar_orbit), camera_(scene.camera),
          resources_(std::move(resources)), selection_(scene.selection), map_(scene.map),
          backing_scale_(scene.backing_scale), earth_moon_(scene.earth_moon),
          preview_body_(scene.preview_body), surface_body_(scene.surface_body),
          physical_navigation_(scene.physical_navigation), small_body_selection_(scene.small_body_selection),
          planet_display_(scene.planet_display), grid_display_(scene.grid_display),
          grid_cache_(scene.grid_cache ? std::optional<mitaka::gui::GridGeometryCache>(*scene.grid_cache) : std::nullopt),
          renderer_display_(scene.renderer_display), satellite_selection_(scene.satellite_selection),
          spacecraft_selection_(scene.spacecraft_selection), spacecraft_display_(scene.spacecraft_display),
          earth_layers_(scene.earth_layers), atmosphere_(scene.atmosphere), eclipse_options_(scene.eclipse_options),
          julian_date_(scene.julian_date), terrain_(scene.terrain ? *scene.terrain : TerrainFrames{}),
          has_terrain_(scene.terrain != nullptr), terrain_amplification_(scene.terrain_amplification),
          radius_display_(scene.radius_display) {
        require_owner(scene.textures, resources_.textures);
        require_owner(scene.small_bodies, resources_.small_bodies);
        require_owner(scene.satellites, resources_.satellites);
        require_owner(scene.spacecraft, resources_.spacecraft);
        require_owner(scene.small_body_display, resources_.small_body_display);
        require_owner(scene.small_body_orbits, resources_.small_body_orbits);
        require_owner(scene.satellite_display, resources_.satellite_display);
        require_owner(scene.satellite_orbits, resources_.satellite_orbits);
        require_owner(scene.eclipse_satellites, resources_.eclipse_satellites);
    }

    SolarScene scene() const {
        return {bodies_, orbits_, lunar_orbit_, camera_, resources_.textures.get(), selection_, map_,
            backing_scale_, earth_moon_, preview_body_, surface_body_, physical_navigation_,
            resources_.small_bodies.get(), small_body_selection_, planet_display_, grid_display_,
            grid_cache_ ? &*grid_cache_ : nullptr, renderer_display_, resources_.satellites.get(),
            satellite_selection_, resources_.spacecraft.get(), spacecraft_selection_, spacecraft_display_,
            resources_.small_body_display.get(), resources_.small_body_orbits.get(),
            resources_.satellite_display.get(), resources_.satellite_orbits.get(), earth_layers_, atmosphere_,
            eclipse_options_, julian_date_, resources_.eclipse_satellites.get(), has_terrain_ ? &terrain_ : nullptr,
            terrain_amplification_, radius_display_};
    }

    void set_terrain(TerrainFrames terrain) {
        terrain_ = std::move(terrain);
        has_terrain_ = true;
    }

private:
    template<typename T>
    static void require_owner(const T* pointer, const std::shared_ptr<const T>& owner) {
        if (pointer != owner.get()) throw std::invalid_argument("SolarScene resource owner does not match scene");
    }

    mitaka::gui::SolarBodies bodies_;
    mitaka::gui::SolarOrbits orbits_;
    std::vector<mitaka::Vec3> lunar_orbit_;
    mitaka::gui::SolarCamera camera_;
    SolarSceneResources resources_;
    std::optional<std::size_t> selection_;
    NSRect map_;
    double backing_scale_;
    bool earth_moon_;
    std::optional<std::size_t> preview_body_;
    std::optional<std::size_t> surface_body_;
    bool physical_navigation_;
    std::optional<std::size_t> small_body_selection_;
    mitaka::gui::PlanetDisplayOptions planet_display_;
    mitaka::gui::GridDisplayOptions grid_display_;
    std::optional<mitaka::gui::GridGeometryCache> grid_cache_;
    mitaka::gui::RendererDisplayOptions renderer_display_;
    std::optional<std::size_t> satellite_selection_;
    std::optional<std::size_t> spacecraft_selection_;
    mitaka::gui::SpacecraftDisplayOptions spacecraft_display_;
    mitaka::gui::EarthLayerOptions earth_layers_;
    mitaka::gui::AtmosphereDisplayOptions atmosphere_;
    mitaka::gui::EclipseDisplayOptions eclipse_options_;
    double julian_date_;
    TerrainFrames terrain_;
    bool has_terrain_;
    mitaka::gui::TerrainAmplification terrain_amplification_;
    mitaka::gui::RadiusDisplayOptions radius_display_;
};
