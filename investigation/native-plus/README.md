# 共通実装の採用と検証

2026-10-29、共通実装 `3f47a39972340c6673f5b8aa4ad8b57bd7564840` を採用した。
`make build test data-test reference-test smoke` はすべて終了コード 0。
ローカル Plus の追加データを読み取り専用で参照した。全ログは [wrapper-validation.log](wrapper-validation.log)。

- 依存: 共通実装の AppKit/Foundation/ImageIO と SHA-256 固定 Lua 5.4.9 を利用。Plus 側への独自依存・ソース複製はない。
- `/simplifier-lai` は利用不可。名前の近い `/simplify-lai` は LobbyAI 専用のため適用せず、差分を手動でレビューした。
- 公式比較: CF96 5427、自転 33129、月 12108 成分が一致許容範囲内。
- GUI smoke: カタログ、観測地点、状態復元、出力、Lua、再生、飛行を確認。
- 旧 Plus の全機能への対応は継続中。対応状況は共通実装の機能対応表を参照。
