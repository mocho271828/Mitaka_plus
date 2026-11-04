#import "SkyView.h"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka::gui;

static void check(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}

static NSBitmapImageRep *snapshot(SkyView *view) {
    NSBitmapImageRep *image = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:image];
    return image;
}

static NSColor *backgroundSample(SkyView *view) {
    const NSRect map = NSInsetRect(view.bounds, 42, 34);
    NSBitmapImageRep *image = snapshot(view);
    check(image != nil, "background snapshot failed");
    const NSInteger x = (map.origin.x + map.size.width * 0.31) / view.bounds.size.width * image.pixelsWide;
    const NSInteger y = (map.origin.y + map.size.height * 0.36) / view.bounds.size.height * image.pixelsHigh;
    return [[image colorAtX:x y:y] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
}

static void backgroundTests() {
    SkyView *view = [[SkyView alloc] initWithFrame:NSMakeRect(0, 0, 600, 400)];
    auto backgrounds = std::make_shared<SkyBackgrounds>();
    backgrounds->images[0] = TextureImage{1, 1, {96, 0, 0, 255}};
    backgrounds->images[1] = TextureImage{1, 1, {0, 96, 0, 255}};
    backgrounds->images[2] = TextureImage{1, 1, {0, 0, 96, 255}};
    [view setSkyBackgrounds:backgrounds];
    const NSColor *empty = backgroundSample(view);
    view.milkyWayMode = MilkyWayMode::normal;
    const NSColor *normal = backgroundSample(view);
    check(normal.redComponent > empty.redComponent + 0.2, "Normal background is missing");
    view.milkyWayMode = MilkyWayMode::bright;
    const NSColor *bright = backgroundSample(view);
    check(bright.greenComponent > empty.greenComponent + 0.2 && bright.redComponent < normal.redComponent - 0.2,
          "switching to Bright must discard the prior rendered image");
    view.milkyWayMode = MilkyWayMode::infrared;
    check(backgroundSample(view).blueComponent > empty.blueComponent + 0.2, "Infrared background is missing");
    view.milkyWayMode = MilkyWayMode::none;
    check(std::abs(backgroundSample(view).blueComponent - empty.blueComponent) < 0.01, "None must hide the image");
    view.milkyWayMode = MilkyWayMode::normal;
    [view setSkyBackgrounds:std::make_shared<SkyBackgrounds>()];
    check(std::abs(backgroundSample(view).redComponent - empty.redComponent) < 0.01,
          "data reload with missing images must not retain the old background");

    // グラデーションでNSImageの上下と、viewport/size変更時のcache無効化を確認する。
    TextureImage gradient{64, 32, std::vector<std::uint8_t>(64 * 32 * 4, 255)};
    for (std::size_t y = 0; y < gradient.height; ++y)
        for (std::size_t x = 0; x < gradient.width; ++x) {
            const auto offset = (y * gradient.width + x) * 4;
            gradient.rgba[offset] = static_cast<std::uint8_t>(x * 3);
            gradient.rgba[offset + 1] = static_cast<std::uint8_t>(y * 6);
            gradient.rgba[offset + 2] = 0;
        }
    backgrounds = std::make_shared<SkyBackgrounds>();
    backgrounds->images[0] = gradient;
    [view setSkyBackgrounds:backgrounds];
    for (SkyViewport viewport : {SkyViewport{266.4, -29, 4}, SkyViewport{120, 20, 8}}) {
        [view setViewport:viewport];
        const auto expected = render_sky_background(gradient,
            {viewport.center_ra_deg + (0.5 - 0.31) * 360 / viewport.zoom,
             viewport.center_dec_deg + (0.5 - 0.36) * 180 / viewport.zoom, 180}, 1, 1);
        const NSColor *actual = backgroundSample(view);
        check(std::abs(actual.redComponent - empty.redComponent - expected.rgba[0] / 255.0) < 0.04
            && std::abs(actual.greenComponent - empty.greenComponent - expected.rgba[1] / 255.0) < 0.04,
            "background view is inverted, rotated, or reusing the old viewport");
        view.frame = NSMakeRect(0, 0, 800, 500);
        const NSColor *resized = backgroundSample(view);
        check(std::abs(resized.redComponent - actual.redComponent) < 0.04
            && std::abs(resized.greenComponent - actual.greenComponent) < 0.04, "resizing must preserve the sky direction");
    }
}

int main(int argc, char **argv) {
    @autoreleasepool {
        try {
            check(argc == 2, "usage: test_sky_view DATA_ROOT");
            [NSApplication sharedApplication];
            backgroundTests();
            const auto model = std::make_shared<const SkyModel>(SkyModel::load(argv[1]));
            SkyView *view = [[SkyView alloc] initWithFrame:NSMakeRect(0, 0, 1024, 512)];
            [view setModel:model bodies:model->bodies(2451545)];
            [view zoomIn];
            check([view viewport].zoom > 1, "zoom action failed");
            check([view selectStarHIP:model->stars()[0].hip], "HIP selection failed");
            [view focusSelection];
            check([view viewport].zoom >= 4, "focus action failed");
            check(![view selectStarHIP:-99999], "unknown HIP accepted");
            const auto faint = std::max_element(model->stars().begin(), model->stars().end(),
                [](const auto& left, const auto& right) { return left.apparent_v_magnitude < right.apparent_v_magnitude; });
            view.magnitudeLimit = 3;
            check([view selectStarHIP:faint->hip] && view.magnitudeLimit >= faint->apparent_v_magnitude,
                  "selecting a faint star must expand the magnitude limit");
            const double validLimit = view.magnitudeLimit;
            for (double invalid : {std::numeric_limits<double>::infinity(),
                                   -std::numeric_limits<double>::infinity(),
                                   std::numeric_limits<double>::quiet_NaN()}) {
                bool rejected = false;
                try { view.magnitudeLimit = invalid; }
                catch (const std::invalid_argument&) { rejected = true; }
                check(rejected && view.magnitudeLimit == validLimit,
                      "nonfinite magnitude limit must be rejected without changing the view");
            }
            [view resetView];
            check([view viewport].zoom == 1, "reset action failed");

            auto catalogs = std::make_shared<ExtendedCatalogs>();
            catalogs->galaxies.push_back({{90, 30}, 1e6, 0.2});
            catalogs->quasars.push_back({{270, -30}, 2e6, 1.5});
            catalogs->ngc.push_back({42, true, {90, 20}, mitaka::DeepSkyKind::emission_or_reflection_nebula, 15, 4, false});
            [view setExtendedCatalogs:catalogs];
            view.showsGalaxies = YES;
            NSBitmapImageRep *image = snapshot(view);
            check(image != nil, "sky snapshot failed");
            const NSRect map = NSInsetRect(view.bounds, 42, 34);
            const auto galaxy = *project_sky({90, 30}, {}, map.size.width, map.size.height);
            const NSInteger x = static_cast<NSInteger>((map.origin.x + galaxy.x) / view.bounds.size.width * image.pixelsWide);
            const NSInteger y = static_cast<NSInteger>((map.origin.y + galaxy.y) / view.bounds.size.height * image.pixelsHigh);
            bool orange = false;
            for (NSInteger dy = -3; dy <= 3; ++dy) for (NSInteger dx = -3; dx <= 3; ++dx) {
                NSColor *color = [[image colorAtX:x + dx y:y + dy] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
                orange = orange || color.redComponent > color.blueComponent + 0.1;
            }
            check(orange, "galaxy density image is missing or vertically inverted");
            check([view selectDeepSkyKind:SkyCatalogKind::quasar index:0], "quasar selection failed");
            [view focusSelection];
            check(view.showsQuasars && std::abs([view viewport].center_ra_deg - 270) < 1e-8,
                  "quasar focus must use catalog coordinates and enable its layer");
            check(![view selectDeepSkyKind:SkyCatalogKind::nebula index:10], "out-of-range catalog selection accepted");
            check(![view selectDeepSkyKind:static_cast<SkyCatalogKind>(99) index:0], "invalid catalog kind accepted");
            view.showsConstellationLines = YES;
            view.showsConstellationBoundaries = YES;
            view.showsConstellationNames = YES;
            check(snapshot(view) != nil, "zoomed constellation rendering failed");
            std::cout << "sky view integration tests passed\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << error.what() << '\n';
            return 1;
        }
    }
}
