# UNIT4 衛星の太陽系表示・選択・追尾

確認日: 2026-10-29。UNIT3 `cf4fcbf` 後の UNIT4 作業ツリーを対象とする。
この記録は描画・ビューの担当範囲に限る。Plus 全機能の実装完了や原版との画素一致を意味しない。

## 実装済みの境界

- `SatelliteRenderer.h/.mm` は `SatelliteSnapshot.positions` の日心 J2000 黄道 AU を、既存の `project_solar` へ直接渡す。親位置の再加算、黄道回転、地月・冥王星補正を描画側で追加しない。
- 全行の index を snapshot と共有する。同じ位置・名前の重複行、言語別出典、位置未評価行を削除しない。描画・クリック対象だけを有効位置と表示範囲で絞る。位置が重なる行も一覧から個別に選択できる。
- `SolarSatellites.mm` はモデル・行数・有限 JD・全位置の有限性を検証してから状態を変更する。同じモデルの時刻更新では選択と追尾を保ち、モデル交換・解除では旧 index と追尾を消す。位置を失った場合はカメラを保持して追尾を停止し、後の位置復帰だけでは追尾を再開しない。
- 惑星・小天体・衛星の選択を排他にする。未評価の衛星を選択・中央移動しても視点を動かさず理由を表示する。衛星の表面観察・着陸・離陸・連続飛行は未対応として拒否する。
- 通常の太陽系全体表示で点・選択リング・選択名を描く。地球・月表示、表面表示、飛行中は表示しない。表示を切っても原行・選択を保持し、クリック対象から外す。
- 一覧操作とマーカーのクリックは `selectSatellite:` を共有する。`notifySelection` は衛星 index の変化を説明生成前に検出し、`satelliteSelectionChanged` callback へ通知する。惑星・小天体・空白への切替、モデル交換・解除は `NSNotFound` を通知し、App が親惑星を既定の出典へ戻せるようにする。同 index の再選択と同じモデルの時刻更新は通知しない。通知済み index を callback の前に保存するため、App の `setBodies:` が再入しても同じ変更を重複通知しない。親位置の計算自体は App / `satellite_scene` の責務で、別の試験記録を参照する。
- 点・選択リング・文字には既存 `RendererQualityScope` の種別を適用する。新しい描画ライブラリ、独自座標変換、原本への書き込みは追加していない。
- 既存の合成 smoke 5 箇所は衛星選択・可視性・通知済み index を一時退避して復元する。合成配置での一時的な解除によって App の親位置再計算を発火させず、試験用の惑星状態へ実データを混ぜない。

## 検証

`native/gui/tests/test_solar_satellites.mm` は独立した3行 fixture とオフスクリーン bitmap を使う。原行順・重複・絶対座標、実画素の品質差、選択リング・文字、追尾と位置喪失、相互排他、表示切替、クリック、モデル交換、不正入力時の状態保持、smoke 復元を確認した。
App と同じ `setBodies:` を callback 内から呼び、単回呼出し・説明通知前の順序・不正 index の非呼出し・クリック経路を確認した。さらに惑星・小天体・空白への切替、同 index 再選択、同モデル時刻更新、モデル交換後の同じ数値 index、繰返し解除、smoke 復元について変更通知の有無と回数を確認した。

| 構成 | 衛星描画・ビュー | 既存小天体ビュー | 結果 |
|---|---:|---:|---|
| arm64 通常、`-Werror` | 99 checks | 19 checks | exit 0 |
| arm64 ASan + UBSan、`-Werror` | 99 checks | 19 checks | exit 0 |
| x86_64、Rosetta、`-Werror` | 99 checks | 19 checks | exit 0 |

ASan は既存 GUI 方針に従い `ASAN_OPTIONS=detect_leaks=0` を指定した。
対象ディレクトリは `native/gui/build-unit4-satellite-scene` と末尾 `-san` / `-x86`。テストは前面ウィンドウを作らず、WindowServer の遮蔽・全画面遷移を検証しない。

最終変更通知修正後のログ:

- `/tmp/mitaka-unit4-satellite-selection-build.log`
- `/tmp/mitaka-unit4-satellite-selection-test.log`
- `/tmp/mitaka-unit4-satellite-selection-small-test.log`
- `/tmp/mitaka-unit4-satellite-selection-san-build.log`
- `/tmp/mitaka-unit4-satellite-selection-san-test.log`
- `/tmp/mitaka-unit4-satellite-selection-san-small-test.log`
- `/tmp/mitaka-unit4-satellite-selection-x86-build.log`
- `/tmp/mitaka-unit4-satellite-selection-x86-test.log`
- `/tmp/mitaka-unit4-satellite-selection-x86-small-test.log`

## 独立レビューと残る統合確認

`time_features` 担当が描画・選択・航行・smoke・テストを読み取りレビューし、追加 callback を含め修正必須の指摘なしと確認した。最終の解除通知修正についても通知済み index の先更新、モデル交換、同 index 非重複、再入、合成 smoke 5 箇所を再レビューし、修正必須の指摘なしと確認した。逆方向の独立レビューとして `SatelliteController.h/.mm` と `test_satellite_controller.mm` も確認し、非同期検索の世代管理、全行とページの区別、モデル交換前の旧 index 消去、非表示中の snapshot 更新・再表示について修正必須の指摘なしと報告した。`AppSatelliteSmokeTests.mm` の snapshot コピーによる出典差の再現、公開選択入口、JSON・カメラ・選択・原 snapshot の復元も読み取り確認したが、その実行結果は統合担当が記録する。

この時点の App 全体 smoke・実機 CUA・全 policy gate の最終判定は統合担当の範囲であり、この担当試験から成功したとは判定しない。衛星の物理的な表面表示、衛星軌道線、保存状態における衛星選択の復元、旧 Plus 全 Lua 衛星 API の互換性も、この変更の実装範囲に含まない。

## 変更管理

`git status`、担当ファイルの `git diff --numstat`、`git diff --check` を確認した。追加ファイルを含む担当差分は 300 行を超えるため、統合担当が品質改善・policy gate 確認後の UNIT4 commit に含める。この担当は stage / commit をしていない。担当の主要製品ファイルは `SatelliteRenderer.mm` 58 行、`SolarSatellites.mm` 80 行、`SolarSystemView.mm` 369 行、`SolarSystemNavigation.mm` 237 行、`SolarSystemSmokeTests.mm` 433 行で、衛星処理は独立した category と renderer に閉じている。

`IMPLEMENTATION_POLICY.md` / `policy_gates/` と skill の最終確認は統合担当へ引き継ぐ。新規依存なし。ローカル原本・独自データの変換、削除、画像再保存は行っていない。
