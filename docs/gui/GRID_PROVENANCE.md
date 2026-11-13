# 座標グリッド・距離目盛の根拠

2026-10-29 に [公式 Mitaka 1.3.1 のソース](../sources/README.md) を参照し、ネイティブ版で採用する幾何と表示範囲を確認した。

Plus の互換対象は Windows 1.5.4 build101013 であり、同梱 API 文書は 1.3.0 表示である。`doc/script_jp/grids.html:12–58` と `scripts/gui.lua:175–182` で確認したのは、赤道・黄道・銀河・地平、円形目盛・方形目盛の独立した切替である。標準版の描画式を使うことは、Plus の実行画面や全モードとの一致を意味しない。

## 球面グリッド

`grid_geometry.cpp::make_coordinate_grid` は、投影前の J2000 赤道座標列を返す。既存の `equatorial_direction`、`equatorial_coordinates`、`j2000_ecliptic_to_equatorial`、`ObservationFrame::to_equatorial` を利用し、描画用に別の暦計算を持たない。

| 種類 | ネイティブ契約 | 公式 1.3.1 の根拠・相違 |
| --- | --- | --- |
| 赤道 | 赤経 30°、赤緯 15°、線上の標本間隔 2° | `Mitaka/main.cpp:1201–1313` の球面格子。適用は `1351–1374` |
| 銀河 | 銀経 30°、銀緯 15°、線上の標本間隔 2° | 同じ球面格子に銀河基底を適用。`main.cpp:1377–1387` |
| 黄道 | J2000 黄道面の大円 1 本、標本間隔 2° | `main.cpp:1398` 以降のプラネタリウム表示は 5° 標本。ネイティブ版では 2° に細分する |
| 地平 | 方位 45°、高度 15°、線上の標本間隔 2° | `Mitaka/mtk_planetarium.cpp:253–327` の方位ラベルは 45°、高度ラベルは 15°。旧格子自体は `dlClstSphere` の 30° 経線を再利用するため、方位線の密度は異なる |

赤道・銀河・地平の緯線または高度線は −75° から +75°。極で点に退化する線は省き、経線の両端で南北の極を表す。緯線と黄道の末尾には始点を再掲し、一周後の丸め差による隙間を防ぐ。赤道・銀河・黄道の格子は日時や観測地点で変わらない。日付時点の平均赤道・黄道へ別途歳差を適用する格子ではない。

### 銀河基底の共有

`common/astro/astrometry.cpp:135–141` は銀河中心方向 `vGC`、銀河北極 `vGN`、外積 `vGO` を列に持つ `M_G2R` を作り、赤道から黄道への変換との積を `M_G2E` としている。ネイティブ版は天の川画像に使っていた同じ基底を `grid_geometry.cpp` に集約し、背景画像と格子で共有する。

- 銀河中心方向: 赤経 17h 45m 40.0383s、赤緯 −29° 00′ 28.069″。
- 銀河北極方向: 赤経 12h 51m 24s、赤緯 +27° 08′。
- 第 2 軸: 北極方向と中心方向の外積。

この 2 方向は厳密には直交しない。既存の背景画像との整合を保つため、逆変換は転置で代用せず、この基底の逆行列を使う。公式の float 基底・転置逆変換とのビット一致は主張しない。赤道座標の描画に黄道変換を重ねず、太陽系 3D へ渡す場合だけ既存コアで J2000 黄道へ変換する。

公式 `astrometry.cpp:128` の黄道傾斜角は 23.43870583°、既存ネイティブコアの J2000 変換は 84381.448″ である。格子は既存コアに合わせる。両者の差を隠して原版と同一の座標変換とは説明しない。

### 地平座標の範囲

地平格子は `AppObserver` で選んだ地球上の地点と、表示中の JD に対応する `ObservationFrame` を使う。方位は真北 0°、東 90°、高度 0° は幾何学的な地平であり、負の高度も保持する。地球以外の惑星・衛星の地表視点に対応した局所格子ではない。

地球の姿勢には既存の公式由来の変換を使い、独立した歳差補正を二重適用しない。大気差、地形、観測者の視差、UTC / UT1 / TT の変換などは追加しない。精度と省略した補正は [OBSERVATION_PROVENANCE.md](../core/OBSERVATION_PROVENANCE.md) に従う。

## 太陽系 3D での表示契約

赤道・銀河・地平の格子はカメラを中心とする方向球として表示する。実距離を持つ天体や、太陽を中心とする距離目盛とは区別する。黄道は公式 `main.cpp:1398–1460` の宇宙表示を参照し、太陽を原点とする XY 面の輪郭と、原点から ±100 AU までの軸を線で描く。面の範囲は各軸 −100 AU から +100 AU である。

公式の黄道面の減衰は `100 AU / ds.scale` に基づく。線画には、公式の半透明面の塗りつぶしと距離に応じた減衰を適用していない。ネイティブのカメラ距離が旧 `ds.scale` と同一であるとは保証しない。線幅、色、ラベル配置、AppKit の投影や重なりも旧 OpenGL 画面との一致を検証したものではない。軌道の表示スイッチと格子の表示スイッチを分離する。

## 円形距離目盛

`Mitaka/mtk_scale_line.cpp:62–104` の 21 種の半径を使う。AU の目盛は黄道面、光年の目盛は共有する銀河基底の面に置く。

| 単位 | 半径 |
| --- | --- |
| AU | 1、10、100、1000、10000 |
| 光年 | 1、3、10、30、100、300、1000、3000、10⁴、10⁵、10⁶、10⁷、10⁸、10⁹、10¹⁰、1.38 × 10¹⁰ |

公式 `make_scale_circle_curve` は太陽中心と銀河中心の両方を持つ。ネイティブ版は太陽中心の目盛を対象とし、銀河中心への切替は実装範囲に含めない。

公式 `get_scale_circle_alpha` と `mtk_calc_alpha.cpp` は、尺度と半径の比が 1 から 5 の間で線形に濃くなり、14 から 70 の間で線形に薄くなる。ネイティブ版もこの区間を使うが、比の分子にはネイティブのカメラ距離を使う。旧 `ds.scale` と意味が同じとは限らず、同じ視点操作で同じ減衰になるという保証ではない。

現在の `SolarCamera` は距離を最大 1000 AU に制限する。この上限と減衰条件のため、定義しているすべての半径が現行ビューで見えるわけではない。光年規模などの巨大な目盛を表示可能にした、あるいは銀河・宇宙規模の航行を実装したとは扱わない。

## 方形距離目盛

公式 `mtk_scale_line.cpp:269` 以降は、視点が向いている対象を中心に、カメラへ正面を向けた正方形を描く。一辺は 10⁰ m から 10²⁷ m までの 28 種。ネイティブ版では中心を `camera.target`、面の軸をカメラ基底に合わせる。

透明度は公式の `calc_alpha(0.01, 5.0, side / camera_distance, 2)` を参照する。`mtk_calc_alpha.cpp::calc_alpha` は比が 0.01 以下または 5 以上で 0、0.01–0.05 と 4.4–5 で線形に減衰し、最大 0.9 となる。定義する指数の範囲と、カメラ距離に応じて実際に描く範囲を区別する。

## 投影の境界と検証

円筒投影では天頂・天底の方位、赤道座標の極の赤経が一意に定まらない。投影直前の線分について、極にある端点の経度成分を隣接点から引き継ぐ。これにより、天頂付近の方位線が任意の 0° 方向へ斜めに曲がる描画を防ぐ。天文座標の変換結果自体は変更しない。

太陽系表示では既存の `project_solar_segment` で手前の面をクリップし、投影後に表示矩形でも線分を切ってから Core Graphics へ渡す。方向球の手前の面付近では投影座標が非常に大きくなるため、描画コンテキストのクリップだけに任せると、格子を含むパス全体が描かれない場合があった。この境界を描画前に処理する。

`GridGeometryCache` は新しい地点・日時を `ObservationFrame` で検証してから置き換える。不正な緯度や非有限の日時で、既存の格子を部分的に変更しない。距離目盛の半径・距離・角度とカメラの有効性は、距離目盛モジュールと既存のカメラ API で検査する。

2026-10-29 に次の 4 対象で AddressSanitizer / UndefinedBehaviorSanitizer の成功を確認した。格子幾何・距離目盛・描画の 3 対象は通常実行でも成功した。描画テストはビットマップを比較するもので、旧 Plus の画面を比較基準にはしていない。

- `test_grid_geometry.cpp`: 格子の線数と有限値、極、閉曲線の継ぎ目、黄道・銀河の既知方向、共有銀河基底の往復変換、地点・日時による地平変換、無効入力。
- `test_distance_scales.cpp`: 21 半径、光年から AU への換算、円の平面・閉曲線、減衰区間、方形の中心・向き・辺長、近接カメラ、非有限値などの拒否。127 項目が成功した。
- `test_grid_renderer.mm`: 独立した表示切替、描画範囲外への漏れ、地平格子の地点・日時依存、方向球のカメラ位置・距離からの独立、無効な観測条件での状態保全、天頂・天底付近の方位線、極付近の拡大、近接カメラでのクリップ。87 項目が成功した。
- `test_sky_background.mm`: 共有する銀河基底と背景画像の UV 座標との対応、既知方向、継ぎ目、往復変換、画像読込みなどの既存回帰。

修正を個別に外した場合の回帰テストで、次の差を確認した。

- 表示矩形によるクリップを外すと `enabled solar grid or distance scale drew no lines` で終了コード 1。
- 極の経度成分を引き継ぐ処理を外すと `horizontal meridian veered away from its azimuth near the zenith or nadir` で終了コード 1。

これらの検証は、アプリ全体の操作、状態復元、Lua 接続、旧 Plus との画面比較の合格を代替しない。

## 初期値と確認範囲

公式 `mtk_switches.cpp:125–139` は `swScaleLine = SCALE_CIRCLE`、赤道・黄道・地平・銀河の各表示は false である。初期値はこれを根拠に円形目盛を有効、方形目盛と座標格子を無効とする。Plus の初期化スクリプトや ini による明示値・上書き順序は未確認であり、Plus の最終的な初期画面を再現したとは主張しない。

## 元コードの許諾

参照した公式ソースは MIT 許諾。元の著作権表示を以下に保持する。利用者のデータや画像の再配布条件を、このコードの許諾から推定しない。

Copyright (c) 2007   Tsunehiko Kato

Copyright (c) 2012   Tsunehiko Kato

Copyright (c) 2007   Tsunehiko Kato and 4D2U Project, National Astronomical Observatory of Japan

Copyright (c) 2007-2015   Tsunehiko Kato and 4D2U Project, National Astronomical Observatory of Japan

Copyright (c) 2007-2008,2014-2016   Tsunehiko Kato and 4D2U Project, National Astronomical Observatory of Japan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
