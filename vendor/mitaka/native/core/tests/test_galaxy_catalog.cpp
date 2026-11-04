#include "mitaka/galaxy_catalog.hpp"

#include <algorithm>
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
        ("mitaka_galaxy_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
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
    std::uint32_t result;
    std::memcpy(&result, &value, 4);
    return result;
}
std::uint32_t raw_u32(const Bytes& bytes, std::size_t offset) {
    return std::uint32_t(bytes.at(offset)) + std::uint32_t(bytes.at(offset + 1)) * 256U +
        std::uint32_t(bytes.at(offset + 2)) * 65536U + std::uint32_t(bytes.at(offset + 3)) * 16777216U;
}
void put(Bytes& bytes, std::size_t offset, std::uint32_t value) {
    for (unsigned i = 0; i < 4; ++i) bytes.at(offset + i) = (value >> (8 * i)) & 255U;
}
template<class Load> void error(const std::filesystem::path& path, Load load) {
    try { load(); }
    catch (const CatalogError& e) {
        require(e.path() == path && !std::string(e.what()).empty(), "error has provenance");
        return;
    }
    throw std::runtime_error("invalid file accepted");
}
void check_gc(const std::filesystem::path& path) {
    const auto bytes = read(path);
    const auto catalog = load_plus_globular_clusters(path);
    require(catalog.source.path == path && catalog.source.bytes == bytes, "GC source ownership");
    require(catalog.records.size() == bytes.size() / 40, "all GC rows");
    for (std::size_t i = 0; i < catalog.records.size(); ++i) {
        const auto& r = catalog.records[i];
        require(std::equal(r.name_bytes.begin(), r.name_bytes.end(), bytes.begin() + 40 * i), "all name bytes");
        const float values[]{r.right_ascension_degrees, r.declination_degrees, r.distance_pc,
            r.core_radius_pc, r.half_light_radius_pc, r.color_b_minus_v, r.color_v_minus_r};
        for (std::size_t j = 0; j < 7; ++j)
            require(bits(values[j]) == raw_u32(bytes, 40 * i + 12 + 4 * j), "GC raw field bits");
    }
    require(read(path) == bytes, "GC original unchanged");
}
void check_nbg(const std::filesystem::path& path) {
    const auto bytes = read(path);
    const auto catalog = load_plus_nearby_galaxies(path);
    require(catalog.source.path == path && catalog.source.bytes == bytes, "NBG source ownership");
    require(catalog.records.size() == bytes.size() / 27, "all NBG rows");
    for (std::size_t i = 0; i < catalog.records.size(); ++i) {
        const auto& r = catalog.records[i];
        const float values[]{r.right_ascension_degrees, r.declination_degrees, r.distance_pc,
            r.angular_diameter_arcminutes, r.minor_major_axis_ratio};
        for (std::size_t j = 0; j < 5; ++j)
            require(bits(values[j]) == raw_u32(bytes, 27 * i + 4 * j), "NBG raw field bits");
        require(r.render_class_code == bytes[27 * i + 20] && r.auxiliary_code == bytes[27 * i + 21] &&
            r.catalog_code == bytes[27 * i + 22], "uninterpreted NBG codes");
        std::uint32_t number;
        std::memcpy(&number, &r.catalog_number, 4);
        require(number == raw_u32(bytes, 27 * i + 23), "NBG signed ID bits");
    }
    require(read(path) == bytes, "NBG original unchanged");
}
void binary_tests(const std::filesystem::path& path) {
    Bytes gc(40, 0);
    for (std::size_t i = 0; i < 12; ++i) gc[i] = std::uint8_t(128 + i);
    gc[3] = 0;
    const float fields[]{123.5f, -45.25f, 12, -1, 0, 2, -3};
    for (std::size_t i = 0; i < 7; ++i) put(gc, 12 + i * 4, bits(fields[i]));
    put(gc, 32, 0x7fc12345U);
    Bytes duplicated = gc;
    duplicated.insert(duplicated.end(), gc.begin(), gc.end());
    write(path, duplicated); check_gc(path);
    auto owned = load_plus_globular_clusters(path);
    write(path, {});
    require(owned.records.size() == 2 && owned.source.bytes == duplicated, "value owned after file changes");
    require(load_plus_globular_clusters(path).records.empty(), "empty GC accepted");
    for (std::size_t length = 1; length < 40; ++length) {
        write(path, Bytes(gc.begin(), gc.begin() + length));
        error(path, [&] { load_plus_globular_clusters(path); });
    }
    write(path, duplicated);
    error(path, [&] { load_plus_globular_clusters(path, {79, 2}); });
    error(path, [&] { load_plus_globular_clusters(path, {80, 1}); });
    require(load_plus_globular_clusters(path, {80, 2}).records.size() == 2, "exact GC limits");
    Bytes nbg(27, 0);
    for (std::size_t i = 0; i < 5; ++i) put(nbg, i * 4, bits(fields[i]));
    nbg[20] = 255; nbg[21] = 254; nbg[22] = 128; put(nbg, 23, 0x80000000U);
    duplicated = nbg; duplicated.insert(duplicated.end(), nbg.begin(), nbg.end());
    write(path, duplicated); check_nbg(path);
    for (std::size_t length = 1; length < 27; ++length) {
        write(path, Bytes(nbg.begin(), nbg.begin() + length));
        error(path, [&] { load_plus_nearby_galaxies(path); });
    }
    write(path, duplicated);
    error(path, [&] { load_plus_nearby_galaxies(path, {53, 2}); });
    error(path, [&] { load_plus_nearby_galaxies(path, {54, 1}); });
    require(load_plus_nearby_galaxies(path, {54, 2}).records.size() == 2, "exact NBG limits");
    write(path, {});
    require(load_plus_nearby_galaxies(path, {0, 0}).records.empty(), "empty NBG accepted");
    const auto missing = path.parent_path() / "absent";
    error(missing, [&] { load_galaxy_catalog_source(missing); });
}
void near(double actual, long double expected, long double scale) {
    require(std::fabs(static_cast<long double>(actual) - expected) <= 3e-15L * scale,
            "independent long double position oracle");
}
void position_tests() {
    constexpr long double pi = 3.141592653589793238462643383279502884L;
    const long double tilt = 84381.448L / 3600 * pi / 180;
    for (float ra : {0.f, 90.f, 180.f, 270.f, 359.999f})
        for (float dec : {-90.f, -45.f, 0.f, 45.f, 90.f})
            for (float distance : {0.f, -0.f, 1.f, 1e9f, std::numeric_limits<float>::max()}) {
                const auto result = evaluate_galaxy_position_pc(ra, dec, distance);
                require(result.position.has_value(), "valid coordinate evaluated");
                require(result.issues == (distance == 0 ? 64 : 0), "zero reason explicit");
                const long double a = static_cast<long double>(ra) * pi / 180;
                const long double d = static_cast<long double>(dec) * pi / 180;
                const long double x = distance * std::cos(d) * std::cos(a);
                const long double y = distance * std::cos(d) * std::sin(a);
                const long double z = distance * std::sin(d);
                const long double scale = distance == 0 ? 1 : distance;
                const auto& p = *result.position;
                near(p.equatorial.x_pc, x, scale); near(p.equatorial.y_pc, y, scale); near(p.equatorial.z_pc, z, scale);
                near(p.native_ecliptic.x_pc, x, scale);
                near(p.native_ecliptic.y_pc, y * std::cos(tilt) + z * std::sin(tilt), scale);
                near(p.native_ecliptic.z_pc, -y * std::sin(tilt) + z * std::cos(tilt), scale);
            }
    const float nan = std::numeric_limits<float>::quiet_NaN(), inf = std::numeric_limits<float>::infinity();
    for (float ra : {-1.f, 360.f, nan, inf})
        for (float dec : {-91.f, 91.f, nan, inf})
            for (float distance : {-1.f, nan, inf, 0.f}) {
                const auto result = evaluate_galaxy_position_pc(ra, dec, distance);
                const unsigned expected = (std::isfinite(ra) ? 2 : 1) | (std::isfinite(dec) ? 8 : 4) |
                    (!std::isfinite(distance) ? 16 : distance < 0 ? 32 : 64);
                require(!result.position && result.issues == expected, "all invalid reasons preserved");
            }
}
void name_tests(const std::filesystem::path& path) {
    std::string raw = "\r\n  % comment\r\n#other\nT58\t*Small Magellanic Cloud\r\nT58 second\nUnknown ";
    raw += char(0x83); raw += char(0x5c); raw += " \x81\x40ruby\nMissing\nBlank * \t\r\n";
    raw += std::string("Bad x\0y\n", 8); raw += "Tail last";
    const Bytes bytes(raw.begin(), raw.end()); write(path, bytes);
    const auto table = load_galaxy_name_table(path);
    require(table.source.bytes == bytes && table.lines.size() == 10, "all physical name lines");
    require(table.lines[0].kind == GalaxyNameLineKind::blank &&
        table.lines[1].kind == GalaxyNameLineKind::comment && table.lines[2].kind == GalaxyNameLineKind::comment,
        "blank and comments retained");
    require(table.lines[3].featured && table.lines[3].key_bytes == "T58" &&
        table.lines[3].payload_bytes == "Small Magellanic Cloud\r", "featured raw payload");
    require(table.lines[4].key_bytes == "T58" && !table.lines[4].featured, "duplicate key retained");
    require(table.lines[5].payload_bytes == std::string("\x83\x5c \x81\x40ruby"), "CP932 backslash bytes retained");
    for (std::size_t i : {6U, 7U, 8U})
        require(table.lines[i].kind == GalaxyNameLineKind::unresolved && !table.lines[i].diagnostic.empty(),
                "malformed name line retained with diagnostic");
    for (std::size_t i = 0; i < table.lines.size(); ++i) {
        const auto& line = table.lines[i];
        require(line.physical_line == i + 1 && raw.substr(line.byte_offset, line.raw_bytes.size()) == line.raw_bytes,
                "line provenance exact");
    }
    error(path, [&] { load_galaxy_name_table(path, {bytes.size(), 9}); });
    error(path, [&] { load_galaxy_name_table(path, {bytes.size() - 1, 10}); });
    require(load_galaxy_name_table(path, {bytes.size(), 10}).lines.size() == 10, "exact name limits");
    write(path, {}); require(load_galaxy_name_table(path, {0, 0}).lines.empty(), "empty name table");
}
void local_tests(const std::filesystem::path& data) {
    check_gc(data / "globular_cluster.dat"); check_nbg(data / "NBG.dat");
    for (const char* name : {"gc.dat", "NBG2.dat"}) {
        const auto path = data / name;
        const auto bytes = read(path);
        require(load_galaxy_catalog_source(path).bytes == bytes, "unresolved source remains raw");
    }
    for (const char* name : {"nearby_galaxies_name.dat", "nearby_galaxy_names.dat", "nearby_galaxy_names_jp.dat"}) {
        const auto path = data / name;
        const auto bytes = read(path);
        const auto table = load_galaxy_name_table(path);
        require(table.source.bytes == bytes, "local name source exact");
        std::size_t offset = 0;
        for (const auto& line : table.lines) {
            require(line.byte_offset == offset && std::equal(line.raw_bytes.begin(), line.raw_bytes.end(),
                bytes.begin() + offset, [](char a, std::uint8_t b) { return std::uint8_t(a) == b; }), "local name line exact");
            offset += line.raw_bytes.size();
            if (offset < bytes.size()) { require(bytes[offset] == '\n', "only LF omitted from line"); ++offset; }
        }
        require(offset == bytes.size() && read(path) == bytes, "all local name bytes retained and unchanged");
    }
}
} // namespace

int main(int argc, char** argv) {
    try {
        Fixtures fixtures;
        binary_tests(fixtures.root / "binary.dat"); position_tests(); name_tests(fixtures.root / "names.dat");
        if (argc == 2) local_tests(argv[1]);
        else if (argc != 1) throw std::runtime_error("usage: test_galaxy_catalog [PLUS_DATA_DIR]");
        std::cout << "galaxy catalog: " << checks << " checks passed\n";
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
