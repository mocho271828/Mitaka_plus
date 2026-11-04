#import "GalaxyController.h"
#include <cmath>
#include <functional>
#include <iostream>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
@interface GalaxyView (TestAccess)
- (void)requestImage;
@end
@interface GalaxyController (TestAccess)
- (void)selectOriginalRow:(id)sender;
- (void)sourceChanged:(id)sender;
- (void)visibilityChanged:(id)sender;
@end
// controller の世代管理を、WindowServer の被覆判定と切り離して検証する。
@interface GalaxyTestWindow : NSWindow
@end
@implementation GalaxyTestWindow
- (NSWindowOcclusionState)occlusionState { return NSWindowOcclusionStateVisible; }
@end
namespace {
std::size_t checks = 0;
void check(bool condition, const char* message) { ++checks; if (!condition) throw std::runtime_error(message); }
void waitFor(const std::function<bool()>& ready, const char* message, GalaxyView *view) {
    NSDate *end = [NSDate dateWithTimeIntervalSinceNow:10];
    while (!ready() && end.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    if (!ready()) std::cerr << "status=" << view.renderStatus.UTF8String
        << " visible=" << view.window.visible << " hidden=" << view.hiddenOrHasHiddenAncestor
        << " occlusion=" << view.window.occlusionState << " renderStarted="
        << [[view valueForKey:@"renderStarted"] boolValue] << "\n";
    check(ready(), message);
}
NSView *find(NSView *view, NSString *identifier) {
    if ([view.accessibilityIdentifier isEqualToString:identifier]) return view;
    for (NSView *child in view.subviews) if (NSView *found = find(child, identifier)) return found;
    return nil;
}
std::shared_ptr<const GalaxySpatialModel> fixture(std::size_t count = 1) {
    std::vector<SdssRecord> rows(count, {{0, 0}, 1, 0});
    rows.push_back({{0, 0}, -1, 0});
    const auto sdss = evaluate_sdss_spatial_snapshot(std::make_shared<const SdssSpatialModel>(
        std::vector<SdssSpatialSource>{{SdssKind::galaxy, "custom/a.dat", rows},
            {SdssKind::galaxy, "custom/a.dat", {{{0, 0}, 0.5, 0}}}, {SdssKind::quasar, "empty", {}}}));
    return std::make_shared<const GalaxySpatialModel>(std::vector<GalaxySpatialSource>{
        GalaxySdssSource{sdss, 0}, GalaxySdssSource{sdss, 1}, GalaxySdssSource{sdss, 2}});
}
void controller_tests() {
    GalaxyController *controller = [[GalaxyController alloc] init];
    const auto model = fixture();
    [controller setModel:model diagnostics:@"独自dataを保持"];
    GalaxyView *view = controller.galaxyView;
    auto *source = (NSPopUpButton *)find(controller.window.contentView, @"galaxy-source");
    auto *ordinal = (NSTextField *)find(controller.window.contentView, @"galaxy-ordinal");
    auto *error = (NSTextField *)find(controller.window.contentView, @"galaxy-error");
    auto *focus = (NSButton *)find(controller.window.contentView, @"galaxy-focus");
    auto *select = (NSButton *)find(controller.window.contentView, @"galaxy-select-row");
    auto *details = (NSTextView *)find(controller.window.contentView, @"galaxy-details");
    check(source && ordinal && error && focus && select && details, "native controls have stable accessibility identifiers");
    check(source.numberOfItems == 3 && [ordinal.stringValue isEqualToString:@"1"], "all sources including duplicate paths and empty sources retained");
    ordinal.stringValue = @"2"; [controller selectOriginalRow:nil];
    check(view.selectedRecord && view.selectedRecord->ordinal == 1, "invalid-position original row is selectable");
    check(!focus.enabled && [details.string containsString:@"位置を生成できない"], "invalid row exposes diagnostic and disables focus");
    const unichar embeddedNul[] = {'1', 0, 'j', 'u', 'n', 'k'};
    for (NSString *invalid in @[@"0", @"3", @"-1", @"+1", @" 1", @"1 ", @"1.0", @"1,000", @"١", @"18446744073709551616", @"",
            [NSString stringWithCharacters:embeddedNul length:6]]) {
        ordinal.stringValue = invalid; [controller selectOriginalRow:nil];
        check(view.selectedRecord && view.selectedRecord->ordinal == 1 && error.stringValue.length > 0,
              "invalid decimal input preserves original selection");
    }
    [source selectItemAtIndex:1]; [controller sourceChanged:nil];
    check([ordinal.stringValue isEqualToString:@"1"], "source change writes ungrouped ordinal");
    [controller selectOriginalRow:nil];
    check(view.selectedRecord && view.selectedRecord->source_index == 1 && focus.enabled, "same-path distinct source selected by index");
    auto *family = (NSButton *)find(controller.window.contentView, @"galaxy-family-0");
    family.state = NSControlStateValueOff; [controller visibilityChanged:nil];
    check(!view.galaxyVisibility.sdss_galaxies && view.selectedRecord && focus.enabled,
          "family visibility does not erase original-row inspection or focus");
    const auto oldCamera = view.galaxyCamera;
    check([view focusSelection] && view.galaxyCamera.target.x_pc != oldCamera.target.x_pc, "focus uses parsec position");
    check(view.galaxyCamera.distance_pc == oldCamera.distance_pc, "focus preserves camera distance");
    [controller setModel:model diagnostics:@"same"];
    check(view.selectedRecord && view.selectedRecord->source_index == 1, "same model retains selection");
    [source selectItemAtIndex:2]; [controller sourceChanged:nil];
    check(!select.enabled && !ordinal.enabled, "empty source is present and not selectable");
    [controller setModel:fixture() diagnostics:@"new"];
    check(!view.selectedRecord && [ordinal.stringValue isEqualToString:@"1"], "replacement model resets IDs and ordinal");
    [controller setModel:nullptr diagnostics:@"optional source missing"];
    [controller selectOriginalRow:nil];
    check(!view.model && !view.selectedRecord && source.numberOfItems == 0 && !select.enabled,
          "unloaded model rejects retained controls");
    check([details.string containsString:@"optional source missing"], "loader diagnostics stay visible without a model");
    [controller invalidate]; [controller close];
}
void view_tests() {
    GalaxyTestWindow *window = [[GalaxyTestWindow alloc] initWithContentRect:NSMakeRect(0, 0, 320, 240)
        styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
    window.releasedWhenClosed = NO;
    GalaxyView *view = [[GalaxyView alloc] initWithFrame:NSMakeRect(0, 0, 320, 240)];
    window.contentView = view;
    constexpr std::size_t fixtureCount = 4096;
    const auto model = fixture(fixtureCount);
    [view setModel:model];
    [view requestImage];
    check([view valueForKey:@"image"] == nil, "hidden window does not start rendering");
    [window orderFront:nil];
    // main-thread callbacks cannot run while this test queues conflicting generations.
    dispatch_queue_t queue = [view valueForKey:@"queue"];
    dispatch_suspend(queue);
    [view setGalaxyCamera:{{0, 0, 0}, 0, 0, 10}];
    [view requestImage];
    const bool oldImageQueued = [[view valueForKey:@"renderStarted"] boolValue];
    view.hidden = YES;
    [view setGalaxyCamera:{{0, 0, 0}, 15, 10, 20}];
    [view requestImage];
    const bool hiddenImageAbsent = [view valueForKey:@"image"] == nil;
    view.hidden = NO; [view requestImage];
    dispatch_resume(queue);
    check(oldImageQueued && hiddenImageAbsent, "hidden view invalidates queued old bitmap");
    waitFor([&] { return [view valueForKey:@"image"] != nil; }, "visible view image timed out", view);
    check(view.galaxyCamera.yaw_deg == 15 && view.galaxyCamera.distance_pc == 20,
          "show uses the latest camera snapshot after cancellation");
    NSImage *image = [view valueForKey:@"image"];
    [view selectRecord:GalaxySpatialRecordId{GalaxySpatialFamily::sdss_galaxy, 0, fixtureCount}];
    [view requestImage];
    check([view valueForKey:@"image"] == image, "selection-only updates preserve the cached bitmap");
    const auto unchanged = view.galaxyCamera;
    check(![view focusSelection] && view.galaxyCamera.distance_pc == unchanged.distance_pc,
          "invalid-position focus does not move the camera");
    [view setGalaxyCamera:{{0, 0, 0}, 0, 0, 10}];
    [view requestImage]; waitFor([&] { return [view valueForKey:@"image"] != nil; }, "camera change image timed out", view);
    image = [view valueForKey:@"image"];
    [view setBoundsOrigin:NSMakePoint(13, 19)];
    check([view valueForKey:@"image"] == image, "bounds translation reuses the bitmap");
    const auto point = GalaxyProjector(view.galaxyCamera, 320, 240).project(*model->row(model->record_id(0)).position);
    check(point.has_value(), "click fixture projects");
    const auto expectedPick = pick_galaxy_spatial_row(*model, GalaxyProjector(view.galaxyCamera, 320, 240),
        view.galaxyVisibility, point->x, point->y, 8);
    check(expectedPick && expectedPick->source_index == 0 && expectedPick->ordinal == 0,
          "overlapping fixture expects the nearer original row");
    NSPoint center = [view convertPoint:NSMakePoint(13 + point->x, 19 + point->y) toView:nil];
    NSPoint blank = [view convertPoint:NSMakePoint(18, 24) toView:nil];
    NSEvent *first = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp location:center modifierFlags:0
        timestamp:0 windowNumber:window.windowNumber context:nil eventNumber:1 clickCount:1 pressure:0];
    NSEvent *last = [NSEvent mouseEventWithType:NSEventTypeLeftMouseUp location:blank modifierFlags:0
        timestamp:0 windowNumber:window.windowNumber context:nil eventNumber:2 clickCount:1 pressure:0];
    [view mouseUp:first];
    waitFor([&] { return view.selectedRecord && view.selectedRecord->ordinal == 0; }, "projected row selection timed out", view);
    check(view.selectedRecord && view.selectedRecord->source_index == 0, "translated bounds pick the projected original row");
    [view selectRecord:GalaxySpatialRecordId{GalaxySpatialFamily::sdss_galaxy, 0, fixtureCount}];
    dispatch_suspend(queue);
    [view mouseUp:first]; [view mouseUp:last];
    dispatch_resume(queue);
    waitFor([&] { return !view.selectedRecord.has_value(); }, "blank row selection timed out", view);
    check(!view.selectedRecord, "later blank pick wins over an earlier hit");
    dispatch_suspend(queue);
    [view mouseUp:first];
    [view setModel:fixture()];
    dispatch_resume(queue);
    waitFor([&] { return [view valueForKey:@"image"] != nil; }, "replacement model image timed out", view);
    check(!view.selectedRecord, "model replacement discards old asynchronous pick");
    [view invalidatePendingWork]; [window close];
}
}
int main() {
    @autoreleasepool {
        try {
            [NSApplication sharedApplication];
            [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
            controller_tests(); view_tests();
            std::cout << "Galaxy controller/view: " << checks << " checks passed\n"; return 0;
        } catch (const std::exception& error) {
            std::cerr << "Galaxy controller/view: " << error.what() << '\n'; return 1;
        }
    }
}
