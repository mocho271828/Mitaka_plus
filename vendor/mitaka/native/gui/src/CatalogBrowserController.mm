#import "CatalogBrowserController.h"
#include "catalog_browser_model.hpp"
#include <atomic>
#include <set>

using namespace mitaka::gui;
namespace {
constexpr std::size_t pageSize = 500;
NSString *string(const std::string& value) {
    return [[NSString alloc] initWithBytes:value.data() length:value.size() encoding:NSUTF8StringEncoding];
}
}

@interface CatalogBrowserTableView : NSTableView
@end

@implementation CatalogBrowserTableView
- (NSMenu *)menuForEvent:(NSEvent *)event {
    const NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    const NSInteger row = [self rowAtPoint:point];
    if (row < 0 || row >= self.numberOfRows) return nil;
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    return self.menu;
}
@end

@implementation CatalogBrowserEntry
@end

@implementation CatalogBrowserController {
    std::shared_ptr<const CatalogBrowserModel> _model;
    BrowserSearchPage _page;
    std::shared_ptr<std::atomic<std::uint64_t>> _generation;
    dispatch_queue_t _searchQueue;
    std::size_t _offset;
    BOOL _hasConstellations;
    std::set<std::int32_t> _starNameHIPs;
    NSSearchField *_search;
    NSPopUpButton *_kind;
    NSTableView *_table;
    NSTextField *_count;
    NSButton *_select, *_center, *_previous, *_next, *_allConstellations, *_noConstellations;
}

- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 760, 550)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    if ((self = [super initWithWindow:window])) {
        window.title = @"天体ブラウザ";
        window.releasedWhenClosed = NO;
        window.minSize = NSMakeSize(560, 350);
        window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
        [window center];
        _generation = std::make_shared<std::atomic<std::uint64_t>>(0);
        _searchQueue = dispatch_queue_create("org.mitaka.catalog-search", DISPATCH_QUEUE_SERIAL);
        _search = [[NSSearchField alloc] init];
        _search.placeholderString = @"名前・HIP・星座・NGC・SDSS連番を全件検索";
        _search.target = self;
        _search.action = @selector(filter:);
        _search.sendsSearchStringImmediately = YES;
        _kind = [[NSPopUpButton alloc] init];
        [_kind addItemsWithTitles:@[@"すべて", @"太陽・惑星・月", @"恒星", @"星座", @"星雲・星団", @"銀河", @"QSO"]];
        _kind.target = self;
        _kind.action = @selector(filter:);
        NSStackView *filters = [NSStackView stackViewWithViews:@[_search, _kind]];
        filters.spacing = 10;
        _table = [[CatalogBrowserTableView alloc] init];
        for (NSString *identifier in @[@"title", @"details"]) {
            NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:identifier];
            column.title = [identifier isEqualToString:@"title"] ? @"天体" : @"座標・分類";
            column.width = [identifier isEqualToString:@"title"] ? 250 : 430;
            [_table addTableColumn:column];
        }
        NSTableColumn *visible = [[NSTableColumn alloc] initWithIdentifier:@"constellation-visible"];
        visible.title = @"表示対象";
        visible.width = 70;
        NSButtonCell *checkbox = [[NSButtonCell alloc] init];
        [checkbox setButtonType:NSButtonTypeSwitch];
        checkbox.title = @"";
        visible.dataCell = checkbox;
        [_table addTableColumn:visible];
        _table.dataSource = self;
        _table.delegate = self;
        _table.target = self;
        _table.doubleAction = @selector(center:);
        NSMenu *contextMenu = [[NSMenu alloc] initWithTitle:@"天体"];
        NSMenuItem *selectItem = [contextMenu addItemWithTitle:@"選択" action:@selector(select:) keyEquivalent:@""];
        NSMenuItem *centerItem = [contextMenu addItemWithTitle:@"選択して中央に表示" action:@selector(center:) keyEquivalent:@""];
        selectItem.target = centerItem.target = self;
        _table.menu = contextMenu;
        _table.usesAlternatingRowBackgroundColors = YES;
        _table.rowHeight = 24;
        _table.allowsMultipleSelection = NO;
        NSScrollView *scroll = [[NSScrollView alloc] init];
        scroll.documentView = _table;
        scroll.hasVerticalScroller = YES;
        scroll.hasHorizontalScroller = YES;
        _count = [NSTextField labelWithString:@"データ未読込"];
        _count.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
        _count.accessibilityIdentifier = @"catalog-result-count";
        _previous = [NSButton buttonWithTitle:@"前の500件" target:self action:@selector(previousPage:)];
        _next = [NSButton buttonWithTitle:@"次の500件" target:self action:@selector(nextPage:)];
        _select = [NSButton buttonWithTitle:@"選択" target:self action:@selector(select:)];
        _center = [NSButton buttonWithTitle:@"選択して中央に表示" target:self action:@selector(center:)];
        _select.enabled = _center.enabled = _previous.enabled = _next.enabled = NO;
        NSStackView *pagination = [NSStackView stackViewWithViews:@[_count, _previous, _next]];
        pagination.spacing = 10;
        _allConstellations = [NSButton buttonWithTitle:@"星座を全表示" target:self action:@selector(showAllConstellations:)];
        _noConstellations = [NSButton buttonWithTitle:@"星座を全非表示" target:self action:@selector(hideAllConstellations:)];
        _allConstellations.toolTip = _noConstellations.toolTip = @"検索条件にかかわらず全星座の表示対象を変更します。線・境界・名称の設定は維持します。";
        _allConstellations.hidden = _noConstellations.hidden = YES;
        NSStackView *footer = [NSStackView stackViewWithViews:@[_select, _center, _allConstellations, _noConstellations]];
        footer.spacing = 10;
        NSStackView *layout = [NSStackView stackViewWithViews:@[filters, scroll, pagination, footer]];
        layout.orientation = NSUserInterfaceLayoutOrientationVertical;
        layout.spacing = 12;
        layout.translatesAutoresizingMaskIntoConstraints = NO;
        [window.contentView addSubview:layout];
        [NSLayoutConstraint activateConstraints:@[
            [layout.leadingAnchor constraintEqualToAnchor:window.contentView.leadingAnchor constant:16],
            [layout.trailingAnchor constraintEqualToAnchor:window.contentView.trailingAnchor constant:-16],
            [layout.topAnchor constraintEqualToAnchor:window.contentView.topAnchor constant:16],
            [layout.bottomAnchor constraintEqualToAnchor:window.contentView.bottomAnchor constant:-16],
            [filters.widthAnchor constraintEqualToAnchor:layout.widthAnchor],
            [scroll.widthAnchor constraintEqualToAnchor:layout.widthAnchor],
            [pagination.widthAnchor constraintEqualToAnchor:layout.widthAnchor],
            [footer.widthAnchor constraintEqualToAnchor:layout.widthAnchor],
            [filters.heightAnchor constraintEqualToConstant:28],
            [pagination.heightAnchor constraintEqualToConstant:28],
            [footer.heightAnchor constraintEqualToConstant:28]]];
    }
    return self;
}
- (void)dealloc {
    if (_generation) _generation->fetch_add(1, std::memory_order_relaxed);
}
- (void)setModel:(std::shared_ptr<const SkyModel>)model extendedCatalogs:(std::shared_ptr<const ExtendedCatalogs>)catalogs {
    _hasConstellations = model && !model->constellations().empty();
    // App の callback が残っても、現在の星名表にない HIP へ旧セル操作を適用しない。
    _starNameHIPs.clear();
    if (model && !model->stars().empty() && catalogs)
        for (const auto& name : catalogs->star_names) _starNameHIPs.insert(name.hip);
    _model = std::make_shared<CatalogBrowserModel>(std::move(model), std::move(catalogs));
    [self filter:nil];
}
- (void)filter:(id)sender {
    (void)sender;
    _offset = 0;
    [self startSearch];
    [self refreshConstellationVisibility];
}
- (void)startSearch {
    const auto generation = _generation;
    const auto ticket = generation->fetch_add(1, std::memory_order_relaxed) + 1;
    const auto model = _model;
    _page = {};
    [_table deselectAll:nil];
    [_table reloadData];
    _select.enabled = _center.enabled = _previous.enabled = _next.enabled = NO;
    if (!model) { _count.stringValue = @"データ未読込"; return; }
    BrowserSearchQuery query;
    query.text = _search.stringValue.UTF8String;
    if (_kind.indexOfSelectedItem > 0) query.kind = static_cast<BrowserObjectKind>(_kind.indexOfSelectedItem - 1);
    query.offset = _offset;
    query.page_size = pageSize;
    _count.stringValue = @"全カタログを検索中…";
    __weak CatalogBrowserController *weakSelf = self;
    // 世代番号はUI入力時に更新する。旧検索は走査中も中止し、結果の逆転を防ぐ。
    dispatch_async(_searchQueue, ^{
        @autoreleasepool {
            try {
                auto page = std::make_shared<BrowserSearchPage>(model->search(query, [&] {
                    return generation->load(std::memory_order_relaxed) != ticket;
                }));
                if (page->cancelled) return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    CatalogBrowserController *controller = weakSelf;
                    if (!controller || generation->load(std::memory_order_relaxed) != ticket) return;
                    [controller applyPage:std::move(*page)];
                });
            } catch (const std::exception& error) {
                NSString *message = string(error.what());
                dispatch_async(dispatch_get_main_queue(), ^{
                    CatalogBrowserController *controller = weakSelf;
                    if (controller && generation->load(std::memory_order_relaxed) == ticket)
                        controller->_count.stringValue = [@"検索に失敗: " stringByAppendingString:message];
                });
            }
        }
    });
}
- (void)applyPage:(BrowserSearchPage)page {
    _page = std::move(page);
    [_table reloadData];
    const auto first = _page.rows.empty() ? 0 : _page.offset + 1;
    const auto last = _page.rows.empty() ? 0 : _page.offset + _page.rows.size();
    _count.stringValue = [NSString stringWithFormat:@"%lu–%lu / 該当 %lu 件（全 %lu 件）",
        static_cast<unsigned long>(first), static_cast<unsigned long>(last),
        static_cast<unsigned long>(_page.total_matches), static_cast<unsigned long>(_page.total_objects)];
    _previous.enabled = _offset > 0;
    _next.enabled = last < _page.total_matches;
}
- (void)previousPage:(id)sender {
    (void)sender;
    if (!_previous.enabled) return;
    _offset = _offset >= pageSize ? _offset - pageSize : 0;
    [self startSearch];
}
- (void)nextPage:(id)sender {
    (void)sender;
    if (!_next.enabled) return;
    _offset += pageSize;
    [self startSearch];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    (void)tableView;
    return static_cast<NSInteger>(_page.rows.size());
}
- (CatalogBrowserEntry *)entryAtRow:(NSInteger)row {
    if (!_model || row < 0 || static_cast<std::size_t>(row) >= _page.rows.size()) return nil;
    const auto reference = _page.rows[static_cast<std::size_t>(row)];
    const auto text = _model->entry(reference);
    CatalogBrowserEntry *entry = [[CatalogBrowserEntry alloc] init];
    entry.kind = static_cast<CatalogObjectKind>(reference.kind);
    entry.identifier = static_cast<NSInteger>(text.identifier);
    entry.title = string(text.title);
    entry.details = string(text.details);
    return entry;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    (void)tableView;
    CatalogBrowserEntry *entry = [self entryAtRow:row];
    if ([column.identifier isEqualToString:@"constellation-visible"]) {
        if (entry && entry.kind == CatalogObjectConstellation && self.constellationVisible)
            return @(self.constellationVisible(entry.identifier));
        if ([self isStarNameSelectable:entry] && self.starNameSelected)
            return @(self.starNameSelected(entry.identifier));
        return nil;
    }
    return [column.identifier isEqualToString:@"title"] ? entry.title : entry.details;
}
- (BOOL)isStarNameSelectable:(CatalogBrowserEntry *)entry {
    return entry && entry.kind == CatalogObjectStar && _starNameHIPs.count(entry.identifier) &&
        self.starNameSelectable && self.starNameSelectable(entry.identifier);
}
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    (void)tableView;
    CatalogBrowserEntry *entry = [self entryAtRow:row];
    if (![column.identifier isEqualToString:@"constellation-visible"] || !entry) return NO;
    if (entry.kind == CatalogObjectConstellation) return self.setConstellationVisible != nil;
    return [self isStarNameSelectable:entry] && self.setStarNameSelected != nil;
}
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    (void)tableView;
    if (![column.identifier isEqualToString:@"constellation-visible"]) return;
    CatalogBrowserEntry *entry = [self entryAtRow:row];
    const BOOL selectable = entry && (entry.kind == CatalogObjectConstellation ||
        [self isStarNameSelectable:entry]);
    [cell setTransparent:!selectable];
    [cell setEnabled:[self tableView:tableView shouldEditTableColumn:column row:row]];
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    if (![self tableView:tableView shouldEditTableColumn:column row:row]) return;
    CatalogBrowserEntry *entry = [self entryAtRow:row];
    if (entry.kind == CatalogObjectConstellation) self.setConstellationVisible(entry.identifier, [value boolValue]);
    else self.setStarNameSelected(entry.identifier, [value boolValue]);
    // Ser の別図形も同じ略号設定を読む。検索と選択はやり直さない。
    [self refreshConstellationVisibility];
}
- (void)refreshConstellationVisibility {
    const BOOL stars = _kind.indexOfSelectedItem == 2;
    const BOOL enabled = stars ? !_starNameHIPs.empty() && self.setAllStarNamesSelected != nil
        : _kind.indexOfSelectedItem == 3 && _hasConstellations && self.setAllConstellationsVisible != nil;
    _allConstellations.title = stars ? @"恒星名を全選択" : @"星座を全表示";
    _noConstellations.title = stars ? @"恒星名の選択を解除" : @"星座を全非表示";
    _allConstellations.toolTip = _noConstellations.toolTip = stars
        ? @"検索条件にかかわらず全恒星名の表示対象を変更します。「選んだ固有名のみ」の表示で使用します。"
        : @"検索条件にかかわらず全星座の表示対象を変更します。線・境界・名称・星座絵の設定は維持します。";
    _allConstellations.hidden = _noConstellations.hidden = !stars && _kind.indexOfSelectedItem != 3;
    _allConstellations.enabled = _noConstellations.enabled = enabled;
    const NSInteger column = [_table columnWithIdentifier:@"constellation-visible"];
    if (column >= 0 && _table.numberOfRows > 0)
        [_table reloadDataForRowIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _table.numberOfRows)]
            columnIndexes:[NSIndexSet indexSetWithIndex:column]];
}
- (void)showAllConstellations:(id)sender {
    (void)sender;
    [self setAllMembership:YES];
}
- (void)hideAllConstellations:(id)sender {
    (void)sender;
    [self setAllMembership:NO];
}
- (void)setAllMembership:(BOOL)selected {
    if (_kind.indexOfSelectedItem == 2) {
        if (!_starNameHIPs.empty() && self.setAllStarNamesSelected) self.setAllStarNamesSelected(selected);
    } else if (_kind.indexOfSelectedItem == 3 && _hasConstellations && self.setAllConstellationsVisible) {
        self.setAllConstellationsVisible(selected);
    }
    [self refreshConstellationVisibility];
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    (void)notification;
    _select.enabled = _center.enabled = _table.selectedRow >= 0;
}
- (void)choose:(BOOL)center {
    CatalogBrowserEntry *entry = [self entryAtRow:_table.selectedRow];
    if (entry && self.chooseObject) self.chooseObject(entry, center);
}
- (void)select:(id)sender { (void)sender; [self choose:NO]; }
- (void)center:(id)sender { (void)sender; [self choose:YES]; }
@end
