#pragma once

#include "mitaka/small_body_catalog.hpp"
#include "mitaka/spacecraft_trajectory.hpp"
#include <algorithm>
#include <charconv>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>

namespace mitaka::gui {

inline std::optional<std::size_t> resolveScriptSmallBody(const std::string& target,
                                                          const mitaka::SmallBodyDataset& dataset) {
    mitaka::SmallBodyKind kind;
    std::size_t prefix;
    if (target.compare(0, 10, "Asteroids.") == 0) { kind = mitaka::SmallBodyKind::asteroid; prefix = 10; }
    else if (target.compare(0, 4, "TNO.") == 0) { kind = mitaka::SmallBodyKind::trans_neptunian; prefix = 4; }
    else if (target.compare(0, 6, "Comet.") == 0) { kind = mitaka::SmallBodyKind::comet; prefix = 6; }
    else return std::nullopt;
    const std::string name = target.substr(prefix);
    if (name.empty()) throw std::invalid_argument("Empty small-body target");
    std::int32_t number = 0;
    const auto parsed = std::from_chars(name.data(), name.data() + name.size(), number);
    const bool isNumber = kind != mitaka::SmallBodyKind::comet && parsed.ec == std::errc{} &&
                          parsed.ptr == name.data() + name.size() && number > 0;
    std::optional<std::size_t> match;
    const auto& records = dataset.records;
    for (std::size_t index = 0; index < records.size(); ++index) {
        const auto& record = records[index];
        if (record.kind != kind) continue;
        const bool matches = isNumber ? record.number == number :
            record.name_bytes == name || std::find(record.alias_bytes.begin(), record.alias_bytes.end(), name) != record.alias_bytes.end();
        if (!matches) continue;
        if (match) throw std::invalid_argument("Ambiguous small-body target: " + target);
        match = index;
    }
    if (!match) throw std::invalid_argument("Unknown small-body target: " + target);
    return match;
}

inline std::size_t resolveScriptSpacecraft(const std::string& target,
                                            const mitaka::SpacecraftDataset& dataset) {
    if (target.compare(0, 11, "Spacecraft.") != 0) throw std::invalid_argument("Invalid spacecraft target");
    const std::string name = target.substr(11);
    if (name.empty()) throw std::invalid_argument("Empty spacecraft target");
    std::optional<std::size_t> match;
    const auto& definitions = dataset.definitions;
    for (std::size_t index = 0; index < definitions.size(); ++index) {
        const auto& definition = definitions[index];
        bool matches = false;
        for (const auto& key : {std::pair{"Name", ""}, {"DisplayName", ""}, {"KEY", ""},
                                {"NAME", "ja"}, {"NAME", "default"}}) {
            const auto* field = mitaka::unique_spacecraft_field(definition, key.first, key.second);
            matches = matches || (field && field->value_bytes == name);
        }
        if (!matches) continue;
        if (match) throw std::invalid_argument("Ambiguous spacecraft target: " + target);
        match = index;
    }
    if (!match) throw std::invalid_argument("Unknown spacecraft target: " + target);
    return *match;
}

// 原バイト列が UTF-8 として扱えない場合、別の天体名に変換しない。
inline bool scriptTargetAscii(const std::string& value) {
    return !value.empty() && std::all_of(value.begin(), value.end(),
        [](unsigned char c) { return c >= 0x20 && c <= 0x7e; });
}

inline std::string smallBodyScriptTarget(const mitaka::SmallBodyDataset& data, std::size_t index) {
    if (index >= data.records.size()) return {};
    const auto& record = data.records[index];
    const char* prefix = record.kind == mitaka::SmallBodyKind::asteroid ? "Asteroids." :
        record.kind == mitaka::SmallBodyKind::trans_neptunian ? "TNO." : "Comet.";
    const auto resolves = [&](const std::string& name) -> std::string {
        if (!scriptTargetAscii(name)) return {};
        const std::string candidate = std::string(prefix) + name;
        if (candidate.size() > 4095) return {};
        try {
            if (resolveScriptSmallBody(candidate, data) == index) return candidate;
        } catch (const std::invalid_argument&) {}
        return {};
    };
    if (record.kind != mitaka::SmallBodyKind::comet && record.number && *record.number > 0)
        if (const auto result = resolves(std::to_string(*record.number)); !result.empty()) return result;
    if (const auto result = resolves(record.name_bytes); !result.empty()) return result;
    for (const auto& alias : record.alias_bytes)
        if (const auto result = resolves(alias); !result.empty()) return result;
    return {};
}

inline std::string spacecraftScriptTarget(const mitaka::SpacecraftDataset& data, std::size_t index) {
    if (index >= data.definitions.size()) return {};
    for (const auto& key : {std::pair{"Name", ""}, {"DisplayName", ""}, {"KEY", ""},
                            {"NAME", "ja"}, {"NAME", "default"}}) {
        const auto* field = mitaka::unique_spacecraft_field(data.definitions[index], key.first, key.second);
        if (!field || !scriptTargetAscii(field->value_bytes)) continue;
        const auto candidate = "Spacecraft." + field->value_bytes;
        if (candidate.size() > 4095) continue;
        try {
            if (resolveScriptSpacecraft(candidate, data) == index) return candidate;
        } catch (const std::invalid_argument&) {}
    }
    return {};
}

inline std::string smallBodySnapshotTarget(const mitaka::SmallBodyDataset* data, std::size_t selected,
    std::optional<std::size_t> previous, const std::string& previousTarget) {
    if (!data) return {};
    if (previous == selected && previousTarget.size() <= 4095 && previousTarget.find('\0') == std::string::npos) {
        try {
            if (resolveScriptSmallBody(previousTarget, *data) == selected) return previousTarget;
        } catch (const std::invalid_argument&) {}
    }
    return smallBodyScriptTarget(*data, selected);
}

inline std::string spacecraftSnapshotTarget(const mitaka::SpacecraftDataset* data, std::size_t selected,
    std::optional<std::size_t> previous, const std::string& previousTarget) {
    if (!data) return {};
    if (previous == selected && previousTarget.size() <= 4095 && previousTarget.find('\0') == std::string::npos &&
        previousTarget.compare(0, 11, "Spacecraft.") == 0) {
        try {
            if (resolveScriptSpacecraft(previousTarget, *data) == selected) return previousTarget;
        } catch (const std::invalid_argument&) {}
    }
    return spacecraftScriptTarget(*data, selected);
}

} // namespace mitaka::gui
