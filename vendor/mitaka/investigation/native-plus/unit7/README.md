# 単位 7 の実装・検証記録

基点は単位 6 の `d1c361a750b2a1d71d71c423194954c4eade7a81`。対象は手元の Mitaka Plus 1.5.4 build101013 と通常版の原本である。独自追加を含むデータを優先し、公開データによる置換や別エディションからの暗黙の補完は行わない。

この単位では風景画像、食と影、旧 Plus の時間操作を GUI・Lua・状態保存へ接続する。地形・銀河のデータ読込と計算も追加するが、これらの 3D 描画は後続の別単位である。旧 Plus 全機能の完了を示すものではない。

| 対象 | この単位の範囲と根拠 | 残る範囲 |
| --- | --- | --- |
| N07 地点と風景 | [実効モデル](places-display-contracts.md)、[画像・投影・実行時契約](earth-landscape-runtime-contracts.md)。採用済み地点出典から、選択地点→地球既定→全体既定の順で風景定義を解決する。画像の失敗を別定義で隠さず、原 ID と観測地を照合する。地平図の投影、表示メニュー、`Places.landscape` を接続。 | [地点ラベル](label-runtime-audit.md)、地球以外の地点、地点編集。 |
| N13 食と影 | [計算契約](n13-eclipse-contracts.md)、[最終描画契約](n13-plus-display-contracts.md)、[GUI描画](../../../native/gui/ECLIPSE_RENDERING.md)、[計算の由来](../../../native/core/ECLIPSE_PROVENANCE.md)。物理半径・同一時刻の幾何、表面減光、境界と円錐を独立設定で扱う。 | 地上の暗化、大気との相互作用、旧 OpenGL の画素一致。 |
| N15 地形 | [計算の由来](../../../native/core/TERRAIN_PROVENANCE.md)、[倍率監査](terrain-amplification-audit.md)。原本を読み取り専用で開き、索引と要求範囲だけを読み込む。通常版の4原本を検証し、Plus にない地形を補完しない。 | [描画設計](terrain-rendering-design.md) に記載した表面・深度・大気・雲への接続。 |
| N16 銀河・星団 | [原典契約](n16-galaxy-catalog-contracts.md)、[コア検証](n16-galaxy-core-validation.md)、[SDSS 検証](n16-sdss-spatial-validation.md)。原 bytes、行順、重複と診断を保持し、確定した parsec の変換だけを使用する。 | [接続案](n16-parsec-rendering-seam.md) に記載した3D描画・カメラ・選択。 |
| N23 時間操作 | [原典監査と検証](n23-time-contract-audit.md)。`Time.step` の12列挙値、日単位の `stepValue`、int32 の `speed`、暦の単発移動と連続再生を分離。原版の月末繰越しと新 GUI の月末 clamp は別契約。 | local/timezone の初期化契約、日時文字列、時間付き補間。 |
| Lua・状態保存 | [スクリプト契約](../../../native/gui/SCRIPTING.md)。食4項目・風景・時間状態を接続し、Session v7 に保存する。地点の原 ID と座標を検証し、復元時は再生を停止する。 | 旧開発版 v1〜v6 の暗黙変換、旧 `State` の Lua 形式。 |

新しい外部依存は追加していない。C++17、AppKit / Foundation / Core Graphics / ImageIO と既存 Lua helper を使う。正確な名称の `/simplifier-lai` は利用できず、類似名 `simplify-lai` は LobbyAI 専用のため代用しない。commit 前に依存・責務分離・異常系・原本保全を手動でレビューする。

## 検証状態

担当別の数値比較・実データ・境界値試験に加え、root による統合検証を完了した。詳細と失敗後の修正は [統合記録](logs/integration/README.md)、再現手順は [commands.sh](logs/integration/commands.sh) を参照する。

- arm64 通常、arm64 ASan/UBSan、x86_64（Rosetta 実行）の core/GUI ビルド・全単体試験、公式計算比較、controller/HTML 試験: PASS。
- Plus 原本での実 AppKit smoke: 3構成とも PASS。通常版原本: arm64 通常で PASS。ウィンドウ試験は直列に実行した。
- 別 clone に単位7のソース差分と新規50ファイルだけを適用した core/GUI ビルド・単体試験: PASS。最終の半影修正4ファイルをコピー後、GUI 全試験も再実行して PASS。
- Plus/通常版の実データ、風景、地形・銀河の個別試験と原本不変性を確認した。3D地形・銀河は本単位の実装済み範囲に含めない。
