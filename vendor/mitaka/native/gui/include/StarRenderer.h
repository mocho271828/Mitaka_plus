#pragma once
#import <AppKit/AppKit.h>
#include "sky_model.hpp"
#include "extended_catalogs.hpp"
#include "display_options.hpp"
#include "renderer_options.hpp"
#include <functional>
#include <set>

struct StarProjection { mitaka::gui::ScreenPoint point; double opacity = 1; };
using StarProjector = std::function<std::optional<StarProjection>(mitaka::EquatorialCoordinates)>;

@interface StarRenderer : NSObject
- (instancetype)initWithModel:(std::shared_ptr<const mitaka::gui::SkyModel>)model
    catalogs:(std::shared_ptr<const mitaka::gui::ExtendedCatalogs>)catalogs;
- (void)setSelectedNameHIPs:(const std::set<std::int32_t>&)hips;
- (void)drawInRect:(NSRect)map magnitudeLimit:(double)magnitudeLimit
    options:(mitaka::gui::StarDisplayOptions)options quality:(mitaka::gui::RendererDisplayOptions)quality
    projector:(const StarProjector&)projector;
@end
