#import "RendererQuality.h"
#import "SkyCatalogRenderer.h"

#include <algorithm>
#include <cmath>

using namespace mitaka::gui;

namespace {

template<typename Record>
std::vector<mitaka::EquatorialCoordinates> coordinatesOf(const std::vector<Record>& records) {
    std::vector<mitaka::EquatorialCoordinates> result;
    result.reserve(records.size());
    for (const auto& record : records) result.push_back(record.coordinates);
    return result;
}

void label(NSString *text, NSPoint point, NSColor *color, const RendererDisplayOptions& quality) {
    RendererQualityScope textQuality(NSGraphicsContext.currentContext.CGContext, quality, RendererPrimitive::text);
    [text drawAtPoint:point withAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:10],
                                           NSForegroundColorAttributeName: color}];
}

struct DensityCache {
    SkyViewport viewport{0, 0, 0};
    NSSize size{};
    NSImage *image = nil;
};

void drawDensity(const SkyCatalogIndex& index, DensityCache& cache, NSRect map,
                 SkyViewport viewport, std::array<double, 3> color) {
    if (cache.viewport.center_ra_deg != viewport.center_ra_deg
        || cache.viewport.center_dec_deg != viewport.center_dec_deg || cache.viewport.zoom != viewport.zoom
        || !NSEqualSizes(cache.size, map.size)) {
        // 等級のないSDSSは間引かず全可視レコードを画素ごとに集計する。
        const auto width = static_cast<std::size_t>(std::ceil(map.size.width / 4));
        const auto height = static_cast<std::size_t>(std::ceil(map.size.height / 4));
        std::vector<std::uint32_t> counts(width * height);
        for (const auto& point : index.project(viewport, map.size.width, map.size.height)) {
            const auto x = std::min(width - 1, static_cast<std::size_t>(point.point.x / map.size.width * width));
            const auto y = std::min(height - 1, static_cast<std::size_t>(point.point.y / map.size.height * height));
            ++counts[y * width + x];
        }
        std::vector<std::uint8_t> pixels(width * height * 4);
        for (std::size_t pixel = 0; pixel < counts.size(); ++pixel) {
            if (counts[pixel] == 0) continue;
            const auto alpha = static_cast<std::uint8_t>(std::min(220.0, 60 + 50 * std::log1p(counts[pixel])));
            for (std::size_t channel = 0; channel < 3; ++channel)
                pixels[pixel * 4 + channel] = static_cast<std::uint8_t>(color[channel] * alpha);
            pixels[pixel * 4 + 3] = alpha;
        }
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmap = CGBitmapContextCreate(pixels.data(), width, height, 8, width * 4,
            space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(space);
        if (bitmap) {
            CGImageRef image = CGBitmapContextCreateImage(bitmap);
            cache.image = image ? [[NSImage alloc] initWithCGImage:image size:map.size] : nil;
            if (image) CGImageRelease(image);
            CGContextRelease(bitmap);
        } else cache.image = nil;
        cache.viewport = viewport;
        cache.size = map.size;
    }
    [cache.image drawInRect:map fromRect:NSZeroRect operation:NSCompositingOperationSourceOver
                  fraction:1 respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationNone)}];
}

} // namespace

@implementation SkyCatalogRenderer {
    std::shared_ptr<const SkyModel> _model;
    std::shared_ptr<const ExtendedCatalogs> _catalogs;
    SkyCatalogIndex _ngcIndex, _galaxyIndex, _quasarIndex;
    DensityCache _galaxyCache, _quasarCache;
}

- (instancetype)initWithModel:(std::shared_ptr<const SkyModel>)model
                      catalogs:(std::shared_ptr<const ExtendedCatalogs>)catalogs {
    if ((self = [super init])) {
        _model = std::move(model);
        _catalogs = std::move(catalogs);
        if (_catalogs) {
            _ngcIndex = SkyCatalogIndex(coordinatesOf(_catalogs->ngc));
            _galaxyIndex = SkyCatalogIndex(coordinatesOf(_catalogs->galaxies));
            _quasarIndex = SkyCatalogIndex(coordinatesOf(_catalogs->quasars));
        }
    }
    return self;
}

- (void)drawInRect:(NSRect)map viewport:(SkyViewport)viewport
    magnitudeLimit:(double)magnitudeLimit options:(SkyCatalogDisplay)options quality:(RendererDisplayOptions)quality {
    if (!_catalogs || !_model || map.size.width <= 0 || map.size.height <= 0) return;
    if (options.galaxies) drawDensity(_galaxyIndex, _galaxyCache, map, viewport, {0.94, 0.64, 0.30});
    if (options.quasars) drawDensity(_quasarIndex, _quasarCache, map, viewport, {0.73, 0.50, 0.94});
    if (options.galaxies || options.quasars)
        label(@"SDSS: 可視域の全件を約4px単位で密度表示（等級情報なし）",
              NSMakePoint(map.origin.x + 8, NSMaxY(map) - 18), NSColor.secondaryLabelColor, quality);
    CGContextRef context = NSGraphicsContext.currentContext.CGContext;
    if (options.nebulae) {
        RendererQualityScope lines(context, quality, RendererPrimitive::line);
        CGContextSetRGBStrokeColor(context, 0.38, 0.84, 0.71, 0.8);
        CGContextSetLineWidth(context, 0.7);
        for (const auto& projected : _ngcIndex.project(viewport, map.size.width, map.size.height)) {
            const auto& object = _catalogs->ngc[projected.index];
            if (object.magnitude != 0 && object.magnitude > magnitudeLimit) continue;
            const double radius = std::clamp(object.angular_size_arcminutes / 60 / (360 / viewport.zoom)
                                             * map.size.width / 2, 2.0, 20.0);
            CGContextStrokeEllipseInRect(context, CGRectMake(map.origin.x + projected.point.x - radius,
                map.origin.y + projected.point.y - radius, radius * 2, radius * 2));
        }
    }
}
@end
