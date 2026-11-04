#pragma once

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DisplayImageFormat) {
    DisplayImageFormatPNG,
    DisplayImageFormatJPEG,
    DisplayImageFormatBMP
};

// メインスレッド専用。元のビューを移動せず、描画結果を別ウィンドウへ複製する。
@interface DisplayOutputController : NSObject <NSWindowDelegate>
@property(nonatomic, weak, nullable) NSView *sourceView;
@property(nonatomic) BOOL pointerVisible;
// 0 は通常表示、1 は黒。範囲外・非有限値は std::invalid_argument。
@property(nonatomic) double fadeOpacity;
@property(nonatomic, readonly) BOOL projectionVisible;

// ファイルI/Oは行わない。PNG/BMP/JPEGへ現在のsourceViewを符号化する。
// ポインタと黒フェードは投影専用であり、この画像には含めない。
- (nullable NSData *)captureFormat:(DisplayImageFormat)format error:(NSError * _Nullable * _Nullable)error;
- (void)showProjection;
- (void)closeProjection;
// タイマー・通知監視・投影ウィンドウを解放する。以降の操作では再開しない。
- (void)invalidate;
@end

NS_ASSUME_NONNULL_END
