#import <AppKit/AppKit.h>
#include "satellite_browser_model.hpp"
#include "satellite_display.hpp"
#include "satellite_orbit_geometry.hpp"

namespace mitaka::gui {
struct SatellitePreparedDate {
    std::shared_ptr<const SatelliteSnapshot> snapshot;
    std::shared_ptr<const SatelliteDisplayModel> display;
    std::shared_ptr<const SatelliteOrbitGeometry> orbits;
};
}

@interface SatelliteController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
@property(nonatomic, copy) void (^chooseObject)(NSUInteger index, BOOL center);
@property(nonatomic, copy) void (^changeDisplayOptions)(mitaka::gui::SatelliteDisplayOptions options);
@property(nonatomic, copy) void (^changeDisplaySelection)(const std::vector<mitaka::SatelliteRecordId>& ids);
- (void)setDisplayModel:(std::shared_ptr<const mitaka::gui::SatelliteDisplayModel>)display;
- (void)setOrbitGeometry:(std::shared_ptr<const mitaka::gui::SatelliteOrbitGeometry>)geometry;
- (void)setModel:(std::shared_ptr<const mitaka::gui::SatelliteBrowserModel>)model
        snapshot:(std::shared_ptr<const mitaka::gui::SatelliteSnapshot>)snapshot;
- (void)setSnapshot:(std::shared_ptr<const mitaka::gui::SatelliteSnapshot>)snapshot;
// prepare と commit の間はブラウザの model を変更しない。
- (mitaka::gui::SatellitePreparedDate)prepareSnapshot:(std::shared_ptr<const mitaka::gui::SatelliteSnapshot>)snapshot
    display:(std::shared_ptr<const mitaka::gui::SatelliteDisplayModel>)display
    orbitGeometry:(std::shared_ptr<const mitaka::gui::SatelliteOrbitGeometry>)geometry;
- (void)commitPreparedDate:(mitaka::gui::SatellitePreparedDate&&)prepared;
- (void)finishDateUpdate;
@end
