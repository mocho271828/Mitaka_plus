#include "galaxy_spatial_load.hpp"

namespace mitaka::gui {

GalaxySpatialLoadResult load_galaxy_spatial_model(
    const std::filesystem::path& data_directory, const ExtendedCatalogs& catalogs,
    bool include_plus_binary, const ExtendedCatalogLoadOptions& options,
    std::function<bool()> should_cancel) {
    if (data_directory.empty()) throw std::invalid_argument("galaxy load: empty data directory");
    GalaxySpatialLoadResult result;
    result.diagnostics = catalogs.warnings;
    const auto cancelled = [&] {
        if (should_cancel && should_cancel()) result.cancelled = true;
        return result.cancelled;
    };
    if (cancelled()) return result;
    const auto resolve = [&](const std::filesystem::path& requested, const char* name) {
        return data_directory / (requested.empty() ? std::filesystem::path(name) : requested);
    };
    std::vector<SdssSpatialSource> sdss;
    sdss.reserve(2);
    sdss.push_back({SdssKind::galaxy, resolve(options.galaxies, "SDSS_GAL.dat"), catalogs.galaxies});
    if (cancelled()) return result;
    sdss.push_back({SdssKind::quasar, resolve(options.quasars, "SDSS_QSO.dat"), catalogs.quasars});
    if (cancelled()) return result;
    const auto snapshot = evaluate_sdss_spatial_snapshot(
        std::make_shared<const SdssSpatialModel>(std::move(sdss)), cancelled);
    if (snapshot->cancelled || cancelled()) {
        result.cancelled = true;
        return result;
    }
    std::vector<GalaxySpatialSource> sources{GalaxySdssSource{snapshot, 0}, GalaxySdssSource{snapshot, 1}};
    if (include_plus_binary) {
        const auto optional = [&](const auto& path, auto load) {
            try {
                sources.emplace_back(load(path, options.limits));
            } catch (const CatalogError& error) {
                result.plus_source_failed = true;
                result.diagnostics.push_back(error.what());
            }
        };
        if (cancelled()) return result;
        optional(data_directory / "globular_cluster.dat", load_plus_globular_clusters);
        if (cancelled()) return result;
        optional(data_directory / "NBG.dat", load_plus_nearby_galaxies);
        if (cancelled()) return result;
    }
    auto model = std::make_shared<const GalaxySpatialModel>(std::move(sources));
    if (cancelled()) return result;
    result.model = std::move(model);
    return result;
}

} // namespace mitaka::gui
