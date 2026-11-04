# リポジトリ分離の検証記録

確認日: 2026-10-29。実行環境: macOS 26.6.2、Apple Silicon arm64、Apple Clang、Make。

## 構成と登録範囲

- `repositories/Mitaka/` を共通コア・GUI・公式 1.3.1 ソースの開発先とした。
- `repositories/Mitaka_plus/` は Git submodule の固定コミットで共通実装を参照し、既存 Makefile に処理を委譲する。
- GitHub の `mocho271828/Mitaka` と `mocho271828/Mitaka_plus` は両方 `isPrivate: true`、`visibility: PRIVATE` を API で確認した。
- ソース・文書・設定だけを登録する。天文データ・惑星画像・旧アプリ・Wine・生成物は除外し、公式ソースの ZIP と同梱リソースは原本の一部として保持する。
- ワークスペースの既存データと公式原本は同じパスで保持し、移行前の `native/` は `archive/native-before-repository-split/` へ保存した。
- 新しい実行時依存はない。Git submodule、Make、既存の C++17 / AppKit と macOS 標準フレームワークを利用する。

Mitaka の初回登録コミットは `67c4779c879454763c30e5e5858011c4eacc96d9`。
以下の共通コードの検証はこのコミットの実装を対象とし、その後の登録は案内・作業規則・検証記録のみである。
移行元の 74 ソースファイルとの照合では、実装・ヘッダー・Makefile・テストの差異はなく、4 つの文書の作業ディレクトリ案内のみ更新した。

## 実行結果

以下は今回実行し、すべて終了コード 0。

| 対象 | 検証 | 記録 |
| --- | --- | --- |
| Mitaka core | `all test rotation-reference-test lunar-reference-test` | [core-tests.log](core-tests.log) |
| Mitaka GUI | `all test controller-test` | [gui-tests.log](gui-tests.log) |
| Mitaka 既存データ | GUI / core `data-test`、CF96 `reference-test` | [data-mitaka.log](data-mitaka.log) |
| Mitaka AppKit | 実アプリの smoke test | [smoke-mitaka.log](smoke-mitaka.log) |
| GitHub から取得した共通コード | Plus の `make build` | [plus-build.log](plus-build.log) |
| 同上 | Plus の `make test` | [plus-tests.log](plus-tests.log) |
| Mitaka_plus 既存データ | Plus の `make data-test reference-test` | [data-mitaka-plus.log](data-mitaka-plus.log) |

AppKit の smoke test は星・太陽系・11 枚の表面画像・自転・実タイマーによる時間再生・月・地表移動・連続飛行の完了を確認した。
実データテストは両方のデータセットを読み取り専用で参照し、全 10 着陸対象を含むモデルの検証も通った。
公式との比較は惑星位置、自転 33,129 成分、月位置・姿勢 12,108 成分を確認した。
Plus の入口では submodule 未取得、`DATA_ROOT` 不足の停止と、空白を含む絶対パスの受け渡しも確認した。

`-Wall -Wextra -Wpedantic -Werror` を指定した既存ビルドが通った。
独立した lint ターゲットはない。
今回、実装コードは変えていないため AddressSanitizer / UndefinedBehaviorSanitizer を再実行していない。
前回の [連続飛行の検証記録](../native-continuous-flight/VALIDATION.md) と sanitizer ログは保持し、今回の実行結果とは区別する。
Intel Mac、macOS 13 実機、全操作の人手による再確認は今回の対象に含めていない。

## 保全・レビュー・方針

[保全記録](PRESERVATION.md) の最終照合で通常 16,365 ファイル、465 シンボリックリンクが一致し、追加・削除・変更は 0 件。
GitHub から取得した公式原本の 311 ファイルも一致した。
実装・登録内容・依存の [独立レビュー](REVIEW.md) で登録を止める不具合はなかった。
秘密鍵と代表的なトークン形式の簡易検索でも登録予定ファイルに該当はなかった。

`IMPLEMENTATION_POLICY.md` と policy gate にリポジトリ構成・Private・登録範囲・固定コミット参照を記録した。
各 gate の検証コピーを `temp_gates/` に作成し、既存実装の検証記録と今回の結果を根拠に判定する。
不合格条件の未チェックは「該当なし」を表す。

正確な名前の `/simplifier-lai` は利用できず未実行。
類似名の `simplify-lai` は非 LobbyAI プロジェクトを適用対象外としているため使用しなかった。
依存関係と差分全体は独立レビューで確認した。

## Git

初回登録は 527 ファイル、96,462 行追加で、commit / push 済み。
原本の CP932・CRLF は `.gitattributes` の `-text` で保持した。
新規文書と設定の `git diff --check` を行い、元の公式ファイルと過去ログの既存空白は変更しない。
最終登録時も状態・変更ファイル・差分量を確認し、検証記録と Plus の固定参照を commit / push する。
取得・更新後は各リポジトリの `git status` と Plus の `git submodule status` で状態を確認できる。
