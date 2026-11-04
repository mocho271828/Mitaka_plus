#include "radius_display.hpp"

#include <array>
#include <cmath>
#include <cstdio>
#include <limits>
#include <stdexcept>

using namespace mitaka::gui;
namespace {
int checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class F> void rejects(F operation, const char* message) {
    try { operation(); }
    catch (const std::invalid_argument&) { check(true, message); return; }
    check(false, message);
}
bool same(const RadiusDisplayOptions& a, const RadiusDisplayOptions& b) {
    return a.space_planet == b.space_planet && a.space_sun == b.space_sun &&
        a.planetarium_planet == b.planetarium_planet &&
        a.planetarium_sun_moon == b.planetarium_sun_moon;
}
} // namespace

int main() {
    try {
        constexpr auto space = RadiusDisplayContext::space;
        constexpr auto sky = RadiusDisplayContext::planetarium;
        const double infinity = std::numeric_limits<double>::infinity();
        const double nan = std::numeric_limits<double>::quiet_NaN();
        const float minimum = std::numeric_limits<float>::denorm_min();
        const float maximum = std::numeric_limits<float>::max();
        const RadiusDisplayOptions defaults;
        check(same(defaults, {1, 1, 1, 1}), "binary stored defaults are all one");
        check(static_cast<int>(RadiusScaleMode::keep_radius) == 0 &&
            static_cast<int>(RadiusScaleMode::keep_orbit) == 1, "legacy scale mode constants");
        validate_radius_scale_mode(RadiusScaleMode::keep_radius);
        validate_radius_scale_mode(RadiusScaleMode::keep_orbit);
        for (int invalid : {-1, 2, 100})
            rejects([&] { validate_radius_scale_mode(static_cast<RadiusScaleMode>(invalid)); }, "invalid mode rejected");
        check(checked_radius_scale(minimum) == minimum && checked_radius_scale(maximum) == maximum,
            "positive float endpoints retained");
        check(checked_radius_scale(1.234567890123) == static_cast<float>(1.234567890123),
            "legacy storage rounds once to float");
        for (double invalid : {0.0, -0.0, -1.0, nan, infinity, -infinity,
                double(maximum) * 2, double(minimum) / 4}) {
            rejects([&] { checked_radius_scale(invalid); }, "invalid scale rejected");
            for (std::size_t index = 0; index < 4; ++index) {
                std::array<double, 4> values{2, 3, 4, 5}; values[index] = invalid;
                auto unchanged = defaults;
                rejects([&] { unchanged = checked_radius_display_options(values[0], values[1], values[2], values[3]); },
                    "invalid component rejects complete candidate");
                check(same(unchanged, defaults), "failed factory cannot partially assign options");
            }
        }
        // 異なる4値で、説明書の sun/planet 順を誤採用していないことを検出する。
        const auto distinct = checked_radius_display_options(2, 3, 4, 5);
        check(planet_radius_display_factor(distinct, space) == 2 &&
            planet_radius_display_factor(distinct, sky) == 4, "planet consumes first and third values");
        check(sun_radius_display_factor(distinct, space) == 3 &&
            sun_radius_display_factor(distinct, sky) == 5, "sun consumes second and fourth values");
        check(moon_radius_display_factor(distinct, space) == 2, "space moon consumes first value");
        check(moon_radius_display_factor(distinct, sky) == 5 * double(2.0f / 20.0f),
            "planetarium moon combines fourth value with derived orbit factor");
        check(moon_orbit_display_factor(defaults) == 1, "real scale preserves real moon orbit");
        for (float neighbour : {std::nextafter(1.0f, 0.0f), std::nextafter(1.0f, 2.0f)}) {
            auto options = defaults; options.space_planet = neighbour;
            check(moon_orbit_display_factor(options) == double(neighbour / 20.0f),
                "only exact float one has special moon branch");
        }
        const std::array<RadiusDisplayOptions, 4> presets{{{1, 1, 1, 1}, {500, 1, 20, 1},
            {1000, 25, 100, 5}, {1500, 50, 200, 10}}};
        for (const auto& options : presets) {
            for (auto context : {space, sky}) {
                const double selected = context == space ? options.space_planet : options.planetarium_planet;
                for (float response : {0.0f, 0.025f, 0.25f, 1.0f, 2.0f}) {
                    const double factor = planet_radius_display_factor(options, context, response);
                    check(factor == 1 + (selected - 1) * double(response), "planet data response formula");
                    const double physical = 71492;
                    check(scaled_display_radius(physical, factor) == physical * factor && physical == 71492,
                        "display calculation does not change physical radius");
                }
                check(moon_radius_display_factor(options, context) ==
                    (context == space ? options.space_planet : options.planetarium_sun_moon * moon_orbit_display_factor(options)),
                    "all local presets preserve moon radius formula");
            }
        }
        check(planet_radius_display_factor(presets[2], space, 0.025f) !=
            planet_radius_display_factor(presets[2], space, 0.25f), "language source Jupiter response stays distinct");
        for (auto context : {space, sky}) {
            check(planet_radius_display_factor(defaults, context, maximum) == 1, "real scale independent of finite response");
            check(sun_radius_display_factor(defaults, context) == 1 &&
                moon_radius_display_factor(defaults, context) == 1, "real sun and moon radius");
            for (float response : {-1.0f, float(infinity), float(nan)})
                rejects([&] { planet_radius_display_factor(distinct, context, response); }, "invalid response rejected");
        }
        auto shrinking = defaults; shrinking.space_planet = 0.25f;
        rejects([&] { planet_radius_display_factor(shrinking, space, 2); }, "negative effective radius rejected");
        shrinking.space_planet = 0.5f;
        rejects([&] { planet_radius_display_factor(shrinking, space, 2); }, "zero effective radius rejected");
        shrinking.space_planet = minimum;
        check(planet_radius_display_factor(shrinking, space, 1) == minimum,
            "unit response preserves a positive subnormal planet scale");
        rejects([&] { moon_orbit_display_factor(shrinking); }, "moon float division underflow rejected");
        rejects([&] { moon_radius_display_factor(shrinking, sky); }, "moon radius does not silently disappear");
        check(moon_radius_display_factor(shrinking, space) == minimum, "space moon does not require orbit-derived factor");
        auto huge = checked_radius_display_options(maximum, maximum, maximum, maximum);
        check(std::isfinite(moon_radius_display_factor(huge, sky)) &&
            std::isfinite(planet_radius_display_factor(huge, space, maximum)), "large valid products remain double");
        for (float RadiusDisplayOptions::* member : {&RadiusDisplayOptions::space_planet, &RadiusDisplayOptions::space_sun,
                &RadiusDisplayOptions::planetarium_planet, &RadiusDisplayOptions::planetarium_sun_moon}) {
            auto invalid = defaults; invalid.*member = 0;
            rejects([&] { validate_radius_display_options(invalid); }, "invalid stored options rejected");
            rejects([&] { planet_radius_display_factor(invalid, space); }, "planet checks whole candidate");
            rejects([&] { sun_radius_display_factor(invalid, sky); }, "sun checks whole candidate");
            rejects([&] { moon_radius_display_factor(invalid, space); }, "moon checks whole candidate");
        }
        const auto bad_context = static_cast<RadiusDisplayContext>(9);
        rejects([&] { planet_radius_display_factor(defaults, bad_context); }, "planet rejects unknown context");
        rejects([&] { sun_radius_display_factor(defaults, bad_context); }, "sun rejects unknown context");
        rejects([&] { moon_radius_display_factor(defaults, bad_context); }, "moon rejects unknown context");
        for (double invalid : {0.0, -1.0, nan, infinity}) {
            rejects([&] { scaled_display_radius(invalid, 1); }, "invalid physical radius rejected");
            rejects([&] { scaled_display_radius(1, invalid); }, "invalid computed factor rejected");
        }
        rejects([&] { scaled_display_radius(std::numeric_limits<double>::max(), 2); }, "double overflow rejected");
        rejects([&] { scaled_display_radius(std::numeric_limits<double>::denorm_min(), 0.25); }, "double underflow rejected");
        check(scaled_display_radius(1738.4, 1) == 1738.4, "other satellite radius with factor one unchanged");
        std::printf("Radius display tests passed: %d checks\n", checks);
        return 0;
    } catch (const std::exception& error) {
        std::fprintf(stderr, "Radius display test failed: %s\n", error.what());
        return 1;
    }
}
