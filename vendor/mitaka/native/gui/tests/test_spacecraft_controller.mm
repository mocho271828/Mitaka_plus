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
void menuAction(NSMenuItem *item) { [NSApp sendAction:item.action to:item.target from:item]; }
NSMenu *contextMenu(NSTableView *table, NSPoint point) {
    const NSPoint windowPoint = [table convertPoint:point toView:nil];
    NSEvent *event = [NSEvent mouseEventWithType:NSEventTypeRightMouseDown location:windowPoint
        modifierFlags:0 timestamp:0 windowNumber:table.window.windowNumber context:nil eventNumber:0 clickCount:1 pressure:1];
    return [table menuForEvent:event];
}
NSMenu *contextMenuForRow(NSTableView *table, NSInteger row) {
    const NSRect bounds = [table rectOfRow:row];
    return contextMenu(table, NSMakePoint(NSMidX(bounds), NSMidY(bounds)));
}
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
    __block unsigned selections = 0;
    controller.chooseObject = ^(NSUInteger index, BOOL centerView) {
        selected = index; centered = centerView; ++selections;
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
    [controller.window.contentView layoutSubtreeIfNeeded];
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    const auto beforeMenu = selections;
    NSMenu *menu = contextMenuForRow(table, 1);
    require(menu.numberOfItems == 2 && table.selectedRow == 1 && selections == beforeMenu,
        "context menu selects the clicked duplicate without invoking an action");
    NSMenuItem *contextSelect = [menu itemAtIndex:0], *contextCenter = [menu itemAtIndex:1];
    require([contextSelect.title isEqualToString:select.title] && [contextCenter.title isEqualToString:center.title],
        "context actions use the existing button wording");
    NSString *unresolved = [controller tableView:table objectValueForTableColumn:table.tableColumns[2] row:1];
    require([unresolved isEqualToString:@"未解決・診断あり"], "context fixture retains an unresolved source definition");
    menuAction(contextSelect);
    require(selected == 1036 && !centered && selections == beforeMenu + 1,
        "context selection passes the clicked original index despite duplicate names and unresolved position");
    menuAction(contextCenter);
    require(selected == 1036 && centered && selections == beforeMenu + 2,
        "context center passes unresolved source identity to the existing guarded focus callback");
    NSMenuItem *invalidItem = [contextCenter copy];
    invalidItem.representedObject = @"invalid generation";
    menuAction(invalidItem);
    invalidItem.representedObject = nil;
    menuAction(invalidItem);
    require(selections == beforeMenu + 2, "context items without a numeric generation must be ignored");
    require(contextMenu(table, NSMakePoint(-5, -5)) == nil && table.selectedRow == 1 && selections == beforeMenu + 2,
        "empty-space context click must preserve the selection and produce no menu");
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    menuAction(contextCenter);
    require(selections == beforeMenu + 2, "an old menu must not act on a different selected row");
    [source selectItemWithTitle:@"spacecraft/second.dat"]; action(source); waitForResult(count);
    require(table.numberOfRows == 1, "source filter selects only the requested catalog");
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    action(select);
    require(selected == 1036, "duplicate source selection returns its original index");
    const auto afterFilter = selections;
    menuAction(contextCenter);
    require(selections == afterFilter, "source filtering invalidates a menu even when the same original index is selected");
    NSString *provenance = [controller tableView:table objectValueForTableColumn:table.tableColumns[1] row:0];
    require([provenance containsString:@"spacecraft/second.dat"], "selected duplicate retains its source provenance");
    menu = contextMenuForRow(table, 0);
    contextCenter = [menu itemAtIndex:1];
    [controller setModel:model snapshot:frame];
    menuAction(contextCenter);
    require(selections == afterFilter && table.numberOfRows == 0,
        "model reload invalidates a menu while the new search is pending");
    waitForResult(count);
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    menuAction(contextCenter);
    require(selections == afterFilter, "model reload invalidates a menu after the same source row returns");

    search.stringValue = @""; action(search); waitForResult(count);
    action(next); waitForResult(count);
    menu = contextMenuForRow(table, 1);
    contextCenter = [menu itemAtIndex:1];
    menuAction(contextCenter);
    require(selected == 501 && centered && selections == afterFilter + 1,
        "context menu on a later page uses the original index rather than the visible row");
    action(previous);
    menuAction(contextCenter);
    require(selections == afterFilter + 1 && table.numberOfRows == 0,
        "page navigation invalidates the previous page menu immediately");
    waitForResult(count);
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
    menuAction(contextCenter);
    require(selections == afterFilter + 1, "previous page cannot reuse a menu for the same visible row number");
    [source selectItemAtIndex:0]; search.stringValue = @"Spacecraft1035"; action(search); waitForResult(count);
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [controller showWindow:nil];
    [controller.window.contentView layoutSubtreeIfNeeded];
    [controller.window displayIfNeeded];
    auto nextFrame = std::make_shared<SpacecraftSnapshot>(*frame);
    nextFrame->julian_date = 2451546;
    nextFrame->positions[1035] = Vec3{1, 2, 3};
    nextFrame->positioned_count = 1;
    auto prepared = [controller prepareSnapshot:nextFrame];
    require([details.string containsString:@"2451545"], "preparing does not update visible details");
    [controller commitPreparedDate:std::move(prepared)];
    require([details.string containsString:@"2451545"], "commit defers visible details update");
    [controller finishDateUpdate];
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
    rejected = false;
    try { (void)[controller prepareSnapshot:frame]; } catch (const std::invalid_argument&) { rejected = true; }
    require(rejected && table.numberOfRows == 0, "invalid candidate is rejected without changing the browser");
    [controller setModel:{} snapshot:{}];
    require(table.numberOfRows == 0 && source.numberOfItems == 1 && !next.enabled && !select.enabled,
        "clearing the model removes old source choices and selection");
    menuAction(contextCenter);
    require(contextMenu(table, NSMakePoint(10, 10)) == nil && selections == afterFilter + 1,
        "empty source cannot expose or execute a stale context action");
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
