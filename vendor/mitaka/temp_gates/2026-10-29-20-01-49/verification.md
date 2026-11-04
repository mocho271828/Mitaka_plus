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

## 判定根拠

検証日: 2026-10-29 20:01 JST。条件番号はこのコピーの判定条件を上から数えたもの。

- 条件1〜3: 単位3 clean の core / GUI all test、通常 / sanitizer / x86_64 の各 test、Plus / 通常版 data-test、4回の全体smokeが成功。既存core公式比較は単位2の成功ログを参照し、単位3で再実行したとは扱わない。
- 条件4: 各 model/test と全体 smoke の ASan/UBSan は成功。最終 controller 全体も ASan/UBSan を含む3構成すべて exit 0。個別ログの成功行を確認した。
- 条件5: GUI README / SCRIPTING / provenance / matrix / unit3 README は手順と部分互換・未対応・実OS遮蔽未通過を区別する。
- 条件6: Git状態・変更ファイル・index差分量・差分検査を確認し、VALIDATION.md に記録した。指定名の simplifier skill は利用不可で手動レビューを実施。300行超の commit は主担当の担当であり、本担当は stage / commit していない。
- 不合格条件は非該当。途中結果を最終合格として扱わず、実行していない構成を成功と記載しない。

共通の対象範囲・ログ・限界は [VALIDATION.md](VALIDATION.md) を参照する。不合格条件の未チェックは非該当を表す。

最終確定: 2026-10-29 20:06 JST。通常 / ASan・UBSan / x86_64 の最終 controller 一式の exit 0 を確認した。対象は UNIT3 の index であり、並行して開始された UNIT4 の未 stage 差分を含めない。
