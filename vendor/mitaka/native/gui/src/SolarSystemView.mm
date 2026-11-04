#import "RendererQuality.h"
#import "SolarSystemViewInternal.h"
#import "SkyView.h"
#import "SolarSceneRenderer.h"
#import "SmallBodyRenderer.h"
#import "SatelliteRenderer.h"
#include <algorithm>
#include <cmath>
#include <exception>

using namespace mitaka;
using namespace mitaka::gui;

static NSDictionary<NSAttributedStringKey, id> *textStyle(NSColor *color, CGFloat size) {
    return @{ NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:size weight:NSFontWeightRegular],
              NSForegroundColorAttributeName: color };
}

using CameraChange = void (^)(SolarCamera&);

@implementation SolarSystemView

- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _smallBodiesVisible = YES;
        _spacecraftVisible = YES;
        _showsTimeInfo = YES;
        _julianDate = 2451545.0;
        _notifiedOverviewVisible = YES;
        self.accessibilityElement = YES;
        self.accessibilityRole = NSAccessibilityImageRole;
        self.accessibilityLabel = @"太陽系の3D表示。ドラッグで回転、Shiftドラッグで移動、スクロールで拡大縮小。";
    }
    return self;
}
- (RendererDisplayOptions)rendererDisplayOptions { return _rendererDisplayOptions; }
- (void)setRendererDisplayOptions:(RendererDisplayOptions)options {
    _rendererDisplayOptions = options;
    self.needsDisplay = YES;
}
- (PlanetDisplayOptions)planetDisplayOptions { return _planetDisplayOptions; }
- (void)setPlanetDisplayOptions:(PlanetDisplayOptions)options {
    _planetDisplayOptions = options;
    self.needsDisplay = YES;
}
- (GridDisplayOptions)gridDisplayOptions { return _gridDisplayOptions; }
- (EarthLayerOptions)earthLayerOptions { return _earthLayerOptions; }
- (void)setEarthLayerOptions:(EarthLayerOptions)options {
    _earthLayerOptions = options;
    self.needsDisplay = YES;
}
- (AtmosphereDisplayOptions)atmosphereDisplayOptions { return _atmosphereDisplayOptions; }
- (EclipseDisplayOptions)eclipseDisplayOptions { return _eclipseDisplayOptions; }
- (void)setEclipseDisplayOptions:(EclipseDisplayOptions)options {
    _eclipseDisplayOptions = options;
    self.needsDisplay = YES;
}
- (void)setAtmosphereDisplayOptions:(AtmosphereDisplayOptions)options {
    validate_atmosphere_display(options);
    _atmosphereDisplayOptions = options;
    self.needsDisplay = YES;
}
- (void)setGridDisplayOptions:(GridDisplayOptions)options {
    _gridDisplayOptions = options;
    self.needsDisplay = YES;
}
- (void)setObservationSite:(ObserverSite)site julianDate:(double)julianDate {
    _gridCache.set_observation(site, julianDate);
    _julianDate = julianDate;
    self.needsDisplay = YES;
}
- (void)dealloc { [_flightTimer invalidate]; }
- (BOOL)surfaceNavigationActive { return _surfaceActive; }
- (BOOL)journeyActive { return _journeyActive; }
- (BOOL)flightAnimating { return _navigation.flying() || (_journeyActive && _journey.flying()); }
- (BOOL)showsTimeInfo { return _showsTimeInfo; }
- (void)setShowsTimeInfo:(BOOL)visible { _showsTimeInfo = visible; self.needsDisplay = YES; }
- (NSUInteger)selectedBodyIndex { return _selection ? *_selection : NSNotFound; }
- (BOOL)isFlipped { return YES; }
- (BOOL)isOpaque { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (NSRect)mapRect { return NSInsetRect(self.bounds, 18, 40); }
- (Vec3)displayPosition:(NSUInteger)index {
    return j2000_equatorial_to_ecliptic(_bodies[index].position_au);
}
- (void)setTextures:(std::shared_ptr<const PlanetTextures>)textures {
    _textures = std::move(textures);
    [self notifySelection];
    self.needsDisplay = YES;
}
- (SolarScene)scene {
    return {_bodies, _orbits, _lunarOrbit, _camera, _textures.get(), _selection,
        [self mapRect], self.window ? self.window.backingScaleFactor : 1, static_cast<bool>(_earthMoonMode), _surfacePreview ? _selection : std::nullopt,
        _surfaceActive ? std::optional<std::size_t>(_navigation.site().body_index) : std::nullopt,
        static_cast<bool>(_journeyActive || _surfaceActive),
        [self smallBodiesSceneVisible] ? _smallBodySnapshot.get() : nullptr,
        !_selection ? _smallBodySelection : std::nullopt, _planetDisplayOptions, _gridDisplayOptions, &_gridCache, _rendererDisplayOptions,
        [self satellitesSceneVisible] ? _satelliteSnapshot.get() : nullptr,
        !_selection ? _satelliteSelection : std::nullopt,
        [self spacecraftSceneVisible] ? _spacecraftSnapshot.get() : nullptr,
        !_selection ? _spacecraftSelection : std::nullopt, _spacecraftDisplayOptions,
        _smallBodyDisplay.get(), _smallBodyOrbits.get(), _satelliteDisplay.get(), _satelliteOrbits.get(),
        _earthLayerOptions, _atmosphereDisplayOptions, _eclipseDisplayOptions, _julianDate,
        _satelliteSnapshot.get()};
}
- (CGFloat)radiusForBody:(NSUInteger)index depth:(double)depth {
    return solar_scene_radius([self scene], index, depth);
}
- (void)setLunarOrbit:(const std::vector<Vec3>&)orbit { _lunarOrbit = orbit; self.needsDisplay = YES; }
- (void)keepCameraOutsideBodies:(SolarCamera&)next {
    if (!_earthMoonMode) return;
    const auto basis = solar_camera_basis(next);
    for (const std::size_t index : {std::size_t(3), std::size_t(10)}) {
        const Vec3 center = [self displayPosition:index];
        const Vec3 offset{next.target.x-center.x, next.target.y-center.y, next.target.z-center.z};
        const double radius = (surface_body_info(index).radius_km + minimum_surface_height_km) / astronomical_unit_km;
        const Vec3 eye{offset.x + basis.outward.x*next.distance_au,
            offset.y + basis.outward.y*next.distance_au, offset.z + basis.outward.z*next.distance_au};
        if (std::hypot(eye.x, eye.y, eye.z) <= radius) {
            const double along = offset.x*basis.outward.x + offset.y*basis.outward.y + offset.z*basis.outward.z;
            const double squared = offset.x*offset.x + offset.y*offset.y + offset.z*offset.z;
            next.distance_au = -along + std::sqrt(std::max(0.0, along*along - squared + radius*radius)) + 1e-10;
        }
    }
}
- (void)updateTrackedCamera {
    if (_journeyActive) {
        if (_journey.flying()) [self updateJourneyAtTime:_lastFlightTime];
    } else if (_surfaceActive) _camera = _navigation.camera(_bodies);
    else if (_earthMoonMode && _earthMoonFollowing) {
        const Vec3 earth = [self displayPosition:3], moon = [self displayPosition:10];
        _camera.target = {(earth.x + moon.x) / 2, (earth.y + moon.y) / 2, (earth.z + moon.z) / 2};
    } else if (_following && _selection) _camera.target = [self displayPosition:*_selection];
    else if (_following && _smallBodySelection && _smallBodySnapshot) {
        const auto& position = _smallBodySnapshot->positions[*_smallBodySelection];
        if (position) _camera.target = *position;
        else _following = NO;
    }
    else if (_following && _satelliteSelection && _satelliteSnapshot) {
        const auto& position = _satelliteSnapshot->positions[*_satelliteSelection];
        if (position) _camera.target = *position;
        else _following = NO;
    }
    else if (_following && _spacecraftSelection && _spacecraftSnapshot) {
        const auto position = spacecraft_scene_position(*_spacecraftSnapshot, *_spacecraftSelection);
        if (position) _camera.target = *position;
        else _following = NO;
    }
    [self keepCameraOutsideBodies:_camera];
}
- (void)setBodies:(const SolarBodies&)bodies orbits:(const SolarOrbits&)orbits {
    _orbits = orbits;
    [self setBodies:bodies];
}

- (void)setBodies:(const SolarBodies&)bodies {
    _bodies = bodies;
    _hasData = YES;
    try { [self updateTrackedCamera]; }
    catch (const std::exception& error) { [self interruptFlight]; [self reportNavigationError:error.what()]; }
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (void)selectBody:(NSUInteger)index {
    if (!_hasData || index >= _bodies.size()) return;
    _selection = index;
    _smallBodySelection.reset();
    _satelliteSelection.reset();
    _spacecraftSelection.reset();
    if (_following && !_surfaceActive && !_earthMoonMode) _camera.target = [self displayPosition:index];
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
}
- (void)notifySelection {
    const auto satelliteSelection = !_selection ? _satelliteSelection : std::nullopt;
    if (_notifiedSatelliteSelection != satelliteSelection) {
        // 親位置更新の setBodies: から再入しても、同じ変更を重複通知しない。
        _notifiedSatelliteSelection = satelliteSelection;
        if (self.satelliteSelectionChanged)
            self.satelliteSelectionChanged(satelliteSelection ? *satelliteSelection : NSNotFound);
    }
    NSString *description = @"天体をクリックして選択します。\n「選択を中心」で視点の中心に移動します。";
    if (_hasData && _selection) {
        const auto& body = _bodies[*_selection];
        const Vec3 p = [self displayPosition:*_selection];
        NSString *surface = _textures && _textures->images[*_selection] ? @"表面画像あり" : @"表面画像なし（色で表示）";
        description = [NSString stringWithFormat:@"%@\n太陽から %.5f AU\n黄道 X %+.5f AU\n黄道 Y %+.5f AU\n黄道 Z %+.5f AU\n%@", bodyName(body.id),
            std::hypot(p.x, p.y, p.z), p.x, p.y, p.z, surface];
    } else if (_smallBodySelection) description = [self smallBodySelectionDescription];
    else if (_satelliteSelection) description = [self satelliteSelectionDescription];
    else if (_spacecraftSelection) description = [self spacecraftSelectionDescription];
    if (self.selectionChanged) self.selectionChanged(description);
    if (self.navigationChanged) self.navigationChanged();
}
- (NSString *)cameraStateDescription {
    if (_journeyActive) {
        NSString *phase = @"停止中";
        switch (_journey.phase()) {
            case FlightPhase::ascent: phase = @"離陸中"; break;
            case FlightPhase::cruise: phase = @"航行中"; break;
            case FlightPhase::descent: phase = @"着陸中"; break;
            default: break;
        }
        const auto& site = _journey.destination();
        return [NSString stringWithFormat:@"%@へ %@ · %.0f%% · 着陸地点 %+.2f° / %+.2f°%@",
            bodyName(_bodies[site.body_index].id), phase, 100*_journey.progress(), site.latitude_deg, site.longitude_deg,
            _flightNotice.length ? [@" · " stringByAppendingString:_flightNotice] : @""];
    }
    if (_surfaceActive) {
        const auto& site = _navigation.site();
        const BOOL reference = surface_body_info(site.body_index).gas_reference_surface;
        return [NSString stringWithFormat:@"%@ %@ · 緯度 %+.2f° / 経度 %+.2f° · 高度 %.3f km · 方位 %.1f° / 仰角 %.1f°%@",
            bodyName(_bodies[site.body_index].id), reference ? @"基準球面" : @"地表視点",
            site.latitude_deg, site.longitude_deg, site.height_km, site.heading_deg, site.elevation_deg,
            _flightNotice.length ? [@" · " stringByAppendingString:_flightNotice] : @""];
    }
    if (_earthMoonMode) {
        const Vec3 earth = [self displayPosition:3], moon = [self displayPosition:10];
        return [NSString stringWithFormat:@"地球–月 距離 %.0f km · 視点距離 %.0f km%@",
            std::hypot(moon.x-earth.x, moon.y-earth.y, moon.z-earth.z) * astronomical_unit_km,
            _camera.distance_au * astronomical_unit_km, _earthMoonFollowing ? @" · 地球と月を追従" : @""];
    }
    return [NSString stringWithFormat:@"視点距離 %.3f AU  ·  方位 %.1f° / 仰角 %.1f°%@", _camera.distance_au,
        _camera.yaw_deg, _camera.pitch_deg, _following ? @"  ·  選択天体を追従" : @""];
}
- (void)notifyCamera {
    const BOOL overviewVisible = !_earthMoonMode && !_surfacePreview && !_surfaceActive && !_journeyActive;
    if (_notifiedOverviewVisible != overviewVisible) {
        _notifiedOverviewVisible = overviewVisible;
        if (self.overviewVisibilityChanged) self.overviewVisibilityChanged(overviewVisible);
    }
    if (self.cameraChanged) self.cameraChanged([self cameraStateDescription]);
}
- (SolarCamera)cameraState { return _camera; }
- (void)changeCamera:(CameraChange)change {
    if (_journeyActive) return;
    try {
        SolarCamera next = _camera;
        change(next);
        [self keepCameraOutsideBodies:next];
        // 公開カメラ値の検証を投影境界に集約し、不正値を表示状態へ反映しない。
        (void)project_solar(next.target, next, 1, 1);
        _camera = next;
        [self notifyCamera];
        self.needsDisplay = YES;
    } catch (const std::exception& error) {
        if (self.cameraChanged) self.cameraChanged([NSString stringWithFormat:@"視点を変更できません: %s", error.what()]);
    }
}
- (void)setCameraState:(const SolarCamera&)camera {
    NSString *error = nil;
    if (![self applyCameraState:camera error:&error] && self.cameraChanged)
        self.cameraChanged([@"視点を変更できません: " stringByAppendingString:error]);
}
- (BOOL)applyCameraState:(const SolarCamera&)camera error:(NSString **)error {
    const SolarCamera next = camera;
    try {
        // 飛行の中断や frame の解除より先に、表示側と同じ規則で全候補を検証する。
        (void)solar_camera_basis(next);
    } catch (const std::exception& failure) {
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
    [self leaveNavigation];
    _camera = next;
    _following = NO;
    [self notifyCamera];
    self.needsDisplay = YES;
    return YES;
}
- (void)resetCamera {
    [self leaveNavigation];
    _following = NO;
    [self changeCamera:^(SolarCamera& next) { next = SolarCamera{}; }];
}
- (void)showInnerPlanets {
    [self leaveNavigation];
    _following = NO;
    [self changeCamera:^(SolarCamera& next) { next = SolarCamera{}; next.distance_au = 7; }];
}
- (void)zoomBy:(double)delta {
    if (_journeyActive) return;
    if (_surfaceActive) { [self changeSurfaceByX:0 y:0 zoom:delta]; return; }
    [self changeCamera:^(SolarCamera& next) { next.zoom(delta); if (self->_earthMoonMode) next.distance_au = std::max(next.distance_au, 0.0002); }];
}
- (void)zoomIn { [self zoomBy:-0.25]; }
- (void)zoomOut { [self zoomBy:0.25]; }
- (void)focusSelection {
    if (!_selection && _smallBodySelection) { [self focusSmallBodySelection]; return; }
    if (!_selection && _satelliteSelection) { [self focusSatelliteSelection]; return; }
    if (!_selection && _spacecraftSelection) { [self focusSpacecraftSelection]; return; }
    if (!_hasData || !_selection) return;
    [self leaveNavigation];
    _following = YES;
    const Vec3 target = [self displayPosition:*_selection];
    [self changeCamera:^(SolarCamera& next) { next.target = target; next.frame.reset(); next.distance_au = std::max(next.distance_au, 0.05); }];
}
- (void)showSurface {
    if ([self rejectSmallBodySurfaceNavigation] || [self rejectSatelliteSurfaceNavigation] || [self rejectSpacecraftSurfaceNavigation]) return;
    if (!_hasData) return;
    if (!_selection) [self selectBody:3];
    [self leaveNavigation];
    _following = YES;
    _surfacePreview = YES;
    const Vec3 target = [self displayPosition:*_selection];
    [self changeCamera:^(SolarCamera& next) { next.target = target; next.distance_au = 0.05; }];
}
- (void)orbitByX:(double)dx y:(double)dy {
    if (_journeyActive) return;
    if (_surfaceActive) { [self changeSurfaceByX:dx y:dy zoom:0]; return; }
    [self changeCamera:^(SolarCamera& next) { next.orbit(dx, dy); }];
}
- (void)panByX:(double)dx y:(double)dy {
    if (_journeyActive) return;
    if (_surfaceActive) { [self changeSurfaceByX:dx y:dy zoom:0]; return; }
    _earthMoonFollowing = NO;
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    _following = NO;
    [self changeCamera:^(SolarCamera& next) { next.pan(dx, dy, map.size.width, map.size.height); }];
}
- (void)mouseDown:(NSEvent *)event {
    [self.window makeFirstResponder:self];
    _lastDrag = _mouseStart = [self convertPoint:event.locationInWindow fromView:nil];
    _dragged = NO;
}
- (void)mouseDragged:(NSEvent *)event {
    const NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    if (!_dragged && std::hypot(point.x - _mouseStart.x, point.y - _mouseStart.y) < 3) return;
    _dragged = YES;
    const double dx = point.x - _lastDrag.x, dy = point.y - _lastDrag.y;
    if ((event.modifierFlags & NSEventModifierFlagShift) || event.type == NSEventTypeRightMouseDragged)
        [self panByX:dx y:dy];
    else [self orbitByX:dx y:dy];
    _lastDrag = point;
}
- (void)rightMouseDown:(NSEvent *)event { [self mouseDown:event]; }
- (void)rightMouseDragged:(NSEvent *)event { [self mouseDragged:event]; }
- (void)rightMouseUp:(NSEvent *)event { (void)event; }
- (void)scrollWheel:(NSEvent *)event {
    const double scale = event.hasPreciseScrollingDeltas ? 0.012 : 0.1;
    [self zoomBy:event.scrollingDeltaY * scale];
}
- (void)magnifyWithEvent:(NSEvent *)event { [self zoomBy:-event.magnification]; }
- (void)mouseUp:(NSEvent *)event {
    if (_dragged || !_hasData) return;
    [self pickBodyAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
}
- (void)pickBodyAtPoint:(NSPoint)click {
    // 地表では地面の向こうの天体を選ばないよう、一覧による選択に限定する。
    if (!_hasData || _surfaceActive || _journeyActive || !NSPointInRect(click, [self mapRect])) return;
    try {
        const auto picked = pick_solar_body([self scene], click);
        if (picked) [self selectBody:*picked];
        else {
            const auto small = [self smallBodiesSceneVisible] ? pick_small_body(*_smallBodySnapshot, *_smallBodyDisplay, _camera, [self mapRect], click) : std::nullopt;
            if (small) { [self selectSmallBody:*small]; return; }
            const auto satellite = [self satellitesSceneVisible] ? pick_satellite(*_satelliteSnapshot, _camera, [self mapRect], click, _satelliteDisplay.get()) : std::nullopt;
            if (satellite) { [self selectSatellite:*satellite]; return; }
            const auto spacecraft = [self spacecraftSceneVisible]
                ? pick_spacecraft(*_spacecraftSnapshot, _camera, [self mapRect], click, _spacecraftDisplayOptions) : std::nullopt;
            if (spacecraft) { [self selectSpacecraft:*spacecraft]; return; }
            _selection.reset(); _smallBodySelection.reset(); _satelliteSelection.reset(); _spacecraftSelection.reset();
            _following = NO; _surfacePreview = NO;
            [self notifySelection]; [self notifyCamera]; self.needsDisplay = YES;
        }
    } catch (const std::exception& error) { [self reportNavigationError:error.what()]; }
}
- (NSUInteger)visibleBodyCount {
    return _hasData ? visible_solar_bodies([self scene]).size() : 0;
}
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    RendererQualityScope canvas(context, _rendererDisplayOptions);
    [[NSColor colorWithSRGBRed:0.025 green:0.043 blue:0.072 alpha:1] setFill];
    NSRectFill(self.bounds);
    const NSRect map = [self mapRect];
    if (map.size.width < 160 || map.size.height < 100) return;
    RendererQualityScope text(context, _rendererDisplayOptions, RendererPrimitive::text);
    NSString *title = @"太陽中心 · J2000 黄道座標 · 透視投影 · 天体サイズは模式表示";
    if (_journeyActive) title = @"連続飛行 · 距離と半径は実比率 · 実時間の演出経路 · 地形なし";
    else if (_surfaceActive) title = @"実半径の球面 · 地形なし · 木土天海は基準球面 · 周囲の微小天体は記号";
    else if (_surfacePreview) title = @"選択天体の表面観察 · 模式半径 · ドラッグで観察方向を変更";
    else if (_earthMoonMode) title = @"地球と月 · 距離と半径は実比率 · 1.5 pt 未満は位置の記号 · 月軌道は地心相対";
    [title drawAtPoint:NSMakePoint(18, 10) withAttributes:textStyle(NSColor.secondaryLabelColor, 11)];
    if (!_hasData) {
        self.toolTip = nil;
        [@"データを開くと太陽系を表示します。" drawAtPoint:NSMakePoint(map.origin.x + 20, NSMidY(map))
                                                    withAttributes:textStyle(NSColor.labelColor, 13)];
        return;
    }
    try {
        const auto diagnostics = draw_solar_scene(context, [self scene]);
        NSMutableArray<NSString *> *messages = [NSMutableArray arrayWithCapacity:diagnostics.size()];
        for (const auto& diagnostic : diagnostics)
            [messages addObject:[NSString stringWithUTF8String:diagnostic.c_str()]];
        self.toolTip = messages.count ? [messages componentsJoinedByString:@"\n"] : nil;
        if (messages.count) {
            NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
            paragraph.lineBreakMode = NSLineBreakByTruncatingTail;
            NSMutableDictionary *style = [textStyle(NSColor.systemOrangeColor, 11) mutableCopy];
            style[NSParagraphStyleAttributeName] = paragraph;
            [[NSString stringWithFormat:@"食と影の診断 %lu 件（詳細はポインタを置いて表示）: %@",
                messages.count, messages.firstObject]
                drawInRect:NSMakeRect(map.origin.x + 8, map.origin.y + 8, map.size.width - 16, 18)
                withAttributes:style];
        }
    }
    catch (const std::exception& error) {
        self.toolTip = [NSString stringWithUTF8String:error.what()];
        [[NSString stringWithFormat:@"描画できません: %s", error.what()] drawAtPoint:NSMakePoint(map.origin.x + 20, NSMidY(map))
            withAttributes:textStyle(NSColor.labelColor, 12)];
    }
    NSString *help = [NSString stringWithFormat:@"ドラッグ: 回転   Shift / 右ドラッグ: 移動   スクロール / ピンチ: 拡縮   格子: %d AU", _camera.distance_au < 15 ? 1 : 10];
    if (_journeyActive) help = @"飛行中は手動の視点操作を固定 · 一覧の選択は次の目的地 · 全体表示で飛行を終了";
    else if (_surfaceActive) help = @"ドラッグ: 見回す   スクロール / ピンチ: 高度変更   天体の選択: 右の一覧   操作すると飛行を中断";
    else if (_surfacePreview) help = @"ドラッグ: 回転   Shift / 右ドラッグ: 移動   スクロール / ピンチ: 拡縮   全体表示へ戻るには「全体」";
    else if (_earthMoonMode) help = @"ドラッグ: 回転   Shift / 右ドラッグ: 移動   スクロール / ピンチ: 拡縮   月軌道は表示日時の地球に追従";
    [help drawAtPoint:NSMakePoint(18, NSMaxY(self.bounds) - 24) withAttributes:textStyle(NSColor.secondaryLabelColor, 10)];
    if ([self smallBodiesSceneVisible]) {
        NSString *time = _showsTimeInfo ? [NSString stringWithFormat:@" · 数値 JD %.5f", _smallBodySnapshot->julian_date] : @"";
        NSString *status = [NSString stringWithFormat:@"小天体 %lu / 原本 %lu 件を位置評価 · 二体近似%@（時系変換なし）",
            _smallBodySnapshot->positioned_count, _smallBodySnapshot->positions.size(), time];
        [status drawAtPoint:NSMakePoint(18, NSMaxY(self.bounds) - 39) withAttributes:textStyle(NSColor.secondaryLabelColor, 10)];
    }
}
@end
