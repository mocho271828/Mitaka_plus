#import "SolarSceneRenderer.h"
#import "SolarSceneOwner.h"
#include "satellite_browser_model.hpp"
#include "surface_navigation.hpp"
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
unsigned checks = 0;
void check(bool value, const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
struct Fixture {
    SolarBodies bodies{};
    SolarOrbits orbits{};
    std::vector<Vec3> lunar;
    PlanetTextures textures;
    SolarCamera camera{{1, 0, 0}, 180, 0, 3 * radius()};
    std::array<std::shared_ptr<const TerrainSurfaceSnapshot>, 11> snapshots{};
    SolarScene scene{bodies, orbits, lunar, camera, &textures, {}, NSMakeRect(0, 0, 81, 81), 1, false, {}, {}};
    static double radius() { return surface_body_info(3).radius_km / astronomical_unit_km; }
    Fixture() {
        const std::array<Body, 11> ids{Body::sun, Body::mercury, Body::venus, Body::earth, Body::mars,
            Body::jupiter, Body::saturn, Body::uranus, Body::neptune, Body::pluto, Body::moon};
        for (std::size_t i = 0; i < bodies.size(); ++i) {
            bodies[i].id = ids[i];
            bodies[i].position_au = {1, 100 + double(i), 0};
            textures.images[i] = TextureImage{1, 1, {200, 200, 200, 255}};
        }
        bodies[0].position_au = {0, 0, 0};
        bodies[3].position_au = {1, 0, 0};
        scene.physical_navigation = true;
        scene.planet_display = {true, false, false, false};
        scene.grid_display.circle_scales = false;
        scene.earth_layers = {false, false};
        scene.atmosphere.mode = AtmosphereMode::none;
        scene.eclipse_options = {false, false, false, false};
        scene.terrain = &snapshots;
    }
    std::shared_ptr<TerrainSurfaceSnapshot> snapshot(std::size_t index) {
        auto value = std::make_shared<TerrainSurfaceSnapshot>();
        value->request = *solar_terrain_request(scene, index, "/selected/local/data");
        value->status = TerrainSnapshotStatus::ready;
        value->frame.mode = TerrainSurfaceMode::none;
        value->frame.width = value->request.width;
        value->frame.height = value->request.height;
        snapshots[index] = value;
        return value;
    }
};
unsigned center(const SolarScene& scene) {
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:81 pixelsHigh:81 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
        colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:324 bitsPerPixel:32];
    if (!bitmap) throw std::runtime_error("bitmap allocation failed");
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    const auto context = NSGraphicsContext.currentContext.CGContext;
    CGContextSetRGBFillColor(context, 0, 0, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, 81, 81));
    draw_solar_scene(context, scene);
    [NSGraphicsContext restoreGraphicsState];
    return bitmap.bitmapData[(81 * 40 + 40) * 4];
}
void requests() {
    Fixture f;
    const std::array<double, 5> factors{1, 2, 5, 10, 20};
    for (std::size_t i = 0; i < factors.size(); ++i) {
        f.scene.terrain_amplification = terrain_amplification_from_lua(double(i + 1));
        check(terrain_amplification_factor(f.scene.terrain_amplification) == factors[i], "amplification mapping");
        check(solar_terrain_request(f.scene, 3, "/selected/local/data")->elevation_factor == factors[i],
            "terrain request amplification");
    }
    for (const auto value : {0.0, 1.5, 6.0, std::numeric_limits<double>::infinity(),
                             std::numeric_limits<double>::quiet_NaN()}) {
        bool invalid = false;
        try { (void)terrain_amplification_from_lua(value); }
        catch (const std::invalid_argument&) { invalid = true; }
        check(invalid, "invalid amplification accepted");
    }
    bool invalid_mode = false;
    try { (void)terrain_amplification_factor(static_cast<TerrainAmplification>(0)); }
    catch (const std::invalid_argument&) { invalid_mode = true; }
    check(invalid_mode, "invalid amplification mode accepted");
    for (std::size_t i = 0; i < 11; ++i) {
        const auto request = solar_terrain_request(f.scene, i, "/selected/local/data");
        check(bool(request) == (i == 1 || i == 3 || i == 4 || i == 10), "terrain body mapping");
        if (request) {
            check(request->display_radius_au == surface_body_info(i).radius_km / astronomical_unit_km,
                "physical radius changed");
            check(request->data_directory == "/selected/local/data", "local source replaced");
        }
    }
    check(solar_surface_raster_size(NSMakeSize(1800, 900)) == std::array<std::size_t, 2>{800, 400},
        "surface viewport budget");
    f.scene.physical_navigation = false;
    check(!solar_terrain_request(f.scene, 3, "/selected/local/data"), "schematic requested terrain");
    f.scene.earth_moon = true;
    check(solar_terrain_request(f.scene, 3, "/selected/local/data").has_value(), "Earth Moon missing Earth");
    check(!solar_terrain_request(f.scene, 4, "/selected/local/data"), "Earth Moon requested Mars");
    f.scene.planet_display.visible = false;
    check(!solar_terrain_request(f.scene, 3, "/selected/local/data"), "hidden planet requested terrain");
    bool rejected = false;
    try { (void)solar_surface_raster_size(NSMakeSize(std::numeric_limits<double>::quiet_NaN(), 80)); }
    catch (const std::invalid_argument&) { rejected = true; }
    check(rejected, "invalid viewport accepted");
}
void snapshot_guards() {
    Fixture f;
    const auto bright = center(f.scene);
    check(bright > 150, "fixture has no lit Earth");
    const auto snapshot = f.snapshot(3);
    check(solar_terrain_frame(f.scene, 3) == &snapshot->frame, "matching terrain missing");
    check(center(f.scene) == 0, "none terrain replaced with datum sphere");
    f.scene.julian_date += 1;
    check(!solar_terrain_frame(f.scene, 3) && center(f.scene) == bright, "old date terrain rendered");
    f.scene.julian_date -= 1;
    f.camera.yaw_deg += 1;
    check(!solar_terrain_frame(f.scene, 3), "old camera terrain rendered");
    f.camera.yaw_deg -= 1;
    f.scene.map.size.width += 1;
    check(!solar_terrain_frame(f.scene, 3), "old viewport terrain rendered");
    f.scene.map.size.width -= 1;
    f.bodies[3].position_au.x += 0.001;
    check(!solar_terrain_frame(f.scene, 3), "old center terrain rendered");
    f.bodies[3].position_au.x = 1;
    check(solar_terrain_frame(f.scene, 3) != nullptr, "matching snapshot not restored");
    f.scene.terrain_amplification = TerrainAmplification::x2;
    check(!solar_terrain_frame(f.scene, 3), "old amplification terrain rendered");
    f.scene.terrain_amplification = TerrainAmplification::x1;
    snapshot->status = TerrainSnapshotStatus::failed;
    check(!solar_terrain_frame(f.scene, 3), "failed terrain rendered");
    snapshot->status = TerrainSnapshotStatus::unavailable;
    check(!solar_terrain_frame(f.scene, 3), "missing terrain rendered");
}
void interior_selection() {
    Fixture f;
    f.camera.distance_au = .999 * Fixture::radius();
    const NSPoint pixel = NSMakePoint(40.5, 40.5);
    (void)visible_solar_bodies(f.scene);
    check(pick_solar_body(f.scene, pixel) == std::optional<std::size_t>(3), "opaque fallback inside sphere was not selected");
    auto snapshot=f.snapshot(3);
    snapshot->frame.mode=TerrainSurfaceMode::terrain;
    snapshot->frame.samples.resize(81*81);
    auto& sample=snapshot->frame.samples[40*81+40];
    sample.distance_au=1e-8;
    sample.normal_local={1,0,0};
    check(pick_solar_body(f.scene, pixel)==std::optional<std::size_t>(3), "visible inside-datum terrain cannot be picked");
    sample.distance_au=std::numeric_limits<double>::infinity();
    check(pick_solar_body(f.scene, pixel)!=std::optional<std::size_t>(3), "uncovered inside-datum pixel selected terrain");
    snapshot->status=TerrainSnapshotStatus::failed;
    check(pick_solar_body(f.scene, pixel)==std::optional<std::size_t>(3), "failed snapshot did not select opaque fallback");
}
void owned_scene_lifetime() {
    std::optional<SolarSceneOwner> stored;
    std::weak_ptr<const PlanetTextures> weak_textures;
    std::weak_ptr<const SatelliteSnapshot> weak_eclipse;
    std::weak_ptr<const TerrainSurfaceSnapshot> weak_terrain;
    {
        Fixture f;
        auto textures = std::make_shared<const PlanetTextures>(f.textures);
        auto eclipse = std::make_shared<const SatelliteSnapshot>();
        auto terrain = f.snapshot(3);
        GridGeometryCache grid;
        grid.set_observation({35, 139}, 2451545.0);
        // Exercise copying of an already populated lazy grid, too.
        (void)grid.grid(GridCoordinateSystem::horizontal);
        f.scene.textures = textures.get();
        f.scene.grid_cache = &grid;
        f.scene.satellites = nullptr;
        f.scene.eclipse_satellites = eclipse.get();
        SolarSceneResources resources;
        resources.textures = textures;
        resources.eclipse_satellites = eclipse;
        weak_textures = textures;
        weak_eclipse = eclipse;
        weak_terrain = terrain;
        stored.emplace(f.scene, resources);
        const auto before = stored->scene();
        const auto original = before.grid_cache->frame().to_equatorial({0, 0});
        f.camera.yaw_deg = 25;
        f.bodies[3].position_au.x = 7;
        f.snapshots[3].reset();
        grid.set_observation({0, 0}, 2451546.0);
        const auto after = stored->scene();
        const auto retained = after.grid_cache->frame().to_equatorial({0, 0});
        check(after.camera.yaw_deg == 180 && after.bodies[3].position_au.x == 1, "scene values alias live input");
        check(original.right_ascension_deg == retained.right_ascension_deg &&
              original.declination_deg == retained.declination_deg,
            "scene grid follows live cache");
        check(after.satellites == nullptr && after.eclipse_satellites == eclipse.get(),
            "hidden satellite lost eclipse snapshot");
        check((*after.terrain)[3] == terrain, "scene terrain array aliases live input");
        bool rejected = false;
        try { (void)SolarSceneOwner(f.scene, {}); }
        catch (const std::invalid_argument&) { rejected = true; }
        check(rejected, "unowned scene pointer accepted");
    }
    check(!weak_textures.expired() && !weak_eclipse.expired() && !weak_terrain.expired(),
        "scene resource destroyed with source");
    SolarSceneOwner copied = *stored;
    SolarSceneOwner moved = std::move(copied);
    stored.reset();
    const auto moved_view = moved.scene();
    check(moved_view.bodies[3].position_au.x == 1 && moved_view.camera.yaw_deg == 180,
        "owner copy or move retained old references");
    check(moved_view.textures && moved_view.eclipse_satellites && (*moved_view.terrain)[3],
        "owner copy or move lost owned resources");
    SolarSceneOwner::TerrainFrames replacement{};
    moved.set_terrain(replacement);
    check(!(*moved.scene().terrain)[3], "terrain setter did not replace old array");
    check(weak_terrain.expired(), "replaced terrain retained after previous owner destruction");
}
}
int main(int argc, char** argv) {
    @autoreleasepool {
        try {
            if (argc == 2 && std::string(argv[1]) == "--pick-only") { interior_selection(); return 0; }
            interior_selection();
            requests();
            snapshot_guards();
            owned_scene_lifetime();
            std::cout << "solar terrain: " << checks << " checks PASS\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "FAIL: " << error.what() << '\n';
            return 1;
        }
    }
}
