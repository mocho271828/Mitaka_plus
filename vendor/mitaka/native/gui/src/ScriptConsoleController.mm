#import "ScriptConsoleController.h"

namespace {
constexpr NSUInteger textLimit = 1024 * 1024;
constexpr NSUInteger historyLimit = 100;
}

@interface ScriptConsoleInputView : NSTextView
@property(nonatomic, weak) ScriptConsoleController *console;
@end

@implementation ScriptConsoleInputView
- (BOOL)performKeyEquivalent:(NSEvent *)event {
    const NSEventModifierFlags flags = event.modifierFlags &
        (NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagShift);
    if (event.type == NSEventTypeKeyDown && flags == NSEventModifierFlagCommand &&
        ([event.charactersIgnoringModifiers isEqualToString:@"\r"] ||
         [event.charactersIgnoringModifiers isEqualToString:@"\3"])) {
        // IME の変換確定を実行操作と取り違えない。
        if (!self.hasMarkedText) [self.console submitInput:nil];
        return YES;
    }
    return [super performKeyEquivalent:event];
}
- (void)keyDown:(NSEvent *)event {
    const NSEventModifierFlags flags = event.modifierFlags &
        (NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagShift);
    if (!self.hasMarkedText && flags == NSEventModifierFlagOption && event.charactersIgnoringModifiers.length == 1) {
        const unichar character = [event.charactersIgnoringModifiers characterAtIndex:0];
        if (character == NSUpArrowFunctionKey) { [self.console previousInput:nil]; return; }
        if (character == NSDownArrowFunctionKey) { [self.console nextInput:nil]; return; }
    }
    [super keyDown:event];
}
@end

@implementation ScriptConsoleController {
    ScriptConsoleInputView *_inputView;
    NSTextView *_outputView;
    NSButton *_run, *_cancel, *_previous, *_next;
    NSTextField *_status;
    NSMutableString *_output;
    NSMutableArray<NSString *> *_history;
    NSUInteger _historyIndex, _historyCharacters;
    NSString *_draft;
    BOOL _cancelling;
}

- (instancetype)init {
    if ((self = [super initWithWindowNibName:@"ScriptConsoleController"])) {
        _inputSource = @"";
        _draft = @"";
        _output = [NSMutableString string];
        _history = [NSMutableArray array];
    }
    return self;
}

- (void)loadWindow {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 780, 600)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    window.title = @"ローカル Lua コンソール";
    window.releasedWhenClosed = NO;
    window.contentMinSize = NSMakeSize(640, 480);
    window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    [window center];
    self.window = window;

    NSTextField *note = [NSTextField wrappingLabelWithString:
        @"信頼したローカル入力だけを実行してください。ファイルの読み書きと OS コマンドの実行を許可します。\n入力ごとに Lua を起動するため、変数は次の入力に残りません。履歴はこの起動中だけ保持します。"];
    note.font = [NSFont systemFontOfSize:11];
    _outputView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 740, 240)];
    _outputView.editable = NO;
    _outputView.string = _output;
    _outputView.accessibilityIdentifier = @"script-console-output";
    _inputView = [[ScriptConsoleInputView alloc] initWithFrame:NSMakeRect(0, 0, 740, 120)];
    _inputView.console = self;
    _inputView.delegate = self;
    _inputView.string = _inputSource;
    _inputView.accessibilityIdentifier = @"script-console-input";
    _inputView.automaticQuoteSubstitutionEnabled = NO;
    _inputView.automaticDashSubstitutionEnabled = NO;
    _inputView.automaticTextReplacementEnabled = NO;
    _inputView.automaticSpellingCorrectionEnabled = NO;
    NSMutableArray<NSScrollView *> *scrolls = [NSMutableArray array];
    for (NSTextView *text in @[_outputView, _inputView]) {
        text.richText = NO;
        text.font = [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular];
        text.textColor = NSColor.textColor;
        text.backgroundColor = NSColor.textBackgroundColor;
        text.insertionPointColor = NSColor.textColor;
        text.textContainerInset = NSMakeSize(6, 6);
        text.autoresizingMask = NSViewWidthSizable;
        text.verticallyResizable = YES;
        text.horizontallyResizable = NO;
        text.textContainer.widthTracksTextView = YES;
        NSScrollView *scroll = [[NSScrollView alloc] init];
        scroll.borderType = NSBezelBorder;
        scroll.hasVerticalScroller = YES;
        scroll.documentView = text;
        [scrolls addObject:scroll];
    }
    NSTextField *inputLabel = [NSTextField labelWithString:@"入力 — 改行: Return ／ 実行: ⌘Return ／ 履歴: ⌥↑・⌥↓"];
    inputLabel.font = [NSFont systemFontOfSize:11];
    _previous = [NSButton buttonWithTitle:@"前の入力" target:self action:@selector(previousInput:)];
    _next = [NSButton buttonWithTitle:@"次の入力" target:self action:@selector(nextInput:)];
    _run = [NSButton buttonWithTitle:@"実行 ⌘Return" target:self action:@selector(submitInput:)];
    _cancel = [NSButton buttonWithTitle:@"取消" target:self action:@selector(cancel:)];
    _run.accessibilityIdentifier = @"script-console-run";
    _cancel.accessibilityIdentifier = @"script-console-cancel";
    _previous.accessibilityIdentifier = @"script-console-previous";
    _next.accessibilityIdentifier = @"script-console-next";
    _status = [NSTextField labelWithString:@""];
    _status.font = [NSFont systemFontOfSize:11];
    _status.accessibilityIdentifier = @"script-console-status";
    NSStackView *buttons = [NSStackView stackViewWithViews:@[_previous, _next, _run, _cancel, _status]];
    buttons.spacing = 10;
    NSStackView *layout = [NSStackView stackViewWithViews:@[note, scrolls[0], inputLabel, scrolls[1], buttons]];
    layout.orientation = NSUserInterfaceLayoutOrientationVertical;
    layout.alignment = NSLayoutAttributeLeading;
    layout.spacing = 10;
    layout.translatesAutoresizingMaskIntoConstraints = NO;
    [window.contentView addSubview:layout];
    [NSLayoutConstraint activateConstraints:@[
        [layout.leadingAnchor constraintEqualToAnchor:window.contentView.leadingAnchor constant:16],
        [layout.trailingAnchor constraintEqualToAnchor:window.contentView.trailingAnchor constant:-16],
        [layout.topAnchor constraintEqualToAnchor:window.contentView.topAnchor constant:16],
        [layout.bottomAnchor constraintEqualToAnchor:window.contentView.bottomAnchor constant:-16],
        [note.widthAnchor constraintEqualToAnchor:layout.widthAnchor],
        [scrolls[0].widthAnchor constraintEqualToAnchor:layout.widthAnchor],
        [scrolls[1].widthAnchor constraintEqualToAnchor:layout.widthAnchor],
        [scrolls[0].heightAnchor constraintGreaterThanOrEqualToConstant:120],
        [scrolls[1].heightAnchor constraintEqualToConstant:120]]];
    [self updateControls];
}

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [self.window makeKeyAndOrderFront:sender];
    [self.window makeFirstResponder:_inputView];
}

- (void)updateControls {
    _run.enabled = !_running && self.runSource &&
        [_inputSource stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length > 0;
    _cancel.enabled = _running && !_cancelling && self.cancelExecution;
    _previous.enabled = !_running && _historyIndex > 0;
    _next.enabled = !_running && _historyIndex < _history.count;
    _status.stringValue = _cancelling ? @"取消中…" : _running ? @"実行中…" : @"入力待ち";
}

- (void)setInputSource:(NSString *)source {
    _inputSource = [source copy];
    _inputView.string = source;
    [self updateControls];
}
- (void)textDidChange:(NSNotification *)notification {
    (void)notification;
    _inputSource = [_inputView.string copy];
    [self updateControls];
}
- (void)setRunning:(BOOL)running {
    _running = running;
    if (!running) _cancelling = NO;
    [self updateControls];
}
- (NSString *)outputText { return [_output copy]; }
- (void)appendOutput:(NSString *)text {
    NSString *record = [text stringByAppendingString:@"\n"];
    [_output appendString:record];
    [_outputView.textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:record
        attributes:@{NSFontAttributeName:[NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular],
                     NSForegroundColorAttributeName:NSColor.textColor}]];
    if (_output.length > textLimit) {
        const NSRange range = [_output rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, _output.length - textLimit)];
        [_output deleteCharactersInRange:range];
        [_outputView.textStorage deleteCharactersInRange:range];
    }
    [_outputView scrollRangeToVisible:NSMakeRange(_output.length, 0)];
}
- (void)clearOutput {
    [_output setString:@""];
    _outputView.string = @"";
}

- (void)submitInput:(id)sender {
    (void)sender;
    if (_running || _inputView.hasMarkedText) return;
    NSString *source = [_inputSource copy];
    if (![source stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].length) return;
    NSData *data = [source dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    if (!data || data.length > textLimit) {
        [self appendOutput:@"入力は UTF-8 で 1 MiB 以下にしてください。"];
        return;
    }
    self.running = YES;
    [self appendOutput:[@"> " stringByAppendingString:source]];
    NSError *error = nil;
    const auto run = self.runSource;
    if (!run || !run(source, &error)) {
        self.running = NO;
        [self appendOutput:error.localizedDescription ? error.localizedDescription : @"Lua の実行先が接続されていません。"];
        return;
    }
    [_history addObject:source];
    _historyCharacters += source.length;
    while (_history.count > historyLimit || _historyCharacters > textLimit) {
        _historyCharacters -= _history.firstObject.length;
        [_history removeObjectAtIndex:0];
    }
    _historyIndex = _history.count;
    _draft = @"";
    self.inputSource = @"";
}

- (void)previousInput:(id)sender {
    (void)sender;
    if (_running || _historyIndex == 0 || _inputView.hasMarkedText) return;
    if (_historyIndex == _history.count) _draft = [_inputSource copy];
    self.inputSource = _history[--_historyIndex];
    [_inputView setSelectedRange:NSMakeRange(_inputSource.length, 0)];
}
- (void)nextInput:(id)sender {
    (void)sender;
    if (_running || _historyIndex == _history.count || _inputView.hasMarkedText) return;
    ++_historyIndex;
    self.inputSource = _historyIndex == _history.count ? _draft : _history[_historyIndex];
    [_inputView setSelectedRange:NSMakeRange(_inputSource.length, 0)];
}
- (void)cancel:(id)sender {
    (void)sender;
    if (!_running || _cancelling || !self.cancelExecution) return;
    _cancelling = YES;
    [self updateControls];
    self.cancelExecution();
}
@end
