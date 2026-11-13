# Plus 通常衛星の相対位置

2026-10-29。対象はローカル Plus 1.5.4 build101013 の通常衛星経路である。
原本は変更せず、実行時依存は C++17 標準ライブラリだけを使用する。

## 根拠と適用範囲

[satellite-position-contracts.md](../../investigation/native-plus/unit4/satellite-position-contracts.md) の静的監査に従う。
対象実行ファイルの SHA-256、命令アドレス、定数、公式 1.3.1 の補助資料は同文書に記載されている。
旧アプリとの実行比較や bit 一致の確認は行っていない。

`evaluate_satellite_relative_position` は `a > 0`、`0 <= e < 1` の楕円軌道を受け取り、
元期、M0、n、Pw、Pnode と回転から相対 km を返す。原版で別解析となる名前 `Moon` は呼出側が除外する。
親の絶対位置、地球・月および冥王星・Charon の中心補正、倍率はこの関数に含まない。
放物線と双曲線はこの監査で確認した位置分岐の範囲外として診断する。

## 計算

`dw = Pw == 0 ? 0 : 360 / Pw / 365.25`、`dn = Pnode == 0 ? 0 : 360 / Pnode / 365.25` とする。
`M = M0 + (n - dw - dn) * (t - epoch)` を既存 `orbital_state` へ委ねる。
呼出前に M を進めないため、元期からの時間が二重に加算されることはない。P から n を再生成しない。

`orbital_state` の長半径を 1 AU として得た位置を無次元の軌道形状として扱い、
`SatelliteRotation` の列基底を掛けた後に入力の長半径 km を掛ける。
n が独立した入力なので、この長さの正規化は軌道形状と時間進行を変えない。
AU 定数の追加や、既存 Kepler ソルバーの再実装は行わない。
km から直接結果を返すため、旧版の km→AU→pc にある中間 float の丸めは再現しない。

時刻は物理的時系を未確定の `legacy numeric JD` として受ける。
`SatelliteTimedRotation` にも同じ JD を要求し、一致しない回転の利用を拒否する。
出力方向はその回転の legacy 出力方向であり、J2000 型へ暗黙変換しない。
UTC / TT / TDB 変換や天文学的精度の保証期間は定義していない。

## 異常系と検証

有限値、a/e の条件、歳差率の overflow、有限かつ右手正規直交の回転、時刻一致、結果の有限性を検査する。
既存ソルバーの不正入力・範囲超過・非収束は分類付き診断へ変換し、失敗時の位置は `nullopt` とする。
ゼロ位置で失敗を隠さず、原記録の修正も行わない。

```sh
clang++ -std=c++17 -Wall -Wextra -Wpedantic -Werror \
  -fsanitize=address,undefined -fno-omit-frame-pointer -I native/core/include \
  native/core/src/astronomy.cpp native/core/src/satellite_position.cpp \
  native/core/tests/test_satellite_position.cpp -o /tmp/mitaka-test-satellite-position
/tmp/mitaka-test-satellite-position
```

110 checks PASS。円軌道の正逆時刻、近点・遠点、歳差による n の相殺、負の歳差周期、
列基底の向き、回転時刻の不一致、e→1 の境界、NaN/Inf、数値 overflow、不正な回転を確認した。
ASan/UBSan の検出はない。
GUI 接続、元の月解析、絶対位置の原点、実画面一致はこの検証の対象外である。
