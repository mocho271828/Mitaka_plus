#import "HoverMenuView.h"
#include <cstdio>
#include <stdexcept>

namespace {
int checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
NSButton *menuButton(HoverMenuView *root, NSString *title) {
    for (NSView *bar in root.subviews)
        for (NSView *view in bar.subviews)
            if ([view isKindOfClass:NSButton.class] && [((NSButton *)view).title isEqualToString:title])
                return (NSButton *)view;
    return nil;
}
NSEvent *trackingEvent(NSEventType type) {
    return [NSEvent enterExitEventWithType:type location:NSZeroPoint modifierFlags:0
        timestamp:0 windowNumber:0 context:nil eventNumber:0 trackingNumber:0 userData:nullptr];
}
}

@interface HoverMenuView (Testing)
- (void)presentMenu:(NSMenu *)menu atPoint:(NSPoint)point;
@end

@interface TestHoverMenuView : HoverMenuView
@property(nonatomic, copy) void (^duringMenu)(NSMenu *menu);
@end
@implementation TestHoverMenuView
- (void)presentMenu:(NSMenu *)menu atPoint:(NSPoint)point {
    (void)point;
    self.duringMenu(menu);
}
@end

@interface MenuTarget : NSObject <NSMenuItemValidation>
@property(nonatomic) NSInteger commands;
@property(nonatomic) BOOL commandEnabled;
- (void)execute:(id)sender;
@end
@implementation MenuTarget
- (void)execute:(id)sender { (void)sender; ++_commands; }
- (BOOL)validateMenuItem:(NSMenuItem *)item {
    item.state = self.commandEnabled ? NSControlStateValueOn : NSControlStateValueOff;
    return self.commandEnabled;
}
@end

int main() {
    @autoreleasepool {
        try {
            [NSApplication sharedApplication];
            MenuTarget *target = [[MenuTarget alloc] init];
            NSMenu *menu = [[NSMenu alloc] init];
            for (NSString *title in @[@"App", @"表示", @"時刻"]) {
                NSMenuItem *group = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
                group.submenu = [[NSMenu alloc] initWithTitle:title];
                NSMenuItem *command = [group.submenu addItemWithTitle:@"切り替え" action:@selector(execute:) keyEquivalent:@"x"];
                command.target = target;
                [menu addItem:group];
            }
            NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 900, 600)
                styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
            window.releasedWhenClosed = NO;
            TestHoverMenuView *root = [[TestHoverMenuView alloc] initWithFrame:NSMakeRect(0, 0, 900, 600) menu:menu];
            NSView *canvas = [[NSView alloc] initWithFrame:root.bounds];
            canvas.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
            [root addSubview:canvas];
            check(root.trackingAreas.count == 0, "unattached view has no active tracking area");
            window.contentView = root;
            [root layoutSubtreeIfNeeded];
            check(root.trackingAreas.count == 1 && NSMaxY(root.trackingAreas[0].rect) == NSHeight(root.bounds),
                "window attachment immediately registers top-edge tracking");
            check(!root.menuVisible, "menu starts hidden");
            check(!menuButton(root, @"App") && menuButton(root, @"表示") && menuButton(root, @"時刻"),
                "native app menu is omitted and operation menus remain accessible");
            check([root hitTest:NSMakePoint(100, 590)] == canvas, "hidden menu leaves top canvas interactive");
            const NSRect originalCanvas = canvas.frame;
            [root mouseEntered:trackingEvent(NSEventTypeMouseEntered)];
            check(root.menuVisible, "top-edge entry reveals menu");
            NSButton *viewButton = menuButton(root, @"表示");
            check(NSMinX(viewButton.frame) >= 78, "window button area remains free");
            check([root hitTest:NSMakePoint(100, 300)] == canvas, "visible menu does not intercept canvas below it");
            const NSPoint buttonPoint = [root convertPoint:NSMakePoint(NSMidX(viewButton.bounds), NSMidY(viewButton.bounds)) fromView:viewButton];
            check([root hitTest:buttonPoint] == viewButton, "menu remains above subsequently added drawing views");
            [root mouseExited:trackingEvent(NSEventTypeMouseExited)];
            check(!root.menuVisible && NSEqualRects(canvas.frame, originalCanvas), "exit hides menu without shrinking canvas");

            __block BOOL sawMenu = NO;
            __weak TestHoverMenuView *weakRoot = root;
            root.duringMenu = ^(NSMenu *copy) {
                sawMenu = YES;
                check(copy != [menu itemAtIndex:1].submenu, "opening uses an independent menu copy");
                NSMenuItem *item = [copy itemAtIndex:0];
                check(item.target == target && item.action == @selector(execute:) && [item.keyEquivalent isEqualToString:@"x"],
                    "menu copy preserves target, command, and keyboard equivalent");
                target.commandEnabled = NO;
                [copy update];
                check(!item.enabled && item.state == NSControlStateValueOff, "unavailable commands validate as disabled");
                target.commandEnabled = YES;
                [copy update];
                check(item.enabled && item.state == NSControlStateValueOn, "available commands and checked state refresh");
                [NSApp sendAction:item.action to:item.target from:item];
                [weakRoot mouseExited:trackingEvent(NSEventTypeMouseExited)];
                check(weakRoot.menuVisible, "leaving bar while menu tracks keeps bar visible");
            };
            [root showMenu];
            [viewButton performClick:nil];
            check(sawMenu && target.commands == 1, "overlay dispatches the same native menu action");
            check(!root.menuVisible, "menu closes after tracking outside an active window");
            root.duringMenu = nil;

            [root setFrameSize:NSMakeSize(1200, 720)];
            [root layoutSubtreeIfNeeded];
            [root showMenu];
            NSView *bar = viewButton.superview;
            check(NSWidth(bar.frame) == 1200 && NSMaxY(bar.frame) == 720 && NSHeight(bar.frame) == 36,
                "menu follows resized top edge");
            check(NSEqualRects(canvas.frame, root.bounds), "drawing still fills resized content");
            check(root.trackingAreas.count == 1 && NSEqualRects(root.trackingAreas[0].rect, bar.frame),
                "tracking area follows resized menu strip without accumulation");
            window.contentView = [[NSView alloc] initWithFrame:window.contentView.bounds];
            check(!root.window && !root.menuVisible && root.trackingAreas.count == 0,
                "window detachment clears tracking and collapses menu");
            window.contentView = root;
            check(root.window == window && root.trackingAreas.count == 1 &&
                NSMaxY(root.trackingAreas[0].rect) == NSHeight(root.bounds),
                "reattachment immediately restores one correctly placed tracking area");
            [root setFrameSize:NSMakeSize(880, 540)];
            check(root.trackingAreas.count == 1 && NSWidth(root.trackingAreas[0].rect) == 880 &&
                NSMaxY(root.trackingAreas[0].rect) == 540,
                "resize after reattachment immediately updates tracking geometry");
            [NSNotificationCenter.defaultCenter postNotificationName:NSWindowDidResignKeyNotification object:window];
            check(!root.menuVisible, "window deactivation collapses menu");
            [root showMenu];
            [NSNotificationCenter.defaultCenter postNotificationName:NSApplicationDidResignActiveNotification object:NSApp];
            check(!root.menuVisible, "application deactivation collapses menu");
            [root showMenu];
            [window close];
            check(!root.menuVisible, "closing window collapses menu");

            NSMenu *fullMenu = [[NSMenu alloc] init];
            NSArray<NSString *> *titles = @[@"App", @"ファイル", @"編集", @"着陸・離陸", @"表示", @"スクリプト", @"時刻", @"操作", @"ウィンドウ"];
            for (NSString *title in titles) {
                NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
                item.submenu = [[NSMenu alloc] initWithTitle:title];
                [fullMenu addItem:item];
            }
            NSWindow *fullWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 640, 480)
                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable |
                    NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView
                backing:NSBackingStoreBuffered defer:NO];
            fullWindow.titleVisibility = NSWindowTitleHidden;
            fullWindow.titlebarAppearsTransparent = YES;
            fullWindow.releasedWhenClosed = NO;
            HoverMenuView *fullRoot = [[HoverMenuView alloc] initWithFrame:fullWindow.contentView.bounds menu:fullMenu];
            fullWindow.contentView = fullRoot;
            [fullRoot layoutSubtreeIfNeeded];
            [fullRoot showMenu];
            for (NSString *title in [titles subarrayWithRange:NSMakeRange(1, titles.count - 1)]) {
                NSButton *button = menuButton(fullRoot, title);
                check(NSMaxX(button.frame) <= NSWidth(fullRoot.bounds), "all eight menus fit smallest supported window");
                NSPoint local = NSMakePoint(NSMidX(button.bounds), NSMidY(button.bounds));
                NSPoint framePoint = [fullRoot.superview convertPoint:local fromView:button];
                NSView *receiver = [fullRoot.superview hitTest:[fullRoot.superview convertPoint:framePoint toView:fullRoot.superview.superview]];
                check(receiver == button, "full-size title bar does not intercept menu click");
            }
            NSButton *firstButton = menuButton(fullRoot, @"ファイル");
            const NSPoint firstCenter = [fullRoot convertPoint:NSMakePoint(NSMidX(firstButton.bounds), NSMidY(firstButton.bounds)) fromView:firstButton];
            check(firstCenter.y > NSMaxY(fullWindow.contentLayoutRect), "full-size click check exercises title-bar overlap");
            check(fullRoot.trackingAreas.count == 1 && NSMaxY(fullRoot.trackingAreas[0].rect) == NSHeight(fullRoot.bounds),
                "full-size hover immediately reaches window top edge");
            constexpr NSWindowButton windowButtons[] = {NSWindowCloseButton, NSWindowMiniaturizeButton, NSWindowZoomButton};
            for (NSWindowButton kind : windowButtons) {
                NSButton *button = [fullWindow standardWindowButton:kind];
                NSPoint local = NSMakePoint(NSMidX(button.bounds), NSMidY(button.bounds));
                NSPoint point = [fullRoot.superview convertPoint:local fromView:button];
                NSView *receiver = [fullRoot.superview hitTest:[fullRoot.superview convertPoint:point toView:fullRoot.superview.superview]];
                check(receiver == button, "hover menu preserves native window button clicks");
            }
            [fullWindow close];
            std::printf("hover menu: %d checks passed\n", checks);
        } catch (const std::runtime_error& failure) {
            std::fprintf(stderr, "hover menu: %s\n", failure.what());
            return 1;
        }
    }
    return 0;
}
