#include "mitaka/small_body_orbit_path.hpp"

#include <cmath>
#include <stdexcept>

namespace mitaka {

namespace {
std::vector<double> sample_dates(SmallBodyOrbitSampling sampling) {
    const double span = sampling.last_jd - sampling.first_jd;
    if (!std::isfinite(sampling.first_jd) || !std::isfinite(sampling.last_jd)
        || !std::isfinite(span) || span <= 0
        || sampling.sample_count < 2 || sampling.sample_count > maximum_small_body_orbit_samples)
        throw std::invalid_argument("invalid small-body orbit sampling request");

    std::vector<double> dates;
    dates.reserve(sampling.sample_count);
    // 先に全時刻を検証し、丸めで失われる標本を暗黙に重複させない。
    for (std::size_t index = 0; index < sampling.sample_count; ++index) {
        const double date = index == sampling.sample_count - 1 ? sampling.last_jd
            : sampling.first_jd + span * (static_cast<double>(index) / (sampling.sample_count - 1));
        if (!std::isfinite(date) || (index > 0 && date <= dates.back()))
            throw std::invalid_argument("small-body orbit sample times are not distinguishable");
        dates.push_back(date);
    }
    return dates;
}
} // namespace

void validate_small_body_orbit_sampling(SmallBodyOrbitSampling sampling) { (void)sample_dates(sampling); }

SmallBodyOrbitPath sample_small_body_orbit_path(const SmallBodyRecord& record,
                                              SmallBodyOrbitSampling sampling) {
    const auto dates = sample_dates(sampling);
    SmallBodyOrbitPath path{record.id, {}};
    path.samples.reserve(dates.size());
    for (double date : dates) path.samples.push_back({date, evaluate_small_body(record, date)});
    return path;
}

std::vector<std::array<std::size_t, 2>> small_body_orbit_segments(const SmallBodyOrbitPath& path) {
    std::vector<std::array<std::size_t, 2>> result;
    if (path.samples.empty()) return result;
    result.reserve(path.samples.size() - 1);
    for (std::size_t index = 1; index < path.samples.size(); ++index)
        if (path.samples[index - 1].evaluation.state && path.samples[index].evaluation.state)
            result.push_back({index - 1, index});
    return result;
}

} // namespace mitaka
