#include "small_body_orbit_model.hpp"

#include <algorithm>
#include <stdexcept>
#include <utility>

namespace mitaka::gui {
namespace {
bool is_minor_planet_packed36(const SmallBodyRecord& record) {
    return record.kind != SmallBodyKind::comet && record.encoding == SmallBodyEncoding::packed_36;
}
bool is_unresolved_non_comet(const SmallBodyRecord& record) {
    return record.kind != SmallBodyKind::comet
        && (record.frame != SmallBodyFrame::heliocentric_j2000_ecliptic
            || record.time_scale != SmallBodyTimeScale::tdb
            || std::holds_alternative<std::monostate>(record.orbit));
}
}

std::vector<std::size_t> small_body_orbit_requested_rows(
    const SmallBodyModel& model, const SmallBodyDisplayModel& display,
    SmallBodyOrbitSampling sampling) {
    if (&model.dataset() != display.dataset().get())
        throw std::invalid_argument("small-body orbit display/model dataset mismatch");
    validate_small_body_orbit_sampling(sampling);
    std::vector<std::size_t> rows;
    std::size_t minor_samples = 0, other_samples = 0;
    for (std::size_t row = 0; row < model.dataset().records.size(); ++row)
        if (display.visibility(row).orbit) {
            rows.push_back(row);
            const auto& record = model.dataset().records[row];
            const bool minor = is_minor_planet_packed36(record);
            auto& total = minor ? minor_samples : other_samples;
            const auto limit = minor ? maximum_minor_planet_orbit_total_samples
                                     : maximum_small_body_orbit_total_samples;
            // 未対応の小天体は診断のため両端だけ評価する。全標本を複製しても軌道は得られない。
            const auto count = !minor && is_unresolved_non_comet(record) ? 2 : sampling.sample_count;
            if (count > limit - total)
                throw std::length_error("small-body orbit request exceeds total sample limit "
                    + std::to_string(limit) + "; reduce requested rows or sample count");
            total += count;
        }
    return rows;
}

std::shared_ptr<const SmallBodyOrbitSnapshot> evaluate_small_body_orbit_snapshot(
    std::shared_ptr<const SmallBodyModel> model,
    std::shared_ptr<const SmallBodyDisplayModel> display,
    SmallBodyOrbitSampling sampling, std::function<bool()> cancelled) {
    if (!model || !display)
        throw std::invalid_argument("small-body orbit model/display is null");
    const auto rows = small_body_orbit_requested_rows(*model, *display, sampling);
    auto result = std::make_shared<SmallBodyOrbitSnapshot>();
    result->model = std::move(model);
    result->display = std::move(display);
    result->sampling = sampling;
    result->requested_count = rows.size();
    result->paths.resize(result->model->dataset().records.size());
    result->minor_planet_paths.resize(result->paths.size());
    for (const auto row : rows) {
        if (cancelled && cancelled()) { result->cancelled = true; return result; }
        const auto& record = result->model->dataset().records[row];
        if (is_minor_planet_packed36(record)) {
            auto path = sample_minor_planet_orbit_path(record, sampling.sample_count, cancelled);
            if (path.cancelled) { result->cancelled = true; return result; }
            if (std::any_of(path.samples.begin(), path.samples.end(), [](const auto& sample) {
                    return !sample.position;
                }) || path.samples.empty()) ++result->unresolved_count;
            result->minor_planet_paths[row] = std::move(path);
            ++result->completed_count;
            continue;
        }
        auto actual_sampling = sampling;
        if (is_unresolved_non_comet(record)) actual_sampling.sample_count = 2;
        auto path = sample_small_body_orbit_path(record, actual_sampling);
        if (std::any_of(path.samples.begin(), path.samples.end(), [](const auto& sample) {
                return !sample.evaluation.state;
            })) ++result->unresolved_count;
        result->paths[row] = std::move(path);
        ++result->completed_count;
    }
    // 最後の行の計算中、または空要求で発生した取消も完成結果にしない。
    result->cancelled = cancelled && cancelled();
    return result;
}

} // namespace mitaka::gui
