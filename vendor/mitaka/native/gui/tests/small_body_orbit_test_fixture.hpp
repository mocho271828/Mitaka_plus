#pragma once

#include "small_body_orbit_model.hpp"

namespace orbit_test {
using namespace mitaka;
using namespace mitaka::gui;
inline constexpr SmallBodyOrbitSampling sampling{2451535, 2451555, 5};

inline std::shared_ptr<SmallBodyDataset> dataset(std::size_t count) {
    auto data = std::make_shared<SmallBodyDataset>();
    data->sources = {{"local-comets.dat", "unused/local-comets.dat", "original local bytes", count, true}};
    for (std::size_t index = 0; index < count; ++index) {
        SmallBodyRecord record;
        record.id = {data->sources.front().key, index};
        record.kind = SmallBodyKind::comet;
        record.encoding = SmallBodyEncoding::comet_fixed_width;
        record.name_bytes = "Duplicate local name";
        record.raw_record_bytes = "unchanged row " + std::to_string(index);
        record.frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
        record.time_scale = SmallBodyTimeScale::tdb;
        record.orbit = PerihelionElements{1 + 0.01 * index, 0.5, 2451545, 0, 0, 0};
        data->records.push_back(std::move(record));
    }
    return data;
}
inline std::shared_ptr<SmallBodyDisplayModel> display(std::shared_ptr<const SmallBodyDataset> data) {
    auto value = std::make_shared<SmallBodyDisplayModel>(std::move(data));
    value->set_kind_options(SmallBodyKind::comet, {true, false, true, false});
    return value;
}
}
