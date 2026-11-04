# N07 の局所検証と原版監査記録

2026-10-29 の UNIT6 作業ツリーで実施した記録。担当は `/root/time_features/time_source_crosscheck`。原典の契約と未確認範囲は [places-binary-contracts.md](../../places-binary-contracts.md) に記載している。

## 検証結果

| 構成 | 合成 observer fixture | Plus の原本 | 通常版の原本 | core parser |
| --- | ---: | ---: | ---: | --- |
| arm64 通常 | 445 checks | 472 checks | 458 checks | PASS |
| arm64 ASan / UBSan | 445 checks | 472 checks | 458 checks | PASS |
| x86_64 | 445 checks | 472 checks | 458 checks | PASS |

`tests/` は `/tmp/mitaka-n07-tests/` の完了ログをそのまま保存したもの。`original-run-notes.txt` は実行担当が保存したコンパイラ、入力、検証範囲の記録である。`commands.sh` はその記録から組み立てた再現用コマンドであり、元の shell transcript ではない。ログの固定作業では試験を再実行していない。

Plus は実効 4 地点、全 4 候補の原定義 108 地点を保持した。通常版は旧形式 `places.dat` の原 bytes と解析診断を保持し、default に自動置換しなかった。これらの件数は実行時の原本の観測値であり、製品の固定上限ではない。

`binary/` は `/tmp/mitaka-n07-binary-audit/` に保存された局所逆アセンブルと文字列・定数調査の出力。原バイナリ・カタログ・画像のコピーは含めない。原版の SHA と対象アドレスは各出力および監査文書で識別する。原版は実行していない。静的監査の出力を動作試験の成功と扱わない。

決定的な I/O 障害注入試験、GUI 起動、風景の画像比較、全体 policy gate 判定は含まない。`peek()` 後の `badbit` 分岐はコードレビューと既存 parser 試験までである。全ファイルの固定ハッシュは `SHA256SUMS` に記録した。
