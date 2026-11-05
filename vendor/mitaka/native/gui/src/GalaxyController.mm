#import "GalaxyController.h"
#include <charconv>
#include <limits>

using namespace mitaka;
using namespace mitaka::gui;
namespace {
NSString *text(const std::string& value) {
    NSString *result = [[NSString alloc] initWithBytes:value.data() length:value.size() encoding:NSUTF8StringEncoding];
    return result ? result : @"UTF-8で表示できない出典";
}
NSString *familyTitle(GalaxySpatialFamily family) {
    switch (family) {
        case GalaxySpatialFamily::sdss_galaxy: return @"SDSS銀河";
        case GalaxySpatialFamily::sdss_quasar: return @"SDSS QSO";
        case GalaxySpatialFamily::globular_cluster: return @"球状星団";
        case GalaxySpatialFamily::nearby_galaxy: return @"近傍銀河";
    }
    throw std::invalid_argument("unknown galaxy family");
}
NSButton *button(NSString *title, id target, SEL action, NSString *identifier) {
    NSButton *result = [NSButton buttonWithTitle:title target:target action:action];
    result.accessibilityIdentifier = identifier;
    [result setContentHuggingPriority:NSLayoutPriorityRequired forOrientation:NSLayoutConstraintOrientationHorizontal];
    return result;
}
NSStackView *horizontal(NSArray<NSView *> *views) {
    NSStackView *stack = [NSStackView stackViewWithViews:views];
    stack.spacing = 10; stack.alignment = NSLayoutAttributeCenterY;
    return stack;
}
NSString *issues(const GalaxySpatialRow& row) {
    if (row.issues == 0) return @"位置に関する診断なし";
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    if (row.issue_domain == GalaxyIssueDomain::sdss) {
        for (unsigned bit = 1; bit <= unsigned(SdssSpatialIssue::nonfinite_classification); bit <<= 1)
            if (row.issues & bit) [result addObject:text(std::string(sdss_spatial_issue_message(SdssSpatialIssue(bit))))];
    } else {
        NSArray<NSString *> *reasons = @[@"赤経が非有限", @"赤経が範囲外", @"赤緯が非有限", @"赤緯が範囲外",
            @"距離が非有限", @"負の距離", @"距離0（原点として表示）"];
        for (NSUInteger bit = 0; bit < reasons.count; ++bit)
            if (row.issues & (1u << bit)) [result addObject:reasons[bit]];
    }
    return [result componentsJoinedByString:@" / "];
}
NSString *details(const GalaxySpatialModel& model, GalaxySpatialRecordId id) {
    const auto row = model.row(id);
    NSMutableString *result = [NSMutableString stringWithFormat:@"%@ · 出典 %lu · 原行 %lu\n%@\n%@\n",
        familyTitle(id.family), id.source_index + 1, id.ordinal + 1,
        text(model.source_path(id.source_index).string()), issues(row)];
    if (row.position) [result appendFormat:@"native J2000黄道 pc: (%.12g, %.12g, %.12g)\n",
        row.position->x_pc, row.position->y_pc, row.position->z_pc];
    else [result appendString:@"位置を生成できないため、描画・中央移動はできません。\n"];
    const auto& source = model.sources()[id.source_index];
    if (const auto* sdss = std::get_if<GalaxySdssSource>(&source)) {
        const auto& raw = sdss->snapshot->model->record({sdss->source_index, id.ordinal});
        [result appendFormat:@"原値 RA %.9g° / Dec %.9g° / 距離 %.9g pc / 分類値 %.9g\n",
            raw.coordinates.right_ascension_deg, raw.coordinates.declination_deg,
            double(raw.distance_parsecs), double(raw.classification_value)];
    } else if (const auto* gc = std::get_if<PlusGlobularClusterCatalog>(&source)) {
        const auto& raw = gc->records[id.ordinal];
        [result appendFormat:@"原値 RA %.9g° / Dec %.9g° / 距離 %.9g pc\ncore半径 %.9g pc / half-light半径 %.9g pc\nB−V %.9g / V−R %.9g\n名称の原12 bytes:",
            double(raw.right_ascension_degrees), double(raw.declination_degrees), double(raw.distance_pc),
            double(raw.core_radius_pc), double(raw.half_light_radius_pc), double(raw.color_b_minus_v), double(raw.color_v_minus_r)];
        for (auto byte : raw.name_bytes) [result appendFormat:@" %02X", unsigned(byte)];
        [result appendString:@"\n"];
    } else {
        const auto& raw = std::get<PlusNearbyGalaxyCatalog>(source).records[id.ordinal];
        [result appendFormat:@"原値 RA %.9g° / Dec %.9g° / 距離 %.9g pc\n角直径 %.9g arcmin / 短長軸比 %.9g\n原code %u / %u / %u · 原番号 %d\n",
            double(raw.right_ascension_degrees), double(raw.declination_degrees), double(raw.distance_pc),
            double(raw.angular_diameter_arcminutes), double(raw.minor_major_axis_ratio),
            unsigned(raw.render_class_code), unsigned(raw.auxiliary_code), unsigned(raw.catalog_code), raw.catalog_number];
    }
    [result appendString:@"点の色・大きさはnativeの種別表示です。原版の測光・形状表示や名称表の結合は未対応です。"];
    return result;
}
}

@implementation GalaxyController {
    GalaxyView *_view;
    NSButton *_families[4], *_select, *_focus;
    NSPopUpButton *_source;
    NSTextField *_ordinal, *_status, *_camera, *_error;
    NSTextView *_details;
    NSString *_diagnostics;
}
- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 940, 800)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    if ((self = [super initWithWindow:window])) {
        window.title = @"銀河・球状星団 — parsec空間";
        window.releasedWhenClosed = NO; window.delegate = self;
        window.minSize = NSMakeSize(800, 680);
        window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
        [window center];
        NSMutableArray<NSView *> *toggles = [NSMutableArray array];
        NSArray<NSString *> *titles = @[@"SDSS銀河", @"SDSS QSO", @"球状星団", @"近傍銀河"];
        for (NSUInteger index = 0; index < 4; ++index) {
            _families[index] = [NSButton checkboxWithTitle:titles[index] target:self action:@selector(visibilityChanged:)];
            _families[index].state = NSControlStateValueOn;
            _families[index].accessibilityIdentifier = [NSString stringWithFormat:@"galaxy-family-%lu", index];
            [toggles addObject:_families[index]];
        }
        [toggles addObject:button(@"視点をリセット", self, @selector(resetCamera:), @"galaxy-reset")];
        _source = [[NSPopUpButton alloc] init];
        _source.accessibilityIdentifier = @"galaxy-source";
        _source.target = self; _source.action = @selector(sourceChanged:);
        [_source.widthAnchor constraintGreaterThanOrEqualToConstant:260].active = YES;
        _ordinal = [NSTextField textFieldWithString:@"1"];
        _ordinal.accessibilityIdentifier = @"galaxy-ordinal";
        _ordinal.target = self; _ordinal.action = @selector(selectOriginalRow:);
        [_ordinal.widthAnchor constraintEqualToConstant:110].active = YES;
        _select = button(@"原行を選択", self, @selector(selectOriginalRow:), @"galaxy-select-row");
        _focus = button(@"選択を中央へ", self, @selector(focus:), @"galaxy-focus");
        NSStackView *row = horizontal(@[_source, [NSTextField labelWithString:@"原行（1から）"], _ordinal, _select, _focus]);
        _view = [[GalaxyView alloc] initWithFrame:NSMakeRect(0, 0, 900, 450)];
        _status = [NSTextField wrappingLabelWithString:@"データ未読込"];
        _status.accessibilityIdentifier = @"galaxy-render-status";
        _camera = [NSTextField labelWithString:@""];
        _camera.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
        _error = [NSTextField wrappingLabelWithString:@""];
        _error.accessibilityIdentifier = @"galaxy-error";
        _error.textColor = NSColor.systemOrangeColor;
        _details = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 900, 130)];
        _details.editable = NO; _details.selectable = YES;
        _details.font = [NSFont monospacedSystemFontOfSize:11 weight:NSFontWeightRegular];
        _details.autoresizingMask = NSViewWidthSizable;
        _details.accessibilityIdentifier = @"galaxy-details";
        NSScrollView *scroll = [[NSScrollView alloc] init];
        scroll.documentView = _details; scroll.hasVerticalScroller = YES;
        [scroll.heightAnchor constraintEqualToConstant:140].active = YES;
        NSStackView *stack = [NSStackView stackViewWithViews:@[horizontal(toggles), row,
            [NSTextField labelWithString:@"ドラッグ: 回転 · Shift+ドラッグ: 平行移動 · スクロール: 拡大縮小 · ダブルクリック: 中央移動"],
            _view, _status, _camera, _error, scroll]];
        stack.orientation = NSUserInterfaceLayoutOrientationVertical;
        stack.alignment = NSLayoutAttributeLeading; stack.spacing = 8;
        stack.translatesAutoresizingMaskIntoConstraints = NO;
        [window.contentView addSubview:stack];
        [NSLayoutConstraint activateConstraints:@[
            [stack.leadingAnchor constraintEqualToAnchor:window.contentView.leadingAnchor constant:12],
            [stack.trailingAnchor constraintEqualToAnchor:window.contentView.trailingAnchor constant:-12],
            [stack.topAnchor constraintEqualToAnchor:window.contentView.topAnchor constant:12],
            [stack.bottomAnchor constraintEqualToAnchor:window.contentView.bottomAnchor constant:-12],
            [_view.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
            [_view.heightAnchor constraintGreaterThanOrEqualToConstant:240],
            [_status.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
            [_error.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
            [scroll.widthAnchor constraintEqualToAnchor:stack.widthAnchor],
            [row.widthAnchor constraintEqualToAnchor:stack.widthAnchor]]];
        [_view setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationVertical];
        __weak GalaxyController *weakSelf = self;
        _view.stateChanged = ^{ [weakSelf refresh]; };
        _diagnostics = @"";
        [self refresh];
    }
    return self;
}
- (GalaxyView *)galaxyView { return _view; }
- (void)setModel:(std::shared_ptr<const GalaxySpatialModel>)model diagnostics:(NSString *)diagnostics {
    const auto prior = [_view model];
    _diagnostics = [diagnostics copy];
    [_view setModel:model];
    if (prior != model) {
        [_source removeAllItems]; _ordinal.stringValue = @"1";
        if (model) for (std::size_t index = 0; index < model->sources().size(); ++index) {
            [_source addItemWithTitle:[NSString stringWithFormat:@"%lu: %@ · %@ (%lu行)", index + 1,
                familyTitle(model->family(index)), text(model->source_path(index).filename().string()), model->source_size(index)]];
        }
    }
    _error.stringValue = @"";
    [self refresh];
}
- (void)setRendererDisplayOptions:(RendererDisplayOptions)options { [_view setRendererDisplayOptions:options]; }
- (void)invalidate { [_view invalidatePendingWork]; }
- (void)windowWillClose:(NSNotification *)notification { (void)notification; [self invalidate]; }
- (void)showWindow:(id)sender { [super showWindow:sender]; _view.needsDisplay = YES; }
- (void)refresh {
    const auto model = [_view model];
    const auto selection = [_view selectedRecord];
    _source.enabled = model && !model->sources().empty();
    const NSInteger source = _source.indexOfSelectedItem;
    _select.enabled = _ordinal.enabled = model && source >= 0 &&
        std::size_t(source) < model->sources().size() && model->source_size(std::size_t(source)) > 0;
    _focus.enabled = selection && model && model->row(*selection).position.has_value();
    const auto visibility = [_view galaxyVisibility];
    const bool flags[] = {visibility.sdss_galaxies, visibility.sdss_quasars, visibility.globular_clusters, visibility.nearby_galaxies};
    for (NSUInteger index = 0; index < 4; ++index) _families[index].state = flags[index] ? NSControlStateValueOn : NSControlStateValueOff;
    _status.stringValue = [_view renderStatus];
    const auto camera = [_view galaxyCamera];
    _camera.stringValue = [NSString stringWithFormat:@"注視点 (%.7g, %.7g, %.7g) pc · 距離 %.7g pc · yaw %.5g° / pitch %.5g°",
        camera.target.x_pc, camera.target.y_pc, camera.target.z_pc, camera.distance_pc, camera.yaw_deg, camera.pitch_deg];
    NSString *selectionDetails = selection && model ? details(*model, *selection) : @"原行を選択すると元の値と位置の診断を表示します。";
    _details.string = [NSString stringWithFormat:@"%@\n%@", selectionDetails, _diagnostics ? _diagnostics : @""];
}
- (void)sourceChanged:(id)sender { (void)sender; _ordinal.stringValue = @"1"; _error.stringValue = @""; [self refresh]; }
- (void)selectOriginalRow:(id)sender {
    (void)sender;
    const auto model = [_view model];
    const NSInteger source = _source.indexOfSelectedItem;
    if (!model || source < 0 || std::size_t(source) >= model->sources().size()) return;
    NSData *encoded = [_ordinal.stringValue dataUsingEncoding:NSUTF8StringEncoding];
    // 埋込み NUL の後も含めて検証し、見えている原行番号と解析値の食い違いを防ぐ。
    const std::string input = encoded.length ? std::string(static_cast<const char *>(encoded.bytes), encoded.length) : "";
    std::size_t ordinal = 0;
    const auto parsed = std::from_chars(input.data(), input.data() + input.size(), ordinal);
    if (parsed.ec != std::errc{} || parsed.ptr != input.data() + input.size() || ordinal == 0 ||
        ordinal > model->source_size(std::size_t(source))) {
        _error.stringValue = @"原行は出典内の1から始まる10進整数で指定してください。";
        return;
    }
    [_view selectRecord:GalaxySpatialRecordId{model->family(std::size_t(source)), std::size_t(source), ordinal - 1}];
    _error.stringValue = @"";
}
- (void)visibilityChanged:(id)sender {
    (void)sender;
    const GalaxySpatialVisibility visibility{_families[0].state == NSControlStateValueOn, _families[1].state == NSControlStateValueOn,
        _families[2].state == NSControlStateValueOn, _families[3].state == NSControlStateValueOn};
    [_view setGalaxyVisibility:visibility];
    if (self.visibilityChanged) self.visibilityChanged(visibility);
}
- (void)resetCamera:(id)sender { (void)sender; [_view setGalaxyCamera:GalaxyCameraPc{}]; }
- (void)focus:(id)sender { (void)sender; [_view focusSelection]; }
@end
