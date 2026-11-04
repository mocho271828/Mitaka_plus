#include "star_brightness.hpp"
#include "display_options.hpp"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <limits>
#include <stdexcept>

using namespace mitaka::gui;
namespace {
int checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class F> void rejects(F operation, const char *message) {
    try { operation(); } catch (const std::invalid_argument&) { check(true, message); return; }
    check(false, message);
}
bool close(double a, double b, double tolerance = 1e-6) {
    return std::abs(a - b) <= tolerance * std::max({1.0, std::abs(a), std::abs(b)});
}
}
int main() {
    try {
        const double infinity = std::numeric_limits<double>::infinity();
        const double nan = std::numeric_limits<double>::quiet_NaN();
        const float minimum = std::numeric_limits<float>::denorm_min();
        const float maximum = std::numeric_limits<float>::max();
        check(checked_star_brightness(1) == 1 && checked_star_brightness(minimum) == minimum &&
            checked_star_brightness(maximum) == maximum, "positive float endpoints accepted");
        check(checked_star_brightness(1.23456789012) == static_cast<float>(1.23456789012), "round once to float");
        for (double value : {0.0, -0.0, -1.0, nan, infinity, -infinity,
                static_cast<double>(maximum) * 2, static_cast<double>(minimum) / 4})
            rejects([&] { checked_star_brightness(value); }, "invalid brightness rejected");
        check(close(brighter_star_brightness(1), 0.63095734) &&
            close(darker_star_brightness(1), 1.58489319), "documented menu directions use float exponent");
        check(close(darker_star_brightness(brighter_star_brightness(1)), 1), "bright/dark roundtrip");
        rejects([&] { darker_star_brightness(maximum); }, "darken overflow rejected");
        for (float value : {0.0f, -1.0f, std::numeric_limits<float>::infinity()}) {
            auto options = StarDisplayOptions{}; options.brightness = value;
            rejects([&] { validate_star_display(options); }, "display rejects invalid brightness");
        }
        validate_star_display(StarDisplayOptions{});
        for (double magnitude : {-30.0, -1.0, 0.0, 3.0, 8.0, 20.0, 1e308}) {
            const auto original = star_point_appearance(magnitude, 1);
            check(original.radius == std::clamp(2.8 - magnitude * 0.32, 0.55, 3.6) &&
                original.opacity == std::clamp(1.2 - magnitude * 0.07, 0.3, 1.0), "default keeps existing native points");
            for (float brightness : {0.25f, 0.5f, 2.0f, 4.0f}) {
                const auto appearance = star_point_appearance(magnitude, brightness);
                check(close(appearance.radius * appearance.radius * appearance.opacity,
                    original.radius * original.radius * original.opacity / brightness), "area times alpha scales inversely with L_ref");
            }
            const auto capped = star_point_appearance(magnitude, minimum);
            const auto faint = star_point_appearance(magnitude, maximum);
            check(capped.radius == 32 && capped.opacity == 1 && faint.opacity > 0 &&
                faint.radius == original.radius, "extreme values stay finite with native radius budget");
        }
        rejects([&] { star_point_appearance(nan, 1); }, "nonfinite magnitude rejected");
        StarBrightnessTransition transition;
        check(!transition.active() && !transition.sample(0), "idle produces no update");
        check(transition.begin(1, 9, 4, 100), "start interpolation");
        check(transition.sample(100) == 1 && transition.active(), "exact start");
        check(close(*transition.sample(101), 5 - 2 * std::sqrt(2.0)), "quarter cosine differs from linear");
        check(transition.sample(102) == 5, "halfway cosine midpoint");
        for (double invalid : {-1.0, nan, infinity}) {
            rejects([&] { transition.begin(5, 9, invalid, 102); }, "invalid duration rejected");
            check(transition.active() && transition.sample(102) == 5, "invalid request preserves interpolation");
        }
        rejects([&] { transition.begin(5, 0, 2, 102); }, "invalid target rejected");
        rejects([&] { transition.begin(0, 9, 2, 102); }, "invalid current rejected");
        rejects([&] { transition.begin(5, 9, 2, nan); }, "invalid initial clock rejected");
        rejects([&] { transition.sample(101); }, "backwards sampling rejected");
        rejects([&] { transition.sample(infinity); }, "invalid sampling clock rejected");
        check(!transition.begin(5, 5, 1, 102), "same current request preserves existing target");
        check(transition.sample(104) == 9 && !transition.active(), "finish exact target at deadline");
        check(!transition.sample(105), "completed produces no update");
        transition.begin(9, 1, 4, 200);
        check(transition.sample(202) == 5, "reverse interpolation midpoint");
        transition.begin(5, 3, 2, 202);
        check(transition.sample(203) == 4 && transition.sample(204) == 3, "replacement starts from current value");
        transition.begin(3, 7, 0, 300);
        check(transition.sample(300) == 7 && !transition.active(), "zero duration immediately finishes");
        transition.begin(7, 1, 1, 400); transition.cancel();
        check(!transition.active() && !transition.sample(401), "cancel does not produce target update");
        transition.begin(minimum, maximum, 100, 0);
        float previous = minimum;
        for (int sample = 0; sample <= 1000; ++sample) {
            const float value = *transition.sample(sample / 10.0);
            check(std::isfinite(value) && value >= previous && value <= maximum, "extreme endpoints remain bounded monotonic");
            previous = value;
        }
        transition.begin(1, 2, 1, -std::numeric_limits<double>::max());
        check(transition.sample(std::numeric_limits<double>::max()) == 2, "huge elapsed duration completes without overflow effect");
        std::printf("Star brightness tests passed: %d checks\n", checks);
        return 0;
    } catch (const std::exception& error) {
        std::fprintf(stderr, "Star brightness test failed: %s\n", error.what());
        return 1;
    }
}
