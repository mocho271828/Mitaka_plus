#include "local_image.hpp"

#include <CoreGraphics/CoreGraphics.h>
#include <ImageIO/ImageIO.h>
#include <algorithm>
#include <array>
#include <cstdint>
#include <fstream>
#include <memory>
#include <stdexcept>
#include <type_traits>

namespace mitaka::gui {
namespace {
constexpr std::uintmax_t maximum_file_bytes = 64 * 1024 * 1024;
constexpr std::size_t maximum_source_pixels = 64 * 1024 * 1024;
constexpr std::size_t maximum_source_dimension = 32768;
constexpr int maximum_output_dimension = 1024;
struct ReleaseCF { void operator()(const void* value) const { if (value) CFRelease(value); } };
template<class T> using CFPointer = std::unique_ptr<std::remove_pointer_t<T>, ReleaseCF>;

std::vector<std::uint8_t> read_image_bytes(const std::filesystem::path& path) {
    std::error_code error;
    const auto status = std::filesystem::status(path, error);
    if (error || !std::filesystem::is_regular_file(status))
        throw std::runtime_error("画像ファイルがないか、通常ファイルではありません");
    const auto size = std::filesystem::file_size(path, error);
    if (error) throw std::runtime_error("画像ファイルのサイズを取得できません");
    if (size == 0 || size > maximum_file_bytes)
        throw std::runtime_error("画像ファイルが空、または64MiBの上限を超えています");
    std::ifstream stream(path, std::ios::binary);
    if (!stream) throw std::runtime_error("画像ファイルを開けません");
    std::vector<std::uint8_t> bytes(static_cast<std::size_t>(size));
    if (!stream.read(reinterpret_cast<char*>(bytes.data()), static_cast<std::streamsize>(size)))
        throw std::runtime_error("画像ファイルの読み込みが途中で終了しました");
    if (stream.peek() != std::char_traits<char>::eof() || stream.bad())
        throw std::runtime_error("画像ファイルが読み込み中に変化しました");
    return bytes;
}

std::size_t dimension(CFDictionaryRef properties, CFStringRef key) {
    const auto value = CFDictionaryGetValue(properties, key);
    std::int64_t result = 0;
    if (!value || CFGetTypeID(value) != CFNumberGetTypeID()
        || !CFNumberGetValue(static_cast<CFNumberRef>(value), kCFNumberSInt64Type, &result)
        || result <= 0 || result > static_cast<std::int64_t>(maximum_source_dimension))
        throw std::runtime_error("画像の寸法が不正、または各辺32768pxの上限を超えています");
    return static_cast<std::size_t>(result);
}

void require_complete(CGImageSourceRef source) {
    if (CGImageSourceGetStatus(source) != kCGImageStatusComplete
        || CGImageSourceGetStatusAtIndex(source, 0) != kCGImageStatusComplete)
        throw std::runtime_error("画像データが不完全、または破損しています");
}

void require_image_end(const std::vector<std::uint8_t>& bytes, CFStringRef type) {
    // ImageIOはEOIのないJPEGを補完するため、完全性をstatusだけに委ねない。
    constexpr std::array<std::uint8_t, 12> png_end{{0, 0, 0, 0, 'I', 'E', 'N', 'D', 0xae, 0x42, 0x60, 0x82}};
    bool complete = true;
    if (CFEqual(type, CFSTR("public.jpeg")))
        complete = bytes.size() >= 2 && bytes[bytes.size() - 2] == 0xff && bytes.back() == 0xd9;
    else if (CFEqual(type, CFSTR("public.png")))
        complete = bytes.size() >= png_end.size() && std::equal(png_end.rbegin(), png_end.rend(), bytes.rbegin());
    if (!complete) throw std::runtime_error("画像の終端が不完全、または終端後に余分なデータがあります");
}

std::uint32_t little_endian(const std::vector<std::uint8_t>& bytes, std::size_t offset, unsigned count) {
    if (offset > bytes.size() || count > bytes.size() - offset)
        throw std::runtime_error("画像ヘッダーが不完全です");
    std::uint32_t value = 0;
    for (unsigned index = 0; index < count; ++index) value |= std::uint32_t(bytes[offset + index]) << (index * 8);
    return value;
}

void require_legacy_pixels(const std::vector<std::uint8_t>& bytes, CFStringRef type,
                           std::size_t width, std::size_t height) {
    // ImageIOは切断BMP/TGAも補完する。デコードはImageIOに任せ、画素領域だけを検証する。
    if (CFEqual(type, CFSTR("com.microsoft.bmp"))) {
        const auto header_size = little_endian(bytes, 14, 4);
        const auto pixel_offset = little_endian(bytes, 10, 4);
        const auto bits = little_endian(bytes, 28, 2);
        const auto compression = little_endian(bytes, 30, 4);
        if (header_size < 40 || header_size > bytes.size() - 14 || pixel_offset < 14 + header_size ||
            pixel_offset > bytes.size() || (bits != 24 && bits != 32) || (compression != 0 && compression != 3))
            throw std::runtime_error("BMPは非圧縮24/32-bit形式に対応しています");
        const auto stride = ((width * bits + 31) / 32) * 4;
        if (height > (bytes.size() - pixel_offset) / stride)
            throw std::runtime_error("BMPの画素データが不完全です");
    } else if (CFEqual(type, CFSTR("com.truevision.tga-image"))) {
        if (bytes.size() < 18 || (bytes[2] != 2 && bytes[2] != 10) || bytes[1] > 1 ||
            (bytes[16] != 16 && bytes[16] != 24 && bytes[16] != 32))
            throw std::runtime_error("TGAは16/24/32-bit true-color形式に対応しています");
        const std::size_t pixel_bytes = bytes[16] / 8;
        std::size_t offset = 18 + bytes[0] + bytes[1] * little_endian(bytes, 5, 2) * ((bytes[7] + 7) / 8);
        std::size_t remaining = width * height;
        const auto consume = [&](std::size_t count) {
            if (offset > bytes.size() || count > bytes.size() - offset)
                throw std::runtime_error("TGAの画素データが不完全です");
            offset += count;
        };
        if (bytes[2] == 2) { consume(remaining * pixel_bytes); return; }
        while (remaining != 0) {
            consume(1);
            const auto packet = bytes[offset - 1];
            const std::size_t count = (packet & 0x7f) + 1;
            if (count > remaining) throw std::runtime_error("TGAの圧縮packetが画素数を超えています");
            consume((packet & 0x80 ? 1 : count) * pixel_bytes);
            remaining -= count;
        }
    }
}

} // namespace

TextureImage load_local_image(const std::filesystem::path& path) {
    const auto bytes = read_image_bytes(path);
    CFPointer<CFDataRef> data(CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, bytes.data(),
        static_cast<CFIndex>(bytes.size()), kCFAllocatorNull));
    if (!data) throw std::runtime_error("画像データを確保できません");
    const void* source_keys[] = {kCGImageSourceShouldCache};
    const void* source_values[] = {kCFBooleanFalse};
    CFPointer<CFDictionaryRef> options(CFDictionaryCreate(kCFAllocatorDefault, source_keys, source_values, 1,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks));
    CFPointer<CGImageSourceRef> source(CGImageSourceCreateWithData(data.get(), options.get()));
    if (!source || CGImageSourceGetCount(source.get()) != 1)
        throw std::runtime_error("単一画像として読み込めません");
    const CFStringRef type = CGImageSourceGetType(source.get());
    if (!type || (!CFEqual(type, CFSTR("public.jpeg")) && !CFEqual(type, CFSTR("public.png")) &&
        !CFEqual(type, CFSTR("com.microsoft.bmp")) && !CFEqual(type, CFSTR("com.truevision.tga-image"))))
        throw std::runtime_error("JPEG / PNG / BMP / TGA 以外の画像形式です");
    require_image_end(bytes, type);
    require_complete(source.get());
    CFPointer<CFDictionaryRef> properties(CGImageSourceCopyPropertiesAtIndex(source.get(), 0, nullptr));
    if (!properties) throw std::runtime_error("画像の寸法を取得できません");
    const auto width = dimension(properties.get(), kCGImagePropertyPixelWidth);
    const auto height = dimension(properties.get(), kCGImagePropertyPixelHeight);
    if (width > maximum_source_pixels / height)
        throw std::runtime_error("画像が64M画素の上限を超えています");
    require_legacy_pixels(bytes, type, width, height);

    CFPointer<CFNumberRef> limit(CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &maximum_output_dimension));
    const void* thumbnail_keys[] = {kCGImageSourceCreateThumbnailFromImageAlways,
        kCGImageSourceThumbnailMaxPixelSize, kCGImageSourceCreateThumbnailWithTransform,
        kCGImageSourceShouldCacheImmediately};
    const void* thumbnail_values[] = {kCFBooleanTrue, limit.get(), kCFBooleanTrue, kCFBooleanTrue};
    CFPointer<CFDictionaryRef> thumbnail_options(CFDictionaryCreate(kCFAllocatorDefault,
        thumbnail_keys, thumbnail_values, 4, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks));
    CFPointer<CGImageRef> image(CGImageSourceCreateThumbnailAtIndex(source.get(), 0, thumbnail_options.get()));
    if (!image) throw std::runtime_error("画像のデコードに失敗しました");
    require_complete(source.get());
    TextureImage result;
    result.width = CGImageGetWidth(image.get());
    result.height = CGImageGetHeight(image.get());
    if (!result.width || !result.height || result.width > maximum_output_dimension || result.height > maximum_output_dimension)
        throw std::runtime_error("縮小画像の寸法が不正です");
    result.rgba.resize(result.width * result.height * 4);
    CFPointer<CGColorSpaceRef> color_space(CGColorSpaceCreateWithName(kCGColorSpaceSRGB));
    CFPointer<CGContextRef> bitmap(CGBitmapContextCreate(result.rgba.data(), result.width, result.height,
        8, result.width * 4, color_space.get(), kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast));
    if (!bitmap) throw std::runtime_error("RGBA画像を生成できません");
    // CGImageの先頭行をRGBAの先頭行へ描き、北を上とする画像の向きを保持する。
    CGContextSetBlendMode(bitmap.get(), kCGBlendModeCopy);
    CGContextDrawImage(bitmap.get(), CGRectMake(0, 0, result.width, result.height), image.get());
    // Bitmap contextのpremultiplied alphaを、描画モデルのstraight alphaへそろえる。
    for (std::size_t pixel = 0; pixel < result.rgba.size(); pixel += 4) {
        const unsigned alpha = result.rgba[pixel + 3];
        for (std::size_t channel = 0; channel < 3; ++channel)
            result.rgba[pixel + channel] = alpha == 0 ? 0 : static_cast<std::uint8_t>(
                std::min(255u, (result.rgba[pixel + channel] * 255u + alpha / 2) / alpha));
    }
    return result;
}

} // namespace mitaka::gui
