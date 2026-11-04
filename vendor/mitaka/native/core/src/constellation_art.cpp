#include "mitaka/constellation_art.hpp"

#include <cmath>
#include <cstring>
#include <fstream>
#include <limits>

namespace mitaka {
namespace {
constexpr double radians = 3.14159265358979323846 / 180;
constexpr double parallel_threshold = 0.999989986419677734375;

class Reader {
public:
    explicit Reader(ConstellationArt& art) : art_(art) {}
    std::uint32_t integer() {
        if (art_.source_bytes.size() - offset_ < 4) fail("truncated CAB value");
        const auto* bytes = art_.source_bytes.data() + offset_;
        offset_ += 4;
        return std::uint32_t{bytes[0]} | (std::uint32_t{bytes[1]} << 8)
            | (std::uint32_t{bytes[2]} << 16) | (std::uint32_t{bytes[3]} << 24);
    }
    float number() {
        const auto bits = integer();
        float value;
        static_assert(sizeof(value) == 4 && std::numeric_limits<float>::is_iec559);
        std::memcpy(&value, &bits, sizeof(value));
        if (!std::isfinite(value)) fail("non-finite CAB value");
        return value;
    }
    void count(std::size_t count, std::size_t width, CatalogLoadLimits limits) const {
        if (count > limits.max_records) fail("CAB count exceeds record limit");
        if (count > (art_.source_bytes.size() - offset_) / width) fail("truncated CAB array");
    }
    void finish() const {
        if (offset_ != art_.source_bytes.size()) fail("trailing CAB bytes");
    }
    [[noreturn]] void fail(const char* reason) const { throw CatalogError(art_.source_path, offset_, reason); }
private:
    ConstellationArt& art_;
    std::size_t offset_ = 0;
};

Vec3 center(const ConstellationArt& art) {
    for (const auto value : art.header)
        if (!std::isfinite(value)) throw std::invalid_argument("non-finite CAB header");
    const double norm = std::hypot(static_cast<double>(art.header[0]), static_cast<double>(art.header[1]), static_cast<double>(art.header[2]));
    if (!std::isfinite(norm) || norm == 0) throw std::invalid_argument("CAB center must be finite and nonzero");
    return {art.header[0] / norm, art.header[1] / norm, art.header[2] / norm};
}
Vec3 rotate_from_pole(Vec3 point, Vec3 direction) {
    // 原版helperの極付近の分岐を保持し、一般的なquaternion関数へ置換しない。
    if (direction.z > parallel_threshold) return point;
    if (direction.z < -parallel_threshold) return {point.x, -point.y, -point.z};
    const double axis_norm = std::hypot(direction.x, direction.y);
    const double sine = std::sqrt((1 - direction.z) / 2);
    const double w = std::sqrt((1 + direction.z) / 2);
    const double x = -direction.y / axis_norm * sine;
    const double y = direction.x / axis_norm * sine;
    return {(1 - 2 * y * y) * point.x + 2 * x * y * point.y + 2 * w * y * point.z,
            2 * x * y * point.x + (1 - 2 * x * x) * point.y - 2 * w * x * point.z,
            -2 * w * y * point.x + 2 * w * x * point.y + (1 - 2 * (x * x + y * y)) * point.z};
}
} // namespace

ConstellationArt load_constellation_art(const std::filesystem::path& path, CatalogLoadLimits limits) {
    ConstellationArt art;
    art.source_path = path;
    std::ifstream input(path, std::ios::binary | std::ios::ate);
    if (!input) throw CatalogError(path, 0, "cannot open CAB");
    const auto length = input.tellg();
    if (length < 0 || static_cast<std::uint64_t>(length) > limits.max_file_bytes
        || static_cast<std::uint64_t>(length) > std::numeric_limits<std::size_t>::max())
        throw CatalogError(path, 0, "CAB exceeds byte limit or has invalid size");
    art.source_bytes.resize(static_cast<std::size_t>(length));
    input.seekg(0);
    input.read(reinterpret_cast<char*>(art.source_bytes.data()), length);
    if (!input || input.peek() != std::char_traits<char>::eof()) throw CatalogError(path, 0, "CAB changed or read failed");
    Reader reader(art);
    for (auto& value : art.header) value = reader.number();
    try { (void)center(art); } catch (const std::invalid_argument& error) { throw CatalogError(path, 0, error.what()); }
    const auto points = reader.integer();
    reader.count(points, 8, limits);
    art.points.reserve(points);
    for (std::uint32_t index = 0; index < points; ++index) art.points.push_back({reader.number(), reader.number()});
    const auto indices = reader.integer();
    reader.count(indices, 4, limits);
    art.indices.reserve(indices);
    for (std::uint32_t index = 0; index < indices; ++index) {
        const auto raw = reader.integer();
        // unsignedから符号付き範囲外への実装依存変換を避ける。
        const auto value = raw <= 0x7fffffffU ? static_cast<std::int32_t>(raw)
            : static_cast<std::int32_t>(static_cast<std::int64_t>(raw) - 0x100000000LL);
        if (value >= 0 && static_cast<std::uint32_t>(value) >= points) reader.fail("CAB vertex index out of range");
        art.indices.push_back(value);
    }
    reader.finish();
    return art;
}

Vec3 constellation_art_direction(const ConstellationArt& art, std::size_t point_index) {
    const auto h = center(art);
    const auto& raw = art.points.at(point_index);
    if (!std::isfinite(raw[0]) || !std::isfinite(raw[1])) throw std::invalid_argument("non-finite CAB point");
    const double angle = std::remainder(static_cast<double>(art.header[4]), 360) * radians;
    const double c = std::cos(angle), s = std::sin(angle);
    const auto point = rotate_from_pole({-raw[0] * c - raw[1] * s, -raw[0] * s + raw[1] * c, 0}, h);
    const double scale = 2 * static_cast<double>(art.header[3]);
    const Vec3 world{h.x + scale * point.x, h.y + scale * point.y, h.z + scale * point.z};
    // Plusの通常天球と同じ赤道座標へ戻す。現coreの別obliquity定数で代用しない。
    constexpr double frame_angle = (23.43870583 - 23.3999996185302734375) * radians;
    return {world.x, std::cos(frame_angle) * world.y - std::sin(frame_angle) * world.z,
            std::sin(frame_angle) * world.y + std::cos(frame_angle) * world.z};
}
} // namespace mitaka
