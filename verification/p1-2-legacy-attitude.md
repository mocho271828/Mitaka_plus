# 地平図の高度差と旧 Plus の地球姿勢

PR #8 と Windows 版 Mitaka Plus 1.5.4 build101013 のセレス・Voyager I・はやぶさを、同じ観測地点・数値 JD で比較した。[10 組の対照表](p1-2-legacy-attitude.tsv)には、現行地平図に描いた対象の方位・高度、旧版の注視命令後に保存したカメラの向き、旧式の地球姿勢を使った独立計算を併記した。

旧版は `Camera:look("Asteroid.Ceres")`、`Camera:look("Spacecraft.VoyagerI")`、`Camera:look("Spacecraft.Hayabusa")` を実行し、描画後に `State:storeAsInit()` で保存した。表の `legacy_exe_phase` と `state_sha256` はこの状態ファイルを特定する。旧版の HUD は、例えば保存方位 −90° を 90° と表示した。`legacy_api_az_negated_mod360_deg` は保存値をこの符号に換算した値である。旧版の高度・方位の測定対象は注視後のカメラであり、対象の点がその位置に描かれたかは別途、表示切替前後の実画面で判定する。

旧版 executable（SHA-256 `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`）の仮想アドレス `0x53F259–0x53F2B6` で、地球の北極と自転の係数 0.641、0.557、190.147、360.9856235 を確認した。これらは[公式通常版に残っている旧式の地球用係数](../vendor/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_orientation.cpp)と一致する。現行 PR は同じ公式ソースで選ばれている `calc_Earth_ec_to_pl_matrix_Captine2003` の歳差・自転モデルを使い、測地緯度・標高 0 で地球の扁平率を考慮する。[現行の自転モデル](../vendor/mitaka/native/core/src/rotation.cpp)・[観測地点の位置](../vendor/mitaka/native/gui/src/horizon_objects.cpp)。

対照計算は次の手順で再現できる。三角関数の角度と出力は度、距離は AU。表の `sun_to_earth_equatorial_j2000_au_xyz` と `sun_to_target_ecliptic_j2000_au_xyz` は、同梱実データから得た現行フレームの入力を各行に記録したものである。両版で比較したセレスの packed36、両探査機の PTH、地球の CF96 の各ファイルは SHA-256 が一致した。

1. `d = JD - 2451545`、`T = d/36525` とし、北極の赤経 `α = −0.641T`、赤緯 `δ = 90 − 0.557T`、自転角 `W = 190.147 + 360.9856235d` を求める。地球固定座標から J2000 赤道座標への回転は、列ベクトル・右手系で `Q = Rz(90 + α) Rx(90 − δ) Rz(W)`。
2. 緯度 φ、東経 λ から地球固定座標上の東 `e = (−sin λ, cos λ, 0)`、北 `n = (−sin φ cos λ, −sin φ sin λ, cos φ)`、天頂 `u = (cos φ cos λ, cos φ sin λ, sin φ)` を求める。対照計算の地球は半径 6378.1366 km の球とした。
3. 表の対象の日心黄道ベクトルを P、地球の日心赤道ベクトルを E とし、`v = Rx(23.43929111111111°) P − E − (6378.1366 / 149597870.7) Q u` を求める。東・北・上の成分は `v` と `Q e`、`Q n`、`Q u` の内積。方位は `atan2(東, 北)` を 0–360° に正規化し、高度は `atan2(上, hypot(東, 北))`。

旧版で読み取った高度と対照計算の差は、探査機 6 組で最大 0.000044°、セレス 4 組を含めても最大 0.000050° だった。一方、方位の読み戻しは、例えば三鷹の Voyager I で 270°、独立計算で 300.11685°（JD 2453695）となり、高度と同じ精度では一致しなかった。方位差を根拠に現行の座標変換を変更していない。
