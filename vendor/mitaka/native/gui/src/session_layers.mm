#include "session_layers.hpp"

#import <CommonCrypto/CommonDigest.h>

#include <algorithm>
#include <limits>
#include <map>
#include <set>
#include <stdexcept>

namespace mitaka::gui {
namespace {
constexpr std::size_t maximum_json_integer = 9007199254740991ULL;

void validate_key(const std::string& key) {
    if (key.empty() || key.size() > 65536 || key.find('\0') != std::string::npos)
        throw std::invalid_argument("session state: invalid source or constellation identity");
}

template<typename Id, typename Less>
void validate_selection(const std::vector<Id>& ids, const std::vector<SessionSourceIdentity>& sources, Less less) {
    std::set<Id, Less> unique(less);
    std::set<std::string> referenced, provided;
    for (const auto& id : ids) {
        validate_key(id.source_key);
        if (id.record_ordinal > maximum_json_integer || !unique.insert(id).second)
            throw std::invalid_argument("session state: invalid or duplicate selected identity");
        referenced.insert(id.source_key);
    }
    for (const auto& source : sources) {
        validate_key(source.source_key);
        if (source.byte_count > maximum_json_integer || source.sha256.size() != 64 ||
            !std::all_of(source.sha256.begin(), source.sha256.end(), [](char c) {
                return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f');
            }) || !provided.insert(source.source_key).second)
            throw std::invalid_argument("session state: invalid or duplicate source fingerprint");
    }
    if (referenced != provided)
        throw std::invalid_argument("session state: source fingerprints do not match selected identities");
}

template<typename Source, typename Id>
std::vector<SessionSourceIdentity> capture_sources(const std::vector<Source>& sources, const std::vector<Id>& ids) {
    std::set<std::string> required;
    for (const auto& id : ids) required.insert(id.source_key);
    std::vector<SessionSourceIdentity> result;
    for (const auto& source : sources)
        if (required.erase(source.key)) result.push_back(session_source_identity(source.key, source.bytes));
    if (!required.empty()) throw std::invalid_argument("session state: selected source is missing");
    std::sort(result.begin(), result.end(), [](const auto& a, const auto& b) { return a.source_key < b.source_key; });
    return result;
}

template<typename Source>
void verify_sources(const std::vector<SessionSourceIdentity>& expected, const std::vector<Source>& current) {
    std::map<std::string, const Source*> sources;
    for (const auto& source : current) sources.emplace(source.key, &source);
    for (const auto& identity : expected) {
        const auto source = sources.find(identity.source_key);
        if (source == sources.end() || source->second->bytes.size() != identity.byte_count ||
            session_source_identity(identity.source_key, source->second->bytes).sha256 != identity.sha256)
            throw std::invalid_argument("session state: selected source bytes have changed or are missing");
    }
}
} // namespace

SessionSourceIdentity session_source_identity(std::string_view key, std::string_view bytes) {
    validate_key(std::string(key));
    if (bytes.size() > std::numeric_limits<CC_LONG>::max())
        throw std::length_error("session state: source exceeds SHA-256 input limit");
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(bytes.data(), static_cast<CC_LONG>(bytes.size()), digest);
    constexpr char hex[] = "0123456789abcdef";
    std::string encoded;
    encoded.reserve(sizeof(digest) * 2);
    for (const auto byte : digest) { encoded += hex[byte >> 4]; encoded += hex[byte & 15]; }
    return {std::string(key), bytes.size(), std::move(encoded)};
}

void validate_session_layers(const SmallBodySessionDisplay& small, const SatelliteSessionDisplay& satellites,
                             const ConstellationDisplayOptions& constellations) {
    validate_small_body_orbit_sampling(small.orbit_sampling);
    validate_selection(small.selected_ids, small.sources, SmallBodyIdLess{});
    validate_selection(satellites.selected_ids, satellites.sources, SatelliteIdLess{});
    for (const auto& key : constellations.exceptions) validate_key(key);
}

SmallBodySessionDisplay capture_small_body_session(const SmallBodyDisplayModel& display, bool visible,
                                                  SmallBodyOrbitSampling sampling) {
    SmallBodySessionDisplay result;
    result.visible = visible;
    result.orbit_sampling = sampling;
    for (std::size_t i = 0; i < result.kinds.size(); ++i)
        result.kinds[i] = display.kind_options(static_cast<SmallBodyKind>(i));
    result.selected_ids = display.selected_ids();
    result.sources = capture_sources(display.dataset()->sources, result.selected_ids);
    return result;
}

SatelliteSessionDisplay capture_satellite_session(const SatelliteDisplayModel& display) {
    SatelliteSessionDisplay result;
    result.options = display.options();
    result.selected_ids = display.selected_ids();
    result.sources = capture_sources(display.model()->dataset().sources, result.selected_ids);
    return result;
}

std::shared_ptr<const SmallBodyDisplayModel> prepare_small_body_session(
    const SmallBodySessionDisplay& state, const SmallBodyDisplayModel& current) {
    validate_session_layers(state, {}, {});
    verify_sources(state.sources, current.dataset()->sources);
    auto result = std::make_shared<SmallBodyDisplayModel>(current);
    for (std::size_t i = 0; i < state.kinds.size(); ++i)
        result->set_kind_options(static_cast<SmallBodyKind>(i), state.kinds[i]);
    result->set_selected_ids(state.selected_ids);
    return result;
}

std::shared_ptr<const SatelliteDisplayModel> prepare_satellite_session(
    const SatelliteSessionDisplay& state, const SatelliteDisplayModel& current) {
    validate_session_layers({}, state, {});
    verify_sources(state.sources, current.model()->dataset().sources);
    auto result = std::make_shared<SatelliteDisplayModel>(current);
    result->set_options(state.options);
    result->set_selected_ids(state.selected_ids);
    return result;
}
} // namespace mitaka::gui
