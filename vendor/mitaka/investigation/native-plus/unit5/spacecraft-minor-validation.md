# 探査機とpacked小天体の座標表示

根拠は [Plus PTH の静的監査](../unit4/spacecraft-position-contracts.md)、[core provenance](../../../native/core/SPACECRAFT_POSITION_PROVENANCE.md)、[renderer provenance](../../../native/gui/SPACECRAFT_RENDERER_PROVENANCE.md)。旧実行ファイルを実行した比較ではない。

`SpacecraftPositionModel` は loader の全 source、原 bytes、定義、言語 section、trajectory、原行を所有する。PTH の `(time,x,y,z)` は binary64 の原 AU を使い、同じ数値 JD で端点判定を先に行う。内部は二分探索で最初に一致した mid、または隣接する原標本の重み付き線形補間を返す。等時刻・異座標を平均、統合、並べ替えしない。範囲外は端点固定であり、天文学的な外挿ではない。元の物理時系 UTC/TT/TDB は認定せず、成功位置にもその診断を残す。

位置は日心 J2000 黄道 AU。旧内部 pc への往復や旧 binary32 係数の丸めを再現したとは主張しない。モデル構築時の全件検査と評価時の O(log N) 探索を分ける。PPI は原資料と既存四点補間器を保持するが、表示に必要な原点・座標面・物理時系が未確定なので、この表示モデルから位置を返さない。

GUI 一覧は定義単位の全行を保持し、CP932/UTF-8 の表示文字列と未解決理由を扱う。`spacecraft_scene_position` は定義→trajectory→source の参照、PTH 契約、同じ JD、有限値、評価結果と snapshot の位置一致を描画・focus・追尾で共通検査する。PPI に座標を付け足した偽の snapshot でも描画位置を返さない。

点・名称・原標本軌跡は独立設定であり、native 初期値は `points=true, labels=false, orbits=false`。点を消すと選択リングと pick も消え、名称・軌跡は独立して表示できる。全体非表示は選択 ID を保持して全描画・pick を止める。これは原 Plus の初期値を確定したという意味ではない。軌跡は原順の隣接点だけを結び、背面・near plane・不正値を跨がない。1,024 本単位の stroke はバッチ境界であり、件数の切捨てではない。

## 36 byte の軌道表

根拠は [packed 36 byte の監査](minor-planet-position-contracts.md) と [core provenance](../../../native/core/MINOR_PLANET_POSITION_PROVENANCE.md)。既存 loader と `orbital_state` を使い、確認済みの asteroid/TNO の `packed_36`、有限な `a > 0`、`n > 0`、`0 <= e < 1` だけを専用 evaluator へ渡す。新しい Kepler solver、太陽位置加算、時刻変換は追加しない。

GUI の `SmallBodyEvaluationMode` は `comet_tdb`、`packed36_legacy_jd`、`unresolved` を区別する。確認済み JPL 彗星は既存 TDB evaluator、36 byte 小惑星/TNO は同じ数値 JD の専用 evaluator を使用する。全種類へ TDB と一律表示せず、未確定な時系・精度期間の診断を残す。全 record と元 source を維持し、評価可能行を一度分類して表示 OFF 時の全件計算を避ける。

37 byte 形式は 36 byte 部分が既知行と一致しても未評価のまま保持する。mp/mp2、TNO/TNO2、番号 -1、重複を暗黙統合しない。未確認の個別軌道 text や非楕円を、この adapter の適用範囲へ拡張しない。

| 対象 | 通常 / ASan・UBSan / x86_64 |
| --- | --- |
| PTH 位置 core | 各 353,093 checks PASS。Plus・通常版を同じ実行に指定 |
| 探査機 renderer | 各構成で Plus 107,995 / 通常版 28,811 checks PASS |
| SmallBodyModel 接続 | 各構成で Plus 58,963 / 通常版 20,138 checks 成功 |
| SolarSystemView 探査機操作 | 各 67 checks 成功 |
| 最新全 App リンクでの Solar 探査機操作 | 各 67 checks 成功 |
| 探査機 controller | 通常構成で 37 checks 成功 |
