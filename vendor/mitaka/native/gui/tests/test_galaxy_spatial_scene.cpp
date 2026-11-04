#include "galaxy_spatial_scene.hpp"

#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <type_traits>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
std::size_t checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class Exception = std::invalid_argument, class F> void rejects(F action) {
    try { action(); } catch (const Exception&) { ++checks; return; }
    throw std::runtime_error("expected rejection");
}
bool same(NativeEclipticPositionPc a, NativeEclipticPositionPc b) {
    return a.x_pc == b.x_pc && a.y_pc == b.y_pc && a.z_pc == b.z_pc;
}
SdssRecord sdss(double ra = 0, double dec = 0, float distance = 1) {
    return {{ra, dec}, distance, -0.25F};
}
std::shared_ptr<const SdssSpatialSnapshot> snapshot(std::vector<SdssSpatialSource> sources) {
    return evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(std::move(sources)));
}
PlusGlobularClusterCatalog gc(std::vector<float> distances) {
    PlusGlobularClusterCatalog result{{"same local path", {0x81, 0x5c, 0x00, 0xff}}, {}};
    for (float distance : distances) {
        PlusGlobularClusterRecord row;
        row.name_bytes = {'x', 0, 'y', 0xff};
        row.distance_pc = distance;
        row.color_b_minus_v = std::numeric_limits<float>::quiet_NaN();
        result.records.push_back(row);
    }
    return result;
}
PlusNearbyGalaxyCatalog nbg(std::vector<float> distances) {
    PlusNearbyGalaxyCatalog result{{"same local path", {0x01, 0x00, 0xff}}, {}};
    for (float distance : distances) {
        PlusNearbyGalaxyRecord row;
        row.distance_pc = distance;
        row.render_class_code = 255; row.auxiliary_code = 99; row.catalog_code = 128;
        row.catalog_number = -123;
        row.angular_diameter_arcminutes = std::numeric_limits<float>::quiet_NaN();
        result.records.push_back(row);
    }
    return result;
}
void identity_and_position_tests() {
    static_assert(!std::is_move_constructible_v<GalaxySpatialModel>);
    static_assert(!std::is_copy_constructible_v<GalaxySpatialModel>);
    const auto sdss_snapshot = snapshot({
        {SdssKind::galaxy, "same local path", {sdss(), sdss(0, 0, 0), sdss(360, 91, -2)}},
        {SdssKind::quasar, "same local path", {sdss(90, 45, 3), sdss(90, 45, 3)}}});
    auto clusters = gc({4, 0, -1});
    clusters.records[2].right_ascension_degrees = 360;
    auto nearby = nbg({5, -0.0F});
    nearby.records[1].declination_degrees = 91;
    std::vector<GalaxySpatialSource> sources{gc({}), GalaxySdssSource{sdss_snapshot, 0}, gc({}),
        clusters, GalaxySdssSource{sdss_snapshot, 1}, nearby, nbg({})};
    const auto model = std::make_shared<const GalaxySpatialModel>(sources);
    std::get<PlusGlobularClusterCatalog>(sources[3]).records[0].distance_pc = 999;
    std::get<PlusGlobularClusterCatalog>(sources[3]).source.bytes[0] = 0;
    check(model->size() == 10 && model->sources().size() == 7, "all rows and empty sources retained");
    const auto& owned = std::get<PlusGlobularClusterCatalog>(model->sources()[3]);
    check(owned.source.bytes == clusters.source.bytes && owned.records[0].distance_pc == 4,
          "raw bytes and typed rows value owned");
    check(owned.records[0].name_bytes[2] == 'y' && owned.records[0].name_bytes[3] == 255,
          "NUL tail name bytes retained");
    const auto& owned_nearby = std::get<PlusNearbyGalaxyCatalog>(model->sources()[5]).records[0];
    check(owned_nearby.render_class_code == 255 && owned_nearby.auxiliary_code == 99 &&
          owned_nearby.catalog_code == 128 && owned_nearby.catalog_number == -123,
          "unknown codes and signed catalog identity retained");
    check(std::get<GalaxySdssSource>(model->sources()[1]).snapshot == sdss_snapshot &&
          std::get<GalaxySdssSource>(model->sources()[4]).snapshot == sdss_snapshot,
          "SDSS positions shared without replication");
    const std::size_t expected_sources[]{1, 1, 1, 3, 3, 3, 4, 4, 5, 5};
    const std::size_t expected_ordinals[]{0, 1, 2, 0, 1, 2, 0, 1, 0, 1};
    for (std::size_t i = 0; i < model->size(); ++i) {
        const auto id = model->record_id(i);
        check(id.source_index == expected_sources[i] && id.ordinal == expected_ordinals[i],
              "empty-source offsets and ordinal");
        check(model->row_index(id) == i && model->row(id).id == id, "ID roundtrip");
        check(model->source_path(id.source_index) == "same local path", "same path sources not merged");
    }
    check(model->row(model->record_id(1)).position.has_value() &&
          same(*model->row(model->record_id(1)).position, {0, 0, 0}), "SDSS zero remains origin");
    check(model->row(model->record_id(2)).issues == sdss_snapshot->rows[2].issues &&
          !model->row(model->record_id(2)).position, "SDSS multiple invalid reasons preserved");
    const auto cluster_invalid = model->row(model->record_id(5));
    check(cluster_invalid.issue_domain == GalaxyIssueDomain::galaxy_catalog &&
          cluster_invalid.issues == (static_cast<unsigned>(GalaxyPositionIssue::ra_out_of_range) |
              static_cast<unsigned>(GalaxyPositionIssue::negative_distance)) && !cluster_invalid.position,
          "GC multiple invalid reasons preserved");
    const auto zero_invalid = model->row(model->record_id(9));
    check(zero_invalid.issues == (static_cast<unsigned>(GalaxyPositionIssue::zero_distance) |
          static_cast<unsigned>(GalaxyPositionIssue::dec_out_of_range)) && !zero_invalid.position,
          "zero distance does not hide invalid coordinate");
    check(same(*model->row(model->record_id(3)).position, {4, 0, 0}) &&
          same(*model->row(model->record_id(8)).position, {5, 0, 0}), "color/shape NaNs do not remove positions");
    check(same(*model->row(model->record_id(6)).position, *model->row(model->record_id(7)).position),
          "duplicate original rows preserved");
    rejects<std::out_of_range>([&] { model->record_id(model->size()); });
    rejects<std::out_of_range>([&] { model->row_index({GalaxySpatialFamily::sdss_quasar, 1, 0}); });
    rejects<std::out_of_range>([&] { model->row_index({GalaxySpatialFamily::globular_cluster, 0, 0}); });
    rejects<std::out_of_range>([&] { model->source_size(7); });
    rejects<std::out_of_range>([&] { model->row_index({GalaxySpatialFamily::sdss_galaxy, 1, 3}); });
    const GalaxySpatialModel empty({});
    check(empty.size() == 0, "no sources supported");
    rejects<std::out_of_range>([&] { empty.record_id(0); });
}
void invalid_snapshot_tests() {
    const auto valid = snapshot({{SdssKind::galaxy, "local", {sdss()}}});
    for (int kind = 0; kind < 10; ++kind) {
        auto bad = std::make_shared<SdssSpatialSnapshot>(*valid);
        switch (kind) {
        case 0: bad->cancelled = true; break;
        case 1: bad->completed_count = 0; break;
        case 2: bad->rows.clear(); break;
        case 3: bad->positioned_count = 0; break;
        case 4: bad->invalid_count = 1; break;
        case 5: bad->zero_distance_count = 1; break;
        case 6: bad->rows[0].issues = 0x8000; break;
        case 7: bad->rows[0].issues = 1; break;
        case 8: bad->rows[0].position.reset(); break;
        case 9: bad->rows[0].position->native_ecliptic.x_pc = std::numeric_limits<double>::quiet_NaN(); break;
        }
        rejects([&] { GalaxySpatialModel model({GalaxySdssSource{bad, 0}}); });
    }
    rejects([] { GalaxySpatialModel model({GalaxySdssSource{nullptr, 0}}); });
    rejects([&] { GalaxySpatialModel model({GalaxySdssSource{std::make_shared<SdssSpatialSnapshot>(), 0}}); });
    rejects<std::out_of_range>([&] { GalaxySpatialModel model({GalaxySdssSource{valid, 1}}); });
    auto bad_path = gc({1}); bad_path.source.path.clear();
    rejects([&] { GalaxySpatialModel model({bad_path}); });
    rejects([] { (void)GalaxySpatialVisibility{}.visible(static_cast<GalaxySpatialFamily>(999)); });
}
void pick_and_selection_tests() {
    const auto sdss_snapshot = snapshot({
        {SdssKind::galaxy, "galaxy", {sdss(), sdss(90, 0, 100), sdss(360, 0, 1)}},
        {SdssKind::quasar, "quasar", {sdss(0, 0, 2)}}});
    const auto model = std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{
        GalaxySdssSource{sdss_snapshot, 0}, GalaxySdssSource{sdss_snapshot, 1}, gc({3, 3, -1}), nbg({4})});
    const GalaxyProjector projector({{0, 0, 0}, 0, 0, 10}, 800, 600);
    for (unsigned mask = 0; mask < 16; ++mask) {
        const GalaxySpatialVisibility visibility{bool(mask & 1), bool(mask & 2), bool(mask & 4), bool(mask & 8)};
        const auto selected = pick_galaxy_spatial_row(*model, projector, visibility, 400, 300, 0);
        if (mask == 0) check(!selected, "no visible family cannot pick");
        else {
            const std::size_t expected = mask & 8 ? 3 : mask & 4 ? 2 : mask & 2 ? 1 : 0;
            check(selected && selected->source_index == expected && selected->ordinal == 0,
                  "family flags, nearest depth, original tie order");
        }
    }
    check(!pick_galaxy_spatial_row(*model, projector, {}, 500, 300, 1), "outside pick radius");
    std::size_t calls = 0;
    check(!pick_galaxy_spatial_row(*model, projector, {}, 400, 300, 1,
        [&] { return ++calls == 1; }) && calls == 1, "pick cancels before first source");
    const GalaxySpatialModel many({gc(std::vector<float>(1025, 1))});
    calls = 0;
    check(!pick_galaxy_spatial_row(many, projector, {}, 400, 300, 1,
        [&] { return ++calls == 4; }) && calls == 4, "pick discards candidate during row walk");
    calls = 0;
    const auto complete = pick_galaxy_spatial_row(many, projector, {}, 400, 300, 1,
        [&] { ++calls; return false; });
    check(complete && complete->ordinal == 0 && calls == 7, "pick checks all batches and completion");
    calls = 0;
    check(!pick_galaxy_spatial_row(many, projector, {}, 400, 300, 1,
        [&] { return ++calls == 7; }), "pick discards completed candidate when cancelled");
    check(!pick_galaxy_spatial_row(*model, projector, {}, -1, 300, 1e7), "outside viewport cannot pick");
    check(!pick_galaxy_spatial_row(*model, projector, {true, false, false, false}, 799, 300, 1),
          "offscreen object excluded from picking");
    for (double bad : {-1.0, 1e8, std::numeric_limits<double>::infinity(),
                       std::numeric_limits<double>::quiet_NaN()})
        rejects([&] { (void)pick_galaxy_spatial_row(*model, projector, {}, 400, 300, bad); });
    rejects([&] { (void)pick_galaxy_spatial_row(*model, projector, {},
        std::numeric_limits<double>::quiet_NaN(), 300, 1); });
    GalaxySpatialScene scene;
    GalaxyCameraPc camera;
    const auto original = camera;
    check(!scene.focus_selection(camera), "empty scene focus no-op");
    rejects([&] { scene.select(model->record_id(0)); });
    scene.set_model(model);
    const auto chosen = model->record_id(7);
    scene.select(chosen);
    check(scene.focus_selection(camera) && same(camera.target, {4, 0, 0}), "focus uses pc unchanged");
    check(camera.distance_pc == original.distance_pc && camera.yaw_deg == original.yaw_deg &&
          camera.pitch_deg == original.pitch_deg, "focus preserves distance and orientation");
    rejects<std::out_of_range>([&] { scene.select(GalaxySpatialRecordId{GalaxySpatialFamily::nearby_galaxy, 3, 1}); });
    check(scene.selection() && *scene.selection() == chosen, "invalid selection atomic");
    scene.set_model(model);
    check(scene.selection() && *scene.selection() == chosen, "same model retains selection");
    scene.select(model->record_id(2));
    check(!scene.focus_selection(camera) && same(camera.target, {4, 0, 0}), "invalid original row inspectable, focus no-op");
    scene.set_model(std::make_shared<const GalaxySpatialModel>(model->sources()));
    check(!scene.selection(), "new model same paths clears selection");
    scene.select(scene.model()->record_id(0));
    scene.select(std::nullopt);
    check(!scene.selection(), "explicit clear");
    scene.set_model(nullptr);
    check(!scene.model() && !scene.selection(), "model detach clears");
}
std::vector<std::uint8_t> read_bytes(const std::filesystem::path& path) {
    std::ifstream file(path, std::ios::binary);
    check(static_cast<bool>(file), "local source readable");
    return {std::istreambuf_iterator<char>(file), std::istreambuf_iterator<char>()};
}
void local_tests(const std::filesystem::path& directory) {
    std::vector<SdssSpatialSource> sdss_sources;
    for (auto kind : {SdssKind::galaxy, SdssKind::quasar}) {
        const auto path = directory / (kind == SdssKind::galaxy ? "SDSS_GAL.dat" : "SDSS_QSO.dat");
        sdss_sources.push_back({kind, path, load_sdss_catalog(path, kind)});
    }
    const auto sdss_snapshot = snapshot(std::move(sdss_sources));
    std::vector<GalaxySpatialSource> sources{GalaxySdssSource{sdss_snapshot, 0}, GalaxySdssSource{sdss_snapshot, 1}};
    // GC/NBG の Plus binary を明示する。通常版の同名形式は自動判別しない。
    const bool plus = std::filesystem::exists(directory / "globular_cluster.dat");
    if (plus) {
        sources.emplace_back(load_plus_globular_clusters(directory / "globular_cluster.dat"));
        sources.emplace_back(load_plus_nearby_galaxies(directory / "NBG.dat"));
    }
    const GalaxySpatialModel model(std::move(sources));
    std::size_t expected = 0, positioned = 0;
    for (std::size_t source = 0; source < model.sources().size(); ++source) {
        const auto count = model.source_size(source);
        for (std::size_t ordinal = 0; ordinal < count; ++ordinal, ++expected) {
            const GalaxySpatialRecordId id{model.family(source), source, ordinal};
            check(model.record_id(expected) == id && model.row_index(id) == expected, "local all row IDs");
            const auto row = model.row(id);
            check(row.id == id, "local all rows retained");
            if (row.position) ++positioned;
            if (source < 2) {
                const auto& reference = sdss_snapshot->rows[expected];
                check(row.issues == reference.issues && row.position.has_value() == reference.position.has_value(),
                      "local SDSS shared exact position/reasons");
                if (row.position)
                    check(same(*row.position, reference.position->native_ecliptic), "local SDSS exact position");
            } else {
                const auto evaluate = [](const auto& record) {
                    return evaluate_galaxy_position_pc(record.right_ascension_degrees,
                        record.declination_degrees, record.distance_pc);
                };
                const auto reference = source == 2
                    ? evaluate(std::get<PlusGlobularClusterCatalog>(model.sources()[source]).records[ordinal])
                    : evaluate(std::get<PlusNearbyGalaxyCatalog>(model.sources()[source]).records[ordinal]);
                check(row.issues == reference.issues && row.position.has_value() == reference.position.has_value(),
                      "local GC/NBG position and diagnostic state");
                if (row.position) {
                    const auto& p = reference.position->native_ecliptic;
                    check(same(*row.position, {p.x_pc, p.y_pc, p.z_pc}), "local GC/NBG exact position");
                }
            }
        }
        if (source >= 2) {
            const auto bytes = read_bytes(model.source_path(source));
            const auto& owned = source == 2 ? std::get<PlusGlobularClusterCatalog>(model.sources()[source]).source
                                           : std::get<PlusNearbyGalaxyCatalog>(model.sources()[source]).source;
            check(owned.bytes == bytes, "local raw source bytes unchanged");
        }
    }
    check(model.size() == expected, "local no row cap");
    const GalaxyProjector projector({{0, 0, 0}, 35, 35, 1e9}, 1024, 768);
    const auto selected = pick_galaxy_spatial_row(model, projector, {}, 512, 384, 12);
    if (selected) check(model.row(*selected).position.has_value(), "local full catalog picking");
    std::cout << "Local galaxy scene rows: " << model.size() << ", positioned: " << positioned
              << ", invalid: " << model.size() - positioned << '\n';
}
} // namespace
int main(int argc, char** argv) {
    try {
        if (argc > 2) throw std::invalid_argument("usage: test_galaxy_spatial_scene [data directory]");
        identity_and_position_tests(); invalid_snapshot_tests(); pick_and_selection_tests();
        if (argc == 2) local_tests(argv[1]);
        std::cout << "Galaxy spatial scene: " << checks << " checks PASS\n";
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
