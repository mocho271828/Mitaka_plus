# P1-4 個別小惑星・外縁天体の検証

実施日: 2026-11-07。基点は `84a6867884314f8eeeabe7b29b066e44c135e0d7`、ブランチは `codex/mitaka-small-body-formats`。別 PC の担当と調整し、カメラ・地形・銀河・時刻・描画設定ダイアログとは別の小天体 core/model を担当した。前回の Lua 等4成果は取り込まず、この基点への独立差分とした。

## 変更と契約

同梱個別ファイルは読み込み済みでも位置を評価できなかった。旧 Plus の個別 reader と共通 evaluator の接続を別 PC の静的調査で確認し、a 指定の楕円 Asteroid/TNObject を位置・一周期軌道・GUI snapshot に接続した。[根拠監査](minor-planet-individual-format-audit.md)に実行ファイルの識別、アドレス、全57本の原 bytes / SHA-256 を記録した。

既存の C++17 loader、`orbital_state`、軌道標本化、表示集合と renderer を利用する。新しい数値解法・依存ライブラリ・パーサーは追加していない。共有の描画本体を変えず、小天体の評価分類と説明を接続した。

旧 reader は binary32 を経由するが、native は double の元期・要素と既存の a 由来 n を維持する。旧 float 丸め・番号上書き・標本則・画素一致を保証しない。物理時系は未認定の数値 JD、成功位置は日心 J2000 黄道 AU。全出典・通常/日本語・同番号を source + ordinal で独立保持する。

明示 n、非楕円、37 byte、個別彗星の未確定 Tp、`Size/B_V/Visible/DwarfPlanet` の表示適用は対象外。旧 n 補完条件は監査で判明したが、今回は同梱57本の a 指定形式に限定した。

合わせて次の2件を修正した。

- 極端な有限 a から n が infinity / 0 になる入力を、a の行位置付きエラーで出典単位に拒否する。原 bytes は保持し、他ファイルを読み続ける。
- packed37 の frame/time_scale を確定扱いに書き換えた記録でも、汎用 evaluator から位置・軌道を得られないよう拒否する。既存 loader はこれらを未確定に保つため、実データ経路への新しい権限や形式対応は追加しない。

## 専用試験

5本を通常・実データ引数付きで実行した。データは本 worktree の `resources/data`（絶対パス）。件数は実際に読み込んだ全行から導出し、固定57件を runtime の許可条件にしない。

| テスト | 合成入力の checks | 実データ込み checks |
| --- | ---: | ---: |
| `test_small_body_catalog` | 78 | 29,106 |
| `test_minor_planet_position` | 90,969 | 262,526 |
| `test_minor_planet_orbit_path` | 1,101 | 2,230,198 |
| `test_small_body_model` | 20,145 | 59,030 |
| `test_small_body_orbit_model` | 67 | 1,145,451 |

全19,475行を保持。位置対応は packed36 8,451 + 個別57 = 8,508 行、これに固定幅彗星2,388行を加えた GUI 位置は10,896行。一周期軌道は8,508×129=1,097,532標本。個別は Asteroid 42、TNObject 15、通常/日本語の同番号7組を含む。

loader経由の円軌道・四分周期・回転、離心率境界、明示 n/未対応形式拒否、派生値の異常、原 bytes、出典単位失敗、期間・取消、selectedOnly、非表示時の省略、名称検索と契約説明を確認した。初回 GUI 軌道試験は新fixtureの source一覧とIDが不一致で失敗し、fixtureを修正後に全10実行が成功した。実装の失敗を成功扱いにせず記録する。

core の3本は独立した `BUILD_DIR=build/p1-4-sanitize SANITIZE=address,undefined` でも通常・実データ付きの全6実行が成功。警告・ASan/UBSan診断なし。

ログ: `/tmp/mitaka-p1-4-focused.log`、`/tmp/mitaka-p1-4-sanitize.log`。

## 全体検証と実画面

`make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は全て終了0。今回 smoke の再試行は不要だった。ログは `/tmp/mitaka-p1-4-{build,test,data-test,reference-test,smoke}.log`。最終のソース注釈調整はコメントのみで、検証後の計算・操作処理の変更はない。

実画面では同梱データで `orbits/asteroids/ceres` を検索し、Ceres / セレスを別出典の2行として確認。日本語出典 `ceres_jp.dat #0` のみを表示集合へ追加し、「表示集合のみ」「軌道線」で1行×129標本・欠損0を確認した。「選択して3Dの中心へ」で追従状態となり、+1日で JD 2451545→2451546、位置は (-2.37980, 0.79747, 0.46313)→(-2.38337, 0.78688, 0.46346) AU に更新された。原本19,475行・位置対応10,896行・出典診断0、個別形式と物理時系未確定の説明も確認。

画像・AXによる実画面確認であり、旧版の画素比較ではない。主画面に既存の `eclipse satellite identifier is absent: Calliso` 警告が表示されることも確認したが、本単位では原本名や衛星機能を変更しない。TNOの手動操作・全形式の実画面操作は未実施で、全57本の計算とmodelは自動試験で検証した。

## 変更管理と未検証

原本57本・12,891 bytesは基点のGit blobとbyte単位で一致。`resources/`、公式原本 `vendor/mitaka/sources/`、Rust移行Markdownは変更していない。旧 executable・Wine prefixはこのPCにないため実行・旧版画素比較は未実施。物理時系・観測精度、n指定や非楕円の互換、Intel/macOS 13実機は未検証である。

`IMPLEMENTATION_POLICY.md` と `policy_gates/preservation.md` に個別形式の採用範囲・既存原本保持との関係を追記。指定名 `/simplifier-lai` は利用可能な skill に存在せず未実行。独立した実装・テスト・資料担当で差分をレビューし、新規依存が不要なことを確認した。[gate検証コピー](../../temp_gates/2026-11-07-03-59-05/)は全条件をチェックして YES。不合格条件の未チェックは該当なし。コミットIDとbundle受領記録はGit履歴およびGit管理外の引き継ぎ資料で特定する。
