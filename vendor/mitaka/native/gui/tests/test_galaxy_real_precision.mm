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

void real_extended_catalog_test(GalaxySpatialSource source) {
    GalaxySpatialModel model({std::move(source)});
    const auto family = model.family(0);
    std::optional<GalaxySpatialRecordId> id;
    for (std::size_t ordinal = 0; ordinal < model.source_size(0); ++ordinal) {
        const GalaxySpatialRecordId candidate{family, 0, ordinal};
        if (!model.row(candidate).position) continue;
        const double size = family == GalaxySpatialFamily::globular_cluster
            ? std::get<PlusGlobularClusterCatalog>(model.sources()[0]).records[ordinal].half_light_radius_pc
            : std::get<PlusNearbyGalaxyCatalog>(model.sources()[0]).records[ordinal].angular_diameter_arcminutes;
        if (std::isfinite(size) && size > 0) id = candidate;
    }
    require(id.has_value(), "extended catalog has no usable size-bearing row");
    const auto position = *model.row(*id).position;
    SolarCamera solar;
    solar.set_target_pc({position.x_pc, position.y_pc, position.z_pc});
    solar.distance_au = 1;
    for (const double pan : {0.0, 700.0, -700.0}) {
        solar.pan(pan, 0, 512, 512);
        const auto view = galaxy_camera_from_shared(shared_camera_from_solar(solar));
        const GalaxyProjector projector(view, 512, 512);
        const auto point = projector.project(position);
        const double expectedX = pan == 700 ? 956 : 256;
        require(point && std::abs(point->x - expectedX) < 1e-6 && std::abs(point->y - 256) < 1e-6,
                "extended real row lost the precise target during an AU pan");
        for (int scale : {1, 2}) {
            RendererDisplayOptions quality;
            quality.antialias = false;
            const auto bitmap = render_galaxy_bitmap(model, view, {}, quality, 512, 512, scale,
                                                       {}, GalaxyBackground::transparent);
            require(bitmap && bitmap->counts().drawn > 0,
                    "extended real row disappeared at 1 AU");
            CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(bitmap->image()));
            require(data != nullptr, "could not read the extended real row bitmap");
            const auto* bytes = CFDataGetBytePtr(data);
            const std::size_t width = CGImageGetWidth(bitmap->image());
            bool drawn = true, selected = true;
            for (const double coordinate : {40.0, 256.0, 470.0}) {
                const double sample = coordinate + 0.5 / scale;
                const std::size_t pixel = (std::size_t(sample * scale) * width + std::size_t(sample * scale)) * 4;
                drawn &= bytes[pixel + 3] != 0;
                const auto picked = pick_galaxy_spatial_row(model, projector, {}, sample, sample, 3);
                selected &= picked && *picked == *id;
            }
            CFRelease(data);
            require(drawn, "extended real row did not cover the visible interior at 1 AU");
            require(selected, "extended real row pixels did not retain their original catalog ID");
        }
    }
    std::cout << model.source_path(0).filename().string() << " original row " << id->ordinal
              << ": 1 AU size, offscreen-center pick and 1x/2x render passed\n";
}
}

int main(int argc, char** argv) {
    try {
        if (argc != 2) throw std::invalid_argument("usage: test_galaxy_real_precision DATA_ROOT");
        real_catalog_test(argv[1], SdssKind::galaxy);
        real_catalog_test(argv[1], SdssKind::quasar);
        const std::filesystem::path directory(argv[1]);
        if (std::filesystem::exists(directory / "globular_cluster.dat")) {
            real_extended_catalog_test(load_plus_globular_clusters(directory / "globular_cluster.dat"));
            real_extended_catalog_test(load_plus_nearby_galaxies(directory / "NBG.dat"));
        }
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "Galaxy real-data precision: " << error.what() << '\n';
        return 1;
    }
}
