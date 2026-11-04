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

## UNIT5 検証根拠

検証日時: 2026-10-29-22-51-25 JST。対象・最終 patch・実行結果・制限は [VALIDATION.md](VALIDATION.md) を参照。判定条件 6 / 6 を確認し、不合格条件は該当なし。C 番号は上の判定条件を先頭から数えた番号である。

| 条件 | 確認した根拠 | 判定の範囲と制限 |
| --- | --- | --- |
| C1–C5（5） | Clang/Make、core の既知値・公式比較、loader 正常/異常/実原本、ASan/UBSan、README 手順と未完範囲。個別・統合・全体 smoke の範囲を分ける。 | 最新 full smoke / clone は成功。Rosetta 実行と Intel 実機、macOS 13 実機は区別。 |
| C6（1） | exact simplifier 不在と代用しない理由、依存再利用、独立レビューを記録。Git status と native / docs 差分を確認。 | 最終 native patch hash と差分量を確認済み。全資料の stage 後の差分量、commit/push、最終 Git 状態は主担当が確定する。 |
