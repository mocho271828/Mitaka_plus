#import <AppKit/AppKit.h>
#include "sky_model.hpp"
#include "display_options.hpp"
#include "constellation_display.hpp"
#include "renderer_options.hpp"
#include "mitaka/observation.hpp"
#include "extended_catalogs.hpp"
#include "sky_catalog_index.hpp"
#include "sky_background.hpp"
#include "constellation_art_model.hpp"
#include <set>
#include <memory>

NSString *bodyName(mitaka::gui::Body body);

@interface SkyView : NSView
@property(nonatomic) mitaka::gui::ConstellationDisplayOptions constellationDisplayOptions;
@property(nonatomic) mitaka::gui::PlanetDisplayOptions planetDisplayOptions;
@property(nonatomic) mitaka::gui::RendererDisplayOptions rendererDisplayOptions;
@property(nonatomic) mitaka::gui::GridDisplayOptions gridDisplayOptions;
- (void)setObservationSite:(mitaka::ObserverSite)site julianDate:(double)julianDate;
@property(nonatomic) mitaka::gui::StarDisplayOptions starDisplayOptions;
@property(nonatomic, copy) void (^selectionChanged)(NSString *description);
@property(nonatomic, copy) void (^viewportChanged)(void);
@property(nonatomic) double magnitudeLimit;
@property(nonatomic) BOOL showsConstellationLines;
@property(nonatomic) BOOL showsConstellationBoundaries;
@property(nonatomic) BOOL showsConstellationNames;
@property(nonatomic) BOOL showsNebulae;
@property(nonatomic) BOOL showsGalaxies;
@property(nonatomic) BOOL showsQuasars;
@property(nonatomic) mitaka::gui::MilkyWayMode milkyWayMode;
@property(nonatomic, readonly) NSUInteger visibleStarCount;
@property(nonatomic, readonly) NSUInteger selectedBodyIndex;
- (void)setModel:(std::shared_ptr<const mitaka::gui::SkyModel>)model
         bodies:(const mitaka::gui::SkyBodies&)bodies;
- (void)setBodies:(const mitaka::gui::SkyBodies&)bodies;
- (void)setExtendedCatalogs:(std::shared_ptr<const mitaka::gui::ExtendedCatalogs>)catalogs;
- (void)setSkyBackgrounds:(std::shared_ptr<const mitaka::gui::SkyBackgrounds>)backgrounds;
- (void)setConstellationArt:(std::shared_ptr<const mitaka::gui::ConstellationArtModel>)art;
- (void)setSelectedStarNameHIPs:(const std::set<std::int32_t>&)hips;
- (void)selectBody:(NSUInteger)index;
- (void)clearSelection;
// 見つかった恒星は等級上限も広げて選択する。未知のHIPでは状態を変更しない。
- (BOOL)selectStarHIP:(int32_t)hip;
- (BOOL)selectDeepSkyKind:(mitaka::gui::SkyCatalogKind)kind index:(NSUInteger)index;
- (mitaka::gui::SkyViewport)viewport;
- (void)setViewport:(mitaka::gui::SkyViewport)viewport;
- (void)resetView;
- (void)zoomIn;
- (void)zoomOut;
- (void)focusSelection;
@end
