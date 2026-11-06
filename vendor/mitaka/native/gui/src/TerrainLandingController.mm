#import "TerrainLandingController.h"
#include <atomic>

using namespace mitaka::gui;
namespace {
using LandingEvaluator = std::function<TerrainLandingResult(const TerrainLandingRequest&, const std::function<bool()>&)>;
void require_main_thread() {
    if (!NSThread.isMainThread) throw std::logic_error("terrain landing controller requires main thread");
}
}
@implementation TerrainLandingController {
    dispatch_queue_t _queue;
    std::shared_ptr<std::atomic<std::uint64_t>> _generation;
    std::optional<TerrainLandingRequest> _pending;
    TerrainLandingCompletion _completion;
    BOOL _running;
    BOOL _invalidated;
}
- (instancetype)init {
    require_main_thread();
    if ((self=[super init])) {
        _queue=dispatch_queue_create("org.mitaka.terrain-landing",DISPATCH_QUEUE_SERIAL);
        _generation=std::make_shared<std::atomic<std::uint64_t>>(0);
    }
    return self;
}
- (void)dealloc { if (_generation) _generation->fetch_add(1,std::memory_order_relaxed); }
- (LandingEvaluator)landingEvaluator { return prepare_terrain_landing; }
- (void)requestLanding:(TerrainLandingRequest)request completion:(TerrainLandingCompletion)completion {
    require_main_thread();
    if (_invalidated) throw std::logic_error("terrain landing controller is invalidated");
    if (!completion) throw std::invalid_argument("terrain landing request requires completion");
    validate_terrain_landing_request(request);
    _generation->fetch_add(1,std::memory_order_relaxed);
    _pending=std::move(request);
    _completion=[completion copy];
    [self startPending];
}
- (void)startPending {
    if (_running || !_pending || _invalidated) return;
    const auto request=std::move(*_pending); _pending.reset();
    const auto generation=_generation;
    const auto ticket=generation->load(std::memory_order_relaxed);
    const auto evaluator=[self landingEvaluator];
    _running=YES;
    __weak TerrainLandingController *weakSelf=self;
    dispatch_async(_queue,^{
        @autoreleasepool {
            const auto cancelled=[generation,ticket]{ return generation->load(std::memory_order_relaxed)!=ticket; };
            TerrainLandingResult result;
            NSString *failure=nil;
            try {
                if(cancelled()) throw TerrainSurfaceCancelled();
                result=evaluator(request,cancelled);
                if(cancelled()) throw TerrainSurfaceCancelled();
            } catch(const TerrainSurfaceCancelled&) {
                failure=@"Terrain landing request was cancelled";
            } catch(const std::exception& error) {
                failure=[NSString stringWithUTF8String:error.what()];
                if(!failure) failure=@"Terrain landing preparation failed (invalid UTF-8 diagnostic)";
            }
            dispatch_async(dispatch_get_main_queue(),^{ [weakSelf finishResult:result error:failure generation:ticket]; });
        }
    });
}
- (void)finishResult:(TerrainLandingResult)result error:(NSString *)error generation:(std::uint64_t)ticket {
    require_main_thread();
    _running=NO;
    if(!_invalidated && _generation->load(std::memory_order_relaxed)==ticket) {
        TerrainLandingCompletion completion=_completion;
        _completion=nil;
        if(completion) completion(result,error);
    }
    [self startPending];
}
- (void)cancel {
    require_main_thread();
    _generation->fetch_add(1,std::memory_order_relaxed);
    _pending.reset(); _completion=nil;
}
- (void)invalidate { require_main_thread(); [self cancel]; _invalidated=YES; }
@end
