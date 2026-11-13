# Plus の惑星・恒星表示と地球描画の調査

調査日: 2026-10-29。実施者: Codex。`3f47a39` を基点とする作業ツリーで、次の実装単位の契約を調べた。原本への操作は読み取りだけであり、この調査自体は描画コードを変更しない。「確認済み」は同梱文書・設定・公式ソース・ローカルファイルの静的確認を示す。旧 Plus を実行した比較や、天文学的精度の検証とは区別する。

## 参照位置と版

| 略記 | 絶対パス |
| --- | --- |
| `PLUS` | `PLUS_ROOT` |
| `REGULAR` | `MITAKA_ROOT` |
| `OFFICIAL` | `vendor/mitaka/sources/official/mitaka_source` |

対象 Plus は Windows 1.5.4 build101013、同梱 API 文書は 1.3.0 表示、公式ソースは Mitaka 1.3.1。Plus 文書のプロパティ契約と、標準版の科学計算・描画方法を同一版の証拠として扱わない。天の川・星座絵・風景の調査は [local-assets-audit.md](local-assets-audit.md) に分離している。

## 惑星表示の確定契約

`PLUS/doc/script_jp/planets.html` と `PLUS/scripts/gui.lua:84–112` を照合した。

| 機能 | API 文書の行 | メニューの行 | 確認できる契約 |
| --- | --- | --- | --- |
| 表示 | 12–18 | 85 | `Planets.visible` と `toggleVisible()`、bool |
| 名称 | 20–26 | 86 | `labels` と `toggleLabels()`、bool |
| 軌道 | 28–34 | 87 | `orbits` と `toggleOrbits()`、bool |
| 自転軸 | 36–42 | 88 | `axes` と `toggleAxes()`、bool |
| 大気 | 44–50 | 90–93 | `ATMOS_NONE` / `ATMOS_SINGLE` / `ATMOS_MULTIPLE` |
| 雲 | 52–58 | 94 | `clouds` と `toggleClouds()`、bool |
| 夜景 | 60–66 | 95 | `cityLights` と `toggleCityLights()`、bool |
| 食の影 | 68–82 | 96–98 | `shadows` / `shadowBorders`、各 bool |
| 本影・半影 | 同梱 1.3.0 文書に記載なし | 99–100 | `shadowUmbra` / `shadowPenumbra` と各 toggle がメニューに存在 |
| 倍率 | 84–94 | 102–106 | 宇宙の太陽・惑星、プラネタリウムの太陽・惑星の 4 倍率と、補間時間の秒数 |
| 地形強調 | 96–98 | 107–112 | 文書とメニューの整数値に不整合がある |

`setScaleTo` のメニュー引数は `(1,1,1,1,1)`、`(500,1,20,1,1)`、`(1000,25,100,5,1)`、`(1500,50,200,10,1)`。最後の 1 は補間時間で、前の 4 値は実半径に掛ける倍率である。許容する倍率の上下限は、この文書では定義されていない。

文書には `setScaleTo` 見出しが `setScale` になる誤記などがある。地形強調は文書が 1–5、メニューは 0–4 を使い、双方が順に 1、2、5、10、20 倍を説明する。未知の公開値をどちらかへ推測で固定しない。

### 公式計算と現在の表示の差

- `OFFICIAL/Mitaka/mtk_planets.cpp:291–296` は実半径へモード別の倍率を掛ける。同ファイルの `get_landing_radius_planet` は地表接近にも表示半径を使う。一方、ネイティブ版は通常の模式半径と、地表移動・連続飛行・地球月表示の物理半径を既に分離している。倍率を追加する際、見た目と航行半径の契約を混ぜない。
- `mtk_planets.cpp:552–562` は天体固定の Z 方向に `−1.3 Rz` から `+1.3 Rz` の軸を描く。`745` と `1022` に軸の表示判定がある。色は `(0.8,0.6,0.2)`、線幅は 1.5。これを採用する場合も、地図上の北と逆行天体の角運動量方向は異なる。
- ネイティブの `SolarBody.orientation` は J2000 黄道の基底。9 惑星は `planet_orientation`、月は `lunar_orientation` が同じ JD から計算済み。太陽の姿勢は固定値なので、太陽の科学的な自転軸を表す根拠にはならない。
- 既存 `SkyModel::solar_orbits` は 9 惑星を近似 1 周期の 181 点で標本化し、CF96 と月の共通期間で切り取る。月軌道は地心相対の 181 点で、表示時刻の地球位置を加える。切り取った軌道を閉じず、原版と同じ標本化・曲線であるとは説明しない。
- ネイティブの姿勢・位置計算の限界は `native/core/ROTATION_PROVENANCE.md`、`LUNAR_PROVENANCE.md`、`OBSERVATION_PROVENANCE.md` に記録済み。単一 JD を使い、UTC / UT1 / TT / TDB、光行時間、歳差章動等の補正を一括して実装済みとは扱わない。

## 恒星の表示・ラベル・マーク

`PLUS/doc/script_jp/stars.html` と `PLUS/scripts/gui.lua:140–155` を照合した。

| 機能 | API 文書の行 | 確認できる契約 |
| --- | --- | --- |
| 恒星表示 | 12–18 | `Stars.visible`、bool |
| 固有名 | 20–26 | `labels`、bool |
| 選択した固有名 | 28–34 | `selectedLabels`、bool。固有名表示が有効な場合の部分集合 |
| Bayer 名 | 36–42 | `bayerLabels`、bool |
| Flamsteed 番号 | 44–50 | `flamsteedLabels`、bool |
| HIP 番号 | 52–58 | `hipLabels`、bool |
| マーク | 60–66 | `markingType` は文字列 `None` / `Binary` / `ExoPlanets` |
| 明るさ | 68–86 | `brightness`、基準 1、時間付き変更。brighten / darken の増減幅は文書では不明 |
| 名前の選択集合 | 88–98 | `select` / `deselect` は空白区切り HIP 文字列、`isSelected` は HIP 文字列 |

`gui.lua:144` には `fadeLabels` / `toggleFadeLabels()` もあるが、同梱 1.3.0 文書にはない。距離による名称減衰の式は Plus について未確認。

`selectedLabels` の「選択」は名称表示の HIP 集合であり、画面で現在クリックしている 1 天体を意味しない。標準版 `mtk_selection.cpp:55–117` はコメント除去後の行全体をキーとして使うが、ローカル Plus の `data/selection.dat` は `HIP_7588: 1` 等の別形式（63 行以降）である。標準版ローダーの無条件流用や `StarNameRecord::is_featured` を選択集合とみなす実装はしない。

### 既存データで可能な名称構築

`native/core/include/mitaka/catalog.hpp` の `HipparcosRecord` は `is_double`、`flamsteed_number`、`bayer_id`、`bayer_subscript`、`constellation_id`、`ads_component` を保持している。追加の公開カタログは不要。固有名と系外惑星主星も既存ローカル追加カタログを優先できる。

- `OFFICIAL/Mitaka/mtk_stars.cpp:114–180` は Bayer、Flamsteed、星座略号、ADS 成分を組み合わせる。Bayer と Flamsteed は独立した表示スイッチ。
- `OFFICIAL/common/text/unicode.cpp:265–279` は Bayer ID 0–23 を α–ω に対応づけ、範囲外を文字にしない。欠測の `−1` と添字の欠測を区別する。
- `mtk_stars.cpp:695–720` は `is_double` を緑のマーク、系外惑星主星を黄色のマークに使う。`mtk_stars_2.cpp:464–483` は HIP なしの系外惑星主星を別色にもしている。既存 HIP リンクだけの描画を HIP なし天体まで対応済みと説明しない。
- 標準版は星座境界が表示される場合に名称内の星座略号を省く分岐を持つ。新 GUI の読みやすい名称構築と、原版のレイアウト・省略則の厳密一致は別項目とする。

描画件数や名称の衝突回避の制限は、読み込んだカタログ件数とは別に持つ。独自追加行や既知番号以外の行を表示上限に合わせてロード時に捨てない。

## グリッドの根拠と分離点

`PLUS/doc/script_jp/grids.html:12–58` は赤道・黄道・銀河・地平の各 grid と circleScales / squareScales の独立 bool を定義する。`60–66` は surfacePointer。`scripts/gui.lua:175–182` に同じ切替があるが、刻み・座標の元期・全表示モードへの適用範囲はこの文書だけでは確定しない。

| 公式ソース | 確認できる描画 |
| --- | --- |
| `Mitaka/main.cpp:1201–1313` | 球面 grid は経線 2h、緯線 15°、線の標本間隔 2°。数値も 2h / 15° 刻み |
| `Mitaka/main.cpp:1351–1387` | 赤道・銀河の座標変換を適用。銀河は `M_G2E` |
| `Mitaka/main.cpp:1398–1460` | プラネタリウムの黄道は 5° ごとの大円。3D は 100 AU の XY 面と軸、距離減衰 |
| `Mitaka/mtk_planetarium.cpp:253–327` | 地平方位は 45° 間隔の 8 方位、高度 15°。観測対象の姿勢・地点から基底を作る |
| `Mitaka/mtk_scale_line.cpp:62–104` | 円形目盛は 21 種。近距離の AU 目盛は黄道面、遠距離の光年目盛は銀河面 |
| `Mitaka/mtk_scale_line.cpp:269` 以降 | 方形目盛は天体中心のカメラに向いた平面、10 の冪の長さと視角による減衰 |

現在の `SkyView` と `HorizonView` の常時 grid、および `SolarSceneRenderer::drawOrbits` 内の XY grid は、この全機能と同義ではない。特に軌道スイッチから XY grid / Z 軸を分離する必要がある。銀河 grid は天の川で確定した公式基底を共有し、赤道図へ黄道変換を重複適用しない。地平変換には既存 `ObservationFrame` を使い、屈折や地球以外の地平面の未対応を隠さない。

## 地球のローカル画像

ローカル `PLUS/textures` の次の 3 枚はすべて JPEG、2048 × 1024 px。画像を再保存・複製していない。

| ファイル | SHA-256 | 公式の利用との関係 |
| --- | --- | --- |
| `earth_cloud.jpg` | `ea61087f63930ae1868373d7d27830bb504ea9408d1a4489bac507dc05c4b97a` | `mtk_planets.cpp:456` が同名でロード |
| `earth_lights.jpg` | `a867851b1e6a30f8985e197d79777d3935a111de297b76a941d88cc03fce56ea` | 同 460 が同名でロード |
| `earth_specular.jpg` | `1130776e7cb25110e29a4dc70a4e3a6a8a2b6c09e0994ac86f36f286f4494aa2` | 公式 464–465 の 2 ファイル名とは一致しない |

標準版が読む specular は `earth_specular_with_cloud.jpg` / `earth_specular_without_cloud.jpg`。手元の 1 枚をどちらかへ暗黙に代用しない。

`mtk_planets.cpp:570` 以降の地球描画には次の経路がある。

- 表面、夜景、雲の球には Z 軸 180° 回転がある。既存 `planet_surface` の経度オフセットと合わせて、二重回転を防ぐ。
- 夜景は `610–638` で加算合成。cityLights を無効にしても接近時の弱い表示が残る分岐がある。有効時の強度には太陽・地球・視点の方向が入る。bool を単純な全画素表示に置き換えて原版一致とはしない。
- 雲は `679–692` では加算合成、半径倍率は `1 + 10 / 6378.1 * topoZoom`。別の 3D 描画経路 `890–916` では `GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR` と `1 + 8 * topoZoom / Re` を使う。モードによる差がある。
- 雲 JPEG は不透明なので、JPEG の alpha をそのまま雲の被覆率にする根拠はない。画素色・照明・合成式を分けて確認する。

既存の `local_image` を使い、選択した data の兄弟 textures から元画像を読み取れる。欠損・破損時に警告を保持し、別の公開画像や別レイヤーで置換しない。通常球、地球月表示、地表表示、連続飛行の各経路で共通のレイヤー設定が必要。

## 大気散乱とローカル emmap.dat

`OFFICIAL/Mitaka/mtk_atmosphere.cpp` に単一散乱・多重散乱の計算があり、`main.cpp:802` が `data/emmap.dat` を読む。青い縁取りだけを大気散乱として実装する必要はない。計算式を描画や Windows スレッドから分離する独立単位にできる。

| 根拠 | 確認できる内容 |
| --- | --- |
| `mtk_planets.cpp:263–284` | 地球のスケール高度 8000 m、粒子数密度 `2.69e25`、描画殻の厚さ係数 6。火星は 11000 m、`4e23`、係数 8 |
| `mtk_atmosphere.cpp:127–141` | 波長 700 / 546.1 / 435.8 nm、Rayleigh 断面積の式と定数 |
| `mtk_atmosphere.cpp:541–568` | 散乱表のヘッダーと `RGBf` 配列の読み込み |
| `common/graphics/color.h:48` | `RGBf` は float 3 成分 |
| `mtk_atmosphere.cpp:587` 以降 | 表を用いる多重散乱光の積分 |
| `mtk_atmosphere.cpp:943–1005` | 単一散乱の 14 分割積分へ、多重散乱時の追加光量を合成。alpha は最大 RGB の 4 倍を制限 |
| `mtk_atmosphere.cpp:1163` 以降 | 半径・スケール高度・密度を表示倍率に合わせて変換 |
| `mtk_planets.cpp:799–800` | この公式版の火星は多重散乱フラグを false で渡す |

ローカル `PLUS/data/emmap.dat` は 983,088 バイト、SHA-256 は `cec4e25b01a793bdd131b896a3404ff40132bc31d6e94fe3c04ed9a3a3fc1013`。Windows の little-endian 配置と公式コードを照合し、以下を読み取った。

```text
int32  RN=20, ThN=4096
double R1=6378000, R2=6442000, H=8000, N0=2.5469e25,
       ThMax=1.884955644607544
float32 RGB[RN * ThN][3]
```

ヘッダーは 48 バイトで、`48 + RN * ThN * 12` がファイル長と一致する。半径と H は m、ThMax は rad。245,760 個の float は全て有限で、最小約 `7.20309e-16`、最大約 `7.25087e-7`。この値は手元の表の検算結果であり、独自データの寸法・内容を固定する条件ではない。

実装時はファイル容量、寸法の積の overflow、最低標本数、有限値、正の H / 密度、`R2 > R1 > 0` を検証し、エラーにパスと offset を含める。表の不在・不正を多重散乱成功として扱わない。単一散乱は別モードとして選択できる。公式は OpenGL 行列と Windows スレッド・大域変数に依存するため、科学計算を純粋関数へ分離し、既存の CPU 画像描画と接続する設計が必要。

## 次の実装単位と API 接点の案

この節は実装開始前の案であり、対応済み API の一覧ではない。

### 第 1 単位: 惑星 4 スイッチと恒星表示

GUI 共通の `display_options.hpp` に以下の値オブジェクトを置く案とする。

```cpp
enum class StarMarking { none, binary, exoplanets };
struct PlanetDisplayOptions {
    bool visible = true, labels = true, orbits = true, axes = false;
};
struct StarDisplayOptions {
    bool visible = true, proper_names = false;
    bool bayer_labels = false, flamsteed_labels = false, hip_labels = false;
    StarMarking marking = StarMarking::none;
};
```

`SkyView` / `HorizonView` は同じ設定を描画とクリック判定に使う。`SolarScene` は惑星設定を受け取り、通常球だけでなく地球月の実球、地表・飛行中の合成と実球の hit test にも可視性を反映する。名称のスイッチを恒星本体や惑星本体の可視性と混同しない。非表示にしても暦表・照明計算・航行対象の位置は変更しない。

3D 軸は既存の北軸と表示半径を使い、9 惑星と月を対象にできる。太陽の未確認の自転軸を固定基底から作らない。全天・地平図は現在記号表示なので、3D の軸機能を全モードで再現したとは説明しない。

恒星名称の文字列構築は AppKit を必要としない処理に分離する。固有名は既存の CP932 変換を利用する。系外惑星主星の bool と `marking` enum が同時に別状態を持たないよう、既存 `showsExoplanetHosts` を同じ enum への操作へ置き換える。Binary と ExoPlanets が同時にオンになる UI は旧契約と異なる。

`selectedLabels` の初期集合、`fadeLabels`、brightness の増減、4 倍率と補間は、未確定部分または別の表示契約を含むため、この単位の完了条件から分離する。未対応 Lua API を成功したふりで受け付けない。

### 状態保存と既存画面への接続

`SessionState` は現在 JSON v2 に `show_star_names` / `show_exoplanet_hosts` を持ち、`AppSessionCommands` が表示設定の保存・適用を集約する。惑星・恒星設定をここで共通の値オブジェクトへ集約し、メニュー、Lua ホスト、状態復元が同じ型を使う設計が適切。新しいスキーマ版を採る場合は preproduction 方針に従い、旧開発版の暗黙変換をしない。版・必須キー・bool・enum を先に検証し、不正入力で一部だけ適用しない。

`SkyCatalogRenderer` の固有名・系外惑星印は現在 SkyView 専用である。地平図でも追加ラベルを扱うなら、投影方法と恒星の表示規則を接点として分離し、SkyView の描画をそのまま複製しない。通常の全天図と地平図で表示・非表示、等級、選択判定が食い違わないことを受入条件にする。

グリッド担当との接点は `SolarSceneRenderer::drawOrbits` の grid 分離と、SkyView / HorizonView の grid 描画部分。惑星・恒星の新設定は grid の設定とは独立させる。

### 後続単位

1. 地球の雲・夜景を、ローカル 2 JPEG と公式式を根拠に独立レイヤーとして実装する。specular の対応は未確定のまま区別する。
2. 散乱表 loader と単一・多重散乱の計算を別責務にし、地球と火星の契約を明示する。元の Windows スレッドは移植しない。
3. 半径倍率と時間補間を、通常表示・物理航行の半径契約を明記したうえで追加する。地形強調値の不整合は別に解決する。
4. 衛星画像、土星・天王星の ring 画像もローカルに存在するが、画像の存在だけで軌道・半径・UV の対応が確定したとは扱わない。

## 必要な検証と未実施項目

- 名称は ID 0 / 23 / 範囲外、欠測、添字、ADS 成分、Flamsteed 単独、複合表示、独自の日本語固有名を確認する。
- 表示スイッチは全天・地平・3D、通常・地球月・地表・飛行中で描画と選択を照合する。軌道を消しても独立 grid 設定が維持されることを確認する。
- 軸は既存の姿勢を使い、地球・逆行惑星・月で方向と投影の座標系を検証する。太陽を対象外としたことを UI / 文書で明示する。
- 設定は全項目の保存往復、不正型・未知 enum・欠落・非対応版の拒否、再読込と再生中の更新を確認する。
- 雲・夜景・散乱は昼夜境界、極、画像継ぎ目、経度方向、殻の交差、表の端、欠損・破損・再読込を個別に確認する。テストに元画像を同梱しない。
- この調査では旧 Plus との画面比較、新しい描画実装、統合テストを実施していない。原本の読み取りと数値配置の検算を、描画完成や全機能互換の検証として報告しない。
