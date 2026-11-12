#import "../src/SolarSystemViewInternal.h"
#import "SolarDateUpdate.h"
#include <algorithm>
#include <cmath>
#include <iostream>
#include <stdexcept>
using namespace mitaka;
using namespace mitaka::gui;
bool solar_scene_opaque_at(const SolarScene& scene, NSPoint point);
struct Record { double date; double yaw; bool coherent; bool realTerrain; };
@interface SolarSystemView (Validation)
- (double)takeFlightClockForTest;
- (void)configureNearBody:(std::size_t)index;
- (void)checkNegativeRoundtrip:(std::size_t)index root:(const char *)root;
- (void)configureSurface:(SurfaceSite)site;
- (void)publishCoverage:(int)coverage;
@end
// 実際の星座データと描画経路を使い、地形の被覆だけを固定する。
// 非同期計算や地形データの欠損に依存せず、文字・CAB と深度判定の合成順を検証する。
@interface ConstellationTerrainView : SolarSystemView
@end
@implementation ConstellationTerrainView
- (void)refreshTerrain {}
@end
@implementation SolarSystemView (Validation)
- (double)takeFlightClockForTest {
    [self invalidateFlightTimer];
    return _lastFlightTime;
}
- (void)configureSurface:(SurfaceSite)site {
    _navigation.set_site(site);
    _surfaceActive = YES;
    _physicalSpaceActive = NO;
    _camera = _navigation.camera(_bodies);
    _camera.vertical_fov_deg = 75;
    _selection.reset();
}
- (void)publishCoverage:(int)coverage {
    const auto scene = [self scene];
    const auto index = *scene.surface_body;
    auto snapshot = std::make_shared<TerrainSurfaceSnapshot>();
    snapshot->request = *solar_terrain_request(scene, index, "/fixture/constellation-occlusion");
    snapshot->status = TerrainSnapshotStatus::ready;
    auto& frame = snapshot->frame;
    frame.mode = TerrainSurfaceMode::terrain;
    frame.width = snapshot->request.width;
    frame.height = snapshot->request.height;
    frame.samples.resize(frame.width * frame.height);
    for (int y = 0; y < frame.height; ++y) for (int x = 0; x < frame.width; ++x)
        if (coverage == 1 || (coverage == 2 && x % 32 < 16))
            frame.samples[y * frame.width + x] = {1e-8, {1, 0, 0}, 0, 0};
    _terrainSnapshots[index] = std::move(snapshot);
    _publishedScene = std::make_shared<SolarSceneOwner>([self scene], SolarSceneResources{});
}
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
static std::vector<unsigned char> constellationPixels(ConstellationTerrainView *view,
                                                      ConstellationDisplayOptions options) {
    view.surfaceConstellationDisplayOptions = std::move(options);
    const int width = view.bounds.size.width, height = view.bounds.size.height;
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
        isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0 bytesPerRow:width * 4 bitsPerPixel:32];
    require(bitmap != nil, "constellation bitmap allocation failed");
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    [view drawRect:view.bounds];
    [NSGraphicsContext restoreGraphicsState];
    return {bitmap.bitmapData, bitmap.bitmapData + width * height * 4};
}
static void constellationOcclusion(const char *root) {
    const auto model = std::make_shared<const SkyModel>(SkyModel::load(root));
    const auto art = std::make_shared<const ConstellationArtModel>(ConstellationArtModel::load(root, model->constellations()));
    const auto record = std::find_if(model->constellations().begin(), model->constellations().end(),
        [](const auto& row) { return row.abbreviation == "Ori"; });
    require(record != model->constellations().end() && !art->records().empty(), "Orion and CAB source required");
    auto bodies = model->solar_bodies(2451545);
    for (std::size_t i = 0; i < bodies.size(); ++i) bodies[i].position_au = {1, 100 + double(i), 0};
    bodies[0].position_au = {0, 0, 0};
    const ConstellationDisplayOptions hidden{false, false, false, false, {"Ori"}, false};
    for (const std::size_t body : {std::size_t{4}, std::size_t{10}}) {
        ConstellationTerrainView *view = [[ConstellationTerrainView alloc] initWithFrame:NSMakeRect(0, 0, 436, 380)];
        [view setBodies:bodies];
        [view setSurfaceStarModel:model catalogs:nullptr];
        [view setSurfaceStarDisplayOptions:{false}];
        [view setSurfaceConstellationArt:art];
        view.planetDisplayOptions = {true, false, false, false};
        view.gridDisplayOptions = {false, false, false, false, false, false};
        view.earthLayerOptions = {false, false};
        view.atmosphereDisplayOptions = {AtmosphereMode::none};
        view.eclipseDisplayOptions = {false, false, false, false};
        const ObservationFrame observation({0, 0}, bodies[body].orientation);
        const auto direction = observation.to_horizontal({record->right_ascension_degrees, record->declination_degrees});
        for (const double roll : {0.0, 37.0}) {
            [view configureSurface:{body, 0, 0, minimum_surface_height_km,
                direction.azimuth_deg, direction.altitude_deg, roll}];
            for (const bool illustration : {false, true}) {
                auto shown = hidden;
                shown.labels = !illustration;
                shown.illustrations = illustration;
                std::array<std::vector<unsigned char>, 3> baseline, overlay;
                for (int coverage = 0; coverage < 3; ++coverage) {
                    [view publishCoverage:coverage];
                    require(solar_terrain_frame([view displayedScene], body) != nullptr, "fixture terrain must be accepted");
                    baseline[coverage] = constellationPixels(view, hidden);
                    overlay[coverage] = constellationPixels(view, shown);
                }
                const auto map = [view mapRect];
                std::size_t visible = 0, hiddenCount = 0;
                for (int y = 0; y < static_cast<int>(view.bounds.size.height); ++y)
                    for (int x = static_cast<int>(map.origin.x); x < NSMaxX(map); ++x) {
                        const auto offset = (y * static_cast<int>(view.bounds.size.width) + x) * 4;
                        const auto differs = [&](int coverage) {
                            return !std::equal(overlay[coverage].begin() + offset, overlay[coverage].begin() + offset + 3,
                                               baseline[coverage].begin() + offset);
                        };
                        require(!differs(1), "opaque terrain must cover constellation text and art");
                        if (!differs(0)) continue;
                        const int local = x - static_cast<int>(map.origin.x);
                        // 補間される被覆境界を避け、完全な不透明・透明画素を比較する。
                        if (local % 16 < 2 || local % 16 > 13) continue;
                        const bool opaque = local % 32 < 16;
                        require(solar_scene_opaque_at([view displayedScene], NSMakePoint(x + .5, NSMidY(map))) == opaque,
                                "constellation coverage must agree with picking depth");
                        require(differs(2) != opaque, "partial terrain coverage must preserve only visible constellation pixels");
                        opaque ? ++hiddenCount : ++visible;
                    }
                require(visible > 0 && hiddenCount > 0, "constellation fixture must cross opaque and clear terrain");
                std::cout << (body == 4 ? "Mars" : "Moon") << (illustration ? " CAB" : " labels")
                    << " roll=" << roll << ": hidden=" << hiddenCount << " visible=" << visible << '\n';
            }
        }
    }
}
static std::optional<double> publishedMarsDistance(SolarSystemView *view, const std::filesystem::path &source) {
    const auto scene = [view displayedScene];
    const auto snapshot = scene.terrain ? (*scene.terrain)[4] : nullptr;
    if (!snapshot) return std::nullopt;
    require(snapshot->status == TerrainSnapshotStatus::ready, snapshot->diagnostic.c_str());
    require(scene.surface_body == 4 && scene.julian_date == 2451545 &&
        snapshot->source_path == source,
        "descent published the wrong body, date or terrain source");
    const auto *frame = solar_terrain_frame(scene, 4);
    require(frame && frame->mode == TerrainSurfaceMode::terrain && frame->patches_read > 0 &&
        std::any_of(frame->samples.begin(), frame->samples.end(), [](const auto &sample) {
            return std::isfinite(sample.distance_au) && sample.distance_au > 0;
        }), "displayed Mars camera has no matching real terrain intersections");
    return scene.camera.distance_au;
}

static void marsDescent(const SolarBodies &bodies, const char *root) {
    const auto source = std::filesystem::canonical(root / terrain_source_relative_path(TerrainBody::mars));
    SolarSystemView *view = [[SolarSystemView alloc] initWithFrame:NSMakeRect(0, 0, 196, 180)];
    [view setBodies:bodies];
    [view setObservationSite:{0, 0} julianDate:2451545];
    view.planetDisplayOptions = {true, false, false, false};
    [view setTerrainDataDirectory:[NSString stringWithUTF8String:root]];
    // 降下中の公開カメラとは独立に、同じ負標高地点の実データから各高度の基準を求める。
    TerrainLandingRequest landing;
    landing.data_directory = root;
    landing.body = TerrainBody::mars;
    landing.latitude_deg = 31.5;
    landing.longitude_deg = 35.5;
    landing.display_radius_km = surface_body_info(4).radius_km;
    const auto expected = prepare_terrain_landing(landing);
    require(expected.status == TerrainSnapshotStatus::ready && expected.radius_km &&
        *expected.radius_km < landing.display_radius_km, "negative real Mars landing surface required");
    const double groundRadiusKm = *expected.radius_km;
    SurfaceNavigation navigation;
    navigation.set_site({4, landing.latitude_deg, landing.longitude_deg, 20, 45, -20});
    [view setCameraState:navigation.camera(bodies)];
    [view selectBody:4];
    constexpr double duration = 60;
    NSString *error = nil;
    if (![view descendToSelectedSurfaceWithDuration:duration error:&error])
        throw std::runtime_error(error ? error.UTF8String : "could not start Mars descent");
    const double start = [view takeFlightClockForTest];
    const double initialDistance = [view cameraState].distance_au;
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:196 pixelsHigh:180 bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
        isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    require(context != nil, "could not create descent drawing context");
    const auto draw = [&] {
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext.currentContext = context;
        [view drawRect:view.bounds];
        [NSGraphicsContext restoreGraphicsState];
    };
    draw();
    double elapsed = 0, lastDistance = initialDistance;
    std::optional<double> highKm, lowKm;
    unsigned intermediate = 0, lagging = 0;
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:60];
    while (elapsed < duration && deadline.timeIntervalSinceNow > 0) {
        @autoreleasepool {
            // 遅い実行環境でも両高度帯を観測できるよう時計を減速し、地形待ちの間も入力と描画を続ける。
            const bool slow = (!highKm && elapsed >= duration * 0.15) || (!lowKm && elapsed >= duration * 0.65);
            elapsed = std::min(duration, elapsed + (slow ? 0.005 : 0.25));
            [view advanceFlightAtTime:start + elapsed];
            draw();
            [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
            const auto distance = publishedMarsDistance(view, source);
            if (view.flightAnimating && distance && *distance != lastDistance) {
                require(*distance < lastDistance && *distance >= [view cameraState].distance_au,
                    "Mars terrain frames did not follow descending camera order");
                if (*distance > [view cameraState].distance_au) ++lagging;
                lastDistance = *distance;
                ++intermediate;
                const double heightKm = *distance * astronomical_unit_km - groundRadiusKm;
                if (heightKm > 1 && !highKm) highKm = heightKm;
                if (heightKm > minimum_surface_height_km && heightKm <= 1 && !lowKm) lowKm = heightKm;
            }
        }
    }
    require(highKm && lowKm, "continuous descent starved Mars terrain above or below 1 km");
    require(!view.flightAnimating, "Mars descent did not finish");
    const double finalDistance = [view cameraState].distance_au;
    require(std::abs(finalDistance * astronomical_unit_km - groundRadiusKm -
        minimum_surface_height_km) < 1e-6, "Mars descent did not land 2 m above real terrain");
    deadline = [NSDate dateWithTimeIntervalSinceNow:60];
    while (publishedMarsDistance(view, source) != finalDistance && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
    require(publishedMarsDistance(view, source) == finalDistance &&
        [view matchesDisplayedCamera:[view cameraState] map:[view mapRect]], "landed Mars camera did not get its terrain");
    [view cancelTerrain];
    std::cout << "Real Mars descent: " << intermediate << " intermediate frames, " << lagging
              << " behind live camera; terrain clearances (km) " << *highKm << ", " << *lowKm
              << "; matching landed frame (2 m above real terrain)" << std::endl;
}

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
    if (index == 4) marsDescent(bodies, root);
}
int main(int argc,char **argv) { @autoreleasepool { [NSApplication sharedApplication]; try {
    require(argc==2,"expected root"); constellationOcclusion(argv[1]); run(3,argv[1]); run(4,argv[1]); return 0;
} catch(const std::exception &e) { std::cerr << e.what() << std::endl; return 1; } } }
