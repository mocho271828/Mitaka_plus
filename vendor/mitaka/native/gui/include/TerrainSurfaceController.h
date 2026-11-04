#import <Foundation/Foundation.h>
#include "terrain_snapshot.hpp"

typedef NS_ENUM(NSInteger, TerrainPreparationState) {
    TerrainPreparationIdle,
    TerrainPreparationPreparing,
    TerrainPreparationReady,
    TerrainPreparationUnavailable,
    TerrainPreparationFailed,
    TerrainPreparationInvalidated
};

typedef void (^TerrainSurfaceCompletion)(
    std::shared_ptr<const mitaka::gui::TerrainSurfaceSnapshot> snapshot, NSString *error);

@interface TerrainSurfaceController : NSObject
// 全メソッド/completionはmain thread。入力不正は現在の要求を変えず同期拒否する。
// 実行中1件と最新pending1件だけ保持する。各要求は原本を再度開き、完成cacheは使わない。
- (void)requestSurface:(mitaka::gui::TerrainSurfaceRequest)request
           completion:(TerrainSurfaceCompletion)completion;
- (TerrainPreparationState)state;
- (std::uint64_t)generation;
// preparing/idle/invalidatedではnull。取替中は旧地形を保持せずcallerが球面へ戻す。
// readyでもframe.modeがnone/sphereなら、その明示された描画方式を採用する。
- (std::shared_ptr<const mitaka::gui::TerrainSurfaceSnapshot>)snapshot;
- (void)cancel;
- (void)invalidate;
@end
