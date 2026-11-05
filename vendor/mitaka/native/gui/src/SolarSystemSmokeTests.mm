#import "SolarSystemViewInternal.h"
#import "SkyView.h"
#include <algorithm>
#include <cmath>
#include <exception>
#include <limits>

using namespace mitaka;
using namespace mitaka::gui;

static bool sameFlightCamera(const SolarCamera& a, const SolarCamera& b) {
    const auto first = solar_camera_basis(a), second = solar_camera_basis(b);
    const auto near = [](Vec3 x, Vec3 y) { return std::hypot(x.x-y.x, x.y-y.y, x.z-y.z) < 1e-11; };
    const Vec3 firstEye{a.target.x+first.outward.x*a.distance_au,
        a.target.y+first.outward.y*a.distance_au, a.target.z+first.outward.z*a.distance_au};
    const Vec3 secondEye{b.target.x+second.outward.x*b.distance_au,
        b.target.y+second.outward.y*b.distance_au, b.target.z+second.outward.z*b.distance_au};
    return near(firstEye, secondEye) && near(first.outward, second.outward)
        && near(first.right, second.right) && near(first.up, second.up);
}

static NSUInteger surfacePixelDifferences(NSBitmapImageRep *a, NSBitmapImageRep *b, NSRect bounds, NSRect sample) {
    if (!a || !b || a.pixelsWide != b.pixelsWide || a.pixelsHigh != b.pixelsHigh) return 0;
    NSUInteger changed = 0;
    for (int row = 0; row < 20; ++row) for (int column = 0; column < 20; ++column) {
        const NSInteger x = (sample.origin.x + (column + 0.5) * sample.size.width / 20) * a.pixelsWide / bounds.size.width;
        const NSInteger y = (sample.origin.y + (row + 0.5) * sample.size.height / 20) * a.pixelsHigh / bounds.size.height;
        NSColor *first = [[a colorAtX:x y:y] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
        NSColor *second = [[b colorAtX:x y:y] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
        if (first && second && std::abs(first.redComponent - second.redComponent)
            + std::abs(first.greenComponent - second.greenComponent) + std::abs(first.blueComponent - second.blueComponent) > 0.1) ++changed;
    }
    return changed;
}

static std::shared_ptr<const SatelliteDisplayModel> hiddenSatelliteDisplay(
    const std::shared_ptr<const SatelliteDisplayModel>& display) {
    if (!display) return nullptr;
    auto hidden = std::make_shared<SatelliteDisplayModel>(*display);
    auto options = hidden->options();
    options.visible = false;
    hidden->set_options(options);
    return hidden;
}

@implementation SolarSystemView (SmokeTests)

- (BOOL)rejectsInvalidCameraStatesWithoutChanges {
    const auto camera = _camera;
    const BOOL following = _following, surface = _surfaceActive, journey = _journeyActive;
    const BOOL earthMoon = _earthMoonMode, earthMoonFollowing = _earthMoonFollowing;
    const BOOL flying = self.flightAnimating;
    const auto selection = _selection, smallSelection = _smallBodySelection, satelliteSelection = _satelliteSelection;
    const auto spacecraftSelection = _spacecraftSelection;
    NSTimer *timer = _flightTimer;
    const double lastTime = _lastFlightTime, progress = _journey.progress();
    for (double distance : {maximum_solar_distance_au * 2, 1e-15, std::numeric_limits<double>::infinity(),
                            std::numeric_limits<double>::quiet_NaN()}) {
        auto invalid = camera;
        invalid.distance_au = distance;
        NSString *error = nil;
        if ([self applyCameraState:invalid error:&error] || !error.length ||
            !sameFlightCamera(camera, _camera) || _camera.distance_au != camera.distance_au ||
            _camera.frame.has_value() != camera.frame.has_value() ||
            _following != following || _surfaceActive != surface || _journeyActive != journey ||
            _earthMoonMode != earthMoon || _earthMoonFollowing != earthMoonFollowing ||
            self.flightAnimating != flying || _flightTimer != timer || _lastFlightTime != lastTime ||
            _journey.progress() != progress || _selection != selection || _smallBodySelection != smallSelection ||
            _satelliteSelection != satelliteSelection || _spacecraftSelection != spacecraftSelection)
            return NO;
    }
    return YES;
}
- (BOOL)runContinuousFlightSmokeTest {
    if (!_hasData || self.flightAnimating || self.journeyActive) return NO;
    const auto camera = _camera;
    const auto bodies = _bodies;
    const auto navigation = _navigation;
    const auto journey = _journey;
    const auto selection = _selection;
    const auto smallSelection = _smallBodySelection;
    const BOOL smallVisible = _smallBodiesVisible;
    _smallBodySelection.reset(); _smallBodiesVisible = NO;
    const auto satelliteSelection = _satelliteSelection;
    const auto spacecraftSelection = _spacecraftSelection;
    const auto notifiedSatelliteSelection = _notifiedSatelliteSelection;
    const auto satelliteDisplay = _satelliteDisplay;
    const BOOL spacecraftVisible = _spacecraftVisible;
    // 合成配置の一時解除は親位置の再計算へ通知せず、実データと一緒に復元する。
    _notifiedSatelliteSelection.reset();
    _satelliteSelection.reset(); _satelliteDisplay = hiddenSatelliteDisplay(satelliteDisplay);
    _spacecraftSelection.reset(); _spacecraftVisible = NO;
    NSString *notice = _flightNotice;
    const double lastTime = _lastFlightTime;
    const BOOL surface = _surfaceActive, earthMoon = _earthMoonMode, preview = _surfacePreview;
    const BOOL earthMoonFollowing = _earthMoonFollowing, following = _following;
    BOOL passed = NO;
    try {
        [self resetCamera];
        [self selectBody:10];
        [self startJourneyAtLatitude:25 longitude:-40];
        const auto start = _camera;
        SurfaceNavigation earth;
        const BOOL started = self.journeyActive && self.flightAnimating && [self scene].physical_navigation
            && sameFlightCamera(start, earth.camera(_bodies));
        const BOOL invalidCameraRejected = [self rejectsInvalidCameraStatesWithoutChanges];
        [self selectBody:4];
        [self orbitByX:20 y:20]; [self panByX:20 y:20]; [self zoomIn];
        const BOOL locked = _journey.destination().body_index == 10 && sameFlightCamera(start, _camera);
        [self advanceFlightAtTime:_lastFlightTime+0.5];
        const auto beforeTracking = _camera;
        auto moved = _bodies;
        moved[3].position_au.x += 1e-8;
        const auto axes = moved[3].orientation;
        constexpr double angle = 0.001;
        moved[3].orientation.x_axis = {axes.x_axis.x*std::cos(angle)+axes.y_axis.x*std::sin(angle),
            axes.x_axis.y*std::cos(angle)+axes.y_axis.y*std::sin(angle), axes.x_axis.z*std::cos(angle)+axes.y_axis.z*std::sin(angle)};
        moved[3].orientation.y_axis = {axes.y_axis.x*std::cos(angle)-axes.x_axis.x*std::sin(angle),
            axes.y_axis.y*std::cos(angle)-axes.x_axis.y*std::sin(angle), axes.y_axis.z*std::cos(angle)-axes.x_axis.z*std::sin(angle)};
        [self setBodies:moved];
        const BOOL tracked = self.flightAnimating && !sameFlightCamera(beforeTracking, _camera);
        [self setBodies:bodies];
        [self interruptFlight];
        const auto stopped = _camera;
        [self advanceFlightAtTime:_lastFlightTime+0.5];
        [self setBodies:moved];
        const BOOL frozen = self.journeyActive && !self.flightAnimating && sameFlightCamera(stopped, _camera);
        [self setBodies:bodies];
        [self resumeJourney];
        const BOOL resumed = self.flightAnimating && sameFlightCamera(stopped, _camera);
        [self advanceFlightAtTime:_lastFlightTime+1.1];
        const BOOL gapStopped = !self.flightAnimating && self.journeyActive && sameFlightCamera(stopped, _camera)
            && _journey.stop_reason() == FlightStopReason::clock_discontinuity;
        [self resumeJourney];
        const auto beforeInvalid = _camera;
        [self advanceFlightAtTime:std::numeric_limits<double>::quiet_NaN()];
        const BOOL invalidStopped = !self.flightAnimating && sameFlightCamera(beforeInvalid, _camera);
        [self resumeJourney];
        const double departureTime = _lastFlightTime;
        for (int step = 1; step <= 96; ++step) [self advanceFlightAtTime:departureTime + step*0.25];
        const auto landed = _camera;
        SurfaceNavigation moon;
        SurfaceSite moonSite;
        moonSite.body_index = 10; moonSite.latitude_deg = 25; moonSite.longitude_deg = -40;
        moon.set_site(moonSite);
        const BOOL completed = !self.journeyActive && !self.flightAnimating && self.surfaceNavigationActive
            && [self scene].physical_navigation && sameFlightCamera(landed, moon.camera(_bodies));
        // 現在の月面から次の惑星へ進む場合も、開始フレームを飛ばさない。
        [self selectBody:4];
        [self startJourneyAtLatitude:-15 longitude:70];
        const BOOL chained = self.journeyActive && self.flightAnimating && sameFlightCamera(landed, _camera)
            && _journey.destination().body_index == 4;
        [self interruptFlight];
        [self resetCamera];
        passed = started && invalidCameraRejected && locked && tracked && frozen && resumed && gapStopped && invalidStopped && completed && chained;
        if (!passed) NSLog(@"CONTINUOUS_VIEW failed start=%d camera=%d lock=%d track=%d freeze=%d resume=%d gap=%d invalid=%d complete=%d chain=%d",
            started, invalidCameraRejected, locked, tracked, frozen, resumed, gapStopped, invalidStopped, completed, chained);
    } catch (const std::exception& error) { [self reportNavigationError:error.what()]; }
    [self invalidateFlightTimer];
    _camera = camera; _bodies = bodies; _navigation = navigation; _journey = journey; _selection = selection;
    _journeyActive = NO; _lastFlightTime = lastTime;
    _flightNotice = notice; _surfaceActive = surface; _earthMoonMode = earthMoon; _surfacePreview = preview;
    _earthMoonFollowing = earthMoonFollowing; _following = following;
    _smallBodySelection = smallSelection; _smallBodiesVisible = smallVisible;
    _satelliteSelection = satelliteSelection; _satelliteDisplay = satelliteDisplay;
    _spacecraftSelection = spacecraftSelection; _spacecraftVisible = spacecraftVisible;
    _notifiedSatelliteSelection = notifiedSatelliteSelection;
    [self notifySelection]; [self notifyCamera]; self.needsDisplay = YES;
    return passed;
}
- (BOOL)runSurfaceNavigationSmokeTest {
    if (!_hasData || self.flightAnimating || self.journeyActive) return NO;
    const auto camera = _camera;
    const auto bodies = _bodies;
    const auto navigation = _navigation;
    const auto selection = _selection;
    const auto smallSelection = _smallBodySelection;
    const BOOL smallVisible = _smallBodiesVisible;
    _smallBodySelection.reset(); _smallBodiesVisible = NO;
    const auto satelliteSelection = _satelliteSelection;
    const auto spacecraftSelection = _spacecraftSelection;
    const auto notifiedSatelliteSelection = _notifiedSatelliteSelection;
    const auto satelliteDisplay = _satelliteDisplay;
    const BOOL spacecraftVisible = _spacecraftVisible;
    // 合成配置の一時解除は親位置の再計算へ通知せず、実データと一緒に復元する。
    _notifiedSatelliteSelection.reset();
    _satelliteSelection.reset(); _satelliteDisplay = hiddenSatelliteDisplay(satelliteDisplay);
    _spacecraftSelection.reset(); _spacecraftVisible = NO;
    NSString *notice = _flightNotice;
    NSString *terrainDirectory = [_terrainDataDirectory copy];
    // 合成配置の球面選択を同期的に公開し、描画済み scene と同じ経路で検証する。
    [self setTerrainDataDirectory:nil];
    const BOOL surface = _surfaceActive, earthMoon = _earthMoonMode, preview = _surfacePreview;
    const BOOL earthMoonFollowing = _earthMoonFollowing, following = _following;
    BOOL passed = NO;
    try {
        [self showEarthMoon];
        [self refreshTerrain];
        const BOOL pairVisible = self.visibleBodyCount == 2;
        // 中心円が枠外、または中心が背面でも、実球の手前交点を選べることを確認する。
        const NSRect map = [self mapRect];
        const double radius = surface_body_info(3).radius_km / astronomical_unit_km;
        const double edgeSlope = std::tan(22.5 * 3.14159265358979323846 / 180) * map.size.width / map.size.height;
        const double overhang = (1 + std::sqrt(1 + edgeSlope*edgeSlope)) / 2;
        _earthMoonFollowing = NO;
        _camera = SolarCamera{};
        _camera.yaw_deg = _camera.pitch_deg = 0;
        _camera.distance_au = 10*radius;
        _bodies[3].position_au = j2000_ecliptic_to_equatorial({0, (10*edgeSlope + overhang)*radius, 0});
        _bodies[10].position_au = {20*radius, 0, 0};
        const NSPoint edge = NSMakePoint(NSMaxX(map)-0.01, NSMidY(map));
        self.needsDisplay = YES;
        [self refreshTerrain];
        [self pickBodyAtPoint:edge];
        const BOOL pickedEdge = _selection && *_selection == 3;
        _bodies[3].position_au = j2000_ecliptic_to_equatorial({10.1*radius, 0.999*radius, 0});
        self.needsDisplay = YES;
        [self refreshTerrain];
        [self pickBodyAtPoint:edge];
        const BOOL pickedBehindCenter = _selection && *_selection == 3;
        _bodies = bodies;
        [self showEarthMoon];
        [self selectBody:10];
        [self landAtLatitude:25 longitude:-40];
        const double landingStart = _lastFlightTime;
        for (int step = 1; step <= 6; ++step) [self advanceFlightAtTime:landingStart + step*0.5];
        const BOOL landed = _surfaceActive && !self.flightAnimating && _camera.frame
            && _navigation.site().body_index == 10 && _navigation.site().height_km == minimum_surface_height_km;
        const auto beforeTracking = _camera;
        auto moved = _bodies;
        moved[10].position_au.x += 0.01;
        [self setBodies:moved];
        const BOOL tracked = std::abs(_camera.target.x-beforeTracking.target.x-0.01) < 1e-10;
        [self setBodies:bodies];
        const auto beforeLook = _navigation.site();
        [self orbitByX:20 y:10];
        [self zoomOut];
        const BOOL movedSurface = _navigation.site().heading_deg != beforeLook.heading_deg
            && _navigation.site().elevation_deg != beforeLook.elevation_deg
            && _navigation.site().height_km > minimum_surface_height_km;
        [self takeOffFromEarthAtLatitude:35 longitude:135];
        const double ascentStart = _lastFlightTime;
        for (int step = 1; step <= 6; ++step) [self advanceFlightAtTime:ascentStart + step*0.5];
        const BOOL ascended = !self.flightAnimating && _navigation.site().body_index == 3
            && std::abs(_navigation.site().height_km - 8*surface_body_info(3).radius_km) < 1e-6;
        [self landAtLatitude:35 longitude:135];
        [self advanceFlightAtTime:_lastFlightTime + 0.5];
        const auto beforeInterrupt = _camera;
        [self interruptFlight];
        [self advanceFlightAtTime:_lastFlightTime + 0.5];
        const BOOL interrupted = !self.flightAnimating && _camera.distance_au == beforeInterrupt.distance_au
            && _camera.target.x == beforeInterrupt.target.x;
        passed = pairVisible && pickedEdge && pickedBehindCenter && landed && tracked && movedSurface && ascended && interrupted;
        if (!passed) NSLog(@"SURFACE_NAVIGATION: pair=%d edge=%d behind=%d landed=%d tracked=%d moved=%d ascended=%d interrupted=%d",
            pairVisible, pickedEdge, pickedBehindCenter, landed, tracked, movedSurface, ascended, interrupted);
    } catch (const std::exception& error) { [self reportNavigationError:error.what()]; }
    [self invalidateFlightTimer];
    _camera = camera; _bodies = bodies; _navigation = navigation; _selection = selection;
    _flightNotice = notice; _surfaceActive = surface; _earthMoonMode = earthMoon; _surfacePreview = preview;
    _earthMoonFollowing = earthMoonFollowing; _following = following;
    _smallBodySelection = smallSelection; _smallBodiesVisible = smallVisible;
    _satelliteSelection = satelliteSelection; _satelliteDisplay = satelliteDisplay;
    _spacecraftSelection = spacecraftSelection; _spacecraftVisible = spacecraftVisible;
    _notifiedSatelliteSelection = notifiedSatelliteSelection;
    [self setTerrainDataDirectory:terrainDirectory];
    [self notifySelection]; [self notifyCamera]; self.needsDisplay = YES;
    return passed;
}
- (BOOL)runCameraSmokeTest {
    const NSRect map = [self mapRect];
    if (!_hasData || _surfaceActive || _journeyActive || map.size.width < 160 || map.size.height < 100) return NO;
    const BOOL savedEarthMoon = _earthMoonMode, savedEarthMoonFollowing = _earthMoonFollowing, savedPreview = _surfacePreview;
    NSString *terrainDirectory = [_terrainDataDirectory copy];
    [self setTerrainDataDirectory:nil];
    const SolarCamera saved = _camera;
    const SolarBodies savedBodies = _bodies;
    const auto selected = _selection;
    const BOOL following = _following;
    const auto smallSelection = _smallBodySelection;
    const BOOL smallVisible = _smallBodiesVisible;
    _smallBodySelection.reset(); _smallBodiesVisible = NO;
    const auto satelliteSelection = _satelliteSelection;
    const auto spacecraftSelection = _spacecraftSelection;
    const auto notifiedSatelliteSelection = _notifiedSatelliteSelection;
    const auto satelliteDisplay = _satelliteDisplay;
    const BOOL spacecraftVisible = _spacecraftVisible;
    // 合成配置の一時解除は親位置の再計算へ通知せず、実データと一緒に復元する。
    _notifiedSatelliteSelection.reset();
    _satelliteSelection.reset(); _satelliteDisplay = hiddenSatelliteDisplay(satelliteDisplay);
    _spacecraftSelection.reset(); _spacecraftVisible = NO;
    [self resetCamera];
    [self orbitByX:40 y:20];
    const BOOL rotated = _camera.yaw_deg != 35 && _camera.pitch_deg != 35;
    [self panByX:24 y:-12];
    const BOOL panned = std::hypot(_camera.target.x, _camera.target.y, _camera.target.z) > 0;
    const double farDistance = _camera.distance_au;
    [self zoomIn];
    const BOOL zoomedIn = _camera.distance_au < farDistance;
    [self zoomOut];
    const BOOL zoomedOut = std::abs(_camera.distance_au - farDistance) < 1e-10;
    [self showInnerPlanets];
    const BOOL inner = _camera.distance_au == 7;
    [self selectBody:3];
    [self focusSelection];
    const Vec3 earth = [self displayPosition:3];
    const BOOL focused = _following && _camera.target.x == earth.x && _camera.target.y == earth.y && _camera.target.z == earth.z;
    const BOOL invalidCameraRejected = [self rejectsInvalidCameraStatesWithoutChanges];
    [self resetCamera];
    [self refreshTerrain];
    const BOOL visible = self.visibleBodyCount > 0;

    // 入力イベントを注入せず、実際のクリック経路を合成配置で確認する。
    _camera = SolarCamera{};
    _camera.yaw_deg = _camera.pitch_deg = 0;
    _camera.distance_au = 10;
    for (auto& body : _bodies) body.position_au = {11, 0, 0};
    _bodies[0].position_au = {0, 0, 0};
    _bodies[1].position_au = {5, 0, 0};
    const NSPoint center = NSMakePoint(NSMidX(map), NSMidY(map));
    self.needsDisplay = YES;
    [self refreshTerrain];
    [self pickBodyAtPoint:center];
    const BOOL pickedFront = _selection && *_selection == 1;

    _bodies[1].position_au = {11, 0, 0};
    _bodies[0].position_au = {9.9995, 0, 0};
    self.needsDisplay = YES;
    [self refreshTerrain];
    [self pickBodyAtPoint:center];
    const BOOL clippedNear = !_selection;

    // 拡大球は四辺で部分表示・選択でき、円全体が枠外なら候補から外れる。
    const double focal = (map.size.height / 2) / std::tan(22.5 * 3.14159265358979323846 / 180);
    _camera.distance_au = 0.05;
    const CGFloat radius = [self radiusForBody:0 depth:_camera.distance_au];
    const std::array<NSPoint, 4> edges{{
        {-1, map.size.height / 2}, {map.size.width + 1, map.size.height / 2},
        {map.size.width / 2, -1}, {map.size.width / 2, map.size.height + 1}
    }};
    BOOL partialVisible = radius > solar_marker_radius(Body::sun), partialPicked = YES, clippedViewport = YES;
    for (std::size_t edge = 0; edge < edges.size(); ++edge) {
        const NSPoint p = edges[edge];
        _bodies[0].position_au = j2000_ecliptic_to_equatorial({0,
            (p.x - map.size.width / 2) * _camera.distance_au / focal,
            (map.size.height / 2 - p.y) * _camera.distance_au / focal});
        self.needsDisplay = YES;
        [self refreshTerrain];
        partialVisible = partialVisible && self.visibleBodyCount == 1;
        const NSPoint click = NSMakePoint(map.origin.x + std::clamp(p.x, 1.0, map.size.width - 1),
            map.origin.y + std::clamp(p.y, 1.0, map.size.height - 1));
        [self pickBodyAtPoint:click];
        partialPicked = partialPicked && _selection && *_selection == 0;

        NSPoint outside = p;
        if (edge == 0) outside.x = -radius - 2;
        else if (edge == 1) outside.x = map.size.width + radius + 2;
        else if (edge == 2) outside.y = -radius - 2;
        else outside.y = map.size.height + radius + 2;
        _bodies[0].position_au = j2000_ecliptic_to_equatorial({0,
            (outside.x - map.size.width / 2) * _camera.distance_au / focal,
            (map.size.height / 2 - outside.y) * _camera.distance_au / focal});
        self.needsDisplay = YES;
        [self refreshTerrain];
        [self pickBodyAtPoint:click];
        clippedViewport = clippedViewport && self.visibleBodyCount == 0 && !_selection;
    }

    _camera.distance_au = 10;
    _bodies[0].position_au = {0, 0, 0};
    self.needsDisplay = YES;
    [self refreshTerrain];
    [self pickBodyAtPoint:center];
    [self focusSelection];
    [self refreshTerrain];
    [self pickBodyAtPoint:NSMakePoint(NSMaxX(map) - 1, NSMaxY(map) - 1)];
    const BOOL cleared = !_selection && !_following;

    _bodies = savedBodies;
    _earthMoonMode = savedEarthMoon; _earthMoonFollowing = savedEarthMoonFollowing; _surfacePreview = savedPreview;
    _camera = saved;
    _selection = selected;
    _following = following;
    _smallBodySelection = smallSelection; _smallBodiesVisible = smallVisible;
    _satelliteSelection = satelliteSelection; _satelliteDisplay = satelliteDisplay;
    _spacecraftSelection = spacecraftSelection; _spacecraftVisible = spacecraftVisible;
    _notifiedSatelliteSelection = notifiedSatelliteSelection;
    [self setTerrainDataDirectory:terrainDirectory];
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
    return rotated && panned && zoomedIn && zoomedOut && inner && focused && invalidCameraRejected && visible
        && pickedFront && clippedNear && partialVisible && partialPicked && clippedViewport && cleared;
}
- (NSBitmapImageRep *)renderedBitmap {
    NSBitmapImageRep *bitmap = [self bitmapImageRepForCachingDisplayInRect:self.bounds];
    if (bitmap) [self cacheDisplayInRect:self.bounds toBitmapImageRep:bitmap];
    return bitmap;
}
- (BOOL)runTextureSmokeTest {
    if (!_hasData || _surfaceActive || _journeyActive || !_textures || !_textures->images[3]) return NO;
    const BOOL savedEarthMoon = _earthMoonMode, savedEarthMoonFollowing = _earthMoonFollowing, savedPreview = _surfacePreview;
    const auto savedCamera = _camera;
    const auto savedSelection = _selection;
    const BOOL savedFollowing = _following;
    const auto savedTextures = _textures;
    const auto smallSelection = _smallBodySelection;
    const BOOL smallVisible = _smallBodiesVisible;
    _smallBodySelection.reset(); _smallBodiesVisible = NO;
    const auto satelliteSelection = _satelliteSelection;
    const auto spacecraftSelection = _spacecraftSelection;
    const auto notifiedSatelliteSelection = _notifiedSatelliteSelection;
    const auto satelliteDisplay = _satelliteDisplay;
    const BOOL spacecraftVisible = _spacecraftVisible;
    // 合成配置の一時解除は親位置の再計算へ通知せず、実データと一緒に復元する。
    _notifiedSatelliteSelection.reset();
    _satelliteSelection.reset(); _satelliteDisplay = hiddenSatelliteDisplay(satelliteDisplay);
    _spacecraftSelection.reset(); _spacecraftVisible = NO;
    [self selectBody:3];
    [self showSurface];
    const NSRect map = [self mapRect];
    const CGFloat radius = [self radiusForBody:3 depth:_camera.distance_au];
    const NSRect sample = NSMakeRect(NSMidX(map) - radius / 2, NSMidY(map) - radius / 2, radius, radius);
    NSBitmapImageRep *textured = [self renderedBitmap];
    // 中心から離れた表面も選択でき、色だけの代替描画とは実画素が異なる。
    [self pickBodyAtPoint:NSMakePoint(NSMidX(map) + radius * 0.7, NSMidY(map))];
    const BOOL pickedSurface = _selection && *_selection == 3;
    [self setTextures:nullptr];
    NSBitmapImageRep *fallback = [self renderedBitmap];
    [self setTextures:savedTextures];
    [self orbitByX:180 y:0];
    NSBitmapImageRep *rotated = [self renderedBitmap];
    const BOOL passed = radius > 30 && pickedSurface
        && surfacePixelDifferences(textured, fallback, self.bounds, sample) > 20
        && surfacePixelDifferences(textured, rotated, self.bounds, sample) > 20;
    _earthMoonMode = savedEarthMoon; _earthMoonFollowing = savedEarthMoonFollowing; _surfacePreview = savedPreview;
    _camera = savedCamera;
    _selection = savedSelection;
    _following = savedFollowing;
    _smallBodySelection = smallSelection; _smallBodiesVisible = smallVisible;
    _satelliteSelection = satelliteSelection; _satelliteDisplay = satelliteDisplay;
    _spacecraftSelection = spacecraftSelection; _spacecraftVisible = spacecraftVisible;
    _notifiedSatelliteSelection = notifiedSatelliteSelection;
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
    return passed;
}
- (BOOL)runRotationSmokeTest:(const mitaka::BodyOrientation&)laterEarthOrientation {
    if (!_hasData || _surfaceActive || _journeyActive || !_textures || !_textures->images[3]) return NO;
    const BOOL savedEarthMoon = _earthMoonMode, savedEarthMoonFollowing = _earthMoonFollowing, savedPreview = _surfacePreview;
    const auto savedCamera = _camera;
    const auto savedSelection = _selection;
    const auto savedBodies = _bodies;
    const BOOL savedFollowing = _following;
    const auto smallSelection = _smallBodySelection;
    const BOOL smallVisible = _smallBodiesVisible;
    _smallBodySelection.reset(); _smallBodiesVisible = NO;
    const auto satelliteSelection = _satelliteSelection;
    const auto spacecraftSelection = _spacecraftSelection;
    const auto notifiedSatelliteSelection = _notifiedSatelliteSelection;
    const auto satelliteDisplay = _satelliteDisplay;
    const BOOL spacecraftVisible = _spacecraftVisible;
    // 合成配置の一時解除は親位置の再計算へ通知せず、実データと一緒に復元する。
    _notifiedSatelliteSelection.reset();
    _satelliteSelection.reset(); _satelliteDisplay = hiddenSatelliteDisplay(satelliteDisplay);
    _spacecraftSelection.reset(); _spacecraftVisible = NO;
    [self selectBody:3];
    [self showSurface];
    const NSRect map = [self mapRect];
    const CGFloat radius = [self radiusForBody:3 depth:_camera.distance_au];
    const NSRect sample = NSMakeRect(NSMidX(map) - radius / 2, NSMidY(map) - radius / 2, radius, radius);
    NSBitmapImageRep *before = [self renderedBitmap];
    // 位置・照明・視点を固定し、別日時の姿勢だけで実画素が変わることを確認する。
    _bodies[3].orientation = laterEarthOrientation;
    self.needsDisplay = YES;
    NSBitmapImageRep *after = [self renderedBitmap];
    const BOOL passed = surfacePixelDifferences(before, after, self.bounds, sample) > 20;
    _bodies = savedBodies;
    _earthMoonMode = savedEarthMoon; _earthMoonFollowing = savedEarthMoonFollowing; _surfacePreview = savedPreview;
    _camera = savedCamera;
    _selection = savedSelection;
    _following = savedFollowing;
    _smallBodySelection = smallSelection; _smallBodiesVisible = smallVisible;
    _satelliteSelection = satelliteSelection; _satelliteDisplay = satelliteDisplay;
    _spacecraftSelection = spacecraftSelection; _spacecraftVisible = spacecraftVisible;
    _notifiedSatelliteSelection = notifiedSatelliteSelection;
    [self notifySelection];
    [self notifyCamera];
    self.needsDisplay = YES;
    return passed;
}
@end
