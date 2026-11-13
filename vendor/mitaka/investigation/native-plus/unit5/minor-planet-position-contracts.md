# 小惑星・太陽系外縁天体のpacked軌道形式

36 byte と37 byte の軌道表を比較し、Kepler 評価と出力単位を示す。[小惑星の位置計算](../../../native/core/MINOR_PLANET_POSITION_PROVENANCE.md)

## 36 バイト版の読込

`0x48bceb–0x48bd03` の `mp.dat` と `0x48bd67–0x48bd7f` の `TNO.dat` は、共通 reader `0x4fff30` にそれぞれ種別 0 / 1 を渡す。
`0x4fff98–0x500018` の読み込みは、ヘッダーなしの次の 36 bytes である。

| byte offset | 型 | 意味・計算時の単位 |
| ---: | --- | --- |
| 0 | little-endian int32 | 元番号。`-1` もそのまま保存する |
| 4 | little-endian binary64 | 元期の数値 JD |
| 12 | little-endian binary32 | `M0`、平均近点角、度 |
| 16 | little-endian binary32 | `w`、近日点引数、度 |
| 20 | little-endian binary32 | `node`、昇交点黄経、度 |
| 24 | little-endian binary32 | `i`、軌道傾斜、度 |
| 28 | little-endian binary32 | `e`、離心率、無次元 |
| 32 | little-endian binary32 | `n`、平均日々運動、度 / 日 |

6 個の binary32 値は double に拡張して内部要素へ格納される。長半径は保存されておらず、`0x5000b5` の `pow` 呼出しで次の double を計算する。

```text
a_AU = pow(0.985607669 / n_deg_per_day, 2.0 / 3.0)
```

定数 `0xc30a70 = 0.985607669`、`0xc30a78 = 2/3`、`0xc30a80 = π/180` を原 binary64 bytes と照合した。
Plus の reader の `a` は double であり、公式 1.3.1 の text reader にある float 保存を追加しない。
個々の天体番号や現在の件数を読込条件にする根拠はない。native は既存の容量・件数上限内で、同形式の追加記録を原順で保持できる。

角度は `0x50011f`、`0x50013c`、`0x500159` の sin/cos に渡され、格納される基底は次の列ベクトル規約の回転に一致する。

```text
R = Rz(node) * Rx(i) * Rz(w)
```

`w` を近点黄経として扱ったり、`node` をもう一度引いたりしない。この経路には衛星の L / I / E / C / Q の基準面変換はない。

## 同一数値 JD と Kepler 評価

更新関数 `0x506220–0x5063a7` は、内部 stride `0xc8` の全記録を走査する。
内部 object の `+0x40` は epoch、`+0x48` は a、`+0x50` は e、`+0x58` は M0、`+0x60` は n、`+0x68…0xa8` は回転行列である。

| 範囲 | 処理 |
| --- | --- |
| `0x51c110–0x51c1a1` | 同じ double `[edi]` を惑星更新 `0x574d50`、小惑星更新 `0x506220`、彗星更新、探査機更新へ渡す |
| `0x506259–0x5062a2` | `a, e, M0, n, epoch, t` を Kepler 関数 `0x4210c0` へ渡す |
| `0x4210df–0x421102` | `M = (M0 + n * (t − epoch)) * π/180` |
| `0x4212bb–0x42133f` | `e < 1` で楕円の Kepler 方程式を Newton 法で解く |
| `0x4213ab–0x4213ef` | 軌道面上の x / y / z を計算する |
| `0x5062b9–0x506344` | 格納した 3 × 3 回転行列を掛ける |
| `0x50634a–0x50637c` | 結果を object の `+0xb0, +0xb8, +0xc0` へ直接保存する |

楕円の位置式は次のとおりである。

```text
E − e * sin(E) = M
orbital_xyz_AU = (a * (cos(E) − e), a * sqrt(1 − e²) * sin(E), 0)
stored_xyz_AU = R * orbital_xyz_AU
```

この呼出し経路に UTC / TT / TDB の変換、JD 原点の加減算、親や太陽の位置加算、有効期間の判定はない。
`legacy_numeric_julian_date` は同じ数値を渡すという契約であり、物理時系の名前ではない。元期の暦日表示を解釈し直したり、値域から MJD と判定したりしない。

旧 Newton 法は初期値 E=M、補正量のしきい値 `1e−8`、最大 100 回である。非収束時は `0x421341–0x42134e` でゼロベクトルを返す。
native は既存 `orbital_state` の有界 solver・明示的な失敗を使い、失敗を太陽位置として描かない。原版の反復順、最後の sin/cos の利用、libm の丸めまで含む bit 一致は主張しない。
原版には `e == 1` / `e > 1` の別分岐もあるが、36 byte の評価対象は `0 ≤ e < 1`、正の n、有限な全要素に限定する。

## 出力の単位・原点・方向

位置取得 `0x5063b0–0x506420` は保存された xyz に `double(float_scale)` を掛けるだけである。
`0x51c09d–0x51c0b0` の共通位置 dispatch も、この戻り値へ追加変換をせず返す。
太陽位置加算、歳差、赤道から黄道への追加回転はこの経路にない。

旧内部の距離尺度は次の初期化から確認した。

| アドレス | 値・処理 |
| --- | --- |
| `0x4fe290`、定数 `0xc30a30` | `AU_m = 149597870690.98932` |
| `0x4fe2d0`、定数 `0xc30a40` | `legacy_pc_m = AU_m / sin(4.84813681109536e−6)` |
| `0x4fe3c0` | `AU_m / legacy_pc_m` を binary32 に丸めて `0x1081a48` へ格納 |
| `0x5063b1` | 同係数を double に拡張し、3 成分へ掛ける |

native の位置出力は **計算済みの AU を直接使い、旧 pc との往復を作らない**。旧内部値を比較する場合だけ、同じ丸め済み係数を別の診断値として使用する。現代の pc / AU 定数で旧内部値を逆換算しない。

[CF96 親スナップショットの監査](../unit4/satellite-position-contracts.md#cf96-親スナップショットと-j2000-黄道方向)では、Plus の共通位置空間は CF96 の日心 J2000 赤道 AU に `Rx(−23.43929111111111°)` を掛けた方向と確認している。
小惑星・TNO は上記 getter から同じ共通位置空間へ直接渡るため、**Plus がこの packed 形式に要求する空間契約は日心 J2000 黄道 AU** として接続できる。
これはファイル名、元期の値域、似た天体の座標からの推測ではなく、読込・評価・共通位置取得の対応に基づく。
任意の追加データが天文学的にこの契約どおり作られているか、要素の観測元、物理時系、誤差を認証したものではない。

元期の最小・最大値は精度保証期間ではない。旧 evaluator が期間を拒否しないことも無期限の精度保証ではない。native は二体近似・精度期間不明を診断に残し、明示された期間がある場合だけその境界を適用する。
小惑星の式自体へ CF96 の有効期間を流用する必要はない。一方、地心方向の生成などに地球位置を併用する場合は、その別入力の時刻と有効範囲も満たす必要がある。

## 37 バイト版と原 bytes の照合

実物の `mp2.dat` / `TNO2.dat` は **37 bytes / record** であり、番号直後の offset 4 に 1 byte を持つ。
対象 executable 内の完全一致 ASCII `mp2.dat` / `TNO2.dat` は見つからず、36 バイト reader の呼出しは確認できた。ただし文字列の不在だけで、動的に作る参照や別 loader が存在しないとは証明できない。
37 バイト版の直接 reader、flag の意味、旧新ファイルの優先順位は確定していない。

比較では各 37 byte 記録の `[0,4) + [5,37)` を作り、同じ種類の 36 byte 原記録全体と完全一致するかを調べた。番号だけ、丸めた軌道値、同じ ordinal だけで対応づけていない。

| 出典 | 原記録数 | 対応する 36 byte 原記録と完全一致 | 不一致 |
| --- | ---: | ---: | ---: |
| `mp2.dat` → `mp.dat` | 7,317 | 7,317 | 0 |
| `TNO2.dat` → `TNO.dat` | 1,193 | 1,134 | 59 |

この一致記録には、36 byte 側で複数の一致候補を持つものはなかった。
これはローカル原本の観測値であり、コードの上限、固定合格件数、独自記録の許可リストには使わない。
元期と値域の再検査結果は以下である。全値は有限で、e は `[0,1)`、n は正であった。

| 出典 | 元期の最小 / 最大 JD | e の最小 / 最大 | n の最小 / 最大（度 / 日） |
| --- | --- | --- | --- |
| `mp.dat` / `mp2.dat` | 2419320.5 / 2454000.5 | 0.001874509966 / 0.890041887760 | 0.008105196059 / 1.298645734787 |
| `TNO.dat` | 2449240.5 / 2454000.5 | 0 / 0.961000025272 | 0.000079203186 / 0.005986240692 |
| `TNO2.dat` | 2449240.5 / 2454000.5 | 0 / 0.961000025272 | 0.000079203186 / 0.082903437316 |

この照合は対応関係の証拠に留め、**小惑星の位置計算 は 37 byte をすべて未対応として位置を返さない**。
数値入力が同じことは、未知 flag の影響や 37 byte loader の旧動作を確定する証拠にはならない。
対応する 36 byte の行があっても統合・暗黙評価・代用を行わず、flag・原 bytes・両方の行を残す。
これらも一覧と元データを保持し、追加 reader の追跡または明示的な別契約を次の作業とする。`2` という接尾辞や非ゼロ flag を理由に優先・削除・準惑星扱いしない。

### 照合した原本の SHA-256

| 出典 | SHA-256 |
| --- | --- |
| `mp.dat` | `892dc28ad165126dfed1c94bd3934870986da5eda7f3b155d33ac67e43dd940c` |
| `mp2.dat` | `988377799653ad09a0d6030a248b88e8a4ddd25276ea2065bb2f25bb8ed684c6` |
| `TNO.dat` | `2bff049a0ad05ffd6c3fa2888cc4f3619cdba81a6e6d67c8f3b48b5185a1df20` |
| `TNO2.dat` | `85c05722ec0a907f07226a3611dae8dc9ceefafc41eb3b3b982f32393694ed35` |

## 公式 1.3.1 との比較と既存 core の再利用

`S/Mitaka/mtk_minor_planets.cpp:200–240` は `key_data` による **text reader** であり、packed 36 / 37 の直接証拠ではない。
`no, epoch, M0, omg, node, i, e, n, obj_type, dp_flg` の順を読み、`a = pow(...)` は float に丸めて保存する。
この版の `dp_flg` をこの未知 1 byte の意味へ流用しない。

- `S/Mitaka/mtk_orbital_element.h:68–75` は JD / AU / 平均日々運動を記載する。
- `S/Mitaka/mtk_orbital_element.cpp:55–78` と `S/common/math/vector3.h:375–394` は上記回転順に対応する。
- `S/common/astro/cele_mech.cpp:183–202` は `M0+n(t−epoch)`、48–75 行は楕円位置式を確認できる。
- `S/Mitaka/mtk_minor_planets.cpp:455–458,620–623` は同じ t の評価と AU→pc のみの取得を行う。
- 別版の `mtk_planet_position.cpp:265–282` にある太陽位置加算を、Plus の小惑星評価へ持ち込まない。

既存 [SmallBodyDataset](../../../native/core/include/mitaka/small_body_catalog.hpp) は 4 出典を独立して保持し、packed parser は `small_body_text.cpp:109–145` にある。
元 bytes、source offset、ordinal、番号、flag、軌道要素を再利用する。新たな binary parser や Kepler solver は不要である。
[orbital_state](../../../native/core/include/mitaka/astronomy.hpp) は同じ角度単位、平均近点角の進み、回転順を扱い、位置 AU と速度 AU / day を返す。小惑星の位置計算では `OrbitalElements` をそのままこの境界へ渡す。

現行 `evaluate_small_body` は `SmallBodyTimeScale::tdb` を必須とし、結果の header も TDB と宣言する。単に packed record の `time_scale` を TDB へ書き換えて通してはならない。
既存の物理時系フィールドは未確定のまま保ち、**評価時刻の契約**として `legacy_numeric_jd` を持つ専用 adapter または明示した評価 contract を追加する案が適切である。
位置について確認したことと、既存 solver が追加で返す解析的速度を区別する。速度を公開する場合は native の二体式の導関数であると明記し、旧 Plus の速度 API を再現したとはしない。
