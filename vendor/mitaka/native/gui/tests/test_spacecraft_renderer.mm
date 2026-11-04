#import "SpacecraftRenderer.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <iostream>
#include <limits>
#include <memory>
#include <stdexcept>
#include <type_traits>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
std::size_t checks = 0;
void require(bool value, const char* message) { ++checks; if (!value) throw std::runtime_error(message); }
void near(double actual, double expected) { require(std::abs(actual - expected) < 1e-10, "independent projection mismatch"); }
void append_double(std::string& bytes, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof bits);
    for (unsigned i = 0; i < 8; ++i) bytes.push_back(static_cast<char>(bits >> (8 * i)));
}

SpacecraftDataset dataset(const std::vector<std::vector<SpacecraftPathSample>>& paths) {
    SpacecraftDataset data;
    for (std::size_t i = 0; i < paths.size(); ++i) {
        const auto source_index = data.sources.size();
        std::string bytes;
        for (const auto& sample : paths[i]) {
            append_double(bytes, sample.time_value);
            for (const double value : sample.coordinate_values) append_double(bytes, value);
        }
        data.sources.push_back({"spacecraft/custom-" + std::to_string(i) + ".pth", {},
            SpacecraftSourceKind::pth_samples, std::move(bytes), true, true, paths[i].size()});
        data.trajectories.push_back({source_index, paths[i], {}});
        data.sources.push_back({"spacecraft/custom-" + std::to_string(i) + ".dat", {},
            SpacecraftSourceKind::definition, "Name: Probe\n", true, true, 1});
        data.definitions.push_back({source_index + 1, {{"Name", "Probe", 0, 0, 1, {}}}, i});
    }
    return data;
}
std::shared_ptr<const SpacecraftSnapshot> snapshot(SpacecraftDataset data, double jd = 1) {
    return evaluate_spacecraft_snapshot(std::make_shared<const SpacecraftBrowserModel>(
        std::make_shared<const SpacecraftPositionModel>(std::move(data))), jd);
}
SolarCamera camera() {
    SolarCamera result;
    result.yaw_deg = 0; result.pitch_deg = 0; result.distance_au = 10;
    return result;
}
std::vector<SpacecraftPathSegment> segments(const SpacecraftSnapshot& state, const SpacecraftDisplayOptions& options,
                                          NSRect map = NSMakeRect(32, 32, 192, 192)) {
    std::vector<SpacecraftPathSegment> result;
    visit_spacecraft_path_segments(state, camera(), map, options, [&](const auto& segment) { result.push_back(segment); });
    return result;
}
SpacecraftDisplayOptions paths_only() { return {false, false, true}; }

void positions_and_picking() {
    auto data = dataset({{{0, {0, -1, 0}}, {2, {0, 1, 0}}},
                         {{0, {5, 0, 0}}, {2, {5, 0, 0}}},
                         {{0, {11, 0, 0}}, {2, {11, 0, 0}}}});
    data.definitions.insert(data.definitions.begin() + 1, data.definitions.front());
    const auto state = snapshot(std::move(data));
    const NSRect map = NSMakeRect(20, 30, 200, 160);
    const auto visible = visible_spacecraft(*state, camera(), map, {});
    require(spacecraft_scene_position(*state, 0).has_value(), "confirmed position available for camera focus");
    require(!spacecraft_scene_position(*state, 4), "out of range scene position unavailable");
    require(visible.size() == 3, "behind camera omitted and duplicate definitions retained");
    require(visible[0].index == 0 && visible[1].index == 1 && visible[2].index == 2,
        "depth ordering stable for duplicate definitions");
    for (const auto& item : visible) { near(item.point.x, 120); near(item.point.y, 110); }
    near(visible.front().point.depth, 10); near(visible.back().point.depth, 5);
    require(pick_spacecraft(*state, camera(), map, NSMakePoint(120, 110), {}) == 2, "nearest-depth duplicate wins");
    require(pick_spacecraft(*state, camera(), map, NSMakePoint(127.999, 110), {}) == 2, "eight point hit tolerance included");
    require(!pick_spacecraft(*state, camera(), map, NSMakePoint(128.001, 110), {}), "hit tolerance bounded");
    require(!pick_spacecraft(*state, camera(), map, NSMakePoint(19, 110), {}), "outside map cannot hit");
    auto tied = *state;
    tied.positions[2].reset();
    require(pick_spacecraft(tied, camera(), map, NSMakePoint(120, 110), {}) == 1, "equal depth last original row wins");
    const auto offset = snapshot(dataset({{{0, {0, 1, 2}}}}));
    const auto offset_visible = visible_spacecraft(*offset, camera(), map, {});
    require(offset_visible.size() == 1, "offset position visible");
    const double scale = 80 * (1 + std::sqrt(2.0)) / 10;
    near(offset_visible[0].point.x, 120 + scale);
    near(offset_visible[0].point.y, 110 - 2 * scale);
    for (bool points : {false, true}) for (bool labels : {false, true}) for (bool orbits : {false, true}) {
        const SpacecraftDisplayOptions options{points, labels, orbits};
        require(visible_spacecraft(*state, camera(), map, options).size() == (points || labels ? 3 : 0),
            "point and label visibility independent of orbit visibility");
        require(pick_spacecraft(*state, camera(), map, NSMakePoint(120, 110), options).has_value() == points,
            "only point option enables hit");
        require(segments(*state, options).size() == (orbits ? 3 : 0), "orbit option independent of point and label visibility");
    }
    const SpacecraftDisplayOptions defaults;
    require(defaults.points && !defaults.labels && !defaults.orbits, "native defaults explicit");
}

void path_boundaries() {
    std::vector<SpacecraftPathSample> path{{0, {0, -2, 0}}, {1, {0, -1, 0}}, {2, {11, 0, 0}},
        {3, {0, 1, 0}}, {4, {0, 2, 0}}, {5, {9.9999, 0, 0}}, {6, {0, 3, 0}},
        {7, {0, 4, 0}}, {8, {0, 1e308, 0}}, {9, {0, 5, 0}}, {10, {0, 6, 0}}, {10, {0, 7, 0}}};
    auto data = dataset({path});
    const auto original_bytes = data.sources[0].bytes;
    data.definitions.push_back(data.definitions.front());
    const auto state = snapshot(std::move(data), 0);
    const auto lines = segments(*state, paths_only());
    const std::vector<std::size_t> expected_first{0, 3, 6, 9, 10};
    require(lines.size() == 2 * expected_first.size(), "no bridge across behind, near plane or projection overflow");
    for (std::size_t i = 0; i < lines.size(); ++i) {
        const auto& line = lines[i];
        require(line.definition_index == i / expected_first.size(), "duplicate source definitions retain independent line identity");
        require(line.first_record_index == expected_first[i % expected_first.size()]
            && line.second_record_index == line.first_record_index + 1, "only original adjacent rows connected");
    }
    require(lines[4].second.x > lines[4].first.x, "different positions at equal time remain a segment");
    require(lines[4].second.x > 224, "offscreen projected points retained for clipping");
    require(state->model->model().dataset().sources[0].bytes == original_bytes, "render geometry preserves raw bytes");
    require(state->model->model().dataset().trajectories[0].path_samples.size() == path.size(), "all samples retained");
    const auto singleton = snapshot(dataset({{{1, {0, 0, 0}}}}));
    require(segments(*singleton, paths_only()).empty(), "singleton path has no artificial closure");
    const auto bad = snapshot(dataset({{{0, {0, 0, 0}}, {1, {0, std::numeric_limits<double>::quiet_NaN(), 0}},
                                       {2, {0, 1, 0}}}}));
    require(segments(*bad, paths_only()).empty(), "invalid raw source is not partly drawn as confirmed PTH");
}

void inconsistent_snapshots() {
    const auto good = snapshot(dataset({{{0, {0, -1, 0}}, {2, {0, 1, 0}}}}));
    const NSRect map = NSMakeRect(32, 32, 192, 192);
    const auto suppressed = [&](const SpacecraftSnapshot& state) {
        require(!spacecraft_scene_position(state, 0), "unconfirmed focus and tracking position suppressed");
        require(visible_spacecraft(state, camera(), map, {}).empty(), "unconfirmed position suppressed");
        require(segments(state, paths_only()).empty(), "unconfirmed path suppressed");
        require(!pick_spacecraft(state, camera(), map, NSMakePoint(128, 128), {}), "unconfirmed hit suppressed");
    };
    auto bad = *good; bad.model.reset(); suppressed(bad);
    bad = *good; bad.evaluations.clear(); suppressed(bad);
    bad = *good; bad.positions.clear(); suppressed(bad);
    bad = *good; bad.positions[0]->x = std::numeric_limits<double>::infinity(); suppressed(bad);
    bad = *good; bad.positions[0]->x = 2; suppressed(bad);
    bad = *good; bad.julian_date = 2; suppressed(bad);
    bad = *good; bad.evaluations[0]->contract = {}; suppressed(bad);
    bad = *good; bad.evaluations[0]->trajectory_index = 1; suppressed(bad);
    bad = *good; bad.evaluations[0]->source_index.reset(); suppressed(bad);
    auto ppi_data = dataset({{{0, {0, -1, 0}}, {2, {0, 1, 0}}}});
    ppi_data.sources[0].kind = SpacecraftSourceKind::ppi_segments;
    bad = *snapshot(std::move(ppi_data));
    bad.positions = good->positions; bad.evaluations = good->evaluations;
    suppressed(bad);
    for (const auto invalid_map : {NSZeroRect, NSMakeRect(0, 0, -1, 100),
        NSMakeRect(0, 0, std::numeric_limits<double>::infinity(), 100),
        NSMakeRect(std::numeric_limits<double>::quiet_NaN(), 0, 100, 100)}) {
        require(visible_spacecraft(*good, camera(), invalid_map, {}).empty(), "invalid viewport empty");
        require(segments(*good, paths_only(), invalid_map).empty(), "invalid viewport path empty");
    }
    require(!pick_spacecraft(*good, camera(), map, NSMakePoint(NAN, 128), {}), "nonfinite mouse cannot hit");
    visit_spacecraft_path_segments(*good, camera(), map, paths_only(), {});
}

struct ReleaseCF { void operator()(const void* value) const { if (value) CFRelease(value); } };
template<class T> using CFPointer = std::unique_ptr<std::remove_pointer_t<T>, ReleaseCF>;
struct Bitmap {
    static constexpr std::size_t side = 256;
    std::vector<std::uint8_t> rgba = std::vector<std::uint8_t>(side * side * 4);
    CFPointer<CGColorSpaceRef> space{CGColorSpaceCreateWithName(kCGColorSpaceSRGB)};
    CFPointer<CGContextRef> context{CGBitmapContextCreate(rgba.data(), side, side, 8, side * 4, space.get(),
        kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast)};
    Bitmap() {
        if (!context) throw std::runtime_error("cannot create spacecraft bitmap");
        CGContextTranslateCTM(context.get(), 0, side);
        CGContextScaleCTM(context.get(), 1, -1);
        clear();
    }
    void clear() {
        CGContextSetRGBFillColor(context.get(), 0.03, 0.05, 0.08, 1);
        CGContextFillRect(context.get(), CGRectMake(0, 0, side, side));
    }
    void render(const SpacecraftSnapshot& state, SpacecraftDisplayOptions options,
                std::optional<std::size_t> selected = {}, RendererDisplayOptions quality = {}) {
        [NSGraphicsContext saveGraphicsState];
        NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithCGContext:context.get() flipped:YES];
        [[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua] performAsCurrentDrawingAppearance:^{
            draw_spacecraft(context.get(), state, camera(), NSMakeRect(32, 32, 192, 192), selected, options, quality);
        }];
        [NSGraphicsContext restoreGraphicsState];
        CGContextFlush(context.get());
    }
};
void raster_and_quality() {
    const auto state = snapshot(dataset({{{0, {0, -1, -0.5}}, {2, {0, 1, 0.5}}}}));
    Bitmap bitmap;
    const auto blank = bitmap.rgba;
    [NSGraphicsContext saveGraphicsState];
    NSGraphicsContext.currentContext = [NSGraphicsContext graphicsContextWithCGContext:bitmap.context.get() flipped:YES];
    draw_spacecraft(nullptr, *state, camera(), NSMakeRect(32, 32, 192, 192), 0, {true, true, true}, {});
    [NSGraphicsContext restoreGraphicsState];
    CGContextFlush(bitmap.context.get());
    require(bitmap.rgba == blank, "null CGContext cannot draw labels through the current AppKit context");
    bitmap.render(*state, {false, false, false}, 0);
    require(bitmap.rgba == blank, "all disabled draws nothing including selection ring");
    bitmap.render(*state, {});
    require(bitmap.rgba != blank, "points rasterize");
    const auto points = bitmap.rgba;
    bitmap.clear(); bitmap.render(*state, {}, 0);
    require(bitmap.rgba != points, "selected point and ring rasterize");
    bitmap.clear(); bitmap.render(*state, {false, true, false});
    require(bitmap.rgba != blank && bitmap.rgba != points, "labels rasterize independently of points");
    const auto labels = bitmap.rgba;
    bitmap.clear(); bitmap.render(*state, {false, true, false}, 0);
    require(bitmap.rgba == labels, "point disabled suppresses selection ring even with label enabled");
    bitmap.clear(); bitmap.render(*state, paths_only());
    require(bitmap.rgba != blank && bitmap.rgba != points, "paths rasterize independently");
    for (bool line : {false, true}) {
        const auto options = line ? paths_only() : SpacecraftDisplayOptions{};
        bitmap.clear(); bitmap.render(*state, options);
        const auto smooth = bitmap.rgba;
        RendererDisplayOptions quality;
        quality.antialias = false;
        bitmap.clear(); bitmap.render(*state, options, {}, quality);
        const auto aliased = bitmap.rgba;
        require(smooth != aliased, "primitive antialias option affects rendered pixels");
        quality.antialias = true;
        if (line) quality.line_smoothing = false; else quality.point_smoothing = false;
        bitmap.clear(); bitmap.render(*state, options, {}, quality);
        require(bitmap.rgba == aliased, "primitive quality matches disabled master for that primitive");
    }
    const auto crossing = snapshot(dataset({{{0, {0, -100, -100}}, {1, {0, 100, 100}}, {2, {0, 4, 0}}}}), 2);
    bitmap.clear(); bitmap.render(*crossing, {true, true, true}, 0);
    require(bitmap.rgba != blank, "crossing segment and edge label rasterize inside clip");
    for (std::size_t y = 0; y < Bitmap::side; ++y) for (std::size_t x = 0; x < Bitmap::side; ++x) {
        if (x >= 32 && x < 224 && y >= 32 && y < 224) continue;
        const auto offset = (y * Bitmap::side + x) * 4;
        require(std::equal(bitmap.rgba.begin() + offset, bitmap.rgba.begin() + offset + 4, blank.begin() + offset),
            "point, ring, label and path cannot draw outside map");
    }
    CGContextSetRGBFillColor(bitmap.context.get(), 1, 0, 0, 1);
    CGContextFillRect(bitmap.context.get(), CGRectMake(2, 2, 5, 5));
    require(bitmap.rgba[(253 * Bitmap::side + 2) * 4] == 255 || bitmap.rgba[(2 * Bitmap::side + 2) * 4] == 255,
        "renderer restores caller clip");
}

void raster_batch_boundaries() {
    const auto last = snapshot(dataset({{{0, {0, 1000, 1000}}, {1, {0, 0, 0}}}}));
    Bitmap expected;
    expected.render(*last, paths_only());
    for (const std::size_t count : {1024U, 1025U}) {
        std::vector<SpacecraftPathSample> path;
        for (std::size_t i = 0; i < count; ++i) path.push_back({static_cast<double>(i), {0, 1000, 1000}});
        path.push_back({static_cast<double>(count), {0, 0, 0}});
        const auto state = snapshot(dataset({path}), count);
        Bitmap actual;
        actual.render(*state, paths_only());
        require(actual.rgba == expected.rgba, "last segment drawn at and after stroke batch boundary");
        require(segments(*state, paths_only()).size() == count, "batch boundary never truncates original samples");
    }
}

void local_data(const std::filesystem::path& directory) {
    const auto model = load_spacecraft_browser_model(directory);
    const auto state = evaluate_spacecraft_snapshot(model, 2451545);
    const auto& data = model->model().dataset();
    std::size_t expected = 0;
    const NSRect map = NSMakeRect(32, 32, 192, 192);
    for (std::size_t definition = 0; definition < data.definitions.size(); ++definition) {
        if (!state->positions[definition]) continue;
        const auto& path = data.trajectories.at(*data.definitions[definition].trajectory_index).path_samples;
        bool previous = false;
        for (const auto& sample : path) {
            const auto& value = sample.coordinate_values;
            const bool projected = project_solar({value[0], value[1], value[2]}, camera(), 192, 192).has_value();
            if (previous && projected) ++expected;
            previous = projected;
        }
    }
    std::size_t actual = 0;
    const auto started = std::chrono::steady_clock::now();
    visit_spacecraft_path_segments(*state, camera(), map, paths_only(), [&](const auto& line) {
        ++actual;
        require(line.second_record_index == line.first_record_index + 1, "local segment retains adjacent raw indices");
    });
    const auto elapsed = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - started).count();
    require(actual == expected, "local paths have no fixed row limit or deduplication");
    require(state->positions.size() == data.definitions.size(), "local all definitions retained");
    std::cout << "Local definitions=" << data.definitions.size() << " segments=" << actual << " visit_ms=" << elapsed << '\n';
}
} // namespace

int main(int argc, char** argv) {
    @autoreleasepool {
        try {
            positions_and_picking(); path_boundaries(); inconsistent_snapshots(); raster_and_quality(); raster_batch_boundaries();
            if (argc > 1) local_data(argv[1]);
            std::cout << "Spacecraft renderer: " << checks << " checks PASS\n";
            return 0;
        } catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
