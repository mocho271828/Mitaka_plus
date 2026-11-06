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

namespace {
void setCameraTarget(SolarCamera& camera, const SolarCamera& source) {
    if (source.precise_target) {
        camera.set_target_pc(source.precise_target->anchor_pc);
        camera.translate_target_au(source.precise_target->offset_au);
    } else camera.set_target_au(source.target);
}

// 同じ遠方基準の間の小さな移動は、絶対 AU を合算する前に差を取る。
Vec3 targetDifference(const SolarCamera& destination, const SolarCamera& initial) {
    if (destination.precise_target && initial.precise_target) {
        const auto& a = destination.precise_target.value();
        const auto& b = initial.precise_target.value();
        return {(a.anchor_pc.x - b.anchor_pc.x) * astronomical_units_per_parsec + (a.offset_au.x - b.offset_au.x),
                (a.anchor_pc.y - b.anchor_pc.y) * astronomical_units_per_parsec + (a.offset_au.y - b.offset_au.y),
                (a.anchor_pc.z - b.anchor_pc.z) * astronomical_units_per_parsec + (a.offset_au.z - b.offset_au.z)};
    }
    return {destination.target.x - initial.target.x, destination.target.y - initial.target.y,
            destination.target.z - initial.target.z};
}
}

@interface SolarSystemView (ScriptTargetAnimationInternal)
- (void)animateScriptTargetFrom:(const SolarCamera&)initial duration:(double)duration includeOrientation:(BOOL)includeOrientation;
@end

@implementation SolarSystemView (ScriptTargets)
- (Vec3)scriptSpacePlacePositionForBodies:(const SolarBodies&)bodies {
    SurfaceNavigation navigation;
    navigation.set_site(*_scriptSpacePlace);
    const auto camera = navigation.camera(bodies);
    const auto basis = solar_camera_basis(camera);
    return {camera.target.x + basis.outward.x * camera.distance_au,
            camera.target.y + basis.outward.y * camera.distance_au,
            camera.target.z + basis.outward.z * camera.distance_au};
}
- (void)setScriptEarthPlaceTarget:(const std::string&)target { _scriptEarthPlaceTarget = target; }
- (const std::string&)scriptEarthPlaceTarget { return _scriptEarthPlaceTarget; }
- (const std::string&)scriptOverviewTarget { return _scriptOverviewTarget; }
- (BOOL)moveScriptEarthSurfaceLatitude:(double)latitude longitude:(double)longitude {
    SurfaceSite site;
    if (![self scriptSurfaceSite:&site] || site.body_index != 3) return NO;
    site.latitude_deg = latitude;
    site.longitude_deg = longitude;
    _navigation.set_site(site);
    _camera = _navigation.camera(_bodies);
    [self notifyCamera];
    self.needsDisplay = YES;
    return YES;
}
- (std::optional<double>)scriptTargetRadiusAU {
    if (_scriptOverviewTarget == "Other.SolarSystem") return 50.0;
    if (_scriptOverviewTarget == "Other.LSS") return 100000000.0 * astronomical_units_per_parsec;
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
    try {
    const auto state = *_targetAnimation;
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    const double t = std::clamp((now - state.start_time) / state.duration, 0.0, 1.0);
    constexpr double pi = 3.14159265358979323846;
    const double weight = (1.0 - std::cos(pi * t)) / 2.0;
    auto destination = state.target;
    Vec3 target = state.body ? [self displayPosition:*state.body] : destination.target;
    if (_scriptSpacePlace && state.body && *state.body == 3)
        target = [self scriptSpacePlacePositionForBodies:_bodies];
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
    if (state.body || state.small_body || state.spacecraft || state.satellite)
        destination.set_target_au(target);
    const Vec3 delta = targetDifference(destination, state.initial);
    const auto& base = weight < 0.5 ? state.initial : destination;
    const double factor = weight < 0.5 ? weight : weight - 1;
    auto next = _camera;
    setCameraTarget(next, base);
    if (t < 1) next.translate_target_au({delta.x * factor, delta.y * factor, delta.z * factor});
    if (state.updates_distance)
        next.distance_au = state.initial_distance + (state.target_distance - state.initial_distance) * weight;
    if (state.initial_orientation && state.target_orientation) {
        const auto orientation = plus_orientation_interpolate(*state.initial_orientation, *state.target_orientation, weight, false);
        next.frame = plus_orientation_basis(orientation);
        next.frame_is_orbit = true;
        next.roll_deg = 0;
    }
    [self keepCameraOutsideBodies:next];
    _camera = next;
    if (t >= 1) {
        _following = YES;
        [self stopScriptTargetTransition];
    }
    [self notifyCamera];
    self.needsDisplay = YES;
    } catch (const std::exception& error) {
        [self stopScriptTargetTransition];
        [self reportNavigationError:error.what()];
    }
}
- (void)animateScriptTargetFrom:(const SolarCamera&)initial duration:(double)duration {
    [self animateScriptTargetFrom:initial duration:duration includeOrientation:NO];
}
- (void)animateScriptPlaceTargetFrom:(const SolarCamera&)initial duration:(double)duration {
    [self animateScriptTargetFrom:initial duration:duration includeOrientation:YES];
}
- (void)animateScriptTargetFrom:(const SolarCamera&)initial duration:(double)duration includeOrientation:(BOOL)includeOrientation {
    [self stopScriptZoomAnimation];
    [self stopScriptTargetTransition];
    if (duration == 0) return;
    const auto destination = _camera;
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    std::optional<PlusOrientationQuaternion> initialOrientation, targetOrientation;
    if (_ourGalaxySelected || includeOrientation) {
        initialOrientation = plus_orientation_from_basis(solar_camera_basis(initial));
        targetOrientation = plus_orientation_from_basis(solar_camera_basis(destination));
    }
    _targetAnimation = ScriptTargetAnimation{initial, destination, initial.distance_au,
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
- (BOOL)selectScriptEarthPlaceLatitude:(double)latitude longitude:(double)longitude surface:(BOOL)surface error:(NSString **)error {
    if (!_hasData) {
        if (error) *error = @"Solar system is unavailable";
        return NO;
    }
    try {
        SurfaceSite site;
        if (surface) {
            if (![self scriptSurfaceSite:&site])
                throw std::invalid_argument("Earth place selection requires a surface observer");
            site.body_index = 3;
            site.latitude_deg = latitude;
            site.longitude_deg = longitude;
            SurfaceNavigation next;
            next.set_site(site);
            const auto camera = next.camera(_bodies);
            [self interruptFlight];
            _navigation = next;
            _camera = camera;
            [self selectBody:3];
        } else {
            site = SurfaceSite{3, latitude, longitude, surface_body_info(3).radius_km * 8, 0, -90};
            SurfaceNavigation next;
            next.set_site(site);
            auto camera = next.camera(_bodies);
            camera.distance_au = _camera.distance_au;
            camera.frame_is_orbit = true;
            [self leaveNavigation];
            [self selectBody:3];
            site.height_km = minimum_surface_height_km;
            _scriptSpacePlace = site;
            camera.set_target_au([self scriptSpacePlacePositionForBodies:_bodies]);
            _camera = camera;
            _physicalSpaceActive = YES;
            _following = YES;
        }
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
    [self notifyCamera];
    self.needsDisplay = YES;
    return YES;
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

- (BOOL)selectScriptOverviewTarget:(const std::string&)target error:(NSString **)error {
    if (!_hasData || (target != "Other.SolarSystem" && target != "Other.LSS")) {
        if (error) *error = @"Overview target is unavailable";
        return NO;
    }
    const auto frame = solar_camera_basis(_camera);
    [self leaveNavigation];
    [self clearGalaxySelection];
    _selection.reset(); _smallBodySelection.reset(); _satelliteSelection.reset(); _spacecraftSelection.reset();
    if (target == "Other.SolarSystem") _selection = 0;
    _scriptOverviewTarget = target;
    _following = YES;
    _camera.set_target_au([self displayPosition:0]);
    _camera.frame = frame;
    _camera.frame_is_orbit = true;
    _camera.roll_deg = 0;
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
    camera.set_target_pc({position.x_pc, position.y_pc, position.z_pc});
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
