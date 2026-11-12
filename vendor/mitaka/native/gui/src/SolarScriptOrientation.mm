#import "SolarSystemViewInternal.h"
#include <chrono>
#include <cmath>

using namespace mitaka::gui;

static double orientationClock() {
    return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
}

static bool sameOrientationBasis(const SolarCameraBasis& a, const SolarCameraBasis& b) {
    const auto close = [](const mitaka::Vec3& x, const mitaka::Vec3& y) {
        return std::hypot(x.x-y.x, x.y-y.y, x.z-y.z) < 1e-10;
    };
    return close(a.outward, b.outward) && close(a.right, b.right) && close(a.up, b.up);
}

// 地表位置を維持したまま、慣性座標の姿勢を地点の方位・高度・ロールへ変換する。
static SurfaceSite surfaceSiteWithOrientation(const SurfaceNavigation& navigation, const SolarBodies& bodies,
                                              const SolarCameraBasis& desired) {
    auto site = navigation.site();
    auto axesSite = site;
    axesSite.heading_deg = axesSite.elevation_deg = axesSite.roll_deg = 0;
    SurfaceNavigation axes;
    axes.set_site(axesSite);
    const auto local = solar_camera_basis(axes.camera(bodies));
    const auto dot = [](mitaka::Vec3 a, mitaka::Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; };
    constexpr double degrees = 180.0 / 3.14159265358979323846;
    const mitaka::Vec3 forward{-desired.outward.x, -desired.outward.y, -desired.outward.z};
    const double north = -dot(forward, local.outward), east = dot(forward, local.right);
    if (std::hypot(north, east) > 1e-12) site.heading_deg = std::atan2(east, north) * degrees;
    site.elevation_deg = std::asin(std::clamp(dot(forward, local.up), -1.0, 1.0)) * degrees;
    site.roll_deg = 0;
    axes.set_site(site);
    const auto unrolled = solar_camera_basis(axes.camera(bodies));
    site.roll_deg = std::atan2(dot(desired.right, unrolled.up), dot(desired.right, unrolled.right)) * degrees;
    return site;
}

@implementation SolarSystemView (ScriptOrientation)
- (BOOL)scriptCameraOrientationAvailable { return YES; }
- (PlusOrientationQuaternion)scriptCameraOrientation {
    const auto basis = solar_camera_basis(_camera);
    if (_scriptOrientation && sameOrientationBasis(plus_orientation_basis(*_scriptOrientation), basis))
        return *_scriptOrientation;
    _scriptOrientation = plus_orientation_from_basis(basis);
    return *_scriptOrientation;
}
- (void)applyScriptOrientation:(PlusOrientationQuaternion)orientation {
    const auto normalized = plus_orientation_normalized(orientation);
    const auto basis = plus_orientation_basis(normalized);
    if (_journeyActive || (_surfaceActive && _navigation.flying()) || _physicalSpaceActive) {
        // 飛行と物理宇宙視点では、視点位置を変えずに表示姿勢を差し替える。
        const auto previous = solar_camera_basis(_camera);
        _camera.translate_target_au({(previous.outward.x - basis.outward.x) * _camera.distance_au,
                                     (previous.outward.y - basis.outward.y) * _camera.distance_au,
                                     (previous.outward.z - basis.outward.z) * _camera.distance_au});
        _camera.frame = basis;
        _camera.frame_is_orbit = false;
        _camera.roll_deg = 0;
        if (_journeyActive || (_surfaceActive && _navigation.flying())) _flightOrientation = normalized;
    } else if (_surfaceActive) {
        _navigation.set_site(surfaceSiteWithOrientation(_navigation, _bodies, basis));
        const double fov = _camera.vertical_fov_deg;
        _camera = _navigation.camera(_bodies);
        _camera.vertical_fov_deg = fov;
    } else {
        _camera.frame = basis;
        _camera.frame_is_orbit = true;
        _camera.roll_deg = 0;
    }
    _scriptOrientation = normalized;
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (void)restoreFlightOrientation {
    if (!_flightOrientation) return;
    const auto orientation = *_flightOrientation;
    if (!_journeyActive && (!_surfaceActive || !_navigation.flying())) _flightOrientation.reset();
    [self applyScriptOrientation:orientation];
}
- (void)stopScriptOrientation {
    [_orientationTimer invalidate];
    _orientationTimer = nil;
    _orientationAnimation.reset();
}
- (void)advanceScriptOrientation {
    if (!_orientationAnimation) return;
    if (![self scriptCameraOrientationAvailable]) { [self stopScriptOrientation]; return; }
    const auto state = *_orientationAnimation;
    const double t = std::clamp((orientationClock() - state.start_time) / state.duration, 0.0, 1.0);
    try {
        PlusOrientationQuaternion q;
        if (state.interpolation != ScriptOrientationInterpolation::quaternion) {
            const auto e = plus_orientation_interpolate_euler(state.initial_euler, state.target_euler, t, state.smooth);
            q = plus_orientation_from_euler(e.heading, e.pitch, e.roll);
            if (state.interpolation == ScriptOrientationInterpolation::relative_euler)
                q = plus_orientation_multiply(state.initial, q);
        } else q = plus_orientation_interpolate(state.initial, state.target, t, state.smooth);
        [self applyScriptOrientation:q];
    } catch (const std::exception& failure) {
        [self stopScriptOrientation];
        if (self.cameraChanged) self.cameraChanged([NSString stringWithUTF8String:failure.what()]);
        return;
    }
    if (t >= 1) [self stopScriptOrientation];
}
- (BOOL)beginScriptOrientation:(ScriptOrientationAnimation)state error:(NSString **)error {
    if (![self scriptCameraOrientationAvailable]) {
        if (error) *error = @"飛行中の姿勢指定にはまだ対応していません。";
        return NO;
    }
    if (!std::isfinite(state.duration) || state.duration < 0) {
        if (error) *error = @"姿勢変更の時間は 0 以上の有限値にしてください。";
        return NO;
    }
    [self stopScriptOrientation];
    // 明示的な姿勢指定を、進行中の対象移動による姿勢補間より優先する。
    if (_targetAnimation) {
        _targetAnimation->initial_orientation.reset();
        _targetAnimation->target_orientation.reset();
    }
    if (state.duration == 0) {
        [self applyScriptOrientation:state.target];
        return YES;
    }
    state.start_time = orientationClock();
    _orientationAnimation = state;
    __weak SolarSystemView *weakSelf = self;
    _orientationTimer = [NSTimer timerWithTimeInterval:1.0/30.0 repeats:YES block:^(NSTimer *timer) {
        SolarSystemView *view = weakSelf;
        if (view) [view advanceScriptOrientation]; else [timer invalidate];
    }];
    [NSRunLoop.mainRunLoop addTimer:_orientationTimer forMode:NSRunLoopCommonModes];
    return YES;
}
- (BOOL)scriptSetCameraOrientation:(PlusOrientationQuaternion)orientation duration:(double)duration smooth:(BOOL)smooth error:(NSString **)error {
    try {
        const auto target = plus_orientation_normalized(orientation);
        if (!std::isfinite(duration) || duration < 0)
            throw std::invalid_argument("camera orientation duration must be nonnegative and finite");
        if (_orientationAnimation) [self advanceScriptOrientation];
        const auto initial = [self scriptCameraOrientation];
        return [self beginScriptOrientation:{initial, target, {}, {}, 0, duration, bool(smooth),
                                             ScriptOrientationInterpolation::quaternion} error:error];
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
}
- (BOOL)scriptSetCameraEuler:(PlusOrientationEuler)euler relative:(BOOL)relative duration:(double)duration smooth:(BOOL)smooth error:(NSString **)error {
    try {
        auto target = plus_orientation_from_euler(euler.heading, euler.pitch, euler.roll);
        if (!std::isfinite(duration) || duration < 0)
            throw std::invalid_argument("camera orientation duration must be nonnegative and finite");
        if (_orientationAnimation) [self advanceScriptOrientation];
        const auto initial = [self scriptCameraOrientation];
        if (relative) target = plus_orientation_normalized(plus_orientation_multiply(initial, target));
        const auto initialEuler = relative ? PlusOrientationEuler{} : plus_orientation_to_euler(initial);
        const auto interpolation = relative ? ScriptOrientationInterpolation::relative_euler
                                            : ScriptOrientationInterpolation::euler;
        return [self beginScriptOrientation:{initial, target, initialEuler, euler, 0, duration, bool(smooth), interpolation} error:error];
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
}
@end
