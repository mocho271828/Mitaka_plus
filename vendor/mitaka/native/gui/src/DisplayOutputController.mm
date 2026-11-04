#import "DisplayOutputController.h"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace {
NSError *outputError(NSString *description) {
    return [NSError errorWithDomain:@"Mitaka.DisplayOutput" code:1
        userInfo:@{NSLocalizedDescriptionKey: description}];
}
}

@interface ProjectionView : NSView
@property(nonatomic, strong) NSImage *image;
@property(nonatomic, copy) NSString *statusMessage;
@property(nonatomic) BOOL pointerVisible;
@property(nonatomic) double fadeOpacity;
@end

@implementation ProjectionView {
    NSTrackingArea *_trackingArea;
    NSPoint _pointerPosition;
    BOOL _hasPointerPosition;
}
- (BOOL)isFlipped { return YES; }
- (BOOL)isOpaque { return YES; }
- (void)updateTrackingAreas {
    if (_trackingArea) [self removeTrackingArea:_trackingArea];
    _trackingArea = [[NSTrackingArea alloc] initWithRect:NSZeroRect
        options:NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect
        owner:self userInfo:nil];
    [self addTrackingArea:_trackingArea];
    [super updateTrackingAreas];
}
- (void)mouseMoved:(NSEvent *)event {
    _pointerPosition = [self convertPoint:event.locationInWindow fromView:nil];
    _hasPointerPosition = YES;
    if (_pointerVisible) self.needsDisplay = YES;
}
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    [NSColor.blackColor setFill];
    NSRectFill(self.bounds);
    if (_image && _image.size.width > 0 && _image.size.height > 0) {
        const CGFloat scale = std::min(self.bounds.size.width / _image.size.width,
                                       self.bounds.size.height / _image.size.height);
        const NSSize size = NSMakeSize(_image.size.width * scale, _image.size.height * scale);
        const NSRect destination = NSMakeRect(NSMidX(self.bounds) - size.width / 2,
            NSMidY(self.bounds) - size.height / 2, size.width, size.height);
        [_image drawInRect:destination fromRect:NSZeroRect operation:NSCompositingOperationSourceOver
            fraction:1 respectFlipped:YES hints:nil];
    }
    if (_statusMessage.length) {
        [_statusMessage drawInRect:NSInsetRect(self.bounds, 20, 20)
            withAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:14],
                             NSForegroundColorAttributeName: NSColor.whiteColor}];
    }
    if (_pointerVisible) {
        const NSPoint point = _hasPointerPosition ? _pointerPosition : NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds));
        [NSColor.yellowColor setStroke];
        NSBezierPath *pointer = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(point.x - 8, point.y - 8, 16, 16)];
        [pointer moveToPoint:NSMakePoint(point.x - 14, point.y)];
        [pointer lineToPoint:NSMakePoint(point.x + 14, point.y)];
        [pointer moveToPoint:NSMakePoint(point.x, point.y - 14)];
        [pointer lineToPoint:NSMakePoint(point.x, point.y + 14)];
        pointer.lineWidth = 1.5;
        [pointer stroke];
    }
    if (_fadeOpacity > 0) {
        [[NSColor.blackColor colorWithAlphaComponent:_fadeOpacity] setFill];
        NSRectFillUsingOperation(self.bounds, NSCompositingOperationSourceOver);
    }
}
@end

@interface DisplayOutputController ()
- (NSWindow *)makeProjectionWindowWithContentRect:(NSRect)rect styleMask:(NSWindowStyleMask)style;
- (NSBitmapImageRep *)snapshotWithError:(NSError **)error;
- (void)refreshSnapshot;
- (void)updateTimer;
- (void)stopTimer;
@end

@implementation DisplayOutputController {
    __weak NSView *_sourceView;
    NSWindow *_projectionWindow;
    ProjectionView *_projectionView;
    NSTimer *_timer;
    BOOL _invalidated, _sleeping, _pointerVisible;
    double _fadeOpacity;
}

- (instancetype)init {
    if ((self = [super init])) {
        NSNotificationCenter *workspace = NSWorkspace.sharedWorkspace.notificationCenter;
        [workspace addObserver:self selector:@selector(willSleep:) name:NSWorkspaceWillSleepNotification object:nil];
        [workspace addObserver:self selector:@selector(didWake:) name:NSWorkspaceDidWakeNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(willTerminate:)
            name:NSApplicationWillTerminateNotification object:nil];
    }
    return self;
}

- (NSView *)sourceView { return _sourceView; }
- (void)setSourceView:(NSView *)view {
    if (_invalidated) return;
    _sourceView = view;
    if (_projectionWindow.visible) [self refreshSnapshot];
    [self updateTimer];
}
- (BOOL)pointerVisible { return _pointerVisible; }
- (void)setPointerVisible:(BOOL)value {
    _pointerVisible = value;
    _projectionView.pointerVisible = value;
    _projectionView.needsDisplay = YES;
}
- (double)fadeOpacity { return _fadeOpacity; }
- (void)setFadeOpacity:(double)value {
    if (!std::isfinite(value) || value < 0 || value > 1)
        throw std::invalid_argument("projection fade opacity must be in [0,1]");
    _fadeOpacity = value;
    _projectionView.fadeOpacity = value;
    _projectionView.needsDisplay = YES;
}
- (BOOL)projectionVisible { return _projectionWindow.visible; }

- (NSBitmapImageRep *)snapshotWithError:(NSError **)error {
    if (error) *error = nil;
    NSView *source = _sourceView;
    if (!NSThread.isMainThread || _invalidated || !source) {
        if (error) *error = outputError(@"画像に保存する表示がありません。");
        return nil;
    }
    [source layoutSubtreeIfNeeded];
    const NSRect bounds = source.bounds;
    const NSRect backing = [source convertRectToBacking:bounds];
    if (!std::isfinite(backing.size.width) || !std::isfinite(backing.size.height) ||
        backing.size.width <= 0 || backing.size.height <= 0 ||
        backing.size.width > 8192 || backing.size.height > 8192 ||
        backing.size.width * backing.size.height > 32 * 1024 * 1024) {
        if (error) *error = outputError(@"表示の画像サイズが有効範囲外です。");
        return nil;
    }
    NSBitmapImageRep *snapshot = [source bitmapImageRepForCachingDisplayInRect:bounds];
    if (!snapshot) {
        if (error) *error = outputError(@"表示の画像を作成できませんでした。");
        return nil;
    }
    [source cacheDisplayInRect:bounds toBitmapImageRep:snapshot];
    return snapshot;
}

- (NSData *)captureFormat:(DisplayImageFormat)format error:(NSError **)error {
    if (error) *error = nil;
    NSBitmapImageFileType type;
    switch (format) {
        case DisplayImageFormatPNG: type = NSBitmapImageFileTypePNG; break;
        case DisplayImageFormatJPEG: type = NSBitmapImageFileTypeJPEG; break;
        case DisplayImageFormatBMP: type = NSBitmapImageFileTypeBMP; break;
        default:
            if (error) *error = outputError(@"対応していない画像形式です。");
            return nil;
    }
    NSBitmapImageRep *snapshot = [self snapshotWithError:error];
    if (!snapshot) return nil;
    NSData *data = [snapshot representationUsingType:type properties:@{NSImageCompressionFactor: @0.95}];
    if (!data && error) *error = outputError(@"指定した形式に画像を変換できませんでした。");
    return data;
}

- (void)refreshSnapshot {
    if (!_projectionView || _invalidated || _sleeping) return;
    NSError *error = nil;
    NSBitmapImageRep *snapshot = [self snapshotWithError:&error];
    if (snapshot) {
        NSImage *image = [[NSImage alloc] initWithSize:_sourceView.bounds.size];
        [image addRepresentation:snapshot];
        _projectionView.image = image;
        _projectionView.statusMessage = @"";
    } else {
        _projectionView.statusMessage = error.localizedDescription;
    }
    _projectionView.needsDisplay = YES;
}

- (void)showProjection {
    if (_invalidated) return;
    if (!_projectionWindow) {
        _projectionWindow = [self makeProjectionWindowWithContentRect:NSMakeRect(0, 0, 1024, 720)
            styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable |
                      NSWindowStyleMaskResizable];
        _projectionWindow.title = @"Mitaka 投影";
        _projectionWindow.releasedWhenClosed = NO;
        _projectionWindow.minSize = NSMakeSize(320, 240);
        _projectionWindow.acceptsMouseMovedEvents = YES;
        _projectionWindow.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
        _projectionWindow.delegate = self;
        _projectionView = [[ProjectionView alloc] initWithFrame:_projectionWindow.contentView.bounds];
        _projectionView.pointerVisible = _pointerVisible;
        _projectionView.fadeOpacity = _fadeOpacity;
        _projectionWindow.contentView = _projectionView;
        [_projectionWindow center];
    }
    [_projectionWindow makeKeyAndOrderFront:nil];
    [self refreshSnapshot];
    [self updateTimer];
}

- (NSWindow *)makeProjectionWindowWithContentRect:(NSRect)rect styleMask:(NSWindowStyleMask)style {
    return [[NSWindow alloc] initWithContentRect:rect styleMask:style backing:NSBackingStoreBuffered defer:NO];
}

- (void)stopTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void)updateTimer {
    const BOOL active = !_invalidated && !_sleeping && _sourceView && _projectionWindow.visible &&
        !_projectionWindow.miniaturized && (_projectionWindow.occlusionState & NSWindowOcclusionStateVisible);
    if (!active) { [self stopTimer]; return; }
    if (_timer) return;
    __weak DisplayOutputController *weakSelf = self;
    _timer = [NSTimer timerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
        (void)timer;
        DisplayOutputController *controller = weakSelf;
        if (!controller) return;
        [controller updateTimer];
        if (controller->_timer) [controller refreshSnapshot];
    }];
    _timer.tolerance = 0.01;
    [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)windowDidChangeOcclusionState:(NSNotification *)notification { (void)notification; [self updateTimer]; }
- (void)windowDidMiniaturize:(NSNotification *)notification { (void)notification; [self stopTimer]; }
- (void)windowDidDeminiaturize:(NSNotification *)notification { (void)notification; [self updateTimer]; }
- (void)windowWillClose:(NSNotification *)notification {
    if (notification.object != _projectionWindow) return;
    [self stopTimer];
    _projectionWindow.delegate = nil;
    _projectionWindow = nil;
    _projectionView = nil;
}
- (void)willSleep:(NSNotification *)notification { (void)notification; _sleeping = YES; [self stopTimer]; }
- (void)didWake:(NSNotification *)notification { (void)notification; _sleeping = NO; [self updateTimer]; }
- (void)willTerminate:(NSNotification *)notification { (void)notification; [self invalidate]; }
- (void)closeProjection { [_projectionWindow close]; }
- (void)invalidate {
    _invalidated = YES;
    [self stopTimer];
    [self closeProjection];
    _sourceView = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self];
}
- (void)dealloc {
    [_timer invalidate];
    _projectionWindow.delegate = nil;
    [_projectionWindow close];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [NSWorkspace.sharedWorkspace.notificationCenter removeObserver:self];
}
@end
