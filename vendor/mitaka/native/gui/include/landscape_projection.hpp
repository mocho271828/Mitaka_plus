#pragma once

#include "horizon_viewport.hpp"
#include "local_image.hpp"
#include "mitaka/place_catalog.hpp"
#include "mitaka/observation.hpp"
#include <array>

namespace mitaka::gui {

// 原版の局所+X=南,+Y=東,+Z=上、PNG/JPEGの行反転に由来する左上原点UV。
// 水平は周期化、垂直は未clamp。azimuthは真北0°・東90°。
std::array<double, 2> landscape_image_uv(const PlaceLandscape& landscape,
                                        HorizontalCoordinates direction);

// 地平図と同じ円筒投影。画像のS/TはともにCLAMP_TO_EDGE、出力は最大1024px。
// 原版の球メッシュのUVを角度から評価する。旧GLの四角形補間・mipmapとの画素一致はしない。
// texture=nullptrでは黒い下半球と透明な上半球。失敗画像の代替であることは呼出元が通知する。
TextureImage render_horizon_landscape(const TextureImage* texture, const PlaceLandscape* landscape,
                                      HorizonViewport viewport, std::size_t width, std::size_t height);

} // namespace mitaka::gui
