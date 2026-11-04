#import "AppControllerInternal.h"
#include "surface_navigation.hpp"
#include <cstdio>
#include <cstdlib>

namespace {
bool sameCamera(const SolarCamera& a, const SolarCamera& b) {
    const auto close = [](mitaka::Vec3 x, mitaka::Vec3 y) {
        return std::hypot(x.x - y.x, x.y - y.y, x.z - y.z) < 1e-10;
    };
    const auto x = solar_camera_basis(a), y = solar_camera_basis(b);
    const mitaka::Vec3 aEye{a.target.x + x.outward.x * a.distance_au,
        a.target.y + x.outward.y * a.distance_au, a.target.z + x.outward.z * a.distance_au};
    const mitaka::Vec3 bEye{b.target.x + y.outward.x * b.distance_au,
        b.target.y + y.outward.y * b.distance_au, b.target.z + y.outward.z * b.distance_au};
    return close(aEye, bEye) && close(x.outward, y.outward) && close(x.up, y.up);
}
}

@implementation AppController (ContinuousFlightSmokeTests)
- (void)runContinuousFlightSmokeTest {
    if (![_solar runContinuousFlightSmokeTest]) {
        [self showError:@"smoke: deterministic continuous flight failed"]; return;
    }
    [_solar selectBody:0];
    if (_journeyButton.enabled) {
        [self showError:@"smoke: Sun must not be a landing destination"]; return;
    }
    [_solar selectBody:10];
    _latitudeField.stringValue = @"0";
    _longitudeField.stringValue = @"0";
    [_playback setSimulationRate:3600];
    [_playback play];
    const double startJD = _jd;
    [_journeyButton performClick:nil];
    if (!_solar.journeyActive || !_solar.flightAnimating || !_travelButtons[4].enabled) {
        [self showError:@"smoke: continuous flight controls did not start"]; return;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 300 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if (!self->_solar.flightAnimating || !(self->_jd > startJD)) {
            [self showError:@"smoke: orbit playback and flight did not advance together"]; return;
        }
        [self->_travelButtons[4] performClick:nil];
        const auto stopped = [self->_solar cameraState];
        if (!self->_solar.journeyActive || self->_solar.flightAnimating || !self->_resumeJourneyButton.enabled) {
            [self showError:@"smoke: continuous flight stop controls failed"]; return;
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 150 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            if (!sameCamera(stopped, [self->_solar cameraState])) {
                [self showError:@"smoke: stopped camera moved during ephemeris playback"]; return;
            }
            // performClick: の押下アニメーション中はタイマーが進むため、
            // 開始瞬間の連続性は同じボタンの action を同期送信して検証する。
            [NSApp sendAction:self->_resumeJourneyButton.action to:self->_resumeJourneyButton.target
                from:self->_resumeJourneyButton];
            if (!self->_solar.flightAnimating || !sameCamera(stopped, [self->_solar cameraState])) {
                [self showError:@"smoke: restart must preserve the stopped camera"]; return;
            }
            // 飛行中の選択変更は着陸先を変更しない。
            [self->_solar selectBody:4];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 24500 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
                [self->_playback pause];
                SurfaceNavigation destination;
                destination.set_site({10, 0, 0, minimum_surface_height_km, 0, 0});
                if (self->_solar.flightAnimating || self->_solar.journeyActive ||
                    !self->_solar.surfaceNavigationActive ||
                    !sameCamera(destination.camera(self->_solarBodies), [self->_solar cameraState])) {
                    [self showError:@"smoke: continuous flight did not land at the moving Moon site"]; return;
                }
                if (!(self->_jd > startJD + 0.5)) {
                    [self showError:@"smoke: continuous flight did not retain date playback"]; return;
                }
                std::printf("Continuous flight AppKit smoke passed: real timer, moving Moon, stop, restart, fixed destination, surface arrival\n");
                [NSApp terminate:nil];
            });
        });
    });
}
@end
