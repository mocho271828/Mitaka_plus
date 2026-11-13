# 通常版Mitakaの食・影の球幾何

通常版 1.3.1 の球幾何の出典を示す。[旧 Plus の表示フラグ](n13-plus-display-contracts.md)・[食の計算](../../../native/core/ECLIPSE_PROVENANCE.md)・[ネイティブ版の描画](../../../native/gui/ECLIPSE_RENDERING.md)

| 原典 | 確認した内容 |
| --- | --- |
| O `mtk_eclipse.cpp:52–66` | 影軸と球面の近い交点、未命中の原点 sentinel |
| O `mtk_eclipse.cpp:74–120` | 本影・半影の円錐、中心距離と半影による候補除外 |
| O `mtk_eclipse.cpp:125–145` | 正規化された平面円盤の重なり面積比 |
| O `mtk_eclipse.cpp:150–297` | `asin` 視半径と視中心角、明るい半球の標本、扁平率・三角形生成 |
| O `mtk_eclipse.cpp:306–399` | 視点が内部なら抑止、画素角閾値、独立した影フラグ、乗算合成 |
