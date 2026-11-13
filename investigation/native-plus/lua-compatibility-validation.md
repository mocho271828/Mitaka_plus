# LUA-04: Lua 5.4.9 標準機能と旧スクリプトの互換監査

確認日: 2026-11-07。

## 結果

- `make -s -j4 -C vendor/mitaka/native/gui lua-compatibility-test script-test` が終了 0。新規の標準機能・互換監査は **168 checks**、既存の ScriptController 回帰も成功した。
- `resources/scripts/*.lua` は **12 件すべてをコンパイルだけ**試みた。9 件は構文を受理し、日本語版 3 件は後述の既知の escape 不整合として拒否した。原本、`init.lua`、原本内のコールバック文字列を実行していない。
- この試験の成功は「既知の非互換を含む現在の契約が確認できた」という意味であり、旧スクリプト 12 件の実行互換や旧 Plus の再現成功を意味しない。
- 全 12 件の原 bytes はコンパイル前後で一致し、[SHA-256 一覧](../../verification/lua04-script-SHA256SUMS) に対する `shasum -a 256 -c` も全件成功した。

環境は macOS 26.6.2 / arm64、Apple clang 21.0.0。

## 全体回帰

`DATA_ROOT` はリポジトリの `resources/data`。

| コマンド | 結果 |
| --- | --- |
| `make -s -j6 build` | 成功 |
| `make -s -j6 test` | core / GUI / controller 成功 |
| `make -s -j6 data-test` | 同梱 Plus データの読み取り検証成功 |
| `make -s -j6 reference-test` | CF96・自転・月・大気・食・銀河 kernel 比較成功 |
| `make -s smoke` | AppKit / Script / Session / Plus と連続飛行を含む全体 smoke 成功 |

アプリ全体の表示・操作は smoke で確認した。旧 Plus 実機との照合は未実施。

## 試験の境界

新規試験は [test_lua_compatibility.mm](../../vendor/mitaka/native/gui/tests/test_lua_compatibility.mm)。実行には既存の `ScriptController.runSource` と `MitakaScript` を使い、試験用に作成した短いソースだけを実行する。ファイル操作・`dofile`・`require` は専用の一時ディレクトリ内の fixture に限定する。`os.execute` は終了コードを返すだけの `exit 0` / `exit 7` を確認する。天文ホスト変更の callback は常に拒否する。

期待する原本 12 ファイル名の集合も照合し、欠落・追加・改名を監査更新なしに通さない。原本のコンパイルには `loadfile(path, 't', {})` を使う。返された関数は呼び出さず、bytecode は許可しない。コンパイル診断の非 ASCII bytes は監査用の出力だけで `\xNN` に変換し、原本は変換・再保存しない。既知の拒否対象・行番号・エラー種別は明示的に照合し、別の拒否や既知結果の変化を黙って成功扱いしない。起動や通常のデータ読み込みには接続せず、専用 Makefile target の明示実行で検証する。

| 対象 | 今回確認した範囲 |
| --- | --- |
| 基本構文 | nil/boolean/number/string、短絡条件・if・break、数値/汎用 for・while・repeat、closure、varargs、複数戻り値と nil |
| 標準ライブラリ | string の抽出・pattern・置換・format、table の sort/insert/remove/concat/pack/unpack/move、utf8、pack/unpack、math |
| エラーとオブジェクト | pcall/xpcall/debug.traceback、metatable、rawget/rawset、coroutine の yield/resume/status/close |
| 現行言語機能 | `_ENV` と `load` の環境指定、integer/float、整数除算・bit 演算、`<const>`・`<close>` |
| ローカル入出力 | fixture の dofile/require と module cache、io.open/read/write/close、os.remove/date/clock/execute |
| 実行境界 | 構文・実行エラー、命令予算、waitTime の取消、その後の再実行。既存 script-test でファイル/OS 権限と外部プロセス取消も再確認 |

## Lua 5.1 と現行 helper の差

Lua 5.4.9 の根拠は同梱する `vendor/mitaka/native/gui/vendor/lua-5.4.9.tar.gz` 内の `doc/manual.html`、`src/lua.c`、`src/llex.c`、`src/lbaselib.c`、`src/linit.c`。固定 SHA-256 は既存 `tools/build_lua.sh` が検証する。`_VERSION` は `Lua 5.4` までを表し、patch version は同梱ソースと build script で特定する。

以下は実行で確認した 5.4.9 の状態と公式 5.1/5.2 文書の比較である。旧 Plus 内蔵 Lua 5.1 の実機結果ではない。[Lua 5.1 Reference Manual](https://www.lua.org/manual/5.1/manual.html)、[Lua 5.2 のライブラリ変更](https://www.lua.org/manual/5.2/manual.html#8.2) を参照。

| 旧 API・動作 | 現行 helper の状態 | 扱い |
| --- | --- | --- |
| `setfenv` / `getfenv` | nil | `_ENV` / `load(..., env)` があるが、互換 wrapper は追加しない |
| `module` | nil | fixture は table を返す module と require cache を検証 |
| global `unpack` | nil | `table.unpack` を検証。nil を含む末尾は明示した範囲で保持 |
| `loadstring` | nil | 文字列を受ける `load` を検証 |
| `table.maxn` / `package.loaders` | nil | `package.searchers` が存在。maxn の独自代替は追加しない |
| `math.mod` / `string.gfind` | nil | 古い互換名も利用可能とは扱わない |
| number | integer / float を区別 | 数値表現と演算結果の全面的な 5.1 一致は保証しない |
| main thread の `coroutine.running()` | thread と true を返す | 5.1 文書の nil と異なる |
| `os.execute` | 成功 true / 失敗 nil、終了種別と code | 5.1 文書の OS 依存 status code と戻り値契約が異なる |

`resources/scripts` に上表の削除 API 名を直接呼ぶ箇所は今回の静的検索では見つからなかった。文字列生成や外部スクリプトまで含む互換保証ではなく、現に見つかった不整合は以下の原文文字コードとホスト API に分ける。

## 原本のコンパイル結果

構文を受理したのは `gui.lua`、`init.lua`、`layouts.lua`、`layouts_jp.lua`、`option.lua`、`quadraopt.lua`、`screenmenu.lua`、`shortcuts.lua`、`tutorial.lua` の 9 件。`init.lua` が構文を通ることは、読み込む先や初期化 API が動くことを意味しない。

| 拒否した原本 | 最初の拒否位置 | 原 bytes と診断 |
| --- | --- | --- |
| `gui_jp.lua` | 21 行 | `地表観測モード(&S)` の「表」（CP932 `95 5c`）を含む文字列で `invalid escape sequence` |
| `screenmenu_jp.lua` | 7 行 | `表示設定` の「表」で同じ診断 |
| `shortcuts_jp.lua` | 57 行 | `ラベルの表示・非表示` の最初の「表」で同じ診断 |

Lua 5.4.9 の `src/llex.c` の `read_string` は `0x5c` を escape 開始として解釈し、未定義 escape を拒否する。公式 [Lua 5.1.5 の lexer](https://www.lua.org/source/5.1/llex.c.html) では未知の非数値 escape の扱いが異なることをソースで確認した。ただし、その違いだけから旧 Plus の日本語表示や文字列内容が正しかったとは推定しない。旧版独自の文字コード処理や Lua の改変有無は未確認である。

非 UTF-8 の診断を従来の worker が `Lua execution failed` に縮退させることも観測した。監査出力の byte escape で位置と原因を取り出したが、製品側の診断や文字コード処理は今回変更していない。

## ホスト API と残課題

`ScreenMenu`、`Input`、`State` がなく、`mtk.LANGUAGE` は nil、`GUI.addMenu` の参照は `Unsupported` を含むエラーになることを確認した。これらは Lua 言語・標準ライブラリとの差ではなく LUA-01 / CUSTOM / INPUT / STATE 等のホスト実装範囲である。原本には `Scene`、`Targets`、`System`、`MitakaRenderer` 等への参照もあり、今回それらを実行して互換性を確かめてはいない。

- Lua 5.1 / LuaJIT の実行系は PATH と対象リポジトリ内で確認できず、インストールや新規依存は追加していない。旧 Plus と同一入力を並べる実機比較は未実施。
- 12 本の原本は実行していない。GUI、時刻、カメラ、メニュー、初期状態の副作用を伴う互換試験は残る。
- 日本語原本の変換方針、旧 Plus の文字列エンコーディング、非 UTF-8 診断改善は未決定。原本書換えや暗黙変換で今回の監査結果を隠さない。
- 全 Lua 5.1 標準関数、数値の全境界、locale、bytecode、C module ABI、Windows / Intel / macOS 13、旧版と同じ OS 環境での比較は未検証。
