# ローカル HTML と Lua 呼出しの原典監査

調査日: 2026-10-29。調査時の HEAD は `ae300e1`。第 3 単位の確定前に、次のブラウザ実装に必要な契約を読み取り専用で調べた。本書以外のブラウザ実装は追加していない。

原典は `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`（以下 `PLUS`）。対象は Plus 1.5.4 build101013、同梱 API 文書の表示は 1.3.0。HTML は CP932 から読み取り、以下の行番号は原本の行番号を指す。旧ブラウザや同梱スクリプトは実行していない。

## 確定したリンク形式

`PLUS/doc/script_jp/uibrowser.html:17–22` は、リンク URL の先頭に `mtkp://` を付け、その後に Mitaka Plus のスクリプトを書く形式を説明する。以下は文書の例と同梱ページの実例である。

| 場所 | href の値 | 確認できる構文 |
| --- | --- | --- |
| `doc/script_jp/uibrowser.html:19` | `mtkp://Camera.zoom = 0.001; Stars.visible=true;` | 空白、複数文、大小文字を含む識別子 |
| 同 20 | `mtkp://Camera.target = 'Planet.Earth';` | 単引用符で囲んだ文字列 |
| 同 21 | `mtkp://dofile('scripts/test.lua');` | 相対パスを持つ Lua ファイル呼出し |
| `ui/index.html:30` | `mtkp://dofile('ui/scripts/eclipse_20090722.lua');` | 同梱 Lua ファイル呼出し |
| 同 32 | `mtkp://Time.step=mtk.STEP_MIN;Time.speed=1;` | 時間ステップと速度 |
| 同 33 | `mtkp://Time:setTime(2009,7,22,0,30,0);Time.speed=0;` | colon 形式、複数引数、複数文 |
| 同 34 | `mtkp://Camera:toggleModeTo();` | 引数なしの colon メソッド |
| 同 36 | `mtkp://dofile('ui/scripts/eclipse_diagram.lua');` | 別の同梱 Lua ファイル呼出し |

原典は `mtkp://` 以降をホスト名やパスとして分割する契約を示していない。Lua の大小文字、空白、引用符、slash を保持する必要がある。一般の URL 正規化後の host / path を組み立て直す処理がこの契約を満たすかは、採用するブラウザ API で別途検証する。

### 符号化の未確定事項

`ui/index.html:5` と `uibrowser.html:4` は `charset=shift_jis` を宣言する。今回確認した `mtkp://` の payload はすべて ASCII 文字で、percent encoding を使う例はない。次の規則は原典から確定できない。

- `%xx` をどの段階で何回復号するか。`+` を空白として扱うか。
- 日本語を含む Lua 文字列の URI 上の符号化が CP932 か UTF-8 か。
- `#`、`?`、`%`、改行、HTML character reference を含む Lua の扱い。
- scheme の大小文字、payload の長さ制限、不正な escape sequence の扱い。

HTML 自体の文字コード宣言を、URI payload の復号規則と同一視しない。まず上表の実例を壊さずに扱えるか確認し、未確定の入力まで旧版互換と説明しない。

## JavaScript からの呼出し

`uibrowser.html:12` は HTML で利用可能な JavaScript や Flash に言及するが、Lua を呼ぶ JavaScript 関数名・引数・戻り値・例を定義していない。`ui`、`doc/script_jp`、`scripts` の HTML / Lua を `<script`、`javascript:`、`onclick`、`onload`、`window.`、`document.`、`location`、`encodeURIComponent`、`external.` で検索したが、呼出し例は見つからなかった。Plus の対象ディレクトリには `.js` ファイルも見つからなかった。

したがって、`window.external` や独自の `executeLua` 等を旧公開 API として追加する根拠はない。JavaScript が `mtkp://` へ遷移する方式も今回の原典だけでは確認できない。Flash への言及は macOS での再生互換や導入方針の根拠にしない。Wine 同梱のブラウザ runtime に含まれる JavaScript は、Plus が制作した UI の実例とは区別した。

## ホーム、ブックマーク、表示 API

| 項目 | 原典 | 確定した範囲 |
| --- | --- | --- |
| 既定ホーム | `uibrowser.html:15–16,23–26` | `ui/index.html`。ホームボタンで戻る |
| ホーム設定 | 同 25–26 | 実行フォルダの `mitakaPlus.ini` にある `homeUrl=...`。絶対パス、Plus からの相対パス、URL |
| ブックマーク | 同 12 | 表示したページを登録する機能がある |
| `GUI.uiBrowser` | `gui.html:47–50` | UI ブラウザの表示・非表示 |
| `GUI:toggleUIBrowser()` | 同 51–54 | 上の表示状態を反転 |
| `GUI.browserUrl` | 同 55–57 | 表示するページの URL 文字列。例は `"ui/index.html"` |

手元の Plus 実行フォルダに `mitakaPlus.ini` は存在しない。見つかった INI は `mitaka.ini`、`mitaka_pp.ini`、`orhioman.ini` で、`home` / `url` / `bookmark` / `browser` 等に該当する設定もなかった。この不在を理由に文書のファイル名を別の INI へ読み替えたり、原本へ新しい INI を書いたりしない。

ブックマークの保存形式・保存先・重複規則・順序・Lua API は未確定。ホーム登録やブックマーク登録が Lua 実行を信頼する操作だとする記載もない。新しいブラウザの設定保存先と信頼状態は、原版の保存互換を推測せず別途設計する。

`scripts/gui.lua:223` と `gui_jp.lua:223` は UI ブラウザの action に `GUI:toggleUIBrowser();` と表示状態式 `GUI.uiBrowser;`、F11 を割り当てる。toolbar にも同 action を追加する（258 行）。将来 getter を接続する際は、現在の他の GUI window API と同様に、実ウィンドウの閉じる操作へ追従する必要がある。

## 同梱ページに必要な相対資産

以下の参照先はすべて手元に存在する。

| 参照元 | 参照値 | 解決先 |
| --- | --- | --- |
| `ui/index.html:9` | `base.css` | `ui/base.css` |
| 同 30 | `images/eclipse_begin.png` | `ui/images/eclipse_begin.png` |
| 同 34 | `images/eclipse_fromland.png` | `ui/images/eclipse_fromland.png` |
| 同 36 | `images/eclipse_diagram.png` | `ui/images/eclipse_diagram.png` |
| `ui/base.css:111` | `./images/li_bl.gif` | `ui/images/li_bl.gif` |
| 同 120,134 | `./images/bg_gray.png` | `ui/images/bg_gray.png` |
| Lua `dofile`、`index.html:30` | `ui/scripts/eclipse_20090722.lua` | `PLUS/ui/scripts/eclipse_20090722.lua` |
| Lua `dofile`、同 36 | `ui/scripts/eclipse_diagram.lua` | `PLUS/ui/scripts/eclipse_diagram.lua` |

HTML / CSS の相対参照は `ui` 内で完結する。一方、同梱 `dofile('ui/scripts/...')` は Plus 実行フォルダを基準にした配置と整合する。後者はファイル配置からの推論であり、旧 runtime の cwd を直接観測した結果ではない。現在のネイティブ `AppScripting` は選択中の `data` の親を Lua helper の `workingDirectoryURL` に設定している。HTML の読み取り許可範囲と Lua の cwd は別の責務として扱う。

同梱ホームが参照する 2 本の Lua は、現在のホスト API では完走しない。両ファイルの 6 行目は未対応の `Places.pointer` で、その後にも大気、影、姿勢、選択などの未対応操作がある。橋渡しの動作確認と、デモ全体の実行互換を分けて記録する。途中まで実行した時間変更等が自動的に巻き戻るとは扱わない。

`ui/scripts/12constels.lua`、`orion3d.lua` と対応画像も存在するが、現在の `ui/index.html` からは参照されていない。未参照ファイルを削除・変換する必要はない。

`ui/index.html:39–40` には `target="_blank"` の HTTP 外部リンクが 2 件ある。このページ自身には外部 JavaScript、iframe、外部 CSS の参照は見つからなかった。DOCTYPE の外部識別子もあるため、実装試験ではネットワーク取得の有無を確認する。

## 実装前に区別すべき境界

ユーザーが決定した権限は「明示的に信頼したローカル HTML のみ許可。オンラインページからの実行は禁止」。この判断は [IMPLEMENTATION_POLICY.md](../../IMPLEMENTATION_POLICY.md) に記録された。旧原典がオンライン配置を許す説明は、今回のユーザーの制約を上書きしない。

ブラウザ実装では、少なくとも表示文書・実行要求の発生フレーム・遷移先を確認し、外部リンク、新規ウィンドウ、戻る / 進む、reload の後もオンライン文書に信頼を継承しないことを検証する。信頼したローカルページが外部の script や frame を読み込む場合も、その事実だけで外部コードへ Lua 権限を与えられない。具体的な制御方法は採用するブラウザ API の確認後に決める。

信頼を単一ファイル・ディレクトリのどちらに付与するか、リンク先の別のローカルページへ継承するか、保存後の変更や symlink をどう扱うか、JavaScript 起因の呼出しをどこまで許すかは、原典からは決まらない。本書では未確定事項として残し、暗黙の互換仕様にしない。ブラウザの読み取り権限を広げることと、ローカル Lua の実行承認は別に検証する。

今回の変更は本監査文書のみ。原本の書き込み・旧アプリ実行・オンライン参照・ブラウザ実装・依存追加は行っていない。符号化、ナビゲーション、相対資産の実ブラウザ試験は次の実装単位で必要となる。
