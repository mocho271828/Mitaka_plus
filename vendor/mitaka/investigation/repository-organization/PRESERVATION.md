# リポジトリ分離時の保全記録

## 保護対象と検証方法

`mitaka/`、`mitaka_plus/`、`sources/official/` は、既存の [baseline-manifest.json](../native-core/baseline-manifest.json) と照合する。
通常ファイルの SHA256 とサイズ、シンボリックリンク先文字列、パス集合を確認し、リンクは辿らない。
公式 ZIP と展開原本の各ファイルも比較する。
参照用 `sources/reference/Mitaka-macOS/` は Git HEAD と作業ツリー状態を確認する。
保護対象に書き込みは行わない。

基準 manifest の SHA256 は `235fc9cbdf0e59d89655c7b4a4c7f3c98b6074d89b88d94cd94db243bed98183`。
前回の連続飛行実装完了時と同じ基準・照合方式を使い、今回の出力はこの調査フォルダへ保存する。

## 開始時照合

- 確認日時: 2026-10-29 06:55:19 UTC（15:55:19 JST）。
- 記録: [preservation-start.json](preservation-start.json)。全項目合格。
- 通常 16,365 ファイル（6,622,642,667 bytes）と 465 シンボリックリンクが一致。追加・削除・変更はすべて 0 件。
- 公式 ZIP と展開原本の全 310 ファイルが一致。
- 参照 Git HEAD は `ab63d81723a9261b663c8ab1283de2e7607f1094` で不変。`git status --porcelain` は空で clean。
- 作業ルートの `git status --short` は終了コード 128（Git リポジトリではない）。この確認担当は Git 初期化や GitHub 操作を行っていない。

## 最終照合手順

プロジェクトルートで以下を実行する。

```sh
ruby investigation/repository-organization/verify_preservation.rb final
```

Ruby 標準ライブラリと既存の `git`、`unzip` を用い、保護対象は読み取りだけを行う。
出力先は `investigation/repository-organization/preservation-final.json`。
終了コード 0 と `passed: true`、各追加・削除・変更件数が 0 であることを確認する。
最終照合では開始時と同じ基準 manifest の SHA256 であることも確認する。
この手順は保護対象を現在のパスに保持したまま、別の作業ディレクトリへ整理する場合に適用できる。
保護対象そのものを移動した場合は、この照合を成功と扱わず、移動前後の相対パス対応を明示した別の照合が必要になる。

## simplifier skill

正確な名前の `/simplifier-lai` は利用可能一覧と `/Users/kota/.codex/skills`、`/Users/kota/.agents/skills` の検索で見つからず、未実行。
類似名の [simplify-lai](/Users/kota/.codex/skills/simplify-lai/SKILL.md) は「Do not use for non-LobbyAI projects」と指定され、本件は適用対象外。
この不適合は commit を妨げる条件ではない。

## 最終照合結果

- 確認日時: 2026-10-29 07:09:25 UTC（16:09:25 JST）。実データを使う全テストの終了後に照合した。
- [preservation-final.json](preservation-final.json) は `passed: true`、終了コード 0。
- 通常 16,365 ファイルと 465 シンボリックリンクが一致し、追加・削除・変更は 0 件。
- 公式 ZIP 内の 310 ファイルと展開原本が一致し、参照 Git の HEAD と clean 状態も不変。
- GitHub から取得した共通リポジトリでも、公式 ZIP と展開原本の計 311 ファイルがローカル原本と一致した（[clone-originals.json](clone-originals.json)）。
- 元の `native/` は `archive/native-before-repository-split/` に保持した。開発用コピーとの差分は 4 つの文書のパス案内だけで、実装・Makefile・テストは同一。

この記録の基準 manifest と保全スクリプトは元のワークスペースに保持する。
GitHub の検証記録には比較結果を収録し、既存データ自体や全データの manifest は収録しない。
