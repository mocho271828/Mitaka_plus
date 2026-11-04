#include "galaxy_spatial_load.hpp"

#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <unistd.h>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
std::size_t checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
class TemporaryDirectory {
public:
    TemporaryDirectory() {
        auto name = (std::filesystem::temp_directory_path() / "mitaka-galaxy-load-XXXXXX").string();
        if (!mkdtemp(name.data())) throw std::runtime_error("cannot create fixture directory");
        path = name;
    }
    ~TemporaryDirectory() { std::error_code error; std::filesystem::remove_all(path, error); }
    std::filesystem::path path;
};
void write(const std::filesystem::path& path, const std::vector<std::uint8_t>& bytes) {
    std::ofstream file(path, std::ios::binary);
    file.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
    if (!file) throw std::runtime_error("fixture write failed");
}
void f32(std::vector<std::uint8_t>& bytes, float value) {
    std::uint32_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    for (unsigned i = 0; i < 4; ++i) bytes.push_back(static_cast<std::uint8_t>(bits >> (8 * i)));
}
std::vector<std::uint8_t> cluster_bytes() {
    std::vector<std::uint8_t> bytes{'G', 0, 'C', 0, 255, 0, 0, 0, 0, 0, 0, 0};
    for (float value : {15.f, -20.f, -1.f, 2.f, 3.f, 0.5f, 0.25f}) f32(bytes, value);
    return bytes;
}
std::vector<std::uint8_t> nearby_bytes() {
    std::vector<std::uint8_t> bytes;
    for (float value : {30.f, 20.f, 12.f, 1.f, std::numeric_limits<float>::quiet_NaN()}) f32(bytes, value);
    for (auto value : {255, 254, 253, 42, 0, 0, 0}) bytes.push_back(static_cast<std::uint8_t>(value));
    return bytes;
}
ExtendedCatalogs fixture() {
    ExtendedCatalogs catalogs;
    catalogs.galaxies = {{{0, 0}, 0, 1}, {{20, 30}, -1, 2}, {{0, 0}, 0, 1}};
    catalogs.quasars = {{{45, -15}, 12, 4}};
    catalogs.warnings = {"existing independent warning", "existing independent warning"};
    return catalogs;
}
void verify_sdss(const GalaxySpatialLoadResult& result, const std::filesystem::path& root) {
    check(result.model && !result.cancelled, "complete SDSS model");
    check(result.model->source_size(0) == 3 && result.model->source_size(1) == 1, "all SDSS rows retained");
    check(result.model->source_path(0) == root / "SDSS_GAL.dat" &&
          result.model->source_path(1) == root / "SDSS_QSO.dat", "selected root provenance");
    check(result.model->row(result.model->record_id(0)).position.has_value(), "zero distance retained at origin");
    check(!result.model->row(result.model->record_id(1)).position, "invalid SDSS row retained without position");
    check(result.model->row(result.model->record_id(2)).position.has_value(), "duplicate SDSS row retained");
    check(result.diagnostics.size() >= 2 && result.diagnostics[0] == "existing independent warning" &&
          result.diagnostics[1] == result.diagnostics[0], "existing diagnostics and duplicates preserved");
}
void tests() {
    TemporaryDirectory directory;
    const auto root = directory.path / "selected data";
    std::filesystem::create_directory(root);
    auto catalogs = fixture();
    // SDSS の原パスが欠損・破損していても、渡された読込結果を再読込しない。
    write(root / "SDSS_GAL.dat", {1});
    const auto only_sdss = load_galaxy_spatial_model(root, catalogs, false);
    verify_sdss(only_sdss, root);
    check(!only_sdss.plus_source_failed, "disabled Plus sources are not failures");
    check(only_sdss.model->sources().size() == 2 && only_sdss.model->size() == 4 &&
          only_sdss.diagnostics.size() == 2, "default does not inspect missing Plus catalogs");
    const auto missing = load_galaxy_spatial_model(root, catalogs, true);
    verify_sdss(missing, root);
    check(missing.plus_source_failed, "missing Plus sources are marked as failures");
    check(missing.model->sources().size() == 2 && missing.diagnostics.size() == 4, "each missing Plus source diagnosed");
    check(missing.diagnostics[2].find((root / "globular_cluster.dat").string()) != std::string::npos &&
          missing.diagnostics[3].find((root / "NBG.dat").string()) != std::string::npos,
          "failed source full paths retained");
    const auto gc = cluster_bytes(), nbg = nearby_bytes();
    write(root / "globular_cluster.dat", gc);
    write(root / "NBG.dat", nbg);
    const auto full = load_galaxy_spatial_model(root, catalogs, true);
    verify_sdss(full, root);
    check(!full.plus_source_failed, "complete Plus sources are not failures");
    check(full.model->sources().size() == 4 && full.model->size() == 6 && full.diagnostics.size() == 2,
          "explicit binary sources append without merging");
    check(std::get<PlusGlobularClusterCatalog>(full.model->sources()[2]).source.bytes == gc &&
          std::get<PlusNearbyGalaxyCatalog>(full.model->sources()[3]).source.bytes == nbg,
          "binary source bytes retained");
    check(!full.model->row(full.model->record_id(4)).position &&
          full.model->row(full.model->record_id(5)).position.has_value(),
          "invalid distance retained; unrelated NaN shape does not suppress position");
    catalogs.galaxies.clear();
    check(std::get<GalaxySdssSource>(full.model->sources()[0]).snapshot->model->size() == 4,
          "model owns exactly copied SDSS rows independently of input");
    catalogs = fixture();
    ExtendedCatalogLoadOptions paths;
    paths.galaxies = "custom/GAL.dat"; paths.quasars = directory.path / "absolute-QSO.dat";
    const auto custom = load_galaxy_spatial_model(root, catalogs, false, paths);
    check(custom.model->source_path(0) == root / paths.galaxies &&
          custom.model->source_path(1) == paths.quasars, "actual SDSS override paths preserved without access");
    write(root / "globular_cluster.dat", {1});
    const auto partial = load_galaxy_spatial_model(root, catalogs, true);
    check(partial.plus_source_failed, "one broken Plus source marks the load as failed");
    check(partial.model->size() == 5 && partial.model->sources().size() == 3 &&
          partial.model->family(2) == GalaxySpatialFamily::nearby_galaxy && partial.diagnostics.size() == 3,
          "one broken optional source preserves SDSS and other source");
    write(root / "NBG.dat", {1});
    // 別名や隣接 root の入力を失敗時の代用品にしない。
    write(root / "gc.dat", gc); write(root / "NBG2.dat", nbg);
    write(directory.path / "globular_cluster.dat", gc); write(directory.path / "NBG.dat", nbg);
    const auto broken = load_galaxy_spatial_model(root, catalogs, true);
    check(broken.plus_source_failed, "broken Plus sources are marked as failures");
    check(broken.model->size() == 4 && broken.diagnostics.size() == 4, "no alternate filename or other root fallback");
    const auto disabled = load_galaxy_spatial_model(root, catalogs, false);
    check(!disabled.plus_source_failed, "unrequested broken sources are not failures");
    check(disabled.model->size() == 4 && disabled.diagnostics.size() == 2, "disabled ignores malformed optional files");
    write(root / "globular_cluster.dat", gc); write(root / "NBG.dat", nbg);
    paths = {}; paths.limits.max_file_bytes = 1;
    const auto limited = load_galaxy_spatial_model(root, catalogs, true, paths);
    check(limited.plus_source_failed, "Plus source limits are marked as failures");
    check(limited.model->size() == 4 && limited.diagnostics.size() == 4,
          "optional load limits do not revalidate already loaded SDSS");
    std::size_t calls = 0;
    const auto counted = load_galaxy_spatial_model(root, catalogs, true, {}, [&] { ++calls; return false; });
    check(counted.model && calls > 8, "cancellation observed through stages and each SDSS row");
    for (std::size_t stop = 1; stop <= calls; ++stop) {
        std::size_t seen = 0;
        const auto cancelled = load_galaxy_spatial_model(root, catalogs, true, {}, [&] { return ++seen == stop; });
        check(cancelled.cancelled && !cancelled.model, "cancelled stages never return partial model");
        check(cancelled.diagnostics == catalogs.warnings, "cancel preserves existing diagnostics");
    }
    const auto empty = load_galaxy_spatial_model(root, {}, false);
    check(empty.model && empty.model->size() == 0 && empty.model->sources().size() == 2,
          "empty SDSS source identities retained");
    try { (void)load_galaxy_spatial_model({}, catalogs, false); }
    catch (const std::invalid_argument&) { ++checks; return; }
    throw std::runtime_error("empty root was not rejected");
}
} // namespace
int main() {
    try { tests(); std::cout << "galaxy spatial load: " << checks << " checks PASS\n"; }
    catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
