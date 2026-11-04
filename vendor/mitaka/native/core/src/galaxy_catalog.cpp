#include "mitaka/galaxy_catalog.hpp"
#include "galaxy_catalog_input.hpp"

#include <cmath>
#include <fstream>
#include <limits>
#include <string_view>

namespace mitaka {

GalaxyCatalogSource load_galaxy_catalog_source(const std::filesystem::path& path,
                                              CatalogLoadLimits limits) {
    std::ifstream stream(path, std::ios::binary | std::ios::ate);
    if (!stream) throw CatalogError(path, 0, "cannot open galaxy catalog");
    const auto end = stream.tellg();
    if (end < 0) throw CatalogError(path, 0, "cannot determine galaxy catalog size");
    const auto size = static_cast<std::uint64_t>(end);
    if (size > limits.max_file_bytes || size > std::numeric_limits<std::size_t>::max() ||
        size > static_cast<std::uint64_t>(std::numeric_limits<std::streamsize>::max()))
        throw CatalogError(path, 0, "galaxy catalog exceeds byte limit");
    GalaxyCatalogSource source{path, std::vector<std::uint8_t>(static_cast<std::size_t>(size))};
    stream.seekg(0);
    if (size) stream.read(reinterpret_cast<char*>(source.bytes.data()), static_cast<std::streamsize>(size));
    if (!stream) throw CatalogError(path, 0, "galaxy catalog read failed");
    // 読取中の追記を黙って落とさない。原本へは書き込まない。
    if (stream.peek() != std::char_traits<char>::eof())
        throw CatalogError(path, size, "galaxy catalog changed while reading");
    return source;
}

PlusGlobularClusterCatalog load_plus_globular_clusters(const std::filesystem::path& path,
                                                       CatalogLoadLimits limits) {
    PlusGlobularClusterCatalog result{load_galaxy_catalog_source(path, limits), {}};
    galaxy_detail::Input input(result.source, limits);
    const auto count = input.fixed_count(40);
    result.records.reserve(count);
    for (std::size_t i = 0; i < count; ++i) {
        PlusGlobularClusterRecord row;
        for (auto& byte : row.name_bytes) byte = input.byte();
        row.right_ascension_degrees = input.f32();
        row.declination_degrees = input.f32();
        row.distance_pc = input.f32();
        row.core_radius_pc = input.f32();
        row.half_light_radius_pc = input.f32();
        row.color_b_minus_v = input.f32();
        row.color_v_minus_r = input.f32();
        result.records.push_back(row);
    }
    return result;
}

PlusNearbyGalaxyCatalog load_plus_nearby_galaxies(const std::filesystem::path& path,
                                                 CatalogLoadLimits limits) {
    PlusNearbyGalaxyCatalog result{load_galaxy_catalog_source(path, limits), {}};
    galaxy_detail::Input input(result.source, limits);
    const auto count = input.fixed_count(27);
    result.records.reserve(count);
    for (std::size_t i = 0; i < count; ++i) {
        PlusNearbyGalaxyRecord row;
        row.right_ascension_degrees = input.f32();
        row.declination_degrees = input.f32();
        row.distance_pc = input.f32();
        row.angular_diameter_arcminutes = input.f32();
        row.minor_major_axis_ratio = input.f32();
        row.render_class_code = input.byte();
        row.auxiliary_code = input.byte();
        row.catalog_code = input.byte();
        row.catalog_number = input.i32();
        result.records.push_back(row);
    }
    return result;
}

GalaxyPositionResult evaluate_galaxy_position_pc(float ra, float dec, float distance) {
    GalaxyPositionResult result;
    const auto add = [&](GalaxyPositionIssue issue) {
        result.issues |= static_cast<GalaxyPositionIssues>(issue);
    };
    if (!std::isfinite(ra)) add(GalaxyPositionIssue::nonfinite_ra);
    else if (ra < 0 || ra >= 360) add(GalaxyPositionIssue::ra_out_of_range);
    if (!std::isfinite(dec)) add(GalaxyPositionIssue::nonfinite_dec);
    else if (dec < -90 || dec > 90) add(GalaxyPositionIssue::dec_out_of_range);
    if (!std::isfinite(distance)) add(GalaxyPositionIssue::nonfinite_distance);
    else if (distance < 0) add(GalaxyPositionIssue::negative_distance);
    else if (distance == 0) add(GalaxyPositionIssue::zero_distance);
    if ((result.issues & ~static_cast<GalaxyPositionIssues>(GalaxyPositionIssue::zero_distance)) != 0)
        return result;
    const Vec3 direction = equatorial_direction({ra, dec});
    const Vec3 equatorial{direction.x * double(distance), direction.y * double(distance),
                          direction.z * double(distance)};
    const Vec3 ecliptic = j2000_equatorial_to_ecliptic(equatorial);
    result.position = GalaxyPositionPc{{equatorial.x, equatorial.y, equatorial.z},
                                       {ecliptic.x, ecliptic.y, ecliptic.z}};
    return result;
}

GalaxyNameTable load_galaxy_name_table(const std::filesystem::path& path, CatalogLoadLimits limits) {
    GalaxyNameTable table{load_galaxy_catalog_source(path, limits), {}};
    const auto& bytes = table.source.bytes;
    std::size_t offset = 0;
    const auto space = [](char c) { return c == ' ' || c == '\t' || c == '\r'; };
    while (offset < bytes.size()) {
        if (table.lines.size() == limits.max_records)
            throw CatalogError(path, offset, "galaxy name table exceeds line limit");
        GalaxyNameLine line;
        line.byte_offset = offset;
        line.physical_line = table.lines.size() + 1;
        const auto start = offset;
        while (offset < bytes.size() && bytes[offset] != '\n') ++offset;
        line.raw_bytes.assign(reinterpret_cast<const char*>(bytes.data() + start), offset - start);
        if (offset < bytes.size()) ++offset;
        std::string_view view(line.raw_bytes);
        while (!view.empty() && space(view.front())) view.remove_prefix(1);
        if (view.empty()) line.kind = GalaxyNameLineKind::blank;
        else if (view.front() == '%' || view.front() == '#') line.kind = GalaxyNameLineKind::comment;
        else if (view.find('\0') != std::string_view::npos)
            line.diagnostic = "NUL byte in galaxy name line";
        else {
            std::size_t length = 0;
            while (length < view.size() && !space(view[length])) ++length;
            line.key_bytes = std::string(view.substr(0, length));
            view.remove_prefix(length);
            while (!view.empty() && space(view.front())) view.remove_prefix(1);
            if (!view.empty() && view.front() == '*') {
                line.featured = true;
                view.remove_prefix(1);
            }
            // CP932 の日本語・全角空白・ルビは bytes のまま残す。
            line.payload_bytes = std::string(view);
            if (view.find_first_not_of(" \t\r") == std::string_view::npos)
                line.diagnostic = "missing galaxy name payload";
            else line.kind = GalaxyNameLineKind::entry;
        }
        table.lines.push_back(std::move(line));
    }
    return table;
}

} // namespace mitaka
