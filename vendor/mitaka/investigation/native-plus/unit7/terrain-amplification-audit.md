# 旧Plusの地形倍率

Windows 版 Plus 1.5.4 の Lua 値と地形の実倍率の関係を示す。[旧版の読取手順](probes/extract-terrain.sh)・[地形データの出典](../../../native/core/TERRAIN_PROVENANCE.md)

## 確定した対応

|Lua `Planets.topoAmplification`|内部 mode|倍率|
|---:|---:|---:|
|1|0|1|
|2|1|2|
|3|2|5|
|4|3|10|
|5|4|20|

同梱 `doc/script_jp/planets.html` の 96–98 行（CP932）に 1..5 と上記倍率の説明がある。旧 Plus binary でも下記の getter / setter / table の経路を確認した。

|根拠|virtual address と処理|
|---|---|
|プロパティ登録|`0x64f47e` から setter `0x64ed30`、getter `0x64ece0`、文字列 `0xc3d0fc` を登録|
|Lua wrapper|getter は `0x5cbcd0` の結果を数値として返す。setter は引数 2 の数値を float にして `0x5cbc90` へ渡す|
|Lua 境界|`0x5cbc90` は内部 mode+1 と比較後、入力を整数化して 1 を引き `0x485690` へ渡す。`0x5cbcd0` は内部 signed byte に 1 を足して返す|
|内部更新|`0x485690` から `0x548600`。後者は mode を `0x11073ac` に保存し、`0xc32d48 + mode*4` の float を表示側の保持値へ保存する|
|係数表|`0xc32d48` の 20 bytes は little-endian float `1,2,5,10,20`|
|状態出力|`0x5cac89` 以降は内部 mode を取得して 1 を足し、`Planets.topoAmplification = %g;` へ出力|
