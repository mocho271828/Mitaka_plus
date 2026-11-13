# Mitaka_plus

Mitaka_plus は、恒星の全天図から地上の観測地点、太陽系、遠方銀河までを探索できる macOS 用の天文シミュレーターです。公式 Mitaka 1.3.1 の天文計算コードを基に、C++17 と AppKit で実装しています。旧 Mitaka Plus 1.5.4 のデータと操作の一部に対応する非公式版です。

## ビルドと起動

ビルドには macOS、Xcode または Xcode Command Line Tools、Git が必要です。アプリは macOS 13.0 以降を対象にビルドします。地球・火星の地形ファイルの取得には [Git LFS](https://git-lfs.com/) を使用します。

```sh
git lfs install
git clone https://github.com/mocho271828/Mitaka_plus.git
cd Mitaka_plus
git lfs pull
make run
```

`make run` はアプリをビルドし、同梱の `resources/data` を開きます。ビルドだけ行うには `make build` を実行してください。出力先は `vendor/mitaka/native/gui/build/Mitaka Native.app` です。Lua 5.4.9 のソースは同梱されており、ビルド時に外部から取得する依存はありません。

## 操作

- **空を眺める** — 全天図と地平図を切り替え、観測地点と日時を指定して恒星、星座、太陽系天体の見え方を確認できます。
- **宇宙を移動する** — 太陽系の 3D 表示で天体を選び、地表への着陸や天体間の飛行ができます。銀河カタログを読み込むと、さらに遠方の天体を検索・表示できます。
- **記録する** — 表示状態を保存して観測を再開したり、画面を PNG・JPEG・BMP に書き出したりできます。
- **Lua で操作する** — カメラ、時刻、表示設定をスクリプトから制御できます。ローカルの Lua はユーザー権限でファイルや OS を操作できるため、信頼するコードを選んで実行してください。

別のデータで起動するには、`hip.dat` と `cf96.dat` が入った `data` フォルダの絶対パスを指定します。アプリ起動後は ⌘O でも選択できます。表面画像や探査機の定義は、その隣の `textures/`、`spacecraft/` から読み込みます。

```sh
make run DATA_ROOT="/absolute/path/to/Mitaka/data"
```

詳しい操作は [GUI ガイド](docs/gui/README.md) と [Lua ガイド](docs/gui/SCRIPTING.md) を参照してください。旧 Plus の公式ソースは含まれていません。対応するデータ形式や旧版との違いは [機能対応表](docs/compatibility/PLUS_FEATURE_MATRIX.md) にまとめています。計算コアや移植元の資料は [ドキュメント一覧](docs/README.md) から探せます。

## 開発に参加する

リポジトリのルートで `make test` を実行できます。実データ試験と変更の提出方法は [コントリビューションガイド](CONTRIBUTING.md#テスト) を参照してください。

## ライセンス

本プロジェクト独自のコードには [MIT License](LICENSE) を適用します。公式 Mitaka と Lua の著作権表示は [Mitaka の表記](vendor/mitaka/native/gui/THIRD_PARTY_NOTICES.txt) と [Lua のライセンス](vendor/mitaka/native/gui/LUA_LICENSE.txt) を参照してください。
