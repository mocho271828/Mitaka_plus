#import "RendererOptionsController.h"
#include <array>
#include <cstdio>
#include <stdexcept>

using mitaka::gui::RendererDisplayOptions;
namespace {
int checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}
bool same(RendererDisplayOptions left, RendererDisplayOptions right) {
    return left.antialias == right.antialias && left.point_smoothing == right.point_smoothing &&
        left.line_smoothing == right.line_smoothing && left.text_smoothing == right.text_smoothing;
}
NSView *findView(NSView *view, NSString *identifier) {
    if ([view.accessibilityIdentifier isEqualToString:identifier]) return view;
    for (NSView *child in view.subviews) {
        NSView *found = findView(child, identifier);
        if (found) return found;
    }
    return nil;
}
NSButton *optionButton(RendererOptionsController *controller, NSUInteger index) {
    NSView *view = findView(controller.window.contentView,
                          [NSString stringWithFormat:@"renderer-option-%lu", static_cast<unsigned long>(index)]);
    check([view isKindOfClass:NSButton.class], "all four options have accessible controls");
    return static_cast<NSButton *>(view);
}
void expectOptions(RendererOptionsController *controller, RendererDisplayOptions expected) {
    const std::array<bool, 4> values{expected.antialias, expected.point_smoothing,
                                   expected.line_smoothing, expected.text_smoothing};
    for (NSUInteger index = 0; index < values.size(); ++index)
        check(optionButton(controller, index).state == (values[index] ? NSControlStateValueOn : NSControlStateValueOff),
              "displayed options match the current host state");
}

void test_operations_without_window() {
    RendererOptionsController *controller = [[RendererOptionsController alloc] init];
    NSString *error = nil;
    check(!controller.isWindowLoaded, "construction does not create a window");
    check(![controller reloadSettingsWithError:&error] && error.length, "missing reader reports failure");
    check(![controller applyOptionAtIndex:0 enabled:NO error:&error] && error.length,
          "missing callbacks reject an edit");
    __block RendererDisplayOptions state;
    __block NSUInteger reads = 0, writes = 0;
    controller.readSettings = ^BOOL(RendererDisplayOptions *options, NSString **) {
        ++reads;
        *options = state;
        return YES;
    };
    controller.applySettings = ^BOOL(RendererDisplayOptions options, NSString **) {
        ++writes;
        state = options;
        return YES;
    };
    check([controller reloadSettingsWithError:&error] && !error && reads == 1 && writes == 0,
          "reload reads without writing settings");
    for (NSInteger index = 0; index < 4; ++index) {
        // UI に残った値ではなく、操作時の外部変更を基準に一項目だけ更新する。
        state = {true, true, true, true};
        RendererDisplayOptions expected = state;
        const std::array<bool RendererDisplayOptions::*, 4> members{
            &RendererDisplayOptions::antialias, &RendererDisplayOptions::point_smoothing,
            &RendererDisplayOptions::line_smoothing, &RendererDisplayOptions::text_smoothing};
        expected.*members[index] = false;
        const NSUInteger before = writes;
        check([controller applyOptionAtIndex:index enabled:NO error:&error] && !error,
              "each quality option accepts an edit");
        check(writes == before + 1 && same(state, expected), "one edit writes once and preserves other options");
    }
    state = {false, true, false, true};
    check([controller applyOptionAtIndex:2 enabled:YES error:&error] && same(state, {false, true, true, true}),
          "individual preferences remain editable while master antialias is off");
    const auto retained = state;
    const NSUInteger beforeInvalid = writes;
    for (NSInteger index : {-1, 4, 999})
        check(![controller applyOptionAtIndex:index enabled:YES error:&error] && error.length,
              "unknown option indices reject");
    check(writes == beforeInvalid && same(state, retained), "invalid indices never alter host settings");
    controller.readSettings = ^BOOL(RendererDisplayOptions *, NSString **failure) {
        *failure = @"settings are unavailable";
        return NO;
    };
    check(![controller applyOptionAtIndex:0 enabled:YES error:&error] &&
          [error isEqualToString:@"settings are unavailable"] && writes == beforeInvalid,
          "read refusal propagates without attempting a write");
    controller.readSettings = ^BOOL(RendererDisplayOptions *options, NSString **) { *options = state; return YES; };
    controller.applySettings = ^BOOL(RendererDisplayOptions, NSString **failure) {
        ++writes;
        *failure = @"host rejected change";
        return NO;
    };
    check(![controller applyOptionAtIndex:0 enabled:YES error:&error] &&
          [error isEqualToString:@"host rejected change"] && same(state, retained),
          "host refusal preserves current settings and its diagnostic");
    __weak RendererOptionsController *weakController = controller;
    __block BOOL nestedApply = YES, nestedReload = YES;
    controller.applySettings = ^BOOL(RendererDisplayOptions options, NSString **) {
        ++writes;
        nestedApply = [weakController applyOptionAtIndex:1 enabled:NO error:nullptr];
        nestedReload = [weakController reloadSettingsWithError:nullptr];
        state = options;
        [weakController synchronizeOptions:state];
        return YES;
    };
    const NSUInteger beforeReentry = writes;
    check([controller applyOptionAtIndex:0 enabled:YES error:&error], "outer edit survives guarded reentry");
    check(!nestedApply && !nestedReload && writes == beforeReentry + 1,
          "apply callback cannot recursively read or write settings");
    controller.readSettings = ^BOOL(RendererDisplayOptions *options, NSString **) {
        nestedApply = [weakController applyOptionAtIndex:0 enabled:NO error:nullptr];
        nestedReload = [weakController reloadSettingsWithError:nullptr];
        *options = state;
        return YES;
    };
    check([controller reloadSettingsWithError:&error] && !nestedApply && !nestedReload,
          "read callback reentry is also rejected");
    const NSUInteger beforeBackground = writes;
    __block BOOL backgroundApply = YES, backgroundRead = YES;
    dispatch_semaphore_t finished = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        @autoreleasepool {
            backgroundApply = [controller applyOptionAtIndex:0 enabled:NO error:nullptr];
            backgroundRead = [controller reloadSettingsWithError:nullptr];
            dispatch_semaphore_signal(finished);
        }
    });
    check(dispatch_semaphore_wait(finished, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)) == 0,
          "background operations return without waiting on the main thread");
    check(!backgroundApply && !backgroundRead && writes == beforeBackground,
          "off-main operations never invoke host writes");
    check(!controller.isWindowLoaded, "model operations and synchronization do not create a window");
}

void test_window_updates() {
    RendererOptionsController *controller = [[RendererOptionsController alloc] init];
    __block RendererDisplayOptions state{true, false, true, false};
    __block NSUInteger writes = 0;
    __weak RendererOptionsController *weakController = controller;
    controller.readSettings = ^BOOL(RendererDisplayOptions *options, NSString **) { *options = state; return YES; };
    controller.applySettings = ^BOOL(RendererDisplayOptions options, NSString **) {
        ++writes;
        state = options;
        // 実アプリの共通 setter も適用中に受動同期する。
        [weakController synchronizeOptions:state];
        return YES;
    };
    [controller showWindow:nil];
    expectOptions(controller, state);
    check(writes == 0, "opening the dialog does not overwrite host settings");
    state = {false, true, false, true};
    [controller synchronizeOptions:state];
    expectOptions(controller, state);
    check(writes == 0, "menu Lua and session-style synchronization does not write back");
    for (NSUInteger index = 1; index < 4; ++index)
        check(optionButton(controller, index).enabled, "master off preserves access to individual preferences");
    [optionButton(controller, 1) performClick:nil];
    check(writes == 1 && same(state, {false, false, false, true}), "checkbox activation applies exactly one change");
    expectOptions(controller, state);
    [controller close];
    state = {true, true, true, false};
    [controller showWindow:nil];
    expectOptions(controller, state);
    check(writes == 1, "reopening reads external changes without restoring stale settings");
    controller.applySettings = ^BOOL(RendererDisplayOptions, NSString **failure) {
        ++writes;
        *failure = @"cannot apply now";
        return NO;
    };
    [optionButton(controller, 0) performClick:nil];
    expectOptions(controller, state);
    NSTextField *status = static_cast<NSTextField *>(findView(controller.window.contentView, @"renderer-options-status"));
    check([status isKindOfClass:NSTextField.class] && [status.stringValue containsString:@"cannot apply now"],
          "rejected checkbox edit displays the host error and restores the accepted values");
    check(writes == 2, "refused checkbox edit does not retry automatically");
    controller.applySettings = ^BOOL(RendererDisplayOptions options, NSString **) {
        ++writes;
        state = options;
        [weakController synchronizeOptions:state];
        return YES;
    };
    [optionButton(controller, 0) performClick:nil];
    expectOptions(controller, state);
    check(writes == 3 && !state.antialias && ![status.stringValue containsString:@"cannot apply now"],
          "a later successful edit clears the error and remains usable");
    controller.readSettings = ^BOOL(RendererDisplayOptions *, NSString **error) {
        *error = @"settings are temporarily unavailable";
        return NO;
    };
    NSString *error = nil;
    check(![controller reloadSettingsWithError:&error] &&
          [status.stringValue containsString:@"settings are temporarily unavailable"],
          "an unavailable host reports its read failure in the visible dialog");
    for (NSUInteger index = 0; index < 4; ++index)
        check(!optionButton(controller, index).enabled, "unavailable host disables stale option controls");
    controller.readSettings = ^BOOL(RendererDisplayOptions *options, NSString **) { *options = state; return YES; };
    check([controller reloadSettingsWithError:&error] && !error && writes == 3,
          "recovering host values does not apply settings automatically");
    for (NSUInteger index = 0; index < 4; ++index)
        check(optionButton(controller, index).enabled, "successful reload restores editing");
    [controller close];
}
}

int main() {
    @autoreleasepool {
        [NSApplication sharedApplication];
        try {
            test_operations_without_window();
            test_window_updates();
            std::printf("renderer options controller: %d checks passed\n", checks);
            return 0;
        } catch (const std::exception& failure) {
            std::fprintf(stderr, "renderer options controller failed: %s\n", failure.what());
            return 1;
        }
    }
}
