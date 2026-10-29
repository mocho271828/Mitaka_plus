# 単位5採用の gate 検証

対象: `5dd3409f8c551ff94666d84f4504f6f92f7047c7`、3 gate / 35 条件 YES。

- 共通コードの複製・新規依存なし。既存 Makefile と submodule へ委譲。
- build / test / data-test / reference-test は終了コード0。`verification/unit5-final-pin-tests.log` 参照。
- submodule未取得・空DATA_ROOT・相対DATA_ROOTは案内付き終了コード2。
- gitlinkはfetch済みorigin/mainに存在。vendorの作業ツリーはclean。
- 両リポジトリはPrivate。データ・旧アプリ・画像・認証情報の登録なし。
- 原本保全・JSON v5 の全体検証・小天体/衛星集合・PTH・星座集合は採用SHAのunit5記録参照。
- 旧Plus全機能完了とは記載していない。READMEの現行固定先を単位5へ更新。
- exact `/simplifier-lai` は利用不可。類似skillはLobbyAI専用のため不適用。依存と差分を手動レビュー。
- 実機Intel/macOS13、複数画面、実OS完全遮蔽、旧Plusとの全画素一致は未確認。

Git状態・変更一覧・差分量・diff --checkをcommit直前にも確認する。
