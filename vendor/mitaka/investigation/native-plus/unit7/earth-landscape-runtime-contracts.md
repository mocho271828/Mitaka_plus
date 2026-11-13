# 地球上の観測地点とパノラマの投影

[風景定義の局所座標](places-display-contracts.md)・[旧版の地上ラベル](label-runtime-audit.md)・[旧版の読取手順](probes/extract-landscape.sh)

## 選択順と失敗時

風景描画本体は `0x5336a0`、唯一確認した direct caller は `0x544892`。地球への適用は以下に限定した。

| 原版の分岐 | native の契約 |
|---|---|
| `0x534648` 以降: 選択地点の完全 ID を照合し、地点の風景名を取得。`0x534805` 以降: 天体種別、天体 ID、風景名を比較 | 選択した Earth 地点の `Planet.Earth.<landscape>` を exact lookup |
| `0x533702–0x533825`: 現在天体の `Default` | `Planet.Earth.Default` |
| `0x533825`: 天体種別 2 は `0x53425c`、その他は `Satellite.Default`。文字列は `0xc31f30` / `0xc31f40` | 地球では `Planet.Default` |
| `0x5338f6–0x533927`: null、画像名 length=0、または Places+0x4c の bool が false | 下半球を黒く描く。上半球は透明 |
| `0x533f8b` 以降: loader の失敗を texture ID -1 として保持し、画像分岐で bind へ進む | 失敗した定義を別の画像へ置き換えず、警告付きの黒い地面とする |

最後の行は不正な GL texture の振る舞いを再現せず、欠損を追跡できる状態にする差分である。選択元に `Default` がなくても、別ファイルの同名定義を取り込まない。ローカル Plus の実際の選択元 `places_jp.dat` には風景が 2 定義だけあり、他ファイルにある組込風景を補わず、その 2 定義を読み込む。

同梱 `doc/script_jp/places.html:31–38` の原名は boolean property `Places.landscape` と method `Places:toggleLandscape()`。描画側は `0x533915` の `Places+0x4c` に対して `0x533918→0x753310` で bool を読む。native の `showsLandscapeImage` がこの有効/無効を担う。原版 bool wrapper の連続 fade 値まで同一にはしていない。

## 地上の基準軸、方位、上下

caller は `0x5447ec` で天体種別を分け、惑星は `0x544935→0x5491f0`、衛星は `0x544814→0x5492b0` の pose を適用する。その後 `0x54481c–0x544867` で観測地経度の Z 回転、`90°−緯度` の Y 回転を適用してから風景を描く。従ってこの mesh は天球の赤道座標でなく、観測地に固定した地上の座標である。

方位文字列テーブル `0xd71a88` は `S, SE, E, NE, N, NW, W, SW`。風景本体の方位表示分岐は index ごとに `45°i−90°` の Z 回転、−3° の X 回転、`(0,1,0)` の平行移動を使う。これから局所 +X=南、+Y=東、+Z=上が定まる。native の East/North/Up は `(Y,−X,Z)` になる。

原 mesh / UV は既存資料の式を維持する。画像の upload 経路は `0x51df30→0x43e6f0→0x44e480→0x43d800`。PNG は `0x44d86a–0x44d968` の row pointer が `base+(height−1−i)*stride`、JPEG は `0x44e6bc–0x44e6da` が `base+(height−scanline−1)*stride` で、元画像の上端を最後のメモリ行へ置く。upload ではさらに反転しない。`0xa9d9ee` / `0xa9d9f4` は import 上の `gluScaleImage` / `gluBuild2DMipmaps` に至る。

native ImageIO 境界は左上原点の RGBA なので、画像用 UV は原 GL の V を反転した次の式になる。

```text
u = wrap360(azimuth + 180 + horizontalOffsetDegrees) / 360
v = 0.5 - altitude / 180 / verticalScale + verticalOffset
```

offset=0、scale=1 では北 u=.5、東 .75、南 0/1、西 .25、天頂 v=0、天底 v=1。S/T の `GL_CLAMP_TO_EDGE` (`0x533be1–0x533c02`) に対応して画像端を clamp する。原引数の第5項は垂直 UV offset、第6項は水平回転であり、同梱旧文書の引数名から読み替えない。

HorizonView は現在の地平投影に従う画素中心の方位・高度をこの UV へ変換し、bilinear filtering する。原版の coarse quad 内補間、mipmap、色管理、全 camera 行列の完全再現ではない。純関数の UV と原 mesh 頂点の整合、および現在の `project_sky` と画面座標の整合を別々に検証した。

## ローカル画像境界

`EarthLandscapes` は immutable な `PlaceDisplayModel`、decoded images、warnings を所有する。選択元の全 bytes / 行 / provenance を保持し、実効値と別にする。画像は背景 thread で読み込み、main thread には immutable shared pointer を渡す。`HorizonLandscapeRenderer` は地点、表示有無、viewport、出力寸法の変化時だけ投影を作り直す。

パスは UTF-8、次いで CP932 として文字列へ変換してから Windows の区切りを置換する。CP932 の「ソ」の末尾 0x5c を区切りと誤認しない。参照元は選択 data ディレクトリの親で、canonical path がその内側にある通常ファイルだけを受け付ける。絶対パス、URL、NUL、外向き symlink は警告になる。既存 `load_local_image` を使い、1 ファイル 64MiB、元画像 64M 画素・各辺 32768px、decoded 各辺 1024px、全風景 cache 128MiB を上限とする。同一 canonical path は共有する。読み取り以外の操作は行わない。

原 loader `0x44e480` は `.bmp/.jpg/.png/.tga` を大小文字非依存で選択する。native は拡張子でなく ImageIO の内容 UTI `public.jpeg/public.png/com.microsoft.bmp/com.truevision.tga-image` で認定する。ローカル SDK `UniformTypeIdentifiers.framework/Headers/UTCoreTypes.h:613–620` は BMP の UTI を宣言する。調査環境では ImageIO reader と writer が 4 形式を提供することを確認した。

JPEG EOI / PNG IEND と既存の容量・寸法・single-image 検証は維持した。ImageIO は切断 BMP/TGA を補完する場合があるため、追加した軽量検証は画像を再デコードせず、BMP の行領域、TGA の raw/RLE packet が全画素を満たすかだけを調べる。BMP は非圧縮 24/32-bit（BI_RGB、BI_BITFIELDS）、TGA は 16/24/32-bit true-color（type 2/10）。BMP の原版対応は BI_RGB 24/32-bit、TGA は原版の `common/graphics/image.cpp:439–548` にも raw/RLE の読み切りがある。BI_BITFIELDS は ImageIO の標準 writer が生成する形式も扱う native 側の拡張である。原版 BMP writer の `bfSize` には付加 2 bytes の計算があるため、その値だけを完全性判定に使わず、実際の行領域を確認する。

TGA の image descriptor と alpha、EXIF、色管理は ImageIO に従う。原 TGA reader が descriptor / alpha を捨てる動作は再現しない。TGA 1.0 は footer を必須とせず、圧縮 packet の画素数超過は拒否する。これらは機能の対応範囲を明示するもので、任意の旧 decoder の不正入力まで同じ結果にする契約ではない。
