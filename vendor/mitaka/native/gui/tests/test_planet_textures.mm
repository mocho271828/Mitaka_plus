#include "planet_textures.hpp"

#include <CoreGraphics/CoreGraphics.h>
#include <ImageIO/ImageIO.h>
#include <algorithm>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <type_traits>

using namespace mitaka::gui;
namespace fs = std::filesystem;

namespace {
void expect(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
struct ReleaseCF { void operator()(const void* value) const { if (value) CFRelease(value); } };
template<class T> using CFPointer = std::unique_ptr<std::remove_pointer_t<T>, ReleaseCF>;

struct TemporaryDirectory {
    fs::path root;
    TemporaryDirectory() {
        std::string pattern = (fs::temp_directory_path() / "mitaka-textures-XXXXXX").string();
        std::vector<char> writable(pattern.begin(), pattern.end());
        writable.push_back('\0');
        const char* created = mkdtemp(writable.data());
        if (!created) throw std::runtime_error("cannot create temporary texture directory");
        root = created;
        fs::create_directory(root / "data");
        fs::create_directory(root / "textures");
    }
    ~TemporaryDirectory() { std::error_code error; fs::remove_all(root, error); }
};

TextureImage stripes(std::size_t width, std::size_t height) {
    TextureImage image{width, height, std::vector<std::uint8_t>(width * height * 4, 255)};
    for (std::size_t y = 0; y < height; ++y)
        for (std::size_t x = 0; x < width; ++x) {
            const auto offset = (y * width + x) * 4;
            image.rgba[offset] = y < height / 2 ? 240 : 15;
            image.rgba[offset + 1] = 30;
            image.rgba[offset + 2] = y < height / 2 ? 15 : 240;
        }
    return image;
}

void write_image(const fs::path& path, const TextureImage& pixels, CFStringRef type, int orientation = 1) {
    CFPointer<CGColorSpaceRef> color_space(CGColorSpaceCreateWithName(kCGColorSpaceSRGB));
    CFPointer<CGDataProviderRef> provider(CGDataProviderCreateWithData(nullptr, pixels.rgba.data(), pixels.rgba.size(), nullptr));
    CFPointer<CGImageRef> image(CGImageCreate(pixels.width, pixels.height, 8, 32, pixels.width * 4,
        color_space.get(), kCGBitmapByteOrder32Big | kCGImageAlphaLast, provider.get(), nullptr, false, kCGRenderingIntentDefault));
    expect(static_cast<bool>(image), "cannot create fixture image");
    const std::string pathname = path.string();
    CFPointer<CFURLRef> url(CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault,
        reinterpret_cast<const UInt8*>(pathname.data()), static_cast<CFIndex>(pathname.size()), false));
    CFPointer<CGImageDestinationRef> destination(CGImageDestinationCreateWithURL(url.get(), type, 1, nullptr));
    expect(static_cast<bool>(destination), "cannot create image fixture destination");
    CFPointer<CFNumberRef> orientation_value(CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &orientation));
    const void* keys[] = {kCGImagePropertyOrientation};
    const void* values[] = {orientation_value.get()};
    CFPointer<CFDictionaryRef> properties(CFDictionaryCreate(kCFAllocatorDefault, keys, values, 1,
        &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks));
    CGImageDestinationAddImage(destination.get(), image.get(), properties.get());
    expect(CGImageDestinationFinalize(destination.get()), "cannot finalize fixture image");
}

std::vector<std::uint8_t> read_bytes(const fs::path& path) {
    std::ifstream stream(path, std::ios::binary);
    return {std::istreambuf_iterator<char>(stream), std::istreambuf_iterator<char>()};
}
void write_bytes(const fs::path& path, const std::vector<std::uint8_t>& bytes) {
    std::ofstream stream(path, std::ios::binary);
    stream.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size()));
    expect(static_cast<bool>(stream), "cannot write fixture bytes");
}
void oversized_jpeg_header(const fs::path& path, const std::vector<std::uint8_t>& original,
                           std::uint16_t width, std::uint16_t height) {
    auto bytes = original;
    // 巨大な画素バッファを確保せず、SOFの寸法でデコード前の上限検査を確認する。
    for (std::size_t index = 0; index + 8 < bytes.size(); ++index) {
        if (bytes[index] != 0xff || (bytes[index + 1] != 0xc0 && bytes[index + 1] != 0xc2)) continue;
        bytes[index + 5] = height >> 8;
        bytes[index + 6] = height & 0xff;
        bytes[index + 7] = width >> 8;
        bytes[index + 8] = width & 0xff;
        write_bytes(path, bytes);
        return;
    }
    throw std::runtime_error("fixture JPEG SOF missing");
}
bool warning_contains(const PlanetTextures& result, const std::string& name, const std::string& reason) {
    return std::any_of(result.warnings.begin(), result.warnings.end(), [&](const auto& warning) {
        return warning.find(name) != std::string::npos && warning.find(reason) != std::string::npos;
    });
}

void synthetic_tests() {
    TemporaryDirectory folder;
    const fs::path texture = folder.root / "textures";
    const auto empty = load_planet_textures(folder.root / "data");
    expect(empty.loaded_count() == 0 && empty.warnings.size() == 11, "missing textures must produce 11 warnings");

    write_image(texture / "sun.jpg", stripes(8, 4), CFSTR("public.png"));
    write_image(texture / "mercury.jpg", stripes(32, 16), CFSTR("public.jpeg"));
    TextureImage transparent{2, 2, {200, 40, 80, 128, 200, 40, 80, 128,
                                 200, 40, 80, 128, 200, 40, 80, 128}};
    write_image(texture / "venus.jpg", transparent, CFSTR("public.png"));
    write_bytes(texture / "earth.jpg", {'b', 'r', 'o', 'k', 'e', 'n'});
    auto truncated = read_bytes(texture / "mercury.jpg");
    truncated.resize(truncated.size() / 2);
    write_bytes(texture / "mars.jpg", truncated);
    write_bytes(texture / "jupiter.jpg", {});
    write_bytes(texture / "saturn.jpg", {0});
    fs::resize_file(texture / "saturn.jpg", 64 * 1024 * 1024 + 1);
    const auto valid_jpeg = read_bytes(texture / "mercury.jpg");
    oversized_jpeg_header(texture / "uranus.jpg", valid_jpeg, 32769, 1);
    oversized_jpeg_header(texture / "neptune.jpg", valid_jpeg, 8193, 8193);
    write_image(texture / "pluto.jpg", stripes(8, 4), CFSTR("com.compuserve.gif"));
    write_image(texture / "moon.jpg", stripes(16, 8), CFSTR("public.jpeg"));
    const auto moon_bytes = read_bytes(texture / "moon.jpg");
    const auto moon_time = fs::last_write_time(texture / "moon.jpg");

    const auto result = load_planet_textures(folder.root / "data" / "");
    expect(result.loaded_count() == 4 && result.warnings.size() == 7, "partial failure must retain the 4 valid images");
    expect(result.images[10] && result.images[10]->width == 16 && result.images[10]->height == 8,
        "Moon texture must occupy the new final body slot");
    expect(read_bytes(texture / "moon.jpg") == moon_bytes && fs::last_write_time(texture / "moon.jpg") == moon_time,
        "Moon loading must preserve the source bytes and modification time");
    const auto& north = *result.images[0];
    expect(north.width == 8 && north.height == 4, "small image must not be upscaled");
    expect(north.rgba[0] > 230 && north.rgba[2] < 25, "north/top row must remain red");
    const auto south = ((north.height - 1) * north.width) * 4;
    expect(north.rgba[south] < 25 && north.rgba[south + 2] > 230, "south/bottom row must remain blue");
    const auto& jpeg = *result.images[1];
    expect(jpeg.rgba[0] > jpeg.rgba[2] + 100, "JPEG north row must remain red");
    const auto& alpha = *result.images[2];
    expect(alpha.rgba[3] == 128 && std::abs(static_cast<int>(alpha.rgba[0]) - 200) <= 2,
        "PNG must preserve straight alpha and unpremultiplied RGB");
    expect(warning_contains(result, "jupiter.jpg", "空"), "empty file must be identified");
    expect(warning_contains(result, "saturn.jpg", "64MiB"), "compressed file limit must be checked before decoding");
    expect(warning_contains(result, "uranus.jpg", "32768px"), "maximum dimension must be checked before decoding");
    expect(warning_contains(result, "neptune.jpg", "64M画素"), "pixel count must be checked before decoding");
    expect(warning_contains(result, "pluto.jpg", "JPEG / PNG"), "unsupported content format must be rejected");

    // 月だけの欠損・破損でも他の有効な画像を保ち、再読込時に古い画像を残さない。
    fs::remove(texture / "moon.jpg");
    const auto missing_moon = load_planet_textures(folder.root / "data");
    expect(!missing_moon.images[10] && missing_moon.loaded_count() == 3 && missing_moon.warnings.size() == 8,
        "missing Moon must not reuse its previous image or discard other bodies");
    expect(warning_contains(missing_moon, "moon.jpg", "通常ファイル"), "missing Moon must have its own warning");
    write_bytes(texture / "moon.jpg", {'b', 'r', 'o', 'k', 'e', 'n'});
    const auto broken_moon = load_planet_textures(folder.root / "data");
    expect(!broken_moon.images[10] && broken_moon.loaded_count() == 3 && broken_moon.warnings.size() == 8,
        "broken Moon must not discard other bodies");
    expect(warning_contains(broken_moon, "moon.jpg", "単一画像"), "broken Moon must have its own warning");
    write_bytes(texture / "moon.jpg", moon_bytes);
    const auto restored_moon = load_planet_textures(folder.root / "data");
    expect(restored_moon.images[10] && restored_moon.loaded_count() == 4 && restored_moon.warnings.size() == 7,
        "valid Moon replacement must be loaded after an earlier failure");

    auto missing_end = valid_jpeg;
    missing_end.resize(missing_end.size() - 2);
    write_bytes(texture / "earth.jpg", missing_end);
    expect(!load_planet_textures(folder.root / "data").images[3], "JPEG without EOI must be rejected");
    missing_end = read_bytes(texture / "sun.jpg");
    missing_end.resize(missing_end.size() - 12);
    write_bytes(texture / "earth.jpg", missing_end);
    expect(!load_planet_textures(folder.root / "data").images[3], "PNG without IEND must be rejected");

    write_image(texture / "earth.jpg", stripes(2050, 1025), CFSTR("public.png"));
    const auto original_large_image = read_bytes(texture / "earth.jpg");
    const auto resized = load_planet_textures(folder.root / "data");
    expect(resized.images[3] && resized.images[3]->width == 1024 && resized.images[3]->height == 512,
        "oversize image must be resized in memory with aspect ratio preserved");
    expect(read_bytes(texture / "earth.jpg") == original_large_image, "resizing must not alter the source file");
    write_image(texture / "earth.jpg", stripes(8, 4), CFSTR("public.jpeg"), 6);
    const auto oriented = load_planet_textures(folder.root / "data");
    expect(oriented.images[3] && oriented.images[3]->width == 4 && oriented.images[3]->height == 8,
        "EXIF orientation must be applied before sampling");

    TemporaryDirectory second_folder;
    const auto fresh = load_planet_textures(second_folder.root / "data");
    expect(fresh.loaded_count() == 0 && fresh.warnings.size() == 11, "data folder change must not reuse earlier textures");
    fs::remove_all(texture);
    fs::create_directory(texture);
    fs::create_directory(texture / "sun.jpg");
    write_image(texture / "earth.png", stripes(8, 4), CFSTR("public.png"));
    write_image(texture / "moon.png", stripes(8, 4), CFSTR("public.png"));
    const auto directory = load_planet_textures(folder.root / "data");
    expect(directory.loaded_count() == 0, "directories and landscape PNG names must not replace planet JPEG files");
}

void integration_tests(const fs::path& data) {
    const auto moon = (data / ".." / "textures" / "moon.jpg").lexically_normal();
    const auto moon_bytes = read_bytes(moon);
    const auto moon_time = fs::last_write_time(moon);
    const auto textures = load_planet_textures(data);
    expect(textures.loaded_count() == 11 && textures.warnings.empty(), "integration data must load all 11 sibling textures");
    expect(textures.images[10] && textures.images[10]->width == 1024 && textures.images[10]->height == 512,
        "existing Moon image must decode into the final slot with its 2:1 aspect ratio");
    for (const auto& image : textures.images) {
        if (!image) continue;
        expect(image->width > 0 && image->width <= 1024 && image->height > 0 && image->height <= 1024,
            "real texture output dimensions exceed bounds");
        expect(image->rgba.size() == image->width * image->height * 4, "real texture byte count mismatch");
    }
    expect(read_bytes(moon) == moon_bytes && fs::last_write_time(moon) == moon_time,
        "integration Moon source bytes or modification time changed");
    std::size_t loaded_layers = 0;
    for (const auto* layer : {&textures.earth_layers.clouds, &textures.earth_layers.night_lights}) {
        if (!*layer) continue;
        ++loaded_layers;
        const auto& image = **layer;
        expect(image.width > 0 && image.height > 0 && image.width <= 1024 && image.height <= 1024
               && image.rgba.size() == image.width * image.height * 4, "real Earth layer dimensions exceed bounds");
    }
    expect(loaded_layers + textures.earth_layers.diagnostics.size() == 2,
           "each local Earth layer is retained or diagnosed");
    expect(textures.atmosphere_emission && textures.atmosphere_emission->path == data / "emmap.dat",
           "atmosphere source identity follows selected data root");
    const auto& emission = *textures.atmosphere_emission;
    if (emission.read_complete) {
        const auto original = read_bytes(emission.path);
        expect(std::string(original.begin(), original.end()) == emission.bytes, "real atmosphere bytes changed");
    }
    std::cout << "real textures: " << textures.loaded_count() << "/11, warnings: " << textures.warnings.size() << '\n';
    std::cout << "Earth layers: " << loaded_layers << "/2; atmosphere bytes: " << emission.bytes.size()
              << "; map: " << bool(emission.map) << "; diagnostics: " << emission.diagnostics.size() << '\n';
    for (const auto& warning : textures.warnings) std::cout << warning << '\n';
}

void earth_layer_tests() {
    TemporaryDirectory folder;
    const auto directory = folder.root / "textures";
    auto result = load_planet_textures(folder.root / "data");
    expect(!result.earth_layers.clouds && !result.earth_layers.night_lights
           && result.earth_layers.diagnostics.size() == 2, "missing Earth layers are diagnosed independently");
    write_image(directory / "earth_cloud.jpg", stripes(16, 8), CFSTR("public.png"));
    write_image(directory / "earth_lights.jpg", stripes(8, 4), CFSTR("public.jpeg"));
    write_image(directory / "earth.jpg", stripes(4, 2), CFSTR("public.png"));
    const auto cloud_bytes = read_bytes(directory / "earth_cloud.jpg");
    const auto lights_bytes = read_bytes(directory / "earth_lights.jpg");
    const auto cloud_time = fs::last_write_time(directory / "earth_cloud.jpg");
    const auto lights_time = fs::last_write_time(directory / "earth_lights.jpg");
    result = load_planet_textures(folder.root / "data");
    expect(result.loaded_count() == 1 && result.earth_layers.clouds && result.earth_layers.night_lights
           && result.earth_layers.diagnostics.empty(), "Earth layers do not alter base-image slot count");
    expect(result.earth_layers.clouds->width == 16 && result.earth_layers.clouds->height == 8
           && result.earth_layers.clouds->rgba[0] > 230, "Earth cloud orientation and small dimensions retained");
    expect(read_bytes(directory / "earth_cloud.jpg") == cloud_bytes
           && read_bytes(directory / "earth_lights.jpg") == lights_bytes
           && fs::last_write_time(directory / "earth_cloud.jpg") == cloud_time
           && fs::last_write_time(directory / "earth_lights.jpg") == lights_time, "Earth layer load preserves original files");
    fs::remove(directory / "earth_cloud.jpg");
    write_bytes(directory / "earth_lights.jpg", {'b', 'r', 'o', 'k', 'e', 'n'});
    result = load_planet_textures(folder.root / "data");
    expect(result.images[3] && !result.earth_layers.clouds && !result.earth_layers.night_lights
           && result.earth_layers.diagnostics.size() == 2, "failed layers do not remove base or reuse prior layer images");
    expect(result.earth_layers.diagnostics[0].find("earth_cloud.jpg") != std::string::npos
           && result.earth_layers.diagnostics[1].find("earth_lights.jpg") != std::string::npos, "layer diagnostics retain file identity");
    write_bytes(directory / "earth_cloud.jpg", cloud_bytes);
    write_bytes(directory / "earth_lights.jpg", lights_bytes);
    result = load_planet_textures(folder.root / "data");
    expect(result.earth_layers.clouds && result.earth_layers.night_lights, "repaired layer assets load on next request");
    TemporaryDirectory other;
    write_image(other.root / "textures" / "earth_cloud.png", stripes(8, 4), CFSTR("public.png"));
    result = load_planet_textures(other.root / "data");
    expect(!result.earth_layers.clouds && !result.earth_layers.night_lights,
           "new data roots and unregistered aliases do not inherit previous layer assets");
}

void atmosphere_asset_tests() {
    TemporaryDirectory folder;
    const auto data = folder.root / "data";
    const auto path = data / "emmap.dat";
    auto result = load_planet_textures(data);
    expect(result.atmosphere_emission && !result.atmosphere_emission->map
           && !result.atmosphere_emission->read_complete
           && !result.atmosphere_emission->diagnostics.empty(), "missing atmosphere map retains diagnostic source");
    write_image(folder.root / "textures" / "earth.jpg", stripes(4, 2), CFSTR("public.png"));
    const std::vector<std::uint8_t> broken{'b', 'r', 'o', 'k', 'e', 'n'};
    write_bytes(path, broken);
    result = load_planet_textures(data);
    expect(result.images[3] && result.atmosphere_emission && !result.atmosphere_emission->map
           && result.atmosphere_emission->read_complete
           && result.atmosphere_emission->bytes == "broken", "invalid atmosphere bytes retained without dropping base");
    // 最小の正しい2×2マップ。値の検証はcore試験、ここは所有と再読込を確認する。
    std::vector<std::uint8_t> bytes(48 + 12 * 4);
    bytes[0] = 2; bytes[4] = 2;
    const double header[] = {6378000, 6442000, 8000, 2.5469e25, 3.141592653589793};
    for (std::size_t item = 0; item < 5; ++item) {
        std::uint64_t bits;
        std::memcpy(&bits, &header[item], sizeof(bits));
        for (std::size_t byte = 0; byte < 8; ++byte)
            bytes[8 + 8 * item + byte] = (bits >> (8 * byte)) & 255;
    }
    write_bytes(path, bytes);
    const auto time = fs::last_write_time(path);
    result = load_planet_textures(data);
    expect(result.atmosphere_emission->map && result.atmosphere_emission->read_complete
           && result.atmosphere_emission->diagnostics.empty()
           && result.atmosphere_emission->map->nodes().size() == 4, "valid replacement atmosphere loads");
    expect(result.atmosphere_emission->bytes == std::string(bytes.begin(), bytes.end())
           && read_bytes(path) == bytes && fs::last_write_time(path) == time, "atmosphere load preserves original bytes/time");
    fs::remove(path);
    result = load_planet_textures(data);
    expect(result.images[3] && !result.atmosphere_emission->map && result.atmosphere_emission->bytes.empty(),
           "removed atmosphere does not reuse old map");
    TemporaryDirectory other;
    result = load_planet_textures(other.root / "data");
    expect(result.atmosphere_emission->path == other.root / "data" / "emmap.dat"
           && !result.atmosphere_emission->map, "atmosphere source changes with data root");
}
} // namespace

int main(int argc, char** argv) {
    try {
        synthetic_tests();
        earth_layer_tests();
        atmosphere_asset_tests();
        if (argc == 2) integration_tests(argv[1]);
        else if (argc != 1) throw std::runtime_error("usage: test_planet_textures [DATA_ROOT]");
        std::cout << "planet texture tests passed\n";
    } catch (const std::exception& error) {
        std::cerr << "planet texture tests failed: " << error.what() << '\n';
        return 1;
    }
}
