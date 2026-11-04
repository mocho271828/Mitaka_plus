# UNIT5: 彗星・衛星の Lua 接続契約監査

## 対象と証拠の範囲

初回監査は 2026-10-29、UNIT4 統合前の作業ツリーを対象にした。HEAD は `cf4fcbfe5447adf554e5bca0b0caf5ae5f529505` で、初回の native 参照は未 commit の UNIT4 変更を含む。以下は当時の監査結果を残し、末尾の「UNIT5 実装追補」で現在の対応範囲を区別する。原本は変更していない。

- `P` = `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`
- `D` = `P/doc/script_jp`。CP932 で復号した元ファイルの行番号を使う。
- 同梱スクリプト説明は Plus 1.3.0、実行ファイルは Plus 1.5.4 build 101013 の資料であり、全 API の同一性を前提にしない。版の区別は [次単位一覧](../unit4/next-feature-units.md) を参照。
- 彗星の座標・軌道計算の成立条件は [コア出典記録](../../../native/core/SMALL_BODY_PROVENANCE.md)、衛星の登録・同名保持は [登録モデル出典記録](../../../native/core/SATELLITE_MODEL_PROVENANCE.md) を参照する。Lua の名前解決を、それらの内部登録処理から推測しない。

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

同一 source 内にも `Rhea` が `:914,925`、`Proteus` が `:1693,1703` と二回ある。Rhea の先行定義だけには `Visible: 1`（`:920`）があるため、重複名を一つに減らすと保持情報が変わる。この値が旧 Lua の selected set 初期値に直結するかは今回未確認。

native の選択は records vector の行 index、元定義は `SatelliteRecordId {source_key, record_ordinal}` で保持する。`native/core/include/mitaka/satellite_model.hpp:40–60,63–74,100–111` は source ごとに分離した登録と先頭 token を明記する。`native/gui/src/satellite_browser_model.mm:50–72,90–101` は全 source の行を保持し、出典と ordinal を表示する。原版の起動時言語選択・読み込み順が未確定なので、この全集合から最初の名前一致を採る処理を旧 `Satellite.<name>` 互換と称することはできない。登録モデルの同名処理は Lua lookup の証拠でもない。

## 初回監査時の native との接続差分

| 現コード | 状態と接続前の条件 |
| --- | --- |
| `native/gui/src/ScriptWorker.mm:393–398` | `Comets`, `Satellites`, `Targets` は未登録。実装できた member だけ登録し、未対応を成功する stub にしない。 |
| `native/gui/src/AppScripting.mm:8–10,30–31,183–192` | target 対応は Sun / 9 Planet / `Satellite.Moon` の 11 名。追加一覧の行は未接続。snapshot は追加行に対する名前をまだ持たず、既定 `Sun` が残るため、target 拡張時には getter の状態モデルも同時に直す必要がある。 |
| `native/gui/src/SolarSmallBodies.mm:10–17`, `AppSmallBodyCommands.mm:18–24,38–52` | 小惑星・TNO・彗星をまとめた表示 bool。`Comets.visible` へ直結すると他 kind まで変わる。kind ごとの独立設定が先に必要。 |
| `native/gui/src/SmallBodyRenderer.mm:34–57` | 点と選択行の label を描く。彗星 labels / orbits / selected set は未実装。 |
| `native/gui/src/SolarSatellites.mm:11–18`, `SatelliteRenderer.mm:35–55` | 衛星全体の表示 bool と選択行の label。独立 labels / orbits / selected set は未実装。 |
| `native/gui/src/SolarSmallBodies.mm:35–66`, `SolarSatellites.mm:42–73` | 原行選択と評価可能位置への即時 focus はある。未知位置では camera を維持する。名前解決・アニメーション・旧 zoomMode はこれだけでは満たさない。 |

`Satellite.Moon` は既存の 11 天体経路にあり、新衛星一覧には二つの source の Moon 行もある。Moon の既存選択・描画・Planets の表示設定と、追加衛星管理設定の対象範囲を整理しないまま名前を再ルーティングすると動作が変わる。旧グループの範囲を推測で統一しない。

## binary の確認と限界

`P/mitakaPlus.exe` は 12,288,000 bytes、SHA-256 は `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。通常の shell / Python による ASCII NUL 終端文字列の読取で、以下の **file offset** を確認した。これは REA の Evidence ではなく、文字列の存在だけの証拠である。

| 文字列 | file offset |
| --- | --- |
| `Comets` / `Satellites` | `0x8396d0` / `0x8a9dbc` |
| `Comet` / `Satellite` | `0x835198` / `0x831f08` |
| `toggle` / `toggleLabels` / `toggleOrbits` / `toggleSelectedOnly` | `0x839d90` / `0x839db0` / `0x839dd8` / `0x839e28` |
| `show` / `hide` / `isVisible` | `0x839e3c` / `0x839e44` / `0x839e4c` |
| `visible` / `labels` / `orbits` / `selectedOnly` | `0x839e58` / `0x839e60` / `0x839e68` / `0x839e7c` |
| `All` / `setTargetTo` / `target` | `0x82dae8` / `0x83a434` / `0x83a708` |

初回監査では reverse-engineer-anything skill の手順で `binary_session` を確認したが、使用可能な native provider がなく、Ghidra / IDA / Kuna は未設定、Hopper の launcher は存在しなかった。依存のインストールや設定変更は行わず、binary を開いた解析 session もなかった。その時点では xref・引数変換・名前比較・戻り値の実装は未確認であり、文字列の近接を関数所属や ABI の証拠にはしていない。その後の局所逆アセンブルの結果は末尾の追補に分けて記録する。

## 次単位の順序と未確定事項

1. **N01 / N02 の実描画状態を先に作る。** kind ごとの小天体設定と衛星設定で visible / labels / orbits を実際の描画へ接続した後、確定した property / toggle を既存 Lua transport に追加できる。既存の静的な all-small-bodies bool の別名にはしない。描画品質・日時更新・全件保持は既存モデルを再利用する。
2. **selectedOnly には複数行の表示集合が必要。** 現在の単一選択とは分離する。原本 `Visible` の初期値との対応、`show/hide` の未知名、重複名、`All` の処理を確定してから公開する。新しい native ルールを採る場合は原版互換ではなく、明示した限定契約として扱う。
3. **target は解決失敗を明示できる入口が必要。** name → 原行の解決、位置評価、camera 更新を分け、曖昧・未知・位置なしの場合に既存 camera / follow / 選択を変更しない。現在の void focus の「視点を維持した」を Lua 成功に読み替えない。旧名の source 選択が未確定なら、旧名での選択は公開を待つ。

残る公開契約の不明点は、`isVisible` が全体 visible / selectedOnly / 画面内の可視性まで含むか、名前比較の大小文字、空・未知・重複・部分的に有効なリスト、空白の範囲と引用記法、変更の原子性、メソッド戻り値、初期 selected set、複数 source の選択順である。推測で実装せず、追加原典またはユーザーに確認した native 契約で区別する。

初回監査時点では製品テストを再実行していない。原本は読み取りだけで、Windows 実行ファイルも実行していない。stage / commit は統合担当に任せる。

## UNIT5 実装追補

UNIT4 commit `002adcf663fd5005e14ac86c343a3ec7e56fa706` 後、`Asteroids` / `TNObjects` / `Comets` / `Satellites` の四つの boolean と toggle を実装した。`ScriptSnapshot` → JSON transport → worker の取得・設定は native の現在値を使い、型違い・引数違い・ホストの拒否を Lua エラーとして伝える。成功する未実装 stub は置かない。旧版の boolean 変換規則は主張せず strict boolean とする。

小天体は kind ごと、衛星は専用 `SatelliteDisplayModel` で設定と表示集合を管理する。初期値は visible のみ true、集合は空。native の出典＋ordinal による集合を GUI で編集し、クリック選択とは分離する。未知・重複 ID の更新は原子拒否し、再読込時は同じ定義出典 bytes の同じ ID だけを保持する。衛星の描画・クリック・Lua・保存はこの一つの表示設定を参照する。独立した旧 master bool は残さない。

衛星の軌道は、検証済み Kepler 行の現在日時の親位置・回転を使う瞬時楕円として接続した。月専用解析や未評価行には点列を作らない。原版の線形状や日時ごとの日心軌跡との一致は主張しない。詳細は [衛星表示](../../../native/gui/SATELLITE_DISPLAY.md) と [小天体軌道](comet-orbit-contracts.md) を参照する。

### 原版の局所静的追跡で追加確認した範囲

同じ SHA-256 の PE を Apple LLVM `/usr/bin/objdump --disassemble --x86-asm-syntax=intel --start-address=… --stop-address=…` で読み取った。以下は仮想アドレスであり、file offset ではない。REA provider によるデータフロー証明や Windows 上の動作試験ではない。

| 仮想アドレス | 確認内容 |
| --- | --- |
| `0x652870–0x652ae0` | `Satellites` のプロパティとメソッド登録列 |
| `0x6522c0`, `0x652350`, `0x6523e0`, `0x652510` | 四つの toggle の wrapper |
| `0x652530 → 0x5d9de0 → 0x55bac0` | show の wrapper と管理処理。wrapper の Lua 戻り値数は 0 |
| `0x652560 → 0x5d9e00 → 0x55c700` | hide の wrapper と管理処理。wrapper の Lua 戻り値数は 0 |
| `0x652590 → 0x5d9e20 → 0x55d340` | isVisible の wrapper と単一名照会。Lua boolean 一つを返す |
| `0x55bd3e`, `0x55bd89` / `0x55c97e`, `0x55c9c9` | `All` 経路で登録列の対象 bit をそれぞれ設定／解除するループ |
| `0x55d49b`, `0x55d4d0` | isVisible は未知名で false、名前一致時は対象 bit を返す。全体の visible / selectedOnly を読む経路ではない |

この局所追跡では登録済み container 内の処理までを確認した。起動時の出典・言語選択、引数変換関数の厳密な型規則、空白の全範囲などは未確定である。表示集合照会の性質が分かっても、全出典を保持する native モデルに旧名をどのように束縛するかは決まらない。このため `show/hide/isVisible` と追加 target 名は未接続を維持する。`Satellite.Moon` は従来の太陽・惑星・月の経路を変更していない。
