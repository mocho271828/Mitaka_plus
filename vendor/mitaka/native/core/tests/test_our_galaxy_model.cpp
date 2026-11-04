#include "mitaka/our_galaxy_model.hpp"

#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <iterator>
#include <limits>

namespace {
using namespace mitaka;
using Bytes = std::vector<std::uint8_t>;
std::size_t checks = 0;
void require(bool condition, const std::string& message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
struct Fixtures {
    std::filesystem::path root = std::filesystem::temp_directory_path() /
        ("mitaka_our_galaxy_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixtures() { require(std::filesystem::create_directory(root), "create fixtures"); }
    ~Fixtures() { std::error_code error; std::filesystem::remove_all(root, error); }
};
void write(const std::filesystem::path& path, const Bytes& bytes) {
    std::ofstream file(path, std::ios::binary);
    file.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
    require(bool(file), "write fixture");
}
Bytes read(const std::filesystem::path& path) {
    std::ifstream file(path, std::ios::binary);
    require(bool(file), "read reference bytes");
    return Bytes(std::istreambuf_iterator<char>(file), {});
}
std::uint32_t bits(float value) {
    std::uint32_t result; std::memcpy(&result, &value, 4); return result;
}
void put(Bytes& bytes, std::size_t offset, std::uint32_t value) {
    for (unsigned i = 0; i < 4; ++i) bytes.at(offset + i) = (value >> (8 * i)) & 255U;
}
void append(Bytes& bytes, std::uint32_t value) {
    const auto offset = bytes.size(); bytes.resize(offset + 4); put(bytes, offset, value);
}
std::uint32_t take(const Bytes& bytes, std::size_t& offset) {
    const auto value = std::uint32_t(bytes.at(offset)) + std::uint32_t(bytes.at(offset + 1)) * 256U +
        std::uint32_t(bytes.at(offset + 2)) * 65536U + std::uint32_t(bytes.at(offset + 3)) * 16777216U;
    offset += 4; return value;
}
template<class Load> void error(const std::filesystem::path& path, Load load) {
    try { load(); }
    catch (const CatalogError& e) {
        require(e.path() == path && !std::string(e.what()).empty(), "error has provenance"); return;
    }
    throw std::runtime_error("invalid model accepted");
}
Bytes fixture() {
    Bytes bytes;
    append(bytes, 2); append(bytes, 3);
    for (float value : {0.f, 0.5f, 1.f, -1.f, 2.f, std::numeric_limits<float>::quiet_NaN()}) append(bytes, bits(value));
    append(bytes, 3); append(bytes, 1);
    for (float value : {0.f, std::numeric_limits<float>::infinity(), -std::numeric_limits<float>::infinity()}) append(bytes, bits(value));
    append(bytes, 2);
    for (float value : {1.f, 2.f, 3.f, -0.f, -1000000.f, std::numeric_limits<float>::max()}) append(bytes, bits(value));
    append(bytes, 0);
    append(bytes, 1);
    for (float value : {std::numeric_limits<float>::quiet_NaN(), 0.f, 2.f}) append(bytes, bits(value));
    append(bytes, 1);
    for (float value : {4.f, std::numeric_limits<float>::infinity(), 6.f}) append(bytes, bits(value));
    return bytes;
}
void check_all(const std::filesystem::path& path) {
    const auto bytes = read(path);
    const auto model = load_our_galaxy_model(path);
    require(model.source.path == path && model.source.bytes == bytes, "source path and bytes exact");
    std::size_t offset = 0;
    for (const auto& map : model.maps) {
        require(std::uint32_t(map.width) == take(bytes, offset), "map width retained");
        require(std::uint32_t(map.height) == take(bytes, offset), "map height retained");
        require(map.values.size() == std::size_t(map.width) * std::size_t(map.height), "all map samples");
        std::size_t nonfinite = 0, outside = 0;
        for (const auto value : map.values) {
            require(bits(value) == take(bytes, offset), "raw map sample bits");
            if (!std::isfinite(value)) ++nonfinite;
            else if (value < 0 || value > 1) ++outside;
        }
        require(map.nonfinite_count == nonfinite && map.outside_unit_interval_count == outside,
                "map diagnostic counts");
    }
    for (const auto& group : model.groups) {
        require(group.positions.size() == take(bytes, offset), "all points in original group order");
        std::size_t nonfinite = 0;
        for (const auto& point : group.positions) {
            require(bits(point.x_pc) == take(bytes, offset), "raw x pc bits");
            require(bits(point.y_pc) == take(bytes, offset), "raw y pc bits");
            require(bits(point.z_pc) == take(bytes, offset), "raw z pc bits");
            if (!std::isfinite(point.x_pc) || !std::isfinite(point.y_pc) || !std::isfinite(point.z_pc)) ++nonfinite;
        }
        require(group.nonfinite_count == nonfinite, "point diagnostic count");
    }
    require(offset == bytes.size() && read(path) == bytes, "all source consumed without modifying original");
}
void synthetic(const std::filesystem::path& path) {
    const auto bytes = fixture(); write(path, bytes); check_all(path);
    const auto model = load_our_galaxy_model(path);
    require(model.maps[0].width == 2 && model.maps[0].height == 3 && model.maps[1].width == 3,
            "custom dimensions preserved instead of replacing with 512");
    require(model.maps[0].nonfinite_count == 1 && model.maps[0].outside_unit_interval_count == 2 &&
        model.maps[1].nonfinite_count == 2, "invalid map values preserved and diagnosed");
    require(model.groups[1].positions.empty() && model.groups[2].nonfinite_count == 1 &&
        model.groups[3].nonfinite_count == 1, "empty and nonfinite clouds retained");
    require(model.groups[0].positions[1].y_pc == -1000000.f &&
        bits(model.groups[0].positions[1].x_pc) == bits(-0.f), "outlier and signed zero preserved");
    for (std::size_t length = 0; length < bytes.size(); ++length) {
        write(path, Bytes(bytes.begin(), bytes.begin() + length));
        error(path, [&] { load_our_galaxy_model(path); });
    }
    for (const auto offset : {0U, 4U, 32U, 36U})
        for (const auto value : {0U, 0xffffffffU, 0x7fffffffU}) {
            auto invalid = bytes; put(invalid, offset, value); write(path, invalid);
            error(path, [&] { load_our_galaxy_model(path); });
        }
    // 2 枚目のマップを読めた後でも、合計上限を超えた結果を返さない。
    write(path, bytes);
    error(path, [&] { load_our_galaxy_model(path, {bytes.size(), 8}); });
    error(path, [&] { load_our_galaxy_model(path, {bytes.size() - 1, 9}); });
    require(load_our_galaxy_model(path, {bytes.size(), 9}).source.bytes == bytes, "exact sample and byte limit");
    for (const auto offset : {52U, 80U, 84U, 100U}) {
        auto invalid = bytes; put(invalid, offset, 0xffffffffU); write(path, invalid);
        error(path, [&] { load_our_galaxy_model(path); });
        put(invalid, offset, 0x7fffffffU); write(path, invalid);
        error(path, [&] { load_our_galaxy_model(path); });
    }
    auto extra = bytes; extra.push_back(0); write(path, extra);
    error(path, [&] { load_our_galaxy_model(path); });
    // マップとは独立した累積点数制限。4 群を個別に許容しても総量で拒否する。
    Bytes point_limit;
    for (int i = 0; i < 2; ++i) { append(point_limit, 1); append(point_limit, 1); append(point_limit, 0); }
    for (int i = 0; i < 4; ++i) {
        append(point_limit, 1); append(point_limit, 0); append(point_limit, 0); append(point_limit, 0);
    }
    write(path, point_limit);
    error(path, [&] { load_our_galaxy_model(path, {point_limit.size(), 3}); });
    require(load_our_galaxy_model(path, {point_limit.size(), 4}).groups[3].positions.size() == 1,
            "exact cumulative point limit");
    write(path, {});
    require(model.source.bytes == bytes && model.maps[0].values.size() == 6, "value ownership after file changes");
}
} // namespace

int main(int argc, char** argv) {
    try {
        Fixtures fixtures; synthetic(fixtures.root / "model.dat");
        for (int i = 1; i < argc; ++i) check_all(argv[i]);
        std::cout << "our galaxy model: " << checks << " checks passed\n";
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
