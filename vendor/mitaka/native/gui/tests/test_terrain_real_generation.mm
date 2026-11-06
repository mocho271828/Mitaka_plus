#import "../src/SolarSystemViewInternal.h"
#import "SolarDateUpdate.h"
#include <iostream>
#include <stdexcept>
using namespace mitaka;
using namespace mitaka::gui;
struct Record { double date; double yaw; bool coherent; bool realTerrain; };
@interface SolarSystemView (Validation)
- (void)configureNearBody:(std::size_t)index;
- (void)checkNegativeRoundtrip:(std::size_t)index root:(const char *)root;
@end
@implementation SolarSystemView (Validation)
- (void)configureNearBody:(std::size_t)index {
    _earthMoonMode=NO; _earthMoonFollowing=NO; _physicalSpaceActive=YES;
    _camera={{1,0,0},180,0,3*surface_body_info(index).radius_km/astronomical_unit_km};
    self.needsDisplay=YES;
}
- (void)checkNegativeRoundtrip:(std::size_t)index root:(const char *)root {
    TerrainLandingRequest request;
    request.body=index==3 ? TerrainBody::earth : TerrainBody::mars;
    request.data_directory=root;
    request.latitude_deg=31.5;
    request.longitude_deg=index==3 ? 135 : 35.5;
    request.display_radius_km=surface_body_info(index).radius_km;
    const auto result=prepare_terrain_landing(request);
    if (result.status!=TerrainSnapshotStatus::ready || !result.radius_km ||
        *result.radius_km>=request.display_radius_km) throw std::runtime_error("no negative real terrain");
    SurfaceSite site{index,request.latitude_deg,request.longitude_deg,minimum_surface_height_km,0,-30,15};
    site.terrain_offset_km=*result.radius_km-request.display_radius_km;
    _navigation.set_site(site); _camera=_navigation.camera(_bodies);
    _selection=index; _surfaceActive=YES; _physicalSpaceActive=NO; _journeyActive=NO;
    [self refreshLanding];
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:30];
    while ((!_landingResult || _landingResult->status!=TerrainSnapshotStatus::ready)
           && deadline.timeIntervalSinceNow>0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    if (!_landingResult || _navigation.site().terrain_offset_km>=0)
        throw std::runtime_error("negative landing did not load");
    const double before=_navigation.site().terrain_offset_km;
    NSString *error=nil;
    if (![self forceSurfaceMode:NO bodyIndex:nullptr error:&error]) throw std::runtime_error("space switch failed");
    [self refreshLanding];
    if (![self descendToSelectedSurfaceWithDuration:0 error:&error]) throw std::runtime_error("negative restore failed");
    [self refreshLanding];
    if (std::abs(_navigation.site().terrain_offset_km-before)>1e-10)
        throw std::runtime_error("negative restored camera jumped to datum");
    if (![self forceSurfaceMode:NO bodyIndex:nullptr error:&error]) throw std::runtime_error("second space switch failed");
    [self refreshLanding];
    if (![self forceSurfaceMode:YES bodyIndex:nullptr error:&error]) throw std::runtime_error("forced restore failed");
    [self refreshLanding];
    if (std::abs(_navigation.site().terrain_offset_km-before)>1e-10)
        throw std::runtime_error("forced negative restore jumped to datum");
    // 取得待ちで宇宙へ移ったとき、宇宙の地形は抑止せず、復帰時は結果が出るまで抑止する。
    _landingResult.reset(); _landingSuppressedBody=index;
    if (![self forceSurfaceMode:NO bodyIndex:nullptr error:&error]) throw std::runtime_error("pending space switch failed");
    [self refreshLanding];
    if (_landingSuppressedBody) throw std::runtime_error("pending landing suppressed space terrain");
    if (![self forceSurfaceMode:YES bodyIndex:nullptr error:&error]) throw std::runtime_error("pending restore failed");
    [self refreshLanding];
    if (!_landingSuppressedBody || _navigation.site().terrain_offset_km!=before)
        throw std::runtime_error("pending restored terrain state invalid");
    _landingResult=result; [self refreshLanding];
    if (_landingSuppressedBody) throw std::runtime_error("completed landing remained suppressed");
    auto moved=_navigation.site(); moved.latitude_deg+=1;
    _navigation.set_site(moved); _camera=_navigation.camera(_bodies);
    [self refreshLanding];
    if (!_landingKey || _landingKey->latitude!=moved.latitude_deg || _navigation.site().terrain_offset_km!=0)
        throw std::runtime_error("changed site reused old terrain");
    [self leaveNavigation]; [self refreshLanding];
    if (_landingKey) throw std::runtime_error("leaving navigation retained terrain cache");
}
@end
@interface RealTerrainView : SolarSystemView
@property(nonatomic) std::size_t bodyIndex;
- (std::vector<Record>)records;
@end
@implementation RealTerrainView { std::vector<Record> _records; }
- (std::vector<Record>)records { return _records; }
- (void)redrawPublishedScene {
    auto scene=[self displayedScene]; auto value=scene.terrain ? (*scene.terrain)[self.bodyIndex] : nullptr;
    bool ok=value && solar_terrain_frame(scene,self.bodyIndex) && value->request.julian_date==scene.julian_date && value->request.camera.yaw_deg==scene.camera.yaw_deg;
    if (value) _records.push_back({scene.julian_date,scene.camera.yaw_deg,ok,value->frame.mode==TerrainSurfaceMode::terrain && value->frame.patches_read>0});
    [super redrawPublishedScene];
}
@end
static void require(bool c,const char *msg) { if(!c) throw std::runtime_error(msg); }
static void run(std::size_t index, const char *root) {
    RealTerrainView *view=[[RealTerrainView alloc] initWithFrame:NSMakeRect(0,0,196,180)];
    SolarBodies bodies{}; const std::array<Body,11> ids{Body::sun,Body::mercury,Body::venus,Body::earth,Body::mars,Body::jupiter,Body::saturn,Body::uranus,Body::neptune,Body::pluto,Body::moon};
    for(std::size_t i=0;i<bodies.size();++i) { bodies[i].id=ids[i]; bodies[i].position_au={1,100+double(i),0}; }
    bodies[0].position_au={0,0,0}; bodies[index].position_au={1,0,0}; if(index==3) bodies[10].position_au={1.0026,0,0};
    [view setBodies:bodies]; view.bodyIndex=index; view.planetDisplayOptions={true,false,false,false}; [view setTerrainDataDirectory:[NSString stringWithUTF8String:root]]; [view configureNearBody:index];
    [view checkNegativeRoundtrip:index root:root]; [view configureNearBody:index];
    [view setObservationSite:{35,139} julianDate:2451545]; [view refreshTerrain];
    for(int i=1;i<=20;++i) { [view beginSceneUpdate]; [view setObservationSite:{35,139} julianDate:2451545]; [view orbitByX:1 y:0]; [view endSceneUpdate]; [view refreshTerrain]; }
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:60];
    while([view records].size()<2 && deadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    auto records=[view records]; require(records.size()==2,"first/latest publication missing");
    require(records[0].date==2451545 && records[1].date==2451545,"wrong published date");
    require(records[0].yaw!=records[1].yaw,"camera input did not change");
    require(records[0].coherent && records[1].coherent && records[0].realTerrain && records[1].realTerrain,"scene/terrain mismatch or no real terrain");
    std::cout << (index==3 ? "Real Earth: 20" : "Real Mars: 20") << " queued input changes -> " << records.size() << " atomic publications, first JD=" << records[0].date << " yaw=" << records[0].yaw << ", final JD=" << records[1].date << " yaw=" << records[1].yaw << "; terrain mode and snapshot match for both" << std::endl;
    [view setFrameSize:NSMakeSize(216,200)]; [view refreshTerrain];
    deadline=[NSDate dateWithTimeIntervalSinceNow:60];
    while([view records].size()<3 && deadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    records=[view records]; require(records.size()==3 && records[2].coherent && records[2].realTerrain,"resize failed to publish matching real terrain");
    auto resized=[view displayedScene]; require(resized.map.size.width==180 && resized.map.size.height==120,"resized viewport mismatch");
    auto frame=solar_terrain_frame(resized,index); require(frame && frame->width==180 && frame->height==120,"resized frame dimensions mismatch");
    // 旧日時の地形計算を要求中に、日時変更で基準球へ切り替える。
    [view orbitByX:1 y:0]; [view refreshTerrain];
    SolarDateInput input{2451546, {35,139}, bodies, false, {}, {}, nullptr, nullptr,
        prepare_satellite_scene(nullptr, nullptr), nullptr};
    auto candidate=[view prepareDateUpdate:input];
    [view commitDateUpdate:std::move(candidate)];
    [view finishDateUpdate]; [view refreshTerrain];
    auto changedDate=[view displayedScene];
    require(changedDate.julian_date==2451546 && !solar_terrain_frame(changedDate,index),
        "date change did not immediately publish a datum scene");
    deadline=[NSDate dateWithTimeIntervalSinceNow:60];
    while([view records].size()<4 && deadline.timeIntervalSinceNow>0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    records=[view records];
    require(records.size()==4 && records[3].date==2451546 && records[3].coherent && records[3].realTerrain,
        "new date failed to converge to matching real terrain");
    std::cout << (index==3 ? "Real Earth" : "Real Mars") << ": date change publishes datum immediately, then matching real terrain" << std::endl;
    NSString *missingRoot = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    [view setTerrainDataDirectory:missingRoot]; [view refreshTerrain];
    deadline=[NSDate dateWithTimeIntervalSinceNow:60];
    while([view records].size()<5 && deadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    records=[view records]; require(records.size()==5 && !records[4].realTerrain,"missing source reused old terrain");
    auto missing=[view displayedScene]; require(!solar_terrain_frame(missing,index),"unavailable terrain frame displayed");
    auto diagnostic=[view terrainDiagnostics]; bool found=false;
    for(const auto &item:diagnostic) if(item.find(index==3 ? "earth_topo" : "mars_topo")!=std::string::npos) found=true;
    require(found,"missing terrain diagnostic absent");
    std::cout << (index==3 ? "Real Earth" : "Real Mars") << " resize: 180x120 matching frame; missing root: datum sphere and explicit source diagnostic" << std::endl;
    [view cancelTerrain];
}
int main(int argc,char **argv) { @autoreleasepool { [NSApplication sharedApplication]; try {
    require(argc==2,"expected root"); run(3,argv[1]); run(4,argv[1]); return 0;
} catch(const std::exception &e) { std::cerr << e.what() << std::endl; return 1; } } }
