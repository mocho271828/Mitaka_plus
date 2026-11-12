# P1-6 Lua 姿勢と銀河表示の gate 検証

- 判定条件のチェックは確認済み、不合格条件のチェックは該当しないことを確認した意味である。変更対象に無関係な条件は既存の検証記録と今回の差分に基づく。原本を今回あらためて比較したと主張しない。
- 基点 `f27914c` の隔離 checkout で `make -j4 build`、`make -j4 test`、`make -j4 data-test`、`make -j4 reference-test`、`make smoke` が成功。data-test と smoke の `DATA_ROOT` は同一リポジトリの共有 checkout の `resources/data` を読み取り専用で指定した。
- `plus-camera-orientation-test` と `script-test` も成功。Lua での倍精度読み戻し、補間途中の再指定、銀河 overlay の表示済みフレームを smoke で検証した。手動 GUI と旧 Plus の比較は未実施。
- ソースに新規依存を追加していない。`/simplifier-lai` は利用できず、利用可能な `simplify-lai` は LobbyAI 専用で対象外。既存の姿勢モデルと Lua bridge を使用する。
- Git 状態、変更ファイル、差分量と `git diff --check` を確認する。原データ、公開範囲、全体方針は変更していない。
