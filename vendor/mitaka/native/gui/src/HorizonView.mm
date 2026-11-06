#import "RendererQuality.h"
#import "ConstellationRenderer.h"
#import "HorizonView.h"
#import "HorizonLandscapeRenderer.h"
#import "StarRenderer.h"
#import "ConstellationArtRenderer.h"
#import "GridRenderer.h"
#import "SkyView.h"
#include "horizon_objects.hpp"
#include "surface_navigation.hpp"
#include <algorithm>
#include <limits>
#include <cmath>
#include <cstring>
#include <stdexcept>
#include <type_traits>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
struct BackgroundKey {
    const SkyBackgrounds* model;
    MilkyWayMode mode;
    std::array<double, 9> observationViewport;
    std::size_t width, height;
    bool operator==(const BackgroundKey& other) const {
        return model == other.model && mode == other.mode && observationViewport == other.observationViewport
            && width == other.width && height == other.height;
    }
};
// 共通の投影座標系では、方位を右向きにするため経度を反転する。
HorizonProjectionViewport skyViewport(HorizonViewport viewport) {
    return {360 - viewport.center_azimuth_deg, viewport.center_altitude_deg, viewport.vertical_fov_deg, viewport.perspective_blend, viewport.roll_deg, viewport.perspective_fov_deg};
}
HorizonViewport horizonViewport(HorizonProjectionViewport viewport) {
    viewport = normalize_horizon_viewport(viewport);
    return {std::fmod(360 - viewport.center_ra_deg, 360), viewport.center_dec_deg, viewport.vertical_fov_deg, viewport.perspective_blend, viewport.roll_deg, viewport.perspective_fov_deg};
}
std::optional<ScreenPoint> projectHorizontal(HorizontalCoordinates coordinates,
                                             HorizonViewport viewport, NSSize size) {
    return project_horizon({360 - coordinates.azimuth_deg, coordinates.altitude_deg},
                       skyViewport(viewport), size.width, size.height);
}
void drawText(NSString *text, NSPoint point, NSColor *color, CGFloat size, const RendererDisplayOptions& quality) {
    RendererQualityScope textQuality(NSGraphicsContext.currentContext.CGContext, quality, RendererPrimitive::text);
    [text drawAtPoint:point withAttributes:@{
        NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:size weight:NSFontWeightRegular],
        NSForegroundColorAttributeName: color
    }];
}
NSString *spacecraftSampling(const SpacecraftSnapshot& snapshot, std::size_t index) {
    if (index >= snapshot.evaluations.size() || !snapshot.evaluations[index] || !snapshot.evaluations[index]->sampling) return @"位置の評価方法は未確認";
    switch (snapshot.evaluations[index]->sampling->kind) {
        case SpacecraftSamplingKind::exact_record: return @"原記録に一致";
        case SpacecraftSamplingKind::interpolated: return @"原記録間の線形補間";
        case SpacecraftSamplingKind::clamped_before: return @"記録期間前・先頭位置に固定";
        case SpacecraftSamplingKind::clamped_after: return @"記録期間後・末尾位置に固定";
    }
    return @"位置の評価方法は未確認";
}
NSColor *bodyColor(Body body, bool belowHorizon) {
    NSColor *color = body == Body::sun ? NSColor.systemYellowColor
        : body == Body::mars ? NSColor.systemOrangeColor : NSColor.systemCyanColor;
    return belowHorizon ? [color colorWithAlphaComponent:0.4] : color;
}
}

@implementation HorizonView {
    std::shared_ptr<const SkyModel> _model;
    std::shared_ptr<const ExtendedCatalogs> _catalogs;
    std::shared_ptr<const SkyBackgrounds> _backgrounds;
    MilkyWayMode _milkyWayMode;
    NSImage *_backgroundImage;
    std::optional<BackgroundKey> _backgroundKey;
    SkyBodies _bodies;
    HorizonLandscapeRenderer *_landscapeRenderer;
    ConstellationDisplayOptions _constellationDisplayOptions;
    PlanetDisplayOptions _planetDisplayOptions;
    RadiusDisplayOptions _radiusDisplayOptions;
    RendererDisplayOptions _rendererDisplayOptions;
    GridDisplayOptions _gridDisplayOptions;
    GridGeometryCache _gridCache;
    StarDisplayOptions _starDisplayOptions;
    StarRenderer *_starRenderer;
    std::shared_ptr<const ConstellationArtModel> _constellationArt;
    std::set<std::int32_t> _selectedStarNameHIPs;
    std::optional<Selection> _selection;
    std::optional<std::size_t> _smallBodySelection, _spacecraftSelection;
    std::shared_ptr<const SmallBodySnapshot> _smallBodies;
    std::shared_ptr<const SmallBodyDisplayModel> _smallBodyDisplay;
    std::shared_ptr<const SpacecraftSnapshot> _spacecraft;
    std::vector<HorizonObject> _smallBodyObjects, _spacecraftObjects;
    Vec3 _earthPosition;
    double _earthJulianDate;
    BOOL _smallBodiesVisible, _spacecraftVisible;
    SpacecraftDisplayOptions _spacecraftDisplayOptions;
    ObserverSite _site;
    std::optional<ObservationFrame> _frame;
    double _julianDate, _magnitudeLimit;
    HorizonViewport _viewport;
    NSPoint _mouseDownPoint, _lastDragPoint;
    BOOL _dragging, _showsTimeInfo;
}

- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _earthPosition = {};
        _earthJulianDate = std::numeric_limits<double>::quiet_NaN();
        _smallBodiesVisible = _spacecraftVisible = YES;
        _site = {35.68, 139.76};
        _julianDate = 2451545;
        _frame.emplace(_site, _julianDate);
        _magnitudeLimit = 6.5;
        _showsTimeInfo = YES;
        _landscapeRenderer = [[HorizonLandscapeRenderer alloc] init];
        self.accessibilityElement = YES;
        self.accessibilityRole = NSAccessibilityImageRole;
        self.accessibilityLabel = @"地平座標の全天図。方位は真北0度・東90度、高度は上向き。観測地点の風景を重ねて表示。ドラッグで移動、ホイール・ピンチで拡大。";
    }
    return self;
}
- (BOOL)isFlipped { return YES; }
- (BOOL)isOpaque { return YES; }
- (BOOL)acceptsFirstResponder { return YES; }
- (NSRect)mapRect {
    const double blend = _viewport.perspective_blend;
    return NSInsetRect(self.bounds, 42 - 24 * blend, 34 + 6 * blend);
}
- (RendererDisplayOptions)rendererDisplayOptions { return _rendererDisplayOptions; }
- (void)setRendererDisplayOptions:(RendererDisplayOptions)options {
    _rendererDisplayOptions = options;
    self.needsDisplay = YES;
}
- (ConstellationDisplayOptions)constellationDisplayOptions { return _constellationDisplayOptions; }
- (void)setConstellationDisplayOptions:(ConstellationDisplayOptions)options {
    // App が現在のカタログとの対応を検証する。読込前の設定も保持する。
    _constellationDisplayOptions = std::move(options);
    self.needsDisplay = YES;
}
- (RadiusDisplayOptions)radiusDisplayOptions { return _radiusDisplayOptions; }
- (void)setRadiusDisplayOptions:(RadiusDisplayOptions)options {
    validate_radius_display_options(options);
    moon_orbit_display_factor(options);
    _radiusDisplayOptions = options;
    self.needsDisplay = YES;
}
- (PlanetDisplayOptions)planetDisplayOptions { return _planetDisplayOptions; }
- (void)setPlanetDisplayOptions:(PlanetDisplayOptions)options {
    _planetDisplayOptions = options;
    self.needsDisplay = YES;
}
- (GridDisplayOptions)gridDisplayOptions { return _gridDisplayOptions; }
- (void)setGridDisplayOptions:(GridDisplayOptions)options {
    _gridDisplayOptions = options;
    self.needsDisplay = YES;
}
- (MilkyWayMode)milkyWayMode { return _milkyWayMode; }
- (void)setMilkyWayMode:(MilkyWayMode)mode {
    SkyBackgrounds{}.image(mode);
    if (_milkyWayMode == mode) return;
    _milkyWayMode = mode;
    self.needsDisplay = YES;
}
- (void)setSkyBackgrounds:(std::shared_ptr<const SkyBackgrounds>)backgrounds {
    if (_backgrounds == backgrounds) return;
    _backgrounds = std::move(backgrounds);
    _backgroundImage = nil;
    _backgroundKey.reset();
    self.needsDisplay = YES;
}
- (void)setObservationSite:(mitaka::ObserverSite)site julianDate:(double)julianDate {
    _gridCache.set_observation(site, julianDate);
    _site = site;
    _julianDate = julianDate;
    _frame = _gridCache.frame();
    [self rebuildMovingObjects];
    [self notifySelection];
    self.needsDisplay = YES;
}
- (StarDisplayOptions)starDisplayOptions { return _starDisplayOptions; }
- (void)setStarDisplayOptions:(StarDisplayOptions)options {
    validate_star_display(options);
    _starDisplayOptions = options;
    self.needsDisplay = YES;
}
- (double)magnitudeLimit { return _magnitudeLimit; }
- (void)setMagnitudeLimit:(double)value {
    if (!std::isfinite(value)) throw std::invalid_argument("magnitude limit must be finite");
    _magnitudeLimit = value;
    if (_selection && _selection->kind == ObjectKind::star &&
        _model->stars()[_selection->index].apparent_v_magnitude > value) _selection.reset();
    [self notifySelection];
    self.needsDisplay = YES;
}
- (double)julianDate { return _julianDate; }
- (BOOL)showsTimeInfo { return _showsTimeInfo; }
- (BOOL)showsLandscapeImage { return _landscapeRenderer.showsLandscapeImage; }
- (void)setShowsLandscapeImage:(BOOL)visible { _landscapeRenderer.showsLandscapeImage = visible; self.needsDisplay = YES; }
- (void)setEarthLandscapes:(std::shared_ptr<const EarthLandscapes>)landscapes {
    [_landscapeRenderer setModel:std::move(landscapes)];
    self.needsDisplay = YES;
}
- (void)setObserverPlaceIdentifier:(const std::string&)identifier {
    [_landscapeRenderer setObserverPlaceIdentifier:identifier];
    self.needsDisplay = YES;
}
- (const std::string&)observerPlaceIdentifier { return [_landscapeRenderer observerPlaceIdentifier]; }
- (void)setShowsTimeInfo:(BOOL)visible { _showsTimeInfo = visible; self.needsDisplay = YES; }
- (ObserverSite)observerSite { return _site; }
- (void)setObserverSite:(ObserverSite)site {
    [self setObservationSite:site julianDate:_julianDate];
}
- (void)setModel:(std::shared_ptr<const SkyModel>)model bodies:(const SkyBodies&)bodies {
    _model = std::move(model);
    _starRenderer = [[StarRenderer alloc] initWithModel:_model catalogs:_catalogs];
    [_starRenderer setSelectedNameHIPs:_selectedStarNameHIPs];
    _bodies = bodies;
    _selection.reset();
    _smallBodySelection.reset();
    _spacecraftSelection.reset();
    [self notifySelection];
    self.needsDisplay = YES;
}
- (void)setExtendedCatalogs:(std::shared_ptr<const ExtendedCatalogs>)catalogs {
    _catalogs = std::move(catalogs);
    _starRenderer = [[StarRenderer alloc] initWithModel:_model catalogs:_catalogs];
    [_starRenderer setSelectedNameHIPs:_selectedStarNameHIPs];
    self.needsDisplay = YES;
}
- (void)setConstellationArt:(std::shared_ptr<const ConstellationArtModel>)art {
    _constellationArt = std::move(art);
    self.needsDisplay = YES;
}
- (void)setSelectedStarNameHIPs:(const std::set<std::int32_t>&)hips {
    _selectedStarNameHIPs = hips;
    [_starRenderer setSelectedNameHIPs:hips];
    self.needsDisplay = YES;
}
- (void)setBodies:(const SkyBodies&)bodies julianDate:(double)julianDate {
    _gridCache.set_observation(_site, julianDate);
    _bodies = bodies;
    _julianDate = julianDate;
    _frame = _gridCache.frame();
    [self rebuildMovingObjects];
    [self notifySelection];
    self.needsDisplay = YES;
}
- (void)setBodies:(const SkyBodies&)bodies julianDate:(double)julianDate earthPosition:(Vec3)earthPosition {
    [self setBodies:bodies julianDate:julianDate earthPosition:earthPosition
        smallBodies:_smallBodies smallBodyDisplay:_smallBodyDisplay spacecraft:_spacecraft];
}
- (void)setBodies:(const SkyBodies&)bodies julianDate:(double)julianDate
    earthPosition:(Vec3)earthPosition smallBodies:(std::shared_ptr<const SmallBodySnapshot>)smallBodies
    smallBodyDisplay:(std::shared_ptr<const SmallBodyDisplayModel>)display
    spacecraft:(std::shared_ptr<const SpacecraftSnapshot>)spacecraft {
    auto prepared = [self prepareBodies:bodies julianDate:julianDate earthPosition:earthPosition
        smallBodies:std::move(smallBodies) smallBodyDisplay:std::move(display) spacecraft:std::move(spacecraft)];
    [self commitPreparedDate:std::move(prepared)];
    [self finishDateUpdate];
}
- (HorizonPreparedDate)prepareBodies:(const SkyBodies&)bodies julianDate:(double)julianDate
    earthPosition:(Vec3)earthPosition smallBodies:(std::shared_ptr<const SmallBodySnapshot>)smallBodies
    smallBodyDisplay:(std::shared_ptr<const SmallBodyDisplayModel>)display
    spacecraft:(std::shared_ptr<const SpacecraftSnapshot>)spacecraft {
    HorizonPreparedDate result;
    result.bodies = bodies;
    result.grid.set_observation(_site, julianDate);
    result.frame = result.grid.frame();
    result.earthPosition = earthPosition;
    result.julianDate = julianDate;
    result.clearSmallBodySelection = !smallBodies || (_smallBodies && _smallBodies->model != smallBodies->model);
    result.clearSpacecraftSelection = !spacecraft || (_spacecraft && _spacecraft->model != spacecraft->model);
    result.smallBodies = std::move(smallBodies);
    result.smallBodyDisplay = std::move(display);
    result.spacecraft = std::move(spacecraft);
    if (_smallBodiesVisible && result.smallBodies && result.smallBodyDisplay && result.smallBodies->model &&
        result.smallBodyDisplay->dataset().get() == &result.smallBodies->model->dataset())
        result.smallBodyObjects = horizon_small_body_objects(*result.smallBodies, *result.smallBodyDisplay, julianDate, earthPosition, horizon_earth_observer_position(*result.frame, _site.latitude_deg));
    if (_spacecraftVisible && result.spacecraft)
        result.spacecraftObjects = horizon_spacecraft_objects(*result.spacecraft, _spacecraftDisplayOptions.points,
            _spacecraftDisplayOptions.labels, julianDate, earthPosition, horizon_earth_observer_position(*result.frame, _site.latitude_deg), spacecraft_scene_position);
    return result;
}
- (void)commitPreparedDate:(HorizonPreparedDate&&)prepared {
    static_assert(std::is_nothrow_move_assignable_v<SkyBodies>);
    static_assert(std::is_nothrow_move_assignable_v<GridGeometryCache>);
    static_assert(std::is_nothrow_move_assignable_v<std::optional<ObservationFrame>>);
    _bodies = std::move(prepared.bodies);
    _gridCache = std::move(prepared.grid);
    _frame = std::move(prepared.frame);
    _earthPosition = prepared.earthPosition;
    _earthJulianDate = _julianDate = prepared.julianDate;
    _smallBodies = std::move(prepared.smallBodies);
    _smallBodyDisplay = std::move(prepared.smallBodyDisplay);
    _spacecraft = std::move(prepared.spacecraft);
    _smallBodyObjects = std::move(prepared.smallBodyObjects);
    _spacecraftObjects = std::move(prepared.spacecraftObjects);
    if (prepared.clearSmallBodySelection) _smallBodySelection.reset();
    if (prepared.clearSpacecraftSelection) _spacecraftSelection.reset();
}
- (void)finishDateUpdate {
    [self notifySelection];
    self.needsDisplay = YES;
}
- (void)rebuildMovingObjects {
    _smallBodyObjects.clear();
    _spacecraftObjects.clear();
    if (_earthJulianDate != _julianDate || !_frame) return;
    if (_smallBodiesVisible && _smallBodies && _smallBodyDisplay && _smallBodies->model &&
        _smallBodyDisplay->dataset().get() == &_smallBodies->model->dataset())
        _smallBodyObjects = horizon_small_body_objects(*_smallBodies, *_smallBodyDisplay, _julianDate, _earthPosition, horizon_earth_observer_position(*_frame, _site.latitude_deg));
    if (_spacecraftVisible && _spacecraft)
        _spacecraftObjects = horizon_spacecraft_objects(*_spacecraft, _spacecraftDisplayOptions.points,
            _spacecraftDisplayOptions.labels, _julianDate, _earthPosition, horizon_earth_observer_position(*_frame, _site.latitude_deg), spacecraft_scene_position);
}
- (void)movingObjectsChanged {
    [self rebuildMovingObjects];
    [self notifySelection];
    self.needsDisplay = YES;
}
- (BOOL)smallBodiesVisible { return _smallBodiesVisible; }
- (void)setSmallBodiesVisible:(BOOL)value { _smallBodiesVisible = value; [self movingObjectsChanged]; }
- (BOOL)spacecraftVisible { return _spacecraftVisible; }
- (void)setSpacecraftVisible:(BOOL)value { _spacecraftVisible = value; [self movingObjectsChanged]; }
- (SpacecraftDisplayOptions)spacecraftDisplayOptions { return _spacecraftDisplayOptions; }
- (void)setSpacecraftDisplayOptions:(SpacecraftDisplayOptions)value { _spacecraftDisplayOptions = value; [self movingObjectsChanged]; }
- (void)setSmallBodySnapshot:(std::shared_ptr<const SmallBodySnapshot>)snapshot {
    if (_smallBodies == snapshot) return;
    if (!snapshot || (_smallBodies && _smallBodies->model != snapshot->model)) _smallBodySelection.reset();
    _smallBodies = std::move(snapshot);
    [self movingObjectsChanged];
}
- (void)setSmallBodyDisplayModel:(std::shared_ptr<const SmallBodyDisplayModel>)display {
    _smallBodyDisplay = std::move(display); [self movingObjectsChanged];
}
- (void)setSpacecraftSnapshot:(std::shared_ptr<const SpacecraftSnapshot>)snapshot {
    if (_spacecraft == snapshot) return;
    if (!snapshot || (_spacecraft && _spacecraft->model != snapshot->model)) _spacecraftSelection.reset();
    _spacecraft = std::move(snapshot);
    [self movingObjectsChanged];
}
- (NSUInteger)selectedSmallBodyIndex { return _smallBodySelection ? *_smallBodySelection : NSNotFound; }
- (NSUInteger)selectedSpacecraftIndex { return _spacecraftSelection ? *_spacecraftSelection : NSNotFound; }
- (BOOL)selectSmallBody:(NSUInteger)index {
    if (!_smallBodies || !_smallBodies->model || index >= _smallBodies->model->dataset().records.size()) return NO;
    _selection.reset(); _spacecraftSelection.reset(); _smallBodySelection = index;
    [self notifySelection]; self.needsDisplay = YES; return YES;
}
- (BOOL)selectSpacecraft:(NSUInteger)index {
    if (!_spacecraft || !_spacecraft->model || index >= _spacecraft->positions.size()) return NO;
    _selection.reset(); _smallBodySelection.reset(); _spacecraftSelection = index;
    [self notifySelection]; self.needsDisplay = YES; return YES;
}
- (const HorizonObject*)selectedMovingObject {
    const auto* objects = _smallBodySelection ? &_smallBodyObjects : &_spacecraftObjects;
    const auto index = _smallBodySelection ? _smallBodySelection : _spacecraftSelection;
    if (!index) return nullptr;
    const auto found = std::find_if(objects->begin(), objects->end(), [&](const auto& object) { return object.index == *index; });
    return found == objects->end() ? nullptr : &*found;
}
- (HorizonViewport)viewport { return _viewport; }
- (void)setViewport:(HorizonViewport)viewport {
    _viewport = horizonViewport(skyViewport(viewport));
    self.needsDisplay = YES;
    if (self.viewportChanged) self.viewportChanged();
}
- (double)verticalFovDegrees {
    return (1 - _viewport.perspective_blend) * _viewport.vertical_fov_deg
        + _viewport.perspective_blend * 45;
}
- (BOOL)setVerticalFovDegrees:(double)degrees {
    if (!std::isfinite(degrees) || degrees <= 0 || degrees > 90 || _viewport.perspective_blend != 0)
        return NO;
    auto viewport = _viewport;
    viewport.vertical_fov_deg = degrees;
    [self setViewport:viewport];
    return YES;
}
- (void)resetView {
    if (self.userViewportChange) self.userViewportChange();
    [self setViewport:{}];
}
- (void)zoomBy:(double)factor atPoint:(NSPoint)point {
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    if (self.userViewportChange) self.userViewportChange();
    [self setViewport:horizonViewport(zoom_horizon(skyViewport(_viewport), factor,
        {point.x - map.origin.x, point.y - map.origin.y}, map.size.width, map.size.height))];
}
- (void)zoomIn { [self zoomBy:1.5 atPoint:NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds))]; }
- (void)zoomOut { [self zoomBy:1 / 1.5 atPoint:NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds))]; }
- (EquatorialCoordinates)selectionCoordinates {
    if (_selection->kind == ObjectKind::body) return _bodies[_selection->index].coordinates;
    const auto& star = _model->stars()[_selection->index];
    return {star.right_ascension_degrees, star.declination_degrees};
}
- (void)focusSelection {
    if (!_model) return;
    const auto* moving = [self selectedMovingObject];
    if (!_selection && !moving) return;
    const auto coordinates = _frame->to_horizontal(moving ? moving->coordinates : [self selectionCoordinates]);
    if (self.userViewportChange) self.userViewportChange();
    [self setViewport:{coordinates.azimuth_deg, coordinates.altitude_deg, std::min(45.0, _viewport.vertical_fov_deg),
                       _viewport.perspective_blend, _viewport.roll_deg, _viewport.perspective_fov_deg}];
}
- (BOOL)lookAtBody:(Body)body {
    HorizonViewport target;
    if (![self viewportForBody:body result:&target]) return NO;
    [self setViewport:target];
    return YES;
}
- (BOOL)viewportForBody:(Body)body result:(HorizonViewport *)result {
    if (!_model || !_frame) return NO;
    const auto found = std::find_if(_bodies.begin(), _bodies.end(), [body](const auto& candidate) { return candidate.id == body; });
    if (found == _bodies.end()) return NO;
    const auto coordinates = _frame->to_horizontal(found->coordinates);
    if (result) *result = {coordinates.azimuth_deg, coordinates.altitude_deg, _viewport.vertical_fov_deg, _viewport.perspective_blend, _viewport.roll_deg, _viewport.perspective_fov_deg};
    return YES;
}
- (BOOL)lookAtStarHIP:(int32_t)hip {
    HorizonViewport target;
    if (![self viewportForStarHIP:hip result:&target]) return NO;
    [self setViewport:target];
    return YES;
}
- (BOOL)viewportForStarHIP:(int32_t)hip result:(HorizonViewport *)result {
    if (!_model || !_frame) return NO;
    const auto index = _model->star_index(hip);
    if (!index) return NO;
    const auto& star = _model->stars()[*index];
    const auto coordinates = _frame->to_horizontal({star.right_ascension_degrees, star.declination_degrees});
    if (result) *result = {coordinates.azimuth_deg, coordinates.altitude_deg, _viewport.vertical_fov_deg, _viewport.perspective_blend, _viewport.roll_deg, _viewport.perspective_fov_deg};
    return YES;
}
- (BOOL)viewportForHeliocentricPosition:(Vec3)position julianDate:(double)julianDate result:(HorizonViewport *)result {
    if (!_model || !_frame || julianDate != _julianDate || _earthJulianDate != _julianDate) return NO;
    const auto equatorial = horizon_heliocentric_coordinates(position, _earthPosition, {0, 0, 0});
    if (!equatorial) return NO;
    const auto coordinates = _frame->to_horizontal(*equatorial);
    if (result) *result = {coordinates.azimuth_deg, coordinates.altitude_deg, _viewport.vertical_fov_deg, _viewport.perspective_blend, _viewport.roll_deg, _viewport.perspective_fov_deg};
    return YES;
}
- (BOOL)viewportForTopocentricHeliocentricPosition:(Vec3)position julianDate:(double)julianDate result:(HorizonViewport *)result {
    if (!_model || !_frame || julianDate != _julianDate || _earthJulianDate != _julianDate) return NO;
    const auto equatorial = horizon_heliocentric_coordinates(position, _earthPosition, horizon_earth_observer_position(*_frame, _site.latitude_deg));
    if (!equatorial) return NO;
    const auto coordinates = _frame->to_horizontal(*equatorial);
    if (result) *result = {coordinates.azimuth_deg, coordinates.altitude_deg, _viewport.vertical_fov_deg, _viewport.perspective_blend, _viewport.roll_deg, _viewport.perspective_fov_deg};
    return YES;
}
- (void)selectBody:(NSUInteger)index {
    if (!_model || index >= _bodies.size()) return;
    _smallBodySelection.reset(); _spacecraftSelection.reset();
    _selection = Selection{ObjectKind::body, index};
    [self notifySelection];
    self.needsDisplay = YES;
}
- (NSUInteger)selectedBodyIndex {
    return _selection && _selection->kind == ObjectKind::body ? _selection->index : NSNotFound;
}
- (void)clearSelection {
    _selection.reset(); _smallBodySelection.reset(); _spacecraftSelection.reset();
    [self notifySelection];
    self.needsDisplay = YES;
}
- (BOOL)selectStarHIP:(int32_t)hip {
    if (!_model) return NO;
    const auto index = _model->star_index(hip);
    if (!index) return NO;
    _magnitudeLimit = std::max(_magnitudeLimit, static_cast<double>(_model->stars()[*index].apparent_v_magnitude));
    _smallBodySelection.reset(); _spacecraftSelection.reset();
    _selection = Selection{ObjectKind::star, *index};
    [self notifySelection];
    self.needsDisplay = YES;
    return YES;
}
- (NSUInteger)visibleStarCount {
    if (!_model || !_starDisplayOptions.visible) return 0;
    return std::count_if(_model->stars().begin(), _model->stars().end(), [self](const auto& star) {
        if (star.apparent_v_magnitude > self->_magnitudeLimit) return false;
        const auto horizontal = self->_frame->to_horizontal({star.right_ascension_degrees, star.declination_degrees});
        return projectHorizontal(horizontal, self->_viewport, NSMakeSize(1, 1)).has_value();
    });
}
- (void)notifySelection {
    NSString *description = @"天体をクリックすると\n方位・高度と明るさ・距離を表示します。\n地平線より下の天体は暗く表示します。";
    if (_selection && _model) {
        const auto horizontal = _frame->to_horizontal([self selectionCoordinates]);
        NSString *name, *detail;
        if (_selection->kind == ObjectKind::star) {
            const auto& star = _model->stars()[_selection->index];
            name = [NSString stringWithFormat:@"HIP %d", star.hip];
            detail = [NSString stringWithFormat:@"V 等級 %.2f", star.apparent_v_magnitude];
        } else {
            const auto& body = _bodies[_selection->index];
            name = bodyName(body.id);
            detail = [NSString stringWithFormat:@"地心距離 %.6f AU", body.distance_au];
        }
        description = [NSString stringWithFormat:@"%@\n方位 %.3f° / 高度 %+.3f°%@\n%@",
            name, horizontal.azimuth_deg, horizontal.altitude_deg, horizontal.altitude_deg < 0 ? @"（地平線下）" : @"", detail];
    }
    if ((_smallBodySelection || _spacecraftSelection) && _model) {
        const auto* object = [self selectedMovingObject];
        const std::string& title = _smallBodySelection ? _smallBodies->model->title(*_smallBodySelection)
                                                       : _spacecraft->model->title(*_spacecraftSelection);
        NSString *name = [NSString stringWithUTF8String:title.c_str()];
        if (!name) name = @"名称不明";
        if (object) {
            const auto horizontal = _frame->to_horizontal(object->coordinates);
            NSString *distance = object->distance_au < 0.001
                ? [NSString stringWithFormat:@"%.6g km", object->distance_au * astronomical_unit_km]
                : [NSString stringWithFormat:@"%.6f AU", object->distance_au];
            description = [NSString stringWithFormat:@"%@\n方位 %.3f° / 高度 %+.3f°%@\n観測地点からの距離 %@",
                name, horizontal.azimuth_deg, horizontal.altitude_deg, horizontal.altitude_deg < 0 ? @"（地平線下）" : @"", distance];
        } else description = [NSString stringWithFormat:@"%@\n現在の時刻または表示設定では位置を表示できません。", name];
        if (object && _spacecraftSelection)
            description = [description stringByAppendingFormat:@"\n%@", spacecraftSampling(*_spacecraft, *_spacecraftSelection)];
    }
    if (self.selectionChanged) self.selectionChanged(description);
}
- (void)mouseDown:(NSEvent *)event {
    if (!_model) return;
    [self.window makeFirstResponder:self];
    _mouseDownPoint = _lastDragPoint = [self convertPoint:event.locationInWindow fromView:nil];
    _dragging = NO;
}
- (void)mouseDragged:(NSEvent *)event {
    if (!_model) return;
    const NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    _dragging = _dragging || std::hypot(point.x - _mouseDownPoint.x, point.y - _mouseDownPoint.y) > 3;
    if (_dragging) {
        if (self.userViewportChange) self.userViewportChange();
        [self setViewport:horizonViewport(pan_horizon(skyViewport(_viewport),
            point.x - _lastDragPoint.x, point.y - _lastDragPoint.y, map.size.width, map.size.height))];
    }
    _lastDragPoint = point;
}
- (void)mouseUp:(NSEvent *)event {
    if (!_model || _dragging) return;
    const NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0 || !NSPointInRect(point, map)) return;
    _selection.reset(); _smallBodySelection.reset(); _spacecraftSelection.reset();
    if ([_landscapeRenderer isOpaqueAtPoint:point inRect:map viewport:_viewport]) {
        [self notifySelection];
        self.needsDisplay = YES;
        return;
    }
    double nearest = 8 * 8;
    const auto unobscured = [&](const auto& projected) {
        return ![_landscapeRenderer isOpaqueAtPoint:NSMakePoint(map.origin.x + projected.x, map.origin.y + projected.y)
                                             inRect:map viewport:_viewport];
    };
    const auto consider = [&](EquatorialCoordinates coordinates, Selection selection) {
        const auto projected = projectHorizontal(_frame->to_horizontal(coordinates), _viewport, map.size);
        if (!projected) return;
        const double dx = map.origin.x + projected->x - point.x, dy = map.origin.y + projected->y - point.y;
        const double distance = dx * dx + dy * dy;
        if (distance <= nearest && unobscured(*projected)) { nearest = distance; _selection = selection; }
    };
    for (std::size_t index = 0; _starDisplayOptions.visible && index < _model->stars().size(); ++index) {
        const auto& star = _model->stars()[index];
        if (star.apparent_v_magnitude <= _magnitudeLimit)
            consider({star.right_ascension_degrees, star.declination_degrees}, {ObjectKind::star, index});
    }
    for (std::size_t index = 0; _planetDisplayOptions.visible && index < _bodies.size(); ++index)
        consider(_bodies[index].coordinates, {ObjectKind::body, index});
    const auto considerMoving = [&](const HorizonObject& object, bool smallBody) {
        if (!object.body) return;
        const auto projected = projectHorizontal(_frame->to_horizontal(object.coordinates), _viewport, map.size);
        if (!projected) return;
        const double dx = map.origin.x + projected->x - point.x, dy = map.origin.y + projected->y - point.y;
        const double distance = dx * dx + dy * dy;
        if (distance <= nearest && unobscured(*projected)) {
            nearest = distance; _selection.reset();
            if (smallBody) { _smallBodySelection = object.index; _spacecraftSelection.reset(); }
            else { _spacecraftSelection = object.index; _smallBodySelection.reset(); }
        }
    };
    for (const auto& object : _smallBodyObjects) considerMoving(object, true);
    for (const auto& object : _spacecraftObjects) considerMoving(object, false);
    double nearestBody = std::numeric_limits<double>::infinity();
    const bool hadNearestSelection = _selection.has_value() || _smallBodySelection.has_value() || _spacecraftSelection.has_value();
    for (std::size_t index = 0; !hadNearestSelection && _planetDisplayOptions.visible && index < _bodies.size(); ++index) {
        const auto projected = projectHorizontal(_frame->to_horizontal(_bodies[index].coordinates), _viewport, map.size);
        if (!projected) continue;
        const double distance = std::hypot(point.x - map.origin.x - projected->x, point.y - map.origin.y - projected->y);
        const double radius = std::clamp(4 * body_marker_display_factor(_radiusDisplayOptions,
            RadiusDisplayContext::planetarium, _bodies[index].id), 1.0, 120.0);
        if (distance <= radius && distance < nearestBody && unobscured(*projected)) {
            nearestBody = distance;
            _selection = Selection{ObjectKind::body, index};
        }
    }
    [self notifySelection];
    self.needsDisplay = YES;
    if (event.clickCount == 2) [self focusSelection];
}
- (void)scrollWheel:(NSEvent *)event {
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    if (event.hasPreciseScrollingDeltas) {
        if (self.userViewportChange) self.userViewportChange();
        [self setViewport:horizonViewport(pan_horizon(skyViewport(_viewport), event.scrollingDeltaX,
            event.scrollingDeltaY, map.size.width, map.size.height))];
    } else [self zoomBy:std::exp(std::clamp(event.scrollingDeltaY * 0.08, -2.0, 2.0))
             atPoint:[self convertPoint:event.locationInWindow fromView:nil]];
}
- (void)magnifyWithEvent:(NSEvent *)event {
    [self zoomBy:std::exp(std::clamp(static_cast<double>(event.magnification), -2.0, 2.0))
         atPoint:[self convertPoint:event.locationInWindow fromView:nil]];
}
- (void)keyDown:(NSEvent *)event {
    NSString *characters = event.charactersIgnoringModifiers;
    if ([characters isEqualToString:@"+"] || [characters isEqualToString:@"="]) [self zoomIn];
    else if ([characters isEqualToString:@"-"]) [self zoomOut];
    else if ([characters isEqualToString:@"0"]) [self resetView];
    else [super keyDown:event];
}

- (void)drawSkyBackgroundInRect:(NSRect)map {
    const auto* texture = _backgrounds ? _backgrounds->image(_milkyWayMode) : nullptr;
    if (!texture) return;
    const double limit = _viewport.perspective_blend > 0 && _viewport.perspective_blend < 1 ? 512 : 1024;
    const double scale = std::min(1.0, limit / std::max(map.size.width, map.size.height));
    const auto width = static_cast<std::size_t>(std::clamp(std::ceil(map.size.width * scale), 1.0, limit));
    const auto height = static_cast<std::size_t>(std::clamp(std::ceil(map.size.height * scale), 1.0, limit));
    const BackgroundKey key{_backgrounds.get(), _milkyWayMode,
        {_site.latitude_deg, _site.longitude_deg, _julianDate,
         _viewport.center_azimuth_deg, _viewport.center_altitude_deg, _viewport.vertical_fov_deg,
         _viewport.perspective_blend, _viewport.roll_deg, _viewport.perspective_fov_deg}, width, height};
    // 非表示中の日時更新は描画まで評価しない。同一 JD の天体更新も画像を再生成しない。
    if (!_backgroundImage || !_backgroundKey || !(*_backgroundKey == key)) {
        const auto pixels = render_horizon_background(*texture, _viewport, *_frame, width, height);
        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
            pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
            isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:NSBitmapFormatAlphaNonpremultiplied
            bytesPerRow:width * 4 bitsPerPixel:32];
        if (bitmap) {
            std::memcpy(bitmap.bitmapData, pixels.rgba.data(), pixels.rgba.size());
            bitmap = [bitmap bitmapImageRepByRetaggingWithColorSpace:NSColorSpace.sRGBColorSpace];
        }
        _backgroundImage = bitmap ? [[NSImage alloc] initWithSize:map.size] : nil;
        if (bitmap) [_backgroundImage addRepresentation:bitmap];
        _backgroundKey = key;
    }
    RendererQualityScope clipped(NSGraphicsContext.currentContext.CGContext, _rendererDisplayOptions);
    CGContextClipToRect(NSGraphicsContext.currentContext.CGContext, map);
    [_backgroundImage drawInRect:map fromRect:NSZeroRect operation:NSCompositingOperationPlusLighter
        fraction:1 respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
}
- (void)drawGrid:(CGContextRef)context inRect:(NSRect)map {
    if (!_landscapeRenderer.hasModel && (_viewport.perspective_blend > 0 || _viewport.roll_deg != 0)) {
        // 投影の変形中も、画素の逆投影で地平線の上下を判定する。
        const int columns = std::max(1, static_cast<int>(std::ceil(map.size.width)));
        const int rows = 64;
        const auto viewport = skyViewport(_viewport);
        CGContextSetRGBFillColor(context, 0.11, 0.10, 0.09, 1);
        CGContextBeginPath(context);
        for (int x = 0; x < columns; ++x) {
            const double px = (x + 0.5) * map.size.width / columns;
            auto altitude = [&](double y) {
                return unproject_horizon({px, y}, viewport, map.size.width, map.size.height).declination_deg;
            };
            double y0 = 0, a0 = altitude(0);
            for (int row = 1; row <= rows; ++row) {
                const double y1 = row * map.size.height / rows;
                const double a1 = altitude(y1);
                double boundary = y1;
                if ((a0 < 0) != (a1 < 0)) {
                    double low = y0, high = y1;
                    for (int i = 0; i < 12; ++i) {
                        const double mid = (low + high) / 2;
                        if ((altitude(mid) < 0) == (a0 < 0)) low = mid; else high = mid;
                    }
                    boundary = (low + high) / 2;
                }
                if (a0 < 0) CGContextAddRect(context, CGRectMake(NSMinX(map) + x * map.size.width / columns,
                    NSMinY(map) + y0, map.size.width / columns + 0.1, boundary - y0));
                if (a1 < 0 && boundary < y1) CGContextAddRect(context, CGRectMake(NSMinX(map) + x * map.size.width / columns,
                    NSMinY(map) + boundary, map.size.width / columns + 0.1, y1 - boundary));
                y0 = y1; a0 = a1;
            }
        }
        CGContextFillPath(context);
    } else if (!_landscapeRenderer.hasModel) {
        // 球面回転後の地平線は一般に曲線になる。
        constexpr double radians = 3.14159265358979323846 / 180;
        const double tilt = _viewport.center_altitude_deg * radians;
        const int columns = std::max(1, static_cast<int>(std::ceil(map.size.width)));
        CGContextSetRGBFillColor(context, 0.11, 0.10, 0.09, 1);
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, NSMinX(map), NSMaxY(map));
        for (int i = 0; i <= columns; ++i) {
            const double fraction = static_cast<double>(i) / columns;
            const double fov = std::max(_viewport.vertical_fov_deg, 1e-9);
            const double longitude = (0.5 - fraction) * 2 * fov * radians;
            const double latitude = std::atan2(-std::cos(longitude) * std::sin(tilt), std::cos(tilt));
            const double y = std::clamp(NSMidY(map) - latitude / radians / fov * map.size.height,
                                        static_cast<double>(NSMinY(map)), static_cast<double>(NSMaxY(map)));
            CGContextAddLineToPoint(context, NSMinX(map) + fraction * map.size.width, y);
        }
        CGContextAddLineToPoint(context, NSMaxX(map), NSMaxY(map));
        CGContextClosePath(context);
        CGContextFillPath(context);
    }
    draw_horizon_grids(context, map, skyViewport(_viewport), _gridDisplayOptions, _gridCache, _rendererDisplayOptions);
}
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    RendererQualityScope canvas(context, _rendererDisplayOptions);
    [[NSColor colorWithSRGBRed:0.025 green:0.043 blue:0.072 alpha:1] setFill];
    NSRectFill(self.bounds);
    const NSRect map = [self mapRect];
    if (map.size.width <= 0 || map.size.height <= 0) return;
    [self drawSkyBackgroundInRect:map];
    [self drawGrid:context inRect:map];
    NSString *time = _showsTimeInfo ? [NSString stringWithFormat:@" · JD %.5f", _julianDate] : @"";
    drawText([NSString stringWithFormat:@"地平座標（小天体・PTH 以外の視差なし、大気差なし） · 緯度 %+.2f° 東経 %+.2f°%@ · %.6g°", _site.latitude_deg,
        _site.longitude_deg, time, self.verticalFovDegrees], NSMakePoint(map.origin.x, 8), NSColor.secondaryLabelColor, 11, _rendererDisplayOptions);
    if (!_model) {
        drawText(@"「データを開く」で hip.dat と cf96.dat のあるフォルダを選択", NSMakePoint(map.origin.x + 20, NSMidY(map)), NSColor.labelColor, 13, _rendererDisplayOptions);
        return;
    }
    const auto artStats = _constellationArt ? draw_horizon_constellation_art(context, *_constellationArt,
        _constellationDisplayOptions, _rendererDisplayOptions, *_frame, _viewport, map) : ConstellationArtRenderStats{};
    const auto constellationStats = draw_horizon_constellations(context, *_model, _constellationDisplayOptions,
        _rendererDisplayOptions, *_frame, _viewport, map);
    if (constellationStats.omitted_intervals || artStats.omitted_intervals) {
        drawText([NSString stringWithFormat:@"星座: 投影の分割上限で %lu 区間を省略",
            static_cast<unsigned long>(constellationStats.omitted_intervals + artStats.omitted_intervals)],
            NSMakePoint(map.origin.x, NSMaxY(map) + 10), NSColor.secondaryLabelColor, 10, _rendererDisplayOptions);
    }
    RendererQualityScope clipped(context, _rendererDisplayOptions);
    CGContextClipToRect(context, map);
    [_starRenderer drawInRect:map magnitudeLimit:_magnitudeLimit options:_starDisplayOptions quality:_rendererDisplayOptions
        projector:[&](EquatorialCoordinates coordinates) -> std::optional<StarProjection> {
            const auto horizontal = _frame->to_horizontal(coordinates);
            const auto point = projectHorizontal(horizontal, _viewport, map.size);
            return point ? std::optional<StarProjection>{{*point, horizontal.altitude_deg < 0 ? 0.3 : 1}} : std::nullopt;
        }];
    for (const auto& body : _bodies) {
        if (!_planetDisplayOptions.visible) break;
        const auto horizontal = _frame->to_horizontal(body.coordinates);
        const auto point = projectHorizontal(horizontal, _viewport, map.size);
        if (!point) continue;
        const NSPoint center = NSMakePoint(map.origin.x + point->x, map.origin.y + point->y);
        NSColor *color = bodyColor(body.id, horizontal.altitude_deg < 0);
        RendererQualityScope points(context, _rendererDisplayOptions, RendererPrimitive::point);
        [color setFill];
        const double radius = std::clamp(4 * body_marker_display_factor(_radiusDisplayOptions,
            RadiusDisplayContext::planetarium, body.id), 1.0, 120.0);
        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(center.x - radius, center.y - radius, 2 * radius, 2 * radius)] fill];
        if (_planetDisplayOptions.labels) drawText(bodyName(body.id), NSMakePoint(center.x + radius + 4, center.y - 16), color, 12, _rendererDisplayOptions);
    }
    const auto drawMoving = [&](const std::vector<HorizonObject>& objects, bool smallBody) {
        for (const auto& object : objects) {
            const auto horizontal = _frame->to_horizontal(object.coordinates);
            const auto point = projectHorizontal(horizontal, _viewport, map.size);
            if (!point) continue;
            const NSPoint center = NSMakePoint(map.origin.x + point->x, map.origin.y + point->y);
            NSColor *color = smallBody ? NSColor.systemOrangeColor : NSColor.systemGreenColor;
            if (horizontal.altitude_deg < 0) color = [color colorWithAlphaComponent:0.4];
            if (object.body) {
                RendererQualityScope points(context, _rendererDisplayOptions, RendererPrimitive::point);
                [color setFill];
                [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(center.x - 3, center.y - 3, 6, 6)] fill];
            }
            if (object.label) {
                const auto& title = smallBody ? _smallBodies->model->title(object.index) : _spacecraft->model->title(object.index);
                NSString *name = [NSString stringWithUTF8String:title.c_str()];
                if (!name) name = @"名称不明";
                if (!smallBody && object.index < _spacecraft->evaluations.size() && _spacecraft->evaluations[object.index] && _spacecraft->evaluations[object.index]->sampling) {
                    const auto kind = _spacecraft->evaluations[object.index]->sampling->kind;
                    if (kind == SpacecraftSamplingKind::clamped_before || kind == SpacecraftSamplingKind::clamped_after)
                        name = [name stringByAppendingString:@"（期間外・端点固定）"];
                }
                drawText(name, NSMakePoint(center.x + 7, center.y - 12), color, 11, _rendererDisplayOptions);
            }
        }
    };
    drawMoving(_smallBodyObjects, true);
    drawMoving(_spacecraftObjects, false);
    if (const auto* object = [self selectedMovingObject]; object && object->body) {
        const auto point = projectHorizontal(_frame->to_horizontal(object->coordinates), _viewport, map.size);
        if (point) {
            RendererQualityScope lines(context, _rendererDisplayOptions, RendererPrimitive::line);
            [NSColor.whiteColor setStroke];
            [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(map.origin.x + point->x - 9, map.origin.y + point->y - 9, 18, 18)] stroke];
        }
    }
    if (_selection && (_selection->kind == ObjectKind::star
        ? _starDisplayOptions.visible : _planetDisplayOptions.visible)) {
        const auto point = projectHorizontal(_frame->to_horizontal([self selectionCoordinates]), _viewport, map.size);
        if (point) {
            RendererQualityScope lines(context, _rendererDisplayOptions, RendererPrimitive::line);
            [NSColor.whiteColor setStroke];
            const double radius = _selection->kind == ObjectKind::body
                ? std::max(9.0, 4 + std::clamp(4 * body_marker_display_factor(_radiusDisplayOptions,
                    RadiusDisplayContext::planetarium, _bodies[_selection->index].id), 1.0, 120.0)) : 9.0;
            NSBezierPath *ring = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(map.origin.x + point->x - radius,
                map.origin.y + point->y - radius, 2 * radius, 2 * radius)];
            ring.lineWidth = 1;
            [ring stroke];
        }
    }
    [_landscapeRenderer drawInRect:map viewport:_viewport quality:_rendererDisplayOptions];
    if (_landscapeRenderer.hasModel)
        draw_horizon_grids(context, map, skyViewport(_viewport), _gridDisplayOptions, _gridCache, _rendererDisplayOptions);
}
@end
