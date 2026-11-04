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

## 判定根拠（UNIT4 / 2026-10-29-21-28-30 JST）

判定条件 6 件を確認した。不合格条件は今回の対象に該当せず、未チェックのまま残した。対象・共通証拠・制約は [VALIDATION.md](VALIDATION.md) に記録する。

- **[verification](../../policy_gates/verification.md) C1–C5（5 件）**: Apple Clang / Make の static core、既知値・不変量・公式比較、正常 / 不完全 / 異常入力と実データ、3 構成の test / script / controller、README の再現手順・残件を照合。 修正後の全体 Plus smoke は 3 構成で成功。歴史的な SAN 失敗と診断を残し、製品時計の修正や全負荷での保証とは記載しない。
- **verification C6（1 件）**: この記事に基準 HEAD、staged files / 行数、native patch hash を記録。`/simplifier-lai` は利用不可、類似名 `simplify-lai` は LobbyAI 専用で代用しない。依存再利用と手動・独立レビューを記録。 **commit 前後の Git 状態、最終差分量、commit の実施・SHA の報告は主担当が確定する。** 文書担当は今回許可された単位4の文書・ログ・検証コピー・保全結果だけを stage し、commit は主担当が行う。
