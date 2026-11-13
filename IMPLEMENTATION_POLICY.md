# 実装方針

Mitaka_plus は本番投入前の新規プロジェクトです。旧 Mitaka Plus のデータと操作のうち、対応を確認できた範囲を[機能対応表](docs/compatibility/PLUS_FEATURE_MATRIX.md)に記載します。開発版の互換性は保存形式ごとに定めます。

## コードとデータの構成

- 天文計算とカタログの読み込みは `vendor/mitaka/native/core/`、表示・操作・状態保存は `vendor/mitaka/native/gui/` に置きます。ルートの Makefile は共通実装にデータの場所を渡します。
- 操作ガイド、仕様、出典は [docs/](docs/README.md) に集約します。調査記録・測定資料はローカルの `docs/research/` に保存し、Git の管理対象から除外します。公式 Mitaka 1.3.1 の版・配布元は[出典資料](docs/sources/README.md)に記録し、移植コードに対応する第三者の許諾表示をアプリに同梱します。
- 共通実装はソースとして同梱します。採用元 Mitaka の基準コミットは `b901489c9b08a85742ff2d5a0ce1d9db522fe246`、表示半径・地形・銀河・時間の取り込み元は `73d3457969f8bcce88937492b66889a90b22d4bd` です。以降の変更はこのリポジトリで管理します。
- Plus のデータ・画像は `resources/` に保持します。アプリは選択したデータを読み取り専用で開きます。

## レビュー条件

| 対象 | 確認項目 |
| --- | --- |
| コア・GUI・依存関係 | [実装の配置、保存形式、スクリプトの実行](policy_gates/shared_implementation.md) |
| 天文データと画像 | [原本の保全、識別、計算・表示の根拠](policy_gates/preservation.md) |
| ビルドと検証 | [変更範囲に応じた試験と記録](policy_gates/verification.md) |

方針を変える場合はこの文書と該当する判定条件を更新します。検証時は3つのチェック表を `temp_gates/YYYY-MM-DD-HH-MM-SS/` にコピーして記入します。作業用のコピーは Git の管理対象外です。
