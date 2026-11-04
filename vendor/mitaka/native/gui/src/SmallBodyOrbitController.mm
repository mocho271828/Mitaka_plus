#import "SmallBodyOrbitController.h"

#include <atomic>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
using OrbitEvaluator = std::function<std::shared_ptr<const SmallBodyOrbitSnapshot>(
    std::shared_ptr<const SmallBodyModel>, std::shared_ptr<const SmallBodyDisplayModel>,
    SmallBodyOrbitSampling, std::function<bool()>)>;

struct OrbitRequest {
    std::shared_ptr<const SmallBodyModel> model;
    SmallBodyOrbitSampling sampling;
    std::vector<std::size_t> rows;

    bool matches(const OrbitRequest& other) const {
        return model == other.model && sampling.first_jd == other.sampling.first_jd
            && sampling.last_jd == other.sampling.last_jd
            && sampling.sample_count == other.sampling.sample_count && rows == other.rows;
    }
};
void require_main_thread() {
    if (!NSThread.isMainThread)
        throw std::logic_error("small-body orbit controller requires main thread");
}
}

@implementation SmallBodyOrbitController {
    dispatch_queue_t _queue;
    std::shared_ptr<std::atomic<std::uint64_t>> _generation;
    std::optional<OrbitRequest> _pending, _cachedRequest;
    std::shared_ptr<const SmallBodyOrbitSnapshot> _cached;
    SmallBodyOrbitCompletion _completion;
    BOOL _invalidated;
}

- (instancetype)init {
    require_main_thread();
    if ((self = [super init])) {
        _queue = dispatch_queue_create("org.mitaka.small-body-orbits", DISPATCH_QUEUE_SERIAL);
        _generation = std::make_shared<std::atomic<std::uint64_t>>(0);
    }
    return self;
}
- (void)dealloc { if (_generation) _generation->fetch_add(1, std::memory_order_relaxed); }

// 計算と queue の境界。試験ではここだけを差し替え、取消と完了順を確定させる。
- (OrbitEvaluator)orbitEvaluator { return evaluate_small_body_orbit_snapshot; }

- (void)requestModel:(std::shared_ptr<const SmallBodyModel>)model
             display:(std::shared_ptr<const SmallBodyDisplayModel>)display
            sampling:(SmallBodyOrbitSampling)sampling
          completion:(SmallBodyOrbitCompletion)completion {
    require_main_thread();
    if (_invalidated) throw std::logic_error("small-body orbit controller is invalidated");
    if (!model || !display || !completion)
        throw std::invalid_argument("small-body orbit request requires model, display and completion");
    OrbitRequest request{model, sampling, small_body_orbit_requested_rows(*model, *display, sampling)};
    if (_pending && _pending->matches(request)) {
        _completion = [completion copy];
        return;
    }
    const auto generation = _generation;
    const auto ticket = generation->fetch_add(1, std::memory_order_relaxed) + 1;
    _pending = request;
    _completion = [completion copy];
    __weak SmallBodyOrbitController *weakSelf = self;
    if (_cachedRequest && _cachedRequest->matches(request)) {
        const auto cached = _cached;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf finishSnapshot:cached error:nil generation:ticket];
        });
        return;
    }
    const auto evaluator = [self orbitEvaluator];
    dispatch_async(_queue, ^{
        @autoreleasepool {
            const auto cancelled = [generation, ticket] {
                return generation->load(std::memory_order_relaxed) != ticket;
            };
            if (cancelled()) return;
            try {
                const auto snapshot = evaluator(model, display, sampling, cancelled);
                if (cancelled() || snapshot->cancelled) return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf finishSnapshot:snapshot error:nil generation:ticket];
                });
            } catch (const std::exception& error) {
                NSString *message = [NSString stringWithUTF8String:error.what()];
                // 外部パス等を含む例外が UTF-8 でない場合も、失敗を成功 cache と混同しない。
                if (!message) message = @"Small-body orbit evaluation failed (invalid UTF-8 diagnostic)";
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf finishSnapshot:nullptr error:message generation:ticket];
                });
            }
        }
    });
}

- (void)finishSnapshot:(std::shared_ptr<const SmallBodyOrbitSnapshot>)snapshot
                 error:(NSString *)error generation:(std::uint64_t)ticket {
    require_main_thread();
    if (_invalidated || !_pending || _generation->load(std::memory_order_relaxed) != ticket) return;
    if (snapshot) {
        _cached = std::move(snapshot);
        _cachedRequest = std::move(_pending);
    }
    _pending.reset();
    SmallBodyOrbitCompletion completion = _completion;
    _completion = nil;
    // callback 内の再要求を妨げないよう、先に pending を解除する。
    completion(error ? nullptr : _cached, error);
}
- (void)cancel {
    require_main_thread();
    _generation->fetch_add(1, std::memory_order_relaxed);
    _pending.reset();
    _completion = nil;
}
- (void)invalidate {
    require_main_thread();
    [self cancel];
    _cached.reset();
    _cachedRequest.reset();
    _invalidated = YES;
}
@end
