#include "small_body_orbit_model.hpp"

#include <algorithm>
#include <stdexcept>
#include <utility>

namespace mitaka::gui {

std::vector<std::size_t> small_body_orbit_requested_rows(
    const SmallBodyModel& model, const SmallBodyDisplayModel& display,
    SmallBodyOrbitSampling sampling) {
    if (&model.dataset() != display.dataset().get())
        throw std::invalid_argument("small-body orbit display/model dataset mismatch");
    validate_small_body_orbit_sampling(sampling);
    std::vector<std::size_t> rows;
    for (std::size_t row = 0; row < model.dataset().records.size(); ++row)
        if (display.visibility(row).orbit) rows.push_back(row);
    // 乗算の overflow を避け、原本行の切り詰めで上限を隠さない。
    if (rows.size() > maximum_small_body_orbit_total_samples / sampling.sample_count)
        throw std::length_error("small-body orbit request exceeds total sample limit 524288: "
            + std::to_string(rows.size()) + " requested rows x "
            + std::to_string(sampling.sample_count)
            + " samples; reduce requested rows or sample count");
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
    for (const auto row : rows) {
        if (cancelled && cancelled()) { result->cancelled = true; return result; }
        auto path = sample_small_body_orbit_path(result->model->dataset().records[row], sampling);
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
