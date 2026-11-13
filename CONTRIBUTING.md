# コントリビューションガイド

不具合は [Issues](https://github.com/mocho271828/Mitaka_plus/issues) で報告できます。再現手順、期待する結果、実際の結果に加えて、macOS のバージョンと Mac のアーキテクチャを添えてください。天体の位置や描画に関する報告では、観測地点、日時と時差、対象の天体、使用したデータがあると同じ条件で確認できます。

## 変更とテスト

1. [README](README.md) の手順でアプリをビルドします。
2. 天文計算とデータの読み込みは `vendor/mitaka/native/core/`、画面・操作・Lua は `vendor/mitaka/native/gui/` で変更します。各ディレクトリの `tests/` に関連するテストがあります。
3. [テスト](#テスト)を実行します。
4. プルリクエストには利用者への影響と確認した手順を記載してください。旧 Plus との対応範囲が変わる場合は[機能対応表](docs/compatibility/PLUS_FEATURE_MATRIX.md)も更新してください。

同梱コードの由来、天文データの扱い、レビュー条件は[実装方針](IMPLEMENTATION_POLICY.md)にまとめています。

## テスト

リポジトリのルートで実行します。

| コマンド | 確認対象 |
| --- | --- |
| `make test` | 計算コア、GUI、コントローラーの自動テスト |
| `make data-test` | 実データを使うカタログ・画像の読み込みと描画モデル |
| `make smoke` | macOS の GUI セッションでアプリを起動し、描画、状態復元、画像出力、再生、飛行、Lua 連携を確認 |

実データを使う試験の既定の入力は `resources/data` です。地球・火星の地形は `git lfs pull` で取得できます。独自のデータで確認する場合は `make data-test DATA_ROOT="/absolute/path/to/data"` のように、`hip.dat` と `cf96.dat` が入ったディレクトリの絶対パスを指定してください。同梱データの件数・版を期待する試験もあります。
