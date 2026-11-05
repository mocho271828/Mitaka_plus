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

@implementation SolarSystemView (ScriptOrientation)
- (BOOL)scriptCameraOrientationAvailable { return !_surfaceActive && !_journeyActive; }
- (PlusOrientationQuaternion)scriptCameraOrientation {
    const auto basis = solar_camera_basis(_camera);
    if (_scriptOrientation && sameOrientationBasis(plus_orientation_basis(*_scriptOrientation), basis))
        return *_scriptOrientation;
    _scriptOrientation = plus_orientation_from_basis(basis);
    return *_scriptOrientation;
}
- (void)applyScriptOrientation:(PlusOrientationQuaternion)orientation {
    const auto normalized = plus_orientation_normalized(orientation);
    _camera.frame = plus_orientation_basis(normalized);
    _camera.frame_is_orbit = true;
    _camera.roll_deg = 0;
    _scriptOrientation = normalized;
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (void)stopScriptOrientation {
    [_orientationTimer invalidate];
    _orientationTimer = nil;
    _orientationAnimation.reset();
}
- (void)advanceScriptOrientation {
    if (!_orientationAnimation) return;
    if (_surfaceActive || _journeyActive) { [self stopScriptOrientation]; return; }
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
    if (_surfaceActive || _journeyActive) {
        if (error) *error = @"地表・飛行中の姿勢指定にはまだ対応していません。";
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
        const auto initial = [self scriptCameraOrientation];
        const auto target = plus_orientation_normalized(orientation);
        return [self beginScriptOrientation:{initial, target, {}, {}, 0, duration, bool(smooth),
                                             ScriptOrientationInterpolation::quaternion} error:error];
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
}
- (BOOL)scriptSetCameraEuler:(PlusOrientationEuler)euler relative:(BOOL)relative duration:(double)duration smooth:(BOOL)smooth error:(NSString **)error {
    try {
        const auto initial = [self scriptCameraOrientation];
        auto target = plus_orientation_from_euler(euler.heading, euler.pitch, euler.roll);
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
