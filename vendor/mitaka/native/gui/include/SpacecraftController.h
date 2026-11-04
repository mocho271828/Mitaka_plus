#import <AppKit/AppKit.h>
#include "spacecraft_browser_model.hpp"

@interface SpacecraftController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
@property(nonatomic, copy) void (^chooseObject)(NSUInteger index, BOOL center);
- (void)setModel:(std::shared_ptr<const mitaka::gui::SpacecraftBrowserModel>)model
        snapshot:(std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>)snapshot;
- (void)setSnapshot:(std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>)snapshot;
@end
