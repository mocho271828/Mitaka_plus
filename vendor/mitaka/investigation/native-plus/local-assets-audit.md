# Plus のローカル背景・星座絵・風景資産の調査

調査日: 2026-10-29。実施者: Codex。公式ソースとローカル原本を読み取り専用で調査した。以下の「確認済み」はファイル・文書・ソースを静的に確認した結果であり、旧 Plus の実行結果との一致を意味しない。調査時のネイティブ実装は `94c9af3` を基点とする作業ツリー。元の画像・スクリプト・バイナリは変更、複製、Git 登録していない。

## 参照位置

| 略記 | 絶対パス |
| --- | --- |
| `PLUS` | `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka` |
| `REGULAR` | `/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka` |
| `OFFICIAL` | `/Users/kota/mitaka/repositories/Mitaka/sources/official/mitaka_source` |

対象 Plus は Windows 1.5.4 build101013、同梱 API 文書の表示は 1.3.0、参照可能な公式ソースは Mitaka 1.3.1。これらの版は区別する。`PLUS/mitakaPlus.exe` は x86 PE で、SHA-256 は `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。

`PLUS/Readme1st_J.txt:124–154` に付属データ・文書を含む利用条件と変更に関する記述がある。公式ソースの許諾から Plus 資産の改変・再配布条件を推定しない。この記録は許諾についての判断を行わず、選択したローカル資産を参照するための形式調査に限る。

## 天の川: 4 状態と 3 枚の画像

`PLUS/doc/script_jp/milkyway.html:12–18` は `Milkyway.type` の値を `None`、`Normal`、`Bright`、`Infrared` とし、`Milkyway:toggleType()` を記載する。例には呼び出し表記の不整合があるが、`PLUS/scripts/gui_jp.lua:169–173` と `screenmenu_jp.lua:83–87` は実際に `Milkyway.type='Normal';` のように代入してメニュー状態を比較している。4 状態のうち 1 状態は非表示であり、4 枚の画像を必要とする仕様ではない。

確認したローカル画像はすべて JPEG、1024 × 512 px、アルファなし。

| 状態 | `PLUS` からの相対パス | バイト数 | SHA-256 |
| --- | --- | ---: | --- |
| Normal | `textures/milkyway.jpg` | 15,666 | `98e5a8da31288e9898b32e77e045a0fd28cfc590e5e955b689b6ac2c43cf8050` |
| Bright | `textures/milkyway2.jpg` | 26,230 | `c1e1a25df435675d3bcbc9295cae6255c5ac3a60ebc7a83cc47003a130d5a758` |
| Infrared | `textures/MilkyWay_IR.jpg` | 425,617 | `08dad5580d182ab780260b3b1c58b32b229b4a95e27190ac555d2a9128da5e7a` |

ファイル名は大文字・小文字を含めて上表のとおり。公式コードと Plus 実行ファイルの文字列は赤外線を `milkyway_IR.jpg` と記すため、大小文字を区別するファイルシステムでは明示的な対応が必要。実行ファイルから名前の存在は確認したが、その文字列の参照先や実行時の選択処理までは確認していない。

`REGULAR/textures` には同名の Normal / Bright 画像がなく、赤外線画像は存在して Plus と同じ SHA-256 だった。選択したデータの兄弟 `textures` で画像が欠ける場合、別のデータセットや別状態の画像へ暗黙に切り替えてはいけない。

`PLUS/media/MilkyWay.mvp` は 66 バイトで、`./images/MilkyWay_Mellinger.jpg` に相当する Windows 表記を 2 行保持する。これはメディア参照であり、全天背景への投影が確認できた画像ではない。

### 公式 1.3.1 の描画経路

| 根拠 | 確認できる処理 |
| --- | --- |
| `OFFICIAL/Mitaka/main.cpp:989–1007` | Visible / Visible2 / IR は順に上記 3 名をロード。公式には別途 CMB があるが、Plus の上記 4 状態には含めない。 |
| `OFFICIAL/Mitaka/main.cpp:1468–1520` | 非表示を判定し、銀河座標変換、球の拡大、Z 軸 180° 回転、天球用 sphere の順で描画。加算ブレンド `GL_SRC_ALPHA, GL_ONE` を使用する。 |
| `OFFICIAL/Mitaka/mtk_our_galaxy_rt.cpp:74–83` | `go_to_galactic_coord()` は `M_G2E` を OpenGL の列優先順で適用する。 |
| `OFFICIAL/common/astro/astrometry.h:48–54` | R は赤道、E は黄道、G は銀河の各座標系。`M_G2E` を赤道変換と誤認しない。 |
| `OFFICIAL/common/astro/astrometry.cpp:127–141` | `M_G2R` と `M_G2E = M_R2E * M_G2R` を構成する。 |
| `OFFICIAL/common/graphics/gl_common.cpp:55–116` | 天球では U を 1 から減少させ、V を北極 1 から南極 0 へ減少させる。 |
| `OFFICIAL/common/graphics/image.cpp:259–278` | JPEG の走査行を上下反転して OpenGL 用に格納する。 |
| `OFFICIAL/common/graphics/gl_texture.cpp:68–90` | 水平方向 repeat、垂直方向 clamp、線形補間と mipmap を設定する。 |

公式の 3D 表示では太陽・カメラ間の距離 2,000–3,000 に応じた減衰もあり、プラネタリウムでは半径 1 を使う。この調査ではその距離単位を確定していない。画像の位置対応と、旧 Plus の明るさ・距離減衰の再現は別問題として扱う。

### 公式コードから導ける画像座標の対応

画像の左から右への連続座標を `s ∈ [0,1]`、上から下を `t ∈ [0,1]` とする。JPEG の行反転、天球 UV、Z 軸 180° 回転を合成すると、銀河経度・緯度と方向は次式になる。

```text
l = π − 2πs  (mod 2π)
b = π/2 − πt
g = (cos(b) cos(l), cos(b) sin(l), sin(b))
赤道方向 = normalize(M_G2R * g)
黄道方向 = normalize(M_G2E * g)
```

公式の行列の列は `vGC, cross(vGN, vGC), vGN`。列として渡すことは `common/math/vector3.h:234–238` でも確認した。`astrometry.h:139–144` の基準方向は次のとおり。

- 銀河中心 `vGC`: 赤経 17h 45m 40.0383s、赤緯 −29° 00′ 28.069″。
- 銀河北極 `vGN`: 赤経 12h 51m 24s、赤緯 +27° 08′ 00″。

これらの 2 方向は厳密には直交せず、倍精度で算出した内積は約 −0.0009772823。公式の基底を現代の別の銀河変換行列へ置換したり、転置を厳密な逆行列とみなしたりすると、参照コードの方向とずれる。画面から画像を逆参照する場合は、この基底の実際の逆行列を使い、方向を正規化する必要がある。公式自身の行列は float で構成されるため、倍精度実装との差も厳密一致とは区別する。

| 画像上の位置 | 対応する方向 |
| --- | --- |
| 中央 `(0.5, 0.5)` | 銀河中心 |
| 上端 `t = 0` | 銀河北極 |
| 左 1/4 `(0.25, 0.5)` | `cross(vGN, vGC)` の正方向 |
| 右 1/4 `(0.75, 0.5)` | 同じ軸の負方向 |
| 左右端 `(0 または 1, 0.5)` | 銀河中心の反対方向 |

ネイティブ全天図は赤道座標なので `M_G2R` を使う。`M_G2E` と既存の赤道投影をそのまま接続して黄道傾斜を二重に適用しない。水平方向の継ぎ目、上下反転、経度の向き、180° 回転の重複を独立に検証する。画素中心を `(x+0.5)/W` として標本化することは新実装側の選択であり、上式が特定の整数画素の中心を指定したという意味ではない。

**未確認:** Plus 実行ファイルがこの公式描画経路と同一か、各状態の色・明るさ・加算量、Plus の全天・地平・3D 各表示での一致。公式由来の位置対応を実装することは可能だが、旧 Plus と画素単位で一致したとは報告できない。

## 星座絵: 89 組の CAB / CDF

`PLUS/ReadmeWin_J.txt:23–25` は 88 星座の絵と一部の 3D 表示を説明する。`doc/script_jp/constels.html:32–60` は `illusts`、`toggleIllusts`、略号を空白で区切る `show` / `hide` / `isVisible` を記載する。`ui/scripts/12constels.lua:1–5` には星座絵を有効にして黄道 12 星座だけ表示する例がある。これらのスクリプトは実行していない。

`PLUS/data/constellations` は 178 ファイルで、89 個の `.cab` と同名の `.cdf` がある。CDF の名前では `serh` がへび座の頭、`sert` が尾に分かれているため、88 星座と 89 ファイルを混同しない。

CDF は CP932 のテキスト。89 件すべてに Version 7.0、Locale ja_jp、Name、Categ、Pos、Sep、Lines がある。Figure は 88 件、Art は `and.cdf` の 1 件にある。`Pos` が CAB の配置中心と等しいことや、その数値の単位は、このキー名だけからは確定できない。

### CAB の物理配置で確認できたこと

Microsoft Cabinet の `MSCF` シグネチャはない。Python 標準ライブラリの `struct` を使った読み取り専用の検算では、89 件すべてが次の little-endian 配置と整合した。

| オフセット | 配置 | 意味の確定状況 |
| ---: | --- | --- |
| 0 | float32 × 5 | 未確定 |
| 20 | uint32 `N` | 後続する 2 個組の数 |
| 24 | float32 × 2 × `N` | 2 個組の数値列。投影や単位は未確定 |
| `24 + 8N` | uint32 `M` | 後続する整数の数 |
| `28 + 8N` | int32 × `M` | 値はすべて −1 または `0..N−1` |

- 全ファイルの長さが `28 + 8N + 4M` と一致し、余りがない。
- 全 float 値は有限。先頭 3 float のノルムは約 0.9999999725–1.0000000381。
- `N` は 24–2,745、`M` は 32–3,513。全ファイル合計は `N = 75,517`、`M = 92,938`。
- 各ファイルの最後の整数は −1。−1 は全体で 17,446 個。
- 78 ファイルでは全 `N` 要素への参照があり、11 ファイルには未参照の要素がある。未参照という理由で原本を削減しない。
- 先頭第 4 float は約 0.028–0.13、第 5 float は約 −324.76–643.46。範囲だけから尺度や回転角と断定しない。

例として `and.cab` は 16,552 バイト / N=1,289 / M=1,553、`ori.cab` は 27,056 / 2,078 / 2,601。`serh.cab` と `sert.cab` の先頭 5 float は同じ値だった。

この配置は「点の配列と、−1 を区切りとする参照列」という解釈を支持するが、**描画意味は未確定**。先頭 3 値の座標系、第 4・第 5 値の意味、点の投影・軸の向き・単位を推測して描画を実装しない。既存 CLI は Apple LLVM `objdump` を利用できたが、使用可能な逆コンパイル provider はなく、導入・実行時解析は行っていない。

### 公式の星座絵形式とは区別する

`OFFICIAL/Mitaka/mtk_constellation.cpp:378–440` が読むのは `cnst_illust.dat`。略号の長さ・文字列、float の尺度、float 9 個の行列、図形種別と図形データを読む。種別は 0 終了、1 線、2 spline、3 円、4 楕円で、方向変換は `normalize(M_R2E * T * normalize(x,y,scale))`。この構造は CAB と一致せず、Plus の該当ディレクトリには `cnst_illust.dat` がない。公式ローダーの流用や公式画像への置換で Plus の絵を扱えたとはしない。

## 観測地の風景画像

`PLUS/doc/script_jp/places.html:31–46` は `Places.landscape` / `toggleLandscape` と `addLandscape(targetName, name, fileName, scale, horOffset, verOffset)` を説明する。画像はアプリからの相対パスまたは絶対パス、2 の冪の寸法を持つアルファ付き PNG、scale は縦倍率、水平オフセットは度単位の回転、同名は上書きと記載する。`addPlace` の経度は東が正、緯度は北が正で、空・不正な風景名は Default を使う。

一方、`defaultplaces_jp.dat:9` の Shinjuku は `.5, .34, -150`、`:14` の Greenwich は `.25, .06, -180` で、後ろ 2 引数の順序が文書の説明と整合しない可能性がある。実装済みデータローダーは `offset_arguments[2]` として元の順序を保持し、描画上の意味を確定していない。

| ローカル定義 | 地点数 | ラベル群数 | 風景定義数 |
| --- | ---: | ---: | ---: |
| `defaultplaces.dat` | 52 | 4 | 21 |
| `defaultplaces_jp.dat` | 52 | 4 | 21 |
| `places_jp.dat` | 4 | 1 | 2 |

ユーザー側 `places_jp.dat` には、Shinjuku を `textures/shinjuku.png, .25, 0, 0` で上書きする定義と、`city2` を `textures/seki2.png, .25, 0, 0` で追加する定義がある。`city2` と既定の `City2` は別名として保持する。独自地点 Tatesho は `city2` を参照する。名称から座標を推定して修正しない。

定義が参照する 21 種の PNG はすべて存在し、PNG color type 6 の RGBA。Greenwich は 1024 × 256 px、残り 20 枚は 1024 × 128 px。

```text
textures/{alma,comet,ginowan,greenwich,jsf,jupiter,mars_opportunity,
mars_spirit,mercury,moon,neptune,northpole,pluto,saturn,seki,seki2,
shinjuku,southpole,tsukuba,uranus,venus}.png
```

`ReadmeWin_J.txt:100–104` は 360° パノラマ、GUI でのオフセット調整、他天体の風景にも言及する。公式 1.3.1 でこの Places の風景描画経路は確認できなかった。公式の地球表面詳細画像を風景パノラマと混同しない。

**実装可能な範囲:** 既存定義からローカル PNG を直接読むこと、アルファ・寸法を検証すること、元の引数を保持すること。**未確定:** 2 オフセット引数の実際の順序・単位・原点、縦倍率と天頂角の関係、水平回転の符号、他天体での基準方向。厳密な配置互換の前に解決が必要。

## 次の実装で分離して検証する項目

- 天の川は選択した `data` の兄弟 `textures` を優先し、None と 3 状態を独立に扱う。欠損・破損はその画像の警告として出し、画像再読込で古い状態を残さない。
- 公式由来の銀河中心・極・左右 1/4・継ぎ目を単体テストで固定する。画像の実際の上下、回転、全天図の赤経方向との一致を確認する。
- 旧 Plus と同一の投影・明るさであることは別の受入項目とし、未実施なら未確認と報告する。
- CAB の物理構造検算は描画意味の確定と分離する。未知値を推測で公開 API の座標や回転へ割り当てない。
- 風景は定義の保存・地点選択と、画像の地平投影を区別する。現在の地点機能が風景まで描画済みであると説明しない。

## 天の川背景の実装・検証（2026-10-29）

`3f47a39` を基点とする次の作業単位で、`native/gui/include/sky_background.hpp` / `src/sky_background.mm` を追加した。None / Normal / Bright / Infrared を独立に選択でき、ローカル `data` の兄弟 `textures` から毎回 3 画像を読み直す。赤外画像は `MilkyWay_IR.jpg` を優先し、その名前が存在しない場合だけ公式名 `milkyway_IR.jpg` を試す。存在する画像の破損、別状態の欠損を別画像の成功で隠さず、画像ごとの警告を返す。

ImageIO の読み込みは惑星画像と `local_image.hpp` / `local_image.mm` に共通化した。既存の 64MiB・64M 画素・各辺 32768px の入力上限、単一 JPEG / PNG、完全な終端、ImageIO の完全性確認、EXIF に基づく向き、最大 1024px の sRGB RGBA 変換を維持する。新しい画像ライブラリは追加していない。

上記の公式由来の銀河基底と球面 UV を、現在の全天図の赤経左向き・赤緯上向きへ投影した。水平 repeat・垂直 clamp の双線形補間を行い、描画画像の長辺を 1024px 以下に制限する。SkyView は画像・選択状態・表示範囲・表示寸法が変わると背景を再生成し、時刻だけが変わる再生では計算済み画像を使う。背景は星や星座線の前に加算合成する。

検証結果は以下のとおり。

| 検証 | 結果 |
| --- | --- |
| `test_sky_background` の人工画像・異常系 | 合格。銀河中心・両極・左右の四分点・継ぎ目・UV 往復・画像の上下・天空投影との一致を確認 |
| Plus の実画像 | 3/3 画像、警告 0。原本を読み取り専用で使用 |
| Regular の実画像 | 1/3 画像、警告 2。欠損している Normal / Bright を赤外画像で代用しない |
| `test_sky_view` の AppKit 描画 | 合格。4 状態、欠損を伴う再読込、上下、表示範囲変更、リサイズ時のキャッシュ更新を確認 |
| 共通化後の `test_planet_textures` | 人工画像・異常系および Plus の 11/11 画像が合格、警告 0 |
| ASan / UBSan | 背景・共通画像・惑星画像の実装を instrument し、人工画像・異常系・Plus 実画像で合格。リンク先の既存 core ライブラリはこの個別検査では非 instrument |
| コンパイル | C++17 / Objective-C++、`-Wall -Wextra -Wpedantic -Werror` で合格 |

この単位で背景を接続した対象は SkyView の全天図。地平図、太陽系 3D、距離に伴う減衰には接続していない。旧 Plus の画面との画素比較は実施しておらず、Plus 固有の投影・明るさまで一致したとは扱わない。CAB / CDF の星座絵と Places の風景の未確定事項は、引き続き上記のとおりである。
