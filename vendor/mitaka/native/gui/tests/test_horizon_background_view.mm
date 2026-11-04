#import "HorizonView.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <iostream>
#include <limits>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;

namespace {
unsigned checks = 0;
void check(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class Action> void rejects(Action action) {
    bool rejected = false;
    try { action(); } catch (const std::invalid_argument&) { rejected = true; }
    check(rejected, "invalid horizon background state must be rejected");
}
NSBitmapImageRep* snapshot(HorizonView* view) {
    const NSInteger width = std::ceil(view.bounds.size.width), height = std::ceil(view.bounds.size.height);
    NSBitmapImageRep* bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr
        pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES
        isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:0
        bytesPerRow:width * 4 bitsPerPixel:32];
    bitmap = [bitmap bitmapImageRepByRetaggingWithColorSpace:NSColorSpace.sRGBColorSpace];
    check(bitmap != nil, "cannot allocate horizon bitmap");
    NSGraphicsContext* context = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    check(context != nil, "cannot allocate horizon bitmap context");
    [NSGraphicsContext saveGraphicsState];
    // WindowServer の画面 profile に依存させず、固定 sRGB の反転 canvas に実 drawRect を描く。
    CGContextTranslateCTM(context.CGContext, 0, height);
    CGContextScaleCTM(context.CGContext, 1, -1);
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithCGContext:context.CGContext flipped:YES];
    @try { [view drawRect:view.bounds]; }
    @finally { [NSGraphicsContext restoreGraphicsState]; }
    return bitmap;
}
NSColor* color(NSBitmapImageRep* bitmap, NSView* view, double x, double y) {
    const auto column = static_cast<NSInteger>(x / view.bounds.size.width * bitmap.pixelsWide);
    const auto row = static_cast<NSInteger>(y / view.bounds.size.height * bitmap.pixelsHigh);
    const auto* pixel = bitmap.bitmapData + row * bitmap.bytesPerRow + column * 4;
    // 固定 sRGB canvas の byte を検査する。colorAtX の device profile への再解釈を避ける。
    return [NSColor colorWithSRGBRed:pixel[0] / 255.0 green:pixel[1] / 255.0
        blue:pixel[2] / 255.0 alpha:pixel[3] / 255.0];
}
NSImage* cached_image(HorizonView* view) {
    // 再生成回数を公開 API に追加せず、内部の画像 identity で遅延評価と再利用を検証する。
    return [view valueForKey:@"backgroundImage"];
}
bool same_pixel(NSBitmapImageRep* first, NSBitmapImageRep* second, NSInteger x, NSInteger y) {
    return std::memcmp(first.bitmapData + y * first.bytesPerRow + x * 4,
                       second.bitmapData + y * second.bytesPerRow + x * 4, 4) == 0;
}
std::shared_ptr<SkyBackgrounds> solid_backgrounds() {
    auto backgrounds = std::make_shared<SkyBackgrounds>();
    backgrounds->images[0] = TextureImage{1, 1, {96, 0, 0, 255}};
    backgrounds->images[1] = TextureImage{1, 1, {0, 96, 0, 255}};
    backgrounds->images[2] = TextureImage{1, 1, {0, 0, 96, 255}};
    return backgrounds;
}
HorizonView* make_view() {
    HorizonView* view = [[HorizonView alloc] initWithFrame:NSMakeRect(0, 0, 600, 400)];
    view.gridDisplayOptions = {false, false, false, false, false, false};
    return view;
}

void compositing_tests() {
    HorizonView* view = make_view();
    auto backgrounds = solid_backgrounds();
    [view setSkyBackgrounds:backgrounds];
    NSBitmapImageRep* base = snapshot(view);
    check(cached_image(view) == nil, "None must not render an unused texture");
    const NSColor* empty = color(base, view, 120, 100);
    const std::array<MilkyWayMode, 3> modes{{MilkyWayMode::normal, MilkyWayMode::bright, MilkyWayMode::infrared}};
    for (std::size_t mode = 0; mode < modes.size(); ++mode) {
        view.milkyWayMode = modes[mode];
        NSBitmapImageRep* image = snapshot(view);
        const NSColor* actual = color(image, view, 120, 100);
        const std::array<CGFloat, 3> delta{{actual.redComponent - empty.redComponent,
            actual.greenComponent - empty.greenComponent, actual.blueComponent - empty.blueComponent}};
        for (std::size_t channel = 0; channel < 3; ++channel)
            check(std::abs(delta[channel] - (channel == mode ? 96.0 / 255 : 0)) < 0.02,
                "background must add the selected local image to the base color");
        const NSRect map = NSInsetRect(view.bounds, 42, 34);
        for (NSInteger y = 0; y < image.pixelsHigh; ++y) {
            for (NSInteger x = 0; x < image.pixelsWide; ++x) {
                const NSPoint point = NSMakePoint((x + 0.5) * view.bounds.size.width / image.pixelsWide,
                    (y + 0.5) * view.bounds.size.height / image.pixelsHigh);
                if (!NSPointInRect(point, map) || point.y > NSMidY(map) + 1)
                    check(same_pixel(base, image, x, y), "background leaked into ground, margins, or controls");
            }
        }
    }
    view.milkyWayMode = MilkyWayMode::none;
    check(std::abs(color(snapshot(view), view, 120, 100).blueComponent - empty.blueComponent) < 0.01,
        "None must remove the image");
    auto infrared_only = std::make_shared<SkyBackgrounds>();
    infrared_only->images[2] = backgrounds->images[2];
    [view setSkyBackgrounds:infrared_only];
    view.milkyWayMode = MilkyWayMode::normal;
    check(std::abs(color(snapshot(view), view, 120, 100).blueComponent - empty.blueComponent) < 0.01,
        "missing Normal must not use Infrared or the previous model");
    check(cached_image(view) == nil, "missing mode must not generate a background");
    view.milkyWayMode = MilkyWayMode::infrared;
    check(color(snapshot(view), view, 120, 100).blueComponent > empty.blueComponent + 0.3,
        "available Infrared must remain independently usable");
    [view setSkyBackgrounds:nullptr];
    check(cached_image(view) == nil, "unload must release the old cached image");
}

void cache_tests() {
    HorizonView* view = make_view();
    const auto backgrounds = solid_backgrounds();
    view.hidden = YES;
    [view setSkyBackgrounds:backgrounds];
    view.milkyWayMode = MilkyWayMode::normal;
    [view setObservationSite:{-33.86, 151.21} julianDate:2460000];
    [view setViewport:{725, 20, 4}];
    check(cached_image(view) == nil, "hidden setters must not rasterize");
    view.hidden = NO;
    snapshot(view);
    NSImage* first = cached_image(view);
    check(first != nil, "first actual drawing must render the requested image");
    snapshot(view);
    check(cached_image(view) == first, "identical drawing must reuse its image");
    [view setBodies:{} julianDate:2460000];
    [view setObservationSite:{-33.86, 151.21} julianDate:2460000];
    [view setViewport:{5, 20, 4}];
    [view setSkyBackgrounds:backgrounds];
    view.milkyWayMode = MilkyWayMode::normal;
    [view clearSelection];
    snapshot(view);
    check(cached_image(view) == first, "same-JD updates and unrelated selection must reuse the cache");
    rejects([&] { view.milkyWayMode = static_cast<MilkyWayMode>(99); });
    rejects([&] { [view setObservationSite:{91, 0} julianDate:2460000]; });
    rejects([&] { [view setBodies:{} julianDate:std::numeric_limits<double>::quiet_NaN()]; });
    rejects([&] { [view setViewport:{0, 0, 0}]; });
    snapshot(view);
    check(cached_image(view) == first && view.julianDate == 2460000,
        "rejected state must preserve the frame and usable cached image");
    view.hidden = YES;
    [view setBodies:{} julianDate:2460000.25];
    [view setBodies:{} julianDate:2460000.5];
    check(cached_image(view) == first, "hidden time updates must remain lazy");
    view.hidden = NO;
    snapshot(view);
    NSImage* changed_date = cached_image(view);
    check(changed_date != first, "new date must regenerate on the next draw");
    [view setObserverSite:{-34, 151.21}];
    snapshot(view);
    NSImage* changed_latitude = cached_image(view);
    check(changed_latitude != changed_date, "latitude must be part of the cache key");
    [view setObserverSite:{-34, 150}];
    snapshot(view);
    NSImage* changed_longitude = cached_image(view);
    check(changed_longitude != changed_latitude, "longitude must be part of the cache key");
    [view setViewport:{10, 21, 5}];
    snapshot(view);
    NSImage* changed_viewport = cached_image(view);
    check(changed_viewport != changed_longitude, "viewport must be part of the cache key");
    view.frame = NSMakeRect(0, 0, 720, 480);
    snapshot(view);
    NSImage* resized = cached_image(view);
    check(resized != changed_viewport, "output dimensions must be part of the cache key");
    view.milkyWayMode = MilkyWayMode::bright;
    snapshot(view);
    NSImage* changed_mode = cached_image(view);
    check(changed_mode != resized, "mode must be part of the cache key");
    [view setSkyBackgrounds:solid_backgrounds()];
    check(cached_image(view) == nil, "a new model must discard the previous cache");
    snapshot(view);
    check(cached_image(view) != changed_mode, "new model identity must regenerate the image");
}

void orientation_tests() {
    HorizonView* view = make_view();
    TextureImage gradient{64, 32, std::vector<std::uint8_t>(64 * 32 * 4, 255)};
    for (std::size_t y = 0; y < 32; ++y) for (std::size_t x = 0; x < 64; ++x) {
        const auto offset = (y * 64 + x) * 4;
        gradient.rgba[offset] = x * 2;
        gradient.rgba[offset + 1] = y * 4;
        gradient.rgba[offset + 2] = 0;
    }
    auto backgrounds = std::make_shared<SkyBackgrounds>();
    backgrounds->images[0] = gradient;
    [view setSkyBackgrounds:backgrounds];
    for (const auto site : {ObserverSite{35.68, 139.76}, ObserverSite{-90, -180}}) {
        for (double jd : {2451545.0, 2451545.25}) {
            [view setObservationSite:site julianDate:jd];
            [view setViewport:{350, 30, 4}];
            view.milkyWayMode = MilkyWayMode::none;
            NSBitmapImageRep* base = snapshot(view);
            view.milkyWayMode = MilkyWayMode::normal;
            NSBitmapImageRep* actual = snapshot(view);
            const NSRect map = NSInsetRect(view.bounds, 42, 34);
            const auto expected = render_horizon_background(gradient, [view viewport], ObservationFrame(site, jd),
                map.size.width, map.size.height);
            for (double fraction_y : {0.2, 0.4}) for (double fraction_x : {0.2, 0.5, 0.8}) {
                const auto x = static_cast<std::size_t>(map.size.width * fraction_x);
                const auto y = static_cast<std::size_t>(map.size.height * fraction_y);
                const NSColor* before = color(base, view, map.origin.x + x + 0.5, map.origin.y + y + 0.5);
                const NSColor* after = color(actual, view, map.origin.x + x + 0.5, map.origin.y + y + 0.5);
                check(std::abs(after.redComponent - before.redComponent - expected.rgba[(y * expected.width + x) * 4] / 255.0) < 0.025
                    && std::abs(after.greenComponent - before.greenComponent - expected.rgba[(y * expected.width + x) * 4 + 1] / 255.0) < 0.025,
                    "view image orientation or observer/date cache is incorrect");
            }
        }
    }
}
} // namespace

int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            compositing_tests();
            cache_tests();
            orientation_tests();
            std::cout << "horizon background view: " << checks << " checks passed (no windows)\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "horizon background view: " << error.what() << '\n';
            return 1;
        }
    }
}
