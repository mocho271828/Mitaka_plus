# 地平図の天の川の座標変換と描画

- `render_horizon_background` は画素中心の地平方位・高度を既存 `ObservationFrame::to_equatorial` に渡し、既存の逆銀河変換・alpha を考慮した双線形補間を再利用する。方位は右、高度は上。U は周期、V は端で固定する。追加の黄道傾斜や時系変換は行わない。
- 画像と出力は各辺 1..1024、RGBA 長を検証する。viewport は既存の正規化に従い、非有限値・非正の倍率を拒否する。
- `HorizonView.milkyWayMode` と `setSkyBackgrounds:` を追加した。星座絵・恒星名集合の接続を保持する。
- 地平図は基礎色、天の川の PlusLighter 合成、不透明な地面、grid・天体の順に描く。天の川は `mapRect` に明示クリップする。既存の地面・周辺 UI の色を変えない。
- cache は画像モデルの同一性・mode・観測緯度経度・JD・viewport・出力寸法を含む。描画時に生成するため、隠れたビューの設定変更では生成しない。同じ JD・正規化済みの同じ範囲・選択だけの変更では再利用する。モデル交換は古い画像を破棄する。
- loader は既存のローカル `data` の兄弟 `textures` のみを使う。None / Normal / Bright / Infrared の選択値を維持し、画像欠損時に他 mode の画像へ代用しない。IR の正式名が欠損した場合のみ既存の小文字名 fallback を許す。破損・symlink の失敗を fallback で隠さない。

| 構成 | strict build | pure + Plus ローカル画像 | pure + 通常版ローカル画像 | 無窓 view bitmap |
| --- | --- | --- | --- | --- |
| arm64 通常 | exit 0 | exit 0、3/3 slot | exit 0、1/3 slot、欠損 2 件の診断 | exit 0、461,593 checks |
| arm64 ASan + UBSan | exit 0 | exit 0、3/3 slot | exit 0、1/3 slot、欠損 2 件の診断 | exit 0、461,593 checks |
| x86_64 Rosetta | exit 0 | exit 0、3/3 slot | exit 0、1/3 slot、欠損 2 件の診断 | exit 0、461,593 checks |

pure 試験は銀河中心・東西・両極、観測地の両極を含む 4 地点・2 JD、方位の周期、天頂・天底、17×13 の投影画素、alpha 補間、画像の継ぎ目、最大寸法、不正入力を確認する。既知方向を地平へ投影して画像中の期待色と比較するため、単に同じ逆変換を二重に呼ぶ試験だけではない。

view 試験は実際の `drawRect:` を固定 sRGB bitmap に描き、3 mode、欠損 mode、map 外・地面の不変、背景の左右上下、cache の全キーと拒否後保持を確認する。固定 sRGB bitmap の raw RGBA を比較すると、基礎色 (6,11,18) は Normal 合成後に (102,11,18) となる。
