#import "SmallBodyController.h"
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
    SmallBodyController *controller = [[SmallBodyController alloc] init];
    NSView *root = controller.window.contentView;
    NSSearchField *search = (NSSearchField *)findView(root, ^bool(NSView *view) { return [view isKindOfClass:NSSearchField.class]; });
    NSTableView *table = (NSTableView *)findView(root, ^bool(NSView *view) { return [view isKindOfClass:NSTableView.class]; });
    NSTextField *count = (NSTextField *)findView(root, ^bool(NSView *view) { return [view.accessibilityIdentifier isEqualToString:@"small-body-result-count"]; });
    NSTextView *details = (NSTextView *)findView(root, ^bool(NSView *view) { return [view isKindOfClass:NSTextView.class]; });
    NSButton *next = button(root, @"次の500件"), *previous = button(root, @"前の500件");
    NSButton *select = button(root, @"選択・診断を表示"), *center = button(root, @"選択して3Dの中心へ");
    require(search && table && count && details && next && previous && select && center, "browser controls are present");
    auto dataset = std::make_shared<SmallBodyDataset>();
    dataset->records.resize(10037);
    for (std::size_t i = 0; i < dataset->records.size(); ++i) {
        auto& record = dataset->records[i];
        record.id = {"mp.dat", i};
        record.number = -1;
        record.name_bytes = "Object " + std::to_string(i);
    }
    dataset->sources.push_back({"mp.dat", {}, "test original rows", dataset->records.size(), true});
    dataset->diagnostics.push_back({SmallBodyDiagnosticCode::missing_source, "TNO2.dat", {}, "source", "missing test source"});
    auto model = std::make_shared<SmallBodyModel>(dataset);
    auto frame = evaluate_small_body_snapshot(model, 2451545);
    auto display = std::make_shared<SmallBodyDisplayModel>(dataset);
    [controller setModel:model snapshot:frame];
    [controller setDisplayModel:display];
    auto foreignDataset = std::make_shared<SmallBodyDataset>();
    auto foreignDisplay = std::make_shared<SmallBodyDisplayModel>(foreignDataset);
    bool rejectedCandidate = false;
    try { (void)[controller prepareSnapshot:frame display:foreignDisplay]; }
    catch (const std::invalid_argument&) { rejectedCandidate = true; }
    require(rejectedCandidate, "candidate with another dataset is rejected before publication");
    auto foreignModel = std::make_shared<SmallBodyModel>(foreignDataset);
    auto foreignFrame = evaluate_small_body_snapshot(foreignModel, 2451545);
    rejectedCandidate = false;
    try { (void)[controller prepareSnapshot:foreignFrame display:display]; }
    catch (const std::invalid_argument&) { rejectedCandidate = true; }
    require(rejectedCandidate, "candidate with another snapshot model is rejected before publication");
    auto prepared = [controller prepareSnapshot:frame display:display];
    [controller commitPreparedDate:std::move(prepared)];
    [controller finishDateUpdate];
    require(table.numberOfRows == 0 && !next.enabled, "search invalidates old rows immediately");
    waitForResult(count);
    require(table.numberOfRows == 500 && next.enabled && !previous.enabled, "first page uses bounded visible row references");
    require([count.stringValue containsString:@"10037"], "count reflects every original row");
    require([details.string containsString:@"missing test source"], "source diagnostics are exposed before row selection");
    NSButton *add = button(root, @"表示集合に追加"), *remove = button(root, @"表示集合から除外");
    require(add && remove && table.allowsMultipleSelection, "display membership has independent multi-row controls");
    __block auto currentDisplay = display;
    __weak SmallBodyController *weakController = controller;
    controller.displayIdsChanged = ^(const std::vector<SmallBodyId>& ids) {
        auto changed = std::make_shared<SmallBodyDisplayModel>(*currentDisplay);
        changed->set_selected_ids(ids);
        currentDisplay = std::move(changed);
        [weakController setDisplayModel:currentDisplay];
    };
    [table selectRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 2)] byExtendingSelection:NO];
    require(!select.enabled && !center.enabled && add.enabled && remove.enabled,
        "multiple rows change display membership without ambiguous single-object focus");
    action(add);
    require(currentDisplay->contains({"mp.dat", 2}) && currentDisplay->contains({"mp.dat", 3}),
        "both original row identities enter the display set");
    action(next); waitForResult(count);
    id title = [controller tableView:table objectValueForTableColumn:table.tableColumns.firstObject row:0];
    require([title isEqualToString:@"Object 500"] && previous.enabled, "next page preserves source indices");
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    action(add);
    require(currentDisplay->contains({"mp.dat", 500}) && currentDisplay->selected_ids().size() == 3,
        "membership survives page navigation and accumulates original row identities");
    action(remove);
    require(!currentDisplay->contains({"mp.dat", 500}) && currentDisplay->selected_ids().size() == 2,
        "removal affects only the explicitly selected rows");
    __block unsigned optionChanges = 0;
    controller.optionsChanged = ^(SmallBodyKind kind, SmallBodyKindDisplayOptions options) {
        auto changed = std::make_shared<SmallBodyDisplayModel>(*currentDisplay);
        changed->set_kind_options(kind, options);
        currentDisplay = std::move(changed);
        ++optionChanges;
        [weakController setDisplayModel:currentDisplay];
    };
    for (NSUInteger kind = 0; kind < 3; ++kind) for (NSUInteger flag = 0; flag < 4; ++flag) {
        NSString *identifier = [NSString stringWithFormat:@"small-body-option-%lu-%lu", kind, flag];
        NSButton *option = (NSButton *)findView(root, ^bool(NSView *view) {
            return [view.accessibilityIdentifier isEqualToString:identifier];
        });
        require(option && option.enabled, "each kind exposes all four independent flags");
        option.state = flag == 0 ? NSControlStateValueOff : NSControlStateValueOn;
        action(option);
        const auto options = currentDisplay->kind_options(static_cast<SmallBodyKind>(kind));
        const bool values[] = {options.visible, options.labels, options.orbits, options.selected_only};
        require(values[flag] == (flag != 0), "kind flag callback updates the intended setting");
    }
    require(optionChanges == 12, "one explicit action produces one kind update");
    NSTextField *first = (NSTextField *)findView(root, ^bool(NSView *view) {
        return [view.accessibilityIdentifier isEqualToString:@"small-body-orbit-first"];
    });
    NSTextField *last = (NSTextField *)findView(root, ^bool(NSView *view) {
        return [view.accessibilityIdentifier isEqualToString:@"small-body-orbit-last"];
    });
    NSTextField *samples = (NSTextField *)findView(root, ^bool(NSView *view) {
        return [view.accessibilityIdentifier isEqualToString:@"small-body-orbit-samples"];
    });
    NSTextField *orbitExplanation = (NSTextField *)findView(root, ^bool(NSView *view) {
        return [view.accessibilityIdentifier isEqualToString:@"small-body-orbit-explanation"];
    });
    require([orbitExplanation.stringValue containsString:@"元期から一周期"]
        && [orbitExplanation.stringValue containsString:@"物理時系は未確定"],
        "orbit controls explain packed36 sampling and unresolved physical time scale");
    NSTextField *orbitStatus = (NSTextField *)findView(root, ^bool(NSView *view) {
        return [view.accessibilityIdentifier isEqualToString:@"small-body-orbit-status"];
    });
    NSButton *apply = button(root, @"軌道区間を適用");
    require(first && last && samples && orbitStatus && apply, "fixed TDB sampling controls are present");
    [controller setOrbitSampling:{2451545, 2451645, 129}];
    require([first.stringValue isEqualToString:@"2451545"] && [last.stringValue isEqualToString:@"2451645"]
        && [samples.stringValue isEqualToString:@"129"], "programmatic numeric fields contain no locale grouping");
    __block unsigned samplingChanges = 0;
    controller.orbitSamplingChanged = ^(SmallBodyOrbitSampling sampling) {
        require(sampling.first_jd == 2451545 && sampling.last_jd == 2451645 && sampling.sample_count == 129,
            "sampling callback preserves explicit absolute TDB interval and count");
        ++samplingChanges;
    };
    action(apply);
    for (NSString *invalid in @[@"2,451,545", @"nan", @"inf", @"2451545junk"]) {
        first.stringValue = invalid;
        action(apply);
    }
    first.stringValue = @"2451545";
    for (NSString *invalid in @[@"1", @"4097", @"2.5", @"129x"]) {
        samples.stringValue = invalid;
        action(apply);
    }
    require(samplingChanges == 1 && orbitStatus.stringValue.length > 0,
        "malformed or out-of-budget sampling is diagnosed before any callback");
    [controller setOrbitSampling:{2451545, 2451645, 129}];
    action(previous); waitForResult(count);
    search.stringValue = @"1"; action(search);
    search.stringValue = @"absent"; action(search);
    search.stringValue = @"Object 10036"; action(search);
    waitForResult(count);
    require(table.numberOfRows == 1 && !next.enabled && !previous.enabled, "latest search generation wins");
    require(currentDisplay->selected_ids().size() == 2, "search filtering does not replace the display set");
    __block NSUInteger selected = NSNotFound;
    __block BOOL centered = NO;
    controller.chooseObject = ^(NSUInteger index, BOOL centerView) {
        selected = index; centered = centerView;
        require(NSThread.isMainThread, "selection callback runs on main thread");
    };
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    require(select.enabled && center.enabled, "unresolved source rows remain selectable");
    require([details.string containsString:@"座標系・時系・軌道要素が未確定"], "unresolved row displays a diagnostic");
    action(select);
    require(selected == 10036 && !centered, "select callback identifies source row rather than repeated number");
    action(center);
    require(centered, "center intent is passed to guarded solar focus");
    [controller showWindow:nil];
    [controller.window.contentView layoutSubtreeIfNeeded];
    [controller.window displayIfNeeded];
    [controller.window setContentSize:NSMakeSize(850, 718)];
    [root layoutSubtreeIfNeeded];
    require(first.bounds.size.width >= 145 && last.bounds.size.width >= 145 && samples.bounds.size.width >= 65,
        "sampling inputs retain readable width at the minimum window size");
    require(add.bounds.size.width > 80 && remove.bounds.size.width > 80,
        "membership action labels are not collapsed by the sampling inputs");
    auto replacement = std::make_shared<SmallBodyModel>(std::make_shared<SmallBodyDataset>());
    [controller setModel:replacement snapshot:evaluate_small_body_snapshot(replacement, 2451545)];
    waitForResult(count);
    require(table.numberOfRows == 0 && !select.enabled, "visible source replacement clears old high-index selection before new dataset");
    [controller setModel:model snapshot:frame];
    [controller setDisplayModel:display];
    search.stringValue = @"1"; action(search);
    [controller setModel:replacement snapshot:evaluate_small_body_snapshot(replacement, 2451545)];
    waitForResult(count);
    require(table.numberOfRows == 0, "source replacement cancels previous queued search results");
    bool rejected = false;
    try { [controller setSnapshot:frame]; } catch (const std::invalid_argument&) { rejected = true; }
    require(rejected, "snapshot from another source model is rejected");
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
        try { tests(); std::cout << "Small-body controller tests passed: " << checks << " checks\n"; return 0; }
        catch (const std::exception& error) { std::cerr << "FAIL: " << error.what() << '\n'; return 1; }
    }
}
