# Plus の描画品質・立体視と未確定のローカル描画資産

調査日: 2026-10-29。調査時の HEAD は `3f47a39`。第 2 単位の統合検証と並行して、次の実装候補を読み取り専用で調べた。製品コード、原本の設定・画像・バイナリは変更していない。以下は静的な確認であり、旧 Plus の実行結果との一致や機能の実装完了を意味しない。

## 原典と対象版

| 略記 | 絶対パス |
| --- | --- |
| `PLUS` | `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka` |
| `OFFICIAL` | `/Users/kota/mitaka/repositories/Mitaka/sources/official/mitaka_source` |
| `SDK` | `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk` |

対象は Plus 1.5.4 build101013。同梱 API 文書の表示は 1.3.0、公式公開ソースは通常版 Mitaka 1.3.1 である。Plus のスクリプト契約、通常版の描画実装、macOS の移植先 API は別の証拠として記録する。行番号は原典を CP932 で読み取った位置。

関連調査は [local-assets-audit.md](local-assets-audit.md)、[local-rendering-audit.md](local-rendering-audit.md)、[local-ui-state-input-audit.md](local-ui-state-input-audit.md) を参照。

## 品質設定で確定している契約

`PLUS/doc/script_jp/renderer.html` は次の独立した bool と toggle を定義する。

| 設定 | toggle | 原典行 | 説明で確定できる範囲 |
| --- | --- | --- | --- |
| `Renderer.antialias` | `toggleAntialias()` | 12–18 | 高画質化。速度低下があり、非対応ハードウェアでは意味がない |
| `Renderer.pointSmooth` | `togglePointSmooth()` | 20–26 | 点の smoothing。速度低下があり、非対応ハードウェアでは意味がない |
| `Renderer.lineSmooth` | `toggleLineSmooth()` | 28–34 | 線の smoothing。速度低下があり、非対応ハードウェアでは意味がない |
| `Renderer.textSmooth` | `toggleTextSmooth()` | 36–42 | 文字の smoothing。速度低下がある |

4 設定の組み合わせ、既定値、サンプル数、MSAA / SSAA の別、色空間、ガンマ、点の形状、線端・接合部の扱いは記載されていない。`antialias=false` が他の 3 設定を無効にするという説明もない。

`PLUS/ReadmeWin_J.txt:48–49` は文字列の高品質描画を選択できるとし、`67–68` は品質と操作スタイルを設定・保存するオプションダイアログを説明する。この README は各設定の保存先や形式までは定義していない。

### 実スクリプトとの名前の差

`PLUS/scripts/option.lua:16–18` は次の値を保持する。

```lua
MitakaRenderer.pointSmooth=false;
MitakaRenderer.lineSmooth=true;
MitakaRenderer.textSmooth=false;
```

API 文書のオブジェクト名は `Renderer`、保存済みスクリプトの名前は `MitakaRenderer`。このファイルは既存環境の値であり、製品の初期値を証明しない。両名が同じオブジェクトの alias か、別の層かは未確認である。移植側がどちらかの名前を受け付けたことだけをもって、旧オプション保存全体の互換性を宣言しない。

別の同梱スクリプトには以下もあるが、`renderer.html` には契約がない。

- `scripts/init.lua:11` と `quadraopt.lua:4`: `Renderer.editOnCapturedBG = false`。
- `scripts/tutorial.lua:16–17`: `Renderer.style=Renderer.STYLE_LOOKAROUND` と `Renderer:resetView()`。

これらを品質設定の alias や既存カメラ操作へ推測で対応付けない。

## 再描画の契約と品質設定を分離する

同じ `renderer.html` の `44–56` と `67–68` には次の契約がある。

- `interactive=false` では `render()` まで自動再描画を行わない。
- `frame` は「次回描画」の整数番号で、描画ごとに 1 増える。
- `resetFrame()` は 0 に設定し、`render()` は現在の設定で描画して番号を 1 増やす。

文書 `50` の呼び出し例は `tiggleInteractive` と綴られているが、見出し `48` は `toggleInteractive`。誤記を独立 API として追加しない。GUI の露出・ウィンドウ移動・投影画面の複数描画と frame 増加の対応、描画完了時点の同期性は未確認。

`renderToFile()` と `captureToFile()` は `70–75` で **Pro only**。品質設定の実装に含めて通常 Plus の必須機能と扱わない。現在のネイティブ静止画保存が、これらの printf 形式ファイル名・frame 契約まで満たすとは説明しない。

## 立体視で確定している契約

`PLUS/doc/script_jp/renderer.html:77–79` の `Renderer.stereoType` は文字列で、値は `None`、`Anaglyph`、`ColorAnaglyph`。

`PLUS/ReadmeWin_J.txt:138–141` は、既存のアナグリフとカラーアナグリフに加え、水平分割、垂直分割、時分割 QuadBuffer を **Mitaka Pro** に追加したと説明する。通常 Plus の必須範囲と Pro の方式を分ける。

以下は Plus 原典では確定できていない。

- 左右の眼と赤・青緑チャンネルの対応、白黒化の係数。
- 眼間距離の単位・初期値・変更方法と、距離や表示倍率に応じた視差の決定。
- 平行移動、off-axis、toe-in の別、収束面、背景や名称の視差。
- 全天・地平・宇宙空間・投影画面での有効範囲、片眼基準の選択操作。
- 画像・動画・タイトル等の重畳と、出力画像の立体視合成範囲。

### 同居する INI は Plus の読み込みを証明しない

`PLUS/mitaka.ini:15–25` には ScreenZ / ScreenW / NearZ / MidZ / FarZ / ObjZ / EyeOffset / EyeCLR / StereoEyeDist があり、`StereoEyeDist=6.4`。`47` は `StereoMode=None`。

このディレクトリには通常版を含む複数の実行ファイルが同居する。ファイルの存在だけでは `mitakaPlus.exe` が各値を読むことや、数値の単位を証明できない。6.4 を AU や現在の画面座標へそのまま渡してはいけない。

### 通常版 1.3.1 で確認できる別の実装

`OFFICIAL/Mitaka/mtk_stereo.cpp` は公開された通常版の実装で、Plus 同一性の根拠にはしない。

| 位置 | 通常版で確認した処理 |
| --- | --- |
| 63–77 | `eye_dist` の getter / setter。ファイル内の初期値は 5.0 |
| 86–92、99–146 | 白黒アナグリフは整数係数 `(299 R + 587 G + 114 B) / 1000`。左画像を R、右画像を G/B に格納 |
| 154–185 | `±0.5 * eye_dist * (1,0,0)` を `calc_draw_struct` に渡し、各眼でシーンを描く |
| 191–228 | カラー版は左眼を R、右眼を G/B の OpenGL color mask で描く |
| 238 以降 | 水平分割の別経路。通常版に存在することと、通常 Plus の対応範囲は別 |

この合成式を独立した純粋関数として移植することは可能だが、それだけでは立体視にならない。左右画像を作る幾何、単位、投影と選択の基準が必要。1 枚の画像を画面上で左右にずらすだけの処理を原版互換の立体視として扱わない。

## 移植先 CoreGraphics の確認と品質機能の候補

調査時のネイティブ描画は CoreGraphics / AppKit と CPU 画像生成を併用する。品質設定を全体に導入する場合は、それぞれに効く範囲を明記する必要がある。

`SDK/System/Library/Frameworks/CoreGraphics.framework/Headers/CGContext.h:920–955` で確認した事項:

| API | 保存・復元との関係 |
| --- | --- |
| `CGContextSetShouldAntialias` | graphics state の一部 |
| `CGContextSetAllowsAntialiasing` | graphics state の外。Should と Allows の両方が true のとき有効 |
| `CGContextSetShouldSmoothFonts` | graphics state の一部。ただし出力 context によって smoothing が保証されない |
| `CGContextSetAllowsFontSmoothing` | graphics state の外。文字の antialias と Should / Allows が条件 |

`CGContextSaveGState` / restore だけで Allows 側まで復元されると仮定しない。共有 context の Allows 設定を一時的な線描画で変更すると、後続の名称や別レイヤーまで影響する。既存の画像 ray tracer に CoreGraphics の bool を渡すだけで、画像内部の輪郭や標本化まで変更されたと説明しない。

次の候補は設計案であり、実装済み API ではない。

1. 点、線、文字を区別した品質設定の値オブジェクトを作り、全ビュー・保存・Lua 接点へ同じ値を渡す。全体 antialias と個別 bool の合成規則は、旧文書にない新実装の決定として記録する。
2. CoreGraphics の各描画群を局所的な graphics state で囲み、品質指定が隣の描画群に漏れないことを検証する。
3. CPU 画像の標本化や画像補間の品質は独立して説明する。旧ハードウェア smoothing との画素一致は未検証とする。
4. stereo は左右カメラと単位の根拠が揃ってから独立単位にする。確定した enum のみ受け付けて未描画の成功を返す実装はしない。

## 星座絵の追加確認と残る境界

`PLUS/data/constellations` の全 CDF を読み取り、`Art` / `Figure` 参照を再確認した。89 件すべてが同じディレクトリの実在する CAB を、**大文字・小文字まで一致する名前**で参照している。`and.cdf:7` のみ `Art: and.cab`、他の 88 件は `Figure`。例は `ori.cdf:7` の `Figure: ori.cab`。

89 件すべてに Version 7.0 / Locale ja_jp / Name / Categ / Pos / Sep / Lines がある。全件をひとつの固定長レコードへ縮約したり、Art を欠落として除外したりしない。星座の頭・尾に分かれる `serh` / `sert` も保持する。

[local-assets-audit.md](local-assets-audit.md) で CAB の little-endian 配列配置は確認済みだが、先頭 5 float、2 要素組の座標・単位、−1 区切りの描画上の意味は未確定。CDF の `Pos` と CAB の中心の対応、座標元期、回転順、3D 絵の対象範囲も確定していない。通常版の別形式 `cnst_illust.dat` の意味を CAB に適用しない。

現段階で安全に分離できる単位は、原本を保持する CDF/CAB 構造の読み取り、参照の診断、メタデータの表示である。位置が未確定のまま星空へ絵を描くことは、読み取り成功とは別の未完了項目とする。

## 景観の引数順は未解決

`PLUS/doc/script_jp/places.html:42` の引数順は `(targetName, name, fileName, scale, horOffset, verOffset)`。`43` は scale を垂直倍率、vertOffset を垂直位置、horOffset を水平回転角の度として説明する。`verOffset` / `vertOffset` の綴りも一致していない。

実データは `data/defaultplaces_jp.dat:9` で Shinjuku が `(0.5, 0.34, -150.0)`、`14` で Greenwich が `(0.25, 0.06, -180.0)`。値の見た目は「垂直 offset、水平角」の順を示唆するが、値域だけから文書の順序を反転してはいけない。垂直位置の単位、パノラマ投影、北の方向、正回転、地平線との位置関係も未確認。

既存独自設定は `data/places_jp.dat:3` の Shinjuku 上書きと `4` の小文字 `city2`、`6` の Tatesho からの参照を含む。`city2` を大文字 `City2` と統合したり、元の `seki2.png` を別画像へ置き換えたりしない。

地平図への景観描画を進めるには、引数の意味を示す Plus の実装または旧版の比較観測が必要。見た目で調整した新しい値は、原本パラメータの自動変換とは分けて扱う。ユーザーの旧設定を修正して整合させる方針は採らない。

## 検証条件と未実施項目

- 品質は点・線・文字を別々に切り替え、他の描画群への設定漏れ、全ビュー、投影・静止画保存、再読込・状態復元を確認する。出力 context が smoothing を保証しない場合を実装成功の見せかけで隠さない。
- stereo の合成関数は左右の単色・異なるパターン、白黒係数、寸法不一致を確認する。幾何は視差ゼロの距離、前後関係、左右交換、画面端、選択・投影の基準を別に検証する。
- CAB は全 89 ファイル、空・切断・巨大件数・非有限値・範囲外添字を検証し、未参照の点を捨てない。構造検証と星空上の位置検証を別の結果にする。
- 景観は既存独自追加を残したまま、経度の継ぎ目、透明度、地平線、極方向、画像欠損を検証する。offset の意味が未確定の段階では視野合成の完了を宣言しない。
- この調査では旧 Windows アプリの起動、Plus バイナリの逆アセンブル、ネットワーク取得、画像の再保存、新しい GUI 試験を実施していない。第 2 単位の controller / sanitizer / CUA 結果は親担当の統合記録を参照する。

品質設定の限定実装は上記の差を記録したうえで開始できる。厳密な Plus stereo / CAB / 景観の再現に進む場合は、追加の静的実装根拠を優先する。旧版の実行比較が必要になった場合は、既存環境を変えずにどう観測するかを別途決める。未確定の値を埋めるために公開データや別製品の仕様で置換しない。

## 調査後の限定実装（品質 helper のみ）

`native/gui/include/renderer_options.hpp` と `RendererQuality.h`、`src/RendererQuality.mm` に、4 個の bool と描画群ごとの保存・復元を追加した。これはネイティブ描画用の契約であり、原版の画素出力、既定値、全体 AA と個別設定の優先順位を復元したという主張ではない。ネイティブの既定値はすべて true、実効値は全体 AA と個別設定の AND とする。文字は AA と `ShouldSmoothFonts` を併せて切り替えるが、出力 context の font smoothing 対応は保証しない。

`tests/test_renderer_quality.mm` は点・線・文字の画素差、設定の入れ子・例外時の復元、`Allows*` の維持、無効な入力の拒否を検証する。専用 `build-unit4-quality` で macOS 13 を下限とする厳格警告ビルド、ASan + UBSan、x86_64（Rosetta）の各実行が 49 checks を通過した。テストの文字描画にはシステムの CoreText を使い、製品 helper は CoreGraphics のみを使う。

この時点ではビュー、メニュー、Lua、保存状態への接続とその統合検証は未実施。stereo、CAB の座標解釈、景観の offset 解釈も未実装のままである。
