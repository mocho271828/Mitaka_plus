# N07 地名・風景 / N08 雲・夜景の接続前監査

2026-10-29。UNIT5 の機能を変更せず、次単位の契約を確認した。対象はローカル Plus 1.5.4 build101013 の同梱文書・データ、取得済み公式標準版 1.3.1 ソース、現在の native 実装である。原本の実行・変更、外部データの取得、新規依存の導入は行っていない。

Plus の API 文書は同梱 1.3.0 版である。標準版の式を確認できても、Plus 1.5.4 の全モードが同じ式とは認定しない。以下の「公式」は標準版ソースの根拠、「Plus 文書」はローカル同梱文書の根拠を表す。今回の監査では PE の追加解析を行っていない。

## 参照と再照合

`PLUS` は `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。`OFFICIAL` はリポジトリ内 `sources/official/mitaka_source`。先行する [資産監査](../local-assets-audit.md)、[描画監査](../local-rendering-audit.md)、[観測地 loader provenance](../../../native/core/PLACE_CATALOG_PROVENANCE.md) を参照し、以下の SHA-256 を元ファイルの読み取りで再照合した。画像を複製・再保存していない。

| PLUS からの相対パス | SHA-256 |
| --- | --- |
| `doc/script_jp/places.html` | `c5cb2f015242ec8ba41710ddda7de5d09604bea72ae89c662c30d00436aae9c4` |
| `doc/script_jp/grids.html` | `053642ea93e30987408d42e6e6daf455106d546a06bc23ea55b080751ba82336` |
| `doc/script_jp/planets.html` | `8e1c554c47ceace2c2e0a14abec4373a9ff620e8ee59d2e238971d5db5537198` |
| `data/defaultplaces.dat` | `63957b4797482ba54da1ada418f647f6438e65ba360db0fcbc903642802ece34` |
| `data/defaultplaces_jp.dat` | `6932bd9aabf13fefc5b7bae570fe903f107da96db57751e85373b2f60507c258` |
| `data/places_jp.dat` | `d61680e75d480a46825d429b05487b7e96f2e6e17742bc9e454b7899f80bde0c` |
| `textures/earth_cloud.jpg` | `ea61087f63930ae1868373d7d27830bb504ea9408d1a4489bac507dc05c4b97a` |
| `textures/earth_lights.jpg` | `a867851b1e6a30f8985e197d79777d3935a111de297b76a941d88cc03fce56ea` |
| `textures/earth_specular.jpg` | `1130776e7cb25110e29a4dc70a4e3a6a8a2b6c09e0994ac86f36f286f4494aa2` |

文書は Windows-31J から UTF-8 へメモリ内で変換して読んだ。ファイル名だけから文字コード、画像の用途、単位を推定しない。

## N07: 保持済みのデータと現在の接続

[`place_catalog.hpp`](../../../native/core/include/mitaka/place_catalog.hpp) / `place_catalog.cpp` は `Places:addPlace`、`addLabelGroup`、`addLandscape` のリテラル呼出しだけを解析する。Lua を実行する loader ではない。観測地、ラベル群、風景の各配列に原順・重複・CP932 の文字列 bytes を保持する。経度は有限値をそのまま、緯度は ±90° で検査する。風景の二つの offset は未解決の原引数として保持する。

一方、戻り値は原ファイル全 bytes と出典別の安定 ID を持たない。現在の GUI 用 [`observer_places.cpp`](../../../native/gui/src/observer_places.cpp) は日本語の既定ファイル、追加ファイルの順で読み、`(target_name, name_bytes)` が同じ観測地を後の値で置き換える。ラベル群と風景を GUI モデルへ渡していない。したがって、この GUI の実効一覧だけから原定義の重複・出典・言語を復元することはできない。

`AppObserverCommands.mm` は全地点を一覧へ出すが、選択可能なのは `Planet.Earth` とその子 ID。入力された緯度・経度を地平図の `ObservationFrame` へ反映する。画面上の経度の正規化は原データ変更ではない。地点 ID、名称、風景、ラベル群はセッションの観測地点として保存されず、現在は地球の緯度・経度を保存する。観測地の追加・編集・書出し UI、地名の天体表面描画、地上風景は未接続である。

地球以外への接点は既存の `SurfaceNavigation` / `SurfaceSite`。天体固定座標の法線・東・北を経緯度から作り、同日時の `BodyOrientation` で J2000 黄道へ回す経路を既に持つ。地球用の恒星時変換を他天体へ流用しない。観測地 target の解決、対象天体の姿勢・半径の根拠、未解決 target の診断は別途必要である。

## N07: 文書から確定する契約と未確定点

| 根拠 | 確認できる内容 | 実装前に残る点 |
| --- | --- | --- |
| `places.html:12–30` | `pointer`、`labels`、`labelSize` と切替 | `labels` 節の見出しが `pointer` と重複する誤記がある。見出し一つで API を決めず、anchor、例、toggle 本文を照合する |
| `places.html:31–38` | `landscape` はプラネタリウムの風景表示 | 原版の初期値、他表示モードへの適用 |
| `places.html:39–41` | ラベル群名、表示開始距離、サイズ、RGBA。同名設定は更新 | 距離の単位、カメラ距離との関係、サイズ倍率の適用順 |
| `places.html:42–44` | 天体、風景名、画像、垂直倍率、二つの offset。アプリ相対または絶対パス。alpha を持つ PNG 等 | 引数の水平・垂直順序、垂直 offset の尺度、投影式 |
| `places.html:45–47`、`abouttargets.html:53–56` | `targetName`、表示名、東経・北緯が正、ラベル群、風景。無効/空の群・風景は `Default`、同名は更新 | 更新キーが表示名・完全 target ID のどちらか、出典と言語ごとの実効順序 |
| `grids.html:60–68` | `Grids.surfacePointer` と toggle | `Places.pointer` と同じ実体を指すかは未確認 |

風景の宣言は `scale, horOffset, verOffset` の順だが、既定データの `.5, .34, -150` などは第 5 引数が垂直、第 6 引数が水平と読むと自然である。この観測だけで順序を入れ替えない。原 bytes と `offset_arguments[2]` の契約を維持し、Plus の引数取込みと投影まで静的に追って確定する。

ローカル風景は 21 PNG で、1024×128 と Greenwich の 1024×256、RGBA を持つことが先行監査で確認されている。これは観測値であり、追加画像の件数・寸法の固定条件にはしない。追加定義の `city2` と `City2` のような名前の大小文字差を無断補正せず、未解決参照として残す。

公式標準版の [`mtk_draw_places.cpp`](../../../sources/official/mitaka_source/Mitaka/mtk_draw_places.cpp) は経緯度を単位球へ写し、地形または球面上にラベルを置く。`PlaceItem` は `R1/R2`、alignment、色等を持つ別形式であり、Plus の `addLabelGroup(distance,...)` と同義ではない。距離・角度による減衰を流用して Plus 一致としない。

公式の地表ポインタは `mtk_planets.cpp:836–844` で対象天体の着陸位置を取得し、`draw_pointer_on_sphere` へ渡す。緑の十字・方位・経緯度で、視点が球内や遠方のときに抑止する。マウス位置へ追従するカーソルという根拠ではない。公式式を独立 native 機能に採用する場合も、Plus の二つの pointer API の alias と混同しない。

### N07 の実装境界案

1. 出典と原定義を全件持つモデルを用意し、原配列と描画用の実効定義を分ける。既存のリテラル parser と文字コード変換を再利用し、同名解決を元配列の削除で表さない。
2. target 解決、ラベル群、風景の解決結果と診断を値として固定する。未知 target・欠損画像・不正形式でも原行を一覧に残す。
3. ラベルと地表ポインタは太陽系の既存姿勢・投影・深度へ接続する。表示距離の単位と pointer の意味が確定してから Lua と同じ設定へ接続する。
4. 風景は offset 契約確定後、既存 `HorizonView` の方位・高度投影と描画 clip に接続する。地平以下の塗りつぶし、星空背景、風景の前後関係を明示する。通常の惑星球テクスチャをパノラマの代用品にしない。
5. 追加・編集は原本を上書きせず、独立した利用者の出力先と明示的保存操作を設ける。セッションには原 bytes の一致を検証できる選択 ID と設定を保存し、不明な ID を別の地点へ差し替えない。保存形式・書出し先は着手時の契約とする。

## N08: 既存画像 loader と描画経路

`earth_cloud.jpg` / `earth_lights.jpg` は 2048×1024 JPEG で、alpha による雲量は持たない。`earth_specular.jpg` を雲または夜景へ代用しない。公式の鏡面画像は `earth_specular_with_cloud.jpg` / `earth_specular_without_cloud.jpg` という二つの別名であり、ローカルの一枚との対応は未確定である。

[`planet_textures.mm`](../../../native/gui/src/planet_textures.mm) は現在、主要 11 天体の基本画像だけを選択 data の兄弟 `textures` から読む。雲・夜景の読み込みは未接続。既存 [`local_image.mm`](../../../native/gui/src/local_image.mm) を共用できる。ImageIO による JPEG/PNG の読取、通常ファイル、終端・寸法・画素数、EXIF 方向を検証し、最大 1024 px の sRGB straight RGBA を返す。PNG の alpha は維持し、JPEG の alpha は不透明となる。元画像を再保存する必要はない。

[`planet_surface.cpp`](../../../native/gui/src/planet_surface.cpp) は球の交差、最近接の不透明表面、姿勢の転置、経度 wrap と bilinear sampling を持つ。現在の基本照明は `0.3 + 0.7 * max(0, normal·sun_direction)` で、出力表面の alpha は 255。入力 alpha を複合層として扱わない。

`SolarSceneRenderer.mm` には通常の見かけサイズの球 (`render_planet_surface`)、物理サイズの個別球 (`render_surface_view`)、航行中の複数球 (`render_surface_scene`) の接点がある。雲・夜景はこの全経路で同じ設定を使う必要がある。現在の球交差は視点が球面内だと拒否するため、雲を単なる追加 `SurfaceSphere` にすると地表視点を拒否する。外部視点でも不透明な雲殻が地球を隠す。雲殻の交差と層の合成を不透明天体の深度とは分ける必要がある。

地球の UV は現実装で半回転の経度 offset を含む。公式の `glRotatef(180,0,0,1)` をさらに加えて二重に回転させない。

## N08: 公式ソースで確認した式

Plus 文書 `planets.html:52–67` は `clouds` と `cityLights` の bool と toggle を定めるが、以下の数式を定めていない。式の根拠は公式 [`mtk_planets.cpp`](../../../sources/official/mitaka_source/Mitaka/mtk_planets.cpp)。

| 経路 | 公式で確認した処理 |
| --- | --- |
| `draw_Earth:599–638` 夜景 | `GL_ONE, GL_ONE` の加算。ambient 材質はゼロ。夜景球は `gl_draw_LOD_sphere(false,true)` で法線を反転し、diffuse を `difi` 倍にする |
| cityLights OFF | `difi = clamp(0.3 * (1 - h / (1.7 * Re)), 0, 1)`。`h` は地球中心からのカメラ距離から表示半径を引いた高度。接近時に弱い表示が残る |
| cityLights ON | `difi = max(0, normalize(earth_position) · normalize(camera_position-earth_position))`。全画素の夜景を一定強度で足す式ではない |
| `draw_Earth:679–692` 雲 | `GL_ONE, GL_ONE`、深度書込み OFF。半径倍率 `1 + (10/6378.1) * topoZoom`、Z 軸 180° texture shift。10 km 相当の正規化半径であり、全表示条件で物理高度 10 km と認定するものではない |
| `draw_planet2:890–916` 雲 | 3D chart の別経路。`GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR`、半径倍率 `1 + 8 * topoZoom / Re`。この関数に夜景の描画分岐はない |

`mtk_sun.cpp:688` は太陽方向を `-normalize(body_position)` の平行光として設定する。`common/graphics/gl_common.cpp:54–121` は `bInvNormal` のとき法線の符号だけを反転し、頂点・UV・頂点の並び順は変えない。通常の太陽照明下では、夜景の diffuse 項は昼側の法線ではなく反転した法線を使う。side light、他の固定機能 OpenGL 状態、色空間まで一致した画素式を今回確定したものではない。

公式の `gl_draw_LOD_sphere` 自体も `gl_common.cpp:121–133` で、カメラと球中心の距離の二乗から半径の二乗を引いた `L02 <= 0` かつ `bCelestial == false` のとき描画を省略する。`draw_celestial_object` は既定値 `bCelestial=false` で呼ぶため、この雲経路は雲殻の内側から描かれない。native が内側も描く場合は、公式互換として暗黙に追加せず、別の表示仕様として判断する。Plus の対応分岐は未確認である。

雲の二つの blend は異なる。`S` を照明・テクスチャ処理後の source 色、`D` を destination 色とすると、加算は `S + D`、3D chart は成分ごとの `S*S + D*(1-S)` である。JPEG alpha を雲の被覆率に見立てる source-over 合成には置き換えない。表示色の飽和・量子化、OpenGL 材質/光源状態、native の sRGB 値での演算は別途検証する。

### N08 の実装境界案

- 既存画像 loader を使う任意の Earth layer 資産と、表示設定を分ける。欠損・破損は理由を残して当該層を利用不可とし、別画像への差替えや基本画像の破壊をしない。
- 純粋な座標 sampling / 層の照明・合成 / 深度の責務を分ける。基本地球表面、雲殻、他天体の前後関係を保持する。地表から雲殻の内側を見るケースを明示的に扱う。
- Plus の実際のモード分岐・初期値を追加確認する。公式式を採用する先行実装なら、その出典と適用モードを明記し、Plus の完全一致とは説明しない。
- `Planets.clouds` / `cityLights`、メニュー、セッションは同じ値を使う。cityLights OFF の既存公式挙動を維持する場合は、完全な非描画スイッチとは異なることを文書と UI 契約で明示する。
- 大気の単一/多重散乱、鏡面反射、地形強調、影は別の計算契約である。青い縁や雲の追加をもってこれらを実装済みとはしない。

## 実装時に必要な検証

N07 は原行/重複/出典の保持、CP932、英語・日本語の分離、未知 target、名前の大小文字差、経度 wrap・極、地形/球面の前後判定、風景の alpha・継ぎ目・方位・上下 offset・clip を検証する。再読込と地点切替では旧画像・旧選択を持ち越さず、セッションの不正参照は適用前に拒否する。元ファイルを fixture としてコピーしない。

N08 は小さな人工画像で昼・夜・terminator、逆法線、cityLights の二分岐、二つの雲 blend を数値検算する。雲殻外/内、地表、他天体の前後、極・継ぎ目・同日時の自転を確認する。三つの native 描画経路、表示 OFF、欠損/破損、再読込、Lua とセッションの往復が同じ状態を使うことを検証する。

今回実施したのはソース/文書/ローカル資産の読み取りとハッシュ照合である。N07/N08 の新しい製品コード、描画テスト、旧 Plus 画面との比較は実施していない。

独立した読取レビューでは、N08 の光源・逆法線・二つの雲合成式と、既存 CPU 描画への接点を照合した。レビューで確認された公式の球内描画抑止を上記へ反映し、修正必須の契約誤認は残っていない。レビュー担当による試験の再実行はなく、Plus 画面との一致を認定したものではない。
