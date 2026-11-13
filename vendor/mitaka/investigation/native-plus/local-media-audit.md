# ローカル Plus の媒体機能調査

調査日: 2026-10-29。これは原本の読み取り調査であり、媒体機能の実装完了報告ではない。実行ファイルの起動、媒体の変換・再保存、登録ファイルの修正、外部への再配布は行っていない。

## 原典と適用範囲

以下では `P` を `PLUS_ROOT` とする。`P/...:行` は原本の改行を維持してデコードした位置、PDF のページは印刷ページと一致する。

|原典|確認した版・制約|
|---|---|
|`P/ReadmeWin_J.txt:3`|Mitaka Plus Windows 1.5.4 build101013。今回の互換対象|
|`P/doc/script_jp/contents.html:17`|Lua API 文書は 1.3.0、2007-12-23。1.5.4 の全挙動を保証する版ではない|
|`P/mitaka_manual_J.pdf:1`|通常版 Mitaka 1.2.1、2012-06-24。Plus 専用説明書ではない。ローカル `.mvp` 登録を説明する参考資料として使用|
|`P/history_J.txt:5–20`、`P/mitaka_pp_history_J.txt:5–36`|通常版 1.2.1a と Mitaka++ 1.3.1 の履歴も混在。後者はタイトル等の一部が多言語化未対応と記載|
|`sources/official/mitaka_source/Mitaka/mtk_movie.cpp:452–539`|通常版の公開ソース。新しい `.mif` のキー形式を読むため、旧 `.mvp` / 5 列形式の代用品にはしない|

フォルダには通常版・Plus・Mitaka++ の実行ファイルと設定が混在する。ファイルの存在だけで Plus 1.5.4 が採用する設定・文字コード・フォーマットを断定できない。以後「文書上」「現物」「未確定」を区別する。

## 探索ルートと登録

`P/mitaka.ini:37–42` は `Data=./data/`、`Textures=./textures/`、`Media=./media/`、`Spacecraft=./spacecraft/`、`Title=./title/` を指定する。`mitaka_pp.ini:35–40` も同じ。PDF p.43 §5.3.5 に同じディレクトリ設定がある。Plus がどちらの INI を読んで優先するかは今回の資料だけでは確定しない。

PDF p.52–53 §5.5 の旧登録形式は次の通り。

- `media/movies.dat`、`media/images.dat`、`media/audio.dat` は任意ファイル。1 行が 1 登録で、空白またはタブ区切りの 5 列: `mvp1 mvp2 type menu_title display_title`。
- `mvp2` は将来拡張用で、同じ `.mvp` を指定する。文書にある type は `M` 動画、`I` 静止画、`A` 音声。メニュー名には空白を含めない。画像の表示タイトルは画像の上に表示し、`{文字|よみ}` のルビを使用できる。
- `.mvp` は 1 媒体の各 PC 用パスを 1 行ずつ並べる。`servers.dat` の順番の後に、コントローラ PC のパスが最後に来る。複数行は連続再生や画像シーケンスではない。
- PDF は絶対 Windows パスを例示するが、ローカル 9 個の `.mvp` はすべて `./images/...` 相当の Windows バックスラッシュ相対パス。実配置からアプリケーションルート基準と整合し、`media/` 基準ではない。
- PDF のネットワーク説明では各 PC が媒体を独立して読み、再生中に媒体データをネットワーク送信しない。今回のローカルには `servers.dat` がない。

現物の `media/` は 11 ファイル、1,598 bytes。9 個の `.mvp` と 2 個の画像登録だけで、`movies.dat` / `audio.dat` はない。`images.dat` は CP932、`images_list.dat` は UTF-8 で、正しくデコードした本文は改行も含め完全一致する。両方を連結すると同じ 9 件を二重登録する。Plus が採用するファイル名・優先順位・両方存在時の規則は未確定。

`media/images.dat:1–9` と `images_list.dat:1–9` の全登録は以下。順番を API index と同一とは未確定のため、表の番号は登録行番号とする。

|行|メニュー名 / type|`.mvp` 内の参照（`P/` 基準）|現物の一致状態|
|---|---|---|---|
|1|天文単位 / `P`|`images/AU.jpg`|欠損。`AU（１天文単位）.jpg` が存在するが同一媒体との自動判定は不可|
|2|光年 / `P`|`images/ly.jpg`|欠損。`ly（１光年）.jpg` が存在するが自動置換しない|
|3|火星大接近 / `I`|`images/Mars.jpg`|欠損。`Mars（火星の軌道）.jpg` が存在するが自動置換しない|
|4|すばる / `I`|`images/M45.jpg`|実名は `m45.jpg`。現在のファイルシステムでは開けるが、大文字小文字を区別する環境では一致しない|
|5|球状星団M13 / `I`|`images/M13.jpg`|実名は `M13.JPG`。同上|
|6|天の川 / `I`|`images/MilkyWay_Mellinger.jpg`|完全一致。`.mvp:1–2` に同一パスが 2 行|
|7|アンドロメダ銀河 / `I`|`images/M31.jpg`|完全一致|
|8|星形成領域S106 / `I`|`images/S106.jpg`|完全一致。`.mvp:1–2` に同一パスが 2 行|
|9|オリオン星雲 / `I`|`images/Orion.jpg`|完全一致。`.mvp:1–2` に同一パスが 2 行|

type `P` はこの PDF の 3 種類の表にない。公開通常版ソースに `PopupImage` は存在するが、これを Plus の `P` の意味・配置へ直結させる根拠は不足している。パーサーは未知 type を落とさず保持し、表示の実装契約と旧互換の確定を分ける必要がある。

## 画像と独自追加の保全

`P/images/` は 15 ファイル、2,988,952 bytes。上表に関係する 9 画像に加えて `IMG_4936.JPG`、`hp（彗星）.jpg`、`syasinn.png`、`惑星の温度.jpg`、`無題.png`、`Thumbs.db` がある。これら追加名は今回検索したテキスト登録・Lua・INI・HTMLから参照を確認できない。未登録画像を自動登録する仕様も確認できない。

アプリケーションルートにも `capture.png`、`kasei.jpg`、`taiyou.jpg`、`冥王星　ニューホライズンズ.jpg`、`冥王星　画像.pptx` 等がある。最後の 2 名前の実ファイルは macOS の分解 Unicode を含む。媒体ファイルを見つけたという事実と、Plus の登録対象であることは別である。

利用者は独自データがあると明示済みだが、今回のローカル一式と未改変配布物を比較していないため、どの画像が利用者作成・改名かは断定しない。全ファイルと登録順を保全し、欠損を公開データで補充したり、候補画像で黙って差し替えたりしない。

動画・音声については `P` 配下を拡張子 `.avi .wmv .mp4 .mov .mkv .mpeg .mpg .mp3 .wav .ogg .wma .mid .midi .m4a .aif .aiff .flac .aac .webm` で調べた範囲に実ファイルはなかった。別フォルダ・拡張子のないファイル・外付け媒体まで存在しないという意味ではない。

`ReadmeWin_J.txt:165–177` は FFmpeg、irrKlang 等を列挙し、ルートに `avcodec-51.dll`、`avformat-51.dll`、`avutil-49.dll`、`irrKlang.dll`、`ikpMP3.dll` がある。利用可能な codec・container の組合せ、音声出力の挙動、正確なシーク精度はこの情報だけでは確定しない。

## API と端の動作

|オブジェクト|文書上のプロパティ / メソッド|原典|
|---|---|---|
|Movies、Audio|`visible`、`toggle()`、相互連動する `name` / `index`、`play()` / `pause()` / `playing` / `togglePlaying()`、書込可能な `frame`、読取専用 `frameLength`、`prev()` / `next()` / `first()` / `last()`|`doc/script_jp/movies.html:12–57`、`audio.html:12–57`|
|Images、Charts、Titles|`visible`、`toggle()`、相互連動する `name` / `index`、`prev()` / `next()` / `first()` / `last()`|各 HTML:12–37|
|ScreenMenu / ScreenMenuItem|`addMovies`、`addImages`、`addAudio`、`addCharts`、`addTitles` が選択メニューを作る。媒体ファイル登録 API の説明ではない|`screenmenu.html:47–61`、`screenmenuitem.html:30–44`|

`Movies.frame` / `Audio.frame` は単に再生位置、`frameLength` は長さと記載される。単位（秒、サンプル、映像フレーム、内部 timebase）、整数性、fps、負値、範囲外値の扱いは記載がない。`frame=0` と `frame=frameLength`、全長の `1/10` 移動は同梱スクリプトに実例があるが、終端で最終画面を表示するか、再生終了位置かは不明。

`prev` / `next` は前後を選択し `name` / `index` が変化するという説明だけである。先頭の `prev`、末尾の `next`、空リスト、未知名、重複名、不正 index、選択変更時の再生位置・再生状態・表示状態の挙動は未確定。Movies / Audio / Images の index 起点も明記されない。`Audio.visible=false` がミュート・停止・一時停止のどれを意味するかも説明がない。

文書には転記誤りがある。Movies / Audio の見出しは `plaing` だが例は `playing`、`next` / `first` の例が `prev`、一部 anchor も重複。`screenmenu.html:56` の見出しは `addAudio` だが例は `addCharts`。誤記を別 API として実装しない。

## 表示位置・座標と操作の範囲

- 画像の登録には位置・幅・高さ・回転・不透明度の列がない。API 文書にもこれらのプロパティはない。PDF p.53 はタイトルを画像上方に置くとだけ説明する。既定配置、アスペクト比、crop、z 順、stereo、複数同時表示は未確定。
- PDF p.14 §2.5 は画像 / 3D chart の `O` / `P` による左右移動、`Z` で閉じる操作を説明する。Plus の active Lua で同じ移動処理を確認できたわけではない。座標量・境界・スクリーン座標か空間座標かは不明。
- PDF p.42–43 の一般表示設定は `ScreenZ=217.3 cm`、`ScreenW=180 cm`、`ObjZ=400 cm`、`TitleWidthRatio=1.0` 等。これは物理スクリーン / 視点の設定であり、画像 API のピクセル座標と置き換えられない。ローカル値は `mitaka.ini:15–25`。
- PDF p.13–14 §2.4 には movie 再生/停止 `X`、閉じる `Z`、先頭 `1`、最後 `2`、全長の ±1/10 を `3` / `4`、±1/50 を `O` / `P`、移動はポーズ中のみとある。通常版の操作説明であり、Plus API の setter 制約の根拠にはしない。

`scripts/init.lua:1–8` は言語別 `gui` / `screenmenu` / `shortcuts` を読み込む。`scripts/screenmenu.lua:2–6` と `screenmenu_jp.lua:2–6` の媒体メニュー追加はすべてコメントアウト済み。現物の GUI が媒体メニューを公開しているとは断定できない。

`shortcuts.lua:41,43,68,107` と日本語版の相当行には `Movies:togglePlaying(); ScreenMenu:enter();` がある。英語版 :72–77 は movie の ±1/10、先頭、最後、タイトル表示を登録するが、日本語版 :72–78 は ±1/10 の実装が時刻操作に置換され、先頭 / タイトルはコメントアウトされている。`frame=frameLength` は日本語版でも有効。説明文だけを使って active 操作を判定しない。

`state/20151008:95–102`、`state/令和6年11月22日(金):95–102` と `ui/scripts/eclipse_diagram.lua:92–99` 等は `Movies.name=0`、`Audio.name=0`、`Charts.name=0`、`Images.index=0` を保存する。API の name=文字列という記述と相違するため、数値 name の暗黙変換規則をこの例だけから決めない。

## Charts と Titles

`charts.html:21` は name の説明内に 0=太陽系の惑星、1=太陽系外縁天体、2=星の色と温度と列挙する。PDF p.33 §4.4 も同じ 3 図を説明する。前二者は大きさ比較、最後は色と温度の関係。旧版の正確な天体一覧・半径・配色・配置・倍率・操作は API にない。外部 chart 登録ファイルも今回の媒体フォルダでは確認できない。

`titles.html:24` は 0=クレジット、1=諸注意、2=国立天文台 4 次元デジタル宇宙シアターのタイトル、3=上映タイトル。name の例 `Credits` 以外の全名称、言語ごとの検索名、上映タイトルの登録方式は未確定。

`P/title/` は 13 ファイル、148,261 bytes。日英 PNG 2 枚、`caution_E/J/JR.txt`、`credit_E/J.txt`、`credit_roll_E/J.txt`、`theater/` 配下の `credit_E/J.txt` と `credit_roll_E/J.txt` がある。

- `mitaka.ini:130–134` に日英 title PNG、`TitleDuration=0.6`、`TitleZPosIni=0.1`。PDF p.48 はフェードしながら標準位置へ移る、奥行き正方向は手前、PNG alpha を使用可能と説明する。`TitleZPosIni` と時間の正確な単位は同表にない。
- `mitaka.ini:137–143` は `credit_roll_J/E.txt`、幅 180、DY -80、Duration 3、Angle 0。PDF p.48 は幅 / DY が cm、上が正、Angle が度、左右軸の倒し角と説明する。Duration は全体表示時間だが単位欄は `-`。これを native の秒に換算する規則は未確定。
- テキストは `\Center` / `{...}`、`\Size[...]`、`\Vspace[...]`、`\Color[...]`、`\\`、`\Table[...]`、`\c`、`%` コメント、ルビを含む。例: `caution_J.txt:1–11`、`credit_J.txt:2–30`、`theater/credit_J.txt:116`。構文の存在と引数の完全な文法・座標系は別である。PDF p.48 は当時この文法を開発中・非公開としている。
- `caution_J.txt` / `caution_JR.txt` / `credit_J.txt` / `theater/credit_J.txt` は有効な UTF-8、`credit_roll_J.txt` / `theater/credit_roll_J.txt` は CP932。登録と同様、単一文字コードを全ファイルへ仮定しない。

## 次の実装に必要な契約と判断

以下は未実装機能の提案であり、旧 Plus の確定仕様ではない。ユーザーは信頼するローカル Lua に旧 Plus 相当の権限を認め、既存独自データを優先すると回答済み。この許可を理由なく再質問しない。

|課題|現時点で可能な進め方|追加の判断が必要になる条件|
|---|---|---|
|改名された 3 画像|登録を欠損のまま保持して診断し、利用者が選択したローカルファイルとの対応を原本外・メモリ上で設定|どの候補が意図した媒体かは資料で決められない。必要時にファイル選択で確認する|
|2 登録ファイルの優先順位|`images.dat` を優先し、代替と不一致を診断する新契約を明記。全登録と未知 type を保持|厳密な Plus 同一挙動を要する場合は原版 loader の追加調査|
|`P` と配置、frame、前後境界|未知を明示し、通常の画像表示や native 操作を別契約で追加可能|旧挙動の完全互換を主張する前に Plus の実装・実機観測が必要|
|動画 / 音声形式|利用者指定のローカル媒体を native SDK で開き、非対応は原因を表示|既存 SDK で扱えない具体的媒体が出た場合に codec 依存追加か対象形式制限を選ぶ。無断変換はしない|
|絶対 Windows / UNC / URL パス|raw を保全し、ローカル選択で解決。ネットワーク媒体・URL を自動取得しない|旧ドライブ対応、ネットワーク共有や URL 自動接続が必要なら接続範囲を確認する|
|3D chart と title text|確定した項目を一覧化し、未対応を表示|正確な旧レンダリングが必要なら追加仕様調査。独自 chart / title 登録があれば実物を優先する|

境界テストは 0 件 / 1 件 / 全 9 件、独自追加、未知 type、CP932 と UTF-8、重複登録、欠損 `.mvp` / 媒体、大文字小文字、分解 Unicode、複数 PC 行の末尾選択、`..` / 絶対パス / UNC / URL、壊れた画像、選択取消、閉じた後の再表示を対象にする。前後境界や frame は採用した新契約と、未確認の旧互換を分けて検証する。

## 再確認用 fingerprint

原本の SHA-256。原本の変更や再保存は行っていない。

```text
a3549a1d491be012e63e7c5dc62c393bfbfb0ab10e251f7d8545b4ccdda37643  ReadmeWin_J.txt
c176cf9b8c37b2d14f8da89845783914ee10a2c281f781e5912cafd99debcfb6  doc/script_jp/contents.html
bc95c24fec9e41d8c9a87e07115b01a875d3907003742d9ca19f592eb8c9f7dc  doc/script_jp/movies.html
cd8873c3515c08c753cfd4e7da7c0e0f9451731c1783ab05ea9fa14600748a43  doc/script_jp/audio.html
4717ebce4d2414ef4bfd12c1a81aba9248fa72fc68151a3178432fb446e39776  doc/script_jp/images.html
946d310fad2e6b2df46b1876707ff1a1dac37274e2f046d7f97973467891a544  doc/script_jp/charts.html
44c0954f2ad0b8ed28a6eb3497a0ed69ebe9c27929695e32481322adc43ffce6  doc/script_jp/titles.html
d5399ef5b460c3c9effa738639f8634a02aa1b94593284f618aaa26d016189c6  media/images.dat
f971d5938fa2539586f4a37f15880ec3965f688c052c950ecc783ab6583d6776  media/images_list.dat
947cc3e147df367b2858d4c1eaa8c86c0f397068f018045de4c6f47e67b049cc  mitaka_manual_J.pdf
```
