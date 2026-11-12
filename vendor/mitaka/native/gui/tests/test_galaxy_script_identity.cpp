#include "galaxy_script_identity.hpp"
#include "mitaka/galaxy_catalog.hpp"

#include <algorithm>
#include <exception>
#include <filesystem>
#include <fstream>
#include <chrono>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <string>
#include <vector>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
int checks = 0;
void require(bool condition, const std::string& message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
PlusGlobularClusterRecord cluster(const std::string& name) {
    PlusGlobularClusterRecord row;
    if (name.size() > row.name_bytes.size()) throw std::logic_error("fixture name too long");
    std::copy(name.begin(), name.end(), row.name_bytes.begin());
    row.distance_pc = 7000;
    return row;
}
PlusNearbyGalaxyRecord nearby(unsigned char code, int number) {
    PlusNearbyGalaxyRecord row;
    row.catalog_code = code;
    row.catalog_number = number;
    row.distance_pc = 710000;
    return row;
}
void roundtrip(const GalaxySpatialModel& model, GalaxySpatialRecordId id, const std::string& expected) {
    const auto actual = script_galaxy_target_identity(model, id);
    require(actual == expected, "identity differs from raw source: " + actual + " / " + expected);
    const auto found = resolve_raw_galaxy_target(actual, model);
    require(found && *found == id, "raw identity must resolve to original record: " + actual);
}
void synthetic() {
    PlusGlobularClusterCatalog gc;
    gc.source.path = "synthetic-gc";
    gc.records = {cluster("NGC 6205"), cluster("Terzan 1"), cluster("")};
    PlusNearbyGalaxyCatalog nbg;
    nbg.source.path = "synthetic-nbg";
    nbg.records = {nearby('N', 224), nearby('T', 58), nearby('N', 0), nearby(0, 1), nearby('*', 1)};
    GalaxySpatialModel model({gc, nbg});
    roundtrip(model, {GalaxySpatialFamily::nearby_galaxy, 1, 0}, "Galaxy.#N224");
    roundtrip(model, {GalaxySpatialFamily::nearby_galaxy, 1, 1}, "Galaxy.#T58");
    roundtrip(model, {GalaxySpatialFamily::nearby_galaxy, 1, 4}, "Galaxy.#*1");
    require(script_galaxy_target_identity(model, {GalaxySpatialFamily::globular_cluster, 0, 0}) == "GC.NGC 6205", "GC identity preserves its source name");
    require(script_galaxy_target_identity(model, {GalaxySpatialFamily::globular_cluster, 0, 1}) == "GC.Terzan 1", "GC identity supports embedded spaces");
    require(script_galaxy_target_identity(model, {GalaxySpatialFamily::globular_cluster, 0, 2}).empty(), "empty GC name is unresolved");
    require(script_galaxy_target_identity(model, {GalaxySpatialFamily::nearby_galaxy, 1, 2}).empty(), "zero NBG number is unresolved");
    require(script_galaxy_target_identity(model, {GalaxySpatialFamily::nearby_galaxy, 1, 3}).empty(), "missing NBG code is unresolved");
    for (const auto& text : {"", "Galaxy.", "Galaxy.Andromeda Galaxy"})
        require(!resolve_raw_galaxy_target(text, model), std::string("non-raw target accepted: ") + text);
    for (const auto& text : {"Galaxy.#", "Galaxy.#N", "Galaxy.#N0", "Galaxy.#N-1", "Galaxy.#N0224", "Galaxy.#N224x", "Galaxy.#N9999999999999999999999", "Galaxy.#N9999"}) {
        bool rejected = false;
        try { (void)resolve_raw_galaxy_target(text, model); }
        catch (const std::invalid_argument&) { rejected = true; }
        require(rejected, std::string("invalid or unknown raw target accepted: ") + text);
    }
    require(script_galaxy_target_identity(model, {GalaxySpatialFamily::nearby_galaxy, 1, 999}).empty(), "invalid ordinal identity unresolved");
    require(script_galaxy_target_identity(model, {GalaxySpatialFamily::nearby_galaxy, 99, 0}).empty(), "invalid source identity unresolved");
    require(script_galaxy_target_identity(model, {GalaxySpatialFamily::globular_cluster, 1, 0}).empty(), "wrong family identity unresolved");

    auto duplicate = nbg;
    duplicate.source.path = "synthetic-nbg-copy";
    GalaxySpatialModel ambiguous({gc, nbg, duplicate});
    require(script_galaxy_target_identity(ambiguous, {GalaxySpatialFamily::nearby_galaxy, 1, 0}).empty(), "duplicate raw ID is not exposed as unique");
    bool rejected = false;
    try { (void)resolve_raw_galaxy_target("Galaxy.#N224", ambiguous); }
    catch (const std::invalid_argument&) { rejected = true; }
    require(rejected, "duplicate raw ID must reject instead of choosing a row");

    gc.records.push_back(cluster("Terzan 1"));
    GalaxySpatialModel ambiguous_gc({gc, nbg});
    require(script_galaxy_target_identity(ambiguous_gc, {GalaxySpatialFamily::globular_cluster, 0, 1}).empty(), "duplicate GC name is not exposed as unique");
}
void name_collision() {
    const auto suffix = std::chrono::steady_clock::now().time_since_epoch().count();
    const auto root = std::filesystem::temp_directory_path() / ("mitaka-galaxy-collision-" + std::to_string(suffix));
    if (!std::filesystem::create_directory(root)) throw std::runtime_error("cannot create fixture directory");
    struct Cleanup { std::filesystem::path path; ~Cleanup() { std::error_code error; std::filesystem::remove_all(path, error); } } cleanup{root};
    PlusNearbyGalaxyCatalog nbg;
    nbg.source.path = "synthetic-nbg";
    nbg.records = {nearby('N', 224), nearby('T', 58)};
    GalaxySpatialModel model({nbg});
    const GalaxySpatialRecordId raw_id{GalaxySpatialFamily::nearby_galaxy, 0, 0};
    const GalaxySpatialRecordId named_id{GalaxySpatialFamily::nearby_galaxy, 0, 1};
    const auto write = [&](const char* text) {
        std::ofstream out(root / "nearby_galaxies_name.dat", std::ios::binary);
        out << text;
        if (!out) throw std::runtime_error("cannot write fixture");
    };
    write("T58 #N224\n");
    require(script_galaxy_target_identity(model, raw_id, root).empty(), "ambiguous raw identity is not exposed");
    require(script_galaxy_target_for_snapshot(&model, raw_id, nullptr, std::nullopt, "", root).empty(),
            "ambiguous raw identity is not exposed in a GUI snapshot");
    require(script_galaxy_target_for_snapshot(&model, raw_id, &model, raw_id, "Galaxy.#N224", root).empty(),
            "previous raw target is not exposed after a collision appears");
    bool rejected = false;
    try { (void)resolve_script_nearby_galaxy("Galaxy.#N224", root, model); }
    catch (const std::invalid_argument& error) { rejected = std::string(error.what()).find("Ambiguous") != std::string::npos; }
    require(rejected, "raw ID/name collision with different records must be ambiguous");
    write("T58 #N9999\n");
    require(resolve_script_nearby_galaxy("Galaxy.#N9999", root, model) == named_id,
            "unknown raw ID still resolves an existing name");
    write("T58 #special\n");
    require(resolve_script_nearby_galaxy("Galaxy.#special", root, model) == named_id,
            "malformed raw ID still resolves an existing name");
    bool unknown = false;
    try { (void)resolve_script_nearby_galaxy("Galaxy.#N9999", root, model); }
    catch (const std::invalid_argument&) { unknown = true; }
    require(unknown, "unknown raw ID without matching name remains an error");
    auto duplicate = nbg;
    duplicate.source.path = "synthetic-nbg-copy";
    duplicate.records = {nearby('N', 224)};
    GalaxySpatialModel ambiguous({nbg, duplicate});
    write("T58 #N224\n");
    bool duplicate_rejected = false;
    try { (void)resolve_script_nearby_galaxy("Galaxy.#N224", root, ambiguous); }
    catch (const AmbiguousRawGalaxyTarget&) { duplicate_rejected = true; }
    require(duplicate_rejected, "ambiguous raw IDs cannot fall back to names");
    write("N224 #N224\n");
    require(resolve_script_nearby_galaxy("Galaxy.#N224", root, model) == raw_id,
            "raw ID and name of the same record are not ambiguous");
    require(script_galaxy_target_for_snapshot(&model, raw_id, nullptr, std::nullopt, "", root) == "Galaxy.#N224",
            "same-record name collision permits snapshot");
    write("T58 Other\n");
    require(resolve_script_nearby_galaxy("Galaxy.#N224", root, model) == raw_id, "raw ID without name collision");
    require(resolve_script_nearby_galaxy("Galaxy.Other", root, model) == named_id, "ordinary named target");
    require(resolve_script_nearby_galaxy("Galaxy.#N224", std::nullopt, model) == raw_id, "raw ID without name table");
    write("N224 Andromeda Galaxy\nT58 Other\n");
    require(script_galaxy_target_for_snapshot(&model, raw_id, &model, raw_id, "Galaxy.Andromeda Galaxy", root) == "Galaxy.Andromeda Galaxy", "named target initially resolves to selected row");
    require(script_galaxy_target_for_snapshot(&model, raw_id, &model, raw_id, "Other.M31", root) == "Other.M31", "alias initially resolves to selected row");
    write("T58 Andromeda Galaxy\n");
    require(script_galaxy_target_for_snapshot(&model, raw_id, &model, raw_id, "Galaxy.Andromeda Galaxy", root).empty(), "changed name table must not expose stale target");
    require(script_galaxy_target_for_snapshot(&model, raw_id, &model, raw_id, "Other.M31", root).empty(), "changed name table must not expose stale alias");
    write("N224 Andromeda Galaxy\nT58 Andromeda Galaxy\n");
    require(script_galaxy_target_for_snapshot(&model, raw_id, &model, raw_id, "Other.M31", root).empty(), "ambiguous name must not expose stale alias");
    write("T58 Other\n");
    require(script_galaxy_target_for_snapshot(&model, raw_id, &model, raw_id, "Galaxy.Andromeda Galaxy", root).empty(), "removed name must not expose stale target");
    std::filesystem::remove(root / "nearby_galaxies_name.dat");
    bool unavailable = false;
    try { (void)resolve_script_nearby_galaxy("Galaxy.#N224", root, model); }
    catch (const CatalogError&) { unavailable = true; }
    require(unavailable, "unreadable name table prevents checking for collision");
    require(script_galaxy_target_for_snapshot(&model, raw_id, nullptr, std::nullopt, "", root).empty(),
            "unreadable name table cannot produce unchecked raw identity");
}
void real_data(const std::filesystem::path& root) {
    auto gc = load_plus_globular_clusters(root / "globular_cluster.dat");
    auto nbg = load_plus_nearby_galaxies(root / "NBG.dat");
    GalaxySpatialModel model({std::move(gc), std::move(nbg)});
    const auto m31 = resolve_raw_galaxy_target("Galaxy.#N224", model);
    require(m31 && m31->family == GalaxySpatialFamily::nearby_galaxy, "real N224 exists");
    require(script_galaxy_target_identity(model, *m31) == "Galaxy.#N224", "real N224 raw identity round trip");
    const auto& clusters = std::get<PlusGlobularClusterCatalog>(model.sources()[0]);
    bool found = false;
    for (std::size_t i = 0; i < clusters.records.size(); ++i) {
        if (script_galaxy_target_identity(model, {GalaxySpatialFamily::globular_cluster, 0, i}) == "GC.NGC 6205") found = true;
    }
    require(found, "real GC.NGC 6205 exists and is unambiguous");
    const auto named = resolve_script_nearby_galaxy("Galaxy.Andromeda Galaxy", root, model);
    require(named == *m31, "existing Andromeda name resolves to source N224");
    require(resolve_script_nearby_galaxy(script_galaxy_target_identity(model, named), root, model) == named,
            "existing galaxy name -> identity -> resolution round trip");
    require(script_galaxy_target_for_snapshot(&model, named, nullptr, std::nullopt, "") == "Galaxy.#N224", "GUI selected galaxy snapshot");
    require(script_galaxy_target_for_snapshot(&model, named, &model, named, "Galaxy.Andromeda Galaxy", root) == "Galaxy.Andromeda Galaxy", "script target spelling preserved");
    require(script_galaxy_target_for_snapshot(&model, named, &model, named, "Other.M31", root) == "Other.M31", "script alias spelling preserved");
    require(script_galaxy_target_for_snapshot(nullptr, named, nullptr, named, "Other.M31").empty(), "missing model cannot reuse stale target");
    const auto named_gc = resolve_script_globular_cluster("GC.NGC 6205", model);
    require(script_galaxy_target_for_snapshot(&model, named_gc, &model, named, "Other.M31") == "GC.NGC 6205", "GUI cluster ignores stale script selection");
    require(resolve_script_globular_cluster(script_galaxy_target_identity(model, named_gc), model) == named_gc,
            "existing cluster name -> identity -> resolution round trip");
    const auto named_m87 = resolve_script_nearby_galaxy("Galaxy.M87", root, model);
    require(resolve_script_nearby_galaxy(script_galaxy_target_identity(model, named_m87), root, model) == named_m87,
            "existing M87 name -> identity -> resolution round trip");
}
}
int main(int argc, char** argv) {
    try {
        synthetic();
        name_collision();
        if (argc == 2) real_data(argv[1]);
        else if (argc != 1) throw std::invalid_argument("usage: test_galaxy_script_identity [data-directory]");
        std::cout << "Galaxy target identity passed: " << checks << " checks\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
