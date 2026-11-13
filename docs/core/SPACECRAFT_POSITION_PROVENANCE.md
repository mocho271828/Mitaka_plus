# Plus PTH の native 位置評価

対象はローカル Mitaka Plus 1.5.4 build101013。単位 5 の新規
`spacecraft_position.hpp/.cpp` は、単位 4 の読み込み結果を所有する評価モデルを追加する。
原本や原データへの書込み、データの差替え、ネットワーク取得、新規依存はない。

## 採用した根拠

旧 Plus 1.5.4 の読み込み命令と補間式を静的に確認した。対象実行ファイルの SHA-256 は
`48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。

- loader `0x5714d0–0x571bbb` は little-endian binary64 の `(time,x,y,z)` を読む。
  時刻を直接保持し、座標には旧 pc 内部単位への係数を掛ける。
  binary32 に丸めるのは係数であり、原座標自体は binary64 のままである。
- evaluator `0x56f890–0x56fb5f` は原数値 JD を比較する。最初・最後の時刻を含む
  端点判定を先に行い、内部は二分探索の最初に等値になった mid を返す。
  隣接区間では `u=(t-t0)/(t1-t0)`、`p=p0*(1-u)+p1*u` を使う。
- 更新 `0x569ab0/0x56aeb0` と描画 `0x56e610` までに追加回転・親位置加算はない。
  同じ空間の CF96 親位置との対応から、Plus の要求する値は日心 J2000 黄道 AU。
  物理時系 UTC/TT/TDB は未確定である。

native は原 binary64 AU を直接補間する。旧 pc への往復、別 AU 定数への換算、
float への座標丸めを加えない。旧版は先に係数を掛けてから補間するため、
旧実行ファイルとの最後の bit の一致や元データの天文学的精度は主張しない。
契約識別子は `mitaka-plus-1.5.4-pth-native-au-v1`。

## モデルと診断の境界

`SpacecraftPositionModel` は既存 `SpacecraftDataset` を値で受け取り、move で所有する。
原 bytes、全定義、言語 section、全軌道、全原行、元の診断をそのまま残す。
モデル構築時に PTH の source 状態・件数・有限値・時刻非減少を一度検査する。
評価時の探索は O(log N) であり、表示フレームごとに全記録を走査しない。
結果に原 bytes を複製せず、source / trajectory / 原 record index で追跡する。

一致と端点固定は同じ原 index を二つ返す。内部補間は両端 index と `u` を返す。
要求時刻が原端点と同値なら `exact_record`、範囲の外なら
`clamped_before` / `clamped_after` とする。全件同時刻では同時刻以下が先頭、
それより後が末尾となる。内部の重複は先頭・末尾に正規化せず、原版と同じ mid を採る。
重複の削除、平均、並べ替えや一律の `lower_bound` / `upper_bound` はしない。
端点固定を物理的な外挿と扱わない。

成功位置は `heliocentric_j2000_ecliptic_au`、採用区間は `sampling` に格納する。
成功時にも `unresolved_time_scale` を返し、要求した numeric JD を変換しない。
不正 source / index / 時刻、時刻差や座標の非有限演算では位置も成功 sampling も返さない。
有限の subnormal 区間は受け入れる。比が丸めで 0 または 1 になっても、
要求時刻が区間内なら状態は `interpolated` のままとする。

PPI の四点 km 補間は既存 `Trajectory` と `evaluate_spacecraft_trajectory` の責務として
再利用可能なまま維持する。PTH と PPI は形式・補間・原点が異なり、PPI の evaluator を
線形 PTH に流用しない。PPI の原点・面・物理時系はこの契約で確定しないため、
新モデルは `unresolved_spatial_contract` と `unresolved_time_scale` を返して表示を抑止する。
名称や `ORIGIN` の文字列だけから別版の既定値を補わない。

単位 4 の loader は PTH 未確定という当時の診断を dataset に持つ。単位 5 の位置結果は
上記の確定契約を明示し、原 loader の診断を黙って削除しない。
GUI はこの評価結果と `sampling` を表示し、位置契約を認定する前のローダーの暫定メッセージを一覧・選択欄から除く。物理時系や不正入力の診断は表示する。
機体 mesh、姿勢、軌跡表示、テキストから PTH を生成する暗黙書込みは本モジュールの範囲外。

## 配布版ごとの実データと実画面（2026-11-12）

Plus 1.5.4 の実データは PTH 7軌跡・14定義で、PPI は収録されていない。ネイティブ版の画面比較では Voyager I の補間時・端点固定時とも表示切替で中央504画素が変化した。

比較には公式通常版 Mitaka 1.7.4a のデータも使用した。13個の探査機定義に記載された原点は、太陽系重心10機、地球2機、太陽1機。JPL の同一中心・J2000 黄道・TDB の幾何座標と12機36標本を照合し、8機18標本の位置差は1 m未満だった。あかつきの2010〜2011年の478標本は JAXA の日心J2000赤道座標を黄道に回転した位置と1 cm以内で一致し、その数値 JD と元の UTC 表記の差は66.184秒だった。他の標本には大きな差があり、これらの照合で全ファイルの座標・物理時系・精度を一括して認定することはできない。統合版で13定義を実際に列挙し、未認定の Voyager I の PPI は地図の表示切替で変化0画素、表示位置なしの診断となることを確認した。

## 単位 5 時点の検証

`tests/test_spacecraft_position.cpp` は、区間補間と独立した各軸の一次関数、
手計算した重複 index 表、各単位軸、binary64 の次隣接値、極大有限座標を使う。
空・1/2/3 記録、奇数・偶数、先頭/内部/末尾/全件の重複、同座標の重複、
端点内外の `nextafter`、遠い範囲外、NaN/Inf、内部に隠れた破損、時刻差 overflow、
subnormal 区間を検査する。成分差 `b-a` が overflow する入力でも、採用した
重み付き和が有限なら正しい位置を返すことを確認する。

実ファイルを読む試験では原ファイルを fixture 以外書き換えない。
fixture でのみロード後にファイルを差し替え、モデルの bytes・採用位置が変わらないことを
確認する。実データの source/定義/原行/同時刻数は入力から数え、固定件数を合格条件にしない。
すべての PTH 行を原 binary64 bytes に戻して照合し、各原時刻を評価する。
PPI の native km 評価が独立して残り、表示位置は返さないことも確認する。

コンパイルは Apple clang 21.0.0 (`clang-2100.3.34.2`)、C++17、
`-Wall -Wextra -Wpedantic -Werror`。
通常 ARM64、ASan/UBSan、x86_64 の各構成でローカル Plus/通常版データを使用する。
次のコマンドはリポジトリのルートから実行する。`MITAKA_DATA_ROOT` には比較に使う通常版の `data` の絶対パスを指定する。sanitizer では `-O1 -fno-omit-frame-pointer
-fsanitize=address,undefined` と対応する core library、x86_64 では `-arch x86_64`
と対応する library を使う。

```sh
cd vendor/mitaka/native/core
mkdir -p build-unit5-position
xcrun clang++ -Iinclude -O2 -g -std=c++17 -Wall -Wextra -Wpedantic -Werror \
  src/spacecraft_position.cpp tests/test_spacecraft_position.cpp build/libmitaka_core.a \
  -o build-unit5-position/test_spacecraft_position
build-unit5-position/test_spacecraft_position \
  "../../../../resources/data" \
  "$MITAKA_DATA_ROOT"
```

通常 ARM64、ASan/UBSan、x86_64 の全構成で、Plus と通常版の実データを合わせて
それぞれ **353,093 checks PASS**。Plus 入力で観測した全 55,405 原行と同時刻の
隣接 14 組を保持し、通常版の 17 PPI 軌道すべてで表示位置を返さなかった。
この件数は実行時の観測値であり、ロード上限やテストの固定期待値ではない。

測定 fixture は 100,003 行と 25,000 回の問い合わせを使う。モデル構築の計測は
fixture の原 bytes 生成後に開始し、所有権移動と全原行の検査を含む。
次の値は同時実行時の実測であり、機種や負荷に依存する閾値をテスト合否にはしない。

| 構成 | モデル構築 | 25,000 回の問い合わせ | 結果 |
| --- | ---: | ---: | --- |
| ARM64、`-O2` | 0.135250 ms | 3.95621 ms | PASS |
| ARM64、ASan/UBSan、`-O1` | 0.733125 ms | 23.7706 ms | PASS |
| x86_64、`-O2` | 0.137166 ms | 5.28688 ms | PASS |

新規外部依存はなく、既存の原文 loader と PPI evaluator を再利用する。
