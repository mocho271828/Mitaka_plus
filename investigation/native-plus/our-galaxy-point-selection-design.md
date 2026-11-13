# 天の川点群の選択: 実装メモ

対象は実装計画の単位 3（GAL-02）。旧 Plus の点群の操作・名前との対応は未確認であり、以下は現行 native 実装を基にした設計案である。
以下の `native/` は `vendor/mitaka/native/` を指す。

## 識別と名前

- `OurGalaxyModel` は元ファイルのパス・bytes と、入力順の 4 群 `disk1` / `disk2` / `disk_ob` / `bulge` を保持する。各点の値は raw xyz のみで、名前や他カタログへの結合キーはない（`native/core/include/mitaka/our_galaxy_model.hpp`、`native/core/src/our_galaxy_model.cpp`）。
- 選択 ID は既存の銀河カタログ ID とは別の型とし、群と群内の原順 ordinal を保持する。メモリ上では出典を持つモデルと組み合わせ、モデルが差し替わったら古い選択と非同期結果を破棄する。不正な点を除いて採番し直さない。同じ座標の点も別 ID とし、表示用の番号を 1 始まりにする場合も内部の原順は維持する。
- 根拠のある名前キーは確認できていない。座標の近さや行順だけで名称を結合せず、名称がない点は出典・群・原順を表示する。

## 描画と選択の一致

- `GalaxyOverlay.mm` は完成画像の request が現在の request と一致する場合に complete を表示し、それ以外は現在のカメラによる preview を表示する。選択対象は表示中の request とモードで決める。
- 完成画像は `native/gui/src/OurGalaxyRenderer.mm` が設定された transform を適用し、変換後の各座標が有限かつ絶対値 1e40 以下、`GalaxyProjector` の投影に成功、点の中心が viewport 内、放射吸収の `extinction.visible` を満たす点を円として描く。`GalaxyOverlay.mm` は OurGalaxy が表示対象で、放射画像の alpha が正の場合に点画像を作成する。点選択は同じ transform、投影、表示条件を使い、完成した `_ourGalaxyImage` が存在する場合に限る。`_ourGalaxyMultiplier` だけでは alpha が 0 の場合や点画像の生成に失敗した場合を除外できない。
- 移動中 preview は `GalaxyOverlay.mm` が群ごとに `max(1, ceil(count / 1500))` の刻みで原順を間引く。各群最大 1500 点の raw xyz を使い、上記と同じ座標範囲・投影・中心の viewport 判定を通った点を 1.5 × 1.5 pt の矩形で描く。preview は raw 座標を用い、transform と吸収を適用しない。距離フェードによる銀河 alpha を適用する。preview と complete それぞれの表示条件を選択にも適用し、両者の描画条件を変更する場合は選択を同時に揃える。
- `GalaxyProjector` は近接面より手前の点と非有限な投影を除き、viewport 境界上の中心を含める。円や矩形の一部が画面内でも、中心が外なら描画されない。クリック座標は描画矩形の左上を原点とする。
- 選択の候補は、上記の条件を満たし描画命令が発行される点と定義する。加算合成や量子化によって点の寄与が最終ピクセルで判別できない場合まで、個別の視認性を保証するものではない。
- 各点群レイヤーでは、クリック位置を描画形状が覆う候補を優先し、同一レイヤー内では群・原順の後の点を選ぶ。preview は 1.5 pt の矩形、complete は群ごとの半径の円として判定する。加算合成には上下関係がないため後描き優先は仮定であり、アンチエイリアス境界とピクセル量子化は近似である。覆う点がなければ選択半径内の画面距離・深度・群・原順で決め、他のレイヤーとも描画順を比較する。画面外や非表示の点を選ばない。
- `GalaxyOverlay.mm` の非同期 pick は表示済み request、表示モード、世代を照合して古い結果を破棄する。`SolarSystemView.mm` は実際に公開された camera/map も照合し、太陽系天体などを先に判定する。点群にも同じ仕組みを適用する。

## 接続箇所と検証

- `native/gui/src/GalaxyOverlay.h` / `.mm`: 選択結果型、preview/complete の点候補、既存候補との比較、表示状態・モデル世代。
- `native/gui/src/SolarSystemViewInternal.h` / `SolarSystemView.mm`: 選択状態、情報欄、モデル差替え・非表示時の解除、focus、選択マーカー、表面移動の抑止。focus とマーカーは選択元の表示モードに対応する描画座標を使う。
- `native/gui/src/OurGalaxyRenderer.mm` と必要な関連ヘッダー: 描画・選択で使う座標変換と候補条件を共有する。放射モデルの可視判定を重複実装しない。
- `native/gui/tests/test_our_galaxy_renderer.mm` と `test_galaxy_overlay.mm`、必要に応じて view のテスト: 元順 ID、変換、同距離・深度、間引きの有無、非表示、画面外、吸収、alpha 0、古い非同期結果、モデル差替え・選択解除を確認する。既存の天の川全体選択も回帰確認する。
- `ourgalaxy_model.dat` の実データでも出典と点数を確認する。元データは変更せず、名前・旧 Plus との一致は根拠が得られるまで未確認として扱う。

## 性能と保存

- 現データの点群は計 102,000 点である。complete の選択は既存 pick と同じバックグラウンド処理とし、全点の変換・投影後にクリック半径内または描画形状内の候補を優先順に減光判定する。減光で隠れた候補を飛ばし、次の可視候補を判定する。
- 放射モデルの構築は 512 × 512 の map 2 枚の変換を伴う。候補がない場合は構築を避けるか、描画側の immutable なモデルを安全に共有する。減光積分は 1 点あたり最大 100,000 steps で、現状は積分途中の中断に対応していない。候補間でキャンセルを確認し、実測で必要な場合に積分内の中断を別途検討する。
- 現行 session v9 は銀河や HIP の選択を保存せず、太陽系天体の選択を保存する（`native/gui/include/session_state.hpp`、`native/gui/src/AppSessionCommands.mm`）。今回も点の選択は保存対象に加えず、復元時は既存の天体選択によって点の選択を解除する。将来保存する場合は群・原順と出典 bytes のサイズ・SHA-256 を照合し、不一致時の事前検証と session 契約の変更を別単位で扱う。

## 段階的な実装案

1. complete の描画と選択で共有する変換・座標検証の契約を切り出す。preview の raw 座標と間引きは維持する。
2. overlay の選択結果に点 ID を加え、表示モードごとの候補集合、減光判定、既存候補との比較、非同期結果の破棄を実装する。
3. view の選択状態、情報欄、focus、マーカー、解除と復元を接続する。

回帰試験には、preview の間引き点が complete では選べる場合、非有限・範囲外・近接面・画面外、変換、減光、alpha 0、点画像の生成失敗、重複座標と優先順位、カメラ・表示・モデル変更および preview から complete への移行中の古い pick、楕円 fallback、focus と session 復元を含める。`test_galaxy_overlay.mm` の不正な放射モデルでも preview と他のレイヤーを表示・選択できる既存の保証を維持する。

## 同一レイヤーの重なりの検証（2026-11-07）

- preview と complete の形状内外、異なる投影位置、群・原順、透明と候補の fallback を単体試験で確認した。overlay の非同期選択も preview と complete で確認した。実 `ourgalaxy_model.dat` を指定した renderer 試験は 66 checks 成功。
- `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は成功。地形を使う試験は LFS ポインタだけでは失敗し、SHA-256 を照合したデータ本体で成功した。
- 加算合成時の後描き優先は現行実装上の仮定。画素の量子化・アンチエイリアス端の厳密判定、旧 Plus との比較、およびこの重なり操作の実画面確認は未実施。
