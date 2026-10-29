# 単位7採用の gate 検証

対象: `b901489c9b08a85742ff2d5a0ce1d9db522fe246`、3 gate / 39 条件 YES。不合格条件6項目は該当なし。

- 共通コードの複製・新規依存なし。Makefileは既存の大気・食の公式比較ターゲットを追加して委譲する。
- build / test / data-test / reference-test は終了コード0。`verification/unit7-final-pin-tests.log` 参照。
- submodule未取得・空DATA_ROOT・相対DATA_ROOTは案内付き終了コード2。
- gitlinkはfetch済みorigin/mainに存在。vendorの作業ツリーはclean。
- 両リポジトリはPrivate。データ・旧アプリ・画像・認証情報の登録なし。
- 原本保全、JSON v7全体検証、原地点ID、風景・食4項目・時間操作、地形・銀河データ基盤は採用SHAのunit7記録参照。
- 地形・銀河3D表示、旧Plus全機能完了とは記載していない。READMEの現行固定先を単位7へ更新。
- exact `/simplifier-lai` は利用不可。類似skillはLobbyAI専用のため不適用。既存依存、差分、登録範囲を手動レビュー。
- 実機Intel/macOS13、複数画面、実OS完全遮蔽、旧Plusとの全画素一致は未確認。

Git状態・変更一覧・差分量・diff --checkをcommit直前にも確認する。
