#pragma once
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

// メインスレッド専用。実行の権限・寿命は既存 ScriptController が管理する。
@interface ScriptConsoleController : NSWindowController <NSTextViewDelegate>
@property(nonatomic, copy, nullable) BOOL (^runSource)(NSString *source, NSError * _Nullable * _Nullable error);
@property(nonatomic, copy, nullable) void (^cancelExecution)(void);
@property(nonatomic) BOOL running;
@property(nonatomic, copy) NSString *inputSource;
@property(nonatomic, readonly, copy) NSString *outputText;
- (void)appendOutput:(NSString *)text;
- (void)clearOutput;
- (void)submitInput:(nullable id)sender;
- (void)previousInput:(nullable id)sender;
- (void)nextInput:(nullable id)sender;
- (void)cancel:(nullable id)sender;
@end

NS_ASSUME_NONNULL_END
