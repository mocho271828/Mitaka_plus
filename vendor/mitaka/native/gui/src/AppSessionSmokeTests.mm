#import "AppControllerInternal.h"
#include "session_smoke_compare.hpp"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <limits>
#include <stdexcept>

namespace {
void requireSession(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}
}

@implementation AppController (SessionSmokeTests)
- (BOOL)runSessionLayerSmokeTest {
    const auto original = [self sessionState];
    try {
        SessionState saved = original;
        saved.mode = 2;
        auto small = *_smallBodyDisplay;
        std::vector<mitaka::SmallBodyId> smallIds;
        const auto& smallRecords = small.dataset()->records;
        for (std::size_t i = 0; i < std::min<std::size_t>(smallRecords.size(), 3); ++i)
            smallIds.push_back(smallRecords[i].id);
        small.set_selected_ids(smallIds);
        for (const auto kind : {mitaka::SmallBodyKind::asteroid, mitaka::SmallBodyKind::trans_neptunian, mitaka::SmallBodyKind::comet})
            small.set_kind_options(kind, {true, true, true, true});
        saved.small_bodies = capture_small_body_session(small, true, {_jd - 1, _jd + 1, 33});
        auto satellites = *_satelliteDisplay;
        std::vector<mitaka::SatelliteRecordId> satelliteIds;
        for (std::size_t i = 0; i < std::min<std::size_t>(satellites.model()->records().size(), 2); ++i)
            satelliteIds.push_back(satellites.id_at(i));
        satellites.set_selected_ids(satelliteIds);
        satellites.set_options({true, true, true, true});
        saved.satellites = capture_satellite_session(satellites);
        saved.spacecraft = {true, false, true, true};
        const ConstellationDisplayModel constellations(_model->constellations());
        saved.constellations = {true, true, false, false, {}};
        saved.constellations.illustrations = true;
        saved.stars.brightness = .375f;
        saved.stars.selected_proper_names_only = true;
        saved.selected_star_name_hips.clear();
        for (const auto hip : _starNameSelection->known_hips()) {
            saved.selected_star_name_hips.insert(hip);
            if (saved.selected_star_name_hips.size() == 3) break;
        }
        saved.earth_layers = {false, true};
        saved.terrain_amplification = TerrainAmplification::x20;
        saved.radius_display = {2, 3, 4, 5};
        saved.radius_scale_mode = RadiusScaleMode::keep_orbit;
        saved.atmosphere = {AtmosphereMode::single, 4.5};
        saved.eclipse = {false, true, true, true};
        saved.plus_time = {PlusTimeStepState(PlusTimeStep::month, -3.25), 0};
        saved.plus_time_zone = PlusTimeZone(-32400);
        saved.show_landscape_image = false;
        if (_observerPlaces) {
            const auto place = std::find_if(_observerPlaces->places.begin(), _observerPlaces->places.end(), observer_place_is_earth);
            if (place != _observerPlaces->places.end()) {
                saved.observer_place_identifier = place->target_name;
                saved.observer_latitude_deg = place->latitude_degrees;
                saved.observer_longitude_deg = std::remainder(place->longitude_degrees, 360.0);
            }
        }
        saved.milky_way_mode = MilkyWayMode::infrared;
        if (!constellations.abbreviations().empty())
            saved.constellations.exceptions.insert(*constellations.abbreviations().begin());
        const auto savedJSON = encode_session_state(saved);
        requireSession([self applySessionState:saved] && sameSessionSmokeJSON(encode_session_state([self sessionState]), savedJSON),
                       "v9 layer settings or source identities did not reach the application");
        requireSession(_mode.selectedSegment == 2 && _horizon.milkyWayMode == MilkyWayMode::infrared,
                       "Milky Way restore did not reach the active horizon view");

        SessionState changed = saved;
        changed.small_bodies.visible = false;
        for (auto& options : changed.small_bodies.kinds) options = {false, false, false, false};
        changed.small_bodies.selected_ids.clear();
        changed.small_bodies.sources.clear();
        changed.small_bodies.orbit_sampling = {_jd - 2, _jd + 2, 17};
        changed.satellites.options = {false, false, false, false};
        changed.satellites.selected_ids.clear();
        changed.satellites.sources.clear();
        changed.spacecraft = {false, true, false, false};
        changed.constellations = {false, false, true, true, {}};
        changed.constellations.illustrations = false;
        changed.stars.brightness = 2;
        changed.stars.selected_proper_names_only = false;
        changed.selected_star_name_hips.clear();
        changed.earth_layers = {true, false};
        changed.terrain_amplification = TerrainAmplification::x2;
        changed.radius_display = {1, 1, 1, 1};
        changed.radius_scale_mode = RadiusScaleMode::keep_radius;
        changed.atmosphere = {AtmosphereMode::none, 0};
        changed.eclipse = {true, false, false, false};
        changed.plus_time = {PlusTimeStepState(PlusTimeStep::value, .123456789), 0};
        changed.plus_time_zone.reset();
        changed.show_landscape_image = true;
        changed.observer_place_identifier.clear();
        changed.milky_way_mode = MilkyWayMode::none;
        requireSession([self applySessionState:changed] &&
                       sameSessionSmokeJSON(encode_session_state([self sessionState]), encode_session_state(changed)),
                       "v9 layer settings retained a previous option or display-set member");
        requireSession(![_playback plusTimeZone], "null time zone was restored as UTC");
        changed.plus_time_zone = PlusTimeZone(0);
        requireSession([self applySessionState:decode_session_state(encode_session_state(changed))] &&
                       [_playback plusTimeZone] && [_playback plusTimeZone]->seconds_west_of_utc == 0,
                       "explicit UTC time zone was restored as unset");
        requireSession([self applySessionState:decode_session_state(savedJSON)] &&
                       sameSessionSmokeJSON(encode_session_state([self sessionState]), savedJSON),
                       "v9 layer settings did not restore from JSON");

        std::size_t rejected = 0;
        auto requireRejected = [&](SessionState invalid) {
            const auto before = encode_session_state([self sessionState]);
            const auto range = _model->time_range();
            invalid.julian_date = _jd == range.first ? range.second : range.first;
            invalid.spacecraft.visible = !saved.spacecraft.visible;
            // 期待した入力拒否では smoke 用の強制終了だけを無効化する。
            // showError は状態欄を更新するだけで、確認ダイアログや外部書込みはない。
            const BOOL smoke = _smokeTest;
            _smokeTest = NO;
            const BOOL accepted = [self applySessionState:invalid];
            _smokeTest = smoke;
            requireSession(!accepted && encode_session_state([self sessionState]) == before,
                           "invalid v9 display identity partially changed the date or application state");
            ++rejected;
        };
        if (!saved.small_bodies.sources.empty()) {
            SessionState invalid = saved;
            auto& hash = invalid.small_bodies.sources.front().sha256;
            hash.front() = hash.front() == '0' ? '1' : '0';
            requireRejected(invalid);
            invalid = saved;
            invalid.small_bodies.selected_ids.front().record_ordinal = 9007199254740991ULL;
            requireRejected(invalid);
        }
        if (!saved.satellites.sources.empty()) {
            SessionState invalid = saved;
            ++invalid.satellites.sources.front().byte_count;
            requireRejected(invalid);
            invalid = saved;
            invalid.satellites.selected_ids.front().record_ordinal = 9007199254740991ULL;
            requireRejected(invalid);
        }
        SessionState invalid = saved;
        std::string unknown = "session-smoke-unknown";
        while (constellations.abbreviations().count(unknown)) unknown.push_back('_');
        invalid.constellations.exceptions.insert(unknown);
        requireRejected(invalid);
        invalid = saved;
        std::int32_t unknownHIP = std::numeric_limits<std::int32_t>::max();
        while (_starNameSelection->known_hips().count(unknownHIP)) --unknownHIP;
        invalid.selected_star_name_hips.insert(unknownHIP);
        requireRejected(invalid);
        invalid = saved;
        invalid.radius_display.space_planet = 0;
        requireRejected(invalid);
        invalid = saved;
        invalid.radius_display.space_planet = std::numeric_limits<float>::denorm_min();
        requireRejected(invalid);
        invalid = saved;
        invalid.stars.brightness = 0;
        requireRejected(invalid);
        invalid = saved;
        invalid.atmosphere.mode = static_cast<AtmosphereMode>(99);
        requireRejected(invalid);
        invalid = saved;
        invalid.atmosphere.intensity = -1;
        requireRejected(invalid);
        invalid = saved;
        invalid.observer_place_identifier = "session-smoke-missing-place";
        requireRejected(invalid);
        if (!saved.observer_place_identifier.empty()) {
            invalid = saved;
            invalid.observer_latitude_deg = saved.observer_latitude_deg > 0 ? -90 : 90;
            requireRejected(invalid);
        }
        invalid = saved;
        invalid.plus_time = {PlusTimeStepState(PlusTimeStep::value, std::numeric_limits<double>::max()), 1};
        requireRejected(invalid);
        auto moving = saved;
        moving.plus_time.speed = -2;
        requireSession([self applySessionState:moving] && !_playback.playing && !_playback.clockTracking &&
                       sameSessionSmokeJSON(encode_session_state([self sessionState]), savedJSON),
                       "session restore resumed playback or changed the saved Plus time step");

        // 実 host を経由して step の各操作と speed 代入が別の状態遷移になることを検証する。
        requireSession([_playback setClockTracking:YES], "time action tracking setup failed");
        NSString *timeActionError = nil;
        for (const auto kind : {ScriptActionKind::set_time_step, ScriptActionKind::set_time_step_value,
                                ScriptActionKind::previous_time_step, ScriptActionKind::next_time_step}) {
            ScriptAction action{};
            action.kind = kind;
            action.number = kind == ScriptActionKind::set_time_step ? 3 : .125;
            requireSession([self applyScriptTimeAction:action error:&timeActionError] && !timeActionError &&
                           _playback.clockTracking && [_playback plusTimeState].speed == 0,
                           "step action stopped clock tracking");
        }
        ScriptAction stopSpeed{};
        stopSpeed.kind = ScriptActionKind::set_time_speed;
        requireSession([self applyScriptTimeAction:stopSpeed error:&timeActionError] && !timeActionError &&
                       !_playback.clockTracking, "zero speed action retained clock tracking");
        requireSession([self applySessionState:saved], "time action test failed to restore session");

        // 地方時の設定は日時を進めない。再生と補間の両方が動作中でも解釈だけを変更する。
        const auto range = _model->time_range();
        const double animationTarget = _jd < range.second ? std::min(_jd + 1, range.second) : range.first;
        [_playback play];
        NSString *animationError = nil;
        requireSession([_playback animateToJulianDate:animationTarget duration:60
                           curve:PlusTimeAnimationCurve::linear
                           sameTargetPolicy:PlusTimeAnimationSameTarget::replace error:&animationError] &&
                       _playback.playing && _playback.timeAnimating,
                       "time transition with playback did not start");
        const double zoneDate = _jd;
        const double zoneRate = _playback.simulationRate;
        const auto zoneStep = [_playback plusTimeState];
        const auto zoneDisplayOffset = _timeSettings.utc_offset_minutes;
        auto requireZoneTimeUnchanged = [&] {
            const auto step = [_playback plusTimeState];
            requireSession(_jd == zoneDate && _playback.julianDate == zoneDate &&
                           _playback.playing && _playback.timeAnimating && !_playback.clockTracking &&
                           _playback.simulationRate == zoneRate && step.speed == zoneStep.speed &&
                           step.step.step() == zoneStep.step.step() && step.step.value_days() == zoneStep.step.value_days() &&
                           _timeSettings.utc_offset_minutes == zoneDisplayOffset,
                           "zone operation changed date, playback, transition, step, or native display offset");
        };
        [self showPlusTimeZone:nil];
        requireSession(_plusTimeZoneEnabledButton.state == NSControlStateValueOn && _plusTimeZoneField.enabled &&
                       [_plusTimeZoneField.stringValue isEqualToString:@"-32400"],
                       "zone form did not show the current exact integer seconds");
        _plusTimeZoneField.stringValue = @"0";
        [_plusTimeZoneWindow close];
        requireSession([_playback plusTimeZone]->seconds_west_of_utc == -32400,
                       "closing the zone form applied its draft");
        requireZoneTimeUnchanged();
        for (NSString *text in @[@"", @"1.5", @"2147483648", @"-2147483649", @"1,000", @"nan", @"0x10", @"1junk"]) {
            NSString *error = nil;
            requireSession(![self applyPlusTimeZoneText:text enabled:YES error:&error] && error.length &&
                           [_playback plusTimeZone]->seconds_west_of_utc == -32400,
                           "invalid zone form input changed the previous time zone");
            requireZoneTimeUnchanged();
        }
        for (NSNumber *seconds in @[@(INT32_MIN), @0, @(INT32_MAX)]) {
            NSString *error = nil;
            requireSession([self applyPlusTimeZoneText:seconds.stringValue enabled:YES error:&error] &&
                           [_playback plusTimeZone] && [_playback plusTimeZone]->seconds_west_of_utc == seconds.intValue,
                           "valid integer zone form input was not applied exactly");
            requireZoneTimeUnchanged();
        }
        [self showPlusTimeZone:nil];
        _plusTimeZoneEnabledButton.state = NSControlStateValueOff;
        [self changePlusTimeZoneEnabled:nil];
        _plusTimeZoneField.stringValue = @"invalid disabled draft";
        [self applyPlusTimeZone:nil];
        requireSession(!_plusTimeZoneField.enabled && ![_playback plusTimeZone],
                       "disabled zone form did not retain explicit unset state");
        requireZoneTimeUnchanged();
        [self showPlusTimeZone:nil];
        requireSession(_plusTimeZoneEnabledButton.state == NSControlStateValueOff && !_plusTimeZoneField.enabled &&
                       _plusTimeZoneField.stringValue.length == 0, "unset zone form did not reload empty");
        _plusTimeZoneEnabledButton.state = NSControlStateValueOn;
        [self changePlusTimeZoneEnabled:nil];
        _plusTimeZoneField.stringValue = @"-32400";
        [self applyPlusTimeZone:nil];
        requireZoneTimeUnchanged();

        // JSON の整数範囲外は typed state に到達する前に拒否され、動作中の状態も保持する。
        NSData *savedData = [NSData dataWithBytes:savedJSON.data() length:savedJSON.size()];
        for (id seconds in @[@YES, @1.5, @2147483648LL, @(-2147483649LL), @"0", NSNull.null]) {
            NSMutableDictionary *object = [NSJSONSerialization JSONObjectWithData:savedData
                options:NSJSONReadingMutableContainers error:nil];
            object[@"plus_time_zone"] = @{@"seconds_west_utc": seconds};
            NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
            const auto before = encode_session_state([self sessionState]);
            bool rejectedZone = false;
            try {
                const auto decoded = decode_session_state({static_cast<const char *>(data.bytes), data.length});
                [self applySessionState:decoded];
            } catch (const std::invalid_argument&) { rejectedZone = true; }
            requireSession(rejectedZone && sameSessionSmokeJSON(encode_session_state([self sessionState]), before),
                           "invalid zone JSON was accepted or changed the application state");
            requireZoneTimeUnchanged();
            ++rejected;
        }
        requireSession([self animateStarBrightness:2 duration:60 error:&animationError] && _starBrightness.animating,
                       "brightness transition did not start");
        invalid = saved;
        invalid.selected_star_name_hips.insert(unknownHIP);
        requireRejected(invalid);
        requireSession(_starBrightness.animating, "rejected session cancelled the existing brightness transition");
        requireZoneTimeUnchanged();
        requireSession([self applySessionState:original] &&
                       sameSessionSmokeJSON(encode_session_state([self sessionState]), encode_session_state(original)),
                       "v9 layer session smoke did not restore the original application state");
        requireSession(!_starBrightness.animating, "successful session restore retained the brightness transition");
        requireSession(!_playback.playing && !_playback.clockTracking && !_playback.timeAnimating,
                       "successful session restore retained time motion");
        std::printf("Session v9 AppKit smoke passed: all layer options, explicit time zone, %zu small-body IDs, %zu satellite IDs, %zu atomic input rejections\n",
                    smallIds.size(), satelliteIds.size(), rejected);
        return YES;
    } catch (const std::exception& error) {
        std::fprintf(stderr, "Session v9 AppKit smoke failed: %s\n", error.what());
        return NO;
    }
}
@end
