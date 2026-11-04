# 連続惑星間飛行の実装時の保全記録

## 保護対象と照合方法

- `mitaka/`
- `mitaka_plus/`
- `sources/official/`

通常ファイルの SHA256 とサイズ、シンボリックリンク先文字列、パスの追加・削除を照合する。リンクは辿らない。
基準はコア実装時の [baseline-manifest.json](../native-core/baseline-manifest.json) を再利用した。
基準ファイルの SHA256 は `235fc9cbdf0e59d89655c7b4a4c7f3c98b6074d89b88d94cd94db243bed98183`。
公式 ZIP と展開原本の全通常ファイルを比較し、参照用 `sources/reference/Mitaka-macOS/` の Git HEAD と作業ツリーも確認する。
保護対象へは書き込まない。

## 変更前のソース

- 取得日時: 2026-10-29 06:05:49 UTC（15:05:49 JST）。
- 記録: [source-snapshot.json](source-snapshot.json)。保存先: [before/](before/)。
- 対象: `native/core/`、`native/gui/`、`policy_gates/`、`IMPLEMENTATION_POLICY.md`。すべての `build*` ディレクトリと生成物を除外した。
- 78 ファイル、520,659 bytes、10,047 行をコピーし、バイト単位の一致、各ファイルの SHA256 と行数を確認した。
- コピーだけを `0444` にした。元ファイルの内容とモードは変更していない。
- 保存完了を実装担当へ通知した後に編集を開始する手順とした。

## 開始時確認

- 確認日時: 2026-10-29 06:08:49 UTC（15:08:49 JST）。
- 記録: [preservation-start.json](preservation-start.json)。全項目合格。
- 通常 16,365 ファイル、6,622,642,667 bytes と 465 シンボリックリンクは基準と一致した。追加・削除・変更はすべて 0 件。
- 公式 ZIP の全 310 ファイルと展開原本の SHA256 は一致した。
- 参照 Git の HEAD は `ab63d81723a9261b663c8ab1283de2e7607f1094`。`git status --porcelain` は空で clean。HEAD と状態は基準と一致した。

## Git と skill

作業ルートの `git status --short` は終了コード 128（Git リポジトリではない）。Git の初期化は行っていない。
参照用 Git は変更しない。
正確な名前の `/simplifier-lai` は利用可能一覧と skills 配下の検索で見つからず、未実行。
類似名の `/Users/kota/.codex/skills/simplify-lai/SKILL.md` は LobbyAI 専用で、非 LobbyAI と機能追加では使わない指定のため適用していない。

## 最終確認

- 確認日時: 2026-10-29 06:28:28 UTC（15:28:28 JST）。
- 記録: [preservation-final.json](preservation-final.json)。全項目合格。
- 通常 16,365 ファイル（6,622,642,667 bytes）の SHA256 とサイズ、465 シンボリックリンクのリンク先文字列、全パス集合は基準と一致した。追加・削除・変更はすべて 0 件。
- 基準 manifest 自体の SHA256 は開始時と一致し、開始時照合も合格しているため、保護対象は今回の作業開始時から変化していない。
- 公式 ZIP の全 310 ファイルと展開原本の SHA256 は一致した。
- 参照 Git は HEAD `ab63d81723a9261b663c8ab1283de2e7607f1094`、`git status --porcelain` は空で clean。開始時と同じ状態を維持している。
- 保護対象への書き込みは行っていない。

## ソース差分

- 計測日時: 2026-10-29 06:27:33 UTC（15:27:33 JST）。
- 記録: [source-diff.json](source-diff.json)、[SOURCE_DIFF.md](SOURCE_DIFF.md)。各ファイルの変更量と変更前後の SHA256 を記録した。
- `before/` の全 78 ファイルが開始時の SHA256 と一致することを確認した。
- 追加 8・変更 18・削除 0 ファイル。追加 1,638 行、削除 473 行、差分の合計 2,111 行。
- `native/core/` の全 31 ファイルは変更されていない。
- 対象はソース・README・方針文書。`build*` ディレクトリ、`investigation/` の記録と `VALIDATION.md`、`temp_gates/` は集計から除外した。
- 差分は 300 行以上だが、作業ルートは非 Git のため commit していない。ルートの新規 Git 初期化と参照 Git の変更は行っていない。

この記録の担当範囲は保全照合と差分計測。ビルド・実データ試験・GUI 検証は統合担当の検証記録を参照する。
