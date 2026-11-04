# Plus 衛星位置の限定静的監査

調査日: 2026-10-29。対象は Plus 1.5.4 build101013 のローカル原版である。
この文書は[前回の軌道監査](../orbit-contracts-audit.md)の残件を補足する。
この静的監査では原本および実装コードを変更していない。単位 3 の実装変更とは分離した調査である。

## 対象と証拠の区別

- `P` は `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。
- `X` は `P/mitakaPlus.exe`、PE32 x86、ImageBase `0x400000`、12,288,000 bytes。
- `X` の SHA-256 は `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。
- `S` は `/Users/kota/mitaka/sources/official/mitaka_source`。これは公式 1.3.1 であり、Plus のソースではない。

`reverse-engineer-anything` skill に従い REA で対象を開いて確認した。
利用可能な深い解析 provider はなく、`analysis_provider_binding` は `null` だった。
以下の命令アドレスと数式は、既存 `/usr/bin/objdump` の Intel 構文逆アセンブルと、PE の section / import table / 定数の読み取りから得た**手動の静的観測**である。
REA provider が生成した Evidence オブジェクトによる関数・データフロー証明ではない。
旧アプリの実行、DLL のロード、依存の追加、原ファイルの書換えは行っていない。

再確認には、例えば次の読み取り専用コマンドを使える。`X` は上記の絶対パスに置き換える。

```sh
/usr/bin/objdump --disassemble --x86-asm-syntax=intel --start-address=0x5558e0 --stop-address=0x555bf6 "$X"
```

## 解消できた残件と残る境界

| 項目 | 確認できたこと | 接続上の制限 |
| --- | --- | --- |
| `a` | 軌道要素の長半径は km。旧版の km→AU 係数を掛けて Kepler 関数へ渡す | 現代の AU 定数へ置換した計算を旧版の bit 一致と呼ばない |
| `M` | `M0 + (n − dw − dn) × (t − epoch)`、角度は度、日単位の進行 | `P` から `n` を上書きしない |
| 歳差 | `dw = 360/Pw/365.25`、`dn = 360/Pnode/365.25`。各周期が 0 の場合だけ各進行率を 0 とする | 原版の零周期は不明値の代用ではない |
| 親中心 | 通常衛星は回転済み相対ベクトルを、同じ更新処理の親の保存位置へ加える | 冥王星と Charon はその後に別の中心補正がある |
| 時刻 | 同じ数値 JD を歳差・Kepler・親更新へ渡す | UTC / TT / TDB の物理的な時系、精度保証期間は未確定 |
| Q の index | 成功して登録された Planet の順番が内部 index になる | 任意ファイルの名前だけで固定の惑星番号を割り当てない |
| 月 | 名前 `Moon` で別の解析位置計算に入る | 通常衛星の Kepler に流さない。旧表示設定による倍率も別途ある |

下記の追加監査で CF96 分岐の出力軸は既存 GUI の J2000 黄道方向へ対応づけられた。任意の登録順、別の暦表分岐、物理的な時系まで無条件に変換できるとの主張ではない。
特に L/I の固定角 `23.43870583°` と Q の `23.439291111111114°` は異なり、前回監査どおり別々に保持する。

## 位置評価への入力

通常衛星の要素は、前回監査のローダーにより次の位置へ格納される。

| メンバー offset | 内容 |
| --- | --- |
| `+0x4` | 親惑星 index |
| `+0x8` | 名前 |
| `+0x40 … +0x54` | 保存済み位置の 3 doubles |
| `+0x58 … +0x98` | 軌道面から描画空間への 3×3 回転 |
| `+0xe0, +0xe8, +0xf0` | epoch、a、e |
| `+0xf8, +0x100, +0x108, +0x110` | w、M0、i、node |
| `+0x118, +0x120, +0x128, +0x130` | n、P、Pw、Pnode |

更新関数 `0x5541d0` は、引数の同じ `t` を回転関数 `0x5542a0`（call `0x5541f7`）と位置関数 `0x5558e0`（call `0x55425c`）へ渡す。
先に得た回転を保存してから位置を評価する。

`0x5559c1–0x555a7a` は Pw / Pnode から `dw / dn` を求め、Kepler 関数 `0x4210c0` へ次を渡す。

```text
a_AU = double(legacy_km_to_AU_float) × a_km
effective_n = n − dw − dn
Kepler(out, a_AU, e, M0, effective_n, epoch, t)
```

Kepler 関数の `0x4210df–0x421102` は `M_rad = (M0 + effective_n × (t − epoch)) × π/180` を計算する。
楕円分岐 `0x4212bb–0x4213ef` は `E − e sin E = M` を解き、`x = a(cos E − e)`、`y = a sqrt(1−e²) sin E`、`z = 0` を返す。
旧実装は最大 100 回、残差 `1e-8` で、失敗時にゼロ座標を返す経路を持つ。
新実装は既存 [Kepler 評価](../../../native/core/include/mitaka/astronomy.hpp)を再利用し、収束失敗を位置なしの診断として伝えればよい。旧版の偽のゼロ位置を再現する必要はない。

`0x555a8b–0x555b83` は保存済み回転を左から掛ける。
`0x555b8a–0x555b93` は親 index を使い `0x53eb50` から親の位置を取得し、`0x555b98–0x555be2` は次を返す。

```text
satellite_pre = parent_cached + double(legacy_AU_to_pc_float) × (rotation × kepler_AU)
```

`0x53eb50–0x53ebbb` は container `0x11070e0` の index に対応する天体から `+0x40 … +0x54` をコピーする getter である。
時刻計算はせず、更新順に依存する。原版の範囲外 index は出力を更新しないため、新実装では検証済みの親スナップショットを必須にする。

公式 1.3.1 の `S/Mitaka/mtk_satellite.cpp:244–253` にも同じ `n − dw − dn`、`a × km_to_AU`、回転、AU→pc がある。
これは上記の静的観測の補助資料であり、Plus を公式ソースと同じと仮定したものではない。
同ソースの `orbit_amp_factor` は Plus の通常衛星の上記経路には見えていないため、共通の倍率として追加しない。

## 旧版の距離換算

旧版の定数初期化は `0x551d30–0x551e7c` で追跡できる。
`float(x)` は binary32 への丸め、以下の除算は命令に従って binary32 または binary64 である。

| 値 | 原版の式 | 保存 VA / 根拠 |
| --- | --- | --- |
| `AU_m` | `149597870690.98932` | double `0xc33080` → `0x1107410` |
| 角度 `s` | `4.84813681109536e-06` rad | double `0xc33090` |
| `legacy_pc_m` | `AU_m / sin(s)` | `0x551d70–0x551d89` → double `0x1107420` |
| `AU_km_float` | `float(AU_m × 0.001)` | `0x551da0–0x551db4` → `0x1107428` |
| `km_to_AU_float` | binary32 `1 / AU_km_float` | `0x551dc0–0x551dd0` → `0x110742c` |
| `pc_km_float` | `float(legacy_pc_m × 0.001)` | `0x551e20–0x551e34` → `0x1107438` |
| `km_to_pc_float` | binary32 `1 / pc_km_float` | `0x551e40–0x551e50` → `0x110743c` |
| `AU_to_pc_float` | `float(AU_m / legacy_pc_m)` | `0x551e60–0x551e74` → `0x1107440` |

`0xa8ee04` は IAT `0xc27ed0` への thunk であり、PE import table では `libmmd.dll!__libm_sse2_sin` となる。
ここを `tan` や角度そのものへ置き換えて読まない。
`legacy_pc_m` は旧版の描画尺度の名前として使っており、現代の parsec 定義と完全一致するとの主張ではない。
native 側で相対 km を直接計算する場合も、原版の中間 float 丸めを省略する違いを明記する。

## 全体の更新順と地球・冥王星系

`0x574d50–0x57530f` は、同じ数値 JD に対して惑星、衛星、中心補正の順に更新する。

1. `0x574e79–0x574e93` は JD `2415020.5 … 2487980.5` を分岐条件とする。範囲内では `0x574ec6` の惑星暦表、範囲外では `0x574fd0` の惑星オブジェクト側の計算を使う。
2. `0x57500e` は各衛星の `0x5541d0` を呼び、先に求めた親の位置へ相対ベクトルを加える。
3. `0x575022–0x57515f` は Earth / Moon の名前を解決し、両方の位置へ同じ補正を加える。
4. `0x575164–0x5752f1` は Pluto / Charon の名前を解決し、両方の位置へ同じ補正を加える。

補正前の親位置を `B`、対象衛星の相対ベクトルを `q = satellite_pre − B` とすると、いずれも次の式である。

```text
delta = (B − satellite_pre) × mu = −mu × q
parent_final = B + delta
satellite_final = satellite_pre + delta
```

| 系 | `mu` | 定数 VA |
| --- | ---: | --- |
| Earth / Moon | `0.012150584133256915` | `0xc33f10` |
| Pluto / Charon | `0.07407407407407407`（2/27） | `0xc33f18` |

Pluto の補正後の中心へ再び同じ Charon 相対ベクトルを加え、その上でこの補正を実行すると二重補正になる。
Nix / Hydra はこの後処理で更新されないため、`Nix = B + q_Nix`、`Hydra = B + q_Hydra` のままである。
これらへ補正後 Pluto の位置を無条件に加えてはならない。
`B` はこの監査では「補正前の親位置」と呼ぶ。重心から天体中心へ移す式と整合するが、初期の暦表全経路の物理的原点を独立に証明したという意味ではない。

暦表分岐の期間は、衛星要素の天文学的な精度保証期間ではない。
native の既存地球・月補正とこの後処理も重ねず、どの処理がどの親スナップショットを返すかを接続時に一度だけ決める。

## 月の別経路

`0x5558f1–0x55590b` は名前 `Moon` を比較し、一致すると `0x555911–0x5559be` の専用経路へ入る。
この経路は Earth を名前解決し、Earth の保存位置に `0x4fd8f0` の月解析ベクトルを加える。
倍率は `double(km_to_pc_float) × settings_value` で、`settings_value` は `0x548550` で得る設定領域の offset `0x10` から読む。
この値の UI 名、既定値、可変範囲は今回追跡していない。
Moon の Orbit ファイルを読み込めることと、その要素を通常の Kepler で評価してよいことは別である。

## Q の親 index と極の式

親の極の式は[前回監査の表](../orbit-contracts-audit.md)に記載済みである。
今回は名前→index の残件を次の経路で確認した。

- `0x57436d–0x57439f` は `Planet`（文字列 VA `0xc31f14`）ブロックを認識する。
- `0x5743d3–0x5743e1` は惑星 container `0x11070e0` の現在件数を取り、constructor `0x537540` へ渡す。
- 件数関数 `0x53db00–0x53db12` は `(end − begin) / 4`、空なら 0 を返す。
- constructor `0x5375b5–0x5375c2` はその引数を `self+0` に保存する。
- `0x5743fc` の読込後に `0x574403–0x57440d` で成功を確認し、`0x574421–0x574427` で container へ追加する。
- 名前検索 `0x53db20` は container を順番に調べる。極の式 `0x53ef00` は天体の `self+0` を読み、`0x53efff` で index 0…8 に分岐する。

従ってこの index は**成功して登録された Planet の順番**であり、名前をハードコードした enum ではない。
ローカル `ssystem.dat / ssystem_jp.dat` の Planet 順は Mercury、Venus、Earth、Mars、Jupiter、Saturn、Uranus、Neptune、Pluto であり、全 9 定義が成功した場合は前回の極の係数表と対応する。
名前だけを見て任意の並べ替え済み定義へこの表を適用したり、失敗した先行 Planet を数に含めたりしない。
任意の入力への adapter は、登録順の証拠がなければ呼出側の明示した親極を要求できる。

## 時刻について確定した範囲

`0x51c110` の呼出経路では、同じ double を `0x51c12b` から回転更新 `0x575320` へ、`0x51c149` から位置更新 `0x574d50` へ渡す。
`0x575362–0x57538b` も同じ値を惑星・衛星の回転へ渡す。
別の呼出経路 `0x51bf60` も、入力の double を `0x51bf83` で位置更新へそのまま渡す。
歳差・Kepler はこれと元の `epoch` の差を日数として使う。

この境界は `legacy numeric JD` として表現できる。
今回追跡した経路に UTC / UT1 / TT / TDB の変換は見つかっていないが、これは入力時刻の物理的な時系を証明したことにはならない。
そのため `JulianDateTdb` などへの暗黙キャスト、未検証の ΔT、精度期間の推定を追加しない。

## 次の実装へ渡せる範囲

1. 全定義・全軌道ファイル・全フィールド・出典・順序を保持する loader は、位置の未知事項から独立して実装できる。
2. L/I/E/C、明示した親極を受ける Q、Moon 専用回転は独立した数値回転境界にできる。Mars node 補正は名前だけで自動適用せず、下記の読み込み時点条件を使う。既存の自転込み `BodyOrientation` を Q の代わりに使わない。
3. 通常衛星の相対位置は、同一 `legacy numeric JD`、検証済みの要素、確定した回転を受け、既存 Kepler を用いて評価できる。月は除外し、親の絶対位置や物理的な時系まで確定したとは表示しない。
4. 絶対位置への接続は、親スナップショットの座標尺度・面・補正前後の段階を明示してから行う。地球・月と Pluto / Charon / Nix / Hydra の補正を一般の `parent + relative` に隠さない。

`.pth` の原点・時系・同時刻標本規則、mp/TNO の最終位置経路と物理的時系、40 バイト形式の追加項目は、この追跡では解消していない。
未確定の記録も全件保持し、計算できない理由と計算可能件数を保持件数から分けて報告する。
新しい公開 API や旧 Lua 名の規則を、静的観測から推測して追加しない。

## 検証と未実施事項

根拠となる命令列、定数、import thunk、ローカル定義順と公式ソースの該当箇所を読み取った。
新しい計算コードは書いていないため、この監査に対する数値実装テストは行っていない。
旧 Plus の実行比較、全画面・全モードの座標同一性、入力時刻の物理的な時系、天文学的な誤差評価は未実施である。
通常の三角関数実装の差まで含む bit 一致は確認していない。

## 追加監査: 識別子、親参照、登録の成否

以下も同じ `X` の限定した静的観測である。

| 項目 | 命令列と確認事項 |
| --- | --- |
| Planet の `Name:` | `0x538a71–0x538a9c` は行を `"%*s %s"`（文字列 `0xc2db44`）で読み、最初の値 token を内部 ID へ格納する。残りの表示名は別の文字列処理へ渡す。ID は `self+4`、表示名は `self+0x20`。 |
| Satellite の `Name:` | `0x552ee1–0x552f0c` が同じ token 形式を使い、ID は `self+8`、表示名は `self+0x24`。 |
| 比較 | Planet 検索 `0x53db20` と Satellite 検索 `0x5554e0` は登録 container の先頭から ID を比較する。IAT `0xc253c8` の `std::operator==(string,const char*)` による byte 列の完全一致であり、大文字小文字の無視や Unicode 正規化はない。重複時は先に登録された一致が選ばれる。 |
| 親 index | `0x5381ca` は構造上の Planet の index、`0x5381cf` はその時点の Satellite 件数を constructor `0x552820` へ渡す。constructor は前者を `self+4`、後者を `self+0` に保存する。 |
| Orbit 内の `Planet:` | Orbit reader `0x5534d0–0x553bf1` は Epoch / a / e / w / omg / M0 / i / node / n / P / Pw / Pnode / RefPlane / RA / Decl を扱う。この reader に `Planet:` の認識・親 index の上書きはない。したがって原文の親名は保存すべきだが、構造親を変更する指定として使わない。 |

ID は C の `%s` が読む空白区切りの byte token である。「ASCII 文字だけ許可する」規則ではない。JP 表示名の括弧やルビを ID へ含めない。原版で同一 `Name:` が繰り返されると代入されるが、native loader は元フィールドを全件保存し、解決上の曖昧さを診断できる。

Planet constructor の available flag は `0x5375c4` で false になる。Orbit reader は `0x538de5` の `fopen` が失敗すると成功にせず戻る。一方、開けたファイルを EOF まで読むと `0x539495` で true にする。数値の `sscanf` 成功数はこの経路で検査していない。空ファイルでも登録判定だけは成功になり得るため、**原版の登録成功と native で位置を計算できることを同じ bool にしない**。後の Orbit 読込失敗も先の成功 flag を取り消さない。

Satellite は constructor の `0x552858` で available を false にし、Orbit reader の `0x5534f3` で開けたファイルを EOF まで読むと `0x553bae` で true にする。ここも有効な数値要素の証明とは別である。

Satellite の読み込みと登録は Planet の内部で先に起きる。`0x5381d0` の constructor、`0x5381eb` の Read、`0x5381f2` の available 確認の後、成功時は `0x5383b0` で global Satellite container へ追加する。Planet 自身はブロック全体の Read が戻った後、`0x574403` で available を確認し、`0x574427` で登録する。

このため親 Orbit が失敗して Planet が登録されなくても、内部の Satellite が先に登録され得る。失敗した親の index は次の成功 Planet に再利用される可能性がある。native はこの状態を安全な構造親参照と混同せず、全定義を残して numeric parent の衝突を診断する。登録 container の初期化・再読込での clear、および言語別ファイル選択の全呼出経路は今回追跡していない。言語別 source を連結して 1 個の登録列と扱わず、既知の入力 source と登録開始状態を契約に含める。

## 追加監査: Mars node 補正が成立する時点

前回監査の `node += 43°` は、原版に分岐が存在することと、通常の初回読み込みで実行されることを分ける必要がある。

`0x553a03–0x553a41` の補正条件は、global Planet container で `Mars` を名前検索した結果と、衛星に保存した親 index の一致である。新しい Planet ブロックの読み込みでは、constructor に渡す index を `N = 現在の登録件数` とすると、内部衛星を読む時点で親はまだ container に追加されていない。検索が返せる値は `−1` または `0 … N−1` であり、`N` とは一致しない。

したがって今回確認した **新規 ssystem ブロックの読み込み経路では補正は実行されない**。この結論は読み込み前の container が空かどうかに依存しない。既存の登録済み衛星の Orbit を後から再読込する別経路なら条件を満たし得るが、その呼出経路は未確認である。

新規 source を読む native model は `apply_mars_node_correction=false` とし、回転 API の明示フラグは別の確認済み読み込み経路にのみ使う。親名 `Mars` だけから true を自動生成しない。

## 追加監査: CF96 親スナップショットと J2000 黄道方向

Plus の `0x574d50` にある CF96 期間内の分岐は、次の式で親の保存位置を更新する。

```text
parent_pre_legacy_pc = double(legacy_AU_to_pc_float)
                       × Rx(−23.43929111111111°)
                       × CF96_position_AU(registration_index, legacy_numeric_JD)
```

- `0x5732e0–0x573341` は AU と旧 pc の長さを初期化する。`0x573410–0x573424` は `AU_m / legacy_pc_m` を float に丸め、`0x1107868` に保存する。
- `0x574dc3` はこの float を double に拡張する。`0x574dcb` が読む `0xc33f00` は `−0.40909280422232897` rad。`0xa8ee10` は PE import table の `libmmd.dll!__libm_sse2_sincos`（IAT `0xc27edc`）への thunk である。
- `0x574de5–0x574e6c` は上の尺度を掛けた Rx 行列を作る。`0x574ec6` の評価結果に `0x574ecb–0x574f81` で行列を掛け、`0x574f8c` で親位置へ格納する。この経路に太陽位置の加算はない。
- 評価関数 `0x42be80` は、読み込み flag と index 範囲を確認し、惑星ごとの `t0,dt`、区間正規化 `2(t−block_start)/dt−1`、ブロック評価を使い、`0x42bfd2–0x42bff3` で定数 `0xc29e78 = 1e−10` を掛ける。これは公式 `S/common/astro/cf96.cpp` の `CF96_planets::eval_pos` / `CF96_planet::eval_pos` と同じ CF96 の構造・評価尺度である。
- 公式 `S/Mitaka/mtk_planet_position.cpp` の `update_planets_position` も `AU_to_pc × Rx(−epsJ2000)` で CF96 の赤道出力を黄道へ変換する。ただし、その版の太陽位置加算や Venus / Pluto の別 trajectory 分岐は、Plus の上記経路へ持ち込まない。

既存 core の `Cf96Ephemeris::state` は太陽中心 J2000 赤道の AU を返す。Plus の親と衛星はこの同じ保存空間で足し合わせるので、今回確認した経路の衛星回転後の方向軸は native の J2000 黄道方向に対応する。L/I 内部の `+23.43870583°` は原版の数式として残し、最後にさらに赤道→黄道の回転を重ねない。これは方向基底の対応であり、旧 float 丸めや libm の差まで含めた bit 一致ではない。

GUI 接続は次の条件へ限定できる。

1. 元 source の成功 Planet 登録順と CF96 の順を検証する。任意の名前を既存 Planet enum へ読み替えない。
2. CF96 の有効範囲・実ファイル範囲内で、同一の数値 JD を `Cf96Ephemeris::state` と衛星評価へ渡す。物理的な UTC / TT / TDB ラベルを新たに付けない。
3. raw CF96 の赤道 AU を既存 `j2000_equatorial_to_ecliptic` で変換し、補正前の親 snapshot とする。相対 km は明示した km→AU 尺度で加える。
4. `SkyModel::solar_bodies` の Earth は地月補正済みなので、この snapshot の代わりにしない。Pluto / Charon の後補正も一度だけ扱い、Nix / Hydra を補正後 Pluto へ付け替えない。
5. 月の旧解析ベクトルと設定倍率、CF96 範囲外の親計算、未解決の登録・参照は別の診断を保持する。通常衛星の確定した subset を、それらとまとめて評価不能にしない。

以上はローカル原版と既存 core の契約を接続する限定した証拠である。全旧表示モードのフレーム変換や天文学的な精度を検証したものではない。
