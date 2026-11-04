#pragma once
#import <AppKit/AppKit.h>
#include "GalaxyRenderer.h"

// NSView と公開メソッドは main thread 専用。worker は immutable 入力だけを所有する。
@interface GalaxyView : NSView
@property(nonatomic, copy) void (^stateChanged)(void);
- (void)setModel:(std::shared_ptr<const mitaka::gui::GalaxySpatialModel>)model;
- (std::shared_ptr<const mitaka::gui::GalaxySpatialModel>)model;
- (mitaka::gui::GalaxyCameraPc)galaxyCamera;
- (void)setGalaxyCamera:(mitaka::gui::GalaxyCameraPc)camera;
- (mitaka::gui::GalaxySpatialVisibility)galaxyVisibility;
- (void)setGalaxyVisibility:(mitaka::gui::GalaxySpatialVisibility)visibility;
- (void)setRendererDisplayOptions:(mitaka::gui::RendererDisplayOptions)options;
- (std::optional<mitaka::gui::GalaxySpatialRecordId>)selectedRecord;
- (void)selectRecord:(std::optional<mitaka::gui::GalaxySpatialRecordId>)record;
- (BOOL)focusSelection;
- (NSString *)renderStatus;
// close/reload 前に世代を更新する。保持済み画像・原行モデルは破棄しない。
- (void)invalidatePendingWork;
@end
