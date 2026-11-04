#include "spacecraft_trajectory_internal.hpp"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <locale>
#include <set>
#include <sstream>

namespace mitaka {

const SpacecraftField* unique_spacecraft_field(const SpacecraftDefinition& definition,
    std::string_view key, std::string_view section) noexcept {
    const SpacecraftField* found = nullptr;
    for (const auto& field : definition.fields) {
        if (field.key != key || field.section_bytes != section) continue;
        if (found) return nullptr;
        found = &field;
    }
    return found;
}

namespace spacecraft_detail {
namespace {
std::string trim(std::string_view value) {
    const auto first = value.find_first_not_of(" \t\r");
    if (first == std::string_view::npos) return {};
    return std::string(value.substr(first, value.find_last_not_of(" \t\r") - first + 1));
}

double real(const SpacecraftSource& source, std::size_t offset) {
    std::uint64_t bits = 0;
    for (std::size_t i = 0; i < sizeof bits; ++i)
        bits |= static_cast<std::uint64_t>(static_cast<unsigned char>(source.bytes[offset + i])) << (8*i);
    double value;
    static_assert(sizeof value == sizeof bits);
    std::memcpy(&value, &bits, sizeof value);
    if (!std::isfinite(value)) throw CatalogError(source.path, offset, "non-finite PTH field");
    return value;
}
} // namespace

std::string ascii_lower(std::string text) {
    for (char& value : text) if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
    return text;
}

std::vector<SpacecraftPathSample> parse_path(const SpacecraftSource& source,
                                           std::vector<SpacecraftDiagnostic>& diagnostics) {
    if (source.bytes.empty() || source.bytes.size() % 32 != 0)
        throw CatalogError(source.path, source.bytes.size(), "PTH requires complete nonempty 32-byte samples");
    std::vector<SpacecraftPathSample> samples;
    samples.reserve(source.bytes.size() / 32);
    for (std::size_t offset = 0; offset < source.bytes.size(); offset += 32) {
        SpacecraftPathSample sample;
        sample.time_value = real(source, offset);
        for (std::size_t axis = 0; axis < 3; ++axis) sample.coordinate_values[axis] = real(source, offset + 8*(axis + 1));
        if (!samples.empty()) {
            if (sample.time_value < samples.back().time_value)
                throw CatalogError(source.path, offset, "PTH time values decrease");
            if (sample.time_value == samples.back().time_value)
                diagnostics.push_back({SpacecraftDiagnosticCode::duplicate_time, source.key,
                    samples.size(), offset, "equal-time PTH samples retained independently; no sample selected for interpolation"});
        }
        samples.push_back(sample);
    }
    diagnostics.push_back({SpacecraftDiagnosticCode::unresolved_pth_contract, source.key, std::nullopt, 0,
        "PTH units, origin, frame and general interpolation contract are unresolved"});
    diagnostics.push_back({SpacecraftDiagnosticCode::unresolved_time_scale, source.key, std::nullopt, 0,
        "PTH physical time scale is unresolved"});
    return samples;
}

SpacecraftDefinition parse_definition(const SpacecraftSource& source, std::size_t source_index,
    const SpacecraftLoadLimits& limits, std::size_t remaining_fields,
    std::vector<SpacecraftDiagnostic>& diagnostics, bool& valid) {
    SpacecraftDefinition result;
    result.source_index = source_index;
    std::set<std::pair<std::string, std::string>> keys;
    std::string section;
    valid = true;
    const auto nul = source.bytes.find('\0');
    if (nul != std::string::npos) throw CatalogError(source.path, nul, "NUL in spacecraft definition");
    std::size_t offset = 0, line = 0;
    while (offset < source.bytes.size()) {
        const auto start = offset;
        auto end = source.bytes.find('\n', offset);
        if (end == std::string::npos) end = source.bytes.size();
        offset = end == source.bytes.size() ? end : end + 1;
        ++line;
        if (end - start > limits.max_line_bytes)
            throw LimitError(source.path, start, "spacecraft definition line limit exceeded");
        auto text = trim(std::string_view(source.bytes).substr(start, end - start));
        if (start == 0 && text.compare(0, 3, "\xEF\xBB\xBF") == 0) text.erase(0, 3);
        if (text.empty() || text.front() == '#' || text.compare(0, 2, "//") == 0) continue;
        if (text.front() == '[') {
            if (text.size() < 3 || text.back() != ']')
                throw CatalogError(source.path, start, "invalid spacecraft definition section");
            section = text.substr(1, text.size()-2);
            continue;
        }
        const auto colon = text.find(':');
        if (colon == std::string::npos || trim(std::string_view(text).substr(0, colon)).empty())
            throw CatalogError(source.path, start, "spacecraft definition requires key: value");
        if (result.fields.size() >= remaining_fields)
            throw LimitError(source.path, start, "spacecraft definition field limit exceeded");
        SpacecraftField field{trim(std::string_view(text).substr(0, colon)),
            trim(std::string_view(text).substr(colon + 1)), start, offset - start, line, section};
        if (!keys.emplace(section, field.key).second) {
            valid = false;
            diagnostics.push_back({SpacecraftDiagnosticCode::duplicate_field, source.key, 0, start,
                "duplicate spacecraft field: " + field.key});
        }
        if (field.key == "Size" || field.key == "SCALE") {
            std::istringstream input(field.value_bytes);
            input.imbue(std::locale::classic());
            double value = 0;
            input >> value;
            const bool number_valid = !input.fail() && std::isfinite(value);
            input >> std::ws;
            if (!number_valid || !input.eof()) {
                valid = false;
                diagnostics.push_back({SpacecraftDiagnosticCode::invalid_number, source.key, 0, start,
                    field.key + " is not one finite number; original value retained"});
            }
        } else if (field.key != "Name" && field.key != "DisplayName" && field.key != "Model" && field.key != "Orbit" &&
                   field.key != "KEY" && field.key != "MODEL" && field.key != "OFFSET" &&
                   field.key != "TRAJECTORY" && field.key != "ORIGIN" && field.key != "NAME") {
            diagnostics.push_back({SpacecraftDiagnosticCode::unknown_field, source.key, 0, start,
                "uninterpreted spacecraft field: " + field.key});
        }
        result.fields.push_back(std::move(field));
    }
    return result;
}

SpacecraftRegistrationList parse_registration_list(const SpacecraftSource& source,
    std::size_t source_index, const SpacecraftLoadLimits& limits, std::size_t remaining_records) {
    SpacecraftRegistrationList result;
    result.source_index = source_index;
    const auto nul = source.bytes.find('\0');
    if (nul != std::string::npos) throw CatalogError(source.path, nul, "NUL in spacecraft registration list");
    std::size_t offset = 0, line = 0;
    while (offset < source.bytes.size()) {
        const auto start = offset;
        auto end = source.bytes.find('\n', start);
        if (end == std::string::npos) end = source.bytes.size();
        offset = end == source.bytes.size() ? end : end + 1;
        ++line;
        if (end - start > limits.max_line_bytes)
            throw LimitError(source.path, start, "spacecraft registration line limit exceeded");
        auto text = trim(std::string_view(source.bytes).substr(start, end - start));
        if (start == 0 && text.compare(0, 3, "\xEF\xBB\xBF") == 0) text.erase(0, 3);
        if (text.empty() || text.front() == '#' || text.compare(0, 2, "//") == 0) continue;
        if (result.entries.size() >= remaining_records)
            throw LimitError(source.path, start, "aggregate spacecraft record limit exceeded");
        result.entries.push_back({text, start, offset-start, line, std::nullopt});
    }
    return result;
}

} // namespace spacecraft_detail
} // namespace mitaka
