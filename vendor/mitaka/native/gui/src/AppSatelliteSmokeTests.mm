#import "AppControllerInternal.h"
#import "SolarSystemViewInternal.h"
#include "satellite_scene.hpp"
#include "session_smoke_compare.hpp"
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <limits>
#include <stdexcept>

@interface SolarSystemView (SatelliteSmokeInput)
- (void)pickBodyAtPoint:(NSPoint)point;
@end

namespace {
bool sameSatellitePosition(mitaka::Vec3 a, mitaka::Vec3 b) {
    return std::hypot(a.x-b.x, a.y-b.y, a.z-b.z) < 1e-11;
}
bool sameSatelliteParents(const SolarBodies& a, const SolarBodies& b) {
    for (std::size_t i = 0; i < a.size(); ++i)
        if (a[i].id != b[i].id || !sameSatellitePosition(a[i].position_au, b[i].position_au)) return false;
    return true;
}
bool sameSatelliteCamera(const SolarCamera& a, const SolarCamera& b) {
    if (!sameSatellitePosition(a.target, b.target) || a.distance_au != b.distance_au ||
        a.yaw_deg != b.yaw_deg || a.pitch_deg != b.pitch_deg || a.frame.has_value() != b.frame.has_value()) return false;
    return !a.frame || (sameSatellitePosition(a.frame->outward, b.frame->outward) &&
        sameSatellitePosition(a.frame->right, b.frame->right) && sameSatellitePosition(a.frame->up, b.frame->up));
}
bool clearSatelliteByBlankClick(SolarSystemView *view) {
    const auto planets = view.planetDisplayOptions;
    const BOOL smallBodies = view.smallBodiesVisible;
    const auto satellites = [view satelliteDisplayModel];
    auto hiddenSatellites = std::make_shared<SatelliteDisplayModel>(*satellites);
    auto satelliteOptions = satellites->options();
    satelliteOptions.visible = false;
    hiddenSatellites->set_options(satelliteOptions);
    const BOOL spacecraft = view.spacecraftVisible;
    auto hiddenPlanets = planets;
    hiddenPlanets.visible = false;
    view.planetDisplayOptions = hiddenPlanets;
    view.smallBodiesVisible = NO;
    [view setSatelliteDisplayModel:hiddenSatellites];
    view.spacecraftVisible = NO;
    // クリックは実際に描画された世代を対象とするため、非表示を描画してから操作する。
    [view display];
    const auto displayed = [view displayedScene];
    const bool hidden = !displayed.planet_display.visible && !displayed.small_bodies &&
        displayed.satellite_display && !displayed.satellite_display->options().visible && !displayed.spacecraft;
    [view pickBodyAtPoint:NSMakePoint(NSMidX(view.bounds), NSMidY(view.bounds))];
    view.planetDisplayOptions = planets;
    view.smallBodiesVisible = smallBodies;
    [view setSatelliteDisplayModel:satellites];
    view.spacecraftVisible = spacecraft;
    return hidden;
}
}

@implementation AppController (SatelliteSmokeTests)
- (BOOL)runSatelliteSmokeTest {
    unsigned checks = 0;
    const auto require = [&](bool condition, const char *message) {
        ++checks;
        if (!condition) throw std::runtime_error(message);
    };
    try {
        require(_model && _satelliteModel && _satelliteSnapshot &&
            _satelliteSnapshot->model == _satelliteModel, "satellite source and snapshot were not loaded together");
        const SessionState saved = [self sessionState];
        const auto savedJSON = encode_session_state(saved);
        const auto source = _satelliteModel;
        const auto originalSnapshot = _satelliteSnapshot;
        const auto originalParents = _solarBodies;
        const NSUInteger originalSatellite = _solar.selectedSatelliteIndex;
        const NSUInteger originalSmallBody = _solar.selectedSmallBodyIndex;
        const NSUInteger originalBody = _solar.selectedBodyIndex;
        const std::size_t rowCount = source->model().records().size();
        require(originalSnapshot->julian_date == _jd && originalSnapshot->positions.size() == rowCount,
            "satellite snapshot date or original row count disagrees with the application");
        require(originalSnapshot->positioned_count == static_cast<std::size_t>(std::count_if(
            originalSnapshot->positions.begin(), originalSnapshot->positions.end(), [](const auto& p) { return p.has_value(); })),
            "satellite positioned count disagrees with its original rows");
        [_solar setCameraState:SolarCamera{}];
        _mode.selectedSegment = 1;
        [self changeMode:nil];
        std::optional<std::size_t> positioned, unresolved;
        for (std::size_t i = 0; i < rowCount; ++i) {
            if (originalSnapshot->positions[i] && !positioned) positioned = i;
            if (!originalSnapshot->positions[i] && !unresolved) unresolved = i;
        }
        const auto expectedParents = [&]() {
            const NSUInteger selected = _solar.selectedSatelliteIndex;
            const auto selectedSource = selected < rowCount
                ? std::optional<std::string>{source->source(selected)} : std::nullopt;
            return apply_satellite_parent_positions(_model->solar_bodies(_jd), *_satelliteSnapshot, selectedSource);
        };
        if (rowCount) {
            [self chooseSatellite:rowCount-1 center:NO];
            require(_solar.selectedSatelliteIndex == rowCount-1 && _solar.selectedBodyIndex == NSNotFound &&
                _solar.selectedSmallBodyIndex == NSNotFound && _mode.selectedSegment == 1,
                "satellite application selection did not preserve the original last row index");
            require([_selectionLabel.stringValue containsString:[NSString stringWithUTF8String:source->title(rowCount-1).c_str()]] &&
                !_travelButtons[1].enabled && !_journeyButton.enabled,
                "satellite selection lost its diagnosis or enabled unsupported surface travel");
            require(sameSatelliteParents(_solarBodies, expectedParents()), "selected satellite parents use another source");
        }
        const auto beforeInvalid = _solar.selectedSatelliteIndex;
        const auto cameraBeforeInvalid = [_solar cameraState];
        [self chooseSatellite:rowCount center:YES];
        require(_solar.selectedSatelliteIndex == beforeInvalid && sameSatelliteCamera([_solar cameraState], cameraBeforeInvalid),
            "invalid satellite index changed selection or camera");
        if (positioned) {
            [self chooseSatellite:*positioned center:YES];
            require(sameSatellitePosition([_solar cameraState].target, *_satelliteSnapshot->positions[*positioned]) &&
                _solar.visibleSatelliteCount > 0, "satellite focus disagrees with the absolute core position");
        }
        auto visibleOptions = [self satelliteDisplayOptions];
        visibleOptions.visible = true;
        [self setSatelliteDisplayOptions:visibleOptions];
        [self toggleSatellites:nil];
        const auto hiddenSelection = _solar.selectedSatelliteIndex;
        require(![self satelliteDisplayOptions].visible && _solar.visibleSatelliteCount == 0 && _satelliteSnapshot == originalSnapshot,
            "hiding satellites dropped their source snapshot or still draws them");
        const auto hiddenScene = [_solar scene];
        require(!hiddenScene.satellites && hiddenScene.eclipse_satellites == _satelliteSnapshot.get() &&
            hiddenScene.julian_date == _jd, "hiding satellite markers removed their eclipse casters or date");
        const auto range = _model->time_range();
        const double nextDate = _jd < range.second ? std::min(_jd + 0.25, range.second) : range.first;
        require([self updateDate:nextDate refreshOrbits:NO] && _satelliteSnapshot->julian_date == _jd &&
            _horizon.julianDate == _jd && _satelliteSnapshot->model == source && _satelliteSnapshot->positions.size() == rowCount,
            "hidden satellite update lost the shared date, model or original rows");
        require(_solar.selectedSatelliteIndex == hiddenSelection && ![self satelliteDisplayOptions].visible &&
            sameSatelliteParents(_solarBodies, expectedParents()), "hidden date update lost selection or parent source");
        const auto updatedHiddenScene = [_solar scene];
        require(!updatedHiddenScene.satellites && updatedHiddenScene.eclipse_satellites == _satelliteSnapshot.get() &&
            updatedHiddenScene.julian_date == _jd, "hidden eclipse casters did not receive the updated snapshot and date");
        if (positioned && _satelliteSnapshot->positions[*positioned])
            require(sameSatellitePosition([_solar cameraState].target, *_satelliteSnapshot->positions[*positioned]),
                "satellite following camera did not update at the new date while hidden");
        [self toggleSatellites:nil];
        require([self satelliteDisplayOptions].visible && _satelliteModel == source && _satelliteSnapshot->positions.size() == rowCount,
            "showing satellites replaced or truncated the source");
        unresolved.reset();
        for (std::size_t i = 0; i < rowCount && !unresolved; ++i)
            if (!_satelliteSnapshot->positions[i]) unresolved = i;
        if (unresolved) {
            const auto camera = [_solar cameraState];
            [self chooseSatellite:*unresolved center:YES];
            require(_solar.selectedSatelliteIndex == *unresolved && sameSatelliteCamera(camera, [_solar cameraState]),
                "unresolved satellite focus changed the existing camera");
            require([_selectionLabel.stringValue containsString:@"位置を表示できません"],
                "unresolved satellite selection did not expose its diagnosis");
        }

        require([self setDate:saved.julian_date], "satellite smoke could not restore the initial date");
        [self applySatelliteSnapshot:originalSnapshot];
        bool distinctSourceTested = false;
        // 原本は変更せず、コピー上の補正差によって出典切替の回帰を確実に検出する。
        if (originalSnapshot->evaluations.size() > 1) {
            auto probe = std::make_shared<SatelliteSnapshot>(*originalSnapshot);
            for (std::size_t e = 1; e < probe->evaluations.size() && !distinctSourceTested; ++e) {
                auto& evaluation = probe->evaluations[e];
                const auto& key = evaluation.context.source_key;
                std::optional<std::size_t> chosen;
                for (std::size_t i = 0; i < rowCount && !chosen; ++i)
                    if (source->source(i) == key) chosen = i;
                if (!chosen || evaluation.planets.empty() || !evaluation.planets.front().position_au) continue;
                evaluation.planets.front().position_au->x += 0.25;
                const auto base = _model->solar_bodies(_jd);
                const auto defaults = apply_satellite_parent_positions(base, *probe);
                const auto selected = apply_satellite_parent_positions(base, *probe, key);
                if (sameSatelliteParents(defaults, selected)) continue;
                [_solar selectBody:0];
                [self applySatelliteSnapshot:probe];
                [self chooseSatellite:*chosen center:NO];
                require(sameSatelliteParents(_solarBodies, selected), "distinct satellite source did not update parents");
                [self selectBody:_bodyButtons[3]];
                require(_solar.selectedSatelliteIndex == NSNotFound && sameSatelliteParents(_solarBodies, defaults),
                    "planet selection retained the previous satellite parent source");
                if (_smallBodyModel && !_smallBodyModel->dataset().records.empty()) {
                    [self chooseSatellite:*chosen center:NO];
                    [self chooseSmallBody:0 center:NO];
                    require(_solar.selectedSatelliteIndex == NSNotFound && sameSatelliteParents(_solarBodies, defaults),
                        "small-body selection retained the previous satellite parent source");
                }
                [self chooseSatellite:*chosen center:NO];
                require(clearSatelliteByBlankClick(_solar), "blank-click scene did not render hidden objects");
                require(_solar.selectedSatelliteIndex == NSNotFound && _solar.selectedBodyIndex == NSNotFound &&
                    _solar.selectedSmallBodyIndex == NSNotFound && sameSatelliteParents(_solarBodies, defaults),
                    "blank click retained selection or the previous satellite parent source");
                distinctSourceTested = true;
            }
        }
        [self applySatelliteSnapshot:originalSnapshot];
        [self refreshSatelliteParents];
        if (rowCount) [self chooseSatellite:rowCount-1 center:NO];
        const auto session = [self sessionState];
        const auto json = encode_session_state(session);
        auto changedOptions = session.satellites.options;
        changedOptions.visible = !changedOptions.visible;
        [self setSatelliteDisplayOptions:changedOptions];
        [_solar setCameraState:SolarCamera{}];
        require([self updateDate:nextDate refreshOrbits:NO], "satellite session setup could not change date");
        require([self applySessionState:decode_session_state(json)], "satellite session JSON could not be restored");
        require(_solar.selectedSatelliteIndex == NSNotFound, "session restore retained transient satellite selection");
        require(!_playback.playing, "session restore resumed playback");
        require(!_playback.clockTracking, "session restore resumed clock tracking");
        require(sameSatelliteCamera([_solar cameraState], session.solar_camera), "session restore changed saved camera");
        require(sameSessionSmokeJSON(encode_session_state([self sessionState]), json), "session restore changed saved state");
        require(_satelliteSnapshot->julian_date == session.julian_date && _satelliteSnapshot->model == source &&
            sameSatelliteParents(_solarBodies, expectedParents()), "session restore retained the previous date or satellite parent source");

        require([self applySessionState:saved], "satellite smoke could not restore the previous session");
        [self applySatelliteSnapshot:originalSnapshot];
        if (originalSatellite < rowCount) [_solar selectSatellite:originalSatellite];
        else if (_smallBodyModel && originalSmallBody < _smallBodyModel->dataset().records.size()) [_solar selectSmallBody:originalSmallBody];
        else if (originalBody == NSNotFound)
            require(clearSatelliteByBlankClick(_solar), "restored blank-click scene did not render hidden objects");
        [_solar setCameraState:saved.solar_camera];
        [self refreshSatelliteParents];
        require(sameSessionSmokeJSON(encode_session_state([self sessionState]), savedJSON) && _satelliteSnapshot == originalSnapshot &&
            sameSatelliteParents(_solarBodies, originalParents) && _solar.selectedSatelliteIndex == originalSatellite &&
            _solar.selectedSmallBodyIndex == originalSmallBody && _solar.selectedBodyIndex == originalBody,
            "satellite smoke changed the original snapshot, selection, camera or session");
        std::printf("Satellite AppKit smoke passed: %u checks; source_rows=%zu positioned=%zu focus=%s diagnosis=%s distinct-source=%s\n",
            checks, rowCount, originalSnapshot->positioned_count, positioned ? "tested" : "no-local-position",
            unresolved ? "tested" : "no-unresolved-row", distinctSourceTested ? "tested" : "no-second-verified-source");
        return YES;
    } catch (const std::exception& error) {
        std::fprintf(stderr, "Satellite AppKit smoke failed: %s\n", error.what());
        std::exit(EXIT_FAILURE);
    }
}
@end
