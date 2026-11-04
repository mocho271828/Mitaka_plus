#import "TerrainSurfaceController.h"

#include <atomic>

using namespace mitaka::gui;

namespace {
using TerrainEvaluator = std::function<std::shared_ptr<const TerrainSurfaceSnapshot>(
    const TerrainSurfaceRequest&, std::uint64_t, const std::function<bool()>&)>;
void require_main_thread() {
    if(!NSThread.isMainThread) throw std::logic_error("terrain controller requires main thread");
}
}

@implementation TerrainSurfaceController {
    dispatch_queue_t _queue;
    std::shared_ptr<std::atomic<std::uint64_t>> _generation;
    std::optional<TerrainSurfaceRequest> _pending;
    std::shared_ptr<const TerrainSurfaceSnapshot> _snapshot;
    TerrainSurfaceCompletion _completion;
    TerrainPreparationState _state;
    BOOL _running;
}
- (instancetype)init {
    require_main_thread();
    if((self=[super init])) {
        _queue=dispatch_queue_create("org.mitaka.terrain-surface",DISPATCH_QUEUE_SERIAL);
        _generation=std::make_shared<std::atomic<std::uint64_t>>(0);
        _state=TerrainPreparationIdle;
    }
    return self;
}
- (void)dealloc { if(_generation) _generation->fetch_add(1,std::memory_order_relaxed); }
// 試験では計算境界だけを差し替え、実際のqueueとmain-threadの採否を検証する。
- (TerrainEvaluator)terrainEvaluator { return prepare_terrain_surface_snapshot; }
- (TerrainPreparationState)state { require_main_thread(); return _state; }
- (std::uint64_t)generation { require_main_thread(); return _generation->load(std::memory_order_relaxed); }
- (std::shared_ptr<const TerrainSurfaceSnapshot>)snapshot { require_main_thread(); return _snapshot; }

- (void)requestSurface:(TerrainSurfaceRequest)request completion:(TerrainSurfaceCompletion)completion {
    require_main_thread();
    if(_state==TerrainPreparationInvalidated) throw std::logic_error("terrain controller is invalidated");
    if(!completion) throw std::invalid_argument("terrain request requires completion");
    validate_terrain_surface_request(request);
    _generation->fetch_add(1,std::memory_order_relaxed);
    _pending=std::move(request);
    _completion=[completion copy];
    _snapshot.reset();
    _state=TerrainPreparationPreparing;
    [self startPending];
}
- (void)startPending {
    if(_running||!_pending||_state==TerrainPreparationInvalidated) return;
    const auto request=std::move(*_pending);
    _pending.reset();
    const auto generation=_generation;
    const auto ticket=generation->load(std::memory_order_relaxed);
    const auto evaluator=[self terrainEvaluator];
    _running=YES;
    __weak TerrainSurfaceController *weakSelf=self;
    dispatch_async(_queue,^{
        @autoreleasepool {
            const auto cancelled=[generation,ticket]{
                return generation->load(std::memory_order_relaxed)!=ticket;
            };
            std::shared_ptr<const TerrainSurfaceSnapshot> result;
            NSString *failure=nil;
            try {
                if(cancelled()) throw TerrainSurfaceCancelled();
                result=evaluator(request,ticket,cancelled);
                if(!result||result->generation!=ticket||!terrain_surface_request_matches(result->request,request))
                    throw std::runtime_error("terrain evaluator returned a mismatched snapshot");
            } catch(const TerrainSurfaceCancelled&) {
                failure=@"Terrain surface request was cancelled";
            } catch(const std::exception& error) {
                failure=[NSString stringWithUTF8String:error.what()];
                if(!failure) failure=@"Terrain preparation failed (invalid UTF-8 diagnostic)";
            }
            // 取消されたworkerも必ず完了を通知し、最新pendingが開始できるようにする。
            dispatch_async(dispatch_get_main_queue(),^{
                [weakSelf finishSnapshot:result error:failure generation:ticket];
            });
        }
    });
}
- (void)finishSnapshot:(std::shared_ptr<const TerrainSurfaceSnapshot>)snapshot
                  error:(NSString *)error generation:(std::uint64_t)ticket {
    require_main_thread();
    _running=NO;
    if(_state!=TerrainPreparationInvalidated&&_generation->load(std::memory_order_relaxed)==ticket) {
        _snapshot=error?nullptr:std::move(snapshot);
        _state=TerrainPreparationFailed;
        if(_snapshot) {
            switch(_snapshot->status) {
            case TerrainSnapshotStatus::ready:_state=TerrainPreparationReady;break;
            case TerrainSnapshotStatus::unavailable:_state=TerrainPreparationUnavailable;break;
            case TerrainSnapshotStatus::failed:break;
            }
        }
        TerrainSurfaceCompletion completion=_completion;
        _completion=nil;
        // 再入要求が同じcontrollerを使えるよう、旧completionを先に手放す。
        if(completion) completion(_snapshot,error);
    }
    [self startPending];
}
- (void)cancel {
    require_main_thread();
    _generation->fetch_add(1,std::memory_order_relaxed);
    _pending.reset();_snapshot.reset();_completion=nil;
    if(_state!=TerrainPreparationInvalidated) _state=TerrainPreparationIdle;
}
- (void)invalidate {
    require_main_thread();
    [self cancel];
    _state=TerrainPreparationInvalidated;
}
@end
