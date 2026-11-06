#import "AppControllerInternal.h"
#import "SolarSystemViewInternal.h"
#import "SolarDateUpdate.h"
#import <objc/runtime.h>
#include "surface_navigation.hpp"
#include "satellite_scene.hpp"
#include <algorithm>
#include <cstdio>
#include <cstdlib>

static std::shared_ptr<mitaka::gui::PreparedSolarDate> failSolarDatePreparation(
    id, SEL, const mitaka::gui::SolarDateInput&) {
    throw std::runtime_error("injected solar date preparation failure");
}
static void failSkyDatePresentation(id, SEL) {
    throw std::runtime_error("injected sky date presentation failure");
}
static IMP originalHorizonFinish = nullptr;
static bool horizonFinishCalled = false;
static void recordHorizonDatePresentation(id receiver, SEL selector) {
    horizonFinishCalled = true;
    reinterpret_cast<void (*)(id, SEL)>(originalHorizonFinish)(receiver, selector);
}

@implementation AppController (SmokeTests)
- (void)runSmokeTest {
    [self runScriptSmokeTestWithCompletion:^{
        [self runSmallBodySmokeTestWithCompletion:^{
            [self runGalaxySmokeTestWithCompletion:^{
                [self runSolarGalaxySmokeTestWithCompletion:^{ [self runSceneSmokeTest]; }];
            }];
        }];
    }];
}
- (void)runSceneSmokeTest {
    if (![self runSatelliteSmokeTest]) return;
    if (![self runPlusSmokeTest]) return;
    const auto nextHour = displayDate(2451545.0 + 1.0 / 24.0);
    const auto previousHour = displayDate(2451545.0 - 1.0 / 24.0);
    const auto nextDay = displayDate(mitaka::julian_date({2000, 1, 1, 23, 59, 59.9}));
    if (nextHour.hour != 13 || nextHour.minute != 0 || previousHour.hour != 11 ||
        previousHour.minute != 0 || nextDay.day != 2 || nextDay.hour != 0 || nextDay.minute != 0) {
        [self showError:@"smoke: minute display rounding failed"];
        return;
    }
    NSOpenPanel *panel = [self dataPanel];
    if (!panel.canChooseDirectories || panel.canChooseFiles) {
        [self showError:@"smoke: data panel must select directories only"];
        return;
    }
    const auto range = _model->time_range();
    const double savedJD = _jd;
    const double nextJD = savedJD < range.second ? std::min(savedJD + 1, range.second) : range.first;
    __block BOOL acceptedOffMain = YES;
    dispatch_semaphore_t backgroundFinished = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        acceptedOffMain = [self updateDate:nextJD refreshOrbits:YES];
        dispatch_semaphore_signal(backgroundFinished);
    });
    dispatch_semaphore_wait(backgroundFinished, DISPATCH_TIME_FOREVER);
    if (acceptedOffMain || _jd != savedJD || _horizon.julianDate != savedJD ||
        [_solar displayedScene].julian_date != savedJD) {
        [self showError:@"smoke: background date update was not rejected atomically"];
        return;
    }
    Method prepareDate = class_getInstanceMethod(SolarSystemView.class, @selector(prepareDateUpdate:));
    if (!prepareDate) { [self showError:@"smoke: solar date preparation API missing"]; return; }
    for (NSInteger mode = 0; mode < 3; ++mode) {
        _mode.selectedSegment = mode;
        [self changeMode:nil];
        const auto oldScene = [_solar displayedScene];
        const auto oldMoon = oldScene.bodies[10];
        const auto oldCamera = [_solar cameraState];
        const auto oldSmall = _smallBodySnapshot;
        const auto oldSatellite = _satelliteSnapshot;
        const auto oldSpacecraft = _spacecraftSnapshot;
        const double oldHorizon = _horizon.julianDate;
        NSString *oldDateText = [_dateLabel.stringValue copy];
        IMP original = method_setImplementation(prepareDate, reinterpret_cast<IMP>(failSolarDatePreparation));
        _smokeTest = NO;
        const BOOL accepted = [self updateDate:nextJD refreshOrbits:YES];
        _jdField.stringValue = [NSString stringWithFormat:@"%.6f", nextJD];
        [self applyDate:nil];
        const BOOL restoredAfterFailure = [_jdField.stringValue isEqualToString:[NSString stringWithFormat:@"%.6f", savedJD]];
        _jdField.stringValue = @"invalid";
        [self applyDate:nil];
        const BOOL restoredAfterInvalid = [_jdField.stringValue isEqualToString:[NSString stringWithFormat:@"%.6f", savedJD]];
        _smokeTest = YES;
        method_setImplementation(prepareDate, original);
        const auto afterScene = [_solar displayedScene];
        const auto afterCamera = [_solar cameraState];
        const auto afterMoon = afterScene.bodies[10];
        if (accepted || !restoredAfterFailure || !restoredAfterInvalid || _jd != savedJD || _horizon.julianDate != oldHorizon ||
            afterScene.julian_date != savedJD || afterMoon.position_au.x != oldMoon.position_au.x ||
            afterMoon.position_au.y != oldMoon.position_au.y || afterMoon.position_au.z != oldMoon.position_au.z ||
            afterCamera.target.x != oldCamera.target.x || afterCamera.target.y != oldCamera.target.y ||
            afterCamera.target.z != oldCamera.target.z || _smallBodySnapshot != oldSmall ||
            _satelliteSnapshot != oldSatellite || _spacecraftSnapshot != oldSpacecraft ||
            ![_dateLabel.stringValue isEqualToString:oldDateText]) {
            [self showError:@"smoke: failed date preparation changed the published state"];
            return;
        }
    }
    Method skyFinish = class_getInstanceMethod(SkyView.class, @selector(finishDateUpdate));
    Method horizonFinish = class_getInstanceMethod(HorizonView.class, @selector(finishDateUpdate));
    if (!skyFinish || !horizonFinish) { [self showError:@"smoke: date presentation API missing"]; return; }
    IMP originalSkyFinish = method_setImplementation(skyFinish, reinterpret_cast<IMP>(failSkyDatePresentation));
    originalHorizonFinish = method_setImplementation(horizonFinish, reinterpret_cast<IMP>(recordHorizonDatePresentation));
    horizonFinishCalled = false;
    _smokeTest = NO;
    const BOOL presentationAccepted = [self updateDate:nextJD refreshOrbits:YES];
    _smokeTest = YES;
    method_setImplementation(skyFinish, originalSkyFinish);
    method_setImplementation(horizonFinish, originalHorizonFinish);
    if (!presentationAccepted || !horizonFinishCalled || _jd != nextJD ||
        _horizon.julianDate != nextJD || [_solar displayedScene].julian_date != nextJD ||
        ![self setDate:savedJD]) {
        [self showError:@"smoke: date presentation failure interrupted publication or later notifications"];
        return;
    }
    for (NSInteger mode = 0; mode < 3; ++mode) {
        _mode.selectedSegment = mode;
        [self changeMode:nil];
        if (![self setDate:nextJD] || _horizon.julianDate != _jd ||
            [_solar displayedScene].julian_date != _jd || ![self setDate:savedJD] ||
            _horizon.julianDate != _jd || [_solar displayedScene].julian_date != _jd)
            std::exit(EXIT_FAILURE);
    }
    _mode.selectedSegment = 0;
    [self changeMode:nil];
    [_sky selectBody:4];
    const NSUInteger allVisible = _sky.visibleStarCount;
    _sky.magnitudeLimit = 3;
    if (_sky.visibleStarCount > allVisible) std::exit(EXIT_FAILURE);
    _sky.magnitudeLimit = 6.5;
    [_window.contentView layoutSubtreeIfNeeded];
    [_sky displayIfNeeded];
    NSBitmapImageRep *bitmap = [_sky bitmapImageRepForCachingDisplayInRect:_sky.bounds];
    if (!bitmap) { [self showError:@"smoke: bitmap creation failed"]; return; }
    [_sky cacheDisplayInRect:_sky.bounds toBitmapImageRep:bitmap];
    // AppKit の実描画をメモリ上で確認し、データや作業ディレクトリへ画像を書き込まない。
    NSUInteger litPixels = 0;
    for (NSInteger y = 0; y < bitmap.pixelsHigh; y += 3)
        for (NSInteger x = 0; x < bitmap.pixelsWide; x += 3) {
            NSColor *color = [[bitmap colorAtX:x y:y] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
            if (color && std::max({color.redComponent, color.greenComponent, color.blueComponent}) > 0.5) ++litPixels;
        }
    if (litPixels < 100 || _sky.visibleStarCount == 0) {
        [self showError:@"smoke: sky rendering is empty"];
        return;
    }
    std::printf("AppKit smoke passed: HIP=%zu visible=%lu bodies=10 lit_samples=%lu render=%ldx%ld\n",
        _model->stars().size(), static_cast<unsigned long>(_sky.visibleStarCount), static_cast<unsigned long>(litPixels),
        static_cast<long>(bitmap.pixelsWide), static_cast<long>(bitmap.pixelsHigh));
    _mode.selectedSegment = 1;
    [self changeMode:nil];
    if (![_solar runCameraSmokeTest]) {
        [self showError:@"smoke: solar camera controls failed"];
        return;
    }
    [_solar selectBody:3];
    [_solar focusSelection];
    for (const double date : {nextJD, savedJD}) {
        if (![self setDate:date]) std::exit(EXIT_FAILURE);
        const auto camera = [_solar cameraState];
        const auto earth = mitaka::j2000_equatorial_to_ecliptic(_solarBodies[3].position_au);
        if (std::hypot(camera.target.x - earth.x, camera.target.y - earth.y, camera.target.z - earth.z) > 1e-10) {
            [self showError:@"smoke: selected body camera tracking failed"];
            return;
        }
    }
    [_solar showInnerPlanets];
    [_window.contentView layoutSubtreeIfNeeded];
    [_solar displayIfNeeded];
    NSBitmapImageRep *solarBitmap = [_solar bitmapImageRepForCachingDisplayInRect:_solar.bounds];
    if (!solarBitmap) { [self showError:@"smoke: solar bitmap creation failed"]; return; }
    [_solar cacheDisplayInRect:_solar.bounds toBitmapImageRep:solarBitmap];
    NSUInteger solarPixels = 0;
    for (NSInteger y = 0; y < solarBitmap.pixelsHigh; y += 3)
        for (NSInteger x = 0; x < solarBitmap.pixelsWide; x += 3) {
            NSColor *color = [[solarBitmap colorAtX:x y:y] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
            if (color && std::max({color.redComponent, color.greenComponent, color.blueComponent}) > 0.5) ++solarPixels;
        }
    if (solarPixels < 100) { [self showError:@"smoke: solar rendering is empty"]; return; }
    std::printf("Solar AppKit smoke passed: bodies=11 camera=orbit,pan,zoom,focus,date-tracking lit_samples=%lu\n",
        static_cast<unsigned long>(solarPixels));
    if (_textures && _textures->images[3]) {
        if (![_solar runTextureSmokeTest]) { [self showError:@"smoke: textured surface rendering failed"]; return; }
        std::printf("Texture AppKit smoke passed: loaded=%zu closeup,rotation,picking,fallback\n", _textures->loaded_count());
        // 姿勢だけを比較するため、CF96 の位置計算範囲には依存させない。
        const auto laterEarth = mitaka::planet_orientation(mitaka::Planet::earth, _jd + 0.25);
        if (![_solar runRotationSmokeTest:laterEarth]) {
            [self showError:@"smoke: dated surface rotation failed"]; return;
        }
        std::printf("Rotation AppKit smoke passed: dated Earth surface, fixed camera and illumination\n");
    } else std::printf("Texture AppKit smoke: Earth texture unavailable; color fallback rendered\n");
    // 同期描画試験の一時オブジェクト解放・UI 後処理を再生時間に含めない。
    // 別の run loop 呼出しで開始し、実タイマーの進行そのものを検証する。
    [NSRunLoop.mainRunLoop addTimer:[NSTimer timerWithTimeInterval:0 repeats:NO block:^(NSTimer *timer) {
        (void)timer;
        [self runPlaybackSmokeTest];
    }] forMode:NSRunLoopCommonModes];
}

- (void)runPlaybackSmokeTest {
    const auto range = _model->time_range();
    const double startJD = (range.first + range.second) / 2;
    if (![self setDate:startJD]) std::exit(EXIT_FAILURE);
    [_solar selectBody:3];
    [_solar showSurface];
    [_playback setSimulationRate:86400];
    [_playback play];
    if (!_playback.playing || _jdField.enabled) {
        [self showError:@"smoke: playback controls not enabled correctly"]; return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 250 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if (!(self->_jd > startJD)) {
            [self showError:@"smoke: real timer did not advance before pause"]; return;
        }
        [self->_playback pause];
        if (!(self->_jd > startJD) || self->_playback.playing || !self->_jdField.enabled) {
            [self showError:@"smoke: real timer failed to advance or pause"]; return;
        }
        if (self->_horizon.julianDate != self->_jd || [self->_solar displayedScene].julian_date != self->_jd) {
            [self showError:@"smoke: displayed scene playback time mismatch"]; return;
        }
        if (!self->_satelliteSnapshot || self->_satelliteSnapshot->model != self->_satelliteModel ||
            self->_satelliteSnapshot->julian_date != self->_jd) {
            [self showError:@"smoke: satellite playback snapshot time mismatch"]; return;
        }
        const NSUInteger selectedSatellite = self->_solar.selectedSatelliteIndex;
        const auto source = selectedSatellite < self->_satelliteModel->model().records().size()
            ? std::optional<std::string>{self->_satelliteModel->source(selectedSatellite)} : std::nullopt;
        const auto expected = apply_satellite_parent_positions(self->_model->solar_bodies(self->_jd),
            *self->_satelliteSnapshot, source);
        const auto sky = self->_model->bodies(self->_jd);
        const auto equal = [](mitaka::Vec3 a, mitaka::Vec3 b) {
            return std::hypot(a.x - b.x, a.y - b.y, a.z - b.z) < 1e-12;
        };
        for (NSUInteger i = 0; i < expected.size(); ++i) {
            const auto& actual = self->_solarBodies[i];
            if (!equal(actual.position_au, expected[i].position_au) ||
                !equal(actual.orientation.x_axis, expected[i].orientation.x_axis) ||
                !equal(actual.orientation.y_axis, expected[i].orientation.y_axis) ||
                !equal(actual.orientation.north_axis, expected[i].orientation.north_axis)) {
                [self showError:@"smoke: playback position/orientation time mismatch"]; return;
            }
        }
        for (NSUInteger i = 0; i < sky.size(); ++i) {
            if (sky[i].distance_au != self->_bodies[i].distance_au) {
                [self showError:@"smoke: sky playback time mismatch"]; return;
            }
        }
        if (!equal([self->_solar cameraState].target,
            mitaka::j2000_equatorial_to_ecliptic(expected[3].position_au))) {
            [self showError:@"smoke: playback camera tracking failed"]; return;
        }
        const double pausedJD = self->_jd;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 120 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            if (self->_jd != pausedJD) { [self showError:@"smoke: paused date changed"]; return; }
            [self->_playback play];
            [self stepHour:self->_timeButtons[4]];
            if (self->_playback.playing || self->_jd != pausedJD + 1.0 / 24.0) {
                [self showError:@"smoke: manual date must stop playback"]; return;
            }
            std::printf("Playback AppKit smoke passed: real timer, shared JD, orbit/spin, tracking, pause, manual seek\n");
            [self runTravelSmokeTest];
        });
    });
}

- (void)runTravelSmokeTest {
    [_solar showEarthMoon];
    [_solar selectBody:10];
    [_solar showSurface];
    const auto moonBefore = _solarBodies[10];
    if (![self setDate:_jd + 1]) std::exit(EXIT_FAILURE);
    const auto moonAfter = _solarBodies[10];
    const auto changed = [](mitaka::Vec3 a, mitaka::Vec3 b) {
        return std::hypot(a.x - b.x, a.y - b.y, a.z - b.z) > 1e-8;
    };
    if (!changed(moonBefore.position_au, moonAfter.position_au) ||
        !changed(moonBefore.orientation.x_axis, moonAfter.orientation.x_axis) ||
        ![_solar runSurfaceNavigationSmokeTest]) {
        [self showError:@"smoke: Moon animation or surface navigation failed"]; return;
    }
    [_solar runTerrainLandingSmokeTestWithCompletion:^(BOOL passed) {
        if (!passed) { [self showError:@"smoke: terrain landing failed"]; return; }
        [self runTravelSmokeTestAfterTerrain];
    }];
}

- (void)runTravelSmokeTestAfterTerrain {
    // 非同期標高反映は停止後もカメラを動かせるため、中断試験中は保留する。
    NSString *savedTerrainDirectory = [_solar suspendTerrainForFlightSmoke];
    [_solar takeOffFromEarthAtLatitude:35.68 longitude:139.76];
    const double startDistance = [_solar cameraState].distance_au;
    if (!_solar.surfaceNavigationActive || !_solar.flightAnimating) {
        [self showError:[NSString stringWithFormat:@"smoke: flight did not start (surface=%d, flying=%d)",
            _solar.surfaceNavigationActive, _solar.flightAnimating]];
        return;
    }
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:2];
    // dispatch_after と NSTimer の処理順序には保証がないため、実タイマーの
    // 更新を待つ。停止や期限超過は別々に失敗させ、完了と誤認しない。
    NSTimer *progress = [NSTimer timerWithTimeInterval:0.02 repeats:YES block:^(NSTimer *timer) {
        const BOOL surface = self->_solar.surfaceNavigationActive;
        const BOOL flying = self->_solar.flightAnimating;
        const double distance = [self->_solar cameraState].distance_au;
        if (!surface || !flying) {
            [timer invalidate];
            [self showError:[NSString stringWithFormat:
                @"smoke: flight stopped before camera progress (surface=%d, flying=%d, start=%.17g, current=%.17g)",
                surface, flying, startDistance, distance]];
            return;
        }
        if (deadline.timeIntervalSinceNow <= 0) {
            [timer invalidate];
            [self showError:@"smoke: real flight timer progress was not observed within 2 seconds"];
            return;
        }
        if (distance == startDistance) {
            return;
        }
        [timer invalidate];
        [self->_solar interruptFlight];
        const auto paused = [self->_solar cameraState];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 120 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            const auto current = [self->_solar cameraState];
            if (self->_solar.flightAnimating || current.distance_au != paused.distance_au ||
                current.target.x != paused.target.x || current.target.y != paused.target.y ||
                current.target.z != paused.target.z) {
                [self showError:[NSString stringWithFormat:
                    @"smoke: interrupted flight changed the camera (flying=%d, distance %.17g -> %.17g, target (%.17g, %.17g, %.17g) -> (%.17g, %.17g, %.17g))",
                    self->_solar.flightAnimating, paused.distance_au, current.distance_au,
                    paused.target.x, paused.target.y, paused.target.z, current.target.x, current.target.y, current.target.z]]; return;
            }
            [self->_solar takeOff];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3400 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                const double expectedDistance = 9 * surface_body_info(3).radius_km / astronomical_unit_km;
                if (self->_solar.flightAnimating || !self->_solar.surfaceNavigationActive ||
                    std::abs([self->_solar cameraState].distance_au - expectedDistance) > 1e-12) {
                    [self showError:@"smoke: flight did not complete"]; return;
                }
                std::printf("Moon/travel AppKit smoke passed: Moon orbit/spin, landing targets, real flight timer, interruption, completion\n");
                [self->_solar setTerrainDataDirectory:savedTerrainDirectory];
                [self runContinuousFlightSmokeTest];
            });
        });
    }];
    [NSRunLoop.mainRunLoop addTimer:progress forMode:NSRunLoopCommonModes];
}
@end
