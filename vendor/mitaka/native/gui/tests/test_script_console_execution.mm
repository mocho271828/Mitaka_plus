#import <Foundation/Foundation.h>
#import "ScriptController.h"
#include <cstdio>
#include <stdexcept>
#include <string>
#include <vector>

using namespace mitaka::gui;
namespace {
void check(bool condition, const char *message) {
    if (!condition) throw std::runtime_error(message);
}

struct Outcome {
    bool succeeded = false;
    std::string message;
    std::vector<std::string> output;
};

Outcome run(ScriptController *controller, NSString *source, bool cancel = false, bool console = true) {
    __block bool finished = false;
    __block Outcome outcome;
    controller.output = ^(NSString *text) {
        check(NSThread.isMainThread, "output must arrive on the main thread");
        outcome.output.emplace_back(text.UTF8String);
    };
    controller.completion = ^(BOOL succeeded, NSString *message) {
        check(NSThread.isMainThread, "completion must arrive on the main thread");
        outcome.succeeded = succeeded;
        outcome.message = message.UTF8String;
        finished = true;
    };
    NSError *error = nil;
    const BOOL launched = console ? [controller runConsoleSource:source error:&error] :
        [controller runSource:source error:&error];
    check(launched, error ? error.localizedDescription.UTF8String : "launch source");
    check(controller.running, "running until completion");
    check(![controller runConsoleSource:@"42" error:&error] && error != nil,
          "reject a second input while the helper is running");
    if (cancel) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            [controller cancel];
        });
    }
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5];
    while (!finished && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    if (!finished) {
        [controller cancel];
        deadline = [NSDate dateWithTimeIntervalSinceNow:2];
        while (!finished && deadline.timeIntervalSinceNow > 0)
            [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
        throw std::runtime_error("source did not finish within five seconds");
    }
    check(!controller.running, "running cleared before completion");
    return outcome;
}

void expectOutput(const Outcome& outcome, std::vector<std::string> expected, const char *message) {
    check(outcome.succeeded && outcome.output == expected, message);
}

void expectFailure(const Outcome& outcome, const char *location, const char *detail) {
    check(!outcome.succeeded, "invalid input must fail");
    check(outcome.message.find(location) != std::string::npos, "error retains the input line number");
    check(outcome.message.find(detail) != std::string::npos, "error retains its cause");
}
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        try {
            check(argc == 2, "pass MitakaScript helper path");
            ScriptController *controller = [[ScriptController alloc]
                initWithHelperURL:[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]]];
            __block ScriptSnapshot state;
            __block int applied = 0;
            controller.snapshot = ^{
                check(NSThread.isMainThread, "snapshot uses the main thread");
                return state;
            };
            controller.applyAction = ^BOOL(const ScriptAction& action, NSString **error) {
                check(NSThread.isMainThread, "host action uses the main thread");
                if (action.kind != ScriptActionKind::set_constellation_lines) {
                    *error = @"Unsupported test host action";
                    return NO;
                }
                ++applied;
                state.constellation_lines = action.enabled;
                return YES;
            };

            expectOutput(run(controller, @"6 * 7"), {"=> 42"}, "arithmetic expression result");
            expectOutput(run(controller, @"nil, true, false, '日本語'"), {"=> nil\ttrue\tfalse\t日本語"},
                         "multiple expression values preserve nil and UTF-8");
            expectOutput(run(controller, @"local value = 21\nreturn value * 2, nil, 'done'"),
                         {"=> 42\tnil\tdone"}, "statement returns multiple values");
            expectOutput(run(controller, @"local value = 21\nvalue = value * 2"), {},
                         "statement without return does not invent a result");
            expectOutput(run(controller, @"print('hello', 2, true, nil)"),
                         {"hello\t2.000000\ttrue\tnil"}, "existing print formatting is unchanged");
            expectOutput(run(controller, @"print('before'); return 42"), {"before", "=> 42"},
                         "print and results remain ordered");
            expectOutput(run(controller, @"(function() print('once'); return 9 end)()"), {"once", "=> 9"},
                         "expression probing does not execute input twice");
            expectOutput(run(controller, @"print = function() error('replaced print') end; return 8"),
                         {"=> 8"}, "result reporting is independent from an overwritten print");
            expectOutput(run(controller, @"setmetatable({}, {__tostring = function() return 'custom' end})"),
                         {"=> custom"}, "result honors Lua tostring semantics");
            Outcome outcome = run(controller, @"string.rep('x', 10000)");
            check(outcome.succeeded && outcome.output.size() == 1 &&
                  outcome.output[0] == "=> " + std::string(8189, 'x') + "... [truncated]",
                  "large results are bounded with an explicit truncation marker");
            outcome = run(controller, @"string.rep('あ', 3000)");
            check(outcome.succeeded && outcome.output.size() == 1, "large UTF-8 result succeeds");
            NSString *unicodeOutput = [NSString stringWithUTF8String:outcome.output[0].c_str()];
            check(unicodeOutput != nil && [unicodeOutput hasPrefix:@"=> あ"] &&
                  [unicodeOutput hasSuffix:@"あ... [truncated]"] && outcome.output[0].size() <= 8207,
                  "truncation retains valid UTF-8 instead of splitting a character");

            expectOutput(run(controller, @"Constels.lines = true"), {}, "statement reaches existing host API");
            check(state.constellation_lines && applied == 1, "host action applied once");
            expectOutput(run(controller, @"Constels.lines"), {"=> true"}, "new input reads current host state");
            expectOutput(run(controller, @"console_global = 7"), {}, "global assignment is a valid statement");
            expectOutput(run(controller, @"console_global"), {"=> nil"}, "each input gets a fresh Lua state");

            expectFailure(run(controller, @"local valid = 1\nlocal broken = )"), "console.lua:2:", "unexpected");
            expectOutput(run(controller, @"40 + 2"), {"=> 42"}, "continue after syntax failure");
            expectFailure(run(controller, @"local function fail()\n  local value = 1\n  error('console failure')\nend\nfail()"),
                          "console.lua:3:", "console failure");
            expectOutput(run(controller, @"'recovered'"), {"=> recovered"}, "continue after runtime failure");
            expectFailure(run(controller, @"setmetatable({}, {__tostring = function() error('format failure') end})"),
                          "console.lua:1:", "format failure");
            expectOutput(run(controller, @"42"), {"=> 42"}, "continue after result formatting failure");
            outcome = run(controller, @"error({detail = 'non-string'})");
            check(!outcome.succeeded, "non-string Lua errors do not terminate the controller");
            expectOutput(run(controller, @"42"), {"=> 42"}, "continue after non-string error");
            outcome = run(controller, @"while true do end");
            check(!outcome.succeeded && outcome.message.find("budget") != std::string::npos,
                  "instruction budget still stops infinite console input");
            outcome = run(controller, @"string.rep('x', 100000000)");
            check(!outcome.succeeded, "allocation budget still rejects oversized Lua allocations");
            expectOutput(run(controller, @"42"), {"=> 42"}, "continue after execution budget failures");

            outcome = run(controller, @"waitTime(30)", true);
            check(!outcome.succeeded && outcome.message.find("停止") != std::string::npos,
                  "cancel interrupts a blocking Lua wait");
            expectOutput(run(controller, @"print('after cancel')"), {"after cancel"},
                         "next input works after cancellation");
            outcome = run(controller, @"os.execute('sleep 30')", true);
            check(!outcome.succeeded && outcome.message.find("停止") != std::string::npos,
                  "cancel still interrupts blocking external commands");
            outcome = run(controller, @"os.exit(0)");
            check(!outcome.succeeded, "os.exit only terminates the current helper");
            expectOutput(run(controller, @"42"), {"=> 42"}, "continue after helper exit");

            expectOutput(run(controller, @"print('legacy'); return 42", false, false), {"legacy"},
                         "existing runSource still executes statements and discards returns");
            outcome = run(controller, @"6 * 7", false, false);
            check(!outcome.succeeded && outcome.message.find("html-link.lua:1:") != std::string::npos,
                  "expression fallback is limited to console input");
            expectOutput(run(controller, @"42"), {"=> 42"}, "console still works after legacy source failure");

            NSError *error = nil;
            check(![controller runConsoleSource:@"" error:&error] && error != nil, "reject empty source");
            NSString *oversized = [@"x" stringByPaddingToLength:1024 * 1024 + 1 withString:@"x" startingAtIndex:0];
            check(![controller runConsoleSource:oversized error:&error], "reject source above 1 MiB");
            check(!controller.running, "rejected source does not leave a running helper");
            expectOutput(run(controller, @"42"), {"=> 42"}, "continue after rejected source");
            [controller invalidate];
            check(![controller runConsoleSource:@"42" error:&error], "invalidated controller rejects console input");
            std::puts("Script console execution tests passed");
            return 0;
        } catch (const std::exception& error) {
            std::fprintf(stderr, "Script console execution tests failed: %s\n", error.what());
            return 1;
        }
    }
}
