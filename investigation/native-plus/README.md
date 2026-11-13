# Mitaka Plus との互換性調査

旧 Windows 版 Mitaka Plus 1.5.4 build101013 とネイティブ版の表示・計算を比較した資料です。各測定の対象データ、観測日時、画面条件は個別の記録に記載しています。

| 対象 | 調査・比較 |
| --- | --- |
| 地表と宇宙の移動 | [地平図・地形・大気の画面測定](ground-window-validation.md)、[離陸・帰還の実測](../../verification/p5/native-window.md)、[カメラ姿勢の比較](../../verification/p6/legacy-orientation.md) |
| 軌道・小天体 | [軌道線と探査機の比較](orbit-window-validation.md)、[個別小惑星ファイルの形式](minor-planet-individual-format-audit.md)、[37 バイト形式の照合](minor-planet-37-byte-audit.md) |
| 表示と選択 | [地平図・地表の画角](fov-projection-design.md)、[近傍銀河と球状星団](galaxy-extended-shape-design.md)、[銀河系内の点の選択](our-galaxy-point-selection-design.md) |
| Lua | [旧スクリプトと Lua 5.4 の差](lua-compatibility-validation.md)、[対話コンソールの試験](lua-console-validation.md) |

機能ごとの現在の対応範囲と制限は[機能対応表](../../vendor/mitaka/PLUS_FEATURE_MATRIX.md)を参照してください。
