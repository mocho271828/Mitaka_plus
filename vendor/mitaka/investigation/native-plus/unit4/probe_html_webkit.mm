#import <AppKit/AppKit.h>
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

@interface Probe : NSObject <WKNavigationDelegate, WKScriptMessageHandler>
@property BOOL finished;
@property NSUInteger blockedFrames;
@property(strong) NSMutableArray<WKScriptMessage *> *messages;
@end
@implementation Probe
- (instancetype)init { if ((self = [super init])) _messages = [NSMutableArray array]; return self; }
- (void)webView:(WKWebView *)view didFinishNavigation:(WKNavigation *)navigation {
    (void)view; (void)navigation; self.finished = YES;
}
- (void)webView:(WKWebView *)view didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    (void)view; (void)navigation; std::cerr << "load failed: " << error.description.UTF8String << '\n';
}
- (void)webView:(WKWebView *)view decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    (void)view;
    if (!action.targetFrame.isMainFrame) { self.blockedFrames += 1; handler(WKNavigationActionPolicyCancel); return; }
    handler(WKNavigationActionPolicyAllow);
}
- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message {
    (void)controller; [self.messages addObject:message];
}
@end

int main() {
    @autoreleasepool {
        NSURL *root = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[@"mitaka-webkit-" stringByAppendingString:NSUUID.UUID.UUIDString]] isDirectory:YES];
        NSWindow *window;
        WKWebView *view;
        int status = 1;
        @try {
            try {
                [NSApplication sharedApplication];
                [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
                [NSApp finishLaunching];
                [NSApp activateIgnoringOtherApps:YES];
                check([NSFileManager.defaultManager createDirectoryAtURL:root withIntermediateDirectories:YES attributes:nil error:nil], "temporary directory failed");
                NSURL *rulesURL = [root URLByAppendingPathComponent:@"rules" isDirectory:YES];
                check([NSFileManager.defaultManager createDirectoryAtURL:rulesURL withIntermediateDirectories:YES attributes:nil error:nil], "rule directory failed");
                WKContentRuleListStore *store = [WKContentRuleListStore storeWithURL:rulesURL];
                __block WKContentRuleList *rules;
                __block NSError *ruleError;
                __block bool compiled = false;
                [store compileContentRuleListForIdentifier:@"local-only-probe" encodedContentRuleList:@"[{\"trigger\":{\"url-filter\":\".*\"},\"action\":{\"type\":\"block\"}},{\"trigger\":{\"url-filter\":\"^file:///\"},\"action\":{\"type\":\"ignore-previous-rules\"}}]" completionHandler:^(WKContentRuleList *value, NSError *error) {
                    rules = value; ruleError = error; compiled = true;
                }];
                wait_for(^bool { return compiled; });
                check(rules && !ruleError, "content rule compilation failed");
                WKContentWorld *world = [WKContentWorld worldWithName:@"MitakaLocalHtmlProbe"];
                Probe *probe = [Probe new];
                WKWebViewConfiguration *config = [WKWebViewConfiguration new];
                config.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
                config.defaultWebpagePreferences.allowsContentJavaScript = NO;
                [config.userContentController addContentRuleList:rules];
                [config.userContentController addScriptMessageHandler:probe contentWorld:world name:@"rawHref"];
                NSString *source = @"document.addEventListener('click',event=>{const a=event.target.closest('a');if(!a)return;const href=a.getAttribute('href');if(!href||!/^mtkp:/i.test(href))return;event.preventDefault();window.webkit.messageHandlers.rawHref.postMessage({href:href,trusted:event.isTrusted});},true);";
                [config.userContentController addUserScript:[[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES inContentWorld:world]];
                view = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 700, 400) configuration:config];
                view.navigationDelegate = probe;
                window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 700, 400) styleMask:NSWindowStyleMaskTitled backing:NSBackingStoreBuffered defer:NO];
                window.releasedWhenClosed = NO;
                window.title = @"Mitaka HTML boundary probe";
                window.contentView = view;
                [window makeKeyAndOrderFront:nil];
                NSArray<NSString *> *payloads = @[@"mtkp://Camera.zoom = 0.001; Stars.visible=true;", @"mtkp://Time:setTime(2009,7,22,0,30,0);Time.speed=0;", @"mtkp://Camera:toggleModeTo();", @"mtkp://Camera.target = 'Planet.Earth';", @"mtkp://dofile('ui/scripts/eclipse_20090722.lua');"];
                NSMutableString *html = [NSMutableString stringWithString:@"<!doctype html><meta charset='utf-8'><style>a{display:block;height:40px}</style><script>document.documentElement.dataset.executed='yes'</script>"];
                for (NSUInteger i = 0; i < payloads.count; ++i)
                    [html appendFormat:@"<a id='a%lu' href=\"%@\">link %lu</a>", static_cast<unsigned long>(i), payloads[i], static_cast<unsigned long>(i)];
                [html appendString:@"<iframe src='frame.html'></iframe><iframe src='https://example.invalid/frame'></iframe>"];
                NSURL *page = [root URLByAppendingPathComponent:@"index.html"];
                check([[html dataUsingEncoding:NSUTF8StringEncoding] writeToURL:page atomically:YES], "page fixture failed");
                check([[@"<script>parent.document.documentElement.dataset.frame='yes'</script>" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[root URLByAppendingPathComponent:@"frame.html"] atomically:YES], "frame fixture failed");
                [view loadFileURL:page allowingReadAccessToURL:root];
                wait_for(^bool { return probe.finished; });
                check([evaluate(view, WKContentWorld.pageWorld, @"document.documentElement.dataset.executed || 'no'") isEqual:@"no"], "page script executed");
                check([evaluate(view, WKContentWorld.pageWorld, @"typeof window.webkit?.messageHandlers?.rawHref") isEqual:@"undefined"], "isolated handler exposed to page world");
                check(probe.blockedFrames >= 1, "local iframe was not blocked");
                for (NSUInteger i = 0; i < payloads.count; ++i) {
                    NSString *selector = [NSString stringWithFormat:@"document.getElementById('a%lu')", static_cast<unsigned long>(i)];
                    NSArray<NSNumber *> *point = evaluate(view, world, [NSString stringWithFormat:@"(()=>{const r=%@.getBoundingClientRect();return [r.x+20,r.y+15]})()", selector]);
                    const NSUInteger before = probe.messages.count;
                    click(window, view, point[0].doubleValue, point[1].doubleValue);
                    wait_for(^bool { return probe.messages.count > before; });
                    WKScriptMessage *message = probe.messages.lastObject;
                    check(message.webView == view && message.frameInfo.isMainFrame && [message.world isEqual:world], "message origin metadata differs");
                    check([message.frameInfo.request.URL isEqual:page], "source URL differs");
                    check([message.body[@"href"] isEqual:payloads[i]], "raw original href changed");
                    check([message.body[@"trusted"] isEqual:@YES], "native click was not trusted");
                    std::cout << "raw href preserved: " << payloads[i].UTF8String << std::endl;
                }
                const NSUInteger before = probe.messages.count;
                evaluate(view, world, @"document.getElementById('a0').click(); 'clicked'");
                wait_for(^bool { return probe.messages.count > before; });
                check([probe.messages.lastObject.body[@"trusted"] isEqual:@NO], "synthetic click marked trusted");
                LocalServer server;
                NSString *remote = [NSString stringWithFormat:@"http://127.0.0.1:%hu", server.port];
                NSString *assetsHTML = [NSString stringWithFormat:@"<!doctype html><link rel='stylesheet' href='local.css'><link rel='stylesheet' href='%@/remote.css'><img src='%@/remote.png'><p>network fixture</p>", remote, remote];
                NSString *localCSS = [NSString stringWithFormat:@"@import url('%@/import.css'); body {font-size:23px; background-image:url('%@/background.png')}", remote, remote];
                check([[assetsHTML dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[root URLByAppendingPathComponent:@"assets.html"] atomically:YES], "asset page fixture failed");
                check([[localCSS dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[root URLByAppendingPathComponent:@"local.css"] atomically:YES], "local CSS fixture failed");
                NSURL *assetsPage = [root URLByAppendingPathComponent:@"assets.html"];
                probe.finished = NO;
                [view loadFileURL:assetsPage allowingReadAccessToURL:root];
                wait_for(^bool { return probe.finished; });
                check([evaluate(view, world, @"getComputedStyle(document.body).fontSize") isEqual:@"23px"], "local stylesheet did not load");
                check(server.requests == 0, "external resource reached loopback despite content rules");
                // 対照用の view には規則を付けず、同じ fixture が実際に接続を試すことを確認する。
                WKWebViewConfiguration *baselineConfig = [WKWebViewConfiguration new];
                baselineConfig.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
                baselineConfig.defaultWebpagePreferences.allowsContentJavaScript = NO;
                WKWebView *baseline = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 0, 700, 400) configuration:baselineConfig];
                Probe *baselineProbe = [Probe new];
                baseline.navigationDelegate = baselineProbe;
                window.contentView = baseline;
                [baseline loadFileURL:assetsPage allowingReadAccessToURL:root];
                wait_for(^bool { return baselineProbe.finished; });
                check(server.requests >= 3, "network baseline did not reach loopback resources");
                std::cout << "external resource requests: protected=0 baseline=" << server.requests << std::endl;
                [baseline stopLoading];
                std::cout << "WebKit raw href probe: " << checks << " checks passed\n";
                status = 0;
            } catch (const std::exception& error) {
                std::cerr << "WebKit probe after " << checks << " checks: " << error.what() << '\n';
            }
        } @catch (NSException *exception) {
            std::cerr << "WebKit probe exception: " << exception.description.UTF8String << '\n';
        }
        [view.configuration.userContentController removeAllScriptMessageHandlers];
        [window orderOut:nil];
        [window close];
        [NSFileManager.defaultManager removeItemAtURL:root error:nil];
        return status;
    }
}
