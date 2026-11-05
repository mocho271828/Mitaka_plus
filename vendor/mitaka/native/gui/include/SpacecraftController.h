#import <AppKit/AppKit.h>
#include "spacecraft_browser_model.hpp"

@interface SpacecraftController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
@property(nonatomic, copy) void (^chooseObject)(NSUInteger index, BOOL center);
- (void)setModel:(std::shared_ptr<const mitaka::gui::SpacecraftBrowserModel>)model
        snapshot:(std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>)snapshot;
- (void)setSnapshot:(std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>)snapshot;
// prepare と commit の間はブラウザの model を変更しない。
- (std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>)prepareSnapshot:(std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>)snapshot;
- (void)commitPreparedDate:(std::shared_ptr<const mitaka::gui::SpacecraftSnapshot>&&)snapshot;
- (void)finishDateUpdate;
@end
