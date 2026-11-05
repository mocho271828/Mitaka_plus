#include "mitaka/our_galaxy_radiative.hpp"

#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
int checks = 0;
void require(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
void close(float value, float expected, float tolerance, const char* message) {
    require(std::isfinite(value) && std::abs(value - expected) <= tolerance, message);
}
template<typename F> void throws(F f, const char* message) {
    try { f(); } catch (const std::exception&) { ++checks; return; }
    throw std::runtime_error(message);
}
OurGalaxyModel uniform(float thin, float dust) {
    OurGalaxyModel model;
    for (auto& map : model.maps) { map.width = 512; map.height = 512; }
    model.maps[0].values.assign(512 * 512, thin);
    model.maps[1].values.assign(512 * 512, dust);
    return model;
}
void tests() {
    auto data = uniform(0, 0);
    OurGalaxyRadiativeModel model(data);
    auto factors = model.modulation(0, 0);
    close(factors[0], 76.f / 255.f, 1e-7f, "thin zero quantization");
    close(factors[1], .004f, 1e-7f, "dust zero quantization");
    factors = model.modulation(1e6f, 0);
    close(factors[0], .3f, 1e-7f, "outside thin default");
    close(factors[1], .004f, 1e-7f, "outside dust default");
    data.maps[0].values[295 * 512 + 256] = .5f;
    data.maps[1].values[295 * 512 + 256] = .5f;
    data.maps[0].values[227 * 512 + 118] = 1.f;
    data.maps[1].values[227 * 512 + 118] = 1.f;
    OurGalaxyRadiativeModel asymmetric(data);
    factors = asymmetric.modulation(0, 0);
    close(factors[0], 165.f / 255.f, 1e-7f, "center thin half quantization");
    close(factors[1], .004f + .004f * .6f * 127.f / 255.f, 1e-7f, "center dust half quantization");
    factors = asymmetric.modulation(-8000, 0);
    // 坐標変換は float 丸めを伴うため整数境界を避けた点も検証する。
    factors = asymmetric.modulation(-7995, 0);
    close(factors[0], 1.f, 1e-7f, "sun map position");
    close(factors[1], .0064f, 1e-7f, "sun dust map position");
    const auto miss = model.trace({0, 0, 5000}, {0, 0, 1});
    require(miss.steps == 0 && miss.intensity.r == 0 && miss.transmittance.r == 1, "ray misses");
    const auto one = model.trace({14999, 0, 0}, {1, 0, 0});
    require(one.steps == 1, "one untrimmed step");
    // 公式式を別途倍精度で計算した固定値。旧 Windows 実行結果ではない。
    close(one.optical_depth, .00800149838f, 2e-6f, "one-step optical depth");
    close(one.intensity.r, .00211761447f, 2e-6f, "one-step red intensity");
    close(one.intensity.g, .00223034440f, 2e-6f, "one-step green intensity");
    close(one.intensity.b, .00220173469f, 2e-6f, "one-step blue intensity");
    require(one.transmittance.r == 1 && one.transmittance.g == 1 && one.transmittance.b == 1, "transmission table quantization");
    const auto zero = model.trace({8000, 0, 50}, {1, 0, 0});
    OurGalaxyRadiativeModel dusty(uniform(0, 1));
    const auto high = dusty.trace({8000, 0, 50}, {1, 0, 0});
    require(high.optical_depth > zero.optical_depth, "dust map changes optical depth");
    require(high.transmittance.r < zero.transmittance.r && high.transmittance.b < high.transmittance.r, "RGB extinction");
    OurGalaxyRadiativeModel bright(uniform(1, 0));
    const auto bright_ray = bright.trace({8000, 0, 50}, {1, 0, 0});
    require(bright_ray.intensity.r > zero.intensity.r, "thin map changes intensity");
    const auto point = model.point_extinction({8000,0,50}, {9000,0,50});
    require(point.optical_depth > 0 && point.visible && point.steps > 0, "point absorption");
    require(point.transmittance.b < point.transmittance.g && point.transmittance.g < point.transmittance.r,
            "point RGB extinction");
    const auto dust_point = dusty.point_extinction({8000,0,50}, {9000,0,50});
    require(point.optical_depth == dust_point.optical_depth, "official point absorption ignores dust map");
    const auto same_point = model.point_extinction({8000,0,0}, {8000,0,0});
    require(same_point.optical_depth == 0 && same_point.steps == 0 && same_point.visible, "coincident point");
    const auto missed_point = model.point_extinction({20000,0,5000}, {22000,0,5000});
    require(missed_point.optical_depth == 0 && missed_point.steps == 0, "point segment misses ellipsoid");
    const auto dark_point = model.point_extinction({8000,0,0}, {-8000,0,0});
    require(!dark_point.visible && dark_point.optical_depth > 2.9f, "official point cutoff");
    throws([&] { model.point_extinction({8000,0,0}, {9000,0,0}, 0); }, "point step accepted zero");
    throws([&] { model.point_extinction({8000,0,0}, {std::numeric_limits<float>::infinity(),0,0}); }, "point infinity accepted");
    const OurGalaxyRadiativeResult sample{{.1f, .2f, .3f}, {.2f, .6f, .9f}, 0, 0};
    auto mixed = compose_our_galaxy({.5f, .5f, .5f}, sample, .5f);
    close(mixed.r, .35f, 1e-6f, "red composition");
    close(mixed.g, .5f, 1e-6f, "green composition");
    close(mixed.b, .625f, 1e-6f, "blue composition");
    mixed = compose_our_galaxy({.5f, .6f, .7f}, sample, 0);
    require(mixed.r == .5f && mixed.g == .6f && mixed.b == .7f, "zero alpha");
    throws([&] { model.trace({0, 0, 0}, {1, 0, 0}); }, "singularity accepted");
    throws([&] { model.trace({0, 0, 0}, {0, 0, 0}); }, "zero direction accepted");
    throws([&] { model.trace({0, 0, 0}, {1, 0, 0}, 0); }, "zero step accepted");
    throws([&] { model.modulation(std::numeric_limits<float>::quiet_NaN(), 0); }, "NaN coordinate accepted");
    throws([&] { compose_our_galaxy({0, 0, 0}, sample, 2); }, "invalid alpha accepted");
    data.maps[0].values[0] = std::numeric_limits<float>::quiet_NaN();
    throws([&] { OurGalaxyRadiativeModel invalid(data); }, "NaN map accepted");
    data.maps[0].values[0] = -1;
    throws([&] { OurGalaxyRadiativeModel invalid(data); }, "negative map accepted");
    data.maps[0].values[0] = 0;
    data.maps[1].width = 511;
    throws([&] { OurGalaxyRadiativeModel invalid(data); }, "invalid dimensions accepted");
    OurGalaxyRadiativeModel clamped(uniform(2, 2));
    factors = clamped.modulation(0, 0);
    close(factors[0], 1, 1e-7f, "thin above one clamped as source");
    close(factors[1], .0064f, 1e-7f, "dust above one clamped as source");
}
} // namespace

int main() {
    try { tests(); std::cout << "our galaxy radiative: " << checks << " checks passed\n"; }
    catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
