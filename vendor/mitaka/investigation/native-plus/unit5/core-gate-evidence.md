# UNIT5 core の gate 根拠監査

## 範囲と状態

2026-10-29、基点 commit `002adcf663fd5005e14ac86c343a3ec7e56fa706` の共有作業ツリーを読み取り監査した。
対象は `minor_planet_position`、`spacecraft_position`、`small_body_orbit_path` の新規 header / source / test、由来文書、既存 loader / evaluator との境界、および UNIT5 の個別検証記録である。
製品コード・policy・既存文書を変更せず、本書だけを追加した。テスト、旧アプリ、原本の再保存は実行していない。

以下の C 番号は、各 gate の「判定条件」を上から数えた番号である。統合文書担当が UNIT5 のテンプレート更新後に番号を照合した（`local_plus_assets` は 17 条件）。この追記は文書上の照合であり、独立監査担当が製品を再実行したものではない。
本書は [core_architecture](../../../policy_gates/core_architecture.md)、[data_contracts](../../../policy_gates/data_contracts.md)、[local_plus_assets](../../../policy_gates/local_plus_assets.md) の判定材料であり、**最終 YES 判定ではない**。
全アプリの最終試験と検証コピーへの判定は統合担当が確定する。原本保全の最終ログは本書末尾のとおり確認した。
UNIT6 の読取資料を同 commit に含める予定であることは承知しているが、本書の runtime 評価対象には含めない。

## 互いに読み替えない計算契約

| 境界 | コードと根拠から確認した内容 | 未確定・対象外 |
| --- | --- | --- |
| packed 36 小惑星・TNO | [header](../../../native/core/include/mitaka/minor_planet_position.hpp) と [由来](../../../native/core/MINOR_PLANET_POSITION_PROVENANCE.md) が `packed_36`、小惑星 / TNO、36 bytes、flag なし、有限な要素、`a > 0`、`n > 0`、`0 <= e < 1` を限定する。既存 `orbital_state` を使い、日心 J2000 黄道 AU を返す。 | packed 37 の追加 byte の意味・原版 reader、個別 text、非楕円 packed 要素は未認定。36 bytes 部分が同じでも 37 を評価しない。mp/mp2、TNO/TNO2 の優先順位や統合を推測しない。 |
| packed 36 の時刻 | 元期と要求の数値 JD を同じ尺度でそのまま使う legacy 契約。宣言期間は両端を含み、期間外は位置なし。期間がなければ `unknown_accuracy_range` を残す。 | UTC / TT / TDB の物理時系や変換は認定しない。成功時も `unresolved_time_scale` を残し、元 record の frame / time metadata を書き換えない。 |
| PTH | [header](../../../native/core/include/mitaka/spacecraft_position.hpp) と [由来](../../../native/core/SPACECRAFT_POSITION_PROVENANCE.md) が、元順の LE binary64 時刻 + XYZ、端点固定、内部の最初に一致した二分探索 mid、隣接標本の線形補間を記録する。位置は日心 J2000 黄道 AU。所有 snapshot を構築時に全件検査し、評価は O(log N)。 | 旧 pc 換算の丸め・原版との bit 一致、姿勢・形状は対象外。物理 UTC / TT / TDB は未認定で、同じ数値 JD を渡す契約と診断を維持する。範囲外は外挿ではなく端点固定。 |
| PPI | 元 bytes、全 segment、既存 `Trajectory` による native km 評価を保持する。新しい PTH 表示 evaluator は PPI に位置を返さない。 | PPI の表示原点・参照面・物理時系は PTH から継承しない。定義中の ORIGIN だけで表示位置を推定しない。 |
| 彗星の有限軌跡 | [header](../../../native/core/include/mitaka/small_body_orbit_path.hpp) と [検証記録](comet-display-helper-validation.md) が有限・狭義昇順の TDB JD、2～4096 標本を要求する。既存 `evaluate_small_body` のみを使い、全標本と診断を保持する。成功した隣接標本だけを結び、欠損を跨がず閉じない。 | packed 36 の legacy numeric JD evaluator へ自動で切り替えない。表示期間・標本数は native の表示契約であり、旧版の標本化や科学的な精度保証期間ではない。 |

この三つは新しい Kepler solver、座標の二重回転、暗黙の親天体加算、時系変換を追加していない。
PTH の二分探索は同時刻の元行を選ぶ規則に意味があるため、sort / deduplicate / lower_bound への置換を避けている。
原版の静的解析結果は由来文書から監査資料へ追跡できるが、本レビューでは旧実行ファイルを再解析・実行していない。

## core_architecture の根拠

| 条件 | 確認した根拠と範囲 |
| --- | --- |
| C1 | 三機能とも `native/core/include/mitaka/` と `native/core/src/` に分離されている。GUI の cache、非同期制御、表示集合は `native/gui/` 側にある。 |
| C2 | 新規 core source の include / 呼出しは既存 core と標準 C++ に閉じている。Windows / Wine / OpenGL / SceneKit / window API はない。個別試験は GUI をリンクせず実施した記録がある。 |
| C3 | 新 evaluator / sampler は file I/O を持たず、呼出側から record / dataset を受ける。既存 loader へ渡す原本 path は試験の引数。CWD 変更、暗黙の Wine 探索、原本書込みを追加していない。 |
| C4 | minor evaluator と sampler は戻り値を所有し、入力 record は const。PTH model は dataset を値で受けて所有し、検査結果も instance 内に持つ。可変の process global はない。 |
| C5 | C++17 と既存 loader / `orbital_state` / `evaluate_small_body` を再利用している。core Makefile の差分は三 source と三 test の登録で、新規外部依存・framework link はない。形式・式・原版との未検証差を由来文書に記載している。 |

対象三機能について、core を旧 UI の build に従属させる変更や不要な互換層は見つからなかった。
共有作業ツリー全体の依存追加有無をこの狭いレビューだけで確定したものではない。

## data_contracts の根拠

| 条件 | 確認した根拠と範囲 |
| --- | --- |
| C1 | 新 evaluator は byte parser を重複実装しない。既存の固定幅 LE loader が保持した型を利用し、36 / 37 bytes と PTH の 32 bytes を区別する。host `long` に依存する新規読込はない。 |
| C2 | minor は保存 bytes 長、flag、kind、variant、全要素、期間を検査する。PTH は source index、parsed / valid、source kind、空 / 長さ / 件数の不整合、全標本の有限性、元順の非減少時刻を構築時に検査する。既存 loader 自体の全異常系は UNIT5 最終回帰で別途確認する。 |
| C3 | header と由来文書が AU、日心 J2000 黄道、legacy numeric JD、TDB sampler、適用可能形式、端点固定、表示用標本数上限を区別している。物理時系と原版丸めの未確認を成功位置から消していない。 |
| C4 | 非対応形式・非有限値・範囲外・計算例外は位置なしと診断。sampling 要求不正は `invalid_argument`。PTH の探索は範囲を縮小し、補間の差・重み・結果も有限検査する。ゼロ座標を失敗代用として返さない。 |
| C5 | minor の結果は source key + ordinal、PTH は trajectory / source index、source key、必要時の原行 ordinal / offset を診断に残す。入力 index 自体が不正なら存在しない source を捏造しない。 |
| C6 | 37、個別小天体 text、PPI 表示、物理時系、原版 bit / 画素一致を対象外として記録している。raw の保持成功と位置評価成功を別に扱う。 |

小惑星の既存 loader 診断は元 record に残る。専用 evaluator は確認済みの面だけを結果から解消し、成功契約の識別子を返す。
PTH でも raw dataset の診断を削除して「全形式が解明済み」と扱わず、専用結果の契約と sampling provenance を返す。

## local_plus_assets の根拠と監査範囲

| 条件 | 根拠、または残る確認 |
| --- | --- |
| C1 | minor は source / ordinal / raw record を const のまま評価する。実原本の全行で source bytes の該当範囲、元 ID、未認定 metadata の不変を照合する test がある。同番号の大量追加・37 の別行・読込後の fixture 変更を含む。描画可能件数で dataset を縮めない。 |
| C2 | 37 / text 等は位置なしと理由を返す。legacy numeric JD と物理時系は更新後の gate が区別する。未評価行が一覧・検索に残ることは [N03/N04 検証](spacecraft-minor-validation.md) に記録されるが、全 GUI を本レビューで再実行していない。 |
| C3 | 既存二体計算を再利用し、sampler は楕円・放物線・双曲線、欠損標本、有限範囲、時刻丸め、最大標本数を試験する。packed 36 は確認できた楕円だけに限定し、他 conic を同形式で認定していない。 |
| C4 | 同 JD snapshot、pick、再読込の GUI 根拠は [N03/N04 検証](spacecraft-minor-validation.md) と [軌道 pipeline 検証](orbit-pipeline-validation.md)。最終 App smoke と共有 callback の修正後回帰は統合担当の結果を要する。 |
| C5～C7 | 衛星の既存契約と UNIT5 の別変更を対象三機能の根拠で代用しない。担当レビューと最終回帰の対象。 |
| C8 | PTH model が全 source / definition / trajectory を所有する。test は全 PTH 原 bytes の再構成一致、全原時刻の選択、同時刻行の保持、PPI の既存 km 評価と新表示位置なしの両立を照合する。更新後の gate は数値 JD 演算の確認と物理時系の未認定を区別する。 |
| C9～C11 | 表示集合・非同期予算・GUI の snapshot と線分境界は別担当のレビューと統合試験で確認する。C10 の core sampler 部分は上記の有限軌跡と個別ログが根拠であり、これだけで GUI 全体の条件を満たしたことにしない。 |
| C12～C16 | 背景・メディアは本レビューの範囲外。既存 gate の条件を今回の core 試験だけで満たしたことにしない。 |
| C17 | 個別試験には原 bytes 不変、fixture の読込後変更、全件保持・異常入力がある。`/tmp/mitaka-unit5-final-preservation.log` は 16,365 files / 6,622,642,667 bytes / 465 symlinks、追加・削除・変更 0、`passed: true` を記録する。本監査ではログを確認し、保全処理自体は再実行していない。 |

読み取り時点の原本観測値は、小天体全 19,475 行中 packed 36 が 8,451 行、PTH は 55,405 標本・隣接同時刻 14 組、通常版 PPI は表示未認定 17 trajectory。
これらは観測値であり、製品の読み込み上限や固定した全件数ではない。
彗星 sampler は 2,457 行を保持し、2,388 行を評価、69 行を未評価として残した記録がある。

## 確認できた試験ログ

既存ログを読み、ファイルの存在と成功行を確認した。下記を再実行したものではない。

| 証跡 | 確認結果と限界 |
| --- | --- |
| [n01-helpers](logs/n01-helpers/) | orbit path は通常 / ASan+UBSan / x86_64 各 17,341 checks。`SHA256SUMS` の 12 ファイルが一致。最初の `detect_leaks=1` 起動失敗も残り、成功は `san-supported`。LeakSanitizer は未実施。 |
| [n01-orbit-pipeline](logs/n01-orbit-pipeline/) | model / controller の三構成を記録する 10 ファイルの `SHA256SUMS` が一致。GUI の純粋 model / queue 境界の証跡で、全 App smoke とは区別する。 |
| [n03-n04](logs/n03-n04/) | PTH core は通常 / ASan+UBSan / x86_64 各 353,093 checks。Plus と通常版の動的全件数を出力。`SHA256SUMS` の 36 ファイルが一致。空の build log は存在するが、それだけで exit status を独立に復元したとは扱わない。 |
| minor 全件試験 | [由来文書](../../../native/core/MINOR_PLANET_POSITION_PROVENANCE.md) は三構成各 253,211 checks を報告。専用の全件 `.log` は unit5 配下と `/tmp/mitaka-unit5-*.log` から確認できず、N03/N04 文書担当も担当者の完了通知と provenance を根拠とした報告であることを確認した。この件数は保存ログを独立確認した結果ではない。 |
| 統合担当の core ログ | `/tmp/mitaka-unit5-core-{normal,san,x86}-test.log` が存在し、各々 minor 90,730、PTH 75,954、orbit path 141 checks の成功行を確認した。引数なしの合成試験であり、上記の実原本全件試験を代替しない。最終の全体 exit status は統合担当が確定する。 |
| 最終 reference / 保全ログ | `/tmp/mitaka-unit5-final-core-reference.log` の CF96 5,427 component comparisons 成功行と、`/tmp/mitaka-unit5-final-preservation.log` の上記全件不変・公式 ZIP 展開 310 files の差 0 を確認した。最終 core 三構成・Plus data / reference 成功は主担当から報告済みだが、全実行の対応表は最終統合記録へ委ねる。 |

x86_64 は Rosetta での実行記録であり、Intel 実機や macOS 13 実機の動作確認ではない。
旧アプリとの画素比較・旧 solver の丸め一致・実天体の暦表精度を、これらの成功件数から主張しない。

## 最終判定までに整理する事項

1. 時系の文言上の曖昧さは、統合文書担当が `local_plus_assets` C2 / C8 と不合格条件へ **確認した数値 JD 演算**と**未認定の物理時系**の区別を反映して解消した。最終検証コピーにも同じ条件を用いる。
2. minor の全件 253,211 checks × 3 は担当 provenance に基づく結果と明記し、保存ログのある core 合成試験 90,730 checks × 3 と混同しない。専用全件ログを独立確認したとは報告しない。
3. 現在の最終 tree に対する build / 全体 test / App smoke / 新規 clone、全 gate の検証を統合担当が確定する。保全最終ログの成功や別担当の個別ログだけで全体成功へ格上げしない。

対象三機能の読み取りでは、必須の製品コード修正は検出しなかった。
これは未認定形式・時系を解明済みとする判断でも、未完了の統合試験を免除する判断でもない。
Git status と差分を確認し、この担当では新規文書以外を編集せず、stage / commit、policy 更新を行っていない。
