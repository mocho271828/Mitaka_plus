# Plus 機能追加・単位4の範囲と検証記録

確認日: 2026-10-29。基準 commit は単位3の `cf4fcbfe5447adf554e5bca0b0caf5ae5f529505`。
この単位は、追加衛星の保持・位置計算・検索・表示、描画品質、全画面/About、信頼したローカル HTML からの Lua 実行、JSON v4 を対象とする。探査機データの保持と評価境界も追加したが、探査機 GUI は含まない。

**通常・ASan / UBSan・x86_64 の全 `test` / `script-test` / `controller-test` と全体 Plus smoke、通常構成の実データ・公式原本比較・通常版 smoke、原本保全は成功した。staged index の clean export でも core / GUI の全 `test` が成功した。SAN の実タイマー smoke は一度失敗したが、試験開始を次の run loop callback へ移す最小修正後に 3 構成の全体 Plus smoke が成功した。最終 staged patch を適用した新規 local clone の core / GUI `all test` と、その後の原本保全再確認も成功した。14 gate・147 条件は検証コピーですべて YES と判定した。** 単位3で未通過だった実 OS の完全遮蔽通知は、今回も成功扱いしない。原版の全機能完成を示す記録ではなく、未対応は [機能対応表](../../../PLUS_FEATURE_MATRIX.md) に残す。

## 実装した接続

| 対象 | 今回の接続 | 範囲・残る制約 |
| --- | --- | --- |
| 衛星データ | system 定義・軌道の原バイト列、行順、出典、重複を保持し、出典ごとの独立登録を検証する。 | 旧 Plus 起動時の言語選択・初期コンテナ状態の再現とは区別する。未解決行も検索・診断に残す。 |
| 衛星位置 | 確定した L / I / E / C / Q の回転、通常衛星の相対 km、同じ数値 JD の raw CF96 親位置を接続する。 | 物理的な時系・要素の精度期間は未確定。月は公式 1.3.1 の既存モデル・倍率 1 の明示入力で、旧 Plus の月解析・倍率との同一性を主張しない。 |
| 衛星の検索・表示 | 全行の検索、出典選択、診断、中央移動、太陽系 3D の点・選択名、日時更新時の追従を接続する。 | 位置未評価行は移動せず理由を示す。衛星軌道線、個体別可視性、表面・自転の GUI、着陸・飛行、衛星選択の保存は未対応。 |
| 親天体の表示 | 同じ出典・JD の最終位置で太陽系の親天体を置換する。選択中はその出典、未選択時は最初の検証済み出典を使う。 | 他出典からの穴埋めや補正の二重適用はしない。衛星表示を切っても原行・選択を保持する。全天図・地平図は既存の基本モデルを使う。 |
| 描画品質 4 項目 | antialiasing / smoothPoint / smoothLine / smoothText をメニュー・Lua・共通状態から 3 ビューへ適用する。 | 各種別の平滑化には antialiasing と個別フラグの両方が必要。Core Graphics 上の契約であり、旧 OpenGL の画素一致ではない。 |
| 全画面・About | 主ウィンドウのメニューと Lua を共通 controller へ接続する。実状態 getter と非同期遷移を扱う。 | 受付と完了を区別する。旧 Windows の同期性・寸法 API・拡大操作は含まない。全画面状態は保存しない。 |
| ローカル HTML | 明示選択した文書の表示と、信頼したメインページでの実クリックによる `mtkp://` を既存 Lua helper へ接続する。 | ページ JavaScript、Flash、オンライン閲覧・実行、iframe への権限、ホーム・履歴・ブックマークは提供しない。旧 Lua の全 API を実装したものではない。 |
| JSON v4 | 描画品質 4 項目と衛星の全体表示を保存・検証・復元する。 | 本番投入前の v1 / v2 / v3 は拒否する。HTML の信頼、実行状態、全画面、衛星の個別選択は復元しない。 |
| 探査機のコア | Plus と通常版の定義・登録・PPI / PTH の原文、時刻、座標、重複を保持する。PPI は既存 `Trajectory` を再利用する。 | この単位の PTH は未確定契約の診断を返し、位置は返さない。後続の静的監査で分かったことを、未接続の evaluator や GUI の実装済み機能と扱わない。 |

ローカル Plus では衛星の 179 出典、362 定義、177 軌道、340 衛星行を保持した。全体 smoke ではそのうち 330 行に位置があり、残る行にも診断がある。これらは今回の入力の実測値であり、公開データの件数に合わせる条件や読込上限ではない。通常版に同じ system 定義がない場合は 0 行と欠損診断のまま既存表示を継続する。

## 原典・計算・表示の境界

衛星の式・定数・原版の処理順は、読み取り専用の限定静的監査で追跡した。[satellite-position-contracts.md](satellite-position-contracts.md) に命令位置と確定・未確定の境界を残す。旧アプリを実行して同じ画面や座標を比較した結果ではない。

成功登録の 9 惑星の ID と順序を確認できる場合だけ CF96 index に対応付ける。raw 親の J2000 赤道 AU から黄道への変換は一度だけで、通常衛星の回転済み相対 km を加える。最初の登録名一致の Earth / Moon、Pluto / Charon には原版の順序で重心補正を一度適用する。補正前・最終位置を別に保持し、片側未評価の対の最終位置や、他出典の代替位置を生成しない。

旧 Plus の数値 JD と UTC / UT1 / TT / TDB の物理的な対応は確定していない。CF96 の利用期間を衛星要素の精度保証期間とは扱わない。native の AU 定数、double 計算、公式 1.3.1 の月モデルを使うため、旧版の中間 float 丸めや旧月モデルとの bit 一致も保証しない。

詳細は [カタログ保持](../../../native/core/SATELLITE_CATALOG_PROVENANCE.md)、[回転](../../../native/core/SATELLITE_ROTATION_PROVENANCE.md)、[相対位置](../../../native/core/SATELLITE_POSITION_PROVENANCE.md)、[登録とモデル](../../../native/core/SATELLITE_MODEL_PROVENANCE.md)、[絶対位置・親天体](../../../native/core/SATELLITE_ABSOLUTE_PROVENANCE.md)、[一覧 controller](satellite-controller-validation.md)、[描画と選択](satellite-scene-validation.md) を参照する。探査機の保持・未確定事項は [SPACECRAFT_TRAJECTORY_PROVENANCE.md](../../../native/core/SPACECRAFT_TRAJECTORY_PROVENANCE.md)、後続評価へ向けた監査は [spacecraft-position-contracts.md](spacecraft-position-contracts.md) に分ける。

## HTML と Lua の実行境界

最大 1 MiB のローカル HTML を読み、同じ読み取りで得た内容を表示する。canonical path、device / inode、SHA-256、メインページ、WebView と表示世代を検査し、別文書・別 frame・古い view へ信頼を継承しない。通常リンクの操作は移動を取り消した場合も信頼を失効させる。文書変更、閉じる操作、新しい文書の選択でも失効する。

ページ JavaScript を無効にしたうえで、アプリの分離した content world が実クリックと元の href を取得する。`mtkp://` は最大 64 KiB、UTF-8 の percent decode を一度だけ行い、不正 escape・NUL を拒否する。Lua は専用一時ファイルを経由して既存 helper で実行し、終了・中断後に一時ディレクトリを削除する。一時ディレクトリの所有権は worker dispatch 前に確定する。

Lua のファイル・OS 権限は通常のローカル Lua と同じであり、サンドボックスではない。既存の予算・中断機構は副作用を巻き戻さない。個別の境界試験とレビュー範囲は [html-bridge-policy-design.md](../html-bridge-policy-design.md)、対応 API は [SCRIPTING.md](../../../native/gui/SCRIPTING.md) を参照する。

## 試験とレビューの記録

以下は単位4の実行結果であり、単位3の成功を流用しない。主担当の完了通知とログを照合して記録した。途中の失敗、修正前の確認、最終統合結果を分けて記録する。

| 統合確認 | 結果・証拠 |
| --- | --- |
| 全 `test` | 通常・ASan / UBSan・x86_64 成功。[通常](logs/mitaka-unit4-final-normal.log)、[sanitizer](logs/mitaka-unit4-final-san.log)、[x86_64](logs/mitaka-unit4-final-x86.log)。core 全体の sanitizer と x86_64 は [core sanitizer](logs/mitaka-unit4-core-full-san.log)、[月 fixture 修正後の core x86_64](logs/mitaka-unit4-lunar-profile-x86-all.log) も参照 |
| Lua `script-test` | host と helper をそれぞれの構成でビルドし、3 構成成功。[通常](logs/mitaka-unit4-script-normal-final.log)、[sanitizer](logs/mitaka-unit4-script-san-final.log)、[x86_64](logs/mitaka-unit4-script-x86-final.log) |
| 最終 `controller-test` | 通常・ASan / UBSan・x86_64 の 3 構成で exit 0。[通常](logs/mitaka-unit4-controller-normal-final.log)、[sanitizer](logs/mitaka-unit4-controller-san-final.log)、[x86_64](logs/mitaka-unit4-controller-x86-final.log) |
| 実データ・公式原本比較 | 通常構成の core data / reference と GUI の Plus / 通常版 data が成功。[core 比較](logs/mitaka-unit4-core-reference-normal.log)、[Plus](logs/mitaka-unit4-data-plus-final.log)、[通常版](logs/mitaka-unit4-data-regular-final.log) |
| 通常構成の全体 smoke | Plus / 通常版とも exit 0。Script、衛星、共通表示、既存の太陽系・月・再生・飛行を含む。[修正後 Plus](logs/mitaka-unit4-timer-boundary-normal-smoke.log)、[通常版](logs/mitaka-unit4-app-regular-normal-final.log)。通常版 smoke は開始境界の fixture 修正前に成功した結果 |
| ASan / UBSan の全体 smoke | 開始境界の修正後、全段階が exit 0。[修正後ログ](logs/mitaka-unit4-timer-boundary-san-smoke.log)。当初の `real timer did not advance before pause`、exit 2 は [失敗時ログ](logs/mitaka-unit4-app-plus-san-timer-failed.log) に保持 |
| x86_64 の全体 smoke | 開始境界の修正後、全段階が exit 0。[ログ](logs/mitaka-unit4-timer-boundary-x86-smoke.log) |
| clean export | staged index を `/tmp/mitaka-unit4-clean.yPCkNr` に展開し、core / GUI の `all test` が exit 0。[ログ](logs/mitaka-unit4-clean.log)。開始境界の fixture 修正前の結果。最終修正後の独立 tree の結果は次行に記録する |
| 新規 local clone | `git clone --no-hardlinks` で作成した `/tmp/mitaka-unit4-clone.YwTjHl` に最終 staged patch を適用し、core / GUI `all test` が成功。[ログ](logs/mitaka-unit4-clone.log)。上記の index export と区別する |
| 原本保全 | 16,365 files、6,622,642,667 bytes、465 symlinks。追加・削除・変更 0、公式 zip の不一致 0、基準と一致。`2026-10-29T12:20:50.290384Z` の最終確認。[ログ](logs/mitaka-unit4-preservation-final.log) |
| policy gate | 14 gate・147 / 147 条件が YES。[検証コピーと判定](../../../temp_gates/2026-10-29-21-28-30/VALIDATION.md)。gate テンプレートを合格記録に使わない |

衛星の core・GUI 境界、HTML・Lua、描画品質、全画面の個別試験と独立レビューは各 provenance / audit に記録する。個別 HTML 結合試験の 3 host は同じ通常 arm64 helper を起動したため、helper 自体の sanitizer / x86_64 成功とは分ける。helper の各構成は上表の `script-test` で確認した。WebKit 試験の対象資産・通常リンクの loopback TCP 接続は 0 だったが、全 scheme・redirect・キャッシュの組合せを網羅した結果ではない。

全画面の独立した実 OS 移行・復帰試験は通常・ASan / UBSan・x86_64 で成功した。[window-validation.md](window-validation.md) を参照する。これは主アプリ全操作や複数画面、About パネルの全表示内容を網羅した証拠ではない。

実 OS の完全遮蔽通知は単位3の [occlusion-environment.md](../unit3/occlusion-environment.md) に記録した未通過のまま残る。通常の controller 試験は `occlusionState` を注入する fixture で停止・復帰条件を検証する。OS 通知自体が通ったとは扱わない。

## 失敗・修正と検証の限界

- ASan / UBSan の全体 smoke は、再生を pause する前に実タイマーが進むことを確認できず一度停止し、変更前の同じ binary の単独実行でも再現した。同期描画試験の後処理を再生の経過時間へ含めてしまう構造を改め、次の run loop callback で再生試験を開始する 6 行追加・1 行削除の修正を採用した。製品時計、1 秒超の中断規則、250 ms の進行検査、pause 後 120 ms の不変検査は変更せず、通常・SAN・x86_64 の全段階が成功した。失敗時の最終 tick の理由までは取得できていないため、具体的な失敗原因を断定しない。[診断と検証](playback-smoke-validation.md)、[失敗時ログ](logs/mitaka-unit4-app-plus-san-timer-failed.log) を残し、再実行の成功で上書きしない。

- x86_64 の月の固定値試験は、ARM64 で採取した原本値との丸め差で一度失敗した。両 CPU で未変更の公式原本との一致を確認し、積和演算縮約の有無を切り分けた。独立採取した 2 プロファイルを一組ずつ比較する fixture にし、月計算本体・許容差を変更せず全試験を通した。[LUNAR_PROVENANCE.md](../../../native/core/LUNAR_PROVENANCE.md)、[診断ログ](logs/mitaka-unit4-lunar-fma-diagnosis.log)、[旧 fixture の再現](logs/mitaka-unit4-lunar-before-profile.log) に失敗を残す。
- 衛星の全体 smoke は、JSON 数値の往復で最下位 bit に差が生じ、文字列の完全一致が失敗した。数値だけを限定した許容差で比較し、真偽値・構造・要素数を維持して検証する。既存再生 smoke も親位置の新しい補正経路に合わせた期待値へ更新した。製品の座標や JSON 型を変更して通したものではない。[初回 smoke](logs/mitaka-unit4-app-plus-normal.log)、[JSON 差の記録](logs/mitaka-unit4-satellite-json-comparison.log)、[修正後 smoke](logs/mitaka-unit4-app-plus-normal-final.log) を区別する。
- HTML の通常リンクは delegate 取消だけでは本文なし TCP 接続を観測した。全 anchor の既定移動をアプリ側で先に取り消す処理へ修正し、製品試験で 0 接続を確認した。非同期 compile callback 保留中の連続 open / close、保持された旧 view の直接 navigation は読み取りレビューで確認し、専用の実行回帰までは追加していない。

`logs/` は完了した `/tmp/mitaka-unit4-*.log` と個別 HTML 試験ログのコピーを収録する。失敗・調査ログも保持し、後続の成功で消さない。収集時に認証情報の標識や原カタログ本文の混入を確認し、ビルド出力・試験結果・合成値・計算値の記録であることを確認した。各ファイルの SHA-256 は [SHA256SUMS](logs/SHA256SUMS) に記載する。最終収録は 164 ファイルであり、新規 clone・最終保全・Private 確認のログも含む。`mitaka-unit4-satellite-scene-x86-build.log` は採取した原ログに 2,111 NUL bytes を含み、Git は binary と判定する。内容は変換せず保持し、このログだけを最終成功の根拠にはしない。

## 方針・依存・変更管理

既存 core の暦表・Kepler・座標変換・月モデル、C++17、AppKit / Foundation / Core Graphics、既存の公式 Lua 5.4.9 helper を再利用する。HTML は macOS 標準 WebKit / CommonCrypto を使用し、外部の実行依存や独自 Lua 処理系を追加しない。原本は読み取り専用であり、旧アプリ・独自データの再保存・変換・起動を行っていない。

`IMPLEMENTATION_POLICY.md` と適切な既存 gate へ、衛星の保持・出典と親位置・補正、HTML の信頼境界、描画品質・JSON v4、全画面の非同期契約を反映する。14 gate・147 条件の [根拠照合表](gate-evidence-draft.md) を最終化し、[検証コピー](../../../temp_gates/2026-10-29-21-28-30/VALIDATION.md) の判定条件を記入してすべて YES とした。不合格条件は該当なしとして未チェックにしている。Private は [最終確認ログ](logs/mitaka-unit4-private-final.log) に記録する。

指定名 `/simplifier-lai` は利用できない。類似名 `simplify-lai` は LobbyAI 用のため代替実行せず、手動の品質確認と独立レビューを記録する。この文書には `japanese-writing` を適用した。最終資料を追加する前の staged UNIT4 は 129 files、+9,954 / −200。native 限定 patch の SHA-256 は `c0f58570a21b6483508a0306bb63adeee2ef6c26ee5fb62a59ae53f181a2df05`。文書担当は許可された単位4の文書・ログ・検証コピー・保全結果だけを stage し、主担当が対象を確認して commit する。UNIT5 は含めない。source / wrapper の commit SHA と採用結果は commit 後に追記する。

次に実装する候補と各機能の不足は [next-feature-units.md](next-feature-units.md) に整理した。探査機表示、衛星表面・自転 GUI、旧 Lua の全 API、未確定の小惑星 / TNO の座標・時刻契約、旧版の画素・全操作の一致は未完了として残す。
