# Mitaka macOS core

公式 Mitaka 1.3.1 から天文計算とデータ読み込みを分離した、開発中の C++17 静的ライブラリ。
macOS の UI や描画機能とは独立してビルド・テストできる。
移植元の配布ファイルと SHA-256 は [公式ソースの出典](../sources/README.md) を参照。
既存データへの書き込み、移行、重複削除は行わない。

## ビルドと通常テスト

Xcode または Command Line Tools の `clang++`、`ar`、`make` を使う。
外部パッケージのインストールは不要。

```sh
# Plus リポジトリのルートから実行
cd vendor/mitaka/native/core
make -j4 all test
```

出力は `build/libmitaka_core.a` と `build/core_probe`。
通常テストは一時ディレクトリに合成データを生成するため、既存アプリや公式ソースを必要としない。
`-Wall -Wextra -Wpedantic -Werror` でビルドする。

```sh
# 別のビルドディレクトリで AddressSanitizer / UndefinedBehaviorSanitizer を有効化する。
make -j4 BUILD_DIR=build/sanitize SANITIZE=address,undefined all test

# arm64 と x86_64 を個別ビルドし、Universal バイナリを作る。
make -j4 universal
xcrun lipo -info build/universal/libmitaka_core.a
```

コンパイラ・アーキテクチャ・計測オプションを変更するときは、別の `BUILD_DIR` を指定する。
Universal 出力は `build/universal/`。Intel 向けのコンパイル成功と、Intel Mac 上での実行確認は区別する。
アプリの deployment target と動作環境は [GUI 操作ガイド](../gui/README.md) を参照。

## 既存データの読み取りテスト

データの場所は呼び出し側が明示する。次の例では Plus に収録したデータを使う。ライブラリは Wine の設定・レジストリ・DLL に依存しない。

```sh
# Plus リポジトリのルートから実行
cd vendor/mitaka/native/core
export DATA_ROOT="$(cd ../../../.. && pwd)/resources"
make data-test

# 同じ実データをサニタイザ付きの実行ファイルで検証する。
make BUILD_DIR=build/sanitize SANITIZE=address,undefined data-test
```

`data-test` は `data/hip.dat` と `data/cf96.dat` を必須入力とする。
`data/constellation_HIP.dat` があれば読み込み、`data/` と `spacecraft/` の直下にある全 `.ppi` を検証する。
データの件数を既存スナップショットに固定せず、読み込んだ件数と評価結果を表示する。
読み込み処理はレコードをフィルタしない。
カタログの独自拡張が既定上限を超える場合は、API の `CatalogLoadLimits` を指定して上限を調整できる。

個別のファイルを調べる場合:

```sh
build/core_probe hip "$DATA_ROOT/data/hip.dat"
build/core_probe cf96 "$DATA_ROOT/data/cf96.dat" 2451545.0
build/core_probe planets 2451545.0
# build/core_probe constellations /absolute/path/constellation_HIP.dat
# build/core_probe trajectory /absolute/path/example.ppi [Julian-date]
```

CLI は成功時に 0、処理エラー時に 1、使用方法が不正な場合に 2 を返す。

## ライブラリの境界

| ヘッダー | 機能 | 単位・座標系 |
| --- | --- | --- |
| `mitaka/astronomy.hpp` | Gregorian 日付と JD、楕円・引力双曲線、9 天体の平均軌道、黄道・赤道変換、B1950→J2000 | AU、AU/day、度。平均惑星軌道は黄道座標 |
| `mitaka/catalog.hpp` | HIP と旧星座バイナリを生値で読み込む | ヘッダーのフィールド名に度・時・mas 等を明示 |
| `mitaka/ephemeris.hpp` | CF96 の位置・速度、`.ppi` 四点軌道補間 | CF96 は太陽中心 J2000 赤道座標・AU・AU/day。`.ppi` は km、原点・座標系はデータ作成元に従う |
| `mitaka/rotation.hpp` | 9 惑星の自転と北極方向、地球の歳差 | 惑星固定 X・Y・北軸を J2000 黄道座標で表す右手正規直交基底 |
| `mitaka/lunar.hpp` | 月の地心位置・姿勢と地球月質量比 | 位置は J2000 赤道座標・AU、姿勢は月固定 X・Y・北軸の J2000 黄道基底 |

ヘッダーを `include/` から参照し、`libmitaka_core.a` をリンクする。
ライブラリ本体は C++ 標準ライブラリのみを使い、Windows、Wine、OpenGL、SceneKit に依存しない。
以下は呼び出し例。

```cpp
#include "mitaka/astronomy.hpp"
#include "mitaka/ephemeris.hpp"
#include "mitaka/rotation.hpp"
#include "mitaka/lunar.hpp"

const double jd = mitaka::julian_date({2000, 1, 1, 12, 0, 0.0});
const auto orbit = mitaka::mean_planet_state(mitaka::Planet::earth, jd);
const auto ephemeris = mitaka::Cf96Ephemeris::load("/absolute/path/cf96.dat");
const auto state = ephemeris.state(2, jd);
const auto orientation = mitaka::planet_orientation(mitaka::Planet::earth, jd);
const auto moon_geocentric = mitaka::lunar_position(jd);
const auto moon_orientation = mitaka::lunar_orientation(jd);
```

日付 API は先発グレゴリオ暦、年 -4712..9999（年 0 は紀元前 1 年）。
日付変換と暦表の評価は、UTC→TT/TDB 変換や閏秒補正を行わない。
CF96 の評価範囲は公式の有効時刻と実ファイルのブロック範囲の共通部分で、`time_range()` から取得する。
平均惑星軌道は公式 1.3.1 の近似値であり、CF96 による評価とは別 API。
CF96 は地球月重心を含む生の位置・速度を保持する。
地心位置は `E = B - r/(earth_moon_mass_ratio+1)`、月の日心位置は `M = E+r` で合成できる。
ここで `B` は CF96 の index 2 の位置、`r` は同時刻の `lunar_position`。すべて J2000 赤道座標・AU。
月速度と地心速度、冥王星系の重心補正は未実装。

`planet_orientation` は公式 1.3.1 の表示用近似を使う。
同じ JD を自転と北極方向の計算に使い、UT1/TT/TDB 変換、章動、極運動、光行時間は補正しない。
数値上の入力範囲は日付 API と同じ年 -4712..9999 であり、この全期間にわたる天文学的な精度を保証する範囲ではない。
基底の X は東経 0 度、Y は東経 90 度、Z は地図上の北極で、金星・天王星では角運動量の正方向と異なる。
画像の経度差分は GUI 側で扱い、姿勢の基底には含めない。
地球は公式の専用歳差・自転計算を使う。
太陽、月、衛星は対象外で、GUI の太陽表面は固定姿勢を維持する。

月は独立した `lunar_position` と `lunar_orientation` で扱う。
両 API の入力範囲は `lunar_minimum_jd=2415020.5` から `lunar_maximum_jd=2487980.5` まで、両端を含む。
暦表記では 1900-01-01 00:00 から 2099-10-04 00:00 で、CF96 と併用するときは `time_range()` との共通部分を使う。
この範囲はこのライブラリの入力範囲であり、モデルの観測精度を保証する年代ではない。
位置は公式の有限項級数と歳差変換、姿勢は公式の RA・DEC・W と周期項を使う。
同じ JD の位置と姿勢を合成すると、地心から見た月面の秤動を表せる。
時系変換・光行時間・測心視差は補正しない。式・単位・限界は [LUNAR_PROVENANCE.md](LUNAR_PROVENANCE.md) に記載した。

バイナリ入力は固定幅の little-endian として復号する。
ファイルをホストの `long` や構造体へ直接読み込まない。
HIP の負視差・独自 ID・未知の名称も保持する。
星座の日本語名は CP932 の元バイト列を保持し、UTF-8 への変換は表示側の責務とする。

形式不備・I/O エラーは例外で通知し、部分的な結果は返さない。
カタログは `CatalogError`、CF96 と軌道はパス・バイト位置を含む `std::runtime_error`。
計算の不正引数、範囲外、非有限の結果も例外とし、暗黙のゼロ座標・平均軌道への代替・軌道端点への固定は行わない。
CF96 と軌道の読み込み後データは不変で、所有期間はオブジェクトが管理する。

## 回帰テストと参照値

`make test` は、公式 Mitaka 1.3.1 の出力から採取した固定値と合成データを使う。天体の位置・速度、惑星の姿勢、月の位置・姿勢について、固定値を採取した条件と比較許容差を以下に記載する。

- [天文計算](ASTRONOMY_PROVENANCE.md)では J2000 の9天体の位置・速度と座標変換を確認する。
- [惑星姿勢](ROTATION_PROVENANCE.md)では基底の直交性・右手性、北極方向、自転方向、地球の歳差を確認する。
- [月](LUNAR_PROVENANCE.md)では位置・姿勢の固定値、距離単位、同時刻の地心視線による秤動を確認する。

移植時の CF96 比較には、461,300 bytes、SHA-256 `22edc2b9e4a0170bb805b2d564dbe90afb1ef7a17370db457887d28d0135dfb4` のデータを使用した。9 惑星・201 時刻で照合した位置と速度の許容差は、それぞれ `1e-12 AU` と `1e-13 AU/day`。現在の自動テストで扱う補間、単位、入力境界は [暦表の仕様](EPHEMERIS_PROVENANCE.md) に記載する。

## ソースの由来

改変ソースには原著作権表示と MIT 許諾文を残した。
ファイルごとの抽出箇所と変更内容:

- [ASTRONOMY_PROVENANCE.md](ASTRONOMY_PROVENANCE.md)
- [CATALOG_PROVENANCE.md](CATALOG_PROVENANCE.md)
- [EPHEMERIS_PROVENANCE.md](EPHEMERIS_PROVENANCE.md)
- [ROTATION_PROVENANCE.md](ROTATION_PROVENANCE.md)
- [LUNAR_PROVENANCE.md](LUNAR_PROVENANCE.md)

描画・操作を確認するには [GUI 操作ガイド](../gui/README.md)、対応する旧 Plus の機能と形式を調べるには [機能対応表](../compatibility/PLUS_FEATURE_MATRIX.md) を参照。
