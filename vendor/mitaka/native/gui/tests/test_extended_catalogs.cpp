#include "extended_catalogs.hpp"

#include <chrono>
#include <fstream>
#include <iostream>

namespace {
void require(bool condition, const std::string& message) {
    if (!condition) throw std::runtime_error(message);
}

void write(const std::filesystem::path& path, const std::string& data) {
    std::ofstream file(path, std::ios::binary);
    file << data;
    require(bool(file), "write fixture");
}
} // namespace

int main(int argc, char** argv) {
    const auto root = std::filesystem::temp_directory_path() /
        ("mitaka_optional_" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    try {
        require(std::filesystem::create_directory(root), "create fixtures");
        auto catalogs = mitaka::gui::load_extended_catalogs(root);
        require(catalogs.warnings.size() == 1 && catalogs.ngc.empty() && catalogs.star_names.empty(),
            "missing optional files aggregate into one warning");
        write(root / "star_names.dat", "  7588*Achernar\n");
        write(root / "exoplanets_HIP_list.dat", "7588\n");
        write(root / "ngc.dat", "corrupt");
        catalogs = mitaka::gui::load_extended_catalogs(root);
        require(catalogs.star_names.size() == 1 && catalogs.exoplanet_hosts.size() == 1 &&
            catalogs.ngc.empty() && catalogs.warnings.size() == 2,
            "corrupt catalog isolates failure while retaining valid catalogs");
        require(catalogs.warnings.front().find("ngc.dat: byte ") != std::string::npos,
            "optional corrupt catalog gives path and offset");
        write(root / "star_names_jp.dat", "  7588*Achernar     Japanese\n");
        catalogs = mitaka::gui::load_extended_catalogs(root);
        require(catalogs.star_names.front().localized_name_bytes == "Japanese", "prefer localized names");
        write(root / "star_names_jp.dat", "corrupt");
        catalogs = mitaka::gui::load_extended_catalogs(root);
        require(catalogs.star_names.empty(), "corrupt preferred file must not silently use another");
        write(root / "user_names.dat", "999999 Custom Star\n999998 Second Star\n");
        mitaka::gui::ExtendedCatalogLoadOptions options;
        options.star_names = "user_names.dat";
        options.exoplanet_hosts = root / "exoplanets_HIP_list.dat";
        options.limits.max_records = 1;
        catalogs = mitaka::gui::load_extended_catalogs(root, options);
        require(catalogs.star_names.empty() && catalogs.exoplanet_hosts.size() == 1,
            "configured limits and absolute custom path");
        options.limits.max_records = 2;
        catalogs = mitaka::gui::load_extended_catalogs(root, options);
        require(catalogs.star_names.size() == 2 && catalogs.star_names.front().hip == 999999,
            "configured relative file and expanded limits include every custom row");
        std::filesystem::remove_all(root);
        if (argc > 1) {
            catalogs = mitaka::gui::load_extended_catalogs(argv[1]);
            for (const auto& warning : catalogs.warnings) {
                std::cout << warning << '\n';
                require(warning.find("Optional catalogs not found: ") == 0,
                    "local catalog must not be corrupt or exceed configured limits");
            }
            std::cout << "Local rows: NGC " << catalogs.ngc.size() << ", GAL " << catalogs.galaxies.size()
                << ", QSO " << catalogs.quasars.size() << ", names " << catalogs.star_names.size()
                << ", hosts " << catalogs.exoplanet_hosts.size() << '\n';
        }
        std::cout << "Extended catalog aggregate tests passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::error_code cleanup_error;
        std::filesystem::remove_all(root, cleanup_error);
        std::cerr << error.what() << '\n';
        return 1;
    }
}
