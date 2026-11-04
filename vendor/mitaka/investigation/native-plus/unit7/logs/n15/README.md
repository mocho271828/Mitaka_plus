# N15 core 検証記録

2026-10-30。最終結果は `*-final-pure.log` / `*-final-data.log`。`commands.sh` は実行したビルド・試験の再現用コマンドであり、shell transcript ではない。アプリ GUI は起動していない。

|構成|strict build|pure|4 原本・全格子 raw 照合|
|---|---|---:|---:|
|通常 arm64|成功|471 PASS|798,907 PASS|
|ASan+UBSan arm64|成功|471 PASS|798,907 PASS|
|x86_64|成功|471 PASS|798,907 PASS|

`normal-data.log` / `san-data.log` / `x86-data.log` / `sanitize.log` / `x86.log` は最後の回帰 1 件追加前の途中ログであり、最終の試験件数には使わない。失敗を隠す目的で削除せず残す。

実データは通常版から明示指定した Earth / Moon / Mercury / Mars の 4 ファイル。Plus に存在しない地形を製品の選択元として自動採用していない。各格子の payload は別ストリームで bytes 照合したが、offset は production の索引を再利用しているため独立 full parser の比較ではない。形式・補間・異常系・メモリ制約の詳細は [TERRAIN_PROVENANCE.md](../../../../../native/core/TERRAIN_PROVENANCE.md)。

`binary/` は旧 Plus 地形倍率の限定静的追跡。原 exe のコピーを含まない。`SOURCE_SHA256SUMS` は試験対象の 4 core ファイル、`SHA256SUMS` はこのディレクトリの記録を検証する。source hash の対象に、他担当が変更する Makefile や GUI は含めない。
