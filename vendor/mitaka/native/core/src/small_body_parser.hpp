#pragma once

#include "mitaka/small_body_catalog.hpp"

#include <string_view>

namespace mitaka::small_body_detail {
struct Line { std::string_view text; std::size_t offset, byte_length; };
class LineReader {
public:
    explicit LineReader(const std::string& bytes) : bytes_(bytes) {}
    std::optional<Line> next();
private:
    const std::string& bytes_;
    std::size_t offset_ = 0;
};
std::string trim(std::string_view value);
double number(const SmallBodySource& source, std::string_view value, std::size_t offset);
std::int32_t integer(const SmallBodySource& source, std::string_view value, std::size_t offset);
void diagnostic(SmallBodyRecord& record, SmallBodyDiagnosticCode code,
                const std::string& field, const std::string& message);
void unresolved(SmallBodyRecord& record);
std::vector<SmallBodyRecord> parse_packed(const SmallBodySource& source, SmallBodyKind kind,
                                         bool flagged, std::size_t max_records);
std::vector<SmallBodyRecord> parse_elements(const SmallBodySource& source, SmallBodyKind kind);
std::vector<SmallBodyRecord> parse_comets(const SmallBodySource& source, std::size_t max_records);
void attach_names(const SmallBodySource& source, std::vector<SmallBodyRecord>& records);
} // namespace mitaka::small_body_detail
