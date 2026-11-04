# N15 地形描画への接続案

2026-10-30。UNIT7 では [地形 core](../../../native/core/TERRAIN_PROVENANCE.md) のファイル保持・格子読み込み・補間・物体ローカル座標計算までを確定する。本書は次の実装単位に渡す読み取り設計であり、地形描画、設定 UI、Lua 接続の完成を示すものではない。

## 現在の描画と必要な変更

`native/gui/src/planet_surface.cpp` の物理描画は、画素ごとの視線と解析的な球の交点を求めている。球面 mesh を変形する実装ではない。`render_surface_scene` 内の depth は AU 単位で、全不透明球の最短交点を保持し、後段の雲にも使う。`render_surface_view` はこの経路への入口である。一方、`render_planet_surface` は物理視線を持たない模式表示である。

`atmosphere_renderer.cpp` は同じカメラから視線を作るが、不透明球の交点を独立して求めている。地形を球の色にだけ反映すると、輪郭・法線・陰の深度が変わらない。地形の三角形を追加する場合も、地形より手前の基準球を残すと負の標高の谷を球が覆ってしまう。地形を有効にした天体の不透明面は、地形面へ置き換える必要がある。

次の実装では全不透明面の depth を確定した後、同じ depth を大気の積分終端と雲の遮蔽へ渡す。N13 食の評価で使う物理半径と、画素上の地形による可視判定は別の入力として保つ。

## 明示する出典と所有

天体と source path の結合は GUI の資産管理層で行う。`TerrainFile::open` は path を読むだけであり、天体や別インストールを探索しない。次の 4 ファイルは通常版に存在する読取可能な候補として提示できる。

|天体|通常版 data 内の明示 path|最大原本サイズ|備考|
|---|---|---:|---|
|Earth|`earth_topo/earth_topo.dat`|81,822,538 bytes|追加データのサブディレクトリをそのまま選べる|
|Moon|`moon_topo.dat`|761,562,016 bytes|全 payload を常駐させない|
|Mercury|`mercury_topo.dat`|59,713,216 bytes|形式は確認済み。旧 Plus の登録・表示対応は未認定|
|Mars|`mars_topo/mars_topo.dat`|213,945,124 bytes|追加データのサブディレクトリをそのまま選べる|

ローカル Plus の地形ファイルは未確認である。Plus の選択時にこれらを自動で代用しない。通常版由来の資産を使う場合は、その出典と選択した path を表示する。現在のデータ root、利用中の地形 source、候補一覧の出典を区別する。

binding は天体 ID、明示 path、開いた `TerrainFile`、読み込んだ source identity を持つ。patch と grid はこの所有者から ordinal で取得し、他のファイルの header / patch と組み合わせない。core の借用 window は次の read で失効するので、描画 job を越えて参照を保存しない。

新しい source の選択に失敗した際は失敗理由を示す。従前の有効な binding を残す設計を採る場合は、その source がまだ利用中であることも示す。部分的な新 binding を既存状態へ混ぜない。保存・復帰時の source 同定を path だけにするか、内容 hash を追加するかは、設定の永続化を実装する単位で確定する。現 core の descriptor identity は内容認証用の hash ではない。

## 三つの半径と地形倍率

|値|由来|用途|
|---|---|---|
|`Rdata`|地形 header の基準半径 m|標高の datum と無次元変位|
|`Rphys`|天体の物理モデル|食・距離・物理的な位置計算|
|`Rdisplay`|N14 の表示文脈が決める半径|画面上の表面形状と遮蔽|

原版 `topograph.cpp` の `TopoSphere::draw` は `fac = unit * elv_fac / R0`、`PatchGrid::calc_buffers` は `(1 + fac * raw_height) * n` を用いる。これに対応する native の描画点の候補式は次である。`h` は meter、`n` は物体固定系の単位方向とする。

```text
local_display_point = (Rdisplay / Rdata) * (Rdata + topoFactor * h) * n
world_point = body_center + body_orientation * local_display_point
```

同じ単位にそろえてから評価し、AU への変換は境界で 1 回行う。`Rdata` と `Rphys` の差を隠すために原 header を書き換えない。`topoFactor` は地形の表示倍率で、N14 の惑星・衛星全体の表示倍率とは別に保存する。N13 に `Rdisplay` や誇張した地形標高を渡さない。

[旧 Plus の限定静的監査](terrain-amplification-audit.md)では Lua `Planets.topoAmplification` の 1..5 が内部 0..4 に対応し、倍率は 1 / 2 / 5 / 10 / 20 と確認した。通常版 GUI の 0..4 もソースで確認できるが、旧 Plus の GUI dispatch は未確定である。core の連続倍率入力を、そのまま旧 Lua の引数仕様とは扱わない。

姿勢は既存 `BodyOrientation` を使う。地形の x / y / z は東経 0 度 / 東経 90 度 / 北極に対応する。画像の 180 度 offset は UV の処理であり、地形幾何を 180 度回転する根拠にはしない。

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

ここで level はファイル内の ordinal である。`2^level` は選択式のしきい値であり、格子寸法を `2^level` に作り直す指示ではない。Earth の 8 → 15 や保存 level の生値もそのまま保持する。原版の距離・モデル行列に対応する値を、N14 の選択済み表示半径と既存 camera から明示して渡す必要がある。

native の資源制限によって level を落とす場合は、通常の公式 LOD と区別して診断する。選択した patch を黙って欠落させる仕様にはしない。四隅だけの除外が誇張した山頂を隠さないかは別途検証が必要であり、公式分岐の転記だけで native の保守的な境界と認定しない。

## 格子から幾何への変換とメモリ

公式 `PatchGrid::calc_buffers`（164–224 行）は halo を含む位置を作り、左右・上下の差分から `-normalize(cross(u, v))` で法線を求める。極の行は放射方向の法線を用い、`draw_poly` は行ごとの triangle strip を描く。native で借用 window を順次処理する場合も、halo、極、三角形の向きの根拠として使える。

同時所有は索引、1 grid の原 bytes、処理中の 1 patch の派生幾何、画面 depth / color を基本とする。Moon の全格子や全 level の頂点列は作らない。core の 256 KiB 制限は原 payload に対するもので、派生頂点・法線・triangle・画面 buffer の容量上限は別に必要である。描画 job の中で patch を順に読み、生成・投影・描画してから破棄する構造を先に試す。

最大格子は 256 × 256 cells。派生幾何の件数を size の積と byte 上限で検証し、途中の vector 再確保による重複常駐も見積もる。必要になった場合だけ、明示容量を持つ cache を追加する。複数天体を同時表示する際も source の個数と全索引容量を合算して制限する。

異なる LOD の隣接区画、経度 seam、極での一致は今後の試験対象である。隙間を埋める skirt や標高の平均化は原値と輪郭を変えるので、根拠なく追加しない。source が途中変更された場合は、その描画結果を公開せず診断する。前の完成 frame を残す場合も、その方針を GUI の失敗表示とそろえる。

## 分割するファイルと接点の案

以下は追加先の候補名であり、公開済み API ではない。

|責務|候補|境界|
|---|---|---|
|明示 source と天体の結合|`terrain_binding.hpp/.mm`|所有する `TerrainFile`、source 表示、読込診断。AppKit に依存しない部分は `.cpp` に置く|
|LOD と patch 幾何|`terrain_geometry.hpp/.cpp`|同じ source の header / patch / grid、表示半径、倍率から bounded な頂点・法線を作る pure 処理|
|地形の不透明描画|`terrain_renderer.hpp/.cpp`|既存投影と画像型を再利用し、最短 depth を共通 frame へ書く|
|表面・大気・雲の共通 frame|`surface_frame.hpp/.cpp`|camera、寸法、画素中心、単位と原点を固定した depth を受け渡す|

共通 frame は同じ camera・画素寸法・scene の結果であることを検査できる値を持ち、地形と解析球が同じ最短交点比較に参加する。depth の単位は AU、未命中は無限大とする候補が既存実装と合う。基準球は地形の粗い探索範囲として利用できるが、負の標高がある天体の最終不透明面としては残さない。

大気側はこの depth を積分終端に使う。雲は depth を読むが更新せず、既存の RGB 加算契約を維持する。地形未選択の場合に既存画像が変化しないことを先に固定する。模式表示に物理地形を適用する仕様は現段階では定めず、物理描画の入口から接続する。

## 次の単位で必要な確認

1. N14 の各文脈から `Rdisplay` を選ぶ境界を確定し、物理半径との混同を回帰試験で防ぐ。
2. source と binding の所有、失敗時の旧状態、選択・保存の仕様を確定する。旧 Plus の未知 GUI/API を推測で足さない。
3. 格子幾何を pure 試験する。平坦面、正負標高、halo 法線、極、日付変更による姿勢、非 2 倍 level を含める。
4. 共通 depth を導入し、物体順序変更、谷と他天体、大気終端、雲の前後、画面外・near-plane を検証する。
5. LOD 境界、近接時の最大負荷、複数 source の容量、source 変更・欠損・読み込み失敗を検証する。
6. 描画結果を確認した後、メニュー・設定保存・確認できた Lua enum を同じ validated setter に結ぶ。

UNIT7 ではここまでの描画コード変更や新たな公開 API の確定を行わず、core と監査証跡を先にまとめる。
