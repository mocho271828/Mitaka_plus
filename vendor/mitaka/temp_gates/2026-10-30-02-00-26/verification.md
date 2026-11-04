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

## 検証根拠

単位7。統合 README、core/GUI/controller/実アプリ3構成、fresh clone、git diff --check を確認。300行以上のため本単位をcommitする。simplifier-lai利用不可は統合READMEと作業報告に明記。 不合格条件はいずれも該当なし。詳細は `investigation/native-plus/unit7/logs/integration/README.md` と同ディレクトリのログを参照。
