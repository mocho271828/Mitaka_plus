# 旧Plusの地上ラベルの描画式

Windows 版 Mitaka Plus 1.5.4 の対象選択・座標・距離フェード・文字倍率を示す。ネイティブ版の地名ラベル表示は未対応。[地点仕様](../unit6/places-binary-contracts.md)・[ラベルの読取手順](probes/extract-labels.sh)

| 命令範囲・確認対象 |
| --- |
| `0x54a000–0x54e180`、直接 caller と planet / Earth / Mars 分岐 |
| `0x5279c0–0x528210`、ラベル用行列 |
| `0x457f40–0x458230`、地形位置 helper 全体と次関数先頭 |
| `0x49a740` / `0x49a770` の実体 |
| `0x53ac70` の行列コピー |
| `0x5ac110–0x5ac166` の画面倍率値 setter / getter |
| 上記 setter / getter を呼ぶ wrapper。登録名は未確定 |
| 三角関数 IAT への thunk |
| 原本 hash、PE section mapping、浮動小数点定数の原 bytes |

指定範囲は対象関数の前後を含む。一部の range の先頭は前関数の途中なので、先頭数命令の表示を関数境界の証拠には使っていない。主要 renderer の命令列は `0x532470–0x533390` を参照する。

## renderer の引数と対象判定

`0x532470` は `this = Places` と 9 個の stack 引数を受ける。prologue 後の `ebx` 基準で次の対応になる。

| offset | 意味・確認範囲 |
| --- | --- |
| `+0x08` / `+0x0c` | 天体 kind / ID。各地点 record と一致するものだけを処理 |
| `+0x10` | surface object または null |
| `+0x14` / `+0x18` | 以下の倍率式の A / B |
| `+0x1c` | caller が `0x4d6af0` から得た値。文字描画へ転送 |
| `+0x20` | caller が object `+0x228 == 2` から作る bool。renderer 内の読み出しは確認できない |
| `+0x24` | 天体別 size、caller object `+0x230` |
| `+0x28` | caller fade |

`Places +0x30` の fade 状態を入口で判定する。照合は record の kind / ID であり、表示名ではない。選択地点の特別扱いは record `+0x24` の完全 target と別途構築した選択 target の完全比較による。

## null surface と地形 surface の座標

null surface 分岐 `0x53326c–0x53332f` は次を計算して `0x532811` へ合流する。角度単位は度。

```text
theta = (90 - latitude) * D2R
phi   = (longitude + 180) * D2R
p     = 1.0019999742507935 * (sin(theta)*cos(phi), sin(theta)*sin(phi), cos(theta))
```

非 null 分岐 `0x5327be` は `0x457f40(surface, out, longitude, latitude)` の結果に同じ `1.0019999742507935` を掛ける。helper 自体にも `longitude + 180` が存在する。

`0x457f40` で surface `+0x18` の地形配列が null なら半径 1 の上記球座標となる。配列がある場合は以下を経る。

- 経度と緯度から tile column / row を作る。column は整数除算の剰余、row は範囲へ clamp する。現代的な負数 modulo へ無条件で書き換える根拠にはしない。
- tile の経緯度境界から補間比率を作る。補間範囲外の経路は高さ 0 を使用する。
- tile の選択 LOD の signed 16-bit 高さを bilinear sample し、`0x458167–0x45816b` で浮動小数点値を整数へ truncation した後、16-bit signed 値として取り出す。
- 半径は `1 + sampledHeight * surface[+0x04] / surface[+0x00]`。その半径で同じ球座標を返す。

したがって surface pointer が非 null でも地形未ロードなら球面へ戻るが、地形ロード済み Earth / Mars を常に半径 1 とする実装はこの経路を再現しない。tile のロード・LOD 選択・scale 初期化全体は本監査の外である。

## group fallback と fade

group の `0x533390` は名前完全一致検索で、未一致時に null を返す。`0x5331ee` は group 配列の **先頭レコード** を代用する。文字列 `Default` を改めて検索しない。配列が空の経路は `_invalid_parameter_noinfo` を呼ぶため、「空なら安全な組込値」をこの関数から導けない。

初期化 `0x5360e0` がデータ読込と独立して組込 `Default` 群を登録することは既存監査で確認済みである。そのため `PlaceDisplayModel` にある「選択ファイルだけの実効群」の先頭を、そのまま runtime fallback としてはならない。登録順と組込初期化を反映した別の runtime view が必要になる。

renderer 入口の modelview を `M`、その translation を `rc`、第 0 列 xyz の二乗ノルムを `k2` とする。`M * Translate(p)` の translation の二乗ノルムを `r2` とすると、`0x5328c4` 以降は次になる。

```text
q = k2 * group.distance * group.distance / r2
if fullySelectedTarget: q = 0.25 * k2 / r2
if q <= 0.0006853892118670046: skip
fade = min(1, (q - 0.0006853892118670046) / 0.0012184695806354284)
t = r2 / k2
if t < 0.01: fade *= t / 0.0001
fade *= PlacesFade * callerFade
if fade <= 0.05: skip
```

近距離項の分母は `0.0001` であり `0.01` ではない。この項を掛けた後の再 clamp はない。減衰という名称だけを根拠に 1 以下へ正規化しない。非有限値・ゼロ距離に対する native 境界の方針は別途必要だが、原版式そのものとは区別する。

最終位置は `p` にさらに `1.000499963760376` を掛ける。alpha は `group.alpha * fade`。選択地点の RGB は色 helper `0x4a1ad0` の index 5、通常地点の RGB は group 色である。色 index 5 の palette 初期値・設定追従までは本監査では確定していない。

renderer 内に地平線や天体裏側の明示的な可視判定は見つからない。`GL_DEPTH_TEST` の変更も行わず caller の状態を継承する。これを「裏側も必ず描画される」または「必ず地形で隠れる」と断定するには caller の depth / geometry state が不足する。

## billboard と文字倍率

サイズ係数は `S = Places.labelSize * perBodySize * group.size / 1.2`。`0x5279c0(rc, M)` へ渡す `M` は最終位置へ平行移動した後の double modelview である。以下は helper の計算をそのまま表したもの。

```text
P = translation(M)
O = accessor49a770()
L = norm(P - O)
F = normalize(P - O - rc)
U = accessor49a740()
R = normalize(cross(U, -F))
U2 = cross(-F, R)
M の3軸 = (R, U2, -F)、translation は保持
glLoadMatrixd(M)
return L
```

`0x49a740` は global doubles `0x102aac0 / 0x102aac8 / 0x102aad0`、`0x49a770` は `0x102ab00 / 0x102ab08 / 0x102ab10` の符号反転を返す。これらを作る camera matrix の producer と native camera の対応は未確定である。

helper 後に renderer は Y 軸 180° 回転を合成し、次の uniform scale を使う。

```text
scale = S * A * (L / B) / 180
A = global float 0x110752c
B = global float 0x1107528
```

A は setter `0x5ac110` / getter `0x5ac130`、B は `0x5ac140` / `0x5ac160` に対応する。Lua wrapper の直接呼出しも確認したが、登録名・画面寸法・FOV・単位への対応は未確定である。A を native viewport width、B を camera distance と推測して埋めない。

表示文字列は地点 record `+0x40` を使う。`0x532dbb` で局所 X に `0.2` 移動して文字 helper `0x4411e0` を呼ぶ。公式通常版にある水平モードの近距離 quaternion 補間や左右 alignment 分岐は、この Plus 関数では確認できない。

## caller と 180° の関係

`.text` の direct `E8` call を調べ、`0x532470` を呼ぶ 4 箇所を確認した。間接呼出しまで存在しないと証明したものではない。

| call site | kind / surface | 確認できた経路 |
| --- | --- | --- |
| `0x54a8cb` | Satellite / null | 衛星ラベル。caller 内で uniform scale を掛ける。外側の全 pose は未確定 |
| `0x54cd4d` | Planet / null | `0x54c920` 内の一般惑星経路 |
| `0x54d37c` | Planet / `0x1107280` | `Mars` 名前解決に一致する分岐 |
| `0x54e110` | Planet / `0x1107220` | `Earth` 分岐から `0x54d500` を通る経路 |

planet 共通 `0x54c920` は `0x54c9d7` で Z 軸 180° 回転を合成する。一般惑星の球面本体には扁平率に応じた Z scale があるが、その push / pop の外でラベルを呼ぶ。

Mars / Earth の surface helper も経度 +180° を使うため、この Z 回転と位置式の +180° は代数的に相殺する。外側の body frame では conventional な `(cos(lat)cos(lon), cos(lat)sin(lon), sin(lat))` に戻る。ただしこれは局所軸についての結論で、外側 pose の epoch・符号まで native と同一という認定ではない。Earth 関数内の明示的な matrix push / pop は追跡したが、すべての別描画 helper 内部の状態保存まで検証したわけではない。

一般惑星を呼ぶ `0x54bc0b` の経路では、`glTranslated` → body matrix → uniform scale → `0x54c920` の順序を確認した。body matrix は getter `0x53ac70` が object `+0x1a8..+0x1e8` の 9 doubles を転置して返し、caller が GL 用に配置する。元 pose の生成・時刻依存性、別 caller `0x54c190`、衛星の外側回転を追跡し終えていないため、全天体への一括適用は留保する。

## 公式通常版との相違

ローカル `sources/official/mitaka_source/Mitaka/mtk_draw_places.cpp` を CP932 として読み取った。通常版の `get_pos_from_lon_lat` は経度への 180° 加算を持たない。また通常版は距離計算前に base origin を引き、水平モードや近距離姿勢補間、左右 alignment を扱う。Plus への移植でこれらを無条件に混ぜない。

通常版の `screen_w` / `screen_z` の式は Plus の A / B 式と形が一致するが、式の一致だけでは Plus wrapper の登録名や native camera の対応は確定しない。近距離 fade の `t / 0.0001` は通常版にも見られるため、逆アセンブルで読み違えた値ではない。
