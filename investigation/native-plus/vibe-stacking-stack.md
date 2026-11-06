# Mitaka Plus 優先順位別スタック計画

## 元計画と前提

- 元計画: [Mitaka Plus 優先順位別スタック実装計画](vibe-stacking-implementation-plan.md)。ユーザー指定の会話内計画「Mitaka Plus の未再現機能を優先順位順に実装する」を再立案したもの。
- 関連資料: [機能優先順位表](feature-priorities.md)、[機能対応表](../../vendor/mitaka/PLUS_FEATURE_MATRIX.md)、[実装方針](../../IMPLEMENTATION_POLICY.md)。
- 計画ゲート: 会話内で実装が指定された計画を使用。旧仕様についてはユーザーが推測を明示的に許可したため、推測は根拠と未検証事項を残す。データ許諾・認証・セキュリティ境界は推測で拡張しない。スタック各行は着手前にファイル、依存と受入を再確認し、ゲートの最終判定は主担当が行う。
- backend: `vanilla`（検出結果）。元の base: `main`、作成時 HEAD `215d9a2`。現在の未追跡ファイルは保護する。
- 本文は計画であり、記載した branch、PR、実装、検証が存在することを意味しない。

## 共通の受入・保全条件

各 ID の完全な受入条件は機能対応表を正本とする。正常・境界・異常、補間の中断/再指定、状態の保存/復元、描画と選択の一致を対象単位に応じて試験する。実データと旧 Plus の比較結果を記録し、環境・データ不足等でできない比較は未検証として残す。原本、同梱データ、旧環境を保持し、出典・使用許諾が確認できないデータや形式の意味は決めつけない。信頼済みローカル Lua および明示信頼されたローカル HTML の既存境界を維持し、起動時コード自動実行やオンライン由来への権限拡張をしない。

各単位で対象試験と `make build`、`make test`、`make data-test`、`make reference-test` を実施する。GUI 変更は `make smoke` と実画面でも確認する。該当する限定テストの対象は下表に記す。未実施は理由と影響を明記する。各単位の gate は `temp_gates/YYYY-MM-DD-HH-MM-SS/` に複写し判定を記入し、機能表と優先順位表を更新する。Git 状態・変更ファイル・差分量を確認し、300 行以上の場合は依存関係と指定 skill の利用可否を確認して原則 commit する。

第 2 単位は地球地平図の FOV と補間を実装し、5 種の全体検証と同梱 HIP 117,956 件による実画面の地平図・45° 復帰を確認した。旧 Plus との比較は未実施。極小画角の混合投影や極付近では微小な未解決線分を省略し、画素誤差は保証しない。非地球 3D 地表の FOV は未対応であり、P1-1 全体は部分実装。詳細は [FOV 設計](fov-projection-design.md) と [検証記録](../../VALIDATION.md)を参照する。

## スタック概要

次表は上から下への通常の着手順であり、各 PR の通常の parent は直前行、最初だけ `main` とする。P1-1 → P1-2 → P1-3 → P1-4 → P1-5 → P1-6 → P1-7 → P1-8 → P2 → P3 → P4 の順を守る。高い優先度の基盤と低い優先度の利用側は別単位とする。例えば 3D カメラは P1、星座線は P2、星座絵は P3 に置く。P3 の媒体メニューのうち P4 の図表・タイトルに依存する部分だけは P4 で追補し、それまでは CUSTOM-04 を部分実装として扱う。

利用許諾・データ・環境等の制約で着手または完了できない部分は、理由と未完了範囲を機能対応表と検証記録に残す。依存しない後続は優先順位の高いものから継続し、必要なら最後の利用可能な共通祖先から分岐する。その際、対象行に **本来の parent、迂回時の実 parent、保留理由、未統合依存、復帰・統合条件** を記録し、実際の依存がある変更は迂回しない。保留解除後は本来の依存を統合し、影響する検証を再実施する。表の parent は変更履歴を残した上で実態に更新する。実装可能な高優先度の作業を低優先度の都合で飛ばさない。

各行の受入はその行の実装範囲に対する判定であり、複数行にまたがる機能 ID の完了判定とは別である。機能 ID は全範囲の実装と必要な検証を満たすまで部分実装または未完了として記録し、利用不能な旧版比較等は未検証と明記する。

- 公開状態: 最初の 6 行が `submitted-now` の予定、以降は `local-only`。投稿操作そのものの承認・実行状態ではない。
- 実装状態: 第 1・第 2 単位は `implemented`、第 3 単位は `implemented`、第 4 単位は `implemented`、残りは `not-started`。既存コードがある項目も今回の受入検証は未着手という意味であり、既存機能が未実装との意味ではない。
- サイズ目安: 1 行は 1 つのレビュー理由に収め、原則 500 行前後まで。膨らむ場合は下記の再分割規則を適用する。
- 独立レビュー: 全行とも、親までの差分を前提に、その行に書いた機能と限定検証だけで判断可能かを着手時に確認する。以下の `yes*` は計画上の判定であり、実コードを調査した上で要件が満たされなければ branch を作らず行を修正する。
- 対象 seam: 対応機能の domain・描画・GUI/Lua 契約およびその回帰試験。各行に関連する境界だけを変更し、他機能の機械的変更は必要最小限に留める。
- P1-1 の 4c〜4f と、P1-4 の 37 byte 形式調査と確認済み形式の軌道、P1-5 の地表遷移と非地球地平、P1-8 の対象解決と移動・追従はそれぞれ別のレビュー理由である。着手前に各行をこの境界で子行・branch に分割し、親と後続の参照を更新する。表の番号は計画上の識別子であり、実装計画の単位番号とは対応させない。

| 順 | branch | parent | 対象 ID | レビュー理由・範囲 | 限定検証 | 公開予定 | 実装状態 | 独立レビュー |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `codex/mitaka-01-camera-zoom` | `main` | P1-1: CAM-03 | ScriptWorker / ScriptController / AppScripting と距離アニメーションを通してズーム補間を表示へ接続する | pc 単位、時間省略時 Camera.duration、線形・対数中点、非有限値・距離境界、途中再指定、太陽系・銀河の描画接続 | `submitted-now` | `implemented` | yes* |
| 2 | `codex/mitaka-02-camera-fov` | `codex/mitaka-01-camera-zoom` | P1-1: CAM-03 | 地平図の画角・補間・45°復帰を投影と選択に整合させる | 0°拒否、90°、再指定、投影・選択・モード往復 | `submitted-now` | `implemented` | yes* |
| 3 | `codex/mitaka-03-galaxy-selection` | `codex/mitaka-02-camera-fov` | P1-1: GAL-02 | OurGalaxy 描画点を出典内 ID で個別選択し、注視追従する | 群・原順、preview/complete と可視性、重複・選択順位、取消・モデル交換、透明、追従解除、実データ、旧版比較 | `submitted-now` | `implemented` | yes* |
| 4 | `codex/mitaka-04-large-scale-view` | `codex/mitaka-03-galaxy-selection` | P1-1: GAL-03 | 同梱通常版原典に基づく SDSS 銀河の分類色を preview と完成画像へ反映する | eClass 境界・無効値、原典参照色、描画画素、実データ分布 | `submitted-now` | `implemented` | yes* |
| 4b | `codex/mitaka-04b-large-scale-precision` | `codex/mitaka-04-large-scale-view` | P1-1: GAL-02, GAL-03 | 遠方天体付近の共有カメラと選択の位置精度を維持する | 実 GAL/QSO、1 AU 距離の描画・選択・pan、保存復元、太陽系帰還 | `submitted-now` | `implemented` | yes* |
| 4c | `codex/mitaka-04c-large-scale-continuity` | `codex/mitaka-04b-large-scale-precision` | P1-1: GAL-02, GAL-03 | 実データの各距離における共有視点と描画の連続性を仕上げる | 1〜10,000 AU・1〜10,000 光年・大規模構造を往復し、入力中・停止直後・完成時の背景、可視性、最新 frame、描画選択と表示復帰を確認。背景欠落は再現確認から開始 | `submitted-now` | `not-started` | yes* |
| 4d | `codex/mitaka-04d-milky-way-appearance` | `codex/mitaka-04c-large-scale-continuity` | P1-1: GAL-02 | 既存モデルの銀河系の外観と縮尺を比較・改善する | 正面・横、腕・バルジ・暗黒帯・太陽位置、移動中と完成後、性能 | `local-only` | `not-started` | yes* |
| 4e | `codex/mitaka-04e-local-group` | `codex/mitaka-04d-milky-way-appearance` | P1-1: GAL-02 | 実カタログの局部銀河群・球状星団の画像と名称を 3D 表示へ接続する | NBG/GC の明示読込、実 ID と描画・選択・Lua、重複・不明キー、点への切替 | `local-only` | `not-started` | yes* |
| 4f | `codex/mitaka-04f-survey-rendering` | `codex/mitaka-04e-local-group` | P1-1: GAL-03 | 実観測の分布を保った遠方銀河の表示詳細度とフェードを改善する | 各距離、原行と選択、観測範囲、移動時・完成時、性能 | `local-only` | `not-started` | yes* |
| 5 | `codex/mitaka-05-ground-small-bodies` | `codex/mitaka-04f-survey-rendering` | P1-2: OBJ-15 | 地上に小天体・有効な探査機を時刻連動で表示・選択する | 実データ、時刻変更、可視切替、描画選択一致、PPI の未確定記録 | `local-only` | `not-started` | yes* |
| 6 | `codex/mitaka-06-terrain-continuity` | `codex/mitaka-05-ground-small-bodies` | P1-3: OBJ-06 | 地球・火星の地形取得と連続操作を安定させる | 同一日時で視点移動、欠落と採用飢餓、実データ、旧画面比較 | `local-only` | `not-started` | yes* |
| 7 | `codex/mitaka-07-small-body-orbits` | `codex/mitaka-06-terrain-continuity` | P1-4: OBJ-09, OBJ-10 | 37 byte 原記録の隔離・調査と、根拠のある形式の小惑星・TNO 軌道描画 | 36/37 byte の区別、不正長・全原行・重複保持、37 byte の採用根拠が確認できるまで位置評価しない、36 byte の位置・選択・軌道・標本上限と実データ | `local-only` | `not-started` | yes* |
| 8 | `codex/mitaka-08-surface-transition` | `codex/mitaka-07-small-body-orbits` | P1-5: CAM-01 | 宇宙と地表の移動・モード遷移、および非地球の地平表示を接続する | 同一日時・観測地の往復、中断、投影・風景と Lua、地球・火星・月の地平表示と選択一致 | `local-only` | `not-started` | yes* |
| 9 | `codex/mitaka-09-camera-orientation` | `codex/mitaka-08-surface-transition` | P1-6: CAM-02 | 姿勢とロールの補間を全対象ビューで整合させる | 全視点、ロール、位置保持、途中再指定、銀河の Lua 実操作 | `local-only` | `not-started` | yes* |
| 10 | `codex/mitaka-10-ground-direction` | `codex/mitaka-09-camera-orientation` | P1-7: CAM-04 | 地上方位・高度の設定と補間を仕上げる | 極越え、角度境界、再指定、地球・非地球 | `local-only` | `not-started` | yes* |
| 11 | `codex/mitaka-11-target-navigation` | `codex/mitaka-10-ground-direction` | P1-8: CAM-06 | 全対象種別の名前・ID・観測地接尾辞解決と、注視・移動・追従を統合する | 名前と ID の往復、重複名・複数出典・未評価行・不明値、地上・非地球地表・宇宙での移動と中断、対象追従、Lua | `local-only` | `not-started` | yes* |
| 12 | `codex/mitaka-12-pointer-selection` | `codex/mitaka-11-target-navigation` | P2: CAM-07 | ポインターによる天体選択と座標 API を整える | 描画位置との一致、境界、選択取消、Lua | `local-only` | `not-started` | yes* |
| 13 | `codex/mitaka-13-object-menu` | `codex/mitaka-12-pointer-selection` | P2: CAM-08 | 天体の共通階層と右クリック操作を整える | 各天体種別、選択対象と操作先、重複名 | `local-only` | `not-started` | yes* |
| 14 | `codex/mitaka-14-camera-distance-mode` | `codex/mitaka-13-object-menu` | P2: CAM-09 | 移動時の距離自動調整の GUI と Lua を整合させる | 対象変更、半径不明、旧版との距離比較 | `local-only` | `not-started` | yes* |
| 15 | `codex/mitaka-15-home-navigation` | `codex/mitaka-14-camera-distance-mode` | P2: CAM-10 | 任意対象と保存ホームへの時間指定移動を実現する | 保存復元、時間省略、移動中再指定 | `local-only` | `not-started` | yes* |
| 16 | `codex/mitaka-16-surface-click` | `codex/mitaka-15-home-navigation` | P2: CAM-12 | 地表ダブルクリックによる地点移動を実現する | 球面端・極、非地球、クリックと移動先の一致 | `local-only` | `not-started` | yes* |
| 17 | `codex/mitaka-17-time-zones` | `codex/mitaka-16-surface-click` | P2: TIME-03 | 地方時と夏時間・時系の変換契約を統合する | 日付境界、夏時間切替、曖昧時刻、Lua と GUI | `local-only` | `not-started` | yes* |
| 18 | `codex/mitaka-18-time-controls` | `codex/mitaka-17-time-zones` | P2: TIME-04, TIME-05, TIME-06 | 順逆行と単位別時刻操作を一貫して評価する | 閏日・月末・年端・速度、全ビュー同一 JD、旧版比較 | `local-only` | `not-started` | yes* |
| 19 | `codex/mitaka-19-realtime-clock` | `codex/mitaka-18-time-controls` | P2: TIME-07 | 実時間追従と時計変更時の時刻制御を実現する | 時計変更、時系変換、追従開始停止 | `local-only` | `not-started` | yes* |
| 20 | `codex/mitaka-20-property-animation` | `codex/mitaka-19-realtime-clock` | P2: ANIM-01 | 時間属性の補間と番組の連続再生を実現する | 補間境界、途中中断・再指定、連続再生と時刻整合 | `local-only` | `not-started` | yes* |
| 21 | `codex/mitaka-21-atmosphere` | `codex/mitaka-20-property-animation` | P2: OBJ-03 | 地平図の利用可能な大気表示を整合させる | 大気別切替、実データ利用可否、旧画面比較 | `local-only` | `not-started` | yes* |
| 22 | `codex/mitaka-22-eclipse-sky` | `codex/mitaka-21-atmosphere` | P2: OBJ-04 | 日食時の地上の空の暗化を実現する | 食の前中後、観測地、時刻追従と旧版比較 | `local-only` | `not-started` | yes* |
| 23 | `codex/mitaka-23-display-radius` | `codex/mitaka-22-eclipse-sky` | P2: OBJ-05 | 表示半径の補間と KEEP_RADIUS を実現する | 倍率境界、連続補間、カメラ距離保持と旧版比較 | `local-only` | `not-started` | yes* |
| 24 | `codex/mitaka-24-satellite-orbits` | `codex/mitaka-23-display-radius` | P2: OBJ-07 | 衛星軌道・表面・自転の対象を拡張する | 衛星別の日時追従、物理時系と精度期間、描画選択 | `local-only` | `not-started` | yes* |
| 25 | `codex/mitaka-25-satellite-landing` | `codex/mitaka-24-satellite-orbits` | P2: CAM-11 | 衛星の離着陸モードを実現する | 複数衛星、両着陸モード、離陸と中断 | `local-only` | `not-started` | yes* |
| 26 | `codex/mitaka-26-comet-data` | `codex/mitaka-25-satellite-landing` | P2: OBJ-08 | 彗星の名前と日付契約を確認し提供範囲を整える | 古代暦・名前・同名、尾の実態とデータ根拠 | `local-only` | `not-started` | yes* |
| 27 | `codex/mitaka-27-oort-cloud` | `codex/mitaka-26-comet-data` | P2: OBJ-11 | 利用可能な根拠に基づきオールトの雲を表示する | 同梱通常版を出典とする再現可能な模式雲、1 万 AU との関係、往復と表示切替 | `local-only` | `not-started` | yes* |
| 28 | `codex/mitaka-28-spacecraft-models` | `codex/mitaka-27-oort-cloud` | P2: OBJ-12, OBJ-13 | 探査機の形状・姿勢・アニメーションを描画する | 機体別、時刻と座標系、PPI の根拠、実データ比較 | `local-only` | `not-started` | yes* |
| 29 | `codex/mitaka-29-star-labels` | `codex/mitaka-28-spacecraft-models` | P2: STAR-02 | 近傍星名と距離に応じたラベルを表示する | 実 HIP ID、距離端、選択位置、フェード、太陽系・銀河の遷移 | `local-only` | `not-started` | yes* |
| 30 | `codex/mitaka-30-constellation-3d` | `codex/mitaka-29-star-labels` | P2: CONST-01 | 星座の線・境界・名称を共有 3D 空間へ接続する | 視点距離、座標投影、切替、旧表示比較 | `local-only` | `not-started` | yes* |
| 31 | `codex/mitaka-31-drawing-performance` | `codex/mitaka-30-constellation-3d` | P2: DRAW-02 | 重い対象レイヤーの描画負荷を測定し改善する | 実データの時間・メモリ、欠落と選択一致、旧版比 | `local-only` | `not-started` | yes* |
| 32 | `codex/mitaka-32-location-edit` | `codex/mitaka-31-drawing-performance` | P2: DATA-01 | 他天体を含む地点編集・保存・着陸を実現する | 天体別位置、編集保存復元、地表着陸と Lua | `local-only` | `not-started` | yes* |
| 33 | `codex/mitaka-33-location-labels` | `codex/mitaka-32-location-edit` | P2: DATA-02 | 地点ラベルの距離条件・外観・グループを整える | 距離境界、重複、表示切替、描画位置 | `local-only` | `not-started` | yes* |
| 34 | `codex/mitaka-34-camera-display` | `codex/mitaka-33-location-labels` | P3: CAM-13 | 視点位置とヘッドライトの表示設定を実現する | 表示切替、設定復元、視点移動との同期 | `local-only` | `not-started` | yes* |
| 35 | `codex/mitaka-35-time-dialog` | `codex/mitaka-34-camera-display` | P3: TIME-02, TIME-08 | 日時の表示操作と時刻状態の独立性を検証する | 閏日・無効日、表示切替前後の JD、不一致は修正 | `local-only` | `not-started` | yes* |
| 36 | `codex/mitaka-36-planet-layers` | `codex/mitaka-35-time-dialog` | P3: OBJ-02 | 惑星の表示レイヤーを対象別に検証する | 4 レイヤーの独立切替、各対象、旧版画素 | `local-only` | `not-started` | yes* |
| 37 | `codex/mitaka-37-individual-visibility` | `codex/mitaka-36-planet-layers` | P3: OBJ-14 | 天体の個体別表示と名前指定 Lua を実現する | 一意名・同名・不明名、出典 ID、保存復元 | `local-only` | `not-started` | yes* |
| 38 | `codex/mitaka-38-star-compat` | `codex/mitaka-37-individual-visibility` | P3: STAR-03, STAR-04, STAR-05 | 恒星選択・記号・明るさの互換を検証する | HIP 往復、3D 測光と色、無効視差、連星・系外惑星、明るさ補間と旧版画素 | `local-only` | `not-started` | yes* |
| 39 | `codex/mitaka-39-constellation-art` | `codex/mitaka-38-star-compat` | P3: CONST-02 | 星座絵を宇宙空間の 3D 表示に接続する | 距離・視点、表示切替、旧版画素比較 | `local-only` | `not-started` | yes* |
| 40 | `codex/mitaka-40-constellation-api` | `codex/mitaka-39-constellation-art` | P3: CONST-03 | 星座略号による個別表示 API を実現する | 略号・未知 ID・Serpens の複数図、往復 | `local-only` | `not-started` | yes* |
| 41 | `codex/mitaka-41-milky-way-modes` | `codex/mitaka-40-constellation-api` | P3: GAL-01 | 天の川の 4 表示方式を検証する | モード、屈折・フェード、旧版画素比較 | `local-only` | `not-started` | yes* |
| 42 | `codex/mitaka-42-coordinate-grids` | `codex/mitaka-41-milky-way-modes` | P3: GRID-01, GRID-02 | 座標網と距離目盛の物理的整合を検証する | 4 座標系、極・軸、AU と光年の間隔、距離リングの色と万・億表記 | `local-only` | `not-started` | yes* |
| 43 | `codex/mitaka-43-surface-pointer` | `codex/mitaka-42-coordinate-grids` | P3: GRID-03 | 地表ポインターの両 API と描画を整合させる | 両 setter/getter、地上と宇宙、座標と表示 | `local-only` | `not-started` | yes* |
| 44 | `codex/mitaka-44-landscape-editor` | `codex/mitaka-43-surface-pointer` | P3: DATA-03 | 風景編集と他天体への適用を実現する | 編集保存、親天体、フェード、画素比較 | `local-only` | `not-started` | yes* |
| 45 | `codex/mitaka-45-external-data` | `codex/mitaka-44-landscape-editor` | P3: DATA-04 | ユーザーデータの追加・編集・再読込を実現する | 形式別読込、無効入力、編集と再読込、原本不変 | `local-only` | `not-started` | yes* |
| 46 | `codex/mitaka-46-language-switch` | `codex/mitaka-45-external-data` | P3: DATA-05 | 翻訳データの共存と言語切替を実現する | 2 言語、文字コード、未翻訳、切替と保存 | `local-only` | `not-started` | yes* |
| 47 | `codex/mitaka-47-window-layout` | `codex/mitaka-46-language-switch` | P3: UI-02, UI-06, UI-08 | ウィンドウ配置の保存と複数画面出力を整える | 全画面、再起動、画面消失、物理複数画面の同期 | `local-only` | `not-started` | yes* |
| 48 | `codex/mitaka-48-snapshot-options` | `codex/mitaka-47-window-layout` | P3: UI-03 | スナップショットの寸法・透明背景・保存操作を実現する | 形式別、寸法境界、透明、保存先と再読込 | `local-only` | `not-started` | yes* |
| 49 | `codex/mitaka-49-settings-dialog` | `codex/mitaka-48-snapshot-options` | P3: UI-04 | 描画品質・操作スタイル設定ダイアログを実現する | 全設定、検証、再起動復元 | `local-only` | `not-started` | yes* |
| 50 | `codex/mitaka-50-documentation` | `codex/mitaka-49-settings-dialog` | P3: UI-07 | 同梱マニュアルと明示された文書を開く操作を実現する | 文書不在、パス・URL、起動失敗、既存信頼境界 | `local-only` | `not-started` | yes* |
| 51 | `codex/mitaka-51-projection-control` | `codex/mitaka-50-documentation` | P3: UI-09, UI-10 | 投影フェードとポインターの制御を実現する | 補間中再指定、3 成分往復、投影のみへの反映 | `local-only` | `not-started` | yes* |
| 52 | `codex/mitaka-52-text-quality` | `codex/mitaka-51-projection-control` | P3: UI-11, RENDER-01 | テキスト・情報表示と文字品質を独立設定する | 文字倍率・ルビ・情報表示、設定復元、画素比較 | `local-only` | `not-started` | yes* |
| 53 | `codex/mitaka-53-explicit-rendering` | `codex/mitaka-52-text-quality` | P3: RENDER-02 | 明示描画と安全なフレーム出力を実現する | フレーム番号、サイズ・出力パターン境界、出力先 | `local-only` | `not-started` | yes* |
| 54 | `codex/mitaka-54-state-file` | `codex/mitaka-53-explicit-rendering` | P3: STATE-01 | 状態ファイルと State API の検証・復元を拡張する | 選択・表示の往復、不正入力で部分適用しない、Lua 信頼境界 | `local-only` | `not-started` | yes* |
| 55 | `codex/mitaka-55-memory-state` | `codex/mitaka-54-state-file` | P3: STATE-02 | メモリ内の状態保存・可否照会・復帰を実現する | 保存前後、複数操作後復元、寿命と不正状態 | `local-only` | `not-started` | yes* |
| 56 | `codex/mitaka-56-initial-state` | `codex/mitaka-55-memory-state` | P3: STATE-03 | 初期状態の保存・解除・起動時復元を実現する | 起動優先順位、欠損、非実行 JSON、自動コード実行の禁止 | `local-only` | `not-started` | yes* |
| 57 | `codex/mitaka-57-script-editor` | `codex/mitaka-56-initial-state` | P3: LUA-02 | 明示実行できるスクリプトエディタを実現する | 新規・保存・読込・実行・取消、信頼済み選択 | `local-only` | `not-started` | yes* |
| 58 | `codex/mitaka-58-script-recording` | `codex/mitaka-57-script-editor` | P3: LUA-02 | 通常操作とカメラ状態を区別して記録する | 記録と再生、途中停止、明示カメラ記録 | `local-only` | `not-started` | yes* |
| 59 | `codex/mitaka-59-script-console` | `codex/mitaka-58-script-recording` | P3: LUA-03 | 対話コンソールの入力と履歴を実現する | 式・文、履歴、位置付きエラー、失敗後の継続 | `local-only` | `not-started` | yes* |
| 60 | `codex/mitaka-60-lua-compat` | `codex/mitaka-59-script-console` | P3: LUA-04 | Lua 5.1 と固定 5.4 の互換性と必要な shim を検証する | 旧スクリプト、構文・標準関数、取消、互換性を記録 | `local-only` | `not-started` | yes* |
| 61 | `codex/mitaka-61-host-api-audit` | `codex/mitaka-60-lua-compat` | P3: LUA-01 | 各実装単位に分散した Lua API の残件を監査する | 対象別契約、別名、未対応名付きエラー、信頼境界 | `local-only` | `not-started` | yes* |
| 62 | `codex/mitaka-62-input-controls` | `codex/mitaka-61-host-api-audit` | P3: INPUT-02 | 方向入力・速度・慣性の操作 API を実現する | 開始停止、速度境界、フォーカス喪失、ヘルプ | `local-only` | `not-started` | yes* |
| 63 | `codex/mitaka-63-input-bindings` | `codex/mitaka-62-input-controls` | P3: INPUT-01 | 入力デバイスのショートカット登録を実現する | 登録・上書き・解除、反復、照会、デバイス切断 | `local-only` | `not-started` | yes* |
| 64 | `codex/mitaka-64-video-media` | `codex/mitaka-63-input-bindings` | P3: MEDIA-01 | 動画のフレーム操作と画面合成を実現する | 再生・移動・終了、選択と Lua、画面合成 | `local-only` | `not-started` | yes* |
| 65 | `codex/mitaka-65-audio-media` | `codex/mitaka-64-video-media` | P3: MEDIA-02 | 音声のフレーム操作と再生を実現する | 再生・移動・Lua、デバイス切断、実機確認 | `local-only` | `not-started` | yes* |
| 66 | `codex/mitaka-66-image-media` | `codex/mitaka-65-audio-media` | P3: MEDIA-03 | 画像の画面合成と選択操作を実現する | 先頭末尾、ルビ、選択と Lua、無効ファイル | `local-only` | `not-started` | yes* |
| 67 | `codex/mitaka-67-custom-actions` | `codex/mitaka-66-image-media` | P3: CUSTOM-01 | 動的メニューとアクション更新を実現する | 追加・更新・削除、コールバック寿命、Lua エラー | `local-only` | `not-started` | yes* |
| 68 | `codex/mitaka-68-custom-toolbar` | `codex/mitaka-67-custom-actions` | P3: CUSTOM-02 | アクション属性とツールバー編集を実現する | 属性・アイコン・ショートカット、保存復元 | `local-only` | `not-started` | yes* |
| 69 | `codex/mitaka-69-screen-menu` | `codex/mitaka-68-custom-toolbar` | P3: CUSTOM-03 | 階層型スクリーンメニューの操作と編集を実現する | 階層移動、決定取消、空項目と編集 | `local-only` | `not-started` | yes* |
| 70 | `codex/mitaka-70-media-menu` | `codex/mitaka-69-screen-menu` | P3: CUSTOM-04 | 実装済み画像・音声・動画のメニューを実現する | 媒体別選択と再生の一致、未実装チャートは未完了扱い | `local-only` | `not-started` | yes* |
| 71 | `codex/mitaka-71-display-fades` | `codex/mitaka-70-media-menu` | P4: DRAW-01 | 名称と軌道等の表示切替を時間補間する | 切替途中の反転、描画と選択の一致 | `local-only` | `not-started` | yes* |
| 72 | `codex/mitaka-72-themes` | `codex/mitaka-71-display-fades` | P4: UI-05 | 標準・黒テーマを選択できるようにする | ダイアログと選択状態の可読性、ロード失敗 | `local-only` | `not-started` | yes* |
| 73 | `codex/mitaka-73-stereoscopy` | `codex/mitaka-72-themes` | P4: RENDER-03 | 通常 Plus のアナグリフ立体視を実現する | 左右投影・視差、切替、静止画出力、旧版比較 | `local-only` | `not-started` | yes* |
| 74 | `codex/mitaka-74-browser-controls` | `codex/mitaka-73-stereoscopy` | P4: CUSTOM-05 | 既存信頼境界を保ちブラウザ操作を拡充する | ローカル信頼失効、オンライン・JS・Flash の拒否 | `local-only` | `not-started` | yes* |
| 75 | `codex/mitaka-75-scenarios` | `codex/mitaka-74-browser-controls` | P4: CUSTOM-06 | 同梱の天文シナリオを操作に接続する | 日時・場所・視点の再現、外部ページ権限 | `local-only` | `not-started` | yes* |
| 76 | `codex/mitaka-76-charts` | `codex/mitaka-75-scenarios` | P4: MEDIA-04 | 3D チャートの選択・表示を実現する | 選択と表示、空・無効データ、Lua | `local-only` | `not-started` | yes* |
| 77 | `codex/mitaka-77-titles` | `codex/mitaka-76-charts` | P4: MEDIA-05 | タイトルの選択・表示を実現する | 選択と描画、切替、Lua | `local-only` | `not-started` | yes* |
| 78 | `codex/mitaka-78-media-menu-followup` | `codex/mitaka-77-titles` | P4: CUSTOM-04 | チャートとタイトルをスクリーンメニューに接続する | 各媒体の選択と表示、先行実装との統合 | `local-only` | `not-started` | yes* |
| 79 | `codex/mitaka-79-sound-controller` | `codex/mitaka-78-media-menu-followup` | P4: MEDIA-06 | 旧版資料に基づく音声コントローラーを実現する | 既存音声制御との整合、デバイス喪失、仕様の仮定 | `local-only` | `not-started` | yes* |

## 第 1 単位の branch admission 判定

- 単一レビュー理由: **YES**。距離ズームの時間補間と表示接続に限る。FOV は第 2 単位。
- named seam: **YES**。`ScriptWorker` → `ScriptController` → `AppScripting` → カメラの距離アニメーションと表示反映。`Camera.zoom` の pc 単位を維持する。
- 独立検証: **YES**。線形・対数補間の中点と終点、距離・時間の境界と不正入力、`Camera.duration` 省略、進行中の再指定と現在位置からの継続、太陽系・銀河の描画への反映を試験し、Lua/controller と対象カメラ試験で確認する。
- 親依存の明確さ: **YES**。`main` 上の既存共有カメラとスクリプト経路を親として用いる。
- 作業都合のみの分割ではない: **YES**。距離の補間契約は投影画角の FOV 契約と独立して検証できる。

## 第 3 単位の branch admission 判定

- 単一レビュー理由: **YES**。OurGalaxy の描画点を個別に選択し、その位置へ注視・追従する。P1-1 全体の描画・縮尺や旧版比較は第 4 単位以降にも残る。
- named seam: **YES**。`OurGalaxyRenderer` の出典モデル内の群・原順 ordinal と描画条件、`GalaxyOverlay` の表示済み request・候補選択、`SolarSystemView` の選択・追従と `AppController` の情報表示。点群に名前キーはなく、位置の近さによる既存天体名の結合は行わない。
- 独立検証: **YES**。renderer と overlay の対象テストで原順・重複、preview 間引き、complete 変換・可視性、画面距離・深度の順位、無効入力、取消、画像生成失敗、透明とモデル交換を検証。太陽系 view の選択・追従解除と統合を対象テストで確認する。実データ操作と旧 Plus 比較は未実施で、全体検証は進行中。
- 親依存の明確さ: **YES**。第 2 単位までの共有カメラと既存の太陽系・銀河選択を利用する。実 branch は `codex/mitaka-03-galaxy-selection`、計画上の親は第 2 単位。
- 作業都合のみの分割ではない: **YES**。点の ID と表示に一致する選択は、大規模構造の描画・尺度の照合とは独立した機能契約である。選択は session v9 に保存しない。

## 第 4 単位の branch admission 判定

- 単一レビュー理由: **YES**。SDSS 銀河の分類ごとの色を、描画の preview と完成画像で一致させる。共有カメラの精度と距離間の表示連続性は独立する後続単位へ分離する。
- named seam: **YES**。`GalaxyRenderer` と `GalaxyOverlay` における同梱 SDSS レコードの eClass から描画色への対応。
- 独立検証: **YES**。通常 Mitaka の同梱原典を根拠に区分と色を確認し、境界値・無効値・出力画素・実データでの分類分布を検査する。旧 Plus での一致は別途検証し、推定と区別する。
- 親依存の明確さ: **YES**。第 3 単位までの描画・選択基盤を用いる。
- 作業都合のみの分割ではない: **YES**。分類色の契約はカメラの精度表現や遠距離移動の連続性から独立してレビューできる。

## 第 4b 単位の branch admission 判定

- 単一レビュー理由: **YES**。遠方の共有カメラ対象について、近距離の描画・選択・移動に必要な位置精度を保つ。
- named seam: **YES**。`SolarCamera`・`SharedCamera`・`GalaxyCameraPc` の pc 基準と AU 差分、renderer・picker・JSON v9 の対象表現。
- 独立検証: **YES**。実 GAL/QSO 各原行の 1 AU 描画画素・選択 ID・pan 往復、セッション復元、不正値、追従、Lua 中断・再指定を確認する。実画面と旧版の比較は未検証として記録する。
- 親依存の明確さ: **YES**。第 4 単位までの共有カメラと銀河表示・選択を用いる。
- 作業都合のみの分割ではない: **YES**。精度表現とその保存契約は、距離間の描画収束・表示連続性とは独立して検証できる。

## 対象ファイルと依存

- カメラ・表示: `vendor/mitaka/native/gui/src/` の `SolarSystemView.mm`、`HorizonView.mm`、`SkyView.mm`、`AppScripting*.mm` と対応する camera・projection・controller 試験。銀河の点 ID は出典と原データの順序を保持し、座標の近さだけで実在天体名を結合しない。
- 天体・時刻・地形: `AppTimeCommands.mm`、地平・太陽系 renderer、地形・小天体の data/core、各種 `test_calendar_time.cpp` と対象別試験。PPI や 37 byte 等の旧 Plus での使用が証明されない形式を既知形式と同一視しない。
- 星座・座標・風景: `ConstellationArtRenderer.mm`、`constellation_art_*`、`GridRenderer.mm`、`grid_geometry.cpp`、`distance_scales.cpp`、`HorizonLandscapeRenderer.mm` と対応試験。
- GUI・状態・Lua・メディア: `AppWindow*.mm`、`DisplayOutputController.mm`、`WindowPresentationController.mm`、`RendererQuality.mm`、`ScriptController.mm`、`ScriptWorker.mm`、`session_*.mm`、`MediaController.mm`、`media_catalog.mm` とそれぞれの `gui/tests/test_*`。利用者による編集はユーザー管理領域に置き、同梱原本を変更しない。
- `LUA-01` は各所有機能で必要な API を接続し、監査行で残件と名前付きエラーを確認する。複数ディスプレイ・デバイス喪失など物理環境が必要な確認は、未実施なら完了判定と区別する。

## レビュー枠・復旧

- レビュー枠は 6 件。親がマージされたら次の `local-only` 行を優先順に昇格し、各 PR の base を記録済みの実 parent とし、タイトルに `(Stacked PR)` を含める。PR URL と実状態を行に記録する。公開・マージは実際の権限と指示を確認して行う。
- 着手前に、単一のレビュー理由、名前付き seam、独立検証、親からの全依存、作業都合だけの分割でないことを再確認する。満たさない場合は branch を作成しない。
- 複数の独立理由や異なる優先度が混在した場合は分割し、単独検証不能な機械的変更は関連単位に統合する。親依存の変更、試験上の下位修正、またはレビュー結果があれば影響する行と親を更新してから作業する。
- vanilla では空 branch を先行作成せず、各行の実差分を親の上に作る。履歴の並べ替えや cherry-pick はユーザー変更と保全を確認してから行う。旧版比較不能、使用許諾の未確認、セキュリティ境界の判断待ちは個別に記録し、独立して進められる後続範囲を続ける。

第 1 単位の距離補間は実装・自動検証済み。実画面で Lua 実行を確認したが、操作後の表示値と旧 Plus 比較は未確認。CAM-03 全体は FOV と残る検証があるため部分実装。
