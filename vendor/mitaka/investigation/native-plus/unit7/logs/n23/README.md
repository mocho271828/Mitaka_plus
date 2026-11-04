# N23 局所検証記録

2026-10-30。UNIT6 `d1c361a` からの N23 差分を対象に実施した。全 App の GUI smoke と Session7 適用試験は root の統合検証の範囲であり、この記録に含めない。

| 構成 | pure step | PlaybackClock | PlaybackController | Lua worker/controller | AppScripting strict compile |
| --- | ---: | ---: | --- | --- | --- |
| 通常 arm64 | 167 checks PASS | 10,146 checks PASS | PASS | PASS | PASS |
| ASan + UBSan arm64 | 167 checks PASS | 10,146 checks PASS | PASS | PASS | PASS |
| x86_64 Rosetta | 167 checks PASS | 10,146 checks PASS | PASS | PASS | PASS |

全て exit 0。PlaybackController 試験は AppKit control を生成するが NSWindow を開かない。SAN の実行は既存の方針に従い `ASAN_OPTIONS=detect_leaks=0`。各 `*-integration-build.log` に `-Wall -Wextra -Wpedantic -Werror` と build command が残る。SAN / x86 の Lua 成功は同ログ末尾、通常 Lua の最終成功は `normal-script.log` にある。

`normal-integration-build.log` は初回の Lua 期待値失敗も残している。日数表を Lua の除算値と厳密 `==` 比較した fixture が、二進浮動小数点の丸め差を許容していなかった。最終 fixture は `4 * epsilon * abs(expected)` の相対比較へ修正した。`max(1, ...)` を用いず、0 は厳密一致のまま。修正後の全 3 構成が成功している。製品の時間閾値や境界検証は緩和していない。

`commands.sh` は同じ局所対象の再実行用。保存されたログは作業時の command 出力そのもので、通常構成の final step/clock と controller は別実行したためログ名がスクリプトの新規出力名と異なる。`binary/commands.sh` は原 EXE を読み取り、限定範囲の逆アセンブルと定数だけを別出力先へ再生成する。原本・画像・天体データをコピーしない。

## 独立レビュー

`plus_spec_audit` が N23 の helper / PlaybackController / PlaybackClock / Time Lua 境界と試験を読み取りレビューし、修正必須の製品問題はなかった。enum と日数の分離、前後 step の日数保持、signed int32 speed、UTC 暦 overflow、失敗時の状態維持、停止・非表示・復元時の speed 0 を確認した。文書の native `current()` 表記を実装の登録名 `Time.setCurrent()` へ修正した。レビュー側の再実行・コード編集は行っていない。
