# Mitaka 1.3.1 の macOS 移植: プラットフォーム境界調査

対象原本: `vendor/mitaka/sources/official/mitaka_source`.
調査方法: ソースと付属文書の静的読取り. 原本は変更せず, アプリ実行・ビルド・通信は行っていない. 以下の相対パスと行番号はこの原本を基準とする. CP932 をデコードして読んだ場合も改行数を維持した.

## 結論

この配布物は Win32/DirectInput/DirectShow/Winsock を使う C++ ソースである. 数値計算を残しつつ, ウィンドウ・入力・ファイルパス・メディア・同期・通信の OS 境界を交換する必要がある. Windows API を置き換えるだけでは不十分で, `long` の幅に依存する既存ファイル形式, UTF-16 を `wchar_t` に格納する文字列処理, Windows のテキストモードによる CRLF 変換も変更対象になる.

本報告は本家 1.3.1 のコードに対する所見であり, 手元の Mitaka/Plus バイナリの全機能や現行本家の実装へそのまま一般化しない. 描画方式は[描画の調査](render-findings.md), Clang の結果は[構文検証](VALIDATION.md)を参照.

## 1. ビルドと依存関係: 確認事実

- `Readme.txt:1–5`: Mitaka version 1.3.1 ソースコード, 2016/3/4, 加藤恒彦 / 国立天文台.
- `Readme.txt:10–15`: ソースは MIT License, 著作権・許諾表示の保持を要求.
- `Readme.txt:22–26`: Windows 7 Ultimate 64 bit, Visual Studio 2015 Professional, Intel C++ Composer XE 2016 でのビルド環境. ホスト OS の 64 bit 表記だけでは生成物の ABI を断定できない.
- `Readme.txt:34–36`: `_USE_MATH_DEFINES` を要求.
- `Readme.txt:38–55`: `libcmt`, `libvcruntime`, `libucrt`, `vfw32`, `wsock32`, `winmm`, `opengl32`, `glu32`, `mfuuid`, `dxguid`, `dinput8`, `Strmiids`, `libjpeg`, `zlib`, `libpng`, `glew32s`, `freetype26MT` を列挙.
- `Readme.txt:57–64`: DirectX SDK June 2010 と IJG JPEG / zlib / libpng / GLEW / FreeType 2.6 を別途用意する説明. `:66–70` は `/MT` と `libc` の除外, `:72–73` はマルチバイト文字セット.
- `Readme.txt:75–77`: ソースとライブラリをプロジェクトへ追加する手順. 調査した 310 個の通常ファイルに `.sln`, `.vcproj`, `.vcxproj`, `.pbxproj`, `.cmake`, `CMakeLists.txt`, `Makefile`, 同梱 `.lib` / `.dll` はない.
- `Readme.txt:80–82`: 配布バイナリの実行ファイルをビルドしたものに置き換える手順. ソース単独で必要な実行時データが揃う構成ではない.

変更候補: 再現可能なビルド定義を新設し, MSVC ランタイム指定と Windows SDK のリンクを OS ごとに分離する. JPEG / PNG / zlib / FreeType など汎用依存は継続利用候補であり, Wine 由来として除外するものではない. 正確な依存版・配布条件・現在の Mac 対応 API は導入時に別途確認する.

## 2. 起動・ウィンドウ・メニュー・時間

| 原本の位置 | 確認できた実装 | 移植時の変更箇所 |
|---|---|---|
| `Mitaka/main.cpp:5863` `WinMain()` | FreeType/CPU 初期化, Windows バージョン照会 `:5875`, `GetComputerName` `:5884`, カレントディレクトリ・INI 初期化 `:5893–5894`, モード選択 `:5934–5935` | ネイティブの起動ライフサイクルと共通初期化を分離. ホスト名別設定の扱いを明示する |
| `main.cpp:5831` `check_multiple_launch()` | `CreateMutex` `:5835`, `ERROR_ALREADY_EXISTS`, `FindWindow`, 既存ウィンドウの前面化 | 多重起動制御と既存インスタンスへの通知を置換 |
| `main.cpp:5923` | `REALTIME_PRIORITY_CLASS` を指定 | 優先度設定の必要性を再評価し, そのまま移植しない |
| `Mitaka/mtk_window_mode.cpp:1127` `Main_WindowMode()` | `WNDCLASS` / `RegisterClass` `:1133–1144`, `CreateWindow` `:1186`, メニュー作成 `:1205`, `PeekMessage` / `TranslateMessage` / `DispatchMessage` `:1241` | ウィンドウ・メニュー・イベントループを交換 |
| `mtk_window_mode.cpp:1015` `WndProc_WindowMode()` | `WM_COMMAND`, Alt+Enter, paint/resize/activate, mouse/key, `WM_GRAPHNOTIFY`, destroy を振り分け | イベント変換層を設け, 共通の操作関数への接続を保つ |
| `main.cpp:2652` `OnCreate()` | `GetDC`, GL 初期化 `:2657`, ジョイスティック協調レベル, `timeBeginPeriod(1)` `:2677`, `timeSetEvent` `:2679` | 描画と入力タイマーの所有者・スレッドを整理 |
| `main.cpp:2855` `OnTimer()` | 初回 `CoInitializeEx(..., COINIT_MULTITHREADED)` `:2862`, 入力更新 `:2866`, アニメーション `:2869` | タイマー callback からの入力・状態更新とメインスレッドの関係を維持して置換 |
| `main.cpp:2687` `OnDestroy()` / `:2875` `OnKillTimer()` | マルチメディアタイマー終了と COM 終了. `WinMain` の `:5976–5978` は完了まで Sleep | 終了待ちと callback 停止を明示的な寿命管理へ置換 |
| `common/frame_rate.h:47` `fps_counter` | `DWORD` 時刻 `:51`, `timeGetTime` `:58`, DWORD 差分 `:61` | 単調時計の期間型に置換, 既存の時間単位を確認 |
| `common/JulianDate.cpp:129` `get_present_JD()` | `SYSTEMTIME` / `GetSystemTime`, UTC の年月日時分秒・ミリ秒を Julian Date へ渡す | UTC 取得だけを交換し, `get_JD()` `:61` / `JD_to_UTC()` `:89` の数値変換を保持可能 |

追加の UI 境界:

- `Mitaka/mtk_dialog_box.cpp:388` `SetTimeDialog_thread()` は `CreateDialog` `:391`, 独自 `GetMessage` ループ `:397`, `CreateSetTimeDialog()` から `_beginthread` `:412` を使う. `Splash_thread()` `:711` も `CreateWindowEx` `:742`, `GetMessage` `:760`, `_beginthread` `:774` を使う. ネイティブ GUI のスレッド所有規則に合わせて組み直す箇所である.
- `Mitaka/Mitaka.rc:10` は `afxres.h`, `:19–20` は日本語・code_page 932, `:53` 以降は Windows ダイアログ, `:98` はアイコン, `:105` 以降は版情報. これらは macOS 用リソースへ置換対象.
- `common/win_dlg.cpp:82` `GetFileNameW()` は `OPENFILENAMEW`, `GetSaveFileNameW` `:99–101`, `GetOpenFileNameW` `:104–105`. 呼出例は `main.cpp:2897` `OnSaveImage()` と `Mitaka/mtk_save_image.cpp:69` `save_image_high_resolution_get_filename()`.
- `main.cpp:5715` `OnKeyDown()` は文字キーや F1 / Esc の操作, `MessageBoxW` `:5754` を含む. `mtk_window_mode.cpp:995` `OnMouseWheel()` は delta の符号をズームへ変換する. キーコード・座標・スケール・フォーカスの変換を行い, 共通操作の意味を保つ必要がある.

## 3. CPU・並列計算・ロック

確認事実:

- `common/cpu.cpp:45` `get_cpu_info()` は `__try` / `__except` と MS 形式 `_asm cpuid` `:54–61`, SSE 命令の例外検出 `:89–107` を使う. `common/cpu.h:42` は `xmmintrin.h`. Apple Silicon でそのままコンパイルするコードではない.
- `Mitaka/mtk_cpu_info.cpp:49` `init_cpu_info()` は `GetSystemInfo` `:51` と上記 CPU 判定, `get_number_of_cpu()` `:58–61` は Windows 構造体のプロセッサ数を返す.
- `Mitaka/mtk_atmosphere.cpp:177` `calc_ray_sub_SSE()` は `__declspec(align(16))`, `__m128`, MS 形式インラインアセンブリ `:203–245`. `calc_ray()` `:264` には `is_SSE_Enable()` が偽なら scalar 処理 `:307–311`, 真なら SSE `:315` という分岐が既にある. 実行時分岐だけでは ARM コンパイルエラーを避けられず, SSE 実装をコンパイル対象から分離する必要がある.
- `mtk_atmosphere.cpp:1040` の XP 経路は `_beginthreadex` `:1057`, `WaitForMultipleObjects` `:1063`, `CloseHandle` `:1067`. Vista 経路は `InterlockedIncrement` `:1090`, `SubmitThreadpoolWork` `:1110`, `WaitForThreadpoolWorkCallbacks` `:1113`, `CreateThreadpoolWork` `:1122`.
- `Mitaka/mtk_our_galaxy_rt.cpp:648–734` に同様の XP / Vista の二経路がある. 計算本体を残し, タスク分配・待機・終了処理を交換する境界が明確に存在する.
- `Mitaka/mtk_thread.h:48` の CS ラッパーは `CRITICAL_SECTION` の初期化・破棄・Enter/Leave を包む.
- **再帰ロックが必要な現行経路**: `Mitaka/mtk_tcp.cpp:728` `send_media_info()` が CS を取得し, `:731` で呼ぶ `send_data_char()` が `:553` で同じ CS を再取得する. 非再帰の `std::mutex` への単純置換はこの経路をデッドロックさせる.

変更候補: まず既存の scalar 計算経路で正しさを確認できる構成にし, SIMD 最適化は別途比較する. ロックの再帰性を保つか呼出関係を整理するかは, 置換実装時に明示する.

## 4. 入力: DirectInput と Win32 キー状態

- `common/interface/joystick.cpp:49` コンストラクタ: `DirectInput8Create` `:55`, `EnumDevices` `:60`, `SetDataFormat` `:68`, `EnumObjects` `:72`.
- `EnumJoysticksCallback()` `:87` はデバイス作成後 `DIENUM_STOP` `:94`: 最初の利用可能デバイスを採用する実装.
- `EnumObjectsCallback()` `:98` は軸範囲を -1000 から +1000 に設定 `:112–113`.
- `SetCooperativeLevel()` `:132`, `GetJoystickState()` `:150` は HWND/協調レベル, Poll/Acquire/GetDeviceState を扱う.
- `axis_state::key_in()` `:188` と `button_state::key_in()` `:235` は `GetAsyncKeyState`. 軸の joystick 入力 `:210` は既にキー入力値があれば戻る `:212`: キーボード優先という動作がある.
- `joystick_state::update()` `:255` は 4 軸・16 ボタン, キー状態を先に反映 `:273–277` し, 続けて DirectInput 状態を扱う `:284–287`.
- `Mitaka/mtk_joystick.cpp:38` に静的 joystick オブジェクト. `init_joystick()` `:106` は単位 1000 と dead zone 0.3 `:109`, キー設定 `:116–119`. `joystick_SetCooperativeLevel()` `:132–135` は `DISCL_EXCLUSIVE | DISCL_FOREGROUND`.

変更候補: デバイス取得だけでなく, 軸範囲, dead zone, 応答曲線, キーボード優先, フォーカスと排他的取得を置換時の動作仕様に含める. macOS の入力 API / ライブラリ選定は未実施.

## 5. 文字コード・ファイルパス・INI

### 確認事実

- `Readme.txt`, `Mitaka/main.cpp`, `common/text/unicode.cpp` の確認サンプルは strict UTF-8 デコードに失敗し, CP932 では成功した. それぞれ LF 数と CRLF 数が一致した. この結果を全ファイルの文字コード断定には使わない.
- `common/win_file.cpp:52` `fopen_utf8()` は通常の `fopen(fn, mode)` `:56` の後, UTF-8 BOM のみを読み飛ばす `:59–64`. 関数名に反してファイル名の UTF-8→OS 変換や本文の文字コード変換はしない.
- `common/win_file.cpp:78` `directory::set()` は `_splitpath` `:83` と末尾 backslash 補完 `:86`. `get_path()` `:92` は `_MAX_PATH` の静的バッファ, `_splitpath` `:99`, `_makepath` `:103`.
- `Mitaka/mtk_directory.cpp:40` に data / locale / textures / media / spacecraft の相対ディレクトリ. `init_directory()` `:68–70` は `GetCurrentDirectory`, `set_current_directory()` `:79–81` は `SetCurrentDirectory`.
- `Mitaka/mtk_ini_file.cpp:219` `load_ini_file()` は `mitaka_<computername>.ini` `:222` を探し, `mitaka.ini` へ戻す `:228`. `GetCurrentDirectory` と `wsprintf("%s\\%s")` `:234–235` で絶対パスを組み立てる.
- `read_ini_bool()` `:187–192` は `GetPrivateProfileInt`, `read_ini_float()` `:198–207` は `GetPrivateProfileString` と `sscanf`. `Mitaka/mtk_params.cpp:85`, `mtk_colors.cpp:102` にも Profile API がある.
- `mtk_ini_file.cpp:258–262` は言語選択に `GetLocaleInfo`, `:356–368` はデータ等のディレクトリ, `:781–784` はコンピュータ別 camera 設定と共通設定.
- `common/graphics/image.cpp:756–867` の wide-path 画像読書きは `_wfopen`, `:883` / `:901` は `_wsplitpath_s`. `_splitpath` は `obj_loader.cpp:503`, `3ds_loader.cpp:698`, `Model3D.cpp:160`, `Mitaka/mtk_3D_model.cpp:71` にもある.
- `common/text/unicode.h:47–48` は `utf16=uint16_t`, `utf32=uint32_t` と固定幅で定義される. 一方 `unicode_string.cpp:129` `utf8_to_wstring()` は UTF-16 列へ変換 `:133` して, 各コード単位を `wchar_t` へ格納 `:135–136`. Windows の 16 bit wchar 前提がある. macOS の 32 bit wchar で補助文字を扱う場合, surrogate pair が単一 scalar に変換されない.
- **CRLF の具体的影響**: `Mitaka/mtk_languages.cpp:153` `load_language_files()` は `languages.dat` を `"rt"` で開く `:160`, `fgets` `:167` の末尾 `\n` だけを除去 `:171–173`, その文字列を設定ファイル名として渡す `:176`. macOS の通常の stdio で CRLF ファイルを読むと末尾 `\r` が残り, 別ファイル名になる.
- `common/text/key_value_file.cpp:62` `load_key_value()` の trim は `" \t\n"` `:77`, `:92–93` であり `\r` を含まない. 文字コード変換とは別に改行正規化が必要.
- `mtk_languages.cpp:198` `select_language()` は `SHGetFolderPath(..., CSIDL_FONTS)` `:217`. `Mitaka/mtk_font.cpp:110` `init_font_face_sub()` は指定フォントを `FT_New_Face` `:116` で開き, 失敗時に Windows フォントディレクトリと backslash で結合 `:119–120`. `mtk_languages.cpp:142` には `arialuni.ttf` のフォールバック指定.
- MS CRT 固有の `stricmp` / `_stricmp` / `_snprintf` 等が使われる. [構文検証の結果](VALIDATION.md)に停止箇所を記載した.

変更候補: 既存データの CP932/UTF-8/BOM/CRLF を一括に決めつけず, ファイル種類ごとに読み込み契約を決める. OS パスは独立した変換境界で扱い, 読取専用アプリ資源・利用者設定・画像保存先を CWD 依存から分離する. INI を置き換える場合は既存のキー, 既定値, 数値変換, ホスト名別フォールバックの挙動を比較する. フォントは実在ファイルとライセンスを確認して同梱または OS フォント解決する.

## 6. ファイル形式・ABI の確定問題

| 原本の位置 | 現行コード | macOS LP64 で必要な修正 |
|---|---|---|
| `Mitaka/mtk_stars.cpp:205` `read_a_Hipparcos_star()` | `long HIP` `:207` を `sizeof(HIP)` `:221` で読む. 入力は `main.cpp:662` の `hip.dat` | Windows 4 byte に対して 8 byte となり後続レコードがずれる. ファイル境界は `int32_t` に固定 |
| `Mitaka/mtk_constellation.cpp:178–179` | `long HIP` を `sizeof(HIP)` で読む. 対象は `:207` の `constellation_HIP.dat` | 同じ 32 bit 固定幅化 |
| `common/graphics/image.cpp:86` | 独自 `DWORD=unsigned long`. `loadBMP()` `:116,123–145` / `saveBMP()` `:182,212–229` は `sizeof(DWORD)` / `sizeof(long)` | BMP の 32 bit フィールドを 64 bit として読書きするため固定幅化 |
| `common/graphics/dib.cpp:201` `load()` / `:252` `save()` | `sizeof(long)` を使う BMP I/O | Windows 構造体の代替だけでなくディスク上の幅も固定 |
| `common/graphics/3ds_loader.cpp:327` `read_smooth_group_list()` | `unsigned long flg` `:334` へ 4 byte だけ fread `:335` | LP64 では上位が未初期化のまま評価される. `uint32_t` 化. chunk length `:114` は `unsigned int` であり同じ問題と混同しない |
| `common/tcp_udp.cpp:66` `get_host_entry()` | IPv4 を `unsigned long` に入れ `sizeof(svraddr)` `:74` を渡す. `:94` でアドレスを `unsigned long*` として読む | IPv4 の幅を越える参照/長さを避け, OS のアドレス型と明示的なコピー長を使う |

これらは `long` をコード全体で機械的に置換する指示ではない. ファイル・プロトコル境界と内部計算型を区別する. 親はターゲット別の `long` / `wchar_t` 幅と構文プローブを別途実測済み.

## 7. 通信

確認事実:

- `common/tcp_udp.h:46` は Winsock 依存. `WSAStartup`, `closesocket`, `SOCKET`, `sin_addr.S_un.S_addr` の OS 層分離が必要.
- `Mitaka/mtk_tcp.cpp:472` の `accept()` 長引数は `int`. `:215–216` / `:478–479` の `TCP_NODELAY` 値は `char`. POSIX の `socklen_t` や適切なソケットオプション型へ置換する境界.
- `mtk_tcp.cpp:497` `send_data_to()` はメッセージ長を生の `int` で送る `:503`. 送信関数は `sizeof(packet)` を使い, `mtk_tcp.h:201–248` の `double_packet`, `LONGLONG_packet`, `view_info` 等の構造体配置を通信へ露出している.
- `mtk_tcp.cpp:586,618,650,686` は `char buf` の `&buf[1]` を構造体ポインタに変換. 受信側 `:277,362,372,392` にも同様の参照. `pack_strings_data()` `:98` は `buf[3]` から呼ばれ `:751`, 任意長文字列の直後へ `int*` でアクセス. alignment 保証のない型付き参照がある.
- CS の再取得は第 3 節のとおり. スレッド・ロック API の交換でも通信の動作を壊しうる.
- 既存コードの検証不足: `:275` の 1024 byte 受信領域へ受信 `len` を検査せず渡す `:290–293`. `unpack_strings()` `:149–159` は外部指定長を 1024 byte 配列へ無制限コピー. `send_data_to()` `:503–508` は部分送信の続き処理をせず失敗扱い. いずれも macOS 固有の問題ではない.

未確認と変更候補:

- Windows と macOS のパケット配置が必ず異なるとは未確認. 現行 Windows の `sizeof` / `alignof` / `offsetof` と実パケットを比較し, 必要なら旧形式を維持する明示的 codec を設ける.
- `common/endian.h:47` に swap 関数, `:104` に `isLittleEndian()` があるが, 調査した `Mitaka/` / `common/` では定義以外の使用が見つからなかった. `common/astro/cf96.cpp:195–210,284` 等にも native byte order の数値読み込みがある. Intel / Apple Silicon Mac は little endian なので, 全データが endian 差で壊れるという結論にはならない.
- 入力長検証と部分 I/O は元から存在する課題として, プラットフォーム移植と区別して記録し, 検証を加える候補. 今回はプロトコル変更もセキュリティ修正も行っていない.

## 8. 動画・音声・AVI の範囲

### 使用される動画・音声経路

- `Mitaka/mtk_movie.cpp:40–41` は ATL と DirectShow を include.
- `mtk_movie::Open()` `:144` は `CoCreateInstance(CLSID_FilterGraph)` `:156`, `IMediaControl` `:163`, `IMediaEventEx` `:168`, `SetNotifyWindow` `:172`, `IMediaSeeking` `:177` を取得. `:185–197` は VMR7 / VMR9 / EVR を選ぶ.
- `:218` の `CA2W(fn)` は ATL のワイド文字変換であり, 明示的な UTF-8 指定ではない. `:219` の `RenderFile` がメディアを開く.
- 再生 `Play()` `:289–295`, 一時停止 `Pause()` `:304–310`, 位置取得 `GetPosition()` `:343–350`, 絶対位置設定 `SetPosition()` `:371–385` がある. `GetEvent()` `:434–439` は DirectShow イベントの取得と解放.
- `Mitaka/mtk_video.cpp:68,186,330,483` に Window mode / VMR7 / VMR9 / EVR の初期化実装.
- `main.cpp:3946` `OnMovieOpenSub()` が上記を HWND / `WM_GRAPHNOTIFY` とともに開く. `OnMovieOpen()` `:3981` と **`OnAudioOpen()` `:3988–3990` は同じ経路を使う**. 音声も独立した単純な sound API ではなく DirectShow に依存する.
- `main.cpp:4003–4005` は再生位置を `LONGLONG` で通信, `:4012–4026` は再生・一時停止と位置の同期. ネイティブ再生へ置換する場合も位置の単位・seek・イベント・同期を合わせる必要がある.
- `mtk_movie.cpp:452` `load_mif_file()` は `MEDIATYPE` として Image / PopupImage / Movie / Audio `:472–476`, `FILE_PATH` `:478` を解釈する.

未確認: 利用可能な codec は `RenderFile` と実行環境のフィルタに依存する. 本ソースだけではすべての実メディアが macOS で再生できると断定できない. サンプルメディアと同期動作は未実行.

### AVI はクラス存在と実使用を区別

- `common/graphics/avi.h:41–42` は Windows / VfW 依存.
- `common/graphics/avi.cpp:53` `AVIFile::open()` → `AVIFileOpen`; `createVIDEO()` `:64–82` → `AVIFileCreateStream`; `selectCompression()` `:90–97` → `AVISaveOptions` / `AVIMakeCompressedStream`; `setFormat()` `:104–107` → `AVIStreamSetFormat`; `writeFrame()` `:114–117` → `AVIStreamWrite`.
- `mtk_ini_file.cpp:755–766` に AVI / TARGA / PNG 系の録画設定と `movie.avi` の既定値がある. `main.cpp:102` は AVI header を include.
- **限定**: `AVIFile`, `createVIDEO`, `selectCompression`, `writeFrame` の全体検索ではクラス定義以外の実呼出が見つからなかった. メッセージループの録画関連処理にもコメントアウトがある (`mtk_window_mode.cpp:1245`, `mtk_network_mode.cpp:489`). 本版で AVI 書出しが有効な操作から到達できるとは確認していない. DirectShow 再生と同じ確度で「現役の必須機能」とは扱わない.

## 9. 次段階の検証案と調査限界

提案のみで今回未実行:

1. ターゲット間の packet `sizeof` / `alignof` / `offsetof`, `long` / `wchar_t` 等の幅を比較. [型のサイズと構文検証](VALIDATION.md)を参照.
2. 既存 `hip.dat` / `constellation_HIP.dat` の 1 レコード消費 byte 数, BMP 読書き, 3DS smooth group を fixture で比較.
3. LF / CRLF, BOM 有無, CP932 / UTF-8, 非 ASCII パス, BMP 外文字を含む文字列を分けて検証.
4. 入力軸・キー優先・ウィンドウフォーカス, 動画の再生・pause・seek・ネットワーク同期を実機比較.
5. SSE を使わない数値計算経路の結果を基準化し, ARM の最適化と並列化は後で同じ結果へ照合.

本調査はソースの構造と API の使用箇所の確認であり, 完全な移植工数見積り, 現行 macOS API の選定, 実行時 codec / データ互換性, すべての到達可能コードの証明は含まない.
