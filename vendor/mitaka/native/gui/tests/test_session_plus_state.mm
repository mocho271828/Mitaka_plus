#include "session_state.hpp"
#import <Foundation/Foundation.h>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka::gui;
int checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class Operation> void rejects(Operation operation) {
    ++checks;
    try { operation(); } catch (const std::invalid_argument&) { return; }
    throw std::runtime_error("invalid Plus session field was accepted");
}
std::string json_bytes(id object) {
    NSError* error = nil;
    NSData* bytes = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    check(bytes && !error, "test fixture serialization failed");
    return {static_cast<const char*>(bytes.bytes), bytes.length};
}
NSMutableDictionary* state_object() {
    const auto json = encode_session_state(SessionState{});
    NSData* bytes = [NSData dataWithBytes:json.data() length:json.size()];
    NSError* error = nil;
    id object = [NSJSONSerialization JSONObjectWithData:bytes options:NSJSONReadingMutableContainers error:&error];
    check([object isKindOfClass:NSMutableDictionary.class] && !error, "test fixture decoding failed");
    return object;
}
void test_roundtrip() {
    for (int step = 0; step <= 11; ++step) {
        for (const auto speed : {std::numeric_limits<std::int32_t>::min(), -1, 0, 1,
                                std::numeric_limits<std::int32_t>::max()}) {
            for (const double days : {-3.25, 0.0, 0.123456789, 36525000.0}) {
                SessionState state;
                state.plus_time = {PlusTimeStepState(static_cast<PlusTimeStep>(step), days), speed};
                state.show_landscape_image = false;
                constexpr char identifier[] = "Planet.Earth.\x82\xa0\0custom";
                state.observer_place_identifier.assign(identifier, sizeof(identifier) - 1);
                const auto saved = encode_session_state(state);
                const auto restored = decode_session_state(saved);
                check(static_cast<int>(restored.plus_time.step.step()) == step &&
                      restored.plus_time.step.value_days() == days && restored.plus_time.speed == speed,
                      "independent enum, day value or signed speed changed");
                check(!restored.show_landscape_image &&
                      restored.observer_place_identifier == state.observer_place_identifier,
                      "landscape choice or original identifier bytes changed");
                check(encode_session_state(restored) == saved, "Plus session did not roundtrip exactly");
            }
        }
    }
}
void test_radius_display() {
    for (const auto mode : {RadiusScaleMode::keep_radius, RadiusScaleMode::keep_orbit}) {
        SessionState state;
        state.radius_display = {std::numeric_limits<float>::min(), 2.5f,
                                std::numeric_limits<float>::denorm_min(),
                                std::numeric_limits<float>::max()};
        state.radius_scale_mode = mode;
        const auto restored = decode_session_state(encode_session_state(state));
        check(restored.radius_display.space_planet == state.radius_display.space_planet &&
              restored.radius_display.space_sun == state.radius_display.space_sun &&
              restored.radius_display.planetarium_planet == state.radius_display.planetarium_planet &&
              restored.radius_display.planetarium_sun_moon == state.radius_display.planetarium_sun_moon &&
              restored.radius_scale_mode == mode, "radius settings did not roundtrip");
    }
    for (NSString *field in @[@"space_planet", @"space_sun", @"planetarium_planet", @"planetarium_sun_moon"]) {
        for (id value in @[NSNull.null, @YES, @"1", @[], @{}, @0, @(-1), @1e-100, @1e100]) {
            auto object = state_object();
            object[@"radius_display"][field] = value;
            rejects([&] { decode_session_state(json_bytes(object)); });
        }
        auto object = state_object();
        [object[@"radius_display"] removeObjectForKey:field];
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (id value in @[NSNull.null, @YES, @"0", @[], @{}, @(-1), @2, @0.5]) {
        auto object = state_object();
        object[@"radius_display"][@"mode"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    SessionState invalid;
    invalid.radius_display.space_planet = 0;
    rejects([&] { encode_session_state(invalid); });
    invalid.radius_display.space_planet = std::numeric_limits<float>::denorm_min();
    rejects([&] { encode_session_state(invalid); });
    auto underflow = state_object();
    underflow[@"radius_display"][@"space_planet"] = @(static_cast<double>(std::numeric_limits<float>::denorm_min()));
    rejects([&] { decode_session_state(json_bytes(underflow)); });
    invalid.radius_display.space_planet = 1;
    invalid.radius_scale_mode = static_cast<RadiusScaleMode>(2);
    rejects([&] { encode_session_state(invalid); });
}
void test_invalid_fields() {
    for (NSString* field in @[@"step", @"value_days", @"speed"]) {
        for (id value in @[NSNull.null, @YES, @"1", @[], @{}]) {
            auto object = state_object();
            object[@"plus_time"][field] = value;
            rejects([&] { decode_session_state(json_bytes(object)); });
        }
        auto object = state_object();
        [object[@"plus_time"] removeObjectForKey:field];
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (id value in @[@(-1), @12, @1.5]) {
        auto object = state_object();
        object[@"plus_time"][@"step"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (id value in @[@(-2147483649.0), @(2147483648.0), @0.5]) {
        auto object = state_object();
        object[@"plus_time"][@"speed"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    for (id value in @[NSNull.null, @YES, @123, @[], @{}, @"!", @"QQ", @"QR==", @"QQ==\n"]) {
        auto object = state_object();
        object[@"observer_place_identifier_base64"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    auto missing = state_object();
    [missing removeObjectForKey:@"observer_place_identifier_base64"];
    rejects([&] { decode_session_state(json_bytes(missing)); });
    for (id value in @[NSNull.null, @1, @"true", @[]]) {
        auto object = state_object();
        object[@"show_landscape_image"] = value;
        rejects([&] { decode_session_state(json_bytes(object)); });
    }
    SessionState overflow;
    overflow.plus_time = {PlusTimeStepState(PlusTimeStep::value, std::numeric_limits<double>::max()), 1};
    rejects([&] { encode_session_state(overflow); });
    // 停止状態なら大きな有限日数はそのまま保存できる。
    overflow.plus_time.speed = 0;
    check(decode_session_state(encode_session_state(overflow)).plus_time.step.value_days() ==
          std::numeric_limits<double>::max(), "finite stationary day value was lost");
}
}
int main() {
    @autoreleasepool {
        try {
            test_roundtrip();
            test_invalid_fields();
            test_radius_display();
            std::cout << "session Plus state tests: " << checks << " checks passed\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "session Plus state tests: " << error.what() << '\n';
            return 1;
        }
    }
}
