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

YES（単位2の commit 前検証。commit / push 自体は実施後判定待ち）。

## 根拠と確認範囲

単位2 README と保存ログに Apple Clang / Make の通常・ASan / UBSan・x86_64 / Rosetta、core 公式参照比較、異常入力、通常版 / Plus 実データ、controller / 全体 smoke の結果を記録した。実行した範囲と Intel / macOS 13 実機・外部ディスプレイ・初回通常版失敗全文等の未確認を区別した。Git の staged 対象 / 行数 / diff check と commit 実施前の状態は VALIDATION.md に記載し、300 行超の commit / push は主担当の実施後判定待ちと報告する。指定名 /simplifier-lai は利用不可で、独立した手動品質レビューを実施した。

共通証跡は [単位2の検証記録](../../investigation/native-plus/unit2/README.md) と [判定対象](VALIDATION.md)。不合格条件は非該当のため未チェック。単位3の未 stage 変更は対象外。
