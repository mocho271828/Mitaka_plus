# 地点定義と地球画像の原典

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

## 文書から確定する契約と未確定点

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

## 公式ソースで確認した式

Plus 文書 `planets.html:52–67` は `clouds` と `cityLights` の bool と toggle を定めるが、以下の数式を定めていない。式の根拠は公式 [`mtk_planets.cpp`](../../../sources/official/mitaka_source/Mitaka/mtk_planets.cpp)。

| 経路 | 公式で確認した処理 |
| --- | --- |
| `draw_Earth:599–638` 夜景 | `GL_ONE, GL_ONE` の加算。ambient 材質はゼロ。夜景球は `gl_draw_LOD_sphere(false,true)` で法線を反転し、diffuse を `difi` 倍にする |
| cityLights OFF | `difi = clamp(0.3 * (1 - h / (1.7 * Re)), 0, 1)`。`h` は地球中心からのカメラ距離から表示半径を引いた高度。接近時に弱い表示が残る |
| cityLights ON | `difi = max(0, normalize(earth_position) · normalize(camera_position-earth_position))`。全画素の夜景を一定強度で足す式ではない |
| `draw_Earth:679–692` 雲 | `GL_ONE, GL_ONE`、深度書込み OFF。半径倍率 `1 + (10/6378.1) * topoZoom`、Z 軸 180° texture shift。10 km 相当の正規化半径であり、全表示条件で物理高度 10 km と認定するものではない |
| `draw_planet2:890–916` 雲 | 3D chart の別経路。`GL_SRC_COLOR, GL_ONE_MINUS_SRC_COLOR`、半径倍率 `1 + 8 * topoZoom / Re`。この関数に夜景の描画分岐はない |

`mtk_sun.cpp:688` は太陽方向を `-normalize(body_position)` の平行光として設定する。`common/graphics/gl_common.cpp:54–121` は `bInvNormal` のとき法線の符号だけを反転し、頂点・UV・頂点の並び順は変えない。通常の太陽照明下では、夜景の diffuse 項は昼側の法線ではなく反転した法線を使う。side light、他の固定機能 OpenGL 状態、色空間まで一致した画素式を確定したものではない。

公式の `gl_draw_LOD_sphere` 自体も `gl_common.cpp:121–133` で、カメラと球中心の距離の二乗から半径の二乗を引いた `L02 <= 0` かつ `bCelestial == false` のとき描画を省略する。`draw_celestial_object` は既定値 `bCelestial=false` で呼ぶため、この雲経路は雲殻の内側から描かれない。native が内側も描く場合は、公式互換として暗黙に追加せず、別の表示仕様として判断する。Plus の対応分岐は未確認である。

雲の二つの blend は異なる。`S` を照明・テクスチャ処理後の source 色、`D` を destination 色とすると、加算は `S + D`、3D chart は成分ごとの `S*S + D*(1-S)` である。JPEG alpha を雲の被覆率に見立てる source-over 合成には置き換えない。表示色の飽和・量子化、OpenGL 材質/光源状態、native の sRGB 値での演算は別途検証する。
