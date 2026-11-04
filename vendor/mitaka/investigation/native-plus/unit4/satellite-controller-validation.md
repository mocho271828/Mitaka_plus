# UNIT4: 衛星一覧コントローラの検証

検証日: 2026-10-29。対象は UNIT4 作業ツリーの `SatelliteController.h` / `SatelliteController.mm` / `test_satellite_controller.mm`。衛星の原典解釈・位置計算・モデル読込み・主アプリ接続は別担当の検証範囲とする。

## 実装の範囲

- 既存 `SmallBodyController` と同じ AppKit のウィンドウ、検索欄、一覧、詳細欄、ページ操作、選択・中央へボタンを使用する。新しい外部依存は追加していない。
- 表示列は衛星名、親天体、出典ファイルと原本内の順番、位置評価の状態。名前と親天体はモデルの表示文字列を使い、コントローラで天体識別や座標を推測しない。
- 全行を保持するモデルに対し、出典と検索文字列で非同期検索する。500 行は画面のページサイズであり、読込み上限ではない。同名・同一言語・別言語の行を統合しない。
- 検索とモデル交換には世代番号を使い、古い検索結果と選択を破棄する。選択 callback はモデルの原行 index と中央へ移動する意図だけを main thread で返す。位置が未解決でも診断のために選択できる。3D での移動可否は接続先が判断する。
- snapshot は同一モデルのものだけ受け付け、差し替え時には選択を維持する。隠れている間の更新は再表示時に詳細欄へ反映する。不一致の snapshot は適用前に例外で拒否する。
- 原本の読書きは行わない。テストはメモリ内に 1,037 行の合成データを作り、実データの件数や内容を固定しない。

## 試験結果

通常・AddressSanitizer + UndefinedBehaviorSanitizer・x86_64 の専用ディレクトリで `-Wall -Wextra -Wpedantic -Werror` ビルドを通過した。実ウィンドウを使用する試験は他の GUI 試験と重ならないよう逐次実行し、3 構成とも 38 checks、exit 0 で完了した。

対象の試験は、ページ送り、最後の高 index の検索、最新検索の優先、出典を跨ぐ同名行の保持、親天体表示、出典選択、main thread の選択 callback、位置・日時更新、非表示からの再表示、データ交換時の古い選択と検索の破棄、不一致 snapshot 拒否、空モデルへの切替、ボタンのレイアウト幅を確認する。

ビルドログ:

- `/tmp/mitaka-unit4-satellite-normal-build.log`
- `/tmp/mitaka-unit4-satellite-san-build.log`
- `/tmp/mitaka-unit4-satellite-x86-build.log`

実行ログ:

- `/tmp/mitaka-unit4-satellite-normal.log`
- `/tmp/mitaka-unit4-satellite-san.log`
- `/tmp/mitaka-unit4-satellite-x86.log`

独立レビューでも修正必須の指摘はなかった。モデル交換前の旧行消去、世代番号と weak self による古い検索結果の破棄、全件数とページサイズの分離、出典と原行 index の保持、未評価行の選択、非表示中の snapshot 更新と再表示、同一モデルでの選択維持を照合した。

## 統合との境界

主アプリの衛星メニュー、データ読込み、日付更新、3D の選択と移動、ローカル原本を使った表示は統合側で別途確認する。この試験の合格を旧 Plus の衛星計算の完全互換や全機能実装の証拠とはしない。

新規 3 ファイルは計 390 行。Git 状態・差分量と `git diff --check` を確認した。統合担当が policy gate と全体差分を確認してまとめて commit するため、この担当では stage / commit を行わない。`/simplifier-lai` の可否確認と commit 前レビュー、方針文書・gate の更新は統合担当へ引き継ぐ。
