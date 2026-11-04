# UNIT5 policy gate 判定根拠（最終照合）

2026-10-29。対象は基点 `002adcf663fd5005e14ac86c343a3ec7e56fa706` 以後の UNIT5 作業ツリーである。修正後 full smoke 4 本、最新 fixture を含む clone の再試験、最終原本保全の通過を確認し、14 gate / 154 条件を最終照合した。判定は [実時刻の検証コピー](../../../temp_gates/2026-10-29-22-51-25/VALIDATION.md) へ記録した。テンプレートのチェック欄は変更していない。

UNIT5 は N01 小天体の表示集合と彗星軌道、N02 衛星の表示集合と瞬間楕円、N03 PTH 探査機、N04 packed 36 byte 小惑星/TNO、N05 星座集合、関連 Lua 真偽値、JSON v5 の単位である。UNIT6 の同梱監査資料は読み取り調査として区別し、製品実装には数えない。原版 Plus の未完機能が残るため、全機能互換の完了判定ではない。

## 証拠の対象と制限

- 主担当と各機能担当の実行ログ・provenance・差分を文書担当が照合した。core の独立した読み取りレビューは [core-gate-evidence.md](core-gate-evidence.md) に記録する。文書担当は統合試験を再実行していない。
- 最終 `git diff --cached --binary -- native` の SHA-256 は `3b897ca64674ad4c435d22e6e8940e96f67ec53078851c525aa947a9b3148dab`。native は 115 files / +8,359 / −372。新規 clone の初回試験と、後続 3 ファイルを同期した再試験を区別する。途中のログを最新 patch と同じソースから得たと説明しない。
- 以下の C 番号は各 gate の「判定条件」を上から数えたもの。テンプレートを数え直し、**14 gate / 154 条件**を確認した。不合格条件は別に確認する。
- 個別ログの固定コピーは [logs/](logs/) 内の担当別 `SHA256SUMS` に記録する。統合ログは主担当が [logs/integration/](logs/integration/) へ保存し、文書担当が 30 件の `SHA256SUMS` を照合した。
- 新規依存はない。core は C++17 標準ライブラリと既存 loader / Kepler / CF96 / 座標変換を使い、GUI は既存 AppKit・Core Graphics・Foundation、macOS 標準 CommonCrypto を使う。Lua 依存の条件は既存のまま。
- `/simplifier-lai` は利用可能な一覧になく、類似名 `simplify-lai` は LobbyAI 専用のため代用しない。担当間の独立レビューで依存・責務・失敗境界を確認した。

## 最終照合した実行結果

| 証跡 | 確認済み範囲と残件 |
| --- | --- |
| core 三構成 | `/tmp/mitaka-unit5-core-{normal,san,x86}-test.log` の試験成功行を確認。主担当から通常・ASan/UBSan・x86_64 の全 test exit 0 報告済み。実原本全件の個別試験とは件数を区別する。 |
| GUI 三構成 | `/tmp/mitaka-unit5-final-{normal,sanitize,x86}-all-test.log`。通常・ASan/UBSan・x86_64 の `all test` exit 0 を主担当が確認。後続 fixture 修正は最終 smoke / clone の対象と照合する。 |
| controller 三構成 | `/tmp/mitaka-unit5-final2-{normal,sanitize,x86}-controller.log`。script を含む全 controller-test が各 exit 0。これは起動した AppKit の試験であり、未実施の人手操作や CUA 操作の代わりに数えない。 |
| 実データ・公式比較 | Plus data / reference と通常版 data の成功報告。通常版最終ログは `/tmp/mitaka-unit5-final2-data-regular.log`。通常版の Plus 専用 Charon を必須とした fixture は修正後に Plus / 通常版 × 3 構成で成功した記録を区別する。 |
| 新規 local clone | `/tmp/mitaka-unit5-final-clean-{core,gui}.log` の staged native patch による `all test` は成功。後続の `AppPlusSmokeTests.mm`、`AppScriptSmokeTests.mm`、`AppScripting.mm` を同期した `/tmp/mitaka-unit5-final3-clean-gui.log` の `all test` も exit 0。最初の clone 試験と後続修正の再試験を区別する。 |
| full smoke | 最初の Plus で Lua fixture が 14,676 行 × 129 標本を要求し予算拒否。次の final2 では旧表示 fixture が全 toggle に全天図への切替を要求して失敗。製品予算を維持した fixture 修正と星座共通 setter 接続後、final3 の Plus 通常 / SAN / x86_64、通常版通常の全 4 本が exit 0。`logs/integration/final3-app-*.log` に固定保存した。 |
| 原本保全 | 最新の `/tmp/mitaka-unit5-final3-preservation.log`、`preservation-final.json` は 16,365 files / 6,622,642,667 bytes / 465 symlinks、追加・削除・変更 0。公式 ZIP 310 files と参照 checkout の不変を確認。 |
| Private | `/tmp/mitaka-unit5-final-private.log` で両リポジトリの Private を主担当が再確認済み。 |

minor の実原本全件 **253,211 checks × 3** は担当者の完了通知と [provenance](../../../native/core/MINOR_PLANET_POSITION_PROVENANCE.md) に基づく。専用の保存ログは確認できず、独立確認したログ結果とはしない。統合 core の **90,730 checks × 3** は引数なしの合成試験であり、同じものではない。PTH・軌道・GUI の個別結果は [N03/N04](spacecraft-minor-validation.md)、[N01](n01-integration-validation.md)、[軌道経路](orbit-pipeline-validation.md) を参照する。

## Gate 条件の照合

| Gate / 条件 | 判定に使う根拠 | 最終判定の境界 |
| --- | --- | --- |
| [core_architecture](../../../policy_gates/core_architecture.md) C1–C5（5） | 新 core evaluator / sampler は既存 loader の保存型を受け、標準 C++ と既存演算だけを使用する。GUI の表示集合・非同期処理とは分離し、データと診断を instance / 戻り値が所有する。[独立監査](core-gate-evidence.md)。 | 独立 core build/test と include/link の確認。新規 GUI framework を core の依存と数えない。 |
| [data_contracts](../../../policy_gates/data_contracts.md) C1–C6（6） | 固定幅 LE の元 bytes を既存 loader が保持。packed 36 / 37、PTH / PPI、TDB / legacy numeric JD を区別。有限値・型・期間・並び・source index を検証し、失敗を位置なしと診断で返す。 | physical UTC / TT / TDB を未認定の numeric JD に付与しない。PPI の既存 native km 評価は GUI 表示認定と別。 |
| [preservation](../../../policy_gates/preservation.md) C1–C7（7） | 最終 manifest / ZIP / 参照 checkout の照合、原 bytes・全行・重複保持、原本外の生成物。GUI 出力先の正規化・symlink 拒否は既存 file I/O 回帰。信頼済み Lua の副作用試験は専用一時領域。派生元の著作権・許諾・差分を provenance に保持。 | Lua の OS 権限を GUI 保存先制約や原本破壊の許可と混同しない。表示上限をロード件数制限に転用しない。 |
| [repository_management](../../../policy_gates/repository_management.md) C1–C5（5） | 共通コードは Mitaka/native、wrapper へ複製しない。Private 最終確認。原データ・旧 app・build は登録外、公式 source は `-text` と ZIP 照合。新規 clone で明示パスを利用。 | 最新 3 ファイルの clone 再試験と native stage 範囲を確認済み。UNIT6 は読取文書だけを区別。 |
| [verification](../../../policy_gates/verification.md) C1–C5（5） | Clang/Make、core の既知値・公式比較、loader 正常/異常/実原本、ASan/UBSan、README 手順と未完範囲。個別・統合・全体 smoke の範囲を分ける。 | 最新 full smoke / clone は成功。Rosetta 実行と Intel 実機、macOS 13 実機は区別。 |
| verification C6（1） | exact simplifier 不在と代用しない理由、依存再利用、独立レビューを記録。Git status と native / docs 差分を確認。 | 最終 native patch hash と差分量を確認済み。全資料の stage 後の差分量、commit/push、最終 Git 状態は主担当が確定する。 |
| [native_gui](../../../policy_gates/native_gui.md) C1–C4、C11–C14（8） | AppKit と core API、明示 data path、全件保持と表示/paging 分離、原本失敗の理由表示、座標/時系の制約、core 単独 build。N03/N04 と全 controller、data-test。 | C13 の実 GUI 操作は起動した AppKit controller と full smoke の範囲。最終 smoke は成功したが、全人手操作を済ませたとはしない。 |
| native_gui C5–C10（6） | 既存 Planet/Star/Grid 共有型と新 small-body/satellite/spacecraft 共有表示型。非表示時の描画・hit 抑止、元選択保持、探査機 points/labels/orbits 独立。星座は原略号 ID と同 ID の全図形へ適用、Sky/Horizon 共通、再 bind 診断。既存星名・grid の回帰。 | 星座表示 menu と Lua の最終共通 setter は最新 smoke 対象。raw ID の保存復元で unknown は原子拒否し、native rebind の消失除去とは区別。 |
| native_gui C15–C17（3） | Renderer 4 設定、Core Graphics 局所復元、既存 window controller の全画面実状態・遷移拒否・About。同機能の controller 回帰。 | UNIT4 の実 OS fullscreen と今回の回帰範囲を区別。全画面全環境の保証ではない。 |
| [solar_view](../../../policy_gates/solar_view.md) C1–C7（7） | CF96・月・同 source/JD の一度だけの親補正、有限 camera・near clip・pick・失敗時保持を既存モデルで再利用。新描画は同 model/snapshot を使う。 | 惑星/月の暦表標本、衛星瞬間楕円、彗星 TDB 区間、PTH 元標本を区別。全体の日時/選択/ビュー経路は最終 smoke で成功。 |
| [planet_textures](../../../policy_gates/planet_textures.md) C1–C11（11） | 既存11定義、ImageIO、容量・寸法、fallback、atomic 切替、UV・光源・物理半径の回帰。 | UNIT6 の雲・夜景・大気は今回未実装。renderer品質設定と画像内部補間を混同しない。 |
| [planet_rotation](../../../policy_gates/planet_rotation.md) C1–C10（10） | 既存公式惑星姿勢・同 JD 基底、有限/範囲、光源/UV、原本比較を core/GUI 回帰。Pluto の補正済み位置と未補正重心を区別。 | 追加衛星の瞬間軌道回転を、衛星表面・自転 GUI と説明しない。 |
| [time_playback](../../../policy_gates/time_playback.md) C1–C20（20） | 既存単調時計、速度・停止・範囲・中断、42セルと固定時差、realtime、同 JD 更新、JSON v5 を test/controller で回帰。軌道線の更新契約をテンプレートと README で一致させた。 | 開始時に固定するのは惑星/月標本。衛星瞬間楕円は各 snapshot と同 JD、彗星は指定 TDB、PTH は元標本。実 timer の全体経路は最終 smoke で成功。 |
| [moon_surface_navigation](../../../policy_gates/moon_surface_navigation.md) C1–C9（9） | 既存公式月・有効期間・ENU・物理表示・移動と一度だけの地月補正を回帰。 | 旧 Plus 月モデルとの bit 一致、追加衛星着陸は認定しない。全体月/着陸/離陸は最終 smoke で成功。 |
| [continuous_flight](../../../policy_gates/continuous_flight.md) C1–C12（12） | 既存 C++ flight の出発状態・同 JD 移動先・工程・衝突回避・中断/再開/手動制約・物理半径を回帰。 | 追加衛星・探査機への未対応飛行を成功扱いしない。全体連続飛行は最終 smoke で成功。 |
| [plus_compatibility](../../../policy_gates/plus_compatibility.md) C1–C3（3） | matrix の版・原典位置・今回の接続・残件、UNIT5 の実施者/対象/結果を記録する。 | native の新 API と未確定の旧名前指定 show/hide/isVisible を分け、原版全機能完了とはしない。 |
| plus_compatibility C4–C7（4） | 既存 trusted HTML の明示信頼、同原 bytes、main/top/file/generation、1 MiB / 64 KiB、一度 decode、信頼破棄、page JS とネットワーク遮断。policy/browser/helper 回帰。 | 独立 WebKit probe と production 試験、全 scheme 網羅を区別。今回 HTML 権限は拡張していない。 |
| plus_compatibility C8–C16（9） | io/os/package/debug の明示権限、別 helper・上限・取消、process group の限界、IPC 型検証、fresh getter/toggle、Lua 5.4.9 差異・hash固定・arch静的link・MIT同梱。新4群の真偽値とホスト拒否伝播を script/controller で回帰。 | helper 外へ離脱した処理や既発生副作用を巻き戻すとはしない。最終 App Lua fixture は全 4 本で成功し、予算拒否を伝える経路も確認した。 |
| plus_compatibility C17–C20（4） | [JSON v5 検証](session-v5-validation.md)。1 MiB、厳密型/有限範囲、canonical base64 ID、ロード済み source SHA/size、未知/重複/予算拒否を mutation 前に検査。全 model 接続後の pending 復元、失敗時保持、停止して復元。 | 星座は原略号の意味 ID で whole-source SHA 不要。クリック index/実行状態/HTML信頼は保存しない。local 1233+31 checks×3 と App full smoke を分ける。 |
| plus_compatibility C21–C22（2） | 保全対象外出力、形式/解像度/alpha・原版との差、既存 file I/O/controller、API・IPC・異常入力・取消・状態復元回帰。 | 元ファイルで副作用試験しない。未知ID拒否後の状態不変と、正常 JSON 数値往復の限定許容差を区別する。 |
| [local_plus_assets](../../../policy_gates/local_plus_assets.md) C1–C4（4） | raw/source/ordinal/重複保持。packed36 の確認済み式だけ既存 Kepler へ接続、37は非評価。JPL彗星 TDB とlegacy numeric JD を別 mode とし、同 JD snapshot、再読込の古い選択を拒否。[core監査](core-gate-evidence.md)。 | 物理時系未認定は診断に残す。成功件数で全形式の認定や入力件数制限を主張しない。 |
| local_plus_assets C5–C8（4） | 衛星の原 bytes/行/出典別登録・親検証・km/AU・一度だけの補正・同snapshot。PTH全標本・同時刻保持・二分探索/端点固定、PPI表示未認定を明記。 | 別 source を親補完へ転用しない。PPI ORIGIN だけで座標/時系を確定しない。 |
| local_plus_assets C9–C11（3） | 表示集合はsource+ordinalで原子検証、small-body元出典/satellite定義出典のbytesで継承。彗星2～4096標本と全要求524288上限、欠損を跨がない非同期世代制御。探査機は同snapshot、原軌跡全隣接標本、near/背面/不正線分拒否。 | 予算拒否を間引きや成功偽装へ変更しない。探査機の検索対象は定義の名称/出典/フィールドであり、全標本一行ずつの検索機能とは説明しない。 |
| local_plus_assets C12–C17（6） | 既存3背景画像、容量/投影cache、media未解決保持・明示選択、ImageIO/AVKit、世代取消、原本最終照合と回帰。 | 単独プレビューを原版合成機能の全再現としない。地平天の川はUNIT6監査段階。 |

## 判定後も残す事実

1. 最終 smoke と最新 clone の成功、対象 native patch hash、実行構成を照合した。途中失敗ログを後続の成功で上書きしていない。
2. 154 条件と不合格条件を実コピーで確認した。今回の変更範囲外の継続条件にも既存回帰結果を対応づけた。
3. UNIT3 の **実 OS 完全遮蔽試験は exit 1 のまま**。macOS が Visible を解除しなかったため、controlled factory の通過を OS 通知の成功と説明しない。[記録](../unit3/occlusion-environment.md)。
4. x86_64 は Rosetta 実行。Intel 実機・macOS 13 実機・原版との画素/bit一致・全配布Luaの実行は未検証として残す。
5. 元データ保持、未知形式・物理時系・PPI 表示・追加衛星表面/自転・旧名前指定 Lua 等の未完事項を matrix と一致させる。後続 UNIT6 の調査を実装済みとしない。
6. 最終 stage/commit/push と wrapper 採用は主担当が順に確定する。本記録は commit 前の検証であり、Git の最終状態や commit 成功を先取りしない。
