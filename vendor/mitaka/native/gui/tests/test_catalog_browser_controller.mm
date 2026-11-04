#import "CatalogBrowserController.h"
#include "constellation_display.hpp"
#include <iostream>
#include <set>
#include <stdexcept>

namespace {
unsigned checks = 0;
void require(bool value, const char *message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
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
void action(NSControl *control) {
    [NSApp sendAction:control.action to:control.target from:control];
}
void waitForResult(NSTextField *label) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5];
    while ([label.stringValue containsString:@"検索中"] && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    require([label.stringValue containsString:@"該当"], "async search completed without error");
}
void runTests() {
    using namespace mitaka::gui;
    CatalogBrowserController *controller = [[CatalogBrowserController alloc] init];
    NSView *root = controller.window.contentView;
    NSSearchField *search = (NSSearchField *)findView(root, ^bool(NSView *v) { return [v isKindOfClass:NSSearchField.class]; });
    NSTableView *table = (NSTableView *)findView(root, ^bool(NSView *v) { return [v isKindOfClass:NSTableView.class]; });
    NSTextField *count = (NSTextField *)findView(root, ^bool(NSView *v) { return [v.accessibilityIdentifier isEqualToString:@"catalog-result-count"]; });
    NSButton *next = button(root, @"次の500件"), *previous = button(root, @"前の500件");
    NSButton *select = button(root, @"選択"), *center = button(root, @"選択して中央に表示");
    require(search && table && count && next && previous && select && center, "browser controls are present");
    auto catalogs = std::make_shared<ExtendedCatalogs>();
    catalogs->galaxies.resize(1'000'037);
    [controller setModel:{} extendedCatalogs:catalogs];
    require(table.numberOfRows == 0 && !next.enabled, "search clears obsolete rows immediately");
    waitForResult(count);
    require(table.numberOfRows == 500 && next.enabled && !previous.enabled, "first result page has bounded rows and valid controls");
    require([count.stringValue containsString:@"1000037"], "count reflects every loaded record");
    action(next);
    waitForResult(count);
    id title = [controller tableView:table objectValueForTableColumn:table.tableColumns.firstObject row:0];
    require([title isEqualToString:@"SDSS GAL 501"] && previous.enabled, "next page begins at the next sequence");
    action(previous);
    waitForResult(count);
    title = [controller tableView:table objectValueForTableColumn:table.tableColumns.firstObject row:0];
    require([title isEqualToString:@"SDSS GAL 1"] && !previous.enabled, "previous page restores the first sequence");
    search.stringValue = @"1"; action(search);
    search.stringValue = @"unmatched"; action(search);
    search.stringValue = @"SDSS GAL 1000037"; action(search);
    waitForResult(count);
    require(table.numberOfRows == 1 && !next.enabled && !previous.enabled, "newest search wins over cancelled queued generations");
    title = [controller tableView:table objectValueForTableColumn:table.tableColumns.firstObject row:0];
    require([title isEqualToString:@"SDSS GAL 1000037"], "last loaded record can be selected from search");
    __block NSInteger selectedID = -1;
    __block BOOL didCenter = NO, callbackOnMain = NO;
    controller.chooseObject = ^(CatalogBrowserEntry *entry, BOOL centered) {
        selectedID = entry.identifier;
        didCenter = centered;
        callbackOnMain = NSThread.isMainThread;
        require(entry.kind == CatalogObjectGalaxy, "selection callback retains catalog kind");
    };
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    require(select.enabled && center.enabled, "selection enables actions");
    action(select);
    require(selectedID == 1'000'036 && !didCenter && callbackOnMain, "select callback has zero-based source ID on main thread");
    action(center);
    require(didCenter, "centering uses the existing callback contract");
    search.stringValue = @"1"; action(search);
    auto replacement = std::make_shared<ExtendedCatalogs>();
    replacement->quasars.resize(2);
    [controller setModel:{} extendedCatalogs:replacement];
    search.stringValue = @""; action(search);
    waitForResult(count);
    require(table.numberOfRows == 2, "source replacement invalidates work referencing the previous catalog");
    title = [controller tableView:table objectValueForTableColumn:table.tableColumns.firstObject row:0];
    require([title isEqualToString:@"SDSS QSO 1"], "display references resolve against the active shared source");
    [controller setModel:{} extendedCatalogs:{}];
    waitForResult(count);
    require(table.numberOfRows == 0 && !next.enabled && !select.enabled, "empty data clears results and selection");
    [controller setModel:{} extendedCatalogs:catalogs];
    waitForResult(count);
    [controller showWindow:nil];
    [controller.window.contentView layoutSubtreeIfNeeded];
    [controller.window displayIfNeeded];
    [controller close];
}
void constellationTests(const std::filesystem::path& data) {
    using namespace mitaka::gui;
    auto model = std::make_shared<SkyModel>(SkyModel::load(data));
    auto display = std::make_shared<ConstellationDisplayModel>(model->constellations());
    CatalogBrowserController *controller = [[CatalogBrowserController alloc] init];
    NSView *root = controller.window.contentView;
    NSSearchField *search = (NSSearchField *)findView(root, ^bool(NSView *v) { return [v isKindOfClass:NSSearchField.class]; });
    NSPopUpButton *kind = (NSPopUpButton *)findView(root, ^bool(NSView *v) { return [v isKindOfClass:NSPopUpButton.class]; });
    NSTableView *table = (NSTableView *)findView(root, ^bool(NSView *v) { return [v isKindOfClass:NSTableView.class]; });
    NSTextField *count = (NSTextField *)findView(root, ^bool(NSView *v) { return [v.accessibilityIdentifier isEqualToString:@"catalog-result-count"]; });
    NSButton *show = button(root, @"星座を全表示"), *hide = button(root, @"星座を全非表示");
    NSTableColumn *column = [table tableColumnWithIdentifier:@"constellation-visible"];
    require(column && show && hide && show.hidden && hide.hidden, "constellation controls must exist and hide outside the constellation filter");
    __block NSUInteger changed = NSNotFound, selected = NSNotFound;
    __block unsigned changes = 0, selections = 0;
    controller.constellationVisible = ^BOOL(NSUInteger index) {
        return display->membership(model->constellations().at(index).abbreviation);
    };
    controller.setConstellationVisible = ^(NSUInteger index, BOOL visible) {
        changed = index; ++changes;
        display->set_visible({model->constellations().at(index).abbreviation}, visible);
    };
    controller.setAllConstellationsVisible = ^(BOOL visible) { display->set_all_visible(visible); };
    controller.chooseObject = ^(CatalogBrowserEntry *entry, BOOL) { selected = entry.identifier; ++selections; };
    [controller setModel:model extendedCatalogs:{}];
    [kind selectItemAtIndex:3]; action(kind); waitForResult(count);
    require(!show.hidden && !hide.hidden && show.enabled && hide.enabled, "constellation filter did not enable membership controls");
    require(table.numberOfRows == static_cast<NSInteger>(std::min<std::size_t>(500, model->constellations().size())), "constellation results lost source rows");
    if (table.numberOfRows) {
        [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        action(button(root, @"選択"));
        require(selected < model->constellations().size(), "selection lost original constellation index");
        const auto previous_selections = selections;
        require([controller tableView:table shouldEditTableColumn:column row:0], "constellation checkbox cannot be edited");
        [controller tableView:table setObjectValue:@NO forTableColumn:column row:0];
        require(changes == 1 && changed == selected && !display->membership(model->constellations()[selected].abbreviation), "checkbox did not update original constellation ID");
        require(table.selectedRow == 0 && selections == previous_selections, "membership editing changed selection or invoked centering");
    }
    search.stringValue = @"Ser"; action(search); waitForResult(count);
    action(hide);
    require(!display->options().default_visible && display->options().exceptions.empty(), "hide all only changed filtered rows");
    for (NSInteger row = 0; row < table.numberOfRows; ++row)
        require(![[controller tableView:table objectValueForTableColumn:column row:row] boolValue], "hidden membership checkbox is stale");
    for (NSInteger row = 0; row < table.numberOfRows; ++row) {
        [controller tableView:table setObjectValue:@YES forTableColumn:column row:row];
        if (model->constellations()[changed].abbreviation == "Ser") break;
    }
    if (display->abbreviations().count("Ser")) {
        require(display->membership("Ser"), "Ser membership was not enabled");
        for (std::size_t index = 0; index < model->constellations().size(); ++index)
            if (model->constellations()[index].abbreviation == "Ser")
                require(controller.constellationVisible(index), "one Ser checkbox did not update every original Ser figure");
    }
    auto layers = display->options(); layers.lines = false; layers.boundaries = true; layers.labels = false;
    display->set_options(layers);
    action(show);
    require(display->options().default_visible && display->options().exceptions.empty()
        && !display->options().lines && display->options().boundaries && !display->options().labels, "show all changed layer masters or retained exceptions");
    [kind selectItemAtIndex:1]; search.stringValue = @""; action(kind); waitForResult(count);
    require(show.hidden && hide.hidden && table.numberOfRows == 11, "other catalog filter was disturbed");
    require(![controller tableView:table shouldEditTableColumn:column row:0]
        && [controller tableView:table objectValueForTableColumn:column row:0] == nil, "non-constellation row exposes a membership checkbox");
    NSButtonCell *cell = [[NSButtonCell alloc] init];
    [controller tableView:table willDisplayCell:cell forTableColumn:column row:0];
    require(cell.transparent && !cell.enabled, "non-constellation checkbox is visible or enabled");
    const auto previous_changes = changes;
    [controller tableView:table setObjectValue:@YES forTableColumn:column row:0];
    require(changes == previous_changes, "other catalog row mutated constellation membership");
    [controller setModel:{} extendedCatalogs:{}];
    [kind selectItemAtIndex:3]; action(kind); waitForResult(count);
    require(table.numberOfRows == 0 && !show.enabled && !hide.enabled, "model removal retained stale constellation controls");
    [controller close];
}

void starNameTests(const std::filesystem::path& data) {
    using namespace mitaka::gui;
    auto model = std::make_shared<SkyModel>(SkyModel::load(data));
    require(model->stars().size() >= 3, "star-name fixture requires three source stars");
    const auto first = model->stars()[0].hip, second = model->stars()[1].hip;
    auto catalogs = std::make_shared<ExtendedCatalogs>();
    catalogs->star_names = {{first, true, "n10-alpha", ""}, {second, false, "n10-beta", ""}};
    const auto known = std::make_shared<const std::set<std::int32_t>>(std::set<std::int32_t>{first, second});
    auto membership = std::make_shared<std::set<std::int32_t>>(std::set<std::int32_t>{first});
    CatalogBrowserController *controller = [[CatalogBrowserController alloc] init];
    NSView *root = controller.window.contentView;
    NSSearchField *search = (NSSearchField *)findView(root, ^bool(NSView *v) { return [v isKindOfClass:NSSearchField.class]; });
    NSPopUpButton *kind = (NSPopUpButton *)findView(root, ^bool(NSView *v) { return [v isKindOfClass:NSPopUpButton.class]; });
    NSTableView *table = (NSTableView *)findView(root, ^bool(NSView *v) { return [v isKindOfClass:NSTableView.class]; });
    NSTextField *count = (NSTextField *)findView(root, ^bool(NSView *v) { return [v.accessibilityIdentifier isEqualToString:@"catalog-result-count"]; });
    NSButton *show = button(root, @"星座を全表示"), *hide = button(root, @"星座を全非表示");
    NSButton *select = button(root, @"選択"), *center = button(root, @"選択して中央に表示");
    NSTableColumn *column = [table tableColumnWithIdentifier:@"constellation-visible"];
    require(search && kind && table && count && show && hide && select && center && column, "star-name browser controls missing");
    __block unsigned changes = 0, allChanges = 0, selections = 0, constellationChanges = 0;
    __block NSInteger chosenHIP = -1, changedHIP = -1;
    __block BOOL didCenter = NO;
    controller.starNameSelectable = ^BOOL(NSInteger hip) { return known->count(hip) != 0; };
    controller.starNameSelected = ^BOOL(NSInteger hip) { return membership->count(hip) != 0; };
    controller.setStarNameSelected = ^(NSInteger hip, BOOL selected) {
        changedHIP = hip; ++changes;
        if (selected) membership->insert(hip); else membership->erase(hip);
    };
    controller.setAllStarNamesSelected = ^(BOOL selected) {
        ++allChanges;
        *membership = selected ? *known : std::set<std::int32_t>{};
    };
    controller.setAllConstellationsVisible = ^(BOOL) { ++constellationChanges; };
    controller.chooseObject = ^(CatalogBrowserEntry *entry, BOOL centered) {
        require(entry.kind == CatalogObjectStar, "star selection callback lost its catalog kind");
        chosenHIP = entry.identifier; didCenter = centered; ++selections;
    };
    [controller setModel:model extendedCatalogs:catalogs];
    [kind selectItemAtIndex:2]; search.stringValue = @"n10-alpha"; action(kind); waitForResult(count);
    require(table.numberOfRows == 1 && !show.hidden && show.enabled && hide.enabled &&
        [show.title isEqualToString:@"恒星名を全選択"] && [hide.title isEqualToString:@"恒星名の選択を解除"],
        "star filter did not expose named-star membership controls");
    require([[controller tableView:table objectValueForTableColumn:column row:0] boolValue] &&
        [controller tableView:table shouldEditTableColumn:column row:0], "featured named HIP checkbox lost initial membership");
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    action(select);
    require(chosenHIP == first && !didCenter && selections == 1 && *membership == std::set<std::int32_t>{first},
        "star selection changed name membership or used row index as HIP");
    action(center);
    require(chosenHIP == first && didCenter && selections == 2 && *membership == std::set<std::int32_t>{first},
        "star centering changed name membership");
    [controller tableView:table setObjectValue:@NO forTableColumn:column row:0];
    require(changes == 1 && changedHIP == first && membership->empty() && table.selectedRow == 0 && selections == 2,
        "name membership editing changed object selection or centering");
    action(show);
    require(*membership == *known && allChanges == 1 && table.numberOfRows == 1 && table.selectedRow == 0 && selections == 2,
        "filtered select-all must select every known name without selecting objects");
    action(hide);
    require(membership->empty() && allChanges == 2 && constellationChanges == 0,
        "filtered clear-all failed or mutated constellations");

    search.stringValue = @""; action(search);
    const auto previousChanges = changes;
    [controller tableView:table setObjectValue:@YES forTableColumn:column row:0];
    require(table.numberOfRows == 0 && changes == previousChanges, "pending search accepted an obsolete cell action");
    waitForResult(count);
    require(table.numberOfRows >= 3, "star filter lost unnamed source rows");
    require([controller tableView:table objectValueForTableColumn:column row:2] == nil &&
        ![controller tableView:table shouldEditTableColumn:column row:2], "unnamed HIP exposes an editable name checkbox");
    NSButtonCell *cell = [[NSButtonCell alloc] init];
    [controller tableView:table willDisplayCell:cell forTableColumn:column row:2];
    require(cell.transparent && !cell.enabled, "unnamed HIP checkbox is visible or enabled");
    for (const NSInteger row : {-1, 2, 5000})
        [controller tableView:table setObjectValue:@YES forTableColumn:column row:row];
    require(changes == previousChanges && membership->empty(), "unnamed or obsolete row mutated membership");

    void (^allNames)(BOOL) = controller.setAllStarNamesSelected;
    controller.setAllStarNamesSelected = nil;
    [controller refreshConstellationVisibility];
    action(show); action(hide);
    require(!show.enabled && !hide.enabled && allChanges == 2 && constellationChanges == 0,
        "missing star callback fell through to constellation actions");
    controller.setAllStarNamesSelected = allNames;
    auto replacement = std::make_shared<ExtendedCatalogs>();
    replacement->star_names = {catalogs->star_names[1]};
    [controller setModel:model extendedCatalogs:replacement];
    waitForResult(count);
    require(![controller tableView:table shouldEditTableColumn:column row:0] &&
        [controller tableView:table objectValueForTableColumn:column row:0] == nil &&
        [controller tableView:table shouldEditTableColumn:column row:1], "replacement catalog trusted a stale named-HIP callback");
    [controller tableView:table setObjectValue:@YES forTableColumn:column row:0];
    require(changes == previousChanges, "removed name accepted a stale cell action");
    [controller setModel:model extendedCatalogs:{}];
    waitForResult(count);
    action(show); action(hide);
    require(table.numberOfRows >= 3 && !show.enabled && !hide.enabled && allChanges == 2 && constellationChanges == 0,
        "missing name table retained stale global callbacks");
    [controller setModel:model extendedCatalogs:catalogs];
    search.stringValue = @"n10-alpha"; action(search);
    [controller setModel:{} extendedCatalogs:{}];
    [controller tableView:table setObjectValue:@YES forTableColumn:column row:0];
    action(show); action(hide); action(select); action(center);
    waitForResult(count);
    require(table.numberOfRows == 0 && !show.enabled && !hide.enabled && !select.enabled && !center.enabled &&
        changes == previousChanges && allChanges == 2 && selections == 2 && constellationChanges == 0,
        "model removal accepted stale row/global/object callbacks or queued search results");
    [controller close];
}

}
int main(int argc, char** argv) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            runTests();
            if (argc == 2) { constellationTests(argv[1]); starNameTests(argv[1]); }
            std::cout << "Catalog browser controller tests passed: " << checks << " checks\n";
            return 0;
        } catch (const std::exception& error) {
            std::cerr << "FAIL: " << error.what() << '\n';
            return 1;
        }
    }
}
