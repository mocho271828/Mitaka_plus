#include "session_state.hpp"
#include "session_layers_json.h"
#include "playback_clock.hpp"
#include "radius_display_validation.hpp"
#include "star_brightness.hpp"

#import <Foundation/Foundation.h>

#include <cmath>
#include <algorithm>
#include <limits>
#include <stdexcept>

namespace mitaka::gui {
namespace {

[[noreturn]] void invalid(NSString *field) {
    throw std::invalid_argument("session state: invalid or missing " + std::string(field.UTF8String));
}

id required(NSDictionary *object, NSString *key) {
    id value = object[key];
    if (!value) invalid(key);
    return value;
}

NSDictionary *dictionary(id value, NSString *field) {
    if (![value isKindOfClass:NSDictionary.class]) invalid(field);
    return (NSDictionary *)value;
}

bool is_boolean(id value) {
    return [value isKindOfClass:NSNumber.class] &&
        CFGetTypeID((__bridge CFTypeRef)value) == CFBooleanGetTypeID();
}

double number(id value, NSString *field) {
    if (![value isKindOfClass:NSNumber.class] || is_boolean(value)) invalid(field);
    const double result = [value doubleValue];
    if (!std::isfinite(result)) invalid(field);
    return result;
}

double numeric_field(NSDictionary *object, NSString *key) {
    return number(required(object, key), key);
}

int integer_field(NSDictionary *object, NSString *key, int low, int high) {
    const double value = numeric_field(object, key);
    if (std::trunc(value) != value || value < low || value > high) invalid(key);
    return static_cast<int>(value);
}

std::optional<Body> optional_body(NSDictionary *object, NSString *key) {
    if (required(object, key) == NSNull.null) return std::nullopt;
    const auto body = static_cast<Body>(integer_field(object, key, 0, static_cast<int>(Body::moon)));
    if (body == Body::earth) invalid(key);
    return body;
}

bool boolean_field(NSDictionary *object, NSString *key) {
    id value = required(object, key);
    if (!is_boolean(value)) invalid(key);
    return [value boolValue];
}

Vec3 vector_field(NSDictionary *object, NSString *key) {
    id value = required(object, key);
    if (![value isKindOfClass:NSArray.class] || [value count] != 3) invalid(key);
    NSArray *components = (NSArray *)value;
    return {number(components[0], key), number(components[1], key), number(components[2], key)};
}

NSArray *vector_json(Vec3 value) { return @[@(value.x), @(value.y), @(value.z)]; }

void validate_viewport(double horizontal, double vertical, double zoom, double maximum_vertical, NSString *field) {
    if (!std::isfinite(horizontal) || horizontal < 0 || horizontal >= 360 ||
        !std::isfinite(vertical) || !std::isfinite(zoom) || zoom < 1 || zoom > 180 ||
        std::abs(vertical) > maximum_vertical) invalid(field);
}

void validate(const SessionState& state) {
    if (state.version != 9) invalid(@"version");
    if (!std::isfinite(state.julian_date)) invalid(@"julian_date");
    PlaybackClock rate_validation;
    rate_validation.set_rate(state.simulation_rate);
    if (state.mode < 0 || state.mode > 2) invalid(@"mode");
    if (!std::isfinite(state.magnitude_limit)) invalid(@"magnitude_limit");
    validate_time_settings(state.time_settings);
    (void)plus_time_rate(state.plus_time);
    validate_star_display(state.stars);
    validate_terrain_amplification(state.terrain_amplification);
    validate_radius_display_state(state.radius_display, state.radius_scale_mode);
    for (const auto hip : state.selected_star_name_hips)
        if (hip <= 0) invalid(@"selected_star_name_hips");
    validate_atmosphere_display(state.atmosphere);
    validate_session_layers(state.small_bodies, state.satellites, state.constellations);
    const int background = static_cast<int>(state.milky_way_mode);
    if (background < 0 || background > 3) invalid(@"milky_way_mode");
    const auto& sky = state.sky_viewport;
    validate_viewport(sky.center_ra_deg, sky.center_dec_deg, sky.zoom, 90 - 90 / sky.zoom, @"sky_viewport");
    const auto& horizon = state.horizon_viewport;
    validate_viewport(horizon.center_azimuth_deg, horizon.center_altitude_deg, 1, 90, @"horizon_viewport");
    if (!std::isfinite(horizon.vertical_fov_deg) || horizon.vertical_fov_deg <= 0 ||
        horizon.vertical_fov_deg > 180) invalid(@"horizon_viewport.fov_deg");
    if (!std::isfinite(horizon.roll_deg)) invalid(@"horizon_viewport.roll_deg");
    // 保存状態のカメラも描画時と同じ基底・距離の契約を通す。
    (void)solar_camera_basis(state.solar_camera);
    const int selected = static_cast<int>(state.selected_body);
    if (selected < 0 || selected > static_cast<int>(Body::moon)) invalid(@"selected_body");
    for (const auto body : {state.sky_selected_body, state.horizon_selected_body})
        if (body && (static_cast<int>(*body) < 0 || *body > Body::moon || *body == Body::earth))
            invalid(@"sky/horizon selected body");
    if (!std::isfinite(state.observer_latitude_deg) || std::abs(state.observer_latitude_deg) > 90)
        invalid(@"observer_latitude_deg");
    if (!std::isfinite(state.observer_longitude_deg) || std::abs(state.observer_longitude_deg) > 180)
        invalid(@"observer_longitude_deg");
}

} // namespace

SessionState decode_session_state(std::string_view json) {
    if (json.empty() || json.size() > maximum_session_state_bytes) invalid(@"JSON size");
    @autoreleasepool {
        NSData *data = [NSData dataWithBytes:json.data() length:json.size()];
        NSError *error = nil;
        id root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!root || error) invalid(@"JSON");
        NSDictionary *object = dictionary(root, @"root object");
        SessionState state;
        state.version = static_cast<std::uint32_t>(integer_field(object, @"version", 9, 9));
        state.julian_date = numeric_field(object, @"julian_date");
        state.simulation_rate = numeric_field(object, @"simulation_rate");
        state.mode = integer_field(object, @"mode", 0, 2);
        state.magnitude_limit = numeric_field(object, @"magnitude_limit");
        NSDictionary *sky = dictionary(required(object, @"sky_viewport"), @"sky_viewport");
        state.sky_viewport = {numeric_field(sky, @"center_ra_deg"), numeric_field(sky, @"center_dec_deg"),
                              numeric_field(sky, @"zoom")};
        NSDictionary *horizon = dictionary(required(object, @"horizon_viewport"), @"horizon_viewport");
        const double horizon_azimuth = numeric_field(horizon, @"center_azimuth_deg");
        const double horizon_altitude = numeric_field(horizon, @"center_altitude_deg");
        const double horizon_zoom = numeric_field(horizon, @"zoom");
        validate_viewport(horizon_azimuth, horizon_altitude, horizon_zoom, 90, @"horizon_viewport");
        const double horizon_fov = horizon[@"fov_deg"] ? numeric_field(horizon, @"fov_deg") : 180 / horizon_zoom;
        state.horizon_viewport = {horizon_azimuth, horizon_altitude, horizon_fov};
        if (horizon[@"roll_deg"]) state.horizon_viewport.roll_deg = numeric_field(horizon, @"roll_deg");
        NSDictionary *camera = dictionary(required(object, @"solar_camera"), @"solar_camera");
        const Vec3 legacy_target = vector_field(camera, @"target");
        if (id precise_value = camera[@"precise_target"]) {
            NSDictionary *precise = dictionary(precise_value, @"precise_target");
            state.solar_camera.set_target_pc(vector_field(precise, @"anchor_pc"));
            state.solar_camera.translate_target_au(vector_field(precise, @"offset_au"));
        } else {
            state.solar_camera.set_target_au(legacy_target);
        }
        state.solar_camera.yaw_deg = numeric_field(camera, @"yaw_deg");
        state.solar_camera.pitch_deg = numeric_field(camera, @"pitch_deg");
        state.solar_camera.distance_au = numeric_field(camera, @"distance_au");
        if (camera[@"roll_deg"]) state.solar_camera.roll_deg = numeric_field(camera, @"roll_deg");
        if (camera[@"frame_is_orbit"]) state.solar_camera.frame_is_orbit = boolean_field(camera, @"frame_is_orbit");
        id frame = required(camera, @"frame");
        if (frame != NSNull.null) {
            NSDictionary *axes = dictionary(frame, @"frame");
            state.solar_camera.frame = SolarCameraBasis{vector_field(axes, @"outward"),
                vector_field(axes, @"right"), vector_field(axes, @"up")};
        }
        state.selected_body = static_cast<Body>(integer_field(object, @"selected_body", 0,
                                                               static_cast<int>(Body::moon)));
        state.sky_selected_body = optional_body(object, @"sky_selected_body");
        state.horizon_selected_body = optional_body(object, @"horizon_selected_body");
        NSDictionary *planets = dictionary(required(object, @"planets"), @"planets");
        state.planets = {boolean_field(planets, @"visible"), boolean_field(planets, @"labels"),
            boolean_field(planets, @"orbits"), boolean_field(planets, @"axes")};
        NSDictionary *radius = dictionary(required(object, @"radius_display"), @"radius_display");
        state.radius_display = checked_radius_display_options(numeric_field(radius, @"space_planet"),
            numeric_field(radius, @"space_sun"), numeric_field(radius, @"planetarium_planet"),
            numeric_field(radius, @"planetarium_sun_moon"));
        state.radius_scale_mode = static_cast<RadiusScaleMode>(integer_field(radius, @"mode", 0, 1));
        state.terrain_amplification = static_cast<TerrainAmplification>(
            integer_field(object, @"terrain_amplification", 1, 5));
        NSDictionary *stars = dictionary(required(object, @"stars"), @"stars");
        state.stars = {boolean_field(stars, @"visible"), boolean_field(stars, @"proper_names"),
            boolean_field(stars, @"bayer_labels"), boolean_field(stars, @"flamsteed_labels"),
            boolean_field(stars, @"hip_labels"), static_cast<StarMarking>(integer_field(stars, @"marking", 0, 2)),
            boolean_field(stars, @"selected_proper_names_only"), checked_star_brightness(numeric_field(stars, @"brightness"))};
        id selected_hips = required(object, @"selected_star_name_hips");
        if (![selected_hips isKindOfClass:NSArray.class]) invalid(@"selected_star_name_hips");
        for (id item in (NSArray *)selected_hips) {
            const double hip = number(item, @"selected_star_name_hips");
            if (hip < 1 || hip > std::numeric_limits<std::int32_t>::max() || std::trunc(hip) != hip ||
                !state.selected_star_name_hips.insert(static_cast<std::int32_t>(hip)).second)
                invalid(@"selected_star_name_hips");
        }
        NSDictionary *earth = dictionary(required(object, @"earth_layers"), @"earth_layers");
        state.earth_layers = {boolean_field(earth, @"clouds"), boolean_field(earth, @"city_lights")};
        NSDictionary *atmosphere = dictionary(required(object, @"atmosphere"), @"atmosphere");
        state.atmosphere = {static_cast<AtmosphereMode>(integer_field(atmosphere, @"mode", 0, 2)),
            numeric_field(atmosphere, @"intensity")};
        NSDictionary *eclipse = dictionary(required(object, @"eclipse"), @"eclipse");
        state.eclipse = {boolean_field(eclipse, @"shadows"), boolean_field(eclipse, @"shadow_borders"),
            boolean_field(eclipse, @"shadow_umbra"), boolean_field(eclipse, @"shadow_penumbra")};
        NSDictionary *grids = dictionary(required(object, @"grids"), @"grids");
        state.grids = {boolean_field(grids, @"equatorial"), boolean_field(grids, @"ecliptic"),
            boolean_field(grids, @"galactic"), boolean_field(grids, @"horizontal"),
            boolean_field(grids, @"circle_scales"), boolean_field(grids, @"square_scales")};
        NSDictionary *renderer = dictionary(required(object, @"renderer"), @"renderer");
        state.renderer = {boolean_field(renderer, @"antialias"), boolean_field(renderer, @"point_smoothing"),
            boolean_field(renderer, @"line_smoothing"), boolean_field(renderer, @"text_smoothing")};
        state.show_time_info = boolean_field(object, @"show_time_info");
        state.show_nebulae = boolean_field(object, @"show_nebulae");
        state.show_galaxies = boolean_field(object, @"show_galaxies");
        state.show_quasars = boolean_field(object, @"show_quasars");
        state.milky_way_mode = static_cast<MilkyWayMode>(integer_field(object, @"milky_way_mode", 0, 3));
        NSDictionary *time = dictionary(required(object, @"time_settings"), @"time_settings");
        state.time_settings.step = static_cast<TimeStep>(integer_field(time, @"step", 0, 10));
        state.time_settings.custom_seconds = integer_field(time, @"custom_seconds", 1, 2592000);
        state.time_settings.utc_offset_minutes = integer_field(time, @"utc_offset_minutes", -840, 840);
        NSDictionary *plus_time = dictionary(required(object, @"plus_time"), @"plus_time");
        state.plus_time.step = PlusTimeStepState(static_cast<PlusTimeStep>(integer_field(plus_time, @"step", 0, 11)),
            numeric_field(plus_time, @"value_days"));
        state.plus_time.speed = integer_field(plus_time, @"speed", std::numeric_limits<std::int32_t>::min(),
            std::numeric_limits<std::int32_t>::max());
        id zone = required(object, @"plus_time_zone");
        if (zone != NSNull.null) {
            NSDictionary *fields = dictionary(zone, @"plus_time_zone");
            state.plus_time_zone = PlusTimeZone(integer_field(fields, @"seconds_west_utc",
                std::numeric_limits<std::int32_t>::min(), std::numeric_limits<std::int32_t>::max()));
        }
        state.show_landscape_image = boolean_field(object, @"show_landscape_image");
        id identifier = required(object, @"observer_place_identifier_base64");
        if (![identifier isKindOfClass:NSString.class]) invalid(@"observer_place_identifier_base64");
        NSData *identifier_bytes = [[NSData alloc] initWithBase64EncodedString:identifier options:0];
        if (!identifier_bytes || ![[identifier_bytes base64EncodedStringWithOptions:0] isEqualToString:identifier])
            invalid(@"observer_place_identifier_base64");
        if (identifier_bytes.length)
            state.observer_place_identifier.assign(static_cast<const char *>(identifier_bytes.bytes), identifier_bytes.length);
        state.observer_latitude_deg = numeric_field(object, @"observer_latitude_deg");
        state.observer_longitude_deg = numeric_field(object, @"observer_longitude_deg");
        decode_session_layers(object, state);
        validate(state);
        return state;
    }
}

std::string encode_session_state(const SessionState& state) {
    validate(state);
    @autoreleasepool {
        const auto& camera = state.solar_camera;
        const auto& sky = state.sky_viewport;
        const auto& horizon = state.horizon_viewport;
        NSMutableArray *selected_hips = [NSMutableArray array];
        for (const auto hip : state.selected_star_name_hips) [selected_hips addObject:@(hip)];
        id frame = NSNull.null;
        if (camera.frame) frame = @{@"outward": vector_json(camera.frame->outward),
                                   @"right": vector_json(camera.frame->right), @"up": vector_json(camera.frame->up)};
        NSMutableDictionary *camera_object = [@{@"target": vector_json(camera.target), @"yaw_deg": @(camera.yaw_deg),
            @"pitch_deg": @(camera.pitch_deg), @"distance_au": @(camera.distance_au), @"frame": frame,
            @"roll_deg": @(camera.roll_deg), @"frame_is_orbit": @(camera.frame_is_orbit)} mutableCopy];
        if (camera.precise_target) {
            camera_object[@"precise_target"] = @{@"anchor_pc": vector_json(camera.precise_target->anchor_pc),
                                                 @"offset_au": vector_json(camera.precise_target->offset_au)};
        }
        NSMutableDictionary *object = [@{
            @"version": @(state.version), @"julian_date": @(state.julian_date),
            @"simulation_rate": @(state.simulation_rate), @"mode": @(state.mode),
            @"magnitude_limit": @(state.magnitude_limit),
            @"sky_viewport": @{@"center_ra_deg": @(sky.center_ra_deg), @"center_dec_deg": @(sky.center_dec_deg),
                               @"zoom": @(sky.zoom)},
            @"horizon_viewport": @{@"center_azimuth_deg": @(horizon.center_azimuth_deg),
                @"center_altitude_deg": @(horizon.center_altitude_deg),
                @"zoom": @(180 / std::max(horizon.vertical_fov_deg, 1.0)),
                @"fov_deg": @(horizon.vertical_fov_deg), @"roll_deg": @(horizon.roll_deg)},
            @"solar_camera": camera_object,
            @"selected_body": @(static_cast<int>(state.selected_body)),
            @"sky_selected_body": state.sky_selected_body ? @(static_cast<int>(*state.sky_selected_body)) : NSNull.null,
            @"horizon_selected_body": state.horizon_selected_body ? @(static_cast<int>(*state.horizon_selected_body)) : NSNull.null,
            @"planets": @{@"visible": @(state.planets.visible), @"labels": @(state.planets.labels),
                @"orbits": @(state.planets.orbits), @"axes": @(state.planets.axes)},
            @"radius_display": @{@"space_planet": @(state.radius_display.space_planet),
                @"space_sun": @(state.radius_display.space_sun),
                @"planetarium_planet": @(state.radius_display.planetarium_planet),
                @"planetarium_sun_moon": @(state.radius_display.planetarium_sun_moon),
                @"mode": @(static_cast<int>(state.radius_scale_mode))},
            @"terrain_amplification": @(static_cast<int>(state.terrain_amplification)),
            @"stars": @{@"visible": @(state.stars.visible), @"proper_names": @(state.stars.proper_names),
                @"bayer_labels": @(state.stars.bayer_labels), @"flamsteed_labels": @(state.stars.flamsteed_labels),
                @"hip_labels": @(state.stars.hip_labels), @"marking": @(static_cast<int>(state.stars.marking)),
                @"selected_proper_names_only": @(state.stars.selected_proper_names_only), @"brightness": @(state.stars.brightness)},
            @"selected_star_name_hips": selected_hips,
            @"earth_layers": @{@"clouds": @(state.earth_layers.clouds), @"city_lights": @(state.earth_layers.city_lights)},
            @"atmosphere": @{@"mode": @(static_cast<int>(state.atmosphere.mode)), @"intensity": @(state.atmosphere.intensity)},
            @"eclipse": @{@"shadows": @(state.eclipse.shadows), @"shadow_borders": @(state.eclipse.shadow_borders),
                @"shadow_umbra": @(state.eclipse.shadow_umbra), @"shadow_penumbra": @(state.eclipse.shadow_penumbra)},
            @"grids": @{@"equatorial": @(state.grids.equatorial), @"ecliptic": @(state.grids.ecliptic),
                @"galactic": @(state.grids.galactic), @"horizontal": @(state.grids.horizontal),
                @"circle_scales": @(state.grids.circle_scales), @"square_scales": @(state.grids.square_scales)},
            @"renderer": @{@"antialias": @(state.renderer.antialias),
                @"point_smoothing": @(state.renderer.point_smoothing),
                @"line_smoothing": @(state.renderer.line_smoothing),
                @"text_smoothing": @(state.renderer.text_smoothing)},
            @"show_time_info": @(state.show_time_info),
            @"show_nebulae": @(state.show_nebulae),
            @"show_galaxies": @(state.show_galaxies),
            @"show_quasars": @(state.show_quasars),
            @"milky_way_mode": @(static_cast<int>(state.milky_way_mode)),
            @"time_settings": @{@"step": @(static_cast<int>(state.time_settings.step)),
                @"custom_seconds": @(state.time_settings.custom_seconds),
                @"utc_offset_minutes": @(state.time_settings.utc_offset_minutes)},
            @"plus_time": @{@"step": @(static_cast<int>(state.plus_time.step.step())),
                @"value_days": @(state.plus_time.step.value_days()), @"speed": @(state.plus_time.speed)},
            @"plus_time_zone": state.plus_time_zone ?
                @{@"seconds_west_utc": @(state.plus_time_zone->seconds_west_of_utc)} : NSNull.null,
            @"show_landscape_image": @(state.show_landscape_image),
            @"observer_place_identifier_base64": [[NSData dataWithBytes:state.observer_place_identifier.data()
                length:state.observer_place_identifier.size()] base64EncodedStringWithOptions:0],
            @"observer_latitude_deg": @(state.observer_latitude_deg),
            @"observer_longitude_deg": @(state.observer_longitude_deg)
        } mutableCopy];
        [object addEntriesFromDictionary:encode_session_layers(state)];
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:object
            options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:&error];
        if (!data || error) throw std::runtime_error("session state: JSON serialization failed");
        if (data.length > maximum_session_state_bytes) invalid(@"JSON size");
        return std::string(static_cast<const char *>(data.bytes), data.length);
    }
}

} // namespace mitaka::gui
