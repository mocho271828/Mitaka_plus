# 地形の基準半径と詳細度の選択

通常版 Mitaka 1.3.1 の地形形式と LOD の比較に使う定数を示す。地球・火星のデータと現行レンダラーの対応は [地形の出典](../../../native/core/TERRAIN_PROVENANCE.md)・[地形面の描画](../../../native/gui/TERRAIN_SURFACE_PROVENANCE.md)を参照。

|天体|通常版 data 内の明示 path|最大原本サイズ|備考|
|---|---|---:|---|
|Earth|`earth_topo/earth_topo.dat`|81,822,538 bytes|追加データのサブディレクトリをそのまま選べる|
|Moon|`moon_topo.dat`|761,562,016 bytes|全 payload を常駐させない|
|Mercury|`mercury_topo.dat`|59,713,216 bytes|形式は確認済み。旧 Plus の登録・表示対応は未認定|
|Mars|`mars_topo/mars_topo.dat`|213,945,124 bytes|追加データのサブディレクトリをそのまま選べる|

## 三つの半径と地形倍率

|値|由来|用途|
|---|---|---|
|`Rdata`|地形 header の基準半径 m|標高の datum と無次元変位|
|`Rphys`|天体の物理モデル|食・距離・物理的な位置計算|
|`Rdisplay`|表示文脈が決める半径|画面上の表面形状と遮蔽|

## 公式 LOD の確定範囲

参照は保存した公式 `common/graphics/topograph.cpp`。旧 Plus の描画全体と同一であるとは未認定である。

|処理|公式ソースの根拠|確認した式・分岐|
|---|---|---|
|小さく見える場合|`TopoSphere::draw`、589–677 行|`R² / L² < tan(6°)²` なら標準球を描く|
|球の内部に視点がある場合|同上|`L² - R² <= 0` なら地形を描かず戻る|
|patch の大きさ|`TopoPatch::calc_nv`、347–382 行|`D = 2 * max(abs(Δlon) * cos(mid_lat), abs(Δlat))`。角度は rad|
|見かけの大きさ|`get_anguler_diam_sqr`、451–460 行と呼出し|`A² = R² * D² / |camera_to_patch_center|²`|
|選択する level|`TopoSphere::draw`|最大 index から下り、`A² > (rad(0.13°) * 2^level)²` の最初の level。見つからない場合は 0|
|低解像度指定|同上|選んだ level を 1 減らし、0 へ下限を設ける|
|patch の除外|`TopoPatch::cull_test`、423–445 行|基準球上の四隅による裏面・frustum 判定|

ここで level はファイル内の ordinal である。`2^level` は選択式のしきい値であり、格子寸法を `2^level` に作り直す指示ではない。Earth の 8 → 15 や保存 level の生値もそのまま保持する。原版の距離・モデル行列に対応する値を、選択済み表示半径と既存 camera から明示して渡す必要がある。
