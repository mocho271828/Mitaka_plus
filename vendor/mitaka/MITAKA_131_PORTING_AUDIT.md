# Mitaka 1.3.1 のソースと移植時の相違点

公式 1.3.1 のソースと非公式 SwiftUI 移植を 2026-10-29 に照合した記録。以下のファイル・行番号は比較対象の版を指す。Mitaka_plus の現行のビルド方法は [Mitaka Native](README.md)、計算結果を原版と照合する手順は [計算コア](native/core/README.md) を参照。

## 対象と取得記録

| 対象 | 保存場所・識別子 | 確認結果 |
|---|---|---|
| 公式 ZIP | [mitaka_source_131.zip](sources/official/mitaka_source_131.zip) | 905,545 bytes、CRC 検査成功 |
| 公式展開物 | [mitaka_source](sources/official/mitaka_source) | 310ファイル。ZIP と全ファイルがバイト単位で一致 |
| 非公式 macOS 移植 | [Mitaka-macOS](https://github.com/yoshikaz1228/Mitaka-macOS/tree/ab63d81723a9261b663c8ab1283de2e7607f1094) | commit `ab63d81723a9261b663c8ab1283de2e7607f1094` に固定 |
| 非公式 repo 内の上流コピー | [Upstream/mitaka-1.3.1](https://github.com/yoshikaz1228/Mitaka-macOS/tree/ab63d81723a9261b663c8ab1283de2e7607f1094/Upstream/mitaka-1.3.1) | 公式展開物と310ファイルすべて一致。欠落・追加・内容差異0 |

公式 ZIP の SHA-256 は `778c66bf6c81d2bf0bba380e9209882ecd961dd79cb9d2140758849d82314429`。
取得元は [国立天文台の配布一覧](https://4d2u.nao.ac.jp/mitaka/download/download_old/)にある [公式 ZIP](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_131.zip)。
取得元と原本の SHA-256 は [同梱ソースの取得記録](sources/README.md) に記載している。

詳細な静的調査記録は [OS 境界](investigation/mitaka-1.3.1/platform-findings.md)、[描画・計算](investigation/mitaka-1.3.1/render-findings.md)、[非公式移植](investigation/mitaka-1.3.1/reference-findings.md)、[非公式の UI](investigation/mitaka-1.3.1/ui-findings.md) に保存した。
## 公式ソースの構成とビルドの前提

公式ソースは C++ 146ファイル、ヘッダ161ファイル、README・アイコン・リソース各1ファイルからなる。
C++ / ヘッダの合計は75,946物理行。これは移植対象の規模を示す値であり、変更行数や工数ではない。
Visual Studio、Xcode、CMake、Make のビルド定義とテストスイートは ZIP に含まれていない。

[Readme.txt:22](sources/official/mitaka_source/Readme.txt#L22) は Windows 7、Visual Studio 2015 / Intel C++ 2016 を前提とする。
リンク対象には Windows の multimedia / sockets / DirectInput / DirectShow / VfW / OpenGL ライブラリと、JPEG、zlib、PNG、GLEW、FreeType がある。
## Win32 と C++ ランタイムへの依存

| 領域と入口 | 公式 1.3.1 での実装 |
|---|---|
| 起動・イベント: [main.cpp:5863](sources/official/mitaka_source/Mitaka/main.cpp#L5863), [mtk_window_mode.cpp:1015](sources/official/mitaka_source/Mitaka/mtk_window_mode.cpp#L1015) | `WinMain`、`WNDCLASS`、`CreateWindow`、`WndProc`、Windows メッセージループ |
| ダイアログ: [mtk_dialog_box.cpp:388](sources/official/mitaka_source/Mitaka/mtk_dialog_box.cpp#L388), [win_dlg.cpp:82](sources/official/mitaka_source/common/win_dlg.cpp#L82) | Windows ダイアログを独立スレッドで起動。画像保存に `OPENFILENAMEW` |
| 時刻・周期処理: [main.cpp:2652](sources/official/mitaka_source/Mitaka/main.cpp#L2652), [JulianDate.cpp:129](sources/official/mitaka_source/common/JulianDate.cpp#L129) | `timeSetEvent`、`timeGetTime`、`GetSystemTime`。timer callback 内で入力とアニメーション更新 |
| CPU・並列計算: [cpu.cpp:45](sources/official/mitaka_source/common/cpu.cpp#L45), [mtk_atmosphere.cpp:177](sources/official/mitaka_source/Mitaka/mtk_atmosphere.cpp#L177) | MS 形式の x86 inline assembly / SSE と Windows thread pool |
| コントローラー: [joystick.cpp:49](sources/official/mitaka_source/common/interface/joystick.cpp#L49), [mtk_joystick.cpp:106](sources/official/mitaka_source/Mitaka/mtk_joystick.cpp#L106) | DirectInput、`GetAsyncKeyState`、4軸 / 16ボタン、dead zone 0.3、キーボード優先 |
| 資源・設定: [mtk_directory.cpp:68](sources/official/mitaka_source/Mitaka/mtk_directory.cpp#L68), [mtk_ini_file.cpp:219](sources/official/mitaka_source/Mitaka/mtk_ini_file.cpp#L219), [win_file.cpp:78](sources/official/mitaka_source/common/win_file.cpp#L78) | CWD、backslash、`_splitpath`、Windows Profile API、ホスト名別 INI |
| フォント: [mtk_languages.cpp:198](sources/official/mitaka_source/Mitaka/mtk_languages.cpp#L198), [mtk_font.cpp:110](sources/official/mitaka_source/Mitaka/mtk_font.cpp#L110) | Windows の Fonts ディレクトリと `arialuni.ttf` への fallback。FreeType にファイルを渡す |
| 動画・音声: [mtk_movie.cpp:144](sources/official/mitaka_source/Mitaka/mtk_movie.cpp#L144), [main.cpp:3946](sources/official/mitaka_source/Mitaka/main.cpp#L3946) | ATL / COM / DirectShow、VMR7 / VMR9 / EVR。音声も同じ再生経路 |
| 通信・同期: [tcp_udp.cpp:66](sources/official/mitaka_source/common/tcp_udp.cpp#L66), [mtk_tcp.cpp:497](sources/official/mitaka_source/Mitaka/mtk_tcp.cpp#L497) | Winsock、構造体の直接送信、Windows のロック |

## 固定機能 OpenGL と描画の対応箇所

[gl_win.cpp:58](sources/official/mitaka_source/common/graphics/gl_win.cpp#L58) の WGL context 作成と表示同期だけを交換しても、macOS の OpenGL Core Profile では動かない。
1.3.1 の自前ソースには `glBegin` が108箇所 / 38ファイル、行列スタック関連 API が308箇所 / 42ファイルあり、固定照明、display list、`GL_QUADS` に依存している。
shader 作成・compile・use API、VBO の生成・upload、`glDrawArrays` / `glDrawElements` はソースの字句検索では見つからなかった。
これらはコメントを含み得る字句検索の件数であり、実行頻度ではない。1.7.4a で使われた API は [Windows 実行版の調査](MACOS_NATIVE_ASSESSMENT.md) に記載する。

| 描画対象 | ソース上の入口 | 原版での表現 |
|---|---|---|
| frame・camera・描画順 | [main.cpp:2336](sources/official/mitaka_source/Mitaka/main.cpp#L2336), [mtk_objects.cpp:206](sources/official/mitaka_source/Mitaka/mtk_objects.cpp#L206) | double の位置計算、camera 相対座標、near / far 分割、透明物の描画順 |
| 惑星・地形・雲 | [mtk_planets.cpp:998](sources/official/mitaka_source/Mitaka/mtk_planets.cpp#L998), [gl_triangle_mesh.cpp:44](sources/official/mitaka_source/common/graphics/gl_triangle_mesh.cpp#L44) | 頂点・法線・UV、光源・材質、地形 LOD、雲と注記の合成 |
| 恒星・銀河・軌道線 | [mtk_stars.cpp:548](sources/official/mitaka_source/Mitaka/mtk_stars.cpp#L548), [mtk_galaxies.cpp:328](sources/official/mitaka_source/Mitaka/mtk_galaxies.cpp#L328) | 星の画面上サイズ、明るさ・alpha、点・線の描き方 |
| 画像・文字・overlay | [gl_texture.cpp:68](sources/official/mitaka_source/common/graphics/gl_texture.cpp#L68), [main.cpp:2427](sources/official/mitaka_source/Mitaka/main.cpp#L2427) | 画像のデコード・転送。字幕、メニュー、fade、文字 atlas の描画順と色 |
| offscreen・ドーム・立体視 | [mtk_pbuffer.cpp:229](sources/official/mitaka_source/Mitaka/mtk_pbuffer.cpp#L229), [mtk_dome_master.cpp:526](sources/official/mitaka_source/Mitaka/mtk_dome_master.cpp#L526), [mtk_stereo.cpp:99](sources/official/mitaka_source/Mitaka/mtk_stereo.cpp#L99) | WGL pbuffer / FBO。ドームの5方向描画・歪み map、左右の眼の順序・色・配置。pbuffer の全呼出経路は未確認 |

Apple は固定機能からの移行手順を説明し、OpenGL 自体は macOS 10.14 から非推奨としている。[Apple の移行資料](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/UpdatinganApplicationtoSupportOpenGL3/UpdatinganApplicationtoSupportOpenGL3.html)、[OpenGL profiles](https://developer.apple.com/documentation/appkit/opengl-profiles)

宇宙座標をそのまま Float に落とすと距離スケールによる精度問題を招く。
CPU の double 計算と camera 相対座標を維持し、GPU に渡す座標範囲を明確にすることが描画移行の重要な検証点になる。

## 天文計算の出典

| 候補 | 根拠・注意点 |
|---|---|
| [mtk_orbital_element.cpp:55](sources/official/mitaka_source/Mitaka/mtk_orbital_element.cpp#L55) | 軌道要素から位置・速度・軌道線を計算。調査した実装に WinAPI / GL 呼出しはない |
| [cele_mech.cpp:48](sources/official/mitaka_source/common/astro/cele_mech.cpp#L48), [astrometry.cpp:73](sources/official/mitaka_source/common/astro/astrometry.cpp#L73) | 楕円・双曲線軌道、座標変換、固有運動。両翻訳単位は今回の Clang 構文チェックに成功 |
| [cf96.cpp:231](sources/official/mitaka_source/common/astro/cf96.cpp#L231), [mtk_trajectory.cpp:118](sources/official/mitaka_source/Mitaka/mtk_trajectory.cpp#L118) | 暦評価と軌跡補間。数値計算と binary decoder を分離し、適用範囲、補間、km→pc、範囲外の挙動を保持 |
| [mtk_planet_orientation.cpp:261](sources/official/mitaka_source/Mitaka/mtk_planet_orientation.cpp#L261) | 姿勢行列の計算と GL へ適用する処理を分離できる |

ただし、`planet` は物理量と `GLuint` / 地形資源を同じクラスに持ち、`mtk_object` も位置・選択・描画を併せ持つ。
計算層全体が独立したライブラリになっているわけではない。[planet](sources/official/mitaka_source/Mitaka/mtk_planet.h#L65)、[mtk_object](sources/official/mitaka_source/Mitaka/mtk_object.h#L113)
## Windows と macOS のデータ表現

Clang のターゲット定義で、64bit Windows の `long` は4 byte、arm64 macOS の `long` は8 byte、`wchar_t` はそれぞれ2 / 4 byteと確認した。
CPU がどちらも64bitであることは、ファイル上の型サイズが同じという意味ではない。

| 根拠 | 現状と問題 |
|---|---|
| [mtk_stars.cpp:205](sources/official/mitaka_source/Mitaka/mtk_stars.cpp#L205), `read_a_Hipparcos_star` | HIP 番号を `long` とし、`sizeof(HIP)` で読む。macOS では後続フィールドの読み取り位置がずれる |
| [mtk_constellation.cpp:178](sources/official/mitaka_source/Mitaka/mtk_constellation.cpp#L178) | 星座線の HIP 番号も `long` のサイズで読む |
| [image.cpp:84](sources/official/mitaka_source/common/graphics/image.cpp#L84) | `DWORD = unsigned long`。BMP ヘッダの読み書きが `sizeof(DWORD)` / `sizeof(long)` に依存 |
| [3ds_loader.cpp:334](sources/official/mitaka_source/common/graphics/3ds_loader.cpp#L334) | `unsigned long` の smoothing mask に4 byteだけ読み込む |
| [unicode_string.cpp:129](sources/official/mitaka_source/common/text/unicode_string.cpp#L129), `utf8_to_wstring` | UTF-16 のコード単位を `wchar_t` に追加する Windows 前提。macOS の wide string の意味と合わない |
| [mtk_languages.cpp:160](sources/official/mitaka_source/Mitaka/mtk_languages.cpp#L160) | `fopen(..., "rt")` と末尾 `\n` の除去を前提に言語ファイル名を読む。macOS では CRLF の `\r` が残る |

## 比較用の非公式 macOS 移植

参照版の Xcode target がコンパイルするのは Swift 4ファイルと144行の独立した C++ コアで、保存された公式310ファイルはビルド対象ではない。
そのため、ビルド成功は公式本体の依存解消を意味しない。[ビルド対象](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac.xcodeproj/project.pbxproj#L150)

| ソース箇所 | 確認した実装 |
|---|---|
| [MitakaCore.h:6](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/Core/MitakaCore.h#L6) と [bridging header](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/Support/MitakaMac-Bridging-Header.h#L1) | `extern "C"` で C++ を Swift から呼ぶ、小さな C ABI。ObjC++ 実装はない |
| [MitakaCore.cpp:58](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/Core/MitakaCore.cpp#L58) | 9天体の軌道要素、楕円 Kepler 方程式、軌道面の回転、Unix time→JD |
| [MitakaMacApp.swift:8](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/MitakaMacApp.swift#L8), [ContentView.swift:7](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/ContentView.swift#L7) | macOS のウィンドウ、天体一覧、検索、選択、表示切替、キーボード操作 |
| [AppModel.swift:15](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/AppModel.swift#L15) | MainActor 上の状態管理と C ABI 呼び出し、30 Hz の時刻更新 |
| [UniverseSceneView.swift:24](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/UniverseSceneView.swift#L24) | `NSViewRepresentable` / Coordinator の表示境界、球・軌道線・ラベル・カメラ操作 |
| [project.pbxproj:273](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac.xcodeproj/project.pbxproj#L273) | macOS 14.0、target の C++17、Swift language mode 5。arm64 / x86_64 ビルドを確認 |
| [MitakaCoreTests.cpp:12](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/Tests/MitakaCoreTests.cpp#L12) | コアの個別ビルドと基本的な健全性のテスト |

### 軌道計算は公式の簡易経路に相当する

公式の [mtk_planet_position.cpp:258](sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp#L258) は、適用範囲内では CF96 と軌跡データを使い、範囲外では平均軌道要素へ切り替える。
参照版は平均軌道要素の経路だけを実装する。
月・衛星、地球月系 / 冥王星カロン系の補正、個別軌跡、惑星速度、双曲線軌道などは含まれない。

平均軌道表の値と平均運動の係数は公式由来だが、Kepler solver は書き直されている。
収束閾値は公式の `1e-8` に対して参照版は `1e-10`、未収束時の扱いも異なる。
参照 API は AU、公式の惑星位置格納は pc なので、座標を直接交換できない。[公式 solver](sources/official/mitaka_source/common/astro/cele_mech.cpp#L48)、[参照 solver](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/Core/MitakaCore.cpp#L75)、[公式の単位変換](sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp#L293)

### 太陽系の画面は観測用表示とは分けて扱う

参照版は距離と半径を対数で圧縮して表示し、描画座標を Float に変換する。
背景は固定 seed で生成した1,600点で、実際の恒星カタログではない。
惑星の固定色や土星の環はあるが、公式の地形・画像・自転・観測者モデルを移植したものではない。[表示半径](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/UniverseSceneView.swift#L150)、[背景星](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/UniverseSceneView.swift#L225)、[距離変換](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/MitakaMac/UniverseSceneView.swift#L265)

カメラは選択が変わった時に移動し、時刻進行による天体移動を追尾しない。
未移植機能は [PORTING.md:23](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/docs/PORTING.md#L23) でも明記されている。

## 比較時の環境と結果

環境は macOS 26.6.2、Xcode 27.1、Apple clang 21.0.0、arm64 ホスト。
コマンドと診断は [VALIDATION.md](investigation/mitaka-1.3.1/VALIDATION.md) に保存した。

| 検証 | 結果 | 判断できる範囲 |
|---|---|---|
| 公式 ZIP の整合性・原本保全 | 成功 | 取得物の CRC、展開後のバイト一致 |
| 公式の15翻訳単位を Clang で構文チェック | 10成功、5失敗 | 計算の `cele_mech` / `astrometry` / `cf96`、数学・文字列処理の一部は構文確認に成功。リンク・実行は未確認 |
| 失敗した公式コード | `windows.h`, `tchar.h`, `stricmp` | OS / CRT 依存を再現。CP932 リテラルや include 大文字小文字の警告も確認 |
| 非公式の既存コアテスト | 成功 | 9天体、地球の識別、J2000 の有限座標と概略距離、Unix epoch の JD 変換 |
| 非公式の universal build | `BUILD SUCCEEDED` | Mach-O に `arm64` / `x86_64` があることを確認。署名なし |

この調査で実行したのは非公式移植のコアテスト。公式 1.3.1 の検査はソースと構文の比較までで、実行版との画像照合は含まない。

公式ソースの [Readme.txt:10](sources/official/mitaka_source/Readme.txt#L10) と各ソースの表示、参照版の [LICENSE](https://github.com/yoshikaz1228/Mitaka-macOS/blob/ab63d81723a9261b663c8ab1283de2e7607f1094/LICENSE) は MIT 条件を示す。
再利用時には元の著作権・許諾・免責表示を保持する。
