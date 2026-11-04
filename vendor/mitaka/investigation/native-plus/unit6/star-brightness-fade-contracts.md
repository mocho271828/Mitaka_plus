# N11 恒星の明るさ・名称フェードの契約調査

調査日: 2026-10-29。初稿は UNIT5 凍結中の読み取り調査。UNIT6 で時間補間の追加追跡と実装結果を追記した。ローカル配布物の原本は変更していない。

今回の追加証拠では、旧 `Stars.brightness` は **`L_ref` 自体**であり、描画では分母に使われる。`brighten()` は値を `10^-0.2` 倍、`darken()` は `10^+0.2` 倍にする。以前の [恒星制御調査](../local-star-controls-audit.md) で未確定としていた公開値と `L_ref` の対応を、この実行ファイルについて更新する。

`fadeLabels` の bool と名称描画の距離依存分岐も確認できた。ただし現行の Sky/Horizon は旧 3D カメラ・縮尺を入力に持たないため、等級による名称間引きへ置き換えて旧機能と称することはできない。

## 対象と証拠の扱い

| 略記 | 対象 |
| --- | --- |
| `PLUS` | `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。Plus 1.5.4 build101013。同梱 API 文書の表示は 1.3.0 |
| `EXE` | `PLUS/mitakaPlus.exe`、12,288,000 bytes、SHA-256 `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457` |
| `OFFICIAL` | `/Users/kota/mitaka/repositories/Mitaka/sources/official/mitaka_source`。公式標準版 1.3.1 |
| `NATIVE` | `/Users/kota/mitaka/repositories/Mitaka/native/gui`。UNIT5 の作業ツリー |

文書・Lua・公式ソースはローカル原本を優先し、CP932 の内容は読み取り時だけデコードした。実行ファイルの記載は `/usr/bin/objdump` による範囲指定の逆アセンブルと PE import / 定数の手動照合である。REA のデータフロー証明や旧アプリの実行比較ではない。原版を起動して invalid input、画面、補間時間を観測する検証は行っていない。

以下のアドレスはこの `EXE` の preferred VA。今回使う `.text` / `.rdata` 範囲では file offset は `VA - 0x400000`。別の配布版へアドレスを流用しない。

## 公開名・型・戻り値

| 公開名 | ローカル文書 / Lua の根拠 | この EXE で確認した契約 |
| --- | --- | --- |
| `Stars.brightness` | `doc/script_jp/stars.html:68–71`。実数、標準 1.0 | getter は保存された float を Lua number へ変換して 1 値を返す。setter は number を float へ変換し、戻り値なし |
| `Stars:brighten()` | 同 `76–79`、`scripts/gui.lua:153`、`screenmenu.lua:71` | 現在値へ `10^-0.2` を掛け、戻り値なし |
| `Stars:darken()` | 同 `80–83`、`gui.lua:154`、`screenmenu.lua:72` | 現在値へ `10^+0.2` を掛け、戻り値なし |
| `Stars:defaultBrightness()` | 同 `84–87`、`gui.lua:155`、`screenmenu.lua:73` | 1.0 を設定し、戻り値なし |
| `Stars:setBrightnessTo(brightness, dur)` | 同 `72–75`。2 実数、`dur` は秒 | number 経路と別 overload の登録を確認。公開された 2 引数経路は target を float、duration を double として補間側へ渡す。戻り値なし |
| `Stars.fadeLabels` | `scripts/gui.lua:144` / `gui_jp.lua:144` の「近くの恒星名のみ表示」。同梱 `stars.html` に説明なし | bool getter / setter があり、getter は 1 値、setter は戻り値なし |
| `Stars:toggleFadeLabels()` | 同じ GUI 行 | bool を反転して保存。戻り値なし |

`stars.html:74` の例は `Stars:setBrightness(...)` と書かれているが、見出しは `setBrightnessTo`。登録も `setBrightnessTo` を確認しているため、この例だけから `setBrightness` alias を追加しない。

同梱テキストから `contrast` / `magnify` / `namelevel` の公開名は確認できていない。`mitaka.ini:114–115` の `[Star] ImagePowIndex=0.38` は実在するが、それらの API と同一視しない。全テキスト検索の範囲と公式指数の説明は [前回調査](../local-star-controls-audit.md) にある。

## `brightness` の値から描画まで

### 登録・保存先

| 経路 | VA と命令の要点 |
| --- | --- |
| property 登録 | `0x6632ca–0x6632da` が getter `0x662c30`、setter `0x662c80` と文字列 `brightness` (`0xcaa1f8`) を登録 |
| getter | `0x662c30 → 0x5e5ff0 → 0x589c30`。後者は `fld dword ptr [ecx+0x6c]`、対象 `ecx=0x1107940` |
| setter | `0x662c80 → 0x5e5f40 → 0x486d80 → 0x589c20`。最終保存先は同じ float `[ecx+0x6c]` |
| 値の名称 | `0x47ce57–0x47ce8d` は同じ getter を呼び、結果を文字列 `L_ref = %.2e` (`0xc2ca98`) に渡す |
| 描画での使用 | 描画関数 `0x582ce0` の `0x582d72` は、同じ絶対 field `0x11079ac` に対して `divss` を実行 |

getter の値を反転する命令はなく、診断文字列と描画読み取りも同じ保存先へ到達する。したがってこの版では `Stars.brightness = L_ref` と判断できる。API 名から「値が大きいほど明るい」と推測して逆数を公開する実装は一致しない。

`0x582d6a` は 100000 (`0xc34ba8`) を掛け、その後 `L_ref` で除算する。この描画経路には縮尺依存係数や別引数の除算もあるため、この局所式だけで全モードの画素サイズを再現できるとは扱わない。別の同 field 読み取りは `0x58305c`、`0x5835ff`、`0x583b16` にある。

最終保存命令には clamp / finite 判定が見えない。ただし Lua の変換 helper と補間側を含めた異常入力全体の仕様は未確定であり、「旧版が任意の NaN・負数を安全に扱う」という意味ではない。

### 増減と標準化

`brighten` wrapper `0x6620b0` は `0x5e62d0`、`darken` wrapper `0x6620d0` は `0x5e6300` を呼ぶ。両方とも以下の float 定数から累乗を計算し、`0x486d90` が現在の `L_ref` へ掛けて保存する。

| 操作 | base の VA / 値 | exponent の VA / 値 |
| --- | --- | --- |
| brighten | `0xc3730c` / 10.0 | `0xc37308` / float の -0.2 |
| darken | `0xc37314` / 10.0 | `0xc37310` / float の +0.2 |

呼出先 `0xa8ee58` は IAT `0xc27e80` への jump。PE import で `libmmd.dll!__libm_sse2_powf` と確認した。したがって通常の正値について、明るくする操作は分母を約 0.630957 倍、暗くする操作は約 1.584893 倍にする。内部値は float なので往復の bitwise 完全一致は保証しない。

`defaultBrightness` wrapper `0x663330 → 0x5e6e90` は即値 `0x3f800000` (float 1.0) を設定する。文書の標準値とも一致する。

## 名称フェードの bool と距離依存処理

### 状態 API

- property 登録 `0x663249–0x663259` は getter `0x662500`、setter `0x662530`、文字列 `fadeLabels` (`0xcaa1ac`) を結ぶ。
- getter `0x662500 → 0x5e4970 → 0x589e60` は `[0x1107940+0x94]` の byte を取得し、Lua bool で返す。
- setter `0x662530 → 0x5e4950 → 0x589e50` は同 byte を設定する。
- `toggleFadeLabels` 登録 `0x662ffe–0x663009`、wrapper `0x6613a0 → 0x5e4980` は同 getter の反転を同 setter へ渡す。

直接 setter も実在するため、メニュー専用 toggle だけの機能ではない。初期値、非 boolean の Lua coercion、全描画モードでの効果範囲は、この確認からは決めない。

### 観測した名称描画経路

名称描画関数 `0x587d00` の `0x587ebf` が同 field `0x11079d4` を読む。この分岐では、true 時に恒星レコードの 3 成分位置から描画状態の 3 成分を引き、false 時はレコードに保存された別の 3 成分を使う。選んだベクトルの長さを描画状態 `+0x68` の double で割り、true 時だけ距離依存 alpha を掛ける。

以下ではコード上の位置を `P`、描画状態の 3 成分を `C`、`+0x68` を `S` と記号化する。現在の native RA/Dec、SolarCamera の距離 AU、ズーム倍率のいずれかと同じ単位だという証明はない。

```text
r = |P - C| / S
fadeLabels=true の主因子 = F(0.03, 1.2, r, 1.0)
fadeLabels=false の主因子 = 1
```

`0x58801e` は `F` として `0x46ddb0` を呼び、名称側の基礎 alpha に掛ける。この helper の命令・定数は公式 `Mitaka/mtk_calc_alpha.cpp:83–97` の `//--- Old` の関数に対応する。

```text
F(r1, r2, r, fac):
  r < r1 または r > r2 なら 0
  dr1 = fac * 0.02、dr2 = fac * 0.3、alpha = 1
  r < r1 + dr1 なら alpha = abs(r - r1) / dr1
  r > r2 - dr2 なら alpha = abs(r - r2) / dr2
  戻り値 = alpha * 0.9
```

定数は `0xc2be90` = float 0.02、`0xc2be94` = float 0.3、`0xc2be98` = float 0.9、`0xc2be9c` = float 1.0。下限・上限の両条件は独立した if であり、一般入力に対して min の式へ書き換えた証拠ではない。

さらに `0x588044–0x5880bb` では、元位置の長さを使う `r0=|P|/S` が 0.06 未満で alpha が正の場合に、`F(0.04, 0.7, r0, 1.0) / 0.9` を掛ける。0.06 と 0.9 は double 定数 `0xc349c0` / `0xc349c8`。これは fade flag の主因子だけでは説明しきれない追加の名称処理である。非正 alpha は `0x5880c7` から描画を飛ばす。

このため、公式標準版で別途見つかった `Dth / 7°` の 4 乗式を、この Plus の `fadeLabels` の確定式として採用しない。また「近くの恒星名」は等級の明るい星だけという意味ではない。固有名 / Bayer 等の個々の枝への適用範囲、`P`・`C`・`S` の生成と単位、他モードの名称関数、初期値は引き続き確認対象となる。

## 時間付き変更の追加追跡（UNIT6）

`setBrightnessTo` は `0x663124–0x66313a` で同名の wrapper `0x661f00` / `0x661fa0` が登録される。numeric 経路は Lua 第 2 引数を float、3 引数を double にして `0x5e6020` へ渡す。さらに第 4 引数を default true の bool として読み、二つの補間 constructor (`0x7bfa90` / `0x7bfc50`) を選ぶ経路がある。

もう一方には型名 `orhInterp::Interp1` の userdata を受けて `0x5e6210` へ渡す経路がある。しかし同梱 `stars.html` に記載されるのは 2 実数の形式だけである。第 4 引数の意味や userdata の生成 API を推測して新しい公開形式を追加しない。

numeric adapter `0x5e6020` は現在値と target を float で比較し、同値なら `0x5e6062/67 → 0x5e61be` で早期 return する。これは旧補間の取消より前なので、現在値と同じ要求は進行中の別 target を止めない。

| 確認対象 | この EXE の追跡結果 |
| --- | --- |
| 既定曲線 | constructor `0x7bfa90`、update `0x7bfae0` は `from + (0.5 - 0.5*cos(pi*u))*(target-from)`。`u==1` は target を直接適用する。cos thunk `0xa8ee0a` は `libmmd.dll!__libm_sse2_cos` |
| 時間比率 | base `0x7c1990` は `u=(now-start)/duration`。負の経過時間は 0。経過が duration を厳密に超えると取消を予約し 1 を返す。duration==0 は 1 を返すがこの分岐自身では登録解除しない |
| 直接代入 | `0x5e5f40` は callback descriptor に一致する補間を `0x7be4d0` で取消後、値を保存する。補間更新中の guard が自己削除を防ぐ |
| 新しい遷移 | `0x7bd9d0` は同じ callback の旧補間を、旧 target を適用せずに置換する。開始値は要求時点の現在値 |
| brighten / darken / default | raw store `0x486d90` / `0x486d80` を通り取消処理を呼ばない。継続中の補間が次の更新で値を上書きし得る |
| callback | `0x5e3dc0` は補間された double を float に丸めて setter `0x5e5f40` へ渡す。descriptor equality `0x5e3e30` は型と receiver/function の fields を比較し、allocation identity ではない |
| 非同期 | `aboutanimation.html:14–16` は開始後に Lua が続行し、待つには `waitTime` が必要と明記する |

cosine vtable `0x137f9fc` は delete/update/finish/start=`0x7bfa40/0x7bfae0/0x7bfb90/0x7bfbd0`。linear vtable `0x137fa10` は `0x7bfc20/0x7bfca0/0x7bfd30/0x7bfd70`。これらは `.data1` にあり、file offset を `VA-0x400000` で求めてはいけない。PE section に基づいて復号した。undocumented な bool 第 4 引数、userdata、repeat/ping-pong mode は公開しない。

時刻は manager `0x7be6a0` に与える cached double。main routine `0x5bedd0` の `0x5bee0d → 0x75e6b0 → 0x753be0` が clock を更新した後、`0x5bf055–0x5bf070` が singleton `0x1195928` の getter `0x753da0` を読んで manager を更新する。型名は `orhAnimation::GlobalTime`。通常分岐は `WINMM.dll!timeGetTime / 1000 - offset`、別分岐は固定 `1/fps` で進む。停止 flag は値を保持する。これらの flag を操作する公開 API や export / minimize 時の意味までは未確認。天体の JD とは別の時計である。

負・非有限 duration の安全な旧仕様、Lua 終了・取消時の遷移寿命、保存対象、全中断状態の時間進行は未確定。native の明示契約は [実装仕様](../../../native/gui/STAR_BRIGHTNESS.md) を参照する。

## UNIT5 時点の native との差と実装順候補

`NATIVE/include/display_options.hpp:16–23` の `StarDisplayOptions` は表示・名称・marking を持ち、明るさ・名称距離を持たない。`StarRenderer.mm:34–71` は Sky/Horizon 共通で、等級上限と RA/Dec の投影を入力とする。点半径は `clamp(2.8-0.32m,0.55,3.6)`、alpha は `clamp(1.2-0.07m,0.3,1)` に投影 alpha を掛けた値。名称 alpha は投影 alpha の 0.9 倍で、星と視点の 3D 距離は入力にない。SolarScene には恒星 renderer 自体がない。

次の順が実装の候補になる。以下は採用済みの仕様ではない。

1. `brightness`、`brighten`、`darken`、`defaultBrightness` は名前・値の方向・増減幅が確定した。共通設定と純粋な描画計算を用意し、等級上限・カタログ件数・名称集合・単一クリック選択と独立に変更する。正の有限値だけを許す場合、その入力域や上下限は安全な native 契約として明示し、旧版の範囲と同じとは称さない。float への丸め、繰返し操作の overflow / underflow 時に全変更を拒否する境界も必要になる。
2. renderer の明るさを分母へ接続しても、旧テクスチャ描画の係数やモード条件を再現したことにはならない。現在の点径・alpha のどこへ反映するか、基準値 1 の画面、明示等級上限、ヒット判定、マーク・ラベルへの効果は別途具体化する。全原本行を保持し、旧視差誤差フィルタによる削除を持ち込まない。
3. `setBrightnessTo` は時間付き状態を持つため、旧補間契約の追加追跡または明示した native 動作の決定が必要。Lua 実行終了で UI の遷移をどうするかも、通常の bool action と同じ扱いにはしない。
4. `fadeLabels` の bool だけを保存して無効果にする段階は設けない。3D の必要入力と対象ラベルを確定してから描画へ接続する。等級上限や旧 `selectedLabels` で代用しない。N10 の名称集合は別担当の [星座絵・恒星選択調査](constellation-art-star-selection-contracts.md) を参照する。

実装時の回帰には、明るさの getter / setter と 10 の ±0.2 乗の増減、1.0 への復帰、不正値での状態保持、表示とヒットの一致、GUI / Lua / 保存状態の同期を含める。フェードは距離・縮尺の単位を確定後に、端点・減衰域・フラグ無効時・ラベル種類を検証する。遷移は再要求・停止・失敗時・時間源を独立して試す。

## 再現用証跡と検証範囲

ローカル一時証跡は次に保存した。恒久的な参照は上の SHA-256 と VA 範囲であり、一時ファイルの存続に依存しない。

- `/tmp/mitaka-unit6-star-bindings.asm`: `0x662e00–0x663340` の登録。
- `/tmp/mitaka-unit6-star-api-evidence.asm`: property wrapper、adapter、保存先、`L_ref` 文字列出力、alpha helper、import thunk の範囲。
- `/tmp/mitaka-unit6-star-brightness-draw.asm`: `0x582ce0–0x583d80` の描画。
- `/tmp/mitaka-unit6-star-fade.asm`: `0x587c60–0x588180`。先頭は前関数の末尾を含み、対象関数は `0x587d00` から。

採取は `/usr/bin/objdump --disassemble --x86-asm-syntax=intel --start-address=<VA> --stop-address=<VA> <EXE>`。定数は PE section に基づく file offset から little-endian float / double として読み、累乗呼出先は PE import table で照合した。

初稿時点では監査文書のみだった。UNIT6 は brightness と 4 メソッドを実装し、独立モデル・controller・Lua・画素試験を追加した。旧アプリの実行比較は行っていない。新規依存と元データへの書戻しはない。fadeLabels は必要な 3D 恒星位置・カメラ位置・縮尺を現行の角度投影が持たず、旧描画の親条件にも未確定部分があるため未接続を維持する。

追加の再現用一時証跡は `/tmp/mitaka-unit6-star-interpolators.asm`（`0x7bf840–0x7c0300`）、`star-interp-base.asm`（`0x7c18e0–0x7c1b40`）、`star-interp-manager.asm`（`0x7bd800–0x7be9d0`）、`star-callback.asm`（`0x5e3dc0–0x5e3ef0`）、`star-clock-source.asm`（`0x753730–0x753e30`）、`star-clock-loop.asm`（`0x5bed60–0x5bef80`）。後半の短い名前にも同じ `/tmp/mitaka-unit6-` prefix が付く。E8 の raw scan は候補抽出だけに用い、上記 call は命令列の文脈で確認した。

以上の主要な静的抜粋と、通常・ASan/UBSan・x86_64 の既存局所試験ログを [logs/n11](logs/n11/) に保存した。[commands.md](logs/n11/commands.md) に採取元と再現コマンド、[SHA256SUMS](logs/n11/SHA256SUMS) に保存ファイルのハッシュを記録する。局所結果は [Lua 表示 API の検証](lua-display-contracts.md)、全体アプリ・新規 clone・原本保全は [単位6の統合記録](README.md) に分けた。
