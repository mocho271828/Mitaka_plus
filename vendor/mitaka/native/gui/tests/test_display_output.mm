#import "DisplayOutputController.h"

#include <chrono>
#include <iostream>
#include <limits>
#include <stdexcept>

@interface OutputTestView : NSView
@property(nonatomic) NSUInteger captures;
@end
@implementation OutputTestView
- (void)drawRect:(NSRect)dirtyRect {
    [NSColor.blueColor setFill];
    NSRectFill(dirtyRect);
}
- (void)cacheDisplayInRect:(NSRect)rect toBitmapImageRep:(NSBitmapImageRep *)representation {
    ++_captures;
    [super cacheDisplayInRect:rect toBitmapImageRep:representation];
}
@end

// WindowServer の通知生成と、通知を受けたコントローラの停止・再開を別々に検証する。
@interface DisplayOutputController (WindowFactory)
- (NSWindow *)makeProjectionWindowWithContentRect:(NSRect)rect styleMask:(NSWindowStyleMask)style;
@end

@interface ControlledProjectionWindow : NSWindow
@property(nonatomic) BOOL testOccluded;
@end
@implementation ControlledProjectionWindow
- (NSWindowOcclusionState)occlusionState {
    return _testOccluded ? static_cast<NSWindowOcclusionState>(0) : NSWindowOcclusionStateVisible;
}
- (void)setTestOccluded:(BOOL)value {
    _testOccluded = value;
    [NSNotificationCenter.defaultCenter postNotificationName:NSWindowDidChangeOcclusionStateNotification object:self];
}
@end

@interface ControlledDisplayOutputController : DisplayOutputController
@end
@implementation ControlledDisplayOutputController
- (NSWindow *)makeProjectionWindowWithContentRect:(NSRect)rect styleMask:(NSWindowStyleMask)style {
    return [[ControlledProjectionWindow alloc] initWithContentRect:rect styleMask:style
        backing:NSBackingStoreBuffered defer:NO];
}
@end

@interface OutputCoverView : NSView
@property(nonatomic) BOOL didDraw;
@end
@implementation OutputCoverView
- (BOOL)isOpaque { return YES; }
- (void)drawRect:(NSRect)dirtyRect {
    [NSColor.blackColor setFill];
    NSRectFill(dirtyRect);
    _didDraw = YES;
}
@end

namespace {
int checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}

template <typename Predicate> bool wait_until(Predicate condition, double timeout = 2) {
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::duration<double>(timeout);
    while (!condition() && std::chrono::steady_clock::now() < deadline) {
        @autoreleasepool {
            NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:NSDate.distantPast
                inMode:NSDefaultRunLoopMode dequeue:YES];
            if (event) [NSApp sendEvent:event];
            [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode
                beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
    }
    return condition();
}

void expect_quiet(OutputTestView *source) {
    const NSUInteger captures = source.captures;
    wait_until([] { return false; }, 0.25);
    check(source.captures == captures, "inactive projection continued capturing");
}

void show_unoccluded(NSWindow *window) {
    [window orderFrontRegardless];
    if ([window isKindOfClass:ControlledProjectionWindow.class])
        [(ControlledProjectionWindow *)window setTestOccluded:NO];
    const bool unoccluded = wait_until([&] {
        return window.visible && !window.miniaturized &&
            (window.occlusionState & NSWindowOcclusionStateVisible);
    });
    if (!unoccluded)
        std::cerr << "Visibility state: appActive=" << NSApp.active
                  << ", visible=" << window.visible << ", miniaturized=" << window.miniaturized
                  << ", occlusion=" << window.occlusionState << '\n';
    check(unoccluded, "test projection did not become unoccluded");
}

void expect_refresh(OutputTestView *source, NSWindow *window, NSUInteger captures, const char *message) {
    const bool refreshed = wait_until([&] { return source.captures > captures; });
    if (!refreshed)
        std::cerr << "Projection state: visible=" << window.visible
                  << ", miniaturized=" << window.miniaturized
                  << ", occlusion=" << window.occlusionState << '\n';
    check(refreshed, message);
}

void test_capture_and_validation() {
    DisplayOutputController *controller = [[DisplayOutputController alloc] init];
    NSError *error = nil;
    check(![controller captureFormat:DisplayImageFormatPNG error:&error] && error,
          "missing capture source was accepted");
    OutputTestView *source = [[OutputTestView alloc] initWithFrame:NSMakeRect(0, 0, 64, 48)];
    controller.sourceView = source;
    for (DisplayImageFormat format : {DisplayImageFormatPNG, DisplayImageFormatJPEG, DisplayImageFormatBMP}) {
        NSData *data = [controller captureFormat:format error:&error];
        check(data.length && !error, "native image encoding failed");
        NSBitmapImageRep *decoded = [[NSBitmapImageRep alloc] initWithData:data];
        check(decoded.pixelsWide > 0 && decoded.pixelsHigh > 0, "encoded image did not decode");
    }
    check(![controller captureFormat:static_cast<DisplayImageFormat>(99) error:&error] && error,
          "unknown image format was accepted");
    source.frame = NSZeroRect;
    check(![controller captureFormat:DisplayImageFormatPNG error:&error] && error,
          "empty view was accepted");
    source.frame = NSMakeRect(0, 0, 20000, 20000);
    check(![controller captureFormat:DisplayImageFormatPNG error:&error] && error,
          "unbounded capture allocation was accepted");
    for (double opacity : {-0.1, 1.1, std::numeric_limits<double>::infinity(),
                           std::numeric_limits<double>::quiet_NaN()}) {
        bool rejected = false;
        try { controller.fadeOpacity = opacity; }
        catch (const std::invalid_argument&) { rejected = true; }
        check(rejected && controller.fadeOpacity == 0, "invalid fade changed projection state");
    }
    controller.fadeOpacity = 1;
    controller.pointerVisible = YES;
    check(controller.fadeOpacity == 1 && controller.pointerVisible, "projection settings were not retained");
    [controller invalidate];
    check(!controller.sourceView && ![controller captureFormat:DisplayImageFormatPNG error:nil],
          "invalidated output retained the capture source");
    [controller showProjection];
    check(!controller.projectionVisible, "invalidated projection reopened");
}

void test_projection_lifecycle(bool systemOcclusion) {
    NSWindow *sourceWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 128, 96)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    sourceWindow.releasedWhenClosed = NO;
    OutputTestView *source = [[OutputTestView alloc] initWithFrame:sourceWindow.contentView.bounds];
    sourceWindow.contentView = source;
    NSView *originalSuperview = source.superview;
    DisplayOutputController *controller = systemOcclusion ? [[DisplayOutputController alloc] init] :
        [[ControlledDisplayOutputController alloc] init];
    controller.sourceView = source;
    [controller showProjection];
    check(controller.projectionVisible && source.captures > 0, "projection did not capture its initial image");
    check(source.window == sourceWindow && source.superview == originalSuperview,
          "projection moved the source view");
    NSWindow *projection = nil;
    for (NSWindow *window in NSApp.windows)
        if (window.delegate == controller) projection = window;
    check(projection && projection != sourceWindow, "independent projection window was not created");
    check([projection isKindOfClass:ControlledProjectionWindow.class] != systemOcclusion,
          "projection window did not use the selected test mode");
    // 他のGUI試験の通常ウィンドウに覆われると、仕様どおり更新が止まるため表示条件を固定する。
    projection.level = NSFloatingWindowLevel;
    show_unoccluded(projection);
    const NSUInteger initialCaptures = source.captures;
    expect_refresh(source, projection, initialCaptures, "visible projection did not refresh");

    [NSWorkspace.sharedWorkspace.notificationCenter postNotificationName:NSWorkspaceWillSleepNotification object:nil];
    expect_quiet(source);
    show_unoccluded(projection);
    const NSUInteger wakeCaptures = source.captures;
    [NSWorkspace.sharedWorkspace.notificationCenter postNotificationName:NSWorkspaceDidWakeNotification object:nil];
    expect_refresh(source, projection, wakeCaptures, "projection did not resume after wake");

    NSWindow *cover = nil;
    if (systemOcclusion) {
        // 枠・影・Retina の丸めを避け、明示的な不透明描画が完了してから OS 通知を待つ。
        cover = [[NSWindow alloc] initWithContentRect:NSInsetRect(projection.frame, -64, -64)
            styleMask:NSWindowStyleMaskBorderless backing:NSBackingStoreBuffered defer:NO];
        cover.releasedWhenClosed = NO;
        cover.level = projection.level + 1;
        cover.opaque = YES;
        cover.hasShadow = NO;
        cover.animationBehavior = NSWindowAnimationBehaviorNone;
        cover.backgroundColor = NSColor.blackColor;
        OutputCoverView *coverView = [[OutputCoverView alloc] initWithFrame:cover.contentView.bounds];
        cover.contentView = coverView;
        [cover orderFrontRegardless];
        [cover display];
        check(wait_until([&] { return coverView.didDraw; }), "system occlusion cover did not draw");
        check(NSContainsRect(cover.frame, projection.frame), "system occlusion cover did not contain projection");
    } else {
        [(ControlledProjectionWindow *)projection setTestOccluded:YES];
    }
    const bool occluded = wait_until([&] {
        return projection.visible && !(projection.occlusionState & NSWindowOcclusionStateVisible);
    }, 5);
    if (!occluded)
        std::cerr << "System occlusion unavailable: projection=" << NSStringFromRect(projection.frame).UTF8String
                  << ", cover=" << NSStringFromRect(cover.frame).UTF8String
                  << ", backingScale=" << projection.backingScaleFactor
                  << ", occlusion=" << projection.occlusionState << '\n';
    check(occluded, "test projection did not become occluded");
    expect_quiet(source);
    [NSWorkspace.sharedWorkspace.notificationCenter postNotificationName:NSWorkspaceWillSleepNotification object:nil];
    [NSWorkspace.sharedWorkspace.notificationCenter postNotificationName:NSWorkspaceDidWakeNotification object:nil];
    expect_quiet(source);
    const NSUInteger occludedWakeCaptures = source.captures;
    [cover close];
    show_unoccluded(projection);
    expect_refresh(source, projection, occludedWakeCaptures, "occluded wake did not resume after uncovering");

    [NSWorkspace.sharedWorkspace.notificationCenter postNotificationName:NSWorkspaceWillSleepNotification object:nil];
    [projection orderOut:nil];
    check(wait_until([&] { return !controller.projectionVisible; }), "sleeping projection did not hide");
    [NSWorkspace.sharedWorkspace.notificationCenter postNotificationName:NSWorkspaceDidWakeNotification object:nil];
    expect_quiet(source);
    const NSUInteger hiddenWakeCaptures = source.captures;
    // showProjection の明示的な更新を通さず、可視性通知だけでタイマーが再開することを確認する。
    show_unoccluded(projection);
    expect_refresh(source, projection, hiddenWakeCaptures, "hidden wake did not resume when projection became visible");

    [projection orderOut:nil];
    check(wait_until([&] { return !controller.projectionVisible; }), "projection did not hide");
    expect_quiet(source);
    [controller showProjection];
    check(controller.projectionVisible, "hidden projection did not reopen");
    [controller closeProjection];
    check(!controller.projectionVisible && source.window == sourceWindow, "closing projection affected source window");
    expect_quiet(source);
    [controller showProjection];
    check(controller.projectionVisible, "closed projection did not reopen");
    [controller invalidate];
    check(!controller.projectionVisible && !controller.sourceView, "invalidate left projection active");
    expect_quiet(source);
    [sourceWindow close];
}

void test_weak_source_and_release() {
    DisplayOutputController *controller = [[DisplayOutputController alloc] init];
    @autoreleasepool {
        NSView *source = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)];
        controller.sourceView = source;
    }
    check(!controller.sourceView, "output controller retained its source view");
    [controller invalidate];
    __weak DisplayOutputController *weakController;
    @autoreleasepool {
        DisplayOutputController *temporary = [[DisplayOutputController alloc] init];
        [temporary showProjection];
        weakController = temporary;
    }
    check(!weakController, "projection window or observers retained controller");
}
}

int main() {
    @autoreleasepool {
        try {
            [NSApplication sharedApplication];
            [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
            [NSApp finishLaunching];
            [NSApp activateIgnoringOtherApps:YES];
            NSArray<NSString *> *arguments = NSProcessInfo.processInfo.arguments;
            const bool systemOcclusion = arguments.count == 2 && [arguments[1] isEqualToString:@"--system-occlusion"];
            check(arguments.count == 1 || systemOcclusion, "usage: test_display_output [--system-occlusion]");
            test_capture_and_validation();
            test_projection_lifecycle(systemOcclusion);
            test_weak_source_and_release();
            std::cout << "DisplayOutputController tests passed ("
                      << (systemOcclusion ? "system occlusion" : "controlled occlusion")
                      << "): " << checks << " checks\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "DisplayOutputController test failed: " << error.what() << '\n';
            return 1;
        }
    }
}
