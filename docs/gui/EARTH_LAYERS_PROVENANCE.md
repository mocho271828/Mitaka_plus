# Earth clouds / night lights の採用根拠

2026-10-29、UNIT6 N08。公式 Mitaka 1.3.1 の通常描画式を、既存 native の画像・球面描画へ移した。Plus 1.5.4 の全モード・初期状態や固定機能 OpenGL の画素を再現したとは主張しない。N27 の 3D chart 固有 blend、鏡面、地形強調は本変更に含めない。

## 原典と式

ローカル原典は `vendor/mitaka/sources/official/mitaka_source/Mitaka/`。読み取りのみで、原コードや同梱画像は変更していない。

| 原典 | 確認した処理 / native の採用 |
| --- | --- |
| `mtk_planets.cpp:454–460` | `earth_cloud.jpg` / `earth_lights.jpg` の独立読込。別名へ置き換えない。 |
| `mtk_planets.cpp:570–692` | 通常の順序は地表 → 夜景 → 鏡面 → 大気 → 雲。鏡面を除く採用層の相対順序を保持。 |
| 同 `:599–639` | 夜景 ON: `max(0, -dot(sun_unit, camera_unit))`。OFF: `clamp(0.3*(1-h/(1.7*Re)),0,1)`。逆法線の diffuse、ambient 0、RGB の `ONE,ONE` 加算、depth write 無効。 |
| 同 `:678–692` | 雲半径倍率 `1+(10/6378.1)*topography_scale`、RGB 加算、depth write 無効。native の地形倍率は明示的に 1。 |
| 同 `:997–1004`、`mtk_solar_system.cpp:79–80,194–225` | 通常の材質 diffuse 1 / ambient 0.1 と照明・法線正規化。雲で法線を反転しない。 |
| `main.cpp:1073–1100` | LIGHT0 の ambient 0.1 / diffuse 1。native 通常雲照明は `clamp(0.03+max(0,dot(normal,sun)),0,1)`。 |
| `mtk_switches.cpp:86–87`、`mtk_planets.cpp:107–108`、`mtk_ini_file.cpp:572–575` | `clouds=true` / `city_lights=false` を公式通常版に基づく native 初期値として採用。 |

雲 ambient の 0.03 は材質 0.1 と global ambient 0.2 / LIGHT0 ambient 0.1 の和に由来する。global ambient の既定値と照明式は [Khronos OpenGL 2.1 glLightModel](https://raw.githubusercontent.com/KhronosGroup/OpenGL-Refpages/main/gl2.1/glLightModel.xml) に基づく。追加照明・色空間・原版の float 丸めまで同じとは扱わない。native の RGB は表示値であり、物理 radiance ではない。

`city_lights=false` は公式の距離依存分岐を選ぶ値であり、地表近くの夜景を完全に消す値ではない。Lua / メニューの説明にもこの意味を維持する。

## 実装の境界

- `earth_layers.hpp/.cpp`: 純 C++ の資産型・借用 binding・式。有限値、単位方向、正の半径、非負の地形倍率を検証する。画像 I/O や AppKit を持たない。
- `planet_textures.mm`: 選択した `data` の兄弟 `textures` から既存 `load_local_image` で読む。既存の画像内容・寸法・メモリ上限を共用する。欠損・不正は層別診断に残し、データフォルダ変更後に前回の画像を流用しない。
- `planet_surface.cpp`: 既存の UV・bilinear sampling・自転姿勢・球交点を共用する。地球の経度 offset 0.5 に 180 度回転を追加しない。夜景を地表へ加算し、雲は独立した加算画像へ出力する。入力エラーでは出力先を変更しない。
- `SolarSceneRenderer.mm`: 同じ `EarthLayerOptions` を模式球、地表透視、複数球の物理透視へ渡す。base/night → atmosphere → cloud の順に合成する。EarthMoon も同一の最近接不透明深度を使う。雲・夜景は地球だけに結びつけ、元の表面画像が欠損しても独立して利用する。
- `SolarSystemView`: `earthLayerOptions` と `atmosphereDisplayOptions` を保持する。大気の不正な mode/intensity は代入前に拒否する。

雲は不透明球に追加せず、最も近い不透明交点より手前の雲殻だけを RGB 加算する。雲自身は不透明深度を更新しない。公式 LOD 球の扱いに合わせて、カメラが雲殻上または内部なら雲を描かない。地表にいること自体は拒否しない。模式球では元の見かけ半径を保つよう画像と描画矩形を同じ殻倍率で広げるが、複数天体の物理的な遮蔽精度とは区別する。

`PlanetTextures::atmosphere_emission` は N12 の loader で `data/emmap.dat` を読み、無効時も原 bytes と診断を保持する。有効 map は地球の multiple にだけ借用し、欠損時は single を継続する。火星は single のみ。模式球へ大気は描かない。散乱式・単位・透過率との区別は [ATMOSPHERE_RENDERING.md](ATMOSPHERE_RENDERING.md) を参照。

新規依存はない。C++ 標準ライブラリ、既存 core geometry、Apple ImageIO / AppKit を再利用した。汎用の画像処理・shader・層管理ライブラリを導入する必要はない。

## 検証

- `test_earth_layers`: 通常 / ASan+UBSan / x86_64、各 63 checks。昼夜・terminator、両 gain、飽和、NaN・不正方向、殻の内外と `nextafter`、UV・自転、深度順序、原子的な出力拒否。
- `test_planet_surface` と `test_planet_textures`: 同3構成で成功。任意画像の欠損・破損・修復・削除・フォルダ交換、原 bytes / mtime 保持、emmap の無効→有効→欠損も確認。
- `test_earth_layer_scene`: offscreen AppKit bitmap、通常 / ASan+UBSan / x86_64。各描画経路の独立 toggle、EarthMoon 遮蔽と pick の整合、地球 multiple の map 結合、火星 single、非 Earth への層漏れ、模式球への大気漏れを検証。各 50 checks、通常構成は任意 benchmark 3 checks を含む 53 checks。
- 原 Plus / 通常版のローカル画像も読込確認。原本を変更せず、公開件数で切り詰めていない。

通常 arm64 の人工シーン 800×800 を各1回測定した値は、大気なし 225.34 ms / single 801.21 ms / multiple 991.45 ms。計測対象はこのシーンのみ。CPU の大気描画コストは残る。既存の模式球 512px・透視長辺 800px 上限を維持し、Retina 倍率で透視 CPU 解像度を増やさない。

アプリでの操作方法は [GUI ガイド](README.md) を参照。
