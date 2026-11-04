#include "mitaka/satellite_model.hpp"

#include <cmath>
#include <map>
#include <set>
#include <utility>

namespace mitaka {
namespace {
using Code = SatelliteModelDiagnosticCode;
using DefinitionKey = std::pair<std::string, std::size_t>;
using NameKey = std::pair<std::string, std::string>;

std::string identifier(const SatelliteDefinition& definition) {
    const auto* field = unique_satellite_field(definition.fields, "Name");
    if (!field) return {};
    // 原版 sscanf("%*s %s") の byte token。表示名の CP932 bytes は変換しない。
    const auto start = field->value_bytes.find_first_not_of(" \t\r\n\v\f");
    if (start == std::string::npos) return {};
    return field->value_bytes.substr(start, field->value_bytes.find_first_of(" \t\r\n\v\f", start)-start);
}

void diagnose(SatelliteModelRecord& record, Code code, const std::string& field, const std::string& message) {
    record.diagnostics.push_back({code, record.definition_index, field, message});
}

void elements(SatelliteModelRecord& record, const SatelliteOrbitRecord& orbit) {
    const auto& fields = orbit.fields;
    const auto epoch = satellite_scalar(fields, "Epoch"), a = satellite_scalar(fields, "a"),
        e = satellite_scalar(fields, "e"), m = satellite_scalar(fields, "M0"),
        n = satellite_scalar(fields, "n"), pw = satellite_scalar(fields, "Pw"),
        pn = satellite_scalar(fields, "Pnode"), w = satellite_scalar(fields, "w"),
        inclination = satellite_scalar(fields, "i"), node = satellite_scalar(fields, "node");
    for (const auto* key : {"Epoch", "a", "e", "M0", "n", "Pw", "Pnode", "w", "i", "node"}) {
        if (!satellite_scalar(fields, key))
            diagnose(record, Code::invalid_field, key, "satellite model: required finite scalar is absent or ambiguous");
    }
    if (!(epoch && a && e && m && n && pw && pn && w && inclination && node)) return;
    const auto* plane = unique_satellite_field(fields, "RefPlane");
    if (!plane || plane->value_bytes.size() != 1) {
        diagnose(record, Code::invalid_field, "RefPlane", "satellite model: reference plane is absent or ambiguous");
        return;
    }
    record.position_elements = SatellitePositionElements{*epoch, *a, *e, *m, *n, *pw, *pn};
    record.rotation_input.reference_plane = plane->value_bytes.front();
    record.rotation_input.elements = SatelliteRotationElements{
        *epoch, *w, *inclination, *node, *pw, *pn,
        satellite_scalar(fields, "RA"), satellite_scalar(fields, "Decl")};
}

struct RegistrationIndices {
    std::map<std::size_t, LegacyPlanetRegistrationIndex> planets;
    std::map<std::size_t, std::size_t> satellites;
    std::set<std::string> sources;
};

bool read_complete_orbit(const SatelliteDataset& data, const SatelliteDefinition& definition) {
    return definition.orbit_source_index && *definition.orbit_source_index < data.sources.size() &&
        data.sources[*definition.orbit_source_index].kind == SatelliteSourceKind::orbit &&
        data.sources[*definition.orbit_source_index].read_complete;
}

RegistrationIndices registration_indices(
    const SatelliteDataset& data, const std::vector<VerifiedSatelliteRegistration>& registrations,
    const std::map<DefinitionKey, std::size_t>& definitions,
    std::vector<SatelliteModelDiagnostic>& diagnostics) {
    RegistrationIndices indices;
    std::map<std::string, std::size_t> counts;
    std::map<std::pair<std::string, SatelliteDefinitionKind>, std::vector<std::size_t>> known_reads;
    std::set<std::string> parsed_sources;
    for (std::size_t i = 0; i < data.definitions.size(); ++i) {
        const auto& definition = data.definitions[i];
        if (read_complete_orbit(data, definition)) known_reads[{definition.id.source_key, definition.kind}].push_back(i);
    }
    for (const auto& source : data.sources)
        if (source.kind == SatelliteSourceKind::system_definition && source.parsed) parsed_sources.insert(source.key);
    for (const auto& registration : registrations) ++counts[registration.source_key];
    for (const auto& registration : registrations) {
        bool valid = !registration.evidence.empty() && counts[registration.source_key] == 1 &&
            (registration.origin == SatelliteRegistrationOrigin::verified_legacy_container ||
             registration.origin == SatelliteRegistrationOrigin::isolated_native_source);
        const auto select = [&](const std::vector<std::size_t>& ordinals, SatelliteDefinitionKind kind) {
            std::vector<std::size_t> selected;
            std::optional<std::size_t> previous;
            for (const auto ordinal : ordinals) {
                const auto found = definitions.find({registration.source_key, ordinal});
                if (found == definitions.end() || data.definitions[found->second].kind != kind ||
                    (previous && ordinal <= *previous) || !read_complete_orbit(data, data.definitions[found->second]))
                    valid = false;
                else selected.push_back(found->second);
                previous = ordinal;
            }
            // 読取成功が観測済みの定義を証拠から除外すると、後続 index がずれる。
            if (selected != known_reads[{registration.source_key, kind}]) valid = false;
            return selected;
        };
        const auto planets = select(registration.planet_definition_ordinals, SatelliteDefinitionKind::planet);
        const auto satellites = select(registration.satellite_definition_ordinals, SatelliteDefinitionKind::satellite);
        if (!valid || !parsed_sources.count(registration.source_key)) {
            diagnostics.push_back({Code::invalid_registration, std::nullopt, registration.source_key,
                "satellite model: registration requires one evidenced source, complete orbit reads and all successful blocks in order"});
            continue;
        }
        indices.sources.insert(registration.source_key);
        for (std::size_t i = 0; i < planets.size(); ++i) indices.planets.emplace(planets[i], LegacyPlanetRegistrationIndex{i});
        for (std::size_t i = 0; i < satellites.size(); ++i) indices.satellites.emplace(satellites[i], i);
    }
    return indices;
}
} // namespace

SatelliteModel::SatelliteModel(SatelliteDataset dataset,
    std::vector<VerifiedSatelliteRegistration> registrations)
    : dataset_(std::move(dataset)), registrations_(std::move(registrations)) {
    std::map<DefinitionKey, std::size_t> definitions;
    std::map<NameKey, std::size_t> first_satellites;
    std::set<std::string> unresolved_satellite_names;
    std::vector<std::string> identifiers;
    for (std::size_t i = 0; i < dataset_.definitions.size(); ++i) {
        const auto& definition = dataset_.definitions[i];
        definitions.emplace(DefinitionKey{definition.id.source_key, definition.id.record_ordinal}, i);
        identifiers.push_back(identifier(definition));
        if (definition.kind == SatelliteDefinitionKind::satellite) {
            SatelliteModelRecord record{};
            record.definition_index = i;
            record.identifier_bytes = identifiers.back();
            records_.push_back(std::move(record));
        }
    }
    const auto indices = registration_indices(dataset_, registrations_, definitions, diagnostics_);
    std::map<std::string, std::size_t> contexts;
    for (const auto& registration : registrations_) {
        if (!indices.sources.count(registration.source_key)) continue;
        contexts.emplace(registration.source_key, registration_contexts_.size());
        registration_contexts_.push_back({registration.source_key, registration.origin,
            registration.evidence, {}, {}, true, true});
    }
    std::map<NameKey, std::size_t> first_planets;
    for (const auto& item : indices.planets) {
        const auto& definition = dataset_.definitions[item.first];
        const auto& name = identifiers[item.first];
        auto& context = registration_contexts_[contexts.at(definition.id.source_key)];
        context.planets.push_back({item.first, name, item.second});
        if (name.empty()) context.planet_identifiers_complete = false;
        if (!name.empty() && !first_planets.emplace(NameKey{definition.id.source_key, name}, item.first).second)
            diagnostics_.push_back({Code::shadowed_identifier, item.first, "Name",
                "satellite model: earlier registered Planet has the same identifier"});
    }
    for (std::size_t i = 0; i < records_.size(); ++i) {
        auto& record = records_[i];
        const auto& definition = dataset_.definitions[record.definition_index];
        if (!indices.sources.count(definition.id.source_key)) continue;
        const auto found = indices.satellites.find(record.definition_index);
        record.registered = found != indices.satellites.end();
        if (!*record.registered) {
            diagnose(record, Code::unregistered_satellite, "Orbit", "satellite model: definition is excluded by verified registration");
            continue;
        }
        record.registration_index = found->second;
        auto& context = registration_contexts_[contexts.at(definition.id.source_key)];
        context.satellite_record_indices.push_back(i);
        if (record.identifier_bytes.empty()) context.satellite_identifiers_complete = false;
        if (record.identifier_bytes.empty()) unresolved_satellite_names.insert(definition.id.source_key);
        else if (!first_satellites.emplace(NameKey{definition.id.source_key, record.identifier_bytes}, i).second)
            diagnose(record, Code::shadowed_identifier, "Name", "satellite model: earlier registered Satellite has the same identifier");
    }
    for (auto& record : records_) {
        const auto& definition = dataset_.definitions[record.definition_index];
        record.rotation_input.name_bytes = record.identifier_bytes;
        if (record.identifier_bytes.empty())
            diagnose(record, Code::missing_field, "Name", "satellite model: name token is absent or ambiguous");
        const auto structural = definition.parent_ordinal
            ? definitions.find({definition.id.source_key, *definition.parent_ordinal}) : definitions.end();
        if (structural == definitions.end() ||
            dataset_.definitions[structural->second].kind != SatelliteDefinitionKind::planet) {
            diagnose(record, Code::unresolved_parent, "Planet", "satellite model: structural parent Planet is unresolved");
            continue;
        }
        record.parent_definition_index = structural->second;
        // 子の読込は親 Planet の append 前。lookup("Mars") は親 index を返せない。
        record.rotation_input.apply_mars_node_correction = false;
        const auto registration = indices.planets.find(structural->second);
        if (indices.sources.count(definition.id.source_key)) {
            record.parent_registered = registration != indices.planets.end();
            if (!*record.parent_registered)
                diagnose(record, Code::unregistered_parent, "Planet",
                    "satellite model: structural parent did not register; legacy numeric parent may refer to another Planet");
        }
        if (registration != indices.planets.end()) record.parent_registration_index = registration->second;
        if (!definition.orbit_index || *definition.orbit_index >= dataset_.orbits.size()) {
            diagnose(record, Code::missing_field, "Orbit", "satellite model: orbit record is unresolved");
            continue;
        }
        const auto& orbit = dataset_.orbits[*definition.orbit_index];
        elements(record, orbit);
        const auto* declared = unique_satellite_field(orbit.fields, "Planet");
        if (declared && declared->value_bytes != identifiers[structural->second])
            diagnose(record, Code::conflicting_parent, "Planet", "satellite model: ignored orbit metadata differs from structural parent");
        if (record.rotation_input.reference_plane == 'C') {
            const auto charon = first_satellites.find({definition.id.source_key, "Charon"});
            if (charon == first_satellites.end() || unresolved_satellite_names.count(definition.id.source_key))
                diagnose(record, Code::unresolved_charon, "RefPlane", "satellite model: first registered Charon requires verified lookup order and identifiers");
            else record.rotation_input.charon_rotation_index = charon->second;
        }
    }
}

SatelliteModelEvaluation SatelliteModel::evaluate(double jd,
    const std::vector<SatelliteModelParentPole>& parent_poles) const {
    SatelliteModelEvaluation result{jd, {}, diagnostics_};
    if (!std::isfinite(jd))
        result.diagnostics.push_back({Code::invalid_context, std::nullopt, "time", "satellite model: non-finite legacy Julian date"});
    std::map<std::size_t, std::vector<const SatelliteParentPole*>> poles;
    for (const auto& supplied : parent_poles) {
        if (supplied.parent_definition_index >= dataset_.definitions.size() ||
            dataset_.definitions[supplied.parent_definition_index].kind != SatelliteDefinitionKind::planet) {
            result.diagnostics.push_back({Code::invalid_context, supplied.parent_definition_index, "parent_pole",
                "satellite model: parent pole does not reference a Planet definition"});
        } else poles[supplied.parent_definition_index].push_back(&supplied.pole);
    }
    for (const auto& supplied : poles) {
        if (supplied.second.size() > 1)
            result.diagnostics.push_back({Code::invalid_context, supplied.first, "parent_pole",
                "satellite model: duplicate parent poles are ambiguous"});
    }
    std::vector<SatelliteRotationInput> rotations;
    std::vector<std::vector<SatelliteParentPoleDiagnostic>> pole_diagnostics(records_.size());
    for (const auto& record : records_) {
        auto input = record.rotation_input;
        if (!record.parent_definition_index || record.identifier_bytes.empty() ||
            record.registered == false || record.parent_registered == false) input.elements.reset();
        if (input.reference_plane == 'Q' && record.parent_definition_index) {
            const auto supplied = poles.find(*record.parent_definition_index);
            if (supplied != poles.end()) {
                if (supplied->second.size() == 1) input.parent_pole = *supplied->second.front();
            } else if (record.parent_registration_index) {
                const auto evaluated = evaluate_legacy_satellite_parent_pole(*record.parent_registration_index, jd);
                input.parent_pole = evaluated.pole;
                pole_diagnostics[rotations.size()] = evaluated.diagnostics;
            }
        }
        rotations.push_back(std::move(input));
    }
    for (std::size_t i = 0; i < records_.size(); ++i) {
        const auto& record = records_[i];
        SatelliteModelPosition position{record.definition_index, {}, record.diagnostics, {}, {}, pole_diagnostics[i], {}};
        if (record.identifier_bytes == "Moon") {
            position.diagnostics.push_back({Code::unsupported_moon, record.definition_index, "Name",
                "satellite model: Moon requires its separate analytic position path"});
        } else if (record.position_elements && record.parent_definition_index && !record.identifier_bytes.empty() &&
                   record.registered != false && record.parent_registered != false) {
            if (record.rotation_input.reference_plane == 'Q' && !rotations[i].parent_pole)
                position.diagnostics.push_back({Code::unresolved_registration, record.definition_index, "parent_pole",
                    "satellite model: Q requires an unambiguous parent pole or verified successful Planet registration"});
            const auto rotation = evaluate_satellite_rotation(rotations, i, jd);
            position.rotation_diagnostics = rotation.diagnostics;
            if (rotation.rotation) {
                const auto evaluated = evaluate_satellite_relative_position(*record.position_elements, {jd, *rotation.rotation}, jd);
                position.relative_position_km = evaluated.relative_position_km;
                if (evaluated.relative_position_km) position.rotation = rotation.rotation;
                position.position_diagnostics = evaluated.diagnostics;
            }
        }
        result.positions.push_back(std::move(position));
    }
    return result;
}
} // namespace mitaka
