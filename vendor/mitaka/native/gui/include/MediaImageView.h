#import <AppKit/AppKit.h>

// 媒体原本を書き換えず、ビューの表示変換だけを保持する。
@interface MediaImageView : NSView
@property(nonatomic, strong) NSImage *image;
@property(nonatomic) double zoom;
@property(nonatomic) double rotationDegrees;
@property(nonatomic) double imageOpacity;
@property(nonatomic) NSPoint pan;
- (void)resetTransform;
@end
