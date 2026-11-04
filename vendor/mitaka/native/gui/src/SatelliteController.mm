#import "SatelliteController.h"
#include <atomic>
#include <algorithm>
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

@implementation SatelliteController {
    std::shared_ptr<const SatelliteBrowserModel> _model;
    std::shared_ptr<const SatelliteSnapshot> _snapshot;
    SatelliteSearchPage _page;
    std::shared_ptr<const SatelliteDisplayModel> _display;
    std::shared_ptr<const SatelliteOrbitGeometry> _orbits;
    std::shared_ptr<std::atomic<std::uint64_t>> _generation;
    dispatch_queue_t _queue;
    std::size_t _offset;
    NSSearchField *_search;
    NSPopUpButton *_source;
    NSTableView *_table;
    NSTextField *_count, *_summary;
    NSTextView *_details;
    NSButton *_previous, *_next, *_select, *_center, *_member;
    NSArray<NSButton *> *_flags;
}
- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 850, 640)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    if ((self = [super initWithWindow:window])) {
        window.title = @"衛星";
        window.releasedWhenClosed = NO;
        window.minSize = NSMakeSize(650, 440);
        window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
        [window center];
        _generation = std::make_shared<std::atomic<std::uint64_t>>(0);
        _queue = dispatch_queue_create("org.mitaka.satellite-search", DISPATCH_QUEUE_SERIAL);
        _search = [[NSSearchField alloc] init];
        _search.placeholderString = @"衛星名・親天体・出典ファイルを全件検索";
        _search.target = self;
        _search.action = @selector(filter:);
        _search.sendsSearchStringImmediately = YES;
        _source = [[NSPopUpButton alloc] init];
        [_source addItemWithTitle:@"すべての出典"];
        _source.accessibilityIdentifier = @"satellite-source-filter";
        _source.target = self;
        _source.action = @selector(filter:);
        NSStackView *filters = [NSStackView stackViewWithViews:@[_search, _source]];
        filters.spacing = 10;
        NSMutableArray<NSButton *> *flags = [NSMutableArray array];
        for (NSString *title in @[@"衛星を表示", @"名称", @"瞬時軌道", @"表示集合のみ"]) {
            NSButton *flag = [NSButton checkboxWithTitle:title target:self action:@selector(changeFlags:)];
            [flags addObject:flag];
        }
        _flags = flags;
        NSStackView *displayOptions = [NSStackView stackViewWithViews:_flags];
        displayOptions.spacing = 16;
        _member = [NSButton buttonWithTitle:@"表示集合に追加" target:self action:@selector(toggleMember:)];
        NSButton *all = [NSButton buttonWithTitle:@"全原行を集合へ" target:self action:@selector(selectAllMembers:)];
        NSButton *none = [NSButton buttonWithTitle:@"集合を空にする" target:self action:@selector(clearMembers:)];
        NSStackView *members = [NSStackView stackViewWithViews:@[_member, all, none]];
        members.spacing = 10;
        _summary = [NSTextField labelWithString:@"データ未読込"];
        _summary.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
        _summary.accessibilityIdentifier = @"satellite-summary";
        _table = [[NSTableView alloc] init];
        NSArray<NSString *> *identifiers = @[@"name", @"parent", @"source", @"state", @"member"];
        NSArray<NSString *> *titles = @[@"衛星名", @"親天体", @"出典と原本内の順番", @"位置の評価", @"表示集合"];
        for (NSUInteger index = 0; index < identifiers.count; ++index) {
            NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:identifiers[index]];
            column.title = titles[index];
            column.width = index == 0 ? 200 : index == 1 ? 140 : index == 2 ? 290 : 170;
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
        _count.accessibilityIdentifier = @"satellite-result-count";
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
        NSStackView *layout = [NSStackView stackViewWithViews:@[filters, displayOptions, _summary, scroll, pagination, members, detailScroll, footer]];
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
- (void)setModel:(std::shared_ptr<const SatelliteBrowserModel>)model snapshot:(std::shared_ptr<const SatelliteSnapshot>)snapshot {
    if (snapshot && snapshot->model != model) throw std::invalid_argument("satellite snapshot/model mismatch");
    // 可視の表が旧 index を新データへ解決する前に、旧検索と選択を破棄する。
    _generation->fetch_add(1, std::memory_order_relaxed);
    _page = {};
    [_table deselectAll:nil];
    [_table reloadData];
    _model = std::move(model);
    _display.reset();
    _orbits.reset();
    [self refreshDisplayControls];
    [_source removeAllItems];
    [_source addItemWithTitle:@"すべての出典"];
    if (_model) for (const auto& source : _model->sources()) [_source addItemWithTitle:string(source)];
    [_source selectItemAtIndex:0];
    [self setSnapshot:std::move(snapshot)];
    [self filter:nil];
}
- (void)setSnapshot:(std::shared_ptr<const SatelliteSnapshot>)snapshot {
    if (snapshot && snapshot->model != _model) throw std::invalid_argument("satellite snapshot/model mismatch");
    if (snapshot != _snapshot) _orbits.reset();
    _snapshot = std::move(snapshot);
    _summary.stringValue = _model ? [NSString stringWithFormat:@"原本の衛星 %lu 件 · 出典 %lu 種類 · 位置評価 %lu 件",
        _model->model().records().size(), _model->sources().size(), _snapshot ? _snapshot->positioned_count : 0] : @"データ未読込";
    if (self.window.visible) { [_table reloadData]; [self updateDetails]; }
}
- (void)setDisplayModel:(std::shared_ptr<const SatelliteDisplayModel>)display {
    if (display && (!_model || display->model().get() != &_model->model()))
        throw std::invalid_argument("satellite display/model mismatch");
    _display = std::move(display);
    [self refreshDisplayControls];
    [_table reloadData];
    [self updateDetails];
}
- (void)setOrbitGeometry:(std::shared_ptr<const SatelliteOrbitGeometry>)geometry {
    if (geometry && geometry->snapshot != _snapshot)
        throw std::invalid_argument("satellite orbit/snapshot mismatch");
    _orbits = std::move(geometry);
    [self updateDetails];
}
- (void)refreshDisplayControls {
    const auto options = _display ? _display->options() : SatelliteDisplayOptions{};
    const bool values[] = {options.visible,options.labels,options.orbits,options.selected_only};
    for (NSUInteger flag=0; flag<_flags.count; ++flag) {
        _flags[flag].state = values[flag] ? NSControlStateValueOn : NSControlStateValueOff;
        _flags[flag].enabled = bool(_display);
    }
    const auto index = [self selectedIndex];
    _member.enabled = _display && index.has_value();
    _member.title = _display && index && _display->contains(_display->id_at(*index)) ? @"表示集合から除く" : @"表示集合に追加";
}
- (void)changeFlags:(id)sender {
    (void)sender;
    if (_display && self.changeDisplayOptions) self.changeDisplayOptions({
        _flags[0].state == NSControlStateValueOn, _flags[1].state == NSControlStateValueOn,
        _flags[2].state == NSControlStateValueOn, _flags[3].state == NSControlStateValueOn});
    [self refreshDisplayControls];
}
- (void)toggleMember:(id)sender {
    (void)sender;
    const auto index = [self selectedIndex];
    if (!_display || !index || !self.changeDisplaySelection) return;
    auto ids = _display->selected_ids();
    const auto id = _display->id_at(*index);
    const auto found = std::find_if(ids.begin(),ids.end(),[&](const auto& candidate) {
        return candidate.source_key == id.source_key && candidate.record_ordinal == id.record_ordinal;
    });
    if (found == ids.end()) ids.push_back(id); else ids.erase(found);
    self.changeDisplaySelection(ids);
}
- (void)selectAllMembers:(id)sender {
    (void)sender;
    if (!_display || !self.changeDisplaySelection) return;
    std::vector<SatelliteRecordId> ids;
    for (std::size_t row=0; row<_display->model()->records().size(); ++row) ids.push_back(_display->id_at(row));
    self.changeDisplaySelection(ids);
}
- (void)clearMembers:(id)sender { (void)sender; if (_display && self.changeDisplaySelection) self.changeDisplaySelection({}); }
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
    __weak SatelliteController *weakSelf = self;
    dispatch_async(_queue, ^{
        @autoreleasepool {
            try {
                auto page = std::make_shared<SatelliteSearchPage>(model->search(query, source, offset, pageSize, [&] {
                    return generation->load(std::memory_order_relaxed) != ticket;
                }));
                if (page->cancelled) return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    SatelliteController *controller = weakSelf;
                    if (controller && generation->load(std::memory_order_relaxed) == ticket) [controller applyPage:std::move(*page)];
                });
            } catch (const std::exception& error) {
                NSString *message = string(error.what());
                dispatch_async(dispatch_get_main_queue(), ^{
                    SatelliteController *controller = weakSelf;
                    if (controller && generation->load(std::memory_order_relaxed) == ticket)
                        controller->_count.stringValue = [@"検索に失敗: " stringByAppendingString:message];
                });
            }
        }
    });
}
- (void)applyPage:(SatelliteSearchPage)page {
    _page = std::move(page);
    [_table reloadData];
    const auto last = _page.offset + _page.rows.size();
    _count.stringValue = [NSString stringWithFormat:@"%lu–%lu / 該当 %lu 件（全 %lu 件）",
        _page.rows.empty() ? 0 : _page.offset + 1, _page.rows.empty() ? 0 : last,
        _page.total_matches, _model->model().records().size()];
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
    if ([column.identifier isEqualToString:@"parent"]) return string(_model->parent_title(index));
    if ([column.identifier isEqualToString:@"source"]) return string(_model->provenance(index));
    if ([column.identifier isEqualToString:@"member"]) return _display && _display->contains(_display->id_at(index)) ? @"含む" : @"含まない";
    if (_snapshot && index < _snapshot->positions.size() && _snapshot->positions[index]) return @"位置評価済み";
    return _snapshot ? @"未解決・診断あり" : @"位置未評価";
}
- (void)updateDetails {
    const auto index = [self selectedIndex];
    if (_model && index) {
        auto text = satellite_description(*_model, *index, _snapshot.get());
        if (_orbits && *index < _orbits->rows.size()) {
            const auto& orbit = _orbits->rows[*index];
            text += "\n瞬時軌道: " + (orbit.points_au.empty() ? orbit.diagnostic : "現在日時の親位置・軌道面を固定した楕円（時刻を進める日心軌跡ではありません）。");
        }
        _details.string = string(text);
    }
    else if (_model) {
        std::string text = "言語別の出典と同名の衛星を別の行として保持します。行を選ぶと位置・診断を表示します。";
        for (const auto& diagnostic : _model->model().dataset().diagnostics) text += "\n" + diagnostic.source_key + ": " + diagnostic.message;
        if (_snapshot) for (const auto& diagnostic : _snapshot->diagnostics) text += "\n" + diagnostic;
        _details.string = string(text);
    } else _details.string = @"";
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    (void)notification;
    _select.enabled = _center.enabled = [self selectedIndex].has_value();
    [self refreshDisplayControls];
    [self updateDetails];
}
- (void)choose:(BOOL)center { const auto index = [self selectedIndex]; if (index && self.chooseObject) self.chooseObject(*index, center); }
- (void)select:(id)sender { (void)sender; [self choose:NO]; }
- (void)center:(id)sender { (void)sender; [self choose:YES]; }
@end
