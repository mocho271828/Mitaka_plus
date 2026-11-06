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

- 公開状態: 最初の 6 行は draft PR として作成済み、以降は `local-only`。
  - 1: [PR #2](https://github.com/mocho271828/Mitaka_plus/pull/2)、2: [PR #3](https://github.com/mocho271828/Mitaka_plus/pull/3)、3: [PR #4](https://github.com/mocho271828/Mitaka_plus/pull/4)、4: [PR #5](https://github.com/mocho271828/Mitaka_plus/pull/5)、4b: [PR #6](https://github.com/mocho271828/Mitaka_plus/pull/6)、4c: [PR #7](https://github.com/mocho271828/Mitaka_plus/pull/7)。各 PR の base は直前の親ブランチ。
- 実装状態: `implemented` は行の範囲を実装・検証済み、`partial` は一部を実装済みで行の受入条件が残る、`in-progress` は現在統合中、`not-started` は今回の作業未着手を表す。既存コードがある項目も今回の受入検証は未着手という意味であり、既存機能が未実装との意味ではない。
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
| 4c | `codex/mitaka-04c-large-scale-continuity` | `codex/mitaka-04b-large-scale-precision` | P1-1: GAL-02, GAL-03 | 実データの各距離における共有視点と描画の連続性を仕上げる | 1〜10,000 AU・1〜10,000 光年・大規模構造を往復し、入力中・停止直後・完成時の背景、可視性、最新 frame、描画選択と表示復帰を確認。背景欠落は再現確認から開始 | `submitted-now` | `partial` | yes* |
| 4d | `codex/mitaka-04d-milky-way-appearance` | `codex/mitaka-04c-large-scale-continuity` | P1-1: GAL-02 | 既存モデルの銀河系の外観と縮尺を比較・改善する | 正面・横、腕・バルジ・暗黒帯・太陽位置、移動中と完成後、性能 | `local-only` | `partial` | yes* |
| 4e | `codex/mitaka-04e-local-group` | `codex/mitaka-04d-milky-way-appearance` | P1-1: GAL-02 | 実カタログの局部銀河群・球状星団の画像と名称を 3D 表示へ接続する | NBG/GC の明示読込、実 ID と描画・選択・Lua、重複・不明キー、点への切替 | `local-only` | `partial` | yes* |
| 4f | `codex/mitaka-04f-survey-rendering` | `codex/mitaka-04e-local-group` | P1-1: GAL-03 | 実観測の分布を保った遠方銀河の表示詳細度とフェードを改善する | 各距離、原行と選択、観測範囲、移動時・完成時、性能 | `local-only` | `partial` | yes* |
| 5 | `codex/mitaka-05-ground-small-bodies` | `codex/mitaka-04f-survey-rendering` | P1-2: OBJ-15 | 地上に小天体・有効な探査機を時刻連動で表示・選択する | 実データ、時刻変更、可視切替、描画選択一致、PPI の未確定記録 | `local-only` | `partial` | yes* |
| 6 | `codex/mitaka-06-terrain-continuity` | `codex/mitaka-05-ground-small-bodies` | P1-3: OBJ-06 | 地球・火星の地形取得と連続操作を安定させる | 同一日時で視点移動、欠落と採用飢餓、実データ、旧画面比較 | `local-only` | `partial` | yes* |
| 6b | `codex/mitaka-06b-terrain-landing` | `codex/mitaka-06-terrain-continuity` | P1-3: OBJ-06, P1-5: CAM-01 | 地表の着陸点を地形の高さに合わせ、地形変更・失敗時の視点を整合させる | 地球・火星の実データ、倍率、非同期要求の中断・再指定、欠損と不正データ | `local-only` | `partial` | yes* |
| 7a | `codex/mitaka-07a-packed37-contract` | `codex/mitaka-06b-terrain-landing` | P1-4: OBJ-09, OBJ-10 | 37 byte 原記録の利用契約を隔離し、未確認の位置を表示しない | 不正長、全原行・flag・重複保持、汎用位置評価と軌道の拒否、実データ | `local-only` | `partial` | yes* |
| 4g | `codex/mitaka-04g-sky-continuity` | `codex/mitaka-07a-packed37-contract` | P1-1: CAM-03 | 地表から宇宙へ全天背景の投影と距離フェードを接続する | 地平投影との画素比較、距離境界、実画像、操作時の処理時間 | `local-only` | `partial` | yes* |
| 6c | `codex/mitaka-06c-negative-terrain` | `codex/mitaka-04g-sky-continuity` | P1-3: OBJ-06 | 基準球より低い地形の着陸・描画・選択を揃える | 地球・火星の実データ、地形倍率、地形失敗と描画・選択の一致 | `local-only` | `partial` | yes* |
| 4h | `codex/mitaka-04h-ground-galaxy` | `codex/mitaka-06c-negative-terrain` | P1-1: GAL-02 | 全天図・地平図から明示読込した Plus 銀河へ安全に遷移する | 実データ、成功・失敗・取消・モード変更、実画面 | `local-only` | `partial` | yes* |
| 7b | `codex/mitaka-07b-small-body-orbits` | `codex/mitaka-04h-ground-galaxy` | P1-4: OBJ-09, OBJ-10 | 根拠のある 36 byte の小惑星・TNO 軌道描画と標本化 | 位置・選択・軌道・標本上限と実データ、旧版標本規則と時系の区別 | `local-only` | `partial` | yes* |
| 8 | `codex/mitaka-08-surface-transition` | `codex/mitaka-07b-small-body-orbits` | P1-5: CAM-01 | 宇宙と地表の移動・モード遷移、および非地球の地平表示を接続する | 同一日時・観測地の往復、中断、投影・風景と Lua、地球・火星・月の地平表示と選択一致 | `local-only` | `partial` | yes* |
| 9 | `codex/mitaka-09-camera-orientation` | `codex/mitaka-08-surface-transition` | P1-6: CAM-02、P1-7: CAM-04 | 姿勢とロールの補間を全対象ビューで整合させる | 全視点、ロール、位置保持、途中再指定、銀河の Lua 実操作 | `local-only` | `partial` | yes* |
| 10 | `codex/mitaka-10-ground-direction` | `codex/mitaka-09-camera-orientation` | P1-7: CAM-04 | 地上方位・高度の設定と補間を仕上げる | 極越え、角度境界、再指定、地球・非地球 | `local-only` | `partial` | yes* |
| 11 | `codex/mitaka-11-target-navigation` | `codex/mitaka-10-ground-direction` | P1-8: CAM-06 | 全対象種別の名前・ID・観測地接尾辞解決と、注視・移動・追従を統合する | 名前と ID の往復、重複名・複数出典・未評価行・不明値、地上・非地球地表・宇宙での移動と中断、対象追従、Lua | `local-only` | `partial` | yes* |
| 4i | `codex/mitaka-04i-galaxy-overlap` | `codex/mitaka-11-target-navigation` | P1-1: GAL-03 | SDSS/QSO 点の重なりで描画順と選択を揃える | preview・完成画像の異なる投影位置、点内外、取消 | `local-only` | `partial` | yes* |
| 4j | `codex/mitaka-04j-galaxy-layer-picking` | `codex/mitaka-04i-galaxy-overlap` | P1-1: GAL-02, GAL-03 | 異なる点群レイヤーの重なりで描画順を選択に反映する | HIP・天の川・SDSS、preview・完成画像、非表示 | `local-only` | `partial` | yes* |
| 8b | `codex/mitaka-08b-non-earth-sky` | `codex/mitaka-04j-galaxy-layer-picking` | P1-5: CAM-01 | 非地球 3D 地表の恒星・星座を天体姿勢と同じ視点で表示する | 火星・月、複数時刻・極・負標高・ロール、地球回帰 | `local-only` | `partial` | yes* |
| 11b | `codex/mitaka-11b-planet-places` | `codex/mitaka-08b-non-earth-sky` | P1-8: CAM-06, P2: DATA-01 | 地球・火星・月の登録地点を Lua から指定し同一天体の地表を移動する | 有効ファイルの ID、移動の再指定、他天体間の拒否、実データと Lua | `local-only` | `partial` | yes* |
| 8c | `codex/mitaka-08c-non-earth-picking` | `codex/mitaka-11b-planet-places` | P1-5: CAM-01 | 非地球 3D 地表の恒星・星座線の選択と地形遮蔽を揃える | 恒星と星座線、可視設定、地形・球面の遮蔽と描画一致 | `local-only` | `partial` | yes* |
| 8d | `codex/mitaka-08d-surface-fov` | `codex/mitaka-08c-non-earth-picking` | P1-1: CAM-03, P1-5: CAM-01 | 非地球 3D 地表の画角と Lua 操作を投影・選択に接続する | 地形・背景・恒星・星座・銀河、補間と再指定、45° 復帰 | `local-only` | `partial` | yes* |
| 4k | `codex/mitaka-04k-our-galaxy-integrated` | `codex/mitaka-08d-surface-fov` | P1-1: Galaxy picking | 天の川点群の同一レイヤー内で描画順に選択する | preview・complete の描画形状と原順 | `local-only` | `partial` | yes* |
| 5b | `codex/mitaka-05b-horizon-integrated` | `codex/mitaka-04k-our-galaxy-integrated` | P1-2: OBJ-15 | 不透明な地平風景に隠れた天体のクリック選択を抑止する | 透明・半透明・不透明、欠損、非表示、fallback と境界の描画選択 | `local-only` | `partial` | yes* |
| 5c | `codex/mitaka-horizon-occluded-pick` | `09196de` | P1-2: OBJ-15 | 地平風景に隠れた候補天体をクリック候補から除外する | 透明・半透明・不透明・補間境界、候補の重なりと順位 | `local-only` | `partial` | yes* |
| 8e | `codex/mitaka-p13-integration` | `codex/mitaka-05b-horizon-integrated` | P1-3: OBJ-06 | 基準球の外縁で画素描画と選択・遮蔽を一致させる | 内外画素・画素端クリック、既存地形選択、実データと 5 種の make | `local-only` | `implemented` | yes* |
| 8f | `codex/mitaka-surface-session-p13` | `codex/mitaka-p13-integration` | P1-1: CAM-03, P3: STATE-01 | 停止中の地表位置・姿勢と画角を状態保存と復元に接続する | JSON v9 の往復と旧状態、異常値の事前拒否、実データ、描画と地形更新 | `local-only` | `partial` | yes* |
| 7c | `codex/mitaka-p14-format-integration` | `cab9b90` | P1-4: OBJ-09, OBJ-10 | 同梱個別形式の a 指定楕円軌道を評価・描画し、既存の離心近点角による標本化と統合する | 全実データ・両形式の高離心率・大きな平均近点角・地上選択、37 byte 拒否、旧版差異 | `local-only` | `partial` | yes* |
| 12 | `codex/mitaka-12-pointer-selection` | `codex/mitaka-surface-session-p13` | P2: CAM-07 | ポインターによる天体選択と座標 API を整える | 描画位置との一致、境界、選択取消、Lua | `local-only` | `not-started` | yes* |
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

## 第 4c 単位の branch admission 判定

- 単一レビュー理由: **YES**。遠方天体の追従中に距離をまたいでも、表示要求と選択対象が現在のカメラに一致することを検証する。
- named seam: **YES**。`AppGalaxySmokeTests` の共有カメラ、銀河画像要求と対象追従の接続。
- 独立検証: **YES**。実 SDSS 天体を追従しながら 1000 AU と 1 pc を往復し、各操作後のカメラ・要求・選択 ID を確認する。実画面および描画の収束は別途判定する。
- 親依存の明確さ: **YES**。第 4b 単位の精密な共有カメラと実データ選択を利用する。
- 作業都合のみの分割ではない: **YES**。距離遷移時の追従・画面要求の整合は、精度表現や銀河の透明度の契約と独立して検証できる。

## 第 4d 単位の branch admission 判定

- 単一レビュー理由: **YES**。天の川モデルの preview と完成画像で距離に応じた透明度と選択条件を整合させる。外観比較の残りは完了扱いにしない。
- named seam: **YES**。`GalaxyOverlay` と `OurGalaxyRenderer` の表示・合成・選択条件。
- 独立検証: **YES**。透明度境界、背景との加算合成、不可視時の選択拒否を確認し、関連 renderer と実データを検証する。
- 親依存の明確さ: **YES**。第 4c 単位までの共有カメラと追従を用いる。
- 作業都合のみの分割ではない: **YES**。天の川モデルの可視性契約は遠方 SDSS の重なりや近傍銀河の識別と独立する。

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

## 第 4e 単位の branch admission 判定

- 単一レビュー理由: **YES**。近傍銀河・球状星団の原 ID、表示半径と Lua 対象の対応を正す。
- named seam: **YES**。近傍銀河カタログ、`SolarScriptTarget`、選択情報と Lua snapshot。近接座標による名称推測はしない。
- 依存: **YES**。第 4d 単位に続く。ID は現在読み込んだ出典内での一意性に限定する。
- テスト可能: **YES**。半径境界、raw ID と名前表の衝突、曖昧 ID、実データ、Lua 対象と選択を検証する。
- 作業都合のみの分割ではない: **YES**。銀河系点群の可視性とは独立したカタログ識別契約である。
- 対象外: atlas と形態コードの根拠不明の画像対応、旧 Plus との未比較部分。第 4e 全体の完成とは扱わない。

## 第 4f 単位の branch admission 判定

- 単一レビュー理由: **YES**。遠方銀河点群の描画順と、その順序に対応する選択を揃える。
- named seam: **YES**。`GalaxyOverlay` と銀河点群の投影・選択。
- 依存: **YES**。第 4e 単位までの共通視点と描画を使用する。
- 独立検証: **YES**。preview と完成後のレイヤー順、重なる点の可視性・描画順・選択を検証する。
- 作業都合のみの分割ではない: **YES**。近傍銀河の対象 ID や天の川の透明度とは別の描画と選択の契約である。
- 対象外: 同一 pixel 内の異なる投影位置、アンチエイリアス、異なるレイヤー間の完全な可視性一致。

## 第 5 単位の branch admission 判定

- 単一レビュー理由: **YES**。地球地上から見た小天体・探査機に観測地点の視差を適用する。
- named seam: **YES**。`HorizonObject` と地球観測フレームの座標変換。
- 依存: **YES**。第 4f 単位の共有カメラと描画の基盤を引き継ぐ。
- 独立検証: **YES**。実データの小天体と PTH を複数の日時・地点で独立した計算と照合し、描画・選択・注視の共通位置を検証する。
- 作業都合のみの分割ではない: **YES**。銀河の描画順とは独立した観測位置の計算契約である。
- 対象外: PPI の形式や意味の推定、地表高度・旧 Plus 実画面との一致。

## 第 6・6b 単位の branch admission 判定

- レビュー理由と対象 seam: **YES**。6 は日時更新時の physical-space 状態と地形世代の整合、6b は着陸位置の地形高さと非同期読み込みに伴う視点の整合を扱う。それぞれ SolarTerrain・地表移動・地形取得と関連する試験に限定する。
- 独立検証と依存: **YES**。6 は 5 を親に地球・火星の実データで公開世代を検証した。6b は 6 を親に、地形倍率、位置変更、失敗・中断・再指定と実データ上の高さを検証する。地形上の着陸は P1-5 にも関係するため、P1-5 の移動試験も再実行する。
- 分割理由: 地形の時刻整合と着陸高度の算出は別の不具合と独立したレビュー理由である。第 7 単位の親は第 6 単位から第 6b 単位に更新する。
- 残件: 基準球より低い地形は球面に留まるため着陸高度が過大になる。複数 LOD の最大高さを採るため、表示中の LOD より高い位置になる場合がある。旧 Plus との表示一致と手動操作の確認は未実施であり、OBJ-06 全体は部分実装のままとする。

## 第 7a・7b 単位の branch admission 判定

- レビュー理由・named seam: **YES**。7a は旧 Plus での利用が未確認の 37 byte 原記録を保持しつつ汎用位置評価を拒否する。7b は確認済み 36 byte の軌道標本と描画を改善する。
- 独立検証・依存: **YES**。それぞれ入力長、位置・軌道と実データの試験があり、7a は 6b を、7b は 7a を親とする。7a の一部と別の高優先 P1-3 負標高対応は並行調査中であり、未統合部分を残件とし、完成次第後続で取り込んで影響範囲を再検証する。
- 分割理由: 形式の契約隔離と別形式の標本化は独立した判断である。旧版利用・物理時系・標本規則を推測で同一視しない。

## 第 4g 単位の branch admission 判定

- 背景投影と操作中の解像度制御は P1-1 の連続性に関わる独立したレビュー単位とする。実装・検証を並列に進めたため、実際の親は着手済みの 7a とする。
- 近距離では既存地平背景と一致させ、3D 銀河と同じ距離範囲で暫定的にフェードする。旧 Plus の距離曲線、実画面での見え方と停止後の描画収束は未確認。

## 第 6c 単位の branch admission 判定

- 負標高の着陸、地形描画・選択と地表星空の整合は P1-3 の独立した残件である。並列実装を優先し、実際の親は 4g とする。
- 地球と火星の公式別配布データで負標高を検証する。地形待ち・失敗時の基準球内は不透明黒、地形の欠けは透明であり、雲・大気も基準球内では省略する。表示中 LOD との高さ差、手動 GUI と旧 Plus の比較は残件。
- 飛行中断 smoke では、非同期地形更新と飛行停止を独立に検査できるよう中断検査中のみ地形読み込みを退避し、その前後に実地形の専用 smoke を残す。過去の smoke 失敗の原因はログ不足のため断定しない。


### OurGalaxy 同一レイヤーの重なり（独立統合単位）

- 独立作業 branch: `codex/mitaka-04k-our-galaxy-overlap`、作業時の親: `815b362`。統合 branch: `codex/mitaka-04k-our-galaxy-integrated`、親: `a8b4a65`。
- 単一レビュー理由: **YES**。同一 OurGalaxy レイヤー内で、描画形状が重なる点の選択順を描画順に揃える。
- named seam: **YES**。`OurGalaxyRenderer` の描画形状・群と原順、および `GalaxyOverlay` の選択候補。
- 独立検証: **YES**。preview・complete の形状内外、異なる座標、群と原順、透明、非表示と実データを対象試験で確認する。
- 依存と範囲: **YES**。既存の描画・レイヤー間選択の上に限定し、追加データやライブラリは不要。
- 作業都合のみの分割ではない: **YES**。同一レイヤー内の判定は他レイヤー間の優先順位と別にレビューできる。
- 状態: `local-only`、P1-1 全体は `partial`。旧 Plus の優先順位とアンチエイリアス境界は未確認。

## 第 5b 単位の branch admission 判定

- レビュー理由・named seam: **YES**。地平風景の不透明な画素に隠れた天体のクリックを抑止し、`HorizonLandscapeRenderer` と `HorizonView` の描画・選択を揃える。
- 独立検証・依存: **YES**。独立作業の親は第 11b 単位 `815b362`、統合時の親は `a6d703a`。小天体・探査機、透明度、画像欠損・非表示・黒地 fallback と境界位置を AppKit の実ビューで確認する。
- 分割理由: 観測位置の視差や後続のポインター API とは独立した風景による選択遮蔽の契約である。
- 仮定・残件: 半透明では選択を許可し、補間のため 4×4 画素すべてが不透明の場合だけ遮蔽する。実画面の境界一致と旧 Plus 比較は未確認。OBJ-15 全体は部分実装のままとする。
## 8e: 基準球外縁の画素と選択

- 単一のレビュー理由・対象 seam: 不透明判定と基準球交差の標本点を描画画素の中心に揃える。既存の描画・選択境界とその回帰試験に閉じる。
- 独立検証・依存: **YES**。8c の遮蔽・描画に依存し、球外縁の両側における画素端クリックを単独試験できる。旧版比較と実画面操作は未実施。

- 基準球外縁修正の独立作業 `98c4f90` は親 `e5d34fc`、統合は `62bbc36` を親とする `codex/mitaka-p13-integration`。独立作業の検証と FOV を含む統合後の検証は `VALIDATION.md` で区別する。
- 共有 checkout への統合は、地平風景の選択遮蔽を含む `a5be624` を親とする `codex/mitaka-06d-surface-edge-integrated`。隔離統合 smoke の初回失敗・再試行と共有 checkout の検証結果も `VALIDATION.md` に記録する。


## 第 8f 単位の branch admission 判定

- レビュー理由と seam: **YES**。地表の停止状態を JSON v9 と地表 navigation の境界で保存・復元し、画角も保存する。
- 依存と検証: **YES**。独立作業では第 8d の FOV (`a8b4a65`) を親とし、最初の統合では `62bbc36`、P1-3 との統合では `a82fd3a` を親とする。前段の FOV は共通祖先に含まれ、旧 v9、正負の地形高さ、不正値の事前拒否、アプリ上の復元を確認する。
- 分割理由: 地表投影と独立した保存契約であり、既存の JSON と地表操作を繋ぐ単一の検証可能な単位である。P3 の State API 全体は未対応のままとする。旧版比較と飛行途中の復元は対象外。
## 第 5c 単位の branch admission 判定

- レビュー理由・named seam: **YES**。地平風景の候補中心の遮蔽を `HorizonView` の既存の選択順位判定に反映する。
- 独立検証・依存: **YES**。第 5b の風景判定を使い、透明点と不透明な候補、可視候補との重なりと順位を AppKit 実ビューで検証する。親は `09196de`。
- 仮定・残件: 補間時は 4×4 画素すべてが不透明なときだけ遮蔽とし、半透明は選択を許す。候補の中心が遮蔽されていれば記号の一部が見える場合も選択しない。実画面の境界一致・旧 Plus 比較は未確認。OBJ-15 は部分実装。

## P1-8 地表星座の Lua 読み戻し

- レビュー理由と seam: **YES**。3D 地表で選択された星座の出典内の一意な略号または英語名を `Camera.target` snapshot に接続する。既存の `Camera:look` と同じ星座一覧を使う。
- 独立検証と依存: **YES**。基点 `35a32c7` の地表星座選択と Lua 注視を前提とする。選択、注視と対象切替を対象試験で確認する。
- 分割理由: 地表上の既存の選択を Lua に伝える変更であり、姿勢・地形遮蔽と独立する。
- 制約: 星座の `Camera.target` setter と `setTargetTo` は未対応であり、相互変換とは扱わない。旧 Plus との比較および実画面操作は未検証。


## P1-6 Lua 姿勢と銀河フレームの branch admission 判定

- レビュー理由と seam: **YES**。`Camera:getOrient` の取得で四元数を float に丸めず、Lua と共有カメラの姿勢境界を検証する。
- 依存と検証: **YES**。親は `f27914c`。実 Lua helper・AppController を通し、姿勢アニメーションを中断して即時再指定した後の取得精度と表示済み銀河フレームを確認する。
- 分割理由: 地形や画像データに依存せず、姿勢の取得・描画への伝播を独立にレビューできる。旧 Plus との比較、手動実画面、独立した銀河ブラウザの操作は対象外。


## P1-2 地球の回転楕円体上の観測位置

- レビュー理由・named seam: **YES**。小天体・PTH 探査機の測心座標で使う地球観測位置を、既存赤道半径と WGS84 扁平率の回転楕円体に限定して更新し、描画・選択・注視で共用する。
- 依存と独立検証: **YES**。基点 `a862f53`。極・赤道・中緯度・不正値、独立した座標式、実データの地点・日時別照合と地平ビュー上の描画・選択・注視を検証する。
- 分割理由・残件: 球面視差の改善は風景遮蔽や PPI 解釈と独立する。緯度は測地緯度、標高 0 と仮定し、地平描画と地形の基準形状は球面のまま。旧 Plus の精度と地上表示との一致は未確認。OBJ-15 は部分実装。

### ポインター選択モード（独立統合単位）

- 元 branch: `codex/mitaka-13-target-selection-mode`、作業時の親: `815b362`。統合基点: `a862f53`。
- 単一レビュー理由: **YES**。Lua の選択モードを 3 画面のポインター操作へ反映する。
- named seam: **YES**。`Targets.selectMode` の Lua・IPC と各 view の選択イベント。
- 独立検証: **YES**。値の往復と無効入力、クリックとホバー、非同期選択の失効を確認する。
- 依存と範囲: **YES**。AppKit と既存 Lua helper を利用し、新規ライブラリは不要。
- 作業都合のみの分割ではない: **YES**。座標 API は含めない。統合後は地表 3D の選択にも反映する。
- 状態: `local-only`、CAM-07 は `partial`。座標 API と旧版比較は残る。
