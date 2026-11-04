#pragma once

#include "mitaka/place_catalog.hpp"

#include <array>
#include <cstdint>

namespace mitaka::gui {

struct LandscapeVertex {
    // 原版の風景描画関数内の単位球 XYZ。地平方位 / ワールド座標ではない。
    std::array<double, 3> position;
    // 原版の OpenGL texture coordinates。画像ピクセルの上下には変換しない。
    std::array<double, 2> uv;
};

class LandscapeImageMesh {
public:
    static constexpr std::size_t columns = 73;
    static constexpr std::size_t rows = 19;
    using Vertices = std::array<LandscapeVertex, columns * rows>;
    using Quad = std::array<std::uint32_t, 4>;
    using Quads = std::array<Quad, (columns - 1) * (rows - 1)>;

    // 旧 Plus 画像あり分岐の二倍極角球。画像なしの黒い半球とは異なる。
    // θ = 5°row, φ = 5°column, P = (cosφ sin2θ, sinφ sin2θ, -cos2θ)。
    // 原第5引数は vertical UV offset、第6引数は右手系 Z 回転角（度）。
    // UV = (1-column/72, .5+(row/18-.5)/scale-offset[0])。
    // UV を切り詰めない。描画側には S/T とも CLAMP_TO_EDGE が必要。
    // 元の seam / pole / quad 順を保つ。倍精度演算であり旧 float と bit 一致はしない。
    // 非有限入力、scale <= 0、非有限 UV は invalid_argument。I/O は行わない。
    explicit LandscapeImageMesh(PlaceLandscape definition);

    const PlaceLandscape& definition() const noexcept { return definition_; }
    const Vertices& vertices() const noexcept { return vertices_; }
    const Quads& quads() const noexcept { return quads_; }

private:
    PlaceLandscape definition_;
    Vertices vertices_{};
    Quads quads_{};
};

} // namespace mitaka::gui
