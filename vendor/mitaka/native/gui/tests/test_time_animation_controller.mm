#import "PlaybackController.h"
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

// run loop を進めず、製品と同じ tick 入口へ決定的な時計を渡す。
@interface PlaybackController (TimeAnimationTest)
- (double)monotonicTime;
- (BOOL)sampleAnimationAtTime:(double)now;
- (BOOL)sampleAtTime:(double)now;
@end

@interface DeterministicTimeController : PlaybackController
@property(nonatomic) double injectedTime;
@end
@implementation DeterministicTimeController
- (double)monotonicTime { return self.injectedTime; }
@end

namespace {
using namespace mitaka::gui;
constexpr double epoch = 2451545;
constexpr auto linear = PlusTimeAnimationCurve::linear;
constexpr auto cosine = PlusTimeAnimationCurve::half_cosine;
constexpr auto preserve = PlusTimeAnimationSameTarget::preserve;
constexpr auto replace = PlusTimeAnimationSameTarget::replace;
int checks = 0;

void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}

struct Fixture {
    DeterministicTimeController *__strong controller;
    double accepted = epoch;
    int attempts = 0, notifications = 0, stops = 0;
    bool accept = true, throw_on_apply = false, pause_on_apply = false;

    Fixture() {
        controller = [[DeterministicTimeController alloc] initWithUnixTimeProvider:^double {
            return (epoch - 2440587.5) * 86400;
        }];
        controller.injectedTime = 100;
        Fixture *fixture = this;
        controller.applyDate = ^BOOL(double jd) {
            ++fixture->attempts;
            check(NSThread.isMainThread, "applyDate ran outside main thread");
            if (fixture->throw_on_apply) throw std::runtime_error("injected animation apply failure");
            if (fixture->pause_on_apply) [fixture->controller pause];
            if (!fixture->accept) return NO;
            fixture->accepted = jd;
            return YES;
        };
        controller.stateChanged = ^{ ++fixture->notifications; };
        controller.didStop = ^{ ++fixture->stops; };
        [controller configureWithJulianDate:epoch range:{epoch - 100, epoch + 100} enabled:YES];
    }
    ~Fixture() { [controller invalidate]; }
    Fixture(const Fixture&) = delete;
    Fixture& operator=(const Fixture&) = delete;

    void start(double target, double duration, PlusTimeAnimationCurve curve = linear,
               PlusTimeAnimationSameTarget policy = preserve) {
        NSString *error = nil;
        check([controller animateToJulianDate:target duration:duration curve:curve sameTargetPolicy:policy error:&error],
              "valid animation was rejected");
        check(error == nil, "successful animation reported an error");
    }
    void tick(double now) {
        controller.injectedTime = now;
        [controller sampleAnimationAtTime:now];
    }
    void plus_play(double days = 0.25, std::int32_t speed = 2) {
        PlusTimeState state;
        state.step.set_value_days(days);
        state.speed = speed;
        NSString *error = nil;
        check([controller setPlusTimeState:state error:&error] && error == nil, "Plus playback setup failed");
        check(controller.playing, "Plus playback did not start");
    }
    void date_is(double expected) {
        check(controller.julianDate == expected && accepted == expected, "controller and accepted display dates diverged");
    }
    void stopped() {
        check(!controller.playing && !controller.clockTracking && !controller.timeAnimating,
              "stop retained an active time mode");
        check([controller plusTimeState].speed == 0, "stop retained nonzero Plus speed");
    }
};

void test_lifecycle_and_curves() {
    for (auto curve : {linear, cosine}) {
        Fixture fixture;
        fixture.start(epoch + 4, 1, curve);
        check(fixture.controller.timeAnimating && !fixture.controller.playing, "animation changed ordinary playing state");
        fixture.tick(100);
        check(fixture.attempts == 0, "unchanged initial tick was applied");
        fixture.tick(100.25);
        const long double weight = curve == linear ? 0.25L : (1 - std::cos(std::acos(-1.0L) / 4)) / 2;
        const long double expected = epoch + 4 * weight;
        check(std::abs(static_cast<long double>(fixture.accepted) - expected) <=
              2 * std::numeric_limits<double>::epsilon() * std::abs(expected), "controller curve differs from oracle");
        check(fixture.controller.julianDate == fixture.accepted, "curve date was not committed");
        fixture.tick(101);
        fixture.date_is(epoch + 4);
        check(fixture.controller.timeAnimating && fixture.stops == 0, "exact endpoint removed positive animation");
        const int attempts = fixture.attempts;
        fixture.tick(std::nextafter(101.0, 102.0));
        fixture.stopped();
        check(fixture.attempts == attempts && fixture.stops == 1, "completion reapplied unchanged endpoint or missed stop");
        fixture.tick(101.5);
        check(fixture.stops == 1, "idle tick repeated completion notification");
    }
}

void test_signed_duration_and_replacement() {
    for (double duration : {0.0, -0.0}) {
        Fixture fixture;
        fixture.start(epoch + 4, duration);
        fixture.tick(100);
        fixture.date_is(epoch + 4);
        fixture.tick(101);
        check(fixture.controller.timeAnimating && fixture.attempts == 1 && fixture.stops == 0,
              "zero duration was removed or redundantly applied");
        fixture.start(epoch + 4, -1, cosine, replace);
        check(fixture.controller.timeAnimating, "same-date calendar request did not replace zero animation");
        fixture.tick(101);
        fixture.stopped();
        check(fixture.stops == 1, "negative duration did not complete at first tick");
    }
    Fixture fixture;
    fixture.start(epoch + 8, 2);
    fixture.tick(100.5);
    fixture.date_is(epoch + 2);
    fixture.start(epoch + 4, 1, linear, replace);
    check(fixture.stops == 0, "replacement reported completion of the displaced animation");
    fixture.tick(101);
    fixture.date_is(epoch + 3);
    fixture.tick(101.5);
    fixture.date_is(epoch + 4);
}

void test_tracking_and_same_target() {
    Fixture fixture;
    auto *controller = fixture.controller;
    check([controller setClockTracking:YES], "clock tracking setup failed");
    fixture.start(epoch, 1);
    check(controller.clockTracking && !controller.timeAnimating, "same JD started animation or stopped tracking");
    fixture.start(epoch + 4, 1);
    check(controller.clockTracking && controller.timeAnimating, "JD registration stopped tracking before changed tick");
    fixture.tick(100);
    check(controller.clockTracking, "unchanged animation tick stopped tracking");
    const int notifications = fixture.notifications;
    fixture.start(epoch, 0);
    check(controller.clockTracking && fixture.notifications == notifications, "same JD disturbed current animation state");
    fixture.tick(100.25);
    fixture.date_is(epoch + 1);
    check(!controller.clockTracking, "accepted changed tick retained tracking");
    fixture.start(epoch + 1, -1);
    fixture.tick(100.5);
    fixture.date_is(epoch + 2);
    check(controller.timeAnimating, "same-current-JD request replaced existing target");

    Fixture calendar;
    check([calendar.controller setClockTracking:YES], "calendar tracking setup failed");
    calendar.start(epoch, 0, cosine, replace);
    check(calendar.controller.timeAnimating && !calendar.controller.clockTracking,
          "same-date calendar registration failed to start or stop tracking");
    calendar.tick(100);
    check(calendar.attempts == 0 && calendar.controller.timeAnimating, "same-date zero calendar tick changed state");
}

void test_playback_reanchor() {
    for (int speed : {-2, 2}) {
        Fixture fixture;
        fixture.plus_play(0.25, speed);
        fixture.start(epoch + 4, 0.5);
        fixture.tick(100.25);
        fixture.date_is(epoch + 2);
        check(fixture.controller.playing && [fixture.controller plusTimeState].speed == speed,
              "animation discarded Plus playback state");
        fixture.tick(100.5);
        fixture.date_is(epoch + 4);
        fixture.tick(100.75);
        check(!fixture.controller.timeAnimating && fixture.controller.playing && fixture.stops == 0,
              "animation completion stopped retained playback");
        fixture.controller.injectedTime = 101;
        check([fixture.controller sampleAtTime:101], "retained playback did not continue");
        fixture.date_is(epoch + 4 + speed * 0.25 * 0.25);
        check([fixture.controller plusTimeState].step.value_days() == 0.25, "animation changed stored step value");
    }
    Fixture zero;
    zero.plus_play(0, 17);
    zero.start(epoch + 1, -1);
    zero.tick(100);
    zero.controller.injectedTime = 100.5;
    check([zero.controller sampleAtTime:100.5], "zero custom speed was not retained after animation");
    zero.date_is(epoch + 1);
    check(zero.controller.playing && [zero.controller plusTimeState].speed == 17, "zero custom lost active Plus state");

    Fixture native;
    [native.controller setSimulationRate:86400];
    [native.controller play];
    native.start(epoch + 2, -1);
    native.tick(100);
    native.controller.injectedTime = 100.25;
    check([native.controller sampleAtTime:100.25], "native playback did not continue after animation");
    native.date_is(epoch + 2.25);
    check(native.controller.simulationRate == 86400, "animation changed native playback rate");

    Fixture speed_change;
    speed_change.plus_play();
    speed_change.start(epoch + 4, 1);
    auto state = [speed_change.controller plusTimeState];
    state.speed = 0;
    const int notifications = speed_change.notifications;
    NSString *error = nil;
    check([speed_change.controller setPlusTimeState:state error:&error], "zero speed update failed during animation");
    check(speed_change.controller.timeAnimating && !speed_change.controller.playing && speed_change.stops == 0 &&
          speed_change.notifications == notifications + 1, "zero speed update stopped animation or missed state notification");
    speed_change.tick(100.5);
    speed_change.date_is(epoch + 2);
}

void test_step_updates_preserve_time_mode() {
    for (bool animating : {false, true}) {
        Fixture fixture;
        auto *controller = fixture.controller;
        check([controller setClockTracking:YES], "step tracking setup failed");
        if (animating) fixture.start(epoch + 4, 1);
        auto step = [controller plusTimeState].step;
        NSString *error = nil;
        for (int operation = 0; operation < 4; ++operation) {
            if (operation == 0) step.select(PlusTimeStep::day);
            else if (operation == 1) step.set_value_days(.125);
            else if (operation == 2) step.previous();
            else step.next();
            check([controller setPlusTimeStep:step error:&error] && error == nil,
                  "step update failed during tracking");
            check(controller.clockTracking && controller.timeAnimating == animating && !controller.playing &&
                  [controller plusTimeState].speed == 0 && fixture.stops == 0,
                  "step update changed tracking or animation");
        }
        auto state = [controller plusTimeState];
        check([controller setPlusTimeState:state error:&error] && !controller.clockTracking,
              "explicit zero speed failed to stop clock tracking");
        check(controller.timeAnimating == animating, "zero speed changed animation");
    }
    Fixture native;
    [native.controller setSimulationRate:86400];
    [native.controller play];
    auto nativeStep = [native.controller plusTimeState].step;
    nativeStep.set_value_days(.125);
    NSString *error = nil;
    check([native.controller setPlusTimeStep:nativeStep error:&error] && native.controller.playing,
          "step update stopped native playback");
    native.controller.injectedTime = 100.5;
    check([native.controller sampleAtTime:100.5], "native playback stopped after step update");
    native.date_is(epoch + .5);

    Fixture plus;
    plus.plus_play(.25, 2);
    plus.controller.injectedTime = 100.25;
    auto plusStep = [plus.controller plusTimeState].step;
    plusStep.set_value_days(.5);
    check([plus.controller setPlusTimeStep:plusStep error:&error] && plus.controller.playing,
          "step update stopped Plus playback");
    plus.date_is(epoch + .125);
    plus.controller.injectedTime = 100.5;
    check([plus.controller sampleAtTime:100.5], "Plus playback stopped after step update");
    plus.date_is(epoch + .375);

    Fixture reentrant;
    reentrant.plus_play();
    reentrant.controller.injectedTime = 100.25;
    reentrant.pause_on_apply = true;
    auto rejectedStep = [reentrant.controller plusTimeState].step;
    rejectedStep.set_value_days(.75);
    error = nil;
    check(![reentrant.controller setPlusTimeStep:rejectedStep error:&error] && error.length > 0,
          "step update ignored reentrant stop");
    reentrant.stopped();
    check([reentrant.controller plusTimeState].step.value_days() == .25,
          "step update committed after reentrant stop");
}

void test_atomic_input_failure() {
    struct Request { double target, duration, now; PlusTimeAnimationCurve curve; PlusTimeAnimationSameTarget policy; };
    const double nan = std::numeric_limits<double>::quiet_NaN();
    const double inf = std::numeric_limits<double>::infinity();
    const Request requests[] = {
        {nan, 1, 100, linear, preserve}, {epoch + 101, 1, 100, linear, preserve},
        {epoch, nan, 100, linear, preserve}, {epoch, inf, 100, linear, preserve},
        {epoch, -inf, 100, linear, preserve}, {epoch, 1, nan, linear, preserve},
        {epoch, nan, 100, linear, replace},
        {epoch, 1, 100, static_cast<PlusTimeAnimationCurve>(99), preserve},
        {epoch, 1, 100, linear, static_cast<PlusTimeAnimationSameTarget>(99)}
    };
    for (const auto& request : requests) {
        Fixture fixture;
        check([fixture.controller setClockTracking:YES], "failure tracking setup failed");
        fixture.start(epoch + 4, 1);
        const int notifications = fixture.notifications;
        fixture.controller.injectedTime = request.now;
        NSString *error = nil;
        check(![fixture.controller animateToJulianDate:request.target duration:request.duration curve:request.curve
            sameTargetPolicy:request.policy error:&error] && error.length > 0, "invalid animation request was accepted");
        check(fixture.controller.timeAnimating && fixture.controller.clockTracking && !fixture.controller.playing &&
              fixture.notifications == notifications && fixture.stops == 0 && fixture.attempts == 0,
              "invalid request changed active state");
        fixture.date_is(epoch);
        fixture.tick(100.25);
        fixture.date_is(epoch + 1);
    }
}

void test_apply_failure_and_reentrancy() {
    for (int failure = 0; failure < 3; ++failure) {
        Fixture fixture;
        fixture.plus_play();
        fixture.start(epoch + 4, 1);
        fixture.tick(100.25);
        fixture.date_is(epoch + 1);
        fixture.accept = failure != 0;
        fixture.throw_on_apply = failure == 1;
        if (failure == 2) fixture.controller.applyDate = nil;
        fixture.tick(100.5);
        fixture.stopped();
        fixture.date_is(epoch + 1);
        check(fixture.stops == 1, "apply failure missed stop notification");
    }
    Fixture pause;
    pause.plus_play();
    pause.start(epoch + 4, 1);
    pause.pause_on_apply = true;
    pause.tick(100.25);
    pause.date_is(epoch + 1);
    pause.stopped();
    check(pause.stops == 1, "reentrant pause failed after accepted display commit");

    Fixture tracking;
    check([tracking.controller setClockTracking:YES], "rejected animation tracking setup failed");
    tracking.start(epoch + 4, 1);
    tracking.accept = false;
    tracking.tick(100.25);
    tracking.stopped();
    tracking.date_is(epoch);
}

void test_interruption_boundaries() {
    for (double interrupted : {101.25, 99.0, std::numeric_limits<double>::infinity(),
                               std::numeric_limits<double>::quiet_NaN()}) {
        Fixture fixture;
        fixture.plus_play();
        fixture.start(epoch + 4, 4);
        fixture.tick(interrupted);
        fixture.stopped();
        fixture.date_is(epoch);
        check(fixture.attempts == 0 && fixture.stops == 1, "invalid tick applied a date before stopping");
    }
    for (bool tracking : {false, true}) {
        for (int operation = 0; operation < 5; ++operation) {
            Fixture fixture;
            if (tracking) check([fixture.controller setClockTracking:YES], "stop tracking setup failed");
            else fixture.plus_play();
            fixture.start(epoch + 4, 4);
            switch (operation) {
                case 0: [fixture.controller pause]; break;
                case 1: [fixture.controller suspendForHiddenWindow]; [fixture.controller resumeAfterHiddenWindow]; break;
                case 2: [fixture.controller suspendForSystemSleep]; [fixture.controller resumeAfterSystemSleep]; break;
                case 3: [fixture.controller invalidate]; break;
                case 4: [fixture.controller interruptWithMessage:@"test interruption"]; break;
            }
            fixture.stopped();
            fixture.date_is(epoch);
            fixture.tick(100.5);
            check(fixture.attempts == 0 && fixture.stops == 1, "stop or wake revived interrupted animation");
        }
    }
    Fixture pause;
    pause.start(epoch + 4, 1);
    pause.controller.injectedTime = 100.5;
    [pause.controller pause];
    pause.date_is(epoch + 2);
    pause.stopped();
}

void test_unavailable_and_explicit_zone() {
    Fixture fixture;
    check(![fixture.controller plusTimeZone], "controller guessed a default timezone");
    [fixture.controller setPlusTimeZone:PlusTimeZone{-9 * 3600}];
    check([fixture.controller plusTimeZone]->seconds_west_of_utc == -9 * 3600, "explicit timezone was not retained");
    [fixture.controller setPlusTimeZone:PlusTimeZone{0}];
    check([fixture.controller plusTimeZone].has_value() && [fixture.controller plusTimeZone]->seconds_west_of_utc == 0,
          "explicit UTC was confused with absent timezone");
    [fixture.controller setPlusTimeZone:std::nullopt];
    check(![fixture.controller plusTimeZone], "cleared timezone remained present");
    for (int operation = 0; operation < 4; ++operation) {
        Fixture unavailable;
        switch (operation) {
            case 0: [unavailable.controller configureWithJulianDate:epoch range:{epoch - 100, epoch + 100} enabled:NO]; break;
            case 1: [unavailable.controller suspendForHiddenWindow]; break;
            case 2: [unavailable.controller suspendForSystemSleep]; break;
            case 3: [unavailable.controller invalidate]; break;
        }
        NSString *error = nil;
        check(![unavailable.controller animateToJulianDate:epoch + 1 duration:1 curve:linear
            sameTargetPolicy:preserve error:&error] && error.length > 0, "unavailable controller accepted animation");
        unavailable.stopped();
        unavailable.date_is(epoch);
    }
}
} // namespace

int main() {
    @autoreleasepool {
        try {
            check(NSThread.isMainThread, "controller tests require main thread");
            [NSApplication sharedApplication];
            const NSUInteger windows = NSApp.windows.count;
            test_lifecycle_and_curves();
            test_signed_duration_and_replacement();
            test_tracking_and_same_target();
            test_playback_reanchor();
            test_step_updates_preserve_time_mode();
            test_atomic_input_failure();
            test_apply_failure_and_reentrancy();
            test_interruption_boundaries();
            test_unavailable_and_explicit_zone();
            check(NSApp.windows.count == windows, "deterministic controller test created a window");
            std::cout << "Time animation controller tests: " << checks << " checks passed\n";
            return 0;
        } catch (const std::exception& failure) {
            std::cerr << "Time animation controller test failed: " << failure.what() << '\n';
            return 1;
        }
    }
}
