#import "GalaxyOverlay.h"
#include "OurGalaxyRadiativeRenderer.h"
#include "our_galaxy_navigation.hpp"
#include <algorithm>
#include <array>
#include <atomic>
#include <cmath>
#include <exception>
#include <limits>

using namespace mitaka::gui;
@protocol GalaxyOverlayRedrawTarget <NSObject>
- (void)redrawPublishedScene;
@end

namespace {
bool sameFrame(const std::optional<SolarCameraBasis>& a, const std::optional<SolarCameraBasis>& b) {
    if (a.has_value() != b.has_value()) return false;
    if (!a) return true;
    const auto equal = [](mitaka::Vec3 x, mitaka::Vec3 y) { return x.x == y.x && x.y == y.y && x.z == y.z; };
    return equal(a->right, b->right) && equal(a->up, b->up) && equal(a->outward, b->outward);
}
bool sameRequest(const GalaxyOverlayRequest& a, const GalaxyOverlayRequest& b) {
    return a.camera.target.x_pc == b.camera.target.x_pc && a.camera.target.y_pc == b.camera.target.y_pc &&
        a.camera.target.z_pc == b.camera.target.z_pc &&
        a.camera.target_offset_au.x == b.camera.target_offset_au.x &&
        a.camera.target_offset_au.y == b.camera.target_offset_au.y &&
        a.camera.target_offset_au.z == b.camera.target_offset_au.z && a.camera.distance_pc == b.camera.distance_pc &&
        a.camera.yaw_deg == b.camera.yaw_deg && a.camera.pitch_deg == b.camera.pitch_deg && a.camera.roll_deg == b.camera.roll_deg &&
        a.camera.vertical_fov_deg == b.camera.vertical_fov_deg && a.camera.frame_is_orbit == b.camera.frame_is_orbit &&
        sameFrame(a.camera.frame, b.camera.frame) && NSEqualSizes(a.size, b.size) && a.scale == b.scale &&
        a.quality.antialias == b.quality.antialias && a.quality.point_smoothing == b.quality.point_smoothing &&
        a.quality.line_smoothing == b.quality.line_smoothing && a.quality.text_smoothing == b.quality.text_smoothing &&
        a.visibility.sdss_galaxies == b.visibility.sdss_galaxies && a.visibility.sdss_quasars == b.visibility.sdss_quasars &&
        a.visibility.globular_clusters == b.visibility.globular_clusters && a.visibility.nearby_galaxies == b.visibility.nearby_galaxies &&
        a.hip_visible == b.hip_visible && a.our_galaxy_visible == b.our_galaxy_visible;
}
// 旧 Plus と native の座標変換・測光は未解明。画面にも仮定を表示する。
const OurGalaxyRenderSettings ourSettings{
    {{{{1,0,0},{0,1,0},{0,0,1}}}, {0,0,0}},
    {{{.99973613,.99461782,.99999994,.4,.75},{.860875785,.993465781,.99999994,.4,.75},
      {.99999994,.98355633,.898172021,.3,.75},{.99999994,.928406835,.559402168,.3,.75}}},
    "公式 1.3.1 の太陽中心黄道座標を暫定採用、旧 Plus 未検証", "公式 1.3.1 の群色を元にした近似"};
struct PreviewSample {
    std::size_t step;
    std::optional<std::size_t> selected;

    // 各区間の代表を原行順で一度だけ描く。選択中の区間も同じ予算を使う。
    std::size_t representative(std::size_t ordinal) const {
        const auto first = ordinal - ordinal % step;
        if (selected && *selected >= first && *selected - first < step) return *selected;
        return first;
    }
};
std::optional<PreviewSample> previewSample(const GalaxySpatialModel& model, std::size_t source,
                                           std::optional<GalaxySpatialRecordId> selected) {
    constexpr std::size_t budget = 6000;
    const auto sources = model.sources().size();
    const bool selectedSource = selected && selected->source_index == source;
    // 出典数が予算を超え、選択出典に通常の枠がない場合だけ1枠を予約する。
    const bool reserve = selected && selected->source_index >= budget;
    const auto shared = budget - reserve;
    const auto quota = shared / sources + (source < shared % sources) + (reserve && selectedSource);
    if (!quota) return std::nullopt;
    const auto count = model.source_size(source);
    const auto step = std::max<std::size_t>(1, count / quota + (count % quota != 0));
    return PreviewSample{step, selectedSource ? std::optional{selected->ordinal} : std::nullopt};
}
template<class F> void forPreviewRows(const GalaxySpatialModel& model, GalaxySpatialVisibility visibility,
                                      std::optional<GalaxySpatialRecordId> selected, F visit) {
    for (std::size_t source = 0; source < model.sources().size(); ++source) {
        const auto family = model.family(source);
        if (!visibility.visible(family)) continue;
        const auto sample = previewSample(model, source, selected);
        if (!sample) continue;
        const auto count = model.source_size(source);
        for (std::size_t ordinal = 0; ordinal < count; ordinal += sample->step)
            if (!visit(GalaxySpatialRecordId{family, source, sample->representative(ordinal)})) return;
    }
}
}

@implementation GalaxyOverlay {
    __weak NSView *_view;
    std::shared_ptr<const GalaxySpatialModel> _model;
    std::shared_ptr<const mitaka::OurGalaxyModel> _ourGalaxyModel;
    std::shared_ptr<const mitaka::OurGalaxyRadiativeModel> _renderedOurGalaxyRadiative;
    std::shared_ptr<const HipSpatialModel> _hipModel;
    std::shared_ptr<std::atomic<std::uint64_t>> _generation;
    std::shared_ptr<std::atomic<std::uint64_t>> _pickGeneration;
    dispatch_queue_t _queue;
    std::optional<GalaxyOverlayRequest> _requested, _rendered;
    GalaxyOverlayDiagnostics _diagnostics;
    std::optional<GalaxySpatialRecordId> _displayedPreviewSelection;
    BOOL _running;
    NSImage *_image;
    NSImage *_ourGalaxyImage;
    NSImage *_ourGalaxyMultiplier;
    NSImage *_ourGalaxyEmission;
    NSImage *_hipImage;
    std::size_t _renderedHipDrawn;
    std::size_t _renderedOurGalaxyDrawn;
    std::size_t _renderedDrawn;
    NSString *_renderFailure;
    NSString *_selectionFailure;
    GalaxySpatialVisibility _visibility;
    BOOL _hipVisible;
    BOOL _ourGalaxyVisible;
}
- (instancetype)initWithView:(NSView *)view {
    if ((self = [super init])) {
        _view = view;
        _generation = std::make_shared<std::atomic<std::uint64_t>>(0);
        _pickGeneration = std::make_shared<std::atomic<std::uint64_t>>(0);
        _queue = dispatch_queue_create("org.mitaka.solar-galaxy-overlay", DISPATCH_QUEUE_SERIAL);
        _hipVisible = YES;
        _ourGalaxyVisible = YES;
    }
    return self;
}
- (void)dealloc { _generation->fetch_add(1, std::memory_order_relaxed); [self invalidatePendingPicks]; }
- (void)redrawPublishedScene {
    NSView *view = _view;
    // 非同期画像の完成は新しい scene ではないため、地形の再計算を要求しない。
    if ([view respondsToSelector:@selector(redrawPublishedScene)])
        [(id<GalaxyOverlayRedrawTarget>)view redrawPublishedScene];
    else
        view.needsDisplay = YES;
}
- (void)invalidatePendingPicks {
    _pickGeneration->fetch_add(1, std::memory_order_relaxed);
    _selectionFailure = nil;
}
- (std::shared_ptr<const GalaxySpatialModel>)model { return _model; }
- (std::shared_ptr<const mitaka::OurGalaxyModel>)ourGalaxyModel { return _ourGalaxyModel; }
- (std::shared_ptr<const HipSpatialModel>)hipModel { return _hipModel; }
- (BOOL)isOurGalaxyVisible { return _ourGalaxyVisible; }
- (void)setHipModel:(std::shared_ptr<const HipSpatialModel>)model {
    if (_hipModel == model) return;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _hipModel = std::move(model); _requested.reset(); _rendered.reset();
    _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _renderFailure = nil; _running = NO;
    _diagnostics = {}; _view.needsDisplay = YES;
}
- (void)setOurGalaxyModel:(std::shared_ptr<const mitaka::OurGalaxyModel>)model {
    if (_ourGalaxyModel == model) return;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _ourGalaxyModel = std::move(model); _renderedOurGalaxyRadiative.reset(); _requested.reset(); _rendered.reset();
    _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _renderFailure = nil; _running = NO;
    _diagnostics = {}; _view.needsDisplay = YES;
}
- (void)setVisibility:(GalaxySpatialVisibility)visibility {
    if (_visibility.sdss_galaxies == visibility.sdss_galaxies && _visibility.sdss_quasars == visibility.sdss_quasars &&
        _visibility.globular_clusters == visibility.globular_clusters && _visibility.nearby_galaxies == visibility.nearby_galaxies) return;
    _visibility = visibility;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _requested.reset(); _rendered.reset(); _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _renderFailure = nil; _running = NO;
    _diagnostics = {};
    _view.needsDisplay = YES;
}
- (void)setHipVisible:(BOOL)visible {
    if (_hipVisible == visible) return;
    _hipVisible = visible;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _requested.reset(); _rendered.reset(); _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _renderFailure = nil; _running = NO;
    _diagnostics = {}; _view.needsDisplay = YES;
}
- (void)setOurGalaxyVisible:(BOOL)visible {
    if (_ourGalaxyVisible == visible) return;
    _ourGalaxyVisible = visible;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _requested.reset(); _rendered.reset(); _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _renderFailure = nil; _running = NO;
    _diagnostics = {}; _view.needsDisplay = YES;
}
- (void)setModel:(std::shared_ptr<const GalaxySpatialModel>)model {
    if (_model == model) return;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _model = std::move(model); _requested.reset(); _rendered.reset(); _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _renderFailure = nil; _running = NO;
    _diagnostics = {};
    _view.needsDisplay = YES;
}
- (void)startLatest {
    if (_running || (!_model && !_ourGalaxyModel && !_hipModel) || !_requested || (_rendered && sameRequest(*_rendered, *_requested))) return;
    _running = YES;
    const auto request = *_requested;
    const auto model = _model;
    const auto ourModel = _ourGalaxyModel;
    const auto cachedRadiative = _renderedOurGalaxyRadiative;
    const auto hipModel = _hipModel;
    const auto generation = _generation;
    const auto expected = generation->load(std::memory_order_relaxed);
    __weak GalaxyOverlay *weakSelf = self;
    dispatch_async(_queue, ^{
        const auto cancelled = [generation, expected] { return generation->load(std::memory_order_relaxed) != expected; };
        std::shared_ptr<const GalaxyBitmap> bitmap, ourBitmap, hipBitmap;
        std::shared_ptr<const OurGalaxyRadiativeImages> radiativeImages;
        std::shared_ptr<const mitaka::OurGalaxyRadiativeModel> radiative;
        NSMutableArray<NSString *> *failures = [NSMutableArray array];
        try {
            if (ourModel && request.our_galaxy_visible) {
                radiative = cachedRadiative ? cachedRadiative : std::make_shared<const mitaka::OurGalaxyRadiativeModel>(*ourModel);
                if (our_galaxy_alpha(request.camera) > 0) {
                    radiativeImages = render_our_galaxy_radiative(*radiative, request.camera,
                        request.size.width, request.size.height, cancelled);
                    if (radiativeImages && !cancelled())
                        ourBitmap = render_our_galaxy_points(*ourModel, ourSettings, request.camera, request.quality,
                            request.size.width, request.size.height, request.scale, cancelled, radiative.get(), radiativeImages->alpha());
                }
            }
        } catch (const std::exception& error) {
            [failures addObject:[NSString stringWithFormat:@"天の川: %s", error.what()]];
        }
        try {
            if (hipModel && request.hip_visible && !cancelled()) hipBitmap = render_hip_spatial_bitmap(*hipModel, request.camera, request.quality,
                request.size.width, request.size.height, request.scale, cancelled);
        } catch (const std::exception& error) {
            [failures addObject:[NSString stringWithFormat:@"HIP: %s", error.what()]];
        }
        try {
            if (model && !cancelled()) bitmap = render_galaxy_bitmap(*model, request.camera, request.visibility, request.quality,
                request.size.width, request.size.height, request.scale, cancelled, GalaxyBackground::transparent);
        } catch (const std::exception& error) {
            [failures addObject:[NSString stringWithFormat:@"銀河カタログ: %s", error.what()]];
        }
        NSString *failure = failures.count ? [failures componentsJoinedByString:@" · "] : nil;
        if (cancelled()) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            GalaxyOverlay *overlay = weakSelf;
            if (!overlay || cancelled()) return;
            overlay->_running = NO;
            overlay->_rendered = request;
            overlay->_renderedOurGalaxyRadiative = radiative;
            overlay->_image = bitmap ? [[NSImage alloc] initWithCGImage:bitmap->image() size:request.size] : nil;
            overlay->_ourGalaxyImage = ourBitmap ? [[NSImage alloc] initWithCGImage:ourBitmap->image() size:request.size] : nil;
            overlay->_ourGalaxyMultiplier = radiativeImages ? [[NSImage alloc] initWithCGImage:radiativeImages->multiplier() size:request.size] : nil;
            overlay->_ourGalaxyEmission = radiativeImages ? [[NSImage alloc] initWithCGImage:radiativeImages->emission() size:request.size] : nil;
            overlay->_hipImage = hipBitmap ? [[NSImage alloc] initWithCGImage:hipBitmap->image() size:request.size] : nil;
            overlay->_renderedHipDrawn = hipBitmap ? hipBitmap->counts().drawn : 0;
            overlay->_renderedDrawn = bitmap ? bitmap->counts().drawn : 0;
            overlay->_renderedOurGalaxyDrawn = ourBitmap ? ourBitmap->counts().drawn : 0;
            overlay->_selectionFailure = nil;
            overlay->_renderFailure = failure ? [@"銀河を描画できません: " stringByAppendingString:failure] : nil;
            [overlay redrawPublishedScene];
            [overlay startLatest];
        });
    });
}
- (NSString *)status {
    if (_selectionFailure) return _selectionFailure;
    if (_diagnostics.display == GalaxyOverlayDisplay::preview) return @"銀河: 移動中の間引き表示（全件を描画中）";
    return _diagnostics.display == GalaxyOverlayDisplay::complete ? _renderFailure : nil;
}
- (GalaxyOverlayDiagnostics)diagnostics { return _diagnostics; }
- (BOOL)isRecordDisplayed:(GalaxySpatialRecordId)record {
    if (!_model || (_diagnostics.display == GalaxyOverlayDisplay::complete && !_image) || !_diagnostics.displayed || _diagnostics.display == GalaxyOverlayDisplay::none ||
        record.source_index >= _model->sources().size() ||
        _model->family(record.source_index) != record.family ||
        record.ordinal >= _model->source_size(record.source_index) ||
        !_diagnostics.displayed->visibility.visible(record.family)) return NO;
    if (_diagnostics.display == GalaxyOverlayDisplay::preview) {
        const auto sample = previewSample(*_model, record.source_index, _displayedPreviewSelection);
        if (!sample || sample->representative(record.ordinal) != record.ordinal) return NO;
    }
    const auto& request = *_diagnostics.displayed;
    const GalaxyProjector projector(request.camera, request.size.width, request.size.height);
    const auto shape = galaxy_spatial_shape(*_model, record, projector,
        _diagnostics.display == GalaxyOverlayDisplay::preview);
    return shape && shape->intersects_viewport(projector);
}
- (void)pickAtPoint:(NSPoint)point camera:(const GalaxyCameraPc&)camera
         completion:(void (^)(std::optional<GalaxySpatialRecordId>))completion {
    if (!completion) return;
    [self pickSpatialAtPoint:point camera:camera completion:^(GalaxyOverlaySelection selected) { completion(selected.galaxy); }];
}
- (BOOL)isHipDisplayed:(std::size_t)index {
    if (!_hipModel || index >= _hipModel->points.size() || !_diagnostics.displayed ||
        !_diagnostics.displayed->hip_visible ||
        _diagnostics.display == GalaxyOverlayDisplay::none ||
        (_diagnostics.display == GalaxyOverlayDisplay::complete && !_hipImage)) return NO;
    if (_diagnostics.display == GalaxyOverlayDisplay::preview &&
        index % hip_spatial_preview_step(_hipModel->points.size()) != 0) return NO;
    const auto& request = *_diagnostics.displayed;
    const GalaxyProjector projector(request.camera, request.size.width, request.size.height);
    const auto point = projector.project(_hipModel->points[index].position);
    return point && projector.contains(*point);
}
- (std::optional<NativeEclipticPositionPc>)ourGalaxyPointPosition:(OurGalaxyPointId)point {
    if (!_ourGalaxyModel) return std::nullopt;
    if (_diagnostics.display == GalaxyOverlayDisplay::preview) {
        const auto preview = our_galaxy_point_position(*_ourGalaxyModel, point, OurGalaxyPointDisplay::preview, ourSettings.transform);
        if (preview) return preview;
    }
    return our_galaxy_point_position(*_ourGalaxyModel, point, OurGalaxyPointDisplay::complete, ourSettings.transform);
}
- (std::optional<NativeEclipticPositionPc>)displayedOurGalaxyPointPosition:(OurGalaxyPointId)point {
    if (!_ourGalaxyModel || !_diagnostics.displayed || !_diagnostics.displayed->our_galaxy_visible ||
        _diagnostics.display == GalaxyOverlayDisplay::none ||
        (_diagnostics.display == GalaxyOverlayDisplay::complete && !_ourGalaxyImage)) return std::nullopt;
    const auto mode = _diagnostics.display == GalaxyOverlayDisplay::preview
        ? OurGalaxyPointDisplay::preview : OurGalaxyPointDisplay::complete;
    const auto position = our_galaxy_point_position(*_ourGalaxyModel, point, mode, ourSettings.transform);
    if (!position) return std::nullopt;
    const auto& request = *_diagnostics.displayed;
    if (mode == OurGalaxyPointDisplay::preview && our_galaxy_alpha(request.camera) <= 0) return std::nullopt;
    if (!our_galaxy_point_visible(*_ourGalaxyModel, point, ourSettings.transform, mode, request.camera,
                                  request.size.width, request.size.height, _renderedOurGalaxyRadiative.get())) return std::nullopt;
    return position;
}
- (void)pickSpatialAtPoint:(NSPoint)point camera:(const GalaxyCameraPc&)camera
         completion:(void (^)(GalaxyOverlaySelection))completion {
    [self invalidatePendingPicks];
    if (!completion || (!_model && !_hipModel && !_ourGalaxyModel) || !_diagnostics.displayed || !_requested ||
        _diagnostics.display == GalaxyOverlayDisplay::none) return;
    auto request = *_requested;
    request.camera = camera;
    if (!sameRequest(request, *_diagnostics.displayed)) return;
    const auto mode = _diagnostics.display;
    const auto previewSelection = _displayedPreviewSelection;
    const auto model = _model;
    const auto hipModel = _hipModel;
    const auto ourModel = _ourGalaxyModel;
    const auto ourRadiative = _renderedOurGalaxyRadiative;
    const bool galaxyDisplayed = mode == GalaxyOverlayDisplay::preview || _image != nil;
    const bool hipDisplayed = request.hip_visible && (mode == GalaxyOverlayDisplay::preview || _hipImage != nil);
    const bool previewOurVisible = mode == GalaxyOverlayDisplay::preview && ourModel &&
        our_galaxy_alpha(request.camera) > 0;
    const bool ourDisplayed = request.our_galaxy_visible && ourModel &&
        (mode == GalaxyOverlayDisplay::preview ? previewOurVisible : _ourGalaxyMultiplier != nil);
    const bool ourPointsDisplayed = request.our_galaxy_visible && ourModel &&
        (mode == GalaxyOverlayDisplay::preview ? previewOurVisible : _ourGalaxyImage != nil);
    const auto picks = _pickGeneration;
    const auto expected = picks->load(std::memory_order_relaxed);
    const auto generation = _generation;
    const auto expectedGeneration = generation->load(std::memory_order_relaxed);
    NSImage *galaxyImage = _image, *hipImage = _hipImage, *ourImage = _ourGalaxyImage;
    __weak GalaxyOverlay *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        const auto cancelled = [picks, expected] { return picks->load(std::memory_order_relaxed) != expected; };
        GalaxyOverlaySelection selected;
        try {
            const GalaxyProjector projector(request.camera, request.size.width, request.size.height);
            if (model && galaxyDisplayed && mode == GalaxyOverlayDisplay::complete) {
                selected.galaxy = pick_galaxy_spatial_row(*model, projector, request.visibility, point.x, point.y, 8, cancelled);
            } else if (model && galaxyDisplayed && projector.contains({point.x, point.y, 0})) {
                double best = 8, depth = std::numeric_limits<double>::infinity();
                std::optional<GalaxySpatialRecordId> painted;
                double bestX = 0, bestY = 0;
                forPreviewRows(*model, request.visibility, previewSelection, [&](GalaxySpatialRecordId id) {
                    if (cancelled()) return false;
                    const auto shape = galaxy_spatial_shape(*model, id, projector, true, cancelled);
                    if (shape && shape->clipping && shape->clipping->cancelled) return false;
                    if (!shape || !shape->intersects_viewport(projector)) return true;
                    const auto& projected = shape->center;
                    const double distance = std::hypot(projected.x - point.x, projected.y - point.y);
                    if (shape->contains(point.x, point.y))
                        painted = id;
                    if (distance <= best && (!selected.galaxy || distance < best || projected.depth_pc < depth ||
                        (projected.x == bestX && projected.y == bestY))) {
                        selected.galaxy = id; best = distance; depth = projected.depth_pc;
                        bestX = projected.x; bestY = projected.y;
                    }
                    return true;
                });
                if (painted) selected.galaxy = painted;
            }
            const auto galaxyCandidate = selected.galaxy;
            std::optional<HipSpatialPick> hip;
            std::optional<OurGalaxyPointPick> ourCandidate;
            if (hipModel && hipDisplayed) {
                hip = pick_hip_spatial_point(*hipModel, projector, point.x, point.y, 8,
                    mode == GalaxyOverlayDisplay::preview, cancelled);
                if (hip) {
                    bool choose = !selected.galaxy;
                    if (selected.galaxy) {
                        const auto row = model->row(*selected.galaxy);
                        const auto projected = projector.project(*row.position);
                        const double distance = std::hypot(projected->x - point.x, projected->y - point.y);
                        choose = hip->distance_points < distance || (hip->distance_points == distance && hip->depth_pc < projected->depth_pc);
                    }
                    if (choose) { selected.galaxy.reset(); selected.hip = hip->index; }
                }
            }
            if (ourPointsDisplayed && !cancelled()) {
                const auto pointMode = mode == GalaxyOverlayDisplay::preview
                    ? OurGalaxyPointDisplay::preview : OurGalaxyPointDisplay::complete;
                ourCandidate = pick_our_galaxy_point(*ourModel, ourSettings.transform, ourSettings.styles, pointMode,
                    request.camera, request.size.width, request.size.height, point.x, point.y, 8, cancelled,
                    pointMode == OurGalaxyPointDisplay::complete ? ourRadiative.get() : nullptr);
                if (const auto& candidate = ourCandidate) {
                    std::optional<GalaxyProjectionPc> existing;
                    if (selected.galaxy) existing = projector.project(*model->row(*selected.galaxy).position);
                    else if (selected.hip) existing = projector.project(hipModel->points[*selected.hip].position);
                    const double distance = existing ? std::hypot(existing->x - point.x, existing->y - point.y)
                                                     : std::numeric_limits<double>::infinity();
                    if (!existing || candidate->distance_points < distance ||
                        (candidate->distance_points == distance && candidate->depth_pc < existing->depth_pc)) {
                        selected.galaxy.reset(); selected.hip.reset(); selected.our_galaxy_point = candidate->id;
                    }
                }
            }
            // 点が重なる場合は描画された図形を近傍ヒットより優先する。
            // OurGalaxy は加算合成なので、両方が見える場合は後描き群を仮に選ぶ。
            if (galaxyCandidate) {
                const auto shape = galaxy_spatial_shape(*model, *galaxyCandidate, projector,
                                                        mode == GalaxyOverlayDisplay::preview, cancelled);
                if (shape && shape->contains(point.x, point.y)) {
                    selected.hip.reset(); selected.our_galaxy_point.reset(); selected.galaxy = galaxyCandidate;
                }
            }
            if (ourCandidate) {
                const auto projected = projector.project(ourCandidate->position);
                const double radius = ourSettings.styles[static_cast<std::size_t>(ourCandidate->id.group)].radius_points;
                const double dx = projected ? point.x - projected->x : 0;
                const double dy = projected ? point.y - projected->y : 0;
                const bool painted = projected && (mode == GalaxyOverlayDisplay::preview
                    ? std::abs(dx) <= .75 && std::abs(dy) <= .75 : dx * dx + dy * dy <= radius * radius);
                if (painted) {
                    selected.galaxy.reset(); selected.hip.reset(); selected.our_galaxy_point = ourCandidate->id;
                }
            }
            // HIP は最後に SourceOver で描画する。
            if (hip) {
                const auto projected = projector.project(hipModel->points[hip->index].position);
                if (projected && hip_spatial_point_contains(projected->x, projected->y, point.x, point.y,
                                                            mode == GalaxyOverlayDisplay::preview)) {
                    selected.galaxy.reset(); selected.our_galaxy_point.reset(); selected.hip = hip->index;
                }
            }
            if (!selected.galaxy && !selected.hip && !selected.our_galaxy_point && ourDisplayed)
                selected.our_galaxy = hit_our_galaxy({{0,0,0}}, request.camera, point.x, point.y,
                                                      request.size.width, request.size.height);
        } catch (const std::exception& error) {
            NSString *failure = [NSString stringWithUTF8String:error.what()];
            dispatch_async(dispatch_get_main_queue(), ^{
                GalaxyOverlay *overlay = weakSelf;
                if (!overlay || cancelled() || !overlay->_diagnostics.displayed ||
                    overlay->_diagnostics.display != mode ||
                    generation->load(std::memory_order_relaxed) != expectedGeneration ||
                    overlay->_model != model || overlay->_hipModel != hipModel || overlay->_ourGalaxyModel != ourModel ||
                    (mode == GalaxyOverlayDisplay::complete && (overlay->_image != galaxyImage || overlay->_hipImage != hipImage || overlay->_ourGalaxyImage != ourImage)) ||
                    !sameRequest(*overlay->_diagnostics.displayed, request)) return;
                overlay->_selectionFailure = [@"銀河の選択に失敗: " stringByAppendingString:(failure ? failure : @"不明なエラー")];
                [overlay redrawPublishedScene];
                completion({});
            });
            return;
        }
        if (cancelled()) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            GalaxyOverlay *overlay = weakSelf;
            if (!overlay || cancelled() || !overlay->_diagnostics.displayed ||
                overlay->_diagnostics.display != mode ||
                generation->load(std::memory_order_relaxed) != expectedGeneration ||
                overlay->_model != model || overlay->_hipModel != hipModel || overlay->_ourGalaxyModel != ourModel ||
                (mode == GalaxyOverlayDisplay::complete && (overlay->_image != galaxyImage || overlay->_hipImage != hipImage || overlay->_ourGalaxyImage != ourImage)) ||
                !sameRequest(*overlay->_diagnostics.displayed, request)) return;
            completion(selected);
        });
    });
}
- (void)drawInRect:(NSRect)rect camera:(const GalaxyCameraPc&)camera
             quality:(RendererDisplayOptions)quality scale:(double)scale
      selectedRecord:(std::optional<GalaxySpatialRecordId>)selected {
    const GalaxyOverlayRequest next{camera, quality, rect.size, scale, _visibility, static_cast<bool>(_hipVisible), static_cast<bool>(_ourGalaxyVisible)};
    if (!_requested || !sameRequest(*_requested, next)) {
        [self invalidatePendingPicks];
        if (_requested) {
            // 旧視点の重い光線計算を止め、新しい要求を同じ直列キューに載せる。
            _generation->fetch_add(1, std::memory_order_relaxed);
            _running = NO;
        }
    }
    _requested = next;
    _diagnostics = {*_requested, std::nullopt, GalaxyOverlayDisplay::none, 0, 0};
    if (_rendered && sameRequest(*_rendered, *_requested)) {
        [_image drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver
                  fraction:1 respectFlipped:YES hints:nil];
        [_ourGalaxyMultiplier drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationMultiply
                  fraction:1 respectFlipped:YES hints:nil];
        [_ourGalaxyEmission drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationPlusLighter
                  fraction:1 respectFlipped:YES hints:nil];
        [_ourGalaxyImage drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationPlusLighter
                  fraction:1 respectFlipped:YES hints:nil];
        [_hipImage drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver
                  fraction:1 respectFlipped:YES hints:nil];
        _diagnostics.displayed = *_rendered;
        _diagnostics.display = GalaxyOverlayDisplay::complete;
        _diagnostics.displayed_drawn = _renderedDrawn;
        _diagnostics.our_galaxy_drawn = _renderedOurGalaxyDrawn;
        _diagnostics.hip_drawn = _renderedHipDrawn;
    } else if (_model || _ourGalaxyModel || _hipModel) {
        // 完成画像が古い視点を指す間は、現在のカメラで間引いた位置を即時投影する。
        // 完成画像をそのまま残すと移動中の天体位置が実際の視点と一致しない。
        const GalaxyProjector projector(camera, rect.size.width, rect.size.height);
        std::array<GalaxyPointColor, 8> cachedPointColors{};
        __strong NSColor *cachedNativeColors[8] = {};
        std::size_t cachedColorCount = 0;
        _displayedPreviewSelection.reset();
        if (_model && selected && selected->source_index < _model->sources().size() &&
            _model->family(selected->source_index) == selected->family && _visibility.visible(selected->family) &&
            selected->ordinal < _model->source_size(selected->source_index)) {
            const auto shape = galaxy_spatial_shape(*_model, *selected, projector, true);
            if (shape && shape->intersects_viewport(projector)) _displayedPreviewSelection = selected;
        }
        if (_model) forPreviewRows(*_model, _visibility, _displayedPreviewSelection, [&](GalaxySpatialRecordId id) {
            ++_diagnostics.preview_rows;
            const auto shape = galaxy_spatial_shape(*_model, id, projector, true);
            if (shape && shape->intersects_viewport(projector)) {
                const auto color = galaxy_point_color(*_model, id);
                std::size_t index = 0;
                while (index < cachedColorCount && (cachedPointColors[index].red != color.red ||
                       cachedPointColors[index].green != color.green || cachedPointColors[index].blue != color.blue)) ++index;
                if (index == cachedColorCount && index < cachedPointColors.size()) {
                    cachedPointColors[index] = color;
                    cachedNativeColors[index] = [NSColor colorWithDeviceRed:color.red green:color.green blue:color.blue alpha:1];
                    ++cachedColorCount;
                }
                NSColor *nativeColor = index < cachedColorCount ? cachedNativeColors[index]
                    : [NSColor colorWithDeviceRed:color.red green:color.green blue:color.blue alpha:1];
                [nativeColor setFill];
                if (shape->preview_rectangle) {
                    NSRectFill(NSMakeRect(rect.origin.x + shape->center.x, rect.origin.y + shape->center.y,
                                          galaxy_spatial_preview_size, galaxy_spatial_preview_size));
                } else {
                    const double radius = shape->radius;
                    if (shape->clipping) {
                        NSBezierPath *path = [NSBezierPath bezierPath];
                        for (const auto& part : shape->clipping->rectangles)
                            [path appendBezierPathWithRect:NSMakeRect(rect.origin.x + part.x,
                                rect.origin.y + part.y, part.width, part.height)];
                        [path fill];
                    } else {
                        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(
                            rect.origin.x + shape->center.x - radius, rect.origin.y + shape->center.y - radius,
                            2 * radius, 2 * radius)] fill];
                    }
                }
                ++_diagnostics.displayed_drawn;
            }
            return true;
        });
        const float previewOurAlpha = _ourGalaxyModel && _ourGalaxyVisible ? our_galaxy_alpha(camera) : 0;
        if (previewOurAlpha > 0) {
            [NSGraphicsContext saveGraphicsState];
            // フェード直後の暗い点が画面端で量子化により消えないよう、プレビューだけ平滑化しない。
            [[NSGraphicsContext currentContext] setShouldAntialias:NO];
            for (std::size_t group = 0; group < _ourGalaxyModel->groups.size(); ++group) {
                const auto& positions = _ourGalaxyModel->groups[group].positions;
                const auto& style = ourSettings.styles[group];
                [[NSColor colorWithSRGBRed:style.red green:style.green blue:style.blue alpha:style.alpha * previewOurAlpha] setFill];
                const auto step = our_galaxy_preview_step(positions.size());
                for (std::size_t index = 0; index < positions.size(); index += step) {
                    const auto& raw = positions[index];
                    const auto valid = [](double value) {
                        return std::isfinite(value) && std::abs(value) <= maximum_galaxy_coordinate_pc;
                    };
                    if (!valid(raw.x_pc) || !valid(raw.y_pc) || !valid(raw.z_pc)) continue;
                    const auto point = projector.project({raw.x_pc, raw.y_pc, raw.z_pc});
                    if (point && projector.contains(*point)) {
                        NSRectFillUsingOperation(NSMakeRect(rect.origin.x + point->x - .75, rect.origin.y + point->y - .75, 1.5, 1.5),
                                                 NSCompositingOperationPlusLighter);
                        ++_diagnostics.our_galaxy_drawn;
                    }
                }
            }
            [NSGraphicsContext restoreGraphicsState];
        }
        if (_hipModel && _hipVisible) {
            [[NSColor colorWithSRGBRed:1 green:1 blue:1 alpha:.8] setFill];
            const auto& points = _hipModel->points;
            const auto step = hip_spatial_preview_step(points.size());
            for (std::size_t index = 0; index < points.size(); index += step) {
                const auto point = projector.project(points[index].position);
                if (point && projector.contains(*point)) {
                    NSRectFillUsingOperation(NSMakeRect(rect.origin.x + point->x, rect.origin.y + point->y,
                                                               hip_spatial_preview_size, hip_spatial_preview_size),
                                             NSCompositingOperationSourceOver);
                    ++_diagnostics.hip_drawn;
                }
            }
        }
        _diagnostics.displayed = *_requested;
        _diagnostics.display = GalaxyOverlayDisplay::preview;
    }
    [self startLatest];
}
@end
