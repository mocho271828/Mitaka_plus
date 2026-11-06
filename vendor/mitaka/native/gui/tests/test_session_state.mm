#include "session_state.hpp"

#import <Foundation/Foundation.h>

#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka::gui;
int checks = 0;

void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}

template<typename Function> void rejects(Function operation) {
    ++checks;
    try { operation(); } catch (const std::invalid_argument&) { return; }
    throw std::runtime_error("invalid session was accepted");
}

std::string json_bytes(id object) {
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    check(data && !error, "test JSON serialization failed");
    return std::string(static_cast<const char *>(data.bytes), data.length);
}

NSMutableDictionary *session_object() {
    const auto json = encode_session_state(SessionState{});
    NSData *data = [NSData dataWithBytes:json.data() length:json.size()];
    NSError *error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    check([object isKindOfClass:NSMutableDictionary.class] && !error, "test JSON parsing failed");
    return (NSMutableDictionary *)object;
}

void rejects_field(NSString *field, id value) {
    NSMutableDictionary *object = session_object();
    if (value) object[field] = value;
    else [object removeObjectForKey:field];
    rejects([&] { decode_session_state(json_bytes(object)); });
}

void test_roundtrip() {
    SessionState state;
    auto json = encode_session_state(state);
    const auto initial = decode_session_state(json);
    check(encode_session_state(initial) == json, "default state did not roundtrip exactly");
    check(initial.version == 9 && initial.simulation_rate == 3600 && !initial.solar_camera.frame,
          "default values changed");
    for (const double fov : {0.001, 45.0, 90.0}) {
        state.solar_camera.vertical_fov_deg = fov;
        check(decode_session_state(encode_session_state(state)).solar_camera.vertical_fov_deg == fov,
              "solar camera FOV did not roundtrip");
    }
    NSMutableDictionary *old_fov = session_object();
    [old_fov[@"solar_camera"] removeObjectForKey:@"fov_deg"];
    check(decode_session_state(json_bytes(old_fov)).solar_camera.vertical_fov_deg == 45,
          "legacy solar FOV default");
    for (const double fov : {0.0, -1.0, 90.1}) {
        state.solar_camera.vertical_fov_deg = fov;
        rejects([&] { encode_session_state(state); });
    }
    state.solar_camera.vertical_fov_deg = 45;
    state.solar_camera.roll(37);
    check(decode_session_state(encode_session_state(state)).solar_camera.roll_deg == 37,
          "camera roll did not roundtrip");
    NSMutableDictionary *old_session = session_object();
    [old_session[@"solar_camera"] removeObjectForKey:@"roll_deg"];
    check(decode_session_state(json_bytes(old_session)).solar_camera.roll_deg == 0,
          "previous v9 camera did not restore its default roll");
    state.horizon_viewport.roll_deg = 37;
    check(decode_session_state(encode_session_state(state)).horizon_viewport.roll_deg == 37,
          "horizon roll did not roundtrip");
    [old_session[@"horizon_viewport"] removeObjectForKey:@"roll_deg"];
    check(decode_session_state(json_bytes(old_session)).horizon_viewport.roll_deg == 0,
          "previous v9 horizon did not restore its default roll");
    state.horizon_viewport.roll_deg = 0;
    for (const double fov : {180.0, 90.0, 45.0, 0.1, std::numeric_limits<double>::min()}) {
        state.horizon_viewport.vertical_fov_deg = fov;
        check(decode_session_state(encode_session_state(state)).horizon_viewport.vertical_fov_deg == fov,
              "horizon FOV did not roundtrip");
    }
    for (const double zoom : {1.0, 2.0, 180.0}) {
        NSMutableDictionary *legacy = session_object();
        [legacy[@"horizon_viewport"] removeObjectForKey:@"fov_deg"];
        legacy[@"horizon_viewport"][@"zoom"] = @(zoom);
        check(decode_session_state(json_bytes(legacy)).horizon_viewport.vertical_fov_deg == 180 / zoom,
              "legacy horizon zoom was not converted to FOV");
    }
    NSMutableDictionary *with_fov = session_object();
    with_fov[@"horizon_viewport"][@"zoom"] = @2;
    with_fov[@"horizon_viewport"][@"fov_deg"] = @0.1;
    check(decode_session_state(json_bytes(with_fov)).horizon_viewport.vertical_fov_deg == 0.1,
          "explicit horizon FOV did not take precedence over legacy zoom");
    state.horizon_viewport.vertical_fov_deg = 0.1;
    const auto precise_json = encode_session_state(state);
    NSData *precise_data = [NSData dataWithBytes:precise_json.data() length:precise_json.size()];
    NSDictionary *precise = [NSJSONSerialization JSONObjectWithData:precise_data options:0 error:nil];
    check([precise[@"horizon_viewport"][@"zoom"] doubleValue] == 180,
          "legacy zoom did not clamp narrow FOV");
    state.horizon_viewport.vertical_fov_deg = 180;
    for (int level = 1; level <= 5; ++level) {
        state.terrain_amplification = static_cast<TerrainAmplification>(level);
        check(decode_session_state(encode_session_state(state)).terrain_amplification == state.terrain_amplification,
              "terrain amplification did not roundtrip");
    }
    // 銀河まで拡張した距離は、保存と復元の両方で描画カメラと同じ上限を使う。
    for (const double distance : {1001.0, 1e12, maximum_solar_distance_au}) {
        state.solar_camera.distance_au = distance;
        check(decode_session_state(encode_session_state(state)).solar_camera.distance_au == distance,
              "extended camera distance did not roundtrip");
    }
    state.solar_camera.distance_au = maximum_solar_distance_au * 2;
    rejects([&] { encode_session_state(state); });
    state.solar_camera.distance_au = 100;
    state.terrain_amplification = static_cast<TerrainAmplification>(0);
    rejects([&] { encode_session_state(state); });
    state.terrain_amplification = TerrainAmplification::x20;
    state.julian_date = 2460000.125;
    state.simulation_rate = -123.5;
    state.mode = 2;
    state.magnitude_limit = 12.5;
    state.sky_viewport = {359.5, -45, 4};
    state.horizon_viewport = {19.25, 20, 60};
    state.solar_camera = {{-5.25, 1e-8, 123.5}, -91.5, 25.25, 1e-10,
                         SolarCameraBasis{{0, 0, 1}, {1, 0, 0}, {0, 1, 0}}};
    state.selected_body = Body::moon;
    state.sky_selected_body = Body::mars;
    state.horizon_selected_body = Body::venus;
    state.constellations.lines = false;
    state.constellations.boundaries = true;
    state.constellations.labels = false;
    state.constellations.illustrations = true;
    state.planets = {false, false, false, true};
    state.stars = {false, true, true, true, true, StarMarking::exoplanets, true, 2.5f};
    state.selected_star_name_hips = {1, 99, 2147483647};
    state.earth_layers = {false, true};
    state.atmosphere = {AtmosphereMode::single, 0.125};
    state.eclipse = {false, true, true, true};
    state.grids = {true, true, true, true, false, true};
    state.renderer = {true, false, true, false};
    state.show_time_info = false;
    state.show_nebulae = true;
    state.show_galaxies = true;
    state.show_quasars = true;
    state.milky_way_mode = MilkyWayMode::infrared;
    state.time_settings = {TimeStep::month, 1234, 540};
    state.small_bodies.visible = true;
    state.satellites.options.visible = false;
    state.observer_latitude_deg = -90;
    state.observer_longitude_deg = -180;
    json = encode_session_state(state);
    const auto restored = decode_session_state(json);
    check(encode_session_state(restored) == json, "configured state did not roundtrip exactly");
    check(restored.simulation_rate == -123.5 && restored.mode == 2 && restored.selected_body == Body::moon,
          "direction, mode, or selected body changed");
    check(restored.sky_selected_body == Body::mars && restored.horizon_selected_body == Body::venus,
          "independent sky/horizon body selections changed");
    check(restored.milky_way_mode == MilkyWayMode::infrared && restored.small_bodies.visible &&
          !restored.satellites.options.visible &&
          restored.time_settings.step == TimeStep::month && restored.time_settings.custom_seconds == 1234 &&
          restored.time_settings.utc_offset_minutes == 540, "background, bodies or time settings changed");
    check(restored.magnitude_limit == 12.5, "faint catalog magnitude was not restored");
    state.magnitude_limit = -2.5;
    check(decode_session_state(encode_session_state(state)).magnitude_limit == -2.5,
          "negative magnitude filter was not restored");
    check(restored.solar_camera.frame && restored.solar_camera.frame->outward.z == 1 &&
          restored.solar_camera.distance_au == 1e-10 && restored.sky_viewport.center_ra_deg == 359.5,
          "camera state changed");
    check(restored.horizon_viewport.center_azimuth_deg == 19.25 &&
          restored.horizon_viewport.center_altitude_deg == 20 && restored.horizon_viewport.vertical_fov_deg == 60 &&
          restored.stars.proper_names && restored.stars.marking == StarMarking::exoplanets && restored.show_nebulae &&
          restored.show_galaxies && restored.show_quasars, "horizon or catalog visibility changed");
    check(!restored.planets.visible && !restored.planets.labels && !restored.planets.orbits && restored.planets.axes &&
          !restored.stars.visible && restored.stars.bayer_labels && restored.stars.flamsteed_labels && restored.stars.hip_labels &&
          restored.grids.equatorial && restored.grids.ecliptic && restored.grids.galactic && restored.grids.horizontal &&
          !restored.grids.circle_scales && restored.grids.square_scales && !restored.show_time_info,
          "independent display options did not roundtrip");
    check(restored.terrain_amplification == TerrainAmplification::x20, "terrain amplification changed");
    check(restored.renderer.antialias && !restored.renderer.point_smoothing &&
          restored.renderer.line_smoothing && !restored.renderer.text_smoothing,
          "renderer preferences did not roundtrip independently");
    check(restored.constellations.illustrations && restored.stars.selected_proper_names_only &&
          restored.stars.brightness == 2.5f && restored.selected_star_name_hips == state.selected_star_name_hips &&
          !restored.earth_layers.clouds && restored.earth_layers.city_lights &&
          restored.atmosphere.mode == AtmosphereMode::single && restored.atmosphere.intensity == 0.125,
          "v6 art, star selection, Earth and atmosphere fields changed");
    check(!restored.eclipse.shadows && restored.eclipse.shadow_borders && restored.eclipse.shadow_umbra &&
          restored.eclipse.shadow_penumbra, "independent eclipse options changed");
    NSMutableDictionary *extra = session_object();
    extra[@"future_extension"] = @{@"text": @"os.execute('must never be evaluated')"};
    check(encode_session_state(decode_session_state(json_bytes(extra))) == encode_session_state(SessionState{}),
          "unknown fields were not ignored as inert data");
}

void test_missing_null_and_types() {
    rejects_field(@"terrain_amplification", nil);
    for (id value in @[NSNull.null, @YES, @NO, @0, @6, @1.5, @"1", @[], @{}])
        rejects_field(@"terrain_amplification", value);
    for (NSString *field in @[@"sky_selected_body", @"horizon_selected_body"]) {
        rejects_field(field, nil);
        for (id value in @[@YES, @"1", @1.5, @(-1), @99, @(static_cast<int>(Body::earth))])
            rejects_field(field, value);
    }
    for (Body body : {Body::earth, static_cast<Body>(-1), static_cast<Body>(99)}) {
        SessionState state;
        state.sky_selected_body = body;
        rejects([&] { encode_session_state(state); });
        state.sky_selected_body.reset();
        state.horizon_selected_body = body;
        rejects([&] { encode_session_state(state); });
    }
    NSArray<NSString *> *fields = @[@"version", @"julian_date", @"simulation_rate", @"mode", @"magnitude_limit",
        @"sky_viewport", @"horizon_viewport", @"solar_camera", @"selected_body", @"constellations", @"observer_latitude_deg",
        @"observer_longitude_deg", @"planets", @"radius_display", @"stars", @"grids", @"renderer", @"show_time_info", @"show_nebulae",
        @"show_galaxies", @"show_quasars", @"milky_way_mode", @"time_settings", @"small_bodies", @"satellites", @"spacecraft", @"selected_star_name_hips", @"earth_layers", @"atmosphere", @"eclipse", @"plus_time", @"show_landscape_image"];
    for (NSString *field in fields) {
        rejects_field(field, nil);
        rejects_field(field, NSNull.null);
        rejects_field(field, @"1");
    }
    for (NSString *field in @[@"version", @"julian_date", @"simulation_rate", @"mode", @"magnitude_limit",
                              @"selected_body", @"observer_latitude_deg", @"observer_longitude_deg"])
        rejects_field(field, @YES);
    for (NSString *field in @[@"show_time_info", @"show_nebulae",
                              @"show_galaxies", @"show_quasars"])
        rejects_field(field, @1);
    rejects_field(@"sky_viewport", @[]);
    rejects_field(@"horizon_viewport", @[]);
    rejects_field(@"solar_camera", @[]);
    for (NSString *field in @[@"version", @"mode", @"selected_body"]) rejects_field(field, @1.5);

    for (NSString *parent in @[@"sky_viewport", @"horizon_viewport", @"solar_camera", @"time_settings", @"planets", @"radius_display", @"stars", @"grids", @"renderer", @"small_bodies", @"satellites", @"spacecraft", @"constellations", @"earth_layers", @"atmosphere", @"eclipse", @"plus_time"]) {
        NSMutableDictionary *object = session_object();
        NSArray *keys = [object[parent] allKeys];
        for (NSString *key in keys) {
            if ([parent isEqualToString:@"solar_camera"] &&
                ([key isEqualToString:@"roll_deg"] || [key isEqualToString:@"frame_is_orbit"] || [key isEqualToString:@"fov_deg"])) continue;
            if ([parent isEqualToString:@"horizon_viewport"] &&
                ([key isEqualToString:@"roll_deg"] || [key isEqualToString:@"fov_deg"])) continue;
            object = session_object();
            [object[parent] removeObjectForKey:key];
            rejects([&] { decode_session_state(json_bytes(object)); });
        }
    }
}

void test_ranges_and_camera() {
    for (id version in @[@0, @1, @2, @3, @4, @5, @6, @7, @8, @10, @(-1), @4294967296.0]) rejects_field(@"version", version);
    for (id mode in @[@(-1), @3]) rejects_field(@"mode", mode);
    for (id body in @[@(-1), @11]) rejects_field(@"selected_body", body);
    for (id value in @[@0, @0.5, @(-0.5), @2592001, @(-2592001)]) rejects_field(@"simulation_rate", value);
    for (id value in @[@(-90.1), @90.1]) rejects_field(@"observer_latitude_deg", value);
    for (id value in @[@(-180.1), @180.1]) rejects_field(@"observer_longitude_deg", value);
    for (NSDictionary *change in @[@{@"zoom": @0}, @{@"zoom": @181}, @{@"zoom": @1.0, @"center_dec_deg": @1},
                                   @{@"center_ra_deg": @(-0.1)}, @{@"center_ra_deg": @360},
                                   @{@"center_dec_deg": @90}]) {
        NSMutableDictionary *object = session_object();
        [object[@"sky_viewport"] addEntriesFromDictionary:change];
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (NSDictionary *change in @[@{@"zoom": @0}, @{@"zoom": @181}, @{@"zoom": @1.0, @"center_altitude_deg": @(-90.1)},
                                   @{@"center_azimuth_deg": @(-0.1)}, @{@"center_azimuth_deg": @360},
                                   @{@"center_altitude_deg": @90.1}, @{@"center_altitude_deg": @YES},
                                   @{@"roll_deg": @YES}, @{@"roll_deg": NSNull.null}, @{@"roll_deg": @"1"},
                                   @{@"fov_deg": @YES}, @{@"fov_deg": NSNull.null}, @{@"fov_deg": @"1"},
                                   @{@"fov_deg": @0}, @{@"fov_deg": @(-1)}, @{@"fov_deg": @180.1}]) {
        NSMutableDictionary *object = session_object();
        [object[@"horizon_viewport"] addEntriesFromDictionary:change];
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (NSDictionary *change in @[@{@"pitch_deg": @90}, @{@"distance_au": @0}, @{@"distance_au": @(maximum_solar_distance_au * 2)},
                                   @{@"distance_au": @1e-10}, @{@"target": @[@1, @2]},
                                   @{@"target": @[@1, @2, @YES]}, @{@"frame": @{}},
                                   @{@"frame": @{@"right": @[@1, @0, @0], @"up": @[@0, @1, @0],
                                                 @"outward": @[@0, @0, @(-1)]}}]) {
        NSMutableDictionary *object = session_object();
        [object[@"solar_camera"] addEntriesFromDictionary:change];
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (id value in @[@(-1), @4, @YES, @0.5]) rejects_field(@"milky_way_mode", value);
    for (NSDictionary *change in @[@{@"step": @(-1)}, @{@"step": @11}, @{@"step": @1.5},
                                   @{@"custom_seconds": @0}, @{@"custom_seconds": @2592001},
                                   @{@"utc_offset_minutes": @(-841)}, @{@"utc_offset_minutes": @841},
                                   @{@"utc_offset_minutes": @YES}]) {
        NSMutableDictionary *object = session_object();
        [object[@"time_settings"] addEntriesFromDictionary:change];
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    SessionState bad;
    bad.julian_date = std::numeric_limits<double>::infinity();
    rejects([&] { encode_session_state(bad); });
    bad = SessionState{};
    bad.simulation_rate = std::numeric_limits<double>::quiet_NaN();
    rejects([&] { encode_session_state(bad); });
    bad = SessionState{};
    bad.solar_camera.target.x = std::numeric_limits<double>::quiet_NaN();
    rejects([&] { encode_session_state(bad); });
    bad = SessionState{};
    bad.milky_way_mode = static_cast<MilkyWayMode>(4);
    rejects([&] { encode_session_state(bad); });
    bad = SessionState{};
    bad.time_settings.custom_seconds = 0;
    rejects([&] { encode_session_state(bad); });
    bad = SessionState{};
    bad.version = 2;
    rejects([&] { encode_session_state(bad); });
    bad = SessionState{};
    bad.selected_body = static_cast<Body>(11);
    rejects([&] { encode_session_state(bad); });
    bad = SessionState{};
    bad.horizon_viewport.vertical_fov_deg = std::numeric_limits<double>::quiet_NaN();
    rejects([&] { encode_session_state(bad); });
    bad = SessionState{};
    bad.magnitude_limit = std::numeric_limits<double>::infinity();
    rejects([&] { encode_session_state(bad); });
}

void test_precise_camera() {
    SessionState state;
    state.solar_camera.set_target_pc({1e9, -2e9, 3e9});
    state.solar_camera.translate_target_au({0.001, -0.002, 0.003});
    const auto json = encode_session_state(state);
    const auto restored = decode_session_state(json);
    check(encode_session_state(restored) == json && restored.solar_camera.precise_target &&
          restored.solar_camera.precise_target->anchor_pc.x == 1e9 &&
          restored.solar_camera.precise_target->anchor_pc.y == -2e9 &&
          restored.solar_camera.precise_target->anchor_pc.z == 3e9 &&
          restored.solar_camera.precise_target->offset_au.x == 0.001 &&
          restored.solar_camera.precise_target->offset_au.y == -0.002 &&
          restored.solar_camera.precise_target->offset_au.z == 0.003,
          "precise camera target did not roundtrip");

    NSData *data = [NSData dataWithBytes:json.data() length:json.size()];
    auto object = (NSMutableDictionary *)[NSJSONSerialization JSONObjectWithData:data
        options:NSJSONReadingMutableContainers error:nil];
    object[@"solar_camera"][@"target"] = @[@1, @2, @3];
    const auto authoritative = decode_session_state(json_bytes(object));
    check(authoritative.solar_camera.precise_target &&
          authoritative.solar_camera.precise_target->anchor_pc.x == 1e9 &&
          authoritative.solar_camera.target.x != 1,
          "precise target was not authoritative over legacy target");
    object[@"solar_camera"][@"target"] = @[@1, @YES, @3];
    rejects([&] { decode_session_state(json_bytes(object)); });
    object[@"solar_camera"][@"target"] = @[@1, @2, @3];
    [object[@"solar_camera"] removeObjectForKey:@"precise_target"];
    const auto legacy = decode_session_state(json_bytes(object));
    check(!legacy.solar_camera.precise_target && legacy.solar_camera.target.x == 1 &&
          legacy.solar_camera.target.y == 2 && legacy.solar_camera.target.z == 3,
          "legacy v9 target was not restored in AU");

    SessionState edge;
    edge.solar_camera.set_target_pc({1e40, -1e40, 0});
    edge.solar_camera.translate_target_au({1e-10, -1e-10, 1e-10});
    const auto edgeRestored = decode_session_state(encode_session_state(edge));
    check(edgeRestored.solar_camera.precise_target &&
          edgeRestored.solar_camera.precise_target->offset_au.x == 1e-10,
          "precise camera boundary did not roundtrip");

    for (id value in @[NSNull.null, @YES, @1, @"target", @[], @{},
        @{@"anchor_pc": @[@1, @2, @3]}, @{@"offset_au": @[@1, @2, @3]},
        @{@"anchor_pc": @[@1, @2], @"offset_au": @[@1, @2, @3]},
        @{@"anchor_pc": @[@1, @YES, @3], @"offset_au": @[@1, @2, @3]},
        @{@"anchor_pc": @[@1, @2, @3], @"offset_au": @[@1, @"2", @3]},
        @{@"anchor_pc": @[@(std::numeric_limits<double>::max()), @0, @0], @"offset_au": @[@0, @0, @0]}]) {
        auto invalid = session_object();
        invalid[@"solar_camera"][@"precise_target"] = value;
        rejects([&] { decode_session_state(json_bytes(invalid)); });
    }
    auto invalid = state;
    invalid.solar_camera.precise_target->offset_au.x = std::numeric_limits<double>::infinity();
    rejects([&] { encode_session_state(invalid); });
}

void test_display_option_boundaries() {
    for (NSString *parent in @[@"planets", @"stars", @"grids", @"renderer", @"earth_layers", @"eclipse"]) {
        for (NSString *key in [session_object()[parent] allKeys]) {
            if ([key isEqualToString:@"marking"] || [key isEqualToString:@"brightness"]) continue;
            for (id value in @[@0, @1, @"true", NSNull.null, @[]]) {
                NSMutableDictionary *object = session_object();
                object[parent][key] = value;
                rejects([&] { decode_session_state(json_bytes(object)); });
            }
        }
    }
    for (id value in @[@(-1), @3, @0.5, @YES, @"None", NSNull.null]) {
        NSMutableDictionary *object = session_object();
        object[@"stars"][@"marking"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    SessionState state;
    state.stars.marking = static_cast<StarMarking>(99);
    rejects([&] { encode_session_state(state); });
    for (unsigned bits = 0; bits < 16; ++bits) {
        SessionState state;
        state.eclipse = {bool(bits & 1), bool(bits & 2), bool(bits & 4), bool(bits & 8)};
        const auto restored = decode_session_state(encode_session_state(state)).eclipse;
        check(restored.shadows == state.eclipse.shadows && restored.shadow_borders == state.eclipse.shadow_borders &&
              restored.shadow_umbra == state.eclipse.shadow_umbra && restored.shadow_penumbra == state.eclipse.shadow_penumbra,
              "eclipse options lost an independent flag");
    }
}

void test_v6_display_boundaries() {
    for (id value in @[@{}, @YES, @1, @[@0], @[@(-1)], @[@1.5], @[@YES], @[@"1"],
                      @[@2147483648.0], @[@1, @1], @[NSNull.null], @[@[]]])
        rejects_field(@"selected_star_name_hips", value);
    auto object = session_object();
    object[@"selected_star_name_hips"] = @[@2147483647, @2, @1];
    check(decode_session_state(json_bytes(object)).selected_star_name_hips ==
          std::set<std::int32_t>({1, 2, 2147483647}), "HIP order affected membership");
    for (const auto hip : {-1, 0}) {
        SessionState bad; bad.selected_star_name_hips.insert(hip);
        rejects([&] { encode_session_state(bad); });
    }
    for (id value in @[@YES, @"1", NSNull.null, @[], @0, @(-1), @1e100, @1e-100]) {
        object = session_object(); object[@"stars"][@"brightness"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (const float value : {std::numeric_limits<float>::denorm_min(), 1.f, std::numeric_limits<float>::max()}) {
        SessionState state; state.stars.brightness = value;
        check(decode_session_state(encode_session_state(state)).stars.brightness == value,
              "positive finite float brightness boundary lost");
    }
    for (const float value : {0.f, -1.f, std::numeric_limits<float>::infinity(), std::numeric_limits<float>::quiet_NaN()}) {
        SessionState bad; bad.stars.brightness = value;
        rejects([&] { encode_session_state(bad); });
    }
    for (id value in @[@YES, @"1", NSNull.null, @[], @(-1), @3, @0.5]) {
        object = session_object(); object[@"atmosphere"][@"mode"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (id value in @[@YES, @"1", NSNull.null, @[], @(-1), @1e100]) {
        object = session_object(); object[@"atmosphere"][@"intensity"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (const auto mode : {AtmosphereMode::none, AtmosphereMode::single, AtmosphereMode::multiple})
        for (const double value : {0., std::numeric_limits<double>::denorm_min(), static_cast<double>(std::numeric_limits<float>::max())}) {
            SessionState state; state.atmosphere = {mode, value};
            const auto restored = decode_session_state(encode_session_state(state));
            check(restored.atmosphere.mode == mode && restored.atmosphere.intensity == value,
                  "atmosphere enum/intensity boundary changed");
        }
    for (const double value : {-1., std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN(), 1e100}) {
        SessionState bad; bad.atmosphere.intensity = value;
        rejects([&] { encode_session_state(bad); });
    }
    SessionState bad; bad.atmosphere.mode = static_cast<AtmosphereMode>(3);
    rejects([&] { encode_session_state(bad); });
    object = session_object(); object[@"stars"][@"future"] = @YES;
    check(encode_session_state(decode_session_state(json_bytes(object))) == encode_session_state(SessionState{}),
          "nested unknown field policy changed");
    // 正当な HIP でも保存ファイル全体の上限を越す集合は拒否する。
    SessionState large;
    for (std::int32_t hip = 1; hip <= 150000; ++hip) large.selected_star_name_hips.insert(hip);
    rejects([&] { encode_session_state(large); });
}

void test_plus_time_zone() {
    const auto default_json = encode_session_state(SessionState{});
    check(!decode_session_state(default_json).plus_time_zone, "default timezone was inferred");
    check(session_object()[@"plus_time_zone"] == NSNull.null, "absent timezone was not encoded as null");
    SessionState state;
    state.time_settings.utc_offset_minutes = 540;
    check(!decode_session_state(encode_session_state(state)).plus_time_zone,
          "UI offset was copied into an unset Plus timezone");
    for (std::int32_t seconds : {std::numeric_limits<std::int32_t>::min(), -32400, -1, 0, 1, 19800,
                                 std::numeric_limits<std::int32_t>::max()}) {
        state.plus_time_zone = PlusTimeZone(seconds);
        const auto json = encode_session_state(state);
        const auto restored = decode_session_state(json);
        check(restored.plus_time_zone && restored.plus_time_zone->seconds_west_of_utc == seconds,
              "explicit Plus timezone changed or became unset");
        check(restored.time_settings.utc_offset_minutes == 540,
              "Plus timezone overwrote the independent UI offset");
        check(encode_session_state(restored) == json, "explicit timezone did not roundtrip exactly");
    }
    state.plus_time_zone.reset();
    check(!decode_session_state(encode_session_state(state)).plus_time_zone, "cleared timezone remained set");
    rejects_field(@"plus_time_zone", nil);
    for (id value in @[@YES, @NO, @0, @1.5, @"UTC", @[], @{}]) rejects_field(@"plus_time_zone", value);
    for (id value in @[@YES, @NO, NSNull.null, @"0", @[], @{}, @0.5, @(-0.5),
                       @(-2147483649LL), @2147483648LL, @(-2147483648.25), @2147483647.25]) {
        auto object = session_object();
        object[@"plus_time_zone"] = @{@"seconds_west_utc": value};
        const auto before = encode_session_state(state);
        rejects([&] { state = decode_session_state(json_bytes(object)); });
        check(encode_session_state(state) == before, "invalid timezone partially replaced the caller state");
    }
    auto object = session_object();
    object[@"plus_time_zone"] = @{@"seconds_west_utc": @0, @"future_extension": @YES};
    const auto with_extra = decode_session_state(json_bytes(object));
    check(with_extra.plus_time_zone && with_extra.plus_time_zone->seconds_west_of_utc == 0,
          "nested timezone extra changed the existing inert-key policy");
    // 非有限数値は Foundation のシリアライズ前に拒否されるため、JSON入力を直接作る。
    const auto zone_key = default_json.find("\"plus_time_zone\"");
    check(zone_key != std::string::npos, "encoded session has no timezone key");
    const auto null_value = default_json.find("null", zone_key);
    check(null_value != std::string::npos, "encoded default timezone is not null");
    for (const std::string token : {"NaN", "1e999", "-1e999"}) {
        auto invalid_number = default_json;
        invalid_number.replace(null_value, 4, "{\"seconds_west_utc\":" + token + "}");
        rejects([&] { decode_session_state(invalid_number); });
    }
    state.version = 7;
    rejects([&] { encode_session_state(state); });
}

void test_json_limits() {
    for (std::string_view text : {"", "null", "true", "[]", "{}", "{", "{\"version\":NaN}",
                                  "{\"version\":1e999}", "{\"version\":1,}"})
        rejects([&] { decode_session_state(text); });
    const std::string invalid_utf8("\xff\xfe\xff", 3);
    rejects([&] { decode_session_state(invalid_utf8); });
    auto maximum = encode_session_state(SessionState{});
    maximum.resize(maximum_session_state_bytes, ' ');
    check(decode_session_state(maximum).version == 9, "size limit rejected exact boundary");
    maximum += ' ';
    rejects([&] { decode_session_state(maximum); });
}

void test_layer_roundtrip_and_boundaries() {
    SessionState state;
    const std::string raw_key("\x82\xa0.dat");
    state.small_bodies.visible = true;
    state.small_bodies.kinds = {{{false,true,false,true}, {true,false,true,false}, {true,true,true,true}}};
    state.small_bodies.selected_ids = {{raw_key,3}, {"mp.dat",0}};
    state.small_bodies.sources = {session_source_identity(raw_key, std::string("x\0y",3)),
                                 session_source_identity("mp.dat", "original")};
    state.small_bodies.orbit_sampling = {2451000.25,2452000.75,4096};
    state.satellites.options = {false,true,true,true};
    state.satellites.selected_ids = {{"ssystem.dat",2}};
    state.satellites.sources = {session_source_identity("ssystem.dat", "system")};
    state.spacecraft = {true,false,true,true};
    state.constellations.default_visible = false;
    state.constellations.exceptions = {"Ser",std::string("\x82\xa0")};
    const auto json = encode_session_state(state);
    const auto decoded = decode_session_state(json);
    check(encode_session_state(decoded) == json, "all v8 display layers roundtrip exactly");
    check(decoded.small_bodies.selected_ids[0].source_key == raw_key &&
          decoded.constellations.exceptions == state.constellations.exceptions,
          "non-UTF8 source and constellation IDs preserved losslessly");
    check(decoded.spacecraft.visible && !decoded.spacecraft.points && decoded.spacecraft.labels && decoded.spacecraft.orbits,
          "spacecraft flags are independent");

    NSData *data = [NSData dataWithBytes:json.data() length:json.size()];
    auto configured = [&]() -> NSMutableDictionary * {
        return [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    };
    for (NSString *parent in @[@"small_bodies", @"satellites"]) {
        for (NSString *field in @[@"selected_ids", @"sources"]) {
            for (id value in @[@{}, NSNull.null, @"array", @[@YES]]) {
                auto object = configured(); object[parent][field] = value;
                rejects([&] { decode_session_state(json_bytes(object)); });
            }
        }
        for (id value in @[@YES,@(-1),@0.5,@9007199254740992.0,@"2",NSNull.null]) {
            auto object = configured(); object[parent][@"selected_ids"][0][@"record_ordinal"] = value;
            rejects([&] { decode_session_state(json_bytes(object)); });
            object = configured(); object[parent][@"sources"][0][@"byte_count"] = value;
            rejects([&] { decode_session_state(json_bytes(object)); });
        }
        for (NSString *value in @[@"",@"%%%",@"YQ",@"YQ==\n",@"YQ===",@"AA=="]) {
            auto object = configured(); object[parent][@"selected_ids"][0][@"source_key_base64"] = value;
            rejects([&] { decode_session_state(json_bytes(object)); });
        }
        for (id value in @[@"",@"BAD",@"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",@YES,NSNull.null]) {
            auto object = configured(); object[parent][@"sources"][0][@"sha256"] = value;
            rejects([&] { decode_session_state(json_bytes(object)); });
        }
        for (NSString *field in @[@"selected_ids",@"sources"]) {
            auto object = configured(); [object[parent][field] addObject:object[parent][field][0]];
            rejects([&] { decode_session_state(json_bytes(object)); });
        }
        auto object = configured(); object[parent][@"sources"] = @[];
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (id value in @[@[],@[@{}],@[@{},@{},@{},@{}],@{},NSNull.null]) {
        auto object = configured(); object[@"small_bodies"][@"kinds"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (NSString *key in @[@"visible",@"labels",@"orbits",@"selected_only"]) {
        for (id value in @[@1,NSNull.null,@"true"]) {
            auto object = configured(); object[@"small_bodies"][@"kinds"][0][key] = value;
            rejects([&] { decode_session_state(json_bytes(object)); });
            object = configured(); object[@"satellites"][@"options"][key] = value;
            rejects([&] { decode_session_state(json_bytes(object)); });
        }
    }
    for (NSString *parent in @[@"spacecraft",@"constellations"]) {
        auto base = configured();
        for (NSString *key in [base[parent] allKeys]) {
            if ([key isEqualToString:@"exceptions_base64"]) continue;
            auto object = configured(); object[parent][key] = @1;
            rejects([&] { decode_session_state(json_bytes(object)); });
        }
    }
    for (id value in @[@[@"U2Vy",@"U2Vy"],@[@"%%%"],@[@""],@[@"AA=="],@{},@[@YES]]) {
        auto object = configured(); object[@"constellations"][@"exceptions_base64"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (NSDictionary *change in @[@{@"first_jd":@YES},@{@"last_jd":@2451000.25},
                                   @{@"sample_count":@1},@{@"sample_count":@4097},@{@"sample_count":@2.5}]) {
        auto object = configured(); [object[@"small_bodies"][@"orbit_sampling"] addEntriesFromDictionary:change];
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
}
} // namespace

int main() {
    @autoreleasepool {
        try {
            test_roundtrip();
            test_missing_null_and_types();
            test_ranges_and_camera();
            test_precise_camera();
            test_display_option_boundaries();
            test_v6_display_boundaries();
            test_plus_time_zone();
            test_json_limits();
            test_layer_roundtrip_and_boundaries();
            std::cout << "session state: " << checks << " checks passed\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "session state: " << error.what() << '\n';
            return 1;
        }
    }
}
