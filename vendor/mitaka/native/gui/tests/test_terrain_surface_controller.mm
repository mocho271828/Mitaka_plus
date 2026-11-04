#import "TerrainSurfaceController.h"
#include "terrain_snapshot_test_fixture.hpp"

#include <atomic>
#include <iostream>

using namespace mitaka::gui;
using Snapshot=std::shared_ptr<const TerrainSurfaceSnapshot>;
using TerrainEvaluator=std::function<Snapshot(const TerrainSurfaceRequest&,std::uint64_t,const std::function<bool()>&)>;

namespace {
unsigned checks=0;
void require(bool value,const char* message) { ++checks;if(!value) throw std::runtime_error(message); }
template<class E=std::invalid_argument,class F> void rejects(F fn,const char* message) {
    try { fn(); }catch(const E&) { ++checks;return; }throw std::runtime_error(message);
}
void spin(bool (^done)(void)) {
    const auto deadline=[NSDate dateWithTimeIntervalSinceNow:5];
    while(!done()&&deadline.timeIntervalSinceNow>0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.002]];
    require(done(),"async terrain completes within bounded wait");
}
struct Probe {
    std::atomic<unsigned> calls{0},finished{0},cancelled{0},failure{0};
    dispatch_semaphore_t permit=dispatch_semaphore_create(0);
};
struct Finished { std::shared_ptr<Probe> probe;~Finished(){++probe->finished;} };
}

@interface ControlledTerrainController : TerrainSurfaceController
- (instancetype)initWithProbe:(std::shared_ptr<Probe>)probe;
- (TerrainEvaluator)terrainEvaluator;
@end
@implementation ControlledTerrainController { std::shared_ptr<Probe> _probe; }
- (instancetype)initWithProbe:(std::shared_ptr<Probe>)probe {
    if((self=[super init])) _probe=std::move(probe);return self;
}
- (TerrainEvaluator)terrainEvaluator {
    const auto probe=_probe;
    return [probe](const auto& request,auto ticket,const auto& cancelled)->Snapshot {
        ++probe->calls;Finished finish{probe};
        if(dispatch_semaphore_wait(probe->permit,dispatch_time(DISPATCH_TIME_NOW,5*NSEC_PER_SEC)))
            throw std::runtime_error("test evaluator permit timed out");
        if(NSThread.isMainThread) throw std::runtime_error("terrain evaluation unexpectedly on main thread");
        if(cancelled()) { ++probe->cancelled;throw TerrainSurfaceCancelled(); }
        const auto failure=probe->failure.exchange(0);
        if(failure==1) throw std::runtime_error("synthetic terrain failure");
        if(failure==2) throw std::runtime_error(std::string("invalid diagnostic: ")+char(0xff));
        if(failure==3) return nullptr;
        auto out=std::make_shared<TerrainSurfaceSnapshot>();out->request=request;out->generation=ticket;
        out->status=TerrainSnapshotStatus::ready;
        if(failure==4) ++out->request.julian_date;
        return out;
    };
}
@end

namespace {
void ordering_and_keys() {
    terrain_test::Temporary temp;const auto original=temp.request();
    const auto probe=std::make_shared<Probe>();
    TerrainSurfaceController *controller=[[ControlledTerrainController alloc] initWithProbe:probe];
    require([controller state]==TerrainPreparationIdle&&![controller snapshot],"initial state explicit idle");
    __block unsigned stale=0,complete=0;
    [controller requestSurface:original completion:^(Snapshot,NSString*){++stale;}];
    spin(^{return probe->calls==1;});
    for(int i=1;i<50;++i) {
        auto request=original;request.julian_date+=i;
        [controller requestSurface:request completion:^(Snapshot,NSString*){++stale;}];
    }
    auto latest=original;latest.julian_date+=50;
    [controller requestSurface:latest completion:^(Snapshot result,NSString *error){
        require(NSThread.isMainThread&&!error&&result&&result->request.julian_date==latest.julian_date,
            "latest exact date wins on main thread");++complete;
    }];
    require([controller state]==TerrainPreparationPreparing&&![controller snapshot],"preparing clears old terrain for sphere fallback");
    require(probe->calls==1,"many requests do not enqueue many workers");
    dispatch_semaphore_signal(probe->permit);
    spin(^{return probe->calls==2;});
    dispatch_semaphore_signal(probe->permit);
    spin(^{return complete==1;});
    require(stale==0&&probe->calls==2&&probe->cancelled==1,"only running and latest pending are evaluated");
    require([controller state]==TerrainPreparationReady&&[controller snapshot]->generation==[controller generation],"published generation matches controller");
    const auto first=[controller snapshot];
    [controller requestSurface:latest completion:^(Snapshot result,NSString *error){
        require(!error&&result!=first&&result->generation!=first->generation,"identical request reopens source instead of caching");++complete;
    }];
    require(![controller snapshot]&&[controller state]==TerrainPreparationPreparing,"replace ready terrain immediately");
    spin(^{return probe->calls==3;});
    const auto generation=[controller generation];
    auto bad=latest;bad.width=0;
    rejects([&]{[controller requestSurface:bad completion:^(Snapshot,NSString*){}];},"invalid request rejects");
    rejects([&]{[controller requestSurface:latest completion:nil];},"null completion rejects");
    require([controller generation]==generation&&[controller state]==TerrainPreparationPreparing,"invalid input preserves pending generation");
    dispatch_semaphore_signal(probe->permit);spin(^{return complete==2;});
    require(probe->cancelled==1,"invalid input does not cancel previous valid request");
    [controller invalidate];
}
void cancellation_errors_and_reentry() {
    terrain_test::Temporary temp;const auto request=temp.request();
    const auto probe=std::make_shared<Probe>();
    TerrainSurfaceController *controller=[[ControlledTerrainController alloc] initWithProbe:probe];
    __block unsigned stale=0,complete=0;
    [controller requestSurface:request completion:^(Snapshot,NSString*){++stale;}];
    spin(^{return probe->calls==1;});[controller cancel];
    require([controller state]==TerrainPreparationIdle&&![controller snapshot],"cancel releases visible frame and completion");
    [controller requestSurface:request completion:^(Snapshot value,NSString *error){require(value&&!error,"request allowed after cancel");++complete;}];
    dispatch_semaphore_signal(probe->permit);spin(^{return probe->calls==2;});
    dispatch_semaphore_signal(probe->permit);spin(^{return complete==1;});
    require(stale==0&&probe->cancelled==1,"cancelled running work cannot replace resumed request");
    for(unsigned failure=1;failure<=4;++failure) {
        probe->failure=failure;
        [controller requestSurface:request completion:^(Snapshot value,NSString *error){
            require(!value&&error.length>0,"unexpected evaluator failure is explicit");++complete;
        }];
        dispatch_semaphore_signal(probe->permit);spin(^{return complete==failure+1;});
        require([controller state]==TerrainPreparationFailed&&![controller snapshot],"failure state never exposes successful old snapshot");
    }
    __block unsigned reentered=0;
    __weak TerrainSurfaceController *weakController=controller;
    [controller requestSurface:request completion:^(Snapshot value,NSString *error){
        require(value&&!error,"success after failure");++reentered;
        [weakController requestSurface:request completion:^(Snapshot second,NSString *nextError){
            require(second&&!nextError,"callback can reenter with next request");++reentered;
        }];
    }];
    dispatch_semaphore_signal(probe->permit);dispatch_semaphore_signal(probe->permit);
    spin(^{return reentered==2;});
    [controller requestSurface:request completion:^(Snapshot,NSString*){++stale;}];
    spin(^{return probe->calls==9;});[controller invalidate];
    require([controller state]==TerrainPreparationInvalidated&&![controller snapshot],"invalidate state clears snapshot");
    rejects<std::logic_error>([&]{[controller requestSurface:request completion:^(Snapshot,NSString*){}];},"invalidated rejects requests");
    dispatch_semaphore_signal(probe->permit);spin(^{return probe->finished==9;});
    [controller cancel];require([controller state]==TerrainPreparationInvalidated&&stale==0,"cancel cannot revive invalidated controller");
}
void actual_io_and_lifetime() {
    terrain_test::Temporary temp;const auto request=temp.request();
    TerrainSurfaceController *controller=[TerrainSurfaceController new];
    __block unsigned complete=0;
    [controller requestSurface:request completion:^(Snapshot value,NSString *error){
        require(!error&&value&&value->status==TerrainSnapshotStatus::unavailable&&!value->diagnostic.empty(),"real missing source diagnostic");++complete;
    }];
    spin(^{return complete==1;});require([controller state]==TerrainPreparationUnavailable,"unavailable separate from failed");
    temp.write(TerrainBody::earth,"broken");
    [controller requestSurface:request completion:^(Snapshot value,NSString *error){
        require(!error&&value->status==TerrainSnapshotStatus::failed&&!value->diagnostic.empty(),"real corrupt source diagnostic");++complete;
    }];
    spin(^{return complete==2;});require([controller state]==TerrainPreparationFailed,"corrupt state failed");
    temp.write(TerrainBody::earth);
    [controller requestSurface:request completion:^(Snapshot value,NSString *error){
        require(!error&&value->status==TerrainSnapshotStatus::ready&&value->source_identity&&value->frame.samples.size()==1089,
            "real background parse mesh and frame complete");++complete;
    }];
    spin(^{return complete==3;});[controller invalidate];
    const auto probe=std::make_shared<Probe>();
    __weak TerrainSurfaceController *weak=nil;
    __block unsigned stale=0;
    @autoreleasepool {
        TerrainSurfaceController *shortLived=[[ControlledTerrainController alloc] initWithProbe:probe];weak=shortLived;
        [shortLived requestSurface:request completion:^(Snapshot,NSString*){++stale;}];
        spin(^{return probe->calls==1;});shortLived=nil;
    }
    require(weak==nil,"worker does not keep controller alive");
    dispatch_semaphore_signal(probe->permit);spin(^{return probe->finished==1;});
    require(probe->cancelled==1&&stale==0,"deallocation cancels and suppresses completion");
}
}
int main() {
    @autoreleasepool {
        try { ordering_and_keys();cancellation_errors_and_reentry();actual_io_and_lifetime();
            std::cout<<"terrain controller: "<<checks<<" checks passed\n";return 0;
        } catch(const std::exception& e) {std::cerr<<"terrain controller: "<<e.what()<<'\n';return 1;}
    }
}
