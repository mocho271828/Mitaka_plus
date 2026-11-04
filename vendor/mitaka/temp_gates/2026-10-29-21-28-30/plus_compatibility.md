# Gate: Plus 互換・ローカルスクリプト・状態保存

## 目的

原版との差を追跡できる形で機能を追加し、部分実装を全機能互換と誤認させない。ユーザーが許可したローカル Lua の権限、アプリの応答性、状態入力と出力の境界を維持する。

## 判定条件

- [x] `PLUS_FEATURE_MATRIX.md` は Windows 1.5.4 build101013 の README / `gui.lua` と、1.3.0 表示の同梱 API 説明書を区別する。機能 ID、原典の読取位置、現在の実装根拠、不足、受入条件を記載する。
- [x] 実装した機能だけ対応状況を更新し、予定・未確定仕様・Pro 専用機能を区別する。ネイティブ UI の実装だけを根拠に Lua API や配布スクリプトを互換と判定しない。
- [x] 記録には対象コミットまたは作業ツリーの時点、試験の実施者・結果、統合ビルドと GUI 操作の確認範囲を残す。未実行の試験を成功と記載せず、通常 Plus の不足が残る間は全機能完了と説明しない。
- [x] Lua はユーザーが明示選択した信頼済みローカル通常ファイル、または下記条件を満たす信頼済みローカル HTML の明示クリックだけを受け付ける。起動時の `init.lua`、URL、オンライン HTML / JavaScript / `mtkp://` から自動で実行しない。
- [x] HTML から Lua を呼ぶ機能を追加する場合、明示的に信頼したローカル HTML に限定する。オンライン文書・フレーム・遷移先には実行権限を与えず、信頼したローカルページから権限を継承させない。未接続の段階では対応済みと記載しない。
- [x] 信頼済み HTML は最大 1 MiB の通常ファイルとして同じ原バイト列を検証・表示する。main frame・表示文書・ファイル同一性を確認してから最大 64 KiB の `mtkp://` ソースを一度だけ復号し、別 helper へ渡す。読み替え・遷移・閉じる時は信頼を破棄する。
- [x] ローカル HTML のページ JavaScript を無効化し、リンク受信は分離した WebKit content world で行う。外部ネットワークの文書・画像・CSS・サブフレームを遮断する。ローカル文書へ遷移する場合も別途明示信頼を必要とする。
- [x] ユーザーが許可した Lua 標準ライブラリの `io` / `os` / `package` / `debug` を利用できる。本人の権限でファイル・外部コマンドを操作できることと、OS サンドボックスではないことを実行 UI と文書で説明する。
- [x] Lua は専用 helper プロセスで動かし、GUI スレッドをブロックしない。入力・メッセージのサイズ上限、Lua メモリ・命令数・実行時間の上限、GUI 側の終了期限を設け、取消・エラー・正常終了後に実行状態を解放する。
- [x] 取消時は helper と同じプロセス群を停止する。既に生じたファイル変更・ホスト操作と、別のプロセス群へ離脱した処理を巻き戻せないことを明記し、プロセス分離を権限制限と説明しない。
- [x] ホスト API の引数・返値・操作対象を IPC 境界で検証し、未対応 API や拒否操作は明示的なエラーにする。成功したふりをする空の互換メソッドを作らず、ファイル名・行・実行時トレースまたは原因を確認できる。
- [x] Time / Stars / Planets / Grids / Renderer / GUI の真偽値、Stars の 3 種と Milkyway の 4 種の列挙値を厳密に検証する。getter / toggle は最新のホスト状態を参照し、GUI からの変更とホスト操作拒否を Lua 側の結果へ反映する。
- [x] Lua 言語版 5.4.9 と旧 Plus の 5.1 系スクリプトの差、実装済みホスト API、未対応 API を `native/gui/SCRIPTING.md` と機能対応表に記す。配布スクリプトの静的確認を全実行成功と扱わない。
- [x] Lua 公式 5.4.9 のアーカイブを HTTPS で取得し、SHA-256 `2335b6c582a52654f94612bf10d2f4672805d05329aa6568b1d8cd9e5c6fb8e6` を検証してから展開する。不一致ではビルドを停止し、取得物・生成物は build 配下に置く。
- [x] Lua はアプリと同じ macOS 13.0 以上の `arm64` / `x86_64` 向けにソースからビルドして helper のみに静的リンクする。core は Lua に依存せず、完成アプリの起動に Homebrew・外部 Lua dylib を要求しない。両アーキテクチャのビルド結果と、実行できたアーキテクチャを区別して記録する。
- [x] Lua の原著作権と MIT 許諾を `native/gui/LUA_LICENSE.txt` に保持し、アプリの Resources に同梱する。旧 Plus のデータ・スクリプト・画像の許諾を Lua や公式 Mitaka ソースの MIT 許諾から推定しない。
- [x] 状態ファイルは最大 1 MiB の JSON v4 とし、版・型・列挙値・有限数値・範囲・観測地・表示状態・時間設定を検証してから適用する。惑星・恒星・格子・日時情報・描画品質・衛星可視性の表示設定も往復させる。衛星の選択 index を再読込後に復元しない。設定の永続化も同じ検証境界を使い、旧開発版 v1 / v2 / v3 を暗黙変換しない。実行可能コード、旧 Lua 状態、任意クラスのデシリアライズとして扱わない。
- [x] 状態復元では再生・飛行・実行中スクリプトを停止し、保存時に動作中だった処理を自動再開しない。不正・過大・非対応版の入力で直前の正常状態を失わず、失敗理由を表示する。
- [x] 画像・状態の GUI 出力は `preservation.md` の保全対象外とし、保存エラーを通知する。画像の形式・実解像度・アルファ対応、投影ウィンドウと原版の外部映像/Pro 機能との差を記載する。
- [x] 代表 API、未対応 API、構文・実行エラー、取消・時間制限、IPC 異常、状態の往復・異常入力、保全対象への出力拒否を確認する。ファイル・OS 操作試験は専用の一時領域で実施し、個別試験と全体アプリの操作結果を別に記録する。

## 不合格条件

- [ ] 一部のネイティブ操作、Lua API、テスト成功だけで旧 Plus 1.5.4 の全機能を再現したと記載している。
- [ ] URL やデータ配置を契機にローカルコードを自動実行するか、信頼済み Lua がユーザー権限を持つことを隠してサンドボックスと説明している。
- [ ] 未対応 API を無視する、型・範囲を検証せずホストへ適用する、GUI スレッドで Lua を実行する、または取消後も同じ helper が動作している。
- [ ] 固定ハッシュを検証しない Lua を使用する、core に Lua 依存を追加する、実行環境に Homebrew を要求する、または Lua の許諾を同梱しない。
- [ ] 状態入力がコードとして実行される、過大・不正入力で状態を一部だけ変更する、または復元によって停止していた処理を自動再開する。
- [ ] テスト未実施、統合未完了、原版との仕様差を隠して gate を YES としている。

## 判定

YES

## 判定根拠（UNIT4 / 2026-10-29-21-28-30 JST）

判定条件 20 件を確認した。不合格条件は今回の対象に該当せず、未チェックのまま残した。対象・共通証拠・制約は [VALIDATION.md](VALIDATION.md) に記録する。

- **[plus_compatibility](../../policy_gates/plus_compatibility.md) C1–C3（3 件）**: matrix の版と原典位置、今回の追加接続・不足・受入条件、UNIT4 README と本稿の対象 / 実施者 / 結果を照合。 原版の全機能完了とは記載しない。全体 Plus smoke は 3 構成で成功。clone / 最終保全 / 最終 gate も確定した。commit と wrapper 採用は後続作業として分ける。
- **plus_compatibility C4–C7（4 件）**: 明示した local HTML の同一 bytes、1 MiB、canonical path / device / inode / SHA-256、main frame / top / view / generation、64 KiB 一度 decode、通常遷移でも trust 失効。ページ JS 無効・isolated world・content rule / navigation cancel。[HTML 設計](../../investigation/native-plus/html-bridge-policy-design.md)。 個別 policy 80 checks、browser + helper 結合 73 checks / 3 host。資産・通常リンクで loopback TCP 0。全 scheme / redirect / cache 組合せを網羅したとは記載しない。compile callback 保留中 open / close と stale view navigation は読み取りレビューの範囲。
- **plus_compatibility C8–C16（9 件）**: 信頼済み Lua の io / os / package / debug、専用 helper、予算・中断、process group の制限、IPC strict、fresh host getter / toggle、5.4.9 差異、固定 archive SHA、arch static link、MIT 同梱。各構成 script-test と既存 Makefile / SCRIPTING、runSource 一時領域所有権の回帰。 process group 外へ離れた子や、既発生の副作用を巻き戻す機構とは説明しない。個別 HTML host の arch だけで helper arch 実行を主張しない。
- **plus_compatibility C17–C20（4 件）**: JSON v4 1 MiB strict・型 / 列挙 / 有限 / 範囲・品質 / 衛星 bool、旧版拒否、復元時停止、出力先制約。session / file I/O / script / controller / 通常全体 smoke で確認。 数値往復の比較だけを限定 ULP 許容へ変更し、製品値・型検証・構造一致を緩めていない。SAN full smoke の以前の失敗を残したうえで、開始境界修正後の 3 構成成功を記録。
