#pragma once
#import <AppKit/AppKit.h>
#include "earth_landscapes.hpp"
#include "horizon_viewport.hpp"
#include "renderer_options.hpp"

// 地点・view変更時だけ再投影し、時刻更新では画像を再生成しない。
@interface HorizonLandscapeRenderer : NSObject
@property(nonatomic) BOOL showsLandscapeImage;
@property(nonatomic, readonly) BOOL hasModel;
- (void)setModel:(std::shared_ptr<const mitaka::gui::EarthLandscapes>)model;
- (void)setObserverPlaceIdentifier:(const std::string&)identifier;
- (const std::string&)observerPlaceIdentifier;
- (void)drawInRect:(NSRect)rect viewport:(mitaka::gui::HorizonViewport)viewport
           quality:(mitaka::gui::RendererDisplayOptions)quality;
@end
