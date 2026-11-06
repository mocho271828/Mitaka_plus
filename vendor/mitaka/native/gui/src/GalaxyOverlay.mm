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
template<class F> void forPreviewRows(const GalaxySpatialModel& model, GalaxySpatialVisibility visibility, F visit) {
    const auto sources = model.sources().size();
    if (!sources) return;
    for (std::size_t source = 0; source < sources; ++source) {
        if (!visibility.visible(model.family(source))) continue;
        const auto quota = 6000 / sources + (source < 6000 % sources ? 1 : 0);
        if (!quota) continue;
        const auto count = model.source_size(source);
        const auto step = std::max<std::size_t>(1, count / quota + (count % quota != 0));
        for (std::size_t ordinal = 0; ordinal < count; ordinal += step)
            if (!visit(GalaxySpatialRecordId{model.family(source), source, ordinal})) return;
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
    BOOL _running;
    NSImage *_image;
    NSImage *_ourGalaxyImage;
    NSImage *_ourGalaxyMultiplier;
    NSImage *_ourGalaxyEmission;
    NSImage *_hipImage;
    std::size_t _renderedHipDrawn;
    std::size_t _renderedOurGalaxyDrawn;
    std::size_t _renderedDrawn;
    NSString *_status;
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
- (void)invalidatePendingPicks { _pickGeneration->fetch_add(1, std::memory_order_relaxed); }
- (std::shared_ptr<const GalaxySpatialModel>)model { return _model; }
- (std::shared_ptr<const mitaka::OurGalaxyModel>)ourGalaxyModel { return _ourGalaxyModel; }
- (std::shared_ptr<const HipSpatialModel>)hipModel { return _hipModel; }
- (BOOL)isOurGalaxyVisible { return _ourGalaxyVisible; }
- (void)setHipModel:(std::shared_ptr<const HipSpatialModel>)model {
    if (_hipModel == model) return;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _hipModel = std::move(model); _requested.reset(); _rendered.reset();
    _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _status = nil; _running = NO;
    _diagnostics = {}; _view.needsDisplay = YES;
}
- (void)setOurGalaxyModel:(std::shared_ptr<const mitaka::OurGalaxyModel>)model {
    if (_ourGalaxyModel == model) return;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _ourGalaxyModel = std::move(model); _renderedOurGalaxyRadiative.reset(); _requested.reset(); _rendered.reset();
    _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _status = nil; _running = NO;
    _diagnostics = {}; _view.needsDisplay = YES;
}
- (void)setVisibility:(GalaxySpatialVisibility)visibility {
    if (_visibility.sdss_galaxies == visibility.sdss_galaxies && _visibility.sdss_quasars == visibility.sdss_quasars &&
        _visibility.globular_clusters == visibility.globular_clusters && _visibility.nearby_galaxies == visibility.nearby_galaxies) return;
    _visibility = visibility;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _requested.reset(); _rendered.reset(); _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _status = nil; _running = NO;
    _diagnostics = {};
    _view.needsDisplay = YES;
}
- (void)setHipVisible:(BOOL)visible {
    if (_hipVisible == visible) return;
    _hipVisible = visible;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _requested.reset(); _rendered.reset(); _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _status = nil; _running = NO;
    _diagnostics = {}; _view.needsDisplay = YES;
}
- (void)setOurGalaxyVisible:(BOOL)visible {
    if (_ourGalaxyVisible == visible) return;
    _ourGalaxyVisible = visible;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _requested.reset(); _rendered.reset(); _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _status = nil; _running = NO;
    _diagnostics = {}; _view.needsDisplay = YES;
}
- (void)setModel:(std::shared_ptr<const GalaxySpatialModel>)model {
    if (_model == model) return;
    _generation->fetch_add(1, std::memory_order_relaxed);
    [self invalidatePendingPicks];
    _model = std::move(model); _requested.reset(); _rendered.reset(); _image = nil; _ourGalaxyImage = nil; _ourGalaxyMultiplier = nil; _ourGalaxyEmission = nil; _hipImage = nil; _status = nil; _running = NO;
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
                radiativeImages = render_our_galaxy_radiative(*radiative, request.camera,
                    request.size.width, request.size.height, cancelled);
                if (radiativeImages && !cancelled() && radiativeImages->alpha() > 0)
                    ourBitmap = render_our_galaxy_points(*ourModel, ourSettings, request.camera, request.quality,
                        request.size.width, request.size.height, request.scale, cancelled, radiative.get(), radiativeImages->alpha());
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
            overlay->_status = failure ? [@"銀河を描画できません: " stringByAppendingString:failure] : nil;
            [overlay redrawPublishedScene];
            [overlay startLatest];
        });
    });
}
- (NSString *)status { return _status; }
- (GalaxyOverlayDiagnostics)diagnostics { return _diagnostics; }
- (BOOL)isRecordDisplayed:(GalaxySpatialRecordId)record {
    if (!_model || (_diagnostics.display == GalaxyOverlayDisplay::complete && !_image) || !_diagnostics.displayed || _diagnostics.display == GalaxyOverlayDisplay::none ||
        record.source_index >= _model->sources().size() ||
        _model->family(record.source_index) != record.family ||
        record.ordinal >= _model->source_size(record.source_index) ||
        !_diagnostics.displayed->visibility.visible(record.family)) return NO;
    if (_diagnostics.display == GalaxyOverlayDisplay::preview) {
        const auto sources = _model->sources().size();
        const auto quota = 6000 / sources + (record.source_index < 6000 % sources ? 1 : 0);
        if (!quota) return NO;
        const auto count = _model->source_size(record.source_index);
        const auto step = std::max<std::size_t>(1, count / quota + (count % quota != 0));
        if (record.ordinal % step) return NO;
    }
    const auto row = _model->row(record);
    if (!row.position) return NO;
    const auto& request = *_diagnostics.displayed;
    const GalaxyProjector projector(request.camera, request.size.width, request.size.height);
    const auto point = projector.project(*row.position);
    return point && projector.contains(*point);
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
    const auto model = _model;
    const auto hipModel = _hipModel;
    const auto ourModel = _ourGalaxyModel;
    const auto ourRadiative = _renderedOurGalaxyRadiative;
    const bool galaxyDisplayed = mode == GalaxyOverlayDisplay::preview || _image != nil;
    const bool hipDisplayed = request.hip_visible && (mode == GalaxyOverlayDisplay::preview || _hipImage != nil);
    const bool ourDisplayed = request.our_galaxy_visible && ourModel && (mode == GalaxyOverlayDisplay::preview || _ourGalaxyMultiplier != nil);
    const bool ourPointsDisplayed = request.our_galaxy_visible && ourModel && (mode == GalaxyOverlayDisplay::preview || _ourGalaxyImage != nil);
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
                forPreviewRows(*model, request.visibility, [&](GalaxySpatialRecordId id) {
                    if (cancelled()) return false;
                    const auto row = model->row(id);
                    if (!row.position) return true;
                    const auto projected = projector.project(*row.position);
                    if (!projected || !projector.contains(*projected)) return true;
                    const double distance = std::hypot(projected->x - point.x, projected->y - point.y);
                    if (distance <= best && (!selected.galaxy || distance < best || projected->depth_pc < depth)) {
                        selected.galaxy = id; best = distance; depth = projected->depth_pc;
                    }
                    return true;
                });
            }
            if (hipModel && hipDisplayed) {
                const auto hip = pick_hip_spatial_point(*hipModel, projector, point.x, point.y, 8,
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
                const auto candidate = pick_our_galaxy_point(*ourModel, ourSettings.transform, pointMode,
                    request.camera, request.size.width, request.size.height, point.x, point.y, 8, cancelled,
                    pointMode == OurGalaxyPointDisplay::complete ? ourRadiative.get() : nullptr);
                if (candidate) {
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
                overlay->_status = [@"銀河の選択に失敗: " stringByAppendingString:(failure ? failure : @"不明なエラー")];
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
             quality:(RendererDisplayOptions)quality scale:(double)scale {
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
        if (_ourGalaxyModel && _ourGalaxyVisible) {
            for (std::size_t group = 0; group < _ourGalaxyModel->groups.size(); ++group) {
                const auto& positions = _ourGalaxyModel->groups[group].positions;
                const auto& style = ourSettings.styles[group];
                [[NSColor colorWithSRGBRed:style.red green:style.green blue:style.blue alpha:style.alpha] setFill];
                const auto step = our_galaxy_preview_step(positions.size());
                for (std::size_t index = 0; index < positions.size(); index += step) {
                    const auto& raw = positions[index];
                    const auto valid = [](double value) {
                        return std::isfinite(value) && std::abs(value) <= maximum_galaxy_coordinate_pc;
                    };
                    if (!valid(raw.x_pc) || !valid(raw.y_pc) || !valid(raw.z_pc)) continue;
                    const auto point = projector.project({raw.x_pc, raw.y_pc, raw.z_pc});
                    if (point && projector.contains(*point)) {
                        NSRectFill(NSMakeRect(rect.origin.x + point->x, rect.origin.y + point->y, 1.5, 1.5));
                        ++_diagnostics.our_galaxy_drawn;
                    }
                }
            }
        }
        if (_hipModel && _hipVisible) {
            [[NSColor colorWithSRGBRed:1 green:1 blue:1 alpha:.8] setFill];
            const auto& points = _hipModel->points;
            const auto step = hip_spatial_preview_step(points.size());
            for (std::size_t index = 0; index < points.size(); index += step) {
                const auto point = projector.project(points[index].position);
                if (point && projector.contains(*point)) {
                    NSRectFill(NSMakeRect(rect.origin.x + point->x, rect.origin.y + point->y, 1.5, 1.5));
                    ++_diagnostics.hip_drawn;
                }
            }
        }
        std::array<GalaxyPointColor, 8> cachedPointColors{};
        __strong NSColor *cachedNativeColors[8] = {};
        std::size_t cachedColorCount = 0;
        if (_model) forPreviewRows(*_model, _visibility, [&](GalaxySpatialRecordId id) {
            ++_diagnostics.preview_rows;
            const auto row = _model->row(id);
            if (!row.position) return true;
            const auto point = projector.project(*row.position);
            if (point && projector.contains(*point)) {
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
                NSRectFill(NSMakeRect(rect.origin.x + point->x, rect.origin.y + point->y, 1.5, 1.5));
                ++_diagnostics.displayed_drawn;
            }
            return true;
        });
        if (!_status) _status = @"銀河: 移動中の間引き表示（全件を描画中）";
        _diagnostics.displayed = *_requested;
        _diagnostics.display = GalaxyOverlayDisplay::preview;
    }
    [self startLatest];
}
@end
