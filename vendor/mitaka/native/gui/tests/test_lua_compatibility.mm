#import <Foundation/Foundation.h>
#import "ScriptController.h"
#include <cstdio>
#include <stdexcept>
#include <string>

using namespace mitaka::gui;
namespace {
int checks = 0;
void check(bool condition, const char *message) {
    ++checks;
    if (!condition) throw std::runtime_error(message);
}

struct FixtureDirectory {
    NSURL *url;
    FixtureDirectory() {
        url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:
            [@"mitaka-lua-compatibility-" stringByAppendingString:NSUUID.UUID.UUIDString]] isDirectory:YES];
        check([NSFileManager.defaultManager createDirectoryAtURL:url withIntermediateDirectories:NO
            attributes:@{NSFilePosixPermissions:@0700} error:nil], "create isolated compatibility fixtures");
    }
    ~FixtureDirectory() { [NSFileManager.defaultManager removeItemAtURL:url error:nil]; }
    void write(NSString *name, NSString *source) const {
        check([source writeToURL:[url URLByAppendingPathComponent:name] atomically:YES
            encoding:NSUTF8StringEncoding error:nil], "write generated fixture");
    }
};

struct Outcome { BOOL succeeded = NO; NSString *message = nil; NSArray<NSString *> *output = nil; };
Outcome run(ScriptController *controller, NSString *source, bool cancel = false) {
    __block BOOL finished = NO;
    __block Outcome outcome;
    NSMutableArray<NSString *> *output = [NSMutableArray array];
    controller.output = ^(NSString *text) { [output addObject:text]; };
    controller.completion = ^(BOOL succeeded, NSString *message) {
        check(NSThread.isMainThread, "completion remains on main thread");
        outcome = {succeeded, message, [output copy]};
        finished = YES;
    };
    NSError *error = nil;
    check([controller runSource:source error:&error], error ? error.localizedDescription.UTF8String : "launch source");
    if (cancel) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [controller cancel]; });
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:8];
    while (!finished && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    const bool timedOut = !finished;
    if (timedOut) {
        [controller cancel];
        deadline = [NSDate dateWithTimeIntervalSinceNow:2];
        while (!finished && deadline.timeIntervalSinceNow > 0)
            [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    }
    check(!timedOut && finished && !controller.running, "source finishes within deadline without blocking the host");
    return outcome;
}

void expectSuccess(ScriptController *controller, const char *name, const char *source) {
    NSString *body = [[NSString stringWithUTF8String:source] stringByAppendingString:@"\nprint('compatibility-ok')"];
    const auto outcome = run(controller, body);
    if (!outcome.succeeded) throw std::runtime_error(std::string(name) + ": " + outcome.message.UTF8String);
    check([outcome.output isEqualToArray:@[@"compatibility-ok"]], "fixture completes all assertions exactly once");
    std::printf("PASS %s\n", name);
}

NSString *luaString(NSString *value) {
    // パスをソースへ埋め込む際は、引用符・改行・非 ASCII をすべて固定長の byte escape にする。
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    check(data != nil, "path is UTF-8 encodable");
    std::string result = "\"";
    const auto *bytes = static_cast<const unsigned char *>(data.bytes);
    for (NSUInteger index = 0; index < data.length; ++index) {
        char escaped[5];
        std::snprintf(escaped, sizeof(escaped), "\\%03u", bytes[index]);
        result += escaped;
    }
    result += '"';
    return [NSString stringWithUTF8String:result.c_str()];
}

void compileBundledScripts(ScriptController *controller, NSURL *root) {
    NSSet<NSString *> *expectedFiles = [NSSet setWithArray:@[
        @"gui.lua", @"gui_jp.lua", @"init.lua", @"layouts.lua", @"layouts_jp.lua", @"option.lua",
        @"quadraopt.lua", @"screenmenu.lua", @"screenmenu_jp.lua", @"shortcuts.lua", @"shortcuts_jp.lua", @"tutorial.lua"]];
    NSMutableSet<NSString *> *auditedFiles = [NSMutableSet set];
    NSDictionary<NSString *, NSNumber *> *expectedFailures = @{
        @"gui_jp.lua":@21, @"screenmenu_jp.lua":@7, @"shortcuts_jp.lua":@57};
    NSError *error = nil;
    NSArray<NSURL *> *files = [NSFileManager.defaultManager contentsOfDirectoryAtURL:root
        includingPropertiesForKeys:@[NSURLIsRegularFileKey] options:0 error:&error];
    check(files != nil, error ? error.localizedDescription.UTF8String : "list bundled scripts");
    files = [files sortedArrayUsingComparator:^NSComparisonResult(NSURL *left, NSURL *right) {
        return [left.lastPathComponent compare:right.lastPathComponent];
    }];
    NSUInteger compiled = 0, rejected = 0;
    for (NSURL *file in files) {
        if (![file.pathExtension isEqualToString:@"lua"]) continue;
        [auditedFiles addObject:file.lastPathComponent];
        NSNumber *regular = nil;
        check([file getResourceValue:&regular forKey:NSURLIsRegularFileKey error:nil] && regular.boolValue,
              "bundled Lua input is a regular file");
        NSData *before = [NSData dataWithContentsOfURL:file options:0 error:nil];
        check(before != nil, "read original bytes before compilation");
        // loadfile はコンパイルだけ。返された関数・init.lua・文字列内のコールバックは呼び出さない。
        NSString *source = [NSString stringWithFormat:
            @"local chunk, failure = loadfile(%@, 't', {})\n"
             "if chunk then assert(type(chunk) == 'function'); print('compiled-only')\n"
             "else print('compile-error:' .. string.gsub(failure, '[^ -~]', function(byte) "
             "return string.format('\\\\x%%02X', string.byte(byte)) end)) end",
            luaString(file.path)];
        const auto outcome = run(controller, source);
        if (!outcome.succeeded)
            throw std::runtime_error(std::string(file.lastPathComponent.UTF8String) + ": " + outcome.message.UTF8String);
        check(outcome.output.count == 1, "compiler reports exactly one result without running original source");
        check([before isEqualToData:[NSData dataWithContentsOfURL:file options:0 error:nil]], "original bytes remain unchanged");
        if ([outcome.output.firstObject isEqualToString:@"compiled-only"]) {
            check(expectedFailures[file.lastPathComponent] == nil, "known rejected source requires an explicit audit update");
            ++compiled;
            std::printf("COMPILE-ONLY %s (%lu bytes)\n", file.lastPathComponent.UTF8String, before.length);
        } else {
            check([outcome.output.firstObject hasPrefix:@"compile-error:"], "compiler failure is explicitly classified");
            NSNumber *line = expectedFailures[file.lastPathComponent];
            NSString *location = [NSString stringWithFormat:@"%@:%@:", file.lastPathComponent, line];
            check(line != nil && [outcome.output.firstObject containsString:location] &&
                  [outcome.output.firstObject containsString:@"invalid escape sequence"],
                  "only documented original-byte incompatibilities are expected");
            ++rejected;
            std::printf("COMPILE-REJECTED %s: %s\n", file.lastPathComponent.UTF8String, outcome.output.firstObject.UTF8String);
        }
    }
    check(compiled > 0, "bundled script directory is not empty");
    check([auditedFiles isEqualToSet:expectedFiles], "all twelve expected original scripts are present and audited");
    check(rejected == expectedFailures.count, "every known incompatible original was audited");
    std::printf("Bundled Lua compile-only: %lu accepted, %lu rejected\n", compiled, rejected);
}
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        try {
            check(argc == 3, "pass helper and absolute bundled scripts directory");
            FixtureDirectory fixtures;
            fixtures.write(@"audit_module.lua", @"return {value = 21}");
            fixtures.write(@"audit_chunk.lua", @"return 6 * 7");
            fixtures.write(@"compile_only.lua", @"error('COMPILE_ONLY_SOURCE_MUST_NOT_RUN')");
            ScriptController *controller = [[ScriptController alloc] initWithHelperURL:
                [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]]];
            controller.workingDirectoryURL = fixtures.url;
            controller.snapshot = ^{ return ScriptSnapshot{}; };
            controller.applyAction = ^BOOL(const ScriptAction&, NSString **error) {
                if (error) *error = @"Compatibility audit does not apply host actions";
                return NO;
            };
            expectSuccess(controller, "standard control flow, closures and varargs", R"lua(
                assert(_VERSION == 'Lua 5.4')
                assert(type(nil) == 'nil' and type(false) == 'boolean' and not false and not nil)
                assert(0 and '' and tonumber('42') == 42 and tostring(true) == 'true')
                local sum = 0
                for index = 1, 4 do sum = sum + index end
                for _, value in ipairs({4, 5}) do if value == 5 then break end; sum = sum + value end
                if sum == 14 then sum = 10 else error('control flow') end
                while sum < 12 do sum = sum + 1 end
                repeat sum = sum - 1 until sum == 10
                local function counter(value) return function() value = value + 1; return value end end
                local count = counter(sum)
                assert(count() == 11 and count() == 12)
                local function values(...) assert(select('#', ...) == 3); return ... end
                local first, second, third = values(1, nil, 3)
                assert(first == 1 and second == nil and third == 3)
            )lua");
            expectSuccess(controller, "string, table, utf8 and numeric libraries", R"lua(
                assert(string.sub('abcdef', 2, 4) == 'bcd' and string.match('x42', '%d+') == '42')
                assert(string.gsub('a,b', ',', ':') == 'a:b' and string.format('%04d', 42) == '0042')
                local values = {3, 1}; table.insert(values, 2); table.sort(values)
                assert(table.concat(values, ',') == '1,2,3' and table.remove(values) == 3)
                local packed = table.pack(1, nil, 3)
                assert(packed.n == 3 and select('#', table.unpack(packed, 1, packed.n)) == 3)
                local copied = {}; table.move(values, 1, 2, 1, copied); assert(copied[2] == 2)
                assert(utf8.len('日本語') == 3 and #'日本語' == 9)
                assert(string.unpack('>I2', string.pack('>I2', 513)) == 513)
                assert(math.floor(-1.2) == -2 and math.abs(math.sin(math.pi / 2) - 1) < 1e-12)
                assert(math.type(3) == 'integer' and math.type(3.0) == 'float')
                assert(7 // 2 == 3 and (5 & 3) == 1 and (1 << 3) == 8)
            )lua");
            expectSuccess(controller, "protected errors, metatables and coroutines", R"lua(
                local value = setmetatable({}, {__index = function(_, key) return key .. '-value' end})
                assert(value.test == 'test-value' and rawget(value, 'test') == nil)
                rawset(value, 'test', 7); assert(value.test == 7)
                local ok, failure = pcall(function() error('expected failure') end)
                assert(not ok and failure:find('expected failure', 1, true))
                ok, failure = xpcall(function() error('trace failure') end, debug.traceback)
                assert(not ok and failure:find('stack traceback', 1, true))
                local thread, isMain = coroutine.running(); assert(type(thread) == 'thread' and isMain)
                local worker = coroutine.create(function(value) coroutine.yield(value + 1); return value + 2 end)
                local resumed, result = coroutine.resume(worker, 40); assert(resumed and result == 41)
                resumed, result = coroutine.resume(worker); assert(resumed and result == 42)
                assert(coroutine.status(worker) == 'dead' and coroutine.close(worker))
            )lua");
            expectSuccess(controller, "load environment, compile-only and 5.4 syntax", R"lua(
                local chunk = assert(load('return value + 1', '@generated.lua', 't', {value = 41}))
                assert(chunk() == 42 and rawget(_G, 'value') == nil)
                local pending = assert(loadfile('compile_only.lua', 't', {}))
                assert(type(pending) == 'function')
                local value <const> = 7
                assert(not load('local value <const> = 7; value = 8', '@const.lua', 't'))
                local closed = false
                do local resource <close> = setmetatable({}, {__close = function() closed = true end}) end
                assert(closed and value == 7)
            )lua");
            expectSuccess(controller, "Lua 5.1 API differences are explicit", R"lua(
                for _, name in ipairs({'setfenv', 'getfenv', 'module', 'unpack', 'loadstring'}) do
                    assert(rawget(_G, name) == nil, name)
                end
                assert(table.maxn == nil and package.loaders == nil and math.mod == nil and string.gfind == nil)
                assert(type(table.unpack) == 'function' and type(package.searchers) == 'table')
                assert(type(load) == 'function' and type(_ENV) == 'table')
                assert(not pcall(function() return setfenv(function() end, {}) end))
                local _, at = string.find('abc', 'b'); assert(at == 2)
            )lua");
            expectSuccess(controller, "local io, dofile, require and os contracts", R"lua(
                assert(dofile('audit_chunk.lua') == 42)
                package.path = './?.lua'; package.cpath = ''
                local first = require('audit_module'); local second = require('audit_module')
                assert(first.value == 21 and rawequal(first, second))
                local file = assert(io.open('generated.txt', 'wb')); assert(file:write('one\ntwo')); assert(file:close())
                file = assert(io.open('generated.txt', 'rb')); assert(file:read('*a') == 'one\ntwo'); assert(file:close())
                assert(os.remove('generated.txt'))
                assert(os.date('!%Y-%m-%d', 0) == '1970-01-01' and type(os.clock()) == 'number')
                local ok, kind, status = os.execute('exit 0'); assert(ok and kind == 'exit' and status == 0)
                ok, kind, status = os.execute('exit 7'); assert(ok == nil and kind == 'exit' and status == 7)
            )lua");
            expectSuccess(controller, "host API gaps are separate from language compatibility", R"lua(
                assert(type(io.open) == 'function' and type(os.execute) == 'function')
                assert(type(package.loadlib) == 'function' and type(debug.getinfo) == 'function')
                assert(type(waitTime) == 'function' and type(print) == 'function')
                assert(rawget(_G, 'ScreenMenu') == nil and rawget(_G, 'Input') == nil and rawget(_G, 'State') == nil)
                assert(mtk.LANGUAGE == nil)
                local ok, failure = pcall(function() return GUI.addMenu end)
                assert(not ok and failure:find('Unsupported', 1, true) and failure:find('addMenu', 1, true))
            )lua");
            compileBundledScripts(controller, [NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[2]] isDirectory:YES]);
            auto outcome = run(controller, @"local value = )");
            check(!outcome.succeeded && [outcome.message containsString:@"html-link.lua:1:"], "syntax failure has source location");
            outcome = run(controller, @"error('runtime failure')");
            check(!outcome.succeeded && [outcome.message containsString:@"runtime failure"], "runtime failure is reported");
            outcome = run(controller, @"while true do end");
            check(!outcome.succeeded && [outcome.message containsString:@"budget"], "instruction budget remains active");
            outcome = run(controller, @"waitTime(30)", true);
            check(!outcome.succeeded && [outcome.message containsString:@"停止"], "cancellation remains active");
            expectSuccess(controller, "continue after failures and cancellation", "assert(6 * 7 == 42)");
            [controller invalidate];
            std::printf("Lua compatibility: %d checks passed; original scripts were not executed\n", checks);
        } catch (const std::exception& failure) {
            std::fprintf(stderr, "Lua compatibility test failed: %s\n", failure.what());
            return 1;
        }
    }
    return 0;
}
