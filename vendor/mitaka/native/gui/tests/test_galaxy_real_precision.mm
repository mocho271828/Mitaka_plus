#include "GalaxyRenderer.h"
#include "shared_camera.hpp"

#include <cmath>
#include <filesystem>
#include <iostream>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
void require(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
}

void verify_frame(const GalaxySpatialModel& model, GalaxySpatialRecordId id,
                  const SolarCamera& solar, double expected_x, double expected_y) {
    constexpr std::size_t size = 512;
    const auto view = galaxy_camera_from_shared(shared_camera_from_solar(solar));
    const GalaxyProjector projector(view, size, size);
    const auto point = projector.project(*model.row(id).position);
    require(point && projector.contains(*point), "real row is not in the viewport");
    require(std::abs(point->x - expected_x) < 1e-6 && std::abs(point->y - expected_y) < 1e-6,
            "real row did not move by the requested pan distance");
    const auto selected = pick_galaxy_spatial_row(model, projector, {}, point->x, point->y, 3);
    require(selected && *selected == id, "real row pick did not retain its original ID");
    RendererDisplayOptions quality;
    quality.antialias = false;
    const auto bitmap = render_galaxy_bitmap(model, view, {}, quality, size, size, 1,
                                              {}, GalaxyBackground::transparent);
    require(bitmap && bitmap->counts().drawn == 1, "real row was not drawn alone");
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(bitmap->image()));
    require(data != nullptr, "could not read rendered bitmap");
    const auto* bytes = CFDataGetBytePtr(data);
    const auto pixel = (std::size_t(point->y) * size + std::size_t(point->x)) * 4;
    const bool drawn = bytes[pixel + 3] != 0;
    CFRelease(data);
    require(drawn, "real row's projected pixel is transparent");
}

void real_catalog_test(const std::filesystem::path& directory, SdssKind kind) {
    const auto path = directory / (kind == SdssKind::galaxy ? "SDSS_GAL.dat" : "SDSS_QSO.dat");
    auto source = std::make_shared<const SdssSpatialModel>(std::vector<SdssSpatialSource>{
        {kind, path, load_sdss_catalog(path, kind)}});
    auto snapshot = evaluate_sdss_spatial_snapshot(source);
    GalaxySpatialModel model({GalaxySdssSource{snapshot, 0}});
    const auto family = kind == SdssKind::galaxy ? GalaxySpatialFamily::sdss_galaxy
                                                  : GalaxySpatialFamily::sdss_quasar;
    std::optional<GalaxySpatialRecordId> id;
    for (std::size_t i = 0; i < model.source_size(0); ++i) {
        const GalaxySpatialRecordId candidate{family, 0, i};
        if (model.row(candidate).position && source->record({0, i}).distance_parsecs > 0 &&
            (kind == SdssKind::quasar || std::isfinite(source->record({0, i}).classification_value))) {
            id = candidate;
            break;
        }
    }
    require(id.has_value(), "catalog has no usable real row");
    const auto position = *model.row(*id).position;
    SolarCamera solar;
    solar.set_target_pc({position.x_pc, position.y_pc, position.z_pc});
    solar.distance_au = 1;
    verify_frame(model, *id, solar, 256, 256);
    solar.pan(12, -9, 512, 512);
    verify_frame(model, *id, solar, 268, 247);
    solar.pan(-12, 9, 512, 512);
    verify_frame(model, *id, solar, 256, 256);
    std::cout << path.filename().string() << " original row " << id->ordinal
              << ": 1 AU render, pick and pan roundtrip passed\n";
}
}

int main(int argc, char** argv) {
    try {
        if (argc != 2) throw std::invalid_argument("usage: test_galaxy_real_precision DATA_ROOT");
        real_catalog_test(argv[1], SdssKind::galaxy);
        real_catalog_test(argv[1], SdssKind::quasar);
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Galaxy real-data precision: " << error.what() << '\n';
        return 1;
    }
}
