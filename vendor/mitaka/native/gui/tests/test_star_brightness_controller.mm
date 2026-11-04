#import "StarBrightnessController.h"
#include <cmath>
#include <cstdio>
#include <limits>
#include <stdexcept>

namespace {
int checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
void waitFor(BOOL (^condition)(void)) {
    const auto deadline = [NSDate dateWithTimeIntervalSinceNow:2];
    while (!condition() && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    check(condition(), "timer completed within bounded main run loop wait");
}
}
int main() {
    @autoreleasepool {
        try {
            __block double now = 10;
            __block float displayed = 1;
            __block int updates = 0, failures = 0;
            __block BOOL reject = NO, throwError = NO, cancelInCallback = NO;
            StarBrightnessController *controller = [[StarBrightnessController alloc]
                initWithMonotonicTimeProvider:^double { return now; }];
            __weak StarBrightnessController *weakController = controller;
            controller.applyValue = ^BOOL(float value) {
                check(NSThread.isMainThread, "apply on main thread");
                if (throwError) throw std::runtime_error("test application failure");
                if (reject) return NO;
                displayed = value; ++updates;
                if (cancelInCallback) [weakController cancel];
                return YES;
            };
            controller.didFail = ^(NSString *message) {
                check(NSThread.isMainThread && message.length, "diagnostic on main thread");
                ++failures;
            };
            NSString *error = nil;
            check([controller animateFrom:displayed to:9 duration:4 error:&error] && !error && controller.animating,
                "start accepted without blocking");
            now = 11;
            waitFor(^BOOL { return displayed > 1; });
            check(std::abs(displayed - (5 - 2 * std::sqrt(2.0))) < 1e-6, "controller uses cosine curve");
            const float current = displayed;
            check(![controller animateFrom:current to:0 duration:1 error:&error] && error && controller.animating,
                "invalid request preserves active timer");
            check([controller animateFrom:current to:current duration:0 error:&error] && !error && controller.animating,
                "same current leaves active target intact");
            now = 14;
            waitFor(^BOOL { return !controller.animating; });
            check(displayed == 9 && failures == 0, "exact target and clean completion");
            check([controller animateFrom:displayed to:3 duration:0 error:&error] && displayed == 3 &&
                !controller.animating, "zero duration applies synchronously");
            check([controller animateFrom:displayed to:7 duration:4 error:&error], "start replacement case");
            now = 16;
            waitFor(^BOOL { return displayed == 5; });
            check([controller animateFrom:displayed to:1 duration:2 error:&error], "replace at current value");
            now = 18;
            waitFor(^BOOL { return !controller.animating; });
            check(displayed == 1, "replacement reaches new target");
            check([controller animateFrom:displayed to:9 duration:4 error:&error], "start cancel case");
            [controller cancel];
            check(!controller.animating && displayed == 1, "cancel retains last displayed value");
            check([controller animateFrom:displayed to:9 duration:4 error:&error], "start refusal case");
            reject = YES;
            check(![controller animateFrom:displayed to:3 duration:0 error:&error] && controller.animating && displayed == 1,
                "immediate refusal keeps previous animation");
            now = 19;
            waitFor(^BOOL { return failures == 1; });
            check(!controller.animating && displayed == 1, "timer refusal stops while retaining display");
            reject = NO;
            check([controller animateFrom:displayed to:9 duration:4 error:&error], "start bad clock case");
            now = 18;
            waitFor(^BOOL { return failures == 2; });
            check(!controller.animating && displayed == 1, "backwards clock stops animation");
            now = 20;
            check([controller animateFrom:displayed to:9 duration:4 error:&error], "start exception case");
            throwError = YES;
            check(![controller animateFrom:displayed to:3 duration:0 error:&error] && controller.animating,
                "immediate application exception preserves previous animation");
            throwError = NO;
            check([controller animateFrom:displayed to:3 duration:0 error:&error] && displayed == 3,
                "application guard recovers after exception");
            check([controller animateFrom:displayed to:9 duration:4 error:&error], "start callback cancellation");
            cancelInCallback = YES; now = 22;
            waitFor(^BOOL { return !controller.animating; });
            check(displayed == 6, "callback cancellation is not overwritten by candidate state");
            cancelInCallback = NO;
            check([controller animateFrom:displayed to:9 duration:4 error:&error], "start invalidation case");
            [controller invalidate];
            check(!controller.animating && ![controller animateFrom:displayed to:1 duration:0 error:&error] && error,
                "invalidated controller refuses restart");
            check(![[StarBrightnessController alloc] initWithMonotonicTimeProvider:nil], "missing clock refused");
            auto unavailable = [[StarBrightnessController alloc] init];
            check(![unavailable animateFrom:1 to:2 duration:1 error:&error] && error, "missing apply destination refused");
            check(updates >= 7, "timer and synchronous applications executed");
            std::printf("Star brightness controller tests passed: %d checks\n", checks);
            return 0;
        } catch (const std::exception& error) {
            std::fprintf(stderr, "Star brightness controller test failed: %s\n", error.what());
            return 1;
        }
    }
}
