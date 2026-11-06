#include "mitaka/minor_planet_position.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>
#include <utility>

namespace mitaka {
namespace {
using Code = SmallBodyDiagnosticCode;

void add(MinorPlanetPositionEvaluation& result, Code code, std::string field,
         std::string message) {
    const bool failure = code == Code::invalid_source || code == Code::invalid_time
        || code == Code::calculation_failed || code == Code::outside_time_range;
    const auto found = std::find_if(result.diagnostics.begin(), result.diagnostics.end(),
        [&](const auto& item) {
            if (item.code != code || item.field != field) return false;
            // 失敗の原因は同じ code / field の既存診断があっても消さない。
            return !failure || (item.message == message && item.source_key == result.id.source_key
                && item.record_ordinal == result.id.record_ordinal);
        });
    if (found == result.diagnostics.end())
        result.diagnostics.push_back({code, result.id.source_key, result.id.record_ordinal,
                                      std::move(field), std::move(message)});
}

bool validate_elements(const OrbitalElements& orbit, MinorPlanetPositionEvaluation& result) {
    for (double value : {orbit.epoch_jd, orbit.semi_major_axis_au, orbit.eccentricity,
                        orbit.mean_anomaly_deg, orbit.mean_motion_deg_per_day,
                        orbit.ascending_node_deg, orbit.inclination_deg,
                        orbit.argument_of_periapsis_deg}) {
        if (!std::isfinite(value)) {
            add(result, Code::invalid_source, "orbit", "minor-planet orbital elements must all be finite");
            return false;
        }
    }
    if (orbit.semi_major_axis_au <= 0 || orbit.mean_motion_deg_per_day <= 0 || orbit.eccentricity < 0) {
        add(result, Code::invalid_source, "orbit", "minor-planet orbit requires a > 0, n > 0 and e >= 0");
        return false;
    }
    if (orbit.eccentricity >= 1) {
        add(result, Code::calculation_failed, "eccentricity",
            "minor-planet non-elliptic position contract is not verified; require e < 1");
        return false;
    }
    return true;
}
} // namespace

MinorPlanetPositionEvaluation evaluate_minor_planet_position(const SmallBodyRecord& record,
                                                             double time) {
    MinorPlanetPositionEvaluation result{record.id, time, {}, {}, record.diagnostics,
                                          MinorPlanetPositionStatus::invalid_record};
    if (!std::isfinite(time)) {
        result.status = MinorPlanetPositionStatus::unavailable_at_time;
        add(result, Code::invalid_time, "legacy_julian_date", "requested legacy numeric JD must be finite");
        return result;
    }
    const bool packed = record.encoding == SmallBodyEncoding::packed_36;
    const bool text = record.encoding == SmallBodyEncoding::element_text;
    if (!packed && !text) {
        add(result, Code::invalid_source, "encoding",
            "position contract is verified only for packed_36 and individual element_text; packed_37 remains unresolved");
        return result;
    }
    if (record.kind != SmallBodyKind::asteroid && record.kind != SmallBodyKind::trans_neptunian) {
        add(result, Code::invalid_source, "kind", "minor-planet position contract applies only to asteroids and TNOs");
        return result;
    }
    if ((packed && record.raw_record_bytes.size() != 36)
        || (text && record.raw_record_bytes.empty()) || record.raw_flag) {
        add(result, Code::invalid_source, "raw_record_bytes", "minor-planet record storage is inconsistent");
        return result;
    }
    // 現 parser は a から n を導出する。今回の契約外の明示 n を無視して位置を出さない。
    if (text && std::any_of(record.fields.begin(), record.fields.end(),
                           [](const auto& field) { return field.key == "n"; })) {
        add(result, Code::invalid_source, "n",
            "individual element_text with explicit n is not supported by the a-derived position contract");
        return result;
    }
    const auto* orbit = std::get_if<OrbitalElements>(&record.orbit);
    if (!orbit) {
        add(result, Code::invalid_source, "orbit", "minor-planet record has no mean-anomaly orbital elements");
        return result;
    }
    if (!validate_elements(*orbit, result)) return result;

    if (record.declared_time_range) {
        const auto range = *record.declared_time_range;
        if (!std::isfinite(range.first_jd) || !std::isfinite(range.last_jd) || range.first_jd > range.last_jd) {
            add(result, Code::invalid_time, "declared_time_range", "declared source time range is invalid");
            return result;
        }
        if (time < range.first_jd || time > range.last_jd) {
            result.status = MinorPlanetPositionStatus::unavailable_at_time;
            add(result, Code::outside_time_range, "legacy_julian_date", "requested time is outside the declared source range");
            return result;
        }
    } else {
        add(result, Code::unknown_accuracy_range, "declared_time_range",
            "two-body approximation; source accuracy interval is not declared");
    }

    // raw loader の未確定診断は元 record に残し、この専用契約で解決した面だけを結果から除く。
    result.diagnostics.erase(std::remove_if(result.diagnostics.begin(), result.diagnostics.end(),
        [](const auto& item) { return item.code == Code::unresolved_frame; }), result.diagnostics.end());
    add(result, Code::unresolved_time_scale, "time_scale",
        "requested legacy numeric JD is used unchanged; physical UTC/TT/TDB is not verified");
    result.status = MinorPlanetPositionStatus::unavailable_at_time;
    try {
        result.heliocentric_j2000_ecliptic_au = orbital_state(*orbit, time).position_au;
        result.contract = packed ? minor_planet_packed_position_contract
                                 : minor_planet_element_position_contract;
        result.status = MinorPlanetPositionStatus::success;
    } catch (const std::invalid_argument& error) {
        add(result, Code::calculation_failed, "orbit", error.what());
    } catch (const std::out_of_range& error) {
        add(result, Code::calculation_failed, "orbit", error.what());
    } catch (const std::runtime_error& error) {
        add(result, Code::calculation_failed, "orbit", error.what());
    }
    return result;
}
} // namespace mitaka
