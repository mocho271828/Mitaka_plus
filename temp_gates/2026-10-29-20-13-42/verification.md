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

## 不合格条件

- [ ] 失敗した検証を成功として報告する。
- [ ] submodule 内の未 commit の変更を、Plus の gitlink 更新だけで保存したと扱う。

## 判定

YES

## 検証根拠

固定先で make build test data-test reference-test が終了コード 0。初回の DATA_ROOT 指定漏れと異常系試験の停止を記録した。正確な /simplifier-lai は利用不可。差分と依存を手動レビューし、Git 状態・変更ファイル・差分量を確認した。検証範囲と実 OS 遮蔽通知の未通過を VALIDATION.md に明記した。

不合格条件の未チェックは該当なしを示す。詳細は [VALIDATION.md](VALIDATION.md) を参照。
