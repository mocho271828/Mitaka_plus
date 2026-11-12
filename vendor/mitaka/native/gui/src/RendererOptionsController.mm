#import "RendererOptionsController.h"
#include <array>

using mitaka::gui::RendererDisplayOptions;
namespace {
constexpr std::array<bool RendererDisplayOptions::*, 4> flags{{
    &RendererDisplayOptions::antialias, &RendererDisplayOptions::point_smoothing,
    &RendererDisplayOptions::line_smoothing, &RendererDisplayOptions::text_smoothing}};
BOOL fail(NSString **error, NSString *message) {
    if (error) *error = message;
    return NO;
}
}

@implementation RendererOptionsController {
    NSButton *_fields[4];
    NSTextField *_status;
    RendererDisplayOptions _options;
    NSString *_message;
    BOOL _hasSettings, _updating;
}
- (instancetype)init {
    if ((self = [super initWithWindowNibName:@"RendererOptionsController"])) _message = @"";
    return self;
}
- (void)loadWindow {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 480, 330)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable backing:NSBackingStoreBuffered defer:NO];
    window.title = @"描画品質";
    window.releasedWhenClosed = NO;
    window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    [window center];
    self.window = window;
    NSMutableArray<NSView *> *rows = [NSMutableArray array];
    NSArray<NSString *> *titles = @[@"アンチエイリアス", @"点を滑らかに描画", @"線を滑らかに描画", @"文字を滑らかに描画"];
    for (NSUInteger index = 0; index < flags.size(); ++index) {
        _fields[index] = [NSButton checkboxWithTitle:titles[index] target:self action:@selector(changeOption:)];
        _fields[index].tag = index;
        _fields[index].accessibilityIdentifier = [NSString stringWithFormat:@"renderer-option-%lu", index];
        [rows addObject:_fields[index]];
    }
    NSTextField *note = [NSTextField wrappingLabelWithString:
        @"変更はすぐに反映されます。アンチエイリアスがオフの間、点・線・文字の滑らかさは適用されません。各項目の設定値は保持されます。"];
    note.font = [NSFont systemFontOfSize:11];
    [rows addObject:note];
    _status = [NSTextField wrappingLabelWithString:_message];
    _status.font = [NSFont systemFontOfSize:11];
    _status.accessibilityIdentifier = @"renderer-options-status";
    [_status.heightAnchor constraintGreaterThanOrEqualToConstant:34].active = YES;
    [rows addObject:_status];
    NSButton *reload = [NSButton buttonWithTitle:@"現在値を読み直す" target:self action:@selector(reload:)];
    NSButton *close = [NSButton buttonWithTitle:@"閉じる" target:self action:@selector(closePanel:)];
    NSStackView *buttons = [NSStackView stackViewWithViews:@[reload, close]];
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
- (void)updateFields {
    for (NSUInteger index = 0; index < flags.size(); ++index) {
        _fields[index].state = _options.*flags[index] ? NSControlStateValueOn : NSControlStateValueOff;
        _fields[index].enabled = _hasSettings && !_updating && self.applySettings != nil;
    }
    _status.stringValue = _message;
}
- (void)synchronizeOptions:(RendererDisplayOptions)options {
    if (!NSThread.isMainThread) return;
    _options = options;
    _hasSettings = YES;
    _message = @"メニュー・Lua・保存状態と同じ設定を表示しています。";
    [self updateFields];
}
- (BOOL)reloadSettingsWithError:(NSString **)error {
    if (error) *error = nil;
    if (!NSThread.isMainThread) return fail(error, @"描画品質は main thread で操作してください。");
    if (_updating) return fail(error, @"描画品質を更新しています。");
    NSString *failure = nil;
    RendererDisplayOptions options;
    BOOL accepted = NO;
    _updating = YES;
    @try { accepted = self.readSettings && self.readSettings(&options, &failure); }
    @finally { _updating = NO; }
    if (accepted) [self synchronizeOptions:options];
    else {
        _hasSettings = NO;
        _message = failure.length ? failure : @"描画品質の現在値を取得できません。";
        [self updateFields];
    }
    return accepted ? YES : fail(error, _message);
}
- (BOOL)applyOptionAtIndex:(NSInteger)index enabled:(BOOL)enabled error:(NSString **)error {
    if (error) *error = nil;
    if (!NSThread.isMainThread) return fail(error, @"描画品質は main thread で操作してください。");
    if (_updating) return fail(error, @"描画品質を更新しています。");
    if (index < 0 || static_cast<NSUInteger>(index) >= flags.size())
        return fail(error, @"描画品質の項目が不正です。");
    NSString *failure = nil;
    RendererDisplayOptions options;
    BOOL read = NO, applied = NO;
    _updating = YES;
    [self updateFields];
    @try {
        read = self.readSettings && self.readSettings(&options, &failure);
        if (read) {
            _options = options;
            options.*flags[index] = enabled;
            applied = self.applySettings && self.applySettings(options, &failure);
        }
    } @finally { _updating = NO; }
    if (applied) [self synchronizeOptions:options];
    else {
        _hasSettings = read;
        _message = failure.length ? failure : read ? @"描画品質の変更を適用できません。" : @"描画品質の現在値を取得できません。";
        [self updateFields];
    }
    return applied ? YES : fail(error, _message);
}
- (void)showWindow:(id)sender {
    [self reloadSettingsWithError:nullptr];
    [super showWindow:sender];
}
- (void)changeOption:(NSButton *)sender {
    [self applyOptionAtIndex:sender.tag enabled:sender.state == NSControlStateValueOn error:nullptr];
}
- (void)reload:(id)sender { (void)sender; [self reloadSettingsWithError:nullptr]; }
- (void)closePanel:(id)sender { (void)sender; [self.window orderOut:nil]; }
@end
