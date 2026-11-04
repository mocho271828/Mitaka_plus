#include "earth_layers.hpp"
#include "planet_surface.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
using RGB = std::array<std::uint8_t, 3>;
std::size_t checks = 0;
void check(bool result, const char* message) {
    ++checks;
    if (!result) throw std::runtime_error(message);
}
void near(double value, double expected, const char* message) {
    check(std::abs(value - expected) < 1e-12, message);
}
template<class F> void rejects(F operation) {
    try { operation(); } catch (const std::invalid_argument&) { ++checks; return; }
    throw std::runtime_error("expected invalid_argument");
}
TextureImage texture(RGB color) { return {1, 1, {color[0], color[1], color[2], 0}}; }
RGB pixel(const TextureImage& image, std::size_t x = 0, std::size_t y = 0) {
    const auto n = 4 * (y * image.width + x);
    return {image.rgba[n], image.rgba[n + 1], image.rgba[n + 2]};
}
std::uint8_t alpha(const TextureImage& image, std::size_t x, std::size_t y) {
    return image.rgba[4 * (y * image.width + x) + 3];
}
EarthLayerView view(double distance = 3) { return {{distance, 0, 0}, {-1, 0, 0}, 1, 1}; }
SolarCamera camera(double distance = 3) { return {{1, 0, 0}, 0, 0, distance}; }
void test_formula() {
    check(EarthLayerOptions{}.clouds && !EarthLayerOptions{}.city_lights, "normal-mode defaults");
    near(earth_cloud_radius_factor(1), 1 + 10.0 / 6378.1, "10 km cloud height");
    near(earth_cloud_radius_factor(0), 1, "zero topography scale");
    near(earth_cloud_radius_factor(2), 1 + 20.0 / 6378.1, "cloud topography scaling");
    near(earth_night_gain(view(), true), 1, "night camera gain");
    auto v = view(); v.earth_to_sun_ecliptic_unit = {1, 0, 0};
    near(earth_night_gain(v, true), 0, "day camera gain");
    v.earth_to_sun_ecliptic_unit = {0, 1, 0};
    near(earth_night_gain(v, true), 0, "terminator camera gain");
    near(earth_night_gain(view(1), false), .3, "city off near-surface gain");
    near(earth_night_gain(view(1.85), false), .15, "city off altitude falloff");
    near(earth_night_gain(view(2.7), false), 0, "city off cutoff");
    near(earth_night_gain(view(10), false), 0, "city off distant clamp");
    check(earth_night_gain(view(.01), false) <= 1, "inside base gain remains bounded");
    near(earth_night_brightness({1, 0, 0}, {-1, 0, 0}, .3), .3, "inverted night normal");
    near(earth_night_brightness({1, 0, 0}, {1, 0, 0}, 1), 0, "no day night lights");
    near(earth_cloud_brightness({1, 0, 0}, {-1, 0, 0}), .03, "cloud normal ambient");
    near(earth_cloud_brightness({1, 0, 0}, {1, 0, 0}), 1, "cloud diffuse clamps");
    check(earth_add_rgb({250, 40, 0}, {20, 10, 255}) == std::array<double, 3>{255, 50, 255}, "additive RGB clamp");
    for (double invalid : {-1., std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()})
        rejects([&] { (void)earth_cloud_radius_factor(invalid); });
    rejects([&] { (void)earth_night_brightness({1, 0, 0}, {-1, 0, 0}, 2); });
    rejects([&] { (void)earth_cloud_brightness({2, 0, 0}, {-1, 0, 0}); });
    rejects([&] { (void)earth_add_rgb({0, -1, 0}, {0, 0, 0}); });
    rejects([&] { (void)earth_add_rgb({0, 0, 0}, {0, std::numeric_limits<double>::quiet_NaN(), 0}); });
    for (auto invalid : {EarthLayerView{{0, 0, 0}, {-1, 0, 0}, 1},
                         EarthLayerView{{3, 0, 0}, {-1, 0, 0}, 0},
                         EarthLayerView{{3, 0, 0}, {0, 0, 0}, 1},
                         EarthLayerView{{3, 0, 0}, {-1, 0, 0}, 1, -1},
                         EarthLayerView{{1e308, 1e308, 1e308}, {-1, 0, 0}, 1e-308}})
        rejects([&] { validate_earth_layer_view(invalid); });
}
void test_three_paths() {
    const auto base = texture({100, 120, 200});
    EarthLayerAssets assets{texture({100, 200, 50}), texture({30, 40, 250}), {}};
    EarthLayerBinding binding{assets, {true, true}, view()};
    TextureImage additive;
    const auto schematic = render_planet_surface(base, camera(), {1, 0, 0}, {}, 1, false, .5, &binding, &additive);
    check(pixel(schematic) == RGB{60, 76, 255}, "night layer is additive and clamps");
    check(pixel(additive) == RGB{3, 6, 2}, "cloud input alpha does not attenuate RGB");
    check(alpha(schematic, 0, 0) == 255 && alpha(additive, 0, 0) == 255, "separate opaque/additive outputs");
    TextureImage view_add, scene_add;
    const auto physical = render_surface_view(base, camera(), {1, 0, 0}, {}, 1, 1, 1, .5, &binding, &view_add);
    const auto scene = render_surface_scene({{base, {1, 0, 0}, {}, 1, false, .5, &binding}}, camera(), 1, 1, &scene_add);
    check(schematic.rgba == physical.rgba && physical.rgba == scene.rgba, "three paths share night compositing");
    check(additive.rgba == view_add.rgba && view_add.rgba == scene_add.rgba, "three paths share cloud compositing");
    binding.options = {false, false};
    const auto off = render_planet_surface(base, camera(), {1, 0, 0}, {}, 1, false, .5, &binding, &additive);
    check(off.rgba == render_planet_surface(base, camera(), {1, 0, 0}, {}, 1).rgba, "distant disabled layers preserve base");
    check(std::all_of(additive.rgba.begin(), additive.rgba.end(), [](auto v) { return v == 0; }), "disabled cloud output clears");
    binding.view = view(1.85);
    check(pixel(render_surface_view(base, camera(1.85), {1, 0, 0}, {}, 1, 1, 1, .5, &binding))
          == RGB{35, 42, 98}, "city OFF still shows weak nearby night lights");
    EarthLayerAssets missing;
    EarthLayerBinding missing_binding{missing, {}, view()};
    check(render_planet_surface(base, camera(), {1, 0, 0}, {}, 17, false, .5, &missing_binding).rgba
          == render_planet_surface(base, camera(), {1, 0, 0}, {}, 17).rgba, "missing layers preserve base without output requirement");
    binding.options = {true, true}; binding.view = view();
    rejects([&] { (void)render_planet_surface(base, camera(), {1, 0, 0}, {}, 1, false, .5, &binding); });
    rejects([&] { (void)render_surface_view(base, camera(), {1, 0, 0}, {}, 1, 1, 1, .5, &binding); });
    binding.view.earth_to_sun_ecliptic_unit = {1, 0, 0};
    SolarCamera day{{-1, 0, 0}, 0, 0, 3};
    check(pixel(render_planet_surface(base, day, {-1, 0, 0}, {}, 1, false, .5, &binding, &additive)) == RGB{100, 120, 200}, "day has no night lights");
    check(pixel(additive) == RGB{100, 200, 50}, "day cloud brightness");
}
void test_cloud_shell_and_depth() {
    const auto base = texture({50, 50, 50});
    EarthLayerAssets assets{texture({100, 100, 100}), {}, {}};
    EarthLayerBinding binding{assets, {true, false}, view()};
    const double factor = earth_cloud_radius_factor(1);
    near(earth_layer_extent(binding), factor, "schematic outer extent");
    for (double distance : {std::nextafter(factor, 0.), factor}) {
        binding.view = view(distance);
        near(earth_layer_extent(binding), 1, "cloud culled on or inside shell");
        TextureImage additive;
        (void)render_surface_view(base, camera(distance), {1, 0, 0}, {}, 1, 1, 1, .5, &binding, &additive);
        check(alpha(additive, 0, 0) == 0, "inside shell emits no cloud");
    }
    binding.view = view(std::nextafter(factor, 2.));
    TextureImage additive;
    (void)render_surface_view(base, camera(binding.view.earth_to_camera_ecliptic_au.x), {1, 0, 0}, {}, 1, 1, 1, .5, &binding, &additive);
    check(alpha(additive, 0, 0) == 255, "immediately outside shell emits cloud");
    binding.view = view(); binding.view.topography_scale = 100;
    const auto disk = render_planet_surface(base, camera(), {1, 0, 0}, {}, 101, false, .5, &binding, &additive);
    bool found_shell = false;
    for (std::size_t y = 0; y < 101; ++y) for (std::size_t x = 0; x < 101; ++x)
        if (alpha(additive, x, y) && !alpha(disk, x, y)) found_shell = true;
    check(found_shell, "schematic shell extends beyond opaque base without hiding background");
    binding.view.topography_scale = 1;
    const auto obstacle = texture({220, 0, 0});
    SurfaceSphere earth{base, {1, 0, 0}, {}, 1, false, .5, &binding};
    SurfaceSphere foreground{obstacle, {2.5, 0, 0}, {}, .25, true};
    TextureImage reverse_add;
    const auto front = render_surface_scene({earth, foreground}, camera(), 3, 3, &additive);
    const auto reverse = render_surface_scene({foreground, earth}, camera(), 3, 3, &reverse_add);
    check(front.rgba == reverse.rgba && additive.rgba == reverse_add.rgba, "opaque/cloud occlusion independent of body order");
    check(pixel(front, 1, 1) == RGB{220, 0, 0} && alpha(additive, 1, 1) == 0, "foreground body occludes cloud");
    SurfaceSphere between{obstacle, {2.0007, 0, 0}, {}, .0002, true};
    const auto under_cloud = render_surface_scene({earth, between}, camera(), 1, 1, &additive);
    check(pixel(under_cloud) == RGB{220, 0, 0} && pixel(additive) == RGB{3, 3, 3}, "cloud adds over nearer-than-surface opaque object");
    binding.view.topography_scale = 0;
    (void)render_surface_scene({earth}, camera(), 1, 1, &additive);
    check(alpha(additive, 0, 0) == 255, "zero-height cloud preserves equal-depth pass");
}
void test_validation_atomicity() {
    const auto base = texture({100, 100, 100});
    EarthLayerAssets assets{texture({100, 100, 100}), {}, {}};
    EarthLayerBinding binding{assets, {}, view()};
    TextureImage output = texture({7, 8, 9});
    const auto unchanged = output.rgba;
    const auto render = [&] { (void)render_surface_view(base, camera(), {1, 0, 0}, {}, 1, 2, 2, .5, &binding, &output); };
    binding.view.display_radius_au = 2; rejects(render);
    binding.view = view(); binding.view.earth_to_camera_ecliptic_au.x = 4; rejects(render);
    binding.view = view(); binding.view.earth_to_sun_ecliptic_unit = {1, 0, 0}; rejects(render);
    binding.view = view(); assets.clouds->rgba.clear(); rejects(render);
    assets.clouds = texture({100, 100, 100});
    rejects([&] { (void)render_surface_scene({{base, {1, 0, 0}, {}, 1, false, .5, &binding},
          {base, {0, 0, 0}, {}, -1}}, camera(), 2, 2, &output); });
    rejects([&] { (void)render_planet_surface(base, camera(), {1, 0, 0}, {}, 1, true, .5, &binding, &output); });
    check(output.width == 1 && output.height == 1 && output.rgba == unchanged, "all invalid inputs leave additive output unchanged");
}
void test_uv_rotation() {
    const auto black = texture({0, 0, 0});
    TextureImage stripes{4, 1, {100, 0, 0, 0, 0, 100, 0, 0, 0, 0, 100, 0, 100, 100, 0, 0}};
    EarthLayerAssets assets{{}, stripes, {}};
    EarthLayerBinding binding{assets, {false, true}, view()};
    const auto regular = render_planet_surface(black, camera(), {1, 0, 0}, {}, 1, false, .5, &binding);
    check(pixel(regular) == RGB{0, 50, 50}, "night UV uses base offset without double rotation");
    BodyOrientation rotated{{-1, 0, 0}, {0, -1, 0}, {0, 0, 1}};
    const auto seam = render_planet_surface(black, camera(), {1, 0, 0}, rotated, 1, false, .5, &binding);
    check(pixel(seam) == RGB{100, 50, 0}, "night longitude wrap follows body rotation");
    check(seam.rgba == render_surface_view(black, camera(), {1, 0, 0}, rotated, 1, 1, 1, .5, &binding).rgba, "physical night UV matches schematic");
}
} // namespace
int main() {
    try {
        test_formula(); test_three_paths(); test_cloud_shell_and_depth(); test_validation_atomicity(); test_uv_rotation();
        std::cout << "Earth layer tests passed: " << checks << " checks\n";
    } catch (const std::exception& error) { std::cerr << "Earth layer tests failed: " << error.what() << '\n'; return 1; }
}
