# Mitaka / Mitaka Plus の macOS ネイティブ対応調査

調査日: 2026-10-29

## 結論

Wine / Wineskin を調査対象から除いても、本体に Windows API、Windows 用実行ファイル・DLL、旧 OpenGL への依存が残る。macOS ネイティブ対応には、対応する本体ソースとビルド環境の確保、OS 依存処理の置換、描画処理とデータ互換性の検証が必要になる。

両方とも、本体の C/C++ ソースとビルド定義は今回の対象ディレクトリに見つからなかった。現段階では移植の行数・工数を算定できない。Plus はさらに Qt 4、多数の外部ライブラリ、Lua のホスト API、HTML UI、既存の状態保存との互換性を扱う必要があり、依存更新の範囲が広い。

追加調査で、本家 Mitaka 1.3.1 の公式ソースを MIT ライセンスで取得できた。手元の 1.7.4a に対応するソースと Plus 独自ソースは未確認。入手先・版・条件の詳細は [ソース入手先調査](/Users/kota/mitaka/SOURCE_AVAILABILITY.md) を参照。

公式1.3.1については、ファイル・行番号ごとの変更対象と非公式macOS移植の再利用範囲を [1.3.1移植調査](/Users/kota/mitaka/MITAKA_131_PORTING_AUDIT.md) にまとめた。公式の一部計算コードは Clang 構文チェックを通り、非公式版は既存コアテストと universal build に成功した。以下のバイナリ調査とは対象版・検証範囲が異なる。

以下の対応案は調査から導いた提案であり、採用済みの実装方針ではない。

## 調査範囲と方法

対象は次の2ディレクトリに限定した。

- [Mitaka 本体](</Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka>)
- [Mitaka Plus 本体](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka>)

Wine エンジン、Wineskin ランチャー、仮想 Windows のシステムファイル・レジストリ等は対象外。本体も prefix 内に保存されているため、prefix 全体を除外する方法は採っていない。本体に同梱された Windows 用 DLL は移植対象の依存であり、Wine 由来とは分類しない。

ファイル一覧、README、設定、スクリプト、データ参照、PE ヘッダー・リソース・import table・文字列を静的に調査した。PE リソースは REA、import table はローカルの LLVM objdump で確認した。対象プログラムの起動、データ削除、ソース改変は行っていない。import はリンク依存の証拠であり、実行時に通る処理や動的ロードする依存を網羅するものではない。

## 現物の構成

| 項目 | Mitaka | Mitaka Plus 側の配布物 |
|---|---|---|
| README の版 | 1.7.4a、2023-03-24 | Plus 1.5.4 build101013 |
| 主実行ファイル | mitaka.exe: Windows PE32+ / x86-64 | mitakaPlus.exe: Windows PE32 / x86 |
| 同居する実行ファイル | 32bit 版 mitaka32_VC.exe | 旧 Mitaka と Mitaka++ の実行ファイルも同居 |
| 同居する版の資料 | — | Mitaka 1.2.1a、Mitaka++ 1.3.1 |
| 本体ソース・ビルド定義 | 未発見 | 未発見。Lua、HTML、設定等は存在 |
| ファイル数・論理サイズ | 304 個、3,447,927,807 bytes（約 3.21 GiB） | 839 個、177,524,992 bytes（約 169.3 MiB） |
| 主な資産 | 天体・地形データ、画像、モデル、独自コマンド、言語ファイル | 天体データ、画像、モデル、Lua、HTML、Qt 翻訳・スタイル、保存状態 |

版の根拠: [Mitaka README](</Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/Readme1st_J.txt:2>)、[Plus README](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/ReadmeWin_J.txt:3>)、[同居 Mitaka README](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/Readme1st_J.txt:2>)、[Mitaka++ README](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitaka_pp_readme_J.txt:2>)。

サイズは対象内の通常ファイルの論理サイズ合計で、ディスク占有量とは異なる。Plus 側には利用者が追加した可能性のある文書・画像・保存状態等もあり、配布時の構成と同一とは断定できない。Mitaka の `.obj` は3Dモデルであり、C/C++ のオブジェクトコードではない。

## 最初に解消すべき事項

### 1. 対応するソースと利用条件

- Mitaka 1.7.4a と Plus 1.5.4 に対応する本体ソース、ビルド定義、依存ライブラリの版・取得元を確保する。別バージョンのソースを入手した場合は、現物との差分と機能差を先に確認する。
- [NAOJ の現行配布ページ](https://4d2u.nao.ac.jp/mitaka/download/)の実行版は手元と同じ 1.7.4a。[公式ソース一覧](https://4d2u.nao.ac.jp/mitaka/download/download_old/#list04)の最新掲載は 1.3.1。追加調査で 1.1.0〜1.3.1 の9版を実取得し、ZIP と版を確認した。
- 1.3.1 の README とソースヘッダで MIT 許諾を確認した。ただし、1.7.4a の配布パッケージ・データや Plus 追加コード全体へ、この条件を広げて扱わない。
- [Plus 公式サイト](http://orihalcon.jp/mitakaplus/)は HTTP で確認できた。Windows 1.5.4 と旧 Mac 1.0.0 の実行版を掲載するが、独自 C/C++ ソースとその改変・再配布条件は未確認。Mitaka Plus、Mitaka++、非公式の Mac 向け部分移植を区別する。
- 同梱 Mitaka README は利用・再配布・改変について条件を設けている。一部の設定・コマンド・言語・メディア記述・保存状態ファイルには例外がある。ソース、配布バイナリ、天文データ、画像、モデル、フォント、外部ライブラリを分けて適用条件を確認する。[同梱条件](</Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/Readme1st_J.txt:128>)、[公式クレジット](https://4d2u.nao.ac.jp/mitaka/credit/index.html)
- Plus 側にも別版の [Mitaka 利用条件](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/Readme1st_J.txt:129>)が同梱されている。[Mitaka++ README の MIT 記述](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitaka_pp_readme_J.txt:119>)は、ベースの Mitaka 1.00 ソースを説明したもの。Plus 全体の許諾を示す根拠にはしない。

公式 MIT ソース以外の対象については、個別の許諾確認が残る。権利者への連絡は行っていない。詳細は [ソース入手先と利用条件](/Users/kota/mitaka/SOURCE_AVAILABILITY.md) に整理した。

### 2. 移植の到達点

実装開始時には、Apple Silicon の arm64 対応、Intel Mac の要否、最低 macOS 版、必須機能を決める。まず「ネイティブ起動、天体表示、カメラ操作、日本語表示、既存データ読込み」を小さな到達点とし、動画、特殊コントローラー、ネットワーク同期、ドーム・複数画面等を必要性に応じて追加する案が妥当。

既存の保存状態があるため、現在の利用実態と維持すべき互換性を確認する必要がある。新規プロジェクトか導入済みプロジェクトかは今回確定していない。実装時に確認し、ユーザー指定の `IMPLEMENTATION_POLICY.md` に記録してから互換性方針を決める。

## 本体に残る Windows 依存

以下は主実行ファイルの import table と同梱資料で確認したもの。

| 分野 | Mitaka | Plus | 必要な作業 |
|---|---|---|---|
| ウィンドウ・メニュー・ダイアログ | USER32、GDI32、COMDLG32、SHELL32 | QtGui4 に加えて USER32、GDI32、SHELL32 | UI、イベント、ダイアログ、クリップボード、フォント処理を macOS 対応にする |
| 描画コンテキスト | OPENGL32、GLU32、wglCreateContext / wglMakeCurrent | 同左に加えて QtOpenGL4、QGLWidget / QGLPixelBuffer、glut32 | コンテキスト生成、画面更新、オフスクリーン描画、文字描画を移植する |
| 入力 | DINPUT8、DirectInput8Create | 同左に加えて HID、SETUPAPI | マウス・キー・ジョイスティック等の入力層を置き換える |
| タイマー・スレッド | WINMM の timeGetTime 等、KERNEL32 | WINMM、KERNEL32、SDL のスレッド・同期 API | 時間基準、更新周期、並行処理を確認して置き換える |
| ネットワーク | WSOCK32 | WSOCK32、WS2_32 | ソケット・イベント処理と同期プロトコルを確認する |
| 動画・画像出力 | AVIFIL32 の AVI 作成 API。設定に EVR | AVIFIL32、MSVFW32、FFmpeg、DevIL / ILU | 再生、圧縮、出力、画像変換を機能単位で置き換える |
| 音声・その他 | ole32 等。音声メニューあり | irrKlang、SDL 音声、COM 系、Direct3DCreate9 | 必要な機能・呼出経路を特定して macOS 側に実装する |

Mitaka の主実行ファイルは12個、Plus は37個の DLL を直接 import している。DLL の数だけで工数を算定することはできない。Plus の `Direct3DCreate9` import は確認できたが、主描画での使用や用途はソース・実行経路の確認が必要。

Windows DLL を同梱し直すだけでは macOS ネイティブにはならない。必要な依存は推移的依存も含めて macOS / 対象 CPU 向けに用意し、入手できないものは置き換える。

## 描画は優先して試作すべき領域

両実行ファイルは `glBegin` / `glEnd`、行列スタック、display list 等の旧 OpenGL API を import する。Mitaka には OpenGL 3.1 以降の GPU シェーダ機能があり、バイナリ内には `#version 130` / `140` と `gl_Vertex`、`gl_ModelViewProjectionMatrix` 等の文字列がある。[導入履歴](</Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/history_J.txt:366>)、[EnableShader 設定](</Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitaka.ini:7>)

この固定機能とシェーダの組合せが対象 macOS の OpenGL コンテキストでそのまま動くとは仮定できない。Apple の Core Profile 移行資料でも、固定機能・行列スタック・旧 GLSL 組込み変数等の変更が必要とされている。[Apple の移行資料](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/UpdatinganApplicationtoSupportOpenGL3/UpdatinganApplicationtoSupportOpenGL3.html)

保守を続ける場合、OpenGL が macOS 10.14 で非推奨になっていることも判断材料になる。短期の OpenGL 移植試作と、長期の Metal 等への描画層変更を比較する必要がある。今回、描画 API の採用判断は行っていない。[Apple の OpenGL 文書](https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/opengl_intro/opengl_intro.html)

最初の試作では、恒星・惑星・軌道・日本語ラベルを表示し、カメラ移動と深度・透明度を比較する。その後、Retina、フルスクリーン、複数画面、オフスクリーン出力、ドーム・立体視のうち必要な機能を確認する。

## Plus 固有の課題

### Qt と外部ライブラリ

README は Qt 4.5.1 と記載するが、同梱 `QtCore4.dll` の VERSIONINFO は **4.6.3.0**。SDL は **1.2.13.0**、DevIL は **0.1.6.7** と確認できた。FFmpeg は `avcodec-51.dll`、`avformat-51.dll`、`avutil-49.dll` という ABI 世代まで確認でき、正確なリリース番号は未確定。[依存一覧](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/ReadmeWin_J.txt:163>)

Qt を維持して移植するなら、現在の macOS / arm64 を対象にできる版への更新と API 差分対応が必要になる。Qt 6 では QGL 系クラスが削除されているため、QGLWidget / QGLPixelBuffer の単純な再コンパイルでは済まない。QOpenGLWidget 等への移行は候補だが、独自 OpenGL 描画が自動的に Metal に変換されるわけではない。[Qt の OpenGL 変更点](https://doc.qt.io/qt-6/opengl-changes-qt6.html)、[Qt の macOS 対応](https://doc.qt.io/qt-6/macos.html)

QuesoGLC、FreeType、fontconfig、lib3ds、FFmpeg、irrKlang、cfitsio、OpenIL、libexpat、SDL、zlib 等について、実際に使う機能、対応版、arm64 ビルド可否、代替、利用条件を一覧化する。古い MSVC / Intel ランタイムへの依存も、新しいビルド環境で解消する必要がある。

### Lua・HTML・状態保存

- [起動スクリプト](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/scripts/init.lua:1>)は、言語別 GUI、メニュー、ショートカット、レイアウト、設定、初期状態を順に読み込む。Lua ファイル単体では動かず、C++ 側の `GUI`、`State`、`Camera`、`mtk` 等の API が必要になる。
- [状態保存の仕様](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/doc/script_jp/state.html:12>)は Lua スクリプトとして保存し、復元時に実行する方式。天体 ID、定数、数値精度、呼出順、無選択値等の意味を維持するか、明示的な移行処理が必要になる。
- [既存状態の例](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/state/20151008:79>)にはカメラ姿勢・対象・FOV 等がある。日本語名かつ拡張子のない保存ファイルもある。これらは再利用できる回帰確認材料であり、削除対象ではない。
- [HTML UI の仕様](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/doc/script_jp/uibrowser.html:12>)にはブラウザ表示と `mtkp://` による Lua 呼出しがあり、[実際の画面](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/ui/index.html:30>)にも使われている。ブラウザとアプリ間の接続、ローカル・オンラインコンテンツから呼べる処理の範囲を確認・設計する。現状の脆弱性を確認したものではない。
- 同文書の Flash / Internet Explorer への言及だけでは、現在使用中の機能や内部実装を断定できない。必要機能を確認して移行対象を決める。
- 文書にある `mitakaPlus.ini` は対象内に見つからなかった。実際の設定保存先は未確定。同居する `mitaka.ini` を Plus の全設定とみなさない。
- 一部のステレオ・画像出力機能は資料で Mitaka Pro 専用と明記されている。Plus の必須機能に一律には含めない。

## データと保守上の具体的な確認事項

天体カタログ、地形、画像、モデル、スクリプトは再利用候補になる。ただし、両配布物は年代・版・構成が異なるため、単純に統合せず読込み仕様と条件を確認する。

| 現物で確認した点 | 対応・確認事項 |
|---|---|
| Windows 形式の相対パスがある | `\\`、カレントディレクトリ依存、外部ファイル参照を解決する資産ローダーを確認する |
| Mitaka の M45.mif は M45.jpg を参照するが実体は m45.jpg。M13 も jpg / JPG が不一致 | 大文字小文字を区別するボリュームでの読込みを確認する。今回、実動作の失敗までは再現していない |
| UTF-8 と CP932 / Shift_JIS が混在する | ファイル単位で文字コードを扱い、日本語名・Lua・HTML・ラベルを検証する。一括変換は避ける |
| `.dat` 等はテキストとバイナリが混在する | 読込みコードで整数幅、構造体配置、バイト順、数値精度を確認する |
| Windows のフォント名を指定する | macOS のフォント選択、字幅、文字描画、代替フォントの条件を確認する |
| 設定・state・画像出力に書込みが必要 | `.app` の読取り専用資産と、利用者の設定・状態・出力先を分離する |
| Plus の `media/*.mvp` 9個は画像パスを含むテキスト | 拡張子から動画本体と分類しない。既存のメディア記述として読込みを確認する |
| Mitaka の大型データ2種が本体直下と data/ に重複する | 各組は cmp で完全一致し、重複分は計 1,049,635,545 bytes。実際の参照先を確認するまで削除しない |
| 地形データの README の指定先と現在のサブディレクトリ配置が異なる | ローダーが再帰検索するか確認する。現在未使用とは断定しない |

具体例: [画像パス](</Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/media/M45.mif:3>)、[日本語フォント](</Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/locale/Japanese.lng:5>)、[Plus の天体データ参照](</Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data/ssystem.dat:13>)。

## 作業順序と完了条件の案

| 優先度 | 作業 | 次へ進むための確認結果 |
|---|---|---|
| 最優先 | 対応ソース・依存・条件の確保、対象 Mac と必要機能の決定 | 対象版を再現できる入力一式と、移植・配布の適用条件が分かる |
| 高 | Windows 依存箇所とデータ形式をソースから一覧化 | 共通の天文計算・資産処理と、OS / 描画依存の境界が分かる |
| 高 | 小さな macOS ネイティブ描画試作 | Wine を介さず対象 CPU で起動し、天体表示・カメラ・日本語ラベルを確認できる |
| 高 | Plus の Qt・依存ライブラリ更新と Lua API 移植 | 基本画面と既存 Lua が動き、状態を保存・復元できる |
| 中 | データ・パス・文字コード・フォント・書込み先の対応 | 既存資産と日本語ファイルを読み込み、既存データを壊さず保存できる |
| 機能範囲による | 入力機器、動画・音声、ネットワーク、ドーム・複数画面 | 採用した機能の操作・出力が比較基準を満たす |
| 配布前 | 再現可能なビルド、CI、依存固定、アプリ梱包、必要な署名・公証 | 対象 Mac で依存欠落なく動作し、配布条件を満たす |

回帰確認は、Windows 版の基準結果と比較する。天体位置・時刻・座標系・日食、カメラ姿勢・FOV、色・透明度・深度、日本語、状態保存・復元、Lua と HTML からの操作を優先する。Plus の既存保存状態や日食スクリプトを利用できる。画像一致だけでなく、天文計算の数値と操作結果も確認する。

まず Mitaka の小さな描画試作で共通リスクを確認し、その結果を Plus に適用できるかソースで判断する進め方を推奨する。両者の共通化や統合は、ソースと差分を確認する前に決定しない。

## 検証範囲と未確定事項

- ファイル構成、実行形式、直接 import、PE リソース、資料・スクリプト・設定の内容を確認した。
- このバイナリ調査の対象である1.7.4a / Plus 本体の実行、ビルド、動作テスト、性能測定は未実施。対応ソース・ビルド定義がなく、静的調査が対象だったため。1.3.1と非公式移植の追加検証は上記の別報告に記録した。
- 深い逆コンパイルは未実施。利用可能な REA 環境に Ghidra / Hopper の実行構成がなかった。新たな解析ツールのインストールは行っていない。
- 関数単位の依存範囲、動的ロード、バイナリデータ形式、実使用機能、既存設定の全保存先、移植工数は未確定。
- 初回調査ではこの調査書を追加し、追加調査ではソース入手状況を更新して [ソース入手先調査](/Users/kota/mitaka/SOURCE_AVAILABILITY.md) を追加した。本体・Wine 関連ファイルの変更・削除はない。
- `/Users/kota/mitaka` は Git リポジトリではないため Git 差分・commit は対象外。`/simplifier-lai` は未実行。実装方針を決定していないため、`IMPLEMENTATION_POLICY.md` / `policy_gates/` の作成・更新は行っていない。

## バイナリの識別情報

| 対象 | SHA-256 |
|---|---|
| Mitaka 側 mitaka.exe | `18a40f74231b2e15eae5d7f8af92119279a117dfc0b11441b5a8038992935707` |
| Plus 側 mitakaPlus.exe | `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457` |
| Plus 側 QtCore4.dll | `e7b82c0083d06f3e2926e102a7601a1bf1b6b192e25cf0a6d2ba12a56eb1918e` |

REA のリソース解析 Evidence ID: Mitaka `ev_d643f61037ad896326120bc7dae7ebce7cfc622d0aa91ee0bc095b51830ac3c5`、Plus `ev_81f281db58d7275a0c4e86a53b2ee17e9a9c51963b2da5f58dd3a19bc1f0cfb0`、QtCore `ev_544c3c20c7739e0c89039291c3d1416870961a42a6d39887b64fac25aa19d1f9`。import table、文字列、ファイル内容の調査結果は別途ローカル読取りで確認したもの。
