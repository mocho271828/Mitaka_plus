#include "mitaka/our_galaxy_model.hpp"
#include "galaxy_catalog_input.hpp"

#include <cmath>

namespace mitaka {

OurGalaxyModel load_our_galaxy_model(const std::filesystem::path& path, CatalogLoadLimits limits) {
    OurGalaxyModel result{load_galaxy_catalog_source(path, limits), {}, {}};
    galaxy_detail::Input input(result.source, limits);
    std::size_t total_samples = 0;
    for (auto& map : result.maps) {
        map.width = input.i32();
        map.height = input.i32();
        if (map.width <= 0 || map.height <= 0) input.fail("nonpositive galaxy map dimensions");
        const auto count64 = std::uint64_t(map.width) * std::uint64_t(map.height);
        if (count64 > limits.max_records - total_samples)
            input.fail("galaxy maps exceed sample limit");
        const auto count = static_cast<std::size_t>(count64);
        // allocation の前に残り bytes を確認し、巨大 dimensions を早期拒否する。
        if (count > input.remaining() / 4) input.fail("truncated galaxy map samples");
        total_samples += count;
        map.values.reserve(count);
        for (std::size_t i = 0; i < count; ++i) {
            const float value = input.f32();
            map.values.push_back(value);
            if (!std::isfinite(value)) ++map.nonfinite_count;
            else if (value < 0 || value > 1) ++map.outside_unit_interval_count;
        }
    }
    std::size_t total_points = 0;
    for (auto& group : result.groups) {
        const auto signed_count = input.i32();
        if (signed_count < 0) input.fail("negative galaxy point count");
        const auto count = static_cast<std::size_t>(signed_count);
        if (count > limits.max_records - total_points) input.fail("galaxy clouds exceed point limit");
        if (count > input.remaining() / 12) input.fail("truncated galaxy point cloud");
        total_points += count;
        group.positions.reserve(count);
        for (std::size_t i = 0; i < count; ++i) {
            const OurGalaxyRawPositionPc position{input.f32(), input.f32(), input.f32()};
            group.positions.push_back(position);
            if (!std::isfinite(position.x_pc) || !std::isfinite(position.y_pc) ||
                !std::isfinite(position.z_pc)) ++group.nonfinite_count;
        }
    }
    if (input.remaining() != 0) input.fail("trailing bytes in galaxy model");
    return result;
}

} // namespace mitaka
