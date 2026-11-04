/*
Derived from Mitaka 1.3.1 common/astro/cf96.cpp and Mitaka/mtk_trajectory.cpp.
Copyright (c) 2007 Tsunehiko Kato
Copyright (c) 2014, 2015 Tsunehiko Kato and 4D2U Project,
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
*/
#include "mitaka/ephemeris.hpp"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <limits>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

namespace mitaka {
namespace {
constexpr double cf96_begin = 2415020.5;
constexpr double cf96_end = 2487980.5;

class Reader {
public:
    explicit Reader(const std::filesystem::path& path)
        : file_(path, std::ios::binary), path_(path.string()) {
        if (!file_) fail("cannot open file");
        file_.seekg(0, std::ios::end);
        const auto size = file_.tellg();
        if (size < 0) fail("cannot determine file size");
        remaining_ = static_cast<std::uint64_t>(size);
        file_.seekg(0);
    }
    Reader(std::string_view bytes, std::string source_name)
        : path_(std::move(source_name)), memory_(bytes), remaining_(bytes.size()) {}
    std::uint64_t remaining() const noexcept { return remaining_; }
    [[noreturn]] void fail(const std::string& reason) const {
        throw std::runtime_error(path_ + ": byte " + std::to_string(offset_) + ": " + reason);
    }
    void read(char* bytes, std::size_t size) {
        if (size > remaining_) fail("truncated input");
        if (memory_) std::memcpy(bytes, memory_->data() + offset_, size);
        else if (!file_.read(bytes, static_cast<std::streamsize>(size))) fail("read failed");
        remaining_ -= size;
        offset_ += size;
    }
    std::size_t count(std::size_t minimum_bytes = 0) {
        std::array<unsigned char, 4> bytes{};
        read(reinterpret_cast<char*>(bytes.data()), bytes.size());
        std::uint32_t value = 0;
        for (std::size_t i = 0; i < bytes.size(); ++i) value |= std::uint32_t(bytes[i]) << (8 * i);
        if (value > static_cast<std::uint32_t>(std::numeric_limits<std::int32_t>::max())) fail("negative count");
        if (minimum_bytes && value > remaining_ / minimum_bytes) fail("count exceeds remaining input");
        return value;
    }
    double real() {
        static_assert(sizeof(double) == 8 && std::numeric_limits<double>::is_iec559,
                      "CF96 requires IEEE-754 binary64");
        std::array<unsigned char, 8> bytes{};
        read(reinterpret_cast<char*>(bytes.data()), bytes.size());
        std::uint64_t bits = 0;
        for (std::size_t i = 0; i < bytes.size(); ++i) bits |= std::uint64_t(bytes[i]) << (8 * i);
        double value;
        std::memcpy(&value, &bits, sizeof(value));
        if (!std::isfinite(value)) fail("non-finite coefficient or time");
        return value;
    }
    std::vector<double> reals(std::size_t count) {
        if (count > remaining_ / 8) fail("coefficient count exceeds remaining input");
        std::vector<double> values;
        values.reserve(count);
        for (std::size_t i = 0; i < count; ++i) values.push_back(real());
        return values;
    }
private:
    std::ifstream file_;
    std::string path_;
    std::optional<std::string_view> memory_;
    std::uint64_t remaining_ = 0;
    std::uint64_t offset_ = 0;
};

struct Series {
    std::vector<double> secular;
    std::vector<std::vector<double>> cosine;
    std::vector<std::vector<double>> sine;
};
struct Planet {
    double start;
    double step;
    std::vector<std::vector<double>> frequency;
    std::vector<std::array<Series, 3>> blocks;
};
struct Segment {
    std::array<double, 4> times;
    std::array<std::array<double, 4>, 3> positions;
};

std::vector<Segment> read_trajectory_segments(Reader& reader) {
    if (reader.remaining() == 0 || reader.remaining() % 128 != 0)
        reader.fail("trajectory must contain complete 128-byte segments");
    std::vector<Segment> segments;
    while (reader.remaining() != 0) {
        Segment segment;
        for (auto& time : segment.times) time = reader.real();
        for (std::size_t i = 1; i < segment.times.size(); ++i)
            if (segment.times[i] <= segment.times[i - 1]) reader.fail("trajectory times must increase strictly");
        if (!segments.empty() && segment.times.front() < segments.back().times.back())
            reader.fail("overlapping or unordered trajectory segments");
        for (auto& axis : segment.positions)
            for (auto& position : axis) position = reader.real();
        segments.push_back(segment);
    }
    return segments;
}

Planet read_planet(Reader& reader) {
    Planet planet;
    planet.start = reader.real();
    planet.step = reader.real();
    if (planet.step <= 0) reader.fail("block duration must be positive");
    const auto order = reader.count();
    const auto imax = reader.count();
    const auto block_count = reader.count(28);
    if (imax == 0 || block_count == 0) reader.fail("empty CF96 dimensions");
    if (order + 1 > reader.remaining() / 4 || imax > reader.remaining() / 16)
        reader.fail("CF96 dimensions exceed remaining input");
    std::vector<std::size_t> counts;
    for (std::size_t i = 0; i <= order; ++i) counts.push_back(reader.count(8));
    for (const auto count : counts) planet.frequency.push_back(reader.reals(count));
    for (std::size_t b = 0; b < block_count; ++b) {
        std::array<Series, 3> block;
        for (auto& series : block) {
            const auto secular_count = reader.count(8);
            if (secular_count != 2 * imax) reader.fail("inconsistent secular dimension");
            series.secular = reader.reals(secular_count);
            if (reader.count() != order + 1) reader.fail("inconsistent Poisson dimension");
            for (const auto count : counts) {
                if (reader.count() != count) reader.fail("inconsistent frequency count");
                series.cosine.push_back(reader.reals(count));
                series.sine.push_back(reader.reals(count));
            }
        }
        planet.blocks.push_back(std::move(block));
    }
    const double end = planet.start + planet.step * static_cast<double>(block_count);
    if (!std::isfinite(end))
        reader.fail("CF96 time range overflow");
    if (end < cf96_begin || planet.start > cf96_end)
        reader.fail("CF96 blocks do not intersect the supported epoch range");
    return planet;
}

void require_finite(double time) {
    if (!std::isfinite(time)) throw std::invalid_argument("julian_date must be finite");
}
void require_finite_result(const std::array<double, 3>& values) {
    for (const auto value : values)
        if (!std::isfinite(value)) throw std::overflow_error("ephemeris result is not finite");
}

} // namespace

struct Cf96Ephemeris::Data { std::vector<Planet> planets; };
struct Trajectory::Data { std::vector<Segment> segments; };

Cf96Ephemeris::Cf96Ephemeris(std::shared_ptr<const Data> data) : data_(std::move(data)) {}
Cf96Ephemeris Cf96Ephemeris::load(const std::filesystem::path& path) {
    Reader reader(path);
    std::array<char, 4> magic{};
    reader.read(magic.data(), magic.size());
    if (magic != std::array<char, 4>{'C', 'F', '9', '6'}) reader.fail("invalid CF96 signature");
    const auto count = reader.count(28);
    if (count == 0) reader.fail("empty CF96 ephemeris");
    auto data = std::make_shared<Data>();
    for (std::size_t i = 0; i < count; ++i) data->planets.push_back(read_planet(reader));
    if (reader.remaining() != 0) reader.fail("unexpected trailing CF96 bytes");
    return Cf96Ephemeris(std::move(data));
}
std::size_t Cf96Ephemeris::planet_count() const noexcept { return data_->planets.size(); }
std::pair<double, double> Cf96Ephemeris::time_range(std::size_t planet) const {
    const auto& p = data_->planets.at(planet);
    // 公式が指定する利用範囲と実際の係数ブロック範囲の共通部分に限定する。
    return {std::max(cf96_begin, p.start),
            std::min(cf96_end, p.start + p.step * static_cast<double>(p.blocks.size()))};
}
EphemerisState Cf96Ephemeris::state(std::size_t planet, double julian_date) const {
    require_finite(julian_date);
    const auto& p = data_->planets.at(planet);
    const auto range = time_range(planet);
    if (julian_date < range.first || julian_date > range.second)
        throw std::out_of_range("julian_date outside CF96 coverage");
    const auto block_index = std::min(static_cast<std::size_t>((julian_date - p.start) / p.step),
                                      p.blocks.size() - 1);
    const auto& block = p.blocks[block_index];
    const double x = 2 * (julian_date - (p.start + static_cast<double>(block_index) * p.step)) / p.step - 1;
    const double fx = 0.5 * x * p.step;
    const double wt = 2 / p.step;
    EphemerisState result{};
    for (std::size_t axis = 0; axis < 3; ++axis) {
        const auto& series = block[axis];
        double power = 1;
        double previous_power = 0;
        for (std::size_t i = 0; i < series.secular.size(); ++i) {
            result.position_au[axis] += series.secular[i] * power;
            if (i > 0) result.velocity_au_per_day[axis] += static_cast<double>(i) * wt * series.secular[i] * previous_power;
            previous_power = power;
            power *= x;
        }
        power = 1;
        previous_power = 0;
        for (std::size_t m = 0; m < p.frequency.size(); ++m) {
            for (std::size_t i = 0; i < p.frequency[m].size(); ++i) {
                const double frequency = p.frequency[m][i];
                const double c = std::cos(frequency * fx);
                const double s = std::sin(frequency * fx);
                const double cosine = series.cosine[m][i];
                const double sine = series.sine[m][i];
                const double term = cosine * c + sine * s;
                result.position_au[axis] += term * power;
                result.velocity_au_per_day[axis] += frequency * (sine * c - cosine * s) * power;
                if (m > 0) result.velocity_au_per_day[axis] += static_cast<double>(m) * wt * term * previous_power;
            }
            previous_power = power;
            power *= x;
        }
        result.position_au[axis] *= 1e-10;
        result.velocity_au_per_day[axis] *= 1e-10;
    }
    require_finite_result(result.position_au);
    require_finite_result(result.velocity_au_per_day);
    return result;
}

Trajectory::Trajectory(std::shared_ptr<const Data> data) : data_(std::move(data)) {}
Trajectory Trajectory::load(const std::filesystem::path& path) {
    Reader reader(path);
    auto data = std::make_shared<Data>();
    data->segments = read_trajectory_segments(reader);
    return Trajectory(std::move(data));
}
Trajectory Trajectory::load_bytes(std::string_view bytes, std::string source_name) {
    Reader reader(bytes, std::move(source_name));
    auto data = std::make_shared<Data>();
    data->segments = read_trajectory_segments(reader);
    return Trajectory(std::move(data));
}
std::size_t Trajectory::segment_count() const noexcept { return data_->segments.size(); }
std::pair<double, double> Trajectory::time_range() const noexcept {
    return {data_->segments.front().times.front(), data_->segments.back().times.back()};
}
std::array<double, 3> Trajectory::position_km(double julian_date) const {
    require_finite(julian_date);
    const auto& segments = data_->segments;
    const auto segment = std::lower_bound(segments.begin(), segments.end(), julian_date,
        [](const Segment& s, double time) { return s.times.back() < time; });
    if (segment == segments.end() || julian_date < segment->times.front())
        throw std::out_of_range("julian_date outside trajectory coverage");
    std::array<double, 3> result{};
    // 四点 Lagrange 補間を使用する。公式の NR 由来 polint 実装は複製しない。
    for (std::size_t i = 0; i < 4; ++i) {
        double weight = 1;
        for (std::size_t j = 0; j < 4; ++j)
            if (i != j) weight *= (julian_date - segment->times[j]) / (segment->times[i] - segment->times[j]);
        for (std::size_t axis = 0; axis < 3; ++axis) result[axis] += weight * segment->positions[axis][i];
    }
    require_finite_result(result);
    return result;
}

} // namespace mitaka
