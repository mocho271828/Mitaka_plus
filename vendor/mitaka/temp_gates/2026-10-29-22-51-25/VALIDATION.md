# UNIT5 最終 policy gate 検証

判定日時: 2026-10-29-22-51-25 JST。判定は **14 gate すべて YES、判定条件 154 / 154**。対象は小天体の表示集合と彗星軌道、衛星の表示集合と瞬間楕円、PTH 探査機の検索・表示・軌跡、packed 36 byte 小惑星/TNO の位置、星座集合、関連 Lua 真偽値、JSON v5、および既存機能の回帰である。原版 Plus の全機能完成を表す判定ではない。同梱する UNIT6 資料は読み取り監査であり、製品実装には数えない。

## 対象と実施者

- 基準 HEAD: `002adcf663fd5005e14ac86c343a3ec7e56fa706`。
- 最終 staged native は **115 files、+8,359 / −372**（GUI README を含む）。`git diff --cached --binary -- native` の SHA-256 は `3b897ca64674ad4c435d22e6e8940e96f67ec53078851c525aa947a9b3148dab`。主担当の `/tmp/mitaka-unit5-final-native.patch` と文書担当の再計算が一致した。
- 実行は主担当と各機能担当、差分・provenance・実行ログの照合と本コピーの記入は `native_gap_audit` が担当した。core の独立した読み取りレビューは [core-gate-evidence.md](../../investigation/native-plus/unit5/core-gate-evidence.md) に記録する。文書担当が統合試験を再実行したとは記載しない。
- 現行テンプレートをこのディレクトリへコピーし、判定条件を実際に `[x]` にした。不合格条件は該当なしを確認して `[ ]` のまま残した。テンプレート自体のチェック欄は変更していない。
- 条件範囲の被覆を機械照合し、欠落・重複・範囲外は各 0。これはログの成功や独立したコードレビューを機械的に代替する判定ではない。

## 各 gate の判定

| Gate | 判定条件 | 判定 |
| --- | --- | --- |
| [continuous_flight](continuous_flight.md) | 12 / 12 | YES |
| [core_architecture](core_architecture.md) | 5 / 5 | YES |
| [data_contracts](data_contracts.md) | 6 / 6 | YES |
| [local_plus_assets](local_plus_assets.md) | 17 / 17 | YES |
| [moon_surface_navigation](moon_surface_navigation.md) | 9 / 9 | YES |
| [native_gui](native_gui.md) | 17 / 17 | YES |
| [planet_rotation](planet_rotation.md) | 10 / 10 | YES |
| [planet_textures](planet_textures.md) | 11 / 11 | YES |
| [plus_compatibility](plus_compatibility.md) | 22 / 22 | YES |
| [preservation](preservation.md) | 7 / 7 | YES |
| [repository_management](repository_management.md) | 5 / 5 | YES |
| [solar_view](solar_view.md) | 7 / 7 | YES |
| [time_playback](time_playback.md) | 20 / 20 | YES |
| [verification](verification.md) | 6 / 6 | YES |

各コピー末尾に条件番号ごとの根拠を記載した。条件番号は「判定条件」の先頭から数え、不合格条件は数に含めない。[詳細照合表](../../investigation/native-plus/unit5/gate-evidence-draft.md) と一致する。

## 最終実行証拠

[UNIT5 README](../../investigation/native-plus/unit5/README.md) に個別結果、provenance、既知の差異をまとめた。統合ログ 30 件は [SHA256SUMS](../../investigation/native-plus/unit5/logs/integration/SHA256SUMS) を照合済み。担当別の個別ログは同 README から参照できる。途中失敗のログを成功ログで上書きしていない。

| 対象 | 結果と根拠 |
| --- | --- |
| core 全 test | 通常 / ASan+UBSan / x86_64 成功。[通常](../../investigation/native-plus/unit5/logs/integration/core-normal-test.log)、[SAN](../../investigation/native-plus/unit5/logs/integration/core-san-test.log)、[x86](../../investigation/native-plus/unit5/logs/integration/core-x86-test.log)。 |
| GUI all test | 通常 / ASan+UBSan / x86_64 成功。[通常](../../investigation/native-plus/unit5/logs/integration/final-normal-all-test.log)、[SAN](../../investigation/native-plus/unit5/logs/integration/final-sanitize-all-test.log)、[x86](../../investigation/native-plus/unit5/logs/integration/final-x86-all-test.log)。後続の smoke fixture 修正は最新 clone と full smoke の結果で照合する。 |
| script / controller | 全 controller-test（script を含む）が各 exit 0。[通常](../../investigation/native-plus/unit5/logs/integration/final2-normal-controller.log)、[SAN](../../investigation/native-plus/unit5/logs/integration/final2-sanitize-controller.log)、[x86](../../investigation/native-plus/unit5/logs/integration/final2-x86-controller.log)。 |
| full smoke | final3 の Plus 通常 / SAN / x86、通常版通常の全 4 本が exit 0。[Plus 通常](../../investigation/native-plus/unit5/logs/integration/final3-app-plus-normal.log)、[Plus SAN](../../investigation/native-plus/unit5/logs/integration/final3-app-plus-sanitize.log)、[Plus x86](../../investigation/native-plus/unit5/logs/integration/final3-app-plus-x86.log)、[通常版](../../investigation/native-plus/unit5/logs/integration/final3-app-regular-normal.log)。Script の予算拒否伝播、小天体・衛星・Session v5・Plus・連続飛行まで完走。 |
| 実データ・公式比較 | [Plus data](../../investigation/native-plus/unit5/logs/integration/final-data-plus.log)、[最終通常版 data](../../investigation/native-plus/unit5/logs/integration/final2-data-regular.log)、[core reference](../../investigation/native-plus/unit5/logs/integration/final-core-reference.log) は成功。小天体 19,475 行と衛星 340 行を保持し、未評価行を黙って切り捨てていない。 |
| 新規 local clone | staged native patch を新規 local clone へ適用した [core all test](../../investigation/native-plus/unit5/logs/integration/final-clean-core.log) と [GUI all test](../../investigation/native-plus/unit5/logs/integration/final-clean-gui.log) が成功。後続の `AppPlusSmokeTests.mm`、`AppScriptSmokeTests.mm`、`AppScripting.mm` を同期した [最新 GUI all test](../../investigation/native-plus/unit5/logs/integration/final3-clean-gui.log) も成功。初回と再試験を区別する。 |
| 最終保全 | 16,365 files / 6,622,642,667 bytes / 465 symlinks、追加・削除・変更 0。公式 ZIP 310 files 一致、参照 checkout 不変。[最終ログ](../../investigation/native-plus/unit5/logs/integration/final3-preservation.log)、[JSON](../../investigation/native-plus/preservation-final.json)。 |
| Private | [最終確認](../../investigation/native-plus/unit5/logs/integration/final-private.log) で source / wrapper の両リポジトリが Private。 |

## 失敗履歴と合格範囲の限界

- 初回 Plus full smoke は Lua fixture が 14,676 行 × 129 標本を要求し、製品の軌道予算上限で拒否された。次の final2 は旧表示 fixture が全 toggle に全天図への切替を要求して失敗した。製品の容量上限や入力全件保持を緩めず、fixture と星座の共通 setter 接続を修正した。失敗ログと final3 成功を別々に保存した。
- 通常版の衛星 fixture が Plus 専用 Charon を必須とした問題、探査機 fixture の source metadata 不足も修正後の試験と区別した。元の実データを件数合わせに変更していない。
- minor の実原本 253,211 checks × 3 は担当者通知と provenance に基づき、専用の保存ログがない。統合 core の合成試験 90,730 checks × 3 と同じ結果として数えない。PTH や彗星軌道の全件試験は各局所記録を参照する。LeakSanitizer 有効指定の非対応エラーと ASan/UBSan 成功も区別する。
- 実 GUI の証拠は起動した AppKit controller / full smoke の操作であり、今回実施していない人手 / CUA 操作を含めない。UNIT3 の実 OS 完全遮蔽通知は [未通過のまま](../../investigation/native-plus/unit3/occlusion-environment.md) であり、controlled factory 成功と区別する。
- x86_64 は Rosetta 実行であり、Intel 実機・macOS 13 実機は未確認。原版との全画素 / bit 一致、全配布 Lua の実行成功、全 HTML scheme の網羅を主張しない。
- packed 37 byte、物理時系未認定の legacy numeric JD、PPI の GUI 位置、衛星表面・自転 GUI、追加衛星・探査機への飛行、旧名前指定 Lua show / hide / isVisible などは未対応または未確定として残す。UNIT6 の雲・夜景・大気・地平天の川などは読取資料だけであり、今回の実装済み範囲ではない。

## 依存・方針・Git

既存 C++17 core / loader / Kepler / CF96 / 座標変換を再利用した。GUI は既存 AppKit / Core Graphics / Foundation、macOS 標準 CommonCrypto、既存の公式 Lua helper を使う。外部 runtime 依存を新規追加していない。source bytes の照合は独自ハッシュ実装でなく CommonCrypto を使い、表示設定の責務と原子的な失敗境界を独立レビューした。

`IMPLEMENTATION_POLICY.md` と適切な既存 gate を更新済み。指定名 `/simplifier-lai` は利用不可であり、類似名 `simplify-lai` は LobbyAI 専用のため代用しない。担当間の独立品質レビューを実施し、文書には `japanese-writing` を適用した。

Git status、変更対象、native 差分量を確認した。300 行を超える UNIT5 は主担当が最終 scope を確認して commit / push する。文書担当はこの検証コピーと根拠資料を作成し、stage / commit は行っていない。最終資料を含む差分量、commit / push と wrapper 採用は主担当が後続に記録する。本判定は commit 完了を先取りしない。`git diff --check` と `git diff --cached --check` は成功し、原本・生成 binary の新規登録はない。
