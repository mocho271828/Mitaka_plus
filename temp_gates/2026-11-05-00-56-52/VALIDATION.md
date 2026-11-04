# UNIT8 採用時の gate 検証

- 判定条件のチェックは確認済み、不合格条件のチェックは該当しないことを確認した意味である。
- 採用元は Mitaka `73d3457969f8bcce88937492b66889a90b22d4bd`。共通 native 107 パスを比較し、違いは Plus のデータパス、オフライン Lua 手順、Plus 固有の説明と未同梱証跡への参照である。
- Plus の `make build`、`make test`、`make data-test`、`make reference-test`、`make smoke` は成功。独立したビルドディレクトリでのクリーンビルドも成功。旧版との画素一致や未確認の実機環境は保証しない。
- `resources/` と `vendor/mitaka/sources/` の作業開始時ファイル 885 件について、作業後も SHA-256 一致を確認。原本との比較は過去の検証記録を参照し、今回再比較したと主張しない。リポジトリ公開範囲は変更していない。
- オフライン Lua は既存の同梱固定ソースを使用し、新規依存はない。`/simplifier-lai` は利用できず、LobbyAI 専用の `simplify-lai` は対象外。
- Git の状態、変更ファイル、差分量、`git diff --check` を確認し、300 行を超える変更を commit する。
