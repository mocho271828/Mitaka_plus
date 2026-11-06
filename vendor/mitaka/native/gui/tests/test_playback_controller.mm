#import "PlaybackController.h"

#include <array>
#include <chrono>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <thread>

namespace {
constexpr double epoch = 2451545.0;
using Clock = std::chrono::steady_clock;

void check(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}

template <typename Predicate> bool wait_until(Predicate condition, double timeout = 2.0) {
    const auto deadline = Clock::now() + std::chrono::duration<double>(timeout);
    while (!condition() && Clock::now() < deadline) {
        @autoreleasepool {
            [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode
                beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
    }
    return condition();
}

void pump_quiet_interval() {
    // 停止後も RunLoop を動かし、残ったタイマーが更新を再開しないことを調べる。
    bool elapsed = false;
    bool *elapsed_flag = &elapsed;
    NSTimer *deadline = [NSTimer scheduledTimerWithTimeInterval:0.12 repeats:NO block:^(NSTimer *timer) {
        (void)timer;
        *elapsed_flag = true;
    }];
    const bool finished = wait_until([&] { return elapsed; });
    [deadline invalidate];
    check(finished, "RunLoop quiet interval timed out");
}

NSControl *find_control(NSView *view, bool popup) {
    if (popup && [view isKindOfClass:NSPopUpButton.class]) return (NSControl *)view;
    if (!popup && [view isKindOfClass:NSButton.class] && ![view isKindOfClass:NSPopUpButton.class])
        return (NSControl *)view;
    for (NSView *child in view.subviews)
        if (NSControl *found = find_control(child, popup)) return found;
    return nil;
}

NSSegmentedControl *find_direction_control(NSView *view) {
    if ([view isKindOfClass:NSSegmentedControl.class]) return (NSSegmentedControl *)view;
    for (NSView *child in view.subviews)
        if (NSSegmentedControl *found = find_direction_control(child)) return found;
    return nil;
}

void send_action(NSControl *control) {
    check(control && control.enabled && control.target && control.action, "UI control is not connected or enabled");
    check([control sendAction:control.action to:control.target], "UI target/action was not handled");
}

struct Observations {
    NSUInteger attempts = 0, successes = 0, state_changes = 0, stops = 0;
    double accepted_jd = epoch, attempted_jd = epoch;
    bool accept = true, on_main_thread = true, monotonic = true;
    double direction = 1;
};

struct Fixture {
    Observations observed;
    PlaybackController *controller = [[PlaybackController alloc] init];

    Fixture() {
        auto *state = &observed;
        controller.applyDate = ^BOOL(double jd) {
            state->on_main_thread = state->on_main_thread && NSThread.isMainThread;
            ++state->attempts;
            state->attempted_jd = jd;
            if (!state->accept) return NO;
            state->monotonic = state->monotonic && std::isfinite(jd) &&
                state->direction * (jd - state->accepted_jd) >= 0;
            state->accepted_jd = jd;
            ++state->successes;
            return YES;
        };
        controller.stateChanged = ^{
            state->on_main_thread = state->on_main_thread && NSThread.isMainThread;
            ++state->state_changes;
        };
        controller.didStop = ^{
            state->on_main_thread = state->on_main_thread && NSThread.isMainThread;
            ++state->stops;
        };
    }
    ~Fixture() { [controller invalidate]; }
    Fixture(const Fixture&) = delete;
    Fixture& operator=(const Fixture&) = delete;

    void configure(double begin = epoch, double end = epoch + 1000) {
        observed.accepted_jd = begin;
        const std::pair<double, double> range{epoch, end};
        [controller configureWithJulianDate:begin range:range enabled:YES];
    }

    void wait_for_update() {
        const auto count = observed.successes;
        check(wait_until([&] { return observed.successes > count || !controller.playing; }),
              "NSTimer did not deliver a successful update before timeout");
        check(controller.playing && observed.successes > count, "playback stopped before successful timer update");
        check(observed.accepted_jd == controller.julianDate, "controller JD differs from accepted display JD");
        check(observed.on_main_thread && observed.monotonic, "callbacks left main thread or JD reversed direction");
    }

    void expect_quiet() {
        const auto attempts = observed.attempts;
        const auto stops = observed.stops;
        const double jd = controller.julianDate;
        pump_quiet_interval();
        check(!controller.playing && observed.attempts == attempts && controller.julianDate == jd,
              "stopped controller received another date update");
        check(observed.stops == stops, "stopped controller repeated didStop");
        check(observed.on_main_thread, "callback was not on main thread");
    }
};

void test_controls_pause_resume_and_rate() {
    Fixture fixture;
    auto *controller = fixture.controller;
    fixture.configure();
    NSButton *toggle = (NSButton *)find_control(controller.view, false);
    NSPopUpButton *rates = (NSPopUpButton *)find_control(controller.view, true);
    check(toggle && rates && rates.numberOfItems == 6, "playback controls or six rates missing");
    constexpr std::array<double, 6> values{{1, 60, 3600, 86400, 864000, 2592000}};
    for (NSUInteger index = 0; index < values.size(); ++index)
        check([rates itemAtIndex:index].representedObject &&
              [[rates itemAtIndex:index].representedObject doubleValue] == values[index], "speed menu value mismatch");
    check(rates.indexOfSelectedItem == 2, "default rate must be one simulation hour per second");

    send_action(toggle);
    check(controller.playing && fixture.observed.state_changes == 1, "play button did not notify playing state");
    [controller play];
    check(fixture.observed.state_changes == 1, "repeated play restarted playback");
    fixture.wait_for_update();
    check(controller.julianDate > epoch, "real timer did not advance JD");

    [rates selectItemAtIndex:3];
    const double before_rate_change = controller.julianDate;
    send_action(rates);
    check(controller.playing && fixture.observed.stops == 0 && controller.julianDate >= before_rate_change,
          "speed change stopped playback or moved JD backward");
    // 同じ旧速度の指定が UI へ戻ることで、popup の action が時計の速度を変えたことも確認する。
    [controller setSimulationRate:3600];
    check(rates.indexOfSelectedItem == 2 && controller.playing && fixture.observed.stops == 0,
          "popup action did not change the clock rate or rate change emitted didStop");
    fixture.wait_for_update();
    send_action(toggle);
    check(!controller.playing && fixture.observed.stops == 1 && fixture.observed.state_changes == 2,
          "pause must notify stateChanged and didStop once");
    check(controller.julianDate == fixture.observed.accepted_jd, "pause did not commit its last successful update");
    [controller pause];
    fixture.expect_quiet();

    const double paused_jd = controller.julianDate;
    send_action(toggle);
    check(controller.playing && controller.julianDate == paused_jd, "resume changed JD before its first update");
    fixture.wait_for_update();
    send_action(toggle);
    check(fixture.observed.stops == 2 && fixture.observed.state_changes == 4, "resume/pause notifications mismatch");
    fixture.expect_quiet();
}

void test_disabled_and_end_of_range() {
    Fixture fixture;
    auto *controller = fixture.controller;
    [controller play];
    check(!controller.playing && fixture.observed.attempts == 0, "unconfigured controller started");
    const std::pair<double, double> invalid_range{1, 0};
    [controller configureWithJulianDate:std::numeric_limits<double>::quiet_NaN() range:invalid_range enabled:NO];
    check(!find_control(controller.view, false).enabled && !find_control(controller.view, true).enabled,
          "disabled controller left controls enabled");
    check(!find_direction_control(controller.view).enabled, "disabled controller left direction control enabled");
    [controller play];
    check(!controller.playing && fixture.observed.attempts == 0 && fixture.observed.stops == 0,
          "disabled playback applied a date or emitted didStop");

    const double end = epoch + 0.000001;
    fixture.configure(epoch, end);
    [controller play];
    check(controller.playing, "short valid range refused playback");
    check(wait_until([&] { return !controller.playing; }), "range end did not stop playback");
    check(fixture.observed.successes > 0 && fixture.observed.accepted_jd == end && controller.julianDate == end,
          "range end was not applied and clamped exactly");
    check(fixture.observed.stops == 1 && fixture.observed.state_changes == 2, "range end stop notification mismatch");
    [controller play];
    check(!controller.playing && fixture.observed.stops == 1, "playback restarted or re-notified at range end");
    check(!find_control(controller.view, false).enabled, "play button enabled at range end");
    fixture.expect_quiet();
}

void test_reverse_controls_and_lower_boundary() {
    Fixture fixture;
    auto *controller = fixture.controller;
    fixture.configure(epoch + 1, epoch + 1);
    NSSegmentedControl *direction = find_direction_control(controller.view);
    NSPopUpButton *rates = (NSPopUpButton *)find_control(controller.view, true);
    NSButton *toggle = (NSButton *)find_control(controller.view, false);
    check(direction && direction.segmentCount == 2 && direction.selectedSegment == 1,
          "forward/reverse direction selector missing");
    check(!toggle.enabled, "forward playback must be disabled at upper boundary");
    direction.selectedSegment = 0;
    send_action(direction);
    fixture.observed.direction = -1;
    check(controller.simulationRate == -3600 && toggle.enabled,
          "direction selector did not allow reverse playback from upper boundary");
    send_action(toggle);
    fixture.wait_for_update();
    check(controller.julianDate < epoch + 1, "reverse timer did not decrease JD");
    [rates selectItemAtIndex:3];
    send_action(rates);
    check(controller.simulationRate == -86400 && controller.playing && fixture.observed.stops == 0,
          "speed selector did not preserve reverse direction");
    fixture.wait_for_update();
    [controller pause];
    fixture.expect_quiet();

    fixture.configure(epoch + 0.000001, epoch + 1);
    [controller playBackward];
    check(wait_until([&] { return !controller.playing; }), "reverse playback did not stop at lower boundary");
    check(controller.julianDate == epoch && fixture.observed.accepted_jd == epoch && !toggle.enabled,
          "reverse playback failed to clamp at the lower boundary");
    [controller play];
    check(!controller.playing, "reverse playback restarted at lower boundary");
    fixture.expect_quiet();

    fixture.observed.direction = 1;
    [controller playForward];
    check(controller.playing && controller.simulationRate == 86400 && direction.selectedSegment == 1,
          "forward command did not start from lower boundary");
    fixture.wait_for_update();
    [controller pause];
    fixture.expect_quiet();
}

void test_live_direction_changes_and_realtime() {
    Fixture fixture;
    auto *controller = fixture.controller;
    fixture.configure(epoch + 100, epoch + 1000);
    [controller setSimulationRate:86400];
    [controller playForward];
    fixture.wait_for_update();
    const double forward_jd = controller.julianDate;
    [controller playBackward];
    check(controller.playing && controller.simulationRate == -86400 &&
          controller.julianDate >= forward_jd && fixture.observed.stops == 0,
          "live reversal failed to commit the previous direction without stopping");
    fixture.observed.direction = -1;
    fixture.wait_for_update();
    const double backward_jd = controller.julianDate;
    [controller playRealtime];
    check(controller.playing && controller.simulationRate == 1 &&
          controller.julianDate <= backward_jd && fixture.observed.stops == 0,
          "real-time command did not preserve the display date while switching direction");
    fixture.observed.direction = 1;
    fixture.wait_for_update();
    [controller pause];
    const double accepted_jd = controller.julianDate;
    [controller setSimulationRate:-123.5];
    NSPopUpButton *rates = (NSPopUpButton *)find_control(controller.view, true);
    check(controller.simulationRate == -123.5 && rates.numberOfItems == 7 &&
          [rates.selectedItem.representedObject doubleValue] == 123.5,
          "custom reverse speed did not show its magnitude");
    [controller setSimulationRate:0];
    check(controller.simulationRate == -123.5 && controller.julianDate == accepted_jd,
          "invalid rate changed simulation state");
    [controller setSimulationRate:-60];
    check(rates.numberOfItems == 6 && rates.indexOfSelectedItem == 1,
          "standard reverse speed did not restore ordinary speed menu");
    fixture.expect_quiet();
}

void test_failed_apply_keeps_successful_date() {
    Fixture fixture;
    auto *controller = fixture.controller;
    fixture.configure();
    [controller play];
    fixture.wait_for_update();
    const double last_good_jd = fixture.observed.accepted_jd;
    const auto successes = fixture.observed.successes;
    const auto attempts = fixture.observed.attempts;
    fixture.observed.accept = false;
    check(wait_until([&] { return !controller.playing; }), "failed applyDate did not stop playback");
    check(fixture.observed.attempts == attempts + 1 && fixture.observed.successes == successes,
          "failed applyDate was retried or accepted");
    check(controller.julianDate == last_good_jd && fixture.observed.accepted_jd == last_good_jd &&
          fixture.observed.attempted_jd >= last_good_jd, "failed candidate replaced the last successful JD");
    check(fixture.observed.stops == 1 && fixture.observed.state_changes == 2, "failure stop notification mismatch");
    fixture.expect_quiet();
}

void test_interrupt_and_invalidate() {
    Fixture fixture;
    auto *controller = fixture.controller;
    fixture.configure();
    [controller play];
    fixture.wait_for_update();
    const double before_interrupt = controller.julianDate;
    const auto attempts = fixture.observed.attempts;
    [controller interruptWithMessage:@"test interruption"];
    check(!controller.playing && controller.julianDate == before_interrupt && fixture.observed.attempts == attempts,
          "interrupt advanced the last successful date");
    check(fixture.observed.stops == 1 && fixture.observed.state_changes == 2, "interrupt must notify stop once");
    [controller interruptWithMessage:@"test repeated interruption"];
    fixture.expect_quiet();

    [controller play];
    fixture.wait_for_update();
    const double before_invalidate = controller.julianDate;
    const auto attempts_before_invalidate = fixture.observed.attempts;
    [controller invalidate];
    check(!controller.playing && controller.julianDate == before_invalidate &&
          fixture.observed.attempts == attempts_before_invalidate, "invalidate advanced or retained playback");
    [controller play];
    check(!find_control(controller.view, false).enabled && !find_control(controller.view, true).enabled,
          "invalidate did not permanently disable controls");
    check(!find_direction_control(controller.view).enabled, "invalidated controller left direction control enabled");
    fixture.expect_quiet();
}

void test_plus_time_state() {
    using namespace mitaka::gui;
    Fixture fixture;
    auto *controller = fixture.controller;
    fixture.configure(epoch + 100, epoch + 1000);
    PlusTimeState plus{PlusTimeStepState(PlusTimeStep::day), 2};
    NSString *error = nil;
    check([controller setPlusTimeState:plus error:&error] && controller.playing,
          "Plus time failed to start");
    fixture.wait_for_update();
    check(controller.plusTimeState.speed == 2 && controller.simulationRate == 3600,
          "Plus playback overwrote native UI rate");
    const auto old = controller.plusTimeState;
    const double before = controller.julianDate;
    plus.step.set_value_days(std::numeric_limits<double>::max());
    check(![controller setPlusTimeState:plus error:&error] && error && controller.playing &&
          controller.julianDate == before && controller.plusTimeState.speed == old.speed &&
          controller.plusTimeState.step.step() == old.step.step(),
          "invalid Plus rate changed active state");
    plus = old;
    plus.step.set_value_days(0);
    check([controller setPlusTimeState:plus error:&error] && controller.playing,
          "zero custom duration must retain nonzero speed");
    const double zero_jd = controller.julianDate;
    const auto zero_attempts = fixture.observed.attempts;
    pump_quiet_interval();
    check(controller.playing && controller.plusTimeState.speed == 2 &&
          controller.julianDate == zero_jd && fixture.observed.attempts == zero_attempts,
          "zero duration advanced JD or discarded speed");
    plus.step.set_value_days(-1); plus.speed = 1;
    check([controller setPlusTimeState:plus error:&error], "negative custom duration refused");
    fixture.observed.direction = -1;
    fixture.wait_for_update();
    check(controller.julianDate < zero_jd, "negative custom playback did not reverse");
    [controller pause];
    check(controller.plusTimeState.speed == 0 && controller.plusTimeState.step.value_days() == -1,
          "pause must clear speed and retain Plus step duration");
    fixture.expect_quiet();
    plus.step.select(PlusTimeStep::hour); plus.speed = 2;
    check([controller setPlusTimeState:plus error:&error], "Plus resume failed");
    fixture.observed.direction = 1;
    [controller setSimulationRate:3600];
    check(controller.playing && controller.plusTimeState.speed == 0 && controller.simulationRate == 3600,
          "same native rate did not leave Plus playback");
    fixture.wait_for_update();
    [controller pause];
    check([controller setPlusTimeState:plus error:&error], "Plus sleep setup failed");
    [controller suspendForSystemSleep]; [controller resumeAfterSystemSleep];
    check(!controller.playing && controller.plusTimeState.speed == 0, "wake resumed Plus playback");
    check([controller setPlusTimeState:plus error:&error], "Plus hidden setup failed");
    [controller suspendForHiddenWindow];
    check(!controller.playing && controller.plusTimeState.speed == 0 &&
          ![controller setPlusTimeState:plus error:&error], "hidden Plus playback did not stop/refuse start");
    [controller resumeAfterHiddenWindow];
    fixture.expect_quiet();
    plus.speed = 0;
    plus.step.set_value_days(std::numeric_limits<double>::max());
    check([controller setPlusTimeState:plus error:&error] && !controller.playing,
          "stopped finite custom duration should be preserved");
    plus.step.select(PlusTimeStep::day); plus.speed = 1;
    fixture.configure(epoch, epoch + 0.000001);
    check([controller setPlusTimeState:plus error:&error], "Plus endpoint setup failed");
    check(wait_until([&] { return !controller.playing; }) && controller.plusTimeState.speed == 0 &&
          controller.julianDate == epoch + 0.000001, "Plus endpoint failed to clamp and clear speed");
    [controller invalidate];
    plus.speed = 0;
    check(![controller setPlusTimeState:plus error:&error], "invalidated Plus setter succeeded");
}

struct TrackingFixture {
    double unix_time = (epoch + 10 - 2440587.5) * 86400;
    double accepted_jd = epoch;
    NSUInteger attempts = 0, stops = 0;
    bool accept = true;
    PlaybackController *controller;
    TrackingFixture() {
        auto *state = this;
        controller = [[PlaybackController alloc] initWithUnixTimeProvider:^double { return state->unix_time; }];
        controller.applyDate = ^BOOL(double jd) {
            check(NSThread.isMainThread, "tracking update left main thread");
            ++state->attempts;
            if (!state->accept) return NO;
            state->accepted_jd = jd;
            return YES;
        };
        controller.didStop = ^{ ++state->stops; };
        [controller configureWithJulianDate:epoch range:std::make_pair(epoch, epoch + 1000) enabled:YES];
    }
    ~TrackingFixture() { [controller invalidate]; }
    TrackingFixture(const TrackingFixture&) = delete;
    TrackingFixture& operator=(const TrackingFixture&) = delete;
    double current_jd() const { return unix_time / 86400 + 2440587.5; }
    void await_current() {
        check(wait_until([&] { return controller.julianDate == current_jd(); }), "tracking timer did not read current UTC");
        check(accepted_jd == current_jd(), "tracking JD differed from displayed JD");
    }
    void expect_quiet() {
        const auto before = attempts;
        pump_quiet_interval();
        check(attempts == before, "suspended tracking retained an updating timer");
    }
};

void test_clock_tracking() {
    TrackingFixture fixture;
    auto *controller = fixture.controller;
    check([controller setClockTracking:YES] && controller.clockTracking && !controller.playing,
          "clock tracking was not distinct from playback");
    check(controller.julianDate == fixture.current_jd(), "tracking did not synchronize immediately");
    fixture.unix_time += 172800;
    fixture.await_current();
    fixture.unix_time -= 86400;
    fixture.await_current();
    check(controller.simulationRate == 3600 && fixture.stops == 0, "tracking changed playback rate or stopped on clock correction");
    NSButton *toggle = (NSButton *)find_control(controller.view, false);
    check(toggle.enabled && [toggle.title isEqualToString:@"一時停止"], "tracking did not expose pause action");
    send_action(toggle);
    check(!controller.clockTracking && fixture.stops == 1, "pause control did not exit tracking");
    fixture.unix_time += 86400;
    fixture.expect_quiet();
    check([controller setClockTracking:YES], "tracking did not restart after pause");
    [controller setSimulationRate:controller.simulationRate];
    check(!controller.clockTracking && !controller.playing, "manual rate selection retained tracking");
    check([controller setClockTracking:YES], "tracking restart failed before manual play");
    const double jd = controller.julianDate;
    [controller playBackward];
    check(!controller.clockTracking && controller.playing && controller.julianDate == jd,
          "manual playback did not leave tracking at last accepted date");
    [controller setClockTracking:NO];
    check(controller.playing, "disabling inactive clock tracking stopped ordinary playback");
    [controller pause];
    check([controller setClockTracking:YES], "tracking restart failed before configure");
    [controller configureWithJulianDate:epoch range:std::make_pair(epoch, epoch + 1000) enabled:YES];
    check(!controller.clockTracking && controller.julianDate == epoch, "manual date configuration retained tracking");
    fixture.expect_quiet();
}

void test_tracking_reentrant_playback_restart() {
    TrackingFixture fixture;
    PlaybackController *controller = fixture.controller;
    __block bool restart = true;
    __weak PlaybackController *weakController = controller;
    controller.stateChanged = ^{
        PlaybackController *active = weakController;
        if (restart && !active.playing && !active.clockTracking) {
            restart = false;
            [active play];
        }
    };
    [controller play];
    check(controller.playing, "reentrant tracking fixture did not start playback");
    check(![controller setClockTracking:YES], "tracking succeeded after callback restarted playback");
    check(controller.playing && !controller.clockTracking, "reentrant restart left two time modes active");
    controller.stateChanged = nil;
}

void test_play_reentrant_tracking_restart() {
    TrackingFixture fixture;
    PlaybackController *controller = fixture.controller;
    check([controller setClockTracking:YES], "tracking fixture did not start");
    __block bool restart = true;
    __weak PlaybackController *weakController = controller;
    controller.stateChanged = ^{
        PlaybackController *active = weakController;
        if (restart && !active.playing && !active.clockTracking) {
            restart = false;
            check([active setClockTracking:YES], "reentrant tracking restart failed");
        }
    };
    [controller play];
    check(!controller.playing && controller.clockTracking,
          "reentrant tracking restart left two time modes active");
    controller.stateChanged = nil;
}

void test_play_reentrant_animation_start() {
    TrackingFixture fixture;
    PlaybackController *controller = fixture.controller;
    check([controller setClockTracking:YES], "tracking fixture did not start");
    __block bool restart = true;
    __weak PlaybackController *weakController = controller;
    controller.stateChanged = ^{
        PlaybackController *active = weakController;
        if (restart && !active.playing && !active.clockTracking) {
            restart = false;
            check([active animateToJulianDate:epoch + 5 duration:10
                curve:mitaka::gui::PlusTimeAnimationCurve::linear
                sameTargetPolicy:mitaka::gui::PlusTimeAnimationSameTarget::replace error:nullptr],
                "reentrant animation start failed");
        }
    };
    [controller play];
    check(!controller.playing && controller.timeAnimating && !controller.clockTracking,
          "reentrant animation was superseded by the older play request");
    controller.stateChanged = nil;
}

void test_tracking_reentrant_same_mode() {
    TrackingFixture fixture;
    PlaybackController *controller = fixture.controller;
    __block bool restart = true;
    __weak PlaybackController *weakController = controller;
    controller.stateChanged = ^{
        PlaybackController *active = weakController;
        if (restart && !active.playing && !active.clockTracking) {
            restart = false;
            check([active setClockTracking:YES], "reentrant tracking start failed");
        }
    };
    [controller play];
    check([controller setClockTracking:YES], "already restarted tracking should succeed");
    check(!controller.playing && controller.clockTracking && fixture.attempts == 1,
          "reentrant tracking was started or sampled twice");
    controller.stateChanged = nil;
}

void test_configure_reentrant_notifications() {
    for (bool stop_callback : {false, true}) for (int operation = 0; operation != 3; ++operation) {
        TrackingFixture fixture;
        PlaybackController *controller = fixture.controller;
        check([controller setClockTracking:YES], "configuration fixture did not start tracking");
        __block bool invoked = false;
        __weak PlaybackController *weakController = controller;
        void (^callback)(void) = ^{
            PlaybackController *active = weakController;
            if (invoked) return;
            invoked = true;
            check(active.julianDate == epoch + 9.5, "configuration notification saw old date");
            if (operation == 0) check([active setClockTracking:YES], "configuration could not use new range");
            if (operation == 1) [active play];
            if (operation == 2) check([active animateToJulianDate:epoch + 10 duration:10
                curve:mitaka::gui::PlusTimeAnimationCurve::linear
                sameTargetPolicy:mitaka::gui::PlusTimeAnimationSameTarget::replace error:nullptr],
                "configuration could not start animation in new range");
        };
        if (stop_callback) controller.didStop = callback; else controller.stateChanged = callback;
        [controller configureWithJulianDate:epoch + 9.5 range:{epoch + 9, epoch + 11} enabled:YES];
        check(invoked, "configuration stop notification was not delivered");
        if (operation == 0) check(controller.clockTracking && !controller.playing &&
            controller.julianDate == fixture.current_jd() && fixture.accepted_jd == controller.julianDate,
            "configuration overwrote the newer tracking operation");
        if (operation == 1) check(controller.playing && !controller.clockTracking && controller.julianDate == epoch + 9.5,
            "configuration overwrote the newer playback operation");
        if (operation == 2) check(controller.timeAnimating && !controller.playing && controller.julianDate == epoch + 9.5,
            "configuration overwrote the newer animation operation");
        controller.stateChanged = nil; controller.didStop = nil;
    }
    {
        TrackingFixture fixture;
        PlaybackController *controller = fixture.controller;
        check([controller setClockTracking:YES], "disabled configuration fixture did not start");
        __block bool invoked = false;
        __weak PlaybackController *weakController = controller;
        controller.stateChanged = ^{
            PlaybackController *active = weakController;
            if (invoked) return;
            invoked = true;
            check(![active setClockTracking:YES], "tracking restarted against disabled configuration");
            [active play];
        };
        [controller configureWithJulianDate:epoch + 3 range:{0, 1} enabled:NO];
        check(invoked && !controller.clockTracking && !controller.playing && controller.julianDate == epoch + 3,
              "disabled configuration was not applied before notification");
        controller.stateChanged = nil;
    }
    {
        TrackingFixture fixture;
        PlaybackController *controller = fixture.controller;
        check([controller setClockTracking:YES], "recursive configuration fixture did not start");
        __block bool invoked = false;
        __weak PlaybackController *weakController = controller;
        controller.stateChanged = ^{
            if (invoked) return;
            invoked = true;
            [weakController configureWithJulianDate:epoch + 7 range:{epoch, epoch + 20} enabled:YES];
        };
        [controller configureWithJulianDate:epoch + 5 range:{epoch, epoch + 15} enabled:YES];
        check(invoked && controller.julianDate == epoch + 7 && !controller.clockTracking,
              "outer configuration overwrote recursive configuration");
        controller.stateChanged = nil;
    }
}

void test_rate_reentrant_notifications() {
    for (int operation = 0; operation != 6; ++operation) {
        TrackingFixture fixture;
        PlaybackController *controller = fixture.controller;
        check([controller setClockTracking:YES], "rate fixture did not start tracking");
        __block bool invoked = false;
        __weak PlaybackController *weakController = controller;
        controller.stateChanged = ^{
            PlaybackController *active = weakController;
            if (invoked || active.clockTracking || active.playing || active.timeAnimating) return;
            invoked = true;
            switch (operation) {
                case 0: check([active setClockTracking:YES], "tracking restart failed"); break;
                case 1: [active setSimulationRate:60]; break;
                case 2: [active play]; break;
                case 3: [active invalidate]; break;
                case 5: [active setSimulationRate:3600]; break;
                case 4: check([active animateToJulianDate:epoch + 20 duration:10
                    curve:mitaka::gui::PlusTimeAnimationCurve::linear
                    sameTargetPolicy:mitaka::gui::PlusTimeAnimationSameTarget::replace error:nullptr],
                    "animation restart failed"); break;
            }
        };
        [controller setSimulationRate:86400];
        check(invoked, "rate stop notification was not delivered");
        if (operation == 0) check(controller.clockTracking && controller.simulationRate == 3600,
                                  "rate change overwrote resumed tracking");
        if (operation == 1) check(controller.simulationRate == 60 && !controller.clockTracking,
                                  "outer rate overwrote recursive rate");
        if (operation == 2) check(controller.playing && controller.simulationRate == 3600,
                                  "outer rate overwrote resumed playback");
        if (operation == 3) check(controller.simulationRate == 3600 && !find_control(controller.view, false).enabled,
                                  "rate changed after invalidation");
        if (operation == 5) check(controller.simulationRate == 3600, "outer rate overwrote same-rate request");
        if (operation == 4) check(controller.timeAnimating && controller.simulationRate == 3600,
                                  "rate change overwrote resumed animation");
        controller.stateChanged = nil;
    }
    {
        TrackingFixture fixture;
        PlaybackController *controller = fixture.controller;
        [controller play];
        fixture.accept = false;
        const auto attempts = fixture.attempts;
        __block bool restarted = false;
        __weak PlaybackController *weakController = controller;
        controller.stateChanged = ^{
            PlaybackController *active = weakController;
            if (!restarted && !active.playing) { restarted = true; [active play]; }
        };
        // サンプルが整数 JD から進む時間を確保し、applyDate の拒否を誘発する。
        std::this_thread::sleep_for(std::chrono::milliseconds(20));
        [controller setSimulationRate:86400];
        check(fixture.attempts > attempts && restarted && controller.playing && controller.simulationRate == 3600,
              "rejected sample overwrote playback restarted by stop notification");
        controller.stateChanged = nil;
    }
}

void test_composed_rate_reentrant_notifications() {
    for (int command = 0; command != 3; ++command) for (bool animate : {false, true}) {
        TrackingFixture fixture;
        PlaybackController *controller = fixture.controller;
        check([controller setClockTracking:YES], "composed rate fixture did not start tracking");
        __block bool invoked = false;
        __weak PlaybackController *weakController = controller;
        controller.stateChanged = ^{
            PlaybackController *active = weakController;
            if (invoked || active.clockTracking) return;
            invoked = true;
            if (animate) {
                check([active animateToJulianDate:epoch + 20 duration:10
                    curve:mitaka::gui::PlusTimeAnimationCurve::linear
                    sameTargetPolicy:mitaka::gui::PlusTimeAnimationSameTarget::replace error:nullptr],
                    "composed rate animation failed");
            } else {
                check([active setClockTracking:YES], "composed rate tracking restart failed");
            }
        };
        if (command == 0) [controller playForward];
        if (command == 1) [controller playBackward];
        if (command == 2) [controller playRealtime];
        check(invoked && !controller.playing && controller.simulationRate == 3600 &&
              (animate ? controller.timeAnimating : controller.clockTracking),
              "composed rate command overwrote newer callback operation");
        controller.stateChanged = nil;
    }
}

void test_rate_controls_reentrant_same_rate() {
    for (bool direction : {false, true}) {
        TrackingFixture fixture;
        PlaybackController *controller = fixture.controller;
        check([controller setClockTracking:YES], "rate control fixture did not start tracking");
        __block bool invoked = false;
        __weak PlaybackController *weakController = controller;
        controller.stateChanged = ^{
            if (invoked) return;
            invoked = true;
            check([weakController setSimulationRate:3600], "same-rate callback failed");
        };
        NSPopUpButton *rates = (NSPopUpButton *)find_control(controller.view, true);
        NSSegmentedControl *segments = find_direction_control(controller.view);
        if (direction) { segments.selectedSegment = 0; send_action(segments); }
        else { [rates selectItemAtIndex:3]; send_action(rates); }
        check(invoked && !controller.clockTracking && controller.simulationRate == 3600 &&
              [rates.selectedItem.representedObject doubleValue] == 3600 && segments.selectedSegment == 1,
              "rate controls disagree with the reentrant same-rate request");
        check(fixture.stops == 1, "same-rate callback suppressed the stop notification");
        controller.stateChanged = nil;
    }
}

void test_tracking_sleep_and_hidden_window() {
    TrackingFixture fixture;
    auto *controller = fixture.controller;
    check([controller setClockTracking:YES], "tracking did not start before sleep");
    [controller suspendForSystemSleep];
    fixture.unix_time += 86400;
    fixture.expect_quiet();
    check(controller.clockTracking && fixture.stops == 0, "sleep cancelled tracking request");
    [controller suspendForHiddenWindow];
    [controller resumeAfterSystemSleep];
    fixture.expect_quiet();
    check(controller.julianDate != fixture.current_jd(), "wake resumed a still hidden window");
    [controller resumeAfterHiddenWindow];
    check(controller.julianDate == fixture.current_jd(), "visible wake failed immediate current UTC sync");
    fixture.unix_time += 60;
    fixture.await_current();
    [controller suspendForHiddenWindow];
    [controller suspendForSystemSleep];
    fixture.unix_time += 86400;
    [controller resumeAfterHiddenWindow];
    fixture.expect_quiet();
    [controller resumeAfterSystemSleep];
    check(controller.julianDate == fixture.current_jd(), "wake failed after hidden flag cleared first");
    [controller suspendForSystemSleep];
    [controller setClockTracking:NO];
    [controller resumeAfterSystemSleep];
    check(!controller.clockTracking, "wake revived explicitly disabled tracking");
    [controller play];
    check(controller.playing, "ordinary play did not start after wake");
    [controller suspendForSystemSleep];
    [controller resumeAfterSystemSleep];
    check(!controller.playing && !controller.clockTracking, "wake restarted ordinary playback");
    fixture.expect_quiet();
}

void test_tracking_failures_and_invalidation() {
    TrackingFixture fixture;
    auto *controller = fixture.controller;
    check([controller setClockTracking:YES], "tracking did not start before failure test");
    const double good = controller.julianDate;
    fixture.accept = false;
    fixture.unix_time += 60;
    check(wait_until([&] { return !controller.clockTracking; }), "failed tracking apply did not stop");
    check(controller.julianDate == good && fixture.accepted_jd == good, "failed tracking date replaced last display");
    fixture.expect_quiet();
    fixture.accept = true;
    for (double invalid_time : {std::numeric_limits<double>::quiet_NaN(),
                               std::numeric_limits<double>::infinity(),
                               (epoch - 1 - 2440587.5) * 86400,
                               (epoch + 1001 - 2440587.5) * 86400}) {
        fixture.unix_time = invalid_time;
        const auto attempts = fixture.attempts;
        check(![controller setClockTracking:YES] && !controller.clockTracking && controller.julianDate == good,
              "tracking accepted invalid clock or discarded last display");
        check(fixture.attempts == attempts, "invalid UTC was sent to applyDate");
    }
    fixture.unix_time = (epoch + 20 - 2440587.5) * 86400;
    check([controller setClockTracking:YES], "valid tracking did not recover from rejected clock");
    [controller invalidate];
    check(!controller.clockTracking && ![controller setClockTracking:YES], "invalidated tracking restarted");
    fixture.expect_quiet();
    PlaybackController *disabled = [[PlaybackController alloc] init];
    check(![disabled setClockTracking:YES], "tracking started without configured data");
    [disabled invalidate];
}
} // namespace

int main() {
    @autoreleasepool {
        try {
            check(NSThread.isMainThread, "AppKit tests require the main thread");
            [NSApplication sharedApplication];
            test_controls_pause_resume_and_rate();
            test_disabled_and_end_of_range();
            test_reverse_controls_and_lower_boundary();
            test_live_direction_changes_and_realtime();
            test_failed_apply_keeps_successful_date();
            test_interrupt_and_invalidate();
            test_plus_time_state();
            test_clock_tracking();
            test_tracking_reentrant_playback_restart();
            test_tracking_reentrant_same_mode();
            test_play_reentrant_tracking_restart();
            test_play_reentrant_animation_start();
            test_configure_reentrant_notifications();
            test_rate_reentrant_notifications();
            test_composed_rate_reentrant_notifications();
            test_rate_controls_reentrant_same_rate();
            test_tracking_sleep_and_hidden_window();
            test_tracking_failures_and_invalidation();
            std::cout << "PlaybackController AppKit tests passed: timer, UI actions, pause/resume, rates, "
                         "forward/reverse, lower/upper boundaries, realtime, disabled, failure, interrupt, invalidate, "
                         "UTC tracking, clock correction, sleep/hidden recovery, tracking failure\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "PlaybackController AppKit test failed: " << error.what() << '\n';
            return 1;
        }
    }
}
