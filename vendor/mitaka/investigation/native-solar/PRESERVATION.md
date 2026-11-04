# 太陽系 3D 表示実装時の保全記録

## 保護対象と照合方法

- `mitaka/`
- `mitaka_plus/`
- `sources/official/`

全通常ファイルは SHA256 とサイズ、シンボリックリンクはリンク先文字列を比較し、パスの追加・削除も照合する。リンクは辿らない。基準はコア実装時の [`baseline-manifest.json`](../native-core/baseline-manifest.json) を再利用する。保護対象への書き込みは行わない。

## 変更前ソースのスナップショット

- 記録: [`source-snapshot.json`](source-snapshot.json)。取得時刻: 2026-10-29 01:57:53 UTC。
- 保存先: [`before/`](before/)。対象は `native/gui/`（`build/` を除外）、`policy_gates/`、`IMPLEMENTATION_POLICY.md`、`native/core/README.md`。
- 19 ファイル、81,944 bytes、1,621 行を保存し、各コピーが元ファイルとバイト単位で一致することを確認した。
- コピーのファイルモードは `0444`。元ファイルの内容やモードは変更していない。
- 各ファイルの SHA256、bytes、行数を記録し、今回の変更量を比較できる状態にした。
- 作業ルートは Git リポジトリではない。Git の初期化は行っていない。

## 開始時確認

- 確認日時: 2026-10-29 03:46:03 UTC。
- 結果: [`preservation-start.json`](preservation-start.json)。
- 通常ファイル 16,365 個、6,622,642,667 bytes、シンボリックリンク 465 個。
- 追加・削除・内容変更はすべて 0 件。
- 公式 ZIP の 310 ファイルと展開原本の SHA256 はすべて一致。
- 参照用 `sources/reference/Mitaka-macOS` の HEAD は `ab63d81723a9261b663c8ab1283de2e7607f1094`、作業ツリーは clean。ともに基準と一致。
- 基準 manifest の SHA256 は `235fc9cbdf0e59d89655c7b4a4c7f3c98b6074d89b88d94cd94db243bed98183`。

## 最終確認

- 確認日時: 2026-10-29 03:58:31 UTC（12:58:31 JST）。
- 結果: [`preservation-result.json`](preservation-result.json)。
- 実装完了後、全保護対象を開始時と同じ基準で再照合した。
- 通常ファイル 16,365 個（6,622,642,667 bytes）とシンボリックリンク 465 個の追加・削除・内容変更はすべて 0 件。
- 公式 ZIP の 310 ファイルと展開原本の SHA256 はすべて一致した。
- 参照用 Git の HEAD と作業ツリー状態は基準と一致し、作業ツリーは clean だった。
- 基準 manifest 自体の SHA256 も開始時と一致した。開始時と最終確認はともに合格。

## ソース変更量

- 記録: [`source-diff.json`](source-diff.json)。計測時刻: 2026-10-29 04:05:16 UTC。
- `before/` の各ファイルの SHA256 がスナップショット記録と一致することを確認した。
- `git diff --no-index --numstat` による対象ソース・文書の差分は、変更 9 ファイル、追加 6 ファイル、削除 0 ファイル。追加 1,073 行、削除 50 行。
- 最終レビューで日時追従の smoke 検証を補強した後の `AppController.mm` の SHA256 は `22e2cf2e08890d9d3b6fa5cc82f3b08e6ff9eac72b94f93ac14bdeaa3b181a3c`。この更新ではソース差分だけを再計測し、上記の保護対象に対する最終照合結果は変更していない。
- 対象: `native/gui/`（`build/` を除外）、`policy_gates/`、`IMPLEMENTATION_POLICY.md`、`native/core/README.md`。最後のファイルは差分なし。
- `IMPLEMENTATION_POLICY.md` 末尾の `investigation/native-solar/` 記録先追加は集計済み。`investigation/` の検証記録、`temp_gates/` の検証コピー、ビルド成果物は集計対象外。
- ルートで `git status --short` を再実行し、Git リポジトリではないことを確認した。差分は 300 行以上だが、Git の新規初期化や commit は行っていない。
