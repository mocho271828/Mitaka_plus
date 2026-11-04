#include "landscape_geometry.hpp"

#include <cmath>
#include <stdexcept>
#include <utility>

namespace mitaka::gui {

LandscapeImageMesh::LandscapeImageMesh(PlaceLandscape definition) : definition_(std::move(definition)) {
    const auto scale = definition_.vertical_scale;
    const auto vertical_offset = definition_.offset_arguments[0];
    const auto horizontal_degrees = definition_.offset_arguments[1];
    if (!std::isfinite(scale) || scale <= 0 || !std::isfinite(vertical_offset) ||
        !std::isfinite(horizontal_degrees)) {
        throw std::invalid_argument("landscape scale and offsets must be finite, with positive scale");
    }
    constexpr double pi = 3.141592653589793238462643383279502884;
    // 巨大な有限度数を radian へ変換する前に周期へ戻し、overflow を避ける。
    const auto rotation = std::remainder(horizontal_degrees, 360.0) * pi / 180.0;
    const auto cosine = std::cos(rotation);
    const auto sine = std::sin(rotation);
    for (std::size_t row = 0; row < rows; ++row) {
        const auto polar = pi * static_cast<double>(row) / static_cast<double>(rows - 1);
        const auto v = 0.5 + (static_cast<double>(row) / static_cast<double>(rows - 1) - 0.5) /
                                 scale - vertical_offset;
        if (!std::isfinite(v)) throw std::invalid_argument("landscape UV coordinate is not finite");
        for (std::size_t column = 0; column < columns; ++column) {
            const auto fraction = static_cast<double>(column) / static_cast<double>(columns - 1);
            const auto azimuth = 2.0 * pi * fraction;
            const auto x = std::cos(azimuth) * std::sin(polar);
            const auto y = std::sin(azimuth) * std::sin(polar);
            vertices_[row * columns + column] = {
                {cosine * x - sine * y, sine * x + cosine * y, -std::cos(polar)},
                {1.0 - fraction, v}};
        }
    }
    for (std::size_t row = 0; row + 1 < rows; ++row) {
        for (std::size_t column = 0; column + 1 < columns; ++column) {
            const auto current = static_cast<std::uint32_t>(row * columns + column);
            constexpr auto stride = static_cast<std::uint32_t>(columns);
            // glBegin(GL_QUADS) の頂点送出順を保存し、極の縮退も削除しない。
            quads_[row * (columns - 1) + column] = {
                current + stride, current + stride + 1, current + 1, current};
        }
    }
}

} // namespace mitaka::gui
