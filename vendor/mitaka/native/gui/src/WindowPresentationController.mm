#import "WindowPresentationController.h"

@implementation WindowPresentationController {
    __weak NSWindow *_window;
    BOOL _transitioning, _targetFullScreen, _closed;
    NSString *_lastTransitionError;
}

- (instancetype)initWithWindow:(NSWindow *)window {
    if ((self = [super init])) {
        _window = window;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(windowClosed:)
            name:NSWindowWillCloseNotification object:window];
    }
    return self;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (BOOL)fullScreen { return (_window.styleMask & NSWindowStyleMaskFullScreen) != 0; }
- (BOOL)transitioning { return _transitioning; }
- (NSString *)lastTransitionError { return _lastTransitionError; }

- (BOOL)requestFullScreen:(BOOL)enabled error:(NSString **)error {
    if (error) *error = nil;
    NSWindow *window = _window;
    if (!window || _closed) {
        if (error) *error = @"主ウィンドウが閉じられています。";
        return NO;
    }
    if (_transitioning) {
        if (enabled == _targetFullScreen) return YES;
        if (error) *error = @"全画面の切り替え中です。完了してから反対方向へ切り替えてください。";
        return NO;
    }
    if (enabled == self.fullScreen) return YES;
    if (!window.visible || window.miniaturized) {
        if (error) *error = @"主ウィンドウを表示してから全画面を切り替えてください。";
        return NO;
    }
    _lastTransitionError = nil;
    _targetFullScreen = enabled;
    _transitioning = YES;
    [window toggleFullScreen:nil];
    return YES;
}

- (BOOL)toggleFullScreenWithError:(NSString **)error {
    if (_transitioning) {
        if (error) *error = @"全画面の切り替え中です。完了してから再度切り替えてください。";
        return NO;
    }
    return [self requestFullScreen:!self.fullScreen error:error];
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
    if (notification.object != _window || _closed) return;
    _lastTransitionError = nil;
    _targetFullScreen = YES;
    _transitioning = YES;
}
- (void)windowWillExitFullScreen:(NSNotification *)notification {
    if (notification.object != _window || _closed) return;
    _lastTransitionError = nil;
    _targetFullScreen = NO;
    _transitioning = YES;
}
- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    if (notification.object != _window || _closed) return;
    _transitioning = NO;
}
- (void)windowDidExitFullScreen:(NSNotification *)notification {
    if (notification.object != _window || _closed) return;
    _transitioning = NO;
}
- (void)windowDidFailToEnterFullScreen:(NSWindow *)window {
    if (window != _window || _closed) return;
    _transitioning = NO;
    _lastTransitionError = @"全画面表示へ切り替えられませんでした。";
}
- (void)windowDidFailToExitFullScreen:(NSWindow *)window {
    if (window != _window || _closed) return;
    _transitioning = NO;
    _lastTransitionError = @"全画面表示を終了できませんでした。";
}
- (void)windowClosed:(NSNotification *)notification {
    if (notification.object != _window) return;
    _closed = YES;
    _transitioning = NO;
    _lastTransitionError = nil;
}

+ (NSDictionary<NSAboutPanelOptionKey, id> *)aboutPanelOptionsForBundle:(NSBundle *)bundle {
    NSMutableAttributedString *credits = [[NSMutableAttributedString alloc] initWithString:
        @"非公式の macOS ネイティブ版です。\n天文データと画像は同梱せず、選択したローカル原本を読み取ります。\n"];
    for (NSString *name in @[@"THIRD_PARTY_NOTICES", @"LUA_LICENSE"]) {
        NSURL *url = [bundle URLForResource:name withExtension:@"txt"];
        if (!url) continue;
        NSString *title = [name isEqualToString:@"LUA_LICENSE"] ? @"Lua ライセンス\n" : @"第三者の著作権・ライセンス\n";
        [credits appendAttributedString:[[NSAttributedString alloc] initWithString:title
            attributes:@{NSLinkAttributeName:url}]];
    }
    return @{NSAboutPanelOptionCredits:credits};
}
@end
