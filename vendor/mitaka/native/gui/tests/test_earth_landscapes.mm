#import "HorizonLandscapeRenderer.h"
#include "landscape_geometry.hpp"
#include "landscape_projection.hpp"
#include "sky_model.hpp"
#include <ImageIO/ImageIO.h>
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <limits>
#include <memory>
#include <type_traits>

using namespace mitaka;
using namespace mitaka::gui;
namespace fs = std::filesystem;
namespace {
std::size_t checks = 0;
void expect(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
void near(double actual, double expected, const char* message) {
    expect(std::isfinite(actual) && std::abs(actual - expected) < 1e-10, message);
}
template<class F> void rejects(F action) {
    bool rejected = false;
    try { action(); } catch (const std::invalid_argument&) { rejected = true; }
    expect(rejected, "invalid input must be rejected");
}
struct ReleaseCF { void operator()(const void* value) const { if (value) CFRelease(value); } };
template<class T> using CFPointer = std::unique_ptr<std::remove_pointer_t<T>, ReleaseCF>;
struct TemporaryDirectory {
    fs::path root;
    TemporaryDirectory() {
        std::string pattern = (fs::temp_directory_path() / "mitaka-landscape-XXXXXX").string();
        std::vector<char> writable(pattern.begin(), pattern.end());
        writable.push_back('\0');
        const char* created = mkdtemp(writable.data());
        if (!created) throw std::runtime_error("cannot create landscape fixture directory");
        root = created;
        fs::create_directory(root / "data");
        fs::create_directory(root / "textures");
    }
    ~TemporaryDirectory() { std::error_code error; fs::remove_all(root, error); }
};
PlaceLandscape definition(std::string target = "Planet.Earth", std::string name = "Default",
                          std::string image = "textures/scene.png") {
    return {std::move(target), std::move(name), std::move(image), 1, {0, 0}};
}
ObserverPlaces fixture(std::vector<PlaceLandscape> landscapes) {
    ObserverPlaces result;
    result.sources.push_back({"places_jp.dat", {'x', '\0', '\r', '\n'}, PlaceCatalog{}, {}});
    result.selected_source = 0;
    result.sources[0].catalog->landscapes = std::move(landscapes);
    result.places = {{"Planet.Earth.Local", "local", 499.123456789123, 35.123456789123, "Default", "City"},
                     {"Planet.Earth.Unknown", "unknown", 0, 0, "", "Unknown"},
                     {"Planet.Mars.Local", "mars", 0, 0, "", "City"}};
    result.sources[0].catalog->places = result.places;
    return result;
}
TextureImage gradient() {
    TextureImage result{64, 32, std::vector<std::uint8_t>(64 * 32 * 4, 255)};
    for (std::size_t y = 0; y < result.height; ++y) for (std::size_t x = 0; x < result.width; ++x) {
        const auto offset = (y * result.width + x) * 4;
        result.rgba[offset] = x * 4;
        result.rgba[offset + 1] = y * 8;
        result.rgba[offset + 2] = 0;
    }
    return result;
}
void write_image(const fs::path& path, CFStringRef type = CFSTR("public.png")) {
    const auto pixels = gradient();
    CFPointer<CGColorSpaceRef> space(CGColorSpaceCreateWithName(kCGColorSpaceSRGB));
    CFPointer<CGDataProviderRef> provider(CGDataProviderCreateWithData(nullptr, pixels.rgba.data(), pixels.rgba.size(), nullptr));
    CFPointer<CGImageRef> image(CGImageCreate(pixels.width, pixels.height, 8, 32, pixels.width * 4,
        space.get(), kCGBitmapByteOrder32Big | kCGImageAlphaLast, provider.get(), nullptr, false, kCGRenderingIntentDefault));
    const auto name = path.string();
    CFPointer<CFURLRef> url(CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault,
        reinterpret_cast<const UInt8*>(name.data()), name.size(), false));
    CFPointer<CGImageDestinationRef> destination(CGImageDestinationCreateWithURL(url.get(), type, 1, nullptr));
    expect(bool(image) && bool(destination), "create landscape image fixture");
    CGImageDestinationAddImage(destination.get(), image.get(), nullptr);
    expect(CGImageDestinationFinalize(destination.get()), "write landscape image fixture");
}
std::vector<char> read_bytes(const fs::path& path) {
    std::ifstream input(path, std::ios::binary);
    return {std::istreambuf_iterator<char>(input), std::istreambuf_iterator<char>()};
}
void legacy_image_format_tests() {
    TemporaryDirectory folder;
    const std::array<CFStringRef, 2> types{CFSTR("com.microsoft.bmp"), CFSTR("com.truevision.tga-image")};
    for (std::size_t index = 0; index < types.size(); ++index) {
        // 内容で形式を判定するため、拡張子を意図的に一致させない。
        const auto path = folder.root / "textures" / (std::to_string(index) + ".data");
        write_image(path, types[index]);
        const auto bytes = read_bytes(path);
        const auto modified = fs::last_write_time(path);
        const auto texture = load_local_image(path);
        expect(texture.width == 64 && texture.height == 32, "BMP/TGA dimensions decoded");
        expect(texture.rgba == gradient().rgba, "BMP/TGA ImageIO orientation and RGB preserved");
        expect(read_bytes(path) == bytes && fs::last_write_time(path) == modified, "BMP/TGA source bytes and mtime preserved");
        const auto input = fixture({definition("Planet.Earth", "Default", "textures/" + path.filename().string())});
        const auto model = EarthLandscapes::load(folder.root / "data", input);
        expect(model.image(0) && model.warnings().empty(), "BMP/TGA landscape loads through local boundary");
        for (const auto count : {bytes.size() / 2, std::size_t(12)}) {
            std::ofstream output(path, std::ios::binary | std::ios::trunc);
            output.write(bytes.data(), count);
            output.close();
            bool rejected = false;
            try { (void)load_local_image(path); } catch (const std::runtime_error&) { rejected = true; }
            expect(rejected, index == 0 ? "truncated BMP must not be repaired into an image" :
                "truncated TGA must not be repaired into an image");
        }
    }
}
void legacy_pixel_span_tests() {
    TemporaryDirectory folder;
    const auto path = folder.root / "textures" / "pixels.data";
    const auto write = [&](const std::vector<std::uint8_t>& bytes) {
        std::ofstream output(path, std::ios::binary | std::ios::trunc);
        output.write(reinterpret_cast<const char*>(bytes.data()), bytes.size());
        output.close();
        expect(bool(output), "write legacy pixel fixture");
    };
    const auto reject = [&](const std::vector<std::uint8_t>& bytes) {
        write(bytes);
        bool rejected = false;
        try { (void)load_local_image(path); } catch (const std::runtime_error&) { rejected = true; }
        expect(rejected, "incomplete or overflowing legacy pixels rejected");
    };
    const std::vector<std::uint8_t> expected{255, 0, 0, 255, 0, 255, 0, 255,
                                           0, 0, 255, 255, 255, 255, 255, 255};
    // FooterなしのTGA 1.0、上原点。RLEのrun/raw両packetを使う。
    std::vector<std::uint8_t> tga(18);
    tga[2] = 2; tga[12] = 2; tga[14] = 2; tga[16] = 24; tga[17] = 0x20;
    tga.insert(tga.end(), {0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255});
    write(tga);
    expect(load_local_image(path).rgba == expected, "TGA 1.0 raw pixels and top origin");
    auto rle = tga;
    rle.resize(18); rle[2] = 10;
    rle.insert(rle.end(), {0x80, 0, 0, 255, 1, 0, 255, 0, 255, 0, 0, 0x80, 255, 255, 255});
    write(rle);
    expect(load_local_image(path).rgba == expected, "TGA RLE run and raw packets");
    rle.pop_back(); reject(rle);
    rle.resize(18); rle.insert(rle.end(), {0x84, 0, 0, 255}); reject(rle);
    tga.pop_back(); reject(tga);

    // 24-bit BI_RGB、下原点、各行末2-byte padding。bfSizeを改変しても短い画素領域は拒否する。
    std::vector<std::uint8_t> bmp(54);
    bmp[0] = 'B'; bmp[1] = 'M'; bmp[2] = 70; bmp[10] = 54; bmp[14] = 40;
    bmp[18] = 2; bmp[22] = 2; bmp[26] = 1; bmp[28] = 24;
    bmp.insert(bmp.end(), {255, 0, 0, 255, 255, 255, 0, 0, 0, 0, 255, 0, 255, 0, 0, 0});
    write(bmp);
    expect(load_local_image(path).rgba == expected, "BMP RGB row padding and bottom origin");
    bmp.resize(62); bmp[2] = 62; reject(bmp);
    bmp[10] = 255; reject(bmp);
}
void selection_tests() {
    auto input = fixture({definition("Planet", "Default"), definition(), definition("Planet.Earth", "City"),
        definition("Planet.Mars", "City"), definition("Planet.Earth", "city")});
    const PlaceDisplayModel model(input);
    expect(select_earth_landscape(model, "Planet.Earth.Local") == 2, "selected place uses own exact landscape name");
    for (const auto* id : {"", "unknown", "planet.Earth.Local", "Planet.Mars.Local", "Planet.Earth.Unknown"})
        expect(select_earth_landscape(model, id) == 1, "missing selected landscape uses Earth.Default");
    input.sources[0].catalog->landscapes.erase(input.sources[0].catalog->landscapes.begin() + 1);
    expect(select_earth_landscape(PlaceDisplayModel(input), "") == 0, "missing Earth.Default uses Planet.Default");
    input.sources[0].catalog->landscapes.erase(input.sources[0].catalog->landscapes.begin());
    expect(!select_earth_landscape(PlaceDisplayModel(input), ""), "no generic fallback means no image definition");
    input.sources.push_back({"defaultplaces.dat", {'d'}, PlaceCatalog{}, {}});
    input.sources[1].catalog->landscapes = {definition()};
    expect(!select_earth_landscape(PlaceDisplayModel(input), ""), "fallback never imports unselected data source");
    const auto& place = input.places[0];
    expect(observer_place_matches(place, place.latitude_degrees, std::remainder(place.longitude_degrees, 360)), "raw coordinate match");
    expect(observer_place_matches(place, 35.1234567891, 139.123456789), "UI 12-digit coordinate round trip");
    expect(observer_place_matches(place, 35.12345678910001, 139.123456789), "identical UI 12-digit representation retains site ID");
    expect(!observer_place_matches(place, 35.1234567892, 139.123456789), "different UI latitude must not retain site ID");
    expect(!observer_place_matches(place, 35.1234567891, 139.123456788), "different UI longitude must not retain site ID");
    expect(!observer_place_matches(input.places[2], 0, 0), "non-Earth site cannot match");
    auto seam = place;
    seam.longitude_degrees = 540;
    expect(observer_place_matches(seam, seam.latitude_degrees, -180), "antimeridian signs are equivalent");
    seam.longitude_degrees = -179.9999999999;
    expect(observer_place_matches(seam, seam.latitude_degrees, 180), "rounded antimeridian signs are equivalent");
    seam.latitude_degrees = -0.0;
    seam.longitude_degrees = -0.0;
    expect(observer_place_matches(seam, 0.0, 0.0), "signed zero coordinates are equivalent");
    expect(!observer_place_matches(place, place.latitude_degrees, place.longitude_degrees), "UI out-of-range longitude rejected");
    expect(!observer_place_matches(place, std::numeric_limits<double>::quiet_NaN(), 0), "NaN coordinate rejected");
}
void coordinate_json_tests() {
    for (const double value : {0.093432768199, -0.093432768199, 35.123456789123, 0.0, -0.0, 90.0, -90.0}) {
        const PlaceRecord place{"Planet.Earth.JSON", "JSON", value, value, "Default", "City"};
        // 実際のFoundation JSON経路を使い、doubleをそのまま比較する回帰を防ぐ。
        char text[64];
        std::snprintf(text, sizeof(text), "%.12g", value);
        const double displayed = std::strtod(text, nullptr);
        NSError* error = nil;
        NSData* encoded = [NSJSONSerialization dataWithJSONObject:@{@"latitude": @(displayed), @"longitude": @(displayed)}
            options:0 error:&error];
        expect(encoded && !error, "encode UI coordinates as Foundation JSON");
        NSDictionary* decoded = [NSJSONSerialization JSONObjectWithData:encoded options:0 error:&error];
        expect(decoded && !error, "decode UI coordinates from Foundation JSON");
        const double latitude = [decoded[@"latitude"] doubleValue];
        const double longitude = [decoded[@"longitude"] doubleValue];
        expect(observer_place_matches(place, latitude, longitude), "JSON coordinate round trip retains site ID");
        expect(!observer_place_matches(place, latitude, longitude + 0.000001), "JSON longitude mismatch rejects site ID");
        expect(!observer_place_matches(place, latitude == 90 ? latitude - 0.000001 : latitude + 0.000001, longitude),
            "JSON latitude mismatch rejects site ID");
    }
}
void projection_tests() {
    auto landscape = definition();
    for (const auto& pair : std::array<std::array<double, 2>, 4>{{{0, .5}, {90, .75}, {180, 0}, {270, .25}}})
        near(landscape_image_uv(landscape, {pair[0], 0})[0], pair[1], "cardinal azimuth comes from original compass");
    near(landscape_image_uv(landscape, {0, 90})[1], 0, "zenith uses top image row");
    near(landscape_image_uv(landscape, {0, -90})[1], 1, "nadir uses bottom image row");
    landscape.vertical_scale = .25;
    landscape.offset_arguments = {.125, 25};
    const LandscapeImageMesh mesh(landscape);
    constexpr double radians_to_degrees = 180 / 3.14159265358979323846;
    for (std::size_t row = 1; row + 1 < mesh.rows; ++row) for (std::size_t col = 1; col + 1 < mesh.columns; ++col) {
        const auto& vertex = mesh.vertices()[row * mesh.columns + col];
        const HorizontalCoordinates direction{std::atan2(vertex.position[1], -vertex.position[0]) * radians_to_degrees,
            std::asin(vertex.position[2]) * radians_to_degrees};
        const auto uv = landscape_image_uv(landscape, direction);
        near(uv[0], vertex.uv[0], "ENU transform agrees with original rotated mesh vertex U");
        near(uv[1], 1 - vertex.uv[1], "PNG/JPEG row flip agrees with original mesh vertex V");
    }
    landscape = definition();
    const auto texture = gradient();
    const auto central = render_horizon_landscape(&texture, &landscape, {0, 0, 4}, 1, 1);
    expect(central.rgba == std::vector<std::uint8_t>({126, 124, 0, 255}), "north horizon samples image center");
    const auto east = render_horizon_landscape(&texture, &landscape, {90, 0, 4}, 1, 1);
    expect(east.rgba[0] == 190, "east samples right image quarter");
    landscape.vertical_scale = .25;
    const auto high = render_horizon_landscape(&texture, &landscape, {0, 50, 4}, 1, 1);
    const auto low = render_horizon_landscape(&texture, &landscape, {0, -50, 4}, 1, 1);
    expect(high.rgba[1] == 0 && low.rgba[1] == 248, "vertical texture clamp retains first and last row");
    const auto left = render_horizon_landscape(&texture, &landscape, {180, 0, 4}, 1, 1);
    const auto right = render_horizon_landscape(&texture, &landscape, {179.999, 0, 4}, 1, 1);
    expect(left.rgba[0] == 0 && right.rgba[0] == 252, "horizontal seam clamps each edge without repeat filtering");
    auto alpha = texture;
    std::fill(alpha.rgba.begin(), alpha.rgba.end(), 80);
    expect(render_horizon_landscape(&alpha, &landscape, {}, 1, 1).rgba[3] == 80, "straight image alpha is retained");
    const auto ground = render_horizon_landscape(nullptr, nullptr, {}, 4, 4);
    for (std::size_t y = 0; y < 4; ++y) for (std::size_t x = 0; x < 4; ++x) {
        const auto offset = (y * 4 + x) * 4;
        expect(ground.rgba[offset] == 0 && ground.rgba[offset + 3] == (y < 2 ? 0 : 255), "absent image draws black lower hemisphere");
    }
    const auto moved = render_horizon_landscape(&texture, &landscape, {270, 10, 4}, 17, 13);
    for (std::size_t y : {std::size_t(0), std::size_t(6), std::size_t(12)})
        for (std::size_t x : {std::size_t(0), std::size_t(8), std::size_t(16)}) {
            const double azimuth = 270 + ((x + .5) / 17 - .5) * 90;
            const double altitude = 10 + (.5 - (y + .5) / 13) * 45;
            const auto screen = project_sky({360 - azimuth, altitude}, {90, 10, 4}, 17, 13);
            expect(bool(screen), "pan and zoom sample projects into viewport");
            near(screen->x, x + .5, "landscape horizontal pixels align with HorizonView sky projection");
            near(screen->y, y + .5, "landscape vertical pixels align with HorizonView sky projection");
            const auto uv = landscape_image_uv(landscape, {azimuth, altitude});
            expect(std::abs(moved.rgba[(y * 17 + x) * 4 + 1] - std::clamp(uv[1] * 256 - 4, 0.0, 248.0)) < 1,
                "viewport samples preserve scale and offsets");
        }
    rejects([&] { landscape_image_uv(landscape, {0, 91}); });
    rejects([&] { render_horizon_landscape(&texture, nullptr, {}, 1, 1); });
    rejects([&] { render_horizon_landscape(nullptr, nullptr, {}, 0, 1); });
    rejects([&] { render_horizon_landscape(nullptr, nullptr, {}, 1, 1025); });
    rejects([&] { render_horizon_landscape(nullptr, nullptr, {0, 0, std::numeric_limits<double>::quiet_NaN()}, 1, 1); });
    landscape.vertical_scale = std::numeric_limits<double>::denorm_min();
    rejects([&] { landscape_image_uv(landscape, {0, 0}); });
}
void loader_and_renderer_tests() {
    TemporaryDirectory folder, outside;
    write_image(folder.root / "textures/scene.png");
    write_image(outside.root / "textures/scene.png");
    const auto before = read_bytes(folder.root / "textures/scene.png");
    const auto modified = fs::last_write_time(folder.root / "textures/scene.png");
    auto input = fixture({definition(), definition("Planet.Earth", "City", "textures/missing.png"),
        definition("Planet", "Default", "textures\\scene.png"), definition("Planet.Mars", "City", "../ignore.png"),
        definition("Planet.Earth", "Empty", "")});
    const auto model = std::make_shared<const EarthLandscapes>(EarthLandscapes::load(folder.root / "data/", input));
    expect(model->warnings().size() == 1, "only missing Earth image warns; non-Earth and empty definitions remain untouched");
    expect(model->image(0) && model->image(0) == model->image(2), "canonical same image is loaded once");
    expect(model->image(0)->rgba == gradient().rgba, "ImageIO keeps top-left source pixel orientation");
    expect(model->selection("Planet.Earth.Local") == 1 && !model->image(1), "broken selected image cannot fall back to another landscape");
    expect(model->definitions().observer_places().sources[0].bytes == input.sources[0].bytes, "all original bytes retained through image loading");
    expect(before == read_bytes(folder.root / "textures/scene.png") && modified == fs::last_write_time(folder.root / "textures/scene.png"), "local image never rewritten");
    fs::create_symlink(outside.root / "textures/scene.png", folder.root / "textures/escape.png");
    input.sources[0].catalog->landscapes = {
        definition("Planet.Earth", "Absolute", (outside.root / "textures/scene.png").string()),
        definition("Planet.Earth", "Link", "textures/escape.png"),
        definition("Planet.Earth", "Nul", std::string("textures/scene.png\0ignored", 26)),
        definition("Planet.Earth", "Drive", "C:\\scene.png"),
        definition("Planet.Earth", "Parent", "../scene.png")};
    const auto guarded = EarthLandscapes::load(folder.root / "data", input);
    expect(guarded.warnings().size() == 5, "external, symlink escape, NUL, drive, parent paths rejected");
    write_image(folder.root / "textures/ソラ.png");
    input.sources[0].catalog->landscapes = {definition("Planet.Earth", "CP932", std::string("textures/\x83\x5c\x83\x89.png"))};
    const auto cp932 = EarthLandscapes::load(folder.root / "data", input);
    expect(cp932.warnings().empty() && cp932.image(0), "CP932 trail-byte backslash is decoded before separators");

    HorizonLandscapeRenderer *renderer = [[HorizonLandscapeRenderer alloc] init];
    expect(renderer.showsLandscapeImage && !renderer.hasModel, "renderer defaults to image enabled without model");
    [renderer setModel:model];
    const std::size_t width = 64, height = 32;
    std::vector<std::uint8_t> rendered(width * height * 4, 255);
    CFPointer<CGColorSpaceRef> color(CGColorSpaceCreateWithName(kCGColorSpaceSRGB));
    CFPointer<CGContextRef> context(CGBitmapContextCreate(rendered.data(), width, height, 8, width * 4, color.get(),
        kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast));
    expect(bool(context), "create offscreen landscape context");
    CGContextTranslateCTM(context.get(), 0, height);
    CGContextScaleCTM(context.get(), 1, -1);
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithCGContext:context.get() flipped:YES];
    const auto draw = [&] {
        std::fill(rendered.begin(), rendered.end(), 255);
        [renderer drawInRect:NSMakeRect(0, 0, width, height) viewport:HorizonViewport{} quality:RendererDisplayOptions{}];
    };
    draw();
    const auto expected = render_horizon_landscape(model->image(0), &model->definitions().landscapes()[0].definition, {}, width, height);
    expect(rendered == expected.rgba, "AppKit compositing preserves top-left projected pixels");
    const auto first = rendered;
    draw();
    expect(rendered == first, "cached image draw remains stable");
    [renderer setObserverPlaceIdentifier:std::string("Planet.Earth.Local")];
    draw();
    expect(rendered[0] == 255 && rendered[(height - 1) * width * 4] == 0, "missing selected image draws transparent sky and black ground");
    expect([renderer observerPlaceIdentifier] == "Planet.Earth.Local", "selected identifier retained");
    [renderer setObserverPlaceIdentifier:std::string{}];
    renderer.showsLandscapeImage = NO;
    draw();
    expect(rendered[0] == 255 && rendered[(height - 1) * width * 4] == 0, "visibility toggle replaces image with original black ground");
    renderer.showsLandscapeImage = YES;
    draw();
    expect(rendered == first, "reenabling image invalidates projection cache");
    [NSGraphicsContext restoreGraphicsState];
}
void local_tests(const fs::path& data) {
    const auto places = load_observer_places(data);
    const auto model = EarthLandscapes::load(data, places);
    expect(model.definitions().observer_places().source_place_count == places.source_place_count, "local row count preserved");
    for (const auto& source : model.definitions().observer_places().sources)
        expect(read_bytes(source.path) == source.bytes, "all selected and unselected local bytes retained");
    const auto selected = model.selection("");
    const auto earth_default = model.definitions().find_landscape("Planet.Earth.Default");
    const auto generic_default = model.definitions().find_landscape("Planet.Default");
    expect(selected == (earth_default ? earth_default : generic_default), "local fallback uses only selected source definitions");
    for (std::size_t index = 0; index < model.definitions().landscapes().size(); ++index) {
        const auto& entry = model.definitions().landscapes()[index];
        if (entry.definition.target_name == "Planet.Earth" && !entry.definition.image_path_bytes.empty())
            expect(model.image(index), "local Earth landscape image loads");
    }
    for (const auto& place : places.places) {
        if (!observer_place_is_earth(place)) continue;
        const auto index = model.selection(place.target_name);
        const auto named = model.definitions().find_landscape("Planet.Earth." + place.landscape);
        expect(index == (named ? named : selected), "local Earth site preserves exact landscape choice or default absence");
        expect(observer_place_matches(place, place.latitude_degrees, std::remainder(place.longitude_degrees, 360)), "original Earth coordinates retain identity");
    }
    std::cout << "Local landscapes: " << data << ", definitions=" << model.definitions().landscapes().size()
              << ", warnings=" << model.warnings().size() << '\n';
    for (const auto& warning : model.warnings()) std::cout << warning << '\n';
}
}
int main(int argc, char** argv) {
    @autoreleasepool {
        try {
            selection_tests();
            coordinate_json_tests();
            projection_tests();
            legacy_image_format_tests();
            legacy_pixel_span_tests();
            loader_and_renderer_tests();
            for (int index = 1; index < argc; ++index) local_tests(argv[index]);
            std::cout << "Earth landscape checks passed: " << checks << '\n';
        } catch (const std::exception& error) {
            std::cerr << error.what() << '\n';
            return 1;
        }
    }
}
