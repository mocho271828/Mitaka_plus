#include "RendererQuality.h"

#import <AppKit/AppKit.h>
#include <CoreText/CoreText.h>

#include <algorithm>
#include <array>
#include <cstdint>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <type_traits>
#include <vector>

using namespace mitaka::gui;

namespace {
std::size_t checks = 0;
void expect(bool condition, const char* message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template<class Callable> void rejects(Callable action) {
    bool rejected = false;
    try { action(); } catch (const std::invalid_argument&) { rejected = true; }
    expect(rejected, "invalid renderer input must be rejected");
}
struct ReleaseCF { void operator()(const void* value) const { if (value) CFRelease(value); } };
template<class T> using CFPointer = std::unique_ptr<std::remove_pointer_t<T>, ReleaseCF>;

struct Bitmap {
    static constexpr std::size_t side = 64;
    std::vector<std::uint8_t> rgba = std::vector<std::uint8_t>(side * side * 4, 255);
    CFPointer<CGColorSpaceRef> space{CGColorSpaceCreateWithName(kCGColorSpaceSRGB)};
    CFPointer<CGContextRef> context{CGBitmapContextCreate(rgba.data(), side, side, 8, side * 4, space.get(),
        kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast)};
    Bitmap() {
        if (!context) throw std::runtime_error("cannot create renderer bitmap fixture");
        CGContextSetRGBFillColor(context.get(), 0, 0, 0, 1);
        CGContextSetRGBStrokeColor(context.get(), 0, 0, 0, 1);
    }
    void clear() { std::fill(rgba.begin(), rgba.end(), 255); }
    void point() { CGContextFillEllipseInRect(context.get(), CGRectMake(13.25, 17.25, 31.5, 27.5)); }
    void line() {
        CGContextBeginPath(context.get());
        CGContextMoveToPoint(context.get(), 8.25, 11.75);
        CGContextAddLineToPoint(context.get(), 52.25, 48.5);
        CGContextStrokePath(context.get());
    }
    std::size_t partial_pixels() const {
        std::size_t result = 0;
        for (std::size_t i = 0; i < rgba.size(); i += 4) {
            if (rgba[i] != 0 && rgba[i] != 255) ++result;
        }
        return result;
    }
};

void option_contract() {
    const RendererDisplayOptions defaults;
    expect(defaults.antialias && defaults.point_smoothing && defaults.line_smoothing && defaults.text_smoothing,
           "native default quality must keep smoothing enabled");
    const std::array<RendererPrimitive, 4> primitives{RendererPrimitive::general, RendererPrimitive::point,
        RendererPrimitive::line, RendererPrimitive::text};
    for (bool master : {false, true}) {
        RendererDisplayOptions options;
        options.antialias = master;
        for (auto primitive : primitives) expect(renderer_antialias(options, primitive) == master,
            "master quality gate must cover every primitive");
    }
    for (auto primitive : {RendererPrimitive::point, RendererPrimitive::line, RendererPrimitive::text}) {
        RendererDisplayOptions options;
        if (primitive == RendererPrimitive::point) options.point_smoothing = false;
        if (primitive == RendererPrimitive::line) options.line_smoothing = false;
        if (primitive == RendererPrimitive::text) options.text_smoothing = false;
        for (auto candidate : primitives) expect(renderer_antialias(options, candidate) == (candidate != primitive),
            "one primitive option must not disable another primitive");
    }
    rejects([] { (void)renderer_antialias({}, static_cast<RendererPrimitive>(-1)); });
    rejects([] { RendererQualityScope scope(nullptr, {}); });
    static_assert(!std::is_copy_constructible_v<RendererQualityScope>);
    static_assert(!std::is_move_constructible_v<RendererQualityScope>);
}

void raster_contract() {
    Bitmap bitmap;
    auto context = bitmap.context.get();
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, false);
    for (auto primitive : {RendererPrimitive::point, RendererPrimitive::line}) {
        const auto draw = [&] { if (primitive == RendererPrimitive::point) bitmap.point(); else bitmap.line(); };
        bitmap.clear();
        {
            RendererQualityScope scope(context, {}, primitive);
            draw();
        }
        expect(bitmap.partial_pixels() > 0, "enabled quality must rasterize fractional edge coverage");
        const auto smooth_pixels = bitmap.rgba;
        bitmap.clear();
        draw();
        expect(bitmap.partial_pixels() == 0, "scope must restore disabled incoming antialias state");
        expect(bitmap.rgba != smooth_pixels, "quality toggle must change rendered point or line pixels");

        RendererDisplayOptions disabled;
        disabled.antialias = false;
        bitmap.clear();
        {
            RendererQualityScope scope(context, disabled, primitive);
            draw();
        }
        expect(bitmap.partial_pixels() == 0, "master gate must disable point and line coverage");
        RendererDisplayOptions individual;
        individual.point_smoothing = false;
        individual.line_smoothing = false;
        bitmap.clear();
        {
            RendererQualityScope scope(context, individual, primitive);
            draw();
        }
        expect(bitmap.partial_pixels() == 0, "individual quality gate must affect rasterization");
    }

    bitmap.clear();
    CGContextSetAllowsAntialiasing(context, false);
    {
        RendererQualityScope scope(context, {}, RendererPrimitive::point);
        bitmap.point();
    }
    expect(bitmap.partial_pixels() == 0, "scope must not override a context that disallows antialiasing");
    bitmap.clear();
    CGContextSetShouldAntialias(context, true);
    bitmap.point();
    expect(bitmap.partial_pixels() == 0, "scope must preserve non-graphics-state AllowsAntialiasing");
    CGContextSetAllowsAntialiasing(context, true);
    bitmap.clear();
    bitmap.point();
    expect(bitmap.partial_pixels() > 0, "fixture must detect a context that permits antialiasing");
}

void nested_and_failure_contract() {
    Bitmap bitmap;
    auto context = bitmap.context.get();
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, false);
    {
        RendererQualityScope outer(context, {}, RendererPrimitive::point);
        RendererDisplayOptions no_lines;
        no_lines.line_smoothing = false;
        {
            RendererQualityScope inner(context, no_lines, RendererPrimitive::line);
            bitmap.line();
        }
        expect(bitmap.partial_pixels() == 0, "nested line override must be effective");
        bitmap.clear();
        bitmap.point();
        expect(bitmap.partial_pixels() > 0, "nested scope must restore its parent's antialias state");
        rejects([&] { RendererQualityScope invalid(context, {}, static_cast<RendererPrimitive>(99)); });
        bitmap.clear();
        bitmap.point();
        expect(bitmap.partial_pixels() > 0, "invalid primitive must not alter the incoming context");
    }
    bitmap.clear();
    bitmap.point();
    expect(bitmap.partial_pixels() == 0, "outer scope must restore the original context");
    try {
        RendererQualityScope scope(context, {}, RendererPrimitive::point);
        throw std::runtime_error("simulated drawing failure");
    } catch (const std::runtime_error&) {}
    bitmap.clear();
    bitmap.point();
    expect(bitmap.partial_pixels() == 0, "drawing exception must not leak quality state");
}

void text_raster_contract() {
    Bitmap bitmap;
    auto context = bitmap.context.get();
    CFPointer<CTFontRef> font{CTFontCreateWithName(CFSTR("Helvetica"), 25, nullptr)};
    if (!font) throw std::runtime_error("cannot create renderer text fixture font");
    const UniChar characters[] = {'A', 'W'};
    CGGlyph glyphs[2]{};
    const CGPoint positions[] = {{5.25, 19.25}, {25.75, 19.25}};
    expect(CTFontGetGlyphsForCharacters(font.get(), characters, glyphs, 2), "fixture glyphs must be available");
    const auto draw = [&] { CTFontDrawGlyphs(font.get(), glyphs, positions, 2, context); };
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, true);
    {
        RendererQualityScope scope(context, {}, RendererPrimitive::text);
        draw();
    }
    expect(bitmap.partial_pixels() > 0, "enabled text quality must retain antialiased glyph edges");
    const auto smooth_pixels = bitmap.rgba;
    RendererDisplayOptions options;
    options.text_smoothing = false;
    bitmap.clear();
    {
        RendererQualityScope scope(context, options, RendererPrimitive::text);
        draw();
    }
    expect(bitmap.partial_pixels() == 0, "disabled text quality must disable glyph antialiasing");
    expect(bitmap.rgba != smooth_pixels, "text quality toggle must change glyph edge pixels");
    bitmap.clear();
    draw();
    expect(bitmap.partial_pixels() > 0, "text scope must restore incoming antialias state");

    // font smoothing 自体は出力 context 依存なので、特定の色縁や subpixel 結果を要求しない。
    CGContextSetAllowsFontSmoothing(context, false);
    CGContextSetShouldSmoothFonts(context, true);
    bitmap.clear();
    draw();
    const auto without_smoothing = bitmap.rgba;
    bitmap.clear();
    {
        RendererQualityScope scope(context, {}, RendererPrimitive::text);
        draw();
    }
    expect(bitmap.rgba == without_smoothing, "text scope must respect disabled context font smoothing");
    bitmap.clear();
    draw();
    expect(bitmap.rgba == without_smoothing, "text scope must preserve context font smoothing permission");
}
void appkit_raster_contract() {
    Bitmap bitmap;
    auto context = bitmap.context.get();
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:NO];
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, true);
    for (auto primitive : {RendererPrimitive::point, RendererPrimitive::line, RendererPrimitive::text}) {
        const auto draw = [&] {
            [NSColor.blackColor set];
            if (primitive == RendererPrimitive::point)
                [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(13.25, 17.25, 31.5, 27.5)] fill];
            else if (primitive == RendererPrimitive::line) {
                NSBezierPath *line = [NSBezierPath bezierPath];
                [line moveToPoint:NSMakePoint(8.25, 11.75)];
                [line lineToPoint:NSMakePoint(52.25, 48.5)];
                [line stroke];
            } else [@"AW" drawAtPoint:NSMakePoint(5.25, 15.25) withAttributes:@{
                NSFontAttributeName: [NSFont systemFontOfSize:25],
                NSForegroundColorAttributeName: NSColor.blackColor}];
        };
        bitmap.clear();
        {
            RendererQualityScope scope(context, {}, primitive);
            draw();
        }
        const auto smooth = bitmap.rgba;
        expect(bitmap.partial_pixels() > 0, "AppKit enabled primitive must have smooth edges");
        RendererDisplayOptions individual;
        if (primitive == RendererPrimitive::point) individual.point_smoothing = false;
        if (primitive == RendererPrimitive::line) individual.line_smoothing = false;
        if (primitive == RendererPrimitive::text) individual.text_smoothing = false;
        bitmap.clear();
        {
            RendererQualityScope scope(context, individual, primitive);
            draw();
        }
        expect(bitmap.rgba != smooth, "AppKit primitive must respond to its individual quality option");
        expect(bitmap.partial_pixels() == 0, "AppKit disabled primitive must have hard edges");
        const auto hard = bitmap.rgba;
        RendererDisplayOptions master;
        master.antialias = false;
        bitmap.clear();
        {
            RendererQualityScope scope(context, master, primitive);
            draw();
        }
        expect(bitmap.rgba == hard, "AppKit master gate must disable the same primitive coverage");
        bitmap.clear();
        draw();
        expect(bitmap.rgba == smooth, "AppKit scope must restore its incoming quality state");
    }
    [NSGraphicsContext restoreGraphicsState];
}
} // namespace

int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            option_contract();
            raster_contract();
            nested_and_failure_contract();
            text_raster_contract();
            appkit_raster_contract();
            std::cout << "renderer_quality: " << checks << " checks passed\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "renderer_quality: " << error.what() << '\n';
            return 1;
        }
    }
}
