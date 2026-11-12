#import "SpacecraftController.h"
#include <atomic>
#include <stdexcept>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
constexpr std::size_t pageSize = 500;
NSString *string(const std::string& text) {
    NSString *value = [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
    return value ? value : @"";
}
}

@interface SpacecraftController ()
- (NSMenu *)contextMenuForRow:(NSInteger)row;
@end

@interface SpacecraftBrowserTableView : NSTableView
@property(nonatomic, weak) SpacecraftController *contextController;
@end

@implementation SpacecraftBrowserTableView
- (NSMenu *)menuForEvent:(NSEvent *)event {
    const NSInteger row = [self rowAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
    if (row < 0 || row >= self.numberOfRows) return nil;
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    return [self.contextController contextMenuForRow:row];
}
@end

@implementation SpacecraftController {
    std::shared_ptr<const SpacecraftBrowserModel> _model;
    std::shared_ptr<const SpacecraftSnapshot> _snapshot;
    SpacecraftSearchPage _page;
    std::shared_ptr<std::atomic<std::uint64_t>> _generation;
    dispatch_queue_t _queue;
    std::size_t _offset;
    NSSearchField *_search;
    NSPopUpButton *_source;
    NSTableView *_table;
    NSTextField *_count, *_summary;
    NSTextView *_details;
    NSButton *_previous, *_next, *_select, *_center;
}
- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 850, 640)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    if ((self = [super initWithWindow:window])) {
        window.title = @"探査機";
        window.releasedWhenClosed = NO;
        window.minSize = NSMakeSize(650, 440);
        window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
        [window center];
        _generation = std::make_shared<std::atomic<std::uint64_t>>(0);
        _queue = dispatch_queue_create("org.mitaka.spacecraft-search", DISPATCH_QUEUE_SERIAL);
        _search = [[NSSearchField alloc] init];
        _search.placeholderString = @"探査機名・定義フィールド・出典ファイルを全件検索";
        _search.target = self;
        _search.action = @selector(filter:);
        _search.sendsSearchStringImmediately = YES;
        _source = [[NSPopUpButton alloc] init];
        [_source addItemWithTitle:@"すべての出典"];
        _source.accessibilityIdentifier = @"spacecraft-source-filter";
        _source.target = self;
        _source.action = @selector(filter:);
        NSStackView *filters = [NSStackView stackViewWithViews:@[_search, _source]];
        filters.spacing = 10;
        _summary = [NSTextField labelWithString:@"データ未読込"];
        _summary.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
        _summary.accessibilityIdentifier = @"spacecraft-summary";
        SpacecraftBrowserTableView *table = [[SpacecraftBrowserTableView alloc] init];
        table.contextController = self;
        _table = table;
        NSArray<NSString *> *identifiers = @[@"name", @"source", @"state"];
        NSArray<NSString *> *titles = @[@"探査機名", @"出典と原本内の順番", @"位置の評価"];
        for (NSUInteger index = 0; index < identifiers.count; ++index) {
            NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:identifiers[index]];
            column.title = titles[index];
            column.width = index == 0 ? 230 : index == 1 ? 350 : 180;
            [_table addTableColumn:column];
        }
        _table.dataSource = self;
        _table.delegate = self;
        _table.target = self;
        _table.doubleAction = @selector(center:);
        _table.usesAlternatingRowBackgroundColors = YES;
        _table.rowHeight = 24;
        _table.allowsMultipleSelection = NO;
        NSScrollView *scroll = [[NSScrollView alloc] init];
        scroll.documentView = _table;
        scroll.hasVerticalScroller = scroll.hasHorizontalScroller = YES;
        _count = [NSTextField labelWithString:@""];
        _count.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
        _count.accessibilityIdentifier = @"spacecraft-result-count";
        _previous = [NSButton buttonWithTitle:@"前の500件" target:self action:@selector(previousPage:)];
        _next = [NSButton buttonWithTitle:@"次の500件" target:self action:@selector(nextPage:)];
        NSStackView *pagination = [NSStackView stackViewWithViews:@[_count, _previous, _next]];
        pagination.spacing = 10;
        _details = [[NSTextView alloc] init];
        _details.editable = NO;
        _details.selectable = YES;
        _details.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
        _details.textColor = NSColor.labelColor;
        _details.backgroundColor = NSColor.textBackgroundColor;
        _details.autoresizingMask = NSViewWidthSizable;
        _details.textContainer.widthTracksTextView = YES;
        NSScrollView *detailScroll = [[NSScrollView alloc] init];
        detailScroll.documentView = _details;
        detailScroll.hasVerticalScroller = YES;
        _select = [NSButton buttonWithTitle:@"選択・診断を表示" target:self action:@selector(select:)];
        _center = [NSButton buttonWithTitle:@"選択して3Dの中心へ" target:self action:@selector(center:)];
        NSStackView *footer = [NSStackView stackViewWithViews:@[_select, _center]];
        footer.spacing = 10;
        NSStackView *layout = [NSStackView stackViewWithViews:@[filters, _summary, scroll, pagination, detailScroll, footer]];
        layout.orientation = NSUserInterfaceLayoutOrientationVertical;
        layout.spacing = 10;
        layout.translatesAutoresizingMaskIntoConstraints = NO;
        [window.contentView addSubview:layout];
        NSMutableArray<NSLayoutConstraint *> *constraints = [NSMutableArray arrayWithArray:@[
            [layout.leadingAnchor constraintEqualToAnchor:window.contentView.leadingAnchor constant:16],
            [layout.trailingAnchor constraintEqualToAnchor:window.contentView.trailingAnchor constant:-16],
            [layout.topAnchor constraintEqualToAnchor:window.contentView.topAnchor constant:16],
            [layout.bottomAnchor constraintEqualToAnchor:window.contentView.bottomAnchor constant:-16],
            [filters.heightAnchor constraintEqualToConstant:28],
            [pagination.heightAnchor constraintEqualToConstant:28],
            [footer.heightAnchor constraintEqualToConstant:28],
            [detailScroll.heightAnchor constraintEqualToConstant:110]]];
        for (NSView *view in layout.arrangedSubviews)
            [constraints addObject:[view.widthAnchor constraintEqualToAnchor:layout.widthAnchor]];
        [NSLayoutConstraint activateConstraints:constraints];
        _select.enabled = _center.enabled = _previous.enabled = _next.enabled = NO;
    }
    return self;
}
- (void)dealloc { if (_generation) _generation->fetch_add(1, std::memory_order_relaxed); }
- (void)setModel:(std::shared_ptr<const SpacecraftBrowserModel>)model snapshot:(std::shared_ptr<const SpacecraftSnapshot>)snapshot {
    if (snapshot && snapshot->model != model) throw std::invalid_argument("spacecraft snapshot/model mismatch");
    // 可視の表が旧 index を新データへ解決する前に、旧検索と選択を破棄する。
    _generation->fetch_add(1, std::memory_order_relaxed);
    _page = {};
    [_table deselectAll:nil];
    [_table reloadData];
    _model = std::move(model);
    [_source removeAllItems];
    [_source addItemWithTitle:@"すべての出典"];
    if (_model) for (const auto& source : _model->sources()) [_source addItemWithTitle:string(source)];
    [_source selectItemAtIndex:0];
    [self setSnapshot:std::move(snapshot)];
    [self filter:nil];
}
- (void)setSnapshot:(std::shared_ptr<const SpacecraftSnapshot>)snapshot {
    if (snapshot && snapshot->model != _model) throw std::invalid_argument("spacecraft snapshot/model mismatch");
    _snapshot = std::move(snapshot);
    _summary.stringValue = _model ? [NSString stringWithFormat:@"原本の探査機 %lu 件 · 出典 %lu 種類 · 位置評価 %lu 件",
        _model->model().dataset().definitions.size(), _model->sources().size(), _snapshot ? _snapshot->positioned_count : 0] : @"データ未読込";
    if (self.window.visible) { [_table reloadData]; [self updateDetails]; }
}
- (std::shared_ptr<const SpacecraftSnapshot>)prepareSnapshot:(std::shared_ptr<const SpacecraftSnapshot>)snapshot {
    if (snapshot && snapshot->model != _model) throw std::invalid_argument("spacecraft snapshot/model mismatch");
    return snapshot;
}
- (void)commitPreparedDate:(std::shared_ptr<const SpacecraftSnapshot>&&)snapshot {
    _snapshot = std::move(snapshot);
}
- (void)finishDateUpdate {
    _summary.stringValue = _model ? [NSString stringWithFormat:@"原本の探査機 %lu 件 · 出典 %lu 種類 · 位置評価 %lu 件",
        _model->model().dataset().definitions.size(), _model->sources().size(), _snapshot ? _snapshot->positioned_count : 0] : @"データ未読込";
    if (self.window.visible) { [_table reloadData]; [self updateDetails]; }
}
- (void)showWindow:(id)sender { [super showWindow:sender]; [_table reloadData]; [self updateDetails]; }
- (void)filter:(id)sender { (void)sender; _offset = 0; [self startSearch]; }
- (void)startSearch {
    const auto generation = _generation;
    const auto ticket = generation->fetch_add(1, std::memory_order_relaxed) + 1;
    const auto model = _model;
    _page = {};
    [_table deselectAll:nil];
    [_table reloadData];
    _select.enabled = _center.enabled = _previous.enabled = _next.enabled = NO;
    [self updateDetails];
    if (!model) { _count.stringValue = @"データ未読込"; return; }
    const std::string query = _search.stringValue.UTF8String;
    const NSInteger sourceIndex = _source.indexOfSelectedItem;
    const auto source = sourceIndex > 0 && static_cast<std::size_t>(sourceIndex) <= model->sources().size()
        ? std::optional<std::string>(model->sources()[sourceIndex - 1]) : std::nullopt;
    const auto offset = _offset;
    _count.stringValue = @"原本の全行を検索中…";
    __weak SpacecraftController *weakSelf = self;
    dispatch_async(_queue, ^{
        @autoreleasepool {
            try {
                auto page = std::make_shared<SpacecraftSearchPage>(model->search(query, source, offset, pageSize, [&] {
                    return generation->load(std::memory_order_relaxed) != ticket;
                }));
                if (page->cancelled) return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    SpacecraftController *controller = weakSelf;
                    if (controller && generation->load(std::memory_order_relaxed) == ticket) [controller applyPage:std::move(*page)];
                });
            } catch (const std::exception& error) {
                NSString *message = string(error.what());
                dispatch_async(dispatch_get_main_queue(), ^{
                    SpacecraftController *controller = weakSelf;
                    if (controller && generation->load(std::memory_order_relaxed) == ticket)
                        controller->_count.stringValue = [@"検索に失敗: " stringByAppendingString:message];
                });
            }
        }
    });
}
- (void)applyPage:(SpacecraftSearchPage)page {
    _page = std::move(page);
    [_table reloadData];
    const auto last = _page.offset + _page.rows.size();
    _count.stringValue = [NSString stringWithFormat:@"%lu–%lu / 該当 %lu 件（全 %lu 件）",
        _page.rows.empty() ? 0 : _page.offset + 1, _page.rows.empty() ? 0 : last,
        _page.total_matches, _model->model().dataset().definitions.size()];
    _previous.enabled = _offset > 0;
    _next.enabled = last < _page.total_matches;
}
- (void)previousPage:(id)sender { (void)sender; if (_previous.enabled) { _offset = _offset >= pageSize ? _offset - pageSize : 0; [self startSearch]; } }
- (void)nextPage:(id)sender { (void)sender; if (_next.enabled) { _offset += pageSize; [self startSearch]; } }
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView { (void)tableView; return static_cast<NSInteger>(_page.rows.size()); }
- (std::optional<std::size_t>)selectedIndex {
    const NSInteger row = _table.selectedRow;
    return row >= 0 && static_cast<std::size_t>(row) < _page.rows.size() ? std::optional<std::size_t>(_page.rows[row]) : std::nullopt;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    (void)tableView;
    if (!_model || row < 0 || static_cast<std::size_t>(row) >= _page.rows.size()) return @"";
    const auto index = _page.rows[row];
    if ([column.identifier isEqualToString:@"name"]) return string(_model->title(index));
    if ([column.identifier isEqualToString:@"source"]) return string(_model->provenance(index));
    if (_snapshot && index < _snapshot->positions.size() && _snapshot->positions[index]) return @"位置評価済み";
    return _snapshot ? @"未解決・診断あり" : @"位置未評価";
}
- (void)updateDetails {
    const auto index = [self selectedIndex];
    if (_model && index) _details.string = string(spacecraft_description(*_model, *index, _snapshot.get()));
    else if (_model) _details.string = string(spacecraft_catalog_description(*_model));
    else _details.string = @"";
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    (void)notification;
    _select.enabled = _center.enabled = [self selectedIndex].has_value();
    [self updateDetails];
}
- (NSMenu *)contextMenuForRow:(NSInteger)row {
    if (!_model || row < 0 || static_cast<std::size_t>(row) >= _page.rows.size()) return nil;
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"探査機"];
    [menu addItemWithTitle:_select.title action:@selector(select:) keyEquivalent:@""];
    [menu addItemWithTitle:_center.title action:@selector(center:) keyEquivalent:@""];
    for (NSMenuItem *item in menu.itemArray) {
        item.target = self;
        item.tag = static_cast<NSInteger>(_page.rows[row]);
        item.representedObject = @(_generation->load(std::memory_order_relaxed));
    }
    return menu;
}
- (void)choose:(BOOL)center sender:(id)sender {
    const auto index = [self selectedIndex];
    if (!index || !self.chooseObject) return;
    if ([sender isKindOfClass:NSMenuItem.class]) {
        NSMenuItem *item = sender;
        // 検索や読込で同じ行番号に別の原本が入っても、開いた時点の項目を転用しない。
        if (![item.representedObject isKindOfClass:NSNumber.class]
            || [item.representedObject unsignedLongLongValue] != _generation->load(std::memory_order_relaxed)
            || item.tag != static_cast<NSInteger>(*index)) return;
    }
    self.chooseObject(*index, center);
}
- (void)select:(id)sender { [self choose:NO sender:sender]; }
- (void)center:(id)sender { [self choose:YES sender:sender]; }
@end
