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
#include "mitaka/our_galaxy_radiative.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <stdexcept>

namespace mitaka {
namespace {
constexpr float radius = 15000.0f, flattening = 0.3f;
constexpr float extinction_base = 0.004f;
constexpr std::size_t map_size = 512;
constexpr std::array<float, 3> extinction_ratio{1.0f, 1.33f, 1.78f};
// 原版 color.cpp を参照ビルドした B-V 0.0 と 1.2 の値。導出は provenance 参照。
constexpr std::array<float, 3> thin_color{0.941287339f, 0.997622490f, 0.999999940f};
constexpr std::array<float, 3> thick_color{0.999999940f, 0.960182071f, 0.721082211f};

bool finite(OurGalaxyRgb c) { return std::isfinite(c.r) && std::isfinite(c.g) && std::isfinite(c.b); }
bool finite(OurGalaxyGalacticVector p) { return std::isfinite(p.x) && std::isfinite(p.y) && std::isfinite(p.z); }
double exp_approx(double x) {
    const double x2 = x * x, x3 = x * x2;
    const double a = 1.0 + 0.2507213 * x + 0.0292732 * x2 + 0.0038278 * x3;
    const double a2 = a * a;
    return 1.0 / (a2 * a2);
}
float transmission(float tau, std::size_t channel) {
    const int index = std::min(500, static_cast<int>(tau * 100.0f));
    return std::exp(-extinction_ratio[channel] * (static_cast<float>(index) / 100.0f));
}
float bulge(float r) {
    const auto index = std::min(2999, static_cast<int>(r * (3000.0f / 13500.0f)));
    // 原版の表の第 0 要素は無限大。黙って有限値に置き換えない。
    if (index == 0) throw std::domain_error("our galaxy: singular bulge table entry");
    const float s = 5.0f * static_cast<float>(index) / 2999.0f;
    static const float r3 = static_cast<float>(0.0011 * std::exp(7.669f * std::pow(8000.0f / 2700.0f, 0.25f) - 8000.0f / 3800.0f));
    return r3 * std::pow(s / 8000.0f * 2700.0f, -7.0f / 8.0f) * std::exp(-7.669 * std::pow(s, 0.25f));
}
} // namespace

OurGalaxyRadiativeModel::OurGalaxyRadiativeModel(const OurGalaxyModel& source) {
    for (std::size_t map = 0; map < maps_.size(); ++map) {
        const auto& original = source.maps[map];
        if (original.width != 512 || original.height != 512 || original.values.size() != map_size * map_size)
            throw std::invalid_argument("our galaxy: radiative maps must be 512 by 512");
        maps_[map].reserve(original.values.size());
        for (float value : original.values) {
            if (!std::isfinite(value) || value < 0.0f)
                throw std::invalid_argument("our galaxy: invalid radiative map sample");
            const float mapped = map == 0 ? value * 0.7f + 0.3f : value;
            maps_[map].push_back(static_cast<std::uint8_t>(255.0f * std::min(mapped, 1.0f)));
        }
    }
}

std::array<float, 2> OurGalaxyRadiativeModel::modulation(float x_pc, float y_pc) const {
    if (!std::isfinite(x_pc) || !std::isfinite(y_pc)) throw std::invalid_argument("our galaxy: invalid map position");
    static const float scale = std::hypot(-138.5f, -68.0f) / 8000.0f;
    static const float theta = std::atan2(68.0f, 138.5f);
    static const float cs = scale * std::cos(theta), sn = scale * std::sin(theta);
    const float x = x_pc * cs - y_pc * sn + 256.5f;
    const float y = x_pc * sn + y_pc * cs + 295.5f;
    if (!(x >= 0.0f && x < 512.0f && y >= 0.0f && y < 512.0f)) return {0.3f, extinction_base};
    const auto index = static_cast<std::size_t>(y) * map_size + static_cast<std::size_t>(x);
    return {maps_[0][index] / 255.0f, extinction_base + extinction_base * 0.6f * maps_[1][index] / 255.0f};
}

OurGalaxyRadiativeResult OurGalaxyRadiativeModel::trace(OurGalaxyGalacticVector p,
    OurGalaxyGalacticVector n, float step_pc) const {
    if (!finite(p) || !finite(n) || !std::isfinite(step_pc) || step_pc < 1.0f || step_pc > 1000.0f)
        throw std::invalid_argument("our galaxy: invalid ray or step");
    // 上限はオーバーフロー防止用で、通常の銀河系内視点より十分に大きい。
    if (std::max({std::abs(p.x), std::abs(p.y), std::abs(p.z)}) > 1.0e7f)
        throw std::out_of_range("our galaxy: ray origin out of range");
    const float norm = std::hypot(n.x, n.y, n.z);
    if (!std::isfinite(norm) || norm == 0.0f) throw std::invalid_argument("our galaxy: invalid ray direction");
    n = {n.x / norm, n.y / norm, n.z / norm};
    const float scaled_norm = std::hypot(n.x, n.y, n.z / flattening);
    const OurGalaxyGalacticVector qn{n.x / scaled_norm, n.y / scaled_norm, n.z / flattening / scaled_norm};
    const OurGalaxyGalacticVector qp{p.x, p.y, p.z / flattening};
    const float b = qn.x * qp.x + qn.y * qp.y + qn.z * qp.z;
    const float c = qp.x * qp.x + qp.y * qp.y + qp.z * qp.z - radius * radius;
    const float disc = b * b - c;
    OurGalaxyRadiativeResult result;
    if (disc <= 0.0f) return result;
    const float d = std::sqrt(disc), t1 = -b - d, t2 = -b + d;
    if (t2 <= 0.0f) return result;
    const float start = std::max(0.0f, t1), end = t2;
    p = {qp.x + start * qn.x, qp.y + start * qn.y, (qp.z + start * qn.z) * flattening};
    const float distance = (end - start) / scaled_norm;
    const float cs = std::max(std::abs(n.z), 0.3f);
    const float ds1 = step_pc / 1.29f / cs, ds2 = 0.29f / 1.29f / cs;
    float ds = ds1 + std::abs(p.z) * ds2, travelled = 0, tau = 0;
    std::array<float, 3> intensity{};
    while (travelled < distance) {
        if (++result.steps > 100000) throw std::runtime_error("our galaxy: ray step limit exceeded");
        const auto m = modulation(p.x, p.y);
        const float rho = std::hypot(p.x, p.y), z = std::abs(p.z);
        const float e1 = ds * m[0] * exp_approx(rho / 3800.0f + z / 350.0f);
        const float e2 = ds * (0.019f * exp_approx(rho / 3800.0f + z / 900.0f) +
                               bulge(std::hypot(rho, z / 0.84f)));
        for (std::size_t channel = 0; channel < 3; ++channel)
            intensity[channel] += (thin_color[channel] * e1 + thick_color[channel] * e2) * transmission(tau, channel);
        tau += ds * m[1] * exp_approx(rho / 3800.0f + z / 186.0f);
        if (tau > 4.0f) break;
        p = {p.x + n.x * ds, p.y + n.y * ds, p.z + n.z * ds};
        travelled += ds;
        ds = ds1 + ds2 * z;
    }
    result.optical_depth = tau;
    result.intensity = {std::min(1.0f, intensity[0] * 0.0035f), std::min(1.0f, intensity[1] * 0.0035f), std::min(1.0f, intensity[2] * 0.0035f)};
    result.transmittance = {transmission(tau, 0), transmission(tau, 1), transmission(tau, 2)};
    return result;
}

OurGalaxyPointExtinction OurGalaxyRadiativeModel::point_extinction(
    OurGalaxyGalacticVector observer, OurGalaxyGalacticVector point, float step_pc) const {
    if (!finite(observer) || !finite(point) || !std::isfinite(step_pc) || step_pc < 1 || step_pc > 1000)
        throw std::invalid_argument("our galaxy: invalid point extinction input");
    if (std::max({std::abs(observer.x), std::abs(observer.y), std::abs(observer.z),
                  std::abs(point.x), std::abs(point.y), std::abs(point.z)}) > 1.0e7f)
        throw std::out_of_range("our galaxy: point extinction position out of range");
    const OurGalaxyGalacticVector delta{point.x-observer.x, point.y-observer.y, point.z-observer.z};
    const float length = std::hypot(delta.x, delta.y, delta.z);
    OurGalaxyPointExtinction result;
    // 原版はゼロ除算するが、同一点には吸収区間がない。
    if (length == 0) return result;
    const OurGalaxyGalacticVector scaled_delta{delta.x, delta.y, delta.z / flattening};
    const float scaled_length = std::hypot(scaled_delta.x, scaled_delta.y, scaled_delta.z);
    const OurGalaxyGalacticVector nq{scaled_delta.x/scaled_length, scaled_delta.y/scaled_length, scaled_delta.z/scaled_length};
    const OurGalaxyGalacticVector start{observer.x, observer.y, observer.z / flattening};
    const float b = nq.x*start.x + nq.y*start.y + nq.z*start.z;
    const float c = start.x*start.x + start.y*start.y + start.z*start.z - radius*radius;
    const float disc = b*b-c;
    if (disc <= 0) return result;
    const float root = std::sqrt(disc);
    const float t1 = std::max(0.0f, -b-root), t2 = std::min(scaled_length, -b+root);
    if (t1 >= t2) return result;
    float x = start.x+t1*nq.x, y = start.y+t1*nq.y, z = start.z+t1*nq.z;
    const OurGalaxyGalacticVector n{delta.x/length, delta.y/length, delta.z/length};
    const float cs = std::max(std::abs(n.z), 0.3f);
    const float ds1 = step_pc/1.27f/cs, ds2 = 0.27f/1.27f/cs;
    float ds = ds1+std::abs(z)*ds2, travelled = 0, tau = 0;
    // 公式の点光源用は楕円座標の z と区間長をそのまま使い、dust map は参照しない。
    while (travelled < t2-t1) {
        if (++result.steps > 100000) throw std::runtime_error("our galaxy: point extinction step limit exceeded");
        const float rho = std::hypot(x, y);
        tau += ds * extinction_base * exp_approx(rho/3800.0f+std::abs(z)/186.0f);
        if (tau > 3.0f) break;
        x += n.x*ds; y += n.y*ds; z += n.z*ds; travelled += ds;
        ds = ds1+std::abs(z)*ds2;
    }
    result.optical_depth = tau;
    result.visible = tau <= 2.9f;
    result.transmittance = {transmission(tau, 0), transmission(tau, 1), transmission(tau, 2)};
    return result;
}

OurGalaxyRgb compose_our_galaxy(OurGalaxyRgb background, const OurGalaxyRadiativeResult& ray, float alpha) {
    if (!finite(background) || !finite(ray.intensity) || !finite(ray.transmittance) || !std::isfinite(alpha) || alpha < 0 || alpha > 1)
        throw std::invalid_argument("our galaxy: invalid composition input");
    const auto channel = [alpha](float bg, float transmission_value, float intensity) {
        return bg * ((1.0f - alpha) + alpha * transmission_value) + alpha * intensity;
    };
    return {channel(background.r, ray.transmittance.r, ray.intensity.r),
            channel(background.g, ray.transmittance.g, ray.intensity.g),
            channel(background.b, ray.transmittance.b, ray.intensity.b)};
}
} // namespace mitaka
