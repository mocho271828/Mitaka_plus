# 彗星・衛星の旧Lua APIと識別子

旧 Plus のメニューと説明書、および同名行の識別に使用するデータを示す。現在使える API は [Lua ガイド](../../../native/gui/SCRIPTING.md) に記載する。

## 確定した Lua 表面 API

`D/comets.html` と `D/satellites.html` は同じ行構成で、それぞれ `Comets` / `Satellites` を公開する。以下の `M` はこの二つの名前のいずれかを表す説明用記号であり、新しい Lua オブジェクト名ではない。

| 元ファイル行 | API | 引数・値・意味 |
| --- | --- | --- |
| 12–19 | `M.visible` / `M:toggle()` | 読書き boolean。天体群の表示・非表示。toggle はそのプロパティを切り替える。 |
| 20–27 | `M.labels` / `M:toggleLabels()` | 読書き boolean。天体名の表示・非表示。 |
| 28–35 | `M.orbits` / `M:toggleOrbits()` | 読書き boolean。軌道線の表示・非表示。 |
| 36–43 | `M.selectedOnly` / `M:toggleSelectedOnly()` | 読書き boolean。群のうち一部のみを表示する設定。`visible == true` の場合に有効。 |
| 44–47 | `M:show(names)` | 固有英語名を空白区切りにした一つの文字列。表示する天体を指定する。 |
| 48–51 | `M:hide(names)` | 同形式の文字列。指定した天体を表示対象から外す。 |
| 52–55 | `M:isVisible(name)` | 固有英語名一つの文字列。指定天体が表示される場合に boolean `true` を返す。 |

toggle / show / hide の戻り値は説明されていない。受理成功を表す `true` を原版の戻り値として追加しない。boolean 以外の代入を Lua がどう変換したかも未確定で、native の strict boolean 検証とは区別する。

`selectedOnly` は現在のクリック選択一件と同義ではない。`P/scripts/gui_jp.lua:117` は衛星側を「主な衛星のみ」と表示し、`P/ui/scripts/eclipse_20090722.lua:23–28` はこの flag を有効にしたうえで多数の衛星を `show` に渡す。彗星側も同ファイル `47–52` で二つの名前を渡す。単一の `selectedSatelliteIndex` / `selectedSmallBodyIndex` をそのまま表示集合に使う実装では、この用例を満たさない。

種類は別オブジェクトで分かれている。`D/asteroids.html:44–55` の `Asteroids` と `D/tnobjects.html:52–63` の **`TNObjects`** は名前または小惑星番号を文字列で受け取るが、`Comets` / `Satellites` には数値 ID・`type`・`kind` プロパティの記載がない。`MinorPlanets` / `TNOs` などの未確認 alias を公開しない。Lua 管理名 `TNObjects` と target 接頭辞 `TNO.` も別である。

## 同梱 UI と実例

| 原本位置 | 観測 |
| --- | --- |
| `scripts/gui.lua:113–117`, `gui_jp.lua:113–117` | 衛星の四つの toggle を呼び、対応 property をメニュー状態の式として読む。 |
| 同 `134–138` | 彗星の四つの toggle と property を使う。 |
| `scripts/screenmenu.lua:36–40,56–60` と `_jp` 版 | 同じ四状態を画面内メニューから扱う。 |
| `scripts/shortcuts.lua:20` と `_jp` 版 | `Satellites.labels = flag` を使う。 |
| `ui/scripts/eclipse_20090722.lua:27–28` | `Satellites:hide("All")` の後、`Moon Phobos Deimos ...` のリストを `show`。リスト中の `Rhea` は二回ある。 |
| 同 `51–52` | `Comets:hide("All")` の後、`Comets:show("Holmes Hale-Bopp(1995O1)")`。 |
| `ui/scripts/eclipse_diagram.lua:23–28,47–52` | 上記と同じ表示設定とリスト。 |

`hide("All")` は実在用例であり、互換実装で必要になる。ただし資料だけでは `show("All")`、`isVisible("All")`、`All` と個別名の混在、大小文字の扱いまで確定しない。`D/comets.html:46,50` の例は `Hale-bopp` だが、上記実スクリプトと個別原本は `Hale-Bopp(1995O1)`。この表記差を case-insensitive lookup や alias の証拠にしない。

## target 名・選択 API と原本 ID

| 原本位置 | 確定した契約 |
| --- | --- |
| `D/abouttargets.html:23–25` | `Satellite.<衛星英語名>`。例は `Satellite.Moon`, `Satellite.Phobos`。 |
| 同 `29–31` | `Comet.<固有英語名>`。`data/orbits/comets/*.dat` の定義名。例は `Comet.Holmes`, `Comet.Hale-Bopp(1995O1)`。 |
| `D/camera.html:105–108` | `Camera.target` は target 名文字列。距離調整は `zoomMode` に従う。 |
| 同 `109–112` | `Camera:setTargetTo(targetName, duration)` は実数秒のアニメーション。省略時は `Camera.duration`。即時 focus の alias ではない。 |
| `D/targets.html:15–20` | `Targets:select(x,y)` は整数画面位置、`Targets:select(targetName)` は名前で選択。戻り値は未記載。 |
| `scripts/gui.lua:42–43` と `_jp` 版 | `Camera:setTargetTo('Satellite.Moon')` / `Satellite.Io` と `Camera.target` の比較。 |

`Targets.selectMode` は `D/targets.html:12–14` に列挙定数があるが、数値値はこの資料では分からない。HTML anchor の `Targets_getId` という名前は `selectMode` 見出しに付いた ID であり、公開 `Targets:getId()` メソッドの根拠ではない。

### 彗星の名前の衝突

`P/data/orbits/comets/hale-bopp.dat:3` と `hale-bopp_jp.dat:3` は同じ `Name: Hale-Bopp(1995O1)`、`holmes.dat:3` と `holmes_jp.dat:3` は同じ `Name: Holmes`。表示名は各 `:4` で異なり、Holmes の要素も `:5–10` で一部異なる。二言語版を上書き統合したり、一方を「同じ行」として捨てたりしない。

一方 `P/data/comets.dat:20` は `17P/Holmes`、`:786` は `C/Hale-Bopp (1995 O1)` という別の名前を持つ。値の一致する項目があっても、個別定義の `Comet.Holmes` をこの JPL 行へ差し替える契約は見つからなかった。個別ファイル四件は現コアでは参照面・時系等が未確定で位置を返さないため、名前だけ解決して `Camera.target` を成功扱いにしてはいけない。

native の `SmallBodyId {source_key, record_ordinal}` と原 bytes 保持契約は `native/core/include/mitaka/small_body_catalog.hpp:29–34,48–59,78–80`。これはネイティブ内部の出典識別であり、旧 Lua にこの tuple を渡せた証拠ではない。

### 衛星の同名と言語別 source

`P/data/ssystem.dat` / `ssystem_jp.dat` は各 170 個の `Satellite` ブロックを持つ。各ファイルの `Name` 先頭 token は 168 種類。`Moon` は両方 `:39`、`Phobos` `:60`、`Deimos` `:71`、`Io` `:133`、`Charon` `:1795` であり、日本語版も同じ英語 token の後に日本語表示名を持つ。

同一 source 内にも `Rhea` が `:914,925`、`Proteus` が `:1693,1703` と二回ある。Rhea の先行定義だけには `Visible: 1`（`:920`）があるため、重複名を一つに減らすと保持情報が変わる。この値が旧 Lua の selected set 初期値に直結するかは未確認。

native の選択は records vector の行 index、元定義は `SatelliteRecordId {source_key, record_ordinal}` で保持する。`native/core/include/mitaka/satellite_model.hpp:40–60,63–74,100–111` は source ごとに分離した登録と先頭 token を明記する。`native/gui/src/satellite_browser_model.mm:50–72,90–101` は全 source の行を保持し、出典と ordinal を表示する。原版の起動時言語選択・読み込み順が未確定なので、この全集合から最初の名前一致を採る処理を旧 `Satellite.<name>` 互換と称することはできない。登録モデルの同名処理は Lua lookup の証拠でもない。

### 原版の局所静的追跡で追加確認した範囲

| 仮想アドレス | 確認内容 |
| --- | --- |
| `0x652870–0x652ae0` | `Satellites` のプロパティとメソッド登録列 |
| `0x6522c0`, `0x652350`, `0x6523e0`, `0x652510` | 四つの toggle の wrapper |
| `0x652530 → 0x5d9de0 → 0x55bac0` | show の wrapper と管理処理。wrapper の Lua 戻り値数は 0 |
| `0x652560 → 0x5d9e00 → 0x55c700` | hide の wrapper と管理処理。wrapper の Lua 戻り値数は 0 |
| `0x652590 → 0x5d9e20 → 0x55d340` | isVisible の wrapper と単一名照会。Lua boolean 一つを返す |
| `0x55bd3e`, `0x55bd89` / `0x55c97e`, `0x55c9c9` | `All` 経路で登録列の対象 bit をそれぞれ設定／解除するループ |
| `0x55d49b`, `0x55d4d0` | isVisible は未知名で false、名前一致時は対象 bit を返す。全体の visible / selectedOnly を読む経路ではない |

この局所追跡では登録済み container 内の処理までを確認した。起動時の出典・言語選択、引数変換関数の厳密な型規則、空白の全範囲などは未確定である。表示集合照会の性質が分かっても、全出典を保持する native モデルに旧名をどのように束縛するかは決まらない。個体別の旧 Lua 名指定 API は未対応。`Satellite.Moon` は従来の太陽・惑星・月の経路を変更していない。
