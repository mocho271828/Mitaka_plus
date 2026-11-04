#include "RendererQuality.h"

namespace mitaka::gui {

RendererQualityScope::RendererQualityScope(CGContextRef context, const RendererDisplayOptions& options,
                                         RendererPrimitive primitive) {
    const bool antialias = renderer_antialias(options, primitive);
    if (!context) throw std::invalid_argument("renderer quality requires a graphics context");
    context_ = CGContextRetain(context);
    CGContextSaveGState(context_);
    CGContextSetShouldAntialias(context_, antialias);
    if (primitive == RendererPrimitive::text) {
        // 有効化しても、出力 context が font smoothing をサポートする保証はない。
        CGContextSetShouldSmoothFonts(context_, antialias);
    }
}

RendererQualityScope::~RendererQualityScope() noexcept {
    CGContextRestoreGState(context_);
    CGContextRelease(context_);
}

} // namespace mitaka::gui
