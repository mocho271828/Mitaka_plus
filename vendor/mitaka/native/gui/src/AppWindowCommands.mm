#import "AppControllerInternal.h"

@implementation AppController (WindowCommands)
- (BOOL)fullScreen { return _windowPresentation.fullScreen; }
- (BOOL)fullScreenTransitioning { return _windowPresentation.transitioning; }

- (BOOL)setFullScreen:(BOOL)enabled error:(NSString **)error {
    if (!_windowPresentation) {
        if (error) *error = @"主ウィンドウがまだ準備されていません。";
        return NO;
    }
    return [_windowPresentation requestFullScreen:enabled error:error];
}
- (BOOL)toggleFullScreenWithError:(NSString **)error {
    if (!_windowPresentation) {
        if (error) *error = @"主ウィンドウがまだ準備されていません。";
        return NO;
    }
    return [_windowPresentation toggleFullScreenWithError:error];
}
- (void)toggleMainFullScreen:(id)sender {
    (void)sender;
    NSString *error = nil;
    if (![self toggleFullScreenWithError:&error]) [self showError:error];
}
- (void)showAbout:(id)sender {
    (void)sender;
    [NSApp orderFrontStandardAboutPanelWithOptions:
        [WindowPresentationController aboutPanelOptionsForBundle:NSBundle.mainBundle]];
}
- (BOOL)validateWindowMenuItem:(NSMenuItem *)item {
    if (item.action == @selector(showAbout:)) return YES;
    if (item.action != @selector(toggleMainFullScreen:)) return NO;
    item.state = self.fullScreen ? NSControlStateValueOn : NSControlStateValueOff;
    return _window && _window.visible && !_window.miniaturized && !self.fullScreenTransitioning;
}

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
    if (notification.object == _window) [_windowPresentation windowWillEnterFullScreen:notification];
}
- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    if (notification.object == _window) [_windowPresentation windowDidEnterFullScreen:notification];
}
- (void)windowWillExitFullScreen:(NSNotification *)notification {
    if (notification.object == _window) [_windowPresentation windowWillExitFullScreen:notification];
}
- (void)windowDidExitFullScreen:(NSNotification *)notification {
    if (notification.object == _window) [_windowPresentation windowDidExitFullScreen:notification];
}
- (void)windowDidFailToEnterFullScreen:(NSWindow *)window {
    if (window != _window) return;
    [_windowPresentation windowDidFailToEnterFullScreen:window];
    if (_windowPresentation.lastTransitionError.length) [self showError:_windowPresentation.lastTransitionError];
}
- (void)windowDidFailToExitFullScreen:(NSWindow *)window {
    if (window != _window) return;
    [_windowPresentation windowDidFailToExitFullScreen:window];
    if (_windowPresentation.lastTransitionError.length) [self showError:_windowPresentation.lastTransitionError];
}
@end
