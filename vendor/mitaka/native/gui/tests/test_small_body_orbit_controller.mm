#import "SmallBodyOrbitController.h"
#include "small_body_orbit_test_fixture.hpp"

#include <atomic>
#include <iostream>
#include <stdexcept>
#include <thread>

using namespace mitaka;
using namespace mitaka::gui;
using OrbitSnapshot = std::shared_ptr<const SmallBodyOrbitSnapshot>;
using OrbitEvaluator = std::function<std::shared_ptr<const SmallBodyOrbitSnapshot>(
    std::shared_ptr<const SmallBodyModel>, std::shared_ptr<const SmallBodyDisplayModel>,
    SmallBodyOrbitSampling, std::function<bool()>)>;

namespace {
unsigned checks = 0;
void require(bool value, const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
template<class Exception = std::invalid_argument, class Function>
void rejects(Function action, const char* message) {
    try { action(); } catch (const Exception&) { require(true, message); return; }
    require(false, message);
}
void spin(bool (^done)(void)) {
    const auto deadline = [NSDate dateWithTimeIntervalSinceNow:5];
    while (!done() && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.002]];
    require(done(), "async orbit operation completes within the bounded wait");
}
struct Probe {
    std::atomic<unsigned> calls{0}, finished{0}, cancellations{0};
    std::atomic<unsigned> fail{0};
    dispatch_semaphore_t permit = dispatch_semaphore_create(0);
};
struct Finished {
    std::shared_ptr<Probe> probe;
    ~Finished() { ++probe->finished; }
};
}

// 計算境界だけで待機し、実際の queue・世代判定・main callback は製品コードを通す。
@interface ControlledOrbitController : SmallBodyOrbitController
- (instancetype)initWithProbe:(std::shared_ptr<Probe>)probe;
- (OrbitEvaluator)orbitEvaluator;
@end
@implementation ControlledOrbitController {
    std::shared_ptr<Probe> _probe;
}
- (instancetype)initWithProbe:(std::shared_ptr<Probe>)probe {
    if ((self = [super init])) _probe = std::move(probe);
    return self;
}
- (OrbitEvaluator)orbitEvaluator {
    const auto probe = _probe;
    return [probe](auto model, auto display, auto sampling, auto cancelled) {
        ++probe->calls;
        Finished finished{probe};
        if (dispatch_semaphore_wait(probe->permit, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)))
            throw std::runtime_error("test evaluator permit timed out");
        if (NSThread.isMainThread) throw std::runtime_error("orbit evaluation unexpectedly uses main thread");
        const auto failure = probe->fail.exchange(0);
        if (failure == 1) throw std::runtime_error("synthetic evaluator failure");
        if (failure == 2) throw std::runtime_error(std::string("invalid byte: ") + char(0xff));
        if (cancelled()) ++probe->cancellations;
        return evaluate_small_body_orbit_snapshot(model, display, sampling, cancelled);
    };
}
@end

namespace {
void coalescing_and_cache() {
    const auto data = orbit_test::dataset(4);
    const auto model = std::make_shared<SmallBodyModel>(data);
    const auto display = orbit_test::display(data);
    auto labels = std::make_shared<SmallBodyDisplayModel>(*display);
    labels->set_kind_options(SmallBodyKind::comet, {true, true, true, false});
    const auto probe = std::make_shared<Probe>();
    SmallBodyOrbitController *controller = [[ControlledOrbitController alloc] initWithProbe:probe];
    __block unsigned superseded = 0, completed = 0;
    __block std::shared_ptr<const SmallBodyOrbitSnapshot> frame;
    [controller requestModel:model display:display sampling:orbit_test::sampling
        completion:^(OrbitSnapshot, NSString *) { ++superseded; }];
    spin(^{ return probe->calls == 1; });
    [controller requestModel:model display:labels sampling:orbit_test::sampling completion:^(OrbitSnapshot value, NSString *error) {
        require(NSThread.isMainThread && !error && value && !value->cancelled, "completed work reaches main thread");
        frame = value; ++completed;
    }];
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return completed == 1; });
    require(superseded == 0 && probe->calls == 1 && frame->display == display,
        "equivalent pending geometry computes once and calls only the latest completion");
    const auto cached = frame;
    [controller requestModel:model display:labels sampling:orbit_test::sampling completion:^(OrbitSnapshot value, NSString *error) {
        require(value == cached && !error, "label-only change returns the same immutable cached geometry");
        ++completed;
    }];
    require(completed == 1, "cached completion is asynchronous like new work");
    spin(^{ return completed == 2; });
    require(probe->calls == 1, "cached interval does not resample during unrelated date updates");

    auto selected = std::make_shared<SmallBodyDisplayModel>(*display);
    selected->set_selected_ids({data->records[3].id});
    selected->set_kind_options(SmallBodyKind::comet, {true, false, true, true});
    [controller requestModel:model display:selected sampling:orbit_test::sampling completion:^(OrbitSnapshot value, NSString *error) {
        require(!error && value->requested_count == 1 && value->paths[3] && !value->paths[0],
            "changed request membership receives independently sampled geometry");
        ++completed;
    }];
    spin(^{ return probe->calls == 2; });
    rejects([&] { [controller requestModel:model display:display sampling:SmallBodyOrbitSampling{0, 0, 5} completion:^(OrbitSnapshot, NSString *) {}]; },
        "invalid interval rejects synchronously");
    rejects([&] { [controller requestModel:nullptr display:display sampling:orbit_test::sampling completion:^(OrbitSnapshot, NSString *) {}]; },
        "null model rejects synchronously");
    rejects([&] { [controller requestModel:model display:display sampling:orbit_test::sampling completion:nil]; },
        "missing completion rejects synchronously");
    const auto oversized_data = orbit_test::dataset(129);
    const auto oversized_model = std::make_shared<SmallBodyModel>(oversized_data);
    const auto oversized_display = orbit_test::display(oversized_data);
    rejects<std::length_error>([&] {
        [controller requestModel:oversized_model display:oversized_display sampling:SmallBodyOrbitSampling{2451535, 2451555, 4096}
            completion:^(OrbitSnapshot, NSString *) {}];
    }, "sample cap rejects synchronously before cancelling valid pending work");
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return completed == 3; });
    require(probe->cancellations == 0, "invalid requests do not cancel previously valid pending work");

    __block unsigned reentered = 0;
    [controller requestModel:model display:selected sampling:orbit_test::sampling completion:^(OrbitSnapshot, NSString *error) {
        require(!error, "cached result is available for callback reentry");
        ++reentered;
        [controller requestModel:model display:selected sampling:orbit_test::sampling completion:^(OrbitSnapshot, NSString *nextError) {
            require(!nextError, "a completion may immediately request the next result"); ++reentered;
        }];
    }];
    spin(^{ return reentered == 2; });
    require(probe->calls == 2, "reentrant cache requests do not restart evaluation");
    [controller invalidate];
}

void replacement_cancellation_and_errors() {
    const auto data = orbit_test::dataset(2);
    const auto model = std::make_shared<SmallBodyModel>(data);
    const auto display = orbit_test::display(data);
    const auto probe = std::make_shared<Probe>();
    SmallBodyOrbitController *controller = [[ControlledOrbitController alloc] initWithProbe:probe];
    __block unsigned stale = 0, completed = 0;
    __block std::shared_ptr<const SmallBodyOrbitSnapshot> final_frame;
    [controller requestModel:model display:display sampling:orbit_test::sampling completion:^(OrbitSnapshot, NSString *) { ++stale; }];
    spin(^{ return probe->calls == 1; });
    const SmallBodyOrbitSampling later{2452000, 2452020, 7};
    [controller requestModel:model display:display sampling:later completion:^(OrbitSnapshot value, NSString *error) {
        require(!error && value->sampling.first_jd == later.first_jd && value->sampling.sample_count == 7,
            "changed absolute TDB interval wins over the previous request");
        final_frame = value; ++completed;
    }];
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return probe->calls == 2; });
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return completed == 1; });
    require(stale == 0 && probe->cancellations == 1, "older running generation is cancelled and never applied");

    [controller requestModel:model display:display sampling:orbit_test::sampling completion:^(OrbitSnapshot, NSString *) { ++stale; }];
    spin(^{ return probe->calls == 3; });
    [controller cancel];
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return probe->finished == 3; });
    const auto cached = final_frame;
    [controller requestModel:model display:display sampling:later completion:^(OrbitSnapshot value, NSString *error) {
        require(value == cached && !error, "hide cancellation keeps completed geometry for redisplay"); ++completed;
    }];
    spin(^{ return completed == 2; });
    require(stale == 0 && probe->calls == 3, "hidden pending computation cannot overwrite the reusable cache");

    const auto replacement_data = orbit_test::dataset(2);
    const auto replacement = std::make_shared<SmallBodyModel>(replacement_data);
    const auto replacement_display = orbit_test::display(replacement_data);
    [controller requestModel:replacement display:replacement_display sampling:later completion:^(OrbitSnapshot value, NSString *error) {
        require(value->model == replacement && value != cached && !error, "reload identity prevents stale model cache reuse"); ++completed;
    }];
    spin(^{ return probe->calls == 4; });
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return completed == 3; });
    probe->fail = true;
    [controller requestModel:replacement display:replacement_display sampling:orbit_test::sampling completion:^(OrbitSnapshot value, NSString *error) {
        require(NSThread.isMainThread && !value && [error containsString:@"synthetic evaluator failure"],
            "worker failure is delivered explicitly on main without an old success result"); ++completed;
    }];
    spin(^{ return probe->calls == 5; });
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return completed == 4; });
    [controller requestModel:replacement display:replacement_display sampling:orbit_test::sampling completion:^(OrbitSnapshot value, NSString *error) {
        require(value && !error, "failed geometry is retried rather than cached as success"); ++completed;
    }];
    spin(^{ return probe->calls == 6; });
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return completed == 5; });
    [controller requestModel:model display:display sampling:later completion:^(OrbitSnapshot, NSString *) { ++stale; }];
    spin(^{ return probe->calls == 7; });
    [controller invalidate];
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return probe->finished == 7; });
    rejects<std::logic_error>([&] { [controller requestModel:model display:display sampling:later completion:^(OrbitSnapshot, NSString *) {}]; },
        "invalidated controller refuses new requests");
    require(stale == 0 && probe->cancellations == 3, "shutdown discards running results and preserves prior cancellations");
}

void lifecycle_and_thread_boundary() {
    const auto data = orbit_test::dataset(1);
    const auto model = std::make_shared<SmallBodyModel>(data);
    const auto display = orbit_test::display(data);
    const auto probe = std::make_shared<Probe>();
    SmallBodyOrbitController *controller = [[ControlledOrbitController alloc] initWithProbe:probe];
    __weak SmallBodyOrbitController *weak_controller = controller;
    __block unsigned completions = 0;
    [controller requestModel:model display:display sampling:orbit_test::sampling completion:^(OrbitSnapshot, NSString *) { ++completions; }];
    spin(^{ return probe->calls == 1; });
    controller = nil;
    require(weak_controller == nil, "worker does not retain its controller or UI lifetime");
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return probe->finished == 1; });
    require(completions == 0 && probe->cancellations == 1, "deallocation cancels active work without invoking callback");
    controller = [[SmallBodyOrbitController alloc] init];
    std::atomic<unsigned> rejected{0};
    std::thread worker([&] {
        @autoreleasepool {
            try { [controller cancel]; } catch (const std::logic_error&) { ++rejected; }
            try { [controller invalidate]; } catch (const std::logic_error&) { ++rejected; }
            try { [controller requestModel:model display:display sampling:orbit_test::sampling completion:^(OrbitSnapshot, NSString *) {}]; }
            catch (const std::logic_error&) { ++rejected; }
            try { (void)[[SmallBodyOrbitController alloc] init]; } catch (const std::logic_error&) { ++rejected; }
        }
    });
    worker.join();
    require(rejected == 4, "all controller mutations and construction enforce main-thread ownership");
    [controller requestModel:model display:display sampling:orbit_test::sampling completion:^(OrbitSnapshot value, NSString *error) {
        require(value && !error && NSThread.isMainThread, "production evaluator and main queue work without the test seam"); ++completions;
    }];
    spin(^{ return completions == 1; });
    [controller invalidate];
}

void invalid_error_encoding() {
    const auto data = orbit_test::dataset(1);
    const auto model = std::make_shared<SmallBodyModel>(data);
    const auto display = orbit_test::display(data);
    const auto probe = std::make_shared<Probe>();
    SmallBodyOrbitController *controller = [[ControlledOrbitController alloc] initWithProbe:probe];
    __block unsigned completed = 0;
    __block OrbitSnapshot cached;
    [controller requestModel:model display:display sampling:orbit_test::sampling completion:^(OrbitSnapshot value, NSString *error) {
        require(value && !error, "valid cached snapshot precedes malformed exception diagnostic");
        cached = value; ++completed;
    }];
    spin(^{ return probe->calls == 1; });
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return completed == 1; });
    probe->fail = 2;
    [controller requestModel:model display:display sampling:SmallBodyOrbitSampling{2452000, 2452020, 5}
        completion:^(OrbitSnapshot value, NSString *error) {
            require(!value && error && [error containsString:@"invalid UTF-8 diagnostic"],
                "non-UTF8 worker exception remains an explicit failure instead of returning stale cached success");
            ++completed;
        }];
    spin(^{ return probe->calls == 2; });
    dispatch_semaphore_signal(probe->permit);
    spin(^{ return completed == 2; });
    [controller requestModel:model display:display sampling:orbit_test::sampling completion:^(OrbitSnapshot value, NSString *error) {
        require(value == cached && !error, "failure does not destroy a separate valid cached request"); ++completed;
    }];
    spin(^{ return completed == 3; });
    require(probe->calls == 2, "valid previous key remains reusable without additional evaluation");
    [controller invalidate];
}
}
int main() {
    @autoreleasepool {
        try {
            coalescing_and_cache(); replacement_cancellation_and_errors(); lifecycle_and_thread_boundary(); invalid_error_encoding();
            std::cout << "Small-body orbit controller tests passed: " << checks << " checks\n";
            return 0;
        } catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
