# Gate: 共通実装と依存関係

## 目的

他リポジトリへの取得時依存を避け、同梱コードの由来と更新を追跡できるようにする。

## 判定条件

- [x] 共通コア・GUI は `vendor/mitaka/` に通常ファイルとして含まれ、Git submodule の取得を必要としない。
  - `git ls-files --stage vendor/mitaka` に gitlink（160000）はなく、`.gitmodules` の追跡もない。共通コード・試験は `vendor/mitaka/native` の通常ファイル。
- [x] 同梱コードの採用元と基準 commit が文書に記録されている。
  - README「採用した共通実装の検証」が共通側の SHA を記録する。今回の基点は #8 の `8335aba`。差分の出典は `54f75fe`、`8822e19`、`a5c9ce4`、`35089e9`、`2318686`。
- [x] Makefile は本リポジトリ内のビルドターゲットを使用する。
  - ルート Makefile は `vendor/mitaka/native/core` と `vendor/mitaka/native/gui` のターゲットを呼び、GUI の helper も同梱ツリーでビルドする。
- [x] 新たな依存を追加した場合、必要性と既存依存では不十分な理由を記録している。
  - 採用対象は AppKit、Foundation、既存 C++、同梱 Lua 5.4.9 を利用する。変更一覧に依存管理ファイル、新しいアーカイブ、ランタイム取得処理はない。
- [x] README に現在の実装の由来と、旧 Mitaka_plus の公式ソースを含まないことを明記している。
  - README 冒頭に通常版 Mitaka 1.3.1 を由来とするコア、新規の native GUI、および旧 Plus の公式ソースを含まない旨がある。
- [x] Lua は同梱した固定 SHA-256 の公式ソースを検証して使用し、helper へ静的リンクする。独自の Lua 処理系や外部 dylib の実行依存を追加しない。
  - `native/gui/tools/build_lua.sh` が同梱 tar.gz を SHA-256 検証し、GUI Makefile の `SCRIPT_HELPER` が `LUA_LIBRARY` をリンクする。追加のコンソール評価コードも同じ Lua ヘッダとライブラリを使う。
- [x] 旧 Plus の互換状況は共通の機能対応表を参照し、未対応のある状態で全機能完了と記載していない。
  - `vendor/mitaka/PLUS_FEATURE_MATRIX.md` と `investigation/native-plus/feature-priorities.md` の対象 ID を照合。UI-04 は4項目の設定画面、LUA-03 は native 実装、UI-07 は PDF/CHM の所在監査、LUA-04 は互換性の監査であり、それぞれの旧版比較を別に記録する。
- [x] Lua コンソールは既存 helper の権限・取消・実行制限を共用し、入力ごとに独立した Lua 環境を使う。入力履歴はプロセス内で上限を持ち、自動実行・永続化しない。
  - `ScriptController.mm` の `runConsoleSource` は同じジョブの取消経路を使用し、`ScriptWorker.mm` は helper 起動ごとに `lua_newstate`、`ScriptConsoleController.mm` は履歴100件・1 Mi文字を上限にする。今回の `first/test.log` で UI 29 checks と helper 実行試験が成功し、`first/smoke.log` の Script AppKit も成功した。専用の手動操作は採用元 `54f75fe` の記録。
- [x] HTML の Lua 呼出しを追加する場合、明示的に信頼したローカル HTML だけに許可し、オンライン文書・フレーム・遷移先から実行させない。
  - `AppScripting.mm` のコンソールと `HtmlBrowserController.scriptRequested` は別の入口であり、HTML は明示選択したローカル文書について既存の検証を通す。コンソール実行を HTML 用 callback として登録していない。
- [x] HTML の実行は同一読み取りの内容・ファイル識別・メインページ・表示世代を検証し、通常リンク操作やファイル変更で信頼を失効させる。ページ JavaScript・Flash を有効にしない。
  - `HtmlBrowserController.mm` は文書識別、メインページと表示世代を検査し、`allowsContentJavaScript = NO` を設定する。HTML ポリシーとブラウザ本体は今回の変更対象に含まれない。
- [x] 描画品質、小天体・衛星の設定と表示集合、軌道標本化、探査機表示、星座集合・星座絵、恒星名選択・明るさ、地球層・大気、食・風景・旧Plus時間状態は共通モデルを使い、全画面/About は共通ウィンドウ処理へ委譲する。
  - 新しい設定画面は `RendererDisplayOptions` と `setRendererDisplayOptions:` を既存画面・Lua と共有する。`ebca717` の `first/test.log` で設定 controller 107 checks 成功。`first/smoke.log` は画質4項目、衛星選択、レイヤー、状態復元を通過した。専用の手動操作は採用元 `a5c9ce4` の記録。
- [x] JSON v9 の保存範囲と旧開発版 v1〜v8 の拒否を記載する。復元は停止状態とし、一時的な小天体・衛星・探査機のクリック選択、全画面・HTML 信頼・実行状態を復元しない。
  - `session_state.mm` は version を9に制限し、`AppSessionCommands.mm` は移動・速度を停止して復元する。新しい Lua コンソールと履歴を session codec へ追加する変更はない。
- [x] JSON v9 は未知・重複 ID、参照出典の SHA-256・バイト数、軌道標本上限などを全体の適用前に検証し、失敗した状態を部分適用しない。
  - `session_layers.mm` は元データの SHA-256・byte_count と ID の重複を検査する。`AppSessionCommands.mm` は表示レイヤーの事前検証を行い、後から適用する。上限と出典を検証するコードに変更はない。
- [x] 種別表示の全体スイッチと表示集合への限定を区別し、名称・軌道もその可視性に従う。旧 Lua の英語名を使う集合 API を、確定した名前解決なしに対応済みと記載しない。
  - `session_layers_json.mm` に visible / labels / orbits / selected_only が別々に保存され、`PLUS_FEATURE_MATRIX.md` の OBJ-14 には名前指定 API の残件が残る。
- [x] JSON v9 の恒星名 HIP は読込済み名称表で検証し、明るさ・地球層・大気を全体検証後に復元する。不正入力で既存の明るさ補間や正常状態を失わない。
  - `AppSessionCommands.mm` の `prepare_display_layers` はコピーした星名モデルに HIP 選択を適用する。既存の明るさ補間を取り消す処理は事前検証後にある。
- [x] 表示半径の4倍率と mode を共通モデルから UI・Lua・模式描画・JSON v9 で共有し、不正な値を拒否する。月の模式位置・軌道線への倍率と物理計算を分離し、未対応の `KEEP_RADIUS` による宇宙倍率変更・倍率補間・原版との画素一致を明示する。
  - `native/gui/src/radius_display.cpp`、`AppSessionCommands.mm` の `validate_radius_for_restore` と `IMPLEMENTATION_POLICY.md` の倍率条件を確認した。統合対象の画質4項目は天体の表示半径・暦表を変更しない。
- [x] 食の4設定・風景・時間設定・原地点IDを保存し、IDと座標を全体適用前に検証する。復元で通常再生・時計追従・旧Plus連続再生を開始しない。
  - `AppSessionCommands.mm` は食・原観測地点・風景を保存し、復元時には `plus_time.speed` を 0 にする。`session_state.mm` が位置と値域を検証する。日時の動作再検証は通常回帰の対象。
- [x] 遠方の共有カメラ対象の pc 基準と AU 差分を描画・選択・移動で共有する。JSON v9 は `solar_camera.precise_target` に両値を組で保存し、従来の近似 AU `target` も残す。精密値がない既存 v9 は `target` を使い、精密値がある場合はそれを優先し、不完全または非有限な値は状態全体の適用前に拒否する。
  - `session_state.mm` が precise_target を anchor_pc と offset_au の組で読み書きし、従来の target も記録する。#8 の共有カメラと `session_state` のコードは今回の UI・監査・地形回帰の移植対象外。
- [x] 共有カメラのロールと任意姿勢の基底を太陽系・銀河の視点と JSON v9 に引き継ぎ、通常視点と地表・飛行の投影条件を分離する。地球地平図のロールを `horizon_viewport.roll_deg` に保存し、項目がない既存 v9 は 0 度で読み込む。縦画角を `horizon_viewport.fov_deg` に保存し、既存の `zoom` も保持する。`fov_deg` がない v9 は `180 / zoom` で復元し、両方ある場合は `fov_deg` を優先する。ロールや投影区分のない既存 v9 は、それぞれ 0 度と従来の地表・飛行用基底として読み込む。
  - `session_state.mm` の roll_deg / frame_is_orbit / fov_deg と、FOV 不在時に 180 / zoom とする読み込みを確認した。`AppSessionCommands.mm` と `session-surface-state.md` が #8 の地表状態と姿勢の復元を扱う。

## 不合格条件

- [ ] ビルド時に別リポジトリからコードを取得する。
  - ルート・GUI Makefile と同梱 Lua の build script を確認した。
- [ ] 同梱コードの由来を追跡できない。
  - 採用元と統合の基点は上記のとおり。

## 判定

YES
