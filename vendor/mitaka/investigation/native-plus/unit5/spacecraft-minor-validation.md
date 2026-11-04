# N03 探査機・N04 小惑星/TNO の実装と局所検証

2026-10-29。単位 4 `002adcf663fd5005e14ac86c343a3ec7e56fa706` に続く単位 5 の記録である。ローカル Plus と通常版の入力を読み取り専用で使用し、原ファイルを変更・再配布せず、件数を公開データへ合わせていない。ここに示す件数は入力を実行時に数えた観測値であり、実装上限や固定 assertion ではない。

## N03 の確定範囲

根拠は [Plus PTH の静的監査](../unit4/spacecraft-position-contracts.md)、[core provenance](../../../native/core/SPACECRAFT_POSITION_PROVENANCE.md)、[renderer provenance](../../../native/gui/SPACECRAFT_RENDERER_PROVENANCE.md)。旧実行ファイルを実行した比較ではない。

`SpacecraftPositionModel` は loader の全 source、原 bytes、定義、言語 section、trajectory、原行を所有する。PTH の `(time,x,y,z)` は binary64 の原 AU を使い、同じ数値 JD で端点判定を先に行う。内部は二分探索で最初に一致した mid、または隣接する原標本の重み付き線形補間を返す。等時刻・異座標を平均、統合、並べ替えしない。範囲外は端点固定であり、天文学的な外挿ではない。元の物理時系 UTC/TT/TDB は認定せず、成功位置にもその診断を残す。

位置は日心 J2000 黄道 AU。旧内部 pc への往復や旧 binary32 係数の丸めを再現したとは主張しない。モデル構築時の全件検査と評価時の O(log N) 探索を分ける。PPI は原資料と既存四点補間器を保持するが、表示に必要な原点・座標面・物理時系が未確定なので、この表示モデルから位置を返さない。

GUI 一覧は定義単位の全行を保持し、CP932/UTF-8 の表示文字列と未解決理由を扱う。`spacecraft_scene_position` は定義→trajectory→source の参照、PTH 契約、同じ JD、有限値、評価結果と snapshot の位置一致を描画・focus・追尾で共通検査する。PPI に座標を付け足した偽の snapshot でも描画位置を返さない。

点・名称・原標本軌跡は独立設定であり、native 初期値は `points=true, labels=false, orbits=false`。点を消すと選択リングと pick も消え、名称・軌跡は独立して表示できる。全体非表示は選択 ID を保持して全描画・pick を止める。これは原 Plus の初期値を確定したという意味ではない。軌跡は原順の隣接点だけを結び、背面・near plane・不正値を跨がない。1,024 本単位の stroke はバッチ境界であり、件数の切捨てではない。

## N04 の確定範囲

根拠は [packed 36 byte の監査](minor-planet-position-contracts.md) と [core provenance](../../../native/core/MINOR_PLANET_POSITION_PROVENANCE.md)。既存 loader と `orbital_state` を使い、確認済みの asteroid/TNO の `packed_36`、有限な `a > 0`、`n > 0`、`0 <= e < 1` だけを専用 evaluator へ渡す。新しい Kepler solver、太陽位置加算、時刻変換は追加しない。

GUI の `SmallBodyEvaluationMode` は `comet_tdb`、`packed36_legacy_jd`、`unresolved` を区別する。確認済み JPL 彗星は既存 TDB evaluator、36 byte 小惑星/TNO は同じ数値 JD の専用 evaluator を使用する。全種類へ TDB と一律表示せず、未確定な時系・精度期間の診断を残す。全 record と元 source を維持し、評価可能行を一度分類して表示 OFF 時の全件計算を避ける。

37 byte 形式は 36 byte 部分が既知行と一致しても未評価のまま保持する。mp/mp2、TNO/TNO2、番号 -1、重複を暗黙統合しない。未確認の個別軌道 text や非楕円を、この adapter の適用範囲へ拡張しない。

## 保存した試験ログ

Apple clang、C++17、`-Wall -Wextra -Wpedantic -Werror` で検証した。GUI は macOS 13.0 deployment target。通常 ARM64、ASan/UBSan、x86_64 は別出力ディレクトリを使う。x86_64 の実行は Apple Silicon 上で行ったもので、Intel 実機検証ではない。ログは [n03-n04](logs/n03-n04/) に元の名前で保存し、[SHA256SUMS](logs/n03-n04/SHA256SUMS) に内容ハッシュを記録した。

| 対象 | 通常 / ASan・UBSan / x86_64 | 証跡 |
| --- | --- | --- |
| PTH 位置 core | 各 353,093 checks PASS。Plus・通常版を同じ実行に指定 | `mitaka-unit5-spacecraft-position-{normal,sanitize,x86}.log` と対応 `-build.log` |
| 探査機 renderer | 各構成で Plus 107,995 / 通常版 28,811 checks PASS | `mitaka-unit5-spacecraft-renderer-{normal,sanitize,x86}-{build,test}.log` |
| 探査機 renderer の null-context 回帰追加後 | 各構成で Plus 107,996 / 通常版 28,812 checks PASS | `mitaka-unit5-spacecraft-renderer-null-context-{normal,sanitize,x86}-{build,test}.log` |
| SmallBodyModel 接続 | 各構成で Plus 58,963 / 通常版 20,138 checks 成功 | `mitaka-unit5-smallbody-model-{normal,sanitize,x86}-{build,test}.log` |
| SolarSystemView 探査機操作 | 各 67 checks 成功 | `mitaka-unit5-solar-spacecraft-{normal,sanitize,x86}-{build,test}.log` |
| 最新全 App リンクでの Solar 探査機操作 | 各 67 checks 成功 | `mitaka-unit5-solar-spacecraft-canonical-{normal,sanitize,x86}-{build,test}.log` |
| 探査機 browser model | 通常構成で Plus 93 / 通常版 63 checks PASS | `mitaka-unit5-spacecraft-browser-{build,plus,regular}.log` |
| 探査機 controller | 通常構成で 37 checks 成功 | `mitaka-unit5-spacecraft-controller.log` と `-build.log` / `-syntax.log` |

小惑星 core の通常・ASan/UBSan・x86_64 は、担当の [provenance](../../../native/core/MINOR_PLANET_POSITION_PROVENANCE.md) に各 253,211 checks PASS と記録されている。この文書作成では再実行していない。上表の GUI model 試験は別の検証である。

独立レビューで `draw_spacecraft` の null CGContext 検査不足が見つかったため、入口で描画を止める guard を追加した。回帰テストは有効な AppKit 描画先を current context にしたまま null CGContext を渡し、点・名称・軌跡を全て有効にしても画像が不変であることを確かめる。旧ログは残し、修正後の renderer 全試験を三構成・両データで再実行した。

実入力の観測値は、Plus PTH 55,405 行と等時刻の隣接 14 組、通常版 PPI 17 軌道。renderer では Plus の 14 定義から投影可能な 79,184 原線分、通常版の 13 定義から 0 線分を得た。小天体は全 19,475 行を保持し、そのうち 8,451 packed 36 byte と 2,388 彗星の計 10,839 行で位置を得た。通常版には該当小天体 0 行で、欠損診断と空表示を正常に処理した。

## SolarSystemView 回帰の範囲

`test_solar_spacecraft.mm` は NSApplication と view を生成するが、ウィンドウは開かない。新規 renderer の画素試験は CGBitmap で実施した。確認した操作は以下である。

- focus、同じ JD の更新、日時追尾、端点固定。PPI・未解決・無効 index の選択はカメラを動かさない。
- null model、配列寸法不整合、NaN/Inf の snapshot を原子的に拒否し、選択・カメラ・追尾・通知を維持する。
- planet / small body / satellite / spacecraft の選択排他、同位置で後の定義を pick、点 OFF・全体 OFF・地球月表示での pick 抑止。
- 全体非表示でも選択を保持し、focus で表示を戻す。モデル交換・unload では古い探査機の選択と追尾を解除する。
- 合成カメラ smoke の前後で探査機の snapshot、選択、表示設定、追尾、カメラを復元する。

並行実装中は全 App オブジェクトのリンクが未成立だったため、必要な view/render/model のオブジェクトを同じ構成でビルドして局所リンクした。全 App smoke を実行済みという記録ではない。最初の通常ビルドでは `OBJECTS` の一時上書きが core 子 make に伝播し、core を正しい構成でビルドし直した。途中のエラーも build ログに保持した。初回試験で不足していた SmallBodySource の fixture メタデータを補い、製品の検証を緩めずに三構成を再実行した。

その後の root 統合 controller-test では、最新の `SatelliteDisplayModel` が選択排他試験の衛星 fixture を `satellite display definition source is missing` で拒否した。fixture の定義 ID に対応する `SatelliteSource` がなかったことが原因である。読み取り済みの `system_definition` 出典と件数を fixture に追加し、製品の検証は緩めていない。失敗時の controller ログは `mitaka-unit5-solar-spacecraft-canonical-controller-before.log` に保持した。修正後は root の最新 `build-unit5-integration` / `-san` / `-x86` の全 App オブジェクトとリンクし、対象試験を直列で実行して三構成各 67 checks の成功を確認した。この再確認もアプリ全体 smoke の代用ではない。

## 未完範囲と確認の限界

N03 は機体 mesh、姿勢、可動部、Hayabusa/Akatsuki 固有の表現、旧版の表示期間・初期値、PPI の表示契約、テキストから PTH を生成する処理を含まない。N04 は 37 byte 形式の意味・優先関係、未確定の個別形式、旧版 Newton 法・float 換算の bit 一致を含まない。成功位置の物理時系や天文学的精度を、表示できた事実から認定しない。

N01/N02 の表示 API・軌道制御、N05/N06、Session v5、Lua と全体メニューの最終適用、Plus/通常版の App 全体 smoke、画像保存、クリーン出力、原本保全照合、全 policy gate は root/各担当の最終記録で判定する。局所の保存・復元試験を全体セッション検証の代用にしない。

依存は既存 C++ コア、標準ライブラリ、AppKit/CoreGraphics/ImageIO と既存投影・品質管理を再利用した。独立した読取レビューで PTH/36 byte の数式・契約、GUI の文字コード・全行保持・未解決表示、snapshot の共通検証を照合した。レビュー担当が試験を再実行していない場合は、上記実行結果と区別する。記録作成中の製品変更は上記 null-context 修正に限定し、原データ・policy は編集していない。stage/commit は root の統合単位に委ねる。
