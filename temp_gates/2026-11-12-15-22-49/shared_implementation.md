# Gate: 共通実装と依存関係

## 目的

他リポジトリへの取得時依存を避け、同梱コードの由来と更新を追跡できるようにする。

## 判定条件

- [x] 共通コア・GUI は `vendor/mitaka/` に通常ファイルとして含まれ、Git submodule の取得を必要としない。
  - git ls-files --stage -- vendor/mitaka の2,027件はすべて mode 100644。gitlink は0件。
- [x] 同梱コードの採用元と基準 commit が文書に記録されている。
  - README の「採用した共通実装の検証」と vendor/mitaka/SOURCE_AVAILABILITY.md が採用版の根拠。今回の実画面比較の起点は GitHub の PR #8 と同じ 0269774。
- [x] Makefile は本リポジトリ内のビルドターゲットを使用する。
  - ルート Makefile の MITAKA は vendor/mitaka。build・test はその native/gui と native/core の Makefile へ渡す。
- [x] 新たな依存を追加した場合、必要性と既存依存では不十分な理由を記録している。
  - 放射吸収モデルの範囲判定、銀河の選択表示、HIP 描画の最適化はいずれも既存の C++/AppKit を使う。製品の Makefile・依存アーカイブへの差分はない。
- [x] README に現在の実装の由来と、旧 Mitaka_plus の公式ソースを含まないことを明記している。
  - README 冒頭が同梱コード・実データの場所を示し、9行目に旧 Mitaka_plus の公式ソースを含まないと記す。
- [x] Lua は同梱した固定 SHA-256 の公式ソースを検証して使用し、helper へ静的リンクする。独自の Lua 処理系や外部 dylib の実行依存を追加しない。
  - native/gui/tools/build_lua.sh のアーカイブ照合と native/gui/Makefile の liblua.a を参照した。今回の GUI 差分に helper・リンク定義はない。
- [x] 旧 Plus の互換状況は共通の機能対応表を参照し、未対応のある状態で全機能完了と記載していない。
  - P1-1 の機能表・優先順位表と VALIDATION.md の実画面記録を照合した。実データの往復を試した条件は JD 2451545、画角45°、地球・M31。旧 Plus の画素比較、他の日時と姿勢、画像 atlas、測光・密度は未確認のまま記述した。
- [x] Lua コンソールは既存 helper の権限・取消・実行制限を共用し、入力ごとに独立した Lua 環境を使う。入力履歴はプロセス内で上限を持ち、自動実行・永続化しない。
  - ScriptConsoleController.mm の履歴上限は100件。実画面の操作には既存の明示実行コンソールを使った。ScriptController・ScriptWorker・履歴モデルの差分はない。
- [x] HTML の Lua 呼出しを追加する場合、明示的に信頼したローカル HTML だけに許可し、オンライン文書・フレーム・遷移先から実行させない。
  - html_bridge_policy.mm の trust と activated link/main frame の判定を確認した。この変更の起点は銀河の描画要求であり、HTML 入口は変更していない。
- [x] HTML の実行は同一読み取りの内容・ファイル識別・メインページ・表示世代を検証し、通常リンク操作やファイル変更で信頼を失効させる。ページ JavaScript・Flash を有効にしない。
  - HtmlBrowserController.mm はメインフレームを確認し、html_bridge_policy.mm がファイル識別を再照合する。両ファイルの Git 差分は空。
- [x] 描画品質、小天体・衛星の設定と表示集合、軌道標本化、探査機表示、星座集合・星座絵、恒星名選択・明るさ、地球層・大気、食・風景・旧Plus時間状態は共通モデルを使い、全画面/About は共通ウィンドウ処理へ委譲する。
  - 変更箇所は既存の GalaxyOverlay、OurGalaxyRadiativeRenderer、HipSpatialRenderer、SolarSystemView の選択マーカーと各回帰試験。別 UI の画質・全画面・レイヤー設定モデルの差分はない。
- [x] JSON v9 の保存範囲と旧開発版 v1〜v8 の拒否を記載する。復元は停止状態とし、一時的な小天体・衛星・探査機のクリック選択、全画面・HTML 信頼・実行状態を復元しない。
  - IMPLEMENTATION_POLICY の JSON v9 条件、session_state.mm と AppSessionCommands.mm の復元経路を参照。セッション形式・再生制御の差分はない。
- [x] JSON v9 は未知・重複 ID、参照出典の SHA-256・バイト数、軌道標本上限などを全体の適用前に検証し、失敗した状態を部分適用しない。
  - session_layers_json.mm に出典別 byte_count / sha256 がある。前回の同一コードの受入は temp_gates/2026-11-12-14-41-11/ にあり、状態適用前の検証ロジックには差分なし。
- [x] 種別表示の全体スイッチと表示集合への限定を区別し、名称・軌道もその可視性に従う。旧 Lua の英語名を使う集合 API を、確定した名前解決なしに対応済みと記載しない。
  - small_body_display.cpp・satellite_display.cpp と PLUS_FEATURE_MATRIX の対象別の可視性を確認。今回の描画差分に小天体・衛星の名称や軌道の選択規則は含まれない。
- [x] JSON v9 の恒星名 HIP は読込済み名称表で検証し、明るさ・地球層・大気を全体検証後に復元する。不正入力で既存の明るさ補間や正常状態を失わない。
  - star_name_selection.cpp・session_layers.mm、恒星名・明るさの状態復元は変更対象外。統合基点での根拠は前回の shared_implementation.md の対応条件。
- [x] 表示半径の4倍率と mode を共通モデルから UI・Lua・模式描画・JSON v9 で共有し、不正な値を拒否する。月の模式位置・軌道線への倍率と物理計算を分離し、未対応の `KEEP_RADIUS` による宇宙倍率変更・倍率補間・原版との画素一致を明示する。
  - radius_display.cpp と RadiusDisplayController.mm に変更はない。IMPLEMENTATION_POLICY は4倍率の模式描画への適用と KEEP_RADIUS の未対応条件を区別する。
- [x] 食の4設定・風景・時間設定・原地点IDを保存し、IDと座標を全体適用前に検証する。復元で通常再生・時計追従・旧Plus連続再生を開始しない。
  - AppSessionCommands.mm の復元経路と session_layers_json.mm の保存構造に差分なし。食・風景・時刻・原地点の既存復元試験は今回の描画修正と別に扱う。
- [x] 遠方の共有カメラ対象の pc 基準と AU 差分を描画・選択・移動で共有する。JSON v9 は `solar_camera.precise_target` に両値を組で保存し、従来の近似 AU `target` も残す。精密値がない既存 v9 は `target` を使い、精密値がある場合はそれを優先し、不完全または非有限な値は状態全体の適用前に拒否する。
  - shipping-full の実画面80枚で地上2枚を除く78枚すべての表示カメラと要求が一致。往復共通11距離の完成地図は各2,039,824画素のRGBが同一で、M31 原行6の黄輪は3区間×3段階の実画像で各48/48方向に見える。shared_camera と JSON v9 の精密座標復元処理に差分なし。
- [x] 共有カメラのロールと任意姿勢の基底を太陽系・銀河の視点と JSON v9 に引き継ぎ、通常視点と地表・飛行の投影条件を分離する。地球地平図のロールを `horizon_viewport.roll_deg` に保存し、項目がない既存 v9 は 0 度で読み込む。縦画角を `horizon_viewport.fov_deg` に保存し、既存の `zoom` も保持する。`fov_deg` がない v9 は `180 / zoom` で復元し、両方ある場合は `fov_deg` を優先する。ロールや投影区分のない既存 v9 は、それぞれ 0 度と従来の地表・飛行用基底として読み込む。
  - session_state.mm では roll_deg の存在を確認し、fov_deg がない地平 viewport は 180 / zoom へ戻す。カメラ値の受け渡しと保存形式に差分はない。

## 不合格条件

- [ ] ビルド時に別リポジトリからコードを取得する。
  - ビルド対象は同梱コア・GUI と固定 Lua ソース。外部 clone/fetch を行うビルド規則の追加はない。
- [ ] 同梱コードの由来を追跡できない。
  - 実画面開始時の PR #8 の head と現地で照合した git rev-parse HEAD はいずれも 0269774。README の同梱元と今回の比較の基点が特定できる。

## 判定

YES
