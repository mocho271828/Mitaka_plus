#include "mitaka/catalog.hpp"

#include <chrono>
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
using Bytes = std::vector<unsigned char>;

void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

class FixtureDirectory {
public:
    FixtureDirectory() {
        const auto id = std::chrono::steady_clock::now().time_since_epoch().count();
        path = std::filesystem::temp_directory_path() / ("mitaka 星のテスト " + std::to_string(id));
        require(std::filesystem::create_directory(path), "cannot create fixture directory");
    }
    ~FixtureDirectory() {
        std::error_code error;
        std::filesystem::remove_all(path, error);
    }
    std::filesystem::path path;
};

void write_bytes(const std::filesystem::path& path, const Bytes& bytes) {
    std::ofstream stream(path, std::ios::binary);
    stream.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
    require(static_cast<bool>(stream), "cannot write fixture");
}

void append_u32(Bytes& bytes, std::uint32_t value) {
    for (unsigned int shift = 0; shift < 32; shift += 8) bytes.push_back((value >> shift) & 0xffU);
}

void append_float(Bytes& bytes, float value) {
    std::uint32_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    append_u32(bytes, bits);
}

void append_name(Bytes& bytes, const std::string& value) {
    require(value.size() <= 255, "fixture name too long");
    bytes.push_back(static_cast<unsigned char>(value.size()));
    bytes.insert(bytes.end(), value.begin(), value.end());
}

Bytes star_fixture() {
    // HIP=0x01020304。RA=1、DEC=-2、負視差、符号付き識別子を含む既知の45バイト。
    Bytes bytes{4, 3, 2, 1};
    for (float value : {1.0f, -2.0f, -0.5f, 0.1f, 125.0f, -256.0f, 4.5f, 0.75f}) {
        append_float(bytes, value);
    }
    const Bytes tail{'G', 2, 1, 0xfe, 0xff, 0xff, 3, 42, 'A'};
    bytes.insert(bytes.end(), tail.begin(), tail.end());
    return bytes;
}

Bytes constellation_fixture() {
    Bytes bytes;
    for (const auto& name : {std::string("And"), std::string("And"), std::string("Andromeda"),
                            std::string("Andromedae"), std::string("\x83\x41", 2),
                            std::string("\x90\xaf", 2)}) append_name(bytes, name);
    append_float(bytes, 15.0f);
    append_float(bytes, -40.0f);
    bytes.insert(bytes.end(), {1, 2});
    append_u32(bytes, 0x01020304U);
    append_u32(bytes, 936850U);
    bytes.insert(bytes.end(), {2, 0});
    append_float(bytes, 1.0f);
    append_float(bytes, 20.0f);
    append_float(bytes, 24.0f);
    append_float(bytes, -30.0f);
    return bytes;
}

template <typename Callback>
void expect_error(Callback callback, const std::filesystem::path& path) {
    bool caught = false;
    try {
        callback();
    } catch (const mitaka::CatalogError& error) {
        caught = true;
        require(error.path() == path, "error must identify input path");
        require(std::string(error.what()).find("byte ") != std::string::npos,
                "error must identify byte offset");
    }
    require(caught, "invalid fixture unexpectedly accepted");
}

void test_synthetic_catalogs() {
    FixtureDirectory directory;
    const auto path = directory.path / "日本語 catalog.dat";
    const auto star = star_fixture();
    require(star.size() == 45, "invalid HIP fixture length");
    write_bytes(path, star);
    const auto stars = mitaka::load_hipparcos(path);
    require(stars.size() == 1, "HIP record count");
    const auto& first = stars.front();
    require(first.hip == 0x01020304, "HIP uses four little-endian bytes on LP64");
    require(first.right_ascension_degrees == 1 && first.declination_degrees == -2, "HIP coordinates");
    require(first.parallax_mas == -0.5f && first.parallax_error_mas == 0.1f, "unfiltered parallax");
    require(first.proper_motion_ra_mas_per_year == 125 && first.proper_motion_dec_mas_per_year == -256,
            "proper motion preserved");
    require(first.apparent_v_magnitude == 4.5f && first.color_b_minus_v == 0.75f, "photometry");
    require(first.is_double && first.flamsteed_number == -2 && first.bayer_id == -1, "signed metadata");
    require(first.bayer_subscript == 3 && first.constellation_id == 42 && first.ads_component == 'A',
            "designation metadata");
    require(first.spectral_type == 'G' && first.spectral_subtype == 2, "spectrum metadata");

    for (std::size_t length = 1; length < star.size(); ++length) {
        write_bytes(path, Bytes(star.begin(), star.begin() + static_cast<std::ptrdiff_t>(length)));
        expect_error([&] { mitaka::load_hipparcos(path); }, path);
    }
    auto invalid_star = star;
    invalid_star[38] = 2;
    write_bytes(path, invalid_star);
    expect_error([&] { mitaka::load_hipparcos(path); }, path);
    invalid_star = star;
    invalid_star[4] = 0; invalid_star[5] = 0; invalid_star[6] = 0xc0; invalid_star[7] = 0x7f;
    write_bytes(path, invalid_star);
    expect_error([&] { mitaka::load_hipparcos(path); }, path);
    write_bytes(path, star);
    expect_error([&] { mitaka::load_hipparcos(path, {44, 1}); }, path);
    expect_error([&] { mitaka::load_hipparcos(path, {45, 0}); }, path);
    require(mitaka::load_hipparcos(path, {45, 1}).size() == 1, "exact limits must succeed");

    const auto constellation = constellation_fixture();
    write_bytes(path, constellation);
    const auto constellations = mitaka::load_constellations(path);
    require(constellations.size() == 1, "constellation count");
    const auto& andromeda = constellations.front();
    require(andromeda.abbreviation == "And" && andromeda.boundary_abbreviation == "And", "abbreviations");
    require(andromeda.english_name == "Andromeda" && andromeda.english_genitive == "Andromedae", "names");
    require(andromeda.japanese_hiragana_bytes == std::string("\x83\x41", 2), "Japanese bytes preserved");
    require(andromeda.japanese_kanji_bytes == std::string("\x90\xaf", 2), "Kanji bytes preserved");
    require(andromeda.right_ascension_degrees == 15 && andromeda.declination_degrees == -40, "center");
    require(andromeda.hip_lines.size() == 1 && andromeda.hip_lines.front().size() == 2,
            "line count must not contain upstream resize/push_back duplicate empty lines");
    require(andromeda.hip_lines.front()[0] == 0x01020304 && andromeda.hip_lines.front()[1] == 936850,
            "line identifiers use little-endian int32");
    require(andromeda.boundary.size() == 2 && andromeda.boundary.front().right_ascension_hours == 1,
            "boundary right ascension remains in file's hour units");
    require(andromeda.boundary.back().declination_degrees == -30, "boundary declination");

    for (std::size_t length = 1; length < constellation.size(); ++length) {
        write_bytes(path, Bytes(constellation.begin(), constellation.begin() + static_cast<std::ptrdiff_t>(length)));
        expect_error([&] { mitaka::load_constellations(path); }, path);
    }
    auto invalid_constellation = constellation;
    invalid_constellation[constellation.size() - 18] = 0xff;
    invalid_constellation[constellation.size() - 17] = 0xff;
    write_bytes(path, invalid_constellation);
    expect_error([&] { mitaka::load_constellations(path); }, path);
    write_bytes(path, constellation);
    expect_error([&] { mitaka::load_constellations(path, {256, 0}); }, path);
    auto two = constellation;
    two.insert(two.end(), constellation.begin(), constellation.end());
    write_bytes(path, two);
    require(mitaka::load_constellations(path).size() == 2, "consecutive variable records");
    expect_error([&] { mitaka::load_constellations(path, {1024, 1}); }, path);
    write_bytes(path, {});
    require(mitaka::load_hipparcos(path).empty() && mitaka::load_constellations(path).empty(), "empty catalogs");
    const auto missing = directory.path / "missing.dat";
    expect_error([&] { mitaka::load_hipparcos(missing); }, missing);
}
} // namespace

int main(int argc, char** argv) {
    try {
        require(argc <= 3, "usage: test_catalog [hip.dat [constellation_HIP.dat]]");
        test_synthetic_catalogs();
        if (argc >= 2) {
            const auto stars = mitaka::load_hipparcos(argv[1]);
            require(stars.size() == 117956 && stars.front().hip == 1 && stars.back().hip == 936850,
                    "bundled HIP catalog regression");
            std::cout << "Existing HIP records: " << stars.size() << '\n';
        }
        if (argc == 3) {
            const auto constellations = mitaka::load_constellations(argv[2]);
            require(constellations.size() == 89 && constellations.front().abbreviation == "And",
                    "bundled constellation catalog regression");
            std::cout << "Existing constellation records: " << constellations.size() << '\n';
        }
        std::cout << "Catalog tests passed\n";
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
