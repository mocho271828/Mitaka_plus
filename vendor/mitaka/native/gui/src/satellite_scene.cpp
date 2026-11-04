#include "satellite_scene.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
struct ParentBinding { const char* identifier; Body body; };
constexpr std::array<ParentBinding, 9> bindings{{
    {"Mercury",Body::mercury}, {"Venus",Body::venus}, {"Earth",Body::earth},
    {"Mars",Body::mars}, {"Jupiter",Body::jupiter}, {"Saturn",Body::saturn},
    {"Uranus",Body::uranus}, {"Neptune",Body::neptune}, {"Pluto",Body::pluto}}};

} // namespace

const SatelliteRegistrationContext* verified_satellite_scene_context(const SatelliteSnapshot& snapshot,
                                                     const SatelliteAbsoluteEvaluation& evaluation) {
    if (!snapshot.model || !std::isfinite(snapshot.julian_date) ||
        evaluation.legacy_julian_date != snapshot.julian_date || !evaluation.registration ||
        evaluation.registration->evidence.empty() || evaluation.context.cf96_binding_evidence.empty() ||
        evaluation.planets.size() != bindings.size()) return nullptr;
    const auto& model = snapshot.model->model();
    if (evaluation.positions.size() != model.records().size() ||
        snapshot.positions.size() != model.records().size()) return nullptr;
    const auto& contexts = model.registration_contexts();
    const auto found = std::find_if(contexts.begin(), contexts.end(), [&](const auto& context) {
        return context.source_key == evaluation.context.source_key;
    });
    if (found == contexts.end() || !found->planet_identifiers_complete ||
        found->planets.size() != bindings.size() || found->origin != evaluation.registration->origin ||
        found->evidence != evaluation.registration->evidence) return nullptr;
    for (std::size_t i = 0; i < bindings.size(); ++i) {
        const auto& parent = evaluation.planets[i];
        const auto& registered = found->planets[i];
        if (parent.identifier_bytes != bindings[i].identifier || parent.registration_index.value != i ||
            registered.identifier_bytes != bindings[i].identifier || registered.registration_index.value != i ||
            parent.definition_index != registered.definition_index) return nullptr;
    }
    return &*found;
}

namespace {
void replace(SolarBodies& bodies, Body id, const std::optional<Vec3>& position) {
    if (!position || !std::isfinite(position->x) || !std::isfinite(position->y) || !std::isfinite(position->z)) return;
    Vec3 equatorial;
    try { equatorial = j2000_ecliptic_to_equatorial(*position); }
    catch (const std::out_of_range&) { return; }
    const auto found = std::find_if(bodies.begin(), bodies.end(), [=](const auto& body) { return body.id == id; });
    if (found != bodies.end()) found->position_au = equatorial;
}
} // namespace

SolarBodies apply_satellite_parent_positions(SolarBodies bodies, const SatelliteSnapshot& snapshot,
                                             const std::optional<std::string>& source) {
    for (const auto& evaluation : snapshot.evaluations) {
        if (source && *source != evaluation.context.source_key) continue;
        const auto* registration = verified_satellite_scene_context(snapshot, evaluation);
        if (!registration) continue;
        for (std::size_t i = 0; i < bindings.size(); ++i)
            replace(bodies, bindings[i].body, evaluation.planets[i].position_au);
        if (registration->satellite_identifiers_complete) {
            for (const auto index : registration->satellite_record_indices) {
                const auto& record = snapshot.model->model().records()[index];
                if (record.identifier_bytes != "Moon") continue;
                const auto& moon = evaluation.positions[index];
                if (moon.definition_index == record.definition_index) replace(bodies, Body::moon, moon.position_au);
                break;
            }
        }
        // 別出典の解決済み値で、選択出典の欠損を暗黙に埋めない。
        break;
    }
    return bodies;
}
} // namespace mitaka::gui
