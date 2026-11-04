# 単位3 最終独立ソースレビュー

確認日: 2026-10-29。基準 commit: `ae300e1e396c5ed0e6eb5129ad8a6f0069489597`。
単位3の最終調整後のソースを読み取りで確認した。**修正必須の新規指摘はない。**
この結論は以下の確認範囲に限り、全 Plus 機能の完成、原版との画素一致、最終統合試験の合格を意味しない。

## 確認範囲

`git diff HEAD` に含まれる単位3の製品ソース、ヘッダー、Makefile、回帰試験、対応範囲・出典・方針文書を対象とした。
レビュー中に主担当が stage したため、index と作業ツリーの両方を含む差分で確認した。

- 共通表示設定、恒星名称・マーク、惑星表示、自転軸、各ビューの描画と選択判定。
- 座標格子、距離目盛、銀河背景で共有する基底、観測地・日時の反映。
- 月間カレンダー、日付入力、日時情報の表示、JSON v3 の検証と復元。
- Lua worker / controller / アプリ間の入力検証、snapshot、共通 setter への接続。
- 新規オブジェクトのビルド・試験ターゲット、既存依存の利用、責務の分割。

UNIT4 の `renderer_options.hpp`、`RendererQuality.h`、`RendererQuality.mm`、`test_renderer_quality.mm` は対象外とした。
同じ作業ツリーにある次単位の衛星カタログ・自転の新規 core ファイルと UNIT4 文書も、単位3の実装として評価していない。
初回レビューでは `tests/test_display_output.mm` の進行中の修正を除外した。その後の private factory と遮蔽試験の変更は、下記の追加レビューで確認した。GUI 試験は別担当が逐次実行し、本担当は重ねて実行していない。
同時に stage されている次単位向け監査文書については、実装済みと未確定の区別を確認した。原本の逆解析を本レビューで再実施したものではない。

## 確認結果

| 観点 | 確認した内容 |
| --- | --- |
| 入力境界 | JSON の真偽値は数値と区別され、列挙値・必須項目・最大 1 MiB・バージョンを検証する。状態の適用前に構造と JD を検証する。Lua も型・引数数・列挙値を検証し、ホストの拒否をエラーとして伝える。 |
| 状態の同期 | メニュー、Lua、復元は共通表示 setter を通る。getter / toggle は最新 snapshot を取得する。復元で再生・時計追従・飛行を自動再開しない。 |
| 非表示時の動作 | 本体を隠した層では描画・名称・マーク・クリック判定・選択リングを抑止し、元データと選択を保持する。軌道表示は本体の可視性から独立している。停止中の恒星表示変更にも状態欄を更新する。 |
| 座標と描画 | 既存の core 座標変換を再利用し、観測地と JD を太陽系ビューの地平格子にも伝える。銀河基底は既存背景と共有し、逆変換は同じ基底の逆行列を使う。大きな距離目盛は描画前に投影・クリップする。 |
| 月間カレンダー | 42 セル、当月外の無効化、範囲端、月末への切詰めを確認した。月移動は入力候補だけを変更し、時分秒と UTC 時差を保持する。プログラムからの数値書込みは POSIX の区切りなし文字列であり、手入力の不正な桁区切りを受理する変更ではない。 |
| 回帰の対応 | 太陽系ビューの観測地・JD 伝播、停止中の恒星数、カレンダーの桁区切り問題に対する修正と回帰確認箇所を確認した。試験コードの存在を実行成功とは扱っていない。 |
| ビルド | 新規描画・幾何・ラベルのオブジェクトと試験ターゲットが既存 Makefile に接続され、利用する framework と core library の依存を持つ。 |

## 依存と責務

追加の外部ライブラリはない。
UI・描画は既存の AppKit / CoreGraphics、JSON は Foundation、Lua は既存の公式 5.4.9 helper、天文計算は既存 core を利用する。
新規の幾何・目盛・ラベル処理は、このアプリ固有の表示契約に閉じており、汎用 JSON parser、描画 framework、天文暦を重ねて実装していない。
今回の処理を置き換えるためだけに別ライブラリを追加する必要は認められなかった。

変更対象の製品ソースで 500 行を超えるファイルはない。主なファイルは `SkyView.mm` 493 行、`AppController.mm` 466 行、`ScriptWorker.mm` 448 行、`AppTimeCommands.mm` 348 行である。
表示設定の適用は `AppDisplayCommands.mm`、格子の幾何と描画は `grid_geometry.cpp` / `GridRenderer.mm`、恒星の名称生成と描画は `star_labels.cpp` / `StarRenderer.mm` に分かれている。
今回の差分に対する必須の責務分割はない。

## 実施した確認と未実施事項

`git diff HEAD --check` は成功した。
このレビューでは製品ソースを変更せず、ビルド・単体試験・GUI 操作を再実行していない。主担当と別担当の統合試験および GUI fixture 検証との競合を避けるためである。
通常・sanitizer・x86_64・実データ・GUI の最終実行結果は [README.md](README.md) に記録する。初回ソースレビューだけで policy gate 全体を合格とはせず、下記の追加レビューと最終試験結果を受領後にコピー上で判定した。

指定名 `/simplifier-lai` は利用可能なスキルに存在しない。利用可能な `simplify-lai` は LobbyAI 専用と規定されており、適用していない。
代わりに、上記の依存・責務・入力境界を手動で独立レビューした。本文の作成には `japanese-writing` を適用した。

レビュー文書を追加する直前の Git 差分は 75 files、4,156 insertions、315 deletions だった。この値には対象外の進行中 fixture と stage 済み監査文書を含む。
300 行以上の作業単位の commit は主担当へ引き継ぎ、本担当は stage / commit を行っていない。
初回レビュー時の本担当の変更はこのレビュー記録だけであり、`IMPLEMENTATION_POLICY.md` と `policy_gates/` のテンプレートは編集していない。追加依頼による gate のコピー判定は、後述の検証記録へ分けて残す。

## 投影 controller の追加レビュー

2026-10-29 19:58 JST、`DisplayOutputController.mm` と `test_display_output.mm` の最終 factory 差分を確認した。**修正必須の指摘はない。**

- 製品側の変更は `DisplayOutputController.mm:190` と `:210` の NSWindow 生成を private factory へ分離した部分だけである。style、backing、defer、ウィンドウ設定は従来と同じで、公開ヘッダーと依存ライブラリを変更していない。
- `DisplayOutputController.mm:219` の `updateTimer` は基準 commit から不変である。無効化・スリープ・参照元欠損・非表示・最小化・非 Visible のいずれかで停止する。timer 内でも毎回この条件を再確認する。sleep / wake / occlusion の通知処理も不変である。
- 通常試験は `test_display_output.mm:27` の NSWindow subclass が公開 `occlusionState` を制御し、公開通知を送る。試験 controller だけがその factory を使い、製品 controller の判定関数・タイマーを置き換えていない。
- 両モードは同じ `test_projection_lifecycle`（`:150`）を通る。表示中の更新、スリープ停止、起床後復帰、遮蔽直後の停止、遮蔽中の sleep / wake による停止維持、遮蔽解除後復帰、非表示中の wake と再表示、close・invalidate の停止を確認する。元の view を投影 window へ移すことも拒否する。
- 実 OS モード（`:183`、`:273`）は製品 factory の実 NSWindow を使用し、不透明な cover の描画完了と包含を待つ。実際の Visible ビットが解除されなければ失敗する。自動 skip、失敗を成功に変える分岐、実 OS モードへの状態注入はない。

担当者が逐次実行した通常・ASan / UBSan・x86_64 の単体試験は各 46 checks で成功した。生ログの成功行を本担当も確認した。`--system-occlusion` は exit 1 であり、完全遮蔽待ちで失敗している。通常試験の合格を WindowServer の遮蔽検出の成功とは扱わない。
根拠と OS 環境の切り分けは [occlusion-environment.md](occlusion-environment.md)、統合試験の最終結果は [README.md](README.md) に残す。

2026-10-29 20:06 JST、全 controller の通常 → ASan / UBSan → x86_64 逐次実行が3構成とも exit 0 と確定した。各生ログで Script、small-body 23、solar small-body 19、media 43、catalog browser 23、Playback、DisplayOutput 46 checks の成功行を確認した。x86_64 は Rosetta であり、Intel 実機ではない。実 OS モードの exit 1 は未通過として残す。

最終判定対象は UNIT3 の index に固定した。`git diff --cached --binary -- native/` の SHA-256 は `8d2bd45c5e0757e563d5d737240e0dd1e8ef2d0e103d47729558971c4a0e7b41` で、レビュー時の native 差分と一致する。並行して開始した UNIT4 の未 stage 差分は含まない。`git diff --cached --check` は成功。clean は最終 factory 前の core / GUI all test、後続 factory は3構成の strict build・単体・controller 一式で確認したものとして区別する。

[時刻付き gate 検証](../../../temp_gates/2026-10-29-20-01-49/VALIDATION.md) は14 gate / 判定条件138個を確認して YES と確定した。原本テンプレートはチェックせず、各コピーへ条件別の根拠を記録した。この結論は未通過の実 OS 遮蔽通知、未接続の UNIT4、旧 Plus の未実装機能を合格扱いするものではない。
