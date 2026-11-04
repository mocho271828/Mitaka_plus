#include "mitaka/catalog.hpp"
#include "mitaka/ephemeris.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <filesystem>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
void check(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}
template <std::size_t Size>
void check_finite(const std::array<double, Size>& values) {
    for (double value : values) check(std::isfinite(value), "non-finite value in loaded data or evaluation");
}
void test_catalogs(const std::filesystem::path& root) {
    const auto hip_path = root / "data/hip.dat";
    const auto stars = mitaka::load_hipparcos(hip_path);
    // 表示上の視差フィルタなどで元レコードが失われていないことを確認する。
    check(stars.size() == std::filesystem::file_size(hip_path) / 45,
          "Hipparcos loader did not preserve every record");
    for (const auto& star : stars) {
        check_finite(std::array<double, 8>{
            star.right_ascension_degrees, star.declination_degrees,
            star.parallax_mas, star.parallax_error_mas,
            star.proper_motion_ra_mas_per_year, star.proper_motion_dec_mas_per_year,
            star.apparent_v_magnitude, star.color_b_minus_v});
    }
    std::cout << "Hipparcos records=" << stars.size() << '\n';
    const auto constellation_path = root / "data/constellation_HIP.dat";
    if (!std::filesystem::exists(constellation_path)) {
        std::cout << "Constellation catalog absent (optional)\n";
        return;
    }
    const auto constellations = mitaka::load_constellations(constellation_path);
    std::size_t lines = 0;
    std::size_t boundary_points = 0;
    for (const auto& constellation : constellations) {
        check_finite(std::array<double, 2>{constellation.right_ascension_degrees,
                                          constellation.declination_degrees});
        lines += constellation.hip_lines.size();
        boundary_points += constellation.boundary.size();
        for (const auto& point : constellation.boundary)
            check_finite(std::array<double, 2>{point.right_ascension_hours, point.declination_degrees});
    }
    std::cout << "Constellation records=" << constellations.size()
              << " lines=" << lines << " boundary-points=" << boundary_points << '\n';
}
void test_cf96(const std::filesystem::path& root) {
    const auto ephemeris = mitaka::Cf96Ephemeris::load(root / "data/cf96.dat");
    check(ephemeris.planet_count() > 0, "empty CF96 ephemeris");
    for (std::size_t planet = 0; planet < ephemeris.planet_count(); ++planet) {
        const auto range = ephemeris.time_range(planet);
        check_finite(std::array<double, 2>{range.first, range.second});
        check(range.first <= range.second, "invalid CF96 time range");
        const double middle = range.first + (range.second - range.first) / 2;
        for (double time : {range.first, middle, range.second}) {
            const auto state = ephemeris.state(planet, time);
            check_finite(state.position_au);
            check_finite(state.velocity_au_per_day);
        }
    }
    std::cout << "CF96 planets=" << ephemeris.planet_count() << " samples-per-planet=3\n";
}
std::vector<std::filesystem::path> trajectory_paths(const std::filesystem::path& root) {
    std::vector<std::filesystem::path> paths;
    for (const auto* name : {"data", "spacecraft"}) {
        const auto directory = root / name;
        if (!std::filesystem::exists(directory)) continue;
        for (const auto& entry : std::filesystem::directory_iterator(directory))
            if (entry.is_regular_file() && entry.path().extension() == ".ppi") paths.push_back(entry.path());
    }
    std::sort(paths.begin(), paths.end());
    return paths;
}
void test_trajectories(const std::filesystem::path& root) {
    const auto paths = trajectory_paths(root);
    std::size_t segment_count = 0;
    std::size_t gap_count = 0;
    for (const auto& path : paths) {
        const auto trajectory = mitaka::Trajectory::load(path);
        check(trajectory.segment_count() > 0, "empty trajectory: " + path.string());
        check(trajectory.segment_count() == std::filesystem::file_size(path) / 128,
              "trajectory loader did not preserve every segment: " + path.string());
        const auto range = trajectory.time_range();
        check_finite(std::array<double, 2>{range.first, range.second});
        check(range.first < range.second, "invalid trajectory time range: " + path.string());
        check_finite(trajectory.position_km(range.first));
        check_finite(trajectory.position_km(range.second));
        bool middle_in_gap = false;
        try {
            const double middle = range.first + (range.second - range.first) / 2;
            check_finite(trajectory.position_km(middle));
        } catch (const std::out_of_range&) {
            // 全体範囲内の空隙はローダーが許容するため、失敗と区別して記録する。
            middle_in_gap = true;
            ++gap_count;
        }
        segment_count += trajectory.segment_count();
        std::cout << "Trajectory " << path.lexically_relative(root).generic_string()
                  << " segments=" << trajectory.segment_count()
                  << " midpoint=" << (middle_in_gap ? "gap" : "evaluated") << '\n';
    }
    std::cout << "Trajectories files=" << paths.size() << " segments=" << segment_count
              << " midpoint-gaps=" << gap_count << '\n';
}
} // namespace

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "Usage: test_data APP_ROOT\n";
        return 2;
    }
    try {
        const auto root = std::filesystem::path(argv[1]);
        check(std::filesystem::is_directory(root), "APP_ROOT must be a directory");
        test_catalogs(root);
        test_cf96(root);
        test_trajectories(root);
        std::cout << "Read-only data integration tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "data integration test: " << error.what() << '\n';
        return 1;
    }
}
