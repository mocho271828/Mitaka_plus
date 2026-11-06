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
    _exitSurfaceAfterAscent = NO;
    if (_journeyActive) _journey.interrupt();
    else if (_surfaceActive) [self restoreFlightOrientation];
    [self invalidateFlightTimer];
    if (flying) {
        _flightNotice = _journeyActive ? @"飛行を停止 · 現在位置から再開できます" : @"飛行を中断";
        [self notifyCamera];
        if (self.navigationChanged) self.navigationChanged();
    }
}
- (void)leaveNavigation {
    [self stopScriptZoomAnimation];
    [self stopScriptTargetTransition];
    [self stopScriptOrientation];
    _flightOrientation.reset();
    [self interruptFlight];
    _journey = InterplanetaryFlight{};
    _journeyActive = NO;
    _surfaceActive = NO;
    _physicalSpaceActive = NO;
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
        [self restoreFlightOrientation];
        if (!_navigation.flying()) {
            if (_exitSurfaceAfterAscent && !interrupted) {
                _physicalSpaceActive = YES;
                _surfaceActive = NO;
            }
            _exitSurfaceAfterAscent = NO;
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
    [self stopScriptZoomAnimation];
    [self invalidateFlightTimer];
    if (!self.flightAnimating) return;
    __weak SolarSystemView *weakSelf = self;
    _flightTimer = [NSTimer timerWithTimeInterval:1.0/30 repeats:YES block:^(NSTimer *timer) {
        (void)timer;
        [weakSelf advanceFlightAtTime:monotonicSeconds()];
    }];
    [[NSRunLoop mainRunLoop] addTimer:_flightTimer forMode:NSRunLoopCommonModes];
}
- (BOOL)beginFlightAtSite:(SurfaceSite)site ascending:(BOOL)ascending preserveLook:(BOOL)preserveLook duration:(double)duration error:(NSString **)error {
    if (!_hasData || _journeyActive) return NO;
    try {
        SurfaceNavigation next;
        next.set_site(site);
        const double time = monotonicSeconds();
        if (ascending) next.begin_ascent(time, duration);
        else if (preserveLook) next.begin_descent_preserving_look(time, duration);
        else next.begin_descent(time, duration);
        const SolarCamera camera = next.camera(_bodies);
        [self stopScriptTargetTransition];
        [self stopScriptOrientation];
        _flightOrientation.reset();
        [self invalidateFlightTimer];
        _navigation = next;
        _camera = camera;
        _lastFlightTime = time;
        _surfaceActive = YES;
        _physicalSpaceActive = NO;
        _exitSurfaceAfterAscent = NO;
        _surfacePreview = NO;
        _earthMoonMode = _earthMoonFollowing = _following = NO;
        // 地形の非同期取得を待つ間も、以前の模式視点を表示しない。
        [self cancelTerrain];
        // 成功した着陸・離陸では対象が天体に切り替わる。失敗時は元の選択を維持する。
        [_galaxyOverlay invalidatePendingPicks];
        _galaxySelection.reset(); _hipSelection.reset(); _ourGalaxyPointSelection.reset(); _ourGalaxySelected = NO;
        _selection = site.body_index;
        _smallBodySelection.reset();
        _satelliteSelection.reset(); _spacecraftSelection.reset();
        _flightNotice = ascending ? @"離陸中" : @"着陸中";
        if (!_navigation.flying()) _flightNotice = @"飛行完了";
        [self startFlightTimer];
        [self notifySelection];
        [self notifyCamera];
        self.needsDisplay = YES;
        return YES;
    } catch (const std::exception& exception) {
        if (error) *error = [NSString stringWithUTF8String:exception.what()];
        else [self reportNavigationError:exception.what()];
        return NO;
    }
}
- (BOOL)takeOffFromHorizon:(SurfaceSite)site error:(NSString **)error {
    return [self takeOffFromHorizon:site duration:3 error:error];
}
- (BOOL)takeOffFromHorizon:(SurfaceSite)site duration:(double)duration error:(NSString **)error {
    if (![self beginFlightAtSite:site ascending:YES preserveLook:YES duration:duration error:error]) return NO;
    // 完了後は同じカメラを宇宙側へ渡し、地表専用操作に固定されないようにする。
    if (_navigation.flying()) _exitSurfaceAfterAscent = YES;
    else {
        _physicalSpaceActive = YES; _surfaceActive = NO;
        if (self.navigationChanged) self.navigationChanged();
        [self notifyCamera];
    }
    return YES;
}
- (BOOL)forceSpaceFromHorizon:(SurfaceSite)site error:(NSString **)error {
    if (![self beginFlightAtSite:site ascending:NO preserveLook:YES duration:0 error:error]) return NO;
    return [self forceSurfaceMode:NO bodyIndex:nullptr error:error];
}
- (BOOL)descendToHorizon:(NSString **)error {
    return [self descendToHorizonWithDuration:3 error:error];
}
- (BOOL)descendToHorizonWithDuration:(double)duration error:(NSString **)error {
    if (!_hasData || _journeyActive) return NO;
    try {
        const auto site = _surfaceActive && _navigation.site().body_index == 3
            ? _navigation.site() : surface_site_from_camera_with_roll(_camera, _bodies, 3);
        if (site.height_km > 8 * surface_body_info(3).radius_km + 1e-6)
            throw std::invalid_argument("地球の近くに移動してください。");
        return [self beginFlightAtSite:site ascending:NO preserveLook:YES duration:duration error:error];
    } catch (const std::exception& exception) {
        if (error) *error = [NSString stringWithUTF8String:exception.what()];
        return NO;
    }
}
- (BOOL)descendToSelectedSurfaceWithDuration:(double)duration error:(NSString **)error {
    if (!_hasData || _journeyActive || !_selection || *_selection == 0) return NO;
    try {
        const auto body = *_selection;
        const auto site = _surfaceActive && _navigation.site().body_index == body
            ? _navigation.site() : surface_site_from_camera_with_roll(_camera, _bodies, body);
        if (site.height_km > 8 * surface_body_info(body).radius_km + 1e-6)
            throw std::invalid_argument("選択した天体の近くに移動してください。");
        return [self beginFlightAtSite:site ascending:NO preserveLook:YES duration:duration error:error];
    } catch (const std::exception& exception) {
        if (error) *error = [NSString stringWithUTF8String:exception.what()];
        return NO;
    }
}
- (BOOL)ascendFromEarthWithDuration:(double)duration error:(NSString **)error {
    if (!_hasData || _journeyActive || !_surfaceActive || _navigation.site().body_index != 3) return NO;
    return [self ascendFromSurfaceWithDuration:duration error:error];
}
- (BOOL)ascendFromSurfaceWithDuration:(double)duration error:(NSString **)error {
    if (!_hasData || _journeyActive || !_surfaceActive) return NO;
    if (![self beginFlightAtSite:_navigation.site() ascending:YES preserveLook:YES duration:duration error:error]) return NO;
    if (_navigation.flying()) _exitSurfaceAfterAscent = YES;
    else {
        _physicalSpaceActive = YES; _surfaceActive = NO;
        if (self.navigationChanged) self.navigationChanged();
        [self notifyCamera];
    }
    return YES;
}
- (BOOL)earthSurfaceSite:(SurfaceSite *)site {
    if (!_surfaceActive || _navigation.site().body_index != 3) return NO;
    if (site) *site = _navigation.site();
    return YES;
}
- (BOOL)scriptSurfaceSite:(SurfaceSite *)site {
    if (![self scriptPlanetariumMode]) return NO;
    if (site) *site = _navigation.site();
    return YES;
}
- (BOOL)scriptSetSurfaceAzimuth:(double)azimuth altitude:(double)altitude {
    SurfaceSite site;
    if (![self scriptSurfaceSite:&site]) return NO;
    site.heading_deg = azimuth;
    site.elevation_deg = altitude;
    _navigation.set_site(site);
    _camera = _navigation.camera(_bodies);
    [self notifyCamera];
    self.needsDisplay = YES;
    return YES;
}
- (BOOL)scriptBodyEclipticPosition:(NSUInteger)index result:(Vec3 *)result {
    if (!_hasData || index >= _bodies.size() || !result) return NO;
    *result = j2000_equatorial_to_ecliptic(_bodies[index].position_au);
    return YES;
}
- (BOOL)scriptSurfaceLookVector:(Vec3)vector position:(BOOL)isPosition result:(SurfaceSite *)result {
    SurfaceSite site;
    if (![self scriptSurfaceSite:&site] || !result) return NO;
    auto unrolledSite = site;
    unrolledSite.roll_deg = 0;
    SurfaceNavigation unrolled;
    unrolled.set_site(unrolledSite);
    const auto basis = solar_camera_basis(unrolled.camera(_bodies));
    if (isPosition) {
        vector.x -= _camera.target.x + basis.outward.x * _camera.distance_au;
        vector.y -= _camera.target.y + basis.outward.y * _camera.distance_au;
        vector.z -= _camera.target.z + basis.outward.z * _camera.distance_au;
    }
    const double length = std::hypot(vector.x, vector.y, vector.z);
    if (!std::isfinite(length) || length <= 1e-15) return NO;
    constexpr double radians = 3.14159265358979323846 / 180.0;
    const double h = site.heading_deg * radians, e = site.elevation_deg * radians;
    const Vec3 forward{-basis.outward.x, -basis.outward.y, -basis.outward.z};
    const auto combine = [](Vec3 a, double x, Vec3 b, double y) {
        return Vec3{a.x * x + b.x * y, a.y * x + b.y * y, a.z * x + b.z * y};
    };
    const auto dot = [](Vec3 a, Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; };
    const Vec3 up = combine(forward, std::sin(e), basis.up, std::cos(e));
    const Vec3 horizontal = combine(forward, std::cos(e), basis.up, -std::sin(e));
    const Vec3 north = combine(horizontal, std::cos(h), basis.right, -std::sin(h));
    const Vec3 east = combine(horizontal, std::sin(h), basis.right, std::cos(h));
    const double northward = dot(vector, north), eastward = dot(vector, east);
    // 天頂・天底は方位を決められないため現在の方位を維持する。
    if (std::hypot(northward, eastward) > length * 1e-12)
        site.heading_deg = std::atan2(eastward, northward) / radians;
    site.elevation_deg = std::asin(std::clamp(dot(vector, up) / length, -1.0, 1.0)) / radians;
    *result = site;
    return YES;
}
- (BOOL)forceSurfaceMode:(BOOL)surface bodyIndex:(NSUInteger *)bodyIndex error:(NSString **)error {
    if (!_hasData) {
        if (error) *error = @"データ未読込のため強制切替できません。";
        return NO;
    }
    if (!surface) {
        [self stopScriptZoomAnimation];
        [self stopScriptTargetTransition];
        [self stopScriptOrientation];
        if (_journeyActive) {
            [self interruptFlight];
            _journeyActive = NO;
            _journey = InterplanetaryFlight{};
            _flightOrientation.reset();
            _physicalSpaceActive = YES;
            [self notifyCamera];
            if (self.navigationChanged) self.navigationChanged();
            self.needsDisplay = YES;
        }
        if (_surfaceActive) {
            [self interruptFlight];
            _camera = _navigation.camera(_bodies);
            _surfaceActive = NO;
            _physicalSpaceActive = YES;
            _flightOrientation.reset();
            [self notifyCamera];
            if (self.navigationChanged) self.navigationChanged();
            self.needsDisplay = YES;
        }
        return YES;
    }
    if (!_selection || *_selection == 0 || _smallBodySelection || _satelliteSelection ||
        _spacecraftSelection || _galaxySelection || _hipSelection) {
        if (error) *error = @"強制着陸には惑星または月を対象に選択してください。";
        return NO;
    }
    try {
        const auto body = *_selection;
        auto site = _surfaceActive && _navigation.site().body_index == body
            ? _navigation.site() : forced_surface_site_from_camera(_camera, _bodies, body);
        site.height_km = minimum_surface_height_km;
        if (_journeyActive) {
            [self interruptFlight];
            _journeyActive = NO;
            _journey = InterplanetaryFlight{};
        }
        if (![self beginFlightAtSite:site ascending:NO preserveLook:YES duration:0 error:error]) return NO;
        [self stopScriptTargetTransition];
        if (bodyIndex) *bodyIndex = body;
        return YES;
    } catch (const std::exception& exception) {
        if (error) *error = [NSString stringWithUTF8String:exception.what()];
        return NO;
    }
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
    [self beginFlightAtSite:site ascending:NO preserveLook:NO duration:3 error:nil];
}
- (void)takeOffFromEarthAtLatitude:(double)latitude longitude:(double)longitude {
    SurfaceSite site;
    site.latitude_deg = latitude;
    site.longitude_deg = longitude;
    [self beginFlightAtSite:site ascending:YES preserveLook:NO duration:3 error:nil];
}
- (void)takeOff {
    if ([self rejectSmallBodySurfaceNavigation] || [self rejectSatelliteSurfaceNavigation] || [self rejectSpacecraftSurfaceNavigation]) return;
    if (!_hasData) return;
    if (_surfaceActive) { [self beginFlightAtSite:_navigation.site() ascending:YES preserveLook:NO duration:3 error:nil]; return; }
    SurfaceSite site;
    site.body_index = _selection.value_or(3);
    if (site.body_index == 0) { if (self.cameraChanged) self.cameraChanged(@"太陽は離陸対象ではありません。"); return; }
    [self beginFlightAtSite:site ascending:YES preserveLook:NO duration:3 error:nil];
}
- (void)changeSurfaceByX:(double)dx y:(double)dy zoom:(double)zoom {
    if ((dx != 0 || dy != 0) && self.userSurfaceViewChange) self.userSurfaceViewChange();
    [self stopScriptOrientation];
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
    if (_journey.flying()) { [self restoreFlightOrientation]; return; }
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
    [self restoreFlightOrientation];
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
        [self stopScriptOrientation];
        _flightOrientation.reset();
        [self invalidateFlightTimer];
        _navigation.interrupt();
        _exitSurfaceAfterAscent = NO;
        _journey = std::move(next);
        _camera = _journey.camera();
        _journeyActive = YES;
        _surfaceActive = _surfacePreview = NO;
        _physicalSpaceActive = NO;
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
