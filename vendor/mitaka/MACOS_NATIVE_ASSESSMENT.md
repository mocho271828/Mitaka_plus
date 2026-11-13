# Mitaka / Mitaka Plus の旧 Windows 配布物

2026-10-29 に比較した Mitaka 1.7.4a と Mitaka Plus 1.5.4 の実行ファイル、同梱ライブラリ、データ形式を記録する。バイナリの識別には末尾の SHA-256 を使用した。ネイティブ版の対応機能は [機能対応表](PLUS_FEATURE_MATRIX.md)、コードの出典は [ソース入手先](SOURCE_AVAILABILITY.md) を参照。

## 調査したアプリフォルダ

| 項目 | Mitaka | Mitaka Plus 側の配布物 |
|---|---|---|
| README の版 | 1.7.4a、2023-03-24 | Plus 1.5.4 build101013 |
| 主実行ファイル | mitaka.exe: Windows PE32+ / x86-64 | mitakaPlus.exe: Windows PE32 / x86 |
| 同居する実行ファイル | 32bit 版 mitaka32_VC.exe | 旧 Mitaka と Mitaka++ の実行ファイルも同居 |
| 同居する版の資料 | — | Mitaka 1.2.1a、Mitaka++ 1.3.1 |
| 本体ソース・ビルド定義 | 未発見 | 未発見。Lua、HTML、設定等は存在 |
| ファイル数・論理サイズ | 304 個、3,447,927,807 bytes（約 3.21 GiB） | 839 個、177,524,992 bytes（約 169.3 MiB） |
| 主な資産 | 天体・地形データ、画像、モデル、独自コマンド、言語ファイル | 天体データ、画像、モデル、Lua、HTML、Qt 翻訳・スタイル、保存状態 |

版の根拠: Mitaka README（`Mitaka 1.7.4a/Readme1st_J.txt:2`）、Plus README（`Plus 1.5.4/ReadmeWin_J.txt:3`）、同居 Mitaka README（`Plus 1.5.4/Readme1st_J.txt:2`）、Mitaka++ README（`Plus 1.5.4/mitaka_pp_readme_J.txt:2`）。

サイズは対象内の通常ファイルの論理サイズ合計で、ディスク占有量とは異なる。Plus 側には利用者が追加した可能性のある文書・画像・保存状態等もあり、配布時の構成と同一とは断定できない。Mitaka の `.obj` は3Dモデルであり、C/C++ のオブジェクトコードではない。

## バイナリの依存

以下は主実行ファイルの PE import table に現れる直接の依存。Mitaka は12個、Plus は37個の DLL を参照する。Plus の `Direct3DCreate9` の実行経路は未確認である。

| 分野 | Mitaka | Plus |
|---|---|---|
| ウィンドウ・メニュー・ダイアログ | USER32、GDI32、COMDLG32、SHELL32 | QtGui4 に加えて USER32、GDI32、SHELL32 |
| 描画コンテキスト | OPENGL32、GLU32、wglCreateContext / wglMakeCurrent | 同左に加えて QtOpenGL4、QGLWidget / QGLPixelBuffer、glut32 |
| 入力 | DINPUT8、DirectInput8Create | 同左に加えて HID、SETUPAPI |
| タイマー・スレッド | WINMM の timeGetTime 等、KERNEL32 | WINMM、KERNEL32、SDL のスレッド・同期 API |
| ネットワーク | WSOCK32 | WSOCK32、WS2_32 |
| 動画・画像出力 | AVIFIL32 の AVI 作成 API。設定に EVR | AVIFIL32、MSVFW32、FFmpeg、DevIL / ILU |
| 音声・その他 | ole32 等。音声メニューあり | irrKlang、SDL 音声、COM 系、Direct3DCreate9 |

両実行ファイルは `glBegin` / `glEnd`、行列スタック、display list 等の旧 OpenGL API を import する。Mitaka には OpenGL 3.1 以降の GPU シェーダ機能があり、バイナリ内には `#version 130` / `140` と `gl_Vertex`、`gl_ModelViewProjectionMatrix` 等の文字列がある。導入履歴（`Mitaka 1.7.4a/history_J.txt:366`）、EnableShader 設定（`Mitaka 1.7.4a/mitaka.ini:7`）

README は Qt 4.5.1 と記載するが、同梱 `QtCore4.dll` の VERSIONINFO は **4.6.3.0**。SDL は **1.2.13.0**、DevIL は **0.1.6.7** と確認できた。FFmpeg は `avcodec-51.dll`、`avformat-51.dll`、`avutil-49.dll` という ABI 世代まで確認でき、正確なリリース番号は未確定。依存一覧（`Plus 1.5.4/ReadmeWin_J.txt:163`）

## 旧 Plus のスクリプトと保存状態

起動時の `scripts/init.lua` は言語別 UI、メニュー、ショートカット、初期状態を読み込む。`doc/script_jp/state.html` は保存状態を Lua として実行する仕様を記す。`doc/script_jp/uibrowser.html` と `ui/index.html` には HTML のリンクから `mtkp://` で Lua を呼ぶ例がある。ネイティブ版に実装した操作と実行条件は [Lua ガイド](native/gui/SCRIPTING.md) に記載する。

## データを照合するときの相違点

- 画像やモデルの参照には Windows 形式の区切り記号を含むパスがある。通常版の `media/M45.mif` は `M45.jpg` を参照し、実ファイルは `m45.jpg`。M13 にも拡張子の大文字・小文字の違いがある。
- 文書・設定の文字コードには UTF-8 と CP932 がある。`.dat` にはテキストとバイナリの両方がある。
- Plus の `media/*.mvp` 9 件は画像パスを含むテキスト。通常版には本体直下と `data/` にバイト一致する大型データが2組あり、その合計は 1,049,635,545 bytes だった。
- 地形データの原配布 README が示す配置と照合したフォルダの配置が異なる。ファイル名・サイズ・出典は [地形データの記録](native/core/TERRAIN_PROVENANCE.md) を参照。

## バイナリの識別情報

| 対象 | SHA-256 |
|---|---|
| Mitaka 側 mitaka.exe | `18a40f74231b2e15eae5d7f8af92119279a117dfc0b11441b5a8038992935707` |
| Plus 側 mitakaPlus.exe | `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457` |
| Plus 側 QtCore4.dll | `e7b82c0083d06f3e2926e102a7601a1bf1b6b192e25cf0a6d2ba12a56eb1918e` |
