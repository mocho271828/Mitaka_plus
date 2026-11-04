# Plus PTH の native 位置評価

対象はローカル Mitaka Plus 1.5.4 build101013。単位 5 の新規
`spacecraft_position.hpp/.cpp` は、単位 4 の読み込み結果を所有する評価モデルを追加する。
原本や原データへの書込み、データの差替え、ネットワーク取得、新規依存はない。

## 採用した根拠

詳細な静的監査とアドレス対応は
[spacecraft-position-contracts.md](../../investigation/native-plus/unit4/spacecraft-position-contracts.md)
を参照する。対象 executable の SHA-256 は
`48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。
この実装では対象 executable を実行していない。

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
GUI が表示中の状態を判定する際は、この評価結果と `sampling` を用いる。
機体 mesh、姿勢、軌跡表示、テキストから PTH を生成する暗黙書込みは本モジュールの範囲外。

## 検証

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

UNIT4 freeze 中は既存 Makefile を変更せず、新規ファイルを個別コンパイルして検証した。
コンパイルは Apple clang 21.0.0 (`clang-2100.3.34.2`)、C++17、
`-Wall -Wextra -Wpedantic -Werror`。
通常 ARM64、ASan/UBSan、x86_64 の各構成でローカル Plus/通常版データを使用する。
再現コマンドの通常版は次のとおり。sanitizer では `-O1 -fno-omit-frame-pointer
-fsanitize=address,undefined` と対応する core library、x86_64 では `-arch x86_64`
と対応する library を使う。

```sh
cd native/core
mkdir -p build-unit5-position
xcrun clang++ -Iinclude -O2 -g -std=c++17 -Wall -Wextra -Wpedantic -Werror \
  src/spacecraft_position.cpp tests/test_spacecraft_position.cpp build/libmitaka_core.a \
  -o build-unit5-position/test_spacecraft_position
build-unit5-position/test_spacecraft_position \
  '/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data' \
  '/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data'
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

ビルドと実行の証跡は `/tmp/mitaka-unit5-spacecraft-position-{normal,sanitize,x86}-build.log`
および `/tmp/mitaka-unit5-spacecraft-position-{normal,sanitize,x86}.log`。
独立した読取レビューでも監査契約との逸脱や必須修正は指摘されなかった。
レビュー担当は追加試験を実行しておらず、上記の実行結果とは区別する。
新規外部依存はなく、既存の原文 loader と PPI evaluator を再利用する。
