#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface MediaController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate>
@property(nonatomic, readonly) NSUInteger entryCount;
@property(nonatomic, readonly) NSUInteger unresolvedCount;
@property(nonatomic, readonly, copy) NSString *diagnosticSummary;
@property(nonatomic, readonly) BOOL previewVisible;
@property(nonatomic, readonly) BOOL mediaPlaying;
@property(nonatomic, readonly, copy) NSString *previewMessage;
// データ切替時には再生・プレビューと一時的な割当てを破棄する。
- (void)loadDataDirectory:(NSURL *)directory;
- (void)openLocalMedia:(nullable id)sender;
- (void)selectEntryAtIndex:(NSUInteger)index;
- (BOOL)mapSelectedEntryToURL:(NSURL *)url error:(NSError * _Nullable * _Nullable)error;
- (BOOL)previewSelected:(NSError * _Nullable * _Nullable)error;
- (void)closePreview;
- (void)invalidate;
@end
NS_ASSUME_NONNULL_END
