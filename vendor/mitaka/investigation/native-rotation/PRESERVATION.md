# 自転・地軸傾斜の実装時の保全記録

## 保護対象と照合方法

- `mitaka/`
- `mitaka_plus/`
- `sources/official/`

全通常ファイルは SHA256 とサイズ、シンボリックリンクはリンク先文字列を比較し、パスの追加・削除も照合する。リンクは辿らない。基準はコア実装時の [`baseline-manifest.json`](../native-core/baseline-manifest.json) を再利用する。保護対象への書き込みは行わない。

## 変更前ソースのスナップショット

- 記録: [`source-snapshot.json`](source-snapshot.json)。取得時刻: 2026-10-29 04:31:12 UTC。
- 保存先: [`before/`](before/)。対象は `native/core/`、`native/gui/`、`policy_gates/`、`IMPLEMENTATION_POLICY.md`。コアと GUI 内の `build*` ディレクトリはすべて除外する。
- 50 ファイル、287,827 bytes、5,614 行を保存し、各コピーが元ファイルとバイト単位で一致することを確認した。
- コピーのファイルモードは `0444`。元ファイルの内容やモードは変更していない。
- 各ファイルの SHA256、bytes、行数を記録し、コアと GUI の双方について今回の変更量を比較できる状態にした。
- 作業ルートで `git status --short` を実行し、Git リポジトリではないことを確認した。Git の初期化は行っていない。

## 開始時確認

- 確認日時: 2026-10-29 04:33:10 UTC（13:33:10 JST）。
- 結果: [`preservation-start.json`](preservation-start.json)。
- 通常ファイル 16,365 個、6,622,642,667 bytes、シンボリックリンク 465 個。
- 追加・削除・内容変更はすべて 0 件。
- 公式 ZIP の 310 ファイルと展開原本の SHA256 はすべて一致。
- 参照用 `sources/reference/Mitaka-macOS` の HEAD は `ab63d81723a9261b663c8ab1283de2e7607f1094`、作業ツリーは clean。ともに基準と一致。
- 基準 manifest の SHA256 は `235fc9cbdf0e59d89655c7b4a4c7f3c98b6074d89b88d94cd94db243bed98183`。

## 最終確認

- 確認日時: 2026-10-29 04:50:34 UTC（13:50:34 JST）。
- 結果: [`preservation-final.json`](preservation-final.json)。全項目合格。
- 通常ファイル 16,365 個、6,622,642,667 bytes の SHA256 とサイズ、シンボリックリンク 465 個のリンク先文字列、全パス集合を基準 manifest と照合した。追加・削除・内容変更はすべて 0 件。
- 基準 manifest 自体の SHA256 は開始時と一致し、開始時の照合も合格しているため、保護対象は開始時から変化していない。
- 公式 ZIP 内の全 310 ファイルと展開原本の SHA256 はすべて一致した。
- 参照用 `sources/reference/Mitaka-macOS` の HEAD は `ab63d81723a9261b663c8ab1283de2e7607f1094`、`git status --porcelain` は空で clean。HEAD と状態は基準から変化していない。
- 保護対象への書き込みは行っていない。

## ソース差分

- 計測日時: 2026-10-29 04:48:04 UTC（13:48:04 JST）。
- 記録: [`source-diff.json`](source-diff.json)。変更ファイル一覧、各ファイルの追加・削除行数、変更前後の SHA256 を保存した。
- `before/` の全ファイルが開始時に記録した SHA256 と一致することを確認したうえで、現在の `native/core/`、`native/gui/`、`policy_gates/`、`IMPLEMENTATION_POLICY.md` と比較した。
- 追加 7 ファイル、変更 16 ファイル、削除 0 ファイル。追加 944 行、削除 62 行、変更量の合計は 1,006 行。
- 各ファイルを `git diff --no-index --numstat` で比較した。`build*` ディレクトリ、`investigation/` の記録と `VALIDATION.md`、`temp_gates/` の検証コピーは集計対象外。
- `IMPLEMENTATION_POLICY.md` と `policy_gates/planet_textures.md` の更新、および `policy_gates/planet_rotation.md` の追加を差分に含む。

## Git と skill の扱い

- 作業ルートで `git status --short` を実行した結果、終了コード 128、`fatal: not a git repository (or any of the parent directories): .git` を確認した。
- 差分は 300 行以上だが、作業ルートは Git リポジトリではないため commit していない。Git の新規初期化も行っていない。参照用 Git リポジトリは別管理であり、変更していない。
- 正確な名前の `/simplifier-lai` skill は利用可能な一覧とローカル skill ファイルに存在せず、実行していない。存在する `simplify-lai` は別名で、SKILL.md に LobbyAI リポジトリ専用と指定されているため、本プロジェクトには適用していない。
- 本記録の担当範囲は保全照合と差分計測。ビルド・実データ試験・GUI 検証の結果は、親担当の `VALIDATION.md` に記録する。
