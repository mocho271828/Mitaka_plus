# Mitaka_plus ドキュメント

初めて使う方は、[ビルドと起動](../README.md#ビルドと起動)でアプリを開き、[GUI 操作ガイド](gui/README.md#画面の操作)で観測地点・日時・天体の選び方を確認できます。

| 調べたいこと | 資料 |
| --- | --- |
| 星図の表示、天体間の移動、画像の保存 | [GUI 操作ガイド](gui/README.md) |
| Lua でカメラ・時間・表示を操作する | [Lua ガイドと対応 API](gui/SCRIPTING.md) |
| 旧 Mitaka Plus のどの機能が使えるか | [機能対応表](compatibility/PLUS_FEATURE_MATRIX.md) |
| 天体位置の計算方法、カタログ形式 | [C++ 計算コア](core/README.md) |
| 大気や地形をどのように描画しているか | [大気の描画](gui/ATMOSPHERE_RENDERING.md)・[地形の描画](gui/TERRAIN_SURFACE_PROVENANCE.md) |
| 公式ソースの版・入手先・照合方法 | [公式ソースと参照先](sources/README.md) |
| 変更の提出、テストの実行 | [コントリビューションガイド](../CONTRIBUTING.md) |

## 天文計算と描画の仕様

| 対象 | 計算・読み込み | 描画 |
| --- | --- | --- |
| 観測地点と座標 | [観測地点の形式](core/PLACE_CATALOG_PROVENANCE.md)、[地平座標と恒星時](core/OBSERVATION_PROVENANCE.md)、[天文計算の由来](core/ASTRONOMY_PROVENANCE.md) | [座標グリッドと距離目盛](gui/GRID_PROVENANCE.md) |
| 恒星・星座・銀河 | [カタログ](core/CATALOG_PROVENANCE.md)、[追加カタログ](core/EXTENDED_CATALOG_PROVENANCE.md)、[星座絵](core/CONSTELLATION_ART_PROVENANCE.md)、[天の川の放射と吸収](core/OUR_GALAXY_RADIATIVE_PROVENANCE.md) | [恒星名と表示設定](gui/STAR_DISPLAY_PROVENANCE.md)、[明るさ](gui/STAR_BRIGHTNESS.md) |
| 惑星と月 | [暦表](core/EPHEMERIS_PROVENANCE.md)、[惑星の自転](core/ROTATION_PROVENANCE.md)、[月の位置・姿勢](core/LUNAR_PROVENANCE.md)、[食](core/ECLIPSE_PROVENANCE.md) | [食と影](gui/ECLIPSE_RENDERING.md) |
| 地形と大気 | [標高の読み込み](core/TERRAIN_PROVENANCE.md)、[大気散乱](core/ATMOSPHERE_PROVENANCE.md) | [地形面](gui/TERRAIN_SURFACE_PROVENANCE.md)、[大気](gui/ATMOSPHERE_RENDERING.md)、[地球の雲・夜景](gui/EARTH_LAYERS_PROVENANCE.md) |
| 小天体 | [小天体の記録と二体軌道](core/SMALL_BODY_PROVENANCE.md)、[小惑星・外縁天体の位置](core/MINOR_PLANET_POSITION_PROVENANCE.md) | [小天体の表示と選択](gui/README.md#小天体天の川ローカルメディア) |
| 追加衛星 | [カタログ](core/SATELLITE_CATALOG_PROVENANCE.md)、[モデルの登録順](core/SATELLITE_MODEL_PROVENANCE.md)、[相対位置](core/SATELLITE_POSITION_PROVENANCE.md)、[絶対位置](core/SATELLITE_ABSOLUTE_PROVENANCE.md)、[回転と親極](core/SATELLITE_ROTATION_PROVENANCE.md) | [衛星と瞬時軌道](gui/SATELLITE_DISPLAY.md) |
| 探査機 | [軌道標本の形式](core/SPACECRAFT_TRAJECTORY_PROVENANCE.md)、[時刻ごとの位置](core/SPACECRAFT_POSITION_PROVENANCE.md) | [探査機と軌跡](gui/SPACECRAFT_RENDERER_PROVENANCE.md) |
