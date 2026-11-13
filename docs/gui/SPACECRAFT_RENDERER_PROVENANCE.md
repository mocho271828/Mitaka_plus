# 探査機の点・名称・PTH 軌跡描画

`SpacecraftRenderer` は、同じ数値 JD で評価した `SpacecraftSnapshot` を太陽系カメラへ投影する。
座標系・単位・時刻の扱いは [PTH の位置評価](../core/SPACECRAFT_POSITION_PROVENANCE.md) に従う。
日心 J2000 黄道 AU をそのまま既存 `project_solar` へ渡し、太陽や親天体の位置を加算しない。
UTC/TT/TDB の物理時系や原版の画素一致は主張しない。

## 描画・カメラ操作の共通境界

`spacecraft_scene_position(snapshot, row)` は、モデル内の原定義から辿れる trajectory と
source index、PTH source の解析状態、評価結果の契約識別子、要求 JD、有限座標を検査する。
snapshot の位置と評価結果の位置が各成分で一致した場合だけ位置を返す。
点・名称・クリック判定と focus・追尾はこの同じ境界を利用できる。
これはアプリ内の snapshot 整合検査であり、外部データの真正性を認証する仕組みではない。
原点・座標面の未確定な PPI、参照違い、日時違い、不正値には描画位置を返さない。

点・名称は画面内の有限な投影結果を遠方から手前へ描く。
同じ深度では原定義順を維持し、定義や名称が重複しても統合しない。
クリック許容距離は native の 8 point とし、同じ距離なら手前を選ぶ。
距離と深度が同じ場合は後の原定義を選ぶ。
名称の UTF-8 表示は `SpacecraftBrowserModel` が確定した文字列を再利用する。

## 表示設定と軌跡

`SpacecraftDisplayOptions` の native 初期値は `points=true, labels=false, orbits=false`。
原 Plus の既定値を推定したものではない。

- `points` は点・選択リング・クリック判定を制御する。
- `labels` は点と独立して名称を制御する。
- `orbits` は点や名称と独立して PTH 軌跡を制御する。

軌跡は確認済み PTH の原標本を原順のまま読み、隣接する二点が投影可能なときだけ線分にする。
同時刻で異なる位置も原隣接関係を維持する。
背面、near plane の内側、非有限値や投影 overflow を挟んで線を結ばない。
各標本が画面外でも投影可能なら線分を渡し、画面境界で clip する。
全線分の配列は作らず visitor で渡す。1,024 本ごとの stroke は描画バッチの区切りであり、
後続出典や標本を切り捨てない。間引き、再標本化、原軌道への閉線分追加も行わない。
表示 OFF 時は標本を走査しない。

配色、点半径、選択リング、11 point の名称は既存 `SatelliteRenderer` と合わせた。
`RendererQualityScope` を使って点・線・文字の品質設定を適用し、context の状態を復元する。
点・リング・名称・軌跡は map の境界内へ clip する。
機体 mesh、姿勢、飛翔方向の推定はこの描画モジュールの対象外である。

## 検証

`tests/test_spacecraft_renderer.mm` はウィンドウを開かず、幾何と CGBitmap の画素を検査する。
独立した投影の手計算、重複定義、同時刻異座標、全 8 表示設定、手前優先の選択、
画面外と near plane、projection overflow、単独標本、PPI、日時・参照・位置の不整合を含む。
画素検査では点・名称・軌跡の独立表示、点 OFF 時のリング抑止、アンチエイリアス設定、
外周画素の不変、呼出側 clip の復元、1,024/1,025 線分目の描画を確認する。

Apple clang 21.0.0、C++17、`-Wall -Wextra -Wpedantic -Werror`、macOS 13.0 deployment target で
通常 ARM64、ASan/UBSan、x86_64 を個別ビルドした。

```sh
cd vendor/mitaka/native/gui
mkdir -p build-unit5-spacecraft-renderer
xcrun clang++ -std=c++17 -Wall -Wextra -Wpedantic -Werror \
  -mmacosx-version-min=13.0 -O2 -g -Iinclude -I../core/include -fobjc-arc \
  tests/test_spacecraft_renderer.mm src/SpacecraftRenderer.mm src/RendererQuality.mm \
  src/spacecraft_browser_model.mm src/solar_camera.cpp ../core/src/spacecraft_position.cpp \
  ../core/src/spacecraft_trajectory.cpp ../core/src/spacecraft_trajectory_parser.cpp \
  ../core/src/catalog.cpp ../core/src/ephemeris.cpp -framework AppKit \
  -o build-unit5-spacecraft-renderer/test_spacecraft_renderer
build-unit5-spacecraft-renderer/test_spacecraft_renderer \
  "../../../../resources/data"
```

ASan/UBSan は `-O1 -fno-omit-frame-pointer -fsanitize=address,undefined`、
x86_64 は `-O2 -arch x86_64` と専用出力ディレクトリを使用する。
通常版データでも同じ実行ファイルを実行した。
全 3 構成で Plus は **107,995 checks PASS**、通常版は **28,811 checks PASS**。
ローカルで観測した Plus 14 定義の投影可能な全 79,184 線分を走査し、通常版 13 定義からは
未確定な PPI の線分を一本も描かなかった。件数は入力から導いた結果で、固定上限ではない。

全線分 visitor の実測は ARM64 1.99542 ms、ASan/UBSan 7.71192 ms、x86_64 3.29108 ms。
この時間は投影・visitor・隣接 index の検査を含み、stroke や文字描画は含まない。
機種と負荷に依存するため合格閾値にはしていない。
原アプリ・データへの書込み、新規外部依存、実 UI ウィンドウを使う試験はない。

最終レビュー後、null CGContext を入口で拒否する guard と回帰を追加した。
有効な NSGraphicsContext が current の状態でも null 引数では名称を含めて画像を変えない。
追加後の三構成は Plus **107,996 checks PASS**、通常版 **28,812 checks PASS**。
