#import "TerrainLandingController.h"
#include "surface_navigation.hpp"
#include "terrain_snapshot_test_fixture.hpp"
#include <atomic>
#include <chrono>
#include <cmath>
#include <iostream>
#include <filesystem>
#include <unistd.h>
#include <stdexcept>
#include <thread>

using namespace mitaka::gui;
using LandingEvaluator=std::function<TerrainLandingResult(const TerrainLandingRequest&,const std::function<bool()>&)>;
static std::atomic<int> started{0};
@interface MockLandingController : TerrainLandingController
@end
@implementation MockLandingController
- (LandingEvaluator)landingEvaluator {
    return [](const TerrainLandingRequest& request,const std::function<bool()>& cancelled) {
        ++started;
        for(int i=0;i<100;++i) {
            if(cancelled()) throw TerrainSurfaceCancelled();
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        TerrainLandingResult result; result.status=TerrainSnapshotStatus::ready;
        result.radius_km=request.elevation_factor;
        return result;
    };
}
@end
// 評価器が取消を即時に観測しない場合も古い A の完了を配送してはいけない。
@interface DelayedLandingController : TerrainLandingController
@end
@implementation DelayedLandingController
- (LandingEvaluator)landingEvaluator {
    return [](const TerrainLandingRequest& request,const std::function<bool()>&) {
        ++started;
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        TerrainLandingResult result; result.status=TerrainSnapshotStatus::ready;
        result.radius_km=request.elevation_factor;
        return result;
    };
}
@end
static void require(bool condition,const char* message) { if(!condition) throw std::runtime_error(message); }
static void wait_until(bool (^condition)(void),double seconds=10) {
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:seconds];
    while(!condition() && deadline.timeIntervalSinceNow>0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.005]];
    require(condition(),"timed out");
}
static void concurrency_test() {
    MockLandingController *controller=[MockLandingController new];
    TerrainLandingRequest request; request.data_directory="/tmp"; request.display_radius_km=6378;
    __block int completed=0; __block double radius=0;
    [controller requestLanding:request completion:^(TerrainLandingResult,NSString*) { ++completed; }];
    wait_until(^{return started.load()>0;});
    request.elevation_factor=2;
    [controller requestLanding:request completion:^(TerrainLandingResult,NSString*) { ++completed; }];
    request.elevation_factor=20;
    [controller requestLanding:request completion:^(TerrainLandingResult result,NSString* error) {
        require(NSThread.isMainThread,"completion must be on main thread");
        require(!error && result.radius_km.has_value(),"latest request failed");
        radius=*result.radius_km; ++completed;
    }];
    wait_until(^{return completed!=0;});
    require(completed==1 && radius==20,"superseded result was applied");
    [controller requestLanding:request completion:^(TerrainLandingResult,NSString*) { ++completed; }];
    [controller cancel];
    const auto until=std::chrono::steady_clock::now()+std::chrono::milliseconds(200);
    while(std::chrono::steady_clock::now()<until)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.005]];
    require(completed==1,"cancelled completion was applied");
    [controller invalidate];
    // A -> B -> A でも先頭の A と最後の A を generation で区別する。
    DelayedLandingController *delayed=[DelayedLandingController new];
    __block int abaCompleted=0;
    __block int abaIdentity=0;
    const int priorStarts=started.load();
    request.elevation_factor=1;
    [delayed requestLanding:request completion:^(TerrainLandingResult,NSString*) { ++abaCompleted; abaIdentity=1; }];
    wait_until(^{return started.load()>priorStarts;});
    request.elevation_factor=2;
    [delayed requestLanding:request completion:^(TerrainLandingResult,NSString*) { ++abaCompleted; abaIdentity=2; }];
    request.elevation_factor=1;
    [delayed requestLanding:request completion:^(TerrainLandingResult result,NSString* error) {
        require(!error && result.radius_km==1,"final A request failed");
        ++abaCompleted; abaIdentity=3;
    }];
    wait_until(^{return abaCompleted!=0;});
    require(abaCompleted==1 && abaIdentity==3,"stale ABA request was applied");
    [delayed invalidate];
    bool rejected=false;
    try { [controller requestLanding:request completion:^(TerrainLandingResult,NSString*) {}]; }
    catch(const std::logic_error&) { rejected=true; }
    require(rejected,"invalidated controller accepted request");
}
static void source_boundary_test(const char* real_root) {
    char name[]="/tmp/mitaka-landing-XXXXXX";
    const char* directory=mkdtemp(name);
    require(directory!=nullptr,"cannot create temporary directory");
    const std::filesystem::path root(directory);
    struct Cleanup { std::filesystem::path root; ~Cleanup() { std::error_code error; std::filesystem::remove_all(root,error); } } cleanup{root};
    TerrainLandingRequest request; request.data_directory=root; request.display_radius_km=6378;
    require(prepare_terrain_landing(request).status==TerrainSnapshotStatus::unavailable,"missing source should be unavailable");
    std::filesystem::create_directories(root/"earth_topo");
    std::filesystem::create_symlink(std::filesystem::path(real_root)/"earth_topo/earth_topo.dat",root/"earth_topo/earth_topo.dat");
    require(prepare_terrain_landing(request).status==TerrainSnapshotStatus::failed,"external symlink was accepted");
    bool cancelled=false;
    try { (void)prepare_terrain_landing(request,[]{return true;}); }
    catch(const TerrainSurfaceCancelled&) { cancelled=true; }
    require(cancelled,"cancelled source request continued");
    request.data_directory=real_root;
    int checks=0; cancelled=false;
    try { (void)prepare_terrain_landing(request,[&checks]{return ++checks>=3;}); }
    catch(const TerrainSurfaceCancelled&) { cancelled=true; }
    require(cancelled,"in-flight sampler cancellation used wrong error");
    request.latitude_deg=91;
    bool rejected=false;
    try { validate_terrain_landing_request(request); }
    catch(const std::invalid_argument&) { rejected=true; }
    require(rejected,"invalid latitude accepted");
}
static void invalid_source_radius_test() {
    terrain_test::Temporary temp;
    auto data=terrain_test::bytes(100);
    std::string header;
    terrain_test::append(header, 10000000.0f);
    data.replace(0, header.size(), header);
    temp.write(TerrainBody::earth, data);
    TerrainLandingRequest request; request.data_directory=temp.root; request.display_radius_km=6378;
    const auto result=prepare_terrain_landing(request);
    require(result.radius_km && *result.radius_km-request.display_radius_km>1e9,
            "fixture must produce an out-of-range landing radius");
    require(result.status==TerrainSnapshotStatus::failed && result.diagnostic=="invalid terrain offset",
            "unusable radius from malformed terrain must be a diagnostic failure");
}
static void real_test(const char* root,TerrainBody body,std::size_t index,double lat,double lon,bool negative=false) {
    TerrainLandingController *controller=[TerrainLandingController new];
    TerrainLandingRequest request; request.data_directory=root; request.body=body;
    request.latitude_deg=lat; request.longitude_deg=lon;
    request.display_radius_km=surface_body_info(index).radius_km;
    for(double factor:{1.0,2.0,20.0}) {
        request.elevation_factor=factor;
        __block bool done=false; __block TerrainLandingResult actual; __block NSString *failure=nil;
        [controller requestLanding:request completion:^(TerrainLandingResult result,NSString *error) {
            actual=result; failure=error; done=true;
        }];
        wait_until(^{return done;},60);
        require(!failure && actual.status==TerrainSnapshotStatus::ready && actual.radius_km,"real data request failed");
        const double offset=*actual.radius_km-request.display_radius_km;
        require(negative ? offset<-.01 : offset>1,"test location has wrong elevation");
        SurfaceNavigation nav; nav.set_site({index,lat,lon,minimum_surface_height_km,0,0,0,offset});
        SolarBodies bodies{}; bodies[index].orientation={{1,0,0},{0,1,0},{0,0,1}};
        auto camera=nav.camera(bodies);
        const double clearance=(camera.distance_au*astronomical_unit_km-*actual.radius_km)*1000;
        require(std::abs(clearance-2)<1e-4,"terrain clearance differs from 2m");
        std::cout<<"body="<<index<<" factor="<<factor<<" clearance_m="<<clearance<<'\n';
    }
}
int main(int argc,char** argv) { @autoreleasepool { try {
    require(argc<=2,"expected optional absolute data root"); concurrency_test(); invalid_source_radius_test();
    if(argc==2) {
        source_boundary_test(argv[1]);
        real_test(argv[1],TerrainBody::earth,3,82.2,-84.7);
        real_test(argv[1],TerrainBody::mars,4,49.625,-81.6875);
        real_test(argv[1],TerrainBody::earth,3,31.5,135,true);
        real_test(argv[1],TerrainBody::mars,4,31.5,35.5,true);
    }
    std::cout<<"terrain landing controller tests passed\n"; return 0;
} catch(const std::exception& error) { std::cerr<<error.what()<<'\n'; return 1; } } }
