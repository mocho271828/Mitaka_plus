#import <AppKit/AppKit.h>
#include "small_body_model.hpp"
#include "small_body_display.hpp"
#include "mitaka/small_body_orbit_path.hpp"

@interface SmallBodyController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
@property(nonatomic, copy) void (^chooseObject)(NSUInteger index, BOOL center);
@property(nonatomic, copy) void (^optionsChanged)(mitaka::SmallBodyKind kind, mitaka::gui::SmallBodyKindDisplayOptions options);
@property(nonatomic, copy) void (^displayIdsChanged)(const std::vector<mitaka::SmallBodyId>& ids);
@property(nonatomic, copy) void (^orbitSamplingChanged)(mitaka::SmallBodyOrbitSampling sampling);
- (void)setDisplayModel:(std::shared_ptr<const mitaka::gui::SmallBodyDisplayModel>)display;
- (void)setOrbitSampling:(mitaka::SmallBodyOrbitSampling)sampling;
- (void)setOrbitStatus:(NSString *)status;
- (void)setModel:(std::shared_ptr<const mitaka::gui::SmallBodyModel>)model
        snapshot:(std::shared_ptr<const mitaka::gui::SmallBodySnapshot>)snapshot;
- (void)setSnapshot:(std::shared_ptr<const mitaka::gui::SmallBodySnapshot>)snapshot;
@end
