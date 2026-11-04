# 既存ファイルの保全基準

`baseline-manifest.json` は macOS コア実装の開始時に採取した読み取り専用の基準値である。
対象はワークスペース内の `mitaka/`、`mitaka_plus/`、`sources/official/` の全通常ファイルとシンボリックリンクである。
通常ファイルは相対パス、バイト数、SHA-256、シンボリックリンクは相対パスとリンク先文字列を記録する。
リンク先を再帰走査せず、既存ファイルの内容、名前、パーミッションを変更しない。
Wine 関連のファイルも保全の対象に含めるが、移植元コードの調査対象には含めない。

公式 `mitaka_source_131.zip` と展開原本は、実装開始時に 310 ファイルすべての内容一致を確認した。
参照用 `sources/reference/Mitaka-macOS` は HEAD と `git status --porcelain=v1 --untracked-files=all` を manifest に記録する。
ワークスペース直下は Git リポジトリではない。

`data-inventory.json` は、実データによる読み込み確認に使うファイルのパス、サイズ、先頭 32 バイトを記録する。
両バンドルに `data/hip.dat` と `data/cf96.dat` があり、`constellation_HIP.dat` は `mitaka_plus` にある。
現行 Mitaka の軌道ファイル `.ppi` は 128 バイトの倍数で、先頭の 4 個の little-endian double が増加するユリウス日になっている。
これは公式 1.3.1 の `trajectory_segment::read_data` のレコード配置に対応する。
Mitaka Plus の `.pth` は先頭がユリウス日と 3 次元座標に見える別形式であり、`.ppi` と同一のローダーに自動的に渡してはならない。

基準 manifest の採取は 2026-10-29 04:44:50 JST に完了した。
通常ファイル 16,365 件、合計 6,622,642,667 バイト、シンボリックリンク 465 件を記録した。
参照リポジトリの HEAD は `ab63d81723a9261b663c8ab1283de2e7607f1094`、作業ツリーは clean であった。
完了時の保全確認では、各エントリの内容に加えて対象ディレクトリのファイル集合の増減も比較する。

## 完了時の照合

統合テスト、AddressSanitizer / UndefinedBehaviorSanitizer、公式計算との比較の完了後、2026-10-29 04:53:19 JST に、基準 manifest と現在のファイル集合、通常ファイルのサイズ・SHA-256、シンボリックリンクのリンク先を最終照合した。
通常ファイル 16,365 件（6,622,642,667 バイト）、シンボリックリンク 465 件について、追加 0 件、削除 0 件、変更 0 件であった。
公式 ZIP と展開原本 310 ファイルの不一致は 0 件。
参照リポジトリの HEAD は基準と一致し、作業ツリーは引き続き clean であった。
機械可読の検証結果は `preservation-result.json` に保存した。
