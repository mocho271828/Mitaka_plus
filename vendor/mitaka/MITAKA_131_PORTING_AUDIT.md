# Mitaka 1.3.1 の macOS ネイティブ移植調査

調査日: 2026-10-29（日本時間）

## 調査結果

公式1.3.1のソースを取得し、改変せずに保存した。
macOS 対応で先に解消すべき問題は、Win32 のアプリ・入出力処理、固定機能 OpenGL、Windows の型サイズを前提にしたデータ読み込みである。
天文計算の一部は macOS の Clang で構文チェックを通ったため、計算・データ・描画・OS 処理を分離して移植できる見込みがある。
ただし、公式ソース全体の macOS ビルドや実行が成立した段階ではない。

非公式 [Mitaka-macOS](https://github.com/yoshikaz1228/Mitaka-macOS) の既存コアテストと arm64 / x86_64 の universal build は成功した。
再利用候補は C++ / Swift 接続、SwiftUI の画面、Xcode 設定、簡易軌道計算である。
実装済みの範囲は8惑星と冥王星の概略表示で、公式 Mitaka の全機能を移植したものではない。
以下の対応案は調査に基づく提案であり、採用済みの実装方針ではない。

## 対象と取得記録

| 対象 | 保存場所・識別子 | 確認結果 |
|---|---|---|
| 公式 ZIP | [mitaka_source_131.zip](/Users/kota/mitaka/sources/official/mitaka_source_131.zip) | 905,545 bytes、CRC 検査成功 |
| 公式展開物 | [mitaka_source](/Users/kota/mitaka/sources/official/mitaka_source) | 310ファイル。ZIP と全ファイルがバイト単位で一致 |
| 非公式 macOS 移植 | [Mitaka-macOS](/Users/kota/mitaka/sources/reference/Mitaka-macOS) | commit `ab63d81723a9261b663c8ab1283de2e7607f1094` に固定 |
| 非公式 repo 内の上流コピー | [Upstream/mitaka-1.3.1](/Users/kota/mitaka/sources/reference/Mitaka-macOS/Upstream/mitaka-1.3.1) | 公式展開物と310ファイルすべて一致。欠落・追加・内容差異0 |

公式 ZIP の SHA-256 は `778c66bf6c81d2bf0bba380e9209882ecd961dd79cb9d2140758849d82314429`。
取得元は [国立天文台の配布一覧](https://4d2u.nao.ac.jp/mitaka/download/download_old/)にある [公式 ZIP](https://4d2u.nao.ac.jp/wp-content/uploads/mitaka/software/mitaka_source_131.zip)。
取得情報は [sources/README.md](/Users/kota/mitaka/sources/README.md)、照合結果は [upstream-comparison.json](/Users/kota/mitaka/investigation/mitaka-1.3.1/upstream-comparison.json) に残した。

詳細な静的調査記録は [OS 境界](/Users/kota/mitaka/investigation/mitaka-1.3.1/platform-findings.md)、[描画・計算](/Users/kota/mitaka/investigation/mitaka-1.3.1/render-findings.md)、[非公式移植](/Users/kota/mitaka/investigation/mitaka-1.3.1/reference-findings.md)、[非公式の UI](/Users/kota/mitaka/investigation/mitaka-1.3.1/ui-findings.md) に保存した。
各分担記録の「ビルド未実施」等は、その静的調査単体の範囲を示す。今回全体の実行結果は本書と `VALIDATION.md` を参照。

調査対象はこの2つのソースツリーに限定した。
Wine / Wineskin、既存の仮想 Windows 環境、Mitaka Plus のバイナリは今回の解析対象に含めていない。
1.3.1 の結果を、手元の Mitaka 1.7.4a や Plus 1.5.4 にそのまま適用することはできない。

## 公式ソースの構成とビルドの前提

公式ソースは C++ 146ファイル、ヘッダ161ファイル、README・アイコン・リソース各1ファイルからなる。
C++ / ヘッダの合計は75,946物理行。これは移植対象の規模を示す値であり、変更行数や工数ではない。
Visual Studio、Xcode、CMake、Make のビルド定義とテストスイートは ZIP に含まれていない。

[Readme.txt:22](/Users/kota/mitaka/sources/official/mitaka_source/Readme.txt:22) は Windows 7、Visual Studio 2015 / Intel C++ 2016 を前提とする。
リンク対象には Windows の multimedia / sockets / DirectInput / DirectShow / VfW / OpenGL ライブラリと、JPEG、zlib、PNG、GLEW、FreeType がある。
macOS 用には対象ソースを明示したビルド定義、Apple 側のアプリ target、必要な外部ライブラリの版と取得方法を用意する必要がある。
README の古いライブラリ指定は由来の記録であり、その版を今後も固定採用する判断ではない。

[Readme.txt:80](/Users/kota/mitaka/sources/official/mitaka_source/Readme.txt:80) は生成した実行ファイルをバイナリ配布物へ入れる方式を説明している。
ソース ZIP には実行用の星表・テクスチャ・地形・フォント等がないため、ソースをビルドできても完全な表示試験には別途データが必要になる。

## OS 依存を交換する具体的な箇所

| 領域と入口 | 現行実装 | 必要な変更 |
|---|---|---|
| 起動・イベント: [main.cpp:5863](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/main.cpp:5863), [mtk_window_mode.cpp:1015](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_window_mode.cpp:1015) | `WinMain`、`WNDCLASS`、`CreateWindow`、`WndProc`、Windows メッセージループ | 共通初期化とネイティブアプリの寿命管理を分離し、キー・マウス・メニューのイベントを既存操作へ接続する |
| ダイアログ: [mtk_dialog_box.cpp:388](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_dialog_box.cpp:388), [win_dlg.cpp:82](/Users/kota/mitaka/sources/official/mitaka_source/common/win_dlg.cpp:82) | Windows ダイアログを独立スレッドで起動。画像保存に `OPENFILENAMEW` | AppKit / SwiftUI の画面・ファイル選択へ置換し、GUI のスレッド所有を整理する。`.rc` の資源も移す |
| 時刻・周期処理: [main.cpp:2652](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/main.cpp:2652), [JulianDate.cpp:129](/Users/kota/mitaka/sources/official/mitaka_source/common/JulianDate.cpp:129) | `timeSetEvent`、`timeGetTime`、`GetSystemTime`。timer callback 内で入力とアニメーション更新 | 単調時計による経過時間、UTC の取得、天文学的な日時変換を分離する。終了時の callback 停止を保証する |
| CPU・並列計算: [cpu.cpp:45](/Users/kota/mitaka/sources/official/mitaka_source/common/cpu.cpp:45), [mtk_atmosphere.cpp:177](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_atmosphere.cpp:177) | MS 形式の x86 inline assembly / SSE と Windows thread pool | ARM では SSE 部分をコンパイル対象から分離し、既存 scalar 経路から検証する。大気・銀河計算のタスク分配と待機を置換する |
| コントローラー: [joystick.cpp:49](/Users/kota/mitaka/sources/official/mitaka_source/common/interface/joystick.cpp:49), [mtk_joystick.cpp:106](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_joystick.cpp:106) | DirectInput、`GetAsyncKeyState`、4軸 / 16ボタン、dead zone 0.3、キーボード優先 | macOS のデバイス・キー入力へ交換する。軸範囲、フォーカス、優先順位、応答を比較する |
| 資源・設定: [mtk_directory.cpp:68](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_directory.cpp:68), [mtk_ini_file.cpp:219](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_ini_file.cpp:219), [win_file.cpp:78](/Users/kota/mitaka/sources/official/mitaka_source/common/win_file.cpp:78) | CWD、backslash、`_splitpath`、Windows Profile API、ホスト名別 INI | `.app` 資源、利用者設定、出力先を分離する。既存キー・既定値・ホスト名別 fallback を移行仕様に含める |
| フォント: [mtk_languages.cpp:198](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_languages.cpp:198), [mtk_font.cpp:110](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_font.cpp:110) | Windows の Fonts ディレクトリと `arialuni.ttf` への fallback。FreeType にファイルを渡す | macOS のフォント解決を用意し、日本語字形・字幅を比較する。同梱する場合はフォントの条件を確認する |
| 動画・音声: [mtk_movie.cpp:144](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_movie.cpp:144), [main.cpp:3946](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/main.cpp:3946) | ATL / COM / DirectShow、VMR7 / VMR9 / EVR。音声も同じ再生経路 | AVFoundation 等を候補に再生・停止・seek・終了イベントを実装し、位置の単位とネットワーク同期を合わせる |
| 通信・同期: [tcp_udp.cpp:66](/Users/kota/mitaka/sources/official/mitaka_source/common/tcp_udp.cpp:66), [mtk_tcp.cpp:497](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_tcp.cpp:497) | Winsock、構造体の直接送信、Windows のロック | ソケット型とエラー処理を交換する。送信形式の幅・alignment・実パケットを確認して codec を分離する |

特に注意が必要な箇所は次のとおり。

- [mtk_tcp.cpp:728](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_tcp.cpp:728) はロック取得中に `send_data_char()` を呼び、同関数の553行で同じロックを再取得する。`CRITICAL_SECTION` を非再帰の `std::mutex` へ単純置換すると、この経路で停止する。
- IPv4 を `unsigned long` とその `sizeof` で扱う [tcp_udp.cpp:74](/Users/kota/mitaka/sources/official/mitaka_source/common/tcp_udp.cpp:74) も LP64 対応が必要。ファイル形式だけの問題ではない。
- 通信には受信長の検証不足、非整列の型付きポインタ参照、部分送信の扱いという既存課題がある。移植前からある保守課題として切り分けた。今回は通信実行・プロトコル変更・セキュリティ修正は行っていない。
- AVI / VfW のクラスと設定は存在するが、ユーザー操作からの有効な呼出は確認できていない。動画再生と AVI 書出しをまとめて必須移植機能としない。
- `JulianDate` の算術変換をすべて OS の日時型へ置換せず、広い年代範囲を扱う既存の天文計算と、現在 UTC を得る処理を分ける。

## 描画は固定機能 OpenGL からの移行が必要

[gl_win.cpp:58](/Users/kota/mitaka/sources/official/mitaka_source/common/graphics/gl_win.cpp:58) の WGL context 作成と表示同期だけを交換しても、macOS の OpenGL Core Profile では動かない。
1.3.1 の自前ソースには `glBegin` が108箇所 / 38ファイル、行列スタック関連 API が308箇所 / 42ファイルあり、固定照明、display list、`GL_QUADS` に依存している。
shader 作成・compile・use API、VBO の生成・upload、`glDrawArrays` / `glDrawElements` は今回の検索では見つからなかった。
これらはコメントを含み得る字句検索の件数であり、実行頻度ではない。手元の1.7.4aのシェーダ対応とは区別する。

| 変更対象 | ソース上の入口 | 移行時に保つもの |
|---|---|---|
| frame・camera・描画順 | [main.cpp:2336](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/main.cpp:2336), [mtk_objects.cpp:206](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_objects.cpp:206) | double の位置計算、camera 相対座標、near / far 分割、透明物の描画順。行列 stack は明示的な行列へ置換 |
| 惑星・地形・雲 | [mtk_planets.cpp:998](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planets.cpp:998), [gl_triangle_mesh.cpp:44](/Users/kota/mitaka/sources/official/mitaka_source/common/graphics/gl_triangle_mesh.cpp:44) | 頂点・法線・UV、光源・材質、地形 LOD、雲と注記の合成。vertex / index buffer と shader に移す |
| 恒星・銀河・軌道線 | [mtk_stars.cpp:548](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_stars.cpp:548), [mtk_galaxies.cpp:328](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_galaxies.cpp:328) | 星の画面上サイズ、明るさ・alpha、点・線の描き方 |
| 画像・文字・overlay | [gl_texture.cpp:68](/Users/kota/mitaka/sources/official/mitaka_source/common/graphics/gl_texture.cpp:68), [main.cpp:2427](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/main.cpp:2427) | CPU の画像 decode と GPU upload を分離。字幕、メニュー、fade、文字 atlas の描画順と色 |
| offscreen・ドーム・立体視 | [mtk_pbuffer.cpp:229](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_pbuffer.cpp:229), [mtk_dome_master.cpp:526](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_dome_master.cpp:526), [mtk_stereo.cpp:99](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_stereo.cpp:99) | WGL pbuffer / FBO を render target へ交換。ドームの5方向描画・歪み map、眼順・色・配置を維持。pbuffer の全呼出経路は未確認 |

短期の比較用に Legacy OpenGL を使う案はあるが、対象 Mac の context 作成・拡張・表示は未検証。
Core Profile を使う場合にも固定機能の再実装が必要になるため、Metal を目指すなら Core Profile 移植を必須の中間段階にはしない案が合理的である。
Apple は固定機能からの移行手順を説明し、OpenGL 自体は macOS 10.14 から非推奨としている。[Apple の移行資料](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/UpdatinganApplicationtoSupportOpenGL3/UpdatinganApplicationtoSupportOpenGL3.html)、[OpenGL profiles](https://developer.apple.com/documentation/appkit/opengl-profiles)

宇宙座標をそのまま Float に落とすと距離スケールによる精度問題を招く。
CPU の double 計算と camera 相対座標を維持し、GPU に渡す座標範囲を明確にすることが描画移行の重要な検証点になる。

## 公式コードから再利用しやすい計算部分

| 候補 | 根拠・注意点 |
|---|---|
| [mtk_orbital_element.cpp:55](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_orbital_element.cpp:55) | 軌道要素から位置・速度・軌道線を計算。調査した実装に WinAPI / GL 呼出しはない |
| [cele_mech.cpp:48](/Users/kota/mitaka/sources/official/mitaka_source/common/astro/cele_mech.cpp:48), [astrometry.cpp:73](/Users/kota/mitaka/sources/official/mitaka_source/common/astro/astrometry.cpp:73) | 楕円・双曲線軌道、座標変換、固有運動。両翻訳単位は今回の Clang 構文チェックに成功 |
| [cf96.cpp:231](/Users/kota/mitaka/sources/official/mitaka_source/common/astro/cf96.cpp:231), [mtk_trajectory.cpp:118](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_trajectory.cpp:118) | 暦評価と軌跡補間。数値計算と binary decoder を分離し、適用範囲、補間、km→pc、範囲外の挙動を保持 |
| [mtk_planet_orientation.cpp:261](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_orientation.cpp:261) | 姿勢行列の計算と GL へ適用する処理を分離できる |

ただし、`planet` は物理量と `GLuint` / 地形資源を同じクラスに持ち、`mtk_object` も位置・選択・描画を併せ持つ。
計算層全体が独立したライブラリになっているわけではない。[planet](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet.h:65)、[mtk_object](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_object.h:113)
抽出時は天体モデル、frame ごとの可視性・相対位置、GPU 資源の所有を分ける必要がある。
姿勢→位置の更新順、地球月系等の重心補正、CF96・軌跡・平均軌道の選択は数値回帰の対象にする。

## データ互換性で先に直す箇所

Clang のターゲット定義で、64bit Windows の `long` は4 byte、arm64 macOS の `long` は8 byte、`wchar_t` はそれぞれ2 / 4 byteと確認した。
CPU がどちらも64bitであることは、ファイル上の型サイズが同じという意味ではない。

| 根拠 | 現状と問題 | 必要な変更・確認 |
|---|---|---|
| [mtk_stars.cpp:205](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_stars.cpp:205), `read_a_Hipparcos_star` | HIP 番号を `long` とし、`sizeof(HIP)` で読む。macOS では後続フィールドの読み取り位置がずれる | ファイル形式に合わせた32bit整数と明示的な読み取りに変更。レコード全体のバイト数、符号、little-endian、EOF を検証 |
| [mtk_constellation.cpp:178](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_constellation.cpp:178) | 星座線の HIP 番号も `long` のサイズで読む | 恒星カタログと共通の固定幅 ID 表現へ変更し、星座線の参照一致を試験 |
| [image.cpp:84](/Users/kota/mitaka/sources/official/mitaka_source/common/graphics/image.cpp:84) | `DWORD = unsigned long`。BMP ヘッダの読み書きが `sizeof(DWORD)` / `sizeof(long)` に依存 | BMP の32bit / 16bitフィールドを明示し、読み込みだけでなく保存も修正。既存形式の fixture で往復・互換性を確認 |
| [3ds_loader.cpp:334](/Users/kota/mitaka/sources/official/mitaka_source/common/graphics/3ds_loader.cpp:334) | `unsigned long` の smoothing mask に4 byteだけ読み込む | `uint32_t` 相当へ変更。chunk 長や他の固定幅フィールドも確認 |
| [unicode_string.cpp:129](/Users/kota/mitaka/sources/official/mitaka_source/common/text/unicode_string.cpp:129), `utf8_to_wstring` | UTF-16 のコード単位を `wchar_t` に追加する Windows 前提。macOS の wide string の意味と合わない | UTF-8 をアプリ境界の基本表現とする案を検討。UTF-16 は `char16_t` / 既存固定幅型で明示し、日本語・補助文字を試験 |
| [mtk_languages.cpp:160](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_languages.cpp:160) | `fopen(..., "rt")` と末尾 `\n` の除去を前提に言語ファイル名を読む。macOS では CRLF の `\r` が残る | CRLF / LF を明示的に処理し、実在するパスへ解決できることを確認 |

ほかの `fread` / `fwrite` も、ファイル形式の型とメモリ上の型を対応付ける必要がある。
`int` / `short` / `float` の読み取りをすべて不具合と判断するものではない。
例えば地形や CF96 は、フィールド幅の確認に加え、長さ・件数・短い読み取りを検証する対象となる。
元データの形式は維持し、読み手のメモリ表現を分離する方法で既存データとの互換性を検証する。

## 非公式 macOS 移植の再利用範囲

参照版の Xcode target がコンパイルするのは Swift 4ファイルと144行の独立した C++ コアで、保存された公式310ファイルはビルド対象ではない。
そのため、ビルド成功は公式本体の依存解消を意味しない。[ビルド対象](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac.xcodeproj/project.pbxproj:150)

| 再利用候補 | 確認した実装 | 採用前に必要な作業 |
|---|---|---|
| [MitakaCore.h:6](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.h:6) と [bridging header](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Support/MitakaMac-Bridging-Header.h:1) | `extern "C"` で C++ を Swift から呼ぶ、小さな C ABI。ObjC++ 実装はない | 単位、原点、座標系、時間尺度、有効日時、エラー表現を API に明記。公式の計算・データ層を接続 |
| [MitakaCore.cpp:58](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.cpp:58) | 9天体の軌道要素、楕円 Kepler 方程式、軌道面の回転、Unix time→JD | 簡易軌道経路の参考として使える。CF96・衛星・速度・重心補正等の完全な計算層は追加移植が必要 |
| [MitakaMacApp.swift:8](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/MitakaMacApp.swift:8), [ContentView.swift:7](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/ContentView.swift:7) | macOS のウィンドウ、天体一覧、検索、選択、表示切替、キーボード操作 | ネイティブ画面の雛形として再利用可能。観測地点・任意日時・飛行・プラネタリウム操作等を追加 |
| [AppModel.swift:15](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/AppModel.swift:15) | MainActor 上の状態管理と C ABI 呼び出し、30 Hz の時刻更新 | 0.25秒で経過時間を切り詰めるため、停止・復帰後の実時間同期仕様を見直す。大型データの背景読み込みを分離 |
| [UniverseSceneView.swift:24](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:24) | `NSViewRepresentable` / Coordinator の表示境界、球・軌道線・ラベル・カメラ操作 | 表示境界と操作例は参考になる。SceneKit 部分は長期保守の描画基盤として別途評価 |
| [project.pbxproj:273](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac.xcodeproj/project.pbxproj:273) | macOS 14.0、target の C++17、Swift language mode 5。今回 universal build 成功 | 将来の最低 OS と対象 CPU を決める。依存・リソース・ライセンス同梱、署名・公証、CI を追加 |
| [MitakaCoreTests.cpp:12](/Users/kota/mitaka/sources/reference/Mitaka-macOS/Tests/MitakaCoreTests.cpp:12) | コアの個別ビルドと基本的な健全性のテスト | 元の計算との回帰比較、日時境界、異常入力、データローダー、UI の試験を追加。Xcode の test action に test target はない |

### 軌道計算は公式の簡易経路に相当する

公式の [mtk_planet_position.cpp:258](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp:258) は、適用範囲内では CF96 と軌跡データを使い、範囲外では平均軌道要素へ切り替える。
参照版は平均軌道要素の経路だけを実装する。
月・衛星、地球月系 / 冥王星カロン系の補正、個別軌跡、惑星速度、双曲線軌道などは含まれない。

平均軌道表の値と平均運動の係数は公式由来だが、Kepler solver は書き直されている。
収束閾値は公式の `1e-8` に対して参照版は `1e-10`、未収束時の扱いも異なる。
参照 API は AU、公式の惑星位置格納は pc なので、座標を直接交換できない。[公式 solver](/Users/kota/mitaka/sources/official/mitaka_source/common/astro/cele_mech.cpp:48)、[参照 solver](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/Core/MitakaCore.cpp:75)、[公式の単位変換](/Users/kota/mitaka/sources/official/mitaka_source/Mitaka/mtk_planet_position.cpp:293)

### 太陽系の画面は観測用表示とは分けて扱う

参照版は距離と半径を対数で圧縮して表示し、描画座標を Float に変換する。
背景は固定 seed で生成した1,600点で、実際の恒星カタログではない。
惑星の固定色や土星の環はあるが、公式の地形・画像・自転・観測者モデルを移植したものではない。[表示半径](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:150)、[背景星](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:225)、[距離変換](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac/UniverseSceneView.swift:265)

カメラは選択が変わった時に移動し、時刻進行による天体移動を追尾しない。
観測用の星空、自由飛行、地表から宇宙までの連続表示には、別途カメラ・精度・LOD の実装が必要になる。
未移植機能は [PORTING.md:23](/Users/kota/mitaka/sources/reference/Mitaka-macOS/docs/PORTING.md:23) でも明記されている。

Apple は SceneKit を soft deprecation とし、新規アプリや大きな更新には推奨せず、保守対応を中心とする方針を説明している。
既存アプリが直ちに動かなくなるという説明ではないが、長期保守を目的とする本体移植で投資を集中するかは再評価が必要である。[Apple WWDC25](https://developer.apple.com/videos/play/wwdc2025/288/)
SwiftUI と C++ 接続を活用し、描画側は Metal 等の適合性を実データ・天文学的な距離範囲・多視点 / ドーム要件で評価する案が考えられる。
参照版には独自の Metal shader / renderer はなく、SceneKit の使用と Metal による本体描画の実装を混同しない。

## 着手順と完了条件の案

| 順序 | 作業 | 完了の判断材料 |
|---|---|---|
| 1 | 公式計算コアの build target を作り、OS 時刻を分離。型幅・CRLF・パス処理を修正する | 実データから HIP / 星座 / BMP を読める。既知日時の位置・速度・座標変換と境界条件が元の計算に一致する |
| 2 | 非公式版のアプリ起動・SwiftUI・C ABI を土台に、公式コアと資源を接続する | 日本語パス・ラベル、時刻、天体選択、カメラ操作をネイティブで確認できる。データ読込が UI を停止させない |
| 3 | 描画方式を試作・比較する。長期保守では Metal の適合性を優先評価する | 恒星・惑星・軌道・日本語を実データで表示し、深度・透明度・近遠の精度・Retina・性能を比較できる |
| 4 | 必須とした地表、銀河、ドーム、立体視、入力機器、メディア、通信を段階移植する | 採用機能ごとに既存操作・表示・同期との比較が通る。AVI 等の未使用疑いは呼出確認後に範囲を決める |
| 5 | CI、依存固定、データ・ライセンス同梱、署名・公証、対象 Mac での確認を整える | 再現可能な build と配布物を用意でき、対応する OS / CPU での起動・操作を確認できる |

最初の実装単位としては、描画に先立つ「公式の軌道計算とデータローダーを macOS で検証できる core target」が適している。
非公式版の簡易計算だけを拡張するより、公式の精度・データ仕様を維持できる境界を先に確定できるためである。
Legacy OpenGL の比較用試作を追加するかは、必要機能と目標 OS を決めた後に判断する。
上表は移植計画の提案であり、今回実装した内容ではない。

## 実施した検証と限界

環境は macOS 26.6.2、Xcode 27.1、Apple clang 21.0.0、arm64 ホスト。
コマンドと診断は [VALIDATION.md](/Users/kota/mitaka/investigation/mitaka-1.3.1/VALIDATION.md) に保存した。

| 検証 | 結果 | 判断できる範囲 |
|---|---|---|
| 公式 ZIP の整合性・原本保全 | 成功 | 取得物の CRC、展開後のバイト一致 |
| 公式の15翻訳単位を Clang で構文チェック | 10成功、5失敗 | 計算の `cele_mech` / `astrometry` / `cf96`、数学・文字列処理の一部は構文確認に成功。リンク・実行は未確認 |
| 失敗した公式コード | `windows.h`, `tchar.h`, `stricmp` | OS / CRT 依存を再現。CP932 リテラルや include 大文字小文字の警告も確認 |
| 非公式の既存コアテスト | 成功 | 9天体、地球の識別、J2000 の有限座標と概略距離、Unix epoch の JD 変換 |
| 非公式の universal build | `BUILD SUCCEEDED` | Mach-O に `arm64` / `x86_64` があることを確認。署名なし |

公式本体の全体ビルド、公式実行版との数値・画像比較、GUI 起動、実機操作、描画性能、Intel 実機での実行は未実施。
公式のビルド定義と macOS 境界の実装がまだなく、今回はソース調査と既存の部分移植のビルド確認に限定したためである。
非公式の現行テストには公式暦との精度比較がなく、テスト成功をプラネタリウムの精度保証とは扱えない。

## 利用条件と残る判断

公式ソースの [Readme.txt:10](/Users/kota/mitaka/sources/official/mitaka_source/Readme.txt:10) と各ソースの表示、参照版の [LICENSE](/Users/kota/mitaka/sources/reference/Mitaka-macOS/LICENSE) は MIT 条件を示す。
再利用時には元の著作権・許諾・免責表示を保持する。
参照版の Xcode resources phase は空のため、配布用アプリにライセンス文書を含める処理も必要になる。[resources phase](/Users/kota/mitaka/sources/reference/Mitaka-macOS/MitakaMac.xcodeproj/project.pbxproj:139)

天文データ、テクスチャ、地形、モデル、フォントの利用・再配布条件はソースとは別に確認する。
既存 Wine パッケージ内のデータをコピーして公開してよいとは判断していない。
条件と版の詳細は [SOURCE_AVAILABILITY.md](/Users/kota/mitaka/SOURCE_AVAILABILITY.md) を参照。

実装に進む前の未決事項は、最低 macOS、Intel 対応、1.3.1 のどの機能までを初期対象にするか、数値・画像の受入基準、使うデータ、既存利用者や運用の有無である。
本調査ではこれらを決定しておらず、後方互換や実装方針を採用する時にプロジェクト状態を確認して `IMPLEMENTATION_POLICY.md` に記録する。

## 作業記録

- 公式 ZIP・原本と、固定 commit の参照リポジトリを取得した。両方のソースに変更はない。
- 本調査書、取得記録、検証記録・ログを追加し、既存の2つの調査書から案内した。
- `/Users/kota/mitaka` は Git リポジトリではない。新規取得した参照 repo の `git status --short` / `git diff --stat` は変更なし。
- 原本の取得は大規模だが、親ディレクトリに Git がないため commit は作成していない。参照 repo にも commit 対象の変更はない。
- `/simplifier-lai` は未実行。調査・取得のみで、commit 対象の実装差分がないため。
- `IMPLEMENTATION_POLICY.md` / `policy_gates/` は更新していない。提案を採用済み方針には変更していない。
- 検証結果は上表のとおり。新規アプリ実装がないため追加の lint・型チェックは行っていない。
