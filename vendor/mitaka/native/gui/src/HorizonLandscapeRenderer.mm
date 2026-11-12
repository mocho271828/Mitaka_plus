#import "HorizonLandscapeRenderer.h"
#import "RendererQuality.h"
#include "landscape_projection.hpp"
#include <algorithm>
#include <array>
#include <cmath>
#include <cstring>

using namespace mitaka::gui;

namespace {
struct LandscapeKey {
    std::optional<std::size_t> selection;
    bool visible;
    std::array<double, 6> viewport;
    std::size_t width, height;
    bool operator==(const LandscapeKey& other) const {
        return selection == other.selection && visible == other.visible && viewport == other.viewport &&
            width == other.width && height == other.height;
    }
};
}

@implementation HorizonLandscapeRenderer {
    std::shared_ptr<const EarthLandscapes> _model;
    std::string _identifier;
    BOOL _showsLandscapeImage;
    NSImage *_image;
    std::optional<TextureImage> _pixels;
    std::optional<LandscapeKey> _key;
}
- (instancetype)init {
    if ((self = [super init])) _showsLandscapeImage = YES;
    return self;
}
- (BOOL)showsLandscapeImage { return _showsLandscapeImage; }
- (void)setShowsLandscapeImage:(BOOL)visible { _showsLandscapeImage = visible; }
- (BOOL)hasModel { return bool(_model); }
- (void)setModel:(std::shared_ptr<const EarthLandscapes>)model {
    if (_model == model) return;
    _model = std::move(model);
    _image = nil;
    _pixels.reset();
    _key.reset();
}
- (void)setObserverPlaceIdentifier:(const std::string&)identifier { _identifier = identifier; }
- (const std::string&)observerPlaceIdentifier { return _identifier; }
- (void)prepareInRect:(NSRect)rect viewport:(HorizonViewport)viewport {
    if (!_model || rect.size.width <= 0 || rect.size.height <= 0) return;
    // 投影の移行中は毎フレーム画像を再生成するため、計算量を抑える。
    const double maximumDimension = viewport.perspective_blend > 0 && viewport.perspective_blend < 1 ? 512 : 1024;
    const double scale = std::min(1.0, maximumDimension / std::max(rect.size.width, rect.size.height));
    const auto width = static_cast<std::size_t>(std::clamp(std::ceil(rect.size.width * scale), 1.0, 1024.0));
    const auto height = static_cast<std::size_t>(std::clamp(std::ceil(rect.size.height * scale), 1.0, 1024.0));
    const auto selected = _model->selection(_identifier);
    const LandscapeKey key{selected, bool(_showsLandscapeImage),
        {viewport.center_azimuth_deg, viewport.center_altitude_deg, viewport.vertical_fov_deg, viewport.perspective_blend, viewport.roll_deg, viewport.perspective_fov_deg}, width, height};
    if (!_image || !_key || !(*_key == key)) {
        const auto* definition = selected ? &_model->definitions().landscapes()[*selected].definition : nullptr;
        const auto* texture = selected && _showsLandscapeImage ? _model->image(*selected) : nullptr;
        _pixels = render_horizon_landscape(texture, definition, viewport, width, height);
        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
            pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
            isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:NSBitmapFormatAlphaNonpremultiplied
            bytesPerRow:width * 4 bitsPerPixel:32];
        if (bitmap) {
            std::memcpy(bitmap.bitmapData, _pixels->rgba.data(), _pixels->rgba.size());
            bitmap = [bitmap bitmapImageRepByRetaggingWithColorSpace:NSColorSpace.sRGBColorSpace];
        }
        _image = bitmap ? [[NSImage alloc] initWithSize:rect.size] : nil;
        if (bitmap) [_image addRepresentation:bitmap];
        _key = key;
    }
}
- (BOOL)isOpaqueAtPoint:(NSPoint)point inRect:(NSRect)rect viewport:(HorizonViewport)viewport {
    if (!NSPointInRect(point, rect) || !_model || !_showsLandscapeImage) return NO;
    [self prepareInRect:rect viewport:viewport];
    if (!_image || !_pixels) return NO;
    const auto& pixels = *_pixels;
    const double x = (point.x - rect.origin.x) / rect.size.width * pixels.width - 0.5;
    const double y = (point.y - rect.origin.y) / rect.size.height * pixels.height - 0.5;
    // 高品質補間の端を保守的に扱い、近傍がすべて不透明な場合のみ選択を抑止する。
    const auto left = static_cast<long>(std::floor(x)), top = static_cast<long>(std::floor(y));
    for (long dy = -1; dy <= 2; ++dy) for (long dx = -1; dx <= 2; ++dx) {
        const auto column = static_cast<std::size_t>(std::clamp(left + dx, 0L, static_cast<long>(pixels.width - 1)));
        const auto row = static_cast<std::size_t>(std::clamp(top + dy, 0L, static_cast<long>(pixels.height - 1)));
        if (pixels.rgba[(row * pixels.width + column) * 4 + 3] != 255) return NO;
    }
    return YES;
}
- (void)drawInRect:(NSRect)rect viewport:(HorizonViewport)viewport quality:(RendererDisplayOptions)quality {
    if (!_model || rect.size.width <= 0 || rect.size.height <= 0) return;
    [self prepareInRect:rect viewport:viewport];
    RendererQualityScope clipped(NSGraphicsContext.currentContext.CGContext, quality);
    CGContextClipToRect(NSGraphicsContext.currentContext.CGContext, rect);
    [_image drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1
        respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
}
@end
