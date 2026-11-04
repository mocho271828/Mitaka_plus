#include "satellite_catalog_internal.hpp"

#include <algorithm>
#include <cmath>
#include <locale>
#include <sstream>
#include <unordered_set>

namespace mitaka::satellite_detail {
namespace {

std::string_view trim(std::string_view value) {
    const auto begin = value.find_first_not_of(" \t\r");
    if (begin == std::string_view::npos) return {};
    return value.substr(begin, value.find_last_not_of(" \t\r") - begin + 1);
}

bool identifier(std::string_view value) {
    return !value.empty() && std::all_of(value.begin(), value.end(), [](unsigned char c) {
        return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
               (c >= '0' && c <= '9') || c == '_';
    });
}

bool listed(std::string_view key, std::initializer_list<std::string_view> keys) {
    return std::find(keys.begin(), keys.end(), key) != keys.end();
}

SatelliteDefinitionKind definition_kind(std::string_view name) {
    if (name == "Ssystem") return SatelliteDefinitionKind::system;
    if (name == "Sun") return SatelliteDefinitionKind::sun;
    if (name == "Planet") return SatelliteDefinitionKind::planet;
    if (name == "Satellite") return SatelliteDefinitionKind::satellite;
    return SatelliteDefinitionKind::unknown;
}

struct Line {
    std::string_view text;
    std::uint64_t offset = 0;
    std::uint64_t size = 0;
    std::size_t number = 0;
};

class Parser {
public:
    Parser(const SatelliteSource& source, const SatelliteLoadLimits& limits,
           std::size_t records, std::size_t fields)
        : source_(source), limits_(limits), remaining_records_(records), remaining_fields_(fields) {}

    ParsedSource parse() {
        std::size_t offset = 0, number = 0;
        while (offset < source_.bytes.size()) {
            const auto end = source_.bytes.find('\n', offset);
            const auto next = end == std::string::npos ? source_.bytes.size() : end + 1;
            Line line{std::string_view(source_.bytes).substr(offset, next - offset),
                      offset, next - offset, ++number};
            offset = next;
            if (line.size > limits_.max_line_bytes) fail(line, "line byte limit exceeded");
            if (line.text.find('\0') != std::string_view::npos) fail(line, "NUL byte in text");
            if (!line.text.empty() && line.text.back() == '\n') line.text.remove_suffix(1);
            line.text = trim(line.text);
            if (line.text.empty() || line.text.front() == '#') continue;
            if (source_.kind == SatelliteSourceKind::orbit) orbit_line(line);
            else definition_line(line);
        }
        if (pending_ || !stack_.empty()) {
            fail(Line{{}, source_.bytes.size(), 0, number + 1}, "unclosed definition block");
        }
        return std::move(result_);
    }

private:
    [[noreturn]] void fail(const Line& line, const std::string& reason) const {
        throw CatalogError(source_.path, line.offset,
                           "line " + std::to_string(line.number) + ": " + reason);
    }

    void diagnose(SatelliteDiagnosticCode code, const Line& line, std::size_t ordinal,
                  const std::string& key, const std::string& message, bool invalid = false) {
        result_.diagnostics.push_back({code, source_.key, ordinal, line.offset, line.number,
                                       key, message});
        if (invalid) result_.valid = false;
    }

    SatelliteField parse_field(const Line& line, std::size_t ordinal) {
        const auto colon = line.text.find(':');
        if (colon == std::string_view::npos) fail(line, "expected key: value");
        const auto key = trim(line.text.substr(0, colon));
        if (!identifier(key)) fail(line, "invalid field key");
        if (result_.field_count >= remaining_fields_) fail(line, "total field limit exceeded");
        ++result_.field_count;
        SatelliteField field{std::string(key), std::string(trim(line.text.substr(colon + 1))),
                             line.offset, line.size, line.number, std::nullopt};
        if (!field_keys_[ordinal].insert(field.key).second) {
            diagnose(SatelliteDiagnosticCode::duplicate_field, line, ordinal, field.key,
                     "duplicate field retained; unique value is unresolved", true);
        }
        const bool orbit = source_.kind == SatelliteSourceKind::orbit;
        const bool numeric = orbit
            ? listed(key, {"Epoch", "a", "e", "w", "M0", "i", "node", "n", "P", "Pw", "Pnode", "RA", "Decl", "T", "L"})
            : listed(key, {"Radius", "Magnitude", "Color", "Visible", "Ring"});
        const bool known = numeric || (orbit ? listed(key, {"Planet", "RefPlane"})
                                            : listed(key, {"Name", "Orbit", "Texture", "RingTexture"}));
        if (!known) diagnose(SatelliteDiagnosticCode::unknown_field, line, ordinal, field.key,
                             "unknown field retained without interpretation");
        if (numeric) {
            std::istringstream input(field.value_bytes);
            input.imbue(std::locale::classic());
            std::vector<double> numbers;
            std::string token;
            bool valid = true;
            while (input >> token) {
                std::istringstream number(token);
                number.imbue(std::locale::classic());
                double value = 0;
                if (!(number >> value) || !std::isfinite(value) || !(number >> std::ws).eof()) {
                    valid = false;
                    break;
                }
                numbers.push_back(value);
            }
            const bool scalar = orbit || listed(key, {"Magnitude", "Visible"});
            if (!valid || numbers.empty() || (scalar && numbers.size() != 1)) {
                diagnose(SatelliteDiagnosticCode::invalid_number, line, ordinal, field.key,
                         "expected finite numeric value(s); original bytes retained", true);
            } else field.numbers = std::move(numbers);
        }
        if (orbit && key == "RefPlane" && !listed(field.value_bytes, {"L", "E", "Q", "C", "I"})) {
            diagnose(SatelliteDiagnosticCode::unresolved_reference_plane, line, ordinal, field.key,
                     "unrecognized reference plane retained without fallback");
        }
        return field;
    }

    void orbit_line(const Line& line) {
        if (result_.orbits.empty()) {
            if (!remaining_records_) fail(line, "total record limit exceeded");
            result_.orbits.push_back({{source_.key, 0}, {}});
            field_keys_.emplace_back();
        }
        auto& fields = result_.orbits.front().fields;
        fields.push_back(parse_field(line, 0));
    }

    void definition_line(const Line& line) {
        if (line.text == "{") {
            if (!pending_) fail(line, "opening brace without block name");
            if (stack_.size() >= limits_.max_block_depth) fail(line, "block depth limit exceeded");
            if (result_.definitions.size() >= remaining_records_) fail(line, "total record limit exceeded");
            const auto ordinal = result_.definitions.size();
            const auto kind = definition_kind(pending_->text);
            result_.definitions.push_back({{source_.key, ordinal}, kind, std::string(pending_->text),
                stack_.empty() ? std::nullopt : std::optional<std::size_t>(stack_.back()),
                pending_->offset, 0, pending_->number, {}, std::nullopt, std::nullopt});
            field_keys_.emplace_back();
            if (kind == SatelliteDefinitionKind::unknown) {
                diagnose(SatelliteDiagnosticCode::unknown_block, *pending_, ordinal, {},
                         "unknown block retained without interpretation");
            }
            stack_.push_back(ordinal);
            pending_.reset();
            return;
        }
        if (line.text == "}") {
            if (pending_ || stack_.empty()) fail(line, "unmatched closing brace");
            auto& record = result_.definitions[stack_.back()];
            record.source_size = line.offset + line.size - record.source_offset;
            stack_.pop_back();
            return;
        }
        if (pending_) fail(line, "expected opening brace after block name");
        if (line.text.find(':') != std::string_view::npos) {
            if (stack_.empty()) fail(line, "field outside definition block");
            auto& record = result_.definitions[stack_.back()];
            record.fields.push_back(parse_field(line, record.id.record_ordinal));
            return;
        }
        if (!identifier(line.text)) fail(line, "unsupported block syntax");
        pending_ = line;
    }

    const SatelliteSource& source_;
    const SatelliteLoadLimits& limits_;
    std::size_t remaining_records_, remaining_fields_;
    ParsedSource result_;
    std::vector<std::size_t> stack_;
    std::vector<std::unordered_set<std::string>> field_keys_;
    std::optional<Line> pending_;
};

} // namespace

ParsedSource parse_source(const SatelliteSource& source, const SatelliteLoadLimits& limits,
                          std::size_t remaining_records, std::size_t remaining_fields) {
    return Parser(source, limits, remaining_records, remaining_fields).parse();
}

} // namespace mitaka::satellite_detail
