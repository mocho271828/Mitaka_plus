#include "mitaka/astronomy.hpp"
#include "mitaka/catalog.hpp"
#include "mitaka/ephemeris.hpp"

#include <cmath>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {
double parse_jd(const char* argument) {
    const std::string text(argument);
    std::size_t consumed = 0;
    const double value = std::stod(text, &consumed);
    if (consumed != text.size() || !std::isfinite(value)) {
        throw std::invalid_argument("JD must be a finite number");
    }
    return value;
}

void usage() {
    std::cerr << "Usage: core_probe hip FILE\n"
              << "       core_probe constellations FILE\n"
              << "       core_probe cf96 FILE [JD]\n"
              << "       core_probe trajectory FILE [JD]\n"
              << "       core_probe planets JD\n";
}
}

int main(int argc, char** argv) {
    if (argc < 3 || argc > 4) { usage(); return 2; }
    try {
        const std::string command(argv[1]);
        std::cout << std::setprecision(16);
        if (command == "hip" && argc == 3) {
            const auto records = mitaka::load_hipparcos(argv[2]);
            std::cout << "Hipparcos records=" << records.size() << '\n';
        } else if (command == "constellations" && argc == 3) {
            const auto records = mitaka::load_constellations(argv[2]);
            std::cout << "Constellation records=" << records.size() << '\n';
        } else if (command == "cf96") {
            const auto ephemeris = mitaka::Cf96Ephemeris::load(argv[2]);
            const double jd = argc == 4 ? parse_jd(argv[3]) : 2451545.0;
            std::cout << "CF96 planets=" << ephemeris.planet_count() << " JD=" << jd
                      << " position=AU velocity=AU/day frame=J2000-equatorial\n";
            for (std::size_t i = 0; i < ephemeris.planet_count(); ++i) {
                const auto state = ephemeris.state(i, jd);
                std::cout << i;
                for (double value : state.position_au) { std::cout << ' ' << value; }
                for (double value : state.velocity_au_per_day) { std::cout << ' ' << value; }
                std::cout << '\n';
            }
        } else if (command == "trajectory") {
            const auto trajectory = mitaka::Trajectory::load(argv[2]);
            const auto range = trajectory.time_range();
            const double jd = argc == 4 ? parse_jd(argv[3]) : range.first;
            std::cout << "Trajectory segments=" << trajectory.segment_count()
                      << " JD-range=" << range.first << ',' << range.second
                      << " sample-JD=" << jd << " position=km\n";
            for (double value : trajectory.position_km(jd)) { std::cout << value << ' '; }
            std::cout << '\n';
        } else if (command == "planets" && argc == 3) {
            const double jd = parse_jd(argv[2]);
            std::cout << "Mean planets JD=" << jd << " position=AU frame=ecliptic\n";
            for (int i = 0; i < 9; ++i) {
                const auto state = mitaka::mean_planet_state(static_cast<mitaka::Planet>(i), jd);
                std::cout << i << ' ' << state.position_au.x << ' '
                          << state.position_au.y << ' ' << state.position_au.z << '\n';
            }
        } else { usage(); return 2; }
    } catch (const std::exception& error) {
        std::cerr << "core_probe: " << error.what() << '\n';
        return 1;
    }
}
