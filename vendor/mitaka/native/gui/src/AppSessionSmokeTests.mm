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
        saved.atmosphere = {AtmosphereMode::single, 4.5};
        saved.eclipse = {false, true, true, true};
        saved.plus_time = {PlusTimeStepState(PlusTimeStep::month, -3.25), 0};
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
                       "v7 layer settings or source identities did not reach the application");
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
        changed.atmosphere = {AtmosphereMode::none, 0};
        changed.eclipse = {true, false, false, false};
        changed.plus_time = {PlusTimeStepState(PlusTimeStep::value, .123456789), 0};
        changed.show_landscape_image = true;
        changed.observer_place_identifier.clear();
        changed.milky_way_mode = MilkyWayMode::none;
        requireSession([self applySessionState:changed] &&
                       sameSessionSmokeJSON(encode_session_state([self sessionState]), encode_session_state(changed)),
                       "v7 layer settings retained a previous option or display-set member");
        requireSession([self applySessionState:decode_session_state(savedJSON)] &&
                       sameSessionSmokeJSON(encode_session_state([self sessionState]), savedJSON),
                       "v7 layer settings did not restore from JSON");

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
                           "invalid v7 display identity partially changed the date or application state");
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
        NSString *animationError = nil;
        requireSession([self animateStarBrightness:2 duration:60 error:&animationError] && _starBrightness.animating,
                       "brightness transition did not start");
        invalid = saved;
        invalid.selected_star_name_hips.insert(unknownHIP);
        requireRejected(invalid);
        requireSession(_starBrightness.animating, "rejected session cancelled the existing brightness transition");
        requireSession([self applySessionState:original] &&
                       sameSessionSmokeJSON(encode_session_state([self sessionState]), encode_session_state(original)),
                       "v7 layer session smoke did not restore the original application state");
        requireSession(!_starBrightness.animating, "successful session restore retained the brightness transition");
        std::printf("Session v7 AppKit smoke passed: all layer options, %zu small-body IDs, %zu satellite IDs, %zu atomic input rejections\n",
                    smallIds.size(), satelliteIds.size(), rejected);
        return YES;
    } catch (const std::exception& error) {
        std::fprintf(stderr, "Session v7 AppKit smoke failed: %s\n", error.what());
        return NO;
    }
}
@end
