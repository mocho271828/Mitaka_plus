# 月の位置・姿勢の由来と対応範囲

`src/lunar.cpp` は公式 Mitaka 1.3.1 の月計算から、描画・グローバル状態を使わない部分を抽出した改変版である。
公式 ZIP・展開原本・既存データは変更していない。
位置と姿勢の原著作権表示、MIT 許諾文の全文は `src/lunar.cpp` に保持した。
非公式 macOS 移植のコードはコピーしていない。

取得元: <https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_131.zip>

原本パスは `sources/official/mitaka_source/` からの相対パス。

| 原本 | 抽出・参照した機能 | SHA-256 |
| --- | --- | --- |
| `Mitaka/mtk_lunar_pos.cpp` | 月の位置級数と日付の黄道から J2000 黄道への変換 | `e6dbf3d1e14f37417943d05fce2ce7ddbb23775ac8519213b3bad46ed375e669` |
| `Mitaka/mtk_satellite_orientation.cpp` | 月の RA・DEC・W と周期項、黄道から月固定座標への回転 | `d0433145605d916047a0ae0b231dd23904138804cb025f2dafbd9035d051ed53` |
| `Mitaka/mtk_planet_position.cpp` | 地球月質量比と重心位置補正 | `9c67e889384f5d3460344e72bbae80f47706250ce4cee7d989b4c549717f413c` |
| `common/math/vector3.h` | 公式行列の回転順序と比較用ビルド | `0a7827644a754c009842ddded726c1e80bead0a390dc743ca957c34006606d91` |
| `common/astro/astro_const.h` | AU と J2000 黄道傾斜角の定数 | `81de471ed93d07889ad9e0f11ca320b96404421d82d80715eb8959b0f2b3f592` |

## 位置と地球月重心

`lunar_position(jd)` は地心 J2000 赤道座標を AU で返す。
原本の `calc_lunar_pos`（`mtk_lunar_pos.cpp:208–290`）は、地心 J2000 黄道座標を km で返す。
経度 63 項・経度位相補正 4 項、緯度 47 項・緯度位相補正 5 項、視差 8 項を、原本と同じ係数・順序で評価する。
原本のコメントは、位置の式の出典を長沢江『天体の位置計算』（地人書館）としている。
原本の `sinpi` は視差の正弦の近似量で、距離は `6378.140 / sinpi`。分母へさらに `sin` を適用しない。

黄道座標は日付の歳差を戻して J2000 にそろえた後、既存の `j2000_ecliptic_to_equatorial` で赤道座標へ変換する。
歳差多項式の `eps0=84381.406/3600` 度と、最後の黄道・赤道変換の `epsJ2000=84381.448/3600` 度は、原本と同様に別値を保持する。
単位変換は公式定数の基礎式 `1 AU = 299792458.0 * 499.0047838061 * 1e-3 km` を double で評価する。
旧アプリの pc 座標や float の `_1AU_km`・`_1km_pc` を経由しないため、旧描画層と完全なビット一致は要求しない。

CF96 の index 2 は地球月重心 `B`。`r=lunar_position(jd)` と公開定数 `R=earth_moon_mass_ratio=81.30057` を用いて次の位置を得る。

```text
Earth = B - r/(R+1)
Moon = Earth + r
```

質量比は `mtk_planet_position.cpp:145–149` の値を保持する。
新 API は月の地心位置だけを返し、CF96 の生の位置・速度を変更しない。
表示用の軌道拡大率はこの計算に含めない。
月の速度・地心の速度は提供しない。CF96 の index 2 の速度を地心速度と読み替えてはいけない。

## 自転・極方向・秤動

`lunar_orientation(jd)` の `BodyOrientation` は、月固定 X・Y・Z 軸を J2000 黄道座標で表す右手正規直交基底。
X は経度 0 度、Y は東経 90 度、Z は北極である。
原本の `calc_moon_orientation_angle`（`mtk_satellite_orientation.cpp:137–195`）の全 E1～E13 周期項を保持する。
`d=jd-2451545`、`T=d/36525` とし、北極の赤経 `alp`・赤緯 `dlt` と本初子午線角 `W` を度で求める。
原本が参照する文献は同ファイル Ref[1] の Seidelmann et al. (2002)。今回、別の年代の姿勢モデルへは更新しない。

公式の黄道→月固定行列の各行を基底として返す。
同じ基底は、次の月固定→黄道変換でも得られる。回転は右手系、積は右から作用する。

```text
body_to_ecliptic = Rx(-epsJ2000) * Rz(90+alp) * Rx(90-dlt) * Rz(W)
```

三角関数へ渡す姿勢角は 360 度で還元し、計算途中の大きな角度を避ける。
位置の級数は原本の短い pi 定数と評価順序を保持する。
行列からベクトルへの逐次回転への変更や角度還元により、原本とは僅かな丸め差がある。

地心から見た月の経度・緯度の変動は、同時刻の月位置と月固定基底の内積から得られる。
そのため、月を常に地球へ正対させる簡略姿勢は使わない。
見かけの秤動を得る視線・観測者位置の合成は呼び出し側の責務で、姿勢 API は月そのものの向きを返す。
表面画像の経度オフセットや UV は姿勢へ含めない。公式の月画像は球描画で 180 度シフトし、専用描画では `u=atan2(y,x)/(2*pi)+0.5` に対応する。

## 入力範囲、時系、精度

位置と姿勢は同じ有限の JD を受け付ける。
対応範囲は `[2415020.5, 2487980.5]`、両端を含む（1900-01-01 00:00～2099-10-04 00:00）。
これは CF96 と組み合わせる今回の数値契約で、原本が保証したモデル有効期間や観測精度ではない。
CF96 と併用するときは、暦表オブジェクトの `time_range()` との共通範囲を使う。
非有限値は `std::invalid_argument`、有限だが範囲外の日付は `std::out_of_range` とする。
ゼロ座標や端点固定を代替値として返さない。

公式の位置モデル内部にある次の補正式をそのまま保持する。

```text
dt = (jd - 2442412.5) / 365.25
T = dt + (0.0317*dt + 1.43) * 1e-6
```

これは UTC→TT 等の一般的な時系変換 API ではない。
位置・姿勢には同一 JD を渡し、UTC/UT1/TT/TDB の相互変換、閏秒、光行時間、光行差、測心視差を追加補正しない。
位置は解析的な有限項近似、姿勢は公式の周期項近似であり、最新の数値暦・観測値との比較による誤差保証は行っていない。
地形、観測地点、詳細な物理秤動を追加する精密観測用モデルや、月以外の衛星は対象外。

## 回帰検証

通常テストは原本を必要とせず、固定値、距離の単位、直交性・右手性・逆変換、順行の自転、同時刻の位置と姿勢から求める地心秤動、両端と範囲外・非有限入力を確認する。
固定値は原本を独立にコンパイルする次のプログラムで再生成できる。

```sh
# このリポジトリのルートから実行
cd native/core
make lunar-reference-test
build/test_lunar_upstream --dump
make BUILD_DIR=build/sanitize SANITIZE=address,undefined lunar-reference-test
```

`mtk_lunar_pos.cpp` は未変更で比較用オブジェクトにコンパイルする。
`tests/extract_lunar_orientation.awk` は公式の許諾文と月の姿勢関数を本文変更なしで `build/` へ取り出す。
比較プログラムは公式の `vector3.h` の回転行列と公式 AU 基礎式で出力座標・単位をそろえる。
通常ライブラリには原本をリンクせず、実行時依存は C++17 標準ライブラリだけである。
比較許容差は実装の回帰確認のためのもので、天文学的な予測精度とは区別する。
1,009 時刻の位置・姿勢 12,108 成分を比較する。
許容差は位置 `2e-15 AU`、姿勢基底の各成分 `1e-11`。J2000 ではそれぞれ `2e-17 AU`、`2e-14` とする。

## ARM64 / x86_64 の演算プロファイル

UNIT4 の x86_64 全体試験で、ARM64 原本から採取した位置の固定値との比較が失敗した。
JD `2415020.5` の X 成分は、期待値 `0.00016353511842929789` に対して
`0.00016353511843153116`、差 `2.2332667399399542e-15 AU` だった。
旧テストを一時ディレクトリへ取り出して再現し、表示桁数だけ増やしてこの差を確認した。
元の `std::to_string` 表示では両値が `0.000164` となり、差が分からなかった。

同じコンパイラ条件で公式原本と新コアを比較すると、ARM64 / x86_64 の双方で
12,108 成分が合格し、位置の最大差はともに `1.73472347598e-18 AU` だった。
公式原本自体の ARM64 / x86_64 出力にも差があり、JD `2487980.5` の X 成分では
`8.460029551904391e-15 AU` になる。したがって係数、単位、軸変換の転記誤りではない。

採取環境は Apple clang 21.0.0 (`clang-2100.3.34.2`)、ホストは
`arm64-apple-darwin25.6.0`。通常の `-O2` ARM64 ビルドは積和演算を縮約する。
汎用 `-arch x86_64` ビルドは乗算と加算を分ける。
未変更の公式位置コードを ARM64 で `-ffp-contract=off` にすると、4 固定時刻の位置は
x86_64 原本と最大 `2.168404344971009e-19 AU` で一致した（最初の 3 時刻は一致、最後は X の 1 ULP）。
公式原本のアセンブリでも、通常 ARM64 の `fmadd` と、縮約無効 ARM64 / x86_64 での不在を確認した。
これは演算縮約の切り分けであり、他のコンパイラすべての丸めを保証するものではない。

固定値試験は、この 2 条件で独立に採取した公式原本の位置を保持する。
最大成分誤差が小さい一方のプロファイルを選び、X・Y・Z の全成分をその同じ組と比較する。
成分ごとのプロファイル混在は認めない。姿勢の固定値と、位置・姿勢の許容差は変更していない。
`src/lunar.cpp` と通常ビルドの演算条件も変更していない。
失敗時には実値・期待値・差・許容差を 17 桁で表示する。

採取コマンド（`native/core` から実行、公式位置原本は上表の SHA-256 のまま）:

```sh
make -j4 BUILD_DIR=build-unit4-absolute lunar-reference-test
build-unit4-absolute/test_lunar_upstream --dump
make -j4 BUILD_DIR=build-unit4-absolute-x86 ARCH=x86_64 lunar-reference-test
build-unit4-absolute-x86/test_lunar_upstream --dump

xcrun clang++ -Iinclude -O2 -g -std=c++17 -Wall -Wextra -Wpedantic -Werror \
  -ffp-contract=off -Wno-invalid-utf8 -Wno-gnu-anonymous-struct \
  -Wno-nested-anon-types -Wno-missing-braces \
  -c ../../sources/official/mitaka_source/Mitaka/mtk_lunar_pos.cpp \
  -o /tmp/mitaka-unit4-lunar-reference-arm-off.o
xcrun clang++ -Iinclude \
  -I../../sources/official/mitaka_source/common/math \
  -I../../sources/official/mitaka_source/common/astro \
  -O2 -g -std=c++17 -Wall -Wextra -Wpedantic -Werror -ffp-contract=off \
  -Wno-invalid-utf8 -Wno-gnu-anonymous-struct -Wno-nested-anon-types \
  tests/test_lunar_upstream.cpp /tmp/mitaka-unit4-lunar-reference-arm-off.o \
  build-unit4-absolute/reference_lunar_orientation.cpp \
  build-unit4-absolute/libmitaka_core.a -o /tmp/mitaka-unit4-lunar-reference-arm-off
/tmp/mitaka-unit4-lunar-reference-arm-off --dump
```

`--dump` の期待値生成は公式原本だけを呼ぶ。新コアを参照値の生成には使わない。
上の縮約無効バイナリは原本の切り分け用で、通常演算条件の新コアとの比較試験には使わない。

最終結果は通常 / ASan+UBSan の月試験が各 14,172 checks PASS、
`make BUILD_DIR=build-unit4-root-x86 ARCH=x86_64 test` は月を含む全 16 テストが PASS。
調査ログは `/tmp/mitaka-unit4-lunar-fma-diagnosis.log`、
原本比較と採取値は `/tmp/mitaka-unit4-lunar-investigate-*.log`、
旧テスト再現は `/tmp/mitaka-unit4-lunar-before-profile.log`、
修正後試験は `/tmp/mitaka-unit4-lunar-profile-*.log` に記録した。
