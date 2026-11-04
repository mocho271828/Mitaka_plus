#include "sky_background.hpp"

#include <CoreGraphics/CoreGraphics.h>
#include <ImageIO/ImageIO.h>
#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <limits>
#include <memory>
#include <stdexcept>
#include <type_traits>

using namespace mitaka;
using namespace mitaka::gui;
namespace fs = std::filesystem;

namespace {
void expect(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}
void near(double actual, double expected, double tolerance, const char* message) {
    expect(std::isfinite(actual) && std::abs(actual - expected) <= tolerance, message);
}
template<class Callable> void rejects(Callable action) {
    bool rejected = false;
    try { action(); } catch (const std::invalid_argument&) { rejected = true; }
    expect(rejected, "invalid background input must be rejected");
}
struct ReleaseCF { void operator()(const void* value) const { if (value) CFRelease(value); } };
template<class T> using CFPointer = std::unique_ptr<std::remove_pointer_t<T>, ReleaseCF>;

struct TemporaryDirectory {
    fs::path root;
    TemporaryDirectory() {
        std::string pattern = (fs::temp_directory_path() / "mitaka-background-XXXXXX").string();
        std::vector<char> writable(pattern.begin(), pattern.end());
        writable.push_back('\0');
        const char* created = mkdtemp(writable.data());
        if (!created) throw std::runtime_error("cannot create temporary background directory");
        root = created;
        fs::create_directory(root / "data");
        fs::create_directory(root / "textures");
    }
    ~TemporaryDirectory() { std::error_code error; fs::remove_all(root, error); }
};

TextureImage gradient() {
    TextureImage image{64, 32, std::vector<std::uint8_t>(64 * 32 * 4, 255)};
    for (std::size_t y = 0; y < image.height; ++y)
        for (std::size_t x = 0; x < image.width; ++x) {
            const auto offset = (y * image.width + x) * 4;
            image.rgba[offset] = static_cast<std::uint8_t>(4 * x);
            image.rgba[offset + 1] = static_cast<std::uint8_t>(8 * y);
            image.rgba[offset + 2] = 0;
        }
    return image;
}
void write_image(const fs::path& path, CFStringRef type) {
    const auto pixels = gradient();
    CFPointer<CGColorSpaceRef> space(CGColorSpaceCreateWithName(kCGColorSpaceSRGB));
    CFPointer<CGDataProviderRef> provider(CGDataProviderCreateWithData(nullptr, pixels.rgba.data(), pixels.rgba.size(), nullptr));
    CFPointer<CGImageRef> image(CGImageCreate(pixels.width, pixels.height, 8, 32, pixels.width * 4,
        space.get(), kCGBitmapByteOrder32Big | kCGImageAlphaLast, provider.get(), nullptr, false, kCGRenderingIntentDefault));
    const auto name = path.string();
    CFPointer<CFURLRef> url(CFURLCreateFromFileSystemRepresentation(kCFAllocatorDefault,
        reinterpret_cast<const UInt8*>(name.data()), name.size(), false));
    CFPointer<CGImageDestinationRef> destination(CGImageDestinationCreateWithURL(url.get(), type, 1, nullptr));
    expect(image && destination, "cannot create background image fixture");
    CGImageDestinationAddImage(destination.get(), image.get(), nullptr);
    expect(CGImageDestinationFinalize(destination.get()), "cannot finalize background image fixture");
}
std::vector<char> read_bytes(const fs::path& path) {
    std::ifstream input(path, std::ios::binary);
    return {std::istreambuf_iterator<char>(input), std::istreambuf_iterator<char>()};
}

void mapping_tests() {
    const EquatorialCoordinates center{266.41682625, -29.007796944444443};
    const EquatorialCoordinates north{192.85, 27.133333333333333};
    const auto center_uv = sky_background_uv(center);
    near(center_uv.x, 0.5, 1e-12, "image center must point at the official Galactic center");
    near(center_uv.y, 0.5, 1e-12, "Galactic center must be on the texture equator");
    near(sky_background_uv(north).y, 0, 1e-12, "top row must point at the official Galactic north");
    near(sky_background_uv({12.85, -27.133333333333333}).y, 1, 1e-12, "bottom row must point at Galactic south");
    const auto center_coordinates = sky_background_coordinates({0.5, 0.5});
    near(center_coordinates.right_ascension_deg, center.right_ascension_deg, 1e-10, "forward center RA mismatch");
    near(center_coordinates.declination_deg, center.declination_deg, 1e-10, "forward center DEC mismatch");
    near(sky_background_coordinates({0.1, 0}).right_ascension_deg, north.right_ascension_deg, 1e-10, "forward pole RA mismatch");

    const auto gc = equatorial_direction(center), gn = equatorial_direction(north);
    const Vec3 east{gn.y * gc.z - gn.z * gc.y, gn.z * gc.x - gn.x * gc.z, gn.x * gc.y - gn.y * gc.x};
    near(sky_background_uv(equatorial_coordinates(east)).x, 0.25, 1e-12, "left quarter must point at positive Galactic y");
    near(sky_background_uv(equatorial_coordinates({-east.x, -east.y, -east.z})).x, 0.75, 1e-12,
         "right quarter must point at negative Galactic y");
    const auto opposite = sky_background_uv({86.41682625, 29.007796944444443});
    expect(opposite.x < 1e-12 || opposite.x > 1 - 1e-12, "opposite center must lie on the horizontal seam");
    for (double u : {0.001, 0.2, 0.4, 0.6, 0.9, 0.999}) {
        for (double v : {0.01, 0.25, 0.5, 0.8, 0.99}) {
            const auto uv = sky_background_uv(sky_background_coordinates({u, v}));
            near(uv.x, u, 1e-12, "UV round trip must use the inverse of the nonorthogonal official basis");
            near(uv.y, v, 1e-12, "latitude round trip mismatch");
        }
    }
    const auto texture = gradient();
    const auto central = render_sky_background(texture, {center.right_ascension_deg, center.declination_deg, 10}, 9, 9);
    const auto offset = (4 * 9 + 4) * 4;
    expect(central.rgba[offset] == 126 && central.rgba[offset + 1] == 124, "rendered center must not be rotated or flipped");
    const auto pole = render_sky_background(texture, {north.right_ascension_deg, north.declination_deg, 10}, 1, 1);
    expect(pole.rgba[1] == 0, "rendered north must sample the top row");
    const auto eastern = equatorial_coordinates(east);
    const auto quarter = render_sky_background(texture, {eastern.right_ascension_deg, eastern.declination_deg, 10}, 1, 1);
    expect(quarter.rgba[0] == 62 && quarter.rgba[1] == 124, "rendered quarter must retain image handedness");

    const SkyViewport viewport{center.right_ascension_deg, center.declination_deg, 4};
    const auto projected = render_sky_background(texture, viewport, 17, 13);
    for (std::size_t y : {std::size_t(0), std::size_t(6), std::size_t(12)}) {
        for (std::size_t x : {std::size_t(0), std::size_t(8), std::size_t(16)}) {
            const EquatorialCoordinates q{viewport.center_ra_deg + (0.5 - (x + 0.5) / 17) * 90,
                                          viewport.center_dec_deg + (0.5 - (y + 0.5) / 13) * 45};
            const auto point = project_sky(q, viewport, 17, 13);
            expect(point.has_value(), "sample coordinate must project inside viewport");
            near(point->x, x + 0.5, 1e-12, "background and stars must share horizontal projection");
            near(point->y, y + 0.5, 1e-12, "background and stars must share vertical projection");
            const auto uv = sky_background_uv(q);
            near(projected.rgba[(y * 17 + x) * 4], uv.x * 256 - 2, 1, "background horizontal sampling mismatch");
            near(projected.rgba[(y * 17 + x) * 4 + 1], std::clamp(uv.y * 256 - 4, 0.0, 248.0), 1,
                 "background vertical sampling mismatch");
        }
    }
    rejects([&] { render_sky_background(texture, {}, 0, 1); });
    rejects([&] { render_sky_background(texture, {}, 1025, 1); });
    rejects([&] { render_sky_background({}, {}, 1, 1); });
    rejects([&] { render_sky_background(texture, {0, 0, std::numeric_limits<double>::quiet_NaN()}, 1, 1); });
    rejects([] { sky_background_coordinates({0, -0.1}); });
    rejects([] { sky_background_uv({0, 91}); });
    rejects([] { SkyBackgrounds{}.image(static_cast<MilkyWayMode>(99)); });
}

void loader_tests() {
    TemporaryDirectory folder;
    const auto data = folder.root / "data", textures = folder.root / "textures";
    const auto empty = load_sky_backgrounds(data);
    expect(empty.loaded_count() == 0 && empty.warnings.size() == 3, "missing backgrounds need three independent warnings");
    expect(!empty.image(MilkyWayMode::none), "None must not select an image");
    write_image(textures / "milkyway.jpg", CFSTR("public.jpeg"));
    write_image(textures / "milkyway2.jpg", CFSTR("public.png"));
    write_image(textures / "MilkyWay_IR.jpg", CFSTR("public.jpeg"));
    const auto original = read_bytes(textures / "milkyway.jpg");
    const auto modified = fs::last_write_time(textures / "milkyway.jpg");
    const auto complete = load_sky_backgrounds(data);
    expect(complete.loaded_count() == 3 && complete.warnings.empty(), "all local background variants should load");
    expect(complete.image(MilkyWayMode::normal) == &*complete.images[0]
        && complete.image(MilkyWayMode::bright) == &*complete.images[1]
        && complete.image(MilkyWayMode::infrared) == &*complete.images[2], "mode slots must remain stable");
    expect(complete.images[1]->rgba[0] == 0 && complete.images[1]->rgba[1] == 0,
           "decoded texture must keep the top-left corner");
    expect(complete.images[1]->rgba[(31 * 64) * 4 + 1] == 248, "decoded texture must keep the bottom row");
    expect(read_bytes(textures / "milkyway.jpg") == original && fs::last_write_time(textures / "milkyway.jpg") == modified,
           "source bytes and modification time must be preserved");
    fs::remove(textures / "milkyway2.jpg");
    std::ofstream(textures / "MilkyWay_IR.jpg", std::ios::binary | std::ios::trunc) << "broken";
    const auto partial = load_sky_backgrounds(data);
    expect(partial.loaded_count() == 1 && partial.warnings.size() == 2, "partial failure must preserve only the valid current image");
    expect(!partial.image(MilkyWayMode::bright) && !partial.image(MilkyWayMode::infrared), "missing modes must never use a different variant");
    fs::remove(textures / "MilkyWay_IR.jpg");
    write_image(textures / "milkyway_IR.jpg", CFSTR("public.png"));
    const auto lowercase = load_sky_backgrounds(data);
    expect(lowercase.images[2].has_value(), "official lowercase infrared name must be supported");
    auto truncated = original;
    truncated.resize(truncated.size() - 2);
    std::ofstream broken(textures / "milkyway.jpg", std::ios::binary | std::ios::trunc);
    broken.write(truncated.data(), static_cast<std::streamsize>(truncated.size()));
    broken.close();
    const auto damaged = load_sky_backgrounds(data);
    expect(!damaged.images[0] && damaged.images[2], "missing JPEG terminator must fail only its own variant");
    TemporaryDirectory other;
    expect(load_sky_backgrounds(other.root / "data").loaded_count() == 0, "data reload must not retain earlier images");
}

void horizon_mapping_tests() {
    const auto texture = gradient();
    const EquatorialCoordinates center{266.41682625, -29.007796944444443};
    const EquatorialCoordinates north{192.85, 27.133333333333333};
    const auto gc = equatorial_direction(center), gn = equatorial_direction(north);
    const auto east = equatorial_coordinates({gn.y * gc.z - gn.z * gc.y,
        gn.z * gc.x - gn.x * gc.z, gn.x * gc.y - gn.y * gc.x});
    const std::array<EquatorialCoordinates, 4> axes{{center, east, north, {12.85, -27.133333333333333}}};
    // 既知の銀河軸を逆方向（赤道→地平）から配置する。画像関数同士の一致だけに依存しない。
    for (const auto site : {ObserverSite{35.68, 139.76}, ObserverSite{-33.86, 151.21},
                            ObserverSite{90, 0}, ObserverSite{-90, -180}}) {
        for (double jd : {2451545.0, 2460000.25}) {
            const ObservationFrame frame(site, jd);
            for (std::size_t index = 0; index < axes.size(); ++index) {
                const auto horizontal = frame.to_horizontal(axes[index]);
                expect(std::abs(horizontal.altitude_deg) < 89.5, "axis fixture must fit at native maximum zoom");
                const auto point = render_horizon_background(texture,
                    {horizontal.azimuth_deg, horizontal.altitude_deg, 180}, frame, 1, 1);
                const std::array<int, 4> expected_green{{124, 124, 0, 248}};
                near(point.rgba[1], expected_green[index], 1, "horizon Galactic axis latitude is inverted or shifted");
                if (index < 2) near(point.rgba[0], index == 0 ? 126 : 62, 1, "horizon Galactic axis handedness mismatch");
            }
            const auto first = render_horizon_background(texture, {0, 0, 1}, frame, 31, 17);
            const auto wrapped = render_horizon_background(texture, {720, 0, 1}, frame, 31, 17);
            expect(first.rgba == wrapped.rgba, "azimuth 0/360 seam must be periodic at both observer poles");
            for (double altitude : {-90.0, 90.0}) {
                const auto vertical = render_horizon_background(texture, {0, altitude, 180}, frame, 9, 9);
                expect(vertical.rgba.size() == 9 * 9 * 4, "zenith/nadir edge viewport must remain finite");
            }
        }
    }
    const ObservationFrame frame({35.68, 139.76}, 2451545);
    const HorizonViewport viewport{2, 20, 4};
    const auto rendered = render_horizon_background(texture, viewport, frame, 17, 13);
    for (std::size_t y = 0; y < rendered.height; ++y) {
        for (std::size_t x = 0; x < rendered.width; ++x) {
            const HorizontalCoordinates horizontal{
                viewport.center_azimuth_deg + ((x + 0.5) / rendered.width - 0.5) * 360 / viewport.zoom,
                viewport.center_altitude_deg + (0.5 - (y + 0.5) / rendered.height) * 180 / viewport.zoom};
            const auto projected = project_sky({360 - horizontal.azimuth_deg, horizontal.altitude_deg},
                {360 - viewport.center_azimuth_deg, viewport.center_altitude_deg, viewport.zoom}, 17, 13);
            expect(projected.has_value(), "background direction must be in the same horizon star viewport");
            near(projected->x, x + 0.5, 1e-10, "background azimuth must increase rightwards");
            near(projected->y, y + 0.5, 1e-10, "background altitude must increase upwards");
            const auto uv = sky_background_uv(frame.to_equatorial(horizontal));
            if (uv.x > 1.0 / 64 && uv.x < 63.0 / 64)
                near(rendered.rgba[(y * 17 + x) * 4], uv.x * 256 - 2, 1, "horizon horizontal bilinear sample mismatch");
            near(rendered.rgba[(y * 17 + x) * 4 + 1], std::clamp(uv.y * 256 - 4, 0.0, 248.0), 1,
                "horizon vertical bilinear sample mismatch");
        }
    }
    const auto at_center = frame.to_horizontal(center);
    const HorizonViewport centered{at_center.azimuth_deg, at_center.altitude_deg, 180};
    const auto alpha = render_horizon_background({2, 1, {80, 120, 160, 255, 255, 0, 0, 0}}, centered, frame, 1, 1);
    expect(alpha.rgba[0] == 80 && alpha.rgba[1] == 120 && alpha.rgba[2] == 160,
        "transparent texture colors must not contaminate horizon interpolation");
    near(alpha.rgba[3], 128, 1, "horizon interpolation must retain weighted alpha");
    const auto opposite = frame.to_horizontal({86.41682625, 29.007796944444443});
    const auto seam = render_horizon_background(texture, {opposite.azimuth_deg, opposite.altitude_deg, 180}, frame, 1, 1);
    near(seam.rgba[0], 126, 1, "Galactic seam must blend the last and first texture columns");
    const auto max_size = render_horizon_background({1, 1, {1, 2, 3, 255}}, {}, frame, 1024, 1024);
    expect(max_size.rgba.size() == 1024 * 1024 * 4 && max_size.rgba.back() == 255,
        "inclusive horizon dimension limit failed");
    const double nan = std::numeric_limits<double>::quiet_NaN();
    for (auto dimensions : {std::pair<std::size_t, std::size_t>{0, 1}, {1, 0}, {1025, 1}, {1, 1025}})
        rejects([&] { render_horizon_background(texture, {}, frame, dimensions.first, dimensions.second); });
    for (auto invalid : {HorizonViewport{nan, 0, 1}, {0, nan, 1}, {0, 0, nan}, {0, 0, 0}, {0, 0, -1}})
        rejects([&] { render_horizon_background(texture, invalid, frame, 1, 1); });
    for (auto invalid : {TextureImage{}, TextureImage{1, 1, {1, 2, 3}}, TextureImage{1025, 1, {}}})
        rejects([&] { render_horizon_background(invalid, {}, frame, 1, 1); });
    expect(render_horizon_background(texture, {725, 90, 0.5}, frame, 11, 7).rgba
        == render_horizon_background(texture, {5, 0, 1}, frame, 11, 7).rgba,
        "horizon viewport normalization must match the view's native bounds");
}

void local_tests(const fs::path& data) {
    const auto backgrounds = load_sky_backgrounds(data);
    // Regular原本にはIRのみ、Plus原本には3枚。各原本の現在の状態をそのまま報告する。
    expect(backgrounds.images[2].has_value(), "local integration data must include the verified infrared image");
    expect(backgrounds.loaded_count() + backgrounds.warnings.size() == 3, "each variant must be loaded or explain its failure");
    for (const auto& image : backgrounds.images) {
        if (!image) continue;
        expect(image->width == 1024 && image->height == 512, "verified local images must preserve their known dimensions");
        const auto rendered = render_sky_background(*image, {}, 1024, 512);
        expect(rendered.rgba.size() == 1024 * 512 * 4, "local background output size mismatch");
        const auto horizon = render_horizon_background(*image, {}, ObservationFrame({35.68, 139.76}, 2451545), 1024, 512);
        expect(horizon.rgba.size() == rendered.rgba.size() && horizon.rgba != rendered.rgba,
            "local horizon background must use the observer frame");
    }
    std::cout << "local backgrounds: " << backgrounds.loaded_count() << "/3; warnings: " << backgrounds.warnings.size() << '\n';
    for (const auto& warning : backgrounds.warnings) std::cout << warning << '\n';
}
} // namespace

int main(int argc, char** argv) {
    try {
        mapping_tests();
        loader_tests();
        horizon_mapping_tests();
        if (argc == 2) local_tests(argv[1]);
        else if (argc != 1) throw std::runtime_error("usage: test_sky_background [DATA_ROOT]");
        std::cout << "sky background tests passed\n";
    } catch (const std::exception& error) {
        std::cerr << "sky background tests failed: " << error.what() << '\n';
        return 1;
    }
}
