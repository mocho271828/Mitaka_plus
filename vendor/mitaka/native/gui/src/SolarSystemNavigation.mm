#import "SolarSystemViewInternal.h"
#import "SkyView.h"
#include <algorithm>
#include <chrono>
#include <cmath>
#include <exception>

using namespace mitaka;
using namespace mitaka::gui;

static double monotonicSeconds() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}
@implementation SolarSystemView (Navigation)
- (void)reportNavigationError:(const char *)message {
    if (self.cameraChanged) self.cameraChanged([NSString stringWithFormat:@"視点を変更できません: %s", message]);
}
- (void)invalidateFlightTimer {
    [_flightTimer invalidate];
    _flightTimer = nil;
}
- (void)interruptFlight {
    const BOOL flying = self.flightAnimating;
    _navigation.interrupt();
    if (_journeyActive) _journey.interrupt();
    [self invalidateFlightTimer];
    if (flying) {
        _flightNotice = _journeyActive ? @"飛行を停止 · 現在位置から再開できます" : @"飛行を中断";
        [self notifyCamera];
        if (self.navigationChanged) self.navigationChanged();
    }
}
- (void)leaveNavigation {
    [self interruptFlight];
    _journey = InterplanetaryFlight{};
    _journeyActive = NO;
    _surfaceActive = NO;
    _surfacePreview = NO;
    _earthMoonMode = NO;
    _earthMoonFollowing = NO;
    _flightNotice = nil;
    _camera.frame.reset();
    if (self.navigationChanged) self.navigationChanged();
}
- (void)showEarthMoon {
    if (!_hasData) return;
    [self leaveNavigation];
    _following = NO;
    _earthMoonMode = _earthMoonFollowing = YES;
    const Vec3 earth = [self displayPosition:3], moon = [self displayPosition:10];
    _camera = SolarCamera{};
    _camera.yaw_deg = std::atan2(moon.y-earth.y, moon.x-earth.x) * 180 / 3.14159265358979323846 + 90;
    _camera.pitch_deg = 35;
    _camera.distance_au = std::max(0.001, 2.6 * std::hypot(moon.x-earth.x, moon.y-earth.y, moon.z-earth.z));
    [self updateTrackedCamera];
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (void)advanceFlightAtTime:(double)time {
    if (_journeyActive) {
        try {
            [self updateJourneyAtTime:time];
            [self notifyCamera];
            self.needsDisplay = YES;
        } catch (const std::exception& error) {
            [self interruptFlight];
            [self reportNavigationError:error.what()];
        }
        return;
    }
    if (!_surfaceActive || !_navigation.flying()) { [self invalidateFlightTimer]; return; }
    try {
        const BOOL interrupted = !std::isfinite(time) || time < _lastFlightTime || time-_lastFlightTime > 1;
        _navigation.advance(time);
        _lastFlightTime = time;
        _camera = _navigation.camera(_bodies);
        if (!_navigation.flying()) {
            [self invalidateFlightTimer];
            _flightNotice = interrupted ? @"飛行を中断（時間の空白）" : @"飛行完了";
            if (self.navigationChanged) self.navigationChanged();
        }
        [self notifyCamera];
        self.needsDisplay = YES;
    } catch (const std::exception& error) {
        [self interruptFlight];
        [self reportNavigationError:error.what()];
    }
}
- (void)startFlightTimer {
    [self invalidateFlightTimer];
    if (!self.flightAnimating) return;
    __weak SolarSystemView *weakSelf = self;
    _flightTimer = [NSTimer timerWithTimeInterval:1.0/30 repeats:YES block:^(NSTimer *timer) {
        (void)timer;
        [weakSelf advanceFlightAtTime:monotonicSeconds()];
    }];
    [[NSRunLoop mainRunLoop] addTimer:_flightTimer forMode:NSRunLoopCommonModes];
}
- (void)beginFlightAtSite:(SurfaceSite)site ascending:(BOOL)ascending {
    if (!_hasData || _journeyActive) return;
    try {
        SurfaceNavigation next;
        next.set_site(site);
        const SolarCamera camera = next.camera(_bodies);
        const double time = monotonicSeconds();
        if (ascending) next.begin_ascent(time); else next.begin_descent(time);
        [self invalidateFlightTimer];
        _navigation = next;
        _camera = camera;
        _lastFlightTime = time;
        _surfaceActive = YES;
        _surfacePreview = NO;
        _earthMoonMode = _earthMoonFollowing = _following = NO;
        _selection = site.body_index;
        _smallBodySelection.reset();
        _satelliteSelection.reset(); _spacecraftSelection.reset();
        _flightNotice = ascending ? @"離陸中" : @"着陸中";
        if (!_navigation.flying()) _flightNotice = @"飛行完了";
        [self startFlightTimer];
        [self notifySelection];
        [self notifyCamera];
        self.needsDisplay = YES;
    } catch (const std::exception& error) { [self reportNavigationError:error.what()]; }
}
- (void)landAtLatitude:(double)latitude longitude:(double)longitude {
    if ([self rejectSmallBodySurfaceNavigation] || [self rejectSatelliteSurfaceNavigation] || [self rejectSpacecraftSurfaceNavigation]) return;
    if (!_hasData) return;
    const std::size_t body = _selection.value_or(3);
    if (body == 0) { if (self.cameraChanged) self.cameraChanged(@"太陽は着陸対象ではありません。"); return; }
    SurfaceSite site;
    if (_surfaceActive && _navigation.site().body_index == body) site = _navigation.site();
    else { site.height_km = surface_body_info(body).radius_km * 8; site.elevation_deg = -80; }
    site.body_index = body;
    site.latitude_deg = latitude;
    site.longitude_deg = longitude;
    [self beginFlightAtSite:site ascending:NO];
}
- (void)takeOffFromEarthAtLatitude:(double)latitude longitude:(double)longitude {
    SurfaceSite site;
    site.latitude_deg = latitude;
    site.longitude_deg = longitude;
    [self beginFlightAtSite:site ascending:YES];
}
- (void)takeOff {
    if ([self rejectSmallBodySurfaceNavigation] || [self rejectSatelliteSurfaceNavigation] || [self rejectSpacecraftSurfaceNavigation]) return;
    if (!_hasData) return;
    if (_surfaceActive) { [self beginFlightAtSite:_navigation.site() ascending:YES]; return; }
    SurfaceSite site;
    site.body_index = _selection.value_or(3);
    if (site.body_index == 0) { if (self.cameraChanged) self.cameraChanged(@"太陽は離陸対象ではありません。"); return; }
    [self beginFlightAtSite:site ascending:YES];
}
- (void)changeSurfaceByX:(double)dx y:(double)dy zoom:(double)zoom {
    [self interruptFlight];
    try {
        auto next = _navigation;
        if (dx != 0 || dy != 0) next.look(dx, dy);
        if (zoom != 0) next.zoom(zoom);
        const auto camera = next.camera(_bodies);
        _navigation = next;
        _camera = camera;
        [self notifyCamera];
        self.needsDisplay = YES;
    } catch (const std::exception& error) { [self reportNavigationError:error.what()]; }
}

- (void)updateJourneyAtTime:(double)time {
    if (!_journeyActive || !_journey.flying()) { [self invalidateFlightTimer]; return; }
    _journey.advance(time, _bodies);
    _lastFlightTime = time;
    _camera = _journey.camera();
    if (_journey.flying()) return;
    [self invalidateFlightTimer];
    if (_journey.completed()) {
        // 航行の終端は同じ日時・緯度経度の地表カメラに一致する。
        // 着陸後も天体固定の視点として公転と自転に追従する。
        _navigation.set_site(_journey.destination());
        _surfaceActive = YES;
        _journeyActive = NO;
        _flightNotice = @"連続飛行完了";
    } else {
        switch (_journey.stop_reason()) {
            case FlightStopReason::clock_discontinuity: _flightNotice = @"飛行を停止（時間の空白）"; break;
            case FlightStopReason::collision: _flightNotice = @"飛行を停止（経路上の天体）"; break;
            default: _flightNotice = @"飛行を停止 · 現在位置から再開できます"; break;
        }
    }
    if (self.navigationChanged) self.navigationChanged();
}
- (void)startJourneyAtLatitude:(double)latitude longitude:(double)longitude {
    if ([self rejectSmallBodySurfaceNavigation] || [self rejectSatelliteSurfaceNavigation] || [self rejectSpacecraftSurfaceNavigation]) return;
    if (!_hasData || _journeyActive) return;
    const std::size_t body = _selection.value_or(10);
    if (body == 0) { if (self.cameraChanged) self.cameraChanged(@"太陽は着陸対象ではありません。"); return; }
    try {
        SurfaceSite destination;
        destination.body_index = body;
        destination.latitude_deg = latitude;
        destination.longitude_deg = longitude;
        const SurfaceSite departure = _surfaceActive ? _navigation.site() : SurfaceSite{};
        const double time = monotonicSeconds();
        InterplanetaryFlight next;
        next.begin(departure, destination, _bodies, time);
        [self invalidateFlightTimer];
        _navigation.interrupt();
        _journey = std::move(next);
        _camera = _journey.camera();
        _journeyActive = YES;
        _surfaceActive = _surfacePreview = NO;
        _earthMoonMode = _earthMoonFollowing = _following = NO;
        _lastFlightTime = time;
        _flightNotice = nil;
        _selection = body;
        _smallBodySelection.reset();
        _satelliteSelection.reset(); _spacecraftSelection.reset();
        [self startFlightTimer];
        [self notifySelection];
        [self notifyCamera];
        self.needsDisplay = YES;
    } catch (const std::exception& error) { [self reportNavigationError:error.what()]; }
}
- (void)resumeJourney {
    if (!_journeyActive || _journey.flying()) return;
    try {
        const double time = monotonicSeconds();
        InterplanetaryFlight next;
        next.begin_from_camera(_camera, _journey.destination(), _bodies, time);
        _journey = std::move(next);
        _lastFlightTime = time;
        _flightNotice = @"現在位置から再開";
        [self startFlightTimer];
        [self notifyCamera];
        if (self.navigationChanged) self.navigationChanged();
        self.needsDisplay = YES;
    } catch (const std::exception& error) { [self reportNavigationError:error.what()]; }
}
@end
