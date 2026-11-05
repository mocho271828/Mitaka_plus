/*
Copyright (c) 2007   Tsunehiko Kato  and  4D2U Project, National Astronomical Observatory of Japan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
#include "OurGalaxyRadiativeRenderer.h"
#include "grid_geometry.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>
#include <stdexcept>
#include <vector>

namespace mitaka::gui {
namespace {
constexpr double center_distance_pc = 8000;
constexpr double max_origin_pc = 1e7;
constexpr double maximum_dimension = 320;

SolarCamera direction_camera(GalaxyCameraPc camera) {
    SolarCamera result;
    result.yaw_deg = camera.yaw_deg;
    result.pitch_deg = camera.pitch_deg;
    result.frame = camera.frame;
    return result;
}
NativeEclipticPositionPc eye_position(GalaxyCameraPc camera) {
    camera = checked_galaxy_camera(camera);
    const auto out = solar_camera_basis(direction_camera(camera)).outward;
    return {camera.target.x_pc + camera.distance_pc * out.x,
            camera.target.y_pc + camera.distance_pc * out.y,
            camera.target.z_pc + camera.distance_pc * out.z};
}
double dot(Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }
Vec3 galactic_components(Vec3 v) {
    // 公式は厳密な逆行列ではなく G2E の転置を使う。共通基底を再利用する。
    static const std::array<Vec3, 3> axes{
        j2000_equatorial_to_ecliptic(galactic_to_j2000_equatorial({1, 0, 0})),
        j2000_equatorial_to_ecliptic(galactic_to_j2000_equatorial({0, 1, 0})),
        j2000_equatorial_to_ecliptic(galactic_to_j2000_equatorial({0, 0, 1}))};
    return {dot(v, axes[0]), dot(v, axes[1]), dot(v, axes[2])};
}
void require_origin(Vec3 p) {
    for (double value : {p.x, p.y, p.z}) {
        if (!std::isfinite(value)) throw std::invalid_argument("non-finite OurGalaxy position");
        if (std::abs(value) > max_origin_pc) throw std::out_of_range("OurGalaxy position exceeds ray model range");
    }
}
float norm(Vec3 p) { return static_cast<float>(std::hypot(p.x, p.y, p.z)); }
float alpha_for(NativeEclipticPositionPc eye, OurGalaxyGalacticVector origin) {
    const float sun = norm({eye.x_pc, eye.y_pc, eye.z_pc});
    const float center = norm({origin.x, origin.y, origin.z});
    if (sun < 1000) return 0;
    float alpha = 1;
    if (sun < 2700) {
        alpha = (sun - 1000) / 1700;
        if (alpha < 0.02f) return 0;
    }
    if (center < 2700) {
        alpha *= (center - 1000) / 1700;
        if (alpha < 0.02f) return 0;
    }
    return alpha;
}
std::uint8_t channel(float value) {
    if (!std::isfinite(value)) throw std::domain_error("non-finite OurGalaxy image channel");
    return static_cast<std::uint8_t>(std::lround(std::clamp(value, 0.0f, 1.0f) * 255));
}
CGImageRef make_image(const std::vector<std::uint8_t>& bytes, size_t width, size_t height) {
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, bytes.data(), static_cast<CFIndex>(bytes.size()));
    if (!data) throw std::runtime_error("failed to allocate OurGalaxy image data");
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CFRelease(data);
    if (!provider) throw std::runtime_error("failed to allocate OurGalaxy image provider");
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    if (!space) { CGDataProviderRelease(provider); throw std::runtime_error("failed to allocate RGB color space"); }
    CGImageRef image = CGImageCreate(width, height, 8, 32, width * 4, space,
        kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big, provider, nullptr, false, kCGRenderingIntentDefault);
    CGColorSpaceRelease(space);
    CGDataProviderRelease(provider);
    if (!image) throw std::runtime_error("failed to create OurGalaxy image");
    return image;
}
} // namespace

OurGalaxyGalacticVector our_galaxy_galactic_position(NativeEclipticPositionPc position) {
    const Vec3 input{position.x_pc, position.y_pc, position.z_pc};
    if (!std::isfinite(input.x) || !std::isfinite(input.y) || !std::isfinite(input.z))
        throw std::invalid_argument("non-finite OurGalaxy position");
    auto transformed = galactic_components(input);
    transformed.x -= center_distance_pc;
    require_origin(transformed);
    return {static_cast<float>(transformed.x), static_cast<float>(transformed.y), static_cast<float>(transformed.z)};
}
OurGalaxyGalacticVector our_galaxy_camera_origin(GalaxyCameraPc camera) {
    return our_galaxy_galactic_position(eye_position(camera));
}
float our_galaxy_alpha(GalaxyCameraPc camera) {
    const auto eye = eye_position(camera);
    return alpha_for(eye, our_galaxy_galactic_position(eye));
}
OurGalaxyRadiativeImages::OurGalaxyRadiativeImages(CGImageRef multiplier, CGImageRef emission, float alpha)
    : multiplier_(CGImageRetain(multiplier)), emission_(CGImageRetain(emission)), alpha_(alpha) {}
OurGalaxyRadiativeImages::~OurGalaxyRadiativeImages() {
    CGImageRelease(multiplier_);
    CGImageRelease(emission_);
}
std::shared_ptr<const OurGalaxyRadiativeImages> render_our_galaxy_radiative(
    const OurGalaxyRadiativeModel& model, GalaxyCameraPc camera, double width, double height,
    std::function<bool()> should_cancel) {
    if (!std::isfinite(width) || width <= 0 || width > 1e7 ||
        !std::isfinite(height) || height <= 0 || height > 1e7)
        throw std::invalid_argument("invalid OurGalaxy viewport dimensions");
    camera = checked_galaxy_camera(camera);
    const auto eye = eye_position(camera);
    const auto origin = our_galaxy_galactic_position(eye);
    const auto alpha = alpha_for(eye, origin);
    const auto directional_camera = direction_camera(camera);
    const double scale = std::min(1.0, maximum_dimension / std::max(width, height));
    const auto w = static_cast<size_t>(std::max(1.0, std::ceil(width * scale)));
    const auto h = static_cast<size_t>(std::max(1.0, std::ceil(height * scale)));
    std::vector<std::uint8_t> multiplier(w*h*4), emission(w*h*4);
    for (size_t y = 0; y < h; ++y) {
        for (size_t x = 0; x < w; ++x) {
            if (should_cancel && should_cancel()) return nullptr;
            OurGalaxyRadiativeResult sample;
            if (alpha > 0) {
                const auto ray = solar_camera_ray(directional_camera, (x + 0.5)*width/w,
                                                  (y + 0.5)*height/h, width, height);
                const auto g = galactic_components(ray);
                sample = model.trace(origin, {static_cast<float>(g.x), static_cast<float>(g.y), static_cast<float>(g.z)});
            }
            const std::array<float, 3> t{sample.transmittance.r, sample.transmittance.g, sample.transmittance.b};
            const std::array<float, 3> i{sample.intensity.r, sample.intensity.g, sample.intensity.b};
            const size_t offset = (y*w+x)*4;
            for (size_t c = 0; c < 3; ++c) {
                multiplier[offset+c] = channel(1-alpha+alpha*t[c]);
                emission[offset+c] = channel(alpha*i[c]);
            }
            multiplier[offset+3] = emission[offset+3] = 255;
        }
    }
    if (should_cancel && should_cancel()) return nullptr;
    CGImageRef m = make_image(multiplier, w, h);
    CGImageRef e = nullptr;
    try { e = make_image(emission, w, h); }
    catch (...) { CGImageRelease(m); throw; }
    std::shared_ptr<const OurGalaxyRadiativeImages> images;
    try { images = std::make_shared<OurGalaxyRadiativeImages>(m, e, alpha); }
    catch (...) { CGImageRelease(m); CGImageRelease(e); throw; }
    CGImageRelease(m);
    CGImageRelease(e);
    return images;
}
} // namespace mitaka::gui
