#import "MediaImageView.h"
#include <algorithm>
#include <cmath>
#include <stdexcept>

@implementation MediaImageView
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) [self resetTransform];
    return self;
}
- (void)setImage:(NSImage *)image { _image = image; [self resetTransform]; }
- (void)setZoom:(double)value {
    if (!std::isfinite(value) || value < 0.05 || value > 20) throw std::invalid_argument("画像倍率は0.05–20です");
    _zoom = value; self.needsDisplay = YES;
}
- (void)setRotationDegrees:(double)value {
    if (!std::isfinite(value)) throw std::invalid_argument("画像回転は有限値が必要です");
    _rotationDegrees = std::remainder(value, 360.0); self.needsDisplay = YES;
}
- (void)setImageOpacity:(double)value {
    if (!std::isfinite(value) || value < 0 || value > 1) throw std::invalid_argument("画像不透明度は0–1です");
    _imageOpacity = value; self.needsDisplay = YES;
}
- (void)setPan:(NSPoint)value {
    if (!std::isfinite(value.x) || !std::isfinite(value.y)) throw std::invalid_argument("画像位置は有限値が必要です");
    _pan = value; self.needsDisplay = YES;
}
- (void)resetTransform {
    _zoom = 1; _rotationDegrees = 0; _imageOpacity = 1; _pan = NSZeroPoint;
    self.needsDisplay = YES;
}
- (BOOL)mouseDownCanMoveWindow { return NO; }
- (void)mouseDragged:(NSEvent *)event {
    self.pan = NSMakePoint(_pan.x + event.deltaX, _pan.y - event.deltaY);
}
- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    [[NSColor colorWithWhite:0.06 alpha:1] setFill]; NSRectFill(self.bounds);
    if (!_image || _image.size.width <= 0 || _image.size.height <= 0) return;
    const double scale = std::min(self.bounds.size.width / _image.size.width, self.bounds.size.height / _image.size.height) * _zoom;
    [NSGraphicsContext saveGraphicsState];
    // AppKit の暗黙のクリップに依存せず、拡大・回転後も隣の操作欄へ描画しない。
    [NSBezierPath clipRect:self.bounds];
    NSAffineTransform *transform = [NSAffineTransform transform];
    [transform translateXBy:NSMidX(self.bounds) + _pan.x yBy:NSMidY(self.bounds) + _pan.y];
    [transform rotateByDegrees:_rotationDegrees];
    [transform scaleBy:scale]; [transform concat];
    [_image drawInRect:NSMakeRect(-_image.size.width / 2, -_image.size.height / 2, _image.size.width, _image.size.height)
        fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:_imageOpacity];
    [NSGraphicsContext restoreGraphicsState];
}
@end
