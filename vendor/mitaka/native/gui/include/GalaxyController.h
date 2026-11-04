#pragma once
#import "GalaxyView.h"

// data root の読込は呼出し側が行う。ここでは元データへ書き込まない。
@interface GalaxyController : NSWindowController <NSWindowDelegate>
- (void)setModel:(std::shared_ptr<const mitaka::gui::GalaxySpatialModel>)model diagnostics:(NSString *)diagnostics;
- (GalaxyView *)galaxyView;
- (void)setRendererDisplayOptions:(mitaka::gui::RendererDisplayOptions)options;
- (void)invalidate;
@end
