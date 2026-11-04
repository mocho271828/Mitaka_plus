#import "RendererQuality.h"
#import "ConstellationRenderer.h"
#import "HorizonView.h"
#import "HorizonLandscapeRenderer.h"
#import "StarRenderer.h"
#import "ConstellationArtRenderer.h"
#import "GridRenderer.h"
#import "SkyView.h"
#include <algorithm>
#include <limits>
#include <cmath>
#include <cstring>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
struct BackgroundKey {
    const SkyBackgrounds* model;
    MilkyWayMode mode;
    std::array<double, 6> observationViewport;
    std::size_t width, height;
    bool operator==(const BackgroundKey& other) const {
        return model == other.model && mode == other.mode && observationViewport == other.observationViewport
            && width == other.width && height == other.height;
    }
};
// 既存の円筒投影・操作を再利用し、方位だけ右向きに反転する。
SkyViewport skyViewport(HorizonViewport viewport) {
    return {360 - viewport.center_azimuth_deg, viewport.center_altitude_deg, viewport.zoom};
}
HorizonViewport horizonViewport(SkyViewport viewport) {
    viewport = normalize_sky_viewport(viewport);
    return {std::fmod(360 - viewport.center_ra_deg, 360), viewport.center_dec_deg, viewport.zoom};
}
std::optional<ScreenPoint> projectHorizontal(HorizontalCoordinates coordinates,
                                             HorizonViewport viewport, NSSize size) {
    return project_sky({360 - coordinates.azimuth_deg, coordinates.altitude_deg},
                       skyViewport(viewport), size.width, size.height);
}
void drawText(NSString *text, NSPoint point, NSColor *color, CGFloat size, const RendererDisplayOptions& quality) {
    RendererQualityScope textQuality(NSGraphicsContext.currentContext.CGContext, quality, RendererPrimitive::text);
    [text drawAtPoint:point withAttributes:@{
        NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:size weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: color
    }];
}
NSColor *bodyColor(Body body, bool belowHorizon) {
    NSColor *color = body == Body::sun ? NSColor.systemYellowColor
        : body == Body::mars ? NSColor.systemOrangeColor : NSColor.systemCyanColor;
    return belowHorizon ? [color colorWithAlphaComponent:0.4] : color;
}
}

@implementation HorizonView {
    std::shared_ptr<const SkyModel> _model;
    std::shared_ptr<const ExtendedCatalogs> _catalogs;
    std::shared_ptr<const SkyBackgrounds> _backgrounds;
    MilkyWayMode _milkyWayMode;
    NSImage *_backgroundImage;
    std::optional<BackgroundKey> _backgroundKey;
    SkyBodies _bodies;
    HorizonLandscapeRenderer *_landscapeRenderer;
    ConstellationDisplayOptions _constellationDisplayOptions;
    PlanetDisplayOptions _planetDisplayOptions;
    RadiusDisplayOptions _radiusDisplayOptions;
    RendererDisplayOptions _rendererDisplayOptions;
    GridDisplayOptions _gridDisplayOptions;
    GridGeometryCache _gridCache;
    StarDisplayOptions _starDisplayOptions;
    StarRenderer *_starRenderer;
    std::shared_ptr<const ConstellationArtModel> _constellationArt;
    std::set<std::int32_t> _selectedStarNameHIPs;
    std::optional<Selection> _selection;
    ObserverSite _site;
    std::optional<ObservationFrame> _frame;
    double _julianDate, _magnitudeLimit;
    HorizonViewport _viewport;
    NSPoint _mouseDownPoint, _lastDragPoint;
    BOOL _dragging, _showsTimeInfo;
}

- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _site = {35.68, 139.76};
        _julianDate = 2451545;
        _frame.emplace(_site, _julianDate);
        _magnitudeLimit = 6.5;
        _showsTimeInfo = YES;
        _landscapeRenderer = [[HorizonLandscapeRenderer alloc] init];
        self.accessibilityElement = YES;
        self.accessibilityRole = NSAccessibilityImageRole;
        self.accessibilityLabel = @"地平座標の全天図。方位は真北0度・東90度、高度は上向き。観測地点の風景を重ねて表示。ドラッグで移動、ホイール・ピンチで拡大。";
    }
    return self;
}
- (BOOL)isFlipped { return YES; }
- (BOOL)isOpaque { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (NSRect)mapRect { return NSInsetRect(self.bounds, 42, 34); }
- (RendererDisplayOptions)rendererDisplayOptions { return _rendererDisplayOptions; }
- (void)setRendererDisplayOptions:(RendererDisplayOptions)options {
    _rendererDisplayOptions = options;
    self.needsDisplay = YES;
}
- (ConstellationDisplayOptions)constellationDisplayOptions { return _constellationDisplayOptions; }
- (void)setConstellationDisplayOptions:(ConstellationDisplayOptions)options {
    // App が現在のカタログとの対応を検証する。読込前の設定も保持する。
    _constellationDisplayOptions = std::move(options);
    self.needsDisplay = YES;
}
- (RadiusDisplayOptions)radiusDisplayOptions { return _radiusDisplayOptions; }
- (void)setRadiusDisplayOptions:(RadiusDisplayOptions)options {
    validate_radius_display_options(options);
    moon_orbit_display_factor(options);
    _radiusDisplayOptions = options;
    self.needsDisplay = YES;
}
- (PlanetDisplayOptions)planetDisplayOptions { return _planetDisplayOptions; }
- (void)setPlanetDisplayOptions:(PlanetDisplayOptions)options {
    _planetDisplayOptions = options;
    self.needsDisplay = YES;
}
- (GridDisplayOptions)gridDisplayOptions { return _gridDisplayOptions; }
- (void)setGridDisplayOptions:(GridDisplayOptions)options {
    _gridDisplayOptions = options;
    self.needsDisplay = YES;
}
- (MilkyWayMode)milkyWayMode { return _milkyWayMode; }
- (void)setMilkyWayMode:(MilkyWayMode)mode {
    SkyBackgrounds{}.image(mode);
    if (_milkyWayMode == mode) return;
    _milkyWayMode = mode;
    self.needsDisplay = YES;
}
- (void)setSkyBackgrounds:(std::shared_ptr<const SkyBackgrounds>)backgrounds {
    if (_backgrounds == backgrounds) return;
    _backgrounds = std::move(backgrounds);
    _backgroundImage = nil;
    _backgroundKey.reset();
    self.needsDisplay = YES;
}
- (void)setObservationSite:(mitaka::ObserverSite)site julianDate:(double)julianDate {
    _gridCache.set_observation(site, julianDate);
    _site = site;
    _julianDate = julianDate;
    _frame = _gridCache.frame();
    [self notifySelection];
    self.needsDisplay = YES;
}
- (StarDisplayOptions)starDisplayOptions { return _starDisplayOptions; }
- (void)setStarDisplayOptions:(StarDisplayOptions)options {
    validate_star_display(options);
    _starDisplayOptions = options;
    self.needsDisplay = YES;
}
- (double)magnitudeLimit { return _magnitudeLimit; }
- (void)setMagnitudeLimit:(double)value {
    if (!std::isfinite(value)) throw std::invalid_argument("magnitude limit must be finite");
    _magnitudeLimit = value;
    if (_selection && _selection->kind == ObjectKind::star &&
        _model->stars()[_selection->index].apparent_v_magnitude > value) _selection.reset();
    [self notifySelection];
    self.needsDisplay = YES;
}
- (double)julianDate { return _julianDate; }
- (BOOL)showsTimeInfo { return _showsTimeInfo; }
- (BOOL)showsLandscapeImage { return _landscapeRenderer.showsLandscapeImage; }
- (void)setShowsLandscapeImage:(BOOL)visible { _landscapeRenderer.showsLandscapeImage = visible; self.needsDisplay = YES; }
- (void)setEarthLandscapes:(std::shared_ptr<const EarthLandscapes>)landscapes {
    [_landscapeRenderer setModel:std::move(landscapes)];
    self.needsDisplay = YES;
}
- (void)setObserverPlaceIdentifier:(const std::string&)identifier {
    [_landscapeRenderer setObserverPlaceIdentifier:identifier];
    self.needsDisplay = YES;
}
- (const std::string&)observerPlaceIdentifier { return [_landscapeRenderer observerPlaceIdentifier]; }
- (void)setShowsTimeInfo:(BOOL)visible { _showsTimeInfo = visible; self.needsDisplay = YES; }
- (ObserverSite)observerSite { return _site; }
- (void)setObserverSite:(ObserverSite)site {
    [self setObservationSite:site julianDate:_julianDate];
}
- (void)setModel:(std::shared_ptr<const SkyModel>)model bodies:(const SkyBodies&)bodies {
    _model = std::move(model);
    _starRenderer = [[StarRenderer alloc] initWithModel:_model catalogs:_catalogs];
    [_starRenderer setSelectedNameHIPs:_selectedStarNameHIPs];
    _bodies = bodies;
    _selection.reset();
    [self notifySelection];
    self.needsDisplay = YES;
}
- (void)setExtendedCatalogs:(std::shared_ptr<const ExtendedCatalogs>)catalogs {
    _catalogs = std::move(catalogs);
    _starRenderer = [[StarRenderer alloc] initWithModel:_model catalogs:_catalogs];
    [_starRenderer setSelectedNameHIPs:_selectedStarNameHIPs];
    self.needsDisplay = YES;
}
- (void)setConstellationArt:(std::shared_ptr<const ConstellationArtModel>)art {
    _constellationArt = std::move(art);
    self.needsDisplay = YES;
}
- (void)setSelectedStarNameHIPs:(const std::set<std::int32_t>&)hips {
    _selectedStarNameHIPs = hips;
    [_starRenderer setSelectedNameHIPs:hips];
    self.needsDisplay = YES;
}
- (void)setBodies:(const SkyBodies&)bodies julianDate:(double)julianDate {
    _gridCache.set_observation(_site, julianDate);
    _bodies = bodies;
    _julianDate = julianDate;
    _frame = _gridCache.frame();
    [self notifySelection];
    self.needsDisplay = YES;
}
- (HorizonViewport)viewport { return _viewport; }
- (void)setViewport:(HorizonViewport)viewport {
    _viewport = horizonViewport(skyViewport(viewport));
    self.needsDisplay = YES;
    if (self.viewportChanged) self.viewportChanged();
}
- (void)resetView { [self setViewport:{}]; }
- (void)zoomBy:(double)factor atPoint:(NSPoint)point {
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    [self setViewport:horizonViewport(zoom_sky(skyViewport(_viewport), factor,
        {point.x - map.origin.x, point.y - map.origin.y}, map.size.width, map.size.height))];
}
- (void)zoomIn { [self zoomBy:1.5 atPoint:NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds))]; }
- (void)zoomOut { [self zoomBy:1 / 1.5 atPoint:NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds))]; }
- (EquatorialCoordinates)selectionCoordinates {
    if (_selection->kind == ObjectKind::body) return _bodies[_selection->index].coordinates;
    const auto& star = _model->stars()[_selection->index];
    return {star.right_ascension_degrees, star.declination_degrees};
}
- (void)focusSelection {
    if (!_selection || !_model) return;
    const auto coordinates = _frame->to_horizontal([self selectionCoordinates]);
    [self setViewport:{coordinates.azimuth_deg, coordinates.altitude_deg, std::max(4.0, _viewport.zoom)}];
}
- (void)selectBody:(NSUInteger)index {
    if (!_model || index >= _bodies.size()) return;
    _selection = Selection{ObjectKind::body, index};
    [self notifySelection];
    self.needsDisplay = YES;
}
- (NSUInteger)selectedBodyIndex {
    return _selection && _selection->kind == ObjectKind::body ? _selection->index : NSNotFound;
}
- (void)clearSelection {
    _selection.reset();
    [self notifySelection];
    self.needsDisplay = YES;
}
- (BOOL)selectStarHIP:(int32_t)hip {
    if (!_model) return NO;
    const auto index = _model->star_index(hip);
    if (!index) return NO;
    _magnitudeLimit = std::max(_magnitudeLimit, static_cast<double>(_model->stars()[*index].apparent_v_magnitude));
    _selection = Selection{ObjectKind::star, *index};
    [self notifySelection];
    self.needsDisplay = YES;
    return YES;
}
- (NSUInteger)visibleStarCount {
    if (!_model || !_starDisplayOptions.visible) return 0;
    return std::count_if(_model->stars().begin(), _model->stars().end(), [self](const auto& star) {
        if (star.apparent_v_magnitude > self->_magnitudeLimit) return false;
        const auto horizontal = self->_frame->to_horizontal({star.right_ascension_degrees, star.declination_degrees});
        return projectHorizontal(horizontal, self->_viewport, NSMakeSize(1, 1)).has_value();
    });
}
- (void)notifySelection {
    NSString *description = @"天体をクリックすると\n方位・高度と明るさ・距離を表示します。\n地平線より下の天体は暗く表示します。";
    if (_selection && _model) {
        const auto horizontal = _frame->to_horizontal([self selectionCoordinates]);
        NSString *name, *detail;
        if (_selection->kind == ObjectKind::star) {
            const auto& star = _model->stars()[_selection->index];
            name = [NSString stringWithFormat:@"HIP %d", star.hip];
            detail = [NSString stringWithFormat:@"V 等級 %.2f", star.apparent_v_magnitude];
        } else {
            const auto& body = _bodies[_selection->index];
            name = bodyName(body.id);
            detail = [NSString stringWithFormat:@"地心距離 %.6f AU", body.distance_au];
        }
        description = [NSString stringWithFormat:@"%@\n方位 %.3f° / 高度 %+.3f°%@\n%@",
            name, horizontal.azimuth_deg, horizontal.altitude_deg, horizontal.altitude_deg < 0 ? @"（地平線下）" : @"", detail];
    }
    if (self.selectionChanged) self.selectionChanged(description);
}
- (void)mouseDown:(NSEvent *)event {
    if (!_model) return;
    [self.window makeFirstResponder:self];
    _mouseDownPoint = _lastDragPoint = [self convertPoint:event.locationInWindow fromView:nil];
    _dragging = NO;
}
- (void)mouseDragged:(NSEvent *)event {
    if (!_model) return;
    const NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    _dragging = _dragging || std::hypot(point.x - _mouseDownPoint.x, point.y - _mouseDownPoint.y) > 3;
    if (_dragging) [self setViewport:horizonViewport(pan_sky(skyViewport(_viewport),
        point.x - _lastDragPoint.x, point.y - _lastDragPoint.y, map.size.width, map.size.height))];
    _lastDragPoint = point;
}
- (void)mouseUp:(NSEvent *)event {
    if (!_model || _dragging) return;
    const NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0 || !NSPointInRect(point, map)) return;
    double nearest = 8 * 8;
    _selection.reset();
    const auto consider = [&](EquatorialCoordinates coordinates, Selection selection) {
        const auto projected = projectHorizontal(_frame->to_horizontal(coordinates), _viewport, map.size);
        if (!projected) return;
        const double dx = map.origin.x + projected->x - point.x, dy = map.origin.y + projected->y - point.y;
        const double distance = dx * dx + dy * dy;
        if (distance <= nearest) { nearest = distance; _selection = selection; }
    };
    for (std::size_t index = 0; _starDisplayOptions.visible && index < _model->stars().size(); ++index) {
        const auto& star = _model->stars()[index];
        if (star.apparent_v_magnitude <= _magnitudeLimit)
            consider({star.right_ascension_degrees, star.declination_degrees}, {ObjectKind::star, index});
    }
    for (std::size_t index = 0; _planetDisplayOptions.visible && index < _bodies.size(); ++index)
        consider(_bodies[index].coordinates, {ObjectKind::body, index});
    double nearestBody = std::numeric_limits<double>::infinity();
    const bool hadNearestSelection = _selection.has_value();
    for (std::size_t index = 0; !hadNearestSelection && _planetDisplayOptions.visible && index < _bodies.size(); ++index) {
        const auto projected = projectHorizontal(_frame->to_horizontal(_bodies[index].coordinates), _viewport, map.size);
        if (!projected) continue;
        const double distance = std::hypot(point.x - map.origin.x - projected->x, point.y - map.origin.y - projected->y);
        const double radius = std::clamp(4 * body_marker_display_factor(_radiusDisplayOptions,
            RadiusDisplayContext::planetarium, _bodies[index].id), 1.0, 120.0);
        if (distance <= radius && distance < nearestBody) {
            nearestBody = distance;
            _selection = Selection{ObjectKind::body, index};
        }
    }
    [self notifySelection];
    self.needsDisplay = YES;
    if (event.clickCount == 2) [self focusSelection];
}
- (void)scrollWheel:(NSEvent *)event {
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    if (event.hasPreciseScrollingDeltas)
        [self setViewport:horizonViewport(pan_sky(skyViewport(_viewport), event.scrollingDeltaX,
            event.scrollingDeltaY, map.size.width, map.size.height))];
    else [self zoomBy:std::exp(std::clamp(event.scrollingDeltaY * 0.08, -2.0, 2.0))
             atPoint:[self convertPoint:event.locationInWindow fromView:nil]];
}
- (void)magnifyWithEvent:(NSEvent *)event {
    [self zoomBy:std::exp(std::clamp(static_cast<double>(event.magnification), -2.0, 2.0))
         atPoint:[self convertPoint:event.locationInWindow fromView:nil]];
}
- (void)keyDown:(NSEvent *)event {
    NSString *characters = event.charactersIgnoringModifiers;
    if ([characters isEqualToString:@"+"] || [characters isEqualToString:@"="]) [self zoomIn];
    else if ([characters isEqualToString:@"-"]) [self zoomOut];
    else if ([characters isEqualToString:@"0"]) [self resetView];
    else [super keyDown:event];
}

- (void)drawSkyBackgroundInRect:(NSRect)map {
    const auto* texture = _backgrounds ? _backgrounds->image(_milkyWayMode) : nullptr;
    if (!texture) return;
    const double scale = std::min(1.0, 1024 / std::max(map.size.width, map.size.height));
    const auto width = static_cast<std::size_t>(std::clamp(std::ceil(map.size.width * scale), 1.0, 1024.0));
    const auto height = static_cast<std::size_t>(std::clamp(std::ceil(map.size.height * scale), 1.0, 1024.0));
    const BackgroundKey key{_backgrounds.get(), _milkyWayMode,
        {_site.latitude_deg, _site.longitude_deg, _julianDate,
         _viewport.center_azimuth_deg, _viewport.center_altitude_deg, _viewport.zoom}, width, height};
    // 非表示中の日時更新は描画まで評価しない。同一 JD の天体更新も画像を再生成しない。
    if (!_backgroundImage || !_backgroundKey || !(*_backgroundKey == key)) {
        const auto pixels = render_horizon_background(*texture, _viewport, *_frame, width, height);
        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
            pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
            isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:NSBitmapFormatAlphaNonpremultiplied
            bytesPerRow:width * 4 bitsPerPixel:32];
        if (bitmap) {
            std::memcpy(bitmap.bitmapData, pixels.rgba.data(), pixels.rgba.size());
            bitmap = [bitmap bitmapImageRepByRetaggingWithColorSpace:NSColorSpace.sRGBColorSpace];
        }
        _backgroundImage = bitmap ? [[NSImage alloc] initWithSize:map.size] : nil;
        if (bitmap) [_backgroundImage addRepresentation:bitmap];
        _backgroundKey = key;
    }
    RendererQualityScope clipped(NSGraphicsContext.currentContext.CGContext, _rendererDisplayOptions);
    CGContextClipToRect(NSGraphicsContext.currentContext.CGContext, map);
    [_backgroundImage drawInRect:map fromRect:NSZeroRect operation:NSCompositingOperationPlusLighter
        fraction:1 respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
}
- (void)drawGrid:(CGContextRef)context inRect:(NSRect)map {
    // 高度0の線が画面外でも、下半球の背景を正しく塗る。
    const double horizonY = NSMidY(map) + _viewport.center_altitude_deg / (180 / _viewport.zoom) * map.size.height;
    const double groundY = std::clamp(horizonY, static_cast<double>(NSMinY(map)), static_cast<double>(NSMaxY(map)));
    if (!_landscapeRenderer.hasModel) {
        CGContextSetRGBFillColor(context, 0.11, 0.10, 0.09, 1);
        CGContextFillRect(context, CGRectMake(map.origin.x, groundY, map.size.width, NSMaxY(map) - groundY));
    }
    draw_sky_grids(context, map, skyViewport(_viewport), _gridDisplayOptions, _gridCache, true, _rendererDisplayOptions);
}
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    RendererQualityScope canvas(context, _rendererDisplayOptions);
    [[NSColor colorWithSRGBRed:0.025 green:0.043 blue:0.072 alpha:1] setFill];
    NSRectFill(self.bounds);
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    [self drawSkyBackgroundInRect:map];
    [self drawGrid:context inRect:map];
    NSString *time = _showsTimeInfo ? [NSString stringWithFormat:@" · JD %.5f", _julianDate] : @"";
    drawText([NSString stringWithFormat:@"地平座標（大気差・視差なし） · 緯度 %+.2f° 東経 %+.2f°%@ · %.1f×", _site.latitude_deg,
        _site.longitude_deg, time, _viewport.zoom], NSMakePoint(map.origin.x, 8), NSColor.secondaryLabelColor, 11, _rendererDisplayOptions);
    if (!_model) {
        drawText(@"「データを開く」で hip.dat と cf96.dat のあるフォルダを選択", NSMakePoint(map.origin.x + 20, NSMidY(map)), NSColor.labelColor, 13, _rendererDisplayOptions);
        return;
    }
    const auto artStats = _constellationArt ? draw_horizon_constellation_art(context, *_constellationArt,
        _constellationDisplayOptions, _rendererDisplayOptions, *_frame, _viewport, map) : ConstellationArtRenderStats{};
    const auto constellationStats = draw_horizon_constellations(context, *_model, _constellationDisplayOptions,
        _rendererDisplayOptions, *_frame, _viewport, map);
    if (constellationStats.omitted_intervals || artStats.omitted_intervals) {
        drawText([NSString stringWithFormat:@"星座: 投影の分割上限で %lu 区間を省略",
            static_cast<unsigned long>(constellationStats.omitted_intervals + artStats.omitted_intervals)],
            NSMakePoint(map.origin.x, NSMaxY(map) + 10), NSColor.secondaryLabelColor, 10, _rendererDisplayOptions);
    }
    RendererQualityScope clipped(context, _rendererDisplayOptions);
    CGContextClipToRect(context, map);
    [_starRenderer drawInRect:map magnitudeLimit:_magnitudeLimit options:_starDisplayOptions quality:_rendererDisplayOptions
        projector:[&](EquatorialCoordinates coordinates) -> std::optional<StarProjection> {
            const auto horizontal = _frame->to_horizontal(coordinates);
            const auto point = projectHorizontal(horizontal, _viewport, map.size);
            return point ? std::optional<StarProjection>{{*point, horizontal.altitude_deg < 0 ? 0.3 : 1}} : std::nullopt;
        }];
    for (const auto& body : _bodies) {
        if (!_planetDisplayOptions.visible) break;
        const auto horizontal = _frame->to_horizontal(body.coordinates);
        const auto point = projectHorizontal(horizontal, _viewport, map.size);
        if (!point) continue;
        const NSPoint center = NSMakePoint(map.origin.x + point->x, map.origin.y + point->y);
        NSColor *color = bodyColor(body.id, horizontal.altitude_deg < 0);
        RendererQualityScope points(context, _rendererDisplayOptions, RendererPrimitive::point);
        [color setFill];
        const double radius = std::clamp(4 * body_marker_display_factor(_radiusDisplayOptions,
            RadiusDisplayContext::planetarium, body.id), 1.0, 120.0);
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(center.x - radius, center.y - radius, 2 * radius, 2 * radius)] fill];
        if (_planetDisplayOptions.labels) drawText(bodyName(body.id), NSMakePoint(center.x + radius + 4, center.y - 16), color, 12, _rendererDisplayOptions);
    }
    if (_selection && (_selection->kind == ObjectKind::star
        ? _starDisplayOptions.visible : _planetDisplayOptions.visible)) {
        const auto point = projectHorizontal(_frame->to_horizontal([self selectionCoordinates]), _viewport, map.size);
        if (point) {
            RendererQualityScope lines(context, _rendererDisplayOptions, RendererPrimitive::line);
            [NSColor.whiteColor setStroke];
            const double radius = _selection->kind == ObjectKind::body
                ? std::max(9.0, 4 + std::clamp(4 * body_marker_display_factor(_radiusDisplayOptions,
                    RadiusDisplayContext::planetarium, _bodies[_selection->index].id), 1.0, 120.0)) : 9.0;
            NSBezierPath *ring = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(map.origin.x + point->x - radius,
                map.origin.y + point->y - radius, 2 * radius, 2 * radius)];
            ring.lineWidth = 1;
            [ring stroke];
        }
    }
    [_landscapeRenderer drawInRect:map viewport:_viewport quality:_rendererDisplayOptions];
    if (_landscapeRenderer.hasModel)
        draw_sky_grids(context, map, skyViewport(_viewport), _gridDisplayOptions, _gridCache, true, _rendererDisplayOptions);
}
@end
