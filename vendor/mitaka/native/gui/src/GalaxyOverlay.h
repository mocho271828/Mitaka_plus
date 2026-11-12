#pragma once
#import <AppKit/AppKit.h>
#include "OurGalaxyRenderer.h"
#include "HipSpatialRenderer.h"

namespace mitaka::gui {
struct GalaxyOverlayRequest {
    GalaxyCameraPc camera;
    RendererDisplayOptions quality;
    NSSize size;
    double scale;
    GalaxySpatialVisibility visibility;
    bool hip_visible;
    bool our_galaxy_visible;
};
enum class GalaxyOverlayDisplay { none, preview, complete };
struct GalaxyOverlayDiagnostics {
    std::optional<GalaxyOverlayRequest> requested;
    std::optional<GalaxyOverlayRequest> displayed;
    GalaxyOverlayDisplay display = GalaxyOverlayDisplay::none;
    std::size_t preview_rows = 0;
    std::size_t displayed_drawn = 0;
    std::size_t our_galaxy_drawn = 0;
    std::size_t hip_drawn = 0;
};
struct GalaxyOverlaySelection {
    std::optional<GalaxySpatialRecordId> galaxy;
    std::optional<std::size_t> hip;
    bool our_galaxy = false;
    std::optional<OurGalaxyPointId> our_galaxy_point;
};
}

// SolarSystemView と同じ矩形へ非同期で銀河を重ねる。
@interface GalaxyOverlay : NSObject
- (instancetype)initWithView:(NSView *)view;
@property(nonatomic, readonly) NSString *status;
// 前回の drawInRect で実際に表示した要求を返す。メインスレッド専用。
- (mitaka::gui::GalaxyOverlayDiagnostics)diagnostics;
- (std::shared_ptr<const mitaka::gui::GalaxySpatialModel>)model;
- (void)invalidatePendingPicks;
- (void)setVisibility:(mitaka::gui::GalaxySpatialVisibility)visibility;
- (void)setHipVisible:(BOOL)visible;
- (void)setOurGalaxyVisible:(BOOL)visible;
- (BOOL)isOurGalaxyVisible;
// 前回描画の可視性・抽出条件・投影を満たす行か照会する。
- (BOOL)isRecordDisplayed:(mitaka::gui::GalaxySpatialRecordId)record;
- (BOOL)isHipDisplayed:(std::size_t)index;
- (std::optional<mitaka::gui::NativeEclipticPositionPc>)ourGalaxyPointPosition:(mitaka::gui::OurGalaxyPointId)point;
- (std::optional<mitaka::gui::NativeEclipticPositionPc>)displayedOurGalaxyPointPosition:(mitaka::gui::OurGalaxyPointId)point;
// point は drawInRect の矩形左上からの座標。要求や表示モードが変われば結果を破棄する。
- (void)pickAtPoint:(NSPoint)point camera:(const mitaka::gui::GalaxyCameraPc&)camera
         completion:(void (^)(std::optional<mitaka::gui::GalaxySpatialRecordId>))completion;
- (void)pickSpatialAtPoint:(NSPoint)point camera:(const mitaka::gui::GalaxyCameraPc&)camera
         completion:(void (^)(mitaka::gui::GalaxyOverlaySelection))completion;
- (std::shared_ptr<const mitaka::OurGalaxyModel>)ourGalaxyModel;
- (std::shared_ptr<const mitaka::gui::HipSpatialModel>)hipModel;
- (void)setHipModel:(std::shared_ptr<const mitaka::gui::HipSpatialModel>)model;
- (void)setOurGalaxyModel:(std::shared_ptr<const mitaka::OurGalaxyModel>)model;
- (void)setModel:(std::shared_ptr<const mitaka::gui::GalaxySpatialModel>)model;
- (void)drawInRect:(NSRect)rect camera:(const mitaka::gui::GalaxyCameraPc&)camera
             quality:(mitaka::gui::RendererDisplayOptions)quality scale:(double)scale
      selectedRecord:(std::optional<mitaka::gui::GalaxySpatialRecordId>)selected surfaceView:(BOOL)surfaceView;
@end
