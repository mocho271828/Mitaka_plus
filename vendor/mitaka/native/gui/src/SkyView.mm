#import "RendererQuality.h"
#import "ConstellationRenderer.h"
#import "SkyView.h"
#import "StarRenderer.h"
#import "ConstellationArtRenderer.h"
#import "GridRenderer.h"
#import "SkyCatalogRenderer.h"
#include <algorithm>
#include <cmath>
#include <cstring>
#include <stdexcept>

using namespace mitaka::gui;

NSString *bodyName(Body body) {
    switch (body) {
        case Body::sun: return @"太陽";
        case Body::mercury: return @"水星";
        case Body::venus: return @"金星";
        case Body::mars: return @"火星";
        case Body::jupiter: return @"木星";
        case Body::saturn: return @"土星";
        case Body::uranus: return @"天王星";
        case Body::neptune: return @"海王星";
        case Body::pluto: return @"冥王星";
        case Body::earth: return @"地球";
        case Body::moon: return @"月";
    }
    return @"";
}

static NSColor *bodyColor(Body body) {
    switch (body) {
        case Body::sun: return [NSColor colorWithSRGBRed:1 green:0.79 blue:0.28 alpha:1];
        case Body::mercury: return NSColor.lightGrayColor;
        case Body::venus: return [NSColor colorWithSRGBRed:1 green:0.9 blue:0.65 alpha:1];
        case Body::mars: return [NSColor colorWithSRGBRed:1 green:0.47 blue:0.33 alpha:1];
        case Body::jupiter: return [NSColor colorWithSRGBRed:0.98 green:0.76 blue:0.52 alpha:1];
        case Body::saturn: return [NSColor colorWithSRGBRed:0.91 green:0.85 blue:0.57 alpha:1];
        case Body::uranus: return [NSColor colorWithSRGBRed:0.53 green:0.9 blue:0.92 alpha:1];
        case Body::neptune: return [NSColor colorWithSRGBRed:0.46 green:0.66 blue:1 alpha:1];
        case Body::pluto: return NSColor.lightGrayColor;
        case Body::earth: return NSColor.systemBlueColor;
        case Body::moon: return NSColor.lightGrayColor;
    }
    return NSColor.whiteColor;
}

static void drawText(NSString *text, NSPoint point, NSColor *color, CGFloat size, const RendererDisplayOptions& quality) {
    RendererQualityScope textQuality(NSGraphicsContext.currentContext.CGContext, quality, RendererPrimitive::text);
    [text drawAtPoint:point withAttributes:@{
        NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:size weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: color
    }];
}

@implementation SkyView {
    std::shared_ptr<const SkyModel> _model;
    SkyBodies _bodies;
    ConstellationDisplayOptions _constellationDisplayOptions;
    PlanetDisplayOptions _planetDisplayOptions;
    RendererDisplayOptions _rendererDisplayOptions;
    GridDisplayOptions _gridDisplayOptions;
    GridGeometryCache _gridCache;
    StarDisplayOptions _starDisplayOptions;
    StarRenderer *_starRenderer;
    std::shared_ptr<const ConstellationArtModel> _constellationArt;
    std::set<std::int32_t> _selectedStarNameHIPs;
    std::optional<Selection> _selection;
    double _magnitudeLimit;
    SkyViewport _viewport;
    NSPoint _mouseDownPoint, _lastDragPoint;
    BOOL _dragging;
    std::shared_ptr<const ExtendedCatalogs> _catalogs;
    SkyCatalogRenderer *_catalogRenderer;
    SkyCatalogDisplay _catalogDisplay;
    std::optional<std::pair<SkyCatalogKind, std::size_t>> _catalogSelection;
    std::shared_ptr<const SkyBackgrounds> _backgrounds;
    MilkyWayMode _milkyWayMode;
    NSImage *_backgroundImage;
    NSSize _backgroundSize;
}

- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _magnitudeLimit = 6.5;
        self.accessibilityElement = YES;
        self.accessibilityRole = NSAccessibilityImageRole;
        self.accessibilityLabel = @"HIP 恒星・太陽・惑星・月の全天図。ドラッグで移動、ホイール・ピンチで拡大。赤経は左向き、赤緯は上向き。";
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
- (void)setObservationSite:(mitaka::ObserverSite)site julianDate:(double)julianDate {
    _gridCache.set_observation(site, julianDate);
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
- (NSUInteger)visibleStarCount {
    if (!_model || !_starDisplayOptions.visible) return 0;
    return std::count_if(_model->stars().begin(), _model->stars().end(), [self](const auto& star) {
        return star.apparent_v_magnitude <= self->_magnitudeLimit
            && project_sky({star.right_ascension_degrees, star.declination_degrees}, self->_viewport, 1, 1).has_value();
    });
}
- (BOOL)showsConstellationLines { return _constellationDisplayOptions.lines; }
- (void)setShowsConstellationLines:(BOOL)value { _constellationDisplayOptions.lines = value; self.needsDisplay = YES; }
- (BOOL)showsConstellationBoundaries { return _constellationDisplayOptions.boundaries; }
- (void)setShowsConstellationBoundaries:(BOOL)value { _constellationDisplayOptions.boundaries = value; self.needsDisplay = YES; }
- (BOOL)showsConstellationNames { return _constellationDisplayOptions.labels; }
- (void)setShowsConstellationNames:(BOOL)value { _constellationDisplayOptions.labels = value; self.needsDisplay = YES; }
- (BOOL)showsNebulae { return _catalogDisplay.nebulae; }
- (void)setShowsNebulae:(BOOL)value { _catalogDisplay.nebulae = value; self.needsDisplay = YES; }
- (BOOL)showsGalaxies { return _catalogDisplay.galaxies; }
- (void)setShowsGalaxies:(BOOL)value { _catalogDisplay.galaxies = value; self.needsDisplay = YES; }
- (BOOL)showsQuasars { return _catalogDisplay.quasars; }
- (void)setShowsQuasars:(BOOL)value { _catalogDisplay.quasars = value; self.needsDisplay = YES; }
- (MilkyWayMode)milkyWayMode { return _milkyWayMode; }
- (void)setMilkyWayMode:(MilkyWayMode)value {
    SkyBackgrounds{}.image(value);
    if (_milkyWayMode == value) return;
    _milkyWayMode = value;
    _backgroundImage = nil;
    self.needsDisplay = YES;
}
- (void)setSkyBackgrounds:(std::shared_ptr<const SkyBackgrounds>)backgrounds {
    _backgrounds = std::move(backgrounds);
    _backgroundImage = nil;
    self.needsDisplay = YES;
}
- (SkyViewport)viewport { return _viewport; }
- (void)setViewport:(SkyViewport)viewport {
    viewport = normalize_sky_viewport(viewport);
    if (_viewport.center_ra_deg != viewport.center_ra_deg || _viewport.center_dec_deg != viewport.center_dec_deg
        || _viewport.zoom != viewport.zoom) _backgroundImage = nil;
    _viewport = viewport;
    self.needsDisplay = YES;
    if (self.viewportChanged) self.viewportChanged();
}
- (void)resetView { [self setViewport:{}]; }
- (void)zoomBy:(double)factor atPoint:(NSPoint)point {
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    [self setViewport:zoom_sky(_viewport, factor, {point.x - map.origin.x, point.y - map.origin.y},
                              map.size.width, map.size.height)];
}
- (void)zoomIn { [self zoomBy:1.5 atPoint:NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds))]; }
- (void)zoomOut { [self zoomBy:1 / 1.5 atPoint:NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds))]; }
- (std::optional<mitaka::EquatorialCoordinates>)selectedCoordinates {
    if (_catalogSelection && _catalogs) {
        const auto [kind, index] = *_catalogSelection;
        if (kind == SkyCatalogKind::nebula) return _catalogs->ngc[index].coordinates;
        return kind == SkyCatalogKind::galaxy ? _catalogs->galaxies[index].coordinates
                                              : _catalogs->quasars[index].coordinates;
    }
    if (!_selection || !_model) return std::nullopt;
    if (_selection->kind == ObjectKind::body) return _bodies[_selection->index].coordinates;
    const auto& star = _model->stars()[_selection->index];
    return mitaka::EquatorialCoordinates{star.right_ascension_degrees, star.declination_degrees};
}
- (void)focusSelection {
    const auto coordinates = [self selectedCoordinates];
    if (!coordinates) return;
    [self setViewport:{coordinates->right_ascension_deg, coordinates->declination_deg,
                       std::max(4.0, _viewport.zoom)}];
}
- (void)setModel:(std::shared_ptr<const SkyModel>)model bodies:(const SkyBodies&)bodies {
    _model = std::move(model);
    _starRenderer = [[StarRenderer alloc] initWithModel:_model catalogs:_catalogs];
    [_starRenderer setSelectedNameHIPs:_selectedStarNameHIPs];
    _bodies = bodies;
    _selection.reset();
    _catalogSelection.reset();
    _catalogRenderer = [[SkyCatalogRenderer alloc] initWithModel:_model catalogs:_catalogs];
    [self notifySelection];
    self.needsDisplay = YES;
}
- (void)setExtendedCatalogs:(std::shared_ptr<const ExtendedCatalogs>)catalogs {
    _catalogs = std::move(catalogs);
    _starRenderer = [[StarRenderer alloc] initWithModel:_model catalogs:_catalogs];
    [_starRenderer setSelectedNameHIPs:_selectedStarNameHIPs];
    _catalogSelection.reset();
    _catalogRenderer = [[SkyCatalogRenderer alloc] initWithModel:_model catalogs:_catalogs];
    [self notifySelection];
    self.needsDisplay = YES;
}
- (void)setBodies:(const SkyBodies&)bodies {
    _bodies = bodies;
    [self notifySelection];
    self.needsDisplay = YES;
}
- (void)selectBody:(NSUInteger)index {
    if (!_model || index >= _bodies.size()) return;
    _selection = Selection{ObjectKind::body, index};
    _catalogSelection.reset();
    [self notifySelection];
    self.needsDisplay = YES;
}
- (NSUInteger)selectedBodyIndex {
    return _selection && _selection->kind == ObjectKind::body ? _selection->index : NSNotFound;
}
- (void)clearSelection {
    _selection.reset();
    _catalogSelection.reset();
    [self notifySelection];
    self.needsDisplay = YES;
}
- (BOOL)selectStarHIP:(int32_t)hip {
    if (!_model) return NO;
    const auto index = _model->star_index(hip);
    if (!index) return NO;
    _magnitudeLimit = std::max(_magnitudeLimit, static_cast<double>(_model->stars()[*index].apparent_v_magnitude));
    _selection = Selection{ObjectKind::star, *index};
    _catalogSelection.reset();
    [self notifySelection];
    self.needsDisplay = YES;
    return YES;
}
- (BOOL)selectDeepSkyKind:(SkyCatalogKind)kind index:(NSUInteger)index {
    if (!_catalogs) return NO;
    switch (kind) {
        case SkyCatalogKind::nebula:
            if (index >= _catalogs->ngc.size()) return NO;
            _catalogDisplay.nebulae = true;
            _magnitudeLimit = std::max(_magnitudeLimit, static_cast<double>(_catalogs->ngc[index].magnitude));
            break;
        case SkyCatalogKind::galaxy:
            if (index >= _catalogs->galaxies.size()) return NO;
            _catalogDisplay.galaxies = true;
            break;
        case SkyCatalogKind::quasar:
            if (index >= _catalogs->quasars.size()) return NO;
            _catalogDisplay.quasars = true;
            break;
        default:
            return NO;
    }
    _selection.reset();
    _catalogSelection = std::make_pair(kind, index);
    [self notifySelection];
    self.needsDisplay = YES;
    return YES;
}
- (void)notifySelection {
    NSString *description = @"天体をクリックすると\n座標と明るさ・距離を表示します。";
    if (_catalogSelection && _catalogs) {
        const auto [kind, index] = *_catalogSelection;
        const auto coordinates = *[self selectedCoordinates];
        if (kind == SkyCatalogKind::nebula) {
            const auto& object = _catalogs->ngc[index];
            NSString *magnitude = object.magnitude == 0 ? @"等級未記載"
                : [NSString stringWithFormat:@"%@ 等級 %.2f", object.is_photographic_magnitude ? @"写真" : @"V", object.magnitude];
            description = [NSString stringWithFormat:@"%@ %d\n赤経 %.3f° / 赤緯 %+.3f°\n%@ / 視直径 %.2f′",
                object.is_ngc ? @"NGC" : @"IC", object.number, coordinates.right_ascension_deg,
                coordinates.declination_deg, magnitude, object.angular_size_arcminutes];
        } else {
            const auto& object = kind == SkyCatalogKind::galaxy ? _catalogs->galaxies[index] : _catalogs->quasars[index];
            description = [NSString stringWithFormat:@"SDSS %@ #%lu\n赤経 %.3f° / 赤緯 %+.3f°\n原典距離 %.6g pc / %@ %.4g",
                kind == SkyCatalogKind::galaxy ? @"銀河" : @"クエーサー", static_cast<unsigned long>(index + 1),
                coordinates.right_ascension_deg, coordinates.declination_deg, object.distance_parsecs,
                kind == SkyCatalogKind::galaxy ? @"eClass" : @"z", object.classification_value];
        }
    } else if (_selection && _model) {
        if (_selection->kind == ObjectKind::star) {
            const auto& star = _model->stars()[_selection->index];
            description = [NSString stringWithFormat:@"HIP %d\n赤経 %.3f° / 赤緯 %+.3f°\nV 等級 %.2f", star.hip,
                star.right_ascension_degrees, star.declination_degrees, star.apparent_v_magnitude];
        } else {
            const auto& body = _bodies[_selection->index];
            description = [NSString stringWithFormat:@"%@\n赤経 %.3f° / 赤緯 %+.3f°\n地心距離 %.6f AU", bodyName(body.id),
                body.coordinates.right_ascension_deg, body.coordinates.declination_deg, body.distance_au];
        }
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
    if (_dragging) [self setViewport:pan_sky(_viewport, point.x - _lastDragPoint.x,
        point.y - _lastDragPoint.y, map.size.width, map.size.height)];
    _lastDragPoint = point;
}
- (void)mouseUp:(NSEvent *)event {
    if (!_model || _dragging) return;
    const NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    _selection = pick_object(*_model, _bodies, _viewport, map.size.width, map.size.height,
                            point.x - map.origin.x, point.y - map.origin.y, _magnitudeLimit, 8,
                            _starDisplayOptions.visible, _planetDisplayOptions.visible);
    _catalogSelection.reset();
    [self notifySelection];
    self.needsDisplay = YES;
    if (event.clickCount == 2) [self focusSelection];
}
- (void)scrollWheel:(NSEvent *)event {
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    if (event.hasPreciseScrollingDeltas)
        [self setViewport:pan_sky(_viewport, event.scrollingDeltaX, event.scrollingDeltaY,
                                 map.size.width, map.size.height)];
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

- (void)drawConstellations:(CGContextRef)context inRect:(NSRect)map {
    if (_constellationArt) draw_sky_constellation_art(context, *_constellationArt,
        _constellationDisplayOptions, _rendererDisplayOptions, _viewport, map);
    draw_sky_constellations(context, *_model, _constellationDisplayOptions, _rendererDisplayOptions, _viewport, map);
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

- (void)drawSkyBackgroundInRect:(NSRect)map {
    const auto* texture = _backgrounds ? _backgrounds->image(_milkyWayMode) : nullptr;
    if (!texture) return;
    if (!_backgroundImage || !NSEqualSizes(map.size, _backgroundSize)) {
        // 表示範囲・画像・モード・寸法が同じなら時刻再生中も計算済み背景を使う。
        const double scale = std::min(1.0, 1024 / std::max(map.size.width, map.size.height));
        const auto width = static_cast<std::size_t>(std::clamp(std::ceil(map.size.width * scale), 1.0, 1024.0));
        const auto height = static_cast<std::size_t>(std::clamp(std::ceil(map.size.height * scale), 1.0, 1024.0));
        const auto pixels = render_sky_background(*texture, _viewport, width, height);
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
        _backgroundSize = map.size;
    }
    [_backgroundImage drawInRect:map fromRect:NSZeroRect operation:NSCompositingOperationPlusLighter
        fraction:1 respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
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
    draw_sky_grids(context, map, _viewport, _gridDisplayOptions, _gridCache, false, _rendererDisplayOptions);
    drawText([NSString stringWithFormat:@"J2000 赤道座標  ·  %.1f×  ·  ドラッグで移動 / ホイール・ピンチで拡大", _viewport.zoom],
             NSMakePoint(map.origin.x, 10), NSColor.secondaryLabelColor, 11, _rendererDisplayOptions);
    if (!_model) {
        drawText(@"「データを開く」で hip.dat と cf96.dat のあるフォルダを選択", NSMakePoint(map.origin.x + 20, NSMidY(map)), NSColor.labelColor, 13, _rendererDisplayOptions);
        return;
    }
    RendererQualityScope clipped(context, _rendererDisplayOptions);
    CGContextClipToRect(context, map);
    [_catalogRenderer drawInRect:map viewport:_viewport magnitudeLimit:_magnitudeLimit options:_catalogDisplay quality:_rendererDisplayOptions];
    [self drawConstellations:context inRect:map];
    [_starRenderer drawInRect:map magnitudeLimit:_magnitudeLimit options:_starDisplayOptions quality:_rendererDisplayOptions
        projector:[&](mitaka::EquatorialCoordinates coordinates) -> std::optional<StarProjection> {
            const auto point = project_sky(coordinates, _viewport, map.size.width, map.size.height);
            return point ? std::optional<StarProjection>{{*point, 1}} : std::nullopt;
        }];
    NSMutableArray<NSValue *> *labels = [NSMutableArray array];
    for (const auto& body : _bodies) {
        if (!_planetDisplayOptions.visible) break;
        const auto point = project_sky(body.coordinates, _viewport, map.size.width, map.size.height);
        if (!point) continue;
        const NSPoint center = NSMakePoint(map.origin.x + point->x, map.origin.y + point->y);
        NSColor *color = bodyColor(body.id);
        RendererQualityScope points(context, _rendererDisplayOptions, RendererPrimitive::point);
        [color setFill];
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(center.x - 4, center.y - 4, 8, 8)] fill];
        if (!_planetDisplayOptions.labels) continue;
        NSRect label = NSMakeRect(std::clamp(center.x + 8, map.origin.x, NSMaxX(map) - 50), center.y - 17, 48, 17);
        // 近接する惑星名をずらし、元の天体位置へ引き出し線を付ける。
        for (NSUInteger attempt = 0; attempt < _bodies.size(); ++attempt) {
            bool overlap = false;
            for (NSValue *used in labels) if (NSIntersectsRect(label, used.rectValue)) overlap = true;
            if (!overlap) break;
            label.origin.y += 18;
        }
        label.origin.y = std::clamp(label.origin.y, map.origin.y, NSMaxY(map) - 17);
        [labels addObject:[NSValue valueWithRect:label]];
        RendererQualityScope lines(context, _rendererDisplayOptions, RendererPrimitive::line);
        [color setStroke];
        NSBezierPath *leader = [NSBezierPath bezierPath];
        [leader moveToPoint:center];
        [leader lineToPoint:NSMakePoint(label.origin.x, NSMidY(label))];
        leader.lineWidth = 0.6;
        [leader stroke];
        drawText(bodyName(body.id), label.origin, color, 12, _rendererDisplayOptions);
    }
    const auto coordinates = [self selectedCoordinates];
    if (coordinates && (!_selection || (_selection->kind == ObjectKind::star
        ? _starDisplayOptions.visible : _planetDisplayOptions.visible))) {
        const auto point = project_sky(*coordinates, _viewport, map.size.width, map.size.height);
        if (point) {
            RendererQualityScope lines(context, _rendererDisplayOptions, RendererPrimitive::line);
            [NSColor.whiteColor setStroke];
            NSBezierPath *ring = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(map.origin.x + point->x - 9, map.origin.y + point->y - 9, 18, 18)];
            ring.lineWidth = 1;
            [ring stroke];
        }
    }
}
@end
