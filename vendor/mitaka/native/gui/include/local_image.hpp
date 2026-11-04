#pragma once

#include <cstddef>
#include <cstdint>
#include <filesystem>
#include <vector>

namespace mitaka::gui {

// 左上原点、8-bit sRGB、RGBA順のstraight alpha。行間のpaddingはない。
struct TextureImage {
    std::size_t width = 0, height = 0;
    std::vector<std::uint8_t> rgba;
};

// 通常ファイルのJPEG / PNG / BMP / TGA内容を読み取り専用で最大1024pxのRGBAへ変換する。
// 容量64MiB、元画像64M画素・各辺32768px。完全性・EXIF向き、JPEG/PNGの終端を検証する。
// BMPは非圧縮24/32-bit、TGAは16/24/32-bit true-color(raw/RLE)。画素領域の切断も拒否する。
// 不正・欠損時はruntime_error。呼出元が画像の用途とファイル名を付けて通知する。
TextureImage load_local_image(const std::filesystem::path& path);

} // namespace mitaka::gui
