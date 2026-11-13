# 惑星テクスチャの調査記録

確認日: 2026-10-29。
既存の `mitaka` と `mitaka_plus` の画像、および取得済み公式 Mitaka 1.3.1 ソースを読み取り専用で確認した。
画像の変換・置換・再保存は行っていない。
この記録は、手元の画像が公式配布時の原画像と同一であると保証するものではない。

## 読み込む場所

`mitaka` のテクスチャディレクトリ:

```text
MITAKA_ROOT/textures
```

`mitaka_plus` のテクスチャディレクトリ:

```text
PLUS_ROOT/textures
```

以下の表のファイル名を、それぞれのディレクトリに追加すると完全パスになる。
GUI が現在選択している `data` の親にある `textures` を参照すれば、対応する既存画像を使える。
公式の標準ディレクトリも `./data/` と `./textures/` が兄弟である。[mtk_directory.cpp:40](../../sources/official/mitaka_source/Mitaka/mtk_directory.cpp#L40)
同じファイル名でも内容が異なるため、別のデータディレクトリの画像を混ぜて補完しない。

## 最小実装に使える 10 枚

全ファイルが JPEG、RGB、アルファなし、幅:高さ = 2:1 である。
寸法・形式は macOS `sips` の読み取りで確認した。
両ディレクトリの同一性はファイルの SHA-256 で比較した。

| 表示対象 | ファイル名 | mitaka の寸法 | mitaka_plus の寸法 | 両ファイルの内容 |
| --- | --- | --- | --- | --- |
| 太陽 | `sun.jpg` | 1024 × 512 | 1024 × 512 | 異なる |
| 水星 | `mercury.jpg` | 2048 × 1024 | 1024 × 512 | 異なる |
| 金星 | `venus.jpg` | 1024 × 512 | 1024 × 512 | 同一 |
| 地球 | `earth.jpg` | 2048 × 1024 | 2048 × 1024 | 異なる |
| 火星 | `mars.jpg` | 1024 × 512 | 1024 × 512 | 異なる |
| 木星 | `jupiter.jpg` | 1024 × 512 | 1024 × 512 | 同一 |
| 土星 | `saturn.jpg` | 1024 × 512 | 1024 × 512 | 同一 |
| 天王星 | `uranus.jpg` | 1024 × 512 | 1024 × 512 | 同一 |
| 海王星 | `neptune.jpg` | 1024 × 512 | 1024 × 512 | 同一 |
| 冥王星 | `pluto.jpg` | 2048 × 1024 | 1024 × 512 | 異なる |

惑星 9 枚の対応は、公式の `plnti` の `tex_fn` と一致する。[mtk_planets.cpp:127](../../sources/official/mitaka_source/Mitaka/mtk_planets.cpp#L127)
太陽は別の描画系で `sun.jpg` を読む。[mtk_sun.cpp:138](../../sources/official/mitaka_source/Mitaka/mtk_sun.cpp#L138)
したがって拡張子を推測する探索は不要であり、この 10 個の固定名を対応表として扱える。
地球・冥王星の表面画像を使用しても、現在の CF96 由来の地球月重心・冥王星系重心の座標が惑星本体の中心へ変わるわけではない。

## 別用途の画像

主要な補助画像も存在するが、上の 10 枚だけで球面の基本色は描ける。
最小実装でこれらを読まない場合でも、既存ファイルはそのまま保持する。

| ファイル名 | 形式 | mitaka の寸法 | mitaka_plus の寸法 | 用途・注意 |
| --- | --- | --- | --- | --- |
| `moon.jpg` | JPEG | 4096 × 2048、RGB | 1024 × 512、Gray | 月面。現在の 10 天体とは別対象 |
| `earth_cloud.jpg` | JPEG、RGB | 2048 × 1024 | 2048 × 1024 | 雲の合成用 |
| `earth_lights.jpg` | JPEG、RGB | 2048 × 1024 | 2048 × 1024 | 夜間の都市光 |
| `earth_specular_with_cloud.jpg` | JPEG、RGB | 2048 × 1024 | なし | 公式 1.3.1 の反射用 |
| `earth_specular_without_cloud.jpg` | JPEG、RGB | 2048 × 1024 | なし | 公式 1.3.1 の反射用 |
| `earth_specular.jpg` | JPEG、RGB | なし | 2048 × 1024 | 旧データ側の反射用画像。上の 2 枚とは同名ではない |
| `saturn_rings.png` | PNG、RGB＋alpha | 1500 × 8 | 1500 × 8 | 環の半径方向の帯。球面へ貼らない |
| `uranus_rings.png` | PNG、RGB＋alpha | 1024 × 8 | 1024 × 8 | 環の半径方向の帯。球面へ貼らない |

地球の補助画像のロードは [mtk_planets.cpp:454](../../sources/official/mitaka_source/Mitaka/mtk_planets.cpp#L454)、環の対応は [mtk_planets.cpp:148](../../sources/official/mitaka_source/Mitaka/mtk_planets.cpp#L148) にある。
補助画像も両データで内容が異なる。

`mitaka_plus` にある `mercury.png`、`venus.png`、`jupiter.png`、`saturn.png`、`uranus.png`、`neptune.png`、`pluto.png`、`moon.png` は、すべて 1024 × 128、RGB＋alpha の地平線風景である。
`mercury.png` の画像内容を目視し、各ファイルが `Places:addLandscape` に指定されることも確認した。`PLUS_ROOT/data/defaultplaces.dat:6`
同名 JPEG が欠けた際に、この PNG を球面テクスチャとして代用してはいけない。

## 公式の UV と画像の向き

通常球の座標は右手系で、`+Z` が北極、経度 `φ` は `+X` から `+Y` に増える。
`θ` を北極からの角度、`latitude` を緯度とすると、公式の球と UV は次になる。[gl_common.cpp:55](../../sources/official/mitaka_source/common/graphics/gl_common.cpp#L55)

```text
p = (sinθ cosφ, sinθ sinφ, cosθ)
u = φ / (2π)
v = 1 − θ/π = 0.5 + latitude/π
```

惑星では通常球の `bCelestial=false` を使う。
天球向けの `true` は `u` が逆向きになるため、そのまま惑星へ流用しない。

公式 JPEG/PNG ローダーは元画像の行 `r` を `height−1−r` に反転してから OpenGL へ渡している。[image.cpp:272](../../sources/official/mitaka_source/common/graphics/image.cpp#L272)、[image.cpp:379](../../sources/official/mitaka_source/common/graphics/image.cpp#L379)
上から下へ並ぶ画素配列を使う native 側では、次の画像座標に相当する。

```text
v_top = θ/π = 0.5 − latitude/π
```

画像のロード時とサンプル時の両方で反転すると、上下が逆になる。
実際の `earth.jpg` は上端が北極、中央付近がグリニッジ、左右端が日付変更線付近の正距円筒図である。
native の画像デコードと画面出力の座標系は、この目印を使って別途検証する。

公式の **3D チャート用 `draw_planet2`** は、火星だけ経度補正が `0°`、他の惑星が `180°` である。[mtk_planets.cpp:897](../../sources/official/mitaka_source/Mitaka/mtk_planets.cpp#L897)
惑星固定座標での球面方向 `n` を使って画像を引く場合は、次の対応になる。

```text
longitude = atan2(n.y, n.x)
u_mars = wrap01(longitude / (2π))
u_other_planets = wrap01(longitude / (2π) + 0.5)
v_top = 0.5 − asin(clamp(n.z, −1, 1)) / π
```

この補正を「公式の全描画経路共通」とは扱わない。
環の影を描く別経路は、補正なしの `u=φ/(2π)` を使っている。[mtk_planetary_ring.cpp:646](../../sources/official/mitaka_source/Mitaka/mtk_planetary_ring.cpp#L646)
最小 GUI が上の規約を採る場合は、「公式 3D チャートの経度規約に対応」と記載するのが正確である。

公式サンプラーは横方向が `REPEAT`、縦方向が `CLAMP_TO_EDGE`、線形補間と mipmap を使う。[gl_texture.cpp:84](../../sources/official/mitaka_source/common/graphics/gl_texture.cpp#L84)
CPU サンプラーでも左右の継ぎ目を wrap、上下の極を clamp する。
縮小画像を使う場合は、画素中心と端の補間で範囲外を参照しないことを確認する。

太陽は通常球へ `sun.jpg` を貼る別処理で、確認した経路には惑星用の `180°` 補正や惑星の自転姿勢計算がない。[mtk_sun.cpp:267](../../sources/official/mitaka_source/Mitaka/mtk_sun.cpp#L267)
惑星用の補正を太陽にも一律に適用しない。

## 日時と惑星の姿勢

画像の UV と、天体を空間のどちらへ向けるかは別の処理である。
公式の姿勢行列 `M` は **J2000 黄道座標から惑星固定座標への変換** を表す。[mtk_planet_orientation.cpp:242](../../sources/official/mitaka_source/Mitaka/mtk_planet_orientation.cpp#L242)
描画は転置 `Mᵀ` を使う。[mtk_object_orientaion.cpp:204](../../sources/official/mitaka_source/Mitaka/mtk_object_orientaion.cpp#L204)
現在の native GUI の黄道 J2000 座標に対しては、表面点の配置は `center + Mᵀ × surfacePoint`、黄道系法線からの UV 計算は `M × normal` となる。

地球以外の公式式は次の形である。
ここで `α,δ` は極の赤経・赤緯、`W` は自転角、回転関数の角度単位は度である。

```text
d = JD − 2451545.0
T = d / 36525.0
εJ2000 = 84381.448 / 3600°
M = Rz(−W) Rx(δ−90°) Rz(−90°−α) Rx(εJ2000)
```

各天体の `α,δ,W` は [mtk_planet_orientation.cpp:65](../../sources/official/mitaka_source/Mitaka/mtk_planet_orientation.cpp#L65) にある。
金星・天王星は `W` の日周係数が負であり、全惑星へ同じ自転方向を適用できない。
地球は別の歳差と回転角の計算へ分岐するため、同ファイルの `calc_planet_orientation_angle` の地球 case だけでは公式と同じ日時連動にならない。[mtk_planet_orientation.cpp:199](../../sources/official/mitaka_source/Mitaka/mtk_planet_orientation.cpp#L199)

最小実装で姿勢計算を省略する場合は、テクスチャ付きの模式球として扱う。
カメラ回転で表面の見え方が変わっても、実日時の自転、極方向、地表の昼夜を再現した表示とは説明しない。
太陽からの方向による照明を加えても、姿勢計算の代わりにはならない。

## データの取り扱いと今回の確認範囲

再利用方法は既存ファイルの読み取りであり、アプリへの画像同梱や再配布はこの調査では行わない。
既存クレジットは地球に NASA Earth Observatory の Blue Marble、金星・木星・土星環などに Bjorn Jonsson、その他の惑星・太陽・月などに James Hastings-Trew の画像集を記載している。`MITAKA_ROOT/locale/theater/credit_roll_E.txt:36`
このクレジットだけでは個々の現存画像の由来・配布条件まで確定できず、公式ソースコードのライセンスをそのまま全画像へ適用しない。

今回はファイル存在、メタデータ、SHA-256 による相互比較、地球 JPEG と地平線 PNG の目視、および公式のロード・球面描画・姿勢処理を確認した。
native 側の画像デコード、サンプラー、画面描画の実装検証は別途必要である。
Wine ランタイム、元アプリの実行環境、全衛星画像、法線マップ、地形パッチの調査は含めていない。
