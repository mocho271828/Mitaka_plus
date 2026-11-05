#import "SmallBodyController.h"
#include <atomic>
#include <algorithm>
#include <stdexcept>
#include <cmath>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
constexpr std::size_t pageSize = 500;
NSString *string(const std::string& text) {
    NSString *value = [[NSString alloc] initWithBytes:text.data() length:text.size() encoding:NSUTF8StringEncoding];
    return value ? value : @"";
}
}

@implementation SmallBodyController {
    std::shared_ptr<const SmallBodyModel> _model;
    std::shared_ptr<const SmallBodySnapshot> _snapshot;
    std::shared_ptr<const SmallBodyDisplayModel> _display;
    NSButton *_options[3][4];
    NSButton *_add, *_remove;
    NSTextField *_firstJD, *_lastJD, *_samples, *_orbitStatus, *_membership;
    SmallBodySearchPage _page;
    std::shared_ptr<std::atomic<std::uint64_t>> _generation;
    dispatch_queue_t _queue;
    std::size_t _offset;
    NSSearchField *_search;
    NSPopUpButton *_kind;
    NSTableView *_table;
    NSTextField *_count, *_summary;
    NSTextView *_details;
    NSButton *_previous, *_next, *_select, *_center;
}
- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 900, 850)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    if ((self = [super initWithWindow:window])) {
        window.title = @"小惑星・太陽系外縁天体・彗星";
        window.releasedWhenClosed = NO;
        window.minSize = NSMakeSize(850, 740);
        window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
        [window center];
        _generation = std::make_shared<std::atomic<std::uint64_t>>(0);
        _queue = dispatch_queue_create("org.mitaka.small-body-search", DISPATCH_QUEUE_SERIAL);
        _search = [[NSSearchField alloc] init];
        _search.placeholderString = @"名前・番号・出典ファイルを全件検索";
        _search.target = self;
        _search.action = @selector(filter:);
        _search.sendsSearchStringImmediately = YES;
        _kind = [[NSPopUpButton alloc] init];
        [_kind addItemsWithTitles:@[@"すべて", @"小惑星", @"太陽系外縁天体", @"彗星"]];
        _kind.target = self;
        _kind.action = @selector(filter:);
        NSStackView *filters = [NSStackView stackViewWithViews:@[_search, _kind]];
        filters.spacing = 10;
        _summary = [NSTextField labelWithString:@"データ未読込"];
        _summary.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
        _summary.accessibilityIdentifier = @"small-body-summary";
        _table = [[NSTableView alloc] init];
        NSArray<NSString *> *identifiers = @[@"name", @"source", @"state", @"member"];
        NSArray<NSString *> *titles = @[@"名称・原番号", @"出典と原本内の順番", @"位置の評価", @"表示集合"];
        for (NSUInteger index = 0; index < identifiers.count; ++index) {
            NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:identifiers[index]];
            column.title = titles[index];
            column.width = index == 0 ? 240 : index == 1 ? 280 : index == 2 ? 170 : 70;
            [_table addTableColumn:column];
        }
        _table.dataSource = self;
        _table.delegate = self;
        _table.target = self;
        _table.doubleAction = @selector(center:);
        _table.usesAlternatingRowBackgroundColors = YES;
        _table.rowHeight = 24;
        _table.allowsMultipleSelection = YES;
        NSScrollView *scroll = [[NSScrollView alloc] init];
        scroll.documentView = _table;
        scroll.hasVerticalScroller = scroll.hasHorizontalScroller = YES;
        _count = [NSTextField labelWithString:@""];
        _count.font = [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightRegular];
        _count.accessibilityIdentifier = @"small-body-result-count";
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
        _add = [NSButton buttonWithTitle:@"表示集合に追加" target:self action:@selector(addMembers:)];
        _remove = [NSButton buttonWithTitle:@"表示集合から除外" target:self action:@selector(removeMembers:)];
        NSStackView *footer = [NSStackView stackViewWithViews:@[_select, _center, _add, _remove]];
        footer.spacing = 10;
        NSMutableArray<NSView *> *rows = [NSMutableArray arrayWithObjects:filters, _summary, nil];
        NSArray<NSString *> *kindTitles = @[@"小惑星", @"太陽系外縁天体", @"彗星"];
        NSArray<NSString *> *flagTitles = @[@"表示", @"名称", @"軌道線", @"表示集合のみ"];
        for (NSUInteger kind = 0; kind < 3; ++kind) {
            NSTextField *label = [NSTextField labelWithString:kindTitles[kind]];
            [label.widthAnchor constraintEqualToConstant:120].active = YES;
            NSMutableArray<NSView *> *controls = [NSMutableArray arrayWithObject:label];
            for (NSUInteger flag = 0; flag < 4; ++flag) {
                NSButton *button = [NSButton checkboxWithTitle:flagTitles[flag] target:self action:@selector(changeOptions:)];
                button.tag = kind * 4 + flag;
                button.accessibilityIdentifier = [NSString stringWithFormat:@"small-body-option-%lu-%lu", kind, flag];
                _options[kind][flag] = button;
                [controls addObject:button];
            }
            NSStackView *row = [NSStackView stackViewWithViews:controls]; row.spacing = 18;
            [rows addObject:row];
        }
        _firstJD = [NSTextField textFieldWithString:@""]; _firstJD.accessibilityIdentifier = @"small-body-orbit-first";
        _lastJD = [NSTextField textFieldWithString:@""]; _lastJD.accessibilityIdentifier = @"small-body-orbit-last";
        _samples = [NSTextField textFieldWithString:@"129"]; _samples.accessibilityIdentifier = @"small-body-orbit-samples";
        [_firstJD.widthAnchor constraintGreaterThanOrEqualToConstant:145].active = YES;
        [_lastJD.widthAnchor constraintGreaterThanOrEqualToConstant:145].active = YES;
        [_samples.widthAnchor constraintEqualToConstant:65].active = YES;
        NSButton *apply = [NSButton buttonWithTitle:@"軌道区間を適用" target:self action:@selector(applySampling:)];
        NSStackView *sampling = [NSStackView stackViewWithViews:@[
            [NSTextField labelWithString:@"彗星 TDB JD"], _firstJD, [NSTextField labelWithString:@"〜"], _lastJD,
            [NSTextField labelWithString:@"標本数"], _samples, apply]];
        sampling.spacing = 8;
        [rows addObject:sampling];
        NSTextField *orbitExplanation = [NSTextField wrappingLabelWithString:@"彗星は指定区間、36 byte の小惑星・外縁天体は元期から一周期を標本化します。標本数は共通です。小惑星・外縁天体の数値 JD の物理時系は未確定です。"];
        orbitExplanation.accessibilityIdentifier = @"small-body-orbit-explanation";
        orbitExplanation.font = [NSFont systemFontOfSize:11];
        [rows addObject:orbitExplanation];
        _orbitStatus = [NSTextField wrappingLabelWithString:@"軌道線は二体近似です。"];
        _orbitStatus.accessibilityIdentifier = @"small-body-orbit-status";
        _orbitStatus.font = [NSFont systemFontOfSize:11];
        _membership = [NSTextField labelWithString:@"表示集合 0 件（行の選択・検索とは独立）"];
        _membership.accessibilityIdentifier = @"small-body-membership";
        [rows addObjectsFromArray:@[_orbitStatus, _membership, scroll, pagination, detailScroll, footer]];
        NSStackView *layout = [NSStackView stackViewWithViews:rows];
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
            [detailScroll.heightAnchor constraintEqualToConstant:90],
            [scroll.heightAnchor constraintGreaterThanOrEqualToConstant:130]]];
        for (NSView *view in layout.arrangedSubviews)
            [constraints addObject:[view.widthAnchor constraintEqualToAnchor:layout.widthAnchor]];
        [NSLayoutConstraint activateConstraints:constraints];
        _select.enabled = _center.enabled = _add.enabled = _remove.enabled = _previous.enabled = _next.enabled = NO;
        [self updateOptions];
    }
    return self;
}
- (void)dealloc { if (_generation) _generation->fetch_add(1, std::memory_order_relaxed); }
- (void)setModel:(std::shared_ptr<const SmallBodyModel>)model snapshot:(std::shared_ptr<const SmallBodySnapshot>)snapshot {
    if (snapshot && snapshot->model != model) throw std::invalid_argument("small-body snapshot/model mismatch");
    // 可視の表が旧 index を新データへ解決する前に、旧検索と選択を破棄する。
    _generation->fetch_add(1, std::memory_order_relaxed);
    _page = {};
    [_table deselectAll:nil];
    [_table reloadData];
    _model = std::move(model);
    _display.reset();
    [self updateOptions];
    [self setSnapshot:std::move(snapshot)];
    [self filter:nil];
}
- (void)setSnapshot:(std::shared_ptr<const SmallBodySnapshot>)snapshot {
    if (snapshot && snapshot->model != _model) throw std::invalid_argument("small-body snapshot/model mismatch");
    _snapshot = std::move(snapshot);
    _summary.stringValue = _model ? [NSString stringWithFormat:@"原本 %lu 件 · 位置計算対応 %lu 件 · 出典診断 %lu 件",
        _model->dataset().records.size(), _model->evaluable_indices().size(), _model->dataset().diagnostics.size()] : @"データ未読込";
    if (self.window.visible) { [_table reloadData]; [self updateDetails]; }
}
- (SmallBodyBrowserDate)prepareSnapshot:(std::shared_ptr<const SmallBodySnapshot>)snapshot
    display:(std::shared_ptr<const SmallBodyDisplayModel>)display {
    if (snapshot && snapshot->model != _model) throw std::invalid_argument("small-body snapshot/model mismatch");
    if (display && (!_model || display->dataset().get() != &_model->dataset()))
        throw std::invalid_argument("small-body display/model mismatch");
    return {std::move(snapshot), std::move(display)};
}
- (void)commitPreparedDate:(SmallBodyBrowserDate&&)prepared {
    _snapshot = std::move(prepared.snapshot);
    _display = std::move(prepared.display);
}
- (void)finishDateUpdate {
    _summary.stringValue = _model ? [NSString stringWithFormat:@"原本 %lu 件 · 位置計算対応 %lu 件 · 出典診断 %lu 件",
        _model->dataset().records.size(), _model->evaluable_indices().size(), _model->dataset().diagnostics.size()] : @"データ未読込";
    [self updateOptions];
    [_table reloadData];
    [self updateSelectionControls];
}
- (void)setDisplayModel:(std::shared_ptr<const SmallBodyDisplayModel>)display {
    if (display && (!_model || display->dataset().get() != &_model->dataset()))
        throw std::invalid_argument("small-body display/model mismatch");
    _display = std::move(display);
    [self updateOptions];
    [_table reloadData];
    [self updateSelectionControls];
}
- (void)updateOptions {
    for (NSUInteger kind = 0; kind < 3; ++kind) {
        const auto options = _display ? _display->kind_options(static_cast<SmallBodyKind>(kind)) : SmallBodyKindDisplayOptions{};
        const bool flags[] = {options.visible, options.labels, options.orbits, options.selected_only};
        for (NSUInteger flag = 0; flag < 4; ++flag) {
            _options[kind][flag].state = flags[flag] ? NSControlStateValueOn : NSControlStateValueOff;
            _options[kind][flag].enabled = bool(_display);
        }
    }
    _membership.stringValue = [NSString stringWithFormat:@"表示集合 %lu 件（行の選択・検索とは独立）",
        _display ? _display->selected_ids().size() : 0];
}
- (void)changeOptions:(NSButton *)sender {
    if (!_display || sender.tag < 0 || sender.tag >= 12) return;
    const NSUInteger kind = sender.tag / 4;
    SmallBodyKindDisplayOptions options{_options[kind][0].state == NSControlStateValueOn,
        _options[kind][1].state == NSControlStateValueOn, _options[kind][2].state == NSControlStateValueOn,
        _options[kind][3].state == NSControlStateValueOn};
    try { if (self.optionsChanged) self.optionsChanged(static_cast<SmallBodyKind>(kind), options); }
    catch (const std::exception& error) { [self setOrbitStatus:string(error.what())]; }
    [self updateOptions];
}
- (void)changeMembers:(BOOL)add {
    if (!_display || !_model) return;
    auto current = _display->selected_ids();
    std::set<SmallBodyId, SmallBodyIdLess> ids(current.begin(), current.end());
    NSIndexSet *selected = _table.selectedRowIndexes;
    for (NSUInteger row = selected.firstIndex; row != NSNotFound; row = [selected indexGreaterThanIndex:row]) {
        if (row >= _page.rows.size()) continue;
        const auto& id = _model->dataset().records[_page.rows[row]].id;
        if (add) ids.insert(id); else ids.erase(id);
    }
    try { if (self.displayIdsChanged) self.displayIdsChanged(std::vector<SmallBodyId>(ids.begin(), ids.end())); }
    catch (const std::exception& error) { [self setOrbitStatus:string(error.what())]; }
}
- (void)addMembers:(id)sender { (void)sender; [self changeMembers:YES]; }
- (void)removeMembers:(id)sender { (void)sender; [self changeMembers:NO]; }
- (void)setOrbitSampling:(SmallBodyOrbitSampling)sampling {
    validate_small_body_orbit_sampling(sampling);
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    _firstJD.stringValue = [[NSString alloc] initWithFormat:@"%.17g" locale:locale, sampling.first_jd];
    _lastJD.stringValue = [[NSString alloc] initWithFormat:@"%.17g" locale:locale, sampling.last_jd];
    _samples.stringValue = [NSString stringWithFormat:@"%lu", sampling.sample_count];
}
- (void)setOrbitStatus:(NSString *)status { _orbitStatus.stringValue = status ? status : @""; }
- (void)applySampling:(id)sender {
    (void)sender;
    try {
        double values[3];
        NSArray<NSTextField *> *fields = @[_firstJD, _lastJD, _samples];
        for (NSUInteger index = 0; index < 3; ++index) {
            NSScanner *scanner = [NSScanner scannerWithString:fields[index].stringValue];
            scanner.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            if (![scanner scanDouble:&values[index]] || !scanner.isAtEnd || !std::isfinite(values[index]))
                throw std::invalid_argument("有限の数値を桁区切りなしで入力してください。");
        }
        if (values[2] < 2 || values[2] > maximum_small_body_orbit_samples || std::trunc(values[2]) != values[2])
            throw std::invalid_argument("軌道の標本数は 2〜4096 の整数です。");
        const SmallBodyOrbitSampling sampling{values[0], values[1], static_cast<std::size_t>(values[2])};
        validate_small_body_orbit_sampling(sampling);
        if (self.orbitSamplingChanged) self.orbitSamplingChanged(sampling);
    } catch (const std::exception& error) { [self setOrbitStatus:string(error.what())]; }
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
    _select.enabled = _center.enabled = _add.enabled = _remove.enabled = _previous.enabled = _next.enabled = NO;
    [self updateDetails];
    if (!model) { _count.stringValue = @"データ未読込"; return; }
    const std::string query = _search.stringValue.UTF8String;
    const auto kind = _kind.indexOfSelectedItem ? std::optional<SmallBodyKind>(static_cast<SmallBodyKind>(_kind.indexOfSelectedItem - 1)) : std::nullopt;
    const auto offset = _offset;
    _count.stringValue = @"原本の全行を検索中…";
    __weak SmallBodyController *weakSelf = self;
    dispatch_async(_queue, ^{
        @autoreleasepool {
            try {
                auto page = std::make_shared<SmallBodySearchPage>(model->search(query, kind, offset, pageSize, [&] {
                    return generation->load(std::memory_order_relaxed) != ticket;
                }));
                if (page->cancelled) return;
                dispatch_async(dispatch_get_main_queue(), ^{
                    SmallBodyController *controller = weakSelf;
                    if (controller && generation->load(std::memory_order_relaxed) == ticket) [controller applyPage:std::move(*page)];
                });
            } catch (const std::exception& error) {
                NSString *message = string(error.what());
                dispatch_async(dispatch_get_main_queue(), ^{
                    SmallBodyController *controller = weakSelf;
                    if (controller && generation->load(std::memory_order_relaxed) == ticket)
                        controller->_count.stringValue = [@"検索に失敗: " stringByAppendingString:message];
                });
            }
        }
    });
}
- (void)applyPage:(SmallBodySearchPage)page {
    _page = std::move(page);
    [_table reloadData];
    const auto last = _page.offset + _page.rows.size();
    _count.stringValue = [NSString stringWithFormat:@"%lu–%lu / 該当 %lu 件（全 %lu 件）",
        _page.rows.empty() ? 0 : _page.offset + 1, _page.rows.empty() ? 0 : last,
        _page.total_matches, _model->dataset().records.size()];
    _previous.enabled = _offset > 0;
    _next.enabled = last < _page.total_matches;
}
- (void)previousPage:(id)sender { (void)sender; if (_previous.enabled) { _offset = _offset >= pageSize ? _offset - pageSize : 0; [self startSearch]; } }
- (void)nextPage:(id)sender { (void)sender; if (_next.enabled) { _offset += pageSize; [self startSearch]; } }
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView { (void)tableView; return static_cast<NSInteger>(_page.rows.size()); }
- (std::optional<std::size_t>)selectedIndex {
    if (_table.numberOfSelectedRows != 1) return {};
    const NSInteger row = _table.selectedRow;
    return row >= 0 && static_cast<std::size_t>(row) < _page.rows.size() ? std::optional<std::size_t>(_page.rows[row]) : std::nullopt;
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row {
    (void)tableView;
    if (!_model || row < 0 || static_cast<std::size_t>(row) >= _page.rows.size()) return @"";
    const auto index = _page.rows[row];
    if ([column.identifier isEqualToString:@"name"]) return string(_model->title(index));
    if ([column.identifier isEqualToString:@"source"]) return string(_model->provenance(index));
    if ([column.identifier isEqualToString:@"member"])
        return _display && _display->contains(_model->dataset().records[index].id) ? @"✓" : @"";
    if (_snapshot && index < _snapshot->positions.size() && _snapshot->positions[index]) return @"評価済み";
    const auto& indices = _model->evaluable_indices();
    if (!std::binary_search(indices.begin(), indices.end(), index)) return @"未確定・診断あり";
    return _snapshot && (_snapshot->evaluated_all || _snapshot->evaluated_selection == index) ? @"評価不可・診断あり" : @"位置未評価";
}
- (void)updateDetails {
    const auto index = [self selectedIndex];
    if (_model && index) _details.string = string(small_body_description(*_model, *index, _snapshot.get()));
    else if (_model) {
        std::string text = "同じ番号・元期でも原本の各行を保持します。1 行を選ぶと位置・診断を表示し、複数行を表示集合へ追加・除外できます。";
        for (const auto& diagnostic : _model->dataset().diagnostics) text += "\n" + diagnostic.source_key + ": " + diagnostic.message;
        _details.string = string(text);
    } else _details.string = @"";
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    (void)notification;
    [self updateSelectionControls];
}
- (void)updateSelectionControls {
    _select.enabled = _center.enabled = [self selectedIndex].has_value();
    _add.enabled = _remove.enabled = _display && _table.numberOfSelectedRows > 0;
    [self updateDetails];
}
- (void)choose:(BOOL)center { const auto index = [self selectedIndex]; if (index && self.chooseObject) self.chooseObject(*index, center); }
- (void)select:(id)sender { (void)sender; [self choose:NO]; }
- (void)center:(id)sender { (void)sender; [self choose:YES]; }
@end
