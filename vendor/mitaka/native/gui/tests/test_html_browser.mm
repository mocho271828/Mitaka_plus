#import "HtmlBrowserController.h"
#import "ScriptController.h"
#include "html_bridge_policy.hpp"
#import <WebKit/WebKit.h>
#include <iostream>
#include <stdexcept>
#include <atomic>
#include <poll.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <thread>
#include <unistd.h>

namespace {
int checks = 0;
void check(bool value, const char *message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
void wait_for(bool (^done)(void)) {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:15];
    while (!done() && deadline.timeIntervalSinceNow > 0) {
        NSEvent *event = [NSApp nextEventMatchingMask:NSEventMaskAny untilDate:[NSDate dateWithTimeIntervalSinceNow:0.01] inMode:NSDefaultRunLoopMode dequeue:YES];
        if (event) [NSApp sendEvent:event];
        [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
    check(done(), "WebKit operation timed out");
}
id evaluate(WKWebView *view, WKContentWorld *world, NSString *source) {
    __block bool done = false;
    __block id result;
    __block NSError *failure;
    [view evaluateJavaScript:source inFrame:nil inContentWorld:world completionHandler:^(id value, NSError *error) {
        result = value; failure = error; done = true;
    }];
    wait_for(^bool { return done; });
    if (failure) std::cerr << failure.description.UTF8String << '\n';
    check(!failure, "app evaluation failed");
    return result;
}
class LocalServer {
public:
    LocalServer() {
        socket_ = socket(AF_INET, SOCK_STREAM, 0);
        check(socket_ >= 0, "loopback socket failed");
        sockaddr_in address{};
        address.sin_family = AF_INET;
        address.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        check(bind(socket_, reinterpret_cast<sockaddr *>(&address), sizeof(address)) == 0, "loopback bind failed");
        socklen_t length = sizeof(address);
        check(getsockname(socket_, reinterpret_cast<sockaddr *>(&address), &length) == 0 && listen(socket_, 8) == 0, "loopback listen failed");
        port = ntohs(address.sin_port);
        worker_ = std::thread([this] {
            while (!stopping_) {
                pollfd pending{socket_, POLLIN, 0};
                if (poll(&pending, 1, 100) <= 0) continue;
                const int client = accept(socket_, nullptr, nullptr);
                if (client < 0) continue;
                ++requests;
                pollfd ready{client, POLLIN, 0};
                if (poll(&ready, 1, 100) > 0) {
                    char request[2048]{};
                    const auto received = recv(client, request, sizeof(request) - 1, MSG_DONTWAIT);
                    if (received > 0) std::cerr << "loopback request: " << request << "\n";
                }
                int enabled = 1;
                setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &enabled, sizeof(enabled));
                const char reply[] = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nContent-Type: text/css\r\nCache-Control: no-store\r\nConnection: close\r\n\r\n";
                send(client, reply, sizeof(reply) - 1, 0);
                close(client);
            }
        });
    }
    ~LocalServer() { stopping_ = true; worker_.join(); close(socket_); }
    unsigned short port = 0;
    std::atomic<unsigned> requests{0};
private:
    int socket_ = -1;
    std::atomic<bool> stopping_{false};
    std::thread worker_;
};
void click(NSWindow *window, WKWebView *view, double x, double y) {
    const NSPoint point = [view convertPoint:NSMakePoint(x, view.isFlipped ? y : view.bounds.size.height - y) toView:nil];
    for (NSEventType type : {NSEventTypeLeftMouseDown, NSEventTypeLeftMouseUp}) {
        NSEvent *event = [NSEvent mouseEventWithType:type location:point modifierFlags:0 timestamp:NSProcessInfo.processInfo.systemUptime windowNumber:window.windowNumber context:nil eventNumber:0 clickCount:1 pressure:1];
        [window sendEvent:event];
    }
}
}

namespace {
WKWebView *browser_view(HtmlBrowserController *browser) {
    return [browser valueForKey:@"webView"];
}
void open_page(HtmlBrowserController *browser, NSURL *url) {
    NSError *error = nil;
    check([browser openTrustedFileURL:url error:&error], error ? error.localizedDescription.UTF8String : "open local HTML");
    wait_for(^bool { return browser.trusted; });
}
void click_link(HtmlBrowserController *browser, NSString *identifier) {
    WKWebView *view = browser_view(browser);
    NSArray<NSNumber *> *point = evaluate(view, [WKContentWorld worldWithName:@"MitakaTrustedLocalHTML"],
        [NSString stringWithFormat:@"(()=>{const r=document.getElementById('%@').getBoundingClientRect();return [r.x+15,r.y+15]})()", identifier]);
    click(browser.window, view, point[0].doubleValue, point[1].doubleValue);
}
void drain() {
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:0.25];
    while (deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
}
}
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSURL *root = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[@"mitaka-browser-" stringByAppendingString:NSUUID.UUID.UUIDString]] isDirectory:YES];
        HtmlBrowserController *browser;
        int status = 1;
        @try {
            try {
                check(argc == 2, "pass MitakaScript helper path");
                [NSApplication sharedApplication];
                [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
                [NSApp finishLaunching];
                [NSApp activateIgnoringOtherApps:YES];
                check([NSFileManager.defaultManager createDirectoryAtURL:root withIntermediateDirectories:YES attributes:nil error:nil], "temporary directory failed");
                LocalServer server;
                NSString *remote = [NSString stringWithFormat:@"http://127.0.0.1:%hu", server.port];
                NSString *html = [NSString stringWithFormat:@"<!doctype html><meta charset='utf-8'><link rel='stylesheet' href='local.css'><link rel='stylesheet' href='%@/remote.css'><style>a{display:block;height:40px}</style><script>document.documentElement.dataset.executed='yes'</script><a id='raw' href=\"mtkp://Camera.target = 'Planet.Earth';\">raw</a><a id='encoded' href=\"mtkp://print('a%%25b+c')\">encoded</a><a id='blank' target='_blank' href=\"mtkp://print('wrong frame')\">blank</a><a id='online' href='%@/page.html'>online</a><img src='%@/remote.png'><iframe src='frame.html'></iframe><iframe src='%@/frame.html'></iframe>", remote, remote, remote, remote];
                NSString *css = [NSString stringWithFormat:@"@import url('%@/import.css');body{font-size:23px;background-image:url('%@/bg.png')}", remote, remote];
                NSURL *page = [root URLByAppendingPathComponent:@"index.html"];
                check([[html dataUsingEncoding:NSUTF8StringEncoding] writeToURL:page atomically:YES], "HTML fixture failed");
                check([[css dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[root URLByAppendingPathComponent:@"local.css"] atomically:YES], "CSS fixture failed");
                check([[@"<a href=\"mtkp://print('frame')\">frame link</a>" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[root URLByAppendingPathComponent:@"frame.html"] atomically:YES], "frame fixture failed");
                browser = [HtmlBrowserController new];
                [browser showWindow:nil];
                __block NSMutableArray<NSString *> *sources = [NSMutableArray array];
                __block NSURL *receivedFile = nil;
                __block bool refuse = false;
                browser.scriptRequested = ^BOOL(NSString *source, NSURL *file, NSString **error) {
                    if (refuse) { *error = @"Host is busy"; return NO; }
                    [sources addObject:source]; receivedFile = file; return YES;
                };
                open_page(browser, page);
                WKWebView *view = browser_view(browser);
                WKContentWorld *world = [WKContentWorld worldWithName:@"MitakaTrustedLocalHTML"];
                check([evaluate(view, world, @"getComputedStyle(document.body).fontSize") isEqual:@"23px"], "local CSS missing");
                check([evaluate(view, WKContentWorld.pageWorld, @"document.documentElement.dataset.executed||'no'") isEqual:@"no"], "page JS executed");
                check([evaluate(view, WKContentWorld.pageWorld, @"typeof window.webkit?.messageHandlers?.mitakaLocalLink") isEqual:@"undefined"], "handler leaked to page world");
                check([evaluate(view, world, @"document.querySelector('iframe').contentDocument?.body?.textContent||''") isEqual:@""], "local frame loaded");
                check(server.requests == 0, "network asset escaped blocking");
                evaluate(view, world, @"document.getElementById('raw').click(); 'synthetic'");
                drain();
                check(sources.count == 0 && browser.trusted, "synthetic click executed or altered trust");
                click_link(browser, @"raw");
                wait_for(^bool { return sources.count == 1; });
                check([sources.lastObject isEqual:@"Camera.target = 'Planet.Earth';"] && [receivedFile.path isEqual:[NSString stringWithUTF8String:mitaka::gui::inspect_html_document(page).canonical_path.c_str()]], "raw source or file changed");
                click_link(browser, @"encoded");
                wait_for(^bool { return sources.count == 2; });
                check([sources.lastObject isEqual:@"print('a%b+c')"], "single decode or plus preservation failed");
                click_link(browser, @"blank"); drain();
                check(sources.count == 2, "non-main target executed");
                refuse = true;
                click_link(browser, @"raw"); drain();
                check(sources.count == 2 && browser.trusted, "host refusal changed source count or trust");
                refuse = false;
                check([[html stringByAppendingString:@"<!-- changed -->"] writeToURL:page atomically:YES encoding:NSUTF8StringEncoding error:nil], "mutated fixture failed");
                click_link(browser, @"raw");
                wait_for(^bool { return !browser.trusted; });
                check(sources.count == 2, "changed disk content executed");
                open_page(browser, page);
                click_link(browser, @"online");
                wait_for(^bool { return !browser.trusted; });
                check(server.requests == 0, "online navigation reached network");
                click_link(browser, @"raw"); drain();
                check(sources.count == 2 && !browser.trusted, "cancelled navigation retained authority");
                open_page(browser, page);
                [browser close];
                check(!browser.trusted && !browser_view(browser), "close retained authority or view");
                [browser showWindow:nil];
                NSURL *japanese = [root URLByAppendingPathComponent:@"shiftjis.html"];
                NSString *jp = @"<meta charset='Shift_JIS'><a id='raw' href=\"mtkp://print('日本語')\">日本語</a>";
                check([[jp dataUsingEncoding:NSShiftJISStringEncoding] writeToURL:japanese atomically:YES], "Shift_JIS fixture failed");
                open_page(browser, japanese);
                click_link(browser, @"raw");
                wait_for(^bool { return sources.count == 3; });
                check([sources.lastObject isEqual:@"print('日本語')"], "Shift_JIS source not preserved");
                NSError *error = nil;
                check(![browser openTrustedFileURL:[NSURL URLWithString:@"https://example.invalid/index.html"] error:&error] && !browser.trusted && error, "online trust accepted");
                ScriptController *scripts = [[ScriptController alloc] initWithHelperURL:[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]]];
                scripts.workingDirectoryURL = root;
                __block mitaka::gui::ScriptSnapshot state;
                __block bool completed = false, succeeded = false;
                __block NSString *output;
                scripts.snapshot = ^{ return state; };
                scripts.applyAction = ^BOOL(const mitaka::gui::ScriptAction& action, NSString **failure) {
                    if (action.kind != mitaka::gui::ScriptActionKind::set_stars_visible) {
                        *failure = @"Unsupported test host action"; return NO;
                    }
                    state.stars.visible = action.enabled;
                    return YES;
                };
                scripts.output = ^(NSString *text) { output = text; };
                scripts.completion = ^(BOOL success, NSString *) { succeeded = success; completed = true; };
                browser.scriptRequested = ^BOOL(NSString *source, NSURL *, NSString **failure) {
                    NSError *launchError = nil;
                    const BOOL started = [scripts runSource:source error:&launchError];
                    if (!started) *failure = launchError.localizedDescription;
                    return started;
                };
                NSURL *integration = [root URLByAppendingPathComponent:@"helper.html"];
                NSString *link = @"<a id='raw' href=\"mtkp://Stars.visible=false; assert(not Stars.visible); print('HTML helper')\">run</a>";
                check([link writeToURL:integration atomically:YES encoding:NSUTF8StringEncoding error:nil], "helper fixture failed");
                open_page(browser, integration);
                click_link(browser, @"raw");
                wait_for(^bool { return completed; });
                check(succeeded && !state.stars.visible && [output isEqual:@"HTML helper"], "HTML click did not complete through Lua helper");
                [scripts invalidate];
                check(server.requests == 0, "network requests leaked during trusted test");
                std::cout << "HTML browser tests: " << checks << " checks passed\n";
                status = 0;
            } catch (const std::exception& error) {
                std::cerr << "HTML browser after " << checks << " checks: " << error.what() << '\n';
            }
        } @catch (NSException *exception) {
            std::cerr << "HTML browser exception: " << exception.description.UTF8String << '\n';
        }
        [browser close];
        [NSFileManager.defaultManager removeItemAtURL:root error:nil];
        return status;
    }
}
