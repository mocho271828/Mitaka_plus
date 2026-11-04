# N15 地形倍率の原版境界

2026-10-30。原アプリの実行・改変・依存の追加は行っていない。`reverse-engineer-anything` skill に従って既存環境を確認したが、native 解析 provider は使用できないため、以下は `/usr/bin/objdump` による限定静的証拠である。REA の decompile 結果とは扱わない。

対象はローカル `mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe`（coff-i386）。SHA-256 は `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。再現コマンドと命令列は [logs/n15/binary](logs/n15/binary/commands.sh)。

## 確定した対応

|Lua `Planets.topoAmplification`|内部 mode|倍率|
|---:|---:|---:|
|1|0|1|
|2|1|2|
|3|2|5|
|4|3|10|
|5|4|20|

同梱 `doc/script_jp/planets.html` の 96–98 行（CP932）に 1..5 と上記倍率の説明がある。旧 Plus binary でも下記の getter / setter / table の経路を確認した。

|根拠|virtual address と処理|保存ログ|
|---|---|---|
|プロパティ登録|`0x64f47e` から setter `0x64ed30`、getter `0x64ece0`、文字列 `0xc3d0fc` を登録|property-registration.txt|
|Lua wrapper|getter は `0x5cbcd0` の結果を数値として返す。setter は引数 2 の数値を float にして `0x5cbc90` へ渡す|property-wrappers.txt|
|Lua 境界|`0x5cbc90` は内部 mode+1 と比較後、入力を整数化して 1 を引き `0x485690` へ渡す。`0x5cbcd0` は内部 signed byte に 1 を足して返す|property-accessors.txt|
|内部更新|`0x485690` から `0x548600`。後者は mode を `0x11073ac` に保存し、`0xc32d48 + mode*4` の float を表示側の保持値へ保存する|mode-command.txt / mode-setter.txt|
|係数表|`0xc32d48` の 20 bytes は little-endian float `1,2,5,10,20`|factor-table.txt|
|状態出力|`0x5cac89` 以降は内部 mode を取得して 1 を足し、`Planets.topoAmplification = %g;` へ出力|state-export.txt|

`constants-and-calls.txt` は初期調査時の raw byte / E8 相対 call 候補の記録であり、全 caller を確定した call graph ではない。最終確証は上の bounded な命令列による。

## 通常版と未確定事項

公式保存ソース `Mitaka/mtk_topography.cpp:47–51,130–146` は内部 mode 0、同じ倍率表、mode の getter / setter を持つ。`mtk_menu_bar.cpp:1011–1015` は GUI の 5 項目から `OnTopoZoomMode(0..4)` を呼ぶ。

これは **通常版 GUI 0..4** の根拠であり、旧 Plus GUI の実際の command dispatch は今回未追跡。旧 Plus で確定したのは Lua 1..5 と内部 0..4 の変換である。getter / setter に見える範囲では、mode 更新前の全範囲検証を確認できない。範囲外入力の危険な振る舞いを native に再現する根拠にはしない。

地形 core の倍率は計算関数の明示した有限非負値であり、Lua 互換列挙を受け取る API ではない。GUI にこの 5 段階を設ける場合は型付き enum を入口にし、係数への対応を 1 箇所で検証する。旧 Plus GUI の既定値、非整数・範囲外・NaN に対する公開挙動は、この調査では確定しない。
