# LUA-03: Lua 対話コンソールの実装と検証

検証日: 2026-11-07（JST）。macOS 26.6.2 / arm64、Apple clang 21.0.0。

## 基点と分担

- 作業開始時は `main`、HEAD `215d9a23ad768b4529a02d0e97384847d6ae6b24`、作業ツリーは clean。
- `origin/codex/mitaka-04c-large-scale-continuity` を取得し、`84a6867884314f8eeeabe7b29b066e44c135e0d7` から `codex/mitaka-lua-console` を作成した。
- 別 PC のカメラ・地形・銀河・時刻の実装を変更しない。コンソール UI、Lua 評価、実行テストを分担し、既存ファイルへの接続をコンソール周辺に限定した。データ原本、Rust 移行 Markdown、main は変更しない。push・他ブランチへの統合・公開設定変更は行わない。

## 実装範囲と仮定

- `ScriptConsoleController` が複数行入力、実行/取消、出力、履歴を担当する。既存の出力画面を「Lua コンソール」へ拡張した。Return は改行、Command+Return は実行、Option+↑/↓ とボタンは履歴。IME 未確定中の実行/履歴移動を防ぐ。
- `lua_console.cpp` はまず `return ` を同じ行に前置してコンパイルし、構文エラーなら元の文をコンパイルする。試行は実行ではなく、副作用を二重実行しない。実行失敗後に文として再試行しない。明示 return、複数値、nil、Lua の `__tostring` に対応し、文字列化自体の失敗も保護呼出しで扱う。
- 結果は `=> ` とタブ区切り、出力・エラーは入力に続けて表示する。構文/実行エラーは `console.lua:行番号` と Lua の診断・traceback を使う。列番号はない。既存 print の整形と改行は維持する。
- 旧 Plus の対話環境の寿命・履歴操作の詳細は未確定。既存 helper の起動単位に合わせ、**入力ごとに独立 Lua 環境**と仮定した。変数は入力間で残らず、一つの複数行入力内では共有できる。画面にも明記する。ホストの状態変更・ファイル書込みは取り消されない。
- 履歴は100件かつ合計1 Mi UTF-16文字、表示ログは末尾1 Mi文字、入力は UTF-8 で1 MiBまで。履歴末尾へ戻ると未実行の下書きを復元する。履歴はプロセス内のみで、保存・自動再実行しない。戻り値の表示は8 KiBで明示的に切り詰め、正常なUTF-8の末尾を分断しない。
- 実行はユーザーのボタン/キー操作に限定する。既存 `ScriptController` の同じ一時ファイル保護・helper・時間/命令/メモリ上限・プロセス群取消・標準ライブラリを使う。オンライン実行、通常データの自動実行、権限拡張はない。
- AppKit・標準 C++・同梱公式 Lua 5.4.9 を使用し、新規依存はない。式の試行は同梱 `lua.c` の `addreturn` と公式 manual の API を根拠に実装した。

## 検証結果

| 検証 | 結果 |
| --- | --- |
| `make -j4 build` | 成功、終了コード0。文字色修正後にも成功 |
| `make -j4 test` | 成功、終了コード0。既存script/controllerと追加UI/実行テストを含む |
| `make -j4 data-test` | 同梱 `/Users/kota/playground/Mitaka_plus/resources/data` で成功、終了コード0 |
| `make -j4 reference-test` | CF96・自転・月・大気・食・銀河の公式比較に成功、終了コード0 |
| `make smoke` | 全体成功、終了コード0。既存Lua・print・GUI.scriptOutput、実データと連続飛行を含む |
| 最終 `make -C vendor/mitaka/native/gui script-console-test` | UI 29 checks、console execution tests passed、終了コード0 |
| `git diff --check` | 成功 |

専用実行試験は、式・文・複数return/nil・日本語・printと結果順序・二重実行拒否・既存ホストAPI・環境分離、2行目の構文エラー・関数内の実行エラー・非文字列エラー・文字列化エラーと復帰、命令/メモリ制限、`waitTime`/外部コマンド取消・helper終了後の復帰、既存HTML用runSourceの挙動、入力/結果の上限を確認した。UI試験は履歴境界・下書き・100件上限、再入・取消重複・起動拒否、IME・通常改行、Unicode出力の境界、ダーク表示の標準文字色を確認した。

ローカルログ: `/tmp/mitaka-lua-console-{build,test,data-test,reference-test,smoke}.log`、最終修正の `/tmp/mitaka-lua-console-build-final.log`、`/tmp/mitaka-lua-console-focused-final.log`。初回の専用 target はテストファイルの並行作成中に未存在で停止した。ファイル生成後の全体 test と最終専用 target は成功した。

## 実画面

同梱データを `--data-root` で指定したアプリを開き、メニューからコンソールを表示した。`6 * 7` → `42`、複数行の local/print/return → `42 nil true`、構文/実行エラーの2行目表示、エラー後の正常実行、Option+↑/↓による履歴/下書き復元、実行ボタン・実行中の無効化、`waitTime(30)` の取消、取消後の print を操作して確認した。

ダーク表示の出力文字が黒くなる問題を実画面で発見し、入力・出力に AppKit の動的な標準文字色を設定した。修正版を再起動し、入力・追記出力が読めることを画面で確認し回帰試験を追加した。再起動後のデータ未選択時には入力を保持して理由を表示することも確認した。既存の「データを開く」パネルは data を選んでも Open が無効になる事象があり、この単位では変更しない。最初の実行確認には起動引数を使用した。

## 残る確認と変更管理

旧 Plus の実機比較、Lua 5.1との完全互換、変数/履歴寿命の旧版一致、補完、Intel/macOS13実機、sanitizer再実行は未実施。今回の機能は同梱5.4.9のnative契約として記録し、旧版全体の互換完了とはしない。データ原本の全件再ハッシュは行わず、`resources/` と `vendor/mitaka/sources/` にGit差分がないことと既存保全記録を確認した。

正確な名前の `/simplifier-lai` は skills と plugin cache に存在せず未実行。類似名の別 skill と同一視せず、依存の妥当性と全差分を独立レビューした。レビューで見つけたファイル選択中の別コンソール実行との競合は、出力を消去する前の再確認で修正した。新規コードの責務を分離し、既存ホストAPIの独自再実装を追加していない。

`IMPLEMENTATION_POLICY.md` と preservation/shared_implementation gate に明示入力・既存権限・環境/履歴寿命の条件を追記。機能対応表と優先表を更新した。gate検証コピー: `temp_gates/2026-11-07-03-02-25`。Git状態・変更ファイル・差分量を確認して、この作業単位をcommitする。
