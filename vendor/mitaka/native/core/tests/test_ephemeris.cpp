#include "mitaka/ephemeris.hpp"

#include <algorithm>
#include <unistd.h>


#include <array>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

namespace {
using Bytes = std::vector<char>;
void check(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}
void near(double actual, double expected, double tolerance = 1e-11) {
    check(std::abs(actual - expected) <= tolerance, "numeric mismatch: " + std::to_string(actual) + " vs " + std::to_string(expected));
}
template <typename Exception, typename Function>
void rejects(Function operation) {
    try { operation(); }
    catch (const Exception&) { return; }
    throw std::runtime_error("expected exception was not raised");
}
void integer(Bytes& bytes, std::uint32_t value) {
    for (int i = 0; i < 4; ++i) bytes.push_back(static_cast<char>((value >> (8 * i)) & 255));
}
void real(Bytes& bytes, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(value));
    for (int i = 0; i < 8; ++i) bytes.push_back(static_cast<char>((bits >> (8 * i)) & 255));
}
void write(const std::filesystem::path& path, const Bytes& bytes) {
    std::ofstream stream(path, std::ios::binary);
    stream.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
    check(static_cast<bool>(stream), "fixture write failed");
}
Bytes cf96_fixture() {
    Bytes bytes{'C', 'F', '9', '6'};
    integer(bytes, 1);
    real(bytes, 2451544.0);
    real(bytes, 2.0);
    integer(bytes, 1); // mx
    integer(bytes, 1); // imax
    integer(bytes, 2); // blocks
    integer(bytes, 1);
    integer(bytes, 1);
    real(bytes, 0.5);
    real(bytes, 1.0);
    for (int block = 0; block < 2; ++block) {
        for (int axis = 0; axis < 3; ++axis) {
            integer(bytes, 2);
            real(bytes, (10.0 * (block + 1) + axis) * 1e10);
            real(bytes, 2e10);
            integer(bytes, 2);
            integer(bytes, 1);
            real(bytes, 3e10);
            real(bytes, 4e10);
            integer(bytes, 1);
            real(bytes, 5e10);
            real(bytes, 6e10);
        }
    }
    return bytes;
}
void append_segment(Bytes& bytes, double start) {
    for (int i = 0; i < 4; ++i) real(bytes, start + i);
    for (int axis = 0; axis < 3; ++axis)
        for (int i = 0; i < 4; ++i) {
            const double t = start + i;
            real(bytes, (axis + 1) * (t * t * t - 2 * t + 7));
        }
}
void test_cf96(const std::filesystem::path& path) {
    auto bytes = cf96_fixture();
    write(path, bytes);
    const auto ephemeris = mitaka::Cf96Ephemeris::load(path);
    check(ephemeris.planet_count() == 1, "CF96 planet count");
    check(ephemeris.time_range(0) == std::make_pair(2451544.0, 2451548.0), "CF96 range");
    const auto center = ephemeris.state(0, 2451545.0);
    for (std::size_t axis = 0; axis < 3; ++axis) {
        near(center.position_au[axis], 13.0 + static_cast<double>(axis));
        near(center.velocity_au_per_day[axis], 9.0);
    }
    const auto boundary = ephemeris.state(0, 2451546.0);
    near(boundary.position_au[0], 20 - 2 + 3 * std::cos(-0.5) + 4 * std::sin(-0.5)
         - (5 * std::cos(-1.0) + 6 * std::sin(-1.0)));
    const auto first = ephemeris.state(0, 2451544.0);
    const auto last = ephemeris.state(0, 2451548.0);
    check(std::isfinite(first.position_au[0]) && std::isfinite(last.position_au[0]), "CF96 endpoint evaluation");
    const double date = 2451544.375;
    const double delta = 1.0 / 1024;
    const auto before = ephemeris.state(0, date - delta);
    const auto after = ephemeris.state(0, date + delta);
    const auto state = ephemeris.state(0, date);
    near(state.velocity_au_per_day[0], (after.position_au[0] - before.position_au[0]) / (2 * delta), 5e-6);
    rejects<std::out_of_range>([&] { ephemeris.state(1, date); });
    rejects<std::out_of_range>([&] { ephemeris.state(0, 2451543.0); });
    rejects<std::out_of_range>([&] { ephemeris.state(0, 2451549.0); });
    rejects<std::invalid_argument>([&] { ephemeris.state(0, std::numeric_limits<double>::quiet_NaN()); });
    bytes.pop_back();
    write(path, bytes);
    rejects<std::runtime_error>([&] { mitaka::Cf96Ephemeris::load(path); });
    bytes = cf96_fixture(); bytes.push_back(0); write(path, bytes);
    rejects<std::runtime_error>([&] { mitaka::Cf96Ephemeris::load(path); });
    bytes = cf96_fixture(); bytes[0] = 'X'; write(path, bytes);
    rejects<std::runtime_error>([&] { mitaka::Cf96Ephemeris::load(path); });
    bytes = {'C', 'F', '9', '6'}; integer(bytes, 0xffffffff); write(path, bytes);
    rejects<std::runtime_error>([&] { mitaka::Cf96Ephemeris::load(path); });
    bytes = cf96_fixture(); bytes[60] = 3; write(path, bytes); // secular count != 2*imax
    rejects<std::runtime_error>([&] { mitaka::Cf96Ephemeris::load(path); });
    bytes = cf96_fixture(); std::fill(bytes.begin() + 16, bytes.begin() + 24, 0); write(path, bytes);
    rejects<std::runtime_error>([&] { mitaka::Cf96Ephemeris::load(path); });
    bytes = cf96_fixture(); std::fill(bytes.begin() + 8, bytes.begin() + 16, 0); write(path, bytes);
    rejects<std::runtime_error>([&] { mitaka::Cf96Ephemeris::load(path); });
    bytes = cf96_fixture();
    Bytes nan; real(nan, std::numeric_limits<double>::quiet_NaN());
    std::copy(nan.begin(), nan.end(), bytes.begin() + 8); write(path, bytes);
    rejects<std::runtime_error>([&] { mitaka::Cf96Ephemeris::load(path); });
}
void test_trajectory(const std::filesystem::path& path) {
    Bytes bytes;
    append_segment(bytes, 0);
    append_segment(bytes, 3);
    write(path, bytes);
    const auto trajectory = mitaka::Trajectory::load(path);
    check(trajectory.segment_count() == 2, "trajectory count");
    check(trajectory.time_range() == std::make_pair(0.0, 6.0), "trajectory range");
    for (double time : {0.0, 1.0, 2.25, 3.0, 5.125, 6.0}) {
        const auto position = trajectory.position_km(time);
        for (std::size_t axis = 0; axis < 3; ++axis)
            near(position[axis], static_cast<double>(axis + 1) * (time * time * time - 2 * time + 7));
    }
    rejects<std::out_of_range>([&] { trajectory.position_km(-1); });
    rejects<std::out_of_range>([&] { trajectory.position_km(7); });
    rejects<std::invalid_argument>([&] { trajectory.position_km(std::numeric_limits<double>::infinity()); });
    bytes.pop_back(); write(path, bytes);
    rejects<std::runtime_error>([&] { mitaka::Trajectory::load(path); });
    write(path, {});
    rejects<std::runtime_error>([&] { mitaka::Trajectory::load(path); });
    bytes.clear(); append_segment(bytes, 0);
    std::copy(bytes.begin(), bytes.begin() + 8, bytes.begin() + 8); write(path, bytes);
    rejects<std::runtime_error>([&] { mitaka::Trajectory::load(path); });
    bytes.clear(); append_segment(bytes, 0); append_segment(bytes, 2); write(path, bytes);
    rejects<std::runtime_error>([&] { mitaka::Trajectory::load(path); });
    bytes.clear(); append_segment(bytes, 0); append_segment(bytes, 4); write(path, bytes);
    const auto gapped = mitaka::Trajectory::load(path);
    rejects<std::out_of_range>([&] { gapped.position_km(3.5); });
}
} // namespace

int main() {
    auto pattern = (std::filesystem::temp_directory_path() / "mitaka-ephemeris-XXXXXX").string();
    if (!mkdtemp(pattern.data())) { std::cerr << "cannot create test directory\n"; return 1; }
    const auto directory = std::filesystem::path(pattern);
    try {
        const auto file = directory / "天文 data.bin";
        test_cf96(file);
        test_trajectory(file);
        rejects<std::runtime_error>([&] { mitaka::Cf96Ephemeris::load(directory / "missing"); });
        rejects<std::runtime_error>([&] { mitaka::Trajectory::load(directory / "missing"); });
        std::filesystem::remove_all(directory);
        std::cout << "ephemeris tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::filesystem::remove_all(directory);
        std::cerr << error.what() << '\n';
        return 1;
    }
}
