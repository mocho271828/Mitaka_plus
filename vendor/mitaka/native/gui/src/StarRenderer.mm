#import "RendererQuality.h"
#import "StarRenderer.h"
#include "star_labels.hpp"
#include "star_brightness.hpp"
#include <algorithm>
#include <unordered_set>

using namespace mitaka::gui;

@implementation StarRenderer {
    std::shared_ptr<const SkyModel> _model;
    NSMutableDictionary<NSNumber*, NSString*> *_names;
    std::unordered_set<std::int32_t> _hosts;
    std::set<std::int32_t> _selectedNames;
}
- (instancetype)initWithModel:(std::shared_ptr<const SkyModel>)model
    catalogs:(std::shared_ptr<const ExtendedCatalogs>)catalogs {
    if ((self = [super init])) {
        _model = std::move(model);
        _names = [NSMutableDictionary dictionary];
        if (catalogs) {
            _hosts.insert(catalogs->exoplanet_hosts.begin(), catalogs->exoplanet_hosts.end());
            for (const auto& record : catalogs->star_names) {
                if (record.is_featured) _selectedNames.insert(record.hip);
                const auto decode = [](const std::string& bytes) {
                    return [[NSString alloc] initWithBytes:bytes.data() length:bytes.size()
                        encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingDOSJapanese)];
                };
                NSString *name = decode(record.localized_name_bytes);
                if (!name.length || [name isEqualToString:@"*"]) name = decode(record.name_bytes);
                if (name.length && ![name isEqualToString:@"*"]) _names[@(record.hip)] = name;
            }
        }
    }
    return self;
}
- (void)setSelectedNameHIPs:(const std::set<std::int32_t>&)hips { _selectedNames = hips; }
- (void)drawInRect:(NSRect)map magnitudeLimit:(double)magnitudeLimit
    options:(StarDisplayOptions)options quality:(RendererDisplayOptions)quality
    projector:(const StarProjector&)projector {
    validate_star_display(options);
    if (!_model || !options.visible) return;
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    RendererQualityScope points(context, quality, RendererPrimitive::point);
    for (const auto& star : _model->stars()) {
        if (star.apparent_v_magnitude > magnitudeLimit) continue;
        const auto projected = projector({star.right_ascension_degrees, star.declination_degrees});
        if (!projected) continue;
        const NSPoint center = NSMakePoint(map.origin.x + projected->point.x, map.origin.y + projected->point.y);
        const auto appearance = star_point_appearance(star.apparent_v_magnitude, options.brightness);
        const double radius = appearance.radius;
        const double alpha = appearance.opacity * projected->opacity;
        const double warmth = std::clamp(static_cast<double>(star.color_b_minus_v), 0.0, 1.6) / 1.6;
        CGContextSetRGBFillColor(context, 0.78 + 0.22 * warmth, 0.87 - 0.12 * warmth, 1 - 0.4 * warmth, alpha);
        CGContextFillEllipseInRect(context, CGRectMake(center.x - radius, center.y - radius, radius * 2, radius * 2));
        if (star_has_marking(star, options.marking, _hosts.count(star.hip) != 0)) {
            RendererQualityScope lines(context, quality, RendererPrimitive::line);
            const bool binary = options.marking == StarMarking::binary;
            CGContextSetRGBStrokeColor(context, binary ? 0.3 : 1, 0.9, 0.3, projected->opacity);
            CGContextSetLineWidth(context, 1);
            CGContextStrokeEllipseInRect(context, CGRectMake(center.x - 6, center.y - 6, 12, 12));
        }
        if (!options.proper_names && !options.bayer_labels && !options.flamsteed_labels && !options.hip_labels)
            continue;
        NSString *proper = options.proper_names && (!options.selected_proper_names_only || _selectedNames.count(star.hip))
            ? _names[@(star.hip)] : nil;
        const auto designation = star_catalog_label(star, options);
        NSString *label = [NSString stringWithUTF8String:designation.c_str()];
        if (proper.length) label = label.length ? [NSString stringWithFormat:@"%@ (%@)", proper, label] : proper;
        if (label.length) {
            RendererQualityScope text(context, quality, RendererPrimitive::text);
            [label drawAtPoint:NSMakePoint(center.x + 5, center.y + 3) withAttributes:@{
            NSFontAttributeName: [NSFont systemFontOfSize:10],
            NSForegroundColorAttributeName: [NSColor colorWithSRGBRed:0.76 green:0.8 blue:0.9 alpha:projected->opacity * 0.9]}];
        }
    }
}
@end
