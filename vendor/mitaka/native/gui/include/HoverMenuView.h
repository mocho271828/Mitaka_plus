#import <AppKit/AppKit.h>

// 描画ビューを子に置き、上端にだけ操作メニューを重ねる。
@interface HoverMenuView : NSView
- (instancetype)initWithFrame:(NSRect)frame menu:(NSMenu *)menu;
@property(nonatomic, readonly) BOOL menuVisible;
- (void)showMenu;
- (void)hideMenu;
@end
