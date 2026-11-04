#include "radius_display.hpp"
#include "sky_model.hpp"

#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
void require_positive(double value, const char* message) {
    if (!std::isfinite(value) || value <= 0) throw std::invalid_argument(message);
}

void validate_context(RadiusDisplayContext context) {
    switch (context) {
    case RadiusDisplayContext::space:
    case RadiusDisplayContext::planetarium: return;
    }
    throw std::invalid_argument("invalid radius display context");
}

void validate_inputs(const RadiusDisplayOptions& options, RadiusDisplayContext context) {
    validate_radius_display_options(options);
    validate_context(context);
}
} // namespace

float checked_radius_scale(double value) {
    require_positive(value, "radius scale must be positive and finite");
    if (value > std::numeric_limits<float>::max())
        throw std::invalid_argument("radius scale exceeds float range");
    const float result = static_cast<float>(value);
    require_positive(result, "radius scale underflows float range");
    return result;
}

RadiusDisplayOptions checked_radius_display_options(double space_planet, double space_sun,
        double planetarium_planet, double planetarium_sun_moon) {
    return {checked_radius_scale(space_planet), checked_radius_scale(space_sun),
        checked_radius_scale(planetarium_planet), checked_radius_scale(planetarium_sun_moon)};
}

void validate_radius_display_options(const RadiusDisplayOptions& options) {
    checked_radius_scale(options.space_planet);
    checked_radius_scale(options.space_sun);
    checked_radius_scale(options.planetarium_planet);
    checked_radius_scale(options.planetarium_sun_moon);
}

void validate_radius_scale_mode(RadiusScaleMode mode) {
    switch (mode) {
    case RadiusScaleMode::keep_radius:
    case RadiusScaleMode::keep_orbit: return;
    }
    throw std::invalid_argument("invalid radius scale mode");
}

double planet_radius_display_factor(const RadiusDisplayOptions& options,
        RadiusDisplayContext context, float response) {
    validate_inputs(options, context);
    if (!std::isfinite(response) || response < 0)
        throw std::invalid_argument("planet radius response must be finite and nonnegative");
    const double scale = context == RadiusDisplayContext::space ?
        options.space_planet : options.planetarium_planet;
    // response=1 は直接返し、小さい scale が減算で消えるのを避ける。
    const double result = response == 1 ? scale : 1 + (scale - 1) * static_cast<double>(response);
    require_positive(result, "planet radius display factor must be positive and finite");
    return result;
}

double sun_radius_display_factor(const RadiusDisplayOptions& options,
        RadiusDisplayContext context) {
    validate_inputs(options, context);
    return context == RadiusDisplayContext::space ?
        options.space_sun : options.planetarium_sun_moon;
}

double moon_orbit_display_factor(const RadiusDisplayOptions& options) {
    validate_radius_display_options(options);
    // 実行版は float の除算後に double 化する。1 だけは縮小しない明示分岐がある。
    const float result = options.space_planet == 1 ? 1 : options.space_planet / 20.0f;
    require_positive(result, "moon orbit display factor underflows float range");
    return result;
}

double moon_radius_display_factor(const RadiusDisplayOptions& options,
        RadiusDisplayContext context) {
    validate_inputs(options, context);
    if (context == RadiusDisplayContext::space) return options.space_planet;
    return scaled_display_radius(options.planetarium_sun_moon, moon_orbit_display_factor(options));
}

double body_marker_display_factor(const RadiusDisplayOptions& options,
        RadiusDisplayContext context, Body body) {
    if (body == Body::sun) return sun_radius_display_factor(options, context);
    if (body == Body::moon) {
        validate_inputs(options, context);
        return context == RadiusDisplayContext::space ? options.space_planet : options.planetarium_sun_moon;
    }
    return planet_radius_display_factor(options, context);
}

double scaled_display_radius(double physical_radius, double display_factor) {
    require_positive(physical_radius, "physical radius must be positive and finite");
    require_positive(display_factor, "radius display factor must be positive and finite");
    const double result = physical_radius * display_factor;
    require_positive(result, "display radius exceeds numeric range");
    return result;
}

} // namespace mitaka::gui
