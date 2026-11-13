# CAB星座絵の投影と恒星名の選択

旧 Plus 1.5.4 build101013（PE32 x86、ImageBase 0x400000）を対象とする。[CAB の測定値](constellation-measurements/cab-structure.tsv)・[CDF の対応](constellation-measurements/cdf-associations.tsv)・[行列の検算](constellation-measurements/cab-independent-review.md)

以下のアドレスは対象バイナリの image base `0x400000` に対する VA。登録→Lua wrapper→内部 adapter→容器を追い、インポート名は PE import table と照合した。全 CAB / CDF の[検算表と原本ハッシュ](constellation-measurements/)を掲載する。読み取った原本 188 ファイルの bytes は、検算前後ですべて一致した。旧アプリを起動した動作比較や画素一致の証拠ではない。

## 確認できた資産と物理形式

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

## 文書とローカル初期集合

`PLUS/doc/script_jp/stars.html:28–35,88–99` は `selectedLabels`、HIP 番号を空白で区切った `select` / `deselect`、単一 HIP 文字列の `isSelected` を記載する。`selectedLabels` は `labels` が true の場合に有効。`scripts/gui.lua:143` は `Selected Proper Names Only` と表示する。`isSelected` の例文 98 行は `isSelect` と誤記しているが、下記の実登録は `isSelected` であり、別名を追加する根拠にはしない。

入力に使用した `star_names.dat`、`star_names_HIP.dat`、`star_names_jp.dat` は、コメントを除くとそれぞれ 174 行である。先頭 6 columns が HIP、第 7 column が `*` または空白。3 ファイルの `*` は同じ 24 HIP で、`selection.dat:63–86` の `HIP_n: 1` の 24 HIP と集合が一致した。

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
