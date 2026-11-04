#import "SpacecraftController.h"
#include <iostream>
#include <stdexcept>

namespace {
unsigned checks = 0;
void require(bool value, const char *message) { ++checks; if (!value) throw std::runtime_error(message); }
NSView *findView(NSView *root, bool (^matches)(NSView *)) {
    if (matches(root)) return root;
    for (NSView *child in root.subviews) if (NSView *found = findView(child, matches)) return found;
    return nil;
}
NSButton *button(NSView *root, NSString *title) {
    return (NSButton *)findView(root, ^bool(NSView *view) {
        return [view isKindOfClass:NSButton.class] && [((NSButton *)view).title isEqualToString:title];
    });
}
void action(NSControl *control) { [NSApp sendAction:control.action to:control.target from:control]; }
void waitForResult(NSTextField *label) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5];
    while ([label.stringValue containsString:@"検索中"] && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    require([label.stringValue containsString:@"該当"], "async search completed without error");
}
void tests() {
    using namespace mitaka;
    using namespace mitaka::gui;
    SpacecraftController *controller = [[SpacecraftController alloc] init];
    NSView *root = controller.window.contentView;
    NSSearchField *search = (NSSearchField *)findView(root, ^bool(NSView *view) { return [view isKindOfClass:NSSearchField.class]; });
    NSTableView *table = (NSTableView *)findView(root, ^bool(NSView *view) { return [view isKindOfClass:NSTableView.class]; });
    NSTextField *count = (NSTextField *)findView(root, ^bool(NSView *view) { return [view.accessibilityIdentifier isEqualToString:@"spacecraft-result-count"]; });
    NSTextView *details = (NSTextView *)findView(root, ^bool(NSView *view) { return [view isKindOfClass:NSTextView.class]; });
    NSPopUpButton *source = (NSPopUpButton *)findView(root, ^bool(NSView *view) { return [view.accessibilityIdentifier isEqualToString:@"spacecraft-source-filter"]; });
    NSButton *next = button(root, @"次の500件"), *previous = button(root, @"前の500件");
    NSButton *select = button(root, @"選択・診断を表示"), *center = button(root, @"選択して3Dの中心へ");
    require(search && table && count && details && source && next && previous && select && center, "browser controls are present");
    SpacecraftDataset dataset;
    dataset.sources.push_back({"spacecraft/first.dat", {}, SpacecraftSourceKind::definition, {}, true, true, 1036});
    dataset.sources.push_back({"spacecraft/second.dat", {}, SpacecraftSourceKind::definition, {}, true, true, 1});
    for (std::size_t i = 0; i < 1037; ++i) {
        SpacecraftDefinition record;
        record.source_index = i < 1036 ? 0 : 1;
        record.fields.push_back({"Name", i == 1036 ? "Spacecraft0" : "Spacecraft" + std::to_string(i), 0, 0, 1, {}});
        dataset.definitions.push_back(std::move(record));
    }
    dataset.diagnostics.push_back({SpacecraftDiagnosticCode::missing_source, "spacecraft/missing.pth", {}, 0, "missing test source"});
    auto model = std::make_shared<SpacecraftBrowserModel>(std::make_shared<SpacecraftPositionModel>(std::move(dataset)));
    auto frame = std::make_shared<SpacecraftSnapshot>();
    frame->model = model;
    frame->julian_date = 2451545;
    frame->positions.resize(model->model().dataset().definitions.size());
    frame->evaluations.resize(frame->positions.size());
    [controller setModel:model snapshot:frame];
    require(table.numberOfRows == 0 && !next.enabled, "search invalidates old rows immediately");
    waitForResult(count);
    require(table.numberOfRows == 500 && next.enabled && !previous.enabled, "first page uses bounded visible row references");
    require([count.stringValue containsString:@"1037"], "count reflects every original row");
    require([details.string containsString:@"missing test source"],
        "source diagnostics are exposed before row selection");
    require(source.numberOfItems == 3, "separate source choices retain all system catalogs");
    action(next); waitForResult(count);
    id title = [controller tableView:table objectValueForTableColumn:table.tableColumns.firstObject row:0];
    require([title isEqualToString:@"Spacecraft500"] && previous.enabled, "next page preserves source indices");
    action(previous); waitForResult(count);
    search.stringValue = @"1"; action(search);
    search.stringValue = @"absent"; action(search);
    search.stringValue = @"Spacecraft1035"; action(search);
    waitForResult(count);
    require(table.numberOfRows == 1 && !next.enabled && !previous.enabled, "latest search generation wins");
    __block NSUInteger selected = NSNotFound;
    __block BOOL centered = NO;
    controller.chooseObject = ^(NSUInteger index, BOOL centerView) {
        selected = index; centered = centerView;
        require(NSThread.isMainThread, "selection callback runs on main thread");
    };
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    require(select.enabled && center.enabled, "unresolved source rows remain selectable");
    require(details.string.length > 0 && [details.string containsString:@"Spacecraft1035"], "row details identify the selected original spacecraft");
    action(select);
    require(selected == 1035 && !centered, "select callback identifies source row rather than repeated number");
    action(center);
    require(centered, "center intent is passed to guarded solar focus");
    search.stringValue = @"Spacecraft0"; action(search); waitForResult(count);
    require(table.numberOfRows == 2, "same-name rows from different sources remain separate");
    [source selectItemWithTitle:@"spacecraft/second.dat"]; action(source); waitForResult(count);
    require(table.numberOfRows == 1, "source filter selects only the requested catalog");
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    action(select);
    require(selected == 1036, "duplicate source selection returns its original index");
    NSString *provenance = [controller tableView:table objectValueForTableColumn:table.tableColumns[1] row:0];
    require([provenance containsString:@"spacecraft/second.dat"], "selected duplicate retains its source provenance");
    [source selectItemAtIndex:0]; search.stringValue = @"Spacecraft1035"; action(search); waitForResult(count);
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [controller showWindow:nil];
    [controller.window.contentView layoutSubtreeIfNeeded];
    [controller.window displayIfNeeded];
    auto nextFrame = std::make_shared<SpacecraftSnapshot>(*frame);
    nextFrame->julian_date = 2451546;
    nextFrame->positions[1035] = Vec3{1, 2, 3};
    nextFrame->positioned_count = 1;
    [controller setSnapshot:nextFrame];
    NSString *state = [controller tableView:table objectValueForTableColumn:table.tableColumns[2] row:0];
    require(table.selectedRow == 0 && [state isEqualToString:@"位置評価済み"],
        "snapshot update retains the source selection and updates evaluated state");
    require([details.string containsString:@"2451546"] && [details.string containsString:@"X 1.00000000"],
        "visible details use the latest snapshot position and date");
    [controller.window orderOut:nil];
    [controller setSnapshot:frame];
    [controller showWindow:nil];
    require(table.selectedRow == 0 && [details.string containsString:@"2451545"]
        && [details.string containsString:@"位置を表示できません"],
        "reopening refreshes hidden snapshot changes without clearing selection");
    auto replacement = std::make_shared<SpacecraftBrowserModel>(std::make_shared<SpacecraftPositionModel>(SpacecraftDataset{}));
    [controller setModel:replacement snapshot:{}];
    waitForResult(count);
    require(table.numberOfRows == 0 && !select.enabled, "visible source replacement clears old high-index selection before new dataset");
    [controller setModel:model snapshot:frame];
    search.stringValue = @"1"; action(search);
    [controller setModel:replacement snapshot:{}];
    waitForResult(count);
    require(table.numberOfRows == 0, "source replacement cancels previous queued search results");
    bool rejected = false;
    try { [controller setSnapshot:frame]; } catch (const std::invalid_argument&) { rejected = true; }
    require(rejected, "snapshot from another source model is rejected");
    require(table.numberOfRows == 0 && !select.enabled, "invalid snapshot leaves the current model and selection unchanged");
    [controller setModel:{} snapshot:{}];
    require(table.numberOfRows == 0 && source.numberOfItems == 1 && !next.enabled && !select.enabled,
        "clearing the model removes old source choices and selection");
    [controller showWindow:nil];
    [controller.window.contentView layoutSubtreeIfNeeded];
    [controller.window displayIfNeeded];
    require(select.bounds.size.width > 80 && center.bounds.size.width > 100, "action buttons have readable layout space");
    [controller close];
}
}
int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try { tests(); std::cout << "Spacecraft controller tests passed: " << checks << " checks\n"; return 0; }
        catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
