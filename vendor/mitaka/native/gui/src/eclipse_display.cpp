#include "eclipse_display.hpp"
#include "satellite_scene.hpp"
#include "surface_navigation.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr double au_km = 149597870.7;
bool finite(Vec3 a) { return std::isfinite(a.x)&&std::isfinite(a.y)&&std::isfinite(a.z); }
bool same_position(Vec3 a, Vec3 b) {
    if (!finite(a)||!finite(b)) return false;
    const double tolerance=128*std::numeric_limits<double>::epsilon()*
        std::max({1.0,std::hypot(a.x,a.y,a.z),std::hypot(b.x,b.y,b.z)});
    return std::hypot(a.x-b.x,a.y-b.y,a.z-b.z)<=tolerance;
}
EclipseSphere sphere(const SolarBodies& bodies, std::size_t index) {
    return {j2000_equatorial_to_ecliptic(bodies[index].position_au),
        (index==0 ? 696000.0 : surface_body_info(index).radius_km)/au_km};
}
// 親補正に使った同じ出典を、丸め誤差だけを許して照合する。
// 未解決の親を他の出典で補うことはしない。
bool matches_display(const SolarBodies& bodies, const SatelliteSnapshot& snapshot,
    const SatelliteAbsoluteEvaluation& evaluation, const SatelliteRegistrationContext& context) {
    constexpr std::array<std::size_t,9> indices{1,2,3,4,5,6,7,8,9};
    for (std::size_t i=0;i<indices.size();++i)
        if (evaluation.planets[i].position_au && !same_position(*evaluation.planets[i].position_au,
                j2000_equatorial_to_ecliptic(bodies[indices[i]].position_au))) return false;
    if (!evaluation.planets[4].position_au || !context.satellite_identifiers_complete) return false;
    for (const auto row : context.satellite_record_indices) {
        if (row>=snapshot.model->model().records().size()) return false;
        const auto& record=snapshot.model->model().records()[row];
        if (record.identifier_bytes!="Moon") continue;
        const auto& position=evaluation.positions[row];
        if (position.definition_index!=record.definition_index) return false;
        if (position.position_au && !same_position(*position.position_au,
                j2000_equatorial_to_ecliptic(bodies[10].position_au))) return false;
        break;
    }
    return true;
}
std::vector<EclipseSphere> jupiter_casters(const SolarBodies& bodies, double jd,
    const SatelliteSnapshot* snapshot, std::vector<std::string>& diagnostics) {
    if (!snapshot) return {};
    if (snapshot->julian_date!=jd) {
        diagnostics.push_back("eclipse satellite snapshot Julian date does not match the scene"); return {};
    }
    for (const auto& evaluation : snapshot->evaluations) {
        const auto* context=verified_satellite_scene_context(*snapshot,evaluation);
        if (!context || !matches_display(bodies,*snapshot,evaluation,*context)) continue;
        const auto& model=snapshot->model->model();
        std::vector<EclipseSphere> result;
        // 原版 Plus の識別子をそのまま使う。Calliso を Callisto へ補正しない。
        for (const auto* identifier : {"Io","Europa","Ganymede","Calliso"}) {
            bool found=false;
            for (const auto row : context->satellite_record_indices) {
                const auto& record=model.records()[row];
                if (record.identifier_bytes!=identifier) continue;
                found=true;
                const auto& position=evaluation.positions[row];
                if (record.parent_definition_index!=evaluation.planets[4].definition_index ||
                    record.definition_index>=model.dataset().definitions.size() ||
                    position.definition_index!=record.definition_index || !position.position_au ||
                    !snapshot->positions[row] || !same_position(*position.position_au,*snapshot->positions[row])) {
                    diagnostics.push_back(std::string("eclipse satellite position or parent is unresolved: ")+identifier);
                    break;
                }
                const auto& definition=model.dataset().definitions[record.definition_index];
                const auto* radius=unique_satellite_field(definition.fields,"Radius");
                if (!radius || !radius->numbers || radius->numbers->empty() ||
                    !std::isfinite(radius->numbers->front()) || radius->numbers->front()<=0) {
                    diagnostics.push_back(std::string("eclipse satellite physical Radius is unresolved: ")+identifier);
                    break;
                }
                result.push_back({*position.position_au,radius->numbers->front()/au_km});
                break; // 原版の先頭登録一致。後続同名で欠損を補完しない。
            }
            if (!found) diagnostics.push_back(std::string("eclipse satellite identifier is absent: ")+identifier);
        }
        return result;
    }
    diagnostics.push_back("eclipse satellite source or displayed parent positions are not verified");
    return {};
}
} // namespace

EclipseDisplayFrame make_eclipse_display_frame(const SolarBodies& bodies, double jd,
    const SatelliteSnapshot* satellites, EclipseDisplayOptions options) {
    if (!std::isfinite(jd)) throw std::invalid_argument("eclipse scene Julian date must be finite");
    EclipseDisplayFrame frame;
    if (!options.shadows&&!options.shadow_borders&&!options.shadow_umbra&&!options.shadow_penumbra) return frame;
    const auto sun=sphere(bodies,0);
    const auto bind=[&](std::size_t receiver, std::vector<EclipseSphere> casters, std::array<double,3> colour) {
        if (casters.empty()) return;
        try { frame.surfaces[receiver].emplace(sun,sphere(bodies,receiver),std::move(casters),options,colour); }
        catch (const std::invalid_argument& error) { frame.diagnostics.push_back(error.what()); }
        catch (const std::out_of_range& error) { frame.diagnostics.push_back(error.what()); }
    };
    // 地球・月は native の既存物理半径。視認性用の表示倍率は幾何へ混ぜない。
    if (options.shadows || options.shadow_borders) {
        bind(3,{sphere(bodies,10)},{0,0,0});
        bind(10,{sphere(bodies,3)},{.3,0,0});
        bind(5,jupiter_casters(bodies,jd,satellites,frame.diagnostics),{0,0,0});
    }
    if (options.shadow_umbra||options.shadow_penumbra) {
        const EclipseGeometry geometry{sun,sphere(bodies,10),sphere(bodies,3)};
        try {
            (void)eclipse_occluder_cones(geometry.sun,geometry.occluder);
            frame.earth_moon_space=geometry;
        } catch (const std::invalid_argument& error) { frame.diagnostics.push_back(error.what()); }
          catch (const std::out_of_range& error) { frame.diagnostics.push_back(error.what()); }
    }
    return frame;
}
} // namespace mitaka::gui
