#include "satellite_orbit_geometry.hpp"
#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr std::size_t segments = 256;
constexpr double tau = 6.283185307179586476925286766559;
bool finite(Vec3 p) { return std::isfinite(p.x) && std::isfinite(p.y) && std::isfinite(p.z); }
bool near(Vec3 a, Vec3 b) {
    return finite(a) && finite(b) && std::hypot(std::hypot(a.x-b.x,a.y-b.y),a.z-b.z) < 1e-10;
}
SatelliteOrbitRow orbit(const SatelliteSnapshot& snapshot, std::size_t index) {
    const auto& model = snapshot.model->model();
    const auto& record = model.records()[index];
    auto unavailable = [](const char* reason) { return SatelliteOrbitRow{{},reason}; };
    if (record.identifier_bytes == "Moon") return unavailable("月の専用解析モデルの軌道線は未対応です。");
    if (!snapshot.positions[index] || !record.position_elements || !record.parent_definition_index)
        return unavailable("位置または楕円軌道要素を評価できないため軌道線を表示しません。");
    const auto& source = model.dataset().definitions[record.definition_index].id.source_key;
    const SatelliteAbsoluteEvaluation* evaluation = nullptr;
    for (const auto& candidate : snapshot.evaluations) if (candidate.context.source_key == source) {
        if (evaluation) return unavailable("同じ出典の位置評価が重複しています。");
        evaluation = &candidate;
    }
    if (!evaluation || evaluation->legacy_julian_date != snapshot.julian_date ||
        evaluation->relative.legacy_julian_date != snapshot.julian_date || !evaluation->registration ||
        evaluation->registration->evidence.empty() || evaluation->context.cf96_binding_evidence.empty() ||
        evaluation->positions.size() != model.records().size() ||
        evaluation->relative.positions.size() != model.records().size())
        return unavailable("同日時・同出典の検証済み位置評価がありません。");
    const auto& absolute = evaluation->positions[index];
    const auto& relative = evaluation->relative.positions[index];
    if (absolute.definition_index != record.definition_index || relative.definition_index != record.definition_index ||
        !absolute.position_au || !relative.relative_position_km || !relative.rotation ||
        !near(*absolute.position_au,*snapshot.positions[index]))
        return unavailable("位置 snapshot と軌道面が一致しません。");
    const auto checked = evaluate_satellite_relative_position(*record.position_elements,
        {snapshot.julian_date,*relative.rotation},snapshot.julian_date);
    if (!checked.relative_position_km || !near(*checked.relative_position_km,*relative.relative_position_km))
        return unavailable("同日時の相対位置・軌道面を再検証できません。");
    const auto parent = std::find_if(evaluation->planets.begin(),evaluation->planets.end(),[&](const auto& p) {
        return p.definition_index == *record.parent_definition_index;
    });
    if (parent == evaluation->planets.end() || !parent->uncorrected_position_au)
        return unavailable("補正前の親位置がありません。");
    double factor = 1;
    if (absolute.pair_correction_applied) {
        if (record.identifier_bytes != "Charon") return unavailable("未対応の重心補正です。");
        factor -= legacy_pluto_charon_mass_fraction;
    }
    const auto origin = *parent->uncorrected_position_au;
    const auto delta = *relative.relative_position_km;
    const double scale = factor / satellite_km_per_au;
    if (!near({origin.x+delta.x*scale,origin.y+delta.y*scale,origin.z+delta.z*scale},*absolute.position_au))
        return unavailable("親位置・重心補正が現在の衛星位置と一致しません。");
    const auto& elements = *record.position_elements;
    const auto& rotation = *relative.rotation;
    const double a = elements.semi_major_axis_km * scale;
    const double b = a * std::sqrt(1-elements.eccentricity*elements.eccentricity);
    SatelliteOrbitRow result;
    result.points_au.reserve(segments+1);
    for (std::size_t point = 0; point < segments; ++point) {
        const double angle = tau * static_cast<double>(point)/segments;
        const double x = a*(std::cos(angle)-elements.eccentricity), y = b*std::sin(angle);
        Vec3 value{origin.x+x*rotation.x_axis.x+y*rotation.y_axis.x,
                   origin.y+x*rotation.x_axis.y+y*rotation.y_axis.y,
                   origin.z+x*rotation.x_axis.z+y*rotation.y_axis.z};
        if (!finite(value)) return unavailable("軌道線の座標が有限範囲を超えました。");
        result.points_au.push_back(value);
    }
    result.points_au.push_back(result.points_au.front());
    return result;
}
}
std::shared_ptr<const SatelliteOrbitGeometry> satellite_orbit_geometry(std::shared_ptr<const SatelliteSnapshot> snapshot) {
    if (!snapshot || !snapshot->model || !std::isfinite(snapshot->julian_date) ||
        snapshot->positions.size() != snapshot->model->model().records().size())
        throw std::invalid_argument("satellite orbit snapshot does not match its dataset");
    auto result = std::make_shared<SatelliteOrbitGeometry>();
    result->snapshot = std::move(snapshot);
    for (std::size_t row = 0; row < result->snapshot->positions.size(); ++row)
        result->rows.push_back(orbit(*result->snapshot,row));
    return result;
}
} // namespace mitaka::gui
