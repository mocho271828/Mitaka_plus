# 地形ファイルの保持と標高計算（N15 core）

2026-10-30。実装は明示したローカルファイルの索引・必要格子の読み込みと物体ローカル座標の計算まで。地形による輪郭・法線・遮蔽を含む GUI 描画は、この core の成功だけで実装済みとしない。

## 原資料と適用範囲

- 公式保存ソース `sources/official/mitaka_source/common/graphics/topograph.h` の `TopoGrid` / `TopoPatch` / `TopoSphere` と同 `.cpp` の reader・座標式を参照した。原本は変更していない。
- `topograph.h:49–50` は最大格子寸法 256、最大レベル数 10。`.cpp:104–113` は格子 header と signed short payload、`:477–492` は patch と `lvN+1` 個の格子、`:689–706` は全体 header と patch 読み込み。
- `.cpp:386–418` の標高補間、`:535–568` の半径・球座標式を参照した。既存原版の float 演算と short への切り捨てをそのまま再現する API ではない（下記）。
- `sources/official/mitaka_source/Mitaka/mtk_topography.cpp:109–118` の通常版登録は Earth / Moon / Mars の 3 種。ローカル Mercury ファイルも同じ形式で読めるが、この通常版登録の証拠だけで旧 Plus の Mercury 表示を認定しない。
- [旧 Plus 倍率の静的記録](../../investigation/native-plus/unit7/terrain-amplification-audit.md) は別の根拠。通常版 C++ と旧 Plus の実装全体が同一であるとは主張しない。

## ファイル形式

値の byte order は little endian。header の原 bytes は各構造に保持し、格子 payload は要求中の 1 枚を変更せず保持する。全ファイルをメモリに常駐させない。

|順序|型と意味|容量|
|---|---|---:|
|全体 header|float 標高単位 m、float 基準半径 m、int32 patch 列数・行数|16 bytes|
|各 patch header|float 東経始点・終点、float 北緯始点・終点、int32 最大 level index|20 bytes|
|各 level header|int32 保存 level 値、int32 格子の列数・行数|12 bytes|
|各 level payload|signed int16 標高、行順（同じ行の列が連続）、halo を含む `(columns+3)*(rows+3)`|要素数 × 2 bytes|

有効頂点の添字は `0..N`、周囲の halo は `-1..N+1`。level の列挙は原ファイルの順序を使い、保存 level 値は別に生値を保持する。原 reader はこの保存値を使わないため、同値の強制や並べ替えはしない。格子寸法の 2 倍増加も仮定しない。特に Earth は 8 の次が 15 である。

読み込み時は全 header を 2 回走査し、payload は offset を進めるだけである。1 回目で件数と上限を検証し、2 回目で容量が確定した索引へ格納する。余剰末尾 bytes、不足 bytes、無効寸法、非有限値、緯経度区間不正を拒否する。原 reader の小さい寸法の補正とは異なり、native は不正値を補正して読まない。

## 所有・資源・失敗の境界

`TerrainFile::open(path, limits)` は明示した 1 ファイルだけを `O_RDONLY` で開く。探索、他ディレクトリへの fallback、コピー、再保存は行わない。`O_NONBLOCK` と `fstat` により FIFO 等を待たずに拒否し、regular file だけを扱う。NUL を含む path も拒否する。

既定上限はファイル 2 GiB、patch 65,536 個、索引 32 MiB、格子 payload 256 KiB。count の積、file offset、`off_t`、file length を割当・read の前に検査する。索引容量は vector の保持領域であり、path・所有 object・allocator の管理領域を含まない。

格子は常に 1 枚だけを保持する。別格子を読み込む前に旧 buffer を破棄するため、一時的にも 2 枚の payload を所有しない。返す `TerrainGridWindow` は借用であり、次の read / release / move / 破棄までだけ有効。同一 `TerrainFile` へのアクセスは caller が直列化する。

source identity は開いた descriptor の device / inode / byte 数 / mtime / ctime（ns を含む）。全体 SHA-256、immutable snapshot、元 path の再解決結果との同一性ではない。索引走査と格子 read の前後で identity を確認し、通常の途中変更を検出する。変更や読み込み失敗時は旧 window も破棄する。メタデータを元に戻す攻撃まで防ぐ原本認証 API とは扱わない。

ファイル不正・変更・上限超過は既存 `CatalogError`、存在しない patch / level ordinal は `out_of_range`。部分的な索引は公開しない。既存標準 C++17 と POSIX の読み取りを使い、外部依存は増やしていない。

## 補間と座標

`terrain_elevation_m` は明示 patch 内の東経・北緯から双線形補間した meter 値を double で返す。公式 `.cpp:386–418` は float 補間後に short を返すが、native は整数化による標高の切り捨てを行わない。原 bytes の値は `elevation_units` から別に取得できる。

終端では最後の有効 cell の係数を 1 として評価し、halo の外挿をしない。区画外・非有限の入力は拒否する。patch の選択、経度 0/360 の wrap、LOD の選択はこの関数に含めない。header / patch / grid が同一出典の対応する組であることは caller の責任とし、header コメントにも明記した。

`terrain_surface_point_m` は `radius_m + elevation_factor * elevation_m` を半径とする。倍率は原標高を書き換えない表示入力である。有限の非負倍率と正の結果半径を検査する。ローカル座標は x が赤道・東経 0 度、y が赤道・東経 90 度、z が北極。J2000 への姿勢変換や画像の経度 offset は含めない。`mtk_topography.cpp` の Earth / Moon 180 度、Mars 0 度は `shift_texture_coord` の指定であり、地形の幾何座標を同じ角度だけ回す根拠として転用しない。

## ローカル原本の実測

当時の読み取り対象の明示 root は `/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data`。全て 180 × 90 = 16,200 patches。旧 Plus 配下には該当する `*topo*.dat` を確認できなかったため、当時は Plus 選択時に採用していない。現在は下記の明示的な限定例外を適用する。

|相対 path|原本 bytes|標高単位 m|基準半径 m|grids|索引 bytes|最大 payload bytes|
|---|---:|---:|---:|---:|---:|---:|
|earth_topo/earth_topo.dat|81,822,538|1|6,378,000|58,914|4,335,984|118,098|
|moon_topo.dat|761,562,016|0.5|1,737,400|129,600|8,294,400|34,322|
|mercury_topo.dat|59,713,216|0.5|2,439,400|97,200|6,480,000|2,450|
|mars_topo/mars_topo.dat|213,945,124|1|3,396,000|113,502|7,392,912|134,162|

- Earth: 1, 2, 4, 8, 15, 30, 60, 120, 240。最大 level index は 0 が 9,083 patches、6 が 7,111、8 が 6。
- Moon: 1, 2, 4, 8, 16, 32, 64, 128。全 patch の最大 index は 7。
- Mercury: 1, 2, 4, 8, 16, 32。全 patch の最大 index は 5。
- Mars: 1, 2, 4, 8, 16, 32, 64, 128, 256。最大 index は 6 が 16,149 patches、8 が 51。

これにより最大約 762 MB の月ファイルも、索引約 8.3 MB と選択格子最大 34,322 bytes で読み取れる。全 payload の常駐・メモリマップは行わない。

## 公式別配布 Earth / Mars の限定採用（2026-11-05）

ユーザーの承認により、国立天文台の[公式ダウンロードページ](https://4d2u.nao.ac.jp/mitaka/download/)から別配布された Earth / Mars だけを `resources/data/` に同梱する。これは旧 Plus 原本の欠損を補う明示的な例外であり、旧 Plus 原本との一致は確認されていない。Moon / Mercury は追加しない。native GUI は下記のサブディレクトリを参照するが、公式 ZIP の Readme は各 dat を `data` 直下に置くよう記載しており、旧 Plus の探索先は未検証である。

2026-11-05 に公式 ZIP を一時領域へ取得・展開し、下記の展開 dat のサイズ・SHA-256 が通常版アプリと通常版リポジトリ内の同名データにも一致することを確認した。原 bytes は変更していない。ZIP 自体は同梱しない。

| 公式配布 | ZIP bytes / SHA-256 | 同梱先 / dat bytes / SHA-256 |
|---|---|---|
| [earth_topo.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/earth_topo.zip) | 33,385,825 / `7c9164028d4a57bb8a2ea63f70b59be704d4dcbd83086d6814dbc3008d9a380e` | `resources/data/earth_topo/earth_topo.dat` / 81,822,538 / `a9082001c38ca0b3111d5f3dd7cf8abfb0b18cf581d4c1eb89589ea932030190` |
| [mars_topo.zip](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mars_topo.zip) | 130,911,334 / `73f7a8a35752f0dae13571903760f753b579b8db87e8135d8227299eba6f6676` | `resources/data/mars_topo/mars_topo.dat` / 213,945,124 / `0e65c81ee8ba0d59312b28e4928ce95c45d389fe024cfc37685b1842d4db907e` |

[国立天文台の利用規定](https://4d2u.nao.ac.jp/policy/)は非営利利用等の条件を定め、第三者への再配布や改変には制限がある。ユーザーのローカル利用承認は第三者への再配布許可ではない。リポジトリは非公開で、公開範囲は変更しない。データの権利・利用条件をコードのライセンスから推定しない。[公式クレジット](https://4d2u.nao.ac.jp/mitaka/credit/)は元データとして Earth の USGS GTOPO30 と Mars の NASA PDS MGS MOLA MEGDR を挙げているが、これだけでは加工済み dat の再配布権は導けない。

## 検証

[コマンド・全ログ・hash](../../investigation/native-plus/unit7/logs/n15/README.md)。通常 / ASan+UBSan / x86_64 それぞれで pure 471 checks、4 原本の全格子照合 798,907 checks が成功した。`-Wall -Wextra -Wpedantic -Werror`。

fixture は原 header/payload、signed extrema、halo、非 2 倍解像度、保存 level 生値、移動所有、境界補間・軸・倍率、全 prefix truncation、不正 header・余剰 bytes、資源上限ちょうどと 1 byte 未満、同サイズ rewrite・append による失効、明示 path 欠損・directory・FIFO・NUL を含む。

実データ試験は全 payload を別の `ifstream` で読み、保持 bytes と比較した。ただし検証側も production の descriptor offset を使うため、独立した全ファイル索引 parser との照合ではない。fixture の layout と公式 reader の読取レビューで索引の契約を別途確認している。テスト用ファイル以外の原本を書き換えていない。

親担当による独立読取レビューで、FD・FIFO・offset・2-pass 索引・容量制限・変更検出・LE16・境界補間に必須指摘なし。patch/grid の対応は caller 責任というコメントを追加した。

## 接続に必要な範囲

core source は `terrain.cpp` と `terrain_sampling.cpp`、test は `tests/test_terrain.cpp`。親担当が `native/core/Makefile` へ接続する。GUI は明示 source と天体の対応、bounded な LOD / mesh 所有、同一 frame の地形深度と大気・雲の遮蔽の接点が必要である。[読み取り設計](../../investigation/native-plus/unit7/terrain-rendering-design.md)に実装候補と未確定境界を分けて記録する。
