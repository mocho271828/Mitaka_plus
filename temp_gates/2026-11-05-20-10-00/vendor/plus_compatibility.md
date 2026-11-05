# Gate: Plus 互換・ローカルスクリプト・状態保存

## 目的

原版との差を追跡できる形で機能を追加し、部分実装を全機能互換と誤認させない。ユーザーが許可したローカル Lua の権限、アプリの応答性、状態入力と出力の境界を維持する。

## 判定条件

- [x] `PLUS_FEATURE_MATRIX.md` は Windows 1.5.4 build101013 の README / `gui.lua` と、1.3.0 表示の同梱 API 説明書を区別する。機能 ID、原典の読取位置、現在の実装根拠、不足、受入条件を記載する。
  - 判定根拠: 確認。PLUS_FEATURE_MATRIX.md 冒頭と各行に出典、機能 ID、現状・不足・受入条件を記載。
- [x] 実装した機能だけ対応状況を更新し、予定・未確定仕様・Pro 専用機能を区別する。ネイティブ UI の実装だけを根拠に Lua API や配布スクリプトを互換と判定しない。
  - 判定根拠: 確認。PLUS_FEATURE_MATRIX.md 冒頭に部分・未実装・Pro 対象外の判定基準と Lua 判定の分離を記載。
- [ ] 記録には対象コミットまたは作業ツリーの時点、試験の実施者・結果、統合ビルドと GUI 操作の確認範囲を残す。未実行の試験を成功と記載せず、通常 Plus の不足が残る間は全機能完了と説明しない。
  - 判定根拠: 未確認。PLUS_FEATURE_MATRIX.md には旧時点と作業範囲の記録がある。今回 build・test・data-test・reference-test・smoke は成功し VALIDATION.md に範囲を記録。ただし個々の試験の実施者と作業ツリー時点の明示は未確認。
- [x] Lua はユーザーが明示選択した信頼済みローカル通常ファイル、または下記条件を満たす信頼済みローカル HTML の明示クリックだけを受け付ける。起動時の `init.lua`、URL、オンライン HTML / JavaScript / `mtkp://` から自動で実行しない。
  - 判定根拠: 確認。unit7/README.md の script 試験・native/gui/SCRIPTING.md の明示選択および init 自動実行禁止。今回実行入口は未変更。
- [x] HTML から Lua を呼ぶ機能を追加する場合、明示的に信頼したローカル HTML に限定する。オンライン文書・フレーム・遷移先には実行権限を与えず、信頼したローカルページから権限を継承させない。未接続の段階では対応済みと記載しない。
  - 判定根拠: 確認。unit7/README.md の HTML 試験・html-bridge-policy-design.md。今回 HTML 信頼境界は未変更。
- [x] 信頼済み HTML は最大 1 MiB の通常ファイルとして同じ原バイト列を検証・表示する。main frame・表示文書・ファイル同一性を確認してから最大 64 KiB の `mtkp://` ソースを一度だけ復号し、別 helper へ渡す。読み替え・遷移・閉じる時は信頼を破棄する。
  - 判定根拠: 確認。unit7/README.md の HTML 試験・html-bridge-policy-design.md の byte/size と信頼破棄契約。今回 HTML 層は未変更。
- [x] ローカル HTML のページ JavaScript を無効化し、リンク受信は分離した WebKit content world で行う。外部ネットワークの文書・画像・CSS・サブフレームを遮断する。ローカル文書へ遷移する場合も別途明示信頼を必要とする。
  - 判定根拠: 確認。unit7/README.md の HTML 試験・html-bridge-policy-design.md の content world と外部参照制限。今回 HTML 層は未変更。
- [x] ユーザーが許可した Lua 標準ライブラリの `io` / `os` / `package` / `debug` を利用できる。本人の権限でファイル・外部コマンドを操作できることと、OS サンドボックスではないことを実行 UI と文書で説明する。
  - 判定根拠: 確認。native/gui/README.md と SCRIPTING.md に標準ライブラリ権限と非サンドボックスを明記。unit7 で script 試験済み。
- [x] Lua は専用 helper プロセスで動かし、GUI スレッドをブロックしない。入力・メッセージのサイズ上限、Lua メモリ・命令数・実行時間の上限、GUI 側の終了期限を設け、取消・エラー・正常終了後に実行状態を解放する。
  - 判定根拠: 確認。unit7/README.md の script 試験と SCRIPTING.md の helper と上限。今回 helper は未変更。
- [x] 取消時は helper と同じプロセス群を停止する。既に生じたファイル変更・ホスト操作と、別のプロセス群へ離脱した処理を巻き戻せないことを明記し、プロセス分離を権限制限と説明しない。
  - 判定根拠: 確認。SCRIPTING.md の取消・副作用の制限と unit7 の script 試験。今回 helper は未変更。
- [x] ホスト API の引数・返値・操作対象を IPC 境界で検証し、未対応 API や拒否操作は明示的なエラーにする。成功したふりをする空の互換メソッドを作らず、ファイル名・行・実行時トレースまたは原因を確認できる。
  - 判定根拠: 確認。unit7 の script 試験と PLUS_FEATURE_MATRIX.md の未対応 API 境界。今回 IPC 実装は未変更。
- [x] Time / Stars / Planets / Grids / Renderer / GUI と Asteroids / TNObjects / Comets / Satellites の対応する真偽値、Stars の 3 種と Milkyway の 4 種と Planets.atmosphere の 3 種の列挙値を厳密に検証する。getter / toggle は最新のホスト状態を参照し、GUI からの変更とホスト操作拒否を Lua 側の結果へ反映する。未確定の名前指定 show / hide / isVisible を実装済みと扱わない。
  - 判定根拠: 確認。今回 make test・smoke 成功。unit7/README.md の Lua 表示設定・拒否と PLUS_FEATURE_MATRIX.md の未確定 API 記録。
- [x] Stars の brightness は正の有限 float、時間付き変更の duration は有限・非負として検証する。名称選択の文字列 HIP と引数数を検証し、未知 HIP の Lua 動作と厳密な native/session 拒否を区別する。Constels.illusts と地球・大気設定は共通ホスト状態へ適用する。
  - 判定根拠: 確認。今回 make test・smoke 成功。unit6/README.md の恒星・大気設定と Lua の入力検証記録。
- [x] Lua 言語版 5.4.9 と旧 Plus の 5.1 系スクリプトの差、実装済みホスト API、未対応 API を `native/gui/SCRIPTING.md` と機能対応表に記す。配布スクリプトの静的確認を全実行成功と扱わない。
  - 判定根拠: 確認。native/gui/SCRIPTING.md と PLUS_FEATURE_MATRIX.md に Lua 5.4.9、API、未対応・全実行成功ではない旨を記載。
- [x] 同梱した Lua 公式 5.4.9 のアーカイブの SHA-256 `2335b6c582a52654f94612bf10d2f4672805d05329aa6568b1d8cd9e5c6fb8e6` を検証してから展開する。不一致ではビルドを停止し、生成物は build 配下に置く。ビルドにネットワーク取得を必要としない。
  - 判定根拠: 確認。tools/build_lua.sh の固定 SHA-256 と native/gui/SCRIPTING.md の offline 構築手順。unit7 で各構成 build 成功、今回 Lua build 層は未変更。
- [x] Lua はアプリと同じ macOS 13.0 以上の `arm64` / `x86_64` 向けにソースからビルドして helper のみに静的リンクする。core は Lua に依存せず、完成アプリの起動に Homebrew・外部 Lua dylib を要求しない。両アーキテクチャのビルド結果と、実行できたアーキテクチャを区別して記録する。
  - 判定根拠: 確認。unit7/README.md の arm64 と x86_64/Rosetta の build/test、SCRIPTING.md の静的リンク範囲。今回 Lua build 層は未変更。
- [x] Lua の原著作権と MIT 許諾を `native/gui/LUA_LICENSE.txt` に保持し、アプリの Resources に同梱する。旧 Plus のデータ・スクリプト・画像の許諾を Lua や公式 Mitaka ソースの MIT 許諾から推定しない。
  - 判定根拠: 確認。LUA_LICENSE.txt と GUI Makefile の bundle コピー、SCRIPTING.md のライセンス説明。unit7 の既存 build を確認。
- [x] 状態ファイルは最大 1 MiB の JSON v9 とし、版・型・列挙値・有限数値・範囲・観測地・表示状態・時間設定を検証してから適用する。既存表示設定に加え、表示半径の4倍率と mode、探査機 4 項目、小天体の種類別設定・表示集合・軌道標本設定、衛星の 4 設定・表示集合、星座の既定値と例外集合・星座絵、恒星の明るさ・名称選択集合、地球の雲・夜景、大気の mode/intensity を往復させる。クリック選択の一時 index を復元しない。旧開発版 v1〜v8 を暗黙変換せず、実行可能コードや任意クラスのデシリアライズとして扱わない。
  - 判定根拠: 確認。今回 make test・smoke 成功。VALIDATION.md に session v9 の検証記録、unit7/README.md の既存状態復元と不正入力試験。
- [x] 小天体・衛星の保存 ID は canonical base64 の出典と原行 ordinal、ロード済み原出典の SHA-256 とバイト数で照合する。星座は原略号バイト列の ID を照合し、全ファイルのハッシュ一致を要求しない。恒星名は読み込んだ名称表の正の int32 HIP を検証する。未知・重複 ID、出典不一致、軌道予算超過を適用前に拒否する。
  - 判定根拠: 確認。今回 make test・smoke 成功。unit5/README.md の ID・出典・予算超過の拒否試験と v9 session 試験。
- [ ] アプリ設定の復元も JSON と同じ検証を通す。データ読込前の復元は全モデル接続後まで保留し、失敗した保留設定を既定値で自動上書きしない。
  - 判定根拠: 未確認。保留設定・失敗時保持の全経路を現行版で網羅未確認。
- [x] JSON v9 は食の4フラグ・風景表示・Plus の刻み enum/日数/speed を独立に往復する。地点 ID は canonical base64 の原 bytes とローカル地点の緯度経度を照合し、未知 ID・座標不一致・overflow を適用前に拒否する。復元時の Plus speed は 0 とする。
  - 判定根拠: 確認。今回 make test・smoke 成功。VALIDATION.md の v9 と unit7/README.md の地点・食・時間復元試験。
- [ ] 有効な状態復元では再生・飛行・実行中スクリプト・恒星明るさの補間を停止し、保存時に動作中だった処理を自動再開しない。不正・過大・非対応版の入力で直前の正常状態を失わず、不正入力で進行中の補間を取り消さず、失敗理由を表示する。
  - 判定根拠: 未確認。有効・無効復元と進行中処理の全組合せは今回網羅未確認。
- [x] 画像・状態の GUI 出力は `preservation.md` の保全対象外とし、保存エラーを通知する。画像の形式・実解像度・アルファ対応、投影ウィンドウと原版の外部映像/Pro 機能との差を記載する。
  - 判定根拠: 確認。unit7 の出力境界の既存試験と native/gui/README.md の画面出力・原版差。今回ファイル出力層は未変更。
- [ ] 代表 API、未対応 API、構文・実行エラー、取消・時間制限、IPC 異常、状態の往復・異常入力、保全対象への出力拒否を確認する。ファイル・OS 操作試験は専用の一時領域で実施し、個別試験と全体アプリの操作結果を別に記録する。
  - 判定根拠: 未確認。既存 script/session 個別試験と過去の smoke 記録はあるが今回 make test・smoke は成功。全列挙した IPC 異常・出力拒否と結果記録の個別照合は未確認。

## 不合格条件

- [ ] 一部のネイティブ操作、Lua API、テスト成功だけで旧 Plus 1.5.4 の全機能を再現したと記載している。
  - 判定根拠: 非該当。PLUS_FEATURE_MATRIX.md と feature-priorities.md に部分実装と未完を記載。
- [ ] URL やデータ配置を契機にローカルコードを自動実行するか、信頼済み Lua がユーザー権限を持つことを隠してサンドボックスと説明している。
  - 判定根拠: 該当を確認していない。非該当と断定するための全経路監査も未完了。
- [ ] 未対応 API を無視する、型・範囲を検証せずホストへ適用する、GUI スレッドで Lua を実行する、または取消後も同じ helper が動作している。
  - 判定根拠: 該当を確認していない。非該当と断定するための全経路監査も未完了。
- [ ] 固定ハッシュを検証しない Lua を使用する、core に Lua 依存を追加する、実行環境に Homebrew を要求する、または Lua の許諾を同梱しない。
  - 判定根拠: 非該当。unit7/README.md の既存ビルド記録、tools/build_lua.sh と GUI Makefile の固定ハッシュ・静的リンク・許諾同梱。今回これらを変更していない。
- [ ] 状態入力がコードとして実行される、過大・不正入力で状態を一部だけ変更する、または復元によって停止していた処理を自動再開する。
  - 判定根拠: 該当を確認していない。非該当と断定するための全経路監査も未完了。
- [ ] テスト未実施、統合未完了、原版との仕様差を隠して gate を YES としている。
  - 判定根拠: 該当を確認していない。非該当と断定するための全経路監査も未完了。

## 判定

NO（未確認条件が残るため。未確認を違反の確認とは扱わない。）
