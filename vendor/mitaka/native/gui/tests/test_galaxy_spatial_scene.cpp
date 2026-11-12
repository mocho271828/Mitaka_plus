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
            check(selected && selected->source_index == expected &&
                  selected->ordinal == (expected == 2 ? 1u : 0u),
                  "family flags, nearest depth, last overlapping row");
        }
    }
    const auto overlap = snapshot({
        {SdssKind::galaxy, "galaxy", {sdss()}},
        {SdssKind::quasar, "quasar", {sdss()}}});
    const GalaxySpatialModel overlapping({GalaxySdssSource{overlap, 0}, GalaxySdssSource{overlap, 1}});
    const auto top = pick_galaxy_spatial_row(overlapping, projector, {}, 400, 300, 0);
    check(top && top->family == GalaxySpatialFamily::sdss_quasar && top->ordinal == 0,
          "exact overlap selects the last visible source");
    const auto hiddenTop = pick_galaxy_spatial_row(overlapping, projector, {true, false, true, true}, 400, 300, 0);
    check(hiddenTop && hiddenTop->family == GalaxySpatialFamily::sdss_galaxy && hiddenTop->ordinal == 0,
          "hidden overlapping source does not replace visible source");
    // 同じ視線上の異なる深度の点は、前後にかかわらず後描きが画面に残る。
    for (bool reverse : {false, true}) {
        const auto depths = snapshot({
            {SdssKind::galaxy, "depth", {sdss(0, 0, reverse ? 2 : 1), sdss(0, 0, reverse ? 1 : 2)}},
            {SdssKind::quasar, "depth-quasar", {sdss(0, 0, reverse ? 2 : 1)}}});
        const GalaxySpatialModel same_source({GalaxySdssSource{depths, 0}});
        const GalaxySpatialModel cross_source({GalaxySdssSource{depths, 0}, GalaxySdssSource{depths, 1}});
        const auto first = projector.project(*same_source.row({GalaxySpatialFamily::sdss_galaxy, 0, 0}).position);
        const auto second = projector.project(*same_source.row({GalaxySpatialFamily::sdss_galaxy, 0, 1}).position);
        check(first && second && first->x == second->x && first->y == second->y && first->depth_pc != second->depth_pc,
              "fixture has exact projected overlap and different depths");
        for (double offset : {0.0, 4.0}) {
            const auto row = pick_galaxy_spatial_row(same_source, projector, {}, 400 + offset, 300, 8);
            check(row && row->ordinal == 1, "last overlapping row selected regardless of depth");
            const auto source = pick_galaxy_spatial_row(cross_source, projector, {}, 400 + offset, 300, 8);
            check(source && source->family == GalaxySpatialFamily::sdss_quasar,
                  "last overlapping source selected regardless of depth");
            const auto hidden = pick_galaxy_spatial_row(cross_source, projector,
                {true, false, true, true}, 400 + offset, 300, 8);
            check(hidden && hidden->family == GalaxySpatialFamily::sdss_galaxy && hidden->ordinal == 1,
                  "hidden source cannot replace visible overlapping row");
        }
    }
    // 異なる投影中心が重なる場合も、表示された後描き点を選ぶ。
    double overlapping_ra = 0;
    for (double ra = 0.001; ra < 10; ra += 0.001) {
        const auto candidate = snapshot({{SdssKind::quasar, "candidate", {sdss(ra)}}});
        const GalaxySpatialModel single({GalaxySdssSource{candidate, 0}});
        const auto projected = projector.project(*single.row(single.record_id(0)).position);
        if (projected && std::hypot(projected->x - 400, projected->y - 300) > 0.25 &&
            std::hypot(projected->x - 400, projected->y - 300) < 1.0) { overlapping_ra = ra; break; }
    }
    check(overlapping_ra != 0, "distinct overlapping projections found");
    const auto partial_snapshot = snapshot({
        {SdssKind::galaxy, "first", {sdss()}},
        {SdssKind::quasar, "second", {sdss(overlapping_ra)}}});
    const GalaxySpatialModel partial({GalaxySdssSource{partial_snapshot, 0}, GalaxySdssSource{partial_snapshot, 1}});
    const auto partial_top = pick_galaxy_spatial_row(partial, projector, {}, 400, 300, 8);
    check(partial_top && partial_top->family == GalaxySpatialFamily::sdss_quasar,
          "later ellipse wins over nearer center when both cover click");
    const auto partial_hidden = pick_galaxy_spatial_row(partial, projector, {true, false, true, true}, 400, 300, 8);
    check(partial_hidden && partial_hidden->family == GalaxySpatialFamily::sdss_galaxy,
          "hidden ellipse does not win overlap");
    const auto zero_radius = pick_galaxy_spatial_row(partial, projector, {}, 400, 300, 0);
    check(zero_radius && zero_radius->family == GalaxySpatialFamily::sdss_quasar,
          "painted geometry takes precedence even outside the proximity radius");
    check(galaxy_spatial_point_contains(GalaxySpatialFamily::sdss_galaxy, 10, 10, 11.2, 10, false) &&
          !galaxy_spatial_point_contains(GalaxySpatialFamily::sdss_galaxy, 10, 10, 11.3, 10, false) &&
          galaxy_spatial_point_contains(GalaxySpatialFamily::globular_cluster, 10, 10, 11.9, 10, false),
          "complete point geometry matches family radius");
    check(galaxy_spatial_point_contains(GalaxySpatialFamily::sdss_galaxy, 10, 10, 11.4, 11.4, true) &&
          !galaxy_spatial_point_contains(GalaxySpatialFamily::sdss_galaxy, 10, 10, 9.9, 10, true) &&
          !galaxy_spatial_point_contains(GalaxySpatialFamily::sdss_galaxy, 10, 10, 11.6, 10, true),
          "preview hit follows offset rectangle");
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
    check(complete && complete->ordinal == 1024 && calls == 7, "pick checks all batches and completion");
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
void projected_extent_tests() {
    constexpr double pi = 3.14159265358979323846;
    auto clusters = gc({100});
    clusters.records[0].half_light_radius_pc = 10;
    auto galaxies = nbg({100});
    galaxies.records[0].angular_diameter_arcminutes = 120;
    const auto sdss_snapshot = snapshot({{SdssKind::galaxy, "sdss", {sdss(0, 0, 100)}}});
    const GalaxySpatialModel model({clusters, galaxies, GalaxySdssSource{sdss_snapshot, 0}});
    const GalaxySpatialRecordId cluster_id{GalaxySpatialFamily::globular_cluster, 0, 0};
    const GalaxySpatialRecordId galaxy_id{GalaxySpatialFamily::nearby_galaxy, 1, 0};
    const GalaxySpatialRecordId sdss_id{GalaxySpatialFamily::sdss_galaxy, 2, 0};
    GalaxyCameraPc camera{{100, 0, 0}, 0, 0, 100};
    camera.vertical_fov_deg = 90;
    const GalaxyProjector projector(camera, 800, 600);
    const auto cluster = galaxy_spatial_shape(model, cluster_id, projector, false);
    const auto galaxy = galaxy_spatial_shape(model, galaxy_id, projector, false);
    check(cluster && std::abs(cluster->center.x - 400) < 1e-10 &&
          std::abs(cluster->center.y - 300) < 1e-10 && std::abs(cluster->radius - 30) < 1e-10,
          "GC projected radius follows half-light radius and depth");
    const double galaxy_radius = 100.0 * 120.0 * pi / 21600.0 * 3.0;
    check(galaxy && std::abs(galaxy->radius - galaxy_radius) < 1e-10,
          "NBG projected radius follows distance and angular diameter");
    for (const auto id : {cluster_id, galaxy_id}) {
        const auto preview = galaxy_spatial_shape(model, id, projector, true);
        const auto complete = galaxy_spatial_shape(model, id, projector, false);
        check(preview && complete && !preview->preview_rectangle &&
              std::abs(preview->radius - complete->radius) < 1e-12,
              "GC/NBG preview and complete share the same circular extent");
    }
    camera.distance_pc = 200;
    const GalaxyProjector farther(camera, 800, 600);
    const auto far_cluster = galaxy_spatial_shape(model, cluster_id, farther, false);
    check(far_cluster && std::abs(far_cluster->radius - 15) < 1e-10,
          "doubling camera depth halves GC projected radius");
    camera.distance_pc = 100;
    camera.vertical_fov_deg = 45;
    const GalaxyProjector narrow(camera, 800, 600);
    const auto narrow_cluster = galaxy_spatial_shape(model, cluster_id, narrow, false);
    check(narrow_cluster && std::abs(narrow_cluster->radius - 30 / std::tan(pi / 8)) < 1e-9,
          "narrower FOV enlarges projected extent");
    const GalaxyProjector taller(camera, 800, 1200);
    const auto tall_cluster = galaxy_spatial_shape(model, cluster_id, taller, false);
    check(tall_cluster && std::abs(tall_cluster->radius - 2 * narrow_cluster->radius) < 1e-9,
          "projected extent scales with viewport height");
    const auto sdss = galaxy_spatial_shape(model, sdss_id, projector, false);
    const auto sdss_preview = galaxy_spatial_shape(model, sdss_id, projector, true);
    check(sdss && !sdss->preview_rectangle && sdss->radius == 1.25,
          "SDSS keeps its complete point radius");
    check(sdss_preview && sdss_preview->preview_rectangle &&
          sdss_preview->contains(401.4, 301.4) && !sdss_preview->contains(399.9, 300),
          "SDSS preview keeps its offset rectangle");
    for (const float invalid : {0.0f, -1.0f, std::numeric_limits<float>::quiet_NaN(),
                                std::numeric_limits<float>::infinity()}) {
        auto bad_clusters = clusters;
        bad_clusters.records[0].half_light_radius_pc = invalid;
        auto bad_galaxies = galaxies;
        bad_galaxies.records[0].angular_diameter_arcminutes = invalid;
        const GalaxySpatialModel invalid_model({bad_clusters, bad_galaxies});
        const auto c = galaxy_spatial_shape(invalid_model, cluster_id, projector, false);
        const auto g = galaxy_spatial_shape(invalid_model, galaxy_id, projector, false);
        check(c && c->radius == 2.0 && g && g->radius == 1.25,
              "invalid sizes retain selectable point fallback");
    }
    auto oversize = galaxies;
    oversize.records[0].angular_diameter_arcminutes = 10800;
    const GalaxySpatialModel oversize_model({clusters, oversize});
    const auto fallback = galaxy_spatial_shape(oversize_model, galaxy_id, projector, false);
    check(fallback && fallback->radius == 1.25, "invalid 90-degree half-angle uses point fallback");
    const auto selected = pick_galaxy_spatial_row(model, projector, {false, false, true, false}, 420, 300, 8);
    check(selected && *selected == cluster_id, "large visible GC can be selected beyond 8 points");
    const auto selected_nbg = pick_galaxy_spatial_row(model, narrow, {false, false, false, true}, 410, 300, 8);
    check(selected_nbg && *selected_nbg == galaxy_id, "large visible NBG can be selected beyond 8 points");
    check(!pick_galaxy_spatial_row(model, projector, {false, false, false, false}, 420, 300, 8),
          "hidden large extent is not selectable");
    SolarCamera direction;
    direction.yaw_deg = 0; direction.pitch_deg = 0;
    const auto axes = solar_camera_basis(direction);
    GalaxyCameraPc offscreen = camera;
    offscreen.vertical_fov_deg = 90;
    const double shift = 410.0 / 3.0;
    offscreen.target = {100 + axes.right.x * shift, axes.right.y * shift, axes.right.z * shift};
    const GalaxyProjector clipped(offscreen, 800, 600);
    const auto outside = galaxy_spatial_shape(model, cluster_id, clipped, false);
    check(outside && outside->center.x < 0 && outside->intersects_viewport(clipped) &&
          outside->contains(0, 300), "offscreen center retains visible extent");
    const auto clipped_pick = pick_galaxy_spatial_row(model, clipped, {false, false, true, false}, 0, 300, 8);
    check(clipped_pick && *clipped_pick == cluster_id, "visible part of offscreen extent is selectable");
    check(!pick_galaxy_spatial_row(model, clipped, {false, false, true, false}, -1, 300, 8),
          "click outside viewport is rejected");
    offscreen.target = {100 + axes.right.x * 150, axes.right.y * 150, axes.right.z * 150};
    const GalaxyProjector invisible(offscreen, 800, 600);
    const auto outside_far = galaxy_spatial_shape(model, cluster_id, invisible, false);
    check(outside_far && !outside_far->intersects_viewport(invisible), "fully outside extent is excluded");
    GalaxyCameraPc behind = camera;
    behind.target = {100 - axes.outward.x * 100, -axes.outward.y * 100, -axes.outward.z * 100};
    const GalaxyProjector near_plane(behind, 800, 600);
    check(!galaxy_spatial_shape(model, cluster_id, near_plane, false), "near-plane center has no projected shape");

    const GalaxySpatialShape enormous{{1e10 + 400, 300, 1}, 1e10, false};
    check(galaxy_spatial_requires_clipping(enormous, 1, 1), "huge ellipse uses viewport clipping");
    const auto pieces = galaxy_spatial_clip_circle(enormous, projector, 0.25, 100000);
    check(pieces.approximated && !pieces.budget_exhausted, "huge boundary is approximated within budget");
    const auto painted = [&](double x, double y) {
        return std::any_of(pieces.rectangles.begin(), pieces.rectangles.end(), [&](const auto& r) {
            return x >= r.x && x <= r.x + r.width && y >= r.y && y <= r.y + r.height;
        });
    };
    check(painted(600, 300) && !painted(200, 300), "clipping keeps the visible side of an offscreen circle");
    const auto limited = galaxy_spatial_clip_circle(enormous, projector, 0.25, 1);
    check(limited.approximated && limited.budget_exhausted, "clipping budget exhaustion is reported");
    const GalaxyProjector wide(camera, 3840, 2160);
    const GalaxySpatialShape wide_enormous{{1e10 + 1920, 1080, 1}, 1e10, false};
    const auto limited_wide = galaxy_spatial_clip_circle(wide_enormous, wide, 0.125, 1000);
    check(limited_wide.budget_exhausted && limited_wide.max_boundary_cell_diagonal < 100,
          "exhausted clipping budget is spread across the visible boundary");
    GalaxySpatialShape budget_shape = wide_enormous;
    budget_shape.clipping = galaxy_spatial_clip_circle(wide_enormous, wide, 0.125, 1);
    check(budget_shape.clipping->budget_exhausted && budget_shape.contains(100, 1080) &&
          !wide_enormous.contains(100, 1080),
          "exhausted shape selects the painted approximation instead of the original circle");
    check(budget_shape.contains(0, 0) && budget_shape.contains(3840, 2160) &&
          !budget_shape.contains(-1, 1080), "clipped rectangle boundaries are inclusive");
    budget_shape.clipping = GalaxySpatialClipResult{};
    check(!budget_shape.contains(3000, 1080) && !budget_shape.intersects_viewport(wide),
          "empty clipped shape never falls back to the original circle");
    std::size_t cancel_checks = 0;
    const auto cancelled_clip = galaxy_spatial_clip_circle(wide_enormous, wide, 0.015625, 100000,
        [&] { return ++cancel_checks == 3; });
    check(cancelled_clip.cancelled && cancelled_clip.rectangles.empty() && cancel_checks == 3,
          "clipping cancellation discards partial geometry within 256 processed cells");

    auto enormous_clusters = clusters;
    enormous_clusters.records[0].half_light_radius_pc = 1e9f;
    const GalaxySpatialModel enormous_model({enormous_clusters});
    const auto centered_shape = galaxy_spatial_shape(enormous_model, cluster_id, projector, false);
    check(centered_shape && centered_shape->clipping && centered_shape->clipping->rectangles.size() == 1 &&
          !centered_shape->clipping->approximated, "fully covering huge circle takes one rectangle");
    auto boundary_camera = camera;
    boundary_camera.vertical_fov_deg = 90;
    boundary_camera.pan(-1e9 * 10.8, 0, 3840, 2160);
    const GalaxyProjector boundary_projector(boundary_camera, 3840, 2160);
    const auto boundary_shape = galaxy_spatial_shape(enormous_model, cluster_id, boundary_projector, false);
    const auto boundary_preview = galaxy_spatial_shape(enormous_model, cluster_id, boundary_projector, true);
    check(boundary_shape && boundary_shape->clipping && boundary_preview && boundary_preview->clipping &&
          boundary_shape->clipping->budget_exhausted && boundary_preview->clipping->budget_exhausted,
          "production shape records exhausted budget in both display modes");
    check(boundary_shape->clipping->rectangles.size() == boundary_preview->clipping->rectangles.size(),
          "preview and complete reuse a scale-independent clipping contract");
    std::size_t pick_cancel_checks = 0;
    check(!pick_galaxy_spatial_row(enormous_model, boundary_projector, {}, 3000, 1080, 0,
              [&] { return ++pick_cancel_checks == 4; }) && pick_cancel_checks == 4,
          "pick returns immediately when clipping reports cancellation");
    const auto& rectangles = boundary_shape->clipping->rectangles;
    const auto sample_step = std::max<std::size_t>(1, rectangles.size() / 32);
    for (std::size_t index = 0; index < rectangles.size(); index += sample_step) {
        const auto& rectangle = rectangles[index];
        const double x = rectangle.x + rectangle.width / 2, y = rectangle.y + rectangle.height / 2;
        check(boundary_shape->contains(x, y) && boundary_preview->contains(x, y),
              "painted rectangle samples remain selectable after budget exhaustion");
    }
    auto tiny_clusters = clusters;
    tiny_clusters.records[0].half_light_radius_pc = 8e6f;
    const GalaxySpatialModel tiny_model({tiny_clusters});
    auto tiny_camera = camera;
    tiny_camera.vertical_fov_deg = 90;
    const GalaxyProjector tiny_projector(tiny_camera, 0.063, 1);
    const auto tiny_shape = galaxy_spatial_shape(tiny_model, cluster_id, tiny_projector, false);
    const double rounded_scale_x = std::ceil(0.063 * 16) / 0.063;
    check(tiny_shape && std::abs(tiny_shape->radius - 40000) < 1e-8 &&
          galaxy_spatial_requires_clipping(*tiny_shape, rounded_scale_x, 16) &&
          tiny_shape->clipping && tiny_shape->clipping->rectangles.size() == 1,
          "tiny viewport clips a radius unsafe after ceil raises the actual raster scale");
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
                const auto evaluate = [source](const auto& record) {
                    auto declination = record.declination_degrees;
                    if (source == 3 && declination >= 270 && declination < 360) declination -= 360;
                    return evaluate_galaxy_position_pc(record.right_ascension_degrees,
                        declination, record.distance_pc);
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
        identity_and_position_tests(); invalid_snapshot_tests(); pick_and_selection_tests(); projected_extent_tests();
        if (argc == 2) local_tests(argv[1]);
        std::cout << "Galaxy spatial scene: " << checks << " checks PASS\n";
    } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
}
