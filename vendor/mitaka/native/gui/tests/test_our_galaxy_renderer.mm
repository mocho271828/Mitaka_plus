#include "OurGalaxyRenderer.h"
#include "OurGalaxyRadiativeRenderer.h"
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
std::size_t checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class F> void rejects(F action) {
    try { action(); } catch (const std::invalid_argument&) { ++checks; return; }
    throw std::runtime_error("expected invalid input rejection");
}
OurGalaxyRenderSettings settings() {
    return {{{{{1, 0, 0}, {0, 0, 1}, {0, 1, 0}}}, {0, 0.3, 0}},
        {{{1, 0, 0, 1, 3}, {0, 1, 0, 1, 3}, {0, 0, 1, 1, 3}, {1, 1, 1, 1, 3}}},
        "fixture transform", "fixture colors"};
}
const GalaxyCameraPc camera{{0, 0, 0}, 0, 0, 10};
std::vector<std::uint8_t> pixels(const GalaxyBitmap& bitmap) {
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(bitmap.image()));
    if (!data) throw std::runtime_error("cannot inspect bitmap pixels");
    std::vector<std::uint8_t> result(CFDataGetBytePtr(data), CFDataGetBytePtr(data) + CFDataGetLength(data));
    CFRelease(data);
    return result;
}
void transform_and_render() {
    OurGalaxyModel model;
    const std::array<OurGalaxyRawPositionPc, 4> positions{{{0, 1, -1}, {0, 1, 1},
                                                           {0, -1, -1}, {0, -1, 1}}};
    for (std::size_t i = 0; i < positions.size(); ++i) model.groups[i].positions.push_back(positions[i]);
    for (int i = 0; i < 1024; ++i) model.groups[0].positions.push_back(positions[0]);
    model.groups[0].positions.push_back({0, std::numeric_limits<float>::quiet_NaN(), 0});
    model.groups[0].positions.push_back({0, 100, 0});
    const auto original = model.groups[0].positions.size();
    const auto bitmap = render_our_galaxy_points(model, settings(), camera, {}, 128, 128, 1);
    check(bitmap && bitmap->counts().total == 1030 && bitmap->counts().drawn == 1028 &&
          bitmap->counts().invalid == 1 && bitmap->counts().outside == 1, "counts across all groups and batches");
    check(model.groups[0].positions.size() == original, "input remains unchanged");
    const auto image = pixels(*bitmap);
    check(image[3] == 0, "background remains transparent");
    const GalaxyProjector projector(camera, 128, 128);
    for (std::size_t i = 0; i < positions.size(); ++i) {
        const auto raw = positions[i];
        const auto projected = projector.project({raw.x_pc, raw.z_pc + 0.3, raw.y_pc});
        check(projected && projector.contains(*projected), "test point projected in view");
        const auto offset = (std::size_t(projected->y) * 128 + std::size_t(projected->x)) * 4;
        for (std::size_t color = 0; color < 3; ++color) {
            const bool on = i == color || i == 3;
            check(on ? image[offset + color] > 200 : image[offset + color] < 10,
                  "transformed position and per-group color reach expected pixel");
        }
        check(image[offset + 3] > 200, "point alpha");
    }
}
void invalid_and_cancel() {
    OurGalaxyModel model;
    auto config = settings();
    config.coordinate_provenance = " \t";
    rejects([&] { (void)render_our_galaxy_points(model, config, camera, {}, 64, 64, 1); });
    config = settings(); config.color_provenance.clear();
    rejects([&] { (void)render_our_galaxy_points(model, config, camera, {}, 64, 64, 1); });
    config = settings(); config.styles[0].red = 1.1;
    rejects([&] { (void)render_our_galaxy_points(model, config, camera, {}, 64, 64, 1); });
    config = settings(); config.styles[0].radius_points = 0;
    rejects([&] { (void)render_our_galaxy_points(model, config, camera, {}, 64, 64, 1); });
    config = settings(); config.transform.matrix[0][0] = std::numeric_limits<double>::infinity();
    rejects([&] { (void)render_our_galaxy_points(model, config, camera, {}, 64, 64, 1); });
    config = settings(); config.transform.matrix[0][0] = 1e100;
    model.groups[0].positions.push_back({1, 0, 0});
    const auto bitmap = render_our_galaxy_points(model, config, camera, {}, 64, 64, 1);
    check(bitmap->counts().invalid == 1, "out-of-range finite transformed position is counted, not thrown");
    check(!render_our_galaxy_points(model, settings(), camera, {}, 64, 64, 1, [] { return true; }),
          "early cancellation returns no bitmap");
    model.groups[0].positions.resize(1000, {0, 0, 0});
    int calls = 0;
    check(!render_our_galaxy_points(model, settings(), camera, {}, 64, 64, 1, [&] { return ++calls >= 3; }),
          "cancellation during rendering discards partial bitmap");
}
void point_absorption() {
    OurGalaxyModel model;
    for (auto& map : model.maps) {
        map.width = 512;
        map.height = 512;
        map.values.assign(512 * 512, 0);
    }
    model.groups[3].positions.push_back({0, 0, 0});
    OurGalaxyRadiativeModel radiative(model);
    const GalaxyCameraPc viewpoint{{0, 0, 0}, 0, 0, 10000};
    const auto config = settings();
    const auto extinction = radiative.point_extinction(our_galaxy_camera_origin(viewpoint),
                                                        our_galaxy_galactic_position({0, 0.3, 0}));
    const auto bitmap = render_our_galaxy_points(model, config, viewpoint, {}, 128, 128, 1,
                                                 {}, &radiative, 1);
    check(bitmap && bitmap->counts().drawn == 1 && extinction.visible, "absorbed point is drawn");
    const auto projected = GalaxyProjector(viewpoint, 128, 128).project({0, 0.3, 0});
    check(bool(projected), "absorbed point projects");
    const auto image = pixels(*bitmap);
    const auto offset = (std::size_t(projected->y) * 128 + std::size_t(projected->x)) * 4;
    const float expected[] = {extinction.transmittance.r, extinction.transmittance.g, extinction.transmittance.b};
    for (std::size_t channel = 0; channel < 3; ++channel)
        check(std::abs(int(image[offset + channel]) - int(std::lround(255 * expected[channel]))) <= 2,
              "point pixel uses channel-specific extinction");
    const auto faded = render_our_galaxy_points(model, config, viewpoint, {}, 128, 128, 1,
                                                {}, &radiative, 0);
    check(pixels(*faded)[offset + 3] == 0, "zero galaxy alpha hides point");
    rejects([&] { (void)render_our_galaxy_points(model, config, viewpoint, {}, 128, 128, 1,
                                                {}, &radiative, -1); });
}
void point_selection() {
    const auto preview = OurGalaxyPointDisplay::preview;
    const auto complete = OurGalaxyPointDisplay::complete;
    const auto transform = settings().transform;
    const auto nan = std::numeric_limits<float>::quiet_NaN();
    check(our_galaxy_preview_step(0) == 1 && our_galaxy_preview_step(1500) == 1 &&
          our_galaxy_preview_step(1501) == 2 && our_galaxy_preview_step(3001) == 3,
          "preview sampling boundaries");

    OurGalaxyModel model;
    model.groups[0].positions = {{nan, 0, 0}, {0, 0, 0}, {0, 0, 0}};
    model.groups[1].positions = {{0, 0, 0}};
    const OurGalaxyPointId first{OurGalaxyPointGroup::disk1, 1};
    auto pick = pick_our_galaxy_point(model, transform, preview, camera, 128, 128, 64, 64, 1);
    check(pick && pick->id == first, "same-position tie uses group and original ordinal");
    model.groups[1].positions[0] = {1, 0, 0};
    pick = pick_our_galaxy_point(model, transform, preview, camera, 128, 128, 64, 64, 1);
    check(pick && pick->id == OurGalaxyPointId{OurGalaxyPointGroup::disk2, 0},
          "same-position tie prefers smaller depth");
    model.groups[1].positions[0] = {11, 0, 0};
    pick = pick_our_galaxy_point(model, transform, preview, camera, 128, 128, 64, 64, 1);
    check(pick && pick->id == first, "point behind camera is not selectable");
    check(!our_galaxy_point_position(model, {OurGalaxyPointGroup::disk1, 0}, preview, transform) &&
          !our_galaxy_point_position(model, {OurGalaxyPointGroup::disk1, 3}, preview, transform) &&
          !our_galaxy_point_position(model, {static_cast<OurGalaxyPointGroup>(100), 0}, preview, transform),
          "invalid positions, ordinals and groups are rejected");

    OurGalaxyModel sampled;
    sampled.groups[0].positions.resize(1501, {nan, 0, 0});
    sampled.groups[0].positions[1] = {0, 0, 0};
    check(!our_galaxy_point_position(sampled, first, preview, transform) &&
          our_galaxy_point_position(sampled, first, complete, transform),
          "preview skips ordinal while complete retains it");
    check(!pick_our_galaxy_point(sampled, transform, preview, camera, 128, 128, 64, 64, 8),
          "preview cannot pick omitted point");
    for (auto& map : sampled.maps) {
        map.width = 512; map.height = 512; map.values.assign(512 * 512, 0);
    }
    const auto transformed = our_galaxy_point_position(sampled, first, complete, transform);
    const auto projected = GalaxyProjector(camera, 128, 128).project(*transformed);
    check(projected.has_value(), "complete point projects");
    pick = pick_our_galaxy_point(sampled, transform, complete, camera, 128, 128,
                                 projected->x, projected->y, 1);
    check(pick && pick->id == first, "complete selection retains original ordinal");
    OurGalaxyRadiativeModel radiative(sampled);
    check(our_galaxy_point_visible(sampled, first, transform, complete, camera, 128, 128, &radiative) &&
          !our_galaxy_point_visible(sampled, first, transform, complete, camera, 128, 128, nullptr) &&
          !our_galaxy_point_visible(sampled, first, transform, preview, camera, 128, 128, nullptr),
          "visibility follows mode and available radiative model");

    OurGalaxyModel coordinates;
    coordinates.groups[0].positions.push_back({0, 1, -1});
    const OurGalaxyPointId id{OurGalaxyPointGroup::disk1, 0};
    const auto raw = our_galaxy_point_position(coordinates, id, preview, transform);
    const auto converted = our_galaxy_point_position(coordinates, id, complete, transform);
    check(raw && converted && raw->y_pc == 1 && raw->z_pc == -1 &&
          std::abs(converted->y_pc + 0.7) < 1e-9 && converted->z_pc == 1,
          "preview uses raw position and complete uses transformed position");
    check(!pick_our_galaxy_point(model, transform, preview, camera, 128, 128, -1, 64, 8),
          "click outside viewport is ignored");
    rejects([&] { (void)pick_our_galaxy_point(model, transform, preview, camera, 128, 128, nan, 64, 8); });
    rejects([&] { (void)pick_our_galaxy_point(model, transform, preview, camera, 128, 128, 64, 64, -1); });
    rejects([&] { (void)pick_our_galaxy_point(model, transform, static_cast<OurGalaxyPointDisplay>(99),
                                               camera, 128, 128, 64, 64, 8); });
    check(!pick_our_galaxy_point(model, transform, preview, camera, 128, 128, 64, 64, 8,
                                 [] { return true; }), "early cancellation returns no selection");
    sampled.groups[0].positions.assign(1000, {0, 0, 0});
    int calls = 0;
    check(!pick_our_galaxy_point(sampled, transform, preview, camera, 128, 128, 64, 64, 8,
                                 [&] { return ++calls >= 3; }),
          "cancellation while scanning discards candidates");
}
void real_model(const char* path) {
    const auto model = load_our_galaxy_model(path);
    const auto bitmap = render_our_galaxy_points(model, settings(),
        GalaxyCameraPc{{0, 0, 0}, 0, 0, 10000}, {}, 128, 128, 1);
    check(bitmap && bitmap->counts().total == 102000, "all original point groups rendered");
    const auto count = bitmap->counts();
    check(count.invalid + count.outside + count.drawn == count.total, "all points accounted for");
}
}
int main(int argc, char** argv) {
    try { transform_and_render(); invalid_and_cancel(); point_absorption(); point_selection(); if (argc > 1) real_model(argv[1]); }
    catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
    std::cout << "OurGalaxy renderer: " << checks << " checks passed\n";
}
