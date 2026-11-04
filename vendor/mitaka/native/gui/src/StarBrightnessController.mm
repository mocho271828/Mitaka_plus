#import "StarBrightnessController.h"
#include "star_brightness.hpp"
#include <chrono>
#include <exception>

using mitaka::gui::StarBrightnessTransition;

@implementation StarBrightnessController {
    StarBrightnessTransition _transition;
    NSTimer *_timer;
    double (^_timeProvider)(void);
    BOOL _invalidated, _applying;
    NSUInteger _revision;
}

- (instancetype)init {
    return [self initWithMonotonicTimeProvider:^double {
        return std::chrono::duration<double>(std::chrono::steady_clock::now().time_since_epoch()).count();
    }];
}

- (instancetype)initWithMonotonicTimeProvider:(double (^)(void))provider {
    if (!provider) return nil;
    if ((self = [super init])) _timeProvider = [provider copy];
    return self;
}

- (BOOL)animating { return _transition.active(); }

- (BOOL)animateFrom:(float)current to:(double)target duration:(double)seconds error:(NSString **)error {
    if (error) *error = nil;
    if (_invalidated || _applying || !self.applyValue) {
        if (error) *error = @"恒星の明るさを変更できません";
        return NO;
    }
    auto candidate = _transition;
    try {
        const double now = _timeProvider();
        if (!candidate.begin(current, target, seconds, now)) return YES;
        if (seconds == 0) {
            const float value = *candidate.sample(now);
            const NSUInteger revision = _revision;
            _applying = YES;
            const BOOL accepted = self.applyValue(value);
            _applying = NO;
            if (!accepted || _revision != revision) {
                if (error) *error = @"恒星の明るさの適用が拒否されました";
                return NO;
            }
        }
    } catch (const std::exception& failure) {
        _applying = NO;
        if (error) *error = [NSString stringWithUTF8String:failure.what()];
        return NO;
    }
    [self cancel];
    _transition = candidate;
    if (!_transition.active()) return YES;
    __weak StarBrightnessController *weakSelf = self;
    _timer = [NSTimer timerWithTimeInterval:1.0 / 30.0 repeats:YES block:^(NSTimer *timer) {
        (void)timer;
        [weakSelf sample];
    }];
    _timer.tolerance = 1.0 / 300.0;
    [NSRunLoop.mainRunLoop addTimer:_timer forMode:NSRunLoopCommonModes];
    return YES;
}

- (void)sample {
    if (!_transition.active() || _applying || _invalidated) return;
    auto candidate = _transition;
    NSString *failure = nil;
    try {
        const auto value = candidate.sample(_timeProvider());
        const NSUInteger revision = _revision;
        _applying = YES;
        const BOOL accepted = value && self.applyValue && self.applyValue(*value);
        _applying = NO;
        if (revision != _revision) return;
        if (accepted) _transition = candidate;
        else failure = @"恒星の明るさの適用が拒否されました";
    } catch (const std::exception& error) {
        _applying = NO;
        failure = [NSString stringWithUTF8String:error.what()];
    }
    if (failure || !_transition.active()) [self cancel];
    if (failure && self.didFail) self.didFail(failure);
}

- (void)cancel {
    ++_revision;
    _transition.cancel();
    [_timer invalidate];
    _timer = nil;
}

- (void)invalidate {
    [self cancel];
    _invalidated = YES;
    self.applyValue = nil;
    self.didFail = nil;
}

- (void)dealloc { [_timer invalidate]; }
@end
