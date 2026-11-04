#pragma once

#include "renderer_options.hpp"
#include <CoreGraphics/CoreGraphics.h>

namespace mitaka::gui {

// 描画群を囲む。Allows 系は graphics state 外なので変更しない。
// context の設定を復元するまで同一スレッド内で使い、別の save/restore と交差させない。
class RendererQualityScope final {
public:
    RendererQualityScope(CGContextRef context, const RendererDisplayOptions& options,
                         RendererPrimitive primitive = RendererPrimitive::general);
    ~RendererQualityScope() noexcept;
    RendererQualityScope(const RendererQualityScope&) = delete;
    RendererQualityScope& operator=(const RendererQualityScope&) = delete;
    RendererQualityScope(RendererQualityScope&&) = delete;
    RendererQualityScope& operator=(RendererQualityScope&&) = delete;

private:
    CGContextRef context_ = nullptr;
};

} // namespace mitaka::gui
