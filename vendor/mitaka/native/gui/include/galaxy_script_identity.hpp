#pragma once

#include "galaxy_spatial_scene.hpp"
#include <algorithm>
#include <charconv>
#include <filesystem>
#include <exception>
#include <stdexcept>
#include <string>

namespace mitaka::gui {

class AmbiguousRawGalaxyTarget : public std::invalid_argument {
public:
    explicit AmbiguousRawGalaxyTarget(const std::string& target)
        : std::invalid_argument("Ambiguous raw galaxy target: " + target) {}
};

inline std::string resolve_script_galaxy_alias(const std::string& target) {
    if (target == "Other.M31") return "Galaxy.Andromeda Galaxy";
    if (target == "Other.M13") return "GC.NGC 6205";
    if (target == "Other.M87") return "Galaxy.M87";
    return target;
}

// Plus 側の識別子を変換せず、全出典において一意な場合だけ解決する。
inline std::optional<GalaxySpatialRecordId> resolve_raw_galaxy_target(
    const std::string& target, const GalaxySpatialModel& model) {
    constexpr std::string_view prefix = "Galaxy.#";
    if (target.compare(0, prefix.size(), prefix) != 0) return std::nullopt;
    const auto key = std::string_view(target).substr(prefix.size());
    if (key.size() < 2 || static_cast<unsigned char>(key[0]) < 33 ||
        static_cast<unsigned char>(key[0]) > 126)
        throw std::invalid_argument("Invalid raw galaxy target: " + target);
    std::int32_t number = 0;
    const auto parsed = std::from_chars(key.data() + 1, key.data() + key.size(), number);
    if (parsed.ec != std::errc{} || parsed.ptr != key.data() + key.size() || number <= 0 ||
        std::to_string(number) != key.substr(1))
        throw std::invalid_argument("Invalid raw galaxy target: " + target);
    std::optional<GalaxySpatialRecordId> match;
    for (std::size_t source = 0; source < model.sources().size(); ++source) {
        const auto* catalog = std::get_if<PlusNearbyGalaxyCatalog>(&model.sources()[source]);
        if (!catalog) continue;
        for (std::size_t ordinal = 0; ordinal < catalog->records.size(); ++ordinal) {
            const auto& record = catalog->records[ordinal];
            if (record.catalog_code != static_cast<unsigned char>(key[0]) || record.catalog_number != number) continue;
            if (match) throw AmbiguousRawGalaxyTarget(target);
            match = GalaxySpatialRecordId{GalaxySpatialFamily::nearby_galaxy, source, ordinal};
        }
    }
    if (!match) throw std::invalid_argument("Unknown raw galaxy target: " + target);
    return match;
}

inline GalaxySpatialRecordId resolve_script_nearby_galaxy(
    const std::string& target, const std::optional<std::filesystem::path>& dataPath, const GalaxySpatialModel& model);

inline std::string script_galaxy_target_identity(const GalaxySpatialModel& model, GalaxySpatialRecordId id,
    const std::optional<std::filesystem::path>& dataPath = std::nullopt) {
    if (id.source_index >= model.sources().size()) return {};
    const auto& source = model.sources()[id.source_index];
    if (id.family == GalaxySpatialFamily::nearby_galaxy) {
        const auto* catalog = std::get_if<PlusNearbyGalaxyCatalog>(&source);
        if (!catalog || id.ordinal >= catalog->records.size()) return {};
        const auto& record = catalog->records[id.ordinal];
        if (record.catalog_code < 33 || record.catalog_code > 126 || record.catalog_number <= 0) return {};
        const auto target = "Galaxy.#" + std::string(1, static_cast<char>(record.catalog_code)) +
                            std::to_string(record.catalog_number);
        try {
            return resolve_script_nearby_galaxy(target, dataPath, model) == id ? target : std::string{};
        } catch (const std::invalid_argument&) { return {}; }
        catch (const CatalogError&) { return {}; }
    }
    if (id.family != GalaxySpatialFamily::globular_cluster) return {};
    const auto* catalog = std::get_if<PlusGlobularClusterCatalog>(&source);
    if (!catalog || id.ordinal >= catalog->records.size()) return {};
    const auto name_for = [](const PlusGlobularClusterRecord& record) {
        const auto end = std::find(record.name_bytes.begin(), record.name_bytes.end(), 0);
        return std::string(record.name_bytes.begin(), end);
    };
    const auto name = name_for(catalog->records[id.ordinal]);
    if (name.empty() || !std::all_of(name.begin(), name.end(), [](unsigned char c) { return c >= 32 && c < 127; })) return {};
    std::size_t matches = 0;
    for (const auto& candidate : model.sources()) {
        const auto* clusters = std::get_if<PlusGlobularClusterCatalog>(&candidate);
        if (!clusters) continue;
        for (const auto& row : clusters->records) if (name_for(row) == name) ++matches;
    }
    return matches == 1 ? "GC." + name : std::string{};
}

inline mitaka::gui::GalaxySpatialRecordId resolve_script_globular_cluster(
    const std::string& target, const mitaka::gui::GalaxySpatialModel& model) {
    const auto name = target.substr(3);
    if (name.empty()) throw std::invalid_argument("Empty globular-cluster target");
    std::optional<mitaka::gui::GalaxySpatialRecordId> match;
    for (std::size_t source = 0; source < model.sources().size(); ++source) {
        const auto* catalog = std::get_if<mitaka::PlusGlobularClusterCatalog>(&model.sources()[source]);
        if (!catalog) continue;
        for (std::size_t ordinal = 0; ordinal < catalog->records.size(); ++ordinal) {
            const auto& bytes = catalog->records[ordinal].name_bytes;
            const auto end = std::find(bytes.begin(), bytes.end(), 0);
            const std::string candidate(bytes.begin(), end);
            if (candidate != name) continue;
            if (match) throw std::invalid_argument("Ambiguous globular-cluster target: " + target);
            match = mitaka::gui::GalaxySpatialRecordId{mitaka::gui::GalaxySpatialFamily::globular_cluster, source, ordinal};
        }
    }
    if (!match) throw std::invalid_argument("Unknown globular-cluster target: " + target);
    return *match;
}

inline mitaka::gui::GalaxySpatialRecordId resolve_script_nearby_galaxy(
    const std::string& target, const std::optional<std::filesystem::path>& dataPath, const mitaka::gui::GalaxySpatialModel& model) {
    std::optional<GalaxySpatialRecordId> raw;
    std::exception_ptr rawError;
    try {
        raw = resolve_raw_galaxy_target(target, model);
    } catch (const AmbiguousRawGalaxyTarget&) {
        // 複数の raw レコードがある場合、名前へのフォールバックでも一意にはならない。
        throw;
    } catch (const std::invalid_argument&) {
        // # で始まる既存の名前もあるため、名前表を調べてから失敗とする。
        rawError = std::current_exception();
    }
    if (!dataPath) {
        if (raw) return *raw;
        if (rawError) std::rethrow_exception(rawError);
    }
    const auto name = target.substr(7);
    if (name.empty()) throw std::invalid_argument("Empty galaxy target");
    if (!dataPath) throw std::invalid_argument("Galaxy-name catalog is unavailable");
    const auto path = *dataPath / "nearby_galaxies_name.dat";
    std::optional<mitaka::gui::GalaxySpatialRecordId> match = raw;
    for (const auto& line : mitaka::load_galaxy_name_table(path).lines) {
        if (line.kind != mitaka::GalaxyNameLineKind::entry || line.key_bytes.size() < 2) continue;
        // 英語名の後ろには間隔を置いて CP932 の日本語名が続く。
        auto end = line.payload_bytes.find("  ");
        const auto nonAscii = std::find_if(line.payload_bytes.begin(), line.payload_bytes.end(),
                                           [](unsigned char ch) { return ch >= 0x80; });
        end = std::min(end, static_cast<std::size_t>(nonAscii - line.payload_bytes.begin()));
        auto candidate = line.payload_bytes.substr(0, end);
        const auto last = candidate.find_last_not_of(" \t\r");
        if (last == std::string::npos) continue;
        candidate.resize(last + 1);
        if (candidate != name) continue;
        std::int32_t number = 0;
        const char *first = line.key_bytes.data() + 1, *lastKey = line.key_bytes.data() + line.key_bytes.size();
        const auto parsed = std::from_chars(first, lastKey, number);
        if (parsed.ec != std::errc{} || parsed.ptr != lastKey || number <= 0) continue;
        for (std::size_t source = 0; source < model.sources().size(); ++source) {
            const auto* catalog = std::get_if<mitaka::PlusNearbyGalaxyCatalog>(&model.sources()[source]);
            if (!catalog) continue;
            for (std::size_t ordinal = 0; ordinal < catalog->records.size(); ++ordinal) {
                const auto& record = catalog->records[ordinal];
                if (record.catalog_code != static_cast<unsigned char>(line.key_bytes.front()) ||
                    record.catalog_number != number) continue;
                const mitaka::gui::GalaxySpatialRecordId id{mitaka::gui::GalaxySpatialFamily::nearby_galaxy, source, ordinal};
                if (match && !(*match == id)) throw std::invalid_argument("Ambiguous galaxy target: " + target);
                match = id;
            }
        }
    }
    if (!match) {
        if (rawError) std::rethrow_exception(rawError);
        throw std::invalid_argument("Unknown galaxy target: " + target);
    }
    return *match;
}

inline std::string script_galaxy_target_for_snapshot(
    const GalaxySpatialModel* model, GalaxySpatialRecordId selected,
    const GalaxySpatialModel* script_model, const std::optional<GalaxySpatialRecordId>& script_id,
    const std::string& script_target, const std::optional<std::filesystem::path>& dataPath = std::nullopt) {
    if (!model) return {};
    if (script_model != model || !script_id || !(selected == *script_id))
        return script_galaxy_target_identity(*model, selected, dataPath);
    const auto resolved = resolve_script_galaxy_alias(script_target);
    try {
        if (selected.family == GalaxySpatialFamily::nearby_galaxy && resolved.compare(0, 7, "Galaxy.") == 0 &&
            resolve_script_nearby_galaxy(resolved, dataPath, *model) == selected) return script_target;
        if (selected.family == GalaxySpatialFamily::globular_cluster && resolved.compare(0, 3, "GC.") == 0 &&
            resolve_script_globular_cluster(resolved, *model) == selected) return script_target;
        return {};
    } catch (const std::invalid_argument&) { return {}; }
    catch (const CatalogError&) { return {}; }
}

} // namespace mitaka::gui
