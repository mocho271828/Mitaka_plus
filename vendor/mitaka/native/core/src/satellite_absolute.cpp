#include "mitaka/satellite_absolute.hpp"

#include <cmath>
#include <initializer_list>
#include <map>
#include <stdexcept>

namespace mitaka {
namespace {
using Code = SatelliteAbsoluteDiagnosticCode;
bool finite(Vec3 v) { return std::isfinite(v.x) && std::isfinite(v.y) && std::isfinite(v.z); }
Vec3 add(Vec3 a, Vec3 b) { return {a.x+b.x, a.y+b.y, a.z+b.z}; }
Vec3 scaled(Vec3 v, double scale) { return {v.x*scale, v.y*scale, v.z*scale}; }

void diagnose(std::vector<SatelliteAbsoluteDiagnostic>& diagnostics, Code code,
              std::optional<std::size_t> definition, const std::string& message) {
    diagnostics.push_back({code, definition, "satellite absolute: " + message});
}

struct Lookups {
    std::map<std::size_t, std::size_t> parent_by_definition;
    std::optional<std::size_t> earth, pluto, moon, charon;
};

void correct_pair(SatelliteAbsoluteEvaluation& result, std::optional<std::size_t> parent_index,
                  std::optional<std::size_t> satellite_index, double fraction) {
    if (!parent_index || !satellite_index) return;
    auto& parent = result.planets[*parent_index];
    auto& satellite = result.positions[*satellite_index];
    if (!parent.uncorrected_position_au || !satellite.position_au) {
        parent.position_au.reset(); satellite.position_au.reset();
        diagnose(parent.diagnostics, Code::unavailable_pair_correction, parent.definition_index,
                 "named pair cannot be corrected because its uncorrected positions are unavailable");
        diagnose(satellite.diagnostics, Code::unavailable_pair_correction, satellite.definition_index,
                 "named pair cannot be corrected because its uncorrected positions are unavailable");
        return;
    }
    const auto p = *parent.uncorrected_position_au, s = *satellite.position_au;
    const Vec3 delta{(p.x-s.x)*fraction, (p.y-s.y)*fraction, (p.z-s.z)*fraction};
    const auto corrected_parent = add(p, delta), corrected_satellite = add(s, delta);
    if (!finite(delta) || !finite(corrected_parent) || !finite(corrected_satellite)) {
        parent.position_au.reset(); satellite.position_au.reset();
        diagnose(parent.diagnostics, Code::numerical_range, parent.definition_index, "pair correction overflow");
        diagnose(satellite.diagnostics, Code::numerical_range, satellite.definition_index, "pair correction overflow");
        return;
    }
    parent.position_au = corrected_parent;
    satellite.position_au = corrected_satellite;
    parent.pair_correction_applied = satellite.pair_correction_applied = true;
}
} // namespace

SatelliteAbsoluteEvaluation evaluate_satellite_absolute(const SatelliteModel& model,
    const Cf96Ephemeris& ephemeris, double jd, const SatelliteAbsoluteContext& context) {
    SatelliteAbsoluteEvaluation result{jd, context, {}, model.evaluate(jd), {}, {}, {}};
    result.positions.reserve(model.records().size());
    for (const auto& record : model.records()) result.positions.push_back({record.definition_index, {}, false, {}});
    diagnose(result.diagnostics, Code::unresolved_time_scale, {}, "numeric JD is shared without a UTC/TT/TDB conversion");
    diagnose(result.diagnostics, Code::unknown_accuracy_range, {}, "CF96 coverage does not establish satellite-element accuracy");
    if (!std::isfinite(jd) || context.source_key.empty() || context.cf96_binding_evidence.empty()) {
        diagnose(result.diagnostics, Code::invalid_context, {}, "finite date, selected source and CF96 binding evidence are required");
        return result;
    }
    const auto& contexts = model.registration_contexts();
    const SatelliteRegistrationContext* registration = nullptr;
    for (const auto& candidate : contexts) {
        if (candidate.source_key != context.source_key) continue;
        if (registration) {
            diagnose(result.diagnostics, Code::invalid_context, {}, "multiple registration contexts for one source");
            return result;
        }
        registration = &candidate;
    }
    if (!registration) {
        diagnose(result.diagnostics, Code::unresolved_registration, {}, "selected source has no verified registration context");
        return result;
    }
    result.registration = SatelliteAbsoluteRegistrationEvidence{registration->origin, registration->evidence};
    const bool verified_cf96_branch = jd >= legacy_satellite_cf96_minimum_jd &&
        jd <= legacy_satellite_cf96_maximum_jd;
    if (!verified_cf96_branch)
        diagnose(result.diagnostics, Code::unverified_ephemeris_branch, {},
                 "date is outside the audited legacy CF96 branch; its alternative ephemeris is unresolved");
    Lookups lookups;
    for (const auto& registered : registration->planets) {
        const auto index = result.planets.size();
        lookups.parent_by_definition.emplace(registered.definition_index, index);
        SatelliteAbsolutePlanet parent{registered.definition_index, registered.registration_index,
            registered.identifier_bytes, {}, {}, false, {}};
        if (!verified_cf96_branch) {
            diagnose(parent.diagnostics, Code::unverified_ephemeris_branch, parent.definition_index,
                     "date is outside the audited legacy CF96 branch");
        } else try {
            const auto p = ephemeris.state(registered.registration_index.value, jd).position_au;
            const auto ecliptic = j2000_equatorial_to_ecliptic({p[0],p[1],p[2]});
            parent.uncorrected_position_au = parent.position_au = ecliptic;
        } catch (const std::out_of_range& error) {
            diagnose(parent.diagnostics, Code::outside_ephemeris, parent.definition_index, error.what());
        } catch (const std::invalid_argument& error) {
            diagnose(parent.diagnostics, Code::numerical_range, parent.definition_index, error.what());
        } catch (const std::overflow_error& error) {
            diagnose(parent.diagnostics, Code::numerical_range, parent.definition_index, error.what());
        }
        if (registered.identifier_bytes == "Earth" && !lookups.earth) lookups.earth = index;
        if (registered.identifier_bytes == "Pluto" && !lookups.pluto) lookups.pluto = index;
        result.planets.push_back(std::move(parent));
    }
    const bool names_complete = registration->planet_identifiers_complete && registration->satellite_identifiers_complete;
    if (!names_complete)
        diagnose(result.diagnostics, Code::unresolved_special_lookup, {}, "incomplete registered identifiers prevent first-name pair lookup");
    for (const auto index : registration->satellite_record_indices) {
        const auto& record = model.records()[index];
        if (record.identifier_bytes == "Moon" && !lookups.moon) lookups.moon = index;
        if (record.identifier_bytes == "Charon" && !lookups.charon) lookups.charon = index;
    }
    const bool valid_moon = context.moon && context.moon->legacy_julian_date == jd &&
        finite(context.moon->geocentric_j2000_ecliptic_km) && !context.moon->evidence.empty();
    if (context.moon && !valid_moon)
        diagnose(result.diagnostics, Code::invalid_moon, {}, "Moon input needs the same date, finite ecliptic km and evidence");
    for (std::size_t i = 0; i < model.records().size(); ++i) {
        const auto& record = model.records()[i];
        auto& position = result.positions[i];
        const auto& definition = model.dataset().definitions[record.definition_index];
        if (definition.id.source_key != context.source_key) {
            diagnose(position.diagnostics, Code::unselected_source, record.definition_index, "record belongs to another source");
            continue;
        }
        if (record.registered != true) {
            diagnose(position.diagnostics, Code::unresolved_registration, record.definition_index, "satellite did not register in the selected context");
            continue;
        }
        std::optional<Vec3> parent, relative;
        if (record.identifier_bytes == "Moon") {
            if (names_complete && lookups.earth && valid_moon) {
                parent = result.planets[*lookups.earth].uncorrected_position_au;
                relative = context.moon->geocentric_j2000_ecliptic_km;
            } else {
                diagnose(position.diagnostics, Code::unavailable_moon, record.definition_index,
                    "Moon requires a resolved first Earth and explicit same-date analytic position");
                continue;
            }
        } else {
            const auto found = record.parent_definition_index
                ? lookups.parent_by_definition.find(*record.parent_definition_index) : lookups.parent_by_definition.end();
            if (found != lookups.parent_by_definition.end()) parent = result.planets[found->second].uncorrected_position_au;
            relative = result.relative.positions[i].relative_position_km;
        }
        if (!parent) {
            diagnose(position.diagnostics, Code::unresolved_parent, record.definition_index, "uncorrected CF96 parent is unavailable");
            continue;
        }
        if (!relative) {
            diagnose(position.diagnostics, Code::unavailable_relative_position, record.definition_index, "see preserved relative-evaluation diagnostics");
            continue;
        }
        const auto point = add(*parent, scaled(*relative, 1 / satellite_km_per_au));
        if (finite(point)) position.position_au = point;
        else diagnose(position.diagnostics, Code::numerical_range, record.definition_index, "absolute position overflow");
    }
    if (names_complete) {
        correct_pair(result, lookups.earth, lookups.moon, legacy_earth_moon_mass_fraction);
        correct_pair(result, lookups.pluto, lookups.charon, legacy_pluto_charon_mass_fraction);
    } else {
        // 未解決名が先に登録されている可能性があるため、補正済み中心として公開しない。
        for (auto& parent : result.planets) {
            if (parent.identifier_bytes != "Earth" && parent.identifier_bytes != "Pluto" && !parent.identifier_bytes.empty()) continue;
            parent.position_au.reset();
            diagnose(parent.diagnostics, Code::unresolved_special_lookup,
                     parent.definition_index, "pair-corrected center is unresolved");
        }
        for (const auto index : {lookups.moon, lookups.charon}) {
            if (!index) continue;
            auto& satellite = result.positions[*index];
            satellite.position_au.reset();
            diagnose(satellite.diagnostics, Code::unresolved_special_lookup,
                     satellite.definition_index, "pair-corrected satellite position is unresolved");
        }
    }
    return result;
}
} // namespace mitaka
