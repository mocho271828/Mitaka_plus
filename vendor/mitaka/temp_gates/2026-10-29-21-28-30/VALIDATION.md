# UNIT4 最終 policy gate 検証

判定日時: 2026-10-29-21-28-30 JST。判定は **14 gate すべて YES、判定条件 147 / 147**。対象は追加衛星の保持・計算・検索・表示、Renderer 4 設定、全画面 / About、信頼済み local HTML と Lua、JSON v4、探査機の保持・評価境界、および既存機能の回帰である。原版の全機能完成を表す判定ではない。UNIT5 の未追跡の小惑星位置・探査機位置 / GUI・表示集合・軌道線は対象外。

## 対象と実施者

- 基準 HEAD: `cf4fcbfe5447adf554e5bca0b0caf5ae5f529505`。
- 最終資料追加前の staged UNIT4: **129 files、+9,954 / −200**。
- `git diff --cached --binary -- native/` の SHA-256: `c0f58570a21b6483508a0306bb63adeee2ef6c26ee5fb62a59ae53f181a2df05`。
- 新規 clone に適用した `/tmp/mitaka-unit4-staged.patch` の SHA-256: `70c0aef245940ddd420a9bf389edd689eb25589189cabc001f0f350d2c448092`。この patch は最終資料追加前の全 staged 対象であり、native 限定 hash と区別する。
- 実行は主担当と各機能担当、資料・差分・ログの照合と本コピーの記入は `native_gap_audit` が担当した。core / data / preservation / repository の根拠と 147 条件の被覆は別担当が読み取りレビューし、必須指摘なし。文書担当が GUI 試験を再実行したとは記載しない。
- 各 gate は現行テンプレートをこのディレクトリにコピーし、判定条件を実際に `[x]` にした。不合格条件は該当なしを確認して `[ ]` のまま残している。テンプレート自体を判定済みにはしない。

## 各 gate の判定

| Gate | 判定条件 | 判定 |
| --- | --- | --- |
| [continuous_flight](continuous_flight.md) | 12 / 12 | YES |
| [core_architecture](core_architecture.md) | 5 / 5 | YES |
| [data_contracts](data_contracts.md) | 6 / 6 | YES |
| [local_plus_assets](local_plus_assets.md) | 14 / 14 | YES |
| [moon_surface_navigation](moon_surface_navigation.md) | 9 / 9 | YES |
| [native_gui](native_gui.md) | 15 / 15 | YES |
| [planet_rotation](planet_rotation.md) | 10 / 10 | YES |
| [planet_textures](planet_textures.md) | 11 / 11 | YES |
| [plus_compatibility](plus_compatibility.md) | 20 / 20 | YES |
| [preservation](preservation.md) | 7 / 7 | YES |
| [repository_management](repository_management.md) | 5 / 5 | YES |
| [solar_view](solar_view.md) | 7 / 7 | YES |
| [time_playback](time_playback.md) | 20 / 20 | YES |
| [verification](verification.md) | 6 / 6 | YES |

各コピー末尾に条件番号ごとの根拠を記載した。条件番号は「判定条件」の先頭から数え、不合格条件は数に含めない。[詳細照合表](../../investigation/native-plus/unit4/gate-evidence-draft.md) の範囲照合で欠落・重複・範囲外は各 0。

## 最終実行証拠

[UNIT4 README](../../investigation/native-plus/unit4/README.md) に全結果と個別 provenance をまとめた。完了したログ 164 件は [SHA256SUMS](../../investigation/native-plus/unit4/logs/SHA256SUMS) で固定する。旧失敗ログを成功ログで上書きせず、個別試験・修正前の結果・最終統合結果を区別する。

| 対象 | 結果と根拠 |
| --- | --- |
| 全 test | 通常 / ASan+UBSan / x86_64 成功。GUI の [通常](../../investigation/native-plus/unit4/logs/mitaka-unit4-final-normal.log)、[SAN](../../investigation/native-plus/unit4/logs/mitaka-unit4-final-san.log)、[x86](../../investigation/native-plus/unit4/logs/mitaka-unit4-final-x86.log)、core の [SAN](../../investigation/native-plus/unit4/logs/mitaka-unit4-core-full-san.log) と [x86 最終](../../investigation/native-plus/unit4/logs/mitaka-unit4-lunar-profile-x86-all.log) を照合。 |
| script / controller | host と helper の各構成の script-test、および通常 / SAN / x86 の最終 controller-test はすべて exit 0。README の各 final ログ参照。 |
| 全体 Plus smoke | 開始境界の fixture 修正後の [通常](../../investigation/native-plus/unit4/logs/mitaka-unit4-timer-boundary-normal-smoke.log)、[SAN](../../investigation/native-plus/unit4/logs/mitaka-unit4-timer-boundary-san-smoke.log)、[x86](../../investigation/native-plus/unit4/logs/mitaka-unit4-timer-boundary-x86-smoke.log) は全段階 exit 0。通常版 smoke は修正前の通常構成で exit 0。 |
| 実データ・原本比較 | 通常の core data / reference、GUI の Plus / 通常版 data は成功。元行・重複・未評価診断を維持し、描画可能件数に切り詰めていない。 |
| 新規 local clone | `git clone --no-hardlinks` の `/tmp/mitaka-unit4-clone.YwTjHl` に上記 staged patch を適用し、core / GUI `all test` が成功。[ログ](../../investigation/native-plus/unit4/logs/mitaka-unit4-clone.log)。以前の clean index export は開始境界 fixture 修正前の別結果。 |
| 最終保全 | `2026-10-29T12:20:50.290384Z` に 16,365 files / 6,622,642,667 bytes / 465 symlinks を照合、追加・削除・変更 0。公式 ZIP 310 files 不一致 0、参照 checkout HEAD / status 一致、基準 manifest 不変。[ログ](../../investigation/native-plus/unit4/logs/mitaka-unit4-preservation-final.log)、[JSON](../../investigation/native-plus/preservation-final.json)。 |
| Private | `gh repo view --json visibility,nameWithOwner` で `mocho271828/Mitaka` の `PRIVATE` を最終確認。[ログ](../../investigation/native-plus/unit4/logs/mitaka-unit4-private-final.log)。 |

## 失敗履歴と合格範囲の限界

- 当初の SAN 全体 smoke の実タイマー失敗は同じ binary 単独でも再現した。同期描画の後処理を試験開始前へ分離するため、次の run loop callback で再生試験を開始する fixture だけを修正した。製品時計、1 秒超の中断規則、250 ms の進行・pause 後 120 ms の不変検査は維持。失敗時 tick の具体的な原因は取得できず、断定しない。[診断と修正](../../investigation/native-plus/unit4/playback-smoke-validation.md)。
- 月の x86 fixture は未変更の公式原本と両 CPU で比較し、FMA の有無による独立採取プロファイルへ修正した。計算本体・許容差は変更していない。JSON の数値往復比較は限定 ULP の比較へ変更したが、製品値・型・構造検証を緩めていない。旧失敗ログを保存した。
- HTML 通常リンクでは delegate の取消だけでは TCP 接続を観測し、managed click の先行取消へ修正した。対象資産・通常リンクの試験は TCP 0。全 scheme / redirect / cache の網羅や、compile callback 保留中の連続 open / close の実行回帰を主張しない。
- 実 GUI の証拠は起動した AppKit smoke、controller、実 OS 全画面移行・復帰である。未実施の手動 / CUA 操作や画素一致は含めない。UNIT3 の実 OS 完全遮蔽通知は [未通過のまま](../../investigation/native-plus/unit3/occlusion-environment.md) であり、制御 fixture の 46 checks 成功とは区別する。
- 衛星の原版数値 JD は物理時系の確定ではない。native の月モデル倍率 1 と旧 Plus 月モデルの同一性を主張しない。衛星表面・自転 GUI、追加衛星への飛行、探査機 GUI / UNIT4 PTH 位置、未対応 Lua API、全旧版機能は合格範囲に含めない。

## 依存・方針・Git

既存の C++17 core / CF96 / Kepler / Trajectory / 月 / 座標変換を再利用し、GUI は AppKit / Core Graphics / Foundation、macOS 標準 WebKit / CommonCrypto、既存の公式 Lua 5.4.9 helper を使う。外部の新規 runtime 依存や独自 Lua 処理系は追加しない。変更範囲と異常系の独立レビューを各 provenance に残した。

`IMPLEMENTATION_POLICY.md` と適切な既存 gate を更新済み。指定名 `/simplifier-lai` は利用不可であり、類似名 `simplify-lai` は LobbyAI 専用のため代用しない。手動・独立品質レビューを行い、文書には `japanese-writing` を適用した。

300 行を超える UNIT4 は主担当が最終 scope を確認して commit する。文書担当は許可された UNIT4 文書・ログ・この検証コピー・最終保全 JSON だけを stage し、UNIT5 は含めない。commit / push と wrapper 採用の SHA・結果は後続に記録する。本判定は commit 実施済みという意味ではない。

最終資料 stage 後の `git status` と対象一覧を確認した。staged は 312 files、テキスト差分 +17,288 / −200（この追記を含む。別に NUL を含む原ビルドログ 1 件）。native 限定 hash は上記のままで、未 stage の tracked 変更はない。UNIT5 の未追跡ファイルは除外した。`git diff --check` と `git diff --cached --check` は成功。164 ログのハッシュと全 Markdown リンクを検証し、別担当の最終読み取り監査でも必須修正はなかった。
