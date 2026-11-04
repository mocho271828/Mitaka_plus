# Gate: ビルド・検証・変更管理

## 目的

独立したビルドと再現可能な検証手順を残す。

## 判定条件

- [x] macOS の Apple Clang と Make で静的ライブラリとヘッドレス実行ファイルを生成できる。
- [x] 天文計算の既知値・不変量または公式コードとの比較を含むテストが通る。
- [x] ローダーの正常系、切断・不正データ、実データ読み込みの結果を記録している。
- [x] AddressSanitizer と UndefinedBehaviorSanitizer の実行結果を記録している。
- [x] README にビルド・テスト・実データ検証手順と今回の未対応範囲を記載している。
- [x] 作業終了時に Git 状態、追加・変更ファイル、行数を確認し、commit と simplifier skill の実施可否を報告している。

## 不合格条件

- [ ] 実行していないアーキテクチャやテストを成功と記載している。
- [ ] gate の検証コピーを作らずに合格と報告している。

## 判定

YES

判定時点: 2026-10-29 17:47:26 。対象は基準 commit `94c9af3d968fcdb9591e4d3efcf2992954293f01` 以降の今回の作業ツリー。判定条件 6 件は根拠を確認した。不合格条件への該当は確認されず、当該欄は未チェックのままとした。

## 判定根拠

- 条件 1・2: clean clone + staged patch の Apple Clang / Make で libmitaka_core.a、core_probe、GUI と単体テストを構築した。公式比較は CF96 5,427 成分、自転 33,129 成分、月 12,108 成分が成功。ログは investigation/native-plus/logs/ に保存されている。

- 条件 3・4: core の正常・異常入力、Plus / 通常版ローカルデータ、ASan / UBSan を記録した。最初の投影 controller 試験の可視性失敗は残している。試験修正後は通常 1 回、Sanitizer 5 回が各 43 checks 成功し、さらに controller-test 全体の ASan / UBSan 成功を確認した。

- 条件 5: native/core/README.md、native/gui/README.md、investigation/native-plus/README.md にコマンド・結果・近似・未確認範囲を記録している。macOS 13 実機、Intel 実機、物理外部ディスプレイを確認済みとは扱っていない。

- 条件 6: Git status / 変更ファイル / 差分量を確認した。確認時の HEAD 比追跡差分は 87 files、8,427 additions、377 deletions で、未追跡の検証記録・ログ・今回の gate コピーも別途確認対象とした。300 行超のため root が commit を予定している。正確な /simplifier-lai は未導入で、代わりの手動品質レビューを実施した旨を investigation/native-plus/README.md に記録している。これは実施可否と予定の報告を判定したもので、commit / push 完了の認定ではない。

試験の実行とログ保存は親担当 root、根拠照合と検証コピー記入は observation_model が担当した。このコピー作成時のビルド・試験再実行は行っていない。詳細なコマンド・制限・ログへのリンクは [検証記録](../../investigation/native-plus/README.md) にある。

## 実施後判定待ち

commit / push の実施、実行後の commit ID・remote 到達・Git clean の確認は未実施のため判定待ち。上の YES は現在の実装・検証記録への判定であり、commit / push の成功を示すものではない。実施後に親担当が結果を追記する。
