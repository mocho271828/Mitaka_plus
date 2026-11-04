# UNIT4: ウィンドウ操作と About の原典監査

調査日: 2026-10-29。実装前の契約案。対象原典はローカル Mitaka Plus 1.5.4 build101013。同梱 Lua API 説明書には 1.3.0 表記があり、版の一致は保証しない。本書は機能の実装完了を示さない。

## 調査対象と証拠の範囲

原典のルートを以下の `PLUS` と表記する。原本は CP932 として読み取り、変更・コピー・再配布していない。

`/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`

優先した資料は `PLUS/doc/script_jp/gui.html`、`system.html`、`PLUS/scripts/gui.lua` と `gui_jp.lua`。補助的に同梱 `.lua` / `.html` / `.htm` / `.ini` / `.txt` / `.xml` を検索した。CHM や PDF 全文の抽出、旧バイナリ内部の API 調査は行っていない。「見つからない」はこの範囲で根拠が見つからないという意味であり、旧実装に存在しないことの証明ではない。

AppKit の契約はインストール済み Apple SDK のヘッダで確認した。

`/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/AppKit.framework/Headers`

## 旧 Lua の確認済み契約

| API | 根拠 | 確定できる内容 | 未確定事項 |
| --- | --- | --- | --- |
| `GUI.fullScreen` | `gui.html:12–19` | `true` / `false` のプロパティ。代入例あり | 画面・Space の扱い、切替完了時点、遷移中の再代入 |
| `GUI:toggleFullScreen()` | `gui.html:16–18` | 引数なし。全画面を切り替え、上記プロパティが変化 | 戻り値、同期完了か受付完了か |
| `GUI:aboutDialog()` | `gui.html:122–124` | 引数なし。アプリ情報ウィンドウを表示 | 戻り値、モーダル性、再呼出し時の動作 |
| `GUI:resetWindows()` | `gui.html:119–121` | 引数なし。ウィンドウの配置を既定位置・サイズへ戻す | 対象ウィンドウ一覧、数値、全画面中の規則、戻り値 |
| `GUI:quit()` | `gui.html:100–102` | 引数なし。アプリを終了 | 戻り値、スクリプトからの終了順序 |
| `System:openDocument(fileName)` | `system.html:55–57` | ファイル名を受け、既定ビューアで開く | 相対基準、欠損時、戻り値 |

`scripts/gui_jp.lua:197` と英語版には全画面メニュー、`GUI.fullScreen` によるチェック状態、`Alt+Return` の設定がある。`gui_jp.lua:233,235,237–238` は配置リセット、About、PDF マニュアル、CHM スクリプトマニュアルの実使用例である。

`gui_jp.lua:232` には `GUI.restoreLastGUI` と `GUI:toggleRestoreLastGUI()` があるが、今回確認した API 説明書に独立した契約記述は見つからない。

`GUI.size` / `GUI.minimumSize` / `GUI.maximized`、その引数形式・単位・戻り値を確認できる公開名や用例は見つからない。Qt のプロパティ名や標準ウィンドウ操作から Lua の継承・公開を推定しない。最大化に関する履歴の記述は、Lua API の存在や名前の証拠に使わない。

## 現行ネイティブの接続点

- `native/gui/src/AppWindow.mm:22–45`: アプリメニューには終了があり、About と全画面専用項目はない。`addPlusMenus:fileMenu:` で各機能メニューへ委譲する。
- 同 `:48–58`: 主ウィンドウはタイトル・閉じる・最小化・サイズ変更を有効にして生成する。通常起動は `MitakaMainWindow` の frame autosave を使う。初期 content rect は 1280 × 800、`minSize` は 1100 × 850。
- 同ファイルの画面構築は Auto Layout を使う。既存の寸法を、そのまま有効な最小ウィンドウ寸法と見なしてはいけない。
- `AppController.mm`: 終了時に設定保存、スクリプト取消、各コントローラの無効化を実施する。最小化・復帰は再生と飛行に専用処理がある。全画面遷移の delegate 処理はない。
- `AppScripting.mm:119` の `applyScriptAction:error:` 冒頭はデータモデルの存在と読み込み完了を要求する。About・全画面などデータ非依存操作を追加する場合は、この条件より前で明示的に処理する。
- `ScriptController.mm:149–154`: helper の要求を main queue で適用し、その終了後にバックグラウンド側で応答を書く。終了操作をこの途中で実行すると、応答前に helper と通信経路を破棄し得る。

## AppKit で再利用する機能

| 機能 | Apple SDK の根拠 | 採用上の注意 |
| --- | --- | --- |
| About | `NSApplication.h:552–568`、`orderFrontStandardAboutPanelWithOptions:` | 名前・アイコン・版は bundle 情報を使用できる。Credits は `NSAttributedString` |
| 全画面 | `NSWindow.h:47,115–142,546–548` | `toggleFullScreen:` と `FullScreenPrimary`。style mask は実際の全画面状態に伴い更新される |
| 全画面の完了・失敗 | `NSWindow.h:863,883,926–929` | will/did enter/exit と失敗 delegate を使う。要求の受付と完了を分ける |
| 内容領域の寸法 | `NSWindow.h:285–291,348–349` | `setContentSize:` と frame/content 変換。単位は AppKit の論理ポイントとして新仕様に明記する |
| 最小寸法 | `NSWindow.h:560–573` | **Auto Layout 使用時は minSize / contentMinSize / maxSize / contentMaxSize が無視される**と明記。既存の制約へ接続する |
| 拡大・復元 | `NSWindow.h:394–399,492,833–834` | `isZoomed` / `performZoom:` / delegate。Windows の最大化や全画面と同一視しない |
| 画面内配置 | `NSWindow.h:347`、`NSScreen.h:40` | `constrainFrameRect:toScreen:` / `visibleFrame`。座標変換や Retina 倍率計算を自作しない |

## 最小のネイティブ実装案

### About

アプリメニューへ「Mitaka Native について」を追加し、標準 About パネルを使う。名前・マーケティング版・ビルド番号は `Info.plist` を正本とする。独自のダイアログ基盤や版番号定数を増やさない。

既存の `THIRD_PARTY_NOTICES.txt` と `LUA_LICENSE.txt` の内容・同梱先を利用し、非公式ネイティブ版であること、原本データを同梱しないこと、既存ライセンス情報を確認可能にする。原版の名前・版を本アプリの識別情報として表示しない。

Lua は原典どおり引数なしの `GUI:aboutDialog()` だけを候補にする。戻り値なしを採用するなら新ホストの明示的な契約として記録する。原典が戻り値を保証したとは記載しない。

### 全画面

主ウィンドウに `FullScreenPrimary` を設定し、AppKit の `toggleFullScreen:` を使う。投影用ウィンドウを勝手に切り替えない。ネイティブメニューと Lua は同じ getter / setter へ接続する。

getter は主ウィンドウの実際の style mask を参照する。切替中フラグを will/did/失敗 delegate で管理し、すでに要求した状態への再要求は冪等に扱う。反対方向の要求を遷移中に受けた場合は明示的に拒否する案とし、未検証の連続 toggle を積まない。

AppKit の全画面切替は非同期なので、Lua の成功応答は受付を意味する案である。完了保証の旧契約は未確認であり、これを一致済みと扱わない。main thread 内で完了待ちの nested run loop を作らず、実状態 getter と delegate の確定を利用する。

JD・観測地・カメラ・選択・通常再生・時計追従を保持する。全画面への切替だけで最小化やスリープの処理を代用しない。delegate では通知対象が主ウィンドウか確認する。

### サイズ・最小サイズ・拡大

ネイティブ UI と内部 API を先に設計し、未確認の `GUI.size` 等の Lua alias は作らない。内容領域の幅・高さを AppKit の論理ポイントで扱う新仕様とする。外枠と内容領域、物理ピクセルを混同しない。

最小サイズは、既存の Auto Layout の内容領域・キャンバス・操作部が必要とする制約として一箇所に保持する。`window.minSize` の代入だけで実装完了としない。入力は有限の正値、制約上の最小値、対象画面の可視領域を検証する。レイアウトが入らない画面で強制的に制約を破る案は採用せず、明示的に拒否するか操作部の既存レイアウトを改善する。

拡大と復元は `isZoomed` と `performZoom:` を使い、独自の復元矩形スタックを作らない。UI は「拡大 / 元に戻す」とし、Windows の最大化との厳密互換を称さない。全画面遷移中のサイズ・拡大操作は無効にする。

ウィンドウ矩形は既存 frame autosave を利用する。天文・表示状態の Session JSON に OS 固有の全画面遷移中フラグや復元矩形を混在させない。配置リセットの対象・既定値は原典未確定のため、実装するなら「ネイティブ版の既定配置」と明示する。

## 別途契約が必要な隣接操作

- `GUI:quit()`: main thread の `terminate:` を呼ぶだけでは helper への応答順序が不定になる。`dispatch_async(main)` だけでも、バックグラウンドの応答書き込みより後になる保証はない。応答送信完了後の終了予約を明示した通信契約が必要。
- マニュアル: ローカル用例は PDF と CHM を別々に開く。PDF を標準ビューアで開く機能と、macOS で CHM の表示環境がない問題を分ける。同梱ローカル HTML を案内するなら代替表示と明記する。未検証の CHM 対応を成功扱いしない。
- 原典にないサイズ API: 引数や単位を決めて実装する前に、旧 API の追加根拠または新 API としての採用判断が必要。

## 実装時の検証条件

1. データ未読み込みでも About と全画面操作が可能で、天体状態が変わらない。
2. 全画面のメニュー・Lua getter が実状態を示し、遷移完了・失敗・重複要求・反対要求を区別する。
3. 通常再生と時計追従を全画面切替の前後で保持し、最小化・スリープの既存停止規則を維持する。
4. Retina 上で論理サイズと描画・クリック領域が一致し、最小サイズで操作部が切れない。
5. 拡大・復元、手動サイズ変更、frame autosave、配置リセットを区別して検証する。
6. Lua の型・引数数を既存の型付き action 境界で検証し、未対応の名前や操作を成功扱いしない。

本監査ではソース実装・外部ライブラリ追加・既存設定変更は行わない。UI 操作検証は実装後に行う。
