/*
Copyright (c) 2007-2015   Tsunehiko Kato  and  4D2U Project, National Astronomical Observatory of Japan

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

#pragma once
#include "mitaka/atmosphere.hpp"

#include <cmath>
#include <stdexcept>

namespace mitaka::atmosphere_detail {
constexpr double pi = 3.141592653589793238462643383279502884;
inline Vec3 add(Vec3 a, Vec3 b) { return {a.x+b.x, a.y+b.y, a.z+b.z}; }
inline Vec3 subtract(Vec3 a, Vec3 b) { return {a.x-b.x, a.y-b.y, a.z-b.z}; }
inline Vec3 multiply(Vec3 a, double c) { return {a.x*c, a.y*c, a.z*c}; }
inline Vec3 divide(Vec3 a, double c) { return multiply(a,1.0/c); }
inline double dot(Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; }
inline bool finite(Vec3 v) { return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z); }

// mtk_approx_func.h:49。exp(-x) への置換は光学的な値を変えるので行わない。
inline double attenuation_approximation(double x) {
    const double x2 = x*x, x3 = x*x2;
    const double a = 1.0 + 0.2507213*x + 0.0292732*x2 + 0.0038278*x3;
    const double a2 = a*a;
    return 1.0/(a2*a2);
}

inline std::array<double, 3> scattering_coefficients(double density) {
    // 元の波長は float で保持した後に double の pow へ渡される。
    constexpr float wavelengths[] = {700.0*1e-9, 546.1*1e-9, 435.8*1e-9};
    constexpr double ns = 2.5469e25, ns_1 = 295e-6, depolarization = 0.031;
    const double sigma = 32.0*pi*pi*pi/3.0*(ns_1*ns_1)/(ns*ns)*
        (6+3*depolarization)/(6-7*depolarization);
    return {density*(sigma/std::pow(wavelengths[0],4)),
            density*(sigma/std::pow(wavelengths[1],4)),
            density*(sigma/std::pow(wavelengths[2],4))};
}

inline void validate_ray(const AtmosphereRay& ray, double ground_radius) {
    if (ray.maximum_distance_m && (!std::isfinite(*ray.maximum_distance_m) || *ray.maximum_distance_m < 0))
        throw std::invalid_argument("invalid atmosphere ray distance limit");
    if (!finite(ray.observer_position_m) || !finite(ray.view_direction) || !finite(ray.sun_direction))
        throw std::invalid_argument("non-finite atmosphere ray");
    if (std::abs(std::hypot(ray.view_direction.x,ray.view_direction.y,ray.view_direction.z)-1) > 2e-6 ||
        std::abs(std::hypot(ray.sun_direction.x,ray.sun_direction.y,ray.sun_direction.z)-1) > 2e-6)
        throw std::invalid_argument("atmosphere directions must be unit vectors");
    if (std::hypot(ray.observer_position_m.x,ray.observer_position_m.y,ray.observer_position_m.z) < ground_radius)
        throw std::invalid_argument("atmosphere observer is below the ground radius");
    if (!std::isfinite(dot(ray.observer_position_m,ray.observer_position_m)))
        throw std::out_of_range("atmosphere ray exceeds numerical range");
}

inline AtmosphereRgb checked(AtmosphereRgb value) {
    if (!std::isfinite(value.r) || !std::isfinite(value.g) || !std::isfinite(value.b) ||
        value.r < 0 || value.g < 0 || value.b < 0)
        throw std::out_of_range("atmosphere intensity exceeds numerical range");
    return value;
}
} // namespace mitaka::atmosphere_detail
