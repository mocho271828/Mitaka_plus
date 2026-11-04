#import "MediaController.h"
#import "MediaImageView.h"
#include <cmath>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <vector>
#include <unistd.h>

namespace fs = std::filesystem;
namespace {
std::size_t checks = 0;
void check(bool value, const char *message) { ++checks; if (!value) throw std::runtime_error(message); }
struct Fixture {
    fs::path root;
    Fixture() {
        char name[] = "/tmp/mitaka-media-controller-XXXXXX";
        const char *path = mkdtemp(name); if (!path) throw std::runtime_error("mkdtemp failed");
        root = path; fs::create_directory(root / "media"); fs::create_directory(root / "data"); fs::create_directory(root / "images");
    }
    ~Fixture() { std::error_code ignored; fs::remove_all(root, ignored); }
    NSURL *url(const char *name) { return [NSURL fileURLWithFileSystemRepresentation:(root / name).c_str() isDirectory:NO relativeToURL:nil]; }
    void write(const char *name, const std::string& value) { std::ofstream out(root / name, std::ios::binary); out << value; }
    void image() {
        NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr pixelsWide:2 pixelsHigh:2
            bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:8 bitsPerPixel:32];
        for (int i = 0; i < 16; ++i) bitmap.bitmapData[i] = 255;
        NSData *data = [bitmap representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        check([data writeToURL:url("images/image.png") atomically:YES], "image fixture write");
    }
    void audio() {
        // 1秒の無音PCM。テスト用ファイルだけを新規生成し、原本の変換は行わない。
        std::string wav("RIFF", 4);
        auto put = [&](std::uint32_t value, int bytes) { for (int i = 0; i < bytes; ++i) wav.push_back(static_cast<char>((value >> (i * 8)) & 255)); };
        put(16036, 4); wav += "WAVEfmt "; put(16, 4); put(1, 2); put(1, 2); put(8000, 4); put(16000, 4); put(2, 2); put(16, 2);
        wav += "data"; put(16000, 4); wav.append(16000, '\0'); write("silent.wav", wav);
    }
};
void spinUntil(MediaController *controller, NSString *text) {
    const auto deadline = [NSDate dateWithTimeIntervalSinceNow:8];
    while (![controller.previewMessage containsString:text] && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}
void imageTransforms() {
    MediaImageView *view = [[MediaImageView alloc] initWithFrame:NSMakeRect(0, 0, 300, 200)];
    check(view.zoom == 1 && view.rotationDegrees == 0 && view.imageOpacity == 1, "default transforms");
    view.zoom = 2; view.rotationDegrees = 450; view.imageOpacity = 0.4; view.pan = NSMakePoint(23, -50);
    check(view.zoom == 2 && view.rotationDegrees == 90 && view.imageOpacity == 0.4 && view.pan.x == 23, "transforms lost");
    for (const double bad : {0.0, -1.0, 21.0, std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()}) {
        bool threw = false; try { view.zoom = bad; } catch (const std::invalid_argument&) { threw = true; }
        check(threw && view.zoom == 2, "invalid zoom mutated state");
    }
    for (const double bad : {-0.1, 1.1, std::numeric_limits<double>::quiet_NaN()}) {
        bool threw = false; try { view.imageOpacity = bad; } catch (const std::invalid_argument&) { threw = true; }
        check(threw && view.imageOpacity == 0.4, "invalid opacity mutated state");
    }
    bool threw = false;
    try { view.rotationDegrees = std::numeric_limits<double>::infinity(); } catch (const std::invalid_argument&) { threw = true; }
    check(threw && view.rotationDegrees == 90, "invalid rotation");
    threw = false;
    try { view.pan = NSMakePoint(NAN, 0); } catch (const std::invalid_argument&) { threw = true; }
    check(threw && view.pan.x == 23, "invalid pan");
    [view resetTransform]; check(view.zoom == 1 && view.rotationDegrees == 0 && view.pan.x == 0 && view.imageOpacity == 1, "reset transform");
}
void imageClipping() {
    NSBitmapImageRep *canvas = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr pixelsWide:240 pixelsHigh:240
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:960 bitsPerPixel:32];
    NSBitmapImageRep *source = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nullptr pixelsWide:2 pixelsHigh:2
        bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:8 bitsPerPixel:32];
    check(canvas != nil && source != nil, "clipping bitmap setup");
    for (int i = 0; i < 16; ++i) source.bitmapData[i] = 255;
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(2, 2)]; [image addRepresentation:source];
    MediaImageView *view = [[MediaImageView alloc] initWithFrame:NSMakeRect(0, 0, 120, 120)];
    view.image = image; view.zoom = 2; view.rotationDegrees = 30; view.imageOpacity = 0.6; view.pan = NSMakePoint(25, 0);
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:canvas];
    [NSGraphicsContext setCurrentContext:context];
    [NSColor.magentaColor setFill]; NSRectFill(NSMakeRect(0, 0, 240, 240));
    const std::size_t byteCount = static_cast<std::size_t>(canvas.bytesPerRow * canvas.pixelsHigh);
    const std::vector<unsigned char> before(canvas.bitmapData, canvas.bitmapData + byteCount);
    // NSView側の暗黙clipに依存しないよう、大きい描画先の中央でdrawRectを実行する。
    NSAffineTransform *offset = [NSAffineTransform transform]; [offset translateXBy:60 yBy:60]; [offset concat];
    [view drawRect:view.bounds];
    [NSGraphicsContext restoreGraphicsState];
    bool outsideUnchanged = true, insideChanged = false;
    for (NSInteger y = 0; y < 240; ++y) {
        for (NSInteger x = 0; x < 240; ++x) {
            const auto pos = static_cast<std::size_t>(y * canvas.bytesPerRow + x * 4);
            bool changed = false;
            for (std::size_t channel = 0; channel < 4; ++channel)
                changed = changed || canvas.bitmapData[pos + channel] != before[pos + channel];
            if (x >= 60 && x < 180 && y >= 60 && y < 180) insideChanged = insideChanged || changed;
            else outsideUnchanged = outsideUnchanged && !changed;
        }
    }
    check(insideChanged, "image clipping regression did not draw");
    check(outsideUnchanged, "transformed image drew outside preview bounds");
}
void controller() {
    Fixture f; f.image(); f.audio();
    f.write("media/images.dat", "x.mvp x.mvp I image title\ny.mvp y.mvp P missing missing\n");
    f.write("media/x.mvp", ".\\images\\image.png\n"); f.write("media/y.mvp", ".\\images\\missing.png\n");
    NSData *original = [NSData dataWithContentsOfURL:f.url("images/image.png")];
    NSData *registry = [NSData dataWithContentsOfURL:f.url("media/images.dat")];
    MediaController *c = [[MediaController alloc] init]; NSError *error = nil;
    [c loadDataDirectory:f.url("data")];
    check(c.entryCount == 2 && c.unresolvedCount == 1, "catalog counts");
    check([c.diagnosticSummary containsString:@"旧type P"] && [c.diagnosticSummary containsString:@"完全一致"], "unresolved diagnostics");
    check(![c previewSelected:&error] && error != nil, "unselected preview");
    [c selectEntryAtIndex:99]; check(![c previewSelected:&error], "invalid selection");
    [c selectEntryAtIndex:1]; check(![c previewSelected:&error], "missing preview accepted");
    check(![c mapSelectedEntryToURL:[NSURL URLWithString:@"https://example.invalid/a.png"] error:&error], "remote mapping accepted");
    check(![c mapSelectedEntryToURL:f.url("images") error:&error], "directory mapping accepted");
    f.write("test.exe", "bad");
    check(![c mapSelectedEntryToURL:f.url("test.exe") error:&error], "unsupported mapping accepted");
    check([c mapSelectedEntryToURL:f.url("images/image.png") error:&error] && c.unresolvedCount == 0, "memory mapping failed");
    const BOOL imagePrepared = [c previewSelected:&error];
    if (!imagePrepared) std::cerr << "image preview: " << error.localizedDescription.UTF8String << '\n';
    check(imagePrepared, "mapped image preview failed");
    check(c.previewVisible && !c.mediaPlaying, "mapped image visibility or autoplay");
    check([c.previewMessage containsString:@"1024"], "preview resolution missing");
    [c closePreview]; check(!c.previewVisible, "close preview failed");
    [c loadDataDirectory:f.url("data")]; check(c.unresolvedCount == 1, "mapping persisted after data reload");
    [c selectEntryAtIndex:0]; check([c previewSelected:&error], "registered image preview failed");
    f.write("broken.png", "not an image");
    check([c mapSelectedEntryToURL:f.url("broken.png") error:&error], "bad image reference setup");
    check(![c previewSelected:&error] && !c.previewVisible, "corrupt image accepted");
    check([c mapSelectedEntryToURL:f.url("silent.wav") error:&error] && [c previewSelected:&error], "local audio prepare failed");
    spinUntil(c, @"再生ボタンで開始。");
    check([c.previewMessage containsString:@"再生ボタンで開始。"] && !c.mediaPlaying, "audio readiness or unexpected autoplay");
    [c closePreview]; check(!c.mediaPlaying && !c.previewVisible, "audio close did not stop");
    f.write("broken.mp4", "invalid media");
    check([c mapSelectedEntryToURL:f.url("broken.mp4") error:&error] && [c previewSelected:&error], "bad movie test setup");
    spinUntil(c, @"再生できません:");
    check([c.previewMessage containsString:@"再生できません:"] && !c.mediaPlaying, "failed codec not reported");
    [c invalidate]; check(!c.previewVisible && !c.mediaPlaying, "invalidate did not stop");
    check([original isEqualToData:[NSData dataWithContentsOfURL:f.url("images/image.png")]], "original image changed");
    check([registry isEqualToData:[NSData dataWithContentsOfURL:f.url("media/images.dat")]], "original registry changed");
    [c loadDataDirectory:[NSURL URLWithString:@"https://example.invalid/data"]];
    check(c.entryCount == 0 && [c.diagnosticSummary containsString:@"ローカル"], "remote data directory accepted");
}
}
int main() {
    @autoreleasepool {
        try {
            [NSApplication sharedApplication]; [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
            imageTransforms(); imageClipping(); controller();
            std::cout << "media_controller: " << checks << " checks passed\n"; return 0;
        } catch (const std::exception& error) { std::cerr << error.what() << '\n'; return 1; }
    }
}
