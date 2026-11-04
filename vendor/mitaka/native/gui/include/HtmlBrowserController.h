#pragma once
#import <AppKit/AppKit.h>

// 明示選択したローカル HTML の閲覧と、ユーザーが押した mtkp リンクだけを扱う。
@interface HtmlBrowserController : NSWindowController
@property(nonatomic, copy) NSURL *defaultDirectoryURL;
@property(nonatomic, copy) BOOL (^scriptRequested)(NSString *source, NSURL *sourceFile, NSString **error);
@property(nonatomic, readonly) BOOL trusted;
// 明示選択・信頼確認済みの file URL だけを渡す。読み込み完了までは実行不可。
- (BOOL)openTrustedFileURL:(NSURL *)url error:(NSError **)error;
- (void)chooseTrustedHTML:(id)sender;
@end
