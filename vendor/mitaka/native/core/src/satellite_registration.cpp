#include "mitaka/satellite_model.hpp"

#include <algorithm>
#include <map>
#include <utility>

namespace mitaka {

SatelliteRegistrationEvaluation make_isolated_satellite_registration(
    const SatelliteDataset& dataset, const std::string& source_key) {
    SatelliteRegistrationEvaluation result;
    const auto sources = std::count_if(dataset.sources.begin(), dataset.sources.end(), [&](const auto& source) {
        return source.key == source_key && source.kind == SatelliteSourceKind::system_definition &&
            source.read_complete && source.parsed;
    });
    if (sources != 1) {
        result.diagnostics.push_back({SatelliteModelDiagnosticCode::invalid_registration, std::nullopt, source_key,
            "satellite registration: require one fully read and parsed definition source"});
        return result;
    }
    VerifiedSatelliteRegistration registration{source_key, {}, {},
        "native isolated empty container; all referenced Orbit sources read through EOF; original block order",
        SatelliteRegistrationOrigin::isolated_native_source};
    std::map<std::size_t, SatelliteDefinitionKind> kinds;
    for (const auto& definition : dataset.definitions)
        if (definition.id.source_key == source_key) kinds.emplace(definition.id.record_ordinal, definition.kind);
    for (std::size_t i = 0; i < dataset.definitions.size(); ++i) {
        const auto& definition = dataset.definitions[i];
        if (definition.id.source_key != source_key) continue;
        const auto parent = definition.parent_ordinal ? kinds.find(*definition.parent_ordinal) : kinds.end();
        using Kind = SatelliteDefinitionKind;
        const bool structure = (definition.kind == Kind::system && !definition.parent_ordinal) ||
            (parent != kinds.end() &&
             ((definition.kind == Kind::sun && parent->second == Kind::system) ||
              (definition.kind == Kind::planet && parent->second == Kind::sun) ||
              (definition.kind == Kind::satellite && parent->second == Kind::planet)));
        if (!structure) {
            result.diagnostics.push_back({SatelliteModelDiagnosticCode::unresolved_registration, i, "block",
                "satellite registration: unsupported definition hierarchy prevents registration proof"});
        }
        if (definition.kind != Kind::planet && definition.kind != Kind::satellite) continue;
        if (!definition.orbit_source_index || *definition.orbit_source_index >= dataset.sources.size() ||
            dataset.sources[*definition.orbit_source_index].kind != SatelliteSourceKind::orbit ||
            !dataset.sources[*definition.orbit_source_index].read_complete) {
            // 未読は原版 fopen 失敗の証拠ではない。後続 index を詰めて推定しない。
            result.diagnostics.push_back({SatelliteModelDiagnosticCode::unresolved_registration, i, "Orbit",
                "satellite registration: unread or ambiguous Orbit prevents isolated registration proof"});
            continue;
        }
        auto& ordinals = definition.kind == SatelliteDefinitionKind::planet
            ? registration.planet_definition_ordinals : registration.satellite_definition_ordinals;
        ordinals.push_back(definition.id.record_ordinal);
    }
    if (result.diagnostics.empty()) result.registration = std::move(registration);
    return result;
}

} // namespace mitaka
