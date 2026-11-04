# 探査機 PTH の位置契約と次の実装境界

調査日: 2026-10-29。対象は利用者のローカル Plus 1.5.4 build101013 である。
この追加監査では原本を読み取り専用で参照し、runtime・データ・画像を変更していない。
前提となる全件保持は [SPACECRAFT_TRAJECTORY_PROVENANCE.md](../../../native/core/SPACECRAFT_TRAJECTORY_PROVENANCE.md)、版とデータ一覧は [orbit-contracts-audit.md](../orbit-contracts-audit.md) を参照する。
この文書の「確定」は対象実行ファイルの解釈を指す。元データの天文学的精度や物理時系を新たに保証するものではない。

## 対象と調査方法

- `P` = `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。
- 対象 `P/mitakaPlus.exe` は PE32 / x86、ImageBase `0x400000`。
- SHA-256: `48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457`。
- `B` = `/Users/kota/mitaka/mitaka/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka`。通常版 1.7.4a であり、PTH 契約の対象とは別である。
- `S` = `sources/official/mitaka_source`。公式 1.3.1 の参照ソースであり、P と B のソースとして扱わない。

REA で対象と capability を確認した。利用できる高水準 decompiler provider がないため、新規 provider を導入せず、Apple LLVM 21 の `/usr/bin/objdump --disassemble --x86-asm-syntax=intel` で限定範囲を静的に読んだ。
以下は手動の逆アセンブル調査であり、REA による decompile 結果や原版実行の観測結果ではない。
PE import table も読み、`0xc259ec = glTranslated`、`0xc25984 = glMultMatrixd`、`0xc25980 = glLightfv` を照合した。
原版のテキスト軌道 loader には PTH の書き出しがあるため、調査のために旧実行ファイルや loader を実行していない。

再確認の入口:

```sh
/usr/bin/objdump --disassemble --x86-asm-syntax=intel \
  --start-address=0x56f890 --stop-address=0x56fb60 \
  '/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe'
```

## PTH の読込と尺度

| 範囲 | 確認した処理 |
| --- | --- |
| `0x5708c0` の定義 reader、`0x570a16–0x570d91` | `Orbit:` の参照を解決し、軌道 reader `0x5714d0` を呼ぶ |
| `0x5714d0–0x571bbb` | `.pth` を binary mode で開く経路と、テキストを読み PTH を生成する経路を持つ |
| `0x571582–0x57159b` | `fread(buffer, 8, 4, file)` を行い、4 要素を読めた記録を採用する |
| `0x5715a1–0x5715e8` | 時刻には変換を掛けず、x / y / z の double に `double(float_scale)` を掛ける |
| `0x566910` | AU のメートル値 `149597870690.98932` を初期化する |
| `0x566950` | `legacy_pc_m = AU_m / sin(1 arcsec)` を初期化する |
| `0x566a40–0x566a54` | `AU_m / legacy_pc_m` を binary32 に丸め、`0x1107748` に保存する |

PTH の 1 記録は little-endian binary64 の `(t, x, y, z)`、32 bytes である。
原座標の単位は AU として解釈され、旧内部の距離単位へ換算される。
**binary32 に丸められるのは換算係数であり、原座標や時刻を float へ変換する処理ではない。**

```text
k = double(float(AU_m / legacy_pc_m))
stored_time = raw_time
stored_xyz = raw_xyz * k                 # 各成分の積は binary64
```

確認した定数から算出した `k` は約 `4.848136995860841e-6`、binary32 bit pattern は `0x36a2ad2e` である。
丸め前との比は約 `1.0000000381145335` となる。
この内部距離を現代の parsec 定義や別の AU 定数で逆換算すると、元データにない尺度差を導入する。
旧内部演算を診断用に再現する場合は、その演算結果と換算係数を明示する。

`0x5716c0` 以降のテキスト経路は出力 `path + ".pth"` を `wb` で開く。
`0x5719f4` は尺度変換前の 4 doubles を書く。これは PTH の AU 解釈と整合する。
native には、この暗黙の生成・原本隣への書き戻しを実装しない。
テキスト全形式、コメント・不正行の処理、出力上書き互換は今回の採用範囲に含めない。

## 時刻選択と線形補間

位置 evaluator は `0x56f890–0x56fb5f` である。
配列は 32 bytes 間隔でアクセスされ、原時刻に対して要求した double を直接比較する。
別時系への変換、時刻原点の加算、地球位置などへの問い合わせはない。

| 条件 | 確認した処理 |
| --- | --- |
| 空配列 | `0x56f8c0–0x56f8c2` から assertion 経路。native は診断付き失敗とする |
| `t <= first.t` | `0x56f8c8–0x56f916`。最初の原記録の座標を返す |
| `t >= last.t` | `0x56f92b–0x56f935` から `0x56fb18`。最後の原記録の座標を返す |
| 内部時刻 | `low = 0, high = count - 1`、`mid = floor((low + high) / 2)` で二分探索する |
| `mid.t == t` | `0x56f967–0x56f96d` から `0x56fad7`。その mid の原記録を即座に返す |
| 隣接区間 | `0x56fa5c–0x56fac6`。下記の線形補間を行う |

```text
u = (t - samples[low].t) / (samples[high].t - samples[low].t)
position = samples[low].position * (1 - u) + samples[high].position * u
```

`mid.t > t` なら high、そうでなければ low を mid に更新する。
native の index 算出は overflow を避けて `low + (high - low) / 2` とできる。
原配列を並べ替えず、有限かつ時刻非減少という現 loader の契約を先に満たす必要がある。
同時刻記録を削除、平均、連結したり、一律に先頭・末尾へ寄せたりしてはならない。
`lower_bound` / `upper_bound` の結果をそのまま採用する規則とも異なる。

両端の判定は二分探索より先に行われる。
全記録が同じ時刻なら、同時刻以下は先頭、より後は末尾となる。
内部の重複群は、探索の最初に一致した mid を返す。
例として時刻 `[0, 1, 1, 1, 2]` の `t = 1` は ordinal 2 となる。
記録数や前後の記録が変わると同じ重複群でも返す ordinal が変わり得るため、原順と全記録数も契約の一部である。

この端点固定は物理的な予測・外挿ではない。
native は「記録範囲より前／後の端点を表示中」を結果と UI に明示し、範囲内の計算成功と区別する。
現実の飛行継続や長期精度を保証する表示にしない。

## 同一数値 JD と描画座標

`0x51c110` は同じ double を、惑星・衛星更新 `0x574d50` に `0x51c149` で、探査機更新 `0x56aeb0` に `0x51c18b` で渡す。
したがって PTH へ渡る時刻値は原版惑星更新と同じ数値 JD である。
UTC / UT1 / TT / TDB のどれを元データが意図するかまでは、この呼出し関係から決まらない。

- `0x569ab0–0x569afe` と `0x56aeb0–0x56af66` は、補間結果を object の保存位置へ直接コピーする。追加回転、親位置、太陽位置の加算はない。
- 描画 `0x56e27a–0x56e290` は同じ補間結果を取得する。
- `0x56e51a`、`0x56e566`、`0x56e5c3` では各成分から camera 原点だけを引く。
- `0x56e610` の `glTranslated` へその相対成分を渡し、機体の局所姿勢 `glMultMatrixd` は後続の `0x56e61d` にある。
- `0x56e2a1` が呼ぶ `0x5493a0` は位置を読むだけで、太陽に向けた光の方向を `glLightfv` に設定する。入力 Vec3 を回転・書換えしない。
- `FaceTo` による地球位置取得または原点選択は `0x56e2b1` 以降の機体姿勢に使われる。PTH 位置へ地球位置を足す原点変換ではない。

[衛星の追加監査](satellite-position-contracts.md#追加監査-cf96-親スナップショットと-j2000-黄道方向)で、Plus の CF96 親位置は `Rx(-23.43929111111111°)` を掛けた日心 J2000 黄道位置と確認している。
探査機はこの同じ描画空間へ位置を直接置くので、**Plus が PTH に要求する空間契約は日心 J2000 黄道 AU** として native へ接続できる。
これはファイルの桁や名称からの推定ではなく、loader と共通描画までの対応に基づく。
任意に追加されたファイルが実際にこの契約どおり作られているか、元座標の誤差・物理時系・観測者補正までは検証していない。

## 原本と独自データの扱い

今回の PTH 実データは `P/spacecraft` の 7 出典、55,405 記録であり、名称別・言語別 `.dat` は 14 定義である。
これは調査時点の観測値であり、実装の上限や合格件数ではない。
`.dat` から一意に解決できた `Orbit` と、原 `.pth` の source index を結ぶ。
既知 7 機種だけを許可する名前リストは作らず、同じ形式の独自追加定義も契約の対象にする。
未登録 PTH、解決できない参照、不正な数値、未知フィールド、同名・言語別定義は一覧に残す。
同じ軌道 source を複数定義が参照する場合でも、表示名や定義を統合しない。

`akatsuki.pth` には隣接する同時刻の異座標が 14 組ある。
最初は `2455338.7916666665`、x は約 `-0.4946970` と `-0.4941740` で異なる。
原行を失わず、要求時刻で採用した ordinal を結果へ返すことで、異なる位置の採用を追跡できる。
原データの修正や連続性の補正は行わない。

`Model` 参照の `.obj` / `.3ds` と `Size` / `FaceTo` は別の表示責務である。
位置を確定しただけで機体 mesh・姿勢・ラベル・原版の軌跡描画まで一致したとは扱わない。
単位 5 の初期表示は位置記号・名称・選択を基本とし、モデル画像や mesh の公開データ置換を行わない。

## PPI と通常版について残る境界

PTH の確定契約を PPI へ流用しない。
`B` の 17 PPI・31,921 segments について、既存 `Trajectory` の 4 点補間・km・原 bytes 保持は利用できる。
全ファイルで日心 AU を直接返すような変更はしない。

公式 `S/Mitaka/mtk_spacecraft_model.cpp:71–85` は `ORIGIN_SUN` で太陽の重心位置を加え、`ORIGIN_SS_BC` では加算しない。
その版の `mtk_spacecraft.cpp:87–97` は特定の機種と origin を固定表で結びつける。
通常版 1.7.4a の定義は `ORIGIN` を持ち、Juno / Kepler は `SS_BC`、Gaia / TESS は `EARTH`、akatsuki は `SUN` と明記している。
ただし別版の固定表だけで、通常版 loader の `EARTH` 基準、座標面、登録時の既定値、時刻の扱いを確定したことにはならない。
今回、通常版 executable の PPI caller までの追加静的追跡は行っていない。

後続の PPI adapter には、明示した origin と basis、および同日 JD の原点スナップショットが必要である。
確定後の概念式は `SS_BC: (probe_BC_km - sun_BC_km) / AU_km`、`SUN: probe_SUN_km / AU_km`、`EARTH: earth_heliocentric_AU + probe_Earth_km / AU_km` となる。
これは origin の意味を検証した後の式であり、現段階で未確定の通常版データを表示する許可ではない。
Sun / Earth 原点が欠損・範囲外なら 0 や別版データで補わず、raw と失敗理由を残す。

## 単位 5 の実装案

既存 loader は原 bytes・全記録・参照を保持したまま使う。
新しい `plus_pth_position.hpp/.cpp` などに、Plus PTH 専用の評価境界を置き、PPI の一般 evaluator と明確に分ける。
既存公開前 API の整理は可能だが、runtime の変更は単位 4 の commit 後に行う。

入力に必要なのは immutable dataset、trajectory index、同一数値 `legacy_julian_date` である。
出力案は次の情報を持つ。

- `optional<array<double, 3>> heliocentric_j2000_ecliptic_au`。
- `source_index` / `trajectory_index` と要求した数値 JD。
- `first_record_index` / `second_record_index`。一致・clamp では同じ index とする。
- `exact_record` / `interpolated` / `clamped_before` / `clamped_after` の明示状態。
- 補間時の `u`、採用契約の識別子、診断。出典の原 bytes は複製せず dataset が保持する。

推奨する native AU の評価は、**原 binary64 AU のまま上記の区間選択と線形補間を行い、pc との往復を作らない**方法である。
これにより GUI の他の native AU 座標と単位を揃えられる。
原版は先に `k` を掛けてから補間するため、演算順と丸めによる最後の数 bit の一致は主張しない。
bit に近い比較用の旧内部値が必要なら別の診断値として `lerp(raw_xyz * k)` を計算する。
その値を native AU へ戻す場合は **同じ丸め済み k で割り**、別の parsec / AU 定数による逆変換を混ぜない。
両方式を暗黙に切替えたり、座標を先に float へ落としたりしない。

GUI は定義 index を選択 ID とし、同じ immutable snapshot を位置表示・クリック・一覧に使う。
全定義と全診断を保持し、描画予算・軌跡サンプル数だけを別途制限する。
endpoint clamp を表示範囲内と誤記せず、追従・軌跡・機体姿勢の対応範囲は個別に示す。
位置評価だけでは全探査機機能の完了を意味しない。

## 単位 5 の境界試験

1. 1 記録、2 記録、3 記録、空、破損 source、範囲外 index、非 PTH input を検査する。
2. 各座標に独立した一次関数を与え、非等間隔時刻の内部補間・正負成分・0・大きな有限値を検証する。
3. 最初と最後の完全一致、直前直後、遠い範囲外を試し、値と clamp 状態を分ける。
4. 重複は先頭・内部・末尾・全件同時刻、同座標・異座標を用意する。奇数・偶数件で旧探索順が選ぶ index を検証する。
5. 重複直前直後では、原群の前後から選ぶ隣接区間と不連続が隠れないことを確かめる。
6. NaN / infinity の要求、時刻差の overflow、極小区間、成分計算の overflow を診断し、不正値を位置として返さない。
7. 原 double の精度を維持し、coordinate の float 化を検出できる fixture を置く。旧係数の丸めと native AU の尺度を混同しない。
8. x / y / z の各単位ベクトルを使い、二重の赤道→黄道回転、Sun / Earth 加算、AU / km 取り違えがないことを確認する。
9. 読込後の原ファイル差替えでも dataset snapshot の採用値・出典が変わらないことを検証する。
10. 実データの全 source / 記録数 / 重複群数を動的に集計し、公開・現況の固定件数を assertion にしない。全 7 出典という現況も上限にしない。
11. GUI では表示中の選択→空／異なる dataset への交換、非表示時の hit 抑止、clamp の表示、未解決定義が一覧に残ることを確認する。

この監査では runtime のテストは追加・再実行していない。
既存 loader の通常・ASan/UBSan・x86_64 の検証結果は provenance に記録済みであり、今回の新しい位置契約の実装試験とは区別する。
