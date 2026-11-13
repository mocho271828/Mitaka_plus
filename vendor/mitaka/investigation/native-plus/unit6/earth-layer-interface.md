# 地球の雲・夜景・大気の合成

## 資産・設定・数式の境界

新規 `earth_layers.hpp/.cpp` は GUI 層の純 C++ とし、AppKit・画像 I/O を持たせない。画像は既存 `TextureImage`、幾何は `Vec3` / `BodyOrientation` を再利用する。別の画像処理ライブラリや汎用の層レンダリング基盤は導入しない。

製品の `native/gui/include/earth_layers.hpp` に以下の型を置いた。

```cpp
struct EarthLayerOptions {
    bool clouds = true;
    bool city_lights = false;
};

struct EarthLayerAssets {
    std::optional<TextureImage> clouds;
    std::optional<TextureImage> night_lights;
    std::vector<std::string> diagnostics;
};

struct EarthLayerView {
    Vec3 earth_to_camera_ecliptic_au;
    Vec3 earth_to_sun_ecliptic_unit;
    double display_radius_au;
    double topography_scale = 1;
};

struct EarthLayerBinding {
    const EarthLayerAssets& assets;
    EarthLayerOptions options;
    EarthLayerView view;
};
```

`EarthLayerBinding` は描画呼出し中だけ借用する。資産は既存の `PlanetTextures::earth_layers` が所有する。値のコピーを画素ごとに行わない。ロードは `planet_textures.mm` から既存 `load_local_image` を使い、選択した `data` の兄弟 `textures/earth_cloud.jpg` と `earth_lights.jpg` だけを読む。読み込み上限、JPEG/PNG 内容検査、sRGB straight RGBA 変換を共用する。欠損時は診断と利用不可状態を保持し、別名画像・前回のデータフォルダの画像で代用しない。

`clouds` は雲層の描画切替。`city_lights` は公式の二つの gain 分岐を選ぶ値であり、false は夜景の完全非表示を意味しない。Lua・メニュー・セッションは一つの設定を使う。

公式 1.3.1 の `mtk_switches.cpp:86–87` は初期表示 bit に cloud を含み、city lights は `EarthCityLightsIni` に従う。`mtk_planets.cpp:107–108` の city lights 既定値は false、`mtk_ini_file.cpp:572–575` は `[Earth] CityLights` の値が 1 の場合だけ true にする。native は cloud=true / city_lights=false を公式通常版に基づく初期値として採用した。現ローカル Plus の `mitaka.ini:106` / `mitaka_pp.ini:103` も `CityLights = 0` だが、変更前の配布既定値や起動時に使われる ini の証明にはしない。Plus の cloud 初期値・分岐は未確定である。

純関数に分ける対象は夜景の gain、逆法線の diffuse 項、雲の半径倍率、加算合成である。通常版で確定した式は次のとおり。

- 夜景 ON の gain は `max(0, -dot(earth_to_sun_unit, earth_to_camera_unit))`。
- 夜景 OFF の gain は `clamp(0.3 * (1 - h / (1.7 * Re)), 0, 1)`。`h = distance_to_center - Re`、`Re` は描画中の地球半径で、同じ単位を使う。
- 通常の太陽照明の夜景 diffuse は `max(0, dot(-normal, sun_unit))`。夜景の ambient 材質はゼロ。
- 雲半径倍率は `1 + (10 / 6378.1) * topography_scale`。地形強調を未実装の段階では明示的な native 値 1 を渡す。全モードで物理高度 10 km と説明しない。
- blend は source/destination の RGB を加算して表示域へ収める。JPEG alpha を雲量に置き換えない。`draw_a_planet` (`mtk_planets.cpp:997–1004`) は diffuse=1 / ambient=`get_lighting_ambient()` を設定し、夜景の材質変更は `glPushAttrib(GL_LIGHTING_BIT | GL_ENABLE_BIT)` / `glPopAttrib` で戻る。雲の `draw_celestial_object` (`mtk_solar_system.cpp:212–225`) は照明・法線正規化を有効化してその材質を使い、法線は反転しない。`main.cpp:1073–1080` の LIGHT0 ambient=0.1 / diffuse=1 も確認できる。global ambient の初期値 0.2 と材質の通常既定値 0.1 から、native の雲 ambient は `0.1 * (0.2 + 0.1) = 0.03` とした。OpenGL の全状態や色空間まで再現しておらず、夜景・雲の画素単位一致は主張しない。詳細な根拠は [provenance](../../../native/gui/EARTH_LAYERS_PROVENANCE.md) に記録した。

非有限値、ゼロ方向、正でない半径、不正画像を事前に拒否する。色の数値範囲と量子化位置は native の明示契約とし、物理 radiance と呼ばない。既存の UV・bilinear sampling を共用し、Earth の既存経度 offset 0.5 に公式の 180 度回転を二重適用しない。

## 三つの描画経路

`SurfaceSphere` の地球にだけ optional binding を付け、`render_surface_scene` で不透明球の交差・最近接深度を先に確定する。`render_surface_view` は既存どおり単球 scene へ委譲する。`render_planet_surface` も同じ binding・夜景 gain・照明・blend を受けるが、現在の模式球投影を保持する。模式球に物理的な視線距離があるとは扱わない。

雲を追加の不透明 `SurfaceSphere` にはしない。雲殻に独立して交差判定し、他天体の最近接不透明交点より手前の部分だけを合成する。雲は不透明表面の depth を更新しない。公式 `gl_draw_LOD_sphere` に合わせ、カメラが雲殻上・内側の場合は雲を描かない。地表視点そのものをエラーにしない。

模式球では同じ半径倍率による画面上の雲殻と基底を使う。シーンの物理 ray と同一の遮蔽精度を持つとは説明せず、通常の模式半径・並び順の制約を継続する。共有する設定・式と、投影固有の幾何を分けて試験する。

## 大気との接点

公式 `mtk_planets.cpp:570–692` の順序は **地表 → 夜景 → 鏡面 → 大気 → 雲**。ネイティブ版では地表・夜景の後、大気・雲の順で合成する。

大気は `mitaka/atmosphere.hpp` と `atmosphere_renderer.hpp` の型で接続した。`AtmosphereDisplayOptions{mode=multiple, intensity=6}` を `SolarScene` と `SolarSystemView` に保持する。地球は single と有効な `data/emmap.dat`、火星は single のみを使う。map が欠損・不正でも single を継続し、原 bytes と診断は `PlanetTextures::atmosphere_emission` に残す。

同じ `SurfaceSphere` 配列とカメラから視線を作り、最も近い不透明交点まで積分する。地球 single の地表半径と描画半径の比で AU から m へ変換する。map 固有の半径・密度は書き換えない。RGB 加算用画像を **地表・夜景 → 大気 → 雲** の順に重ね、alpha を透過率として再乗算しない。EarthMoon 表示も二つの個別描画から共通の深度合成へ移した。

大気は物理透視の全体・EarthMoon・地表表示へ接続した。`render_planet_surface` の模式球と最小記号は物理透視 ray を持たないため、大気を描かない。この制約を大気の三経路対応と読み替えない。大気の式と境界は [ATMOSPHERE_RENDERING.md](../../../native/gui/ATMOSPHERE_RENDERING.md) を参照する。
