#import <AppKit/AppKit.h>
#include "satellite_browser_model.hpp"
#include "satellite_display.hpp"
#include "satellite_orbit_geometry.hpp"

@interface SatelliteController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
@property(nonatomic, copy) void (^chooseObject)(NSUInteger index, BOOL center);
@property(nonatomic, copy) void (^changeDisplayOptions)(mitaka::gui::SatelliteDisplayOptions options);
@property(nonatomic, copy) void (^changeDisplaySelection)(const std::vector<mitaka::SatelliteRecordId>& ids);
- (void)setDisplayModel:(std::shared_ptr<const mitaka::gui::SatelliteDisplayModel>)display;
- (void)setOrbitGeometry:(std::shared_ptr<const mitaka::gui::SatelliteOrbitGeometry>)geometry;
- (void)setModel:(std::shared_ptr<const mitaka::gui::SatelliteBrowserModel>)model
        snapshot:(std::shared_ptr<const mitaka::gui::SatelliteSnapshot>)snapshot;
- (void)setSnapshot:(std::shared_ptr<const mitaka::gui::SatelliteSnapshot>)snapshot;
@end
