#import "ScriptConsoleController.h"
#include <cstdio>
#include <stdexcept>

namespace {
int checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
NSView *findView(NSView *view, NSString *identifier) {
    if ([view.accessibilityIdentifier isEqualToString:identifier]) return view;
    for (NSView *child in view.subviews)
        if (NSView *found = findView(child, identifier)) return found;
    return nil;
}
NSEvent *key(NSString *characters, NSEventModifierFlags flags) {
    return [NSEvent keyEventWithType:NSEventTypeKeyDown location:NSZeroPoint modifierFlags:flags
        timestamp:0 windowNumber:0 context:nil characters:characters charactersIgnoringModifiers:characters
        isARepeat:NO keyCode:36];
}
}

int main() {
    @autoreleasepool {
        try {
            [NSApplication sharedApplication];
            ScriptConsoleController *console = [ScriptConsoleController new];
            __block NSUInteger executions = 0, cancellations = 0;
            __block NSString *lastSource = nil;
            __weak ScriptConsoleController *weakConsole = console;
            console.runSource = ^BOOL(NSString *source, NSError **) {
                ++executions;
                lastSource = source;
                [weakConsole submitInput:nil];
                return YES;
            };
            console.cancelExecution = ^{ ++cancellations; };
            check(!console.isWindowLoaded, "construction and callbacks do not load the window");
            console.inputSource = @" \n\t";
            [console submitInput:nil];
            check(executions == 0, "blank input does not execute");
            [console previousInput:nil]; [console nextInput:nil];
            check([console.inputSource isEqualToString:@" \n\t"], "empty history keeps draft");
            console.inputSource = @"local x = 3\nreturn x + 2";
            [console submitInput:nil];
            check(executions == 1 && console.running, "explicit submit starts exactly one run including callback reentry");
            check([lastSource isEqualToString:@"local x = 3\nreturn x + 2"], "multiline source is preserved");
            check(console.inputSource.length == 0 && [console.outputText containsString:@"> local x = 3\nreturn x + 2\n"],
                "accepted input is echoed and cleared");
            console.inputSource = @"next draft";
            [console submitInput:nil]; [console previousInput:nil]; [console nextInput:nil];
            check(executions == 1 && [console.inputSource isEqualToString:@"next draft"], "busy submit and history leave draft intact");
            [console cancel:nil]; [console cancel:nil];
            check(cancellations == 1 && console.running, "cancel invokes once and waits for completion");
            [console appendOutput:@"取消しました。"];
            console.running = NO;
            [console cancel:nil];
            check(cancellations == 1, "idle cancel is inert");
            console.inputSource = @"2 + 2";
            [console submitInput:nil]; console.running = NO;
            console.inputSource = @"unfinished\ndraft";
            [console previousInput:nil];
            check([console.inputSource isEqualToString:@"2 + 2"], "previous recalls newest input");
            [console previousInput:nil]; [console previousInput:nil];
            check([console.inputSource isEqualToString:@"local x = 3\nreturn x + 2"], "history stops at oldest entry");
            [console nextInput:nil]; [console nextInput:nil]; [console nextInput:nil];
            check([console.inputSource isEqualToString:@"unfinished\ndraft"], "history roundtrip restores multiline draft");
            console.runSource = ^BOOL(NSString *, NSError **error) {
                ++executions;
                *error = [NSError errorWithDomain:@"test" code:1 userInfo:@{NSLocalizedDescriptionKey:@"helper missing"}];
                return NO;
            };
            [console submitInput:nil];
            check(!console.running && [console.inputSource isEqualToString:@"unfinished\ndraft"] &&
                [console.outputText hasSuffix:@"helper missing\n"], "launch failure retains editable input and displays reason");
            console.runSource = ^BOOL(NSString *source, NSError **) { ++executions; lastSource = source; return YES; };
            console.inputSource = @"error('intentional')";
            [console submitInput:nil];
            [console appendOutput:@"console.lua:1: intentional\nstack traceback:"];
            console.running = NO;
            console.inputSource = @"print('after error')";
            [console submitInput:nil];
            check(console.running && [lastSource isEqualToString:@"print('after error')"], "runtime failure permits next explicit run");
            console.running = NO;
            const NSUInteger beforeLarge = executions;
            console.inputSource = [@"a" stringByPaddingToLength:1024 * 1024 + 1 withString:@"a" startingAtIndex:0];
            [console submitInput:nil];
            check(executions == beforeLarge && !console.running && [console.outputText containsString:@"1 MiB"],
                "oversize source is rejected before launch");
            console.inputSource = @"1";
            NSWindow *window = console.window;
            NSTextView *input = (NSTextView *)findView(window.contentView, @"script-console-input");
            NSTextView *output = (NSTextView *)findView(window.contentView, @"script-console-output");
            NSButton *run = (NSButton *)findView(window.contentView, @"script-console-run");
            NSButton *cancel = (NSButton *)findView(window.contentView, @"script-console-cancel");
            check(input && output && run && cancel && input.editable && !output.editable,
                "window has editable input and readonly transcript with run and cancel controls");
            check(run.enabled && !cancel.enabled, "idle controls reflect executable input");
            const NSUInteger beforeKey = executions;
            check([input performKeyEquivalent:key(@"\r", NSEventModifierFlagCommand)], "command return is handled");
            check(executions == beforeKey + 1 && !run.enabled && cancel.enabled, "command return performs one explicit execution");
            console.running = NO;
            console.inputSource = @"draft";
            const unichar upCharacter = NSUpArrowFunctionKey, downCharacter = NSDownArrowFunctionKey;
            [input keyDown:key([NSString stringWithCharacters:&upCharacter length:1], NSEventModifierFlagOption)];
            check([console.inputSource isEqualToString:@"1"], "option up recalls history from editor");
            [input keyDown:key([NSString stringWithCharacters:&downCharacter length:1], NSEventModifierFlagOption)];
            check([console.inputSource isEqualToString:@"draft"], "option down restores draft from editor");
            [input setMarkedText:@"変換" selectedRange:NSMakeRange(0, 2) replacementRange:NSMakeRange(0, input.string.length)];
            const NSUInteger beforeComposition = executions;
            [input performKeyEquivalent:key(@"\r", NSEventModifierFlagCommand)];
            [console submitInput:nil];
            check(executions == beforeComposition && input.hasMarkedText, "composition cannot submit from shortcut or button");
            [input unmarkText];
            console.inputSource = @"line 1";
            [input setSelectedRange:NSMakeRange(input.string.length, 0)];
            [input insertNewline:nil];
            check([input.string containsString:@"\n"] && executions == beforeComposition, "ordinary return inserts newline without executing");
            [console clearOutput];
            [console appendOutput:@"first\nsecond"];
            check([console.outputText isEqualToString:@"first\nsecond\n"] && [output.string isEqualToString:console.outputText],
                "print records preserve embedded newline and visible transcript");
            check([input.textColor isEqual:NSColor.textColor] &&
                [[output.textStorage attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:nil] isEqual:NSColor.textColor],
                "input and appended output retain the adaptive text color in dark appearance");
            [console appendOutput:[@"😀" stringByPaddingToLength:1024 * 1024 + 20 withString:@"😀" startingAtIndex:0]];
            check(console.outputText.length <= 1024 * 1024 && [output.string isEqualToString:console.outputText] &&
                [console.outputText dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO],
                "output limit retains valid Unicode and synchronizes visible text");
            [console clearOutput];
            check(console.outputText.length == 0 && output.string.length == 0, "clear output affects only transcript");
            for (NSUInteger index = 0; index < 105; ++index) {
                console.inputSource = [NSString stringWithFormat:@"%lu", index];
                [console submitInput:nil]; console.running = NO;
            }
            console.inputSource = @"retained draft";
            for (NSUInteger index = 0; index < 110; ++index) [console previousInput:nil];
            check([console.inputSource isEqualToString:@"5"], "history retains newest one hundred commands");
            for (NSUInteger index = 0; index < 110; ++index) [console nextInput:nil];
            check([console.inputSource isEqualToString:@"retained draft"], "bounded history still restores draft");
            [window close];
            std::printf("script console: %d checks passed\n", checks);
        } catch (const std::exception& failure) {
            std::fprintf(stderr, "script console test failed: %s\n", failure.what()); return 1;
        }
    }
    return 0;
}
