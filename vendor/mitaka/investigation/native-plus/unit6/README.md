# 単位 6 の検証記録

基点は単位 5 の `5dd3409f8c551ff94666d84f4504f6f92f7047c7`。対象は手元の Mitaka Plus 1.5.4 build101013 と通常版のデータである。独自追加を含む原本を優先し、公開データでの置換、件数合わせ、原本への書込みを行わない。

この単位は地平図の背景、観測地点の読込規則、地球の雲・夜景、星座絵、恒星名の選択と明るさ、大気の計算と表示を接続する。下表の範囲を検証したもので、旧 Plus 全機能の完了判定ではない。

| 対象 | 実装と根拠 | 残る範囲 |
| --- | --- | --- |
| N06 地平図の天の川 | [原典契約](horizon-milkyway-contracts.md)、[検証](n06-horizon-background-validation.md)。全天図と共通のモードを同じ JD・観測地で変換する。Plus の 3 画像、通常版の赤外線画像と欠損診断を確認。 | Plus 原版の全画素一致、地上景観との合成。 |
| N07 観測地点 | [原版の選択規則](places-binary-contracts.md)、[ログ](logs/n07/README.md)。日本語ファイルを優先し、user の存在時は単独採用、不存在時だけ default を採用する。全4出典を保持し、既知の完全 ID だけを後勝ち・初出位置維持で一覧化する。 | 地上ラベル、風景画像、地球以外の地点への適用。 |
| N08 地球の雲・夜景 | [実装の由来](../../../native/gui/EARTH_LAYERS_PROVENANCE.md)、[接続](earth-layer-interface.md)。独立したローカル画像、10 km の雲殻、距離依存の夜景、深度と合成順を実装。 | 旧 OpenGL の画素一致、画像以外の地形。 |
| N09 CAB 星座絵 | [契約](constellation-art-star-selection-contracts.md)、[検証](n09-n10-validation.md)。89 件の全点・全 index を保持して、全天図・地平図の共通表示集合に接続。 | 3D での星座絵、旧 OpenGL の描画一致。 |
| N10 恒星名の選択 | 同 [契約](constellation-art-star-selection-contracts.md)、[ブラウザ検証](n10-catalog-browser-validation.md)。名称表の HIP で保持し、検索と独立した全選択、名称 master と選択済みのみのフィルタ、再読込の継承を実装。 | 原版全起動処理との一致。Lua の未知 HIP 無視と native の厳密拒否は意図して区別。 |
| N11 恒星の明るさ | [契約](star-brightness-fade-contracts.md)、[実装](../../../native/gui/STAR_BRIGHTNESS.md)。正の有限 float と半余弦補間、明・暗・既定操作を共通状態へ接続。 | 3D の `fadeLabels`、原版の点描画との画素一致。 |
| N12 大気 | [数値の由来](../../../native/core/ATMOSPHERE_PROVENANCE.md)、[描画](../../../native/gui/ATMOSPHERE_RENDERING.md)、[参照比較](n12-reference-audit.md)。地球の単一・emmap 多重散乱、火星の単一散乱を物理球へ接続。 | 地平図・模式球の大気、食と大気の相互作用、旧 Plus 全モード一致。 |
| Lua・状態保存 | [スクリプト契約](../../../native/gui/SCRIPTING.md)、[Session v6](session-v6-validation.md)。上記の設定・選択集合を共通 getter/setter と JSON v6 に接続。 | 旧開発版 JSON v1〜v5 は暗黙変換しない。未対応 Lua は明示エラーを維持。 |

新しい外部依存は追加していない。純 C++17 の計算と loader、AppKit / Core Graphics / ImageIO / Foundation、既存の Lua helper を用いる。独立した読取レビューで、数値と描画の境界、原 bytes の保持、既存の画像読込・選択集合・状態保存の再利用を確認した。正確な名称の `/simplifier-lai` は利用できず、類似名 `simplify-lai` は LobbyAI 専用のため代用しない。

## 統合検証

実施環境は macOS 26.6.2 / Apple Silicon。通常、ASan/UBSan、x86_64（Rosetta）のコア・GUI 全単体試験と、Lua を含むコントローラ試験が成功した。Plus 原本の実アプリ試験は3構成、通常版原本は通常構成で成功した。Session v6 の原子的拒否、メニューの実操作、再生・飛行まで確認した。単位5の新規 local clone に今回の native 差分を適用し、既存ビルド生成物なしのコア・GUI all test も成功した。統合ログとコマンドは [logs/integration](logs/integration/) に保存する。各担当の比較・境界値試験は上表から辿れる。

ローカルデータの試験は Plus と通常版で成功した。CF96 の公式比較は 5,427 成分、最大位置差 7.10543e-14 AU、最大速度差 6.93889e-18 AU/day。自転 33,129、月 12,108 checks も成功した。大気の公式比較、原版 CAB と明るさの静的監査は担当別の記録に分けている。

途中失敗も別ログで保持する。最初の全体 smoke はメニューの期待が旧項目数のままだったため失敗し、新項目の実操作・checkmark・状態保持を検査する fixture へ更新した。最初の core 実データバッチは `CF96_DATA` の指定漏れで参照比較だけ停止し、明示パスを指定した再試験が成功した。製品の容量上限や原データを変更して解決していない。

原本保全検査では 16,365 files / 6,622,642,667 bytes / 465 symlinks に追加・削除・変更がなく、公式 ZIP の 310 ファイルも一致した。Private の共通リポジトリへコード・検証記録のみを登録する。

Intel 実機、macOS 13 実機、複数画面、実 OS の完全遮蔽通知、旧 Windows Plus の全画素一致は未確認である。Rosetta の成功を Intel 実機試験と扱わない。食、半径、地形、銀河の 3D 表示を含む次単位の調査・未接続コードは、この単位の実装済み範囲に含めない。
