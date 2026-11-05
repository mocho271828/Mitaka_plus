#import "../src/SolarSystemViewInternal.h"
#include <iostream>
#include <stdexcept>
using namespace mitaka;
using namespace mitaka::gui;
struct Record { double date; double yaw; bool coherent; bool realTerrain; };
@interface SolarSystemView (Validation)
- (void)configureNearEarth;
@end
@implementation SolarSystemView (Validation)
- (void)configureNearEarth {
    _earthMoonMode=YES; _earthMoonFollowing=NO; _camera={{1,0,0},180,0,3*surface_body_info(3).radius_km/astronomical_unit_km};
    self.needsDisplay=YES;
}
@end
@interface RealTerrainView : SolarSystemView
- (std::vector<Record>)records;
@end
@implementation RealTerrainView { std::vector<Record> _records; }
- (std::vector<Record>)records { return _records; }
- (void)redrawPublishedScene {
    auto scene=[self displayedScene]; auto value=scene.terrain ? (*scene.terrain)[3] : nullptr;
    bool ok=value && solar_terrain_frame(scene,3) && value->request.julian_date==scene.julian_date && value->request.camera.yaw_deg==scene.camera.yaw_deg;
    if (value) _records.push_back({scene.julian_date,scene.camera.yaw_deg,ok,value->frame.mode==TerrainSurfaceMode::terrain && value->frame.patches_read>0});
    [super redrawPublishedScene];
}
@end
static void require(bool c,const char *msg) { if(!c) throw std::runtime_error(msg); }
int main(int argc,char **argv) { @autoreleasepool { [NSApplication sharedApplication]; try {
    require(argc==2,"expected root"); RealTerrainView *view=[[RealTerrainView alloc] initWithFrame:NSMakeRect(0,0,196,180)];
    SolarBodies bodies{}; const std::array<Body,11> ids{Body::sun,Body::mercury,Body::venus,Body::earth,Body::mars,Body::jupiter,Body::saturn,Body::uranus,Body::neptune,Body::pluto,Body::moon};
    for(std::size_t i=0;i<bodies.size();++i) { bodies[i].id=ids[i]; bodies[i].position_au={1,100+double(i),0}; }
    bodies[0].position_au={0,0,0}; bodies[3].position_au={1,0,0}; bodies[10].position_au={1.0026,0,0};
    [view setBodies:bodies]; view.planetDisplayOptions={true,false,false,false}; [view setTerrainDataDirectory:[NSString stringWithUTF8String:argv[1]]]; [view configureNearEarth];
    [view setObservationSite:{35,139} julianDate:2451545]; [view refreshTerrain];
    for(int i=1;i<=20;++i) { [view beginSceneUpdate]; [view setObservationSite:{35,139} julianDate:2451545]; [view orbitByX:1 y:0]; [view endSceneUpdate]; [view refreshTerrain]; }
    NSDate *deadline=[NSDate dateWithTimeIntervalSinceNow:60];
    while([view records].size()<2 && deadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    auto records=[view records]; require(records.size()==2,"first/latest publication missing");
    require(records[0].date==2451545 && records[1].date==2451545,"wrong published date");
    require(records[0].yaw!=records[1].yaw,"camera input did not change");
    require(records[0].coherent && records[1].coherent && records[0].realTerrain && records[1].realTerrain,"scene/terrain mismatch or no real terrain");
    std::cout << "Real Earth: 20 queued input changes -> " << records.size() << " atomic publications, first JD=" << records[0].date << " yaw=" << records[0].yaw << ", final JD=" << records[1].date << " yaw=" << records[1].yaw << "; terrain mode and snapshot match for both" << std::endl;
    [view setFrameSize:NSMakeSize(216,200)]; [view refreshTerrain];
    deadline=[NSDate dateWithTimeIntervalSinceNow:60];
    while([view records].size()<3 && deadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    records=[view records]; require(records.size()==3 && records[2].coherent && records[2].realTerrain,"resize failed to publish matching real terrain");
    auto resized=[view displayedScene]; require(resized.map.size.width==180 && resized.map.size.height==120,"resized viewport mismatch");
    auto frame=solar_terrain_frame(resized,3); require(frame && frame->width==180 && frame->height==120,"resized frame dimensions mismatch");
    NSString *missingRoot = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    [view setTerrainDataDirectory:missingRoot]; [view refreshTerrain];
    deadline=[NSDate dateWithTimeIntervalSinceNow:60];
    while([view records].size()<4 && deadline.timeIntervalSinceNow>0) [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    records=[view records]; require(records.size()==4 && !records[3].realTerrain,"missing source reused old terrain");
    auto missing=[view displayedScene]; require(!solar_terrain_frame(missing,3),"unavailable terrain frame displayed");
    auto diagnostic=[view terrainDiagnostics]; bool found=false;
    for(const auto &item:diagnostic) if(item.find("earth_topo")!=std::string::npos) found=true;
    require(found,"missing earth diagnostic absent");
    std::cout << "Real Earth resize: 180x120 matching frame; missing root: datum sphere and explicit earth_topo diagnostic" << std::endl;
    [view cancelTerrain]; return 0;
} catch(const std::exception &e) { std::cerr << e.what() << std::endl; return 1; } } }
