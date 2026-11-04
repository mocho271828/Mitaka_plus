#import "HtmlBrowserController.h"
#import <WebKit/WebKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#include "html_bridge_policy.hpp"
#include <stdexcept>

using namespace mitaka::gui;
namespace {
NSString *const bridgeName = @"mitakaLocalLink";
NSString *const bridgeWorldName = @"MitakaTrustedLocalHTML";
NSString *const localRules = @"[{\"trigger\":{\"url-filter\":\".*\"},\"action\":{\"type\":\"block\"}},{\"trigger\":{\"url-filter\":\"^file:///\"},\"action\":{\"type\":\"ignore-previous-rules\"}}]";
NSString *const linkScript = @R"js(
document.addEventListener('click', event => {
    const anchor = event.target.closest?.('a');
    if (!anchor) return;
    const href = anchor.getAttribute('href');
    if (href === null) return;
    event.preventDefault();
    const target = anchor.getAttribute('target') || document.querySelector('base[target]')?.getAttribute('target') || '';
    window.webkit.messageHandlers.mitakaLocalLink.postMessage({href, target, trusted: event.isTrusted});
}, true);
)js";
NSError *htmlError(NSString *text) {
    return [NSError errorWithDomain:@"MitakaLocalHTML" code:1 userInfo:@{NSLocalizedDescriptionKey:text}];
}
}

// WKUserContentController の強参照が window controller に循環しないようにする。
@interface HtmlMessageForwarder : NSObject <WKScriptMessageHandler>
@property(nonatomic, weak) id<WKScriptMessageHandler> receiver;
@end
@implementation HtmlMessageForwarder
- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.receiver userContentController:controller didReceiveScriptMessage:message];
}
@end

@interface HtmlBrowserController () <WKNavigationDelegate, WKScriptMessageHandler, NSWindowDelegate> {
    WKWebView *_webView;
    NSTextField *_status;
    WKNavigation *_snapshotNavigation;
    NSURL *_sourceURL;
    std::optional<HtmlDocumentSnapshot> _snapshot;
    HtmlBridgePolicy _policy;
    NSUInteger _generation;
    BOOL _initialNavigation;
}
@end

@implementation HtmlBrowserController
- (instancetype)init {
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 900, 660)
        styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
        backing:NSBackingStoreBuffered defer:NO];
    self = [super initWithWindow:window];
    if (self) {
        window.releasedWhenClosed = NO;
        window.title = @"信頼したローカル HTML";
        window.minSize = NSMakeSize(600, 360);
        window.delegate = self;
        NSButton *open = [NSButton buttonWithTitle:@"信頼した HTML を開く…" target:self action:@selector(chooseTrustedHTML:)];
        open.frame = NSMakeRect(12, 618, 220, 30);
        open.autoresizingMask = NSViewMinYMargin;
        [window.contentView addSubview:open];
        _status = [NSTextField labelWithString:@"ローカル HTML を明示選択してください。オンラインページは読み込みません。"];
        _status.frame = NSMakeRect(12, 8, 876, 40);
        _status.autoresizingMask = NSViewWidthSizable;
        _status.maximumNumberOfLines = 2;
        [window.contentView addSubview:_status];
        [window center];
    }
    return self;
}
- (BOOL)trusted { return _policy.trusted(); }
- (void)chooseTrustedHTML:(id)sender {
    (void)sender;
    if (self.window.attachedSheet) return;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[UTTypeHTML];
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.directoryURL = self.defaultDirectoryURL;
    panel.prompt = @"信頼して開く";
    panel.message = @"このファイルのリンクを押すと Lua を実行し、ローカルファイル操作とコマンド実行を許可します。信頼できる HTML のみ選択してください。ページ JavaScript は実行しません。";
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result != NSModalResponseOK) return;
        NSError *error = nil;
        if (![self openTrustedFileURL:panel.URL error:&error]) self->_status.stringValue = error.localizedDescription;
    }];
}
- (void)discardDocument {
    ++_generation;
    _policy.revoke();
    _snapshot.reset();
    _sourceURL = nil;
    _snapshotNavigation = nil;
    _initialNavigation = NO;
    [_webView stopLoading];
    [_webView.configuration.userContentController removeAllScriptMessageHandlers];
    // 旧 view が非同期処理で残っても、delegate の一致検査で移動を取り消す。
    [_webView removeFromSuperview];
    _webView = nil;
}
- (BOOL)openTrustedFileURL:(NSURL *)url error:(NSError **)error {
    NSAssert(NSThread.isMainThread, @"HTML UI must run on the main thread");
    [self discardDocument];
    try {
        _snapshot = read_html_document(url);
        _sourceURL = [NSURL fileURLWithFileSystemRepresentation:_snapshot->identity.canonical_path.c_str() isDirectory:NO relativeToURL:nil];
        NSString *encoding = @"UTF-8";
        if (![[NSString alloc] initWithData:_snapshot->data encoding:NSUTF8StringEncoding]) {
            if (![[NSString alloc] initWithData:_snapshot->data encoding:NSShiftJISStringEncoding])
                throw std::invalid_argument("HTML must use UTF-8 or Shift_JIS text encoding");
            encoding = @"Shift_JIS";
        }
        _status.stringValue = @"ローカル HTML を読み込んでいます…";
        const NSUInteger generation = _generation;
        __weak HtmlBrowserController *weakSelf = self;
        [WKContentRuleListStore.defaultStore compileContentRuleListForIdentifier:@"MitakaLocalHTMLOnly-v1"
            encodedContentRuleList:localRules completionHandler:^(WKContentRuleList *rules, NSError *failure) {
            HtmlBrowserController *controller = weakSelf;
            if (!controller || controller->_generation != generation) return;
            if (!rules || failure) {
                [controller discardDocument];
                controller->_status.stringValue = @"外部リソースの遮断設定を作成できないため、読み込みを中止しました。";
                return;
            }
            [controller loadSnapshotWithRules:rules encoding:encoding];
        }];
        return YES;
    } catch (const std::exception& failure) {
        [self discardDocument];
        NSString *message = [NSString stringWithUTF8String:failure.what()];
        if (error) *error = htmlError(message);
        _status.stringValue = message;
        return NO;
    }
}
- (void)loadSnapshotWithRules:(WKContentRuleList *)rules encoding:(NSString *)encoding {
    WKWebViewConfiguration *config = [WKWebViewConfiguration new];
    config.websiteDataStore = WKWebsiteDataStore.nonPersistentDataStore;
    config.defaultWebpagePreferences.allowsContentJavaScript = NO;
    [config.userContentController addContentRuleList:rules];
    WKContentWorld *world = [WKContentWorld worldWithName:bridgeWorldName];
    HtmlMessageForwarder *forwarder = [HtmlMessageForwarder new];
    forwarder.receiver = self;
    [config.userContentController addScriptMessageHandler:forwarder contentWorld:world name:bridgeName];
    [config.userContentController addUserScript:[[WKUserScript alloc] initWithSource:linkScript
        injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES inContentWorld:world]];
    NSRect bounds = self.window.contentView.bounds;
    _webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, 54, bounds.size.width, bounds.size.height - 104) configuration:config];
    _webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _webView.navigationDelegate = self;
    [self.window.contentView addSubview:_webView];
    // 同じ read から得た immutable bytes を表示し、ディスクの再読み込み競合を避ける。
    _initialNavigation = YES;
    _snapshotNavigation = [_webView loadData:_snapshot->data MIMEType:@"text/html" characterEncodingName:encoding baseURL:_sourceURL];
    if (!_snapshotNavigation) {
        [self discardDocument];
        _status.stringValue = @"HTML の読み込みを開始できませんでした。";
    }
}
- (void)webView:(WKWebView *)view decidePolicyForNavigationAction:(WKNavigationAction *)action
        decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    if (view != _webView) { handler(WKNavigationActionPolicyCancel); return; }
    if (!action.targetFrame.isMainFrame) { handler(WKNavigationActionPolicyCancel); return; }
    if (_initialNavigation && action.navigationType == WKNavigationTypeOther && [action.request.URL isEqual:_sourceURL]) {
        _initialNavigation = NO;
        handler(WKNavigationActionPolicyAllow);
        return;
    }
    // キャンセルした移動でも信用を残さない。mtkp は raw href の専用経路だけを使う。
    _policy.revoke();
    _snapshot.reset();
    _status.stringValue = @"ページ移動を取り消し、信頼を解除しました。実行するには HTML を選択し直してください。";
    handler(WKNavigationActionPolicyCancel);
}
- (void)webView:(WKWebView *)view didFinishNavigation:(WKNavigation *)navigation {
    if (view != _webView || navigation != _snapshotNavigation || !_snapshot) return;
    _policy.trust(_snapshot->identity);
    _status.stringValue = [NSString stringWithFormat:@"信頼済み: %@ — このページの mtkp リンクを押すと Lua を実行します。", _sourceURL.lastPathComponent];
}
- (void)webView:(WKWebView *)view didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    (void)navigation;
    if (view != _webView) return;
    _policy.revoke();
    _snapshot.reset();
    _status.stringValue = error.localizedDescription;
}
- (void)webView:(WKWebView *)view didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    [self webView:view didFailNavigation:navigation withError:error];
}
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)view {
    if (view != _webView) return;
    [self discardDocument];
    _status.stringValue = @"HTML 表示が終了しました。ファイルを選択し直してください。";
}
- (void)userContentController:(WKUserContentController *)controller didReceiveScriptMessage:(WKScriptMessage *)message {
    if (message.webView != _webView || controller != _webView.configuration.userContentController ||
        ![message.world isEqual:[WKContentWorld worldWithName:bridgeWorldName]] ||
        ![message.name isEqualToString:bridgeName] || !message.frameInfo.isMainFrame) return;
    id body = message.body;
    if (![body isKindOfClass:NSDictionary.class] || ![body[@"href"] isKindOfClass:NSString.class] ||
        ![body[@"target"] isKindOfClass:NSString.class] || body[@"trusted"] != (__bridge id)kCFBooleanTrue) return;
    NSString *target = body[@"target"];
    NSString *href = body[@"href"];
    if (![href.lowercaseString hasPrefix:@"mtkp:"]) {
        _policy.revoke();
        _snapshot.reset();
        _status.stringValue = @"ページ移動を取り消し、信頼を解除しました。実行するには HTML を選択し直してください。";
        return;
    }
    const bool mainTarget = target.length == 0 || [target isEqualToString:@"_self"];
    const auto result = _policy.evaluate({href, message.frameInfo.request.URL, _webView.URL,
        true, mainTarget, mainTarget, true});
    if (result.disposition != HtmlBridgeDisposition::script) {
        _status.stringValue = [NSString stringWithUTF8String:result.error.c_str()];
        return;
    }
    NSString *source = [[NSString alloc] initWithBytes:result.script.data() length:result.script.size() encoding:NSUTF8StringEncoding];
    NSString *failure = nil;
    if (!self.scriptRequested || !self.scriptRequested(source, _sourceURL, &failure)) {
        _status.stringValue = failure ? failure : @"Lua 実行は接続されていません。";
        return;
    }
    _status.stringValue = @"Lua を開始しました。結果はスクリプト出力で確認できます。";
}
- (void)windowWillClose:(NSNotification *)notification {
    (void)notification;
    [self discardDocument];
    _status.stringValue = @"信頼を解除しました。ローカル HTML を選択してください。";
}
- (void)dealloc {
    [_webView.configuration.userContentController removeAllScriptMessageHandlers];
}
@end
