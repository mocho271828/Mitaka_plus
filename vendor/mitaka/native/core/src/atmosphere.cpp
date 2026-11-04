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

AtmosphereRgb integrate_ray(double ground, double outer, double height,
    const AtmosphereRay& ray, const std::array<double,3>& coefficients,
    double start, double end, std::size_t samples) {
    const double scaled_ground = ground/height, scaled_outer = outer/height;
    const Vec3 step = multiply(ray.view_direction,(end-start)/(samples-1)/height);
    Vec3 point = add(multiply(ray.view_direction,start/height),divide(ray.observer_position_m,height));
    std::array<float,3> intensity{};
    double view_depth = 0;
    for (std::size_t i=0; i<samples; ++i) {
        const double point_squared = dot(point,point);
        if (!std::isfinite(point_squared)) throw std::out_of_range("atmosphere scaled ray exceeds numerical range");
        const double density = attenuation_approximation(std::sqrt(point_squared)-scaled_ground);
        view_depth += density;
        const double b = dot(point,ray.sun_direction);
        const double discriminant = b*b-point_squared+scaled_outer*scaled_outer;
        const double sun_distance = discriminant <= 0 ? -b : -b+std::sqrt(discriminant);
        const auto sun_samples = samples-i+1;
        const Vec3 sun_step = multiply(ray.sun_direction,sun_distance/(sun_samples-1));
        Vec3 sun_point = point;
        double sun_depth = 0;
        for (std::size_t j=0; j<sun_samples; ++j) {
            sun_depth += attenuation_approximation(std::sqrt(dot(sun_point,sun_point))-scaled_ground);
            sun_point = add(sun_point,sun_step);
        }
        const double view_step_m = (end-start)/samples;
        const double sun_step_m = (sun_distance*height)/sun_samples;
        const double depth = view_depth*view_step_m + sun_depth*sun_step_m;
        for (std::size_t channel=0; channel<3; ++channel) {
            const double optical_depth = coefficients[channel]*depth;
            if (!std::isfinite(optical_depth)) throw std::out_of_range("atmosphere optical depth exceeds numerical range");
            intensity[channel] += density*attenuation_approximation(optical_depth);
        }
        point = add(point,step);
    }
    const float step_m = (end-start)/(samples-1);
    for (std::size_t channel=0; channel<3; ++channel) intensity[channel] *= coefficients[channel]*step_m;
    return checked({intensity[0],intensity[1],intensity[2]});
}

void validate_parameters(const AtmosphereParameters& p, std::size_t samples) {
    for (double value : {p.ground_radius_m,p.outer_radius_m,p.scale_height_m,
                         p.surface_number_density_per_m3,p.incident_intensity})
        if (!std::isfinite(value)) throw std::invalid_argument("non-finite atmosphere parameter");
    if (p.ground_radius_m <= 0 || p.outer_radius_m <= p.ground_radius_m || p.scale_height_m <= 0 ||
        p.surface_number_density_per_m3 < 0 || p.incident_intensity < 0 || samples < 2 || samples > 4096)
        throw std::invalid_argument("invalid atmosphere radius, scale height, density, intensity or sample count");
    if (p.ground_radius_m*p.ground_radius_m == 0 ||
        !std::isfinite(p.outer_radius_m*p.outer_radius_m) ||
        (p.ground_radius_m/p.scale_height_m)*(p.ground_radius_m/p.scale_height_m) == 0 ||
        !std::isfinite((p.outer_radius_m/p.scale_height_m)*(p.outer_radius_m/p.scale_height_m)))
        throw std::out_of_range("atmosphere geometry exceeds numerical range");
}
} // namespace

AtmosphereRgb atmosphere_single_scattering(const AtmosphereParameters& p,
    const AtmosphereRay& ray, std::size_t samples) {
    validate_parameters(p,samples);
    validate_ray(ray,p.ground_radius_m);
    if (p.incident_intensity == 0 || p.surface_number_density_per_m3 == 0) return {};
    const auto& origin = ray.observer_position_m;
    const auto& view = ray.view_direction;
    const auto& sun = ray.sun_direction;
    const double b = dot(view,origin), d0 = b*b-dot(origin,origin);
    const double atmosphere_d = d0+p.outer_radius_m*p.outer_radius_m;
    if (atmosphere_d <= 0) return {};
    double start = std::max(0.0,-b-std::sqrt(atmosphere_d));
    double end = -b+std::sqrt(atmosphere_d);
    if (end <= 0) return {};
    if (ray.maximum_distance_m) end = std::min(end,*ray.maximum_distance_m);
    if (end <= start) return {};

    // 原式の 0.9999 は交差だけでなく密度基準と影にも適用される。理由は原典未記載。
    const double ground = p.ground_radius_m*0.9999;
    const double ground_d = d0+ground*ground;
    if (ground_d >= 0) {
        const double near_ground = -b-std::sqrt(ground_d), far_ground = -b+std::sqrt(ground_d);
        if (start < far_ground && start <= near_ground && end > near_ground) end = near_ground;
    }
    const Vec3 view_perp = subtract(view,multiply(sun,dot(view,sun)));
    const Vec3 origin_perp = subtract(origin,multiply(sun,dot(origin,sun)));
    const double a = dot(view_perp,view_perp), shadow_b = dot(view_perp,origin_perp);
    const double shadow_d = shadow_b*shadow_b-a*(dot(origin_perp,origin_perp)-ground*ground);
    std::optional<std::array<double,2>> second_region;
    if (shadow_d > 0) {
        const double near_shadow = (-shadow_b-std::sqrt(shadow_d))/a;
        const double far_shadow = (-shadow_b+std::sqrt(shadow_d))/a;
        if (start < far_shadow) {
            const double el = dot(view,sun), origin_sun = dot(origin,sun);
            if (start >= near_shadow) {
                if (start*el+origin_sun < 0) {
                    if (end <= far_shadow) return {};
                    start = far_shadow;
                }
            } else if (near_shadow*el+origin_sun < 0 && end > near_shadow) {
                if (end > far_shadow) second_region = {{far_shadow,end}};
                end = near_shadow;
            }
        }
    }
    const auto coefficients = scattering_coefficients(p.surface_number_density_per_m3);
    auto result = integrate_ray(ground,p.outer_radius_m,p.scale_height_m,ray,coefficients,start,end,samples);
    if (second_region) {
        const auto second = integrate_ray(ground,p.outer_radius_m,p.scale_height_m,ray,coefficients,
                                          (*second_region)[0],(*second_region)[1],samples);
        result.r += second.r; result.g += second.g; result.b += second.b;
    }
    const double cosine = dot(view,multiply(sun,-1));
    const double phase = 3.0/(16.0*3.141592654)*(1+cosine*cosine);
    const double factor = phase*p.incident_intensity;
    result.r *= factor; result.g *= factor; result.b *= factor;
    return checked(result);
}

AtmosphereDisplaySample compose_atmosphere_display(AtmosphereRgb single,
    AtmosphereRgb multiple, double incident_intensity) {
    checked(single); checked(multiple);
    if (!std::isfinite(incident_intensity) || incident_intensity < 0)
        throw std::invalid_argument("invalid atmosphere display intensity");
    // 原 GUI の I0 と RGBf は float。各積を float に丸めてから加算する。
    const float intensity = incident_intensity;
    const AtmosphereRgb scaled{intensity*multiple.r,intensity*multiple.g,intensity*multiple.b};
    const auto result = checked({single.r+scaled.r,single.g+scaled.g,single.b+scaled.b});
    return {result,std::min(1.0f,4.0f*std::max({result.r,result.g,result.b}))};
}
} // namespace mitaka
