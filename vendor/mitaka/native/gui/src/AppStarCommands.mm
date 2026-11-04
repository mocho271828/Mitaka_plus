#import "AppControllerInternal.h"
#include "star_brightness.hpp"

@implementation AppController (StarCommands)
- (void)setStarBrightness:(double)value cancelTransition:(BOOL)cancel {
    auto options = [self starDisplayOptions];
    options.brightness = checked_star_brightness(value);
    validate_star_display(options);
    // 不正な要求は進行中の補間にも影響させない。
    if (cancel) [_starBrightness cancel];
    [self setStarDisplayOptions:options];
}
- (BOOL)animateStarBrightness:(double)value duration:(double)seconds error:(NSString **)error {
    if (!_model || _loading) {
        if (error) *error = @"天文データの読み込み完了後に実行してください。";
        return NO;
    }
    if (!_starBrightness) {
        _starBrightness = [[StarBrightnessController alloc] initWithMonotonicTimeProvider:^{
            return NSProcessInfo.processInfo.systemUptime;
        }];
        __weak AppController *weakSelf = self;
        _starBrightness.applyValue = ^BOOL(float brightness) {
            AppController *controller = weakSelf;
            if (!controller || !controller->_model || controller->_loading) return NO;
            [controller setStarBrightness:brightness cancelTransition:NO];
            return YES;
        };
        _starBrightness.didFail = ^(NSString *message) {
            AppController *controller = weakSelf;
            if (controller) [controller showError:message];
        };
    }
    return [_starBrightness animateFrom:[self starDisplayOptions].brightness
        to:value duration:seconds error:error];
}
- (void)changeStarBrightness:(NSMenuItem *)sender {
    try {
        const float value = [self starDisplayOptions].brightness;
        switch (sender.tag) {
            case 0: [self setStarBrightness:brighter_star_brightness(value) cancelTransition:NO]; break;
            case 1: [self setStarBrightness:darker_star_brightness(value) cancelTransition:NO]; break;
            case 2: [self setStarBrightness:1 cancelTransition:NO]; break;
            default: break;
        }
    } catch (const std::exception& error) {
        [self showError:[NSString stringWithUTF8String:error.what()]];
    }
}
@end
