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

#include "atmosphere_internal.hpp"

#include <algorithm>

namespace mitaka {
namespace {
using namespace atmosphere_detail;

const std::array<double,500>& acos_table() {
    static const auto table = [] {
        std::array<double,500> values{};
        for (std::size_t i=0; i<values.size(); ++i) {
            const double x = static_cast<double>(i)/(values.size()-1);
            values[i] = x >= 1 ? 0 : std::acos(x);
        }
        return values;
    }();
    return table;
}

// 内向き/外向きで共通の球殻積分。補間積と累積を原版どおり float に丸める。
class ShellIntegral {
public:
    ShellIntegral(const AtmosphereEmissionMap& map, const AtmosphereRay& ray)
        : map_(map), ray_(ray), coefficients_(scattering_coefficients(map.grid().surface_number_density_per_m3)),
          angle_step_(map.grid().maximum_sun_zenith_angle_rad/(map.grid().angle_count-1)) {}

    bool advance(std::size_t radial_index, double next_t) {
        const double radius = map_.radii_m()[radial_index];
        const Vec3 point = add(multiply(ray_.view_direction,next_t),ray_.observer_position_m);
        const double stop = ray_.maximum_distance_m ? std::min(next_t,*ray_.maximum_distance_m) : next_t;
        const double dt = stop-t;
        const double half_density_path = 0.5*attenuation_approximation(
            (radius-map_.grid().ground_radius_m)/map_.grid().scale_height_m)*dt;
        std::array<double,3> half_depth;
        for (std::size_t channel=0; channel<3; ++channel) {
            half_depth[channel] = coefficients_[channel]*half_density_path;
            depth_[channel] += half_depth[channel];
            if (!std::isfinite(depth_[channel])) throw std::out_of_range("atmosphere shell optical depth exceeds numerical range");
        }
        const double cosine = std::clamp(dot(divide(point,radius),ray_.sun_direction),-1.0,1.0);
        if (!std::isfinite(cosine)) throw std::out_of_range("atmosphere shell direction exceeds numerical range");
        const auto index = static_cast<std::size_t>(std::abs(cosine)*499);
        const double angle = cosine >= 0 ? acos_table()[index] : pi-acos_table()[index];
        const double angle_position = angle/angle_step_;
        // 範囲外の角度は原式同様に発光を加えない。整数変換前に上限を検査する。
        if (angle_position < map_.grid().angle_count-1) {
            const auto angle_index = static_cast<std::size_t>(angle_position);
            const float second_weight = (angle_position-angle_index)*dt;
            const float first_weight = dt-second_weight;
            const auto& first = map_.nodes()[radial_index*map_.grid().angle_count+angle_index];
            const auto& second = map_.nodes()[radial_index*map_.grid().angle_count+angle_index+1];
            const AtmosphereRgb emission{first_weight*first.r+second_weight*second.r,
                first_weight*first.g+second_weight*second.g,first_weight*first.b+second_weight*second.b};
            intensity.r += attenuation_approximation(depth_[0])*emission.r;
            intensity.g += attenuation_approximation(depth_[1])*emission.g;
            intensity.b += attenuation_approximation(depth_[2])*emission.b;
        }
        for (std::size_t channel=0; channel<3; ++channel) depth_[channel] += half_depth[channel];
        t = stop;
        return stop < next_t || (ray_.maximum_distance_m && stop >= *ray_.maximum_distance_m);
    }
    double t = 0;
    AtmosphereRgb intensity;
private:
    const AtmosphereEmissionMap& map_;
    const AtmosphereRay& ray_;
    const std::array<double,3> coefficients_;
    const double angle_step_;
    std::array<double,3> depth_{};
};
} // namespace

AtmosphereRgb atmosphere_multiple_scattering(const AtmosphereEmissionMap& map, const AtmosphereRay& ray) {
    validate_ray(ray,map.grid().ground_radius_m);
    const double radius = std::sqrt(dot(ray.observer_position_m,ray.observer_position_m));
    const double b = dot(ray.observer_position_m,ray.view_direction);
    // 地表から内向きの長さゼロの光路。原式の交点減算による微小な負の dt を避ける。
    if (radius <= map.grid().ground_radius_m && b < 0) return {};
    const double d0 = b*b-radius*radius;
    const double outer_d = d0+map.grid().outer_radius_m*map.grid().outer_radius_m;
    if (!std::isfinite(outer_d)) throw std::out_of_range("atmosphere shell geometry exceeds numerical range");
    // 原関数を呼ぶ描画側の前方交差条件を、この独立 API で保証する。
    if (outer_d < 0 || -b+std::sqrt(outer_d) <= 0) return {};

    const auto& radii = map.radii_m();
    std::size_t radial_index = radii.size()-1;
    for (std::size_t i=1; i<radii.size(); ++i) {
        if (radius < radii[i]) { radial_index = i-1; break; }
    }
    ShellIntegral integral(map,ray);
    if (radial_index == radii.size()-1) {
        integral.t = -b-std::sqrt(outer_d);
        radial_index = radii.size()-2;
    }
    if (ray.maximum_distance_m && integral.t >= *ray.maximum_distance_m) return {};
    if (dot(divide(ray.observer_position_m,radius),ray.view_direction) < 0) {
        for (std::size_t i=radial_index;; --i) {
            const double discriminant = d0+radii[i]*radii[i];
            if (discriminant < 0) { radial_index = i; break; }
            if (integral.advance(i,-b-std::sqrt(discriminant))) return checked(integral.intensity);
            if (i == 0) return checked(integral.intensity);
        }
    }
    for (std::size_t i=radial_index+1; i<radii.size(); ++i)
        if (integral.advance(i,-b+std::sqrt(d0+radii[i]*radii[i]))) break;
    return checked(integral.intensity);
}
} // namespace mitaka
