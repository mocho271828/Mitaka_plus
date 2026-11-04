#include "small_body_parser.hpp"

#include <algorithm>
#include <charconv>
#include <cmath>
#include <cstring>
#include <locale>
#include <map>
#include <sstream>

namespace mitaka::small_body_detail {
namespace {
constexpr double mean_motion_at_one_au = 0.985607669;

bool comment_or_empty(const std::string& text) {
    return text.empty() || text.front() == '#' || text.front() == '%';
}

template<class Bits> Bits little_endian(std::string_view bytes, std::size_t offset) {
    Bits result = 0;
    for (std::size_t i = 0; i < sizeof(Bits); ++i)
        result |= static_cast<Bits>(static_cast<unsigned char>(bytes[offset + i])) << (8*i);
    return result;
}

template<class Float, class Bits> Float floating(std::string_view bytes, std::size_t offset) {
    const Bits bits = little_endian<Bits>(bytes, offset);
    Float result;
    static_assert(sizeof result == sizeof bits);
    std::memcpy(&result, &bits, sizeof result);
    return result;
}

void require_orbit_numbers(const SmallBodySource& source, std::size_t offset,
                           double radius, double eccentricity) {
    if (!std::isfinite(radius) || radius <= 0 || eccentricity < 0)
        throw CatalogError(source.path, offset, "invalid orbit size or eccentricity");
}

std::optional<double> calendar_perihelion(const SmallBodySource& source, SmallBodyRecord& record,
                                         const std::string& text, std::size_t offset) {
    const double value = number(source, text, offset);
    record.perihelion_time_value = value;
    if (value < 15821015) {
        diagnostic(record, SmallBodyDiagnosticCode::unresolved_historical_calendar, "Tp",
                   "historical calendar and BCE year convention are unresolved");
        return std::nullopt;
    }
    // 年月日の桁を整数部から分離し、日未満は倍精度の大きな年月日値から引かない。
    const auto dot = text.find('.');
    const std::string whole = text.substr(0, dot);
    if (whole.size() != 8 || whole.find_first_not_of("0123456789") != std::string::npos)
        throw CatalogError(source.path, offset, "Tp must use YYYYMMDD.DDD calendar form");
    const int date = integer(source, whole, offset);
    const double fraction = dot == std::string::npos ? 0 : number(source, "0" + text.substr(dot), offset);
    if (fraction < 0 || fraction >= 1) throw CatalogError(source.path, offset, "invalid Tp day fraction");
    try { return julian_date({date/10000, date/100%100, date%100, 0, 0, 0}) + fraction; }
    catch (const std::invalid_argument& error) { throw CatalogError(source.path, offset, error.what()); }
    catch (const std::out_of_range& error) { throw CatalogError(source.path, offset, error.what()); }
}
} // namespace

std::optional<Line> LineReader::next() {
    if (offset_ == bytes_.size()) return std::nullopt;
    const std::size_t start = offset_;
    const auto newline = bytes_.find('\n', start);
    const std::size_t end = newline == std::string::npos ? bytes_.size() : newline;
    offset_ = newline == std::string::npos ? end : end + 1;
    const std::size_t content_end = end > start && bytes_[end-1] == '\r' ? end - 1 : end;
    return Line{std::string_view(bytes_).substr(start, content_end - start), start, offset_ - start};
}

std::string trim(std::string_view value) {
    const auto first = value.find_first_not_of(" \t\r\n");
    if (first == std::string_view::npos) return {};
    return std::string(value.substr(first, value.find_last_not_of(" \t\r\n") - first + 1));
}

double number(const SmallBodySource& source, std::string_view value, std::size_t offset) {
    std::istringstream stream(trim(value));
    stream.imbue(std::locale::classic());
    double result = 0;
    stream >> result;
    if (stream.fail() || !std::isfinite(result)) throw CatalogError(source.path, offset, "invalid finite numeric field");
    stream >> std::ws;
    if (!stream.eof()) throw CatalogError(source.path, offset, "trailing numeric field bytes");
    return result;
}

std::int32_t integer(const SmallBodySource& source, std::string_view value, std::size_t offset) {
    const std::string text = trim(value);
    std::int32_t result = 0;
    const auto parsed = std::from_chars(text.data(), text.data() + text.size(), result);
    if (parsed.ec != std::errc{} || parsed.ptr != text.data() + text.size())
        throw CatalogError(source.path, offset, "invalid int32 field");
    return result;
}

void diagnostic(SmallBodyRecord& r, SmallBodyDiagnosticCode code,
                const std::string& field, const std::string& message) {
    r.diagnostics.push_back({code, r.id.source_key, r.id.record_ordinal, field, message});
}

void unresolved(SmallBodyRecord& r) {
    diagnostic(r, SmallBodyDiagnosticCode::unresolved_frame, "frame", "source reference frame is unresolved");
    diagnostic(r, SmallBodyDiagnosticCode::unresolved_time_scale, "time_scale", "source time scale is unresolved");
}

std::vector<SmallBodyRecord> parse_packed(const SmallBodySource& source, SmallBodyKind kind,
                                         bool flagged, std::size_t max_records) {
    const std::size_t size = flagged ? 37 : 36;
    if (source.bytes.size() % size != 0) throw CatalogError(source.path, source.bytes.size(), "incomplete packed orbit record");
    const std::size_t count = source.bytes.size() / size;
    if (count > max_records) throw CatalogError(source.path, 0, "small-body record limit exceeded");
    std::vector<SmallBodyRecord> records;
    records.reserve(count);
    for (std::size_t index = 0; index < count; ++index) {
        SmallBodyRecord r;
        r.id = {source.key, index}; r.kind = kind;
        r.encoding = flagged ? SmallBodyEncoding::packed_37 : SmallBodyEncoding::packed_36;
        r.source_offset = index * size;
        r.raw_record_bytes = source.bytes.substr(r.source_offset, size);
        const auto bits = little_endian<std::uint32_t>(r.raw_record_bytes, 0);
        std::int32_t id;
        std::memcpy(&id, &bits, sizeof id);
        r.number = id;
        const std::size_t base = flagged ? 5 : 4;
        if (flagged) {
            r.raw_flag = static_cast<std::uint8_t>(r.raw_record_bytes[4]);
            diagnostic(r, SmallBodyDiagnosticCode::unknown_field, "raw_flag", "packed flag meaning is unresolved");
        }
        const double epoch = floating<double, std::uint64_t>(r.raw_record_bytes, base);
        double values[6];
        for (std::size_t field = 0; field < 6; ++field) {
            values[field] = floating<float, std::uint32_t>(r.raw_record_bytes, base + 8 + 4*field);
            if (!std::isfinite(values[field])) throw CatalogError(source.path, r.source_offset + base + 8 + 4*field, "non-finite packed orbit field");
        }
        if (!std::isfinite(epoch) || values[5] <= 0) throw CatalogError(source.path, r.source_offset, "invalid epoch or mean motion");
        const double a = std::pow(mean_motion_at_one_au / values[5], 2.0/3.0);
        require_orbit_numbers(source, r.source_offset, a, values[4]);
        r.epoch_value = epoch;
        r.orbit = OrbitalElements{epoch, a, values[4], values[0], values[5], values[2], values[3], values[1]};
        unresolved(r);
        records.push_back(std::move(r));
    }
    return records;
}

std::vector<SmallBodyRecord> parse_elements(const SmallBodySource& source, SmallBodyKind kind) {
    SmallBodyRecord r;
    r.id = {source.key, 0}; r.kind = kind; r.encoding = SmallBodyEncoding::element_text;
    r.raw_record_bytes = source.bytes;
    std::map<std::string, std::pair<std::string, std::size_t>> values;
    LineReader reader(source.bytes);
    while (const auto line = reader.next()) {
        const auto text = trim(line->text);
        if (comment_or_empty(text)) continue;
        const auto colon = text.find(':');
        if (colon == std::string::npos) throw CatalogError(source.path, line->offset, "missing element field separator");
        const auto key = trim(std::string_view(text).substr(0, colon));
        const auto value = trim(std::string_view(text).substr(colon + 1));
        if (key.empty() || !values.emplace(key, std::make_pair(value, line->offset)).second)
            throw CatalogError(source.path, line->offset, "empty or duplicate element field");
        r.fields.push_back({key, value});
    }
    auto field = [&](const std::string& key) -> const auto& {
        const auto found = values.find(key);
        if (found == values.end()) throw CatalogError(source.path, 0, "missing element field: " + key);
        return found->second;
    };
    auto numeric = [&](const std::string& key) { const auto& item = field(key); return number(source, item.first, item.second); };
    r.name_bytes = field("Name").first;
    if (values.count("DisplayName")) r.display_name_bytes = field("DisplayName").first;
    const double e = numeric("e"), w = numeric("w"), node = numeric("node"), i = numeric("i");
    if (kind == SmallBodyKind::comet) {
        require_orbit_numbers(source, 0, numeric("q"), e);
        r.perihelion_time_value = numeric("Tp");
        diagnostic(r, SmallBodyDiagnosticCode::unresolved_perihelion_time, "Tp",
                   "individual comet files use unresolved mixed perihelion time forms");
    } else {
        const auto type = field("Type").first;
        if (type != "Asteroid" && type != "TNObject") throw CatalogError(source.path, field("Type").second, "unknown small-body Type");
        r.kind = type == "TNObject" ? SmallBodyKind::trans_neptunian : SmallBodyKind::asteroid;
        r.number = integer(source, field("No").first, field("No").second);
        const double a = numeric("a"), epoch = numeric("Epoch");
        require_orbit_numbers(source, 0, a, e);
        r.epoch_value = epoch;
        r.orbit = OrbitalElements{epoch, a, e, numeric("M0"), mean_motion_at_one_au / a / std::sqrt(a), node, i, w};
    }
    const std::string interpreted = kind == SmallBodyKind::comet ? "|Name|DisplayName|q|e|w|node|i|Tp|" :
                                   "|Name|DisplayName|Type|No|a|e|w|node|i|Epoch|M0|";
    for (const auto& entry : r.fields) {
        if (interpreted.find("|" + entry.key + "|") == std::string::npos)
            diagnostic(r, SmallBodyDiagnosticCode::unknown_field, entry.key, "field retained without applying unresolved display semantics");
    }
    unresolved(r);
    return {std::move(r)};
}

std::vector<SmallBodyRecord> parse_comets(const SmallBodySource& source, std::size_t max_records) {
    std::vector<SmallBodyRecord> records;
    LineReader reader(source.bytes);
    while (const auto line = reader.next()) {
        if (comment_or_empty(trim(line->text))) continue;
        if (line->text.size() < 115) throw CatalogError(source.path, line->offset, "incomplete fixed-width comet row");
        if (records.size() == max_records) throw CatalogError(source.path, line->offset, "small-body record limit exceeded");
        SmallBodyRecord r;
        r.id = {source.key, records.size()}; r.kind = SmallBodyKind::comet;
        r.encoding = SmallBodyEncoding::comet_fixed_width;
        r.source_offset = line->offset;
        r.raw_record_bytes = source.bytes.substr(line->offset, line->byte_length);
        auto field = [&](const char* key, std::size_t start, std::size_t size) {
            const auto value = trim(line->text.substr(start, size));
            r.fields.push_back({key, value}); return value;
        };
        auto numeric = [&](const char* key, std::size_t start, std::size_t size) {
            return number(source, field(key, start, size), line->offset + start);
        };
        r.name_bytes = field("Name", 0, 38);
        if (r.name_bytes.empty()) throw CatalogError(source.path, line->offset, "empty comet name");
        r.epoch_value = numeric("Epoch", 39, 7);
        const double q = numeric("q", 47, 11), e = numeric("e", 59, 10);
        const double i = numeric("i", 70, 9), w = numeric("w", 80, 9), node = numeric("Node", 90, 9);
        require_orbit_numbers(source, line->offset, q, e);
        const auto tp = calendar_perihelion(source, r, field("Tp", 100, 14), line->offset + 100);
        field("Ref", 115, std::string_view::npos);
        r.frame = SmallBodyFrame::heliocentric_j2000_ecliptic;
        r.time_scale = SmallBodyTimeScale::tdb;
        if (tp) r.orbit = PerihelionElements{q, e, *tp, node, i, w};
        records.push_back(std::move(r));
    }
    return records;
}

void attach_names(const SmallBodySource& source, std::vector<SmallBodyRecord>& records) {
    std::map<std::int32_t, std::vector<std::string>> names;
    LineReader reader(source.bytes);
    while (const auto line = reader.next()) {
        const auto text = trim(line->text);
        if (comment_or_empty(text)) continue;
        const auto split = text.find_first_of(" \t");
        if (split == std::string::npos) throw CatalogError(source.path, line->offset, "missing small-body name");
        const auto id = integer(source, std::string_view(text).substr(0, split), line->offset);
        const auto name = trim(std::string_view(text).substr(split));
        if (name.empty()) throw CatalogError(source.path, line->offset, "empty small-body name");
        names[id].push_back(name);
    }
    // 全行検証後に付加し、不正な名称表からの部分的な更新を避ける。
    for (auto& r : records) {
        if (!r.number) continue;
        const auto found = names.find(*r.number);
        if (found != names.end()) r.alias_bytes = found->second;
    }
}
} // namespace mitaka::small_body_detail
