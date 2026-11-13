# 公式 Mitaka 1.3.1: 描画・計算・データ読込の静的調査

調査対象: `vendor/mitaka/sources/official/mitaka_source`.
以下のソースパスはこのディレクトリからの相対パス. 行番号は原本を CP932 として読み取った位置であり, 変換後の別ファイルの行番号ではない. 原本の編集, ビルド, 実行は行っていない. 本文の「確認」はソースまたは Apple 一次資料の確認を指し, 動作確認を意味しない.

## 結論

- 現在の描画は OpenGL の即時モード, 固定機能ライティング, 組込み行列スタック, display list に広く依存する. WGL のウィンドウ・context 部分だけを置き換えて macOS Core Profile で動かすことはできない.
- 暫定移植は macOS Legacy OpenGL を対象にすると既存描画コードを多く残せる. ただし OpenGL は macOS 10.14 以降非推奨であり, 対象 Mac での context 作成・必要拡張・表示精度を確認する必要がある.
- 長期 Metal 移行では, 天体計算と CPU データ読込を保持しつつ, 即時モード描画を mesh / material / render pass に置き換える. 描画API非依存の計算クラスは存在するが, アプリ全体の計算層は静的変数・global 設定・描画用の軌道情報更新と結合している.
- データ読込にも移植課題がある. 特に BMP 処理は `DWORD = unsigned long` および `sizeof(long)` を使用するため, LP64 環境ではファイルの 32 bit フィールドを 64 bit 幅で扱う. WinAPI の置換だけでは解消しない.

## 1. 描画の流れと OpenGL 依存

| 処理 | 確認箇所 | 意味 |
| --- | --- | --- |
| ウィンドウと context 作成 | `Mitaka/main.cpp:2652` `OnCreate`; 2657 `GetDC`, 2660 `initGL_Window`, 2666 `MakeCurrent`, 2667 `initGL` | Win32 の HWND/HDC から描画初期化が始まる |
| WGL の実装 | `common/graphics/gl_win.cpp:58` `COpenGL::init`; 64 `ChoosePixelFormat`, 65 `SetPixelFormat`, 66 `wglCreateContext`; 73 `MakeCurrent`, 80 `wglMakeCurrent` | macOS の context / view / presentation 管理に置換する境界 |
| GL 初期化 | `Mitaka/main.cpp:1019` `initGL`; 1023 `glewInit`, 1054 FBO 拡張確認, 1073–1096 固定機能照明, 1104–1128 display list | GLEW を使用しているが, shader ベースの描画を意味しない |
| 表示モード選択 | `Mitaka/main.cpp:2587` `draw`; 2603–2609 anaglyph / side-by-side / top-and-bottom / dome / normal | 複数眼・ドーム表示を別経路で処理 |
| 通常描画準備 | `Mitaka/main.cpp:2470` `draw_normal`; 2475 `calc_draw_struct`, 2478–2483 `prepare_draw_objects` / `prepare_draw_planetarium`, 2485 `draw_scene_all` | camera 情報の生成と可視オブジェクト準備を経て描画 |
| シーン描画 | `Mitaka/main.cpp:2336` `draw_scene`; 2339–2354 modelview 行列, 2361 frustum, 2367–2370 3D / planetarium 分岐 | 組込み行列スタックを使用 |
| 画面合成 | `Mitaka/main.cpp:2399` `draw_scene_all_0`; 2403 color/depth clear, 2419 viewport, 2422 scene, 2427–2449 設定画面・字幕・メニュー・fade | 天体描画以外にも GL 依存 UI / overlay がある |

`Mitaka` と `common` の `.cpp`, `.h`, `.c` を字句検索した結果:

- `glBegin(...)`: 108 箇所, 38 ファイル.
- `glMatrixMode`, `glPushMatrix`, `glPopMatrix`, `glMultMatrix*`, `glLoadIdentity`: 計 308 箇所, 42 ファイル.
- `glNewList`, `glCallList`, `glCallLists`: 計 8 箇所, 3 ファイル.
- shader の生成・ソース設定・compile・program 作成/attach/use API は検索対象内で 0 箇所.
- buffer の生成・bind・upload と `glDrawArrays` / `glDrawElements` は検索対象内で 0 箇所.
- ソースツリー内に `.glsl`, `.vert`, `.frag`, `.hlsl`, `.metal` ファイルは見つからない.

これはコメント内の出現を含み得る静的な字句件数であり, 実行頻度ではない. 外部ライブラリ内部の描画実装まで不在と断定するものではない.

具体例は `main.cpp:1113` の `GL_QUADS`, `mtk_stars.cpp:548,597,643` の星の quad, `mtk_galaxies.cpp:328,344` の points / lines. `common/graphics/gl_win.cpp:161` の `gl_enter_2D_mode` は `glPushAttrib`, projection/modelview stack, `glOrtho` を使う. shader だけを追加して既存経路を残す構成では Core Profile に適合しない.

## 2. macOS Core Profile との互換性

Apple の移行資料は OpenGL 3.2 Core で固定機能 pipeline と組込み行列 stack がなくなり, shaders, generic vertex attributes, buffer objects への変更が必要と説明している. したがって上記の既存コードは Core Profile へ無変更では移せない.

- [Apple: Updating an Application to Support OpenGL 3](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/UpdatinganApplicationtoSupportOpenGL3/UpdatinganApplicationtoSupportOpenGL3.html)
- [Apple: Choosing Pixel Formats](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/opengl_pixelformats/opengl_pixelformats.html): Legacy profile は従来の機能・拡張を維持するための選択肢.
- [Apple: OpenGL profiles](https://developer.apple.com/documentation/appkit/opengl-profiles): Legacy / 3.2 Core / 4.1 Core の公開定義.
- [Apple: NSOpenGLContext initializer](https://developer.apple.com/documentation/appkit/nsopenglcontext/init%28format%3Ashare%3A%29): 非推奨として Metal / MetalKit を案内.

Apple の archive には macOS 10.14 以降 OpenGL 非推奨との記載がある. これは即時に利用不能という意味ではない. Legacy profile の実際の作成可否, GPU ごとの拡張, 対象 OS の動作は今回未検証. 個々の GL enum/API の削除一覧を Apple がすべて列挙しているとは主張しない.

## 3. 描画と天体計算が接続している場所

| 接続点 | 確認した構造 | 分離案 |
| --- | --- | --- |
| `Mitaka/mtk_planet.h:65` `planet` | texture filename 72, `GLuint tex_idx` 73, `TopoSphere*` 84, 半径 90, 扁平率 91, eclipse vector 94 を同じ class が所有. GL header を44行で include | 物理的天体データと texture / terrain GPU resource を別所有にする |
| `Mitaka/mtk_object.h:113` `mtk_object` | 119–128 に描画用相対位置・scale・depth・alpha・hit 状態. 138 `get_pos`, 149 `prepare_draw`, 157 `hit_test`, 159 `draw` が同居 | 天体 model, 可視性・選択判定, render item を分離する |
| `Mitaka/mtk_draw_struct.h:51` | 59–65 double の変換・frustum, 68 JD, 70–71 scale, 75–86 camera/target/near-far. 39行で windows.h, 41–43でtext/screen/cameraをinclude | scene snapshot の出発点になるが, 現時点で独立した純粋データ構造ではない |
| `Mitaka/mtk_draw_struct.cpp:58` `set` | global scale, dome mode, local camera side effect, font scale, target planet に依存 | 計算に必要な入力を明示し, camera/global/UI の副作用を外に出す |
| `Mitaka/mtk_objects.cpp:206` `prepare_draw_objects` | 209 global object list; 210–212 near/mid/far; 337 object.prepare_draw; 344–361 near/far/選択リスト; 380 camera 相対位置; 405–407 z sort | CPU の frame preparation として抽出可能 |
| `Mitaka/mtk_objects.cpp:449` `draw_objects` | 454 GL state push; 457–468 far-to-near 順に object.draw; 475 pop | 描画順と透明合成規則を保って renderer に移す |

`main.cpp:2500` `update_time_and_global_camera` は時刻更新, target/camera 位置, 地形高度による観測者半径, 惑星表面法線, planetarium target の追尾をまとめて扱う. 「天体計算部分をそのまま独立ライブラリとしてビルドできる」とはまだ言えない.

`Mitaka/mtk_planet_position.cpp:258` `update_planets_position` には CF96 と平均軌道要素の選択があり, 276–279で Venus / Pluto の trajectory を優先し, 288–290で軌道描画に使う軌道要素を更新する. 101–110に静的な位置・速度・trajectory・CF96・軌道要素データを持つ. `mtk_solar_system.cpp:125` `set_zoom_mode` も satellite zoom, 天体位置/姿勢, space curves の再計算を起こす.

## 4. 再利用しやすい CPU 計算コード

| 候補 | 根拠 | 移植時の注意 |
| --- | --- | --- |
| `Mitaka/mtk_orbital_element.h:66` `orbital_elements` | epoch, AU 長半径, 離心率, 平均近点角, 日運動, 行列, pos/vel を保持. `.cpp:55` parameters, 76 pos, 84 pos+velocity, 109 update, 118 orbit sample, 127 inverse conversion. include は数学・天体計算中心 | 調査した実装に GL / WinAPI 呼出しなし. 数値再利用の優先候補 |
| `common/astro/cele_mech.cpp` | 48 楕円軌道, 84/133 双曲線軌道, 193 orbital position, 213 orbital velocity | 収束・境界条件と単位を既存結果で比較 |
| `common/astro/astrometry.cpp` | 73 B1950→J2000, 113 proper motion 付き変換 | 座標系・歳差の既存仕様を維持 |
| `common/math/vector3.h:54`, `quaternion.h:53` | 数学テンプレート, math/vector include 中心 | renderer と共有可能. コンパイラ互換性は未ビルド |
| `common/astro/cf96.h:63,77,94` | block / planet / planets と evaluate_pos/vel. `.cpp:231,248,311,321` 評価処理 | 数値評価と binary decoder を分ける. decoder は int/double の native 読込 |
| `Mitaka/mtk_trajectory.h:49,78` | trajectory segment と trajectory class. `.cpp:45` 4点補間, 118 segment.get_pos, 252 trajectory.get_pos | double array の binary 読込, km→pc 変換238行, 範囲外の端点clamp258–259行を保持 |
| `common/JulianDate.cpp:61,78,89` | JD / UTC の算術変換 | 同じファイルの129行以降は SYSTEMTIME / GetSystemTime. 時刻源を分離し注入可能にする |

`mtk_planet_orientation.cpp:261–265` は姿勢角から行列を計算する一方, 273行 `set_planet_orientation_GL` は GL の向き設定へ委譲する. 数学的姿勢の計算と GPU への適用は分離できる.

## 5. データ読込の OS / ABI 依存

### パス・配置

- `Mitaka/mtk_directory.cpp:40–45`: `./data`, `./locale`, `./textures`, `./media`, `./spacecraft` が相対ディレクトリの初期値.
- 同68行 `init_directory` は70行 `GetCurrentDirectory`; 79行 `set_current_directory` は81行 `SetCurrentDirectory` を呼ぶ.
- `common/win_file.cpp:78` `directory::set` は `_splitpath`, `MAX_PATH`, backslash 連結を使用. 92行 `get_path` は static char buffer と `_makepath` を使用.
- 同52行 `fopen_utf8` は plain `fopen` の後に先頭3byteの UTF-8 BOM を読み飛ばす処理. 名前から Unicode ファイルパス対応と判断してはいけない.

移植案: app bundle の resource root と書込み先を区別し, CWD の変更に依存しないパス解決にする. パス文字コードとデータ本文文字コードは別の問題として扱う. 大文字小文字の異なる名前や日本語パスへの対応は今回網羅検証していない.

### Binary layout

- `common/graphics/image.cpp:85–86`: `WORD = unsigned short`, `DWORD = unsigned long`.
- BMP読込 `image::loadBMP` は116行. 123/126行で `sizeof(DWORD)`, 135–145行で `sizeof(DWORD)` / `sizeof(long)` を使用.
- BMP書込 `image::saveBMP` は182行. header write 部分でも同じ型幅に依存する.
- LP64 では long が64bitのため, Windows の32bit BMP header fieldをそのまま解釈できない. 固定幅 `uint32_t` / `int32_t` と規定の byte order に基づく読書きへ置換する必要がある.
- `image.cpp:715,733` の画像形式選択は `_splitpath_s`; 756行以降の wchar path overload には `_wfopen` がある.
- `common/astro/cf96.cpp:68–69,195–210,284`: native int / double を fread. `Mitaka/mtk_trajectory.cpp:95–100`: double配列を fread. CPU 数式は再利用候補だが, decoder は形式の幅・endianness・不完全ファイル時の扱いを確認する必要がある.
- `Mitaka/mtk_data_file.h:45` の `key_data` と `.cpp:43` `get_token` は stdio ベースの一般的な parser として再利用候補.

### 画像とGPU資源

`common/graphics/gl_texture.cpp:68` `add_texture` は75行で GL texture を生成してから画像を読み込み, 85行で bind, 90行で mipmap upload, 91行で CPU画像を解放する. decode と GPU upload の境界を分けると, 同じ画像資産を OpenGL / Metal の双方で使用しやすい.

## 6. 暫定 OpenGL 移植の変更候補

以下は提案であり, 実装・検証済みではない.

1. `common/graphics/gl_win.cpp`, `gl_win.h`, `main.cpp:2652` を起点に HWND/HDC と context 管理を macOS の view/context 管理へ置換する. 固定機能を維持する段階では Legacy profile を明示する.
2. `<gl/gl.h>` などの header と Windows に依存する GL utility 宣言を平台別に分ける. `Mitaka/mtk_OpenGL.h:39` は windows.h, `common/graphics/gl_common.h:42` は Windows 系 include path を使用する.
3. `gl_win.cpp:207–228` の `WGL_EXT_swap_control` / `wglSwapIntervalEXT` を macOS の表示同期に置換する.
4. `Mitaka/mtk_pbuffer.cpp` の WGL pbuffer/共有context経路は置換または使用経路の廃止判断が必要. 143行 pixel format, 229–248行 pbuffer・context・共有・current の作成が Windows 依存. ただし呼出元を完全追跡していないため, 現在すべての経路で使用されるとは断定しない.
5. `main.cpp:1054` と `common/graphics/gl_framebuffer.cpp:62` の FBO 機能確認を対象環境に合わせる. Legacy profile での ARB/EXT 関数・拡張対応を実機確認する. FBO 不可時は現コードが dome mode を通常表示へ変更する1055–1058行の挙動も検証する.
6. パス処理・BMP型幅・時刻取得を修正してから, 通常表示, star/planet texturing, 透明合成, UI overlay, screenshot, stereo/dome を段階確認する.

Core Profile を暫定目標にする場合も固定機能から shader / buffer への大幅な描画再実装が必要になる. Metal を長期目標とするなら, Core Profile 専用移植を必須の中間段階にするかは費用対効果の判断事項.

## 7. 長期 Metal 移行の変更候補

| 移行対象 | 具体的な入口 | 保持する仕様 / 置換する処理 |
| --- | --- | --- |
| Frame / camera | `main.cpp:2336`, `mtk_draw_struct.h:51`, `mtk_objects.cpp:206` | double の天体・camera計算と相対座標化, near/far分割を保持. matrix stack を明示的な行列定数にする |
| 基本 mesh | `common/graphics/gl_triangle_mesh.cpp:44` `gl_draw_triangle_mesh`; `gl_common.cpp:96–114` sphere strip | CPU頂点・法線・UVを vertex/index buffer にする. 64–86行の独立indexとsmooth/flat法線の違いを保持 |
| 惑星 material / light | `Mitaka/mtk_planets.cpp:998` `draw_a_planet`; 1003–1022 material, sun light, translation, orientation, scale | 固定照明・material・texture combiner を shader と明示的な状態に変換 |
| 惑星地形・雲・注記 | `mtk_planets.cpp:532` cloud, 571 Earth, 732 planet; 773–795 TopoSphere/places/pointer | 同一視点での地形LOD・透明雲・overlayの前後関係を維持 |
| 星・銀河・軌道線 | `mtk_stars.cpp:548,597,643,677`, `mtk_galaxies.cpp:328,344` | billboard/point/line に対応する GPU pipeline を作る. pixel size と alpha を比較 |
| 画面UI・文字 | `gl_win.cpp:161`, `main.cpp:2427–2449` | 正射影overlay, texture atlas等への置換. UI全体の別調査と統合 |
| Render target | `common/graphics/gl_framebuffer.cpp:62` | RGBA texture / depth attachment を Metal texture / render pass へ変換 |
| Dome | `Mitaka/mtk_dome_master.cpp:299` `generate_map`, 445 `Draw`, 526 `draw_dome_master_sub` | CPU歪みmapを再利用. 625行の5方向描画, 629–646 FBO, 656–674合成を複数passへ変換 |
| Stereo | `Mitaka/mtk_stereo.cpp:99,123,154,191,238,273` | 眼ごとのrender target と合成shader. 現99/123行経路の readPixels / CPU色変換, 147行 glDrawPixels を置換. 出力の色チャンネルと配置を保持 |
| 画像upload | `common/graphics/gl_texture.cpp:68` | CPU画像decodeを維持し, backend resource作成と分離 |

Metal 移行では遠大な宇宙座標を無条件に float に落とさない. 現在の `vector3d`, `matrix3d`, JD double, camera相対座標, near/far分割を維持し, GPU に渡す座標範囲を明示する. 星空から惑星地表までのスケール差と透明描画順は重要な回帰点になる.

## 8. 回帰確認すべき既存の数値・表示仕様

- `mtk_object_position.cpp:109–113`: 天体位置より姿勢を先に更新する. コメントでは天王星衛星軌道面の姿勢依存を説明している.
- `mtk_planet_position.cpp:123–167`: 更新時間閾値, Earth/Moon と Pluto 系の重心補正. 同258–306行: CF96適用範囲, trajectory優先, 範囲外の平均軌道要素.
- `mtk_trajectory.cpp:118–128,238,252–259`: 補間, km→pc, 範囲外clamp.
- `mtk_solar_system.cpp:125–134`: zoom が位置・姿勢・space curve 更新へ与える影響.
- `mtk_objects.cpp:405–407,449–468`: depth sort, near/far分割,遠方からの透明合成順.
- `main.cpp:2500–2556`: 地形高度, 観測者半径, 表面法線, 追尾camera.
- dome の5方向camera / 投影offset / distortion map, stereoの眼順・色チャンネル・左右/上下配置.
- BMPの既存画像を読むfixtureと, 書き出しheaderサイズを確認するfixture. CF96/trajectoryには既知日時・既知位置の数値fixture.

比較画像や既知の天体計算結果は今回採取していない. テストの提案であり, 合格済みとは扱わない.

## 9. 調査の限界

ソースの静的調査のみ. macOS build, Legacy/Core context creation, Metal試作, 実機描画, 画像差分, 性能, 全入力データの形式検証は未実施. shader不在件数は明示した自前ソース範囲に限る. pbufferの実際の使用有無や, すべてのOS依存経路の網羅性も未確定. ソース原本は変更していない.
