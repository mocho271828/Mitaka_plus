#import "GalaxyView.h"
#include "RendererQuality.h"
#include <atomic>
#include <cmath>

using namespace mitaka::gui;
namespace {
bool sameVector(mitaka::Vec3 a, mitaka::Vec3 b) {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}
bool sameCamera(const GalaxyCameraPc& a, const GalaxyCameraPc& b) {
    return a.target.x_pc == b.target.x_pc && a.target.y_pc == b.target.y_pc && a.target.z_pc == b.target.z_pc &&
        sameVector(a.target_offset_au, b.target_offset_au) &&
        a.yaw_deg == b.yaw_deg && a.pitch_deg == b.pitch_deg && a.distance_pc == b.distance_pc && a.roll_deg == b.roll_deg && a.frame_is_orbit == b.frame_is_orbit &&
        a.frame.has_value() == b.frame.has_value() &&
        (!a.frame || (sameVector(a.frame->outward, b.frame->outward) &&
                       sameVector(a.frame->right, b.frame->right) && sameVector(a.frame->up, b.frame->up)));
}
NSString *errorText(const std::exception& error) {
    NSString *text = [NSString stringWithUTF8String:error.what()];
    return text ? text : @"銀河表示に失敗しました";
}
}
@implementation GalaxyView {
    GalaxySpatialScene _scene;
    GalaxyCameraPc _camera;
    GalaxySpatialVisibility _visibility;
    RendererDisplayOptions _quality;
    std::shared_ptr<std::atomic<std::uint64_t>> _generation, _pickGeneration;
    dispatch_queue_t _queue;
    NSImage *_image;
    NSString *_renderStatus;
    BOOL _renderStarted, _dragged;
    NSPoint _lastMouse;
}
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _generation = std::make_shared<std::atomic<std::uint64_t>>(0);
        _pickGeneration = std::make_shared<std::atomic<std::uint64_t>>(0);
        _queue = dispatch_queue_create("org.mitaka.galaxy-render", DISPATCH_QUEUE_SERIAL);
        _renderStatus = @"データ未読込";
        self.accessibilityIdentifier = @"galaxy-view";
        self.accessibilityLabel = @"銀河の3D表示。ドラッグで回転、Optionドラッグでロール、Shiftドラッグで平行移動、スクロールで拡大縮小。";
    }
    return self;
}
- (void)dealloc {
    if (_generation) _generation->fetch_add(1, std::memory_order_relaxed);
    if (_pickGeneration) _pickGeneration->fetch_add(1, std::memory_order_relaxed);
    [NSNotificationCenter.defaultCenter removeObserver:self];
}
- (BOOL)isFlipped { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)isOpaque { return YES; }
- (void)changed { self.needsDisplay = YES; if (self.stateChanged) self.stateChanged(); }
- (void)invalidateImage {
    [self invalidatePendingWork];
    _image = nil; _renderStarted = NO;
    _renderStatus = _scene.model() ? @"全原行を描画待ち" : @"データ未読込";
    [self changed];
}
- (void)invalidatePendingWork {
    _generation->fetch_add(1, std::memory_order_relaxed);
    _pickGeneration->fetch_add(1, std::memory_order_relaxed);
    _renderStarted = _image != nil;
}
- (void)setModel:(std::shared_ptr<const GalaxySpatialModel>)model {
    if (_scene.model() == model) return;
    _scene.set_model(std::move(model));
    [self invalidateImage];
}
- (std::shared_ptr<const GalaxySpatialModel>)model { return _scene.model(); }
- (GalaxyCameraPc)galaxyCamera { return _camera; }
- (void)setGalaxyCamera:(GalaxyCameraPc)camera {
    camera = checked_galaxy_camera(camera);
    if (sameCamera(camera, _camera)) return;
    _camera = camera;
    [self invalidateImage];
}
- (GalaxySpatialVisibility)galaxyVisibility { return _visibility; }
- (void)setGalaxyVisibility:(GalaxySpatialVisibility)visibility {
    if (_visibility.sdss_galaxies == visibility.sdss_galaxies && _visibility.sdss_quasars == visibility.sdss_quasars &&
        _visibility.globular_clusters == visibility.globular_clusters && _visibility.nearby_galaxies == visibility.nearby_galaxies) return;
    _visibility = visibility;
    [self invalidateImage];
}
- (void)setRendererDisplayOptions:(RendererDisplayOptions)options {
    if (_quality.antialias == options.antialias && _quality.point_smoothing == options.point_smoothing &&
        _quality.line_smoothing == options.line_smoothing && _quality.text_smoothing == options.text_smoothing) return;
    _quality = options;
    [self invalidateImage];
}
- (std::optional<GalaxySpatialRecordId>)selectedRecord { return _scene.selection(); }
- (void)selectRecord:(std::optional<GalaxySpatialRecordId>)record {
    _scene.select(record);
    _pickGeneration->fetch_add(1, std::memory_order_relaxed);
    [self changed];
}
- (BOOL)focusSelection {
    auto next = _camera;
    if (!_scene.focus_selection(next)) return NO;
    [self setGalaxyCamera:next];
    return YES;
}
- (NSString *)renderStatus { return _renderStatus; }
- (void)setFrameSize:(NSSize)size {
    const BOOL changed = !NSEqualSizes(size, self.frame.size);
    [super setFrameSize:size];
    if (changed && _generation) [self invalidateImage];
}
- (void)setBoundsSize:(NSSize)size {
    const BOOL changed = !NSEqualSizes(size, self.bounds.size);
    [super setBoundsSize:size];
    if (changed && _generation) [self invalidateImage];
}
- (void)setBoundsOrigin:(NSPoint)origin {
    const BOOL changed = !NSEqualPoints(origin, self.bounds.origin);
    [super setBoundsOrigin:origin];
    // 画像自体は左上原点のまま使えるが、移動前の click 座標は採用できない。
    if (changed && _pickGeneration) _pickGeneration->fetch_add(1, std::memory_order_relaxed);
    if (changed) self.needsDisplay = YES;
}
- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    if (_generation && hidden) [self invalidatePendingWork];
    else self.needsDisplay = YES;
}
- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    if (self.window) {
        for (NSNotificationName name in @[NSWindowDidChangeOcclusionStateNotification,
                NSWindowDidChangeBackingPropertiesNotification, NSWindowWillCloseNotification])
            [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(windowStateChanged:)
                name:name object:self.window];
    }
    [self invalidateImage];
}
- (void)windowStateChanged:(NSNotification *)notification {
    if ([notification.name isEqualToString:NSWindowDidChangeBackingPropertiesNotification]) [self invalidateImage];
    else if ([notification.name isEqualToString:NSWindowWillCloseNotification] ||
             !(self.window.occlusionState & NSWindowOcclusionStateVisible)) [self invalidatePendingWork];
    else self.needsDisplay = YES;
}
- (void)requestImage {
    const NSSize size = self.bounds.size;
    if (_renderStarted || !_scene.model() || !self.window.visible || self.hiddenOrHasHiddenAncestor ||
        !(self.window.occlusionState & NSWindowOcclusionStateVisible) || size.width <= 0 || size.height <= 0) return;
    _renderStarted = YES;
    const auto model = _scene.model();
    const auto camera = _camera; const auto visibility = _visibility; const auto quality = _quality;
    const auto generation = _generation;
    const auto expected = generation->load(std::memory_order_relaxed);
    const double scale = self.window.backingScaleFactor;
    _renderStatus = @"全原行を描画中";
    __weak GalaxyView *weakSelf = self;
    dispatch_async(_queue, ^{
        @autoreleasepool {
            const auto cancelled = [generation, expected] { return generation->load(std::memory_order_relaxed) != expected; };
            if (cancelled()) return;
            std::shared_ptr<const GalaxyBitmap> bitmap;
            NSString *failure = nil;
            try { bitmap = render_galaxy_bitmap(*model, camera, visibility, quality,
                    size.width, size.height, scale, cancelled); }
            catch (const std::exception& error) { failure = errorText(error); }
            if (cancelled()) return;
            dispatch_async(dispatch_get_main_queue(), ^{
                GalaxyView *view = weakSelf;
                if (!view || cancelled()) return;
                if (bitmap) {
                    view->_image = [[NSImage alloc] initWithCGImage:bitmap->image() size:size];
                    const auto counts = bitmap->counts();
                    view->_renderStatus = [NSString stringWithFormat:
                        @"全 %lu 行 · 描画 %lu · 画面外 %lu · 無効位置 %lu · 非表示種別 %lu · 画像 %lu×%lu px",
                        counts.total, counts.drawn, counts.outside, counts.invalid, counts.hidden,
                        CGImageGetWidth(bitmap->image()), CGImageGetHeight(bitmap->image())];
                } else view->_renderStatus = failure ? failure : @"描画を中止しました";
                [view changed];
            });
        }
    });
}
- (void)drawRect:(NSRect)dirty {
    (void)dirty;
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    if (!context) return;
    RendererQualityScope general(context, _quality);
    [NSBezierPath clipRect:self.bounds];
    [[NSColor colorWithRed:0.015 green:0.02 blue:0.035 alpha:1] setFill]; NSRectFill(self.bounds);
    if (_image) [_image drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositingOperationCopy
        fraction:1 respectFlipped:YES hints:nil];
    const auto selected = _scene.selection();
    if (selected && _scene.model() && self.bounds.size.width > 0 && self.bounds.size.height > 0 &&
        self.bounds.size.width <= 1e7 && self.bounds.size.height <= 1e7 &&
        _visibility.visible(selected->family)) {
        const auto row = _scene.model()->row(*selected);
        if (row.position) {
            const GalaxyProjector projector(_camera, self.bounds.size.width, self.bounds.size.height);
            const auto point = projector.project(*row.position);
            if (point && projector.contains(*point)) {
                RendererQualityScope lines(NSGraphicsContext.currentContext.CGContext, _quality, RendererPrimitive::line);
                [NSColor.whiteColor setStroke];
                NSBezierPath *ring = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(self.bounds.origin.x + point->x - 7, self.bounds.origin.y + point->y - 7, 14, 14)];
                ring.lineWidth = 1.5; [ring stroke];
            }
        }
    }
    [self requestImage];
}
- (void)mouseDown:(NSEvent *)event {
    [self.window makeFirstResponder:self];
    _lastMouse = [self convertPoint:event.locationInWindow fromView:nil]; _dragged = NO;
}
- (void)mouseDragged:(NSEvent *)event {
    const NSPoint next = [self convertPoint:event.locationInWindow fromView:nil];
    const double dx = next.x - _lastMouse.x, dy = next.y - _lastMouse.y;
    _lastMouse = next; _dragged = YES;
    try {
        auto camera = _camera;
        if (event.modifierFlags & NSEventModifierFlagShift) camera.pan(dx, dy, self.bounds.size.width, self.bounds.size.height);
        else if (event.modifierFlags & NSEventModifierFlagOption) camera.roll(dx * 0.35);
        else camera.orbit(dx, dy);
        [self setGalaxyCamera:camera];
    } catch (const std::exception& error) { _renderStatus = errorText(error); [self changed]; }
}
- (void)rotateWithEvent:(NSEvent *)event {
    try { auto camera = _camera; camera.roll(event.rotation); [self setGalaxyCamera:camera]; }
    catch (const std::exception& error) { _renderStatus = errorText(error); [self changed]; }
}
- (void)scrollWheel:(NSEvent *)event {
    try { auto camera = _camera; camera.zoom(event.scrollingDeltaY * 0.02); [self setGalaxyCamera:camera]; }
    catch (const std::exception& error) { _renderStatus = errorText(error); [self changed]; }
}
- (void)mouseUp:(NSEvent *)event {
    if (_dragged || !_scene.model() || !self.window.visible || self.hiddenOrHasHiddenAncestor) return;
    const NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    const NSSize size = self.bounds.size;
    const NSPoint origin = self.bounds.origin;
    if (size.width <= 0 || size.height <= 0) return;
    const auto model = _scene.model(); const auto camera = _camera; const auto visibility = _visibility;
    const auto generation = _generation, picks = _pickGeneration;
    const auto expected = generation->load(std::memory_order_relaxed);
    const auto pick = picks->fetch_add(1, std::memory_order_relaxed) + 1;
    const BOOL focus = event.clickCount > 1;
    __weak GalaxyView *weakSelf = self;
    dispatch_async(_queue, ^{
        const auto cancelled = [generation, expected, picks, pick] {
            return generation->load(std::memory_order_relaxed) != expected || picks->load(std::memory_order_relaxed) != pick;
        };
        if (cancelled()) return;
        std::optional<GalaxySpatialRecordId> selected;
        NSString *failure = nil;
        try {
            const GalaxyProjector projector(camera, size.width, size.height);
            selected = pick_galaxy_spatial_row(*model, projector, visibility, point.x - origin.x, point.y - origin.y, 8, cancelled);
        } catch (const std::exception& error) { failure = errorText(error); }
        if (cancelled()) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            GalaxyView *view = weakSelf;
            if (!view || cancelled()) return;
            if (failure) { view->_renderStatus = failure; [view changed]; return; }
            [view selectRecord:selected];
            if (focus) [view focusSelection];
        });
    });
}
@end
