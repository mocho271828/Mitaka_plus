# 単位6の Lua 表示 API と局所検証

対象はローカル Plus 1.5.4 build101013 と、その同梱 API 文書（表示版 1.3.0）。原本は変更していない。既存 Lua 5.4 helper、Foundation の通信・timer、C++ の型付き action を利用し、新規依存は追加していない。以下は接続した API の範囲であり、旧 Plus の全スクリプト互換を意味しない。

## 接続した契約

| API | 原典 | native の接続 |
| --- | --- | --- |
| `Stars.brightness`、`brighten()`、`darken()`、`defaultBrightness()`、`setBrightnessTo(target, seconds)` | `doc/script_jp/stars.html:68–87` と [N11 の静的追跡](star-brightness-fade-contracts.md) | 正の有限 float の `L_ref`、標準 1、増減は 10 の ±0.2 乗。半余弦補間を共通設定と点描画へ接続する。戻り値、取消・同値・寿命・zero duration の差は [実装仕様](../../../native/gui/STAR_BRIGHTNESS.md) に明記する。 |
| `Stars.selectedLabels` / `toggleSelectedLabels()` | `stars.html:28–35`、`scripts/gui.lua:143` | 独立した HIP 集合により固有名だけを絞る。Bayer・Flamsteed・HIP 番号、点、マーク、クリック選択を変更しない。 |
| `Stars:select(list)` / `deselect(list)` / `isSelected(hip)` | `stars.html:88–99`、[N10 の登録から名前表までの追跡](constellation-art-star-selection-contracts.md) | 複数 HIP または単独 `All` の選択・解除は戻り値なし。単一 HIP の照会は表示フラグと独立した集合への所属を boolean で返す。 |
| `Constels.illusts` / `toggleIllusts()` | `constels.html:32–39`、`ui/scripts/12constels.lua:1–5` | strict boolean の取得・設定・反転。共通設定を全天図・地平図の 2D 星座絵へ接続する。個別星座の旧 Lua show/hide と 3D 配置は未対応。 |
| `Planets.clouds/cityLights`、`toggleClouds()` / `toggleCityLights()` | `planets.html:52–67`、`scripts/gui.lua:94–95` | strict boolean の取得・設定・反転。太陽系の地球の雲・夜景設定へ接続する。 |
| `Planets.atmosphere` / `toggleAtmosphere()` | `planets.html:44–50`、`scripts/gui.lua:90–92`、下記の静的追跡 | 整数 0 / 1 / 2 の取得・設定、なし→単一→多重→なしの反転。公開定数は `mtk.ATMOS_NONE` / `mtk.ATMOS_SINGLE` / `mtk.ATMOS_MULTIPLE` のみ。 |

全 getter と toggle は要求時点のホストの snapshot を使う。変更はメインスレッドの共通 setter へ渡し、ホストが拒否した場合は Lua エラーとして返す。未対応のプロパティ・メソッドを成功扱いしない。

HIP 文字列は正の int32 範囲の ASCII 十進数字を半角空白で区切る。外側・連続空白は許すが、符号、小数、指数、接尾辞、空文字、`All` と数値の混在は全体を拒否する。全トークンの検証後に変更する。原版の `atoi` より厳密な native の入力境界である。未知 HIP は Lua の個別操作では無視し、照会は false。`All` は読み込み済みの全名前集合を対象とする。通常 GUI・native モデル・セッション復元での未知 HIP 拒否とは意図して分けている。

雲・夜景の描画範囲と夜景 false の高度依存係数は [地球レイヤー](../../../native/gui/EARTH_LAYERS_PROVENANCE.md)、大気の物理半径限定・地球 map 欠損時の単一散乱への移行・火星の単一散乱は [大気描画](../../../native/gui/ATMOSPHERE_RENDERING.md) に従う。大気強度の公開旧 Lua API は確認できず追加していない。同梱文書の例にある短い定数名や未確認 alias も補完しない。

## 大気 enum と巡回順の追加証拠

対象 EXE は 12,288,000 bytes、SHA-256 `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。`/usr/bin/objdump` の範囲指定逆アセンブルと PE section に基づく定数確認による限定的な静的追跡であり、REA のデータフロー証明や旧アプリの実行観測ではない。抜粋は [atmosphere-lua-static-evidence.txt](logs/n11/atmosphere-lua-static-evidence.txt) に保存した。

- 登録 `0x64ee83–0x64eed4` は `ATMOS_NONE/SINGLE/MULTIPLE` にそれぞれ 0 / 1 / 2 を渡す。double 定数 `0xc3cd90` は 1、`0xc3cd88` は 2。
- property 登録 `0x64f3be` は setter `0x64e8e0` と getter `0x64e8a0`。setter は Lua number を整数へ変換して `0x5cb160` に渡し、0 / 1 / 2 の分岐から `0x485160` に保存する。getter は `0x5cb1d0` を通って number 1 値を返す。
- toggle 登録 `0x64f0ec` は wrapper `0x64db80 → 0x5cb200`。現在値の正規化後、`0x5cb224–0x5cb236` で 1 を加え 3 で割った剰余を保存する。Lua の戻り値は 0 個。

native は原版の小数から整数への切捨てを再現せず、最初から整数 0..2 だけを受け付ける。資料の登録値・正常値の順序と、不正入力を厳密に拒否する境界を区別する。

## 局所検証と保存ログ

通常、ASan/UBSan、x86_64（Rosetta）の三構成で次を確認した。追加の GUI 実行は行わず、実施済みのログを [logs/n11](logs/n11/) に保存した。再現コマンド、各ファイルの元パスと保存名は [commands.md](logs/n11/commands.md)、SHA-256 は [SHA256SUMS](logs/n11/SHA256SUMS)。

| 対象 | 各構成の結果 | 確認範囲 |
| --- | --- | --- |
| `test_star_brightness` | 1,084 checks PASS | float 境界、増減、標準値、半余弦と端点、点描画の計算。 |
| `test_star_brightness_controller` | 45 checks PASS | 置換・同値要求・逆時計・拒否・再入・破棄。 |
| `test_script_controller` | PASS | N11 と N09/N10、雲・夜景・大気の strict 型・引数、最新 snapshot、toggle、集合操作、不正入力、ホスト拒否の伝播。 |
| `test_display_rendering` | 103 checks PASS | brightness=1 の復帰、明暗、名称とマークの保持、既存表示レイヤーの独立性。 |

独立した読み取りレビューでは N11 の数値・controller と、追加 Lua 全体の入力・snapshot・host 境界に修正必須の指摘は残っていない。レビュー担当による試験の重複実行は行っていない。大気の巡回順は本書の静的追跡で確認したもので、そのレビューが別途同じ逆アセンブルを再追跡したという意味ではない。

全体アプリ・原データ・新規 clone の結果は [単位6の統合記録](README.md) に分ける。Intel 実機や旧 Windows Plus の全画素一致は、この局所試験で保証しない。Lua の信頼境界に変更はなく、明示的に信頼したローカルスクリプト・ローカル HTML だけを入口とし、オンラインページからの実行は禁止を維持する。
