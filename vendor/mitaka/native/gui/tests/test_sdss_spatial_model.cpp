#include "sdss_spatial_model.hpp"

#include <algorithm>
#include <array>
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

template<class Exception = std::invalid_argument, class F>
void rejects(F action) {
    try { action(); }
    catch (const Exception&) { ++checks; return; }
    throw std::runtime_error("expected rejection");
}

SdssRecord record(double ra = 0, double dec = 0, float distance = 2, float value = -0.25F) {
    return {{ra, dec}, distance, value};
}

bool same_float(float a, float b) { return std::memcmp(&a, &b, sizeof(float)) == 0; }

void close(double actual, long double expected, double scale, const char* message) {
    check(std::isfinite(actual), "non-finite output");
    const long double tolerance = 32 * std::numeric_limits<double>::epsilon() * scale;
    check(std::abs(static_cast<long double>(actual) - expected) <= tolerance, message);
}

void check_position(const SdssRecord& raw, const SdssSpatialPositionPc& position) {
    // 既存変換関数を呼ばない long double の参照式。native 傾斜を明示する。
    const long double radians = std::acos(-1.0L) / 180;
    const long double ra = raw.coordinates.right_ascension_deg * radians;
    const long double dec = raw.coordinates.declination_deg * radians;
    const long double obliquity = (84381.448L / 3600) * radians;
    const long double distance = raw.distance_parsecs;
    const long double x = distance * std::cos(dec) * std::cos(ra);
    const long double y = distance * std::cos(dec) * std::sin(ra);
    const long double z = distance * std::sin(dec);
    close(position.equatorial.x_pc, x, raw.distance_parsecs, "equatorial x");
    close(position.equatorial.y_pc, y, raw.distance_parsecs, "equatorial y");
    close(position.equatorial.z_pc, z, raw.distance_parsecs, "equatorial z");
    close(position.native_ecliptic.x_pc, x, raw.distance_parsecs, "ecliptic x");
    close(position.native_ecliptic.y_pc, y * std::cos(obliquity) + z * std::sin(obliquity),
          raw.distance_parsecs, "ecliptic y");
    close(position.native_ecliptic.z_pc, z * std::cos(obliquity) - y * std::sin(obliquity),
          raw.distance_parsecs, "ecliptic z");
    close(std::hypot(position.native_ecliptic.x_pc, position.native_ecliptic.y_pc,
                     position.native_ecliptic.z_pc), distance, raw.distance_parsecs, "distance invariant");
}

void valid_and_identity_tests() {
    static_assert(!std::is_convertible_v<EquatorialPositionPc, Vec3>);
    static_assert(!std::is_convertible_v<NativeEclipticPositionPc, Vec3>);
    static_assert(!std::is_convertible_v<EquatorialPositionPc, NativeEclipticPositionPc>);
    static_assert(!std::is_move_constructible_v<SdssSpatialModel>);
    static_assert(!std::is_copy_assignable_v<SdssSpatialModel>);
    static_assert(!std::is_move_assignable_v<SdssSpatialModel>);
    const float greatest = std::numeric_limits<float>::max();
    const float smallest = std::numeric_limits<float>::denorm_min();
    std::vector<SdssRecord> input{
        record(), record(90, 0, 3), record(180, 0, 4), record(270, 0, 5),
        record(37, 90, 6), record(120, -90, 7), record(359.999999, -45, greatest),
        record(std::nextafter(360.0, 0.0), 0, smallest), record(135, 57, 0),
        record(0, 0, -0.0F), record(0, 0, 2, greatest), record(0, 0, 2, -greatest)};
    std::vector<SdssSpatialSource> sources{
        {SdssKind::galaxy, "empty-leading", {}},
        {SdssKind::galaxy, "local/custom catalog.dat", input},
        {SdssKind::galaxy, "empty-middle", {}},
        {SdssKind::quasar, "local/custom catalog.dat", {input[0], input[0]}},
        {SdssKind::quasar, "empty-trailing", {}}};
    const auto model = std::make_shared<const SdssSpatialModel>(sources);
    sources[1].records[0].distance_parsecs = 999;
    sources[1].path = "changed";
    check(model->sources()[1].path == "local/custom catalog.dat", "source path value ownership");
    check(model->record({1, 0}).distance_parsecs == 2, "record value ownership");
    const auto snapshot = evaluate_sdss_spatial_snapshot(model);
    check(snapshot->model == model, "model identity");
    check(snapshot->rows.size() == input.size() + 2, "all original rows");
    check(snapshot->completed_count == model->size() && snapshot->positioned_count == model->size(),
          "all valid positions");
    check(snapshot->invalid_count == 0 && snapshot->zero_distance_count == 2 && !snapshot->cancelled,
          "zero distances retained");
    for (std::size_t row = 0; row < model->size(); ++row) {
        const auto id = model->record_id(row);
        check(id.source_index == (row < input.size() ? 1U : 3U), "empty source identity mapping");
        check(id.ordinal == (row < input.size() ? row : row - input.size()), "original ordinal");
        check(model->row_index(id) == row, "record ID roundtrip");
        const auto& raw = model->record(id);
        const auto& result = snapshot->rows[row];
        check(result.position.has_value(), "valid row lost");
        check(!has_sdss_spatial_issue(result.issues, SdssSpatialIssue::not_evaluated), "completion flag");
        check_position(raw, *result.position);
    }
    check(same_float(model->record({1, 9}).distance_parsecs, -0.0F), "original negative zero lost");
    check(snapshot->rows[0].position->equatorial.x_pc == snapshot->rows[10].position->equatorial.x_pc &&
          snapshot->rows[0].position->equatorial.x_pc == snapshot->rows[11].position->equatorial.x_pc,
          "classification affected position");
    check(model->sources()[3].kind == SdssKind::quasar, "same path sources merged");
    const auto& north = snapshot->rows[4].position->native_ecliptic;
    const double legacy_y = 6 * std::sin(23.43870583 * std::acos(-1.0) / 180);
    check(std::abs(north.y_pc - legacy_y) > 1e-5, "native/official obliquity incorrectly conflated");
    rejects<std::out_of_range>([&] { (void)model->record_id(model->size()); });
    rejects<std::out_of_range>([&] { (void)model->record_id(std::numeric_limits<std::size_t>::max()); });
    rejects<std::out_of_range>([&] { (void)model->row_index({5, 0}); });
    rejects<std::out_of_range>([&] { (void)model->record({0, 0}); });
    rejects<std::out_of_range>([&] { (void)model->record({1, input.size()}); });
}

void invalid_tests() {
    const auto nan = std::numeric_limits<double>::quiet_NaN();
    const auto inf = std::numeric_limits<double>::infinity();
    const auto fnan = std::numeric_limits<float>::quiet_NaN();
    const auto finf = std::numeric_limits<float>::infinity();
    const std::vector<std::pair<SdssRecord, SdssSpatialIssue>> cases{
        {record(nan), SdssSpatialIssue::nonfinite_right_ascension},
        {record(inf), SdssSpatialIssue::nonfinite_right_ascension},
        {record(-inf), SdssSpatialIssue::nonfinite_right_ascension},
        {record(-0.001), SdssSpatialIssue::right_ascension_out_of_range},
        {record(360), SdssSpatialIssue::right_ascension_out_of_range},
        {record(0, nan), SdssSpatialIssue::nonfinite_declination},
        {record(0, inf), SdssSpatialIssue::nonfinite_declination},
        {record(0, std::nextafter(-90.0, -inf)), SdssSpatialIssue::declination_out_of_range},
        {record(0, std::nextafter(90.0, inf)), SdssSpatialIssue::declination_out_of_range},
        {record(0, 0, fnan), SdssSpatialIssue::nonfinite_distance},
        {record(0, 0, finf), SdssSpatialIssue::nonfinite_distance},
        {record(0, 0, -finf), SdssSpatialIssue::nonfinite_distance},
        {record(0, 0, -std::numeric_limits<float>::denorm_min()), SdssSpatialIssue::negative_distance},
        {record(0, 0, 1, fnan), SdssSpatialIssue::nonfinite_classification},
        {record(0, 0, 1, finf), SdssSpatialIssue::nonfinite_classification}};
    std::vector<SdssRecord> records;
    for (const auto& item : cases) records.push_back(item.first);
    records.push_back(record(nan, 91, -1, fnan));
    records.push_back(record(360, -91, 0, 0));
    const auto model = std::make_shared<const SdssSpatialModel>(
        std::vector<SdssSpatialSource>{{SdssKind::galaxy, "invalid local rows", records}});
    const auto snapshot = evaluate_sdss_spatial_snapshot(model);
    check(snapshot->rows.size() == records.size() && snapshot->completed_count == records.size(),
          "invalid rows dropped");
    check(snapshot->invalid_count == records.size() && snapshot->positioned_count == 0,
          "invalid counts");
    check(snapshot->zero_distance_count == 1, "invalid zero-distance row count");
    for (std::size_t row = 0; row < cases.size(); ++row) {
        check(!snapshot->rows[row].position, "invalid row positioned");
        check(snapshot->rows[row].issues == static_cast<SdssSpatialIssues>(cases[row].second),
              "wrong invalid reason");
        check(!sdss_spatial_issue_message(cases[row].second).empty(), "missing issue text");
        check(same_float(model->record({0, row}).distance_parsecs, records[row].distance_parsecs),
              "invalid original distance changed");
        check(same_float(model->record({0, row}).classification_value, records[row].classification_value),
              "invalid classification changed");
    }
    const auto combined = snapshot->rows[cases.size()].issues;
    for (const auto issue : {SdssSpatialIssue::nonfinite_right_ascension,
                            SdssSpatialIssue::declination_out_of_range,
                            SdssSpatialIssue::negative_distance,
                            SdssSpatialIssue::nonfinite_classification})
        check(has_sdss_spatial_issue(combined, issue), "combined reasons lost");
    check(has_sdss_spatial_issue(snapshot->rows.back().issues, SdssSpatialIssue::zero_distance),
          "zero distance reason lost");
    rejects([] { (void)sdss_spatial_issue_message(static_cast<SdssSpatialIssue>(3)); });
    rejects([] { (void)sdss_spatial_issue_message(static_cast<SdssSpatialIssue>(65535)); });
}

void empty_and_cancel_tests() {
    const auto empty = std::make_shared<const SdssSpatialModel>(std::vector<SdssSpatialSource>{});
    const auto empty_snapshot = evaluate_sdss_spatial_snapshot(empty);
    check(empty_snapshot->rows.empty() && !empty_snapshot->cancelled, "empty result");
    rejects<std::out_of_range>([&] { (void)empty->record_id(0); });
    rejects([] { (void)evaluate_sdss_spatial_snapshot(nullptr); });
    rejects([] { SdssSpatialModel model({{SdssKind::galaxy, {}, {}}}); });
    rejects([] { SdssSpatialModel model({{static_cast<SdssKind>(99), "a", {}}}); });
    std::vector<SdssRecord> records(4, record());
    const auto model = std::make_shared<const SdssSpatialModel>(std::vector<SdssSpatialSource>{
        {SdssKind::galaxy, "a", records}, {SdssKind::quasar, "b", records}});
    for (const std::size_t stop : {0U, 1U, 4U, 7U, 8U}) {
        std::size_t calls = 0;
        const auto snapshot = evaluate_sdss_spatial_snapshot(model, [&] { return calls++ == stop; });
        check(snapshot->completed_count == stop && snapshot->positioned_count == stop,
              "cancellation count");
        check(snapshot->rows.size() == model->size(), "cancellation removed rows");
        check(snapshot->cancelled == (stop < model->size()), "cancellation completion boundary");
        for (std::size_t i = 0; i < model->size(); ++i) {
            check(snapshot->rows[i].position.has_value() == (i < stop), "cancelled position state");
            check(has_sdss_spatial_issue(snapshot->rows[i].issues, SdssSpatialIssue::not_evaluated) ==
                  (i >= stop), "cancelled issue state");
        }
    }
    rejects<std::runtime_error>([&] {
        (void)evaluate_sdss_spatial_snapshot(model, []() -> bool { throw std::runtime_error("cancel callback"); });
    });
    check(evaluate_sdss_spatial_snapshot(model)->positioned_count == model->size(), "retry after cancel");
}

float raw_float(const char* bytes) {
    std::uint32_t bits = 0;
    for (unsigned i = 0; i < 4; ++i)
        bits |= static_cast<std::uint32_t>(static_cast<unsigned char>(bytes[i])) << (8 * i);
    float result;
    std::memcpy(&result, &bits, sizeof(result));
    return result;
}

void local_catalog_tests(const std::filesystem::path& directory) {
    std::vector<SdssSpatialSource> sources;
    for (const auto kind : {SdssKind::galaxy, SdssKind::quasar}) {
        const auto path = directory / (kind == SdssKind::galaxy ? "SDSS_GAL.dat" : "SDSS_QSO.dat");
        sources.push_back({kind, path, load_sdss_catalog(path, kind)});
    }
    const auto model = std::make_shared<const SdssSpatialModel>(std::move(sources));
    const auto snapshot = evaluate_sdss_spatial_snapshot(model);
    std::size_t flat = 0, zero = 0;
    for (std::size_t source_index = 0; source_index < model->sources().size(); ++source_index) {
        const auto& source = model->sources()[source_index];
        check(std::filesystem::file_size(source.path) / 16 == source.records.size(), "local file row count");
        std::ifstream file(source.path, std::ios::binary);
        check(static_cast<bool>(file), "cannot open local catalog");
        for (std::size_t ordinal = 0; ordinal < source.records.size(); ++ordinal, ++flat) {
            std::array<char, 16> bytes{};
            file.read(bytes.data(), bytes.size());
            check(static_cast<bool>(file), "local raw row missing");
            const auto& raw = model->record({source_index, ordinal});
            const auto id = model->record_id(flat);
            check(id.source_index == source_index && id.ordinal == ordinal, "local source/ordinal");
            check(raw.coordinates.right_ascension_deg == raw_float(bytes.data()) &&
                  raw.coordinates.declination_deg == raw_float(bytes.data() + 4), "local raw angles");
            check(same_float(raw.distance_parsecs, raw_float(bytes.data() + 8)) &&
                  same_float(raw.classification_value, raw_float(bytes.data() + 12)), "local raw values");
            const auto& row = snapshot->rows[flat];
            check(row.position.has_value(), "local position lost");
            check_position(raw, *row.position);
            const bool is_zero = raw.distance_parsecs == 0;
            zero += is_zero;
            check(has_sdss_spatial_issue(row.issues, SdssSpatialIssue::zero_distance) == is_zero,
                  "local zero reason");
        }
        check(file.peek() == std::char_traits<char>::eof(), "unread local bytes");
    }
    check(snapshot->completed_count == flat && snapshot->positioned_count == flat &&
          snapshot->invalid_count == 0 && !snapshot->cancelled, "local completion");
    check(snapshot->zero_distance_count == zero, "local zero count");
    std::cout << "Local SDSS/QSO rows: " << flat << ", zero distance: " << zero << '\n';
    std::cout << "Record storage bytes: " << flat * sizeof(SdssRecord)
              << ", snapshot row bytes: " << flat * sizeof(SdssSpatialRow) << '\n';
}
} // namespace

int main(int argc, char** argv) {
    try {
        if (argc > 2) throw std::invalid_argument("usage: test_sdss_spatial_model [data directory]");
        valid_and_identity_tests();
        invalid_tests();
        empty_and_cancel_tests();
        if (argc == 2) local_catalog_tests(argv[1]);
        std::cout << "SDSS spatial model tests passed: " << checks << " checks\n";
    } catch (const std::exception& error) {
        std::cerr << "FAIL: " << error.what() << '\n';
        return 1;
    }
}
