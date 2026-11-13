# コントリビューションガイド

不具合は [Issues](https://github.com/mocho271828/Mitaka_plus/issues) で報告できます。再現手順、期待する結果、実際の結果に加えて、macOS のバージョンと Mac のアーキテクチャを添えてください。天体の位置や描画に関する報告では、観測地点、日時と時差、対象の天体、使用したデータがあると同じ条件で確認できます。

## 変更とテスト

1. [README](README.md) の手順でアプリをビルドします。
2. 天文計算とデータの読み込みは `vendor/mitaka/native/core/`、画面・操作・Lua は `vendor/mitaka/native/gui/` で変更します。各ディレクトリの `tests/` に関連するテストがあります。
3. リポジトリのルートで `make test` を実行します。データの読み込み、天文計算、画面の変更には、それぞれ[検証手順](VALIDATION.md)の実データ試験、公式ソースとの比較、GUI スモークテストを利用できます。
4. プルリクエストには利用者への影響と確認した手順を記載してください。旧 Plus との対応範囲が変わる場合は[機能対応表](vendor/mitaka/PLUS_FEATURE_MATRIX.md)も更新してください。

同梱コードの由来、天文データの扱い、レビュー条件は[実装方針](IMPLEMENTATION_POLICY.md)にまとめています。
