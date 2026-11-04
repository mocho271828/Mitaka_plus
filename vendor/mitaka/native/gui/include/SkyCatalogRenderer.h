#import <AppKit/AppKit.h>

#include "extended_catalogs.hpp"
#include "sky_catalog_index.hpp"
#include "renderer_options.hpp"

struct SkyCatalogDisplay {
    bool nebulae = false, galaxies = false, quasars = false;
};

@interface SkyCatalogRenderer : NSObject
- (instancetype)initWithModel:(std::shared_ptr<const mitaka::gui::SkyModel>)model
                      catalogs:(std::shared_ptr<const mitaka::gui::ExtendedCatalogs>)catalogs;
- (void)drawInRect:(NSRect)map viewport:(mitaka::gui::SkyViewport)viewport
    magnitudeLimit:(double)magnitudeLimit options:(SkyCatalogDisplay)options
    quality:(mitaka::gui::RendererDisplayOptions)quality;
@end
