# 惑星テクスチャ実装時の保全記録

## 保護対象と照合方法

- `mitaka/`
- `mitaka_plus/`
- `sources/official/`

全通常ファイルは SHA256 とサイズ、シンボリックリンクはリンク先文字列を比較し、パスの追加・削除も照合する。リンクは辿らない。基準はコア実装時の [`baseline-manifest.json`](../native-core/baseline-manifest.json) を再利用する。保護対象への書き込みは行わない。

## 変更前ソースのスナップショット

- 記録: [`source-snapshot.json`](source-snapshot.json)。取得時刻: 2026-10-29 04:08:25 UTC。
- 保存先: [`before/`](before/)。対象は `native/gui/`（`build/` を除外）、`policy_gates/`、`IMPLEMENTATION_POLICY.md`、`native/core/README.md`。
- 25 ファイル、133,640 bytes、2,644 行を保存し、各コピーが元ファイルとバイト単位で一致することを確認した。
- コピーのファイルモードは `0444`。元ファイルの内容やモードは変更していない。
- 各ファイルの SHA256、bytes、行数を記録し、今回の変更量を比較できる状態にした。
- 作業ルートで `git status --short` を実行し、Git リポジトリではないことを確認した。Git の初期化は行っていない。

## 開始時確認

- 確認日時: 2026-10-29 04:10:28 UTC（13:10:28 JST）。
- 結果: [`preservation-start.json`](preservation-start.json)。
- 通常ファイル 16,365 個、6,622,642,667 bytes、シンボリックリンク 465 個。
- 追加・削除・内容変更はすべて 0 件。
- 公式 ZIP の 310 ファイルと展開原本の SHA256 はすべて一致。
- 参照用 `sources/reference/Mitaka-macOS` の HEAD は `ab63d81723a9261b663c8ab1283de2e7607f1094`、作業ツリーは clean。ともに基準と一致。
- 基準 manifest の SHA256 は `235fc9cbdf0e59d89655c7b4a4c7f3c98b6074d89b88d94cd94db243bed98183`。

## 最終確認

- 確認日時: 2026-10-29 04:23:32 UTC（13:23:32 JST）。
- 結果: [`preservation-result.json`](preservation-result.json)。
- 全保護対象を開始時と同じ基準で再照合した。
- 通常ファイル 16,365 個（6,622,642,667 bytes）とシンボリックリンク 465 個の追加・削除・内容変更はすべて 0 件。
- 公式 ZIP の 310 ファイルと展開原本の SHA256 はすべて一致した。
- 参照用 Git の HEAD と作業ツリー状態は基準と一致し、作業ツリーは clean だった。
- 基準 manifest 自体の SHA256 も開始時と一致した。開始時と最終確認はともに合格。

## ソース変更量

- 記録: [`source-diff.json`](source-diff.json)。計測時刻: 2026-10-29 04:25:46 UTC。
- `before/` の各ファイルの SHA256 が作業前のスナップショット記録と一致することを確認した。
- `git diff --no-index --numstat` による対象ソース・文書の差分は、変更 9 ファイル、追加 7 ファイル、削除 0 ファイル。追加 939 行、削除 46 行、合計 985 行。
- 対象: `native/gui/`、`policy_gates/`、`IMPLEMENTATION_POLICY.md`、`native/core/README.md`。`build/`、`build-sanitize/` など `build*` ディレクトリはすべて除外した。
- `investigation/` の検証記録、`temp_gates/` の検証コピー、ビルド成果物は集計対象外。
- `native/core/README.md` は作業前と SHA256 が一致し、差分なし。
- ルートで `git status --short` を再実行し、Git リポジトリではないことを確認した。差分は 300 行以上だが、この状態では commit できないため、Git の新規初期化や commit は行っていない。

## コア実装の確認範囲

[`core-current-manifest.json`](core-current-manifest.json) に `native/core/` の実装・ヘッダ・テスト・ツール・Makefile の 14 ファイルについて現在の SHA256 を記録した。今回の作業前スナップショットに含めたコアファイルは README のみであり、実装ファイルの過去の SHA256 記録は見つからなかった。そのため、コア実装が作業前と同一であることを SHA256 比較で証明したとは扱わない。この記録は今後の比較基準として利用できる。
