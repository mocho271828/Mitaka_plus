# 単位2の policy gate 検証

検証日: 2026-10-29 19:09 JST。判定者: observation_model 担当、統合試験実施者: 主担当および各実装担当。

## 対象と結論

基準 HEAD は `3f47a39972340c6673f5b8aa4ad8b57bd7564840`。主担当が単位2のソースを固定した tree は `21f3a1376816e4fa716bff8ed1537ec7779d2cd1`。
その後に追加した単位2のログ・検証文書・この gate コピーを含めて commit 前にレビューした。並行中の単位3ソース、調査文書、未 stage 変更はこの判定の対象外である。

**14 gate は YES。** 各コピーの判定条件に根拠を確認してチェックを入れた。不合格条件は非該当として未チェックのまま残した。テンプレートの `policy_gates/` はこの作業では編集していない。
この判定は Mitaka_plus の全機能完成を意味しない。今回の実装範囲、未対応 API、原版との未確定差は機能対応表と単位2 README に残る。

## 証跡

- [単位2の検証記録](../../investigation/native-plus/unit2/README.md) に通常 / ASan / UBSan / x86_64 / Rosetta、core 比較、通常版 / Plus 実データ、controller、全体 smoke、CUA 媒体操作を記録した。
- [ログ manifest](../../investigation/native-plus/unit2/logs/SNAPSHOT.tsv) に 22 本の元ログのコピー、元日時・サイズ・SHA-256 を記録した。別に Camera.zoom の取得出力記録と初回通常版失敗の抜粋を保存している。
- 初回小天体 smoke の非同期待機失敗、任意媒体を必須とした実データ assertion、媒体 clip の修正前失敗を削除せず、修正と再試験の範囲を記した。
- 新規 clone は局所修正前の staged patch で成功した。後続の Camera / media clip / 任意媒体 assertion は strict build・sanitizer・controller・全体 smoke で再確認したが、最終全差分の新規 clone 試験は再実行していない。
- 原本は [preservation-final.json](../../investigation/native-plus/preservation-final.json) で追加・削除・変更 0、公式 ZIP 310 ファイル一致、参照 checkout clean を確認した。
- 既存依存の再利用、AVKit / AVFoundation の導入理由、App* の境界、非同期選択と時刻・状態復元を手動レビューした。指定名 `/simplifier-lai` は利用不可。別名の LobbyAI 用 `simplify-lai` を実行したとは扱わない。

## Git と commit 前の確認

文書担当は単位2の証跡文書・ログとこの gate ディレクトリだけを stage する。単位3のコード・調査文書は stage しない。
300 行超のため主担当が commit する。**commit / push は実施後判定待ち**であり、現時点の成功とは扱わない。
主担当は実施後に source commit、push 結果、Mitaka_plus の参照更新とその最終状態を追記する。
最終 staged のファイル数・追加削除行、差分検査、tree は下記の確認記録を参照する。

2026-10-29 19:10 JST の確認では、単位2の staged 差分は 128 files、8,281 行追加・392 行削除（この確認追記前）。`git diff --cached --check` と `git diff --check` は成功した。固定 tree から staged `native/` への差分はなく、単位3の変更は未 stage / untracked として区別されている。
保存した 22 本のログは manifest のサイズ・SHA-256 と一致し、14 コピーの判定条件 130 個はチェック済み、不合格条件は未チェックだった。git status の追加・変更ファイルを確認した。commit / push は引き続き主担当の実施後判定待ち。

## commit 後の追記

ローカル Git で source commit `ae300e1e396c5ed0e6eb5129ad8a6f0069489597` を確認した。wrapper commit `8497dfe` の `vendor/mitaka` も同じ source commit を指している。
上節の未 commit 記録は 19:10 JST 時点の経緯として残す。この追記では push 状態を確認しておらず、単位3の作業ツリー変更や後続 gate の合否も判定しない。
