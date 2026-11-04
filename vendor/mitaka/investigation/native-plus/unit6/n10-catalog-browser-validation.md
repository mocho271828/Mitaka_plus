# N10 恒星名集合のブラウザー操作と検証

2026-10-29。この記録は CatalogBrowserController の N10 操作境界と専用ビルドを対象にする。UNIT6 の統合検証・実ウィンドウ試験の結果を先取りしない。

## 操作境界

恒星行のチェックボックスは、現在読み込んだ星名表に HIP が存在し、かつ呼出元の `starNameSelectable` が許可する場合だけ有効にする。`setModel` で HIP 索引を更新するため、古い callback が残ったままカタログを解除・交換しても、旧行を編集できない。索引には既存の標準ライブラリ `std::set` を用い、永続化や原本データの変更は行わない。

「恒星名を全選択」「恒星名を全解除」は検索結果だけを対象にせず、呼出元の既知 HIP 集合全体への操作を委譲する。現在の星名表が空、または callback がない場合は無効にする。恒星と星座の操作は現在の kind を明示的に分岐し、恒星 callback の欠落を星座 callback で補わない。

恒星の選択・中央表示と、恒星名を表示する HIP 集合は独立する。既存の検索 generation と検索開始時の行消去を保持し、非同期検索が完了する前の古い行やモデル解除前の結果を採用しない。

## 追加した回帰

`native/gui/tests/test_catalog_browser_controller.mm` は実ローカル恒星表の HIP を使い、星名だけを 2 件の合成表に限定して次を検査する。

- 星名検索で絞っても「全選択」は全既知 HIP に作用し、恒星の選択・中央表示と相互に集合を変更しない。
- 名のない HIP、範囲外行、検索待機中の旧行は編集できない。
- callback 欠落時の旧ボタン操作は星座 callback に流入しない。
- 星名表の交換・欠損、モデル解除、解除前の非同期検索結果、旧セル・旧ボタン操作で古い集合を変更しない。

## 専用ビルドと未実行範囲

以下はすべて既存 Makefile の `-Wall -Wextra -Wpedantic -Werror` を含む設定で exit 0。GUI 枠は統合担当が専有するため、この担当は試験バイナリを実行していない。

| 構成 | BUILD_DIR | ビルド結果 | GUI 試験 |
| --- | --- | --- | --- |
| arm64 通常 | `build-unit6-browser-normal` | exit 0 | 統合担当へ引継ぎ |
| arm64 ASan + UBSan | `build-unit6-browser-san` | exit 0 | 統合担当へ引継ぎ |
| x86_64 | `build-unit6-browser-x86` | exit 0 | 統合担当へ引継ぎ |

対象は各ディレクトリの `test_catalog_browser_controller`。ローカル `data` ディレクトリを引数に取る。ビルド実出力は [logs/n10-browser](logs/n10-browser/) に保存し、SHA256SUMS で固定した。実行結果は統合担当のログで別途確認する。

`time_features` による製品・試験の読み取りレビューでは修正必須の指摘なし。現在の HIP と callback の両方による guard、旧行消去・generation、kind 分岐、選択と集合の独立性を確認した。これは試験の追加実行ではない。

`git diff --check` は成功。Controller は 295 行、試験は 294 行。新規依存、公開 header、Makefile、README、IMPLEMENTATION_POLICY、policy gate はこの追補で変更していない。stage / commit と最終 gate 判定は統合担当が実施する。
