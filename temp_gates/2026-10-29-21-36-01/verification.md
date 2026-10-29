# Gate: ビルド・検証・変更管理

## 目的

共通実装の参照先とデータの渡し方を、再現可能なビルドと検証で確認する。

## 判定条件

- [x] `make build` と `make test` が成功する。
- [x] データ参照や submodule の採用コミットを変更した場合、既存データを指定した `make data-test` と `make reference-test` が成功する。
- [x] `DATA_ROOT` は絶対パスの `data` ディレクトリとして受け取り、コアのデータテストにはその親ディレクトリを渡す。
- [x] submodule 未取得や `DATA_ROOT` 不足の場合は、手順を示すエラーで停止する。
- [x] 作業完了時に `git status`、変更ファイル、差分量を確認し、300 行以上の変更では原則 commit する。
- [x] commit 前に `/simplifier-lai` skill の利用可否と依存関係を確認し、利用できない場合は報告する。
- [x] gate 検証用コピーに判定を記録し、実施したテストと未実施の確認を作業報告へ残す。
- [x] 追加衛星・描画品質・全画面・HTML を採用する場合、共通側の対応試験と採用 SHA を特定する。HTML helper の構成、実 OS 通知、実機・複数画面など未確認の範囲を成功扱いしない。

## 不合格条件

- [ ] 失敗した検証を成功として報告する。
- [ ] submodule 内の未 commit の変更を、Plus の gitlink 更新だけで保存したと扱う。

## 判定

YES

## 検証根拠

- 固定 SHA で `make build test data-test reference-test` の exit 0 を確認し、`verification/unit4-final-pin-tests.log` に保存した。core / GUI / controller / Plus 実データ / 公式比較を含む。
- 既存 Makefile の `DATA_ROOT` 契約を確認。data ディレクトリを GUI へ、その親を core の data-test へ渡す。
- 未取得 submodule、空 DATA_ROOT、相対 DATA_ROOT の 3 件が案内付き exit 2 で停止。`verification/unit4-negative.log` に保存した。
- `git status`・変更ファイル・差分量・`git diff --check`・stage 範囲を確認し、300 行以上のログと記録を含めこの採用を commit / push する。submodule 自体の未保存変更はない。
- 正確な `/simplifier-lai` は利用不可。類似の `simplify-lai` は LobbyAI 専用なので適用しない。既存依存の再利用と不要なコード複製がないことを手動レビューした。
- この timestamp の 3 gate / 26 条件を記入した。不合格条件の未チェックは該当なしを示す。
- renderer 64、HTML policy 80、session 964、satellite controller 38、solar satellite 99、controlled fullscreen 31、controlled occlusion 46 checks がラッパーで成功。HTML 実ブラウザ/helper 結合、3 構成の全体 smoke と script-test は同じ固定 SHA の共通単位4記録を参照し、ラッパーで重複実行したとは扱わない。
- 実 OS の完全遮蔽通知は共通側の未通過を保持。Intel Mac / macOS 13 実機、複数画面、全操作の人手確認は未実施。共通側の途中失敗と fixture 修正の記録は消さない。

詳細は [今回の検証記録](VALIDATION.md) と [リポジトリの記録](../../VALIDATION.md) を参照。
