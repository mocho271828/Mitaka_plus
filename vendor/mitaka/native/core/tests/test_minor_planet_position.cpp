#include "mitaka/minor_planet_position.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstring>
#include <fstream>
#include <iostream>
#include <iterator>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using Code = SmallBodyDiagnosticCode;
int checks = 0;
void expect(bool value, const std::string& label) {
    ++checks;
    if (!value) throw std::runtime_error(label);
}
void near(double actual, double expected, double tolerance = 2e-13) {
    expect(std::isfinite(actual) && std::abs(actual - expected) <= tolerance, "position mismatch");
}
bool has(const MinorPlanetPositionEvaluation& result, Code code) {
    return std::any_of(result.diagnostics.begin(), result.diagnostics.end(),
        [=](const auto& item) { return item.code == code; });
}
void position(const MinorPlanetPositionEvaluation& result, Vec3 expected, double tolerance = 2e-13,
              std::string_view contract = minor_planet_packed_position_contract) {
    expect(result.heliocentric_j2000_ecliptic_au.has_value(), "position available");
    const auto actual = *result.heliocentric_j2000_ecliptic_au;
    near(actual.x, expected.x, tolerance); near(actual.y, expected.y, tolerance); near(actual.z, expected.z, tolerance);
    expect(result.contract == contract && result.status == MinorPlanetPositionStatus::success,
           "successful contract identified");
    expect(has(result, Code::unresolved_time_scale), "physical time uncertainty retained");
    expect(!has(result, Code::unresolved_frame), "dedicated contract resolves spatial frame");
}
void rejected(const MinorPlanetPositionEvaluation& result, Code code) {
    expect(!result.heliocentric_j2000_ecliptic_au && result.contract.empty(), "failure exposes no position or successful contract");
    expect(has(result, code), "typed rejection retained");
}
SmallBodyRecord record() {
    SmallBodyRecord result;
    result.id = {"mp.dat", 5};
    result.source_offset = 180;
    result.raw_record_bytes.assign(36, '\0');
    result.orbit = OrbitalElements{2451545, 2, 0, 0, 90, 0, 0, 0};
    result.diagnostics = {
        {Code::unresolved_frame, result.id.source_key, 5, "frame", "raw unresolved frame"},
        {Code::unresolved_time_scale, result.id.source_key, 5, "time_scale", "raw unresolved time"},
        {Code::unknown_field, result.id.source_key, 5, "custom", "preserved custom diagnostic"}
    };
    return result;
}
OrbitalElements& elements(SmallBodyRecord& item) { return std::get<OrbitalElements>(item.orbit); }

void analytic_geometry() {
    auto item = record();
    const double epoch = elements(item).epoch_jd;
    position(evaluate_minor_planet_position(item, epoch), {2, 0, 0});
    position(evaluate_minor_planet_position(item, epoch + 1), {0, 2, 0});
    position(evaluate_minor_planet_position(item, epoch + 2), {-2, 0, 0});
    position(evaluate_minor_planet_position(item, epoch + 4), {2, 0, 0});
    position(evaluate_minor_planet_position(item, epoch - 1), {0, -2, 0});
    elements(item).mean_anomaly_deg = 90;
    position(evaluate_minor_planet_position(item, epoch + 1), {-2, 0, 0});
    elements(item).mean_anomaly_deg = 0;
    elements(item).eccentricity = 0.5;
    position(evaluate_minor_planet_position(item, epoch), {1, 0, 0});
    position(evaluate_minor_planet_position(item, epoch + 2), {-3, 0, 0});
    // M = E - e sin(E) から既知 E を入力化し、解法を複製せず一般楕円を検証する。
    for (double e : {0.1, 0.7, 0.99, std::nextafter(1., 0.)}) {
        for (double eccentric_anomaly : {-2., -0.25, 0., 0.2, 1., 2.9}) {
            elements(item).eccentricity = e;
            elements(item).mean_anomaly_deg = (eccentric_anomaly - e*std::sin(eccentric_anomaly)) * 180 / std::acos(-1.);
            position(evaluate_minor_planet_position(item, epoch),
                {2*(std::cos(eccentric_anomaly)-e), 2*std::sqrt((1-e)*(1+e))*std::sin(eccentric_anomaly), 0}, 2e-12);
        }
    }
    item = record();
    elements(item).ascending_node_deg = 90;
    position(evaluate_minor_planet_position(item, epoch), {0, 2, 0});
    elements(item).ascending_node_deg = 0;
    elements(item).argument_of_periapsis_deg = 90;
    position(evaluate_minor_planet_position(item, epoch), {0, 2, 0});
    elements(item).inclination_deg = 90;
    position(evaluate_minor_planet_position(item, epoch), {0, 0, 2});
    // 一般角の期待値は各基本回転を順番に適用し、核の展開行列と独立に比較する。
    const double rad = std::acos(-1.) / 180;
    elements(item).argument_of_periapsis_deg = 31;
    elements(item).inclination_deg = 47;
    elements(item).ascending_node_deg = 83;
    const double x = 2*std::cos(31*rad), y = 2*std::sin(31*rad);
    const double inclined_y = y*std::cos(47*rad), inclined_z = y*std::sin(47*rad);
    position(evaluate_minor_planet_position(item, epoch),
        {x*std::cos(83*rad)-inclined_y*std::sin(83*rad), x*std::sin(83*rad)+inclined_y*std::cos(83*rad), inclined_z});
    item.kind = SmallBodyKind::trans_neptunian;
    expect(evaluate_minor_planet_position(item, epoch).heliocentric_j2000_ecliptic_au.has_value(), "TNO uses confirmed packed contract");
}

void invalid_and_unverified() {
    const auto base = record();
    for (double value : {std::numeric_limits<double>::quiet_NaN(), std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity()}) {
        rejected(evaluate_minor_planet_position(base, value), Code::invalid_time);
        const std::array<double OrbitalElements::*, 8> fields{
            &OrbitalElements::epoch_jd, &OrbitalElements::semi_major_axis_au, &OrbitalElements::eccentricity,
            &OrbitalElements::mean_anomaly_deg, &OrbitalElements::mean_motion_deg_per_day,
            &OrbitalElements::ascending_node_deg, &OrbitalElements::inclination_deg, &OrbitalElements::argument_of_periapsis_deg};
        for (auto field : fields) {
            auto item = base; elements(item).*field = value;
            rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_source);
        }
    }
    for (double value : {0., -1.}) {
        auto item = base; elements(item).semi_major_axis_au = value;
        rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_source);
        item = base; elements(item).mean_motion_deg_per_day = value;
        rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_source);
    }
    auto item = base; elements(item).eccentricity = -0.1;
    rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_source);
    for (double value : {1., std::nextafter(1., 2.), 2.}) {
        item = base; elements(item).eccentricity = value;
        rejected(evaluate_minor_planet_position(item, 2451545), Code::calculation_failed);
    }
    item = base; elements(item).mean_motion_deg_per_day = std::numeric_limits<double>::max();
    rejected(evaluate_minor_planet_position(item, 2451547), Code::calculation_failed);
    item = base; elements(item).epoch_jd = -std::numeric_limits<double>::max();
    rejected(evaluate_minor_planet_position(item, std::numeric_limits<double>::max()), Code::calculation_failed);
    for (auto encoding : {SmallBodyEncoding::packed_37, SmallBodyEncoding::comet_fixed_width}) {
        item = base; item.encoding = encoding;
        rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_source);
    }
    item = base; item.kind = SmallBodyKind::comet;
    rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_source);
    for (std::size_t length : {0U, 35U, 37U}) {
        item = base; item.raw_record_bytes.resize(length);
        rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_source);
    }
    item = base; item.raw_flag = 0;
    rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_source);
    item = base; item.orbit = std::monostate{};
    rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_source);
    item = base; item.orbit = PerihelionElements{1, 0.5, 2451545, 0, 0, 0};
    rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_source);
}

void periods_and_preservation() {
    auto item = record();
    auto result = evaluate_minor_planet_position(item, 2451545);
    expect(has(result, Code::unknown_accuracy_range) && has(result, Code::unknown_field), "unknown accuracy and independent diagnostics preserved");
    expect(result.id.source_key == item.id.source_key && result.id.record_ordinal == item.id.record_ordinal && result.legacy_julian_date == 2451545, "source ordinal and numeric JD retained");
    expect(item.frame == SmallBodyFrame::unresolved && item.time_scale == SmallBodyTimeScale::unresolved && item.diagnostics.size() == 3, "raw metadata never rewritten");
    expect(item.raw_record_bytes == std::string(36, '\0') && item.source_offset == 180, "raw bytes and offset unchanged");
    expect(std::count_if(result.diagnostics.begin(), result.diagnostics.end(), [](const auto& d) { return d.code == Code::unresolved_time_scale; }) == 1, "time diagnostic not duplicated");
    item.declared_time_range = SmallBodyTimeRange{2451545, 2451547};
    expect(!has(evaluate_minor_planet_position(item, 2451545), Code::unknown_accuracy_range), "declared interval recognized");
    position(evaluate_minor_planet_position(item, 2451545), {2, 0, 0});
    position(evaluate_minor_planet_position(item, 2451547), {-2, 0, 0});
    rejected(evaluate_minor_planet_position(item, std::nextafter(2451545., 0.)), Code::outside_time_range);
    rejected(evaluate_minor_planet_position(item, std::nextafter(2451547., 3e6)), Code::outside_time_range);
    for (auto range : {SmallBodyTimeRange{2, 1}, SmallBodyTimeRange{NAN, 3}, SmallBodyTimeRange{1, INFINITY}}) {
        item.declared_time_range = range;
        rejected(evaluate_minor_planet_position(item, 2451545), Code::invalid_time);
    }
}

struct Fixture {
    std::filesystem::path root = std::filesystem::temp_directory_path() /
        ("mitaka-minor-position-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count()));
    Fixture() { std::filesystem::create_directories(root); }
    ~Fixture() { std::error_code ec; std::filesystem::remove_all(root, ec); }
    void write(const std::string& name, const std::string& bytes) const {
        std::filesystem::create_directories((root/name).parent_path());
        std::ofstream out(root/name, std::ios::binary); out.write(bytes.data(), static_cast<std::streamsize>(bytes.size()));
        if (!out) throw std::runtime_error("fixture write failed");
    }
};
template<class Bits> void append_bits(std::string& bytes, Bits value) {
    for (std::size_t i = 0; i < sizeof value; ++i) bytes.push_back(static_cast<char>((value >> (8*i)) & 255));
}
template<class Float, class Bits> void append_float(std::string& bytes, Float value) {
    Bits bits; static_assert(sizeof bits == sizeof value);
    std::memcpy(&bits, &value, sizeof bits); append_bits(bytes, bits);
}
std::string packed(std::int32_t number, float mean_anomaly, float motion, bool flag = false) {
    std::string bytes; append_bits(bytes, static_cast<std::uint32_t>(number));
    if (flag) bytes.push_back(static_cast<char>(255));
    append_float<double, std::uint64_t>(bytes, 2451545.25);
    for (float value : {mean_anomaly, 0.F, 0.F, 0.F, 0.F, motion}) append_float<float, std::uint32_t>(bytes, value);
    return bytes;
}
const SmallBodySource& source(const SmallBodyDataset& data, const std::string& key) {
    const auto found = std::find_if(data.sources.begin(), data.sources.end(), [&](const auto& s) { return s.key == key; });
    if (found == data.sources.end()) throw std::runtime_error("source absent");
    return *found;
}
void loaded_custom_records() {
    Fixture fixture;
    const auto bytes = packed(-1, 30.F, 0.2F);
    const auto flagged = packed(-1, 30.F, 0.2F, true);
    // 元番号 -1 と同一 bytes が繰り返されても、独自追加行を ordinal ごとに保持する。
    std::string many;
    for (int i = 0; i < 10037; ++i) many += bytes;
    fixture.write("mp.dat", many); fixture.write("mp2.dat", flagged);
    fixture.write("TNO.dat", bytes); fixture.write("TNO2.dat", flagged);
    const auto data = load_small_body_dataset(fixture.root);
    expect(data.records.size() == 10040, "custom count has no historical fixed limit");
    std::size_t success = 0, rejected_flag = 0;
    for (const auto& item : data.records) {
        const auto result = evaluate_minor_planet_position(item, 2451545.25);
        expect(item.raw_record_bytes == source(data, item.id.source_key).bytes.substr(item.source_offset, item.raw_record_bytes.size()), "all raw record slices retained");
        if (item.encoding == SmallBodyEncoding::packed_36) {
            const double radius = std::pow(0.985607669 / double(0.2F), 2./3.);
            position(result, {radius*std::sqrt(3.)/2, radius/2, 0});
            expect(std::get<OrbitalElements>(item.orbit).semi_major_axis_au == radius, "packed a remains binary64 without intermediate float");
            ++success;
        } else {
            rejected(result, Code::invalid_source); ++rejected_flag;
            auto projection = item.raw_record_bytes; projection.erase(4, 1);
            expect(projection == bytes, "exact 36-byte correspondence still does not authorize 37-byte evaluation");
        }
    }
    expect(success == 10038 && rejected_flag == 2, "each original row classified independently");
    fixture.write("mp.dat", packed(99, 0.F, 1.F));
    expect(source(data, "mp.dat").bytes == many && data.records.front().raw_record_bytes == bytes, "loaded snapshot retains original after file changes");
}

void loaded_element_records() {
    Fixture fixture;
    const std::string body = "Name: Custom\r\nNo: -1\r\nEpoch: 2451545.25\r\na: 4\r\ne: 0\r\n"
                             "M0: 0\r\nw: 0\r\nnode: 0\r\ni: 0\r\nVisible: 0\r\nSize: 1 2 3\r\n";
    const auto asteroid = "Type: Asteroid\r\n" + body;
    fixture.write("orbits/asteroids/a.dat", asteroid);
    fixture.write("orbits/asteroids/a_jp.dat", asteroid + "DisplayName: \x83\x5a\x83\x8c\x83\x58\r\n");
    fixture.write("orbits/asteroids/tno.dat", "Type: TNObject\r\n" + body);
    fixture.write("orbits/asteroids/explicit-n.dat", asteroid + "n: 90\r\n");
    const auto data = load_small_body_dataset(fixture.root);
    expect(data.records.size() == 4, "individual and language source rows are never merged by number");
    for (const auto& item : data.records) {
        const auto original = item.raw_record_bytes;
        expect(original == source(data, item.id.source_key).bytes && item.id.record_ordinal == 0
               && item.number == -1, "individual source bytes and identity retained");
        const auto& orbit = std::get<OrbitalElements>(item.orbit);
        near(orbit.mean_motion_deg_per_day, 0.123200958625, 0);
        expect(orbit.epoch_jd == 2451545.25, "individual Epoch remains numeric JD");
        if (item.id.source_key == "orbits/asteroids/explicit-n.dat") {
            rejected(evaluate_minor_planet_position(item, orbit.epoch_jd), Code::invalid_source);
            expect(has(evaluate_minor_planet_position(item, orbit.epoch_jd), Code::unknown_field),
                   "unresolved explicit motion field remains diagnosed");
            continue;
        }
        const double period = 360 / orbit.mean_motion_deg_per_day;
        for (int quarter = -1; quarter <= 4; ++quarter) {
            const Vec3 expected[]{{4,0,0},{0,4,0},{-4,0,0},{0,-4,0}};
            position(evaluate_minor_planet_position(item, orbit.epoch_jd + quarter * period / 4),
                     expected[(quarter + 4) % 4], 2e-11, minor_planet_element_position_contract);
        }
        auto rotated = item;
        elements(rotated).inclination_deg = 90;
        elements(rotated).argument_of_periapsis_deg = 90;
        position(evaluate_minor_planet_position(rotated, orbit.epoch_jd), {0,0,4}, 2e-13,
                 minor_planet_element_position_contract);
        for (double eccentricity : {0.5, std::nextafter(1., 0.)}) {
            auto changed = item; elements(changed).eccentricity = eccentricity;
            position(evaluate_minor_planet_position(changed, orbit.epoch_jd), {4*(1-eccentricity),0,0},
                     2e-13, minor_planet_element_position_contract);
        }
        for (double eccentricity : {1., std::nextafter(1., 2.)}) {
            auto changed = item; elements(changed).eccentricity = eccentricity;
            rejected(evaluate_minor_planet_position(changed, orbit.epoch_jd), Code::calculation_failed);
        }
        for (int invalid = 0; invalid < 3; ++invalid) {
            auto changed = item;
            if (invalid == 0) changed.raw_record_bytes.clear();
            if (invalid == 1) changed.raw_flag = 0;
            if (invalid == 2) changed.kind = SmallBodyKind::comet;
            rejected(evaluate_minor_planet_position(changed, orbit.epoch_jd), Code::invalid_source);
        }
        expect(item.raw_record_bytes == original && item.frame == SmallBodyFrame::unresolved
               && item.time_scale == SmallBodyTimeScale::unresolved,
               "successful individual evaluation never rewrites unresolved source metadata");
        expect(has(evaluate_minor_planet_position(item, orbit.epoch_jd), Code::unknown_field),
               "unknown display fields do not prevent position or acquire inferred semantics");
    }
}

void real_data(const std::filesystem::path& directory) {
    expect(std::filesystem::is_directory(directory), "real data directory exists");
    const auto data = load_small_body_dataset(directory);
    std::size_t candidates = 0, individual = 0, evaluated = 0, retained_other = 0;
    for (const auto& item : data.records) {
        const auto& original = source(data, item.id.source_key);
        expect(original.bytes.substr(item.source_offset, item.raw_record_bytes.size()) == item.raw_record_bytes, "real bytes unchanged");
        const auto result = evaluate_minor_planet_position(item, 2451545);
        expect(result.id.source_key == item.id.source_key && result.id.record_ordinal == item.id.record_ordinal, "real source/ordinal unchanged");
        const bool text = item.encoding == SmallBodyEncoding::element_text
            && item.kind != SmallBodyKind::comet;
        if (item.encoding != SmallBodyEncoding::packed_36 && !text) {
            rejected(result, Code::invalid_source); ++retained_other; continue;
        }
        ++candidates;
        if (text) ++individual;
        const auto* orbit = std::get_if<OrbitalElements>(&item.orbit);
        expect(orbit != nullptr, "parsed eligible row has elements");
        if (orbit->eccentricity >= 1) { rejected(result, Code::calculation_failed); continue; }
        expect(result.heliocentric_j2000_ecliptic_au.has_value(), "valid real ellipse evaluated");
        expect(result.contract == (text ? minor_planet_element_position_contract
                                       : minor_planet_packed_position_contract), "real encoding contract identified");
        ++evaluated;
        for (double jd : {orbit->epoch_jd, orbit->epoch_jd-123.5, orbit->epoch_jd+123.5}) {
            const auto at = evaluate_minor_planet_position(item, jd);
            expect(at.heliocentric_j2000_ecliptic_au.has_value(), "real ellipse numeric JD evaluated");
            const auto point = *at.heliocentric_j2000_ecliptic_au;
            const double radius = std::hypot(point.x, std::hypot(point.y, point.z));
            const double tolerance = 2e-12*orbit->semi_major_axis_au;
            expect(radius >= orbit->semi_major_axis_au*(1-orbit->eccentricity)-tolerance && radius <= orbit->semi_major_axis_au*(1+orbit->eccentricity)+tolerance, "real ellipse remains in perihelion/aphelion bounds");
            expect(has(at, Code::unresolved_time_scale) && has(at, Code::unknown_accuracy_range), "real uncertainty retained after success");
        }
        expect(item.frame == SmallBodyFrame::unresolved && item.time_scale == SmallBodyTimeScale::unresolved, "real raw unresolved metadata unchanged");
    }
    expect(candidates + retained_other == data.records.size(), "all actual input rows classified without fixed counts");
    for (const auto& original : data.sources) {
        if (!original.loaded) continue;
        std::ifstream input(original.path, std::ios::binary);
        const std::string bytes{std::istreambuf_iterator<char>(input), std::istreambuf_iterator<char>()};
        expect(bytes == original.bytes, "real original source remains unchanged");
    }
    std::cout << "minor-planet real data: sources=" << data.sources.size() << " source diagnostics=" << data.diagnostics.size()
              << " records=" << data.records.size() << " packed36=" << candidates-individual << " individual=" << individual
              << " evaluated=" << evaluated << " other retained=" << retained_other << '\n';
}
} // namespace

int main(int argc, char** argv) {
    try {
        analytic_geometry(); invalid_and_unverified(); periods_and_preservation(); loaded_custom_records(); loaded_element_records();
        for (int i = 1; i < argc; ++i) real_data(argv[i]);
        std::cout << "minor-planet position: " << checks << " checks passed\n";
    } catch (const std::exception& error) {
        std::cerr << "minor-planet position failure: " << error.what() << '\n'; return 1;
    }
}
