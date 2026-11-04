#pragma once

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

// メインスレッド専用。主ウィンドウの delegate から全画面通知を転送する。
@interface WindowPresentationController : NSObject <NSWindowDelegate>
- (instancetype)initWithWindow:(NSWindow *)window;
@property(nonatomic, readonly) BOOL fullScreen;
@property(nonatomic, readonly) BOOL transitioning;
@property(nonatomic, copy, readonly, nullable) NSString *lastTransitionError;

// YES は受付または同じ状態への再要求。AppKit の非同期遷移完了を意味しない。
- (BOOL)requestFullScreen:(BOOL)enabled error:(NSString * _Nullable * _Nullable)error;
- (BOOL)toggleFullScreenWithError:(NSString * _Nullable * _Nullable)error;

// 名称・バージョンは標準 About パネルが bundle 情報から取得する。
+ (NSDictionary<NSAboutPanelOptionKey, id> *)aboutPanelOptionsForBundle:(NSBundle *)bundle;
@end

NS_ASSUME_NONNULL_END
