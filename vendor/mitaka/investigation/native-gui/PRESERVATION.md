# GUI 実装時の保全記録

## 保護対象

- `mitaka/`
- `mitaka_plus/`
- `sources/official/`

上記の全通常ファイルは SHA256 とサイズ、シンボリックリンクはリンク先文字列、さらにパス集合を照合する。リンクを辿って外部ファイルを検査しない。基準はコア実装時の [`baseline-manifest.json`](../native-core/baseline-manifest.json) を参照し、同じ manifest の複製は作らない。

## 開始時確認

- 確認日時: 2026-10-29 05:25:24 JST。
- 結果: [`preservation-start.json`](preservation-start.json)。
- 通常ファイル: 16,365 個、6,622,642,667 bytes。
- シンボリックリンク: 465 個。
- 追加・削除・内容変更: すべて 0 件。
- 公式 ZIP の 310 ファイルと展開原本の SHA256: すべて一致。
- 参照用 `sources/reference/Mitaka-macOS` の HEAD: `ab63d81723a9261b663c8ab1283de2e7607f1094`。作業ツリーは clean、基準と一致。

## 最終確認

- 確認日時: 2026-10-29 05:37:42 JST。
- 結果: [`preservation-final.json`](preservation-final.json)。
- GUI ビルド・起動、通常ビルドおよび ASan/UBSan の両既存データテスト、AppKit smoke 検証後に、開始時と同じ基準を使って全保護対象を再照合した。
- 通常ファイル 16,365 個（6,622,642,667 bytes）とシンボリックリンク 465 個について、追加・削除・内容変更はすべて 0 件。
- 公式 ZIP の 310 ファイルと展開原本の SHA256 はすべて一致した。
- 参照用 Git リポジトリの HEAD と作業ツリー状態は基準と一致し、作業ツリーは clean だった。
- manifest 自体の SHA256 は開始時・最終確認ともに `235fc9cbdf0e59d89655c7b4a4c7f3c98b6074d89b88d94cd94db243bed98183`。
