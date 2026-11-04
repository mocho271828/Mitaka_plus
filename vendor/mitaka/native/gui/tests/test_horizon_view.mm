#import "HorizonView.h"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>

namespace {
using namespace mitaka;
using namespace mitaka::gui;
unsigned checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
template <typename Exception, typename Operation> void rejects(Operation operation) {
    try { operation(); }
    catch (const Exception&) { ++checks; return; }
    throw std::runtime_error("expected exception was not raised");
}
void near(double actual, double expected) {
    check(std::abs(actual - expected) < 1e-9, "numeric mismatch");
}
void test_state(HorizonView *view) {
    __block unsigned viewportChanges = 0;
    view.viewportChanged = ^{ ++viewportChanges; };
    [view setViewport:{725, 45, 2}];
    near([view viewport].center_azimuth_deg, 5);
    near([view viewport].center_altitude_deg, 45);
    [view zoomIn];
    near([view viewport].zoom, 3);
    [view zoomOut];
    near([view viewport].zoom, 2);
    [view resetView];
    near([view viewport].center_azimuth_deg, 180);
    near([view viewport].center_altitude_deg, 0);
    near([view viewport].zoom, 1);
    check(viewportChanges == 4, "viewport callback mismatch");
    const double nan = std::numeric_limits<double>::quiet_NaN();
    rejects<std::invalid_argument>([&] { [view setViewport:{nan, 0, 1}]; });
    near([view viewport].center_azimuth_deg, 180);
    [view setObserverSite:{-90, -180}];
    near([view observerSite].latitude_deg, -90);
    rejects<std::invalid_argument>([&] { [view setObserverSite:{91, 0}]; });
    rejects<std::invalid_argument>([&] { [view setObserverSite:{0, nan}]; });
    near([view observerSite].latitude_deg, -90);
    SkyBodies bodies{};
    [view setBodies:bodies julianDate:2451545];
    rejects<std::invalid_argument>([&] { [view setBodies:bodies julianDate:nan]; });
    near(view.julianDate, 2451545);
    rejects<std::out_of_range>([&] { [view setBodies:bodies julianDate:1e10]; });
    near(view.julianDate, 2451545);
    view.magnitudeLimit = 7;
    rejects<std::invalid_argument>([&] { view.magnitudeLimit = nan; });
    near(view.magnitudeLimit, 7);
    check(![view selectStarHIP:32349] && view.visibleStarCount == 0, "empty model changed selection/count");
    [view focusSelection];
    [view selectBody:0];
    [view setObserverSite:{35.68, 139.76}];
    view.viewportChanged = nil;
}
void test_drawing(HorizonView *view) {
    NSBitmapImageRep *bitmap = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    check(bitmap != nil, "could not create bitmap");
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:bitmap];
    const double scaleX = bitmap.pixelsWide / view.bounds.size.width;
    const double scaleY = bitmap.pixelsHigh / view.bounds.size.height;
    const auto sky = [[bitmap colorAtX:100 * scaleX y:100 * scaleY] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
    const auto ground = [[bitmap colorAtX:100 * scaleX y:380 * scaleY] colorUsingColorSpace:NSColorSpace.sRGBColorSpace];
    check(sky && ground && ground.redComponent > sky.redComponent + 0.03, "ground was not distinguished from sky");
}
void test_data(HorizonView *view, const char *directory) {
    auto model = std::make_shared<SkyModel>(SkyModel::load(directory));
    const double jd = std::clamp(2451545.0, model->time_range().first, model->time_range().second);
    const auto bodies = model->bodies(jd);
    [view setModel:model bodies:bodies];
    [view setBodies:bodies julianDate:jd];
    const auto count = view.visibleStarCount;
    check(count > 1000 && count < model->stars().size(), "full sky magnitude filter failed");
    __block NSString *description;
    view.selectionChanged = ^(NSString *text) { description = text; };
    check([view selectStarHIP:32349], "Sirius HIP could not be selected");
    check([description containsString:@"HIP 32349"] && [description containsString:@"高度"], "selection description missing horizon coordinates");
    [view focusSelection];
    check([view viewport].zoom >= 4 && view.visibleStarCount < count, "focus did not reduce sky extent");
    const auto& star = model->stars()[*model->star_index(32349)];
    const auto horizontal = equatorial_to_horizontal({star.right_ascension_degrees, star.declination_degrees},
                                                     [view observerSite], jd);
    near([view viewport].center_azimuth_deg, horizontal.azimuth_deg);
    check(![view selectStarHIP:-1] && [description containsString:@"HIP 32349"], "missing HIP changed selection");
    [view selectBody:0];
    check([description containsString:@"太陽"] && [description containsString:@"地心距離"], "body selection was not described");
    [view resetView];
    test_drawing(view);
    [view setModel:nullptr bodies:bodies];
    check(view.visibleStarCount == 0, "unloading model left stars");
    view.selectionChanged = nil;
}
}

int main(int argc, char **argv) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            HorizonView *view = [[HorizonView alloc] initWithFrame:NSMakeRect(0, 0, 800, 480)];
            test_state(view);
            test_drawing(view);
            if (argc == 2) test_data(view, argv[1]);
            std::cout << "horizon view: " << checks << " checks passed\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "horizon view: " << error.what() << '\n';
            return 1;
        }
    }
}
