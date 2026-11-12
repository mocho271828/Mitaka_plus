#pragma once
#import <AppKit/AppKit.h>
#include "renderer_options.hpp"

// 実状態は App が所有する。main thread 専用で、失敗した apply は状態を変更しない。
@interface RendererOptionsController : NSWindowController
@property(nonatomic, copy) BOOL (^readSettings)(mitaka::gui::RendererDisplayOptions *options, NSString **error);
@property(nonatomic, copy) BOOL (^applySettings)(mitaka::gui::RendererDisplayOptions options, NSString **error);
- (BOOL)reloadSettingsWithError:(NSString **)error;
// 0: AA、1: 点、2: 線、3: 文字。最新値を読んで指定した項目だけを変更する。
- (BOOL)applyOptionAtIndex:(NSInteger)index enabled:(BOOL)enabled error:(NSString **)error;
// メニュー・Lua・復元からの受動反映。callback を呼ばず、適用中にも使える。
- (void)synchronizeOptions:(mitaka::gui::RendererDisplayOptions)options;
@end
