# 単位7 統合検証

実施者: root。2026-10-30 JST、基点 `d1c361a750b2a1d71d71c423194954c4eade7a81` に対する単位7の作業ツリー。実装ファイルは `native-artifacts.sha256`、記録は `SHA256SUMS` で固定する。同時作業中の単位8ファイルはビルド・検証・commit 対象に含めない。

## 実行結果

| 検証 | 対象とログ | 結果 |
| --- | --- | --- |
| core 全試験・公式比較 | `core-{normal,san,x86}.log`。CF96、rotation、lunar、atmosphere、eclipse の参照比較を含む | 3構成 PASS |
| GUI 全試験 | `gui-{normal,san,x86}-final.log` | 3構成 PASS |
| AppKit controller / HTML | `controllers-{normal,san,x86}.log` | 3構成 PASS |
| Plus 実アプリ | `smoke-plus-{normal,san,x86}-final.log` | 3構成 PASS |
| 通常版実アプリ | `smoke-regular-normal-final.log` | arm64 通常 PASS |
| core/GUI 実データ | `{core,gui}-data-{plus,regular}.log` | arm64 通常 PASS |
| 新規 clone | `fresh-core.log`、`fresh-gui.log`、`fresh-gui-final.log` | core/GUI 全試験 PASS |
| 原本保全・Private | `preservation.log`、`private-repositories.jsonl` | 差分なし・両リポジトリ Private |

normal は arm64、san は arm64 AddressSanitizer/UndefinedBehaviorSanitizer、x86 は x86_64 を Rosetta で実行した。window を生成する試験と実アプリは root が直列実行した。controlled transition / controlled occlusion と記録された試験は状態遷移の注入試験であり、実 OS の全画面遷移を全条件で確認したという意味ではない。

代表結果は食の表面1021・表示92・円錐28293・scene21、風景2592（実データ2611）、地平背景461593、Plus time167・PlaybackClock10146、Session1595+836 checks。公式食計算7993比較の最大絶対差は `1.63202784619898e-14`。食は物理半径・同一JDを使い、衛星マークを非表示にしても食用のsnapshotを保持する。4食設定、風景、時間設定、原地点IDの保存・復元と不正入力拒否を検証した。

実アプリでは Lua、状態復元、時刻・観測地、表示30項目、3大気モード、明るさ、名称選択、描画品質、画像出力、太陽系視点、位置・自転の日時更新、実タイマー、月面と連続飛行を確認した。Plusの小天体は18出典19475行、衛星は32出典340行を保持する。通常版で存在しない追加データは別版から補完しない。

## 修正と再検証

初回失敗も削除せず保存した。`initial-core-*-missing-env.log` は CF96_DATA の指定漏れで、同じローカル原本を明示して3構成を再実行した。`initial-gui-normal-missing-scene-date.log` はsceneへのJD受渡し不足を検出したもので、SolarSystemViewが保持する観測JDをsceneへ渡し、smokeに検証を加えた。`initial-gui-normal-fallback-fixture.log` は影が有効なfixtureで旧ベクタ表示経路を期待した試験で、対象試験の食設定を明示した。画像欠損時の食は別の試験で確認する。

半影の最終監査では、二面のalphaと天体による生成線の終端clipを修正した。薄い物理円錐が121pxの遠い試験視点ではsubpixelになるため、scene fixtureを地球・月へ近づけた。半径は誇張していない。最終修正後は GUI 全試験3構成、Plus smoke3構成、通常版smoke、新規cloneのGUI全試験を再実行した。担当別の根拠と局所ログは `../n13-rendering/`（GUI）・`../n13/`（core）と単位7の契約文書に残す。

新規cloneは `/tmp/mitaka-unit7-fresh-20261030`。基点の追跡差分に加え `fresh-new-native-files.txt` の50ファイルを適用した。`fresh-patch-sha256.txt` は最初の差分のハッシュであり、最終半影修正前である。その後 `eclipse_cone_renderer.hpp/.cpp`、`test_eclipse_cone_renderer.cpp`、`test_eclipse_scene.mm` の4ファイルを現在の検証対象からコピーし、`fresh-gui-final.log` の全試験を実行した。

## commit 前レビュー

外部依存の追加はない。数式・バイナリ形式のためのC++17 coreと、既存AppKit/Foundation/Core Graphics/ImageIO/Lua境界を再利用した。独自の画像decoderやLua実行系は追加していない。画像はImageIO前に完全性を検証する。時間操作はtyped state、地点は原bytes ID、描画と食はimmutable snapshotで境界を明示した。

正確な名称の `/simplifier-lai` は利用不可。類似名 `simplify-lai` はLobbyAI専用で非対象リポジトリへの適用を禁止しているため実行していない。代わりに担当間レビューとrootによる全差分レビューで、原本保全、既存依存の利用、日時整合、無効入力の原子的拒否、状態復元時の停止、ソースとGUIの責務分離を確認した。特に半影の幾何・時間stepの契約・地形の限定読込・銀河の単位/全件保持を独立に照合した。

全14 policy gateは `temp_gates/2026-10-30-02-00-26/` の検証コピーと同ディレクトリの検証根拠に記録する。未完成の3D地形・銀河、地上の食暗化、旧Plus全API・全操作を完了扱いしない。機能ごとの残項目は `PLUS_FEATURE_MATRIX.md` に保持する。
