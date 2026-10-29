# 単位6採用の gate 検証

対象: `d1c361a750b2a1d71d71c423194954c4eade7a81`、3 gate / 37 条件 YES。不合格条件6項目は該当なし。

- 共通コードの複製・新規依存なし。既存 Makefile と submodule へ委譲。
- build / test / data-test / reference-test は終了コード0。`verification/unit6-final-pin-tests.log` 参照。
- submodule未取得・空DATA_ROOT・相対DATA_ROOTは案内付き終了コード2。
- gitlinkはfetch済みorigin/mainに存在。vendorの作業ツリーはclean。
- 両リポジトリはPrivate。データ・旧アプリ・画像・認証情報の登録なし。
- 原本保全、JSON v6全体検証、星座絵・恒星名選択・明るさ補間・地球層・大気・地点読込は採用SHAのunit6記録参照。
- 旧Plus全機能完了とは記載していない。READMEの現行固定先を単位6へ更新。
- exact `/simplifier-lai` は利用不可。類似skillはLobbyAI専用のため不適用。既存依存、差分、登録範囲を手動レビュー。
- 実機Intel/macOS13、複数画面、実OS完全遮蔽、旧Plusとの全画素一致は未確認。

Git状態・変更一覧・差分量・diff --checkをcommit直前にも確認する。
