#import <Foundation/Foundation.h>
#include "small_body_model.hpp"
#include "mitaka/minor_planet_position.hpp"
#include <chrono>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
unsigned checks = 0;
void require(bool value, const char *message) { ++checks; if (!value) throw std::runtime_error(message); }
template<class Exception, class Function> void rejects(Function function, const char *message) {
    try { function(); } catch (const Exception&) { require(true, message); return; }
    require(false, message);
}
SmallBodyRecord comet(std::size_t ordinal) {
    SmallBodyRecord record;
    record.id = {"comets.dat", ordinal};
    record.kind = SmallBodyKind::comet;
    record.number = -1;
    record.name_bytes = "Duplicate comet";
    record.frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
    record.time_scale = SmallBodyTimeScale::tdb;
    record.orbit = PerihelionElements{1, 0.5, 2451545, 0, 0, 0};
    return record;
}
SmallBodyRecord packed(std::size_t ordinal, SmallBodyKind kind = SmallBodyKind::asteroid) {
    SmallBodyRecord record;
    record.id = {kind == SmallBodyKind::asteroid ? "mp.dat" : "TNO.dat", ordinal};
    record.kind = kind;
    record.number = -1;
    record.raw_record_bytes = std::string(36, '\0');
    record.orbit = OrbitalElements{2451545, 2, 0, 0, 90, 0, 0, 0};
    record.diagnostics = {{SmallBodyDiagnosticCode::unresolved_frame, record.id.source_key, ordinal, "frame", "raw frame unresolved"},
        {SmallBodyDiagnosticCode::unresolved_time_scale, record.id.source_key, ordinal, "time_scale", "raw physical time unresolved"}};
    return record;
}
void requirePosition(const std::optional<Vec3>& position, Vec3 expected, const char* message) {
    require(position && std::abs(position->x - expected.x) < 1e-12
        && std::abs(position->y - expected.y) < 1e-12 && std::abs(position->z - expected.z) < 1e-12, message);
}
void packedTests() {
    auto data = std::make_shared<SmallBodyDataset>();
    data->records = {comet(0), packed(0), packed(0, SmallBodyKind::trans_neptunian), packed(1), packed(2),
                     packed(3), packed(4), comet(1), packed(5), packed(1, SmallBodyKind::trans_neptunian)};
    auto& records = data->records;
    std::get<OrbitalElements>(records[2].orbit).semi_major_axis_au = 3;
    std::get<OrbitalElements>(records[2].orbit).mean_motion_deg_per_day = 45;
    records[3].encoding = SmallBodyEncoding::packed_37;
    records[3].raw_record_bytes.push_back('\0');
    records[3].raw_flag = 0;
    // 未確認の 37 byte を汎用 evaluator に迂回させない。
    records[3].frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
    records[3].time_scale = SmallBodyTimeScale::tdb;
    std::get<OrbitalElements>(records[4].orbit).mean_motion_deg_per_day = 0;
    records[5].declared_time_range = SmallBodyTimeRange{2451545, 2451546};
    records[6].raw_record_bytes.pop_back();
    records[7].time_scale = SmallBodyTimeScale::unresolved;
    records[8].encoding = SmallBodyEncoding::element_text;
    records[8].orbit = std::monostate{};
    records[8].frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
    records[8].time_scale = SmallBodyTimeScale::tdb;
    records[9].name_bytes = "duplicate id number";
    records[9].alias_bytes = {"tail alias"};
    data->sources.push_back({"mp.dat", {}, "source bytes unchanged", 6, true});
    auto model = std::make_shared<SmallBodyModel>(data);
    require(model->evaluation_mode(0) == SmallBodyEvaluationMode::comet_tdb, "comet keeps verified TDB evaluation mode");
    require(model->evaluation_mode(1) == SmallBodyEvaluationMode::packed36_legacy_jd
        && model->evaluation_mode(2) == SmallBodyEvaluationMode::packed36_legacy_jd, "36-byte asteroid and TNO use numeric JD mode");
    for (auto index : {3u, 7u, 8u})
        require(model->evaluation_mode(index) == SmallBodyEvaluationMode::unresolved, "unsupported row retains unresolved mode");
    rejects<std::out_of_range>([&] { model->evaluation_mode(10); }, "mode index bounds checked");
    const auto frame = evaluate_small_body_snapshot(model, 2451545);
    require(frame->positions.size() == records.size() && frame->positioned_count == 5, "mixed dataset retains all original rows");
    require(frame->julian_date == 2451545, "mixed snapshot has unchanged single numeric JD");
    requirePosition(frame->positions[0], {1, 0, 0}, "comet TDB result is unchanged");
    requirePosition(frame->positions[1], {2, 0, 0}, "packed circle has AU units without another rotation or Sun offset");
    requirePosition(frame->positions[2], {3, 0, 0}, "TNO source remains independent");
    for (auto index : {3u, 4u, 6u, 7u, 8u}) require(!frame->positions[index], "unsupported or invalid row has no invented position");
    const auto later = evaluate_small_body_snapshot(model, 2451546);
    requirePosition(later->positions[1], {0, 2, 0}, "packed mean motion advances once in days");
    requirePosition(later->positions[2], {3 / std::sqrt(2.0), 3 / std::sqrt(2.0), 0}, "TNO uses its own orbital elements");
    require(later->positions[5].has_value(), "declared final endpoint is inclusive");
    const auto outside = evaluate_small_body_snapshot(model, std::nextafter(2451546., 2451547.));
    require(!outside->positions[5] && outside->positions[1], "range rejection is per record and leaves other rows valid");
    require(small_body_description(*model, 5, outside.get()).find("outside the declared") != std::string::npos,
        "range diagnostic reaches row detail");
    const auto minorDetail = small_body_description(*model, 1, frame.get());
    require(minorDetail.find("原版の数値 JD") != std::string::npos && minorDetail.find("物理時系 UTC/TT/TDB は未確定") != std::string::npos,
        "successful packed row states numeric JD and physical time uncertainty");
    require(minorDetail.find("(TDB 入力") == std::string::npos && minorDetail.find("raw frame unresolved") == std::string::npos,
        "resolved packed frame is not contradicted or mislabeled as TDB");
    require(minorDetail.find("raw physical time unresolved") != std::string::npos, "physical time diagnostic is preserved");
    require(small_body_description(*model, 3, frame.get()).find("packed 37 byte · 原フラグ 0（意味未確定）")
        != std::string::npos && minorDetail.find("原フラグ") == std::string::npos,
        "show a zero raw flag on the 37-byte row, never on its 36-byte counterpart");
    require(small_body_description(*model, 0, frame.get()).find("(TDB 入力") != std::string::npos, "comet detail retains TDB label");
    require(small_body_description(*model, 4, frame.get()).find("requires a > 0") != std::string::npos, "invalid packed input retains evaluator diagnostic");
    require(records[1].frame == SmallBodyFrame::unresolved && records[1].time_scale == SmallBodyTimeScale::unresolved
        && records[1].diagnostics.size() == 2 && records[1].raw_record_bytes == std::string(36, '\0')
        && data->sources.front().bytes == "source bytes unchanged", "evaluation never rewrites original frame, time, diagnostics or bytes");
    require(model->search("-1", {}, 0, 100).total_matches == records.size(), "duplicate original numbers remain searchable");
    require(model->search("tail alias", SmallBodyKind::trans_neptunian, 0, 100).rows == std::vector<std::size_t>{9}, "last TNO alias remains searchable");
    const auto hidden = evaluate_small_body_snapshot(model, 2451545, false);
    require(hidden->positioned_count == 0 && hidden->diagnostics.empty(), "hidden unselected dataset performs no evaluations");
    require(small_body_description(*model, 1, hidden.get()).find("位置評価を省略") != std::string::npos, "skipped eligible packed row is stated");
    const auto selected = evaluate_small_body_snapshot(model, 2451546, false, 2);
    require(selected->positioned_count == 1 && selected->positions[2], "hidden view evaluates only selected TNO");
    const auto selectedUnknown = evaluate_small_body_snapshot(model, 2451546, false, 3);
    require(selectedUnknown->positioned_count == 0, "selecting unknown 37-byte row does not generate a position");
    const auto selectedInvalid = evaluate_small_body_snapshot(model, 2451546, false, 4);
    require(selectedInvalid->positioned_count == 0 && !selectedInvalid->diagnostics.empty(), "selected invalid packed input reports reason");
    auto replaced = std::make_shared<SmallBodyModel>(std::make_shared<SmallBodyDataset>(*data));
    require(small_body_description(*replaced, 1, frame.get()).find("位置未評価") != std::string::npos, "old snapshot is not attached to reloaded model");

    auto many = std::make_shared<SmallBodyDataset>();
    many->records.resize(10037, packed(0));
    for (std::size_t index = 0; index < many->records.size(); ++index) many->records[index].id.record_ordinal = index;
    auto large = std::make_shared<SmallBodyModel>(many);
    const auto all = evaluate_small_body_snapshot(large, 2451546);
    require(all->positions.size() == many->records.size() && all->positioned_count == many->records.size(), "custom packed rows are not truncated to public catalog size");
    for (std::size_t index = 0; index < all->positions.size(); ++index) {
        requirePosition(all->positions[index], {0, 2, 0}, "all same-number same-epoch original rows are evaluated");
        require(large->dataset().records[index].id.record_ordinal == index, "original duplicate row order is preserved");
    }
}
void individualTests() {
    auto data = std::make_shared<SmallBodyDataset>();
    auto text = packed(0);
    text.id = {"orbits/asteroids/custom.dat", 0};
    text.encoding = SmallBodyEncoding::element_text;
    text.name_bytes = "Independent text orbit";
    text.orbit = OrbitalElements{0, 1, 0, 0, 0.985607669, 0, 0, 0};
    text.raw_record_bytes = "original text bytes";
    text.fields = {{"Visible", "0"}, {"Size", "999 999 999"}};
    text.diagnostics.clear();
    data->records = {packed(0), text, text, text, text, packed(1), text};
    data->records[2].id.source_key = "orbits/asteroids/custom_jp.dat";
    data->records[2].kind = SmallBodyKind::trans_neptunian;
    data->records[2].display_name_bytes = "\x83\x65\x83\x58\x83\x67";
    data->records[3].id.source_key = "orbits/asteroids/explicit-n.dat";
    data->records[3].fields.push_back({"n", "90"});
    std::get<OrbitalElements>(data->records[3].orbit).semi_major_axis_au = 4;
    std::get<OrbitalElements>(data->records[3].orbit).mean_motion_deg_per_day = 90;
    data->records[6].id.source_key = "orbits/asteroids/inconsistent-n.dat";
    data->records[6].fields.push_back({"n", "1"});
    data->records[4].id.source_key = "orbits/asteroids/non-elliptic.dat";
    std::get<OrbitalElements>(data->records[4].orbit).eccentricity = 1;
    data->records[5].encoding = SmallBodyEncoding::packed_37;
    const auto model = std::make_shared<SmallBodyModel>(data);
    require(model->evaluation_mode(1) == SmallBodyEvaluationMode::element_text_legacy_jd,
        "individual format has its own numeric JD mode");
    const auto frame = evaluate_small_body_snapshot(model, 90 / 0.985607669);
    require(frame->positions.size() == 7 && frame->positioned_count == 4,
        "same-number packed and language variants remain independent; unsupported inputs are rejected");
    require(small_body_summary(*model) == "原本 7 件 · 位置評価候補（未対応を含む） 6 件 · 出典診断 0 件",
        "summary calls dispatch candidates candidates and does not count unresolved 37-byte input");
    requirePosition(frame->positions[1], {0, 1, 0}, "individual circle advances without extra units or frame conversion");
    requirePosition(frame->positions[2], {0, 1, 0}, "TNO language variant is independently evaluated");
    const auto explicitFrame = evaluate_small_body_snapshot(model, 1);
    requirePosition(explicitFrame->positions[3], {0, 4, 0}, "explicit mean motion drives the selected row position");
    require(!frame->positions[6] && small_body_description(*model, 6, frame.get()).find("explicit n") != std::string::npos,
        "inconsistent explicit n is explained in row detail");
    require(!frame->positions[4] && !frame->positions[5], "non-elliptic and unresolved 37-byte records do not produce positions");
    const auto detail = small_body_description(*model, 1, frame.get());
    require(detail.find("原版の数値 JD") != std::string::npos && detail.find("個別軌道") != std::string::npos
        && detail.find("(TDB 入力") == std::string::npos, "individual detail names its contract without certifying physical time");
    require(model->search("テスト", {}, 0, 100).rows == std::vector<std::size_t>{2},
        "individual Japanese name remains searchable");
    const auto hidden = evaluate_small_body_snapshot(model, 0, false);
    require(hidden->positioned_count == 0, "hidden individual rows skip evaluation");
    const auto selected = evaluate_small_body_snapshot(model, 0, false, 2);
    require(selected->positioned_count == 1 && selected->positions[2] && !selected->positions[1],
        "hidden selection evaluates only the exact source row");
    const auto selectedExplicit = evaluate_small_body_snapshot(model, 1, false, 3);
    require(selectedExplicit->positioned_count == 1 && !selectedExplicit->positions[1],
        "hidden selection evaluates only the explicit-n source row");
    requirePosition(selectedExplicit->positions[3], {0, 4, 0}, "hidden explicit-n selection keeps its mean motion");
    const auto selectedUnsupported = evaluate_small_body_snapshot(model, 0, false, 6);
    require(!selectedUnsupported->positions[6]
        && small_body_description(*model, 6, selectedUnsupported.get()).find("explicit n") != std::string::npos,
        "hidden selection retains the inconsistent-n diagnostic");
    require(data->records[1].raw_record_bytes == text.raw_record_bytes
        && data->records[1].frame == SmallBodyFrame::unresolved
        && data->records[1].time_scale == SmallBodyTimeScale::unresolved,
        "individual evaluation leaves bytes and source metadata unchanged");
}
void syntheticTests() {
    auto dataset = std::make_shared<SmallBodyDataset>();
    dataset->records = {comet(0), comet(1), comet(2)};
    dataset->records[1].display_name_bytes = "\x83\x65\x83\x58\x83\x67";
    dataset->records[1].alias_bytes = {"alias-last"};
    dataset->records[2].frame = SmallBodyFrame::unresolved;
    dataset->records[2].diagnostics.push_back({SmallBodyDiagnosticCode::unresolved_frame, "comets.dat", 2, "frame", "frame unresolved"});
    dataset->sources.push_back({"comets.dat", {}, "original bytes", 3, true});
    auto model = std::make_shared<SmallBodyModel>(dataset);
    require(model->dataset().records.size() == 3, "duplicate -1 numbers and epochs remain separate rows");
    require(model->dataset().sources.front().bytes == "original bytes", "source bytes remain unchanged");
    require(model->title(1) == "テスト", "CP932 names decode for display without rewriting source");
    require(model->search("テスト", {}, 0, 500).rows == std::vector<std::size_t>{1}, "Japanese names are searchable");
    require(model->search("ALIAS-LAST", {}, 0, 500).rows == std::vector<std::size_t>{1}, "aliases use case-insensitive search");
    require(model->search("-1", {}, 0, 500).total_matches == 3, "negative original numbers are searchable without merging");
    require(model->search("comets.dat", SmallBodyKind::asteroid, 0, 500).total_matches == 0, "kind filter is applied");
    auto page = model->search("", {}, 1, 1);
    require(page.total_matches == 3 && page.rows == std::vector<std::size_t>{1}, "pagination counts all matches and keeps source indices");
    require(model->search("", {}, 10, 1).rows.empty(), "page after end has no fabricated record");
    require(model->search("", {}, 0, 500, [] { return true; }).cancelled, "superseded search is cancelled");
    rejects<std::invalid_argument>([&] { model->search("", {}, 0, 0); }, "zero page size is rejected");
    auto frame = evaluate_small_body_snapshot(model, 2451545);
    require(frame->positions.size() == 3 && frame->positioned_count == 2, "unresolved rows retained without invented positions");
    require(frame->positions[0] && frame->positions[1] && !frame->positions[2], "same-number positions remain independent");
    require(std::abs(frame->positions[0]->x - 1) < 1e-12 && std::abs(frame->positions[0]->y) < 1e-12,
        "core heliocentric ecliptic AU position is not transformed again");
    require(small_body_description(*model, 2, frame.get()).find("frame unresolved") != std::string::npos, "unresolved diagnostic remains visible");
    require(small_body_description(*model, 0, frame.get()).find("精度保証期間は不明") != std::string::npos, "unknown accuracy range is stated");
    require(small_body_description(*model, 0, frame.get()).find("原番号 -1") != std::string::npos, "original sentinel number remains visible without renumbering");
    auto hidden = evaluate_small_body_snapshot(model, 2451546, false);
    require(hidden->positioned_count == 0 && hidden->positions.size() == 3, "hidden view skips calculations while retaining all rows");
    auto selected = evaluate_small_body_snapshot(model, 2451546, false, 1);
    require(selected->positioned_count == 1 && selected->positions[1] && !selected->positions[0], "hidden view evaluates only selected source row");
    require(std::abs(selected->positions[1]->y) > 0.001, "later JD updates selected position");
    rejects<std::out_of_range>([&] { evaluate_small_body_snapshot(model, 2451545, false, 3); }, "out-of-range selection rejected");
    rejects<std::invalid_argument>([&] { evaluate_small_body_snapshot(model, std::numeric_limits<double>::quiet_NaN()); }, "NaN time rejected");
    rejects<std::invalid_argument>([&] { evaluate_small_body_snapshot(model, std::numeric_limits<double>::infinity()); }, "infinite time rejected");
    rejects<std::invalid_argument>([] { SmallBodyModel model(nullptr); }, "null dataset rejected");
    auto many = std::make_shared<SmallBodyDataset>();
    many->records.resize(10037, dataset->records[2]);
    for (std::size_t i = 0; i < many->records.size(); ++i) many->records[i].id.record_ordinal = i;
    SmallBodyModel large(many);
    page = large.search("", {}, 10000, 500);
    require(page.total_matches == 10037 && page.rows.size() == 37 && page.rows.back() == 10036, "last source row remains reachable beyond page limit");
}
void localTests(const char *directory) {
    const auto start = std::chrono::steady_clock::now();
    auto dataset = std::make_shared<SmallBodyDataset>(load_small_body_dataset(directory));
    auto model = std::make_shared<SmallBodyModel>(dataset);
    require(model->search("", {}, 0, 500).total_matches == dataset->records.size(), "local search covers every retained source record");
    const auto frameStart = std::chrono::steady_clock::now();
    std::shared_ptr<const SmallBodySnapshot> frame;
    for (int step = 0; step < 30; ++step) frame = evaluate_small_body_snapshot(model, 2451545 + step);
    const double frameMs = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - frameStart).count() / 30;
    require(frame->positions.size() == dataset->records.size(), "local frame keeps original row cardinality");
    std::size_t expectedCount = 0, packedCount = 0, individualCount = 0, cometCount = 0;
    for (std::size_t index = 0; index < dataset->records.size(); ++index) {
        const auto& record = dataset->records[index];
        std::optional<Vec3> expected;
        if ((record.kind == SmallBodyKind::asteroid || record.kind == SmallBodyKind::trans_neptunian)
            && (record.encoding == SmallBodyEncoding::packed_36 || record.encoding == SmallBodyEncoding::element_text)) {
            expected = evaluate_minor_planet_position(record, frame->julian_date).heliocentric_j2000_ecliptic_au;
            if (expected) {
                if (record.encoding == SmallBodyEncoding::packed_36) ++packedCount;
                else ++individualCount;
            }
        } else if (record.kind == SmallBodyKind::comet && record.encoding != SmallBodyEncoding::packed_37) {
            const auto result = evaluate_small_body(record, frame->julian_date);
            if (result.state) { expected = result.state->position_au; ++cometCount; }
        }
        require(frame->positions[index].has_value() == expected.has_value(), "local eligible and unresolved rows match independent core evaluation");
        if (expected) { ++expectedCount; requirePosition(frame->positions[index], *expected, "local result uses core position without additional transform"); }
        if (record.encoding == SmallBodyEncoding::packed_37) require(!frame->positions[index], "all local 37-byte rows remain retained but unpositioned");
    }
    require(frame->positioned_count == expectedCount && expectedCount == packedCount + individualCount + cometCount,
        "local counts derive from actual records and contracts");
    if (!dataset->records.empty()) {
        auto last = model->search("", {}, dataset->records.size() - 1, 500);
        require(last.rows.size() == 1 && last.rows.front() == dataset->records.size() - 1, "last local row is reachable");
    }
    const auto hiddenStart = std::chrono::steady_clock::now();
    for (int step = 0; step < 30; ++step) (void)evaluate_small_body_snapshot(model, 2451545 + step, false);
    const double hiddenMs = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - hiddenStart).count() / 30;
    std::cout << "Local small bodies: records=" << dataset->records.size() << " evaluable=" << model->evaluable_indices().size()
        << " positioned=" << frame->positioned_count << " packed=" << packedCount << " individual=" << individualCount
        << " comets=" << cometCount << " frame_ms=" << frameMs << " hidden_ms=" << hiddenMs
        << " total_ms=" << std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count() << '\n';
}
}
int main(int argc, char **argv) {
    @autoreleasepool {
        try { syntheticTests(); packedTests(); individualTests(); if (argc > 1) localTests(argv[1]); std::cout << "Small-body model tests passed: " << checks << " checks\n"; return 0; }
        catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
