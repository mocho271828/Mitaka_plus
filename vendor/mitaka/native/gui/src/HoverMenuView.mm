#import "HoverMenuView.h"

namespace {
constexpr CGFloat menuHeight = 36;
constexpr CGFloat windowButtonSpace = 78;
}

@implementation HoverMenuView {
    NSMenu *_sourceMenu;
    NSView *_menuBar;
    NSArray<NSButton *> *_buttons;
    NSTrackingArea *_topTrackingArea;
    BOOL _trackingMenu;
}

- (instancetype)initWithFrame:(NSRect)frame menu:(NSMenu *)menu {
    if ((self = [super initWithFrame:frame])) {
        _sourceMenu = menu;
        _menuBar = [[NSView alloc] init];
        _menuBar.wantsLayer = YES;
        _menuBar.layer.backgroundColor = [NSColor colorWithWhite:0.055 alpha:0.96].CGColor;
        _menuBar.accessibilityIdentifier = @"hover-menu-bar";
        _menuBar.hidden = YES;
        [self addSubview:_menuBar];
        NSMutableArray<NSButton *> *buttons = [NSMutableArray array];
        for (NSInteger index = 1; index < menu.numberOfItems; ++index) {
            NSMenuItem *item = [menu itemAtIndex:index];
            if (!item.submenu || item.hidden) continue;
            NSButton *button = [NSButton buttonWithTitle:item.title target:self action:@selector(openMenu:)];
            button.tag = index;
            button.bordered = NO;
            button.font = [NSFont systemFontOfSize:13];
            button.contentTintColor = NSColor.whiteColor;
            button.accessibilityLabel = item.title;
            [_menuBar addSubview:button];
            [buttons addObject:button];
        }
        _buttons = buttons;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(applicationDeactivated:)
            name:NSApplicationDidResignActiveNotification object:NSApp];
        self.needsLayout = YES;
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (BOOL)menuVisible { return !_menuBar.hidden; }

- (NSRect)menuRect {
    return NSMakeRect(NSMinX(self.bounds), NSMaxY(self.bounds) - MIN(menuHeight, NSHeight(self.bounds)),
        NSWidth(self.bounds), MIN(menuHeight, NSHeight(self.bounds)));
}

- (void)layout {
    [super layout];
    _menuBar.frame = [self menuRect];
    CGFloat x = windowButtonSpace;
    for (NSButton *button in _buttons) {
        const CGFloat width = ceil(button.fittingSize.width) + 16;
        button.frame = NSMakeRect(x, 0, width, NSHeight(_menuBar.bounds));
        x += width;
    }
}

- (void)didAddSubview:(NSView *)subview {
    [super didAddSubview:subview];
    // 後から加えた描画ビューより、メニュー帯を常に手前に保つ。
    if (_menuBar && subview != _menuBar)
        [self addSubview:_menuBar positioned:NSWindowAbove relativeTo:nil];
}

- (void)viewWillMoveToWindow:(NSWindow *)window {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    if (self.window) {
        [center removeObserver:self name:NSWindowDidResignKeyNotification object:self.window];
        [center removeObserver:self name:NSWindowWillCloseNotification object:self.window];
    }
    [self collapseMenu];
    [super viewWillMoveToWindow:window];
    if (window) {
        [center addObserver:self selector:@selector(windowDeactivated:) name:NSWindowDidResignKeyNotification object:window];
        [center addObserver:self selector:@selector(windowDeactivated:) name:NSWindowWillCloseNotification object:window];
    }
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    // AppKit の初回更新を待たず、表示直後から上端のホバーを受け取る。
    [self updateTrackingAreas];
}

- (void)setFrameSize:(NSSize)size {
    [super setFrameSize:size];
    if (self.window) [self updateTrackingAreas];
}

- (void)updateTrackingAreas {
    if (_topTrackingArea) [self removeTrackingArea:_topTrackingArea];
    _topTrackingArea = nil;
    if (self.window) {
        _topTrackingArea = [[NSTrackingArea alloc] initWithRect:[self menuRect]
            options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInKeyWindow
            owner:self userInfo:nil];
        [self addTrackingArea:_topTrackingArea];
    }
    [super updateTrackingAreas];
}

- (void)mouseEntered:(NSEvent *)event {
    (void)event;
    [self showMenu];
}
- (void)mouseExited:(NSEvent *)event {
    (void)event;
    [self hideMenu];
}
- (void)showMenu { _menuBar.hidden = NO; }
- (void)hideMenu {
    if (!_trackingMenu) [self collapseMenu];
}
- (void)collapseMenu { _menuBar.hidden = YES; }
- (void)windowDeactivated:(NSNotification *)notification {
    (void)notification;
    [self collapseMenu];
}
- (void)applicationDeactivated:(NSNotification *)notification {
    (void)notification;
    [self collapseMenu];
}

- (void)presentMenu:(NSMenu *)menu atPoint:(NSPoint)point {
    [menu popUpMenuPositioningItem:nil atLocation:point inView:self];
}

- (void)openMenu:(NSButton *)sender {
    if (sender.tag < 0 || sender.tag >= _sourceMenu.numberOfItems) return;
    NSMenu *menu = [[_sourceMenu itemAtIndex:sender.tag].submenu copy];
    if (!menu) return;
    [self showMenu];
    _trackingMenu = YES;
    // 原本を別の親へ移さず、同じ target/action と検証規則を持つコピーを開く。
    [self presentMenu:menu atPoint:[self convertPoint:NSMakePoint(NSMinX(sender.frame), 0) fromView:_menuBar]];
    _trackingMenu = NO;
    const NSPoint mouse = [self convertPoint:self.window.mouseLocationOutsideOfEventStream fromView:nil];
    if (!self.window.keyWindow || !NSPointInRect(mouse, [self menuRect])) [self hideMenu];
}
@end
