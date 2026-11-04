#include "mitaka/place_catalog.hpp"

#include <cmath>
#include <fstream>
#include <locale>
#include <limits>
#include <sstream>
#include <string_view>

namespace mitaka {
namespace {

class LineParser {
public:
    LineParser(const std::filesystem::path& path, std::string_view text,
               std::uint64_t offset, std::size_t line)
        : path_(path), text_(text), offset_(offset), line_(line) {}

    bool finished() {
        whitespace();
        if (text_.substr(position_, 3) == "--[") fail("long comments are unsupported in literal place data");
        return position_ == text_.size() || text_.substr(position_, 2) == "--";
    }

    void token(std::string_view expected) {
        whitespace();
        if (text_.substr(position_, expected.size()) != expected) fail("expected " + std::string(expected));
        position_ += expected.size();
    }

    std::string method() {
        token("Places");
        token(":");
        whitespace();
        const auto start = position_;
        while (position_ < text_.size() && ((text_[position_] >= 'A' && text_[position_] <= 'Z') ||
               (text_[position_] >= 'a' && text_[position_] <= 'z'))) ++position_;
        const std::string value(text_.substr(start, position_ - start));
        token("(");
        return value;
    }

    std::string string() {
        whitespace();
        if (position_ == text_.size() || (text_[position_] != '"' && text_[position_] != '\'')) {
            fail("expected quoted string literal");
        }
        const char quote = text_[position_++];
        std::string value;
        while (position_ < text_.size()) {
            const char ch = text_[position_++];
            if (ch == quote) return value;
            const auto byte = static_cast<unsigned char>(ch);
            if (((byte >= 0x81 && byte <= 0x9f) || (byte >= 0xe0 && byte <= 0xfc)) &&
                position_ < text_.size()) {
                const auto trail = static_cast<unsigned char>(text_[position_]);
                if ((trail >= 0x40 && trail <= 0x7e) || (trail >= 0x80 && trail <= 0xfc)) {
                    // CP932の「ソ」「表」などの第2byteをエスケープ開始と誤認しない。
                    value.push_back(ch);
                    value.push_back(text_[position_++]);
                    continue;
                }
            }
            if (ch == '\\') {
                if (position_ == text_.size()) fail("unfinished string escape");
                const char escaped = text_[position_++];
                // 実データはエスケープなし。他のLua文字列構文を曖昧に解釈しない。
                if (escaped != '\\' && escaped != '"' && escaped != '\'') {
                    fail("unsupported string escape in literal place data");
                }
                value.push_back(escaped);
            } else {
                if (static_cast<unsigned char>(ch) < 0x20) fail("control byte in string literal");
                value.push_back(ch);
            }
        }
        fail("unterminated string literal");
    }

    double number() {
        whitespace();
        const auto start = position_;
        while (position_ < text_.size() && std::string_view("0123456789+-.eE").find(text_[position_]) !=
               std::string_view::npos) ++position_;
        std::istringstream input(std::string(text_.substr(start, position_ - start)));
        input.imbue(std::locale::classic());
        double value = 0;
        input >> value;
        if (!input || input.peek() != std::char_traits<char>::eof() || !std::isfinite(value)) {
            fail("expected finite decimal number literal");
        }
        return value;
    }

    void end() {
        token(")");
        whitespace();
        if (position_ < text_.size() && text_[position_] == ';') ++position_;
        if (!finished()) fail("unexpected text after Places call");
    }

    [[noreturn]] void fail(const std::string& reason) const {
        throw CatalogError(path_, offset_ + position_, "line " + std::to_string(line_) + ": " + reason);
    }

private:
    void whitespace() {
        while (position_ < text_.size() && (text_[position_] == ' ' || text_[position_] == '\t' ||
               text_[position_] == '\r')) ++position_;
    }
    const std::filesystem::path& path_;
    std::string_view text_;
    std::uint64_t offset_;
    std::size_t line_, position_ = 0;
};

std::string next_string(LineParser& line) { line.token(","); return line.string(); }
double next_number(LineParser& line) { line.token(","); return line.number(); }

void require_name(const std::string& value, LineParser& line) {
    if (value.empty()) line.fail("required name is empty");
}

void parse_record(LineParser& line, PlaceCatalog& catalog) {
    const auto method = line.method();
    if (method == "addPlace") {
        PlaceRecord place;
        place.target_name = line.string();
        place.name_bytes = next_string(line);
        place.longitude_degrees = next_number(line);
        place.latitude_degrees = next_number(line);
        place.label_group = next_string(line);
        place.landscape = next_string(line);
        require_name(place.target_name, line);
        require_name(place.name_bytes, line);
        if (place.latitude_degrees < -90 || place.latitude_degrees > 90) line.fail("latitude outside [-90,90]");
        line.end();
        catalog.places.push_back(std::move(place));
    } else if (method == "addLabelGroup") {
        PlaceLabelGroup group;
        group.name = line.string();
        group.display_distance = next_number(line);
        group.size = next_number(line);
        for (auto& channel : group.rgba) channel = next_number(line);
        require_name(group.name, line);
        if (group.display_distance < 0 || group.size < 0) line.fail("negative label distance or size");
        for (const auto channel : group.rgba) if (channel < 0 || channel > 1) line.fail("RGBA channel outside [0,1]");
        line.end();
        catalog.label_groups.push_back(std::move(group));
    } else if (method == "addLandscape") {
        PlaceLandscape landscape;
        landscape.target_name = line.string();
        landscape.name = next_string(line);
        landscape.image_path_bytes = next_string(line);
        landscape.vertical_scale = next_number(line);
        for (auto& offset : landscape.offset_arguments) offset = next_number(line);
        require_name(landscape.target_name, line);
        require_name(landscape.name, line);
        require_name(landscape.image_path_bytes, line);
        if (landscape.vertical_scale <= 0) line.fail("landscape scale must be positive");
        line.end();
        catalog.landscapes.push_back(std::move(landscape));
    } else {
        line.fail("unsupported Places method: " + method);
    }
}

PlaceCatalog parse_catalog(const std::filesystem::path& path, const std::vector<char>& bytes,
                           CatalogLoadLimits limits) {
    const auto size = bytes.size();
    PlaceCatalog catalog;
    std::uint64_t offset = 0;
    std::size_t line_number = 0, count = 0;
    while (offset < size) {
        const auto start = offset;
        ++line_number;
        std::string text;
        while (offset < size) {
            const char ch = bytes[offset++];
            if (ch == '\n') break;
            if (ch == '\0' || text.size() == 4096) {
                throw CatalogError(path, offset - 1, "line " + std::to_string(line_number) +
                    (ch == '\0' ? ": NUL byte in place catalog" : ": text line exceeds 4096 bytes"));
            }
            text.push_back(ch);
        }
        LineParser line(path, text, start, line_number);
        if (line.finished()) continue;
        if (count == limits.max_records) line.fail("place catalog exceeds record limit");
        parse_record(line, catalog);
        ++count;
    }
    return catalog;
}

} // namespace

PlaceCatalogSource load_plus_place_source(const std::filesystem::path& path, CatalogLoadLimits limits) {
    std::ifstream input(path, std::ios::binary | std::ios::ate);
    if (!input) throw CatalogError(path, 0, "cannot open place catalog");
    const auto end = input.tellg();
    if (end < 0) throw CatalogError(path, 0, "cannot determine place catalog size");
    const auto size = static_cast<std::uint64_t>(end);
    if (size > limits.max_file_bytes || size > std::numeric_limits<std::size_t>::max() ||
        size > static_cast<std::uint64_t>(std::numeric_limits<std::streamsize>::max()))
        throw CatalogError(path, 0, "place catalog exceeds byte limit");
    input.seekg(0);
    if (!input) throw CatalogError(path, 0, "cannot seek place catalog");
    PlaceCatalogSource result{path, std::vector<char>(static_cast<std::size_t>(size)), {}, {}};
    if (size && !input.read(result.bytes.data(), static_cast<std::streamsize>(size)))
        throw CatalogError(path, 0, "place catalog read failed");
    // 読み取り途中の伸長も黙って切り捨てず、取り込む版を不明確にしない。
    const auto next = input.peek();
    if (input.bad()) throw CatalogError(path, size, "place catalog end check failed");
    if (next != std::char_traits<char>::eof())
        throw CatalogError(path, size, "place catalog grew while reading");
    try {
        result.catalog = parse_catalog(path, result.bytes, limits);
    } catch (const CatalogError& error) {
        result.error = error;
    }
    return result;
}

PlaceCatalog load_plus_place_catalog(const std::filesystem::path& path, CatalogLoadLimits limits) {
    auto source = load_plus_place_source(path, limits);
    if (source.error) throw *source.error;
    return std::move(*source.catalog);
}

} // namespace mitaka
