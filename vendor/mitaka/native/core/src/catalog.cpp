/*
Copyright (c) 2007-2015 Tsunehiko Kato and 4D2U Project,
National Astronomical Observatory of Japan

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

Mitaka 1.3.1 mtk_stars.cpp / mtk_constellation.cpp の形式定義から分離。
2026: 固定幅・little-endian 読込、検証、RAII、描画非依存の生データAPIへ変更。
*/
#include "mitaka/catalog.hpp"

#include <array>
#include <cmath>
#include <cstring>
#include <fstream>
#include <limits>
#include <utility>

namespace mitaka {

CatalogError::CatalogError(const std::filesystem::path& path, std::uint64_t offset,
                           const std::string& reason)
    : std::runtime_error(path.string() + ": byte " + std::to_string(offset) + ": " + reason),
      path_(path), offset_(offset) {}

namespace {

static_assert(sizeof(float) == 4 && std::numeric_limits<float>::is_iec559,
              "The catalog format requires IEEE 754 binary32");

class Reader {
public:
    Reader(const std::filesystem::path& path, std::uint64_t max_bytes)
        : path_(path), stream_(path, std::ios::binary | std::ios::ate) {
        if (!stream_) fail("cannot open catalog");
        const auto length = stream_.tellg();
        if (length < 0) fail("cannot determine catalog size");
        size_ = static_cast<std::uint64_t>(length);
        if (size_ > max_bytes) fail("catalog exceeds byte limit");
        stream_.seekg(0);
        if (!stream_) fail("cannot seek catalog");
    }

    std::uint64_t remaining() const noexcept { return size_ - offset_; }
    std::uint64_t size() const noexcept { return size_; }
    [[noreturn]] void fail(const std::string& reason) const {
        throw CatalogError(path_, offset_, reason);
    }

    void read(char* destination, std::size_t count) {
        if (count > remaining()) fail("truncated record");
        stream_.read(destination, static_cast<std::streamsize>(count));
        if (!stream_) fail("catalog read failed");
        offset_ += count;
    }

    std::uint8_t u8() {
        unsigned char value = 0;
        read(reinterpret_cast<char*>(&value), 1);
        return value;
    }

    std::int8_t i8() {
        const auto value = u8();
        return static_cast<std::int8_t>(value < 128 ? value : static_cast<int>(value) - 256);
    }

    std::int16_t i16() {
        std::array<unsigned char, 2> bytes{};
        read(reinterpret_cast<char*>(bytes.data()), bytes.size());
        const auto value = static_cast<std::uint16_t>(bytes[0] | (bytes[1] << 8));
        return static_cast<std::int16_t>(value < 32768 ? value : static_cast<int>(value) - 65536);
    }

    std::uint32_t u32() {
        std::array<unsigned char, 4> bytes{};
        read(reinterpret_cast<char*>(bytes.data()), bytes.size());
        return std::uint32_t{bytes[0]} | (std::uint32_t{bytes[1]} << 8) |
               (std::uint32_t{bytes[2]} << 16) | (std::uint32_t{bytes[3]} << 24);
    }

    std::int32_t i32() {
        const auto value = u32();
        const auto signed_value = value < 0x80000000U ? static_cast<std::int64_t>(value)
                                                    : static_cast<std::int64_t>(value) - 0x100000000LL;
        return static_cast<std::int32_t>(signed_value);
    }

    float number() {
        const auto bits = u32();
        float value;
        std::memcpy(&value, &bits, sizeof(value));
        if (!std::isfinite(value)) fail("non-finite floating-point value");
        return value;
    }

    std::string name() {
        const auto length = u8();
        std::string value(length, '\0');
        if (length != 0) read(value.data(), length);
        return value;
    }

private:
    std::filesystem::path path_;
    std::ifstream stream_;
    std::uint64_t size_ = 0;
    std::uint64_t offset_ = 0;
};

HipparcosRecord read_star(Reader& reader) {
    HipparcosRecord star{};
    star.hip = reader.i32();
    star.right_ascension_degrees = reader.number();
    star.declination_degrees = reader.number();
    star.parallax_mas = reader.number();
    star.parallax_error_mas = reader.number();
    star.proper_motion_ra_mas_per_year = reader.number();
    star.proper_motion_dec_mas_per_year = reader.number();
    star.apparent_v_magnitude = reader.number();
    star.color_b_minus_v = reader.number();
    star.spectral_type = reader.i8();
    star.spectral_subtype = reader.i8();
    const auto double_flag = reader.u8();
    if (double_flag > 1) reader.fail("double-star flag must be 0 or 1");
    star.is_double = double_flag != 0;
    star.flamsteed_number = reader.i16();
    star.bayer_id = reader.i8();
    star.bayer_subscript = reader.i8();
    star.constellation_id = reader.i8();
    star.ads_component = reader.i8();
    return star;
}

ConstellationRecord read_constellation(Reader& reader) {
    ConstellationRecord constellation{};
    constellation.abbreviation = reader.name();
    constellation.boundary_abbreviation = reader.name();
    constellation.english_name = reader.name();
    constellation.english_genitive = reader.name();
    constellation.japanese_hiragana_bytes = reader.name();
    constellation.japanese_kanji_bytes = reader.name();
    constellation.right_ascension_degrees = reader.number();
    constellation.declination_degrees = reader.number();
    const auto line_count = reader.u8();
    constellation.hip_lines.reserve(line_count);
    for (unsigned int line = 0; line < line_count; ++line) {
        const auto point_count = reader.u8();
        if (static_cast<std::uint64_t>(point_count) * 4 > reader.remaining()) {
            reader.fail("truncated constellation line");
        }
        std::vector<std::int32_t> points;
        points.reserve(point_count);
        for (unsigned int point = 0; point < point_count; ++point) points.push_back(reader.i32());
        constellation.hip_lines.push_back(std::move(points));
    }
    const auto boundary_count = reader.i16();
    if (boundary_count < 0) reader.fail("negative constellation boundary count");
    if (static_cast<std::uint64_t>(boundary_count) * 8 > reader.remaining()) {
        reader.fail("truncated constellation boundary");
    }
    constellation.boundary.reserve(static_cast<std::size_t>(boundary_count));
    for (int point = 0; point < boundary_count; ++point) {
        constellation.boundary.push_back({reader.number(), reader.number()});
    }
    return constellation;
}

} // namespace

std::vector<HipparcosRecord> load_hipparcos(const std::filesystem::path& path,
                                          CatalogLoadLimits limits) {
    Reader reader(path, limits.max_file_bytes);
    // Windowsのlong=4、bool=1を含め45バイト。ホストのstructのsizeofは使わない。
    constexpr std::uint64_t record_bytes = 45;
    if (reader.size() % record_bytes != 0) reader.fail("HIP catalog size is not a multiple of 45 bytes");
    const auto count = reader.size() / record_bytes;
    if (count > limits.max_records) reader.fail("HIP catalog exceeds record limit");
    std::vector<HipparcosRecord> stars;
    stars.reserve(static_cast<std::size_t>(count));
    while (reader.remaining() != 0) stars.push_back(read_star(reader));
    return stars;
}

std::vector<ConstellationRecord> load_constellations(const std::filesystem::path& path,
                                                   CatalogLoadLimits limits) {
    Reader reader(path, limits.max_file_bytes);
    std::vector<ConstellationRecord> constellations;
    while (reader.remaining() != 0) {
        if (constellations.size() >= limits.max_records) reader.fail("constellation catalog exceeds record limit");
        constellations.push_back(read_constellation(reader));
    }
    return constellations;
}

} // namespace mitaka
