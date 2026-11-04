# UNIT4 policy gate 検証根拠の照合表

確認日: 2026-10-29。下書きとして作成した本ファイルを、最終結果に合わせて確定した。判定そのものは [検証コピー](../../../temp_gates/2026-10-29-21-28-30/VALIDATION.md) に記録し、14 gate・147 条件をすべて YES とした。テンプレートは判定済みへ書き換えない。通常・SAN・x86_64 の全体 Plus smoke、新規 local clone、最終保全の成功をログと照合した。単位4の範囲に限る判定であり、原版の全機能完成を意味しない。

## 対象と証拠の時点

- 基準 HEAD: `cf4fcbfe5447adf554e5bca0b0caf5ae5f529505`。
- 最終文書・ログ・検証コピーを追加する前の staged UNIT4: **129 files、+9,954 / −200**。`git diff --cached --binary -- native/` の SHA-256 は `c0f58570a21b6483508a0306bb63adeee2ef6c26ee5fb62a59ae53f181a2df05`。
- 新規 clone に適用した全 staged patch の SHA-256 は `70c0aef245940ddd420a9bf389edd689eb25589189cabc001f0f350d2c448092`。native 限定 hash とは対象を区別する。
- `unit5/`、未追跡の探査機位置・GUI、小天体軌道線の追加ファイルは対象外。UNIT4 内の監査が後続契約を記載していても、未接続のコードを今回の実装として数えない。
- 実行担当は主担当と各機能担当。文書担当がログ、由来文書、差分を照合し、core / data / preservation / repository の 4 gate は別担当による読み取りレビューも行った。読み取りレビューでは追加の必須修正所見はなかった。
- 既存ログは実行当時の結果であり、全ログが上記 patch hash と同じソースから生成されたことを主張しない。最終統合ログと個別試験・途中の失敗ログを区別する。後続の共有ソース変更がある場合は、対象と再試験を追記する。
- 14 gate の判定条件は **147 件**。以下の C 番号は各テンプレートの「判定条件」を上から数えた番号で、不合格条件とは区別する。別担当の読み取り確認では、147 条件の範囲に欠落・二重被覆・範囲外はいずれも 0 だった。

## 共通の実行証拠

| 証拠 | 照合した結果と限界 |
| --- | --- |
| [GUI 通常](logs/mitaka-unit4-final-normal.log)、[SAN](logs/mitaka-unit4-final-san.log)、[x86_64](logs/mitaka-unit4-final-x86.log) | 各構成の全 `test` 成功。session 964、file I/O 51、calendar 333、playback clock 10,134 checks など。ログの個別 check 数は固定した公開データ件数ではない。 |
| [core SAN](logs/mitaka-unit4-core-full-san.log)、[月 fixture 修正後の core x86_64](logs/mitaka-unit4-lunar-profile-x86-all.log) | 全 core 試験成功。追加回帰を後から含む衛星絶対位置等の個別結果は各 provenance と専用ログを併記する。途中の古い check 数を最終件数と混同しない。 |
| [script 通常](logs/mitaka-unit4-script-normal-final.log)、[SAN](logs/mitaka-unit4-script-san-final.log)、[x86_64](logs/mitaka-unit4-script-x86-final.log) | それぞれの host / helper 構成で `script-test` 成功。個別 HTML 試験が通常 arm64 helper を共用した事実とは分ける。 |
| [controller 通常](logs/mitaka-unit4-controller-normal-final.log)、[SAN](logs/mitaka-unit4-controller-san-final.log)、[x86_64](logs/mitaka-unit4-controller-x86-final.log) | 逐次実行した最終 `controller-test` が全構成 exit 0。衛星一覧 38、太陽系衛星 99、表示出力の制御 fixture 46、window 状態 31 checks 等。 |
| [公式比較](logs/mitaka-unit4-core-reference-normal.log)、[Plus data](logs/mitaka-unit4-data-plus-final.log)、[通常版 data](logs/mitaka-unit4-data-regular-final.log) | 通常構成の実データ・公式原本比較成功。未解決行・任意ファイル欠損を正常な空データへ変換しない。 |
| [通常 Plus 全体 smoke](logs/mitaka-unit4-timer-boundary-normal-smoke.log)、[SAN](logs/mitaka-unit4-timer-boundary-san-smoke.log)、[x86_64](logs/mitaka-unit4-timer-boundary-x86-smoke.log)、[通常版 全体 smoke](logs/mitaka-unit4-app-regular-normal-final.log) | Plus は試験開始境界の修正後に 3 構成で全段階 exit 0。通常版は修正前の通常構成で exit 0。起動した AppKit アプリ内の操作経路・描画・読込・再生・月・飛行を検証。すべての人手操作や CUA 操作を行ったという意味ではない。 |
| [SAN 全体 smoke の固定した失敗ログ](logs/mitaka-unit4-app-plus-san-timer-failed.log)、[診断と修正](playback-smoke-validation.md) | `real timer did not advance before pause`、make exit 2 を保存。同じ変更前 binary の単独実行でも再現したが、その後の成功もあり非決定的だった。同期処理の後片付けを再生時間に含める試験構造を改め、次の callback で試験を開始した。製品時計・中断規則・250 ms 進行検査・pause 後 120 ms 不変検査は変更せず、失敗時 tick の具体的な原因は断定しない。 |
| [clean export](logs/mitaka-unit4-clean.log) | staged index を `/tmp/mitaka-unit4-clean.yPCkNr` に展開した core / GUI の `all test` が exit 0。Git の新規 clone と同じ作業であるとは記載しない。開始境界の fixture 修正前の結果。 |
| [新規 local clone](logs/mitaka-unit4-clone.log) | `git clone --no-hardlinks` で作成した `/tmp/mitaka-unit4-clone.YwTjHl` に最終 staged patch を適用し、core / GUI `all test` が成功。開始境界の fixture 修正を含む。 |
| [最終保全](logs/mitaka-unit4-preservation-final.log) | `2026-10-29T12:20:50.290384Z` 時点で 16,365 files / 6,622,642,667 bytes / 465 symlinks、変更 0。公式 ZIP 310 files の不一致 0、参照 checkout の HEAD / status 一致。 |

ログの固定コピーとハッシュは [SHA256SUMS](logs/SHA256SUMS) に保持する。失敗ログは後続の成功で上書きしない。

## Gate ごとの照合

| Gate / 条件 | 実装・確認の根拠 | 最終判定時の留意点 |
| --- | --- | --- |
| [core_architecture](../../../policy_gates/core_architecture.md) C1–C5（5 件） | `native/core` の C++17 header / source と `native/gui` の Objective-C++ を分離。core の静的ライブラリ・単体試験は標準ライブラリのみでリンク。既存 CF96 / Kepler / Trajectory / 座標変換を再利用し、各 satellite / spacecraft provenance に記録。パスは呼出側から渡し、データと評価状態はインスタンス内に所有。 | 新規 WebKit / CommonCrypto 利用は GUI 層に限る。Lua は既存 helper だけへ静的リンク。独立 core build / test の成功を上表で確認。 |
| [data_contracts](../../../policy_gates/data_contracts.md) C1–C6（6 件） | PTH / PPI は固定幅 little-endian を明示。読み取り量・件数・有限値・時刻順・不完全入力を検査。原 bytes・重複・未解決行を保持。衛星の絶対位置は明示 binding・同一数値 JD・CF96 範囲を要求。[衛星絶対位置](../../../native/core/SATELLITE_ABSOLUTE_PROVENANCE.md)、[探査機保持](../../../native/core/SPACECRAFT_TRAJECTORY_PROVENANCE.md)。 | PTH は UNIT4 では位置なし。PPI は既存 native km 補間であり、未確定の原点・面・物理時系を消して GUI へ渡さない。 |
| [preservation](../../../policy_gates/preservation.md) C1–C4、C7（5 件） | 保全 manifest、ZIP 照合、参照 checkout の不変性。原 bytes、原記録順、重複を保持し、読み取り専用。新規コード・生成物・試験一時ファイルは保全対象外。派生元・定数・差分・許諾は provenance に記載。 | loader の出典ファイルを決定的に列挙する順序と、ファイル内の原記録順を区別する。出典の列挙を、原記録の並べ替え・統合とは扱わない。保全結果の採取時点を明示。 |
| preservation C5–C6（2 件） | GUI file I/O 51 checks、正規化・symlink 解決後の出力拒否。Lua 標準ライブラリの権限を UI / SCRIPTING に明示。I/O / OS 試験は専用一時領域。HTML の明示信頼は原データを破壊する試験の許可として使わない。 | 信頼済み Lua の OS 権限と、GUI の画像・状態保存先制約を混同しない。 |
| [repository_management](../../../policy_gates/repository_management.md) C1、C3–C4（3 件） | 共通実装は `Mitaka/native`。staged 対象はソース・文書・設定で、元のデータ・画像・旧アプリ・生成物を含まない。公式ソースは `.gitattributes` の `/sources/official/** -text` と ZIP 照合で保持。 | UNIT5 の未追跡ファイルと wrapper の採用準備を、この UNIT4 index に含めない。 |
| repository_management C2、C5（2 件） | 主担当が `gh repo view --json visibility,nameWithOwner` により `PRIVATE` を最終確認し、[結果](logs/mitaka-unit4-private-final.log) を保存。新規 local clone と明示パスによる実データ参照を clone / data / reference 試験で確認。 | 新規 clone に timer fixture 修正を含む staged patch を適用し core / GUI `all test` が成功。修正前の index export と別のログで記録している。 |
| [verification](../../../policy_gates/verification.md) C1–C5（5 件） | Apple Clang / Make の static core、既知値・不変量・公式比較、正常 / 不完全 / 異常入力と実データ、3 構成の test / script / controller、README の再現手順・残件を照合。 | 修正後の全体 Plus smoke は 3 構成で成功。歴史的な SAN 失敗と診断を残し、製品時計の修正や全負荷での保証とは記載しない。 |
| verification C6（1 件） | この記事に基準 HEAD、staged files / 行数、native patch hash を記録。`/simplifier-lai` は利用不可、類似名 `simplify-lai` は LobbyAI 専用で代用しない。依存再利用と手動・独立レビューを記録。 | **commit 前後の Git 状態、最終差分量、commit の実施・SHA の報告は主担当が確定する。** 文書担当は今回許可された単位4の文書・ログ・検証コピー・保全結果だけを stage し、commit は主担当が行う。 |
| [native_gui](../../../policy_gates/native_gui.md) C1–C4、C9–C10、C12（7 件） | core API の再利用、ユーザー指定パス、全件保持と描画 / paging の分離、失敗のファイル・理由表示、各ビューの座標と概略精度、core 単独 build を確認。追加衛星でも元行を削除せず、未評価の位置を原点に置換しない。 | 原版の時系・観測補正・bit 一致を主張しない。 |
| native_gui C5–C8（4 件） | 共通表示型と単一適用経路、非表示時の描画 / hit 抑止と選択保持、星名・mark の出典、格子の座標境界。`test_display_rendering` 82、`test_grid_renderer` 101、distance 127、星名・grid geometry 試験が 3 構成で通過。 | UNIT3 の実装部分も UNIT4 の回帰結果で確認する。旧版の線や画素との一致は別問題。 |
| native_gui C11（1 件） | 投影・位置・地平座標・検索の test、Plus / 通常版 data、通常全体 smoke、衛星 controller 38 / view 99 checks を確認。 | **実 GUI 確認の範囲は、起動した AppKit smoke、個別 controller、実 OS window 試験として記録。** 未実施の人手 / CUA 操作を含めない。修正後の全体 Plus smoke は 3 構成とも成功。 |
| native_gui C13–C15（3 件） | Renderer 4 設定の実効値を global && type とし、Core Graphics 状態を局所保存・復元。renderer_quality 64 checks、全体 smoke の 4 flags。同じ window controller をメニュー / Lua から利用し、実状態取得・遷移中逆要求拒否・失敗解除。About は bundle / license。[window-validation](window-validation.md)。 | 状態 fixture 31 checks と実 OS 全画面移行・復帰 5 checks は各 3 構成で成功。About の全見た目・複数画面を網羅した証拠ではない。 |
| [solar_view](../../../policy_gates/solar_view.md) C1–C3（3 件） | CF96 / 月 / AU と回転を既存 core で評価。UNIT4 は同じ source / JD の検証済み親 snapshot を使い、Earth/Moon・Pluto/Charon の補正を一度だけ適用。未検証の別 source で穴埋めしない。絶対位置・scene の専用回帰。 | raw 親 / 補正前 / 最終位置を区別。基本モデルと衛星 source の切替・選択解除・再適用が二重補正にならないことを専用試験で確認。 |
| solar_view C4–C7（4 件） | 有限 camera 境界、near clip / picking、date / focus / pan / zoom、失敗時の直前正常状態。通常全体 smoke と solar model / view / satellite scene 回帰。 | 修正後の全体 Plus smoke は 3 構成の全項目を通過。途中停止した古い失敗ログは区別して残す。 |
| [planet_textures](../../../policy_gates/planet_textures.md) C1–C11（11 件） | 11 定義・ImageIO・容量 / 寸法制限・縮小・欠損 fallback・atomic 切替・UV / 光源 / 物理半径等の既存契約。`test_planet_textures` / `test_planet_surface` を 3 構成で再実行。通常全体 smoke の 11 textures、close-up 描画を確認。 | UNIT4 の renderer 品質 flag とテクスチャ内部補間を混同しない。実データを再保存しない。 |
| [planet_rotation](../../../policy_gates/planet_rotation.md) C1–C10（10 件） | 既存の公式 9 惑星・Earth 姿勢・J2000 黄道基底・同 JD、有限 / 範囲拒否、光源 / UV、日時移動・原本比較を再実行。公式比較は 33,129 組、差分と有効期間を記録。UNIT4 の Pluto 表示は検証済み source 補正時と raw 重心時を区別。 | 姿勢モデルを改変して x86_64 月 fixture の差を消していない。旧 Plus 衛星表面・自転 GUI は今回未対応。 |
| [time_playback](../../../policy_gates/time_playback.md) C1–C19（19 件） | playback clock 10,134、calendar 333、session 964 checks、PlaybackController の実 timer / pause / rate / bounds / realtime / failure / interrupt / hidden / UTC tracking。JSON v4、42 セル、month/year clamp、固定 offset、atomic な同 JD snapshot を回帰。 | 制御された遮蔽 fixture は状態分岐の試験であり、OS の完全遮蔽通知成功ではない。親 snapshot 補正の期待値を更新した回帰と、独立 clock / controller 成功を分ける。 |
| time_playback C20（1 件） | Plus 全体 smoke は開始境界の修正後に 3 構成で実再生を通過。通常版は修正前の通常構成で成功。3 構成の controller も通過。 | **同期描画 callback の後処理を再生時間から分ける fixture のみを修正。** 手動 tick や固定待ち時間追加はなく、製品時計と検査条件を維持。失敗時の最終 tick が採取できなかった制約を残す。 |
| [moon_surface_navigation](../../../policy_gates/moon_surface_navigation.md) C1–C9（9 件） | 公式月・有効期間・地月補正・月軌道・ENU・物理表示・独立 3 秒移動・GUI 接続。公式月 12,108 組比較、lunar / surface navigation 試験、通常全体 smoke の月 / 着陸 / 離陸を確認。 | 通常モデルの地月比と Plus source 補正係数を別経路として一度だけ使う。native 月モデル倍率 1 は旧 Plus 月モデル・設定との同一性を主張しない。修正後の全体 Plus smoke は 3 構成とも月・移動まで通過。 |
| [continuous_flight](../../../policy_gates/continuous_flight.md) C1–C12（12 件） | C++ flight model、現在の出発状態、同 JD の移動先、24 秒工程、衝突回避、中断 / 再開 / 手動制限 / 半径。`test_interplanetary_flight` と通常全体 smoke の連続飛行を確認。 | 開始境界修正後の Plus 全体 smoke は 3 構成とも連続飛行まで成功。追加衛星への飛行は未対応として拒否。 |
| [plus_compatibility](../../../policy_gates/plus_compatibility.md) C1–C3（3 件） | matrix の版と原典位置、今回の追加接続・不足・受入条件、UNIT4 README と本稿の対象 / 実施者 / 結果を照合。 | 原版の全機能完了とは記載しない。全体 Plus smoke は 3 構成で成功。clone / 最終保全 / 最終 gate も確定した。commit と wrapper 採用は後続作業として分ける。 |
| plus_compatibility C4–C7（4 件） | 明示した local HTML の同一 bytes、1 MiB、canonical path / device / inode / SHA-256、main frame / top / view / generation、64 KiB 一度 decode、通常遷移でも trust 失効。ページ JS 無効・isolated world・content rule / navigation cancel。[HTML 設計](../html-bridge-policy-design.md)。 | 個別 policy 80 checks、browser + helper 結合 73 checks / 3 host。資産・通常リンクで loopback TCP 0。全 scheme / redirect / cache 組合せを網羅したとは記載しない。compile callback 保留中 open / close と stale view navigation は読み取りレビューの範囲。 |
| plus_compatibility C8–C16（9 件） | 信頼済み Lua の io / os / package / debug、専用 helper、予算・中断、process group の制限、IPC strict、fresh host getter / toggle、5.4.9 差異、固定 archive SHA、arch static link、MIT 同梱。各構成 script-test と既存 Makefile / SCRIPTING、runSource 一時領域所有権の回帰。 | process group 外へ離れた子や、既発生の副作用を巻き戻す機構とは説明しない。個別 HTML host の arch だけで helper arch 実行を主張しない。 |
| plus_compatibility C17–C20（4 件） | JSON v4 1 MiB strict・型 / 列挙 / 有限 / 範囲・品質 / 衛星 bool、旧版拒否、復元時停止、出力先制約。session / file I/O / script / controller / 通常全体 smoke で確認。 | 数値往復の比較だけを限定 ULP 許容へ変更し、製品値・型検証・構造一致を緩めていない。SAN full smoke の以前の失敗を残したうえで、開始境界修正後の 3 構成成功を記録。 |
| [local_plus_assets](../../../policy_gates/local_plus_assets.md) C1–C4（4 件） | 小天体の raw / variant / duplicate 保持、未確定行の非評価と診断、core conics、同 JD snapshot と古い選択破棄。small body core / GUI / controller と Plus 19,475 行・2,388 評価可能の通常 smoke。 | 件数を固定して切り詰めない。未確定 mp / TNO frame / time を推定した位置へ変換しない。 |
| local_plus_assets C5–C8（4 件） | 179 出典・362 定義・177 軌道・340 衛星行、出典別 native 登録、相対 km / 絶対 AU / 補正 / 診断、同 model snapshot、再読込拒否、探査機 raw / PPI / PTH 全件。各 satellite / spacecraft provenance と専用回帰。 | 衛星は確定した旧版の数値 JD 契約を実装し、未知の UTC / TT / TDB 等へ変換もラベル付けもしない。UNIT4 探査機 GUI / PTH 位置は未接続。 |
| local_plus_assets C9–C14（6 件） | 3 背景画像の別読込・限界・cache、media raw 参照・ImageIO / AVKit / AVFoundation・明示再生・世代取消。background / media model 45 / controller 43 checks と保全結果。 | 単独プレビューを旧版の合成・全 API 完成と扱わない。元データを置換・再エンコードしない。 |

## 最終判定時の確認

1. **timer 失敗と修正**を記録。fixture 開始境界のみの修正後、通常・SAN・x86_64 の全体 Plus smoke が成功した。失敗時の原因を断定できない限界と旧ログを維持する。
2. **新規 clone** は `--no-hardlinks` による独立 tree と最終 staged patch で core / GUI `all test` が成功した。index export の clean 試験とは区別する。Private の最終確認もログに固定した。
3. **最終保全** は `2026-10-29T12:20:50.290384Z`、全 16,365 files / 465 symlinks と公式 ZIP を再照合し、追加・削除・変更 0 だった。
4. **実 GUI の検証範囲**は起動した AppKit smoke、個別 controller、実 OS 全画面である。未実施の人手 / CUA 操作は含めない。UNIT3 の OS 完全遮蔽の未通過は [occlusion-environment.md](../unit3/occlusion-environment.md) に残し、controlled fixture の成功で上書きしない。
5. **最終 gate コピー**は [14 gate・147 条件](../../../temp_gates/2026-10-29-21-28-30/VALIDATION.md) を実際に記入した。source commit と wrapper 採用は主担当による対象確認後に行い、結果を追記する。

### 条件の読み方で曖昧さが残る箇所

- `local_plus_assets` の「未確定の時刻系を推測しない」は、衛星の **原版と同じ数値 JD を受け渡す契約**と、物理時系を未確定として公開する契約を区別する。UTC / UT1 / TT / TDB を推測した変換は行っていない。これを原版の物理精度が確定した証拠として扱わない。
- `preservation` の「暗黙の並べ替え」は元のレコードの順序・重複を対象とする。ファイル出典の決定的列挙は原レコードの変更とは区別し、列挙順も source key として追跡できるようにする。
- `native_gui` の実 GUI 条件は、実ウィンドウを起動した自動操作と人手 / CUA を区別して記述する。画像や全操作の目視を実施したという推定はしない。
- `plus_compatibility` のネットワーク遮断は製品の content rule / navigation 境界と、実行した資産・リンク試験で評価する。「loopback TCP 0」はその試験対象の実測であり、WebKit のあらゆる入力を網羅した証明ではない。
- `verification` の commit 報告は、commit 前の予定と commit 後の SHA / Git 状態を分ける。最終資料の stage は明示許可された対象だけに限り、source commit と wrapper 採用の結果は別途記録する。

## 不合格条件との照合メモ

今回確認した staged UNIT4 に、保全対象の書換え・公開化・データ同梱・表示件数に合わせた原行破棄・Wine 起動・core の GUI 依存追加は見つからなかった。未知の計算をゼロで埋める経路、未対応 Lua API の空成功、コードとしての状態復元、無信頼 HTML の実行は製品側で拒否し、異常系の回帰がある。

新規 clone、最終保全、最終 gate は完了した。過去の失敗と限定した検証範囲を分け、単位4の対象だけを YES と判定する。未完了の旧版機能、実 OS 遮蔽通知、後続の UNIT5 を合格範囲に含めない。
