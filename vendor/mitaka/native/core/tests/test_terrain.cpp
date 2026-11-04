#include "mitaka/terrain.hpp"

#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <set>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <sys/stat.h>

namespace {
using namespace mitaka;
int checks = 0;
void expect(bool value, const char* label) {
    ++checks;
    if (!value) throw std::runtime_error(label);
}
template<class Exception, class Function> void throws(Function action, const char* label) {
    try { action(); } catch (const Exception&) { ++checks; return; }
    throw std::runtime_error(label);
}
template<class Value> void put(std::string& bytes, std::size_t offset, Value value) {
    using Bits = std::conditional_t<sizeof(Value) == 2, std::uint16_t, std::uint32_t>;
    Bits bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (std::size_t i = 0; i < sizeof(bits); ++i) bytes[offset + i] = char((bits >> (8 * i)) & 255);
}
struct Fixture {
    std::string bytes;
    std::vector<std::size_t> patch_offsets, grid_offsets;
};
Fixture fixture() {
    Fixture result;
    auto& bytes = result.bytes;
    bytes.resize(16);
    put(bytes, 0, 0.5f); put(bytes, 4, 1000.0f);
    put(bytes, 8, std::int32_t(2)); put(bytes, 12, std::int32_t(1));
    for (int patch = 0; patch < 2; ++patch) {
        const auto start = bytes.size(); result.patch_offsets.push_back(start);
        bytes.resize(start + 20);
        put(bytes, start, float(-180 + 180 * patch));
        put(bytes, start + 4, float(180 * patch));
        put(bytes, start + 8, 90.0f); put(bytes, start + 12, -90.0f);
        put(bytes, start + 16, std::int32_t(patch == 0 ? 1 : 0));
        for (int level = 0; level < (patch == 0 ? 2 : 1); ++level) {
            const int columns = patch == 0 ? level + 1 : 15, rows = level + 1;
            const auto header = bytes.size(); result.grid_offsets.push_back(header);
            bytes.resize(header + 12 + 2 * (columns + 3) * (rows + 3));
            put(bytes, header, std::int32_t(patch == 0 ? level : -77));
            put(bytes, header + 4, std::int32_t(columns)); put(bytes, header + 8, std::int32_t(rows));
            for (int row = -1; row <= rows + 1; ++row) {
                for (int col = -1; col <= columns + 1; ++col) {
                    std::int16_t value = static_cast<std::int16_t>(patch * 100 + level * 1000 + col * 10 + row * 20);
                    if (row == -1 && col == -1) value = -32768;
                    if (row == rows + 1 && col == columns + 1) value = 32767;
                    put(bytes, header + 12 + 2 * ((row + 1) * (columns + 3) + col + 1), value);
                }
            }
        }
    }
    return result;
}
struct TemporaryDirectory {
    std::filesystem::path path;
    TemporaryDirectory() {
        path = std::filesystem::temp_directory_path() / ("mitaka-terrain-" +
            std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
        expect(std::filesystem::create_directory(path), "create fixture directory");
    }
    ~TemporaryDirectory() { std::error_code error; std::filesystem::remove_all(path, error); }
};
void write(const std::filesystem::path& path, const std::string& bytes) {
    std::ofstream file(path, std::ios::binary);
    file.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
    if (!file) throw std::runtime_error("cannot write terrain fixture");
}
void basic(const std::filesystem::path& path, const Fixture& data) {
    write(path, data.bytes);
    auto source = TerrainFile::open(path);
    expect(source.path() == path && source.identity().file_bytes == data.bytes.size(), "explicit source and size");
    expect(source.header().elevation_unit_m == 0.5f && source.header().radius_m == 1000 &&
           source.header().patch_columns == 2 && source.header().patch_rows == 1, "header fields");
    expect(std::memcmp(source.header().raw_bytes.data(), data.bytes.data(), 16) == 0, "raw sphere header");
    expect(source.patches().size() == 2 && source.grids().size() == 3, "all indexed records");
    expect(source.resident_grid_bytes() == 0, "opening does not read payloads");
    expect(source.index_storage_bytes() == 2 * sizeof(TerrainPatch) + 3 * sizeof(TerrainGridDescriptor), "bounded exact index");
    for (std::size_t p = 0; p < source.patches().size(); ++p) {
        const auto& patch = source.patches()[p];
        expect(patch.file_offset == data.patch_offsets[p], "patch file order");
        expect(std::memcmp(patch.raw_bytes.data(), data.bytes.data() + patch.file_offset, 20) == 0, "raw patch header");
        for (int level = 0; level <= patch.maximum_level_index; ++level) {
            const auto& grid = source.read_grid(p, level);
            const auto& descriptor = grid.descriptor();
            expect(descriptor.header_offset == data.grid_offsets[patch.first_grid + level], "grid file order");
            expect(std::memcmp(descriptor.raw_bytes.data(), data.bytes.data() + descriptor.header_offset, 12) == 0, "raw grid header");
            expect(std::memcmp(grid.raw_bytes().data(), data.bytes.data() + descriptor.payload_offset,
                               descriptor.payload_bytes) == 0, "all payload bytes preserved");
            expect(grid.patch_index() == p && grid.level_index() == std::size_t(level), "window identity");
            expect(grid.elevation_units(-1, -1) == -32768 &&
                   grid.elevation_units(descriptor.columns + 1, descriptor.rows + 1) == 32767, "signed extrema halo");
            for (int y = 0; y <= descriptor.rows; ++y)
                for (int x = 0; x <= descriptor.columns; ++x)
                    expect(grid.elevation_units(x, y) == int(p) * 100 + level * 1000 + x * 10 + y * 20,
                           "row-major positive and negative vertex decoding");
            throws<std::out_of_range>([&] { grid.elevation_units(-2, 0); }, "negative halo bound");
            throws<std::out_of_range>([&] { grid.elevation_units(0, descriptor.rows + 2); }, "positive halo bound");
            expect(source.resident_grid_bytes() == descriptor.payload_bytes, "only one grid owned");
            expect(&source.read_grid(p, level) == &grid, "same grid cached");
        }
    }
    expect(source.grids().back().stored_level == -77 && source.grids().back().columns == 15,
           "unused stored level and non power of two dimension preserved");
    throws<std::out_of_range>([&] { source.read_grid(2, 0); }, "unknown patch");
    throws<std::out_of_range>([&] { source.read_grid(1, 1); }, "unknown level");
    source.release_grid(); expect(source.resident_grid_bytes() == 0, "release payload memory");
    auto moved = std::move(source);
    expect(moved.read_grid(0, 0).elevation_units(0, 0) == 0, "descriptor move ownership");
    moved.verify_source_unchanged();
    const auto& grid = moved.read_grid(0, 0);
    const auto& patch = moved.patches()[0];
    expect(terrain_elevation_m(moved.header(), patch, grid, -90, 0) == 7.5, "native fractional bilinear meters");
    expect(terrain_elevation_m(moved.header(), patch, grid, 0, -90) == 15, "last vertex without halo extrapolation");
    expect(terrain_elevation_m(moved.header(), patch, grid, -180, 90) == 0, "first vertex");
    const auto point = terrain_surface_point_m(moved.header(), patch, grid, -90, 0, 2);
    expect(std::abs(point[0]) < 1e-10 && point[1] == -1015 && point[2] == 0, "local axes and factor");
    expect(terrain_surface_point_m(moved.header(), patch, grid, -90, 0, 0)[1] == -1000, "zero factor sphere");
    const auto pole = terrain_surface_point_m(moved.header(), patch, grid, -180, 90);
    expect(std::abs(pole[0]) < 1e-10 && pole[2] == 1000, "north pole");
    for (const double longitude : {-181.0, 1.0, std::numeric_limits<double>::quiet_NaN()})
        throws<std::invalid_argument>([&] { terrain_elevation_m(moved.header(), patch, grid, longitude, 0); }, "outside patch longitude");
    for (const double latitude : {-91.0, 91.0, std::numeric_limits<double>::infinity()})
        throws<std::invalid_argument>([&] { terrain_elevation_m(moved.header(), patch, grid, -90, latitude); }, "outside patch latitude");
    for (const double factor : {-1.0, std::numeric_limits<double>::infinity(), std::numeric_limits<double>::max()})
        throws<std::invalid_argument>([&] { terrain_surface_point_m(moved.header(), patch, grid, -90, 0, factor); }, "invalid factor or radius");
}
void invalid(const std::filesystem::path& path, const Fixture& data) {
    auto reject = [&](const std::string& bytes) {
        write(path, bytes);
        throws<CatalogError>([&] { TerrainFile::open(path); }, "invalid source must reject atomically");
    };
    for (std::size_t n = 0; n < data.bytes.size(); ++n) reject(data.bytes.substr(0, n));
    reject(data.bytes + "x");
    for (float value : {0.0f, -1.0f, std::numeric_limits<float>::infinity(), std::numeric_limits<float>::quiet_NaN()}) {
        for (std::size_t offset : {0, 4}) { auto bytes = data.bytes; put(bytes, offset, value); reject(bytes); }
    }
    for (int value : {0, -1, std::numeric_limits<int>::max()}) {
        for (std::size_t offset : {8, 12}) { auto bytes = data.bytes; put(bytes, offset, value); reject(bytes); }
    }
    for (int level : {-1, 10, std::numeric_limits<int>::max()}) {
        auto bytes = data.bytes; put(bytes, data.patch_offsets[0] + 16, level); reject(bytes);
    }
    for (int dimension : {0, -1, 257, std::numeric_limits<int>::max()}) {
        for (std::size_t offset : {4, 8}) {
            auto bytes = data.bytes; put(bytes, data.grid_offsets[0] + offset, dimension); reject(bytes);
        }
    }
    for (std::size_t offset : {0, 4, 8, 12}) {
        auto bytes = data.bytes; put(bytes, data.patch_offsets[0] + offset, std::numeric_limits<float>::quiet_NaN()); reject(bytes);
    }
    for (const auto entry : {std::pair<std::size_t, float>{0, 1}, {4, 181}, {8, 91}, {12, -91}, {12, 90}}) {
        auto bytes = data.bytes; put(bytes, data.patch_offsets[0] + entry.first, entry.second); reject(bytes);
    }
    write(path, data.bytes);
    auto loaded = TerrainFile::open(path);
    TerrainLoadLimits limits;
    limits.max_file_bytes = data.bytes.size(); limits.max_patches = 2;
    limits.max_index_bytes = loaded.index_storage_bytes(); limits.max_grid_bytes = loaded.maximum_grid_bytes();
    expect(TerrainFile::open(path, limits).grids().size() == 3, "exact resource limits");
    auto small = limits; --small.max_file_bytes;
    throws<CatalogError>([&] { TerrainFile::open(path, small); }, "file limit before payload allocation");
    small = limits; --small.max_patches;
    throws<CatalogError>([&] { TerrainFile::open(path, small); }, "patch count limit");
    small = limits; --small.max_index_bytes;
    throws<CatalogError>([&] { TerrainFile::open(path, small); }, "metadata memory limit");
    small = limits; --small.max_grid_bytes;
    throws<CatalogError>([&] { TerrainFile::open(path, small); }, "single grid memory limit");
    small = limits; small.max_index_bytes = 0;
    throws<CatalogError>([&] { TerrainFile::open(path, small); }, "zero metadata limit");
}
void source_changes(const std::filesystem::path& path, const Fixture& data) {
    write(path, data.bytes);
    auto loaded = TerrainFile::open(path);
    loaded.read_grid(0, 0);
    write(path, data.bytes + "x");
    throws<CatalogError>([&] { loaded.read_grid(0, 0); }, "cached source modification detected");
    expect(loaded.resident_grid_bytes() == 0, "changed source discards stale cached payload");
    write(path, data.bytes);
    auto second = TerrainFile::open(path);
    auto changed = data.bytes; changed.back() ^= 1; write(path, changed);
    throws<CatalogError>([&] { second.read_grid(0, 1); }, "same-size source mutation detected");
    expect(second.resident_grid_bytes() == 0, "same-size rejection keeps no grid");
    throws<CatalogError>([&] { TerrainFile::open(path.parent_path() / "missing.dat"); }, "missing explicit file has no fallback");
    throws<CatalogError>([&] { TerrainFile::open(path.parent_path()); }, "directory rejected");
    throws<CatalogError>([&] { TerrainFile::open(path.string() + std::string("\0suffix", 7)); },
                         "embedded NUL cannot select a truncated source path");
    const auto fifo = path.parent_path() / "fifo";
    expect(::mkfifo(fifo.c_str(), 0600) == 0, "create nonregular fixture");
    throws<CatalogError>([&] { TerrainFile::open(fifo); }, "nonregular source rejects without blocking");
}

void local_data(const std::filesystem::path& path) {
    auto terrain = TerrainFile::open(path);
    std::ifstream independent(path, std::ios::binary);
    std::size_t checked_grids = 0;
    std::set<std::pair<int, int>> dimensions;
    for (std::size_t index = 0; index < terrain.patches().size(); ++index) {
        const auto& patch = terrain.patches()[index];
        for (int level = 0; level <= patch.maximum_level_index; ++level) {
            const auto& grid = terrain.read_grid(index, level);
            const auto& descriptor = grid.descriptor();
            std::string bytes(descriptor.payload_bytes, '\0');
            independent.seekg(static_cast<std::streamoff>(descriptor.payload_offset));
            independent.read(bytes.data(), static_cast<std::streamsize>(bytes.size()));
            expect(bool(independent) && std::memcmp(bytes.data(), grid.raw_bytes().data(), bytes.size()) == 0,
                   "independent read matches all original grid bytes");
            expect(terrain.resident_grid_bytes() <= terrain.maximum_grid_bytes(), "bounded payload residency");
            dimensions.emplace(descriptor.columns, descriptor.rows);
            ++checked_grids;
        }
    }
    terrain.verify_source_unchanged();
    expect(checked_grids == terrain.grids().size(), "all original grids read");
    std::cout << "terrain source=" << path << " bytes=" << terrain.identity().file_bytes
              << " patches=" << terrain.patches().size() << " grids=" << checked_grids
              << " index_bytes=" << terrain.index_storage_bytes()
              << " max_payload=" << terrain.maximum_grid_bytes() << " dimensions=";
    for (const auto& size : dimensions) std::cout << size.first << 'x' << size.second << ',';
    std::cout << '\n';
}
} // namespace

int main(int argc, char** argv) {
    try {
        TemporaryDirectory temporary;
        const auto path = temporary.path / "explicit-terrain.dat";
        const auto data = fixture();
        basic(path, data); invalid(path, data); source_changes(path, data);
        for (int i = 1; i < argc; ++i) local_data(argv[i]);
        std::cout << "terrain: " << checks << " checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "terrain failure: " << error.what() << '\n';
        return 1;
    }
}
