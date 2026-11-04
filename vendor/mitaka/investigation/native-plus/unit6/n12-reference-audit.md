# N12 大気の公式 scalar 参照監査

対象は保存済み公式 1.3.1 の `sources/official/mitaka_source/Mitaka/mtk_atmosphere.cpp` と呼出側。原本は読み取りのみ。旧 Plus 本体とのバイナリ同一性や物理モデルの観測精度は、この照合では主張しない。

## 入出力と描画接点

`inline_calc_scattered_light_intensity`（350–499 行）の `R1/R2/H/r0` は m、`n0` は m⁻³。`r0` は惑星中心から視点、`ev` は視点から画素、`lv` は惑星から太陽を向く単位方向で、同じ直交基底を使う。散乱角の余弦は `dot(ev,-lv)`。座標系が回転しても同じ式を使えるが、平行移動・距離単位の変換は呼出側の責任となる。

3D の `draw_atmosphere`（1163–1358 行）は描画中の惑星中心・半径から視点距離を復元し、視点軸の基底へ太陽方向を投影する。`calc_atmosphere_intensity_map_sub2`（943–1009 行）は float のパラメータと方向を double 本体へ渡し、単一散乱を 14 標本で計算する。その後に `I0 * multiple` を RGB float で加算し、`alpha=min(1,4*max(RGB))` を格納する。描画は `GL_ONE, GL_ONE` の加算なので alpha は再乗算する透過率ではない。

地上の `mtk_planetarium.cpp:338–601` は、外層を `R1+20H` とし、単一散乱を 22 標本で評価する。多重散乱は `r0/zoom`、日食補正を介し、さらに `correct_RGB` と別の alpha 係数を使う。`mtk_satellites.cpp:1046–1050` の空背景も 22 標本と色補正を使う。この経路と 3D の 14 標本・色補正なしの経路は異なる。N12 core の純関数試験は散乱値を扱い、地上の gamma・日食・表示 gain を勝手に混合しない。

## 単一散乱

| 根拠 | 確定した動作 |
| --- | --- |
| 124–134 行 | 波長 R/G/B は float の 700/546.1/435.8 nm。float 丸め後に double の `pow` と Rayleigh 係数を計算する。 |
| 264–344 行 | 視線側の密度 `Tt` と太陽側の密度 `Ts` は double、RGB 累積は各加算時に float。太陽側標本数は `imax-i+1`。積算中の `dt=(t2-t1)/imax` と最後の float `dt=(t2-t1)/(imax-1)` は別であり、同一化しない。 |
| 307–321 行 | scalar/SSE 分岐。今回の独立参照は scalar を明示選択し、SSE 本文は採用しない。 |
| 365–397 行 | 大気球への交差がない、接するだけ、全交差が視点の後ろなら黒。視点より前の区間だけを扱う。 |
| 397 行 | `R1 *= .9999` は地表クリップだけでなく、影の円柱判定と密度計算にも使われる。原注釈は `//*****` のみで、物理的な理由は不明。移植で用途を狭めない。 |
| 398–478 行 | 地表で終端を切り、太陽と逆側の円柱影を除く。光路が二つに分かれれば両区間を float RGB 加算する。 |
| 486–497 行 | 位相係数は `3/(16*3.141592654)*(1+cos²θ)`、最後に `I0`。ここだけの π 定数を `M_PI` に置換しない。 |

`mtk_approx_func.h:49–58` の `exp_d(x)` は `exp(-x)` の近似であり、`(1+.2507213x+.0292732x²+.0038278x³)^-4`。標準 `exp` に置き換えるとモデルの数値が変わる。

## emmap と多重散乱

`init_multiple_scattering`（541–569 行）の形式は、int32 の `RN/ThN`、double の `R1/R2/H/N0/ThMax`、続いて半径行ごとに `RGBf[ThN]`。little endian のローカル原本は 48 byte ヘッダー＋12 byte RGB ノード。半径は `R1+(R2-R1)*i/(RN-1)` で等間隔。`RGBf` は `common/graphics/color.h:47` の `vector3<float>` である。

原 loader は読込サイズ・次元・有限値を検証しないため、独立参照試験に渡すのは native parser を通過した正常ファイルだけとする。不正入力試験は native loader の責任とし、原本の未定義動作を再現しない。

`calc_multiple_scattered_light_intensity`（587–747 行）は、map 固有の半径・密度を使う。500 要素の acos 表を floor index で参照し、角度の二つの map ノードを float の `f1/f2` で補間する。半径の内向き区間、続く外向き区間を順番に積分し、各区間の半分の光学深さを加算前後に置く。地表到達時は返る。RGB へは毎回 float で加算する。

原関数は、大気外の視点で大気が後ろにある場合も負の交差時刻を採用し得る。原描画側で排除された入力まで安全な native 公開関数へ転用しない。参照照合は前方交差のある有効な ray に限り、native に追加した前方交差 guard は別の回帰で検証する。

地表ちょうどから地面へ向く ray では、原関数の球面交差の桁落ちが微小な負 `dt` を生む。例として合成 map の `observer=(0,0,6378000)`、視線天頂角 91°、太陽天頂角 0° で RGB は `(-3.8417057561732624e-16,-1.421431002729165e-16,-8.0675817173869366e-16)` になる。native は `radius <= R1 && dot(observer,view) < 0` の遮蔽を厳密な 0 にする。これは原版の数値的な負値を再現する変更ではなく、公開 ray 境界の明示的な安全契約であり、通常の数値比較と分けて検証する。

公式 Earth の単一散乱は `R=6378136.6, H=8000, dp=6, n0=2.69e25`。ローカル emmap は `R1=6378000, R2=6442000, H=8000, N0=2.5469e25` で一致しない。単一散乱の設定で map を読み替える根拠はない。

## 独立試験の方法

`native/core/tests/extract_atmosphere.awk` は、公式の許諾表示、波長・散乱係数、map globals、7 関数を関数本文の変更なしに抽出する。構造・個数・終端が変わったら失敗する。`vector3.h` と `mtk_approx_func.h` は公式のまま include する。Windows 依存の `color.h` は避け、同じ `typedef vector3<float> RGBf` のみを宣言する。`is_SSE_Enable()` を false に固定し、到達禁止の SSE stub は例外で失敗させる。

`native/core/tests/test_atmosphere_upstream.cpp` は、合成 map と任意の `--emmap PATH` 原本に対し、全ヘッダー・全半径・全 RGB ノードが原 loader と完全一致することを検証する。単一散乱は double 本体と float public wrapper の両方、多重散乱は昼夜・地表・地平・宇宙からの大気縁を比較する。単一散乱の標本数は 2/3/14/22/64。RGB の一致成分数・最大絶対差・最大相対差を出力する。

数値比較の上限は `8 * float epsilon * max(abs(actual),abs(expected))`。ゼロに対する固定の絶対許容差は設けない。これは異なる CPU/コンパイラの積和融合による最下位差を扱うためで、演算精度や物理精度を保証する幅ではない。許容差に到達する差異があれば、まず演算順序・float 境界を調べる。

原 TU にだけ既存の `REFERENCE_FLAGS` と `-Wno-unused-variable` が必要。後者は原関数内の未使用 `zS2` を変更せず残すため。製品側の警告は抑制しない。

## 検証状況

2026-10-29、原文抽出・参照 TU・試験 TU の strict C++17 コンパイルと、通常構成の以下 3 実行がすべて exit 0。原データは読み取りのみで変更していない。

| 実行 | 単一散乱 | 多重散乱 | 地表内向きの別検証 | ログ |
| --- | --- | --- | --- | --- |
| `make atmosphere-reference-test` | 12,606 成分すべて完全一致 | 合成 792 成分中 701 完全一致 | 32 rays が厳密 0 | `/tmp/mitaka-unit6-n12-reference-normal.log` |
| `build/test_atmosphere_upstream --emmap <Plus 原本>` | 12,606 成分すべて完全一致 | 合成 + 原本 1,584 成分中 1,385 完全一致 | 64 rays が厳密 0 | `/tmp/mitaka-unit6-n12-reference-plus.log` |
| `build/test_atmosphere_upstream --emmap <通常版原本>` | 12,606 成分すべて完全一致 | 合成 + 原本 1,584 成分中 1,385 完全一致 | 64 rays が厳密 0 | `/tmp/mitaka-unit6-n12-reference-regular.log` |

3 実行とも多重散乱の最大絶対差 `3.0517578125e-05`、最大相対差 `1.63027751399e-07` で、上記の float 比較上限内。別検証した地表内向き ray の原版出力の最大絶対値は `1.03013097726e-13`。この微小値への許容差を通常比較へ広げていない。

初回参照実行は上記の地表内向き負値を native が拒否して失敗した。所有担当が遮蔽 guard と製品側境界試験を追加した後、参照試験もこの境界を明示的に分離して上記の再実行を完了した。ASan/UBSan と x86_64 の参照比較はこの監査担当では未実施で、統合担当へ引き継ぐ。

## 所有担当による最終再検証

同日、N12 所有担当が通常 / ASan+UBSan / x86_64 の各構成で、Plus / 通常版の原本を用いる全参照試験を実施し、すべて exit 0 を確認した。単一散乱は各 12,606 成分すべて完全一致。arm64 の多重散乱差は上表と同じ、x86_64 は各 1,584 成分すべて完全一致。地表内向きの別検証も各 64 rays 通過した。実行コマンドと最終ログは [N12 ログ](logs/n12/COMMANDS.md)、製品側の境界・遮蔽終端は [core provenance](../../../native/core/ATMOSPHERE_PROVENANCE.md)に記録する。
