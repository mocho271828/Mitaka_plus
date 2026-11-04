# ローカル Plus の独自 UI・画像合成・状態・入力の追加調査

調査日: 2026-10-29。第2実装単位の後に進める機能のための読み取り調査であり、以下の API が移植済みという報告ではない。原版実行ファイルの起動、原本の書換え、媒体の変換、オンラインページの実行は行っていない。

## 原典と確度

`P` は `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。`D` は `P/doc/script_jp`、`L` は `P/scripts`。行番号は原本の改行を維持してデコードした位置で、HTML の表示行数ではない。CP932 と UTF-8 を区別して読み、原本には保存していない。

- 対象の README は Plus 1.5.4 build101013（`P/ReadmeWin_J.txt:3`）。API 文書は 1.3.0、2007-12-23（`D/contents.html:17`）。同じ版の仕様書として扱わない。
- **文書確定**は API 文書に型・意味がある項目、**用例のみ**は同梱 Lua で使用を確認した項目、**未確定**は範囲・単位・境界・別名関係が確認できない項目とする。文書の明白な転記誤りも別途記す。
- 通常版 Mitaka の PDF と `sources/official/mitaka_source/Mitaka/` は比較資料であり、Plus のバインディングや描画動作の根拠に置き換えない。
- 媒体の全9登録、独自追加、`.mvp`、ファイル名不一致、Charts / Titles の資産は [local-media-audit.md](local-media-audit.md)、Lua 接続の第1単位時点の調査は [local-lua-audit.md](local-lua-audit.md) を参照する。後者の「現在登録済み」は調査時点の記録であり、最新の対応表ではない。

## 1. 画像の position / zoom と描画領域

結論として、今回確認した Plus 文書・同梱 Lua から **Images の位置・倍率・回転・不透明度の API 契約は確定できない**。ネイティブの画像プレビューに同名の操作を設けても、旧 Plus の同一単位や合成範囲を満たしたことにはならない。

|対象|確認できた内容|根拠・未確定点|
|---|---|---|
|`Images`|`visible:boolean`、`name:string`、`index:integer`、`toggle/prev/next/first/last`。name と index は連動する|`D/images.html:12–37`。位置・幅・高さ・倍率・回転・不透明度は未掲載。index の起点、前後の端、名前重複時の選択は未確定|
|登録の配置情報|`images.dat` は媒体参照2列、type、メニュー名、表示名の5列|`P/media/images.dat:1–9`。位置やサイズの列はない。type `P` の厳密な表示契約は未確定|
|画像 transform の用例|`L/`、`P/ui/scripts/`、`P/state/`、`D/` のテキストを検索しても `Images/Movies/Audio/Charts/Titles` の position / zoom / scale / rotation / opacity / width / height 指定を確認できない|未掲載 API の不存在を証明するものではない。バイナリ解析・実機観測はこの調査では行っていない|
|`Camera.zoom`|宇宙空間モードでのターゲット天体からの距離。単位は **パーセク**|`D/camera.html:72–78`。画像の表示倍率への転用は不可|
|`Pointer:setPos/addPos/getPos`|実数3座標。getPos は3つの実数を返す|`D/pointer.html:20–30`。原点・軸・距離単位・投影との対応は未確定。2D のピクセル座標として扱えない|
|`ScreenMenu.angle`|正面0、単位は **度**|`D/screenmenu.html:15–16`。画像位置の契約ではない|
|`ToolBar:setIconSize(width,height)`|整数2引数、アイコン寸法は **ピクセル**|`D/toolbar.html:21–22`。描画ビューの寸法と混同しない|
|通常版 PDF の画面設定|ScreenW / ScreenZ 等は物理スクリーンの設定|`P/mitaka_manual_J.pdf` p.42–43、`P/mitaka.ini:15–25`。画像の画面座標や Retina の point/pixel とは別|

第2単位のネイティブ `native/gui/src/MediaImageView.mm` の静的確認では、画像1枚を独立したプレビュー領域の中央へアスペクト比を保って収め、その fit 倍率に `zoom` を掛ける。pan は AppKit ビュー上の point、回転は度、不透明度は0–1、背景は暗色、合成は SourceOver。倍率1は原画像の1画素を1画素で表示する意味ではない。これは採用したネイティブ契約で、天文シーンへの重畳、投影画面への重畳、複数画像の z 順、旧 `P` の特殊表示、画像を含む天文シーンの capture を実装した証拠にはならない。

### 通常版公開ソースにある比較用の手掛かり

|原典|通常版で確認した処理|Plus へ持ち込めない推論|
|---|---|---|
|`main.cpp:2248–2275`|画像の scale に `get_screen_w()/180.0 * get_chart_zoom_factor()` を使用。PopupImage の分岐がある|Plus の `P`、画像のピクセル座標、倍率の Lua プロパティ名が同じとはいえない|
|`mtk_3D_chart.cpp:63–67,91–117`|chart の経度・緯度と倍率を保持。経度に360の補正、緯度を±90へ制限、倍率は0.2–5|Plus Images の範囲・初期値・原点として採用する根拠にはならない|
|`main.cpp:5265–5280`|通常の画像では入力軸から chart 経度・緯度を変更し、画像にも chart 倍率を適用|平面画像の水平ドラッグと同一処理とはいえない|
|`main.cpp:5284–5294`|画像の前後選択は先頭・末尾で wrap する|Plus `Images:prev/next` の境界契約は別途確認が必要|

以上のパスは `sources/official/mitaka_source/Mitaka/` 基準。画像平面の配置、立体視、物理スクリーン設定まで含む通常版描画を、ネイティブの平面プレビューへ名前だけ移植しない。

## 2. 画像合成・描画制御・保存

|対象|文書または用例で確認した契約|移植上の不足|
|---|---|---|
|`Renderer.interactive` / `toggleInteractive()`|false の間は `render()` まで描画しない（`D/renderer.html:44–50`）|AppKit の再描画抑止、投影・画像 capture との整合が必要。単なるフラグ保存では満たせない|
|`Renderer.frame` / `resetFrame()` / `render()`|frame は**次の描画番号の整数**。描画ごとに1増加、reset は0（同:52–68）|Movies / Audio の再生位置とは別のカウンター|
|`renderFileNamePattern`|`output%05i.png` 等の printf 形式（同:58–60）|対応する書式を限定して検証する必要がある。任意の書式文字列を C の varargs へ直渡しする根拠にはならない|
|`renderWidth/renderHeight`|整数の出力寸法（同:61–65）|範囲・上限・0の扱いは未確定|
|`renderToFile/captureToFile`|前者は指定寸法、後者は現在の描画領域寸法、双方 frame +1（同:70–75）|文書で **Pro only**。通常 Plus 1.5.4 の必須対応に数えない|
|`GUI:saveImageDialog()`|現在のシミュレーション画面を画像保存するファイル選択（`D/gui.html:20–21`）|こちらは Pro 限定記載なし。旧 output pattern API と区別する|
|`Renderer.stereoType`|文字列 `None/Anaglyph/ColorAnaglyph`（`D/renderer.html:77–79`）|画像合成や左右ビュー、capture の立体視対応は未確定|
|`Scene.Background.black`、`Scene.editOnCapturedBG`、`Renderer.editOnCapturedBG`|false の代入例（`L/init.lua:10–11`、`L/quadraopt.lua:1–4`）|画像 capture 上で編集するらしい名前だけから、入力の意味・合成順・保持期間を決めない|
|`Scene.Fader.type=Fader.TYPE_SOLIDCOLOR`|代入例のみ（`L/quadraopt.lua:3`）|色、時間、対象ビュー、他のtypeは未確定|
|`Scene.Fader` / `Desktop.Fader`|日本語 GUI は前者の toggle と後者の visible を同時使用。英語 GUI は両方 Desktop（`L/gui_jp.lua:193`、`L/gui.lua:193`）|同一オブジェクトか別名か不明。投影専用黒フェードへ両方を接続して同一互換としない|
|`Scene:clearLayouts()`|日英 `layouts*.lua:1` に呼出しだけがある|layout 登録、画像合成要素、順序、座標 API は確認できない|
|`Scene:clear()` / `Scene.mode`、`Renderer.style/resetView`|`L/tutorial.lua:14–17` の初期化例|API 文書に Scene の専用ページはなく、引数や状態範囲は未確定|

出力を実装する場合も原本や選択データ配下への書込みを避ける既存 guard を使う。原本の見た目を調べるために画像を再保存したり、既存画像へ上書きしない。

## 3. 動画・音声

文書上の `Movies` / `Audio` は `visible`、`name/index`、`play/pause/playing/togglePlaying`、`frame/frameLength`、前後・先頭・末尾を持つ（`D/movies.html:12–57`、`D/audio.html:12–57`）。`frameLength` は読取専用。`frame` の単位、整数性、fps、音声サンプル数との関係、未ロード時や範囲外の値、再生終了時の挙動は記載されない。

- 同梱英語 shortcut は `Movies.frameLength/10` の移動と先頭/末尾を使用する。日本語版は前後操作が Time 操作へ変更され、先頭移動はコメントアウト、末尾移動だけが有効（`L/shortcuts.lua:72–77`、`L/shortcuts_jp.lua:72–78`）。説明文字列の「ムービーを1/10戻す」だけを実装の根拠にしない。
- `visible=false` が非表示・停止・一時停止・ミュートのどれに影響するか、name/index の変更で再生が始まるか、前後の端で wrap するかは未確定。ネイティブ側では明示操作まで再生しないという採用済みの契約を保つ。
- `GUI.soundControler/toggleSoundControler` は綴りを含め `L/gui_jp.lua:224` に用例があるが、音量・音源数・channel・mixer・loop の API は確認できない。
- `P` の探索範囲に動画・音声実ファイルと登録 `movies.dat/audio.dat` は見つからない。既存 codec DLL の存在は、全フォーマットや seek の完全互換の証明ではない。AVFoundation で開ける明示選択したローカルファイルを扱い、非対応を診断する単位は切り出せる。
- 通常版 `mtk_movie.cpp:343–385` は DirectShow の position と SetPositions を使うが、これだけで Plus の `frame` が同じ単位・精度とはいえない。`Renderer.frame` の整数カウンターへ代用しない。

Lua への接続を進める際は、ネイティブの「秒」の seek をそのまま旧 `frame` と称さない。旧 frame の再現が必要なら、Plus 実機または binding 実装による単位と境界の確認が先になる。

## 4. 独自メニューとツールバー

初期 GUI 自体を `scripts/gui_jp.lua` が作ることは文書に明記される（`D/editmenutoolbar.html:12`）。アクションは実行する Lua 文字列と状態を判定する Lua 文字列を持ち、同じオブジェクトをメニューとツールバーが共有する（同:14–23）。状態文字列を単なる boolean として登録する方式ではない。

|API|文書確定の契約|根拠|
|---|---|---|
|`GUI:addMenu(menu/title)`、`addToolBar(toolbar/title)`|既存オブジェクトの場合は同じものを返し、文字列の場合は新規オブジェクトを返す|`D/gui.html:103–117`|
|`MenuItem:addMenu(menu/title)`|子階層の追加、同様にオブジェクトを返す|`D/menuitem.html:12–17`|
|`MenuItem:addAction(action)` / `(title,script)` / `(title,script,updateScript)`|アクション共有、または新規作成して返す|同:18–26|
|`MenuItem:addSeparator/clear`|区切り追加、子項目を削除|同:27–32|
|`MenuAction.title`、`setIcon(filename)`、`setShortcut(key)`|titleは文字列。setIcon/setShortcutは自身を返しchain可能。アイコンはalpha PNG可|`D/menuaction.html:12–19`|
|`ToolBar:addAction(action)/addSeparator/clear/setIconSize`|アクション、区切り、内容削除、ピクセル単位の寸法|`D/toolbar.html:12–22`|
|タイトル内の `&`|続く文字を下線・親メニュー内の shortcut として使用|`D/editmenutoolbar.html:26`|

`D/editmenutoolbar.html:33–35` には `ToolBar:addAction(title,script)` の例もあるが、ToolBar の API ページは object 版だけを載せる。異なる掲載範囲を記録し、片方だけで完全な overload 一覧としない。

同梱 GUI は2本の toolbar を作り、24×24の icon を指定して menu action を共有する（`L/gui_jp.lua:240–262`）。macOS では既存 NSMenu/NSMenuItem と同じ action model を共有する設計が候補になる。ただし次は未確定であり、旧互換の完了条件に残す。

- updateScript の評価頻度、スレッド、例外時の表示、式末尾のセミコロンの評価方式。
- action 削除時に共有 toolbar が保持する参照の寿命、clear 後の Lua object の有効性。
- 同じ title / shortcut の重複、親の変更、GUI 再読み込み時の重複処理。
- Windows の mnemonic と macOS の command shortcut の対応、toolbar の移動・保存範囲。

信頼済み local Lua の実行許可は既にある。別途、イベント後も同じ Lua グローバル環境を保持する callback 実行モデル、停止・終了時の破棄、評価エラーの表示を定める必要がある。既存のファイル単位 helper が終了した後に文字列だけを残しても、同梱 script が定義した関数や変数は再現できない。

## 5. スクリーンメニュー

`ScreenMenu` は通常メニューとは別に、正面0度の角度、階層、選択、開閉を持つ。

|対象|文書確定の動作|根拠|
|---|---|---|
|`enter()`|閉じていれば表示。表示中なら選択項目を実行し、submenuなら子階層へ|`D/screenmenu.html:18–20`|
|`cancel()`|親へ戻り、rootなら閉じる|同:22–24|
|`up/down`|前後の項目を選択|同:26–30。端や空メニューの規則は未確定|
|`addMenu/addAction`|ScreenMenuItem / ScreenMenuAction の共有と文字列からの作成|同:32–46、`D/screenmenuitem.html:15–29`|
|`addMovies/addImages/addAudio/addCharts/addTitles`|各媒体の選択メニューを追加|同:47–61、`D/screenmenuitem.html:30–44`。媒体登録APIではない|
|`clear()`|内容の削除|`D/screenmenu.html:62`、`screenmenuitem.html:45`|

同梱 `L/screenmenu_jp.lua:2–6` と英語版では媒体の add 呼出しはコメントアウトされている。API が存在することと、現物の初期メニューに出ることを区別する。`ScreenMenu.onlyOnControler=true`（`L/option.lua:20`）と `isShown()`（`L/shortcuts_jp.lua:44`）は用例のみで、綴り・対象画面・setter の全契約は未確定。

平面上の階層リストと選択状態は実装単位として切り出せるが、角度位置、投影側への表示、立体視、controller限定表示まで対応したと表現しない。

## 6. HTML 説明・操作パネル

旧 UI Browser は単なる説明文ビューではない。文書は Internet Explorer 互換 HTML、JavaScript、Flash、オンライン URL、bookmark、および `mtkp://` リンクに埋めた Lua の実行を説明する（`D/uibrowser.html:12–22`）。ホームは `ui/index.html` で、`mitakaPlus.ini` の `homeUrl` を絶対/相対ローカルパスまたは URL に変更できる（同:24–26）。今回の `P` に `mitakaPlus.ini` は存在しない。

現物 `P/ui/index.html` は Shift_JIS 宣言（:5）、ローカル CSS（:9）、画像付き Lua 実行リンクと時刻・離着陸操作（:30–36）、外部 http リンク2件（:39–40）を含む。inline JavaScript / Flash の使用はこのページでは確認できない。`ui/scripts/` は `12constels.lua`、`eclipse_20090722.lua`、`eclipse_diagram.lua`、`orion3d.lua` の4本。

HTML の `images/...` は HTML 所在 `ui/` を基準に読む。一方リンクの `dofile('ui/scripts/...')` はアプリケーションルートを前提とする。HTML の URL 解決と Lua の作業ディレクトリを同一の基準にすると、既存 local 操作パネルが壊れる。

移植は次の単位に分けられる。これは旧動作の確定ではなく提案である。

1. ローカル説明 HTML/CSS/画像の読み取り表示。リンク先・壊れた資産を見える形で診断し、JavaScript、外部取得、`mtkp://` の自動実行は有効にしない。
2. 利用者が明示的に信頼したローカル操作パネルに限り、クリックした `mtkp://` の Lua を既存 helper へ渡す機能。HTML 自体の信頼範囲、遷移後の扱い、callback の実行環境を先に定める。
3. IE/Flash/オンライン実行の完全互換は別課題。今回承認済みのローカル Lua 実行からオンライン実行へ権限を拡張しない。

`System:openDocument(filename)` は既定アプリで文書を開く API（`D/system.html:55–57`）。同梱メニューは PDF と CHM を指定する（`L/gui_jp.lua:237–238`）。埋込み HTML と同じ API として処理しない。macOS の CHM 表示方法も別に必要となる。

## 7. 保存状態と編集ウィンドウ

|API|文書確定の内容|根拠|
|---|---|---|
|`State:set(string)`|文字列を **Lua として実行**|`D/state.html:12–14`|
|`get()` / `getStored()`|現在/保存済み状態を **Lua 文字列** で返す|同:15–17,24–26|
|`store/restore/canRestore`|内部保存、復帰、保存の有無を返すboolean|同:18–29|
|`storeAsInit/resetInit`|`state/init.lua` へ保存 / ファイル内容を空にする|同:30–35|
|`GUI:openStateDialog/saveStateDialog`|Lua状態ファイルの読込実行 / 保存|`D/gui.html:82–87`|
|`clearScript/saveScriptDialog/runScript`|編集内容の初期化 / ファイル保存 / 実行|同:88–99|

`D/gui.html:91–93` は編集用ロードの説明なのに `openStateDialog` を再掲する。これを根拠に、状態適用と編集ロードを同時に行う仕様や未確認の別メソッド名を発明しない。

現物には拡張子なしの `state/20151008` と `state/令和6年11月22日(金)` があり、いずれも106行の Lua。`state/init.lua` は0 bytes。両状態は日時、表示フラグ、天体集合、カメラ、媒体選択等を保存するが、全プロパティの serialization 仕様を証明するものではない。

- :79–86 は target、forceMode、quaternion、zoom、azimuth、altitude、fov、traceTarget。2015年ファイルの target は `Planet.Earth.Place_3`、2024年は `Planet.Earth`。独自場所や当時のIDを切り捨てない。
- :95–102 は Movies/Audio/Charts の `name=0` と Images の `index=0`。文書の name:string と異なる。数値nameの暗黙変換規則は未確定。
- :103–106 は input help / fontScale / fadingDuration / FPS。Titles、媒体 transform、媒体再生位置、GUI menu定義はこの2状態には見つからない。
- `L/init.lua:1–8` は GUI、screenmenu、shortcuts、layouts、quadraopt、option と `state/init.lua` を順に実行する。ネイティブにこの連鎖を追加すると単なる状態ロードを超えるため、自動有効化しない。

型付き JSON の保存・pause復元は現行ネイティブの契約であり、Lua文字列を返す旧 `State` と同じではない。対応するなら登録済み API だけで再適用可能な Lua の生成範囲、旧非対応項目の診断、内部buffer未設定時の動作を定める。Lua内restoreとGUIからのrestoreではhelper cancelの扱いも分ける必要がある。

`storeAsInit/resetInit` は原本書込みと衝突する。原本を保持したまま app の利用者領域に初期状態を保存し、読み先を明示する設計が候補だが、旧ファイルを直接更新する完全同一動作とは記載しない。自動実行を望む場合は既存の明示実行許可とは別に確認する。

## 8. 入力マッピング

|API / 値|文書確定の契約|根拠|
|---|---|---|
|`Input:addShortcut(key,bRepeat,script,description)`|文字列3つとboolean、成功booleanを返す。repeat=trueは押し続けで連続実行|`D/input.html:12–14`|
|`removeShortcut(key)`|成功boolean|同:16–18|
|`getShortcut(index)`|キー名と説明の文字列2つ。indexは **0始まり**|同:20–22|
|`getNumShortcuts()`|登録件数の整数|同:23–24|
|`left/right/up/down`|視野回転またはメニュー選択|同:26–37。入力対象の優先順位は未確定|
|`zoomUp/zoomDown/rollLeft/rollRight/close`|視野・距離・roll操作、表示画像やmenuの取消|同:38–52。媒体 transform の座標単位は決まらない|
|`orientSpeed/zoomSpeed/rollSpeed/pointerSpeed`|実数の速度倍率、1が標準|同:53–64|
|`inertiaThreshold`|整数 **ms**、文書標準10、大きいほど慣性が起きやすく0で無効|同:65–66|
|`helpInfo/toggleHelpInfo`|shortcut一覧の表示|同:68–74|

`bRepeat=false` は API 文書で「キーを離すごと」と書かれるが、編集説明では押したときの操作として説明される。keyDown / keyUp の正確な発火時点、OS key repeat 依存、repeat間隔は断定できない。

`D/editshortcuts.html:15–22` は SHIFT/CONTROL/CTRL/ALT/META、英数字、矢印、function、数値キー、LBUTTON/MBUTTON/RBUTTON、JSBUTTON を列挙する。`RIHGT` や joystick2にJSBUTTON1を重ねる等の誤記があるため、そのまま追加 alias としない。同梱 Lua は正しく `RIGHT` を使う。

現物は言語別の差と変更を含む。

- `L/shortcuts_jp.lua:41,43` の X/ENTER は Movies toggle と ScreenMenu enter を順に両方呼ぶ。排他的な「menu またはmovie」とは書かれていない。
- :44 の ESC は `ScreenMenu:isShown()` によって `Scene:toggleMode()` と cancel を分ける。両者は API 文書未掲載。
- :59–64 の title / pointer / cityLight / F1 はコメントアウト。:65 の TAB は独自 `togglePointer()` を呼ぶ。英語版は `Desktop.pointer`、日本語版は Pointer と Targets を使い、同一処理ではない。
- :68–79 は ELECOM PS2/USB用の有効設定。:79 の JSBUTTON12 は script と説明が逆順で、実行文字列に日本語説明が入る。原本を黙って修正せず、ロード診断で場所と原因を出せる必要がある。
- :81–105 の SANWA/Logicool例はコメント、:108–119 の WIIMOTE系は有効。WIIMOTE 名は1.3 API文書に列挙されない。macOS機器とのbutton番号・axis・deadzone・接続方法は未確定。
- `L/option.lua:3–7` は回転/roll/zoom倍率0.5、flightSpeed1、inertia150を設定する。文書標準値と現物初期設定を分ける。flightSpeed の単位は未掲載。
- 通常 menu action の `setShortcut` と `Input:addShortcut` が同じキーに登録されたときの優先順位、編集テキスト入力中の扱い、アプリ非active時の扱いは未確定。

## 9. 次の移植単位と未解決の判断

以下は作業提案であり、実装済み一覧ではない。実装状態はルートの対応表で管理する。

|単位|資料から定義できる入口|完了とする前に必要な検証・判断|
|---|---|---|
|UI action model と local menu/toolbar|共有action、タイトル、icon、実行/状態スクリプト、追加/clear|同じLua環境の寿命、cancel、例外、重複、clear後参照、check表示、再ロード、既存nativeメニューとの共存|
|スクリーンメニュー|階層・enter/cancel・選択状態|空/1件/端/子削除、対象画面、角度と描画位置。未確定の投影仕様は明記|
|登録shortcutとhelp一覧|0始まり列挙、追加/解除、説明表示|入力の発火時点とrepeat契約、文字入力の競合、keyup欠損、非active解除、機器番号の実機確認|
|ローカル説明HTML|HTML/CSS/画像を読み取り表示|Shift_JIS、相対資産、リンク遷移、外部取得をしないこと、JS/schemeの不実行|
|明示的に信頼するlocal HTML操作パネル|既存 `mtkp://` Lua 文字列と `dofile`|信頼対象を選択ページだけ/指定ディレクトリ全体のどこまでにするか、遷移時失効、実行環境の共有。オンライン実行は禁止を維持|
|旧Stateの部分互換|サポート済み属性からLua文字列を生成・buffer保持|対象範囲、再適用、未知属性診断、元データ不変、helper自己cancelを起こさないこと|
|原本外の初期状態|利用者領域へ保存する案|`storeAsInit/resetInit` の書込み先と自動実行の希望。原本内ファイルを変更する案は採らない|
|画像合成・媒体Lua制御|画像選択/表示とnative previewの継続改善|旧位置・倍率・frameの単位未確定。独自native契約を使う場合は名前と対応範囲を明示し、完全互換扱いしない|
|高度なScene/layout、音声mixer、旧renderer|同梱用例の保持と未対応診断|原典の詳細仕様またはPlus実機観測が必要。未知objectを無処理で成功させない|

ユーザーは信頼するローカル Lua の旧 Plus 相当権限と、独自ローカルデータ優先を承認済みである。この判断を再質問しない。新たな確認候補は **local HTML のどこまでを実行可能と信頼するか** と **保存状態を起動時に自動実行したいか** に限定できる。読み取り表示、既存データの保全、未対応の診断はこの回答を待たず進められる。

## 調査の限界

Plus バイナリの動的観測・逆アセンブル、IE/DirectShow/irrKlang のランタイム動作、実機controller入力は未実施。確定できなかった仕様を通常版ソースや現在のネイティブ実装から補ってはいない。この調査とは別に実施したネイティブ画像プレビューの controls 配置・境界 clip 修正は、旧画像単位や描画領域を確定するものではない。
