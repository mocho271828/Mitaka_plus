# N01: 彗星軌道・種類別表示の契約監査

## 範囲と状態

2026-10-29、UNIT4 の作業ツリーを読み取り監査した。基点は UNIT3 commit `cf4fcbfe5447adf554e5bca0b0caf5ae5f529505`。以下の native 行番号は UNIT4 の変更を含む。この文書は調査結果と次単位の実装条件であり、N01 の実装完了報告ではない。原本、runtime、設定、既存テストは変更していない。

- `P` は `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。原本は CP932 で復号した元ファイルの行番号で参照する。
- 対象実行版は Plus 1.5.4 build 101013、同梱 API 説明は Plus 1.3.0。通常版の公式 1.3.1 ソースとは分ける。
- 優先順位は [次単位一覧](../unit4/next-feature-units.md) の N01。既存ローカル原本と独自追加を保持し、公開データによる置換・統合・再保存は行わない。
- Lua の名前解決・登録列・戻り値の監査は [UNIT5 Lua 契約](lua-comet-satellite-contracts.md) を参照する。

## 原典で確認できる表示契約

| 原本位置 | 確認できること | 確認できないこと |
| --- | --- | --- |
| `P/doc/script_jp/comets.html:12–19` | `Comets.visible` は read/write boolean、`toggle()` はその反転。 | 初期値、labels/orbits を含む全レイヤーとの厳密な優先順位。 |
| 同 `20–27` | `labels` と `toggleLabels()` は彗星名の表示設定。 | 衝突回避、最大件数、選択行を例外表示するか。 |
| 同 `28–35` | `orbits` と `toggleOrbits()` は軌道線の表示設定。 | 標本数、表示期間、視距離による範囲変更、閉曲線条件。 |
| 同 `36–43` | `selectedOnly` と `toggleSelectedOnly()` は一部のみを表示する設定。説明は `visible == true` の場合に有効とする。 | 初期集合、個別 `Visible` 属性との対応。 |
| 同 `44–55` | `show` / `hide` は固有英語名の空白区切り文字列を受け取り、`isVisible` は一つの名前から boolean を返す。 | 大小文字、未知名・重複名、空リスト、部分成功、グローバル表示設定との関係。 |
| `P/scripts/gui_jp.lua:134–138` | 上記四つにそれぞれ設定用のメニュー項目がある。 | visible と labels / orbits の優先順位、実行版における描画アルゴリズム。 |
| `P/ui/scripts/eclipse_20090722.lua:47–52` | `selectedOnly = true`、`hide("All")`、`show("Holmes Hale-Bopp(1995O1)")` を組み合わせる。 | `show("All")`、`isVisible("All")`、`All` と他名の混在。 |

`selectedOnly` はクリック中の一件とは別の、複数天体からなる表示集合を必要とする。同梱実例の二つの名前を、現在の `selectedSmallBodyIndex` 一件に読み替えてはいけない。クリック選択、追尾、検索結果、表示集合は別の状態である。

種類別の管理名も区別する。`P/doc/script_jp/asteroids.html:12–55` は `Asteroids`、`tnobjects.html:12–63` は **`TNObjects`**。後者の `oort` / `toggleOort` は `:44–51` の別機能である。Asteroids / TNObjects の `show` / `hide` は英語名または小惑星番号を文字列で受け取るが、Comets へ番号指定を一般化する根拠はない。`MinorPlanets` や `TNOs` という Lua alias も確認していない。

## 原本の名前と評価できる行

`P/doc/script_jp/abouttargets.html:29–31` は `Comet.<固有英語名>` を `data/orbits/comets/*.dat` の名前として説明する。一方、現在の native で座標評価できる彗星は、形式・参照面・時系を確認した固定幅 `data/comets.dat` の行である。この二つを自動対応させる根拠はない。

| 原本 | 保持すべき相違 |
| --- | --- |
| `data/orbits/comets/hale-bopp.dat:3–12` と `hale-bopp_jp.dat:3–12` | `Name: Hale-Bopp(1995O1)` は共通だが表示名は異なる。`Tp: 2450539.63709`、`Size: 500`、`Visible: 1` を含む。 |
| `data/orbits/comets/holmes.dat:3–12` と `holmes_jp.dat:3–12` | `Name: Holmes` は共通だが、q/e/i/w/Node/Tp に言語別の差がある。`Tp` は `20070504.49985` / `20070504.49994`。 |
| `data/comets.dat:1–4` | JPL ELEMENTS.COMET の URL、固定幅の列見出し、Halley の行がある。元列は Epoch/q/e/i/w/Node/Tp/Ref。 |
| `data/comets.dat:20,786` | 行名は `17P/Holmes` と `C/Hale-Bopp (1995 O1)`。個別ファイルの Name と一致しない。 |

個別四定義の `Tp` は JD に見える値と暦日形式に見える値が混在する。桁数だけで時系・参照面・日付解釈を決めない。言語別定義を重複として削除したり、JPL 行に差し替えたりしない。現コアはこれらを未解明行として保持し、位置を捏造しない。

[SMALL_BODY_PROVENANCE.md](../../../native/core/SMALL_BODY_PROVENANCE.md):62–85 は、固定幅原本の列と JPL の一次資料を照合した時系・参照面の根拠を記録している。Epoch は MJD TDB、Tp は暦日表現を変換した TDB JD、q は AU、角度は J2000 黄道系の度。1582-10-15 より前の暦は未解明としている。これらは固定幅形式についての確認であり、個別定義や packed mp/TNO 形式の根拠にはならない。

同文書 `:143–149` の既存全件検証記録は、67 source・19,475 小天体行、固定幅彗星 2,453 行のうち評価可能 2,388 行、歴史暦未解明 65 行。評価可能な内訳は楕円 859、放物線 1,298、双曲線 231。この監査で全件試験を再実行した値ではなく、ローカル原本が変われば再集計する。固定件数を製品の読み込み上限にしない。

## 現 native と不足している境界

| 現コード | 現在の実装 | N01 で必要になる差分 |
| --- | --- | --- |
| `native/core/include/mitaka/small_body_catalog.hpp:11–19,29–61` | kind、source key + 原行 ordinal、元 bytes、参照面・時系・要素・診断を保持。 | 元 ID を表示集合にも使う。未知 kind や無効 ID の検証を境界に置く。 |
| 同 `:78–92` | 全既知ファイル・個別定義を保持し、確認できた行だけ評価する。未解明行は状態なしと診断を返す。 | 画面に出ない行をカタログから削除しない。 |
| `native/gui/src/small_body_model.mm:37–72` | 全行の名称・出典・検索・kind 絞り込み・ページング。 | 検索条件を描画設定や表示集合に流用しない。 |
| 同 `:74–103`、`include/small_body_model.hpp:31–45` | 元行数の positions を持つ同一 JD の snapshot。全体非表示時は選択行だけ評価できる。 | kind/filter ごとの必要評価と軌道標本を扱う境界が未実装。 |
| `native/gui/src/SmallBodyRenderer.mm:7–59` | 点、選択リング、選択行だけの名称。kind は色に使う。 | 独立した labels、軌道線、種類別設定、複数行集合。 |
| `native/gui/src/SolarSmallBodies.mm:10–34` | 全小天体共通の表示 bool。overview で描画し、地月表示・表面・移動中は除外する。 | 種類別設定と scene の表示条件を分ける。 |
| 同 `:35–72` | 元行選択と追尾。位置未評価なら focus は視点を維持し、表面操作は拒否する。 | 表示集合の更新でクリック選択や追尾を勝手に変更しない。 |
| `native/gui/src/AppSmallBodyCommands.mm:18–52` | 表示中の太陽系で全評価、非表示では選択行評価。選択操作は全体表示を有効にする。 | 種類別状態の更新、非表示時の日時更新、表示復帰時の再評価。 |
| `native/gui/include/session_state.hpp:23–48`、`src/session_state.mm:168,222` | version 4 に `show_small_bodies` bool がある。小天体の元行集合は未保存。 | 型・サイズ・出典整合を検証した静的状態の保存。 |
| `native/gui/src/ScriptWorker.mm:42–90,393–398` | BooleanBinding と snapshot/action 経由の既存設定。Comets/Asteroids/TNObjects は未登録。 | 実装済み設定だけを strict boolean と toggle へ接続。 |
| `native/gui/src/AppScripting.mm:8–10,30–31,183–192` | Camera.target は既存 11 天体の経路。 | 小天体英名の解決を点描画の対応から推測しない。 |

## 軌道計算・投影の再利用

`native/core/include/mitaka/small_body_orbit.hpp:7–20` と `src/small_body_orbit.cpp:25–56` は、既に三種の二体軌道を扱う。`e != 1` は既存 `orbital_state`、厳密な `e == 1` は Barker 方程式を使う。q、時刻、角度の非有限値や計算不能は明示した例外で返す。摂動、非重力効果、時系変換は適用しない。N01 で新しい Kepler solver を書く必要はない。

座標は **太陽中心 J2000 黄道 AU**。既存の小天体点と同じく `project_solar` / `project_solar_segment` に直接渡す。惑星の `SolarBodies` / `SolarOrbits` は J2000 赤道なので `SolarSceneRenderer.mm:91–93` で黄道へ変換しているが、その変換を彗星にもコピーすると二重変換になる。衛星の親座標補正も彗星には不要。

`native/gui/src/sky_model.cpp:26–52,206–218` の惑星軌跡は、表示用の近似周期と CF96 の共通範囲を使う 181 点の時間標本で、閉曲線にしない。これを一般的な彗星周期・精度範囲として再利用してはいけない。既存の線分投影と `RendererQualityScope(..., line)` は再利用できる。`SolarSceneRenderer.mm:77–108` は near plane を扱う線分投影と明示した原点加算の位置を示す。

## 次単位で採用する native 契約と未決定事項

以下は原版の未知挙動を断定したものではない。統合担当は、種類別四つの bool と source + ordinal による表示集合を、明示した native 契約として採用する方針を確認済み。runtime への実装は UNIT4 commit 後の別指示で行う。

### 表示設定と元行の集合

1. asteroid / trans_neptunian / comet ごとに `visible`、`labels`、`orbits`、`selected_only` を持つ。表示集合はクリック選択一件から分離する。GUI の種別検索はこの状態を変更しない。
2. 集合は元 source + ordinal を識別する。source の bytes が変わった再読込で、同 ordinal を同一対象と見なさない。source の一致確認、無効な復帰の診断・取り消しを境界に置く。同名・同番号の二行を別々に操作できるようにする。
3. body、label、orbit の表示判定を一か所へ集約し、pick も同じ body 判定を使う。点を隠した行がクリックに反応する状態を避ける。新しい native 契約として `visible` を種別全体の master にするか、body のみにするかは実装前に明記する。原典の短い説明だけで優先順位を確定しない。
4. 初期 bool と初期集合を明記する。原本の `Visible: 1` を旧集合の初期値と断定しない。全体 bool を残す場合の master 関係も一意にする。既存状態の復帰はプロジェクト方針に沿って検証し、偶然のデフォルトに任せない。
5. 登録行・診断・raw bytes は全件保持する。N01 の座標・軌道描画は確認できた固定幅彗星行に限り、packed asteroid/TNO と個別彗星の未解明を解消したことにはしない。

### 有限の軌道線

1. 独立した標本生成の境界へ、元行、開始・終了 TDB JD、標本数または上限を明示して渡す。要求の有限性・順序・サイズを検証する。原版の表示日数・標本数は未確定なので、実装の値は native の表示方針として説明する。
2. 最小実装は全 conic を指定期間の開いた軌跡として扱える。閉じないことを明示すれば、長周期楕円と双曲線・放物線を同一の「一周」として描かずに済む。楕円の一周期全体を追加する場合も、周期の overflow、`e → 1`、極小 q、巨大期間の上限を別途検証する。
3. 各標本は既存の行評価を通し、位置・診断・実際の JD を保持する。計算失敗や未解明の標本を消して前後を直結しない。連続する有効標本間だけ線分を作り、欠損を跨ぐ偽の線や暗黙の終始接続を防ぐ。
4. 標本化期間は描画上の範囲であり、軌道要素の科学的な精度保証範囲ではない。既存の `unknown_accuracy_range` を消さない。有限な位置を返したことだけで原版精度・実際の暦表精度を主張しない。
5. 全軌跡の再計算を `drawRect` に置かない。表示設定・元 model・期間・標本化条件に対応する結果を作り、世代違いの結果を適用しない。上限やキャンセルを入れる場合も、登録行を無言で先頭 N 件に間引かない。保留・計算不能は行の診断と区別する。
6. 非表示時は不要な全軌道計算を止め、選択中の位置・追尾に必要な評価は維持する。表示復帰時は現 JD / model / 設定に揃える。非表示状態のキャッシュを古い日時のまま表示しない。

### GUI、Lua、session の接続

- GUI は種類別四設定に加え、複数行を集合へ追加・除外する明示操作が必要。通常の単一クリック・focus と同じ操作へ兼用しない。少なくとも二行の集合を作成・解除できて初めて `selected_only` を有効な機能として公開する。
- Lua は既存 BooleanBinding、snapshot、action 境界を使う。表示だけできた段階で `show` / `hide` / `isVisible` を成功する stub にしない。旧英名を全 source の最初の一致で解決したり、JPL の別名へ自動置換したりしない。追加の登録順・名前解決の根拠は UNIT5 監査で扱う。
- 保存するのは静的表示状態と明示した集合。source ごとの ordinal 群など、型のある形式で全件を扱い、既存 1 MiB 上限・strict boolean・原子適用を維持する。元データへ書き戻さず、復帰で再生・外部実行・視点移動を開始しない。
- 全種類の設定を用意しても、packed asteroid/TNO の座標が確定するまでは描画対応と表示しない。オールト雲、尾、光度、表面、全天・地平線、Camera の旧名 target 拡張は別単位。

## 必要な試験契約

ここに挙げる N01 試験は未実施。既存テストを読み取ったうえで、追加差分を検証する条件を整理した。

| 境界 | 合格を確認する条件 |
| --- | --- |
| 原行保持 | 同名・同番号・言語別・独自追加・最終行を元順で保持。元 bytes と読取件数が変わらず、表示集合の操作で dataset が変化しない。 |
| conic | 楕円、放物線、双曲線の標本が既存 evaluator の同 JD の位置と一致。近点・対称時刻・面の回転・`e = 1 ± ε` を含む。 |
| 標本要求 | NaN/Inf、逆転・ゼロ期間、標本数の下限・上限、overflow、極小 q を決めた契約で拒否。拒否時に現表示を部分変更しない。 |
| 線分位相 | 放物線・双曲線の始終点を閉じない。中間標本失敗時に前後を直結しない。楕円も実際に得た標本以上の閉曲線を作らない。 |
| 参照面 | 既知の非ゼロ z / 傾斜軌道が点と線で一致し、二重黄道変換・地球や親天体の加算がない。 |
| 投影 | near plane を跨ぐ線分、画面端、背面、空の path を確認。既存 map clip と line quality 設定が効き、周囲の UI へ漏れない。 |
| 種類別設定 | 三 kind を同じ fixture に入れ、四 bool の組合せを確認。片方の kind の変更が他を変えない。labels off の選択行、body off の pick、orbits only の採用契約を実描画で確認。 |
| 表示集合 | 二行を含む集合、空集合、同名の別行、集合外のクリック選択を確認。集合変更で単一選択・追尾・検索条件が変わらず、`selected_only` off でも集合を失わない。 |
| model/JD 更新 | 同 model の日時変更、異 model、source bytes 変更、非表示中の選択追尾、表示復帰、遅れて届いた旧世代の結果を確認。 |
| session | bool と数値を混同せず、重複 ID、範囲外 ordinal、欠損 source、変更された source、サイズ超過を検証。失敗時は現状態を維持し、成功時は pause 復帰。 |
| Lua | GUI 更新を getter が読み返し、toggle が実際の各 kind 描画に作用する。未知 member / 型違いは失敗。旧名解決は確定した範囲のみに限定する。 |
| 実原本 | 実行時の全件数から確認し、2,388 等を前提に切り捨てない。未解明 65 行や個別四定義も到達可能。元ファイルの SHA-256 等の保全検証を維持。 |

既存 `native/core/tests/test_small_body_orbit.cpp:30–104` は独立した放物線解析値、保存量、速度差分、三 conic、既存 solver 一致、放物線極限、異常値を検証する。これを再実装して同じ式同士を比較する試験は不要。追加するのは標本化・欠損・描画・表示状態の契約である。`native/gui/tests/test_small_body_model.mm:29–72` は原行保持、検索、世代キャンセル、未解明位置、非表示の選択行評価を既に扱う。

## 監査の結論と実行記録

N01 は、評価済み固定幅彗星の有限軌跡と、元行 ID に基づく種類別表示を明示した native 契約として実装できる。原版の軌道期間、初期集合、個別英名の source 解決は未確定であり、そのまま全互換とは称せない。原版の未知挙動を再現する必要が出た場合は、追加原典で確定するか、ユーザーに提示する具体的な限定契約として決める。

この作業では原典・現行ソース・既存試験を読み取り、新規文書だけを追加した。旧実行ファイル、Lua、GUI、製品テストは実行していない。新規依存・policy 変更はない。stage / commit は UNIT4 の統合担当が行い、この文書を runtime の実装完了証拠として扱わない。
