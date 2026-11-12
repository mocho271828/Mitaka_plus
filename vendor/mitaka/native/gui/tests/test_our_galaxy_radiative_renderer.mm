#include "OurGalaxyRadiativeRenderer.h"
#include "grid_geometry.hpp"
#include <algorithm>
#include <array>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <limits>
#include <stdexcept>
#include <vector>

using namespace mitaka;
using namespace mitaka::gui;

static std::vector<std::uint8_t> pixels(CGImageRef image) {
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(image));
    assert(data);
    const auto* begin = CFDataGetBytePtr(data);
    std::vector<std::uint8_t> result(begin, begin + CFDataGetLength(data));
    CFRelease(data);
    return result;
}
template<typename Exception, typename Fn> static void throws(Fn fn) {
    bool caught = false;
    try { fn(); } catch (const Exception&) { caught = true; }
    assert(caught);
}
static std::uint8_t quantize(float value) {
    return static_cast<std::uint8_t>(std::lround(std::fmax(0, std::fmin(1, value))*255));
}
int main() {
    OurGalaxyModel source;
    for (auto& map : source.maps) {
        map.width = map.height = 512;
        map.values.assign(512*512, 0.5f);
    }
    OurGalaxyRadiativeModel model(source);
    auto zero = our_galaxy_galactic_position({0,0,0});
    assert(zero.x == -8000 && zero.y == 0 && zero.z == 0);
    const auto center = j2000_equatorial_to_ecliptic(galactic_to_j2000_equatorial({8000,0,0}));
    const auto center_g = our_galaxy_galactic_position({center.x, center.y, center.z});
    assert(std::hypot(center_g.x, center_g.y, center_g.z) < 10);
    GalaxyCameraPc camera;
    camera.yaw_deg = 0; camera.pitch_deg = 0; camera.distance_pc = 12000;
    const auto origin = our_galaxy_camera_origin(camera);
    const auto direct = our_galaxy_galactic_position({12000, 0, 0});
    assert(origin.x == direct.x && origin.y == direct.y && origin.z == direct.z);
    auto shifted = camera;
    shifted.target_offset_au = {1000 * astronomical_units_per_parsec, 0, 0};
    const auto moved_origin = our_galaxy_camera_origin(shifted);
    const auto moved_direct = our_galaxy_galactic_position({13000, 0, 0});
    assert(moved_origin.x == moved_direct.x && moved_origin.y == moved_direct.y && moved_origin.z == moved_direct.z);
    assert(our_galaxy_alpha(camera) > 0);
    const auto rendered = render_our_galaxy_radiative(model, camera, 1, 1);
    assert(rendered && rendered->alpha() == our_galaxy_alpha(camera));
    assert(CGImageGetWidth(rendered->multiplier()) == 1 && CGImageGetHeight(rendered->emission()) == 1);
    const auto offset = our_galaxy_galactic_position({11999, 0, 0});
    const auto ray = model.trace(origin, {offset.x-origin.x, offset.y-origin.y, offset.z-origin.z});
    const auto mult = pixels(rendered->multiplier()), emiss = pixels(rendered->emission());
    const std::array<float, 3> t{ray.transmittance.r, ray.transmittance.g, ray.transmittance.b};
    const std::array<float, 3> i{ray.intensity.r, ray.intensity.g, ray.intensity.b};
    for (std::size_t c = 0; c < 3; ++c) {
        assert(std::abs(int(mult[c])-int(quantize(1-rendered->alpha()+rendered->alpha()*t[c]))) <= 1);
        assert(std::abs(int(emiss[c])-int(quantize(rendered->alpha()*i[c]))) <= 1);
    }
    assert(mult[3] == 255 && emiss[3] == 255);
    std::array<std::uint8_t, 4> buffer{100, 120, 140, 255};
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(buffer.data(), 1, 1, 8, 4, colorspace,
        kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
    assert(context);
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), rendered->multiplier());
    CGContextSetBlendMode(context, kCGBlendModePlusLighter);
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), rendered->emission());
    CGContextRelease(context); CGColorSpaceRelease(colorspace);
    const std::array<int, 3> background{100, 120, 140};
    for (std::size_t c = 0; c < 3; ++c) {
        const int expected = std::min(255, int(std::lround(background[c] * mult[c] / 255.0)) + int(emiss[c]));
        assert(std::abs(int(buffer[c])-expected) <= 2);
    }
    // 画像データの先頭行と最終行は左上原点の視線を使う。
    camera.vertical_fov_deg = 90;
    const auto rows = render_our_galaxy_radiative(model, camera, 1, 2);
    const auto rows_mult = pixels(rows->multiplier()), rows_emiss = pixels(rows->emission());
    SolarCamera directional; directional.yaw_deg = camera.yaw_deg; directional.pitch_deg = camera.pitch_deg;
    directional.vertical_fov_deg = camera.vertical_fov_deg;
    for (std::size_t y = 0; y < 2; ++y) {
        const auto direction = solar_camera_ray(directional, .5, y+.5, 1, 2);
        const auto target = our_galaxy_galactic_position({12000+direction.x*1000, direction.y*1000, direction.z*1000});
        const auto sample = model.trace(origin, {target.x-origin.x, target.y-origin.y, target.z-origin.z});
        assert(std::abs(int(rows_mult[y*4])-int(quantize(1-rows->alpha()+rows->alpha()*sample.transmittance.r))) <= 1);
        assert(std::abs(int(rows_emiss[y*4])-int(quantize(rows->alpha()*sample.intensity.r))) <= 1);
    }
    int calls = 0;
    assert(!render_our_galaxy_radiative(model, camera, 4, 4, [&] { return ++calls == 3; }));
    assert(calls == 3);
    camera.distance_pc = 10;
    const auto hidden = render_our_galaxy_radiative(model, camera, 1000, 500);
    assert(hidden->alpha() == 0 && CGImageGetWidth(hidden->multiplier()) == 320 && CGImageGetHeight(hidden->multiplier()) == 160);
    const auto white = pixels(hidden->multiplier()), black = pixels(hidden->emission());
    for (std::size_t p = 0; p < white.size(); p += 4) {
        assert(white[p] == 255 && white[p+1] == 255 && white[p+2] == 255);
        assert(black[p] == 0 && black[p+1] == 0 && black[p+2] == 0);
    }
    throws<std::invalid_argument>([&] { render_our_galaxy_radiative(model, camera, 0, 1); });
    throws<std::invalid_argument>([&] { our_galaxy_galactic_position({NAN, 0, 0}); });
    throws<std::out_of_range>([&] { our_galaxy_galactic_position({1e9, 0, 0}); });
    camera.distance_pc = 1e8;
    assert(our_galaxy_alpha(camera) == 0);
    camera.pitch_deg = 90;
    throws<std::invalid_argument>([&] { our_galaxy_camera_origin(camera); });
    throws<std::invalid_argument>([&] { our_galaxy_alpha(camera); });
}
