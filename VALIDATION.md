# 検証記録

## 2026-10-29: 表示設定・座標格子・カレンダーの更新

共通実装を `cf4fcbfe5447adf554e5bca0b0caf5ae5f529505` に固定した。Mitaka の `origin/main` に存在し、submodule 自体に未保存の差分がないことを確認した。

`DATA_ROOT` に独自追加を含むローカル Plus の `data` を指定し、`make build test data-test reference-test` の終了コード 0 を確認した。記録は [verification/unit3-final-pin-tests.log](verification/unit3-final-pin-tests.log)、ログの SHA-256 は [verification/unit3-SHA256SUMS](verification/unit3-SHA256SUMS)。小天体 19,475 行を保持し、そのうち 2,388 行の位置を評価した。カタログ一覧は 1,059,477 行を保持し、500 行ずつ表示する契約を確認した。公式計算との比較は CF96 5,427 成分、自転 33,129 成分、月 12,108 成分が成功した。

最初の呼び出しでは `DATA_ROOT` の指定がなく、ビルドとテストの成功後、`check-data` が案内を出して終了コード 2 で停止した。[初回ログ](verification/unit3-initial-invocation.log) を保持し、指定を加えて全ターゲットを再実行した。submodule 未取得と相対 `DATA_ROOT` も、[異常系ログ](verification/unit3-negative.log) のとおり案内付きエラーで停止する。

投影ウィンドウのテストは、試験ウィンドウに遮蔽状態を注入してタイマー条件を検証するもので、46 checks が成功した。実 OS の完全遮蔽通知は共通側で未通過のまま保持しており、この結果を実 OS 通知の成功とは扱わない。共通側の通常・ASan/UBSan・Rosetta x86_64 のコントローラ試験、4 回の GUI smoke、原本保全の結果と制約は [共通側の単位3記録](vendor/mitaka/investigation/native-plus/unit3/README.md) を参照。ラッパーでは sanitizer・x86_64・smoke を重複実行せず、Intel Mac と macOS 13 の実機確認も未実施である。

両 GitHub リポジトリが Private であることを再確認した。共通コードの複製、新規依存、原本・天文データの登録はない。`IMPLEMENTATION_POLICY.md` と対応 gate に、明示的に信頼したローカル HTML のみ Lua 呼び出しを許可する方針を追記した。HTML ブラウザの実装完了は主張しない。

正確な名前の `/simplifier-lai` は利用できず未実行。類似名の `simplify-lai` は LobbyAI 専用のため対象外である。既存 Makefile と Git submodule の利用、差分、依存と登録範囲を手動レビューした。[今回の gate 記録](temp_gates/2026-10-29-20-13-42/VALIDATION.md) は 3 gate と 22 条件を YES とし、不合格条件の未チェックは該当なしを示す。Git 状態・変更ファイル・差分量を確認し、この更新を commit / push する。

## 2026-10-29: ローカル Plus データ対応の更新

共通実装を `ae300e1e396c5ed0e6eb5129ad8a6f0069489597` に固定した。Mitaka の `origin/main` に存在し、submodule 自体に未保存の差分がないことを確認した。

この固定コミットで `make build test data-test reference-test` が終了コード 0。記録は [verification/unit2-final-pin-tests.log](verification/unit2-final-pin-tests.log)。Plus 原本を指定し、独自追加を含む小天体・画像一覧・天の川背景、既存カタログ、GUI と Lua コントローラを検証した。公式比較は CF96 5,427 成分、自転 33,129 成分、月 12,108 成分が成功した。

共通側の sanitizer、Rosetta x86_64、GUI smoke、画面操作、原本保全は [共通側の検証記録](vendor/mitaka/investigation/native-plus/unit2/README.md) を参照。Intel Mac と macOS 13 の実機確認は未実施。

両 GitHub リポジトリが Private であることを再確認した。新規依存やコードの複製はなく、画像・動画は共通実装の ImageIO / AVKit を使う。`/simplifier-lai` は利用できず未実行。類似名の `simplify-lai` は LobbyAI 専用のため対象外。依存・差分・登録範囲を手動レビューした。

今回の変更は共通参照、README、検証記録のみであり、既存の方針を変更していない。3 gate の検証コピーへ判定を記録し、Git 状態・変更ファイル・差分量を確認して commit する。

確認日: 2026-10-29。macOS 26.6.2 / arm64。

## 固定参照

`vendor/mitaka` は Private リポジトリ `https://github.com/mocho271828/Mitaka.git` の Git submodule。
採用コミットは `94c9af3d968fcdb9591e4d3efcf2992954293f01`。
このコミットは GitHub の `main` に push 済みであることを fetch で確認した。
初回取得した `67c4779c879454763c30e5e5858011c4eacc96d9` との差分は作業規則・案内・検証記録だけで、`native/` と `sources/` に差分はない。
共通コードの複製、新規の実行時依存、既存データの登録は行っていない。

## 実行した検証

GitHub から取得した共通コードで初回ビルドとコア・GUI・コントローラのテストが成功した。
最終コミットへ参照を更新した後にも、以下をすべて実行して終了コード 0 を確認した。

```sh
make build test data-test reference-test
```

`DATA_ROOT` はローカルに保持した Mitaka_plus の `data` を明示した。
空白を含む絶対パスの受け渡し、既存データの読み込み、11 枚の画像、全着陸対象、CF96・自転・月の公式計算との比較が成功した。
記録は [verification/final-pin-tests.log](verification/final-pin-tests.log)。
submodule 未取得とデータ指定不足で案内付きエラーになることも確認した。

共通実装の AppKit smoke test、元ファイルの保全照合、依存と登録範囲の独立レビューは [共通リポジトリの検証記録](vendor/mitaka/investigation/repository-organization/VALIDATION.md) を参照。
実装コードは変更していないため、sanitizer は今回再実行せず既存の結果を保持した。
Intel Mac、macOS 13 実機、全操作の人手による再確認は今回行っていない。

## 方針と変更管理

両 GitHub リポジトリの `isPrivate: true` と `visibility: PRIVATE` を確認した。
`IMPLEMENTATION_POLICY.md` と 3 つの policy gate に共通参照、登録範囲、データ保全、検証手順を記録した。
gate は `temp_gates/` にコピーし、判定条件をチェックして YES とした。
不合格条件の未チェックは該当なしを表す。

正確な名前の `/simplifier-lai` は提供されておらず未実行。
類似の `simplify-lai` は非 LobbyAI プロジェクトを適用対象外としているため使用していない。
既存 Makefile と Git submodule の利用、不要な独自実装がないことを独立レビューで確認した。
登録前に Git 状態・追加ファイル・差分量と `git diff --check` を確認し、初回ファイルと固定参照を commit / push する。
