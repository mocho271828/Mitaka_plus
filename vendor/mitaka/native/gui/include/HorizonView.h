#import <AppKit/AppKit.h>
#include "sky_model.hpp"
#include "small_body_model.hpp"
#include "small_body_display.hpp"
#include "SpacecraftRenderer.h"
#include "display_options.hpp"
#include "radius_display.hpp"
#include "constellation_display.hpp"
#include "renderer_options.hpp"
#include "horizon_viewport.hpp"
#include "sky_background.hpp"
#include "extended_catalogs.hpp"
#include "constellation_art_model.hpp"
#include "earth_landscapes.hpp"
#include <set>
#include "mitaka/observation.hpp"
#include "GridRenderer.h"
#include "horizon_objects.hpp"
#include <memory>

namespace mitaka::gui {
// 準備から公開までは地平図の地点・表示設定を変更しない。
struct HorizonPreparedDate {
    SkyBodies bodies;
    GridGeometryCache grid;
    std::optional<ObservationFrame> frame;
    Vec3 earthPosition;
    double julianDate;
    std::shared_ptr<const SmallBodySnapshot> smallBodies;
    std::shared_ptr<const SmallBodyDisplayModel> smallBodyDisplay;
    std::shared_ptr<const SpacecraftSnapshot> spacecraft;
    std::vector<HorizonObject> smallBodyObjects, spacecraftObjects;
    bool clearSmallBodySelection, clearSpacecraftSelection;
};
}

@interface HorizonView : NSView
@property(nonatomic) mitaka::gui::ConstellationDisplayOptions constellationDisplayOptions;
@property(nonatomic) mitaka::gui::PlanetDisplayOptions planetDisplayOptions;
@property(nonatomic) mitaka::gui::RadiusDisplayOptions radiusDisplayOptions;
@property(nonatomic) mitaka::gui::RendererDisplayOptions rendererDisplayOptions;
@property(nonatomic) mitaka::gui::GridDisplayOptions gridDisplayOptions;
@property(nonatomic) mitaka::gui::MilkyWayMode milkyWayMode;
- (void)setSkyBackgrounds:(std::shared_ptr<const mitaka::gui::SkyBackgrounds>)backgrounds;
- (void)setObservationSite:(mitaka::ObserverSite)site julianDate:(double)julianDate;
@property(nonatomic) mitaka::gui::StarDisplayOptions starDisplayOptions;
@property(nonatomic, copy) void (^selectionChanged)(NSString *description);
@property(nonatomic, copy) void (^viewportChanged)(void);
@property(nonatomic, copy) void (^userViewportChange)(void);
@property(nonatomic) double magnitudeLimit;
@property(nonatomic) BOOL showsTimeInfo;
@property(nonatomic) BOOL showsLandscapeImage;
- (void)setEarthLandscapes:(std::shared_ptr<const mitaka::gui::EarthLandscapes>)landscapes;
- (void)setObserverPlaceIdentifier:(const std::string&)identifier;
- (const std::string&)observerPlaceIdentifier;
@property(nonatomic, readonly) NSUInteger visibleStarCount;
@property(nonatomic, readonly) NSUInteger selectedBodyIndex;
@property(nonatomic, readonly) NSUInteger selectedSmallBodyIndex;
@property(nonatomic, readonly) NSUInteger selectedSpacecraftIndex;
@property(nonatomic) BOOL smallBodiesVisible;
@property(nonatomic) BOOL spacecraftVisible;
@property(nonatomic) mitaka::gui::SpacecraftDisplayOptions spacecraftDisplayOptions;
- (void)setSmallBodySnapshot:(std::shared_ptr<const mitaka::gui::SmallBodySnapshot>)snapshot;
- (void)setSmallBodyDisplayModel:(std::shared_ptr<const mitaka::gui::SmallBodyDisplayModel>)display;
- (void)setSpacecraftSnapshot:(std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>)snapshot;
- (BOOL)selectSmallBody:(NSUInteger)index;
- (BOOL)selectSpacecraft:(NSUInteger)index;
@property(nonatomic, readonly) double julianDate;
- (void)setModel:(std::shared_ptr<const mitaka::gui::SkyModel>)model
         bodies:(const mitaka::gui::SkyBodies&)bodies;
- (void)setExtendedCatalogs:(std::shared_ptr<const mitaka::gui::ExtendedCatalogs>)catalogs;
- (void)setConstellationArt:(std::shared_ptr<const mitaka::gui::ConstellationArtModel>)art;
- (void)setSelectedStarNameHIPs:(const std::set<std::int32_t>&)hips;
- (void)setBodies:(const mitaka::gui::SkyBodies&)bodies julianDate:(double)julianDate;
- (void)setBodies:(const mitaka::gui::SkyBodies&)bodies julianDate:(double)julianDate earthPosition:(mitaka::Vec3)earthPosition;
- (void)setBodies:(const mitaka::gui::SkyBodies&)bodies julianDate:(double)julianDate
    earthPosition:(mitaka::Vec3)earthPosition
    smallBodies:(std::shared_ptr<const mitaka::gui::SmallBodySnapshot>)smallBodies
    smallBodyDisplay:(std::shared_ptr<const mitaka::gui::SmallBodyDisplayModel>)display
    spacecraft:(std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>)spacecraft;
- (mitaka::gui::HorizonPreparedDate)prepareBodies:(const mitaka::gui::SkyBodies&)bodies julianDate:(double)julianDate
    earthPosition:(mitaka::Vec3)earthPosition
    smallBodies:(std::shared_ptr<const mitaka::gui::SmallBodySnapshot>)smallBodies
    smallBodyDisplay:(std::shared_ptr<const mitaka::gui::SmallBodyDisplayModel>)display
    spacecraft:(std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>)spacecraft;
- (void)commitPreparedDate:(mitaka::gui::HorizonPreparedDate&&)prepared;
- (void)finishDateUpdate;
- (mitaka::ObserverSite)observerSite;
- (void)setObserverSite:(mitaka::ObserverSite)site;
- (mitaka::gui::HorizonViewport)viewport;
- (void)setViewport:(mitaka::gui::HorizonViewport)viewport;
- (double)verticalFovDegrees;
- (BOOL)setVerticalFovDegrees:(double)degrees;
- (void)selectBody:(NSUInteger)index;
- (void)clearSelection;
- (BOOL)selectStarHIP:(int32_t)hip;
- (BOOL)lookAtBody:(mitaka::gui::Body)body;
- (BOOL)lookAtStarHIP:(int32_t)hip;
- (BOOL)viewportForBody:(mitaka::gui::Body)body result:(mitaka::gui::HorizonViewport *)result;
- (BOOL)viewportForStarHIP:(int32_t)hip result:(mitaka::gui::HorizonViewport *)result;
- (BOOL)viewportForHeliocentricPosition:(mitaka::Vec3)position julianDate:(double)julianDate
                                  result:(mitaka::gui::HorizonViewport *)result;
- (void)focusSelection;
- (void)resetView;
- (void)zoomIn;
- (void)zoomOut;
@end
