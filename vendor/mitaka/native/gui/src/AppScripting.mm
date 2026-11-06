#import "AppControllerInternal.h"
#include "star_brightness.hpp"
#include "SpacecraftRenderer.h"
#include "our_galaxy_navigation.hpp"
#include "shared_camera.hpp"
#include "galaxy_script_identity.hpp"
#include "mitaka/extended_catalog.hpp"
#import "HtmlBrowserController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include <array>
#include <algorithm>
#include <charconv>
#include <chrono>
#include <filesystem>
#include <stdexcept>

static constexpr std::array<const char *, 11> scriptBodyNames = {
    "Sun", "Planet.Mercury", "Planet.Venus", "Planet.Earth", "Planet.Mars", "Planet.Jupiter",
    "Planet.Saturn", "Planet.Uranus", "Planet.Neptune", "Planet.Pluto", "Satellite.Moon"};
static constexpr std::array<mitaka::gui::Body, 11> scriptBodies = {
    mitaka::gui::Body::sun, mitaka::gui::Body::mercury, mitaka::gui::Body::venus,
    mitaka::gui::Body::earth, mitaka::gui::Body::mars, mitaka::gui::Body::jupiter,
    mitaka::gui::Body::saturn, mitaka::gui::Body::uranus, mitaka::gui::Body::neptune,
    mitaka::gui::Body::pluto, mitaka::gui::Body::moon};

// 地平図と 3D 地表で同じ慣性座標の姿勢を使う。
static SurfaceSite horizonSite(HorizonViewport viewport, mitaka::ObserverSite observer) {
    return {3, observer.latitude_deg, observer.longitude_deg, minimum_surface_height_km,
            viewport.center_azimuth_deg, viewport.center_altitude_deg, viewport.roll_deg};
}

static PlusOrientationQuaternion horizonOrientation(HorizonViewport viewport, mitaka::ObserverSite observer,
                                                     const SolarBodies& bodies) {
    SurfaceNavigation navigation;
    navigation.set_site(horizonSite(viewport, observer));
    return plus_orientation_from_basis(solar_camera_basis(navigation.camera(bodies)));
}

static HorizonViewport horizonWithOrientation(HorizonViewport viewport, mitaka::ObserverSite observer,
                                               const SolarBodies& bodies, PlusOrientationQuaternion orientation) {
    auto site = horizonSite(viewport, observer);
    auto reference = site;
    reference.heading_deg = reference.elevation_deg = reference.roll_deg = 0;
    SurfaceNavigation navigation;
    navigation.set_site(reference);
    const auto local = solar_camera_basis(navigation.camera(bodies));
    const auto desired = plus_orientation_basis(plus_orientation_normalized(orientation));
    const auto dot = [](mitaka::Vec3 a, mitaka::Vec3 b) { return a.x*b.x + a.y*b.y + a.z*b.z; };
    constexpr double degrees = 180.0 / 3.14159265358979323846;
    const mitaka::Vec3 forward{-desired.outward.x, -desired.outward.y, -desired.outward.z};
    const double north = -dot(forward, local.outward), east = dot(forward, local.right);
    if (std::hypot(north, east) > 1e-12) site.heading_deg = std::atan2(east, north) * degrees;
    site.elevation_deg = std::asin(std::clamp(dot(forward, local.up), -1.0, 1.0)) * degrees;
    site.roll_deg = 0;
    navigation.set_site(site);
    const auto unrolled = solar_camera_basis(navigation.camera(bodies));
    site.roll_deg = std::atan2(dot(desired.right, unrolled.up), dot(desired.right, unrolled.right)) * degrees;
    viewport.center_azimuth_deg = site.heading_deg;
    viewport.center_altitude_deg = site.elevation_deg;
    viewport.roll_deg = site.roll_deg;
    return viewport;
}

static std::string resolveScriptStarTarget(const std::string& target, NSString *dataPath) {
    const std::string name = target.substr(5);
    if (!name.empty() && std::all_of(name.begin(), name.end(), [](unsigned char ch) { return ch >= '0' && ch <= '9'; }))
        return target;
    if (!dataPath) throw std::invalid_argument("Star-name catalog is unavailable");
    const auto path = std::filesystem::path(dataPath.fileSystemRepresentation) / "star_names_HIP.dat";
    std::optional<std::int32_t> hip;
    for (const auto& record : mitaka::load_star_names(path)) {
        if (record.name_bytes != name) continue;
        if (hip && *hip != record.hip) throw std::invalid_argument("Star name is ambiguous: " + name);
        hip = record.hip;
    }
    if (!hip) throw std::invalid_argument("Unknown star name: " + name);
    return "Star." + std::to_string(*hip);
}

static std::optional<std::size_t> resolveScriptSmallBody(const std::string& target,
                                                          const mitaka::gui::SmallBodyModel& model) {
    mitaka::SmallBodyKind kind;
    std::size_t prefix;
    if (target.compare(0, 10, "Asteroids.") == 0) { kind = mitaka::SmallBodyKind::asteroid; prefix = 10; }
    else if (target.compare(0, 4, "TNO.") == 0) { kind = mitaka::SmallBodyKind::trans_neptunian; prefix = 4; }
    else if (target.compare(0, 6, "Comet.") == 0) { kind = mitaka::SmallBodyKind::comet; prefix = 6; }
    else return std::nullopt;
    const std::string name = target.substr(prefix);
    if (name.empty()) throw std::invalid_argument("Empty small-body target");
    std::int32_t number = 0;
    const auto parsed = std::from_chars(name.data(), name.data() + name.size(), number);
    const bool isNumber = kind != mitaka::SmallBodyKind::comet && parsed.ec == std::errc{} &&
                          parsed.ptr == name.data() + name.size() && number > 0;
    std::optional<std::size_t> match;
    const auto& records = model.dataset().records;
    for (std::size_t index = 0; index < records.size(); ++index) {
        const auto& record = records[index];
        if (record.kind != kind) continue;
        const bool matches = isNumber ? record.number == number :
            record.name_bytes == name || std::find(record.alias_bytes.begin(), record.alias_bytes.end(), name) != record.alias_bytes.end();
        if (!matches) continue;
        if (match) throw std::invalid_argument("Ambiguous small-body target: " + target);
        match = index;
    }
    if (!match) throw std::invalid_argument("Unknown small-body target: " + target);
    return match;
}

static std::size_t resolveScriptSpacecraft(const std::string& target,
                                            const mitaka::gui::SpacecraftBrowserModel& model) {
    const std::string name = target.substr(11);
    if (name.empty()) throw std::invalid_argument("Empty spacecraft target");
    std::optional<std::size_t> match;
    const auto& definitions = model.model().dataset().definitions;
    for (std::size_t index = 0; index < definitions.size(); ++index) {
        const auto* display = mitaka::unique_spacecraft_field(definitions[index], "DisplayName");
        const auto* internal = mitaka::unique_spacecraft_field(definitions[index], "Name");
        if ((!display || display->value_bytes != name) && (!internal || internal->value_bytes != name)) continue;
        if (match) throw std::invalid_argument("Ambiguous spacecraft target: " + target);
        match = index;
    }
    if (!match) throw std::invalid_argument("Unknown spacecraft target: " + target);
    return *match;
}

static std::size_t resolveScriptSatellite(const std::string& target,
                                          const mitaka::gui::SatelliteBrowserModel& model,
                                          std::optional<std::string> source) {
    const auto name = target.substr(10);
    if (name.empty()) throw std::invalid_argument("Empty satellite target");
    std::optional<std::size_t> match;
    const auto& records = model.model().records();
    for (std::size_t index = 0; index < records.size(); ++index) {
        if (records[index].identifier_bytes != name || (source && model.source(index) != *source)) continue;
        if (match) throw std::invalid_argument("Ambiguous satellite target; select its source in the satellite browser: " + target);
        match = index;
    }
    if (!match) throw std::invalid_argument("Unknown satellite target in the selected source: " + target);
    return *match;
}

static mitaka::gui::GalaxySpatialRecordId resolveScriptGlobularCluster(
    const std::string& target, const mitaka::gui::GalaxySpatialModel& model) {
    return mitaka::gui::resolve_script_globular_cluster(target, model);
}

static mitaka::gui::GalaxySpatialRecordId resolveScriptNearbyGalaxy(
    const std::string& target, NSString *dataPath, const mitaka::gui::GalaxySpatialModel& model) {
    const std::optional<std::filesystem::path> path = dataPath
        ? std::optional{std::filesystem::path(dataPath.fileSystemRepresentation)} : std::nullopt;
    return mitaka::gui::resolve_script_nearby_galaxy(target, path, model);
}

static std::size_t resolveScriptConstellation(const std::string& target, const mitaka::gui::SkyModel& model) {
    const auto name = target.substr(8);
    std::optional<std::size_t> match;
    const auto& records = model.constellations();
    for (std::size_t index = 0; index < records.size(); ++index) {
        if (name.empty() || (records[index].english_name != name && records[index].abbreviation != name)) continue;
        if (match) throw std::invalid_argument("Ambiguous constellation target: " + target);
        match = index;
    }
    if (!match) throw std::invalid_argument("Unknown constellation target: " + target);
    return *match;
}

static NSString *const scriptCompatibilityNote =
    @"対応: Time の日時・速度・時計追従、Camera の target・look・zoom・azimuth・altitude、星座・恒星・惑星・座標線・天の川の対応済み表示設定、Renderer の描画品質、GUI の既存ウィンドウ・全画面・情報表示。\n"
     "未対応の API はエラーを表示して停止します。\n";

@implementation AppController (Scripting)
- (void)stopScriptPlaceTransition {
    [_scriptPlaceTimer invalidate];
    _scriptPlaceTimer = nil;
    if (_scriptPlaceTransition && [_solar scriptEarthPlaceTarget] == _scriptPlaceTransition->target)
        [_solar setScriptEarthPlaceTarget:std::string{}];
    _scriptPlaceTransition.reset();
}
- (void)advanceScriptPlaceTransition {
    if (!_scriptPlaceTransition) return;
    const auto state = *_scriptPlaceTransition;
    if (_mode.selectedSegment != state.mode || [_solar scriptEarthPlaceTarget] != state.target) {
        [self stopScriptPlaceTransition];
        return;
    }
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    const double progress = std::clamp((now - state.start_time) / state.duration, 0.0, 1.0);
    constexpr double pi = 3.14159265358979323846;
    const double angle = state.angle * (1 - std::cos(pi * progress)) / 2;
    const mitaka::Vec3 position{state.start.x * std::cos(angle) + state.tangent.x * std::sin(angle),
        state.start.y * std::cos(angle) + state.tangent.y * std::sin(angle),
        state.start.z * std::cos(angle) + state.tangent.z * std::sin(angle)};
    const double latitude = progress >= 1 ? state.latitude : std::atan2(position.z, std::hypot(position.x, position.y)) * 180 / pi;
    const double longitude = progress >= 1 ? state.longitude : std::atan2(position.y, position.x) * 180 / pi;
    if (state.mode == 1 && ![_solar moveScriptEarthSurfaceLatitude:latitude longitude:longitude]) {
        [self stopScriptPlaceTransition];
        return;
    }
    _observerLatitude = latitude;
    _observerLongitude = longitude;
    [_horizon setObserverSite:{latitude, longitude}];
    [_sky setObservationSite:{latitude, longitude} julianDate:_jd];
    [_solar setObservationSite:{latitude, longitude} julianDate:_jd];
    if (progress >= 1) {
        [_horizon setObserverPlaceIdentifier:state.target];
        _scriptPlaceTransition.reset();
        [self stopScriptPlaceTransition];
    }
}
- (void)startScriptPlaceTransitionToLatitude:(double)latitude longitude:(double)longitude
                                  duration:(double)duration target:(const std::string&)target {
    [self stopScriptPlaceTransition];
    auto unit = [](double lat, double lon) {
        constexpr double r = 3.14159265358979323846 / 180;
        return mitaka::Vec3{std::cos(lat*r)*std::cos(lon*r), std::cos(lat*r)*std::sin(lon*r), std::sin(lat*r)};
    };
    SurfaceSite site;
    const bool surface = _mode.selectedSegment == 1 && [_solar scriptSurfaceSite:&site];
    const auto start = unit(surface ? site.latitude_deg : _observerLatitude, surface ? site.longitude_deg : _observerLongitude);
    const auto end = unit(latitude, longitude);
    const double dot = std::clamp(start.x*end.x + start.y*end.y + start.z*end.z, -1.0, 1.0);
    mitaka::Vec3 tangent{end.x - dot*start.x, end.y - dot*start.y, end.z - dot*start.z};
    double length = std::hypot(std::hypot(tangent.x, tangent.y), tangent.z);
    if (length < 1e-12) {
        // 対蹠点では経路が一意でないため、安定した直交方向を選ぶ。
        const auto axis = std::abs(start.z) < 0.9 ? mitaka::Vec3{0, 0, 1} : mitaka::Vec3{1, 0, 0};
        tangent = {axis.x - start.x*(axis.x*start.x + axis.z*start.z),
                   -start.y*(axis.x*start.x + axis.z*start.z),
                   axis.z - start.z*(axis.x*start.x + axis.z*start.z)};
        length = std::hypot(std::hypot(tangent.x, tangent.y), tangent.z);
    }
    tangent = {tangent.x / length, tangent.y / length, tangent.z / length};
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    _scriptPlaceTransition = ScriptPlaceTransition{start, tangent, std::acos(dot), now, duration, latitude, longitude, _mode.selectedSegment, target};
    [_horizon setObserverPlaceIdentifier:std::string{}];
    __weak AppController *weakSelf = self;
    _scriptPlaceTimer = [NSTimer timerWithTimeInterval:1.0 / 30.0 repeats:YES block:^(NSTimer *timer) {
        AppController *controller = weakSelf;
        if (controller) [controller advanceScriptPlaceTransition]; else [timer invalidate];
    }];
    [NSRunLoop.mainRunLoop addTimer:_scriptPlaceTimer forMode:NSRunLoopCommonModes];
}
- (HorizonViewport)scriptCameraViewport {
    auto viewport = [_horizon viewport];
    SurfaceSite site;
    if (_mode.selectedSegment == 1 && [_solar scriptSurfaceSite:&site]) {
        viewport.center_azimuth_deg = site.heading_deg;
        viewport.center_altitude_deg = site.elevation_deg;
    }
    return viewport;
}
- (void)setScriptCameraViewport:(HorizonViewport)viewport {
    if (_mode.selectedSegment == 1 && [_solar scriptPlanetariumMode]) {
        [_solar scriptSetSurfaceAzimuth:viewport.center_azimuth_deg altitude:viewport.center_altitude_deg];
    } else {
        [_horizon setViewport:viewport];
    }
}
- (BOOL)scriptLookViewport:(const ScriptLookTarget&)target result:(HorizonViewport *)result {
    const bool surface = _mode.selectedSegment == 1 && [_solar scriptPlanetariumMode];
    auto surfaceLook = [&](mitaka::Vec3 vector, bool isPosition) {
        SurfaceSite site;
        if (![_solar scriptSurfaceLookVector:vector position:isPosition result:&site]) return NO;
        *result = [self scriptCameraViewport];
        result->center_azimuth_deg = site.heading_deg;
        result->center_altitude_deg = site.elevation_deg;
        return YES;
    };
    if (target.kind == ScriptLookTarget::Kind::body) {
        if (!surface) return [_horizon viewportForBody:scriptBodies[target.index] result:result];
        mitaka::Vec3 position;
        return [_solar scriptBodyEclipticPosition:target.index result:&position] && surfaceLook(position, true);
    }
    if (target.kind == ScriptLookTarget::Kind::star) {
        if (!surface) return [_horizon viewportForStarHIP:static_cast<std::int32_t>(target.index) result:result];
        if (!_model) return NO;
        const auto index = _model->star_index(static_cast<std::int32_t>(target.index));
        if (!index) return NO;
        const auto& star = _model->stars()[*index];
        const auto direction = mitaka::equatorial_direction({star.right_ascension_degrees, star.declination_degrees});
        return surfaceLook(mitaka::j2000_equatorial_to_ecliptic(direction), false);
    }
    if (target.kind == ScriptLookTarget::Kind::constellation) {
        if (!target.constellation_model || target.index >= target.constellation_model->constellations().size()) return NO;
        const auto& record = target.constellation_model->constellations()[target.index];
        if (surface) {
            const auto direction = mitaka::equatorial_direction({record.right_ascension_degrees, record.declination_degrees});
            return surfaceLook(mitaka::j2000_equatorial_to_ecliptic(direction), false);
        }
        const mitaka::ObservationFrame frame(_horizon.observerSite, _horizon.julianDate);
        const auto point = frame.to_horizontal({record.right_ascension_degrees, record.declination_degrees});
        *result = [_horizon viewport];
        result->center_azimuth_deg = point.azimuth_deg;
        result->center_altitude_deg = point.altitude_deg;
        return YES;
    }
    std::optional<mitaka::Vec3> position;
    if (target.kind == ScriptLookTarget::Kind::our_galaxy) {
        if (![_solar ourGalaxyModel]) return NO;
        const auto p = mitaka::gui::our_galaxy_center({{0, 0, 0}});
        position = mitaka::Vec3{p.x_pc * mitaka::gui::astronomical_units_per_parsec,
                                p.y_pc * mitaka::gui::astronomical_units_per_parsec,
                                p.z_pc * mitaka::gui::astronomical_units_per_parsec};
    } else if (target.kind == ScriptLookTarget::Kind::galaxy) {
        if (!target.galaxy_model || target.galaxy_model != _galaxyModel || target.index >= target.galaxy_model->size()) return NO;
        const auto p = target.galaxy_model->row(target.galaxy_model->record_id(target.index)).position;
        if (!p) return NO;
        position = mitaka::Vec3{p->x_pc * mitaka::gui::astronomical_units_per_parsec,
                                p->y_pc * mitaka::gui::astronomical_units_per_parsec,
                                p->z_pc * mitaka::gui::astronomical_units_per_parsec};
    } else if (target.kind == ScriptLookTarget::Kind::small_body) {
        if (!_smallBodyModel) return NO;
        if (!_scriptLookSmallBodySnapshot || _scriptLookSmallBodySnapshot->model != _smallBodyModel ||
            _scriptLookSmallBodySnapshot->julian_date != _jd ||
            target.index >= _scriptLookSmallBodySnapshot->positions.size() ||
            !_scriptLookSmallBodySnapshot->positions[target.index])
            _scriptLookSmallBodySnapshot = evaluate_small_body_snapshot(_smallBodyModel, _jd, false, target.index);
        if (target.index < _scriptLookSmallBodySnapshot->positions.size())
            position = _scriptLookSmallBodySnapshot->positions[target.index];
    } else if (target.kind == ScriptLookTarget::Kind::satellite) {
        if (!_satelliteSnapshot || _satelliteSnapshot->model != _satelliteModel ||
            _satelliteSnapshot->julian_date != _jd || target.index >= _satelliteSnapshot->positions.size()) return NO;
        position = _satelliteSnapshot->positions[target.index];
    } else {
        if (!_spacecraftModel) return NO;
        if (!_scriptLookSpacecraftSnapshot || _scriptLookSpacecraftSnapshot->model != _spacecraftModel ||
            _scriptLookSpacecraftSnapshot->julian_date != _jd)
            _scriptLookSpacecraftSnapshot = [self spacecraftSnapshotAtDate:_jd];
        if (_scriptLookSpacecraftSnapshot) position = spacecraft_scene_position(*_scriptLookSpacecraftSnapshot, target.index);
    }
    if (!position) return NO;
    if (surface) return surfaceLook(*position, true);
    if (target.kind == ScriptLookTarget::Kind::small_body || target.kind == ScriptLookTarget::Kind::spacecraft)
        return [_horizon viewportForTopocentricHeliocentricPosition:*position julianDate:_jd result:result];
    return [_horizon viewportForHeliocentricPosition:*position julianDate:_jd result:result];
}
- (void)stopScriptCameraAnimation {
    _scriptAzimuthAnimation.reset();
    _scriptAltitudeAnimation.reset();
    _horizonOrientationAnimation.reset();
    _scriptLookTarget.reset();
    _scriptLookSmallBodySnapshot.reset();
    _scriptLookSpacecraftSnapshot.reset();
    [_scriptCameraTimer invalidate];
    _scriptCameraTimer = nil;
}
- (void)updateScriptCameraAnimations {
    if (_horizonOrientationAnimation) {
        const auto state = *_horizonOrientationAnimation;
        const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
        const double t = std::clamp((now - state.start_time) / state.duration, 0.0, 1.0);
        try {
            PlusOrientationQuaternion q;
            if (state.quaternion) q = plus_orientation_interpolate(state.initial, state.target, t, state.smooth);
            else {
                const auto e = plus_orientation_interpolate_euler(state.initial_euler, state.target_euler, t, state.smooth);
                q = plus_orientation_from_euler(e.heading, e.pitch, e.roll);
                if (state.relative) q = plus_orientation_multiply(state.initial, q);
            }
            [_horizon setViewport:horizonWithOrientation([_horizon viewport], _horizon.observerSite, _solarBodies, q)];
        } catch (const std::exception& failure) {
            [self stopScriptCameraAnimation];
            _status.stringValue = [NSString stringWithFormat:@"姿勢を変更できません: %s", failure.what()];
            return;
        }
        if (t >= 1) [self stopScriptCameraAnimation];
        return;
    }
    std::optional<HorizonViewport> lookViewport;
    if (_scriptLookTarget) {
        HorizonViewport target;
        try {
            if (![self scriptLookViewport:*_scriptLookTarget result:&target]) {
                [self stopScriptCameraAnimation];
                _status.stringValue = @"注視対象の現在位置を取得できないため、カメラの移動を停止しました。";
                return;
            }
        } catch (const std::exception& failure) {
            [self stopScriptCameraAnimation];
            _status.stringValue = [NSString stringWithFormat:@"注視対象の評価に失敗しました: %s", failure.what()];
            return;
        }
        if (_scriptAzimuthAnimation) _scriptAzimuthAnimation->target = _scriptAzimuthAnimation->start +
            std::remainder(target.center_azimuth_deg - _scriptAzimuthAnimation->start, 360.0);
        if (_scriptAltitudeAnimation) _scriptAltitudeAnimation->target = target.center_altitude_deg;
        lookViewport = target;
    }
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    auto viewport = [self scriptCameraViewport];
    const auto previousViewport = viewport;
    if (lookViewport) {
        if (!_scriptAzimuthAnimation) viewport.center_azimuth_deg = lookViewport->center_azimuth_deg;
        if (!_scriptAltitudeAnimation) viewport.center_altitude_deg = lookViewport->center_altitude_deg;
    }
    auto sample = [now](std::optional<ScriptCameraAnimation>& animation, double& value) {
        if (!animation) return;
        const auto state = *animation;
        const double progress = std::clamp((now - state.start_time) / state.duration, 0.0, 1.0);
        constexpr double pi = 3.14159265358979323846;
        const double weight = state.smooth ? (1.0 - std::cos(pi * progress)) / 2.0 : progress;
        value = state.start + (state.target - state.start) * weight;
        if (progress >= 1.0) { value = state.target; animation.reset(); }
    };
    sample(_scriptAzimuthAnimation, viewport.center_azimuth_deg);
    sample(_scriptAltitudeAnimation, viewport.center_altitude_deg);
    if (std::abs(std::remainder(viewport.center_azimuth_deg - previousViewport.center_azimuth_deg, 360.0)) > 1e-9 ||
        std::abs(viewport.center_altitude_deg - previousViewport.center_altitude_deg) > 1e-9)
        [self setScriptCameraViewport:viewport];
    if (!_scriptAzimuthAnimation && !_scriptAltitudeAnimation && !_scriptLookTarget) {
        [self stopScriptCameraAnimation];
    }
}
- (void)startScriptCameraTimer {
    if (_scriptCameraTimer) return;
    __weak AppController *weakSelf = self;
    _scriptCameraTimer = [NSTimer timerWithTimeInterval:1.0 / 30.0 repeats:YES block:^(NSTimer *timer) {
        AppController *controller = weakSelf;
        if (controller) [controller updateScriptCameraAnimations];
        else [timer invalidate];
    }];
    [NSRunLoop.mainRunLoop addTimer:_scriptCameraTimer forMode:NSRunLoopCommonModes];
}
- (void)stopScriptFovAnimation {
    _scriptFovAnimation.reset();
    [_scriptFovTimer invalidate];
    _scriptFovTimer = nil;
}
- (void)updateScriptFovAnimation {
    if (!_scriptFovAnimation) return;
    if (_mode.selectedSegment != 2 || _horizonProjectionTimer || [_horizon viewport].perspective_blend != 0) {
        [self stopScriptFovAnimation];
        return;
    }
    const auto animation = *_scriptFovAnimation;
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    const double t = std::clamp((now - animation.start_time) / animation.duration, 0.0, 1.0);
    auto viewport = [_horizon viewport];
    viewport.vertical_fov_deg = t >= 1 ? animation.target : animation.start + (animation.target - animation.start) * t;
    [_horizon setViewport:viewport];
    if (t >= 1) [self stopScriptFovAnimation];
}
- (BOOL)animateScriptFovTo:(double)target duration:(double)duration error:(NSString **)error {
    if (_mode.selectedSegment != 2 || _horizonProjectionTimer || [_horizon viewport].perspective_blend != 0 ||
        !std::isfinite(target) || target <= 0 || target > 90 || !std::isfinite(duration) || duration < 0) {
        if (error) *error = @"視野角は地平図で 0 より大きく 90 度以下、時間は 0 秒以上にしてください。";
        return NO;
    }
    if (_scriptFovAnimation) [self updateScriptFovAnimation];
    const double initial = [_horizon viewport].vertical_fov_deg;
    [self stopScriptFovAnimation];
    if (duration == 0 || initial == target) {
        auto viewport = [_horizon viewport];
        viewport.vertical_fov_deg = target;
        [_horizon setViewport:viewport];
        return YES;
    }
    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    _scriptFovAnimation = ScriptCameraAnimation{initial, target, now, duration, false};
    __weak AppController *weakSelf = self;
    _scriptFovTimer = [NSTimer timerWithTimeInterval:1.0 / 30.0 repeats:YES block:^(NSTimer *timer) {
        AppController *controller = weakSelf;
        if (controller) [controller updateScriptFovAnimation];
        else [timer invalidate];
    }];
    [NSRunLoop.mainRunLoop addTimer:_scriptFovTimer forMode:NSRunLoopCommonModes];
    return YES;
}
- (void)resetViewAngle:(id)sender {
    (void)sender;
    NSString *error = nil;
    if (![self animateScriptFovTo:45 duration:0 error:&error] && error) [self showError:error];
}
- (void)configureScripts {
    if (_scripts) return;
    _scripts = [[ScriptController alloc] init];
    __weak AppController *weakSelf = self;
    _scripts.snapshot = ^ScriptSnapshot {
        AppController *controller = weakSelf;
        ScriptSnapshot state;
        if (!controller) return state;
        [controller fillScriptTimeSnapshot:state];
        const NSUInteger selected = controller->_solar.selectedBodyIndex;
        if (![controller->_solar scriptOverviewTarget].empty())
            state.target = [controller->_solar scriptOverviewTarget];
        else if (selected == 3 && ![controller->_solar scriptEarthPlaceTarget].empty())
            state.target = [controller->_solar scriptEarthPlaceTarget];
        else if (selected < scriptBodyNames.size()) state.target = scriptBodyNames[selected];
        else if (const auto hip = [controller->_solar selectedScriptStarHIP]) {
            state.target = controller->_scriptStarHIP == hip ? controller->_scriptStarTarget : "Star." + std::to_string(*hip);
        }
        else if (controller->_scriptSmallBodyIndex &&
                 controller->_solar.selectedSmallBodyIndex == *controller->_scriptSmallBodyIndex)
            state.target = controller->_scriptSmallBodyTarget;
        else if (controller->_scriptSpacecraftIndex &&
                 controller->_solar.selectedSpacecraftIndex == *controller->_scriptSpacecraftIndex)
            state.target = controller->_scriptSpacecraftTarget;
        else if (controller->_satelliteModel &&
                 controller->_solar.selectedSatelliteIndex < controller->_satelliteModel->model().records().size())
            state.target = "Satellite." + controller->_satelliteModel->model().records()[controller->_solar.selectedSatelliteIndex].identifier_bytes;
        else if (const auto galaxy = [controller->_solar selectedScriptGalaxyRecord]) {
            state.target = mitaka::gui::script_galaxy_target_for_snapshot(
                controller->_galaxyModel.get(), *galaxy, controller->_scriptGalaxyModel.get(),
                controller->_scriptGalaxyRecord, controller->_scriptGalaxyTarget,
                controller->_activePath ? std::optional{std::filesystem::path(controller->_activePath.fileSystemRepresentation)} : std::nullopt);
        }
        else if ([controller->_solar isScriptOurGalaxySelected] && !controller->_scriptOurGalaxyTarget.empty())
            state.target = controller->_scriptOurGalaxyTarget;
        state.camera_distance_au = [controller->_solar cameraState].distance_au;
        state.constellation_lines = controller->_sky.showsConstellationLines;
        state.constellation_boundaries = controller->_sky.showsConstellationBoundaries;
        state.constellation_labels = controller->_sky.showsConstellationNames;
        state.constellation_illustrations = [controller constellationDisplayOptions].illustrations;
        state.asteroids = [controller smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::asteroid];
        state.tnobjects = [controller smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::trans_neptunian];
        state.comets = [controller smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::comet];
        state.satellites = [controller satelliteDisplayOptions];
        state.planets = [controller planetDisplayOptions];
        // 共通 snapshot はロード中にも GUI の状態取得に使われる。
        state.radius_display = controller->_radiusDisplayOptions;
        state.radius_scale_mode = controller->_radiusScaleMode;
        state.terrain_amplification = [controller terrainAmplification];
        state.eclipse = [controller eclipseDisplayOptions];
        state.landscape = controller->_horizon.showsLandscapeImage;
        const auto earthLayers = [controller earthLayerOptions];
        state.earth_clouds = earthLayers.clouds;
        state.earth_city_lights = earthLayers.city_lights;
        switch ([controller atmosphereDisplayOptions].mode) {
            case AtmosphereMode::none: state.atmosphere_mode = 0; break;
            case AtmosphereMode::single: state.atmosphere_mode = 1; break;
            case AtmosphereMode::multiple: state.atmosphere_mode = 2; break;
        }
        state.stars = [controller starDisplayOptions];
        state.selected_star_names = [controller selectedStarNameHIPs];
        state.grids = [controller gridDisplayOptions];
        state.renderer = [controller rendererDisplayOptions];
        state.full_screen = [controller fullScreen];
        switch (controller->_sky.milkyWayMode) {
            case MilkyWayMode::none: state.milky_way_type = "None"; break;
            case MilkyWayMode::normal: state.milky_way_type = "Normal"; break;
            case MilkyWayMode::bright: state.milky_way_type = "Bright"; break;
            case MilkyWayMode::infrared: state.milky_way_type = "Infrared"; break;
        }
        state.nebulae = controller->_sky.showsNebulae;
        state.distant_galaxies = controller->_sky.showsGalaxies;
        state.quasars = controller->_sky.showsQuasars;
        const auto scriptViewport = [controller scriptCameraViewport];
        const double azimuth = scriptViewport.center_azimuth_deg;
        state.camera_azimuth_deg = azimuth > 180 ? azimuth - 360 : azimuth;
        state.camera_altitude_deg = scriptViewport.center_altitude_deg;
        if (controller->_mode.selectedSegment == 2 && !controller->_horizonProjectionTimer &&
            [controller->_horizon viewport].perspective_blend == 0)
            state.camera_fov = [controller->_horizon viewport].vertical_fov_deg;
        state.camera_duration = controller->_scriptCameraDuration;
        state.camera_zoom_mode = controller->_scriptCameraZoomMode;
        if (controller->_mode.selectedSegment == 1)
            state.camera_mode = controller->_solar.scriptPlanetariumMode ? 0 : 1;
        else if (controller->_mode.selectedSegment == 2) state.camera_mode = 0;
        state.camera_mode_duration = controller->_scriptCameraModeDuration.value_or(7.1);
        if ((controller->_mode.selectedSegment == 1 && [controller->_solar scriptCameraOrientationAvailable]) ||
            (controller->_mode.selectedSegment == 2 && controller->_model)) {
            const auto q = controller->_mode.selectedSegment == 2
                ? horizonOrientation([controller->_horizon viewport], controller->_horizon.observerSite, controller->_solarBodies)
                : [controller->_solar scriptCameraOrientation];
            const auto e = plus_orientation_to_euler(q);
            state.camera_orientation = std::array<double, 4>{static_cast<float>(q.x), static_cast<float>(q.y),
                static_cast<float>(q.z), static_cast<float>(q.w)};
            state.camera_euler = std::array<double, 3>{e.heading, e.pitch, e.roll};
        }
        state.target_browser = controller->_browser.window.visible;
        state.time_setting = controller->_calendarWindow.visible;
        state.place_setting = controller->_observerWindow.visible;
        state.script_output = controller->_scriptWindow.visible;
        state.dual_screen = controller->_displayOutput.projectionVisible;
        return state;
    };
    _scripts.applyAction = ^BOOL(const ScriptAction& action, NSString **error) {
        return [weakSelf applyScriptAction:action error:error];
    };
    _scripts.output = ^(NSString *text) {
        AppController *controller = weakSelf;
        if (!controller) return;
        NSTextStorage *storage = controller->_scriptLog.textStorage;
        // output は print 一回ごとのレコード。文字列内の改行も保持して Lua の行出力に合わせる。
        [storage appendAttributedString:[[NSAttributedString alloc] initWithString:[text stringByAppendingString:@"\n"]]];
        // 長時間動くスクリプトの出力でウィンドウのメモリが増え続けることを防ぐ。
        constexpr NSUInteger limit = 1024 * 1024;
        if (storage.length > limit) [storage deleteCharactersInRange:NSMakeRange(0, storage.length - limit)];
        [controller->_scriptLog scrollRangeToVisible:NSMakeRange(storage.length, 0)];
    };
    _scripts.completion = ^(BOOL succeeded, NSString *message) {
        AppController *controller = weakSelf;
        if (!controller) return;
        controller->_scripts.output(message);
        if (!succeeded) [controller showError:message];
    };
}
- (void)showScriptConsole:(id)sender {
    (void)sender;
    if (!_scriptWindow) {
        _scriptWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 740, 420)
            styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
            backing:NSBackingStoreBuffered defer:NO];
        _scriptWindow.releasedWhenClosed = NO;
        _scriptWindow.title = @"ローカル Lua スクリプト";
        NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:_scriptWindow.contentView.bounds];
        scroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        scroll.hasVerticalScroller = YES;
        _scriptLog = [[NSTextView alloc] initWithFrame:scroll.bounds];
        _scriptLog.editable = NO;
        _scriptLog.string = scriptCompatibilityNote;
        _scriptLog.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
        _scriptLog.autoresizingMask = NSViewWidthSizable;
        scroll.documentView = _scriptLog;
        [_scriptWindow.contentView addSubview:scroll];
        [_scriptWindow center];
    }
    [_scriptWindow makeKeyAndOrderFront:nil];
}
- (void)runScript:(id)sender {
    (void)sender;
    if (!_model || _loading || _scripts.running) return;
    [self configureScripts];
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    UTType *luaType = [UTType typeWithFilenameExtension:@"lua"];
    panel.allowedContentTypes = @[luaType ? luaType : UTTypePlainText];
    panel.message = @"信頼したローカル Lua ファイルを選択してください。ファイルの読み書きとコマンド実行を許可して実行します。";
    [panel beginSheetModalForWindow:_window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK || !self->_model || self->_loading) return;
        [self showScriptConsole:nil];
        self->_scriptLog.string = [NSString stringWithFormat:@"実行: %@\n%@", panel.URL.path, scriptCompatibilityNote];
        self->_scripts.workingDirectoryURL = [NSURL fileURLWithPath:self->_activePath.stringByDeletingLastPathComponent isDirectory:YES];
        NSError *error = nil;
        if (![self->_scripts runFile:panel.URL error:&error]) [self showError:error.localizedDescription];
    }];
}
- (void)showHtmlBrowser:(id)sender {
    (void)sender;
    if (!_htmlBrowser) {
        _htmlBrowser = [HtmlBrowserController new];
        __weak AppController *weakSelf = self;
        _htmlBrowser.scriptRequested = ^BOOL(NSString *source, NSURL *file, NSString **failure) {
            AppController *controller = weakSelf;
            if (!controller || !controller->_model || controller->_loading) {
                if (failure) *failure = @"天文データが使用できません。";
                return NO;
            }
            [controller configureScripts];
            if (controller->_scripts.running) {
                if (failure) *failure = @"実行中の Lua を停止してからリンクを押してください。";
                return NO;
            }
            [controller showScriptConsole:nil];
            controller->_scripts.workingDirectoryURL = [NSURL fileURLWithPath:controller->_activePath.stringByDeletingLastPathComponent isDirectory:YES];
            NSError *error = nil;
            if (![controller->_scripts runSource:source error:&error]) {
                if (failure) *failure = error.localizedDescription;
                return NO;
            }
            controller->_scripts.output([NSString stringWithFormat:@"ローカル HTML から実行: %@", file.path]);
            return YES;
        };
    }
    if (_activePath.length) _htmlBrowser.defaultDirectoryURL = [[NSURL fileURLWithPath:_activePath.stringByDeletingLastPathComponent isDirectory:YES] URLByAppendingPathComponent:@"ui" isDirectory:YES];
    [_htmlBrowser showWindow:nil];
}
- (void)cancelScript:(id)sender { (void)sender; [_scripts cancel]; }
- (BOOL)applyScriptAction:(const ScriptAction&)action error:(NSString **)error {
    const bool windowAction = action.kind == ScriptActionKind::set_full_screen ||
        action.kind == ScriptActionKind::toggle_full_screen || action.kind == ScriptActionKind::show_about;
    if (!windowAction && (!_model || _loading)) { if (error) *error = @"天文データが使用できません。"; return NO; }
    if ((action.kind == ScriptActionKind::set_camera_distance || action.kind == ScriptActionKind::animate_camera_zoom) &&
        (_mode.selectedSegment != 1 || (_solar.surfaceNavigationActive && !_solar.flightAnimating))) {
        if (error) *error = @"カメラ距離は宇宙視点でのみ変更できます。";
        return NO;
    }
    try {
        switch (action.kind) {
            case ScriptActionKind::set_satellites_visible:
            case ScriptActionKind::set_satellites_labels:
            case ScriptActionKind::set_satellites_orbits:
            case ScriptActionKind::set_satellites_selected_only: {
                auto options = [self satelliteDisplayOptions];
                if (action.kind == ScriptActionKind::set_satellites_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_satellites_labels) options.labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_satellites_orbits) options.orbits = action.enabled;
                else options.selected_only = action.enabled;
                [self setSatelliteDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_full_screen: return [self setFullScreen:action.enabled error:error];
            case ScriptActionKind::toggle_full_screen: return [self toggleFullScreenWithError:error];
            case ScriptActionKind::show_about: [self showAbout:nil]; return YES;
            case ScriptActionKind::set_antialias:
            case ScriptActionKind::set_point_smoothing:
            case ScriptActionKind::set_line_smoothing:
            case ScriptActionKind::set_text_smoothing: {
                auto options = [self rendererDisplayOptions];
                if (action.kind == ScriptActionKind::set_antialias) options.antialias = action.enabled;
                else if (action.kind == ScriptActionKind::set_point_smoothing) options.point_smoothing = action.enabled;
                else if (action.kind == ScriptActionKind::set_line_smoothing) options.line_smoothing = action.enabled;
                else options.text_smoothing = action.enabled;
                [self setRendererDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_time_step:
            case ScriptActionKind::set_time_step_value:
            case ScriptActionKind::set_time_speed:
            case ScriptActionKind::previous_time_step:
            case ScriptActionKind::next_time_step:
            case ScriptActionKind::step_time_forward:
            case ScriptActionKind::step_time_rewind:
            case ScriptActionKind::set_date:
            case ScriptActionKind::set_rate:
            case ScriptActionKind::stop:
            case ScriptActionKind::set_clock_tracking:
            case ScriptActionKind::set_time_info:
            case ScriptActionKind::set_time_animation_jd:
            case ScriptActionKind::set_time_animation_calendar:
                return [self applyScriptTimeAction:action error:error];
            case ScriptActionKind::select_target: {
                if (action.enabled && (!std::isfinite(action.duration_seconds) || action.duration_seconds < 0))
                    throw std::invalid_argument("Camera target duration must be finite and nonnegative");
                const auto initial = [_solar cameraState];
                const auto previousRadius = [_solar scriptTargetRadiusAU];
                if (action.text.compare(0, 13, "Planet.Earth.") == 0) {
                    if (!_observerPlaces) throw std::invalid_argument("Observer place catalog is unavailable");
                    const auto place = std::find_if(_observerPlaces->places.begin(), _observerPlaces->places.end(),
                        [&](const auto& candidate) { return candidate.target_name == action.text && observer_place_is_earth(candidate); });
                    if (place == _observerPlaces->places.end()) throw std::invalid_argument("Unknown Earth place: " + action.text);
                    const bool horizon = _mode.selectedSegment == 2;
                    const bool surface = _mode.selectedSegment == 1 && [_solar scriptPlanetariumMode];
                    const double latitude = place->latitude_degrees;
                    const double longitude = std::remainder(place->longitude_degrees, 360.0);
                    if ((horizon || surface) && action.enabled && action.duration_seconds > 0) {
                        SurfaceSite site;
                        if (surface && (![_solar scriptSurfaceSite:&site] || site.body_index != 3))
                            throw std::invalid_argument("Animated Earth place selection requires an Earth observer");
                        [self stopScriptPlaceTransition];
                        if (horizon) [_solar selectBody:3];
                        [_solar setScriptEarthPlaceTarget:action.text];
                        [self startScriptPlaceTransitionToLatitude:latitude longitude:longitude duration:action.duration_seconds target:action.text];
                        break;
                    }
                    [self stopScriptPlaceTransition];
                    if (horizon) {
                        [_solar selectBody:3];
                    } else if (![_solar selectScriptEarthPlaceLatitude:latitude longitude:longitude surface:surface error:error]) {
                        return NO;
                    }
                    _observerLatitude = latitude;
                    _observerLongitude = longitude;
                    [_horizon setObserverSite:{latitude, longitude}];
                    [_horizon setObserverPlaceIdentifier:action.text];
                    [_sky setObservationSite:{latitude, longitude} julianDate:_jd];
                    [_solar setObservationSite:{latitude, longitude} julianDate:_jd];
                    if (!horizon && !surface) {
                        _mode.selectedSegment = 1;
                        [self changeMode:nil];
                        [_solar applyScriptZoomMode:_scriptCameraZoomMode previousRadius:previousRadius initialDistance:initial.distance_au];
                        if (action.enabled) [_solar animateScriptPlaceTargetFrom:initial duration:action.duration_seconds];
                    }
                    [_solar setScriptEarthPlaceTarget:action.text];
                    break;
                }
                if (action.text == "Other.SolarSystem" || action.text == "Other.LSS") {
                    if (![_solar selectScriptOverviewTarget:action.text error:error]) return NO;
                    _mode.selectedSegment = 1;
                    [self changeMode:nil];
                    [_solar applyScriptZoomMode:_scriptCameraZoomMode previousRadius:previousRadius initialDistance:initial.distance_au];
                    if (action.enabled) [_solar animateScriptPlaceTargetFrom:initial duration:action.duration_seconds];
                    break;
                }
                const auto galaxyTarget = mitaka::gui::resolve_script_galaxy_alias(action.text);
                if (action.text == "Other.OurGalaxyCenter" || action.text == "Other.OurGalaxy") {
                    if (![_solar selectScriptOurGalaxyOverview:(action.text == "Other.OurGalaxy") error:error]) return NO;
                    _scriptOurGalaxyTarget = action.text;
                    _mode.selectedSegment = 1;
                    [self changeMode:nil];
                    [_solar applyScriptZoomMode:_scriptCameraZoomMode previousRadius:previousRadius initialDistance:initial.distance_au];
                    if (action.enabled) [_solar animateScriptTargetFrom:initial duration:action.duration_seconds];
                    break;
                }
                if (galaxyTarget.compare(0, 3, "GC.") == 0 || galaxyTarget.compare(0, 7, "Galaxy.") == 0) {
                    if (!_galaxyModel || _galaxyLoading) throw std::invalid_argument("Galaxy catalog is unavailable");
                    const auto id = galaxyTarget.compare(0, 3, "GC.") == 0
                        ? resolveScriptGlobularCluster(galaxyTarget, *_galaxyModel)
                        : resolveScriptNearbyGalaxy(galaxyTarget, _activePath, *_galaxyModel);
                    if (![_solar selectScriptGalaxyRecord:id error:error]) return NO;
                    _scriptGalaxyRecord = id;
                    _scriptGalaxyModel = _galaxyModel;
                    _scriptGalaxyTarget = action.text;
                    _mode.selectedSegment = 1;
                    [self changeMode:nil];
                    [_solar focusSelection];
                    [_solar applyScriptZoomMode:_scriptCameraZoomMode previousRadius:previousRadius initialDistance:initial.distance_au];
                    if (action.enabled) [_solar animateScriptTargetFrom:initial duration:action.duration_seconds];
                    break;
                }
                if (action.text.compare(0, 10, "Satellite.") == 0 && action.text != "Satellite.Moon") {
                    if (!_satelliteModel || !_satelliteSnapshot || _loading || _satelliteSnapshot->model != _satelliteModel ||
                        _satelliteSnapshot->julian_date != _jd)
                        throw std::invalid_argument("Satellite catalog is unavailable");
                    const auto selected = _solar.selectedSatelliteIndex;
                    const auto source = selected < _satelliteModel->model().records().size()
                        ? std::optional<std::string>{_satelliteModel->source(selected)} : std::nullopt;
                    const auto index = resolveScriptSatellite(action.text, *_satelliteModel, source);
                    if (index >= _satelliteSnapshot->positions.size() || !_satelliteSnapshot->positions[index])
                        throw std::invalid_argument("Satellite position is unavailable at the current time: " + action.text);
                    [_solar stopScriptTargetTransition];
                    [_solar selectSatellite:index];
                    _scriptStarHIP.reset();
                    _scriptStarTarget.clear();
                    _mode.selectedSegment = 1;
                    [self changeMode:nil];
                    [_solar focusSelection];
                    [_solar applyScriptZoomMode:_scriptCameraZoomMode previousRadius:previousRadius initialDistance:initial.distance_au];
                    if (action.enabled) [_solar animateScriptTargetFrom:initial duration:action.duration_seconds];
                    break;
                }
                if (action.text.compare(0, 11, "Spacecraft.") == 0) {
                    if (!_spacecraftModel || _loading) throw std::invalid_argument("Spacecraft catalog is unavailable");
                    const auto index = resolveScriptSpacecraft(action.text, *_spacecraftModel);
                    const auto snapshot = [self spacecraftSnapshotAtDate:_jd];
                    if (!snapshot || !spacecraft_scene_position(*snapshot, index))
                        throw std::invalid_argument("Spacecraft position is unavailable at the current time: " + action.text);
                    [self applySpacecraftSnapshot:snapshot];
                    [_solar selectSpacecraft:index];
                    _scriptSpacecraftIndex = index;
                    _scriptSpacecraftTarget = action.text;
                    _scriptStarHIP.reset();
                    _scriptStarTarget.clear();
                    _mode.selectedSegment = 1;
                    [self changeMode:nil];
                    [_solar focusSelection];
                    [_solar applyScriptZoomMode:_scriptCameraZoomMode previousRadius:previousRadius initialDistance:initial.distance_au];
                    if (action.enabled) [_solar animateScriptTargetFrom:initial duration:action.duration_seconds];
                    break;
                }
                if (action.text.compare(0, 10, "Asteroids.") == 0 || action.text.compare(0, 4, "TNO.") == 0 ||
                    action.text.compare(0, 6, "Comet.") == 0) {
                    if (!_smallBodyModel || _loading) throw std::invalid_argument("Small-body catalog is unavailable");
                    const auto index = resolveScriptSmallBody(action.text, *_smallBodyModel);
                    const auto snapshot = evaluate_small_body_snapshot(_smallBodyModel, _jd, false, *index);
                    if (*index >= snapshot->positions.size() || !snapshot->positions[*index])
                        throw std::invalid_argument("Small-body position is unavailable at the current time: " + action.text);
                    [self applySmallBodySnapshot:snapshot];
                    [_solar selectSmallBody:*index];
                    _scriptSmallBodyIndex = *index;
                    _scriptSmallBodyTarget = action.text;
                    _scriptStarHIP.reset();
                    _scriptStarTarget.clear();
                    _mode.selectedSegment = 1;
                    [self changeMode:nil];
                    [_solar focusSelection];
                    [_solar applyScriptZoomMode:_scriptCameraZoomMode previousRadius:previousRadius initialDistance:initial.distance_au];
                    if (action.enabled) [_solar animateScriptTargetFrom:initial duration:action.duration_seconds];
                    break;
                }
                if (action.text.compare(0, 5, "Star.") == 0) {
                    const auto target = resolveScriptStarTarget(action.text, _activePath);
                    if (![_solar selectScriptStarTarget:target error:error]) return NO;
                    _scriptStarHIP = [_solar selectedScriptStarHIP];
                    _scriptStarTarget = action.text;
                    _mode.selectedSegment = 1;
                    [self changeMode:nil];
                    [_solar focusSelection];
                    [_solar applyScriptZoomMode:_scriptCameraZoomMode previousRadius:previousRadius initialDistance:initial.distance_au];
                    if (action.enabled) [_solar animateScriptTargetFrom:initial duration:action.duration_seconds];
                    break;
                }
                const auto found = std::find(scriptBodyNames.begin(), scriptBodyNames.end(), action.text);
                if (found == scriptBodyNames.end()) throw std::invalid_argument("Unsupported Camera.target: " + action.text);
                [_solar selectBody:static_cast<NSUInteger>(found - scriptBodyNames.begin())];
                _scriptStarHIP.reset();
                _scriptStarTarget.clear();
                _mode.selectedSegment = 1;
                [self changeMode:nil];
                [_solar focusSelection];
                [_solar applyScriptZoomMode:_scriptCameraZoomMode previousRadius:previousRadius initialDistance:initial.distance_au];
                if (action.enabled) [_solar animateScriptTargetFrom:initial duration:action.duration_seconds];
                break;
            }
            case ScriptActionKind::look_target: {
                if (!std::isfinite(action.duration_seconds) || action.duration_seconds < 0)
                    throw std::invalid_argument("Invalid Camera look duration");
                std::optional<ScriptLookTarget> look;
                HorizonViewport target;
                const auto galaxyTarget = mitaka::gui::resolve_script_galaxy_alias(action.text);
                if (action.text == "Other.OurGalaxyCenter" || action.text == "Other.OurGalaxy") {
                    look = ScriptLookTarget{ScriptLookTarget::Kind::our_galaxy, 0};
                } else if (galaxyTarget.compare(0, 3, "GC.") == 0 || galaxyTarget.compare(0, 7, "Galaxy.") == 0) {
                    if (!_galaxyModel || _galaxyLoading) throw std::invalid_argument("Galaxy catalog is unavailable");
                    const auto id = galaxyTarget.compare(0, 3, "GC.") == 0
                        ? resolveScriptGlobularCluster(galaxyTarget, *_galaxyModel)
                        : resolveScriptNearbyGalaxy(galaxyTarget, _activePath, *_galaxyModel);
                    look = ScriptLookTarget{ScriptLookTarget::Kind::galaxy, _galaxyModel->row_index(id), {}, _galaxyModel};
                } else if (action.text.compare(0, 5, "Star.") == 0) {
                    const auto starTarget = resolveScriptStarTarget(action.text, _activePath);
                    std::int32_t hip = 0;
                    const char *first = starTarget.data() + 5, *last = starTarget.data() + starTarget.size();
                    const auto parsed = std::from_chars(first, last, hip);
                    if (parsed.ec != std::errc{} || parsed.ptr != last || hip <= 0)
                        throw std::invalid_argument("Invalid star HIP: " + starTarget);
                    look = ScriptLookTarget{ScriptLookTarget::Kind::star, static_cast<std::size_t>(hip)};
                } else if (action.text.compare(0, 10, "Asteroids.") == 0 || action.text.compare(0, 4, "TNO.") == 0 ||
                           action.text.compare(0, 6, "Comet.") == 0) {
                    if (!_smallBodyModel || _loading) throw std::invalid_argument("Small-body catalog is unavailable");
                    look = ScriptLookTarget{ScriptLookTarget::Kind::small_body, *resolveScriptSmallBody(action.text, *_smallBodyModel)};
                } else if (action.text.compare(0, 11, "Spacecraft.") == 0) {
                    if (!_spacecraftModel || _loading) throw std::invalid_argument("Spacecraft catalog is unavailable");
                    look = ScriptLookTarget{ScriptLookTarget::Kind::spacecraft, resolveScriptSpacecraft(action.text, *_spacecraftModel)};
                } else if (action.text.compare(0, 10, "Satellite.") == 0 && action.text != "Satellite.Moon") {
                    if (!_satelliteModel || !_satelliteSnapshot || _loading) throw std::invalid_argument("Satellite catalog is unavailable");
                    const auto selected = _solar.selectedSatelliteIndex;
                    const auto source = selected < _satelliteModel->model().records().size()
                        ? std::optional<std::string>{_satelliteModel->source(selected)} : std::nullopt;
                    look = ScriptLookTarget{ScriptLookTarget::Kind::satellite, resolveScriptSatellite(action.text, *_satelliteModel, source)};
                } else if (action.text.compare(0, 8, "Constel.") == 0) {
                    if (!_model || _loading) throw std::invalid_argument("Constellation catalog is unavailable");
                    look = ScriptLookTarget{ScriptLookTarget::Kind::constellation, resolveScriptConstellation(action.text, *_model), _model};
                } else {
                    const auto body = std::find(scriptBodyNames.begin(), scriptBodyNames.end(), action.text);
                    if (body != scriptBodyNames.end())
                        look = ScriptLookTarget{ScriptLookTarget::Kind::body, static_cast<std::size_t>(body - scriptBodyNames.begin())};
                }
                if (!look || ![self scriptLookViewport:*look result:&target])
                    throw std::invalid_argument("Unsupported or unavailable Camera:look target: " + action.text);
                if (_mode.selectedSegment == 1 && [_solar scriptPlanetariumMode]) [_solar stopScriptOrientation];
                if (_scriptAzimuthAnimation || _scriptAltitudeAnimation || _horizonOrientationAnimation) [self updateScriptCameraAnimations];
                const auto start = [self scriptCameraViewport];
                target.roll_deg = start.roll_deg;
                [self stopScriptCameraAnimation];
                if (_mode.selectedSegment != 1 || ![_solar scriptPlanetariumMode]) {
                    _mode.selectedSegment = 2;
                    [self changeMode:nil];
                }
                if (!action.enabled || action.duration_seconds == 0) {
                    [self setScriptCameraViewport:target];
                    if (action.enabled) {
                        _scriptLookTarget = *look;
                        [self startScriptCameraTimer];
                    }
                } else {
                    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
                    const double startAzimuth = std::remainder(start.center_azimuth_deg, 360.0);
                    _scriptAzimuthAnimation = ScriptCameraAnimation{startAzimuth,
                        startAzimuth + std::remainder(target.center_azimuth_deg - startAzimuth, 360.0), now, action.duration_seconds, true};
                    _scriptAltitudeAnimation = ScriptCameraAnimation{start.center_altitude_deg,
                        target.center_altitude_deg, now, action.duration_seconds, true};
                    _scriptLookTarget = *look;
                    [self startScriptCameraTimer];
                }
                break;
            }
            case ScriptActionKind::animate_camera_zoom:
                return [_solar animateScriptZoomTo:action.number duration:action.duration_seconds logarithmic:action.enabled error:error];
            case ScriptActionKind::set_camera_distance:
                return [_solar animateScriptZoomTo:action.number duration:0 logarithmic:NO error:error];
            case ScriptActionKind::set_camera_fov:
                return [self animateScriptFovTo:action.number duration:0 error:error];
            case ScriptActionKind::animate_camera_fov:
                return [self animateScriptFovTo:action.number duration:action.duration_seconds error:error];
            case ScriptActionKind::set_constellation_lines:
            case ScriptActionKind::set_constellation_boundaries:
            case ScriptActionKind::set_constellation_illustrations:
            case ScriptActionKind::set_constellation_labels: {
                auto options = [self constellationDisplayOptions];
                if (action.kind == ScriptActionKind::set_constellation_lines) options.lines = action.enabled;
                else if (action.kind == ScriptActionKind::set_constellation_boundaries) options.boundaries = action.enabled;
                else if (action.kind == ScriptActionKind::set_constellation_illustrations) options.illustrations = action.enabled;
                else options.labels = action.enabled;
                [self setConstellationDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_star_labels:
            case ScriptActionKind::set_stars_visible:
            case ScriptActionKind::set_bayer_labels:
            case ScriptActionKind::set_flamsteed_labels:
            case ScriptActionKind::set_selected_star_labels:
            case ScriptActionKind::set_hip_labels: {
                auto options = [self starDisplayOptions];
                if (action.kind == ScriptActionKind::set_star_labels) options.proper_names = action.enabled;
                else if (action.kind == ScriptActionKind::set_stars_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_bayer_labels) options.bayer_labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_flamsteed_labels) options.flamsteed_labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_selected_star_labels) options.selected_proper_names_only = action.enabled;
                else options.hip_labels = action.enabled;
                [self setStarDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_star_name_membership: {
                if (!_starNameSelection) throw std::invalid_argument("star name catalog is not loaded");
                std::vector<std::int32_t> known;
                for (const auto hip : action.hips)
                    if (_starNameSelection->known_hips().count(hip)) known.push_back(hip);
                [self setStarNameMembership:known selected:action.enabled];
                break;
            }
            case ScriptActionKind::set_all_star_names_selected:
                [self setAllStarNamesSelected:action.enabled];
                break;
            case ScriptActionKind::set_star_brightness:
                [self setStarBrightness:action.number cancelTransition:YES];
                break;
            case ScriptActionKind::brighten_stars:
                [self setStarBrightness:brighter_star_brightness([self starDisplayOptions].brightness) cancelTransition:NO];
                break;
            case ScriptActionKind::darken_stars:
                [self setStarBrightness:darker_star_brightness([self starDisplayOptions].brightness) cancelTransition:NO];
                break;
            case ScriptActionKind::default_star_brightness:
                [self setStarBrightness:1 cancelTransition:NO];
                break;
            case ScriptActionKind::animate_star_brightness:
                return [self animateStarBrightness:action.number duration:action.duration_seconds error:error];
            case ScriptActionKind::set_star_marking: {
                auto options = [self starDisplayOptions];
                if (action.text == "None") options.marking = StarMarking::none;
                else if (action.text == "Binary") options.marking = StarMarking::binary;
                else if (action.text == "ExoPlanets") options.marking = StarMarking::exoplanets;
                else throw std::invalid_argument("Unsupported Stars.markingType: " + action.text);
                [self setStarDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_shadows:
            case ScriptActionKind::set_shadow_borders:
            case ScriptActionKind::set_shadow_umbra:
            case ScriptActionKind::set_shadow_penumbra: {
                auto options = [self eclipseDisplayOptions];
                if (action.kind == ScriptActionKind::set_shadows) options.shadows = action.enabled;
                else if (action.kind == ScriptActionKind::set_shadow_borders) options.shadow_borders = action.enabled;
                else if (action.kind == ScriptActionKind::set_shadow_umbra) options.shadow_umbra = action.enabled;
                else options.shadow_penumbra = action.enabled;
                [self setEclipseDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_landscape:
                _horizon.showsLandscapeImage = action.enabled;
                [NSApp.mainMenu update];
                break;
            case ScriptActionKind::set_terrain_amplification:
                [self setTerrainAmplification:action.terrain_amplification];
                break;
            case ScriptActionKind::set_radius_scale:
            case ScriptActionKind::set_radius_scale_mode: {
                RadiusDisplayOptions options;
                RadiusScaleMode mode;
                if (![self readRadiusDisplayOptions:&options mode:&mode error:error]) return NO;
                if (action.kind == ScriptActionKind::set_radius_scale) options = action.radius_display;
                else mode = action.radius_scale_mode;
                return [self applyRadiusDisplayOptions:options mode:mode error:error];
            }
            case ScriptActionKind::set_earth_clouds:
            case ScriptActionKind::set_earth_city_lights: {
                auto options = [self earthLayerOptions];
                if (action.kind == ScriptActionKind::set_earth_clouds) options.clouds = action.enabled;
                else options.city_lights = action.enabled;
                [self setEarthLayerOptions:options];
                break;
            }
            case ScriptActionKind::set_atmosphere_mode: {
                auto options = [self atmosphereDisplayOptions];
                if (action.number == 0) options.mode = AtmosphereMode::none;
                else if (action.number == 1) options.mode = AtmosphereMode::single;
                else if (action.number == 2) options.mode = AtmosphereMode::multiple;
                else throw std::invalid_argument("Unsupported Planets.atmosphere mode");
                [self setAtmosphereDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_planets_visible:
            case ScriptActionKind::set_planet_labels:
            case ScriptActionKind::set_planet_orbits:
            case ScriptActionKind::set_planet_axes: {
                auto options = [self planetDisplayOptions];
                if (action.kind == ScriptActionKind::set_planets_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_planet_labels) options.labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_planet_orbits) options.orbits = action.enabled;
                else options.axes = action.enabled;
                [self setPlanetDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_asteroids_visible:
            case ScriptActionKind::set_asteroids_labels:
            case ScriptActionKind::set_asteroids_orbits:
            case ScriptActionKind::set_asteroids_selected_only:
            {
                auto options = [self smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::asteroid];
                if (action.kind == ScriptActionKind::set_asteroids_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_asteroids_labels) options.labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_asteroids_orbits) options.orbits = action.enabled;
                else options.selected_only = action.enabled;
                [self setSmallBodyDisplayOptions:options forKind:mitaka::SmallBodyKind::asteroid];
                break;
            }
            case ScriptActionKind::set_tnobjects_visible:
            case ScriptActionKind::set_tnobjects_labels:
            case ScriptActionKind::set_tnobjects_orbits:
            case ScriptActionKind::set_tnobjects_selected_only:
            {
                auto options = [self smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::trans_neptunian];
                if (action.kind == ScriptActionKind::set_tnobjects_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_tnobjects_labels) options.labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_tnobjects_orbits) options.orbits = action.enabled;
                else options.selected_only = action.enabled;
                [self setSmallBodyDisplayOptions:options forKind:mitaka::SmallBodyKind::trans_neptunian];
                break;
            }
            case ScriptActionKind::set_comets_visible:
            case ScriptActionKind::set_comets_labels:
            case ScriptActionKind::set_comets_orbits:
            case ScriptActionKind::set_comets_selected_only:
            {
                auto options = [self smallBodyDisplayOptionsForKind:mitaka::SmallBodyKind::comet];
                if (action.kind == ScriptActionKind::set_comets_visible) options.visible = action.enabled;
                else if (action.kind == ScriptActionKind::set_comets_labels) options.labels = action.enabled;
                else if (action.kind == ScriptActionKind::set_comets_orbits) options.orbits = action.enabled;
                else options.selected_only = action.enabled;
                [self setSmallBodyDisplayOptions:options forKind:mitaka::SmallBodyKind::comet];
                break;
            }
            case ScriptActionKind::set_equatorial_grid:
            case ScriptActionKind::set_ecliptic_grid:
            case ScriptActionKind::set_galactic_grid:
            case ScriptActionKind::set_horizontal_grid:
            case ScriptActionKind::set_circle_scales:
            case ScriptActionKind::set_square_scales: {
                auto options = [self gridDisplayOptions];
                if (action.kind == ScriptActionKind::set_equatorial_grid) options.equatorial = action.enabled;
                else if (action.kind == ScriptActionKind::set_ecliptic_grid) options.ecliptic = action.enabled;
                else if (action.kind == ScriptActionKind::set_galactic_grid) options.galactic = action.enabled;
                else if (action.kind == ScriptActionKind::set_horizontal_grid) options.horizontal = action.enabled;
                else if (action.kind == ScriptActionKind::set_circle_scales) options.circle_scales = action.enabled;
                else options.square_scales = action.enabled;
                [self setGridDisplayOptions:options];
                break;
            }
            case ScriptActionKind::set_milky_way_type:
                if (action.text == "None") [self setMilkyWayMode:MilkyWayMode::none];
                else if (action.text == "Normal") [self setMilkyWayMode:MilkyWayMode::normal];
                else if (action.text == "Bright") [self setMilkyWayMode:MilkyWayMode::bright];
                else if (action.text == "Infrared") [self setMilkyWayMode:MilkyWayMode::infrared];
                else throw std::invalid_argument("Unsupported Milkyway.type: " + action.text);
                break;
            case ScriptActionKind::set_nebulae: _sky.showsNebulae = action.enabled; break;
            case ScriptActionKind::set_distant_galaxies: _sky.showsGalaxies = action.enabled; break;
            case ScriptActionKind::set_quasars: _sky.showsQuasars = action.enabled; break;
            case ScriptActionKind::set_camera_zoom_mode:
                _scriptCameraZoomMode = static_cast<int>(action.number);
                break;
            case ScriptActionKind::set_camera_duration:
                if (!std::isfinite(action.number) || action.number < 0)
                    throw std::invalid_argument("Camera.duration must be nonnegative and finite");
                _scriptCameraDuration = action.number;
                break;
            case ScriptActionKind::set_camera_mode_duration:
                if (!std::isfinite(action.number) || action.number < 0)
                    throw std::invalid_argument("Camera.modeDuration must be nonnegative and finite");
                _scriptCameraModeDuration = action.number;
                break;
            case ScriptActionKind::set_camera_mode:
                if ((action.number != 0 && action.number != 1) || !std::isfinite(action.duration_seconds) ||
                    action.duration_seconds < 0 || (action.enabled && action.duration_seconds != 0))
                    throw std::invalid_argument("Invalid Camera mode or duration");
                if (_scriptAzimuthAnimation || _scriptAltitudeAnimation || _horizonOrientationAnimation) [self updateScriptCameraAnimations];
                if (![self setEarthSurfaceMode:action.number == 0 duration:action.duration_seconds force:action.enabled error:error]) return NO;
                [self stopScriptCameraAnimation];
                break;
            case ScriptActionKind::set_camera_orientation:
            case ScriptActionKind::animate_camera_orientation:
            case ScriptActionKind::set_camera_euler:
            case ScriptActionKind::add_camera_euler:
            case ScriptActionKind::animate_camera_euler:
            case ScriptActionKind::animate_add_camera_euler: {
                if (_mode.selectedSegment == 2 && _model) {
                    if (!std::isfinite(action.duration_seconds) || action.duration_seconds < 0)
                        throw std::invalid_argument("Invalid camera orientation duration");
                    const bool quaternion = action.kind == ScriptActionKind::set_camera_orientation || action.kind == ScriptActionKind::animate_camera_orientation;
                    const bool relative = action.kind == ScriptActionKind::add_camera_euler || action.kind == ScriptActionKind::animate_add_camera_euler;
                    if (_scriptAzimuthAnimation || _scriptAltitudeAnimation || _horizonOrientationAnimation) [self updateScriptCameraAnimations];
                    const auto initial = horizonOrientation([_horizon viewport], _horizon.observerSite, _solarBodies);
                    const PlusOrientationEuler euler{action.orientation[0], action.orientation[1], action.orientation[2]};
                    auto target = quaternion ? plus_orientation_normalized({action.orientation[0], action.orientation[1], action.orientation[2], action.orientation[3]})
                                             : plus_orientation_from_euler(euler.heading, euler.pitch, euler.roll);
                    if (relative) target = plus_orientation_normalized(plus_orientation_multiply(initial, target));
                    [self stopScriptCameraAnimation];
                    if (action.duration_seconds == 0) {
                        [_horizon setViewport:horizonWithOrientation([_horizon viewport], _horizon.observerSite, _solarBodies, target)];
                    } else {
                        const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
                        _horizonOrientationAnimation = HorizonOrientationAnimation{initial, target,
                            relative ? PlusOrientationEuler{} : plus_orientation_to_euler(initial), euler,
                            now, action.duration_seconds, bool(action.enabled), quaternion, relative};
                        [self startScriptCameraTimer];
                    }
                    break;
                }
                if (_mode.selectedSegment != 1 || ![_solar scriptCameraOrientationAvailable])
                    throw std::invalid_argument("Camera orientation is unavailable in this view");
                const bool quaternion = action.kind == ScriptActionKind::set_camera_orientation || action.kind == ScriptActionKind::animate_camera_orientation;
                if (quaternion) {
                    if (![_solar scriptSetCameraOrientation:{action.orientation[0], action.orientation[1], action.orientation[2], action.orientation[3]}
                        duration:action.duration_seconds smooth:action.enabled error:error]) return NO;
                } else {
                    const bool relative = action.kind == ScriptActionKind::add_camera_euler || action.kind == ScriptActionKind::animate_add_camera_euler;
                    if (![_solar scriptSetCameraEuler:{action.orientation[0], action.orientation[1], action.orientation[2]}
                        relative:relative duration:action.duration_seconds smooth:action.enabled error:error]) return NO;
                }
                [self stopScriptCameraAnimation];
                break;
            }
            case ScriptActionKind::animate_camera_azimuth:
            case ScriptActionKind::animate_camera_altitude: {
                if (!std::isfinite(action.number) || !std::isfinite(action.duration_seconds) || action.duration_seconds < 0)
                    throw std::invalid_argument("Invalid Camera animation parameters");
                const bool azimuth = action.kind == ScriptActionKind::animate_camera_azimuth;
                if (!azimuth && (action.number < -90 || action.number > 90))
                    throw std::invalid_argument("Camera.altitude must be between -90 and 90 degrees");
                if (_mode.selectedSegment == 1 && [_solar scriptPlanetariumMode]) [_solar stopScriptOrientation];
                if (_horizonOrientationAnimation) {
                    [self updateScriptCameraAnimations];
                    [self stopScriptCameraAnimation];
                }
                _scriptLookTarget.reset();
                auto viewport = [self scriptCameraViewport];
                double start = azimuth ? viewport.center_azimuth_deg : viewport.center_altitude_deg;
                if (azimuth && start > 180) start -= 360;
                auto& animation = azimuth ? _scriptAzimuthAnimation : _scriptAltitudeAnimation;
                if (action.duration_seconds == 0) {
                    animation.reset();
                    if (azimuth) viewport.center_azimuth_deg = action.number;
                    else viewport.center_altitude_deg = action.number;
                    [self setScriptCameraViewport:viewport];
                } else {
                    const double now = std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
                    animation = ScriptCameraAnimation{start, action.number, now, action.duration_seconds, action.enabled};
                    [self startScriptCameraTimer];
                }
                if (_mode.selectedSegment != 1 || ![_solar scriptPlanetariumMode]) {
                    _mode.selectedSegment = 2;
                    [self changeMode:nil];
                }
                break;
            }
            case ScriptActionKind::set_camera_azimuth: {
                if (!std::isfinite(action.number)) throw std::invalid_argument("Camera.azimuth must be finite");
                if (_mode.selectedSegment == 1 && [_solar scriptPlanetariumMode]) [_solar stopScriptOrientation];
                if (_horizonOrientationAnimation) {
                    [self updateScriptCameraAnimations];
                    [self stopScriptCameraAnimation];
                }
                _scriptLookTarget.reset();
                _scriptAzimuthAnimation.reset();
                auto viewport = [self scriptCameraViewport];
                viewport.center_azimuth_deg = std::remainder(action.number, 360.0);
                [self setScriptCameraViewport:viewport];
                if (_mode.selectedSegment != 1 || ![_solar scriptPlanetariumMode]) {
                    _mode.selectedSegment = 2;
                    [self changeMode:nil];
                }
                break;
            }
            case ScriptActionKind::set_camera_altitude: {
                if (!std::isfinite(action.number)) throw std::invalid_argument("Camera.altitude must be finite");
                if (action.number < -90.0 || action.number > 90.0)
                    throw std::invalid_argument("Camera.altitude must be between -90 and 90 degrees");
                if (_mode.selectedSegment == 1 && [_solar scriptPlanetariumMode]) [_solar stopScriptOrientation];
                if (_horizonOrientationAnimation) {
                    [self updateScriptCameraAnimations];
                    [self stopScriptCameraAnimation];
                }
                _scriptLookTarget.reset();
                _scriptAltitudeAnimation.reset();
                auto viewport = [self scriptCameraViewport];
                viewport.center_altitude_deg = action.number;
                [self setScriptCameraViewport:viewport];
                if (_mode.selectedSegment != 1 || ![_solar scriptPlanetariumMode]) {
                    _mode.selectedSegment = 2;
                    [self changeMode:nil];
                }
                break;
            }
            case ScriptActionKind::set_target_browser:
                if (action.enabled) [self showBrowser:nil]; else [_browser.window orderOut:nil];
                break;
            case ScriptActionKind::set_time_setting:
                if (action.enabled) [self showCalendar:nil]; else [_calendarWindow orderOut:nil];
                break;
            case ScriptActionKind::set_place_setting:
                if (action.enabled) [self showObserver:nil]; else [_observerWindow orderOut:nil];
                break;
            case ScriptActionKind::set_script_output:
                if (action.enabled) [self showScriptConsole:nil]; else [_scriptWindow orderOut:nil];
                break;
            case ScriptActionKind::set_dual_screen:
                if (action.enabled) [[self displayOutput] showProjection]; else [_displayOutput closeProjection];
                break;
            case ScriptActionKind::save_image_dialog:
                return [self beginImageSaveDialog:DisplayImageFormatPNG error:error];
        }
        return YES;
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
}
@end
