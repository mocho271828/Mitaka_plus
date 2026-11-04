# N09 星座絵・N10 恒星名選択集合の原典監査

調査日: 2026-10-29。UNIT4 の `002adcf663fd5005e14ac86c343a3ec7e56fa706` を基点とする UNIT5 作業ツリーを読み取った。[次の実装単位](../unit4/next-feature-units.md) の N09 / CONST-02 と N10 / STAR-02・STAR-03 を対象とする。初回は読取専用調査として記録した。UNIT6 で loader→projection→draw と名前初期化の追加追跡を行い、根拠が揃った Sky/Horizon 用 helper と独立試験を実装した。旧アプリ・原データ・設定は変更していない。App/Lua/状態復元の統合結果は別の UNIT6 検証記録を参照する。

## 原典と調査方法

| 略記 | 絶対パス |
| --- | --- |
| `PLUS` | `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka` |
| `OFFICIAL` | `/Users/kota/mitaka/repositories/Mitaka/sources/official/mitaka_source` |
| native / investigation | `/Users/kota/mitaka/repositories/Mitaka` を基準とする |

Plus の対象は Windows 1.5.4 build101013、同梱文書の表示版は 1.3.0、公式参照ソースは通常 Mitaka 1.3.1。CP932 は読み取り時だけデコードした。原本・画像・実行ファイルの複製、変換、実行は行っていない。既存調査は [星座契約](../local-constels-contract-audit.md)、[恒星制御](../local-star-controls-audit.md)、[資産](../local-assets-audit.md)、[Lua](../local-lua-unit4-audit.md)。本書の静的追跡結果は、これらの未確定事項の一部を更新する。

`PLUS/mitakaPlus.exe` は PE32 x86、12,288,000 bytes、SHA-256 `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。reverse-engineer-anything skill の手順で REA を使用したが、文字列検索に必要な解析 provider は利用できなかった。REA の section header 確認は成功し、前後の SHA は一致した（evidence `ev_0c497604fcf1a0daf136edd25f524077a1e65ee7c66fa289d966b8054bcab030`）。その後は既存 `/usr/bin/objdump` と標準ライブラリによる限定的な静的確認だけを行い、REA の対象を閉じた。解析環境の追加導入・設定変更はない。

以下のアドレスはこの SHA の image base `0x400000` に対する VA。登録→Lua wrapper→内部 adapter→容器を追い、インポート名は PE import table と照合した。逆アセンブルの最小抜粋、全 CAB / CDF の検算表、対象原本の SHA は [logs/n09-n10](logs/n09-n10/) に保存した。読み取った原本 188 ファイルの bytes は、検算前後ですべて一致した。旧アプリを起動した動作比較や画素一致の証拠ではない。

## N09: 確認できた資産と物理形式

`PLUS/doc/script_jp/constels.html:32–39` は `Constels.illusts` と `Constels:toggleIllusts()`、`ui/scripts/12constels.lua:1–5` は星座絵を有効にして黄道 12 星座を表示する例を持つ。文書 33 行の説明は「星座線」となっているが、38 行は「星座絵」である。例文だけから線と絵を同じスイッチにしない。

`data/constellations` は同名の CAB / CDF が各 89 件。CDF はすべて Version 7.0、Locale ja_jp。`Figure:` は 88 件、`and.cdf:7` の 1 件だけは `Art:`。`serh` と `sert` はへび座の頭・尾であり、88 略号に対する 89 図形を保持する。ローカル `constellation_HIP.dat` の `Ser1` / Caput は `serh`、`Ser2` / Cauda は `sert` と名称と位置が対応する。この対応を含む 89 行の名称位置と CDF `Pos` は一致するが、これは CAB の配置原点を示す証拠ではない。

全 CAB を読み取り専用で検算し、次の little-endian 配置と余りなく一致した。

| offset | 値 | 確定している意味 |
| ---: | --- | --- |
| 0 | `float32[5]` | 正規化前の中心方向 h.xyz、尺度 s、Z 回転角 a（度） |
| 20 | `uint32 N` | 後続の数値対の個数 |
| 24 | `float32[2] × N` | 描画点 p=(-x,y,0) を生成する有限の数値対 |
| `24 + 8N` | `uint32 M` | 後続整数の個数 |
| `28 + 8N` | `int32[M]` | ローカル値は −1 または `0..N−1`。描画は任意の負値で strip を切る |

全長は `28 + 8N + 4M`。N は 24–2,745、合計 75,517。M は 32–3,513、合計 92,938。−1 は合計 17,446。78 ファイルでは全数値対が参照され、11 ファイルには未参照要素がある。未参照要素も原順のまま保持する。

先頭 3 float のノルムは約 0.9999999725–1.0000000381、第 4 float は約 0.028–0.13、第 5 float は約 −324.76–643.46。これらの意味は値域ではなく、以下の読込から描画への命令追跡で確定した。`and.cab` は 16,552 bytes / N=1,289 / M=1,553、`ori.cab` は 27,056 / 2,078 / 2,601。`serh.cab` と `sert.cab` は先頭 5 float が同じ一方、CDF `Pos` はそれぞれ `(233.75,8)` と `(270,−5)` で異なる。

### loader→projection→draw の追加確定

列挙 `0x4ba640` は `data/constellations/*.cab` を独立に列挙し、`0x4ba7d0` が 5 float、点列、index 列を読む。容器 `0x102af80` の stride は 60 bytes。略号照合は basename の大文字小文字を畳み、`serh` / `sert` を `ser` として扱う。対応 CDF は CAB 読込後に参照する。CDF の `Figure:` / `Art:` の区別を CAB 読込可否へ転用しない。

`0x4baa76–0x4baaf4` は h を正規化し、+Z から h への quaternion helper `0x4bed00` を呼ぶ。点は `0x4babd8–0x4babed` で (-x,y,0) となる。格納 quaternion は逆だが、描画 `0x4c10f9–0x4c127c` の行列が OpenGL 列優先で転置されるため実効回転は +Z→h である。helper の h.z > `0.9999899864196777` は identity、h.z < 負の同閾値は X 軸 180 度。それ以外は cross(+Z,h) 軸の回転である。

原点 observer、正の距離 d に限る局所変換は、列ベクトルの表記で次のとおり。

```
p = (-raw_x, raw_y, 0)
w = h + 2*s*R(+Z→h)*Rz(a degrees)*p
local draw direction = normalize(Rx(-23.399999618530273 degrees)*w)
```

`0x4c0f56–0x4c12d6` の rotate / translate / matrix / scale / rotate の順と import table を照合した。d は全項に共通の正倍率なので方向から消える。observer が非ゼロの 3D 空間描画では距離は消えず、本 helper の対象外とする。

通常天球の RA/DEC は別行列 `0xd93840` を通る（境界描画 `0x4c1878–0x4c1913`）。初期化 `0x4200a0` は double `0xc29c30` = −0.4090825891398903 rad（−23.43870583 度）を使う。`0x41fff0` / `0x420010` の import は PE import table 上の `libmmd!__libm_sse2_cos` / `__libm_sse2_sin` であり、関数名を推測していない。従って native の通常赤道座標へ戻す残差は **Rx(23.43870583 − 23.399999618530273 度)**。既存 core の別 obliquity 定数 23.4392911 度で代用しない。

描画 `0x4c0ae0` は `GL_LINE_STRIP`（3）を使い、signed index が負になるたび strip を終える。自動閉路・spline・塗り・texture はない。未終端の末尾 strip も描く。未参照点、重複点、全負値を保持する。ローカル 89 件は全部一般 quaternion 分岐だった。独立した行列再構成は最大差 0、正距離を消す方向検算は最大差 2.22e−16。これは理想 double 演算の検算であり、旧 SSE の逆平方根や画素の同一性は主張しない。

### native の実装境界

`constellation_art.hpp/.cpp` は既存 `CatalogLoadLimits` / `CatalogError` と標準 C++ で raw bytes、header、全点、全 index を保持する。容量、個数、切断、余剰、非有限、無効な中心、範囲外 index は全体拒否する。0 件、任意の負 separator の許容は native 試験で固定する。元ファイルの書戻しや asset 同梱はない。

`ConstellationArtModel` は列挙を決定的なパス順で行う。各有効 CAB と raw 略号 ID を関連付け、Ser 二図形を保持する。関連付けが曖昧・不在の場合も raw 図形を保持し、描画対象から外して診断する。欠損は空、壊れた任意ファイルはファイル単位の診断。全有効ファイルの保持 bytes にも容量上限を適用する。

`constellation_art_projection` は空間直線の大円方向を適応分割し、既存 `equatorial_coordinates` / `ObservationFrame` / `project_sky_segment` を使う。通常星座の RA/DEC 線形補間を CAB に転用しない。画素誤差・角幅・評価予算・深さを制限し、継ぎ目・極・未確定区間を推測して結ばない。原点を通る線に十分近い反対端点は拒否し、描画は omitted 数を返す。

`ConstellationArtRenderer` は既存 line quality scope と clip を使う。線、境界、名称と独立の `illustrations` と、既存 defaultVisible / exceptions の論理積で描く。native 色と太さを使い、旧 OpenGL の画素一致は保証しない。Sky/Horizon だけが対象であり、3D art の完成とは扱わない。通常版公式 `cnst_illust.dat` は別形式なので自動代用しない。

## N10: 文書とローカル初期集合

`PLUS/doc/script_jp/stars.html:28–35,88–99` は `selectedLabels`、HIP 番号を空白で区切った `select` / `deselect`、単一 HIP 文字列の `isSelected` を記載する。`selectedLabels` は `labels` が true の場合に有効。`scripts/gui.lua:143` は `Selected Proper Names Only` と表示する。`isSelected` の例文 98 行は `isSelect` と誤記しているが、下記の実登録は `isSelected` であり、別名を追加する根拠にはしない。

手元の `star_names.dat`、`star_names_HIP.dat`、`star_names_jp.dat` は、コメントを除くとそれぞれ 174 行である。先頭 6 columns が HIP、第 7 column が `*` または空白。3 ファイルの `*` は同じ 24 HIP で、`selection.dat:63–86` の `HIP_n: 1` の 24 HIP と集合が一致した。

`selection.dat` 全体は 84 有効行（SUN 1、PLN 9、SAT 23、MP 5、HIP 24、GC 2、LGG 14、NBG 2、CNST 4）で、観測された値はすべて 1。これは現在のローカル fixture の一致であり、読み込み順・重複・値 0 の意味を証明しない。公式 `mtk_selection.cpp:59–79,103–106` はコメントを除いた行全体の完全一致を使う別形式なので、Plus の `: 1` 行へそのまま流用しない。

### 登録から membership 更新までの静的証拠

| 層 | VA と確認できた処理 |
| --- | --- |
| Stars scope | `0x662ed5` 付近から文字列 `Stars` (`0xc396d8`) を登録 |
| `select` 登録 | `0x6631d7` → wrapper `0x662310`。文字列は `0xcaa18c` |
| `deselect` 登録 | `0x6631e7` → wrapper `0x662340`。文字列は `0xcaa194` |
| `isSelected` 登録 | `0x6631fa` → wrapper `0x662370`。文字列は `0xcaa1a0` |
| wrapper | 引数 1 の self と引数 2 の文字列を既存変換 helper へ渡す。select / deselect は戻り個数 0。isSelected は bool を push して戻り個数 1 |
| adapter | `0x5e6480` / `0x5e64a0` / `0x5e64c0` → `0x589e70` / `0x58a7d0` / `0x58b130`。共通容器 `0x1107940` を使用。変更側だけ表示更新を呼ぶ |
| 容器 | begin / end は this+`0x50` / `0x54`、stride 64 bytes。row+0 の整数キーを比較し、row+4 の char を更新・照合 |

`select` の一致行への書込みは `0x58a41f` の `'*'`、`deselect` は `0x58ad7f` の空白。既存の他行を消さず、全行を走査して一致する行だけを更新する。従って操作は追加 / 削除であり、集合の置換ではない。一致行が複数存在する容器なら全一致行を更新するが、旧 loader が重複 HIP を受理することまでは確認していない。

`All` は文字列 `0xc2dae8`。select の `0x58a11c`、deselect の `0x58aa7c` が import `0xc253c8`（`MSVCP80.dll` の `std::string == const char*`）で比較し、全行の row+4 をそれぞれ `'*'` / 空白へ更新する。大小文字を同一視する比較ではない。通常の HIP token は import `0xc25634` の `MSVCR80.dll!atoi` へ渡る。分割 helper `0x411400` に渡す文字列 `0xc297a0` は ASCII space 1 字であり、タブ等の規則まで確認済みとはしない。

通常 token が一致しなければ行は変わらない。同じ token を繰り返しても同じ char を代入する。`atoi` は厳密な十進整数 parser ではないため、旧実装が先頭数値以外を含む入力を厳密に拒否すると説明しない。Lua 共通変換 helper による arity・型 coercion、空文字列 / 空 token の全挙動は未追跡である。

`isSelected` は `0x58b130` から単一文字列を `atoi` に渡し、最初の一致行の row+4 が `'*'` か比較する（`0x58b1b8`）。未一致は false（`0x58b18e`）。`visible`、`labels`、`selectedLabels` や投影・等級は参照しない。したがって返すのは **固有名集合への membership** であり、現在画面にラベルが描かれたかどうかではない。文書 97 行の「labels と selectedLabels が有効な場合」という条件付き説明を、この membership の意味として読む。`isSelected` 内には `All` 専用分岐がないため、全件選択を問い合わせる拡張は追加しない。

`selectedLabels` の独立プロパティ登録も `0x663234`（setter `0x6624c0`、getter `0x662490`、名前 `0xc3acd4`）にある。membership の更新・照会と別経路である。旧 `select` を、現在のクリック対象を変える native `selectStarHIP:` へ接続してはいけない。

### 初期化の追加確定と残る不明点

起動順は HIP 読込 `0x48bb11`、名前呼出し `0x48bbd0`、名前 reader `0x57fff0`。基底名は `star_names.dat`（`0xc2c4c4`）。reader `0x58014e–0x580155` が入力第 7 byte を row+4 に保存し、`0x58047a–0x580487` / `0x580ca2–0x580cac` が同じ値を容器へ保持する。この印が member の初期値になる。

言語 resolver `0x41c149–0x41c205` / `0x41c379` は English（2）で基底名、Japanese（1）と JapaneseRuby（0）で `_jp` の存在時はそれを選び、なければ基底名を使う。複数ファイルの合算ではない。設定読込 `0x4f6f87–0x4f7046` と GetLocaleInfoA の 0411 判定も照合した。native が採用するローカルカタログ選択は App の明示した契約を維持する。

`selection.dat` による後段上書き、値 0、重複、reload と `star_names_HIP.dat` を startup fallback とする根拠は未確定。名前ファイルの初期印の確定と、全起動完了時の集合が完全一致する保証を区別する。native `StarNameSelection` は採用済み名前レコードの `is_featured` を初期値とし、未知の優先順位を追加しない。

## N10 の native 接続契約

現行 `native/core/src/extended_catalog.cpp:190–212` は `StarNameRecord{hip,is_featured,name_bytes,localized_name_bytes}` を返し、重複 HIP はファイル全体エラーにする。`native/gui/src/extended_catalogs.cpp:42–46` は明示 `options.star_names`、存在する日本語ファイル、英語ファイルの順で一つを読む。これは現在の native 契約であり、旧起動順の再現ではない。

`StarRenderer.mm` は固有名をローカル名優先で取得し、Bayer / Flamsteed / HIP の designation と合成する。UNIT6 で `StarDisplayOptions.selected_proper_names_only` と renderer への選択 HIP 集合の setter を追加した。全天 / 地平図は renderer を共有し、既存の座標・恒星カタログ・等級制限を再利用する。

1. 名前カタログに存在する HIP を対象とする型付き `StarNameSelection` を設けた。単一クリック対象と独立させ、追加・削除・全選択・全解除・照会を提供する。初期値は既存 `is_featured` とする。これは **native の明示契約**であり、旧 `selection.dat` の読込を再現したとは説明しない。
2. `selected_proper_names_only` を `proper_names` から独立させる。固有名だけに `proper_names && (!selected_proper_names_only || membership)` を適用する。既存の可視・等級・投影条件はその外側に残す。Bayer / Flamsteed / HIP 表示と星の点・マーク・クリック対象は変えない。公式 `mtk_stars.cpp:160–161` の固有名 / 小名称の分離もこの設計を支持するが、Plus の画素一致の証拠にはしない。
3. native の型付き batch は全件検証後に更新し、未知 HIP を原子的に拒否する。Lua 旧操作では未知 token が無変更となる証拠があるので、同じ未知エラーをそのまま公開しない。旧 `atoi` の寛容入力を再現するか、厳密な十進入力だけを新契約として認めるかは Lua 境界で別途明示する。型 / arity を推測した wrapper を追加しない。
4. モデル交換時は同じ HIP の membership を維持し、消失 HIP は報告して除去、新規 HIP は初期規則に従う。これは旧 reload の未確定挙動とは別である。手動 JSON 復元は App の境界で未知 HIP を含む全体を拒否し、状態を部分適用しない。codec は正の int32 と配列内重複までを検証する。
5. App 統合では共通 setter から隠れている側も含む Sky / Horizon、ブラウザ、Lua snapshot、保存状態へ同じ集合を渡す。既存 catalog browser の名前がある HIP の checkbox と、検索に依存しない全選択 / 全解除を使用する。選択行の移動や等級変更を membership 操作へ混ぜない。これらの App 統合結果は root の UNIT6 記録で確定する。

必要な依存は既存 C++17 containers、AppKit、Lua、JSON 検証境界で足りる。別のカタログ・UI・parser 基盤は追加しない。N11 の brightness・fadeLabels・文字の距離減衰は [別の契約](star-brightness-fade-contracts.md) で扱う。Solar の 3D 恒星描画は現在未実装であり、Sky / Horizon の接続だけで全空間の名称表示が完了したとは扱わない。

## 受入条件

| 対象 | 必要な確認 |
| --- | --- |
| CAB 構造 | 全ローカル 89 件の原順・byte 数・値・未参照要素を保持。切断、余剰、overflow、巨大 count、非有限、範囲外 index は拒否。欠損を別資産で代用しない |
| CAB 描画 | 変換の根拠が揃ってから、非対称図形・Ser 二図形・RA seam・極・地平線・異なる日時/地点を検証。画素試験と旧版比較の範囲を区別 |
| 固有名集合 | 初期値、追加 / 削除の非置換、All、繰返し、未存在、空入力、型不正、後半 invalid による部分更新防止。Lua と native の異なる入力境界を明示 |
| 独立性 | labels / selected-only / visible が false でも membership getter と編集は保たれる。単一選択・等級・Bayer / Flamsteed / HIP は変わらない |
| 実描画 | Sky / Horizon とも選択固有名だけが変化し、非表示中の更新後も同期する。名前なし / 任意カタログなしを含める |
| ローカル保持 | 現在の 174 行 / 24 初期印を照合するが、この件数を製品上限にしない。独自追加された有効行を全件保持し、元ファイルへ書き戻さない |
| モデル / JSON | reload の継承・消失報告・新規初期値、全体復元、未知 HIP の原子的拒否、再生停止を既存境界で確認 |
| 検証構成 | 通常、ASan+UBSan、Rosetta x86_64 の適切な model / renderer / controller / App 試験。GUI は他の実行と直列化 |

追加追跡と helper 実装の検証結果は `n09-n10-validation.md` に分ける。App/Lua/session の統合試験は root の UNIT6 記録で確定し、局所試験だけで機能全体の完成とは扱わない。stage / commit は root が一括して行う。
