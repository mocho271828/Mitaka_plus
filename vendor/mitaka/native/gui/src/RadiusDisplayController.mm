#import "RadiusDisplayController.h"
#include <stdexcept>

using namespace mitaka::gui;
namespace {
BOOL fail(NSString **error, NSString *message) {
    if (error) *error = message;
    return NO;
}
NSLocale *inputLocale() { return [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"]; }
NSString *scaleText(float value) {
    // 最大 float を短い十進表示で範囲外へ丸めないよう、double の往復精度を保つ。
    return [[NSString alloc] initWithFormat:@"%.17g" locale:inputLocale(), static_cast<double>(value)];
}
}

@implementation RadiusDisplayController {
    NSTextField *_fields[4];
    NSPopUpButton *_mode;
    NSTextField *_status;
    NSButton *_apply;
    NSArray<NSString *> *_draft;
    RadiusScaleMode _draftMode;
    BOOL _hasSettings, _applying;
    NSString *_message;
}
- (instancetype)init {
    // loadWindow を上書きするので nib は読まない。nil window の initializer は
    // AppKit が読込済みと扱うため、こちらで遅延生成の状態を開始する。
    if ((self = [super initWithWindowNibName:@"RadiusDisplayController"])) {
        _draft = @[@"", @"", @"", @""];
        _draftMode = RadiusScaleMode::keep_orbit;
        _message = @"";
    }
    return self;
}
- (void)loadWindow {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 520, 400)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
        backing:NSBackingStoreBuffered defer:NO];
    window.title = @"天体の表示半径倍率";
    window.releasedWhenClosed = NO;
    window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    [window center];
    self.window = window;
    NSArray<NSString *> *titles = @[@"宇宙空間：惑星・月", @"宇宙空間：太陽",
        @"プラネタリウム：惑星", @"プラネタリウム：太陽・月"];
    NSMutableArray<NSView *> *rows = [NSMutableArray array];
    for (NSUInteger i = 0; i < 4; ++i) {
        NSTextField *label = [NSTextField labelWithString:titles[i]];
        [label.widthAnchor constraintEqualToConstant:250].active = YES;
        _fields[i] = [NSTextField textFieldWithString:_draft[i]];
        _fields[i].accessibilityIdentifier = [NSString stringWithFormat:@"radius-scale-%lu", i];
        [_fields[i].widthAnchor constraintEqualToConstant:210].active = YES;
        NSStackView *row = [NSStackView stackViewWithViews:@[label, _fields[i]]];
        row.spacing = 12;
        [rows addObject:row];
    }
    _mode = [[NSPopUpButton alloc] init];
    [_mode addItemsWithTitles:@[@"見かけの半径を保つ（KEEP_RADIUS）", @"視点距離を保つ（KEEP_ORBIT）"]];
    _mode.accessibilityIdentifier = @"radius-scale-mode";
    [rows addObject:_mode];
    NSTextField *note = [NSTextField wrappingLabelWithString:
        @"倍率は模式表示に適用します。全天図・地平図の点には大きさの上下限があります。地表・飛行などの物理表示や物理半径は変更しません。視点の状態により適用できない場合は理由を表示します。"];
    note.font = [NSFont systemFontOfSize:11];
    [rows addObject:note];
    _status = [NSTextField wrappingLabelWithString:_message];
    _status.accessibilityIdentifier = @"radius-scale-status";
    [_status.heightAnchor constraintGreaterThanOrEqualToConstant:34].active = YES;
    [rows addObject:_status];
    NSButton *reload = [NSButton buttonWithTitle:@"現在値を読み直す" target:self action:@selector(reload:)];
    _apply = [NSButton buttonWithTitle:@"適用" target:self action:@selector(apply:)];
    _apply.accessibilityIdentifier = @"radius-scale-apply";
    NSButton *close = [NSButton buttonWithTitle:@"閉じる" target:self action:@selector(closePanel:)];
    NSStackView *buttons = [NSStackView stackViewWithViews:@[reload, _apply, close]];
    buttons.spacing = 12;
    [rows addObject:buttons];
    NSStackView *layout = [NSStackView stackViewWithViews:rows];
    layout.orientation = NSUserInterfaceLayoutOrientationVertical;
    layout.alignment = NSLayoutAttributeLeading;
    layout.spacing = 10;
    layout.translatesAutoresizingMaskIntoConstraints = NO;
    [window.contentView addSubview:layout];
    [NSLayoutConstraint activateConstraints:@[
        [layout.leadingAnchor constraintEqualToAnchor:window.contentView.leadingAnchor constant:18],
        [layout.trailingAnchor constraintEqualToAnchor:window.contentView.trailingAnchor constant:-18],
        [layout.topAnchor constraintEqualToAnchor:window.contentView.topAnchor constant:18],
        [note.widthAnchor constraintEqualToAnchor:layout.widthAnchor],
        [_status.widthAnchor constraintEqualToAnchor:layout.widthAnchor]]];
    [self updateFields];
}
- (void)windowDidLoad {
    [super windowDidLoad];
    [self updateFields];
}
- (void)updateFields {
    if (!self.isWindowLoaded) return;
    for (NSUInteger i = 0; i < 4; ++i) _fields[i].stringValue = _draft[i];
    [_mode selectItemAtIndex:static_cast<NSInteger>(_draftMode)];
    _apply.enabled = _hasSettings && self.applySettings != nil;
    _status.stringValue = _message;
}
- (BOOL)reloadSettingsWithError:(NSString **)error {
    if (error) *error = nil;
    if (![NSThread isMainThread]) return fail(error, @"表示半径設定は main thread で操作してください。");
    if (_applying) return fail(error, @"表示半径の適用中は読み直せません。");
    NSString *failure = nil;
    RadiusDisplayOptions options;
    RadiusScaleMode mode = RadiusScaleMode::keep_orbit;
    const auto read = self.readSettings;
    BOOL accepted = read && read(&options, &mode, &failure);
    if (accepted) {
        try {
            validate_radius_display_options(options);
            validate_radius_scale_mode(mode);
        } catch (const std::invalid_argument& exception) {
            failure = [NSString stringWithUTF8String:exception.what()];
            accepted = NO;
        }
    }
    _hasSettings = accepted;
    if (accepted) {
        _draft = @[scaleText(options.space_planet), scaleText(options.space_sun),
            scaleText(options.planetarium_planet), scaleText(options.planetarium_sun_moon)];
        _draftMode = mode;
        _message = @"";
    } else {
        _message = failure.length ? failure : @"現在の表示半径設定を取得できません。";
    }
    [self updateFields];
    return accepted ? YES : fail(error, _message);
}
- (BOOL)applyFieldValues:(NSArray<NSString *> *)values mode:(NSInteger)mode error:(NSString **)error {
    if (error) *error = nil;
    if (![NSThread isMainThread]) return fail(error, @"表示半径設定は main thread で操作してください。");
    if (_applying) return fail(error, @"表示半径を適用しています。処理の完了をお待ちください。");
    if (values.count != 4 || (mode != 0 && mode != 1)) return fail(error, @"4個の倍率と有効なモードを指定してください。");
    RadiusDisplayOptions options;
    try {
        double parsed[4];
        for (NSUInteger i = 0; i < 4; ++i) {
            NSString *value = values[i];
            if (![value isKindOfClass:NSString.class] || value.length == 0 || value.length > 128)
                return fail(error, @"倍率には128文字以内の正の数値を指定してください。");
            NSScanner *scanner = [NSScanner scannerWithString:value];
            scanner.locale = inputLocale();
            if (![scanner scanDouble:&parsed[i]] || !scanner.isAtEnd)
                return fail(error, @"倍率には桁区切りのない正の数値を指定してください。");
        }
        options = checked_radius_display_options(parsed[0], parsed[1], parsed[2], parsed[3]);
    } catch (const std::invalid_argument& exception) {
        return fail(error, [NSString stringWithUTF8String:exception.what()]);
    }
    const auto apply = self.applySettings;
    if (!apply) return fail(error, @"表示半径の適用先が接続されていません。");
    NSString *failure = nil;
    BOOL accepted = NO;
    _applying = YES;
    @try { accepted = apply(options, static_cast<RadiusScaleMode>(mode), &failure); }
    @finally { _applying = NO; }
    return accepted ? YES : fail(error, failure.length ? failure : @"表示半径の変更は受け付けられませんでした。");
}
- (void)showWindow:(id)sender {
    NSString *error = nil;
    [self reloadSettingsWithError:&error];
    [super showWindow:sender];
}
- (void)reload:(id)sender { (void)sender; [self reloadSettingsWithError:nullptr]; }
- (void)apply:(id)sender {
    (void)sender;
    NSString *error = nil;
    if (![self applyFieldValues:@[_fields[0].stringValue, _fields[1].stringValue,
            _fields[2].stringValue, _fields[3].stringValue] mode:_mode.indexOfSelectedItem error:&error]) {
        _message = error;
    } else if ([self reloadSettingsWithError:&error]) {
        _message = @"表示半径倍率を適用しました。";
    } else {
        _message = [@"変更は適用済みですが、現在値を取得できません。\n" stringByAppendingString:error];
    }
    _status.stringValue = _message;
}
- (void)closePanel:(id)sender { (void)sender; [self close]; }
@end
