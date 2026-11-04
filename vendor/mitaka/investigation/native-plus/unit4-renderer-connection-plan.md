# UNIT4 描画品質の接続計画

作成・更新日: 2026-10-29。UNIT3 のソース凍結中に作成し、`cf4fcbf` commit 後に描画接続を実装した。**描画 helper・各 renderer・3 view の値保持と呼出しは実装済み。下記の専用回帰試験が成功した。** AppController、メニュー、Lua、保存状態、キャプチャ・投影の統合判定は別担当の最終結果を必要とする。この単位だけで Plus 全機能の対応完了とはしない。

原典の版・読取位置は [local-renderer-stereo-audit.md](local-renderer-stereo-audit.md) を参照。対象は Plus 1.5.4 build101013、同梱 API 文書は 1.3.0 表示。以下の描画群分類、既定値、全体 AA と個別 bool の合成はネイティブ版の契約であり、旧 Plus の画素・ハードウェア設定の再現を保証しない。

## 実装済みの独立部分

| ファイル（`native/gui/` からの相対位置） | 現在の内容 |
| --- | --- |
| `include/renderer_options.hpp` | `RendererDisplayOptions` の bool 4 個と `RendererPrimitive`。既定値はすべて true。実効値は全体 `antialias` と該当する個別 bool の AND |
| `include/RendererQuality.h`、`src/RendererQuality.mm` | context を retain して graphics state を保存し、描画群の `ShouldAntialias` と文字の `ShouldSmoothFonts` を変更、終了時に復元する RAII。graphics state 外の `Allows*` は変更しない |
| `tests/test_renderer_quality.mm` | 点・線・CoreText と AppKit の NSString / NSBezierPath の実画素差、設定の入れ子・例外時復元、`Allows*` 維持、無効入力を検証する 64 checks |

独立 helper 段階の `build-unit4-quality` の 49 checks に加え、接続後の専用 `build-unit4-renderer` / `build-unit4-renderer-san` / `build-unit4-renderer-x86` で各 64 checks が成功した。追加依存はなく、製品 helper は CoreGraphics、テストは既存の AppKit / CoreText を使う。

## 接点と所有範囲

ビューは設定を値として保持し、そのフレームに使う renderer へ明示的に渡す。renderer 側に別の可変設定を保持させない。

| 接点 | 追加する契約 | 担当 |
| --- | --- | --- |
| `SkyView.h`、`HorizonView.h`、`SolarSystemView.h` | `@property(nonatomic) mitaka::gui::RendererDisplayOptions rendererDisplayOptions;` | 描画担当 |
| 3 view の実装、`SolarSystemViewInternal.h` | `_rendererDisplayOptions` と getter / setter。setter は代入して `needsDisplay = YES`。モデル、カタログ、選択、視点、JD、観測地を変更しない | 描画担当 |
| `StarRenderer.h/.mm` | `drawInRect:magnitudeLimit:options:quality:projector:`。quality は `RendererDisplayOptions` の値 | 描画担当 |
| `SkyCatalogRenderer.h/.mm` | `drawInRect:viewport:magnitudeLimit:options:quality:` | 描画担当 |
| `GridRenderer.h/.mm` | `draw_sky_grids` の最後に `const RendererDisplayOptions& quality` を追加 | 描画担当 |
| `SmallBodyRenderer.h/.mm` | `draw_small_bodies` の最後に `const RendererDisplayOptions& quality` を追加 | 描画担当 |
| `SolarSceneRenderer.h/.mm` | `SolarScene` の末尾に `RendererDisplayOptions renderer_display{}`。既存の集約初期化項目を並べ替えない | 描画担当 |
| `SolarSystemView` の `scene` | 保持値を `SolarScene.renderer_display` へ渡す | 描画担当 |
| AppController、メニュー、状態の読み書き | 共通の getter / setter で 3 view を同期。保存値の型検証と拒否時の現状維持は既存の状態境界に従う | root |
| Lua の 4 bool と toggle | ホストの現在値を読み、共通 setter に渡す。未対応 stereo 等を成功扱いしない | Lua 担当、root |
| Makefile、対応表、README、policy gate、全体検証 | 接続後の実装範囲と実測結果を反映 | root |

内部描画関数の品質引数に既定引数は設けず、全呼出箇所を compiler で確認する。bool の値オブジェクトに独自の JSON 解析や Lua 依存は追加しない。呼出しは既存の AppKit メインスレッドの UI 更新経路に揃える。

描画担当が変更する既存ソースは上表の view / renderer ファイルと関連描画テストに限定する。`App*`、session、Makefile、Media、DisplayOutputController は root または各担当が接続する。

## 4 設定を適用する描画群

| 設定 | ネイティブ版での実効範囲 | 対象外・差分 |
| --- | --- | --- |
| `antialias` | 各 canvas の全体 scope。点・線・文字の個別指定を許可する master | 原版で master と同じ意味だったことは未確認 |
| `point_smoothing` | 恒星、全天・地平の惑星記号、小天体記号、太陽系のテクスチャ欠損時の模式円盤の輪郭 | CPU が生成するテクスチャ球画像の内部画素は変更しない |
| `line_smoothing` | 座標格子、距離目盛、星座線・境界、軌道、自転軸、恒星マーク、天体・小天体の選択リング、星雲輪郭、名称への引出線 | 光学的な線幅や投影座標を変更しない |
| `text_smoothing` | 星・天体・小天体・星座・格子・カタログの名称、canvas 内のタイトル・操作案内・診断文字 | native menu、ボタン、table、別ウィンドウの UI 文字には適用しない |

全景の背景画像、天の川、銀河・クエーサー密度画像、惑星表面の CPU ray tracing は既存の解像度・画像補間を保つ。これらの画像内部まで品質が変わったとは説明しない。キャプチャと投影画面は描画済み canvas の画像を受け取るため、元 canvas の設定が反映されることを統合検証する。投影側の独立した pointer、状態文字とメディアプレビューはこの単位の適用範囲外。

## 現在の描画箇所と接続順

行番号は UNIT3 凍結中の作成時点。実装再開時には最新ソースのシンボルを確認する。

| 現在の箇所 | 接続する scope |
| --- | --- |
| `StarRenderer.mm:33` の `drawInRect`、点 `47`、マーク `52`、文字 `60` | 恒星ループ全体に point。マークの実描画だけ line、文字の実描画だけ text を入れ子にする |
| `SkyCatalogRenderer.mm:91` の `drawInRect`、密度凡例 `96`、星雲輪郭 `108` | 凡例・名称は text、輪郭は line。密度画像の生成・cache の条件は不変 |
| `GridRenderer.mm:44` の文字 helper、`135` の `draw_sky_grids`、`188` の `draw_solar_grid` | 格子全体は line、目盛文字 helper は text。既存の map clipping を維持 |
| `SmallBodyRenderer.mm:33` の `draw_small_bodies`、点 `42`、ring `46`、文字 `49` | ループ全体は point。選択 ring と名称だけ line / text |
| `SolarSceneRenderer.mm:81` の `drawOrbits` | line |
| 同 `143` の `drawBody`、fallback `162`、ring `169` | fallback の模式円盤は point、ring は line。画像生成の sampling は不変 |
| 同 `172` の `drawLabels`、leader `204`、名称 `205` | leader は line、名称は text。配置計算・優先順は不変 |
| 同 `290` の `draw_solar_scene`、axes `299` | scene 全体は general。軸は line。格子と小天体へ値を渡す |
| `SkyView.mm:47` の文字 helper、`362` の星座描画、`428` の `drawRect` | view 全体は general。星座線・境界・引出線・ring は line、天体記号は point、名称・案内は text |
| `HorizonView.mm:27` の文字 helper、`273` の `drawGrid`、`281` の `drawRect` | general と分類別 scope。地平格子は quality 引数経由。地面と地平線の既存 clipping を維持 |
| `SolarSystemView.mm:304` の `drawRect`、タイトル `315`、診断 `323`、案内 `331`、状態 `336` | view 全体は general。全 canvas 内文字に text。シーンへ保持値を渡す |

同じ画素の重なり順を維持するため、品質別に全点・全線・全文字を別 pass へまとめ直さない。通常の恒星 1 件ごとに不要な save / restore を追加せず、既存ループ外の point scope と、実際に必要なマーク・文字の局所 scope を使う。

既存 `CGContextSaveGState` / restore、`NSGraphicsContext` の保存、clip と RAII の寿命を交差させない。すべて正しく入れ子にし、途中 return と例外でも元の設定を復元する。`AllowsAntialiasing` / `AllowsFontSmoothing` は変更しない。AppKit が描画時に context 設定を上書きする可能性は、既存 helper の CoreText 試験だけでは否定できないため、実際の NSString / NSBezierPath 描画を別に検証する。

## 接続後の検証結果と残る統合確認

専用試験は通常の厳格警告（`-Wall -Wextra -Wpedantic -Werror`）、ASan + UBSan、x86_64（Rosetta）で同じ 3 バイナリを実行し、すべて成功した。GUI ウィンドウは作らず、AppKit の bitmap context を使用した。元のローカル星表は読み取りのみ。

| 試験 | 各構成の結果 | 確認内容 |
| --- | --- | --- |
| `test_renderer_quality` | 64 checks PASS | CoreGraphics・CoreText・NSString・NSBezierPath の各品質、master と個別値の合成、通常・例外経路の状態復元 |
| `test_display_rendering`（Plus のローカル data 指定） | 127 checks PASS | 恒星の点・マーク・文字、星雲輪郭、小天体の点・ring・文字、太陽系の模式円盤・軌道・名称の実画素差。非対象 flag の不変。非表示 Sky/Horizon の値保持・選択維持。既存の表示・ピック・軸回帰 |
| `test_grid_renderer` | 101 checks PASS | 全天・太陽系格子の線・文字 flag の実画素差、点 flag 不変、既存の clip・観測地・極と継ぎ目の回帰 |

通常ログ: `/tmp/mitaka-unit4-quality-test.log`、`/tmp/mitaka-unit4-renderer-local.log`、`/tmp/mitaka-unit4-renderer-grid.log`。SAN ログ: `/tmp/mitaka-unit4-renderer-san-{quality,local,grid}.log`。x86_64 ログ: `/tmp/mitaka-unit4-renderer-x86-{quality,local,grid}.log`。各構成の build ログは `/tmp/mitaka-unit4-renderer-{build,san-build,x86-build}.log`。後続の同日変更をこの結果へ遡って含めない。

`SkyView.mm` は 505 行となるため責務をレビューした。今回の追加は既存の描画フローに品質値を渡すものに限り、個別処理の抽出先は Star / Grid / SkyCatalog renderer が既にある。5 行だけを別 category へ分けても責務は改善しないため、現時点では凝集した view を維持する。bitmap 描画試験は helper の実装をなぞらず、製品 renderer の出力と設定間の独立性を検証している。

独立レビュー（`time_features`、同日）では、general → point → line → text の実効 AND、早期 return・C++ 例外を含む LIFO、Sky/Horizon の clip、SolarScene の旧 try/restore 置換、画像補間と描画順の維持を確認し、修正必須の指摘はなかった。これは描画担当範囲の読取レビューであり、App 側の統合合格を代替しない。

以下のうち App / Lua / session / capture / projection と実ウィンドウ操作は統合担当の最終確認へ残す。

- 3 view の setter / getter が 4 bool を保持し、カタログ再読込、選択、JD、観測地、viewport、camera を変えないことを確認する。非表示ビューにも設定を渡し、表示復帰後の初回描画へ反映する。
- 実 renderer の点・線・文字を分離した bitmap 領域で比較する。タイトルの画素差だけで星の設定まで適用されたと判断しない。恒星マーク、格子目盛文字、太陽系の名称と選択 ring、小天体の選択表示を含める。
- 個別 bool の変更が対象の描画群へ作用し、他の群へ漏れないことを検証する。master off と該当個別 off の実効状態を同じ context で比較する。アンチエイリアス有無が見える非整数の中心・斜線を使い、OS 固有のフォント画像全体を固定 fixture にしない。
- AppKit の実際の NSString 描画でも text 設定を確認する。font smoothing は出力 context 次第であり、subpixel smoothing の存在を前提条件にしない。作用しない経路は検出して未対応を明記する。
- 既存の描画順・clip 外の不変・点選択・非表示の判定・極と座標の継ぎ目・格子観測地更新の回帰を通す。
- AppController の共通適用経路、メニュー表示、Lua getter / toggle、検証済み JSON の保存・復元は担当側の統合試験で確認する。不正型の拒否時に一部の view だけ更新しない。
- 実 canvas のキャプチャと投影で設定を切り替え、変化を確認する。CUA と controller 試験は root の直列実行に合わせる。
- 通常・ASan + UBSan・x86_64（Rosetta）の必要試験を接続後に実行する。UNIT3 の合格記録を UNIT4 の検証結果へ流用しない。

## Stereo の追加読取結果

ローカル文書・scripts・INI・locale を追加検索したが、Plus の眼間距離の単位、左右眼と色の対応、収束面、全天・地平・宇宙空間での有効範囲を確定する根拠は増えていない。

- `PLUS/locale/strings_Japanese.dat:994` の `MENU_CHK_SINGLE_EYE: 右目用映像のみ` と英語版の同じ行に対応する表示文字列がある。対象製品や実装、合成方式を証明するスクリプト契約は確認できない。
- `PLUS/doc/script_jp/aboutdistance.html:12` のパーセク指定は `Camera.zoom` の契約であり、`StereoEyeDist` へ転用しない。
- `PLUS/history_J.txt:109` の視差変更の記述は通常版の履歴。`Readme1st_J.txt:2` は通常版 1.2.1a、`mitaka_pp_readme_J.txt:2` は Mitaka++ 1.3.1。同居ファイルを Plus の証拠へ混同しない。

`PLUS` の絶対位置は上記 renderer audit に記載。この追加調査では旧アプリの実行、バイナリ解析、ネットワーク取得、原本編集を行っていない。stereo は今回の接続対象に含めず、enum 受理だけの成功 API や 1 枚の画像を左右にずらす代替実装を追加しない。
