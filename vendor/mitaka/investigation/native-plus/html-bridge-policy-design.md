# ローカル HTML の Lua 実行境界

調査・実装日: 2026-10-29。第 4 単位で policy、専用 HTML ウィンドウ、既存 Lua controller を接続した。旧原典の実例は [local-html-bridge-audit.md](local-html-bridge-audit.md) に分けて記録した。

## 採用した限定契約

ユーザーが許可したのは、明示的に信頼したローカル HTML からの Lua 呼出しである。オンライン文書には許可しない。今回の helper はこの判断を実装するための境界であり、旧ブラウザの全互換実装ではない。

- `read_html_document` は絶対 file URL の `.html` / `.htm` を読み取り、identity と immutable `NSData` を返す。`inspect_html_document` は同じ処理から identity だけを取得する。URL の host、user、password、port、query、fragment、base URL は認めない。
- `realpath` で実体パスを求め、通常ファイルだけを最大 1 MiB まで読む。FIFO、ディレクトリ、欠損、大きすぎるファイルを拒否する。読み始めの stat だけを信用せず、実際の読取量にも上限を適用する。
- identity は実体パス、device、inode、内容の SHA-256。読取前後とパスの stat も比較する。読取中の通常の変更や置換を検出したら失敗する。暗号処理は macOS の CommonCrypto を利用し、独自 hash 実装や新しい外部依存を追加しない。
- 明示承認後、UI がその identity を `trust` へ渡す。`trust` は内部 API であり、外部から渡された任意 identity を承認済みと解釈する入口ではない。
- 実行要求は main source frame、main target frame、既存 target frame、link activation をすべて要求する。source URL と現在の top document URL の双方について、承認した identity と一致することを再確認する。
- URL、identity、内容、payload が検証できなければ拒否する。別 document または内容変更、不正 payload の場合は承認も失効させる。別 frame や非 link activation の要求は実行しない。
- main page の `mtkp` 以外のリンクや遷移要求を受けた時点で承認を失効させる。同じファイルへの再読込、アンカー、別の local file、online URL も対象とする。取り消して元の画面が残った場合も復活しない。frame の読み込みと別 target の `mtkp` は拒否し、実行権限を与えない。
- 新しいファイルの選択、close、読み込み失敗、WebKit process 終了時に承認を破棄する。戻る・進むの UI と、保存設定や bookmark に承認を永続化する実装はない。

symlink の別名と `.` を含むパスは同じ実体へ正規化する。実体パスまで同じなら alias を認める一方、同じ内容の新 inode への置換や symlink の差替えは承認を引き継がない。ファイルの内容を変更して元の内容へ戻した履歴までは追跡しない。

## payload の限定復号

入力は URL を host / path へ分解する前の `NSString` である。先頭の `mtkp://` は大小文字を区別せず、その後の payload を UTF-8 の percent encoding として一度だけ復号する。`+` は literal のまま保持し、`%2520` は `%20` になる。空文字、不正 escape、不正 UTF-8、NUL、64 KiB を超える復号結果を拒否する。入力にも `7 + 3 × 64 KiB` UTF-16 code unit の上限を設ける。

Foundation の `stringByRemovingPercentEncoding` は UTF-8 の percent escape を復号し、不正な encoding では nil を返す契約である。SDK の `Foundation.framework/Headers/NSURL.h` で確認した。CP932 の URI payload、旧版の `+` / `%` の挙動、上限、scheme の大小文字規則は原典未確定である。これらは今回の限定 native 契約として扱う。

## WebKit と Lua の接続

この helper は WebKit の resource loader を制御しない。source frame の URL がローカルでも、その文書が remote script を読み込めば同じ権限で動作し得るため、URL 照合だけで実行を有効にしてはいけない。

専用 WKWebView は content JavaScript を無効にし、外部 resource の取得も禁止する。`WKWebpagePreferences.allowsContentJavaScript = NO` は inline script、参照された script、`javascript:` URL を含むページの JavaScript を停止する。アプリの user script は別であり、それ自体を実行境界として扱う。[Apple: allowsContentJavaScript](https://developer.apple.com/documentation/webkit/wkwebpagepreferences/allowscontentjavascript), [Apple: WKPreferences.javaScriptEnabled](https://developer.apple.com/documentation/webkit/wkpreferences/javascriptenabled)

content rule はロード前にコンパイルと設定を完了させ、失敗時は trusted document を読み込まない。以下の順序で全取得を止めてから file URL のみ許す。`resource-type` を省略した規則は全種別に適用され、`ignore-previous-rules` は同じ list の先行規則だけを無視する。WebKit は canonical URL と照合する。[WebKit: Content Blockers](https://webkit.org/blog/3476/content-blockers-first-look/), [Apple: WKContentRuleList](https://developer.apple.com/documentation/webkit/wkcontentrulelist)

```json
[
  {"trigger":{"url-filter":".*"},"action":{"type":"block"}},
  {"trigger":{"url-filter":"^file:///"},"action":{"type":"ignore-previous-rules"}}
]
```

ファイル選択ごとに新しい WKWebView と nonpersistent data store を作る。承認対象と同じ read で得た bytes を `loadData:MIMEType:characterEncodingName:baseURL:` へ渡し、元の canonical file URL を相対資産の基準にする。UTF-8、またはその復号が失敗した場合に Shift_JIS として読める文書を受け付ける。原典ホームの CSS と画像は `ui` 内で完結する。原本ファイルは変更しない。

frame navigation は delegate で拒否する。main page のリンクは app user script が既定の移動を取り消し、`mtkp` なら専用経路へ、通常リンクなら承認失効へ渡す。delegate へ届く他の main navigation も初回 snapshot 以外は拒否して失効させる。破棄済み view の遅れた要求も view の一致検査で拒否する。`WKNavigationTypeLinkActivated` 単独を人の操作の証明として扱わない。

trust は snapshot を読み込んだ同じ view / navigation の完了後にだけ設定する。ルールの非同期コンパイルは世代番号で検査し、古い callback から view を復活させない。実行時にはディスク上の identity と内容も再検査する。HTML の再読込と承認 bytes の取り違えを避ける一方、CSS や画像の内容は承認 identity に含めない。ページ script と frame が無効なため、これらの資産へ Lua 実行権限は渡らない。

承認された source は `ScriptController.runSource` から既存 Lua helper へ渡す。専用 0700 の一時ディレクトリと 0600 の Lua ファイルを作成し、終了・中断時に削除する。一時ディレクトリの所有権は worker dispatch 前に job に確定する。既存の時間・命令・メモリ予算と停止操作を再利用し、HTML 上で Lua を直接解釈しない。

## 原典 href の URL 正規化で見つかった差

Foundation の `NSURL URLWithString:` をローカルの SDK で実行すると、次の原典例は nil になった。

- `mtkp://Camera.zoom = 0.001; Stars.visible=true;`
- `mtkp://Time:setTime(2009,7,22,0,30,0);Time.speed=0;`
- `mtkp://Camera:toggleModeTo();`
- `mtkp://Camera.target = 'Planet.Earth';`

`mtkp://dofile('ui/scripts/eclipse_20090722.lua');` は元の absoluteString を保持した。この結果は Foundation の観測であり、WKWebView の href parser を実行した結果ではない。`WKNavigationAction.request.URL.absoluteString` が旧 href 全例を保存することは未確認である。

独立 WebKit probe ではアプリが管理する named `WKContentWorld` に `WKUserScript` を登録し、click 時に `getAttribute('href')` を読み取る方式を検証した。原典の上記 4 例と `dofile` の例は、空白・コロン・引用符を含めて元の文字列と完全一致した。ページの JavaScript を無効にしても app user script は動作した。

製品では message の WebView、world、source main frame、source URL、現在の document 世代・identity を host 側で検証する。named world は JavaScript 名前空間を分離するが DOM は共有するため、それだけを信頼の根拠としない。app script は全 anchor の既定移動を取り消し、host は `event.isTrusted` が真の操作だけを扱う。Lua の target は既存 main frame に限定する。旧版に存在する JavaScript API を推測して追加しない。

## 確認した SDK API

SDK は `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk`。以下は `System/Library/Frameworks/WebKit.framework/Headers/` の公開 header で確認した。

| Header | 確認した契約 |
| --- | --- |
| `WKNavigationAction.h` | sourceFrame、targetFrame（新 window なら nil）、request、navigationType |
| `WKFrameInfo.h` | isMainFrame、現在の request、securityOrigin、webView |
| `WKWebView.h` | loadFileURL と read access、loadData、現在の URL |
| `WKNavigationDelegate.h` | action policy、preferences 付き policy、provisional / redirect / commit / failure callbacks |
| `WKWebpagePreferences.h` | allowsContentJavaScript |
| `WKContentRuleListStore.h` | compileContentRuleListForIdentifier:encodedContentRuleList:completionHandler: |
| `WKUserContentController.h` | addContentRuleList:、addScriptMessageHandler:contentWorld:name:（handler は指定 world の全 frame に存在）、addUserScript: |
| `WKUserScript.h` | document start / main frame only / content world を指定する initializer |
| `WKContentWorld.h` | named world の変数名前空間は分離、DOM は共有 |
| `WKScriptMessage.h` | body、webView、frameInfo、world、name |

SDK の型や存在が確認できたことと、WebKit の実挙動を試験したことを区別する。

## 製品境界の検証

`html_bridge_policy.hpp` / `.mm` とその test、`HtmlBrowserController.h` / `.mm` とその test を追加し、既存 Makefile と `AppScripting` に接続した。policy 自体は Foundation と CommonCrypto、UI は既存 AppKit と macOS WebKit を使う。別の HTML parser や Lua 実行系は追加しない。

`-Wall -Wextra -Wpedantic -Werror`、macOS 13 deployment target、ARC でビルドした。policy test は通常 arm64、AddressSanitizer / UndefinedBehaviorSanitizer、x86_64 実行の各構成で **80 checks** 成功した。main frame / top document 一致、不正 frame、新 window、非 link activation、別 local / online source、取消後の失効、同一サイズ・mtime 復元後の内容変更、inode 置換、symlink 差替え、不正 UTF-8 / escape / NUL、document / payload の境界値、snapshot の不変性を含む。

製品 `HtmlBrowserController` の test は通常 arm64、AddressSanitizer / UndefinedBehaviorSanitizer、x86_64 の各 host で **73 checks** 成功した。ローカル CSS、ページ JavaScript と handler の分離、frame 拒否、実クリックと合成 click の区別、raw href、percent decode、host 拒否、ファイル変更、オンラインリンク取消と失効、close、Shift_JIS を検査した。最後に実クリックから `runSource`、Lua helper、ホストの表示フラグ変更、snapshot 再取得、`print`、完了まで接続した。三構成の結合試験は同じ通常 arm64 の `build-unit4-script/MitakaScript` を起動したため、helper 自体の sanitizer / x86_64 検証とは区別する。

loopback server で remote stylesheet、image、CSS `@import`、CSS background、iframe、通常リンクへの TCP 接続を数え、各製品試験で **0 接続** だった。初期実装では通常リンクの delegate 取消だけでは HTTP payload のない接続を観測したため、app script ですべての anchor の既定移動を先に取り消す形に修正した。キャッシュ済み資産、redirect、全 scheme の組合せを網羅した試験ではない。

読み取りレビューでは snapshot と表示 bytes の結合、世代・view・world・frame の検査、復号、通常リンク取消、破棄済み view の delegate 拒否、一時ディレクトリ所有権を確認し、必須修正の残件はなかった。compile callback 保留中の連続 open / close と保持された旧 view への直接 navigation はコードレビューで確認し、専用の実行回帰は追加していない。fixture は一時ディレクトリだけに作成し、終了時に削除した。Plus 原本への書込みや旧アプリ起動は行っていない。

最終ログは `native/gui/` を基準に次のとおり。

- policy: `build-unit4-html-policy/test.log`、同ディレクトリの `test-policy-san-final.log`、`test-policy-x86-final.log`
- 製品 HTML: `build-unit4-html-policy/test-browser-integration.log`、`build-unit4-html-san/test-browser-integration.log`、`build-unit4-html-x86/test-browser-integration.log`
- Lua controller（source staging と cleanup の回帰を含む）: `build-unit4-script/script-test.log`

再実行は `make -C native/gui BUILD_DIR=<専用ディレクトリ> html-browser-test`。sanitizer は `SANITIZE=address,undefined`（実行時 `ASAN_OPTIONS=detect_leaks=0`）、Intel は `ARCH=x86_64` を指定する。この target は選択構成の helper をビルドして渡す。上記の今回の試験では、test 実行ファイルへ通常 arm64 helper の絶対パスを直接渡した。

## 独立 WebKit probe の結果

`investigation/native-plus/unit4/probe_html_webkit.mm` を AppKit / WebKit とリンクし、通常の macOS window 上で 65 checks が成功した。ソースは検証専用であり、製品の BrowserController でも Lua 実行機能でもない。

- inline page script が動かず、page world に app の message handler が見えないことを確認した。
- AppKit の mouse down / up を WebKit に届け、原典 5 件の raw href を受信した。message の WebView、main frame、world、URL の一致を確認した。
- native click は `event.isTrusted=true`、app 側 JavaScript からの `.click()` は false になった。probe は差を検証するため false も記録するが、製品実装は false を拒否する必要がある。
- local iframe navigation が delegate で取り消されることを確認した。
- 同じ local fixture で remote stylesheet、image、CSS `@import`、CSS background の取得先を loopback HTTP server にした。規則ありは 0 件、規則なしの対照 view は 4 件のリクエストを送った。規則ありでも local CSS の font-size は反映された。

この probe は raw href 経路と上記 resource 種の遮断だけを確認した初期調査である。その後の snapshot / 製品 controller / Lua helper 結合は前節の test で確認した。probe で成功した範囲をブラウザ全体の安全性の証明とはしない。外部サーバーへの接続と Plus 原本の変更は行っていない。

コマンド（`native/gui` から実行）:

```sh
xcrun clang++ -std=c++17 -O2 -g -Wall -Wextra -Wpedantic -Werror -mmacosx-version-min=13.0 -fobjc-arc ../../investigation/native-plus/unit4/probe_html_webkit.mm -framework AppKit -framework WebKit -o build-unit4-html-policy/probe_html_webkit
build-unit4-html-policy/probe_html_webkit
```

ログは `native/gui/build-unit4-html-policy/build-webkit-probe.log` と `test-webkit-probe.log`。製品接続後の独立レビュー結果は前節に記録した。
