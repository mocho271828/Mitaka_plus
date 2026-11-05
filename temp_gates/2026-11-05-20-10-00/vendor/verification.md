# Gate: ビルド・検証・変更管理

## 目的

独立したビルドと再現可能な検証手順を残す。

## 判定条件

- [x] macOS の Apple Clang と Make で静的ライブラリとヘッドレス実行ファイルを生成できる。
  - 判定根拠: 今回作業ツリーの make build / test / data-test / reference-test が終了コード 0（作業担当からの結果）。従来の実データ・異常入力・公式比較は VALIDATION.md と単位7/8記録を併用。
- [x] 天文計算の既知値・不変量または公式コードとの比較を含むテストが通る。
  - 判定根拠: 今回作業ツリーの make build / test / data-test / reference-test が終了コード 0（作業担当からの結果）。従来の実データ・異常入力・公式比較は VALIDATION.md と単位7/8記録を併用。
- [x] ローダーの正常系、切断・不正データ、実データ読み込みの結果を記録している。
  - 判定根拠: 今回作業ツリーの make build / test / data-test / reference-test が終了コード 0（作業担当からの結果）。従来の実データ・異常入力・公式比較は VALIDATION.md と単位7/8記録を併用。
- [x] AddressSanitizer と UndefinedBehaviorSanitizer の実行結果を記録している。
  - 判定根拠: VALIDATION.md の P1-4 記録に evaluator/sampler の ASan+UBSan 成功を記載。GUI 全体の sanitizer は今回未実施。
- [x] README にビルド・テスト・実データ検証手順と今回の未対応範囲を記載している。
  - 判定根拠: README.md と native/gui/README.md にビルド・実データ手順と P1 の未対応範囲を記載。
- [x] 作業終了時に Git 状態、追加・変更ファイル、行数を確認し、commit と simplifier skill の実施可否を報告している。
  - 判定根拠: 前回作業終了時に Git 状態・変更ファイル・差分量を確認し、commit 8ff301c と利用不可の simplifier を報告済み。今回の gate 判定更新・push 後も作業担当が Git 状態等を確認し報告する。

## 不合格条件

- [ ] 実行していないアーキテクチャやテストを成功と記載している。
  - 判定: 実行結果と未実施範囲を区別して VALIDATION.md に記録。
- [ ] gate の検証コピーを作らずに合格と報告している。
  - 判定: この検証コピーを作成済み。

## 判定

YES（実施済みの検証結果と未実施範囲を区別。不合格条件の未チェックは該当が確認されていないことを示す。）
