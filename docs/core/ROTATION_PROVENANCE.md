# 惑星姿勢の由来と対応範囲

`src/rotation.cpp` は、公式 Mitaka 1.3.1 の `Mitaka/mtk_planet_orientation.cpp` から計算部分を抽出した改変版である。
公式 ZIP と展開原本は編集していない。
原著作権表示と MIT ライセンス全文は `src/rotation.cpp` に保持した。
非公式 macOS 移植のコードはコピーしていない。

取得元: <https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_131.zip>

原本パスは `vendor/mitaka/sources/official/mitaka_source/` からの相対パス。

| 原本 | 参照・抽出した機能 | SHA-256 |
| --- | --- | --- |
| `Mitaka/mtk_planet_orientation.cpp` | 自転角と北極の赤経・赤緯、地球専用の歳差・自転、黄道から惑星固定座標への行列 | `ee18f5b31e7685be7a5f5ce1ed27ab791976b820176811b6db75b6d7eed32189` |
| `common/math/vector3.h` | 原本行列の回転順序の確認、比較用ビルド | `0a7827644a754c009842ddded726c1e80bead0a390dc743ca957c34006606d91` |
| `common/astro/astro_const.h` | J2000 黄道傾斜角、比較用ビルド | `81de471ed93d07889ad9e0f11ca320b96404421d82d80715eb8959b0f2b3f592` |

## 座標と自転の契約

`planet_orientation(Planet, jd)` は `BodyOrientation` を返す。
`x_axis`、`y_axis`、`north_axis` は惑星固定座標の X、Y、Z を J2000 黄道座標で表した単位ベクトルで、右手正規直交基底をなす。
X は赤道上の東経 0 度、Y は東経 90 度、Z は北極である。
惑星固定ベクトル `(x,y,z)` の黄道座標は `x*x_axis + y*y_axis + z*north_axis` で得られる。
逆変換は各基底との内積で得られる。

公式 `calc_planet_ec_to_pl_matrix` が返す行列は黄道から惑星固定座標への変換である。
新 API の基底は、この行列の各行に対応する。
地球以外は `calc_planet_orientation_angle` の赤経 `alp`、赤緯 `dlt`、自転角 `W` の係数を保持し、次の逆変換で基底を求める。
`Rx` と `Rz` は右手系の能動回転、角度は度、積は右から作用する。

```text
body_to_ecliptic = Rx(-epsJ2000) * Rz(90+alp) * Rx(90-dlt) * Rz(W)
epsJ2000 = 84381.448 / 3600
```

金星・天王星は `W` の時間変化が負であり、基底の北極を反転させずに逆行を表す。
北極は公式の地図上の北で、これらの惑星の角運動量の正方向とは異なる。
冥王星は公式の北極 `RA=132.993` 度、`DEC=-6.163` 度と、正の自転率を保持する。
軌道面の法線に対する地軸傾斜のスカラー値は返さず、描画側は基底から軸方向を得る。

地球は公式 `calc_Earth_ec_to_pl_matrix_Captine2003` の歳差多項式と自転式を使う。
`calc_planet_orientation_angle` の地球用角度は、公式の実際の姿勢行列でも使われていないため抽出しない。
旧 `Lieske1977` 関数も使用しない。

```text
body_to_ecliptic = Rx(-epsJ2000) * Rx(eps0) * Rz(-PhiA)
                  * Rx(-omgA) * Rz(chiA) * Rz(spin)
eps0 = 84381.406 / 3600
spin = 360 * (0.7790572732640 + 1.00273781191135448 * (jd-2451545))
```

`eps0` と `epsJ2000` は原本で別の値なので同一化しない。
原本で `GMST` と命名された自転の線形式を保持するが、新 API が時系補正済みの恒星時を計算するとは扱わない。

## 時刻、入力、未対応範囲

原本のアプリケーションは一つの JD を位置・姿勢の計算へ渡す。
新 API もこの表示用近似を保持し、UT1・TT・TDB の変換、閏秒、章動、極運動、光行時間の補正を行わない。
現在の IAU モデルへの更新や、観測用の精度検証は今回の範囲に含めない。
数値上は先発 Gregorian 年 -4712..9999 の JD を受け付ける。
これは演算可能な範囲であり、長期間のモデル精度を保証するものではない。

非有限 JD と不正な `Planet` 値は `std::invalid_argument`、範囲外の有限 JD は `std::out_of_range` を送出する。
不正な値をゼロ姿勢に置き換えない。
計算は値型だけを使い、変更可能な共有状態や描画依存を持たない。
三角関数の前に角度を 360 度で還元するため、原本の巨大な角度を直接 radian にする計算とは丸め差がある。

太陽・月・衛星は対象外である。
公式の太陽描画には惑星と同じ姿勢モデルの登録がなく、GUI も固定表面を維持する。
画像経度の差分は姿勢 API に混ぜず、GUI 側で扱う。
公式の球メッシュは `longitude=360u`、`latitude=180v-90` で、惑星表面描画は火星に 0 度、他の 8 惑星に 180 度の画像回転を適用する。
この画像差分を基底へ重ねて適用すると、経度が二重にずれる。

## 検証と再生成

通常の `make test` は原本を必要としない。
`tests/test_rotation.cpp` は全 9 惑星と対応暦の端点を含む複数時刻で、基底の単位長・直交性・右手性・逆変換を検証する。
J2000 の北極、地球の傾斜と Greenwich 方向、金星・天王星の負の自転率、地球の歳差、公式から生成した固定値、不正入力も検証する。

公式との比較は次のコマンドで再実行できる。

```sh
# このリポジトリのルートから実行
cd vendor/mitaka/native/core
make rotation-reference-test
make BUILD_DIR=build/sanitize SANITIZE=address,undefined rotation-reference-test
build/test_rotation_upstream --dump
```

`tests/extract_rotation.awk` は上記原本から許諾表示と 3 関数を本文変更なしで `build/reference_rotation.cpp` へ抽出する。
必要な関数や終端が欠けていれば失敗する。
比較用プログラムだけが原本の `vector3.h` と `astro_const.h` を使い、コア本体は C++17 標準ライブラリのみを使う。
`--dump` は通常テストの固定値を再生成し、17 桁の値を標準出力へ表示する。

比較範囲は J2000、1700..2100 年の 201 時刻、対応暦全域の 201 時刻、J2000 前後の秒・日・世紀単位の時差で、合計 33,129 成分を照合する。
単位ベクトル成分の許容差は J2000 で `2e-14`、1700..2100 年で `2e-9`、対応暦全域で `5e-8` とする。
これは角度還元と演算順序の差を含む実装回帰の基準であり、天体姿勢の観測精度を表す値ではない。
