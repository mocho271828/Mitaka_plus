#include "extended_catalogs.hpp"

namespace mitaka::gui {
namespace {

bool catalog_exists(const std::filesystem::path& path, std::vector<std::string>& warnings) {
    std::error_code error;
    const bool exists = std::filesystem::exists(path, error);
    if (error) warnings.push_back(path.filename().string() + ": " + error.message());
    return exists && !error;
}

template <typename Load>
void optional_catalog(const std::filesystem::path& path, ExtendedCatalogs& catalogs,
                      std::vector<std::string>& missing, Load load) {
    if (!catalog_exists(path, catalogs.warnings)) {
        missing.push_back(path.filename().string());
        return;
    }
    try {
        load(path);
    } catch (const CatalogError& error) {
        catalogs.warnings.push_back(error.what());
    }
}

} // namespace

ExtendedCatalogs load_extended_catalogs(const std::filesystem::path& data_directory,
                                       const ExtendedCatalogLoadOptions& options) {
    ExtendedCatalogs catalogs;
    std::vector<std::string> missing;
    const auto resolve = [&](const std::filesystem::path& requested, const char* default_name) {
        return data_directory / (requested.empty() ? std::filesystem::path(default_name) : requested);
    };
    optional_catalog(resolve(options.ngc, "ngc.dat"), catalogs, missing,
        [&](const auto& path) { catalogs.ngc = load_ngc_catalog(path, options.limits); });
    optional_catalog(resolve(options.galaxies, "SDSS_GAL.dat"), catalogs, missing,
        [&](const auto& path) { catalogs.galaxies = load_sdss_catalog(path, SdssKind::galaxy, options.limits); });
    optional_catalog(resolve(options.quasars, "SDSS_QSO.dat"), catalogs, missing,
        [&](const auto& path) { catalogs.quasars = load_sdss_catalog(path, SdssKind::quasar, options.limits); });
    const auto japanese_names = data_directory / "star_names_jp.dat";
    const auto names = !options.star_names.empty() ? data_directory / options.star_names :
        (catalog_exists(japanese_names, catalogs.warnings) ? japanese_names : data_directory / "star_names.dat");
    optional_catalog(names, catalogs, missing,
        [&](const auto& path) { catalogs.star_names = load_star_names(path, options.limits); });
    optional_catalog(resolve(options.exoplanet_hosts, "exoplanets_HIP_list.dat"), catalogs, missing,
        [&](const auto& path) { catalogs.exoplanet_hosts = load_exoplanet_host_hips(path, options.limits); });
    if (!missing.empty()) {
        std::string message = "Optional catalogs not found: ";
        for (const auto& name : missing) {
            if (message.back() != ' ') message += ", ";
            message += name;
        }
        catalogs.warnings.push_back(std::move(message));
    }
    return catalogs;
}

} // namespace mitaka::gui
