#import <Foundation/Foundation.h>
#include "small_body_orbit_model.hpp"

typedef void (^SmallBodyOrbitCompletion)(
    std::shared_ptr<const mitaka::gui::SmallBodyOrbitSnapshot> snapshot, NSString *error);

@interface SmallBodyOrbitController : NSObject
// 全メソッドと completion は main thread。入力不正は同期例外で原子的に拒否する。
// 同じ model・軌道要求行・絶対 TDB 区間は再利用し、最新 completion だけを呼ぶ。
- (void)requestModel:(std::shared_ptr<const mitaka::gui::SmallBodyModel>)model
             display:(std::shared_ptr<const mitaka::gui::SmallBodyDisplayModel>)display
            sampling:(mitaka::SmallBodyOrbitSampling)sampling
          completion:(SmallBodyOrbitCompletion)completion;
// 非表示中の取消。完成済み cache は保持し、以降の request を許す。
- (void)cancel;
// 終了用。cache を破棄し、以降の request を拒否する。
- (void)invalidate;
@end
