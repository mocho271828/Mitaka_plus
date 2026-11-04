#include "session_layers_json.h"
#include <cmath>
#include <stdexcept>

namespace mitaka::gui {
namespace {
[[noreturn]] void invalid() { throw std::invalid_argument("session state: invalid display layer field"); }
NSDictionary *object(id value) {
    if (![value isKindOfClass:NSDictionary.class]) invalid();
    return value;
}
NSArray *array(id value) {
    if (![value isKindOfClass:NSArray.class]) invalid();
    return value;
}
bool boolean(id value) {
    if (![value isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)value) != CFBooleanGetTypeID()) invalid();
    return [value boolValue];
}
double number(id value) {
    if (![value isKindOfClass:NSNumber.class] || CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID()) invalid();
    const double result = [value doubleValue];
    if (!std::isfinite(result)) invalid();
    return result;
}
std::size_t integer(id value) {
    const double result = number(value);
    if (result < 0 || result > 9007199254740991.0 || std::trunc(result) != result) invalid();
    return static_cast<std::size_t>(result);
}
NSString *text(const std::string& value) {
    NSString *result = [[NSString alloc] initWithBytes:value.data() length:value.size() encoding:NSUTF8StringEncoding];
    if (!result) invalid();
    return result;
}
std::string string(id value) {
    if (![value isKindOfClass:NSString.class]) invalid();
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) invalid();
    return {static_cast<const char*>(data.bytes), data.length};
}
NSString *encoded_bytes(const std::string& value) {
    return [[NSData dataWithBytes:value.data() length:value.size()] base64EncodedStringWithOptions:0];
}
std::string decoded_bytes(id value) {
    if (![value isKindOfClass:NSString.class]) invalid();
    NSData *data = [[NSData alloc] initWithBase64EncodedString:value options:0];
    // 同じ raw ID に複数の表記を許さず、破損・余分な文字を拒否する。
    if (!data || ![[data base64EncodedStringWithOptions:0] isEqualToString:value]) invalid();
    return {static_cast<const char*>(data.bytes), data.length};
}
template<typename Options> Options decode_options(NSDictionary *value) {
    return {boolean(value[@"visible"]), boolean(value[@"labels"]), boolean(value[@"orbits"]), boolean(value[@"selected_only"])};
}
template<typename Options> NSDictionary *encode_options(const Options& value) {
    return @{@"visible": @(value.visible), @"labels": @(value.labels), @"orbits": @(value.orbits), @"selected_only": @(value.selected_only)};
}
template<typename Id> std::vector<Id> decode_ids(id value) {
    std::vector<Id> result;
    for (id item in array(value)) {
        NSDictionary *record = object(item);
        result.push_back({decoded_bytes(record[@"source_key_base64"]), integer(record[@"record_ordinal"])});
    }
    return result;
}
template<typename Id> NSArray *encode_ids(const std::vector<Id>& ids) {
    NSMutableArray *result = [NSMutableArray array];
    for (const auto& value : ids) [result addObject:@{@"source_key_base64": encoded_bytes(value.source_key), @"record_ordinal": @(value.record_ordinal)}];
    return result;
}
std::vector<SessionSourceIdentity> decode_sources(id value) {
    std::vector<SessionSourceIdentity> result;
    for (id item in array(value)) {
        NSDictionary *record = object(item);
        result.push_back({decoded_bytes(record[@"source_key_base64"]), integer(record[@"byte_count"]), string(record[@"sha256"])});
    }
    return result;
}
NSArray *encode_sources(const std::vector<SessionSourceIdentity>& sources) {
    NSMutableArray *result = [NSMutableArray array];
    for (const auto& value : sources) [result addObject:@{@"source_key_base64": encoded_bytes(value.source_key), @"byte_count": @(value.byte_count), @"sha256": text(value.sha256)}];
    return result;
}
} // namespace

void decode_session_layers(NSDictionary *root, SessionState& state) {
    NSDictionary *small = object(root[@"small_bodies"]);
    state.small_bodies.visible = boolean(small[@"visible"]);
    NSArray *kinds = array(small[@"kinds"]);
    if (kinds.count != state.small_bodies.kinds.size()) invalid();
    for (std::size_t i = 0; i < state.small_bodies.kinds.size(); ++i)
        state.small_bodies.kinds[i] = decode_options<SmallBodyKindDisplayOptions>(object(kinds[i]));
    state.small_bodies.selected_ids = decode_ids<SmallBodyId>(small[@"selected_ids"]);
    state.small_bodies.sources = decode_sources(small[@"sources"]);
    NSDictionary *sampling = object(small[@"orbit_sampling"]);
    state.small_bodies.orbit_sampling = {number(sampling[@"first_jd"]), number(sampling[@"last_jd"]), integer(sampling[@"sample_count"])};
    NSDictionary *satellites = object(root[@"satellites"]);
    state.satellites.options = decode_options<SatelliteDisplayOptions>(object(satellites[@"options"]));
    state.satellites.selected_ids = decode_ids<SatelliteRecordId>(satellites[@"selected_ids"]);
    state.satellites.sources = decode_sources(satellites[@"sources"]);
    NSDictionary *spacecraft = object(root[@"spacecraft"]);
    state.spacecraft = {boolean(spacecraft[@"visible"]), boolean(spacecraft[@"points"]), boolean(spacecraft[@"labels"]), boolean(spacecraft[@"orbits"])};
    NSDictionary *constellations = object(root[@"constellations"]);
    state.constellations = {boolean(constellations[@"lines"]), boolean(constellations[@"boundaries"]), boolean(constellations[@"labels"]), boolean(constellations[@"default_visible"]), {}, boolean(constellations[@"illustrations"])};
    for (id value in array(constellations[@"exceptions_base64"]))
        if (!state.constellations.exceptions.insert(decoded_bytes(value)).second) invalid();
}

NSDictionary *encode_session_layers(const SessionState& state) {
    NSMutableArray *kinds = [NSMutableArray array];
    for (const auto& kind : state.small_bodies.kinds) [kinds addObject:encode_options(kind)];
    NSMutableArray *exceptions = [NSMutableArray array];
    for (const auto& id : state.constellations.exceptions) [exceptions addObject:encoded_bytes(id)];
    const auto& sampling = state.small_bodies.orbit_sampling;
    return @{
        @"small_bodies": @{@"visible": @(state.small_bodies.visible), @"kinds": kinds,
            @"selected_ids": encode_ids(state.small_bodies.selected_ids), @"sources": encode_sources(state.small_bodies.sources),
            @"orbit_sampling": @{@"first_jd": @(sampling.first_jd), @"last_jd": @(sampling.last_jd), @"sample_count": @(sampling.sample_count)}},
        @"satellites": @{@"options": encode_options(state.satellites.options), @"selected_ids": encode_ids(state.satellites.selected_ids), @"sources": encode_sources(state.satellites.sources)},
        @"spacecraft": @{@"visible": @(state.spacecraft.visible), @"points": @(state.spacecraft.points), @"labels": @(state.spacecraft.labels), @"orbits": @(state.spacecraft.orbits)},
        @"constellations": @{@"lines": @(state.constellations.lines), @"boundaries": @(state.constellations.boundaries), @"labels": @(state.constellations.labels), @"default_visible": @(state.constellations.default_visible), @"exceptions_base64": exceptions, @"illustrations": @(state.constellations.illustrations)}
    };
}
} // namespace mitaka::gui
