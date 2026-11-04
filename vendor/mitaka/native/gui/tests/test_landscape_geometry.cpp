#include "landscape_geometry.hpp"

#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <type_traits>
#include <utility>

namespace {
using mitaka::gui::LandscapeImageMesh;
std::size_t checks = 0;

void require(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}

void near(double actual, double expected, const char* message) {
    require(std::abs(actual - expected) < 1e-12, message);
}

mitaka::PlaceLandscape definition(double scale = 1, double vertical = 0, double horizontal = 0) {
    return {"Planet.Earth", "Local", "unopened-image.png", scale, {vertical, horizontal}};
}

void position(const LandscapeImageMesh& mesh, std::size_t row, std::size_t column, std::array<double, 3> expected) {
    const auto& actual = mesh.vertices()[row * LandscapeImageMesh::columns + column].position;
    for (std::size_t axis = 0; axis < 3; ++axis) near(actual[axis], expected[axis], "known cardinal position");
}

void test_original_geometry() {
    const LandscapeImageMesh mesh(definition());
    require(mesh.vertices().size() == 1387 && mesh.quads().size() == 1296, "original 73 by 19 grid and 72 by 18 quads");
    position(mesh, 0, 0, {0, 0, -1});
    position(mesh, 18, 0, {0, 0, 1});
    position(mesh, 9, 0, {1, 0, 0});
    position(mesh, 9, 18, {0, 1, 0});
    position(mesh, 9, 36, {-1, 0, 0});
    position(mesh, 9, 54, {0, -1, 0});
    require(mesh.quads().front() == LandscapeImageMesh::Quad{73, 74, 1, 0} &&
            mesh.quads().back() == LandscapeImageMesh::Quad{1385, 1386, 1313, 1312},
            "original quad winding and pole degeneracies retained");
    for (std::size_t row = 0; row < LandscapeImageMesh::rows; ++row) {
        const auto& first = mesh.vertices()[row * LandscapeImageMesh::columns];
        const auto& last = mesh.vertices()[(row + 1) * LandscapeImageMesh::columns - 1];
        near(first.uv[0], 1, "left seam U is one");
        near(last.uv[0], 0, "right seam U is zero");
        for (std::size_t axis = 0; axis < 3; ++axis) near(first.position[axis], last.position[axis], "seam positions coincide");
    }
    for (const auto& vertex : mesh.vertices()) {
        near(vertex.position[0] * vertex.position[0] + vertex.position[1] * vertex.position[1] +
             vertex.position[2] * vertex.position[2], 1, "all vertices on unit sphere");
    }
    for (const auto& quad : mesh.quads()) {
        for (const auto index : quad) require(index < mesh.vertices().size(), "all quad indices within vertex array");
        require(quad[0] == quad[3] + 73 && quad[1] == quad[2] + 73 && quad[2] == quad[3] + 1,
                "each quad keeps original next-row then current-row order");
    }
}

void test_offsets_and_immutability() {
    auto input = definition(0.25, 0.125, 90);
    const LandscapeImageMesh mesh(input);
    position(mesh, 9, 0, {0, 1, 0});
    position(mesh, 9, 18, {-1, 0, 0});
    near(mesh.vertices().front().uv[1], -1.625, "fifth argument is vertical UV offset and remains below zero");
    near(mesh.vertices().back().uv[1], 2.375, "upper UV remains above one for CLAMP_TO_EDGE sampler");
    near(mesh.vertices()[9 * 73].uv[1], 0.375, "equatorial UV offset");
    input.offset_arguments = {9, 9};
    require(mesh.definition().offset_arguments == std::array<double, 2>{0.125, 90}, "source argument order copied independently");
    const LandscapeImageMesh periodic(definition(1, 0, -270));
    position(periodic, 9, 0, {0, 1, 0});
    const LandscapeImageMesh huge(definition(1, 0, std::numeric_limits<double>::max()));
    for (const auto& vertex : huge.vertices()) {
        for (const auto component : vertex.position) require(std::isfinite(component), "large finite rotation never overflows");
    }
}

void test_rejection() {
    const auto nan = std::numeric_limits<double>::quiet_NaN();
    const auto inf = std::numeric_limits<double>::infinity();
    for (const auto& input : {definition(0), definition(-1), definition(nan), definition(inf),
                             definition(1, nan), definition(1, inf), definition(1, 0, nan), definition(1, 0, inf),
                             definition(std::numeric_limits<double>::denorm_min())}) {
        bool rejected = false;
        try { const LandscapeImageMesh invalid(input); }
        catch (const std::invalid_argument&) { rejected = true; }
        require(rejected, "invalid geometry rejects without exposing partial mesh");
    }
}
} // namespace

static_assert(std::is_same_v<decltype(std::declval<LandscapeImageMesh&>().vertices()), const LandscapeImageMesh::Vertices&>);
static_assert(std::is_same_v<decltype(std::declval<LandscapeImageMesh&>().quads()), const LandscapeImageMesh::Quads&>);

int main() {
    try {
        test_original_geometry();
        test_offsets_and_immutability();
        test_rejection();
        std::cout << "Landscape geometry checks passed: " << checks << '\n';
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
