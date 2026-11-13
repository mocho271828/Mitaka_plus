# 物理球の大気描画

N12 の `render_atmosphere_scene` は、既存 `SurfaceSphere` と `SolarCamera` の透視投影に対して、公式 scalar 計算による単一散乱とローカル emmap の多重散乱を加算する。青い縁の近似画像による代用は行わない。計算の出典と数値差は [core provenance](../core/ATMOSPHERE_PROVENANCE.md)、原式の詳細は [参照監査](../../investigation/native-plus/unit6/n12-reference-audit.md)に記録する。

## 表示設定とデータ

`AtmosphereDisplayOptions` の `mode` は `none / single / multiple` の三状態。ローカル Plus の `doc/script_jp/planets.html:44–50` の `Planets.atmosphere` に対応する全体設定であり、Earth と Mars の独立スイッチは追加しない。既定は公式 `mtk_switches.cpp:123` の multiple、強度はローカル Plus ini の 6。強度は有限・非負・float 最大値以下とする。

公式 `mtk_planets.cpp:264–282` に従うパラメータは次のとおり。

| 対象 | 地表半径 m | 外層 | H m | N0 m⁻³ |
| --- | --- | --- | --- | --- |
| Earth | 6,378,136.6 | 地表 + 6H | 8,000 | 2.69e25 |
| Mars | 呼出側の実天体半径 | 地表 + 8H | 11,000 | 4e23 |

`AtmosphereLayer` は同一 `SurfaceSphere` 配列内の index と単一散乱設定、呼出中だけ有効な map ポインタを持つ。index の重複・範囲外、発光する球、太陽原点への結合は拒否する。強度は表示設定で置換する。multiple モードで map がなければ単一散乱を続ける。

`PlanetTextures.atmosphere_emission` は `data/emmap.dat` の原 bytes と診断を保持する。欠損・破損を正常扱いの空 map にしない。Earth にだけこの map を結合し、Mars は単一散乱を使う。map 固有の半径・密度と Earth 単一散乱のパラメータには差があるが、それぞれをそのまま保持する。map の地表より低い視点では map を評価せず、単一散乱だけを使う。

## 投影、遮蔽、合成

入力の球中心・表示半径・カメラ距離は AU、基底は同じ J2000 黄道座標。各画素中心から既存 `solar_camera_ray` で視線を得る。地表半径 m / 表示球半径 AU を倍率として惑星相対の視点と終端を m に変換する。表示半径の拡大に対して大気と地表が一緒に動く一方、core に渡る物理半径は一定となる。

全不透明球に既存 `sphere_hit_distance` を適用し、最も近い交差まで大気を積分する。層を持たない他天体も遮蔽物になる。カメラがいずれかの不透明球の表面・内部なら全画素を 0 にする。finite、単位、添字、重複などの設定検査は none モードでも省略しない。

出力は左上原点の RGBA、寸法は各 1–1024。層ごとの RGB を加算し、最後に [0,1] に clamp、255 倍して丸める。非ゼロ RGB の alpha は 255、黒は 0。これは `PlusLighter` 合成で RGB の二重減衰を避けるためで、透過率ではない。core の alpha を RGB に掛けない。

SolarSceneRenderer の物理 1 天体、共通の地球・月、全 11 天体の経路は、共通の不透明球を使って **base/night → atmosphere → cloud** の順に描く。雲は不透明 depth を更新しない。模式的な最小サイズの天体マーカーには適用しない。

## 検証

純描画の `test_atmosphere_renderer` は、2026-10-29 に通常 arm64、ASan/UBSan arm64、x86_64 の各構成で 4,259 checks、exit 0。GUI window や OS の表示状態は使わない。

- 65×65 の形状、明るい大気縁と画面外の黒、全画素の alpha を確認。
- 1 画素の視線・最寄り地表終端に対し、core の直接計算と RGB の byte 化まで一致を確認。
- 合成 map による多重散乱の加算、map なしの単一散乱継続、none / 強度 0 / 層なしを確認。
- 近い遮蔽物、球の順番の入れ替え、遠い遮蔽物、夜側、地表・内部視点、大気に届かない視線を確認。
- 表示球半径とカメラ距離を同倍率にした場合の描画一致、不正寸法・強度・幾何・添字・重複・発光球・太陽原点の拒否を確認。

[N08 の最終検証](EARTH_LAYERS_PROVENANCE.md)では Solar 接続の回帰 50 checks が通常 / SAN / x86 の各構成で通過した。通常構成は任意 benchmark 3 checks を含む 53 checks。Earth map の効果、Mars に map を使わないこと、none / 強度 0 / 非表示、物理 3 経路、模式表示への不適用に加え、空画像の AppKit guard と非 Earth での toggle 不変を検証している。アプリ全体の最終試験・状態保存・メニューの結果は UNIT6 統合記録で判定する。

## 原版と区別する範囲

原版の GL mesh、角度 0.005 の間引き、adaptive sampling、内側 shell の 1.001 倍配置を再現せず、既存の物理球と同一の画素視線を直接積分する。任意の他天体への積分終端は native の明示的な拡張であり、原版の画像との完全一致を主張しない。地平線空背景、日食、恒星減衰、地上 gamma 補正は今回の対象外。

[N08 の最終計測](EARTH_LAYERS_PROVENANCE.md)は 800×800 の人工シーンを各 1 回、並行負荷のある通常 arm64 環境で測定し、none 225.34 ms / single 801.21 ms / multiple 991.45 ms だった。環境固定の性能保証ではない。現実装には画素ごとにカメラ幾何を再計算する余地が残るが、数値契約を変える近似や無言の標本削減は入れていない。
