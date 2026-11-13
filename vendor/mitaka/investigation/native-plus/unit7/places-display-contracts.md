# 風景と地上ラベルの定義・局所メッシュ

## 表示モデル

`native/gui/include/place_display_model.hpp` / `src/place_display_model.cpp` の `PlaceDisplayModel` は `ObserverPlaces` を値として所有し、const accessors だけを公開する。

- 全出典の原 bytes、全定義行、選択元、地点実効値、provenance、欠損・解析診断を snapshot 内へ保持する。実効値の上書きによって原行を消さない。
- `selected_source` の catalog だけから表示定義を生成する。非選択元を合算せず、選択元の解析失敗や空入力で別の出典へ切り替えない。不正な選択 index は `invalid_argument` とする。
- ラベル群は `name` の bytes 完全一致をキーとする。後の行が値と provenance を更新し、初出の配列位置を保つ。根拠は `0x529147` の比較と `0x5294ab–0x529750` の既存レコード更新。
- 風景は入力 `target_name + "." + name` の bytes 完全一致をキーとする。`Planet` / `Satellite` の特殊経路も同じ文字列連結になる。後勝ち・初出位置維持と原引数を保存する。根拠は `0x52a590` のキー構築、`0x52ab5b` の比較、`0x52adcc–0x52ae31` の更新。
- `PlaceDefinitionOrigin` は source index と、その catalog の対応する定義配列内のゼロ始まり row index を指す。元ファイルの物理行番号ではない。
- 検索は完全一致の optional index を返すだけとし、天体 alias 解決、組込群の合成、名前の大小文字補正、観測者の選択を行わない。

原入力に `.` が含まれる場合も修飾キーは文字列連結である。例えば `Unknown.A` + `B` と `Unknown` + `A.B` は同じキーになる。これは登録キーの性質を再現するものであり、その未知 target が原版で有効な天体へ解決されるという認定ではない。

## 画像あり分岐の局所形状

`landscape_geometry.hpp` / `landscape_geometry.cpp` の `LandscapeImageMesh` は、`PlaceLandscape` の値と固定長の頂点・quad 配列を所有する。画像を開かず、OpenGL / AppKit に依存しない。

描画関数 `0x5336a0` の画像あり分岐に対応し、row `0..18`、column `0..72` から 1,387 頂点と 1,296 quads を作る。`θ = 5°row`、`φ = 5°column` とすると、式は次になる。

```text
position = Rz(horizontalDegrees) * (cosφ sin(2θ), sinφ sin(2θ), -cos(2θ))
u = 1 - column/72
v = 0.5 + (row/18 - 0.5)/scale - verticalOffset
```

`0x533a93–0x533b77` が座標と UV、`0x533c10–0x533c2f` が Z 軸回転の根拠である。wrapper / adapter の原引数では第5引数が垂直 UV offset、第6引数が水平回転角（度）であり、同梱 1.3.0 文書の引数名と逆である。モデルは `offset_arguments[0]` / `[1]` にこの原順を保つ。

`0x533c88–0x533d0b` の送出順に従い、各 quad は `nextRow/currentColumn → nextRow/nextColumn → currentRow/nextColumn → currentRow/currentColumn` とする。継ぎ目の頂点、極の重複・縮退 quad を削除しない。`0x533be1–0x533c02` は S/T とも `GL_CLAMP_TO_EDGE` を指定するため、生 UV を `0..1` へ切り詰めない。将来の描画側でこの sampler 契約が必要になる。

native 境界では既存 parser と同様に scale の正値・有限性を要求し、offset の非有限値や計算後の UV overflow を拒否する。巨大な有限角度は radian 化前に 360° の周期へ戻す。倍精度による式の再現であり、旧 float の丸めまで bit 一致させた実装ではない。

## 未確定条件と追加で確認した分岐

モデルの exact lookup と原版描画の fallback は別の契約である。ラベル lookup `0x533390` は完全一致がないと `0x53342f` で null を返す。呼出側 `0x5331ee` は群配列の先頭を代用する。文字列 `Default` を検索しているわけではない。一方、初期化 `0x5360e0` はデータ読込と独立して組込 `Default` 群を作るため、選択ファイルだけの先頭を runtime fallback とみなすこともできない。組込色 helper と全初期化を確定するまで、このモデルは組込群・fallback を補わない。

選択地点用風景の分岐 `0x534648` は地点の完全 ID を照合し、その地点の風景名を使う。`0x534805` 以降で天体種別、`0x534840–0x53484d` で天体 ID、`0x534877–0x534899` で風景名を比較する経路がある。通常の天体別 `Default` 探索や全体 fallback も別に存在する。選択地点・通常経路・未解決 target を含む全 fallback の対応が未完のため、native observer への適用は行わない。

次の事項はこの変更で解決していない。

- 風景描画関数が継承するカメラ行列、局所軸と絶対方位の北、地平図・地表視点への変換。
- 画像デコーダから texture upload までの上下方向。raw UV の符号だけから画像ピクセルの上下を推定しない。
- 画像なし分岐の黒い半球。この分岐の極角は θ であり、画像ありの 2θ 球と異なる。
- ラベルの全 surface / null-surface 分岐、サイズ・距離減衰・遮蔽・billboard の画面対応。特に null-surface 分岐には経度へ 180° を加える計算があり、公式標準版の単純な経緯度変換を代用しない。
