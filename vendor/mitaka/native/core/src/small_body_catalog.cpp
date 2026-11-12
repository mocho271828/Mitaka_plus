#include "mitaka/small_body_catalog.hpp"
#include "small_body_parser.hpp"

#include <algorithm>
#include <cmath>
#include <fstream>
#include <limits>
#include <sstream>

namespace mitaka {
namespace {
void read_source(SmallBodySource& source, CatalogLoadLimits limits) {
    std::ifstream stream(source.path, std::ios::binary | std::ios::ate);
    if (!stream) throw CatalogError(source.path, 0, "cannot open small-body source");
    const auto length = stream.tellg();
    if (length < 0 || static_cast<std::uint64_t>(length) > limits.max_file_bytes ||
        static_cast<std::uint64_t>(length) > static_cast<std::uint64_t>(std::numeric_limits<std::streamsize>::max()))
        throw CatalogError(source.path, 0, "small-body source exceeds byte limit");
    source.bytes.resize(static_cast<std::size_t>(length));
    stream.seekg(0);
    if (!stream.read(source.bytes.data(), length))
        throw CatalogError(source.path, 0, "cannot read complete small-body source");
}

void load_source(SmallBodyDataset& dataset, const std::filesystem::path& root,
                 const std::string& key, SmallBodyKind kind, SmallBodyEncoding encoding,
                 CatalogLoadLimits limits, bool names = false) {
    SmallBodySource source{key, root / key, {}, 0, false};
    try {
        read_source(source, limits);
        const auto remaining = limits.max_records - dataset.records.size();
        std::vector<SmallBodyRecord> records;
        if (names) small_body_detail::attach_names(source, dataset.records);
        else if (encoding == SmallBodyEncoding::element_text)
            records = small_body_detail::parse_elements(source, kind);
        else if (encoding == SmallBodyEncoding::comet_fixed_width)
            records = small_body_detail::parse_comets(source, remaining);
        else records = small_body_detail::parse_packed(source, kind,
                         encoding == SmallBodyEncoding::packed_37, remaining);
        if (records.size() > remaining) throw CatalogError(source.path, 0, "small-body record limit exceeded");
        source.record_count = records.size();
        dataset.records.insert(dataset.records.end(), std::make_move_iterator(records.begin()),
                               std::make_move_iterator(records.end()));
        source.loaded = true;
    } catch (const CatalogError& error) {
        std::error_code ec;
        const bool missing = !std::filesystem::exists(source.path, ec) && !ec;
        dataset.diagnostics.push_back({missing ? SmallBodyDiagnosticCode::missing_source :
                                                SmallBodyDiagnosticCode::invalid_source,
                                       key, std::nullopt, "source", error.what()});
    }
    dataset.sources.push_back(std::move(source));
}

void load_directory(SmallBodyDataset& dataset, const std::filesystem::path& root,
                    const std::string& key, SmallBodyKind kind, CatalogLoadLimits limits) {
    std::error_code ec;
    std::filesystem::directory_iterator cursor(root / key, ec), end;
    if (ec) {
        dataset.diagnostics.push_back({ec == std::errc::no_such_file_or_directory ?
                                       SmallBodyDiagnosticCode::missing_source : SmallBodyDiagnosticCode::invalid_source,
                                       key, std::nullopt, "directory", ec.message()});
        return;
    }
    std::vector<std::string> files;
    while (cursor != end) {
        const auto path = cursor->path();
        if (path.extension() == ".dat") files.push_back(key + "/" + path.filename().string());
        cursor.increment(ec);
        if (ec) {
            dataset.diagnostics.push_back({SmallBodyDiagnosticCode::invalid_source, key, std::nullopt,
                                           "directory", ec.message()});
            return;
        }
    }
    std::sort(files.begin(), files.end());
    for (const auto& file : files) load_source(dataset, root, file, kind, SmallBodyEncoding::element_text, limits);
}
} // namespace

SmallBodyDataset load_small_body_dataset(const std::filesystem::path& root, CatalogLoadLimits limits) {
    SmallBodyDataset result;
    load_source(result, root, "mp.dat", SmallBodyKind::asteroid, SmallBodyEncoding::packed_36, limits);
    load_source(result, root, "mp2.dat", SmallBodyKind::asteroid, SmallBodyEncoding::packed_37, limits);
    load_source(result, root, "TNO.dat", SmallBodyKind::trans_neptunian, SmallBodyEncoding::packed_36, limits);
    load_source(result, root, "TNO2.dat", SmallBodyKind::trans_neptunian, SmallBodyEncoding::packed_37, limits);
    load_source(result, root, "comets.dat", SmallBodyKind::comet, SmallBodyEncoding::comet_fixed_width, limits);
    load_directory(result, root, "orbits/asteroids", SmallBodyKind::asteroid, limits);
    load_directory(result, root, "orbits/comets", SmallBodyKind::comet, limits);
    load_source(result, root, "small_objects_name.dat", SmallBodyKind::asteroid,
                SmallBodyEncoding::element_text, limits, true);
    return result;
}

SmallBodyEvaluation evaluate_small_body(const SmallBodyRecord& record, double jd) {
    SmallBodyEvaluation result{std::nullopt, record.diagnostics};
    auto add = [&](SmallBodyDiagnosticCode code, const std::string& field, const std::string& message) {
        if (std::none_of(result.diagnostics.begin(), result.diagnostics.end(), [&](const auto& d) {
                return d.code == code && d.field == field;
            })) result.diagnostics.push_back({code, record.id.source_key, record.id.record_ordinal, field, message});
    };
    bool unavailable = false;
    // 面・時系の値だけで、未確認の追加 byte を持つ形式を評価可能にしない。
    if (record.encoding == SmallBodyEncoding::packed_37) {
        add(SmallBodyDiagnosticCode::invalid_source, "encoding", "packed_37 position contract is unresolved");
        unavailable = true;
    }
    if (!std::isfinite(jd)) { add(SmallBodyDiagnosticCode::invalid_time, "julian_date", "time must be finite"); unavailable = true; }
    if (record.frame != SmallBodyFrame::heliocentric_j2000_ecliptic) {
        add(SmallBodyDiagnosticCode::unresolved_frame, "frame", "source reference frame is unresolved"); unavailable = true;
    }
    if (record.time_scale != SmallBodyTimeScale::tdb) {
        add(SmallBodyDiagnosticCode::unresolved_time_scale, "time_scale", "source time scale is unresolved"); unavailable = true;
    }
    if (record.declared_time_range) {
        const auto range = *record.declared_time_range;
        if (!std::isfinite(range.first_jd) || !std::isfinite(range.last_jd) || range.first_jd > range.last_jd) {
            add(SmallBodyDiagnosticCode::invalid_time, "declared_time_range", "invalid declared time range"); unavailable = true;
        } else if (jd < range.first_jd || jd > range.last_jd) {
            add(SmallBodyDiagnosticCode::outside_time_range, "julian_date", "time is outside declared source range"); unavailable = true;
        }
    } else add(SmallBodyDiagnosticCode::unknown_accuracy_range, "declared_time_range",
               "two-body approximation; source accuracy interval is not declared");
    if (std::holds_alternative<std::monostate>(record.orbit)) {
        add(SmallBodyDiagnosticCode::unresolved_perihelion_time, "orbit", "source elements cannot be normalized"); unavailable = true;
    }
    if (unavailable) return result;
    try {
        if (const auto* elements = std::get_if<OrbitalElements>(&record.orbit)) result.state = orbital_state(*elements, jd);
        else result.state = perihelion_orbital_state(std::get<PerihelionElements>(record.orbit), jd);
    } catch (const std::invalid_argument& error) {
        add(SmallBodyDiagnosticCode::calculation_failed, "orbit", error.what());
    } catch (const std::out_of_range& error) {
        add(SmallBodyDiagnosticCode::calculation_failed, "orbit", error.what());
    } catch (const std::runtime_error& error) {
        add(SmallBodyDiagnosticCode::calculation_failed, "orbit", error.what());
    }
    return result;
}
} // namespace mitaka
