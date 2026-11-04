#import <AppKit/AppKit.h>
#include "radius_display.hpp"

// App が実状態を所有する。失敗を返す apply は状態を変更しない契約。
// callback と公開操作は main thread 限定。カメラの可否判定も App 側で行う。
@interface RadiusDisplayController : NSWindowController
@property(nonatomic, copy) BOOL (^readSettings)(mitaka::gui::RadiusDisplayOptions *options,
    mitaka::gui::RadiusScaleMode *mode, NSString **error);
@property(nonatomic, copy) BOOL (^applySettings)(mitaka::gui::RadiusDisplayOptions options,
    mitaka::gui::RadiusScaleMode mode, NSString **error);

// 窓を生成せず最新値を検証する。表示中ならフォームも更新する。
- (BOOL)reloadSettingsWithError:(NSString **)error;
// UI と同じ入力境界。全4値と mode を検証した後に apply を一度だけ呼ぶ。
- (BOOL)applyFieldValues:(NSArray<NSString *> *)values
                   mode:(NSInteger)mode error:(NSString **)error;
@end
