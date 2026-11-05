// P1-4 の描画時間調査用。GUI の実装と実データを使用し、単体テストには含めない。
// リポジトリルートから以下を実行する。DATA_ROOT はアプリのデータディレクトリ。
// cd vendor/mitaka/native/gui
// make -j4 core build/SmallBodyRenderer.o build/small_body_model.o \
//   build/small_body_display.o build/small_body_orbit_model.o \
//   build/solar_camera.o build/RendererQuality.o
// xcrun clang++ -std=c++17 -O2 -fobjc-arc -mmacosx-version-min=13.0 \
//   -Iinclude -I../core/include \
//   ../../../../investigation/native-plus/small-body-render-benchmark.mm \
//   build/SmallBodyRenderer.o build/small_body_model.o build/small_body_display.o \
//   build/small_body_orbit_model.o build/solar_camera.o build/RendererQuality.o \
//   build/core/libmitaka_core.a -framework AppKit -o /tmp/mitaka-small-body-render-benchmark
// DATA_ROOT=../../../../resources/data
// /usr/bin/time -l /tmp/mitaka-small-body-render-benchmark "${DATA_ROOT}"
// 800×600 bitmap 上の描画であり、ウィンドウ全体の FPS は測定しない。
#import <AppKit/AppKit.h>
#include "SmallBodyRenderer.h"
#include <chrono>
#include <iostream>
using namespace mitaka;
using namespace mitaka::gui;
int main(int argc, char** argv) {
    if (argc != 2) return 2;
    @autoreleasepool {
        auto data = std::make_shared<const SmallBodyDataset>(load_small_body_dataset(argv[1]));
        auto model = std::make_shared<SmallBodyModel>(data);
        auto display = std::make_shared<SmallBodyDisplayModel>(data);
        display->set_kind_options(SmallBodyKind::asteroid, {true, false, true, false});
        display->set_kind_options(SmallBodyKind::trans_neptunian, {true, false, true, false});
        display->set_kind_options(SmallBodyKind::comet, {false, false, false, false});
        auto frame = evaluate_small_body_snapshot(model, 2451545);
        auto orbits = evaluate_small_body_orbit_snapshot(model, display, {2451545-182.625, 2451545+182.625, 129});
        auto space = CGColorSpaceCreateDeviceRGB();
        auto context = CGBitmapContextCreate(nullptr, 800, 600, 8, 3200, space, kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(space);
        if (!context) return 3;
        SolarCamera camera; camera.distance_au = 7;
        const auto map = NSMakeRect(0, 0, 800, 600);
        std::size_t segment_count = 0;
        visit_small_body_orbit_segments(*frame, *display, orbits.get(), camera, map, [&](const auto&) { ++segment_count; });
        std::cout << "records=" << data->records.size() << " requested=" << orbits->requested_count << " unresolved=" << orbits->unresolved_count << " projected=" << segment_count << "\n";
        for (int i=0;i<3;++i) {
            CGContextClearRect(context, NSRectToCGRect(map));
            const auto start=std::chrono::steady_clock::now();
            draw_small_bodies(context, *frame, *display, orbits.get(), camera, map, {}, {});
            std::cout << "draw_seconds=" << std::chrono::duration<double>(std::chrono::steady_clock::now()-start).count() << '\n';
        }
        CGContextRelease(context);
    }
}
