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

NGC/SDSSのレコード定義は公式Mitaka 1.3.1を参照。由来は docs/core/EXTENDED_CATALOG_PROVENANCE.md を参照。
*/
#include "mitaka/extended_catalog.hpp"

#include <array>
#include <charconv>
#include <cmath>
#include <cstring>
#include <fstream>
#include <limits>
#include <set>
#include <string_view>

namespace mitaka {
namespace {

static_assert(sizeof(float) == 4 && std::numeric_limits<float>::is_iec559,
              "The catalog format requires IEEE 754 binary32");

class Input {
public:
    Input(const std::filesystem::path& path, CatalogLoadLimits limits)
        : path_(path), stream_(path, std::ios::binary | std::ios::ate), limits_(limits) {
        if (!stream_) fail("cannot open catalog");
        const auto size = stream_.tellg();
        if (size < 0) fail("cannot determine catalog size");
        size_ = static_cast<std::uint64_t>(size);
        if (size_ > limits.max_file_bytes) fail("catalog exceeds byte limit");
        stream_.seekg(0);
        if (!stream_) fail("cannot seek catalog");
    }

    std::size_t record_count(std::size_t width) const {
        if (size_ % width != 0) fail("truncated fixed-width record");
        const auto count = size_ / width;
        if (count > limits_.max_records) fail("catalog exceeds record limit");
        return static_cast<std::size_t>(count);
    }

    void read(char* bytes, std::size_t count) {
        stream_.read(bytes, static_cast<std::streamsize>(count));
        if (!stream_) fail("catalog read failed");
        offset_ += count;
    }

    bool line(std::string& value) {
        value.clear();
        line_start_ = offset_;
        ++line_number_;
        // 行の上限を独立させ、巨大な1行によるメモリ増加を防ぐ。
        while (offset_ < size_) {
            char ch = 0;
            read(&ch, 1);
            if (ch == '\n') break;
            if (ch == '\0') fail("NUL byte in text catalog");
            value.push_back(ch);
            if (value.size() > 4096) fail("text line exceeds 4096 bytes");
        }
        if (!value.empty() && value.back() == '\r') value.pop_back();
        return offset_ != line_start_;
    }

    void check_count(std::size_t count) const {
        if (count > limits_.max_records) fail("catalog exceeds record limit");
    }

    [[noreturn]] void fail(const std::string& reason) const {
        const auto context = line_number_ == 0 ? std::string{} :
            "line " + std::to_string(line_number_) + ": ";
        throw CatalogError(path_, offset_, context + reason);
    }

private:
    std::filesystem::path path_;
    std::ifstream stream_;
    CatalogLoadLimits limits_;
    std::uint64_t size_ = 0, offset_ = 0, line_start_ = 0;
    std::size_t line_number_ = 0;
};

float number(const unsigned char* bytes, const Input& input) {
    const std::uint32_t bits = std::uint32_t{bytes[0]} | (std::uint32_t{bytes[1]} << 8) |
        (std::uint32_t{bytes[2]} << 16) | (std::uint32_t{bytes[3]} << 24);
    float result;
    std::memcpy(&result, &bits, sizeof(result));
    if (!std::isfinite(result)) input.fail("non-finite floating-point value");
    return result;
}

EquatorialCoordinates coordinates(const unsigned char* bytes, const Input& input) {
    EquatorialCoordinates result{number(bytes, input), number(bytes + 4, input)};
    if (result.right_ascension_deg < 0 || result.right_ascension_deg >= 360 ||
        result.declination_deg < -90 || result.declination_deg > 90) {
        input.fail("equatorial coordinates outside RA [0,360), Dec [-90,90]");
    }
    return result;
}

std::string_view trim(std::string_view value) {
    const auto first = value.find_first_not_of(" \t\r");
    if (first == std::string_view::npos) return {};
    const auto last = value.find_last_not_of(" \t\r");
    return value.substr(first, last - first + 1);
}

bool is_comment(std::string_view value) {
    value = trim(value);
    return value.empty() || value.front() == '%' || value.front() == '#';
}

std::int32_t hip_number(std::string_view value, const Input& input) {
    value = trim(value);
    if (value.empty()) input.fail("expected a positive HIP identifier");
    std::int32_t hip = 0;
    const auto parsed = std::from_chars(value.data(), value.data() + value.size(), hip);
    if (parsed.ec != std::errc{} || parsed.ptr != value.data() + value.size() || hip <= 0) {
        input.fail("expected a positive HIP identifier");
    }
    return hip;
}

} // namespace

std::vector<NgcRecord> load_ngc_catalog(const std::filesystem::path& path, CatalogLoadLimits limits) {
    Input input(path, limits);
    std::vector<NgcRecord> result;
    const auto count = input.record_count(21);
    result.reserve(count);
    std::set<std::pair<bool, std::int16_t>> identifiers;
    for (std::size_t i = 0; i < count; ++i) {
        std::array<unsigned char, 21> record{};
        input.read(reinterpret_cast<char*>(record.data()), record.size());
        const auto id = static_cast<std::uint16_t>(record[0] | (record[1] << 8));
        if (id == 0 || id > std::numeric_limits<std::int16_t>::max()) input.fail("invalid NGC/IC identifier");
        if (record[2] > 1 || record[20] > 1) input.fail("boolean flag must be 0 or 1");
        if (record[11] > 11) input.fail("unknown NGC object classification");
        const auto size = number(record.data() + 12, input);
        if (size < 0) input.fail("negative angular size");
        NgcRecord value{static_cast<std::int16_t>(id), record[2] != 0,
            coordinates(record.data() + 3, input), static_cast<DeepSkyKind>(record[11]),
            size, number(record.data() + 16, input), record[20] != 0};
        if (!identifiers.emplace(value.is_ngc, value.number).second) input.fail("duplicate NGC/IC identifier");
        result.push_back(value);
    }
    return result;
}

std::vector<SdssRecord> load_sdss_catalog(const std::filesystem::path& path, SdssKind kind,
                                        CatalogLoadLimits limits) {
    if (kind != SdssKind::galaxy && kind != SdssKind::quasar) {
        throw std::invalid_argument("unknown SDSS catalog kind");
    }
    Input input(path, limits);
    std::vector<SdssRecord> result;
    const auto count = input.record_count(16);
    result.reserve(count);
    for (std::size_t i = 0; i < count; ++i) {
        std::array<unsigned char, 16> record{};
        input.read(reinterpret_cast<char*>(record.data()), record.size());
        SdssRecord value{coordinates(record.data(), input), number(record.data() + 8, input),
                         number(record.data() + 12, input)};
        if (value.distance_parsecs < 0) input.fail("negative distance");
        result.push_back(value);
    }
    return result;
}

std::vector<StarNameRecord> load_star_names(const std::filesystem::path& path, CatalogLoadLimits limits) {
    Input input(path, limits);
    std::vector<StarNameRecord> result;
    std::set<std::int32_t> identifiers;
    std::string line;
    while (input.line(line)) {
        if (is_comment(line)) continue;
        // 配布データの先頭6桁がHIP、7桁目は選択印、名称は8桁目から。
        if (line.size() < 8 || (line[6] != '*' && line[6] != ' ')) input.fail("invalid star-name columns");
        const auto hip = hip_number(std::string_view(line).substr(0, 6), input);
        const auto names = std::string_view(line).substr(7);
        const auto separator = names.find("  ");
        const auto english = trim(names.substr(0, separator));
        const auto localized = separator == std::string_view::npos ? std::string_view{} : trim(names.substr(separator));
        if (english.empty()) input.fail("empty star name");
        if (!identifiers.insert(hip).second) input.fail("duplicate star-name HIP identifier");
        input.check_count(result.size() + 1);
        result.push_back({hip, line[6] == '*', std::string(english), std::string(localized)});
    }
    return result;
}

std::vector<std::int32_t> load_exoplanet_host_hips(const std::filesystem::path& path,
                                                CatalogLoadLimits limits) {
    Input input(path, limits);
    std::vector<std::int32_t> result;
    std::string line;
    while (input.line(line)) {
        if (is_comment(line)) continue;
        const auto hip = hip_number(line, input);
        input.check_count(result.size() + 1);
        result.push_back(hip);
    }
    return result;
}

} // namespace mitaka
