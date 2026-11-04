#include "planet_surface.hpp"

#include <array>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
using RGB = std::array<std::uint8_t, 3>;

void check(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}

TextureImage texture(std::size_t width, std::size_t height, const std::vector<RGB>& colors) {
    check(colors.size() == width * height, "invalid test texture");
    TextureImage result{width, height, {}};
    for (const auto& color : colors) {
        result.rgba.insert(result.rgba.end(), color.begin(), color.end());
        result.rgba.push_back(0); // 入力alphaを日照や円盤のalphaへ混ぜない契約も検証する。
    }
    return result;
}

RGB pixel(const TextureImage& image, std::size_t x = 0, std::size_t y = 0) {
    const auto offset = (y * image.width + x) * 4;
    return {image.rgba[offset], image.rgba[offset + 1], image.rgba[offset + 2]};
}

std::uint8_t alpha(const TextureImage& image, std::size_t x, std::size_t y) {
    return image.rgba[(y * image.width + x) * 4 + 3];
}

template<typename Function> void rejects(Function operation) {
    try { operation(); } catch (const std::invalid_argument&) { return; }
    throw std::runtime_error("expected invalid_argument");
}

void test_longitude_and_camera() {
    const std::vector<RGB> colors{{255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0}};
    const auto map = texture(4, 1, colors);
    SolarCamera camera{{0, 0, 0}, 0, 0, 10};
    for (std::size_t column = 0; column < colors.size(); ++column) {
        camera.yaw_deg = -135 + 90 * double(column);
        check(pixel(render_planet_surface(map, camera, {}, {}, 1, true)) == colors[column],
              "longitude or camera direction reversed");
    }
    camera.yaw_deg = 180;
    const auto east_seam = render_planet_surface(map, camera, {}, {}, 1, true);
    check(pixel(east_seam) == RGB{255, 128, 0}, "longitude must wrap across first and last texels");
    camera.yaw_deg = -180;
    check(pixel(render_planet_surface(map, camera, {}, {}, 1, true)) == pixel(east_seam),
          "longitude seam must be continuous");
    camera.yaw_deg = -90;
    check(pixel(render_planet_surface(map, camera, {}, {}, 1, true)) == RGB{128, 128, 0},
          "longitude interpolation must blend neighboring texels");
    camera.yaw_deg = -135;
    check(pixel(render_planet_surface(map, camera, {}, {}, 1, true, 0)) == colors[2],
          "Mars longitude origin must differ by half a turn");
    check(pixel(render_planet_surface(map, camera, {}, {}, 1, true, 1.5)) == colors[0],
          "longitude offset must wrap whole turns");
}

void test_latitude() {
    const auto map = texture(1, 2, {{255, 0, 0}, {0, 0, 255}});
    SolarCamera camera{{0, 0, 0}, 0, 89, 10};
    check(pixel(render_planet_surface(map, camera, {}, {}, 1, true)) == RGB{255, 0, 0},
          "north latitude must clamp to first row");
    camera.pitch_deg = -89;
    check(pixel(render_planet_surface(map, camera, {}, {}, 1, true)) == RGB{0, 0, 255},
          "south latitude must clamp to last row");
    camera.pitch_deg = 0;
    const auto disk = render_planet_surface(map, camera, {}, {}, 5, true);
    check(pixel(disk, 2, 0) == RGB{255, 0, 0} && pixel(disk, 2, 4) == RGB{0, 0, 255},
          "north must appear above south for equatorial view");
    check(pixel(disk, 2, 2) == RGB{128, 0, 128}, "latitude interpolation at equator");

    const auto map2d = texture(2, 2, {{100, 0, 0}, {0, 100, 0}, {0, 0, 100}, {100, 100, 100}});
    check(pixel(render_planet_surface(map2d, camera, {}, {}, 1, true)) == RGB{50, 50, 50},
          "bilinear interpolation must use all four texels");
}

void test_lighting_and_disk() {
    const auto map = texture(1, 1, {{100, 100, 100}});
    SolarCamera camera{{0, 0, 0}, 0, 0, 10};
    check(pixel(render_planet_surface(map, camera, {-1, 0, 0}, {}, 1)) == RGB{100, 100, 100},
          "sunward face must receive full light");
    for (const Vec3 body : {Vec3{1, 0, 0}, Vec3{0, 1, 0}, Vec3{1e308, 0, 0}, Vec3{1e-308, 0, 0}})
        check(pixel(render_planet_surface(map, camera, body, {}, 1)) == RGB{30, 30, 30},
              "night and terminator must retain ambient light");
    check(pixel(render_planet_surface(map, camera, {}, {}, 1, true)) == RGB{100, 100, 100},
          "emissive surface must not be darkened");
    const auto half_lit = render_planet_surface(map, camera, {0, 1, 0}, {}, 5);
    check(pixel(half_lit, 0, 2) == RGB{86, 86, 86} && pixel(half_lit, 4, 2) == RGB{30, 30, 30},
          "illumination must come from the Sun rather than the viewer");
    const auto disk = render_planet_surface(map, camera, {}, {}, 5, true);
    check(disk.width == 5 && disk.height == 5 && disk.rgba.size() == 100, "surface dimensions");
    for (std::size_t y = 0; y < 5; ++y) for (std::size_t x = 0; x < 5; ++x) {
        const double sx = (2.0 * x + 1) / 5 - 1, sy = (2.0 * y + 1) / 5 - 1;
        const bool inside = sx * sx + sy * sy <= 1;
        check(alpha(disk, x, y) == (inside ? 255 : 0), "disk alpha mask");
        check(pixel(disk, x, y) == (inside ? RGB{100, 100, 100} : RGB{}), "straight alpha RGB");
    }
    const auto largest = render_planet_surface(map, camera, {}, {}, 512, true);
    check(largest.rgba.size() == 512 * 512 * 4 && alpha(largest, 0, 0) == 0
          && alpha(largest, 256, 256) == 255, "largest supported diameter");
}

void test_body_orientation() {
    const BodyOrientation identity;
    const BodyOrientation quarter_turn{{0, 1, 0}, {-1, 0, 0}, {0, 0, 1}};
    const BodyOrientation tilted{{1, 0, 0}, {0, 0, -1}, {0, 1, 0}};
    const std::vector<RGB> colors{{255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0}};
    const auto longitude_map = texture(4, 1, colors);
    SolarCamera camera{{0, 0, 0}, -135, 0, 10};
    for (std::size_t column = 0; column < colors.size(); ++column) {
        camera.yaw_deg = -135 + 90 * double(column);
        check(pixel(render_planet_surface(longitude_map, camera, {}, quarter_turn, 1, true))
              == colors[(column + 3) % 4], "rotation must transform the normal into the body frame");
    }
    camera.yaw_deg = 0;
    const auto latitude_map = texture(1, 2, {{255, 0, 0}, {0, 0, 255}});
    const auto tilted_disk = render_planet_surface(latitude_map, camera, {}, tilted, 5, true);
    check(pixel(tilted_disk, 4, 2) == RGB{255, 0, 0}
          && pixel(tilted_disk, 0, 2) == RGB{0, 0, 255}, "tilted north pole must point right");
    for (const std::size_t row : {0u, 2u, 4u})
        check(pixel(tilted_disk, 2, row) == RGB{128, 0, 128}, "tilted equator must cross disk vertically");

    const auto unrotated = render_planet_surface(latitude_map, camera, {}, identity, 5, true);
    for (std::size_t y = 0; y < 5; ++y) for (std::size_t x = 0; x < 5; ++x)
        check(alpha(tilted_disk, x, y) == alpha(unrotated, x, y), "orientation must preserve the disk outline");
    const auto solid = texture(1, 1, {{100, 80, 60}});
    const auto reference = render_planet_surface(solid, camera, {0, 1, 0}, identity, 17);
    for (const auto& orientation : {quarter_turn, tilted})
        check(render_planet_surface(solid, camera, {0, 1, 0}, orientation, 17).rgba == reference.rgba,
              "body orientation must not rotate the illumination");
}

void test_invalid_orientation() {
    const auto map = texture(1, 1, {{100, 100, 100}});
    const SolarCamera camera;
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double infinity = std::numeric_limits<double>::infinity();
    const std::array<BodyOrientation, 7> invalid{{
        {{0, 0, 0}, {0, 1, 0}, {0, 0, 1}},
        {{1.00001, 0, 0}, {0, 1, 0}, {0, 0, 1}},
        {{1, 0, 0}, {1, 0, 0}, {0, 0, 1}},
        {{1, 0, 0}, {1e-5, 1, 0}, {0, 0, 1}},
        {{1, 0, 0}, {0, 1, 0}, {0, 0, -1}},
        {{nan, 0, 0}, {0, 1, 0}, {0, 0, 1}},
        {{1, 0, 0}, {0, 1, 0}, {0, 0, infinity}}
    }};
    for (const auto& orientation : invalid)
        rejects([&] { render_planet_surface(map, camera, {}, orientation, 1, true); });
    const BodyOrientation rounded{{1 + 1e-10, 0, 0}, {0, 1, 0}, {0, 0, 1}};
    check(render_planet_surface(map, camera, {}, rounded, 1, true).rgba.size() == 4,
          "orientation must allow ordinary floating-point rounding");
}

void test_invalid_input() {
    const auto map = texture(1, 1, {{100, 100, 100}});
    SolarCamera camera;
    rejects([&] { render_planet_surface({}, camera, {}, {}, 1, true); });
    rejects([&] { render_planet_surface({1, 0, {}}, camera, {}, {}, 1, true); });
    rejects([&] { render_planet_surface({1, 1, {0, 0, 0}}, camera, {}, {}, 1, true); });
    rejects([&] { render_planet_surface({1, 1, {0, 0, 0, 0, 0}}, camera, {}, {}, 1, true); });
    const auto maximum = std::numeric_limits<std::size_t>::max();
    rejects([&] { render_planet_surface({maximum, 2, {}}, camera, {}, {}, 1, true); });
    rejects([&] { render_planet_surface({maximum / 2, 1, {}}, camera, {}, {}, 1, true); });
    rejects([&] { render_planet_surface(map, camera, {}, {}, 0, true); });
    rejects([&] { render_planet_surface(map, camera, {}, {}, 513, true); });
    rejects([&] { render_planet_surface(map, camera, {}, {}, 1); });
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double infinity = std::numeric_limits<double>::infinity();
    rejects([&] { render_planet_surface(map, camera, {}, {}, 1, true, nan); });
    rejects([&] { render_planet_surface(map, camera, {nan, 0, 0}, {}, 1, true); });
    rejects([&] { render_planet_surface(map, camera, {0, infinity, 0}, {}, 1); });
    camera.pitch_deg = 90;
    rejects([&] { render_planet_surface(map, camera, {}, {}, 1, true); });
    camera.pitch_deg = 0; camera.target.z = nan;
    rejects([&] { render_planet_surface(map, camera, {}, {}, 1, true); });
}

void test_perspective_sphere() {
    const auto map = texture(1, 1, {{100, 100, 100}});
    const Vec3 body{-1, 0, 0};
    SolarCamera camera{body, 0, 0, 0.3};
    const auto disk = render_surface_view(map, camera, body, {}, 0.1, 101, 101);
    check(pixel(disk, 50, 50) == RGB{100, 100, 100}, "perspective sunward center");
    const double tangent = std::tan(22.5 * 3.14159265358979323846 / 180);
    std::size_t covered = 0;
    for (std::size_t y = 0; y < 101; ++y) for (std::size_t x = 0; x < 101; ++x) {
        const double horizontal = ((2.0 * x + 1) / 101 - 1) * tangent;
        const double vertical = (1 - (2.0 * y + 1) / 101) * tangent;
        // 中心距離3Rの球の角半径はasin(1/3)。正投影の円盤径を流用しない。
        const bool visible = horizontal * horizontal + vertical * vertical <= 1.0 / 8;
        check(alpha(disk, x, y) == (visible ? 255 : 0), "physical perspective silhouette");
        if (visible) ++covered;
        else check(pixel(disk, x, y) == RGB{}, "missed surface must remain transparent black");
    }
    camera.distance_au = 0.6;
    const auto distant = render_surface_view(map, camera, body, {}, 0.1, 101, 101);
    std::size_t far_covered = 0;
    for (std::size_t y = 0; y < 101; ++y) for (std::size_t x = 0; x < 101; ++x)
        far_covered += alpha(distant, x, y) != 0;
    check(far_covered < covered / 3, "physical sphere must shrink with distance");

    const auto color_map = texture(4, 2, {{255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {255, 255, 0},
                                       {100, 0, 0}, {0, 100, 0}, {0, 0, 100}, {100, 100, 0}});
    const BodyOrientation rotated{{0, 1, 0}, {-1, 0, 0}, {0, 0, 1}};
    for (const auto& orientation : {BodyOrientation{}, rotated}) {
        for (const double longitude_offset : {0.0, 0.5}) {
            const auto surface = render_surface_view(color_map, camera, body, orientation,
                                                      0.1, 1, 1, longitude_offset);
            const auto reference = render_planet_surface(color_map, camera, body, orientation,
                                                         1, false, longitude_offset);
            check(pixel(surface) == pixel(reference), "perspective and disk must share UV and illumination");
        }
    }
}

void test_surface_horizon() {
    const auto map = texture(1, 1, {{100, 80, 60}});
    const Vec3 body{-1, 0, 0};
    const double radius = 6378.1366 / 149597870.7;
    const double distance = radius + 0.002 / 149597870.7;
    SolarCamera camera{{body.x + distance, 0, distance}, 0, 0, distance};
    camera.frame = SolarCameraBasis{{0, 0, -1}, {0, 1, 0}, {1, 0, 0}};
    const auto surface = render_surface_view(map, camera, body, {}, radius, 101, 101);
    check(alpha(surface, 50, 0) == 0 && alpha(surface, 50, 50) == 0,
          "upward and tangent rays must miss from 2m height");
    check(alpha(surface, 50, 51) == 255 && alpha(surface, 50, 100) == 255,
          "ground rays must hit below the horizon at 2m height");
    const auto day = pixel(surface, 50, 100);
    check(day[0] >= 99 && day[1] >= 79 && day[2] >= 59, "nearby ground receives local sunlight");
    camera.target.x += 2;
    const auto night = render_surface_view(map, camera, {1, 0, 0}, {}, radius, 101, 101);
    check(pixel(night, 50, 100) == RGB{30, 24, 18}, "night ground uses ambient illumination");

    // 上空でも同じray/sphere描画が全球を返す。天体姿勢は輪郭や日照を変えない。
    camera = {body, 0, 0, radius * 9};
    const auto orbit = render_surface_view(map, camera, body, {}, radius, 101, 101);
    const BodyOrientation tilted{{0, 0, -1}, {0, 1, 0}, {1, 0, 0}};
    check(render_surface_view(map, camera, body, tilted, radius, 101, 101).rgba == orbit.rgba,
          "surface orientation must preserve physical silhouette and lighting");
    check(alpha(orbit, 50, 50) == 255 && alpha(orbit, 0, 0) == 0, "orbital view contains a full globe");
}

void test_invalid_surface_view() {
    const auto map = texture(1, 1, {{100, 100, 100}});
    const Vec3 body{-1, 0, 0};
    SolarCamera camera{body, 0, 0, 1};
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double infinity = std::numeric_limits<double>::infinity();
    for (const auto radius : {0.0, -1.0, nan, infinity, 1.0, 2.0})
        rejects([&] { render_surface_view(map, camera, body, {}, radius, 10, 10); });
    for (const auto size : {0u, 1025u}) {
        rejects([&] { render_surface_view(map, camera, body, {}, 0.1, size, 10); });
        rejects([&] { render_surface_view(map, camera, body, {}, 0.1, 10, size); });
    }
    rejects([&] { render_surface_view({}, camera, body, {}, 0.1, 10, 10); });
    rejects([&] { render_surface_view(map, camera, body, {}, 0.1, 10, 10, nan); });
    rejects([&] { render_surface_view(map, camera, {}, {}, 0.1, 10, 10); });
    rejects([&] { render_surface_view(map, camera, {nan, 0, 0}, {}, 0.1, 10, 10); });
    const BodyOrientation invalid{{1, 0, 0}, {0, 1, 0}, {0, 0, -1}};
    rejects([&] { render_surface_view(map, camera, body, invalid, 0.1, 10, 10); });
    check(render_surface_view(map, camera, body, {}, 0.1, 1024, 1).rgba.size() == 4096,
          "largest viewport dimension and single row");
}

void test_sphere_picking() {
    const auto map = texture(1, 1, {{100, 100, 100}});
    const SolarCamera camera{{-10, 0, 0}, 0, 0, 10}; // 視点は原点、前方は-X。
    const auto center_hit = sphere_hit_distance(camera, {-10, 0, 0}, 1, 50.5, 50.5, 101, 101);
    check(center_hit && std::abs(*center_hit - 9) < 1e-12, "picking returns first positive hit in AU");
    check(!sphere_hit_distance(camera, {10, 0, 0}, 1, 50.5, 50.5, 101, 101),
          "sphere behind a forward ray must miss");

    for (const Vec3 body : {Vec3{-10, 4.3, 0}, Vec3{0.1, 0.999, 0}}) {
        const auto center = project_solar(body, camera, 101, 101);
        check(!center || center->x > 101, "regression sphere center must be outside the view");
        const auto image = render_surface_view(map, camera, body, {}, 1, 101, 101);
        const auto edge_hit = sphere_hit_distance(camera, body, 1, 100.5, 50.5, 101, 101);
        check(edge_hit && alpha(image, 100, 50) == 255,
              "visible limb must be selectable when sphere center is offscreen or behind camera");
        const auto ray = solar_camera_ray(camera, 100.5, 50.5, 101, 101);
        const Vec3 hit{ray.x * *edge_hit - body.x, ray.y * *edge_hit - body.y,
                       ray.z * *edge_hit - body.z};
        check(std::abs(std::hypot(hit.x, hit.y, hit.z) - 1) < 1e-12,
              "picking distance must reach the sphere surface");
        for (std::size_t y = 0; y < 101; ++y) for (std::size_t x = 0; x < 101; ++x)
            check(sphere_hit_distance(camera, body, 1, x + 0.5, y + 0.5, 101, 101).has_value()
                  == (alpha(image, x, y) != 0), "picking and rendered silhouette must agree");
    }

    const double radius = 6378.1366 / 149597870.7, height = 0.002 / 149597870.7;
    SolarCamera near_camera{{-1, 0, 0}, 0, 0, radius + height};
    const auto ground = sphere_hit_distance(near_camera, {-1, 0, 0}, radius, 0.5, 0.5, 1, 1);
    check(ground && std::abs(*ground - height) < 1e-20, "2m surface hit must avoid root cancellation");

    // x=2,y=1をかすめる接線。境界直外の球を選択しないことも確認する。
    check(sphere_hit_distance(camera, {-2, 1, 0}, 1, 50.5, 50.5, 101, 101).has_value(),
          "tangent ray must count as a hit");
    check(!sphere_hit_distance(camera, {-2, 1 + 1e-10, 0}, 1, 50.5, 50.5, 101, 101),
          "ray outside the tangent must miss");
    const Vec3 eye{0.5176380902050415, 1.9318516525781366, 0};
    const Vec3 direction{-0.7071067811865476, -0.7071067811865474, 0};
    SolarCamera tangent_camera{{eye.x + direction.x, eye.y + direction.y, 0}, 0, 0, 1};
    tangent_camera.frame = SolarCameraBasis{{-direction.x, -direction.y, 0},
                                             {direction.y, -direction.x, 0}, {0, 0, 1}};
    const auto tangent = sphere_hit_distance(tangent_camera, {}, 1, 0.5, 0.5, 1, 1);
    check(tangent && std::abs(*tangent - std::sqrt(3.0)) < 1e-12,
          "rounded negative discriminant must preserve an ideal tangent");
    const double nan = std::numeric_limits<double>::quiet_NaN();
    rejects([&] { sphere_hit_distance(camera, {-10, 0, 0}, 0, 0, 0, 101, 101); });
    rejects([&] { sphere_hit_distance(camera, {0, 0, 0}, 1, 0, 0, 101, 101); });
    rejects([&] { sphere_hit_distance(camera, {-1, 0, 0}, 1, 0, 0, 101, 101); });
    rejects([&] { sphere_hit_distance(camera, {nan, 0, 0}, 1, 0, 0, 101, 101); });
    rejects([&] { sphere_hit_distance(camera, {-10, 0, 0}, 1, nan, 0, 101, 101); });
    rejects([&] { sphere_hit_distance(camera, {-10, 0, 0}, 1, 0, 0, 0, 101); });
}

void test_scene_depth_and_emission() {
    const auto red = texture(1, 1, {{200, 0, 0}});
    const auto blue = texture(1, 1, {{0, 0, 200}});
    const SolarCamera camera{{-10, 0, 0}, 0, 0, 10};
    const SurfaceSphere small{red, {-6, 0.7, 0}, {}, 1, true};
    const SurfaceSphere large{blue, {-7, 0, 0}, {}, 3, true};
    const auto scene = render_surface_scene({small, large}, camera, 101, 81);
    check(scene.rgba == render_surface_scene({large, small}, camera, 101, 81).rgba,
          "sphere occlusion must not depend on draw order");
    for (std::size_t y = 0; y < scene.height; ++y) for (std::size_t x = 0; x < scene.width; ++x) {
        const auto near = sphere_hit_distance(camera, small.center, small.radius_au,
            x + 0.5, y + 0.5, scene.width, scene.height);
        const auto far = sphere_hit_distance(camera, large.center, large.radius_au,
            x + 0.5, y + 0.5, scene.width, scene.height);
        const RGB expected = near && (!far || *near < *far) ? RGB{200, 0, 0}
            : far ? RGB{0, 0, 200} : RGB{};
        check(pixel(scene, x, y) == expected, "nearest surface, not center, determines occlusion");
        check(alpha(scene, x, y) == (near || far ? 255 : 0), "scene alpha uses the nearest hit");
    }
    const SolarCamera sun_camera{{0, 0, 0}, 0, 0, 10};
    const SurfaceSphere sun{red, {}, {}, 1, true, 0};
    check(pixel(render_surface_scene({sun}, sun_camera, 1, 1)) == RGB{200, 0, 0},
          "physical Sun at heliocentric origin must be emissive");
    check(render_surface_scene({}, camera, 2, 2).rgba == std::vector<std::uint8_t>(16),
          "empty physical scene must remain transparent");
    rejects([&] { render_surface_scene({{red, {}, {}, 1, false}}, sun_camera, 1, 1); });
    rejects([&] { render_surface_scene({{red, {}, {}, 11, true}}, sun_camera, 1, 1); });
}

void test_scene_projection_bounds() {
    const auto map = texture(1, 1, {{100, 100, 100}});
    SolarCamera camera{{-10, 0, 0}, 0, 0, 10};
    // 中心が背面の地平線、四辺の外側、遠景の小球、縦長viewportを含める。
    const std::array<Vec3, 9> centers{{{-10, 4.3, 0}, {-10, -4.3, 0}, {-10, 0, 4.3},
        {-10, 0, -4.3}, {0.1, 0.999, 0}, {-1.001, 0, 0}, {-1000, 0, 0}, {3, 0, 0}, {-10, 0, 0}}};
    for (const auto dimensions : {std::array<std::size_t, 2>{101, 61}, {61, 101}}) {
        for (const auto center : centers) {
            const auto image = render_surface_scene({{map, center, {}, 1, true}}, camera,
                dimensions[0], dimensions[1]);
            for (std::size_t y = 0; y < image.height; ++y) for (std::size_t x = 0; x < image.width; ++x)
                check((alpha(image, x, y) != 0) == sphere_hit_distance(camera, center, 1,
                    x + 0.5, y + 0.5, image.width, image.height).has_value(),
                    "bounded scene rasterization must preserve every visible limb");
        }
    }
}
} // namespace

int main() {
    try {
        test_longitude_and_camera(); test_latitude(); test_lighting_and_disk();
        test_body_orientation(); test_invalid_orientation(); test_invalid_input();
        test_perspective_sphere(); test_surface_horizon(); test_invalid_surface_view();
        test_sphere_picking();
        test_scene_depth_and_emission(); test_scene_projection_bounds();
        std::cout << "planet surface tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
