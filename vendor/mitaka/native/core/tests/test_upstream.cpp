#include "mitaka/ephemeris.hpp"

#include <CommonCrypto/CommonDigest.h>
#include <unistd.h>
#include <algorithm>
#include <array>
#include <cmath>
#include <cstdio>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>
#include <vector>
#include "cf96.h"

namespace {
std::vector<unsigned char> verified_reference_bytes(const char* path) {
    // 原本の固定長配列は拡張 CF96 を扱えないため、比較済みの既存データだけを許可する。
    constexpr std::size_t expected_size = 461300;
    constexpr std::array<unsigned char, CC_SHA256_DIGEST_LENGTH> expected_digest{{
        0x22, 0xed, 0xc2, 0xb9, 0xe4, 0xa0, 0x17, 0x0b,
        0xb8, 0x05, 0xb2, 0xd5, 0x64, 0xdb, 0xe9, 0x0a,
        0xfb, 0x1e, 0xf7, 0xa1, 0x73, 0x70, 0xdb, 0x45,
        0x78, 0x87, 0xd2, 0x8d, 0x01, 0x35, 0xdf, 0xb4
    }};
    std::ifstream input(path, std::ios::binary | std::ios::ate);
    if (!input || input.tellg() != static_cast<std::streamoff>(expected_size)) {
        throw std::runtime_error("reference input must be the known 461300-byte cf96.dat");
    }
    input.seekg(0);
    std::vector<unsigned char> bytes(expected_size);
    if (!input.read(reinterpret_cast<char*>(bytes.data()), static_cast<std::streamsize>(bytes.size())) ||
        input.peek() != std::char_traits<char>::eof()) {
        throw std::runtime_error("cannot read reference input");
    }
    std::array<unsigned char, CC_SHA256_DIGEST_LENGTH> digest{};
    if (!CC_SHA256(bytes.data(), static_cast<CC_LONG>(bytes.size()), digest.data()) ||
        digest != expected_digest) {
        throw std::runtime_error("reference input SHA-256 is not the known cf96.dat; refusing upstream loader");
    }
    return bytes;
}

class TemporaryDirectory {
public:
    TemporaryDirectory() {
        auto pattern = (std::filesystem::temp_directory_path() / "mitaka-reference-XXXXXX").string();
        if (!mkdtemp(pattern.data())) throw std::runtime_error("cannot create reference directory");
        path = pattern;
    }
    ~TemporaryDirectory() {
        std::error_code error;
        std::filesystem::remove_all(path, error);
    }
    TemporaryDirectory(const TemporaryDirectory&) = delete;
    TemporaryDirectory& operator=(const TemporaryDirectory&) = delete;
    std::filesystem::path path;
};
} // namespace

int main(int argc, char** argv) {
    if (argc != 2) { std::cerr << "Usage: test_upstream cf96.dat\n"; return 2; }
    try {
        const auto bytes = verified_reference_bytes(argv[1]);
        TemporaryDirectory directory;
        const auto snapshot = directory.path / "cf96.dat";
        {
            // ハッシュ検証した同じ内容を両ローダーに渡し、元ファイルの更新から比較を隔離する。
            std::ofstream output(snapshot, std::ios::binary);
            output.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
            output.close();
            if (!output) throw std::runtime_error("cannot write reference snapshot");
        }
        const auto core = mitaka::Cf96Ephemeris::load(snapshot);
        CF96_planets original;
        if (!original.load(snapshot.c_str()) || core.planet_count() != static_cast<std::size_t>(original.get_planet_num())) {
            throw std::runtime_error("upstream planet count mismatch");
        }
        std::size_t comparisons = 0;
        double max_position_error = 0, max_velocity_error = 0;
        for (std::size_t planet = 0; planet < core.planet_count(); ++planet) {
            const auto range = core.time_range(planet);
            // 始端・終端と内部の複数ブロックを横断して比較する。
            for (int sample = 0; sample <= 200; ++sample) {
                const double jd = range.first + (range.second - range.first) * sample / 200.0;
                const auto state = core.state(planet, jd);
                const auto position = original.eval_pos(static_cast<int>(planet), jd);
                const auto velocity = original.eval_vel(static_cast<int>(planet), jd);
                const double expected_position[] = {position.x, position.y, position.z};
                const double expected_velocity[] = {velocity.x, velocity.y, velocity.z};
                for (std::size_t axis = 0; axis < 3; ++axis) {
                    const double pe = std::abs(state.position_au[axis] - expected_position[axis]);
                    const double ve = std::abs(state.velocity_au_per_day[axis] - expected_velocity[axis]);
                    if (!std::isfinite(pe) || !std::isfinite(ve) || pe > 1e-12 || ve > 1e-13) {
                        throw std::runtime_error("CF96 differs from official 1.3.1");
                    }
                    max_position_error = std::max(max_position_error, pe);
                    max_velocity_error = std::max(max_velocity_error, ve);
                    ++comparisons;
                }
            }
        }
        std::cout << "upstream CF96: " << comparisons << " component comparisons passed; max position error="
                  << max_position_error << " AU, max velocity error=" << max_velocity_error << " AU/day\n";
    } catch (const std::exception& error) {
        std::cerr << "upstream comparison: " << error.what() << '\n'; return 1;
    }
}
