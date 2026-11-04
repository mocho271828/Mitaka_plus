# N01: 小天体の一覧・描画・航行接続の検証

## 対象と完了範囲

2026-10-29。UNIT4 の commit `002adcf663fd5005e14ac86c343a3ec7e56fa706` を基点に、小天体の種類別表示、複数行の表示集合、固定 TDB 区間の軌道線を接続した。本書は N01 の局所検証であり、UNIT5 の全体試験、Lua worker との往復、状態保存、原本保全検査、policy gate の最終判定を代替しない。

原典の確定仕様と native の追加契約は [原典監査](comet-orbit-contracts.md) と [接続計画](n01-integration-plan.md) に記録した。数値計算・集合モデルは [helper 検証](comet-display-helper-validation.md)、非同期 snapshot は [pipeline 検証](orbit-pipeline-validation.md) を参照する。

## 実装した境界

- `SmallBodyRenderer` は body / label / orbit / pick に同じ可視性判定を使う。native の visible は種別全体の master であり、名称・軌道はそれぞれの設定に加えて visible と集合条件を満たすときだけ描画する。旧 Plus の優先順位の再現を主張しない。軌道は既存の `project_solar_segment` へ日心 J2000 黄道 AU を渡し、隣接する成功標本だけを結ぶ。終始点を自動で閉じず、欠損を跨がない。既存の描画品質 scope を使って点・線・文字を分離し、map に clip する。
- `SolarSmallBodies` は表示モデルと位置・軌道 snapshot の同一 dataset / model を検証する。新モデルへ切り替えると旧軌道・選択を除き、同じモデルの日時更新では表示集合を維持する。単一の選択は表示集合を変更せず、惑星・小天体・衛星・探査機の選択は相互排他にする。
- `SmallBodyController` は3種類それぞれの4フラグ、複数行の集合への追加・除去、固定 TDB 開始・終了 JD と標本数を表示する。検索・500件ページ・出典・Dark Aqua を維持し、複数行選択中は単一天体への「中心へ」を無効にする。入力拒否は元の設定を維持し、理由を画面へ表示する。
- `AppSmallBodyCommands` は設定コピーを検証してから適用し、要求行数 × 標本数の 524,288 上限を事前検証する。固定区間の初期値は、読込後の初期 JD ±182.625 日、129標本。変更時・再読込時は旧要求を取り消し、非表示中は計算を休止する。初期 JD の代入順、読込失敗時の再開、終了時の invalidate は統合担当の共有処理へ接続した。
- `AppScripting` は `Asteroids` / `TNObjects` / `Comets` の visible / labels / orbits / selectedOnly の snapshot と12種の変更 action を App の共通 setter へ接続する。worker 側の property / toggle と往復試験は Lua 担当の範囲である。

軌道 sampler は既存の TDB evaluator に限定する。N04 の packed 36 byte 小惑星・TNO は位置表示へ接続されているが、legacy numeric JD の軌道標本化は N01 の対象外である。未確定行は診断を保持し、原記録を削除しない。原版の sampling 期間・点数・線の画素一致は未確認である。

旧 Lua の英名による show / hide / isVisible は、複数 source の原記録への名前解決が未確定のため追加していない。native の source + ordinal 集合を旧英名と同一の仕様とは説明しない。

新しい依存は追加していない。C++17、既存の evaluator / projection / RendererQuality、Foundation / dispatch、AppKit を再利用する。担当の製品ファイルは責務ごとに分離し、既存の原本ファイルへ書き込む経路はない。

## 局所試験

専用出力 `native/gui/build-unit5-n01{,-san,-x86}` で実行した。全構成で C++17、`-Wall -Wextra -Wpedantic -Werror`、macOS 13 deployment target を指定する。通常・sanitizer は arm64、x86_64 は Rosetta であり、macOS 13 / Intel の実機試験ではない。sanitizer は ASan + UBSan、`halt_on_error=1` を使用した。

| 試験 | 通常 arm64 | ASan + UBSan arm64 | x86_64 / Rosetta |
| --- | --- | --- | --- |
| 小天体一覧 controller | 60 checks / exit 0 | 60 checks / exit 0 | 60 checks / exit 0 |
| 実 bitmap 描画、ローカル Plus データ | 148 checks / exit 0 | 148 checks / exit 0 | 148 checks / exit 0 |
| Solar 選択・追尾・overview 遷移 | 42 checks / exit 0 | 42 checks / exit 0 | 42 checks / exit 0 |

controller は全12設定の変更、ページを跨ぐ原行 ID の集合操作、単一選択との分離、不正数値・非有限値・標本数上限、入力拒否時の復元、最小ウィンドウ幅を確認した。

描画試験は、軌道線だけを描く合成場面を追加し、非空の画素、lineSmooth の作用、描画品質 master off と線の非平滑化の一致、pointSmooth / textSmooth が軌道線の平滑化を変更しないこと、種類非表示・空集合の非描画、集合復帰、拡大時の map 外非描画を確認した。名称表示を有効にして `nullptr` を渡した場合も、現在の AppKit 描画先の画素が変化しないことを確認した。既存の星・格子・カタログ・衛星等を含む試験も同じ実行で通した。ローカルデータの読み取り先は `/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/data` である。

## 独立レビューと統合境界

time_features 担当が renderer / Solar / controller / App と対応試験を読み取りレビューし、可視性の共通化、単一選択と集合の分離、絶対 TDB 区間、欠損区間、モデルの同一性、設定の事前検証について修正必須の指摘はなかった。pipeline 担当のレビューでは、地球・月表示で軌道を設定してから全体へ戻ると要求が再開しない共有 callback の欠落を検出した。

統合担当は `overviewVisibilityChanged` を航行の最終状態から通知し、App の要求再開へ接続した。`showSurface` は途中の全体表示状態を通知しないよう、航行状態を確定してから camera を変更する処理へ修正した。Solar 試験に、地球・月→全体、地球・月→内惑星、地球・月→表面→全体、同じモードの再指定の callback 回帰を追加した。

Solar の3構成は、これらの共有修正後に再ビルドし、上記42 checksで成功した。callback は最終状態と一致し、同じモードや地球・月→表面の遷移で一時的な overview を通知しないことを確認した。生成対象全体の strict build も3構成で exit 0 だった。

time_features 担当は最終 callback と軌道 bitmap 回帰も再レビューし、修正必須の指摘はなかった。その後 root の独立レビューで、null の CoreGraphics context を渡すと、文字描画だけが現在の AppKit context へ流れる経路を検出した。`draw_small_bodies` の入口で null を拒否し、上記の実画素回帰を追加した。この修正後は対象描画試験を3構成で再ビルド・再実行し、各148 checksで成功した。先行する145 checksの結果と区別して記録する。

共有 API の編集中に、衛星 master の削除途中と新規 session smoke の型の namespace 未修飾による build 失敗があった。これらを試験成功に含めず、所有担当の修正後に最終 build を行った。App 全体の smoke と Lua / session の確認結果は root の統合記録で確定する。

## 保存した証跡

[logs/n01-integration](logs/n01-integration/) に先行する成功6 buildログ、null guard 修正後の3 buildログ、最終9試験ログ、修正前の描画試験3ログ、途中失敗6 buildログ、実行コマンドの記録を保存した。`SHA256SUMS` は28ファイル、`SOURCE_SHA256SUMS` は担当境界の製品・試験10ファイルを記録する。共有 `AppScripting.mm` の hash はこの局所検証時点のファイル全体に対する値である。

Git status、変更ファイル、差分量を確認した。300行を超える変更を含むため、担当では stage / commit せず親の UNIT5 commit 単位へ引き渡す。正確な名前の `/simplifier-lai` は利用可能な一覧にない。独立した読取レビューを行い、commit 前の全差分品質・policy gate は親作業が担当する。N01 担当では `IMPLEMENTATION_POLICY.md` / `policy_gates/` を変更していない。
