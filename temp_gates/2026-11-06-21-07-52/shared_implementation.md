# Gate: 共通実装と依存関係

## 目的

他リポジトリへの取得時依存を避け、同梱コードの由来と更新を追跡できるようにする。

## 判定条件

- [x] 共通コア・GUI は `vendor/mitaka/` に通常ファイルとして含まれ、Git submodule の取得を必要としない。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] 同梱コードの採用元と基準 commit が文書に記録されている。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] Makefile は本リポジトリ内のビルドターゲットを使用する。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] 新たな依存を追加した場合、必要性と既存依存では不十分な理由を記録している。
  - 判定: YES。Git 差分に依存定義や Makefile の変更はなく、FOV 差分で新しいライブラリを追加していない。
- [x] README に現在の実装の由来と、旧 Mitaka_plus の公式ソースを含まないことを明記している。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] Lua は同梱した固定 SHA-256 の公式ソースを検証して使用し、helper へ静的リンクする。独自の Lua 処理系や外部 dylib の実行依存を追加しない。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] 旧 Plus の互換状況は共通の機能対応表を参照し、未対応のある状態で全機能完了と記載していない。
  - 判定: YES。PLUS_FEATURE_MATRIX.md と feature-priorities.md は CAM-03 と P1-1 を部分実装、旧 Plus 比較を未実施と記載する。
- [x] HTML の Lua 呼出しを追加する場合、明示的に信頼したローカル HTML だけに許可し、オンライン文書・フレーム・遷移先から実行させない。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] HTML の実行は同一読み取りの内容・ファイル識別・メインページ・表示世代を検証し、通常リンク操作やファイル変更で信頼を失効させる。ページ JavaScript・Flash を有効にしない。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] 描画品質、小天体・衛星の設定と表示集合、軌道標本化、探査機表示、星座集合・星座絵、恒星名選択・明るさ、地球層・大気、食・風景・旧Plus時間状態は共通モデルを使い、全画面/About は共通ウィンドウ処理へ委譲する。
  - 判定: YES。既存の根拠は前回 gate、変更後の回帰は `make test` と `make smoke` の成功を参照。
- [x] JSON v9 の保存範囲と旧開発版 v1〜v8 の拒否を記載する。復元は停止状態とし、一時的な小天体・衛星・探査機のクリック選択、全画面・HTML 信頼・実行状態を復元しない。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] JSON v9 は未知・重複 ID、参照出典の SHA-256・バイト数、軌道標本上限などを全体の適用前に検証し、失敗した状態を部分適用しない。
  - 判定: YES。既存の根拠は前回 gate、変更後の回帰は `make test` と `make smoke` の成功を参照。
- [x] 種別表示の全体スイッチと表示集合への限定を区別し、名称・軌道もその可視性に従う。旧 Lua の英語名を使う集合 API を、確定した名前解決なしに対応済みと記載しない。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] JSON v9 の恒星名 HIP は読込済み名称表で検証し、明るさ・地球層・大気を全体検証後に復元する。不正入力で既存の明るさ補間や正常状態を失わない。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] 表示半径の4倍率と mode を共通モデルから UI・Lua・模式描画・JSON v9 で共有し、不正な値を拒否する。月の模式位置・軌道線への倍率と物理計算を分離し、未対応の `KEEP_RADIUS` による宇宙倍率変更・倍率補間・原版との画素一致を明示する。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] 食の4設定・風景・時間設定・原地点IDを保存し、IDと座標を全体適用前に検証する。復元で通常再生・時計追従・旧Plus連続再生を開始しない。
  - 判定: YES（差分と既存記録）。今回の関連する変更を確認し、既存条件の根拠は temp_gates/2026-11-06-20-33-32/shared_implementation.md を参照。共通条件の根拠は前回 gate。最終回帰は `make test` と `make smoke` に成功。
- [x] 共有カメラのロールと任意姿勢の基底を太陽系・銀河の視点と JSON v9 に引き継ぎ、通常視点と地表・飛行の投影条件を分離する。地球地平図のロールを `horizon_viewport.roll_deg` に保存し、項目がない既存 v9 は 0 度で読み込む。縦画角を `horizon_viewport.fov_deg` に保存し、既存の `zoom` も保持する。`fov_deg` がない v9 は `180 / zoom` で復元し、両方ある場合は `fov_deg` を優先する。ロールや投影区分のない既存 v9 は、それぞれ 0 度と従来の地表・飛行用基底として読み込む。
  - 判定: YES。session_state.mm で fov_deg・zoom の保存、fov_deg 優先と 180 / zoom の旧 v9 読込を確認。姿勢・状態の最終回帰は `make test` と `make smoke` に成功。


## 不合格条件

- [ ] ビルド時に別リポジトリからコードを取得する。
- [ ] 同梱コードの由来を追跡できない。

## 判定

YES（今回の変更および既存記録に基づく）

不合格条件への該当は確認されていない。`make smoke` と実画面の地平図・45° 復帰は確認済み。旧 Plus 比較は未実施。
