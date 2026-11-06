# Plus 小惑星・TNO の位置評価

2026-10-29。対象は手元の Plus 1.5.4 build101013 の packed 36 byte 経路である。
原本を変更せず、既存 C++17 コアと標準ライブラリだけで評価する。

## 根拠

[小惑星位置契約の監査](../../investigation/native-plus/unit5/minor-planet-position-contracts.md) に
対象 executable の SHA-256、reader・更新・getter のアドレス、距離係数、同一数値 JD の伝播、
公式 1.3.1 との相違を記録した。根拠は限定した静的解析であり、旧アプリとの実行比較ではない。

`mp.dat` / `TNO.dat` の 36 byte は番号、binary64 元期、binary32 の M0 / w / node / i / e / n である。
既存 `load_small_body_dataset` が little-endian の原 bytes・source・ordinal・offset・重複を保持して読み込む。
長半径は `pow(0.985607669 / n, 2/3)` の binary64 値であり、追加の float 丸めを行わない。
新 evaluator は parser を重複させず、その `OrbitalElements` を利用する。

## API と適用範囲

`evaluate_minor_planet_position(const SmallBodyRecord&, double legacy_julian_date)` は
const record を受け、`MinorPlanetPositionEvaluation` に ID、要求 JD、optional の日心 J2000 黄道 AU、
成功時の契約名、分類付き診断を返す。呼出側が保持する dataset の原 bytes、名前、flag、順序を変更しない。
契約名は `mitaka-plus-1.5.4-packed36-legacy-jd-native-au-v1` である。

対応条件は `packed_36` の asteroid / trans_neptunian、36 byte の保持、flag なし、
有限な全軌道要素、`a > 0`、`n > 0`、`0 <= e < 1` である。
天体番号、名称、現在の原本件数は条件にしない。
`packed_37` は 36 byte 行と数値入力が一致しても未対応の診断を返す。
追加 byte の意味と reader の契約が未確定であるため、代用・優先・統合に使わない。
当初の36 byte契約では個別軌道 text は対象外だった。2026-11-07に a 指定楕円を別契約 `mitaka-plus-1.5.4-element-text-legacy-jd-native-au-v1` で追加した。旧 float 丸め・番号上書きとの差と採用範囲は [個別形式監査](../../../../investigation/native-plus/minor-planet-individual-format-audit.md) を参照。明示 n、彗星、非楕円、要素欠損は位置を返さない。
既存の確定済み JPL 彗星 evaluator は別の API として維持する。

時刻は元期と同じ尺度の数値 JD をそのまま渡す。物理時系を UTC / TT / TDB と認定せず、
時系未確定の診断を成功時にも残す。元 record の frame / time_scale を書き換えず、
この契約で解決した frame の診断だけを専用結果から取り除く。
精度保証期間が未宣言なら、その不確かさも残す。宣言された有限期間は両端を含めて適用し、
不正な期間や期間外の要求は位置なしとする。元期の値域を精度保証期間に転用しない。

## 既存計算の利用と旧実装との差

既存 `orbital_state` へ元期・M0・n を一度だけ渡す。
`M = M0 + n * (t - epoch)`、楕円 Kepler 方程式、軌道面上の位置、
`Rz(node) * Rx(i) * Rz(w)` を既存コアへ委ねる。新しい solver や時刻変換は追加しない。
太陽位置加算、追加の黄道変換、衛星用の基準面回転は行わない。

結果は AU を直接返す。旧 AU→pc の binary32 係数を通した後に逆変換する処理は加えない。
既存 solver の有界収束・範囲検査を使用し、旧 Newton 法の反復順や途中丸め、最後の sin/cos、
libm の相違まで含む bit 一致は主張しない。旧非収束時のゼロ位置は再現せず、
invalid_argument / out_of_range / runtime_error を計算失敗の診断に変換する。
速度は本 API に公開しない。

## 検証

P1-4 の sampler は、位置評価で行全体が無効な場合と、その時刻だけ位置を得られない場合を明示的に区別する。原レコードに以前の不正診断があっても、元期が宣言期間外なだけなら後続の有効な標本を計算する。同一の code / field の以前の失敗診断と今回の異なる原因も保持する。この境界不具合は人工レコードで再現し、同梱 36 byte 実データでは再現していない。

専用テストは `native/core/tests/test_minor_planet_position.cpp`。次の依存で独立ビルドする。

```sh
clang++ -std=c++17 -Wall -Wextra -Werror -pedantic -O2 -I native/core/include \
  native/core/src/astronomy.cpp native/core/src/catalog.cpp \
  native/core/src/small_body_catalog.cpp native/core/src/small_body_text.cpp \
  native/core/src/small_body_orbit.cpp native/core/src/minor_planet_position.cpp \
  native/core/tests/test_minor_planet_position.cpp -o /tmp/mitaka-unit5-minor-position
```

引数には任意のローカル data directory を複数渡せる。試験用データの書き込み先は一時ディレクトリのみである。

- 円軌道の元期・四分の一周期・一周期・負の時間差、楕円の近点・遠点・既知の離心近点角を検算する。
- 各軸 90 度と一般角の基本回転を独立に適用し、回転順・AU・時間進行が一度であることを確認する。
- e→1、NaN / Inf、非正 a / n、未確認 conic、演算 overflow、欠損要素、異なる encoding を拒否する。
- 宣言期間の両端・直前直後、未知の精度期間、原診断の保持を確認する。
- 10,037 行の同じ独自レコードを間引かず評価し、番号 -1・重複・原 bytes・source / ordinal を保持する。
- 37 byte の余分な 1 byte を除けば 36 byte と完全一致する fixture でも、位置なしを確認する。
- 読込後に試験用ファイルを差し替えても snapshot の原 bytes が変化しないことを確認する。
- 実データは実際の loaded rows から対象数を数え、現況件数を固定 assertion にしない。

通常 strict build、ASan+UBSan、x86_64 の各構成で Plus / 通常版のローカル data を検証し、
いずれも **253,211 checks PASS**。sanitizer の検出はない。
Plus の観測値は全 19,475 行、packed 36 byte 8,451 行の位置評価成功、他の 11,024 行を保持。
通常版はこの loader の対象小天体 source がなく、0 行と欠損診断になる。
別担当が header / 実装 / 監査文書 / packed parser / orbital_state を独立に照合し、修正必須の指摘はなかった。
独立レビューでは試験を再実行していない。
GUI 接続、原版の実行比較、画素一致、物理時系と天文学的精度の確定はこの単体検証に含まない。
