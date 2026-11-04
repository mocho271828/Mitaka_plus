#import "WindowPresentationController.h"
#include <chrono>
#include <iostream>
#include <stdexcept>

@interface PresentationTestWindow : NSWindow
@property(nonatomic) BOOL actualFullScreen, testHidden, testMiniaturized;
@property(nonatomic) NSUInteger toggleCount;
@end
@implementation PresentationTestWindow
- (NSWindowStyleMask)styleMask {
    return ([super styleMask] & ~NSWindowStyleMaskFullScreen) |
        (_actualFullScreen ? NSWindowStyleMaskFullScreen : 0);
}
- (BOOL)isVisible { return !_testHidden; }
- (BOOL)isMiniaturized { return _testMiniaturized; }
- (void)toggleFullScreen:(id)sender { (void)sender; ++_toggleCount; }
@end

@interface PresentationTestBundle : NSBundle
@end
@implementation PresentationTestBundle
- (NSURL *)URLForResource:(NSString *)name withExtension:(NSString *)extension {
    return [[NSURL fileURLWithPath:@"/test/Resources" isDirectory:YES]
        URLByAppendingPathComponent:[name stringByAppendingPathExtension:extension]];
}
@end

namespace {
int checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
NSWindow *window(Class windowClass) {
    NSWindow *result = [[windowClass alloc] initWithContentRect:NSMakeRect(100, 100, 640, 480)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    result.releasedWhenClosed = NO;
    result.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
    return result;
}
NSNotification *notice(NSString *name, NSWindow *window) {
    return [NSNotification notificationWithName:name object:window];
}
void test_state_machine() {
    PresentationTestWindow *main = (PresentationTestWindow *)window(PresentationTestWindow.class);
    NSWindow *other = window(NSWindow.class);
    WindowPresentationController *controller = [[WindowPresentationController alloc] initWithWindow:main];
    NSString *error = @"old error";
    check(!controller.fullScreen && !controller.transitioning, "initial state is not windowed");
    check([controller requestFullScreen:NO error:&error] && !error && !main.toggleCount,
        "same-state request toggled the window");
    main.testHidden = YES;
    check(![controller requestFullScreen:YES error:&error] && error && !controller.transitioning,
        "hidden window accepted fullscreen");
    main.testHidden = NO;
    main.testMiniaturized = YES;
    check(![controller requestFullScreen:YES error:&error] && error, "miniaturized window accepted fullscreen");
    main.testMiniaturized = NO;
    check([controller requestFullScreen:YES error:&error] && !error && main.toggleCount == 1,
        "fullscreen request was not accepted once");
    check(controller.transitioning && !controller.fullScreen,
        "accepted request was incorrectly reported as completed");
    check([controller requestFullScreen:YES error:&error] && main.toggleCount == 1,
        "same pending request was not idempotent");
    check(![controller requestFullScreen:NO error:&error] && error && main.toggleCount == 1,
        "opposite pending request was accepted");
    check(![controller toggleFullScreenWithError:&error] && error && main.toggleCount == 1,
        "toggle was queued during a transition");
    [controller windowDidEnterFullScreen:notice(NSWindowDidEnterFullScreenNotification, other)];
    [controller windowDidFailToEnterFullScreen:other];
    check(controller.transitioning && !controller.lastTransitionError,
        "another window completed or failed the main transition");
    [controller windowWillEnterFullScreen:notice(NSWindowWillEnterFullScreenNotification, main)];
    main.actualFullScreen = YES;
    check(controller.fullScreen && controller.transitioning,
        "fullscreen getter did not follow actual style during transition");
    [controller windowDidEnterFullScreen:notice(NSWindowDidEnterFullScreenNotification, main)];
    check(controller.fullScreen && !controller.transitioning, "enter completion was not recorded");
    check([controller requestFullScreen:YES error:&error] && main.toggleCount == 1,
        "completed same-state request toggled");
    check([controller toggleFullScreenWithError:&error] && !error && main.toggleCount == 2,
        "fullscreen exit was not accepted");
    check(controller.fullScreen && controller.transitioning, "exit acceptance changed actual getter");
    check([controller requestFullScreen:NO error:&error] && main.toggleCount == 2,
        "same pending exit was not idempotent");
    check(![controller requestFullScreen:YES error:&error] && error, "opposite pending exit was accepted");
    [controller windowDidFailToExitFullScreen:main];
    check(!controller.transitioning && controller.fullScreen && controller.lastTransitionError,
        "exit failure corrupted actual state or remained pending");
    check([controller requestFullScreen:NO error:&error] && !controller.lastTransitionError,
        "retry after failure was rejected");
    [controller windowWillExitFullScreen:notice(NSWindowWillExitFullScreenNotification, main)];
    main.actualFullScreen = NO;
    [controller windowDidExitFullScreen:notice(NSWindowDidExitFullScreenNotification, main)];
    check(!controller.fullScreen && !controller.transitioning, "exit completion was not recorded");
    [controller windowWillEnterFullScreen:notice(NSWindowWillEnterFullScreenNotification, main)];
    check(controller.transitioning && !controller.fullScreen, "native window button transition was ignored");
    [controller windowDidFailToEnterFullScreen:main];
    check(!controller.transitioning && !controller.fullScreen && controller.lastTransitionError,
        "entry failure corrupted state or remained pending");
    [controller windowWillEnterFullScreen:notice(NSWindowWillEnterFullScreenNotification, other)];
    [controller windowWillExitFullScreen:notice(NSWindowWillExitFullScreenNotification, other)];
    check(!controller.transitioning, "another window started the main transition");
    check([controller requestFullScreen:YES error:nil], "final request failed");
    [NSNotificationCenter.defaultCenter postNotificationName:NSWindowWillCloseNotification object:other];
    check(controller.transitioning, "another window close cancelled transition");
    [NSNotificationCenter.defaultCenter postNotificationName:NSWindowWillCloseNotification object:main];
    check(!controller.transitioning && ![controller requestFullScreen:YES error:&error] && error,
        "closed window accepted another request");
    [controller windowWillEnterFullScreen:notice(NSWindowWillEnterFullScreenNotification, main)];
    [controller windowDidFailToEnterFullScreen:main];
    [controller windowDidFailToExitFullScreen:main];
    check(!controller.transitioning && !controller.lastTransitionError,
        "late notification reopened the closed state or reported a failure");
    [main close];
    [other close];
}

void test_about_options() {
    NSDictionary *options = [WindowPresentationController aboutPanelOptionsForBundle:[[PresentationTestBundle alloc] init]];
    NSAttributedString *credits = options[NSAboutPanelOptionCredits];
    check(credits.length && [credits.string containsString:@"非公式"], "About does not identify this unofficial app");
    check(!options[NSAboutPanelOptionApplicationName] && !options[NSAboutPanelOptionVersion] &&
        !options[NSAboutPanelOptionApplicationVersion], "About duplicates bundle identity or version");
    const NSRange noticeRange = [credits.string rangeOfString:@"第三者の著作権・ライセンス"];
    const NSRange luaRange = [credits.string rangeOfString:@"Lua ライセンス"];
    check(noticeRange.location != NSNotFound && luaRange.location != NSNotFound, "About license links missing");
    NSURL *noticeURL = [credits attribute:NSLinkAttributeName atIndex:noticeRange.location effectiveRange:nil];
    NSURL *luaURL = [credits attribute:NSLinkAttributeName atIndex:luaRange.location effectiveRange:nil];
    check([noticeURL.lastPathComponent isEqualToString:@"THIRD_PARTY_NOTICES.txt"] &&
        [luaURL.lastPathComponent isEqualToString:@"LUA_LICENSE.txt"], "About links do not use bundled licenses");
}

template <typename Predicate> bool wait_until(Predicate condition, double timeout = 12) {
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::duration<double>(timeout);
    while (!condition() && std::chrono::steady_clock::now() < deadline) {
        @autoreleasepool {
            NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:NSDate.distantPast
                inMode:NSDefaultRunLoopMode dequeue:YES];
            if (event) [NSApp sendEvent:event];
            [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
    }
    return condition();
}
void test_system_fullscreen() {
    NSWindow *main = window(NSWindow.class);
    WindowPresentationController *controller = [[WindowPresentationController alloc] initWithWindow:main];
    main.delegate = controller;
    main.title = @"Mitaka fullscreen system test";
    [main makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    check(wait_until([&] { return main.visible && NSApp.active; }), "test window did not become active");
    NSString *error = nil;
    check([controller requestFullScreen:YES error:&error] && !error, "system entry request rejected");
    check(wait_until([&] { return !controller.transitioning; }) && controller.fullScreen &&
        !controller.lastTransitionError, "system did not finish entering fullscreen");
    check([controller requestFullScreen:NO error:&error] && !error, "system exit request rejected");
    check(wait_until([&] { return !controller.transitioning; }) && !controller.fullScreen &&
        !controller.lastTransitionError, "system did not finish exiting fullscreen");
    [main close];
}
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        try {
            const bool system = argc == 2 && std::string(argv[1]) == "--system-fullscreen";
            if (argc != 1 && !system) throw std::runtime_error("usage: test_window_presentation [--system-fullscreen]");
            [NSApplication sharedApplication];
            [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
            if (system) test_system_fullscreen();
            else { test_state_machine(); test_about_options(); }
            std::cout << "WindowPresentationController tests passed (" << (system ? "system fullscreen" : "controlled transition")
                      << "): " << checks << " checks\n";
        } catch (const std::exception& error) {
            std::cerr << "WindowPresentationController test failed: " << error.what() << '\n';
            return 1;
        }
    }
    return 0;
}
