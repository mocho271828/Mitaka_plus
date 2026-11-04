#include "catalog_browser_model.hpp"
#import <Foundation/Foundation.h>

#include <algorithm>
#include <array>
#include <charconv>
#include <cstdio>
#include <stdexcept>
#include <string_view>
#include <unordered_map>

namespace mitaka::gui {
namespace {
constexpr std::array kinds{BrowserObjectKind::planet, BrowserObjectKind::star,
    BrowserObjectKind::constellation, BrowserObjectKind::nebula, BrowserObjectKind::galaxy, BrowserObjectKind::quasar};
// SkyModel::solar_bodiesの順序。暦表中の9惑星と太陽・月の選択IDに対応する。
constexpr std::array planetNames{"太陽", "水星", "金星", "地球", "火星", "木星", "土星", "天王星", "海王星", "冥王星", "月"};
constexpr std::array planetAliases{"sun", "mercury", "venus", "earth", "mars", "jupiter", "saturn", "uranus", "neptune", "pluto", "moon"};

std::string utf8(NSString *text) {
    const char *bytes = text.UTF8String;
    return bytes ? bytes : "";
}
std::string decode(const std::string& bytes, bool japanese = false) {
    const NSStringEncoding encoding = japanese
        ? CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese) : NSUTF8StringEncoding;
    return utf8([[NSString alloc] initWithBytes:bytes.data() length:bytes.size() encoding:encoding]);
}
std::string folded(std::string_view text) {
    NSString *value = [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
    return utf8([[value stringByFoldingWithOptions:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch | NSWidthInsensitiveSearch
                                           locale:[NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]] lowercaseString]);
}
std::vector<std::string> tokens(const std::string& query) {
    const auto normalized = folded(query);
    std::vector<std::string> result;
    std::size_t start = 0;
    while (start < normalized.size()) {
        start = normalized.find_first_not_of(" \t\r\n", start);
        if (start == std::string::npos) break;
        const auto end = normalized.find_first_of(" \t\r\n", start);
        const auto word = normalized.substr(start, end - start);
        bool split = false;
        for (const std::string_view prefix : {"hip", "ngc", "ic"}) {
            if (word.size() > prefix.size() && word.compare(0, prefix.size(), prefix) == 0
                && word[prefix.size()] >= '0' && word[prefix.size()] <= '9') {
                result.emplace_back(prefix);
                result.push_back(word.substr(prefix.size()));
                split = true;
                break;
            }
        }
        if (!split) result.push_back(word);
        start = end == std::string::npos ? normalized.size() : end;
    }
    return result;
}
bool matches(const std::vector<std::string>& query, std::initializer_list<std::string_view> fields) {
    return std::all_of(query.begin(), query.end(), [&](const auto& token) {
        return std::any_of(fields.begin(), fields.end(), [&](auto field) { return field.find(token) != std::string_view::npos; });
    });
}
std::string_view identifier(std::size_t value, std::array<char, 32>& buffer) {
    const auto converted = std::to_chars(buffer.data(), buffer.data() + buffer.size(), value);
    return {buffer.data(), static_cast<std::size_t>(converted.ptr - buffer.data())};
}
std::string starNames(const StarNameRecord& record) {
    return decode(record.name_bytes) + " " + decode(record.localized_name_bytes, true);
}
std::string coordinates(EquatorialCoordinates position) {
    std::array<char, 100> buffer{};
    std::snprintf(buffer.data(), buffer.size(), "RA %.3f° / Dec %+.3f°", position.right_ascension_deg, position.declination_deg);
    return buffer.data();
}
std::string decimal(double value, const char *format) {
    std::array<char, 100> buffer{};
    std::snprintf(buffer.data(), buffer.size(), format, value);
    return buffer.data();
}
}

CatalogBrowserModel::CatalogBrowserModel(std::shared_ptr<const SkyModel> model,
                                       std::shared_ptr<const ExtendedCatalogs> catalogs)
    : model_(std::move(model)), catalogs_(std::move(catalogs)) {}

std::size_t CatalogBrowserModel::count(BrowserObjectKind kind) const noexcept {
    switch (kind) {
        case BrowserObjectKind::planet: return model_ ? planetNames.size() : 0;
        case BrowserObjectKind::star: return model_ ? model_->stars().size() : 0;
        case BrowserObjectKind::constellation: return model_ ? model_->constellations().size() : 0;
        case BrowserObjectKind::nebula: return catalogs_ ? catalogs_->ngc.size() : 0;
        case BrowserObjectKind::galaxy: return catalogs_ ? catalogs_->galaxies.size() : 0;
        case BrowserObjectKind::quasar: return catalogs_ ? catalogs_->quasars.size() : 0;
    }
    return 0;
}
std::size_t CatalogBrowserModel::size() const noexcept {
    std::size_t result = 0;
    for (auto kind : kinds) result += count(kind);
    return result;
}

BrowserSearchPage CatalogBrowserModel::search(const BrowserSearchQuery& query,
                                             const std::function<bool()>& cancelled) const {
    if (query.page_size == 0 || query.page_size > 5000) throw std::invalid_argument("browser page size must be 1..5000");
    @autoreleasepool {
        BrowserSearchPage result;
        result.total_objects = size();
        result.offset = query.offset;
        result.rows.reserve(std::min(query.page_size, result.total_objects));
        const auto words = tokens(query.text);
        const auto stop = [&] {
            if (!cancelled || !cancelled()) return false;
            result.cancelled = true;
            result.rows.clear();
            return true;
        };
        const auto appendRange = [&](BrowserObjectKind kind, std::size_t length) {
            const auto begin = query.offset > result.total_matches ? query.offset - result.total_matches : 0;
            const auto available = query.page_size - result.rows.size();
            if (begin < length) for (std::size_t i = 0; i < std::min(length - begin, available); ++i)
                result.rows.push_back({kind, begin + i});
            result.total_matches += length;
        };
        const auto append = [&](BrowserObjectKind kind, std::size_t index) {
            if (result.total_matches >= query.offset && result.rows.size() < query.page_size)
                result.rows.push_back({kind, index});
            ++result.total_matches;
        };
        for (const auto kind : kinds) {
            if (stop()) return result;
            if (query.kind && *query.kind != kind) continue;
            const auto length = count(kind);
            if (words.empty()) { appendRange(kind, length); continue; }
            const std::string_view sdssPrefix = kind == BrowserObjectKind::galaxy ? "sdss gal 銀河 galaxy" : "sdss qso quasar";
            if (kind == BrowserObjectKind::galaxy || kind == BrowserObjectKind::quasar) {
                if (matches(words, {sdssPrefix})) { appendRange(kind, length); continue; }
                // 連番以外の情報がないSDSSで、語句が一致しない場合は走査自体を省略する。
                if (std::any_of(words.begin(), words.end(), [&](const auto& word) {
                    return sdssPrefix.find(word) == std::string_view::npos
                        && word.find_first_not_of("0123456789") != std::string::npos;
                })) continue;
            }
            std::unordered_map<std::int32_t, std::size_t> names;
            if (kind == BrowserObjectKind::star && catalogs_) {
                for (std::size_t i = 0; i < catalogs_->star_names.size(); ++i) {
                    if ((i & 255) == 0 && stop()) return result;
                    names[catalogs_->star_names[i].hip] = i;
                }
            }
            for (std::size_t index = 0; index < length; ++index) {
                if ((index & 255) == 0 && stop()) return result;
                bool found = false;
                std::array<char, 32> number{};
                // 名称の変換は小さなautoreleasepoolで解放し、大量検索の一時NSStringを蓄積しない。
                @autoreleasepool {
                    switch (kind) {
                        case BrowserObjectKind::planet:
                            found = matches(words, {planetNames[index], planetAliases[index], "太陽系 planet"});
                            break;
                        case BrowserObjectKind::star: {
                            const auto& star = model_->stars()[index];
                            const auto id = identifier(static_cast<std::size_t>(star.hip), number);
                            found = matches(words, {"hip 恒星 star", id});
                            if (!found) {
                                const auto name = names.find(star.hip);
                                if (name != names.end()) found = matches(words, {"hip 恒星 star", id,
                                    folded(starNames(catalogs_->star_names[name->second]))});
                            }
                            break;
                        }
                        case BrowserObjectKind::constellation: {
                            const auto& constellation = model_->constellations()[index];
                            const auto name = folded(constellation.abbreviation + " " + constellation.english_name + " "
                                + constellation.english_genitive + " " + decode(constellation.japanese_hiragana_bytes, true)
                                + " " + decode(constellation.japanese_kanji_bytes, true));
                            found = matches(words, {name, "星座 constellation"});
                            break;
                        }
                        case BrowserObjectKind::nebula: {
                            const auto& object = catalogs_->ngc[index];
                            found = matches(words, {object.is_ngc ? "ngc 星雲 星団 nebula" : "ic 星雲 星団 nebula",
                                identifier(static_cast<std::size_t>(object.number), number)});
                            break;
                        }
                        case BrowserObjectKind::galaxy:
                        case BrowserObjectKind::quasar:
                            found = matches(words, {sdssPrefix, identifier(index + 1, number)});
                            break;
                    }
                }
                if (found) append(kind, index);
            }
        }
        stop();
        return result;
    }
}

BrowserEntryText CatalogBrowserModel::entry(BrowserObjectReference reference) const {
    if (reference.index >= count(reference.kind)) throw std::out_of_range("catalog browser reference out of range");
    @autoreleasepool {
        const auto index = reference.index;
        BrowserEntryText result{static_cast<std::int64_t>(index), {}, {}};
        switch (reference.kind) {
            case BrowserObjectKind::planet:
                result.title = planetNames[index]; result.details = "太陽系の天体";
                break;
            case BrowserObjectKind::star: {
                const auto& star = model_->stars()[index];
                result.identifier = star.hip;
                result.title = "HIP " + std::to_string(star.hip);
                if (catalogs_) for (auto name = catalogs_->star_names.rbegin(); name != catalogs_->star_names.rend(); ++name)
                    if (name->hip == star.hip) {
                        auto title = decode(name->localized_name_bytes, true);
                        if (title.empty() || title == "*") title = decode(name->name_bytes);
                        if (!title.empty()) result.title += " · " + title;
                        break;
                    }
                result.details = coordinates({star.right_ascension_degrees, star.declination_degrees})
                    + decimal(star.apparent_v_magnitude, " · V %.2f");
                break;
            }
            case BrowserObjectKind::constellation: {
                const auto& object = model_->constellations()[index];
                result.title = object.english_name;
                const auto japanese = decode(object.japanese_hiragana_bytes, true);
                if (!japanese.empty() && japanese != "*") result.title += " · " + japanese;
                result.details = object.abbreviation + " · " + coordinates({object.right_ascension_degrees, object.declination_degrees});
                break;
            }
            case BrowserObjectKind::nebula: {
                const auto& object = catalogs_->ngc[index];
                result.title = std::string(object.is_ngc ? "NGC " : "IC ") + std::to_string(object.number);
                result.details = coordinates(object.coordinates) + decimal(object.angular_size_arcminutes, " · %.2f′");
                break;
            }
            case BrowserObjectKind::galaxy:
            case BrowserObjectKind::quasar: {
                const auto& object = reference.kind == BrowserObjectKind::galaxy ? catalogs_->galaxies[index] : catalogs_->quasars[index];
                result.title = std::string(reference.kind == BrowserObjectKind::galaxy ? "SDSS GAL " : "SDSS QSO ") + std::to_string(index + 1);
                result.details = coordinates(object.coordinates) + decimal(object.distance_parsecs / 1e6, " · %.3f Mpc");
                break;
            }
        }
        return result;
    }
}
}
