#import "SatelliteController.h"
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
    SatelliteController *controller = [[SatelliteController alloc] init];
    NSView *root = controller.window.contentView;
    NSSearchField *search = (NSSearchField *)findView(root, ^bool(NSView *view) { return [view isKindOfClass:NSSearchField.class]; });
    NSTableView *table = (NSTableView *)findView(root, ^bool(NSView *view) { return [view isKindOfClass:NSTableView.class]; });
    NSTextField *count = (NSTextField *)findView(root, ^bool(NSView *view) { return [view.accessibilityIdentifier isEqualToString:@"satellite-result-count"]; });
    NSTextView *details = (NSTextView *)findView(root, ^bool(NSView *view) { return [view isKindOfClass:NSTextView.class]; });
    NSPopUpButton *source = (NSPopUpButton *)findView(root, ^bool(NSView *view) { return [view.accessibilityIdentifier isEqualToString:@"satellite-source-filter"]; });
    NSButton *next = button(root, @"次の500件"), *previous = button(root, @"前の500件");
    NSButton *select = button(root, @"選択・診断を表示"), *center = button(root, @"選択して3Dの中心へ");
    require(search && table && count && details && source && next && previous && select && center, "browser controls are present");
    SatelliteDataset dataset;
    dataset.sources.push_back({"ssystem.dat", {}, SatelliteSourceKind::system_definition, "source A", true, true, true, 1038});
    dataset.sources.push_back({"ssystem_jp.dat", {}, SatelliteSourceKind::system_definition, "source B", true, true, true, 1038});
    for (const auto& sourceRecord : dataset.sources) {
        SatelliteDefinition parent;
        parent.id = {sourceRecord.key, 0};
        parent.kind = SatelliteDefinitionKind::planet;
        parent.fields.push_back({"Name", "Jupiter", 0, 0, 1, {}});
        dataset.definitions.push_back(std::move(parent));
    }
    for (std::size_t i = 0; i < 1037; ++i) {
        SatelliteDefinition record;
        record.id = {i < 1036 ? "ssystem.dat" : "ssystem_jp.dat", i + 1};
        record.kind = SatelliteDefinitionKind::satellite;
        record.parent_ordinal = 0;
        record.fields.push_back({"Name", i == 1036 ? "Satellite0" : "Satellite" + std::to_string(i), 0, 0, 1, {}});
        dataset.definitions.push_back(std::move(record));
    }
    dataset.diagnostics.push_back({SatelliteDiagnosticCode::missing_source, "orbits/missing.dat", {}, 0, 0, "source", "missing test source"});
    auto model = std::make_shared<SatelliteBrowserModel>(std::make_shared<SatelliteModel>(std::move(dataset)));
    auto frame = std::make_shared<SatelliteSnapshot>();
    frame->model = model;
    frame->julian_date = 2451545;
    frame->positions.resize(model->model().records().size());
    frame->diagnostics.push_back("snapshot diagnostic");
    [controller setModel:model snapshot:frame];
    __block auto display = std::make_shared<SatelliteDisplayModel>(std::shared_ptr<const SatelliteModel>(model,&model->model()));
    [controller setDisplayModel:display];
    __block unsigned displayChanges = 0;
    __weak SatelliteController *weakController = controller;
    controller.changeDisplayOptions = ^(SatelliteDisplayOptions options) {
        auto updated = std::make_shared<SatelliteDisplayModel>(*display);
        updated->set_options(options); display = updated; ++displayChanges;
        [weakController setDisplayModel:display];
    };
    controller.changeDisplaySelection = ^(const std::vector<SatelliteRecordId>& ids) {
        auto updated = std::make_shared<SatelliteDisplayModel>(*display);
        updated->set_selected_ids(ids); display = updated; ++displayChanges;
        [weakController setDisplayModel:display];
    };
    require(table.numberOfRows == 0 && !next.enabled, "search invalidates old rows immediately");
    waitForResult(count);
    require(table.numberOfRows == 500 && next.enabled && !previous.enabled, "first page uses bounded visible row references");
    require([count.stringValue containsString:@"1037"], "count reflects every original row");
    require([details.string containsString:@"missing test source"] && [details.string containsString:@"snapshot diagnostic"],
        "source and snapshot diagnostics are exposed before row selection");
    require(source.numberOfItems == 3, "separate source choices retain all system catalogs");
    for (NSString *title in @[@"衛星を表示",@"名称",@"瞬時軌道",@"表示集合のみ"]) {
        NSButton *flag = button(root,title);
        require(flag && flag.enabled,"all four display controls are available");
        const auto previous = flag.state;
        flag.state = previous == NSControlStateValueOn ? NSControlStateValueOff : NSControlStateValueOn;
        action(flag);
        require(flag.state != previous,"checkbox readback follows authoritative display callback");
    }
    require(displayChanges == 4 && !display->options().visible && display->options().labels &&
        display->options().orbits && display->options().selected_only,"all four flags reach the display model");
    id parentTitle = [controller tableView:table objectValueForTableColumn:table.tableColumns[1] row:0];
    require([parentTitle isEqualToString:@"Jupiter"], "parent body is displayed from the model");
    action(next); waitForResult(count);
    id title = [controller tableView:table objectValueForTableColumn:table.tableColumns.firstObject row:0];
    require([title isEqualToString:@"Satellite500"] && previous.enabled, "next page preserves source indices");
    action(previous); waitForResult(count);
    search.stringValue = @"1"; action(search);
    search.stringValue = @"absent"; action(search);
    search.stringValue = @"Satellite1035"; action(search);
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
    require(details.string.length > 0 && [details.string containsString:@"Satellite1035"], "row details identify the selected original satellite");
    action(select);
    require(selected == 1035 && !centered, "select callback identifies source row rather than repeated number");
    action(center);
    require(centered, "center intent is passed to guarded solar focus");
    search.stringValue = @"Satellite0"; action(search); waitForResult(count);
    require(table.numberOfRows == 2, "same-name rows from different sources remain separate");
    [source selectItemWithTitle:@"ssystem_jp.dat"]; action(source); waitForResult(count);
    require(table.numberOfRows == 1, "source filter selects only the requested catalog");
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    action(select);
    require(selected == 1036, "duplicate source selection returns its original index");
    NSString *provenance = [controller tableView:table objectValueForTableColumn:table.tableColumns[2] row:0];
    require([provenance containsString:@"ssystem_jp.dat"], "selected duplicate retains its source provenance");
    action(button(root,@"表示集合に追加"));
    require(display->selected_ids().size() == 1 && display->contains(display->id_at(1036)) &&
        !display->contains(display->id_at(0)),"same-name membership uses exact source and ordinal");
    require(selected == 1036 && table.selectedRow == 0,"membership preserves clicked selection and filtered row");
    action(button(root,@"全原行を集合へ"));
    require(display->selected_ids().size() == 1037,"select all includes every page and source, even under a filter");
    action(button(root,@"集合を空にする"));
    require(display->selected_ids().empty() && selected == 1036,"clearing membership preserves clicked selection");
    [source selectItemAtIndex:0]; search.stringValue = @"Satellite1035"; action(search); waitForResult(count);
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    [controller showWindow:nil];
    [controller.window.contentView layoutSubtreeIfNeeded];
    [controller.window displayIfNeeded];
    auto nextFrame = std::make_shared<SatelliteSnapshot>(*frame);
    nextFrame->julian_date = 2451546;
    nextFrame->positions[1035] = Vec3{1, 2, 3};
    nextFrame->positioned_count = 1;
    auto orbit = std::make_shared<SatelliteOrbitGeometry>();
    orbit->snapshot = nextFrame;
    auto wrongOrbit = std::make_shared<SatelliteOrbitGeometry>();
    wrongOrbit->snapshot = frame;
    auto wrongFrame = std::make_shared<SatelliteSnapshot>();
    auto wrongModel = std::make_shared<SatelliteModel>(SatelliteDataset{});
    auto wrongDisplay = std::make_shared<SatelliteDisplayModel>(wrongModel);
    unsigned rejectedCandidates = 0;
    try { (void)[controller prepareSnapshot:wrongFrame display:display orbitGeometry:nullptr]; }
    catch (const std::invalid_argument&) { ++rejectedCandidates; }
    try { (void)[controller prepareSnapshot:nextFrame display:wrongDisplay orbitGeometry:orbit]; }
    catch (const std::invalid_argument&) { ++rejectedCandidates; }
    try { (void)[controller prepareSnapshot:nextFrame display:display orbitGeometry:wrongOrbit]; }
    catch (const std::invalid_argument&) { ++rejectedCandidates; }
    require(rejectedCandidates == 3 && [details.string containsString:@"2451545"] && table.selectedRow == 0,
        "invalid candidate leaves the snapshot and selection unchanged");
    auto prepared = [controller prepareSnapshot:nextFrame display:display orbitGeometry:orbit];
    require([details.string containsString:@"2451545"], "preparation leaves displayed details unchanged");
    [controller commitPreparedDate:std::move(prepared)];
    require([details.string containsString:@"2451545"] && table.selectedRow == 0,
        "commit does not update the UI or disturb the selection");
    [controller finishDateUpdate];
    NSString *state = [controller tableView:table objectValueForTableColumn:table.tableColumns[3] row:0];
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
    auto replacement = std::make_shared<SatelliteBrowserModel>(std::make_shared<SatelliteModel>(SatelliteDataset{}));
    bool wrongDisplayRejected = false;
    try { [controller setDisplayModel:std::make_shared<SatelliteDisplayModel>(
        std::shared_ptr<const SatelliteModel>(replacement,&replacement->model()))]; }
    catch (const std::invalid_argument&) { wrongDisplayRejected = true; }
    require(wrongDisplayRejected && table.selectedRow == 0,"display from another model is rejected before changing selection");
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
        try { tests(); std::cout << "Satellite controller tests passed: " << checks << " checks\n"; return 0; }
        catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
