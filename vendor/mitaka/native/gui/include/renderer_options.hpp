#pragma once

#include <stdexcept>

namespace mitaka::gui {

// ネイティブ描画の品質設定。旧 Plus のハードウェア描画との画素互換は表さない。
struct RendererDisplayOptions {
    bool antialias = true;
    bool point_smoothing = true;
    bool line_smoothing = true;
    bool text_smoothing = true;
};

enum class RendererPrimitive { general, point, line, text };

// 全体設定で AA を許可した場合にだけ、描画種別ごとの設定を適用する。
inline bool renderer_antialias(const RendererDisplayOptions& options, RendererPrimitive primitive) {
    switch (primitive) {
        case RendererPrimitive::general: return options.antialias;
        case RendererPrimitive::point: return options.antialias && options.point_smoothing;
        case RendererPrimitive::line: return options.antialias && options.line_smoothing;
        case RendererPrimitive::text: return options.antialias && options.text_smoothing;
    }
    throw std::invalid_argument("invalid renderer primitive");
}

} // namespace mitaka::gui
