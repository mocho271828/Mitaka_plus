# Gate: リポジトリ分離と登録範囲

## 目的

共通実装の重複と、ローカルデータ・旧環境の意図しない登録を防ぐ。

## 判定条件

- [x] 共通コアと GUI の変更先は Mitaka の `native/` であり、Mitaka_plus に複製していない。
- [x] GitHub リポジトリの可視性は Private である。
- [x] Git の追跡対象はソース・文書・設定・公式ソース原本であり、天文データ・表面画像・旧アプリ・Wine 環境・生成物を含まない。
- [x] 公式ソースは `.gitattributes` で改行変換を無効にし、ZIP と展開原本の一致を確認している。
- [x] 新規 clone からビルドと単体テストを実行でき、ローカルデータは明示的なパスで参照する。

## 不合格条件

- [ ] 許可なくリポジトリを Public にする、またはローカルデータ・認証情報を登録する。
- [ ] 共通実装を Mitaka_plus へコピーして並行保守する。

## 判定

YES

判定時点: 2026-10-29 17:47:26 。対象は基準 commit `94c9af3d968fcdb9591e4d3efcf2992954293f01` 以降の今回の作業ツリー。判定条件 5 件は根拠を確認した。不合格条件への該当は確認されず、当該欄は未チェックのままとした。

## 判定根拠

- 条件 1・3: git status / diff の変更先は共通側 native と関連文書・設定・検証記録であり、Mitaka_plus へ実装を複製していない。追跡 native に dat / jpg / png / build を含めない確認を root が実施し、.gitignore と差分の手動レビューでも原本・生成物の登録を認めなかった。

- 条件 2: この検証中に `gh repo view --json nameWithOwner,isPrivate,visibility` を実行し、mocho271828/Mitaka は isPrivate=true / visibility=PRIVATE と確認した。root も両リポジトリの Private を再確認した。

- 条件 4: .gitattributes は /sources/official/** に -text を指定する。preservation-final.json の公式 ZIP 310 ファイル照合は不一致 0。

- 条件 5: 新規 clone に今回の staged patch を適用し、既存生成物を持ち込まず core all test と GUI all test が成功した。clean-build ログに clone と core_probe / libmitaka_core.a / GUI のコンパイル記録がある。ローカルデータは起動引数 / DATA_ROOT で明示指定している。commit / push 済みの remote clone の試験という意味ではない。

試験の実行とログ保存は親担当 root、根拠照合と検証コピー記入は observation_model が担当した。このコピー作成時のビルド・試験再実行は行っていない。詳細なコマンド・制限・ログへのリンクは [検証記録](../../investigation/native-plus/README.md) にある。

## 実施後判定待ち

commit / push の実施、実行後の commit ID・remote 到達・Git clean の確認は未実施のため判定待ち。上の YES は現在の実装・検証記録への判定であり、commit / push の成功を示すものではない。実施後に親担当が結果を追記する。
