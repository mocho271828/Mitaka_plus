#import "SolarSystemViewInternal.h"
#include "HipSpatialRenderer.h"
#include "SpacecraftRenderer.h"
#include "shared_camera.hpp"
#include "our_galaxy_navigation.hpp"
#include <charconv>
#include <algorithm>
#include <chrono>
#include <cmath>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

@implementation SolarSystemView (ScriptTargets)
- (std::optional<double>)scriptTargetRadiusAU {
    if (_selection) {
        const auto index = *_selection;
        const double radius = index == 0 ? 696000.0 : surface_body_info(index).radius_km;
        return radius / astronomical_unit_km;
    }
    if (_ourGalaxySelected) return 15000.0 * astronomical_units_per_parsec;
    const auto model = [_galaxyOverlay model];
    if (!_galaxySelection || !model) return std::nullopt;
    const auto id = *_galaxySelection;
    const auto& source = model->sources().at(id.source_index);
    double radius = 0;
    if (const auto* catalog = std::get_if<PlusGlobularClusterCatalog>(&source)) {
        radius = catalog->records.at(id.ordinal).half_light_radius_pc;
    } else if (const auto* catalog = std::get_if<PlusNearbyGalaxyCatalog>(&source)) {
        const auto& record = catalog->records.at(id.ordinal);
        constexpr double pi = 3.14159265358979323846;
        const double angle = record.angular_diameter_arcminutes * pi / 43200.0;
        if (angle > 0 && angle < pi / 2) radius = record.distance_pc * std::tan(angle);
    }
    if (!std::isfinite(radius) || radius <= 0) return std::nullopt;
    return radius * astronomical_units_per_parsec;
}
- (void)applyScriptZoomMode:(int)mode previousRadius:(std::optional<double>)previousRadius initialDistance:(double)initialDistance {
    const auto radius = [self scriptTargetRadiusAU];
    double distance = initialDistance;
    if (mode == 2 && radius) distance = 9.0 * *radius;
    else if (mode == 1 && radius && previousRadius && *radius > *previousRadius) distance = 9.0 * *radius;
    // 星など大きさ不明の場合は、推測した極端なズームを避け距離を維持する。
    [self changeCamera:^(SolarCamera& next) { next.distance_au = std::clamp(distance, 0.000005, maximum_solar_distance_au); }];
}
- (void)stopScriptTargetTransition {
    [_targetTimer invalidate];
    _targetTimer = nil;
    _targetAnimation.reset();
}
- (void)advanceScriptTargetTransition {
    if (!_targetAnimation) return;
    const auto state = *_targetAnimation;
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    const double t = std::clamp((now - state.start_time) / state.duration, 0.0, 1.0);
    constexpr double pi = 3.14159265358979323846;
    const double weight = (1.0 - std::cos(pi * t)) / 2.0;
    Vec3 target = state.body ? [self displayPosition:*state.body] : state.target;
    if (state.small_body) {
        if (!_smallBodySnapshot || !_smallBodySelection || *_smallBodySelection != *state.small_body ||
            *state.small_body >= _smallBodySnapshot->positions.size() || !_smallBodySnapshot->positions[*state.small_body]) {
            [self stopScriptTargetTransition];
            return;
        }
        target = *_smallBodySnapshot->positions[*state.small_body];
    }
    if (state.spacecraft) {
        if (!_spacecraftSnapshot || !_spacecraftSelection || *_spacecraftSelection != *state.spacecraft) {
            [self stopScriptTargetTransition];
            return;
        }
        const auto position = spacecraft_scene_position(*_spacecraftSnapshot, *state.spacecraft);
        if (!position) { [self stopScriptTargetTransition]; return; }
        target = *position;
    }
    if (state.satellite) {
        if (!_satelliteSnapshot || !_satelliteSelection || *_satelliteSelection != *state.satellite ||
            *state.satellite >= _satelliteSnapshot->positions.size() || !_satelliteSnapshot->positions[*state.satellite]) {
            [self stopScriptTargetTransition];
            return;
        }
        target = *_satelliteSnapshot->positions[*state.satellite];
    }
    if ((state.galaxy && (!_galaxySelection || !(*state.galaxy == *_galaxySelection))) ||
        (state.our_galaxy && !_ourGalaxySelected)) {
        [self stopScriptTargetTransition];
        return;
    }
    _camera.target = {state.initial.x + (target.x - state.initial.x) * weight,
                      state.initial.y + (target.y - state.initial.y) * weight,
                      state.initial.z + (target.z - state.initial.z) * weight};
    _camera.distance_au = state.initial_distance + (state.target_distance - state.initial_distance) * weight;
    if (state.initial_orientation && state.target_orientation) {
        const auto orientation = plus_orientation_interpolate(*state.initial_orientation, *state.target_orientation, weight, false);
        _camera.frame = plus_orientation_basis(orientation);
        _camera.frame_is_orbit = true;
        _camera.roll_deg = 0;
    }
    if (t >= 1) {
        _following = YES;
        [self stopScriptTargetTransition];
    }
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (void)animateScriptTargetFrom:(const SolarCamera&)initial duration:(double)duration {
    [self stopScriptTargetTransition];
    if (duration == 0) return;
    const auto destination = _camera;
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    std::optional<PlusOrientationQuaternion> initialOrientation, targetOrientation;
    if (_ourGalaxySelected) {
        initialOrientation = plus_orientation_from_basis(solar_camera_basis(initial));
        targetOrientation = plus_orientation_from_basis(solar_camera_basis(destination));
    }
    _targetAnimation = ScriptTargetAnimation{initial.target, destination.target, initial.distance_au,
                                              destination.distance_au, now, duration, _selection, _smallBodySelection, _spacecraftSelection, _satelliteSelection, _galaxySelection, static_cast<bool>(_ourGalaxySelected), initialOrientation, targetOrientation};
    _camera = initial;
    _following = NO;
    [self notifyCamera];
    self.needsDisplay = YES;
    __weak SolarSystemView *weakSelf = self;
    _targetTimer = [NSTimer timerWithTimeInterval:1.0 / 30.0 repeats:YES block:^(NSTimer *timer) {
        SolarSystemView *view = weakSelf;
        if (view) [view advanceScriptTargetTransition]; else [timer invalidate];
    }];
    [NSRunLoop.mainRunLoop addTimer:_targetTimer forMode:NSRunLoopCommonModes];
}
- (std::optional<std::int32_t>)selectedScriptStarHIP {
    const auto model = [_galaxyOverlay hipModel];
    if (!model || !_hipSelection || *_hipSelection >= model->points.size()) return std::nullopt;
    return model->points[*_hipSelection].hip;
}
- (std::optional<GalaxySpatialRecordId>)selectedScriptGalaxyRecord { return _galaxySelection; }
- (BOOL)isScriptOurGalaxySelected { return _ourGalaxySelected; }
- (BOOL)selectScriptGalaxyRecord:(GalaxySpatialRecordId)record error:(NSString **)error {
    const auto model = [_galaxyOverlay model];
    try {
        if (!model || !model->row(record).position) throw std::invalid_argument("Galaxy position is unavailable");
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
    [self stopScriptTargetTransition];
    [self clearGalaxySelection];
    _selection.reset(); _smallBodySelection.reset(); _satelliteSelection.reset(); _spacecraftSelection.reset();
    _galaxySelection = record;
    _following = NO;
    [self notifySelection];
    return YES;
}
- (BOOL)selectScriptOurGalaxyOverview:(BOOL)overview error:(NSString **)error {
    if (![_galaxyOverlay ourGalaxyModel]) {
        if (error) *error = @"Our Galaxy model is unavailable";
        return NO;
    }
    SolarCamera destination;
    try {
        auto camera = galaxy_camera_from_shared(shared_camera_from_solar(_camera));
        if (overview) {
            const NSRect map = [self mapRect];
            camera = frame_our_galaxy({{0, 0, 0}}, camera, 8000, map.size.width, map.size.height);
        } else {
            camera = center_our_galaxy({{0, 0, 0}}, camera);
        }
        destination = solar_camera_from_shared(shared_camera_from_galaxy(camera));
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
    [self stopScriptTargetTransition];
    [self leaveNavigation];
    [self clearGalaxySelection];
    _selection.reset(); _smallBodySelection.reset(); _satelliteSelection.reset(); _spacecraftSelection.reset();
    _ourGalaxySelected = YES;
    _following = YES;
    _camera = destination;
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
    return YES;
}

- (BOOL)selectScriptStarTarget:(const std::string&)target error:(NSString **)error {
    constexpr std::string_view prefix = "Star.";
    const std::string_view text(target);
    std::int32_t hip = 0;
    if (text.substr(0, prefix.size()) != prefix) {
        if (error) *error = @"Unsupported star target";
        return NO;
    }
    const auto digits = text.substr(prefix.size());
    const auto parsed = std::from_chars(digits.data(), digits.data() + digits.size(), hip);
    if (digits.empty() || parsed.ec != std::errc{} || parsed.ptr != digits.data() + digits.size() || hip <= 0) {
        if (error) *error = @"Star target must contain a positive HIP number";
        return NO;
    }
    const auto model = [_galaxyOverlay hipModel];
    std::optional<std::size_t> index;
    if (model) {
        for (std::size_t i = 0; i < model->points.size(); ++i) {
            if (model->points[i].hip != hip) continue;
            if (index) {
                if (error) *error = @"HIP number is ambiguous in the loaded spatial catalog";
                return NO;
            }
            index = i;
        }
    }
    if (!index) {
        if (error) *error = @"HIP star has no available spatial position";
        return NO;
    }
    const auto position = model->points[*index].position;
    auto camera = _camera;
    camera.target = {position.x_pc * astronomical_units_per_parsec,
                     position.y_pc * astronomical_units_per_parsec,
                     position.z_pc * astronomical_units_per_parsec};
    try {
        (void)solar_camera_basis(camera);
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
    [self clearGalaxySelection];
    _selection.reset(); _smallBodySelection.reset(); _satelliteSelection.reset(); _spacecraftSelection.reset();
    _hipSelection = *index;
    _following = NO;
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
    return YES;
}
@end
