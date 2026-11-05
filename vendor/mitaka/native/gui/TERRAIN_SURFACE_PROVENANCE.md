# 地形メッシュと描画標本

UNIT8 の `terrain_mesh` / `terrain_surface` は、選択された同一出典の `TerrainFile` を使う CPU モデルである。地球・月・水星・火星の非同期読込と地形交点による表面描画を GUI へ接続した。地形倍率は画面・Lua・描画・状態保存へコード上で接続し、全体統合と旧版一致は未検証。原本は変更しない。ユーザー承認による公式別配布 Earth / Mars の明示的な限定採用、ハッシュと利用条件は [地形の出典記録](../core/TERRAIN_PROVENANCE.md) を参照。Moon / Mercury を別版から補完しない。

## 根拠と計算

原資料はローカルの `sources/official/mitaka_source/common/graphics/topograph.cpp`。原資料のバイト列は不変で、派生した `terrain_mesh.cpp` に MIT notice を保持した。

| 項目 | 原資料の位置 | 採用範囲 |
|---|---|---|
| 格子と halo | 100–145 行 | `TerrainFile` の符号付き標高と周囲 1 点を使用 |
| 頂点半径 | 164–224 行 | `(1 + unit * height * factor / Rdata) * direction` |
| 法線 | 164–224 行 | halo の中央差分、`-cross(right, down)`。南北極は半径方向 |
| 三角形 | 226–255 行 | 行方向 strip と同じセル対角線。極の退化面も元の順序で保持 |
| patch の角径 | 347–382、451–460 行 | 中点までの距離と `2 * max(dlon*cos(lat), dlat)` |
| LOD | 589–677 行 | `.13度 * 2^level` の閾値、low resolution は 1 段下げる |
| 遠方・内部 | 589–677 行 | 視点が datum 内なら none、`R/L < tan(6度)` は sphere |

`Rdata` はファイル header の基準半径であり、`Rdisplay` は呼出側の表示半径である。標高を無次元化してから `Rdisplay` を一度だけ乗算する。負標高も保持する。天体固定座標は x=東経0度の赤道、y=東経90度の赤道、z=北極。原版の OpenGL 下端原点の v は、既存画像標本化に合わせて上端原点 `.5-lat/180` に変換する。画像ごとの経度 offset はテクスチャ側の責務で、地形の位置を回転しない。

元の float 演算とのビット一致は主張しない。計算は double で行う。原版の datum 四隅による patch culling は盛り上がった地形を落とし得るため採用せず、全 patch を順番に処理する。追加の skirt や未知の LOD 接続規則は作らない。異なる LOD 間の継ぎ目を隙間なく接続する保証は、このモデルの試験範囲に含まれない。

## 所有と失敗

索引と原格子 1 枚は既存 `TerrainFile` が所有する。メッシュ側の上限は頂点 1 patch と halo 3 行の合計。描画側は frame bytes、mesh bytes、三角形数、画素検査数を個別に制限する。全ファイルや全メッシュを常駐させない。source identity の確認は開いた FD の metadata に基づき、暗号学的な snapshot を意味しない。

viewport、右手正規直交基底、有限の中心・表示半径・倍率、有限正の頂点半径を検証する。上限超過・数値不正・I/O・原本変更は失敗とし、部分 frame や無通知の sphere fallback を返さない。全処理後に原本の変更を再検査する。

## 描画との接点

`TerrainSurfaceFrame` は画素ごとの単位視線に沿った距離 AU、天体固定法線、UV を返す。screen clipping は被覆判定にだけ使用し、距離と属性は元の 3D 三角形と既存 `solar_camera_ray` の交点から求める。これにより near 平面で巨大になる投影座標から属性を逆算する精度損失を避ける。

**terrain モードでは同じ天体の analytic datum sphere を opaque pass から外す。** 基準球と単純な最短深度合成をすると、負標高が基準球に隠れる。他天体との遮蔽は正距離の最小値を使い、確定した地形深度を大気・雲・食の描画へ渡す接続を追加した。テクスチャ照明と表面の食評価には、この標本の実際の位置・法線を使う。要求条件に一致する snapshot のみを採用し、読込中・欠損・失敗時は診断付きの基準球表示に戻す。GUI 統合の確認結果と部品試験は区別する。

P1-3 では計算中の scene を入力変更では取り消さず、完了後に一致する地形・天体・視点をまとめて公開し、待機要求は最新の 1 世代に集約する。データルートや viewport の変更は旧世代を無効にする。実 Earth データでは 20 回の日時・視点更新中、最初と最新の両世代が公開され、それぞれの地形・日時・視点の一致を確認した。表示は入力値に遅れる場合があり、実時間性は保証しない。旧通常版データによる過去の 800×450 単発測定は約 152〜1102 ms で、キャッシュ条件は統制していない。

高さ倍率 `Planets.topoAmplification` は Lua 値 1〜5 に対し実倍率 1・2・5・10・20 を対応させる。UI・Lua・描画・状態保存への配線を追加し、JSON v9 の必須整数 `terrain_amplification`（1〜5）で保存する。統合試験の完了を前提にしない。着陸・高度計算は地形面追従を保証しない。

## 検証と品質

通常、ASan+UBSan、x86_64 で pure 13,197 checks と、通常版の明示された Earth/Moon/Mercury/Mars 4 ファイルを用いる 31,929 checks がそれぞれ通過した。独立 Möller–Trumbore 交点との全画素照合、near 横断、負標高、patch 順序、回転・表示倍率、4 種上限と失敗の原子性を含む。詳しい実行結果・制約は 同梱元 Mitaka の `investigation/native-plus/unit8/terrain-surface-validation.md` を参照。

既存 `TerrainFile`、`SolarCamera`、`BodyOrientation` と C++17 標準ライブラリを再利用した。新規依存なし。独立読み取りレビューでは最終 ray-plane / barycentric / finite guard を含め修正必須指摘なし。責務を原格子読取、1 patch メッシュ、frame 標本化に分けて手動品質レビューを実施した。`/simplifier-lai` は利用不可、近似名 `simplify-lai` は LobbyAI 限定のため適用していない。
