# Mitaka Native

Mitaka_plus の macOS アプリを構成する C++17 の天文計算ライブラリと、AppKit / Objective-C++ のデスクトップ GUI です。国立天文台が公開した Mitaka 1.3.1 のソースから計算処理を移植し、旧 Mitaka Plus Windows 1.5.4 のデータと操作に対応しています。機能ごとの対応範囲は [旧 Plus との互換表](PLUS_FEATURE_MATRIX.md) で確認できます。

ビルドと起動は、クローンしたリポジトリのルートで `make run` を実行します。アプリは `native/gui/build/Mitaka Native.app` に生成されます。取得に必要なツール、地形データの Git LFS 設定、別のデータを指定する方法は [プロジェクトの README](../../README.md) を参照してください。

| 資料 | 内容 |
| --- | --- |
| [GUI 操作ガイド](native/gui/README.md) | 全天図・地平図・太陽系の表示、観測地点、時間再生、天体間の飛行、画像出力 |
| [Lua スクリプト](native/gui/SCRIPTING.md) | 実行方法、ローカルファイルへのアクセス、対応 API と旧版との差異 |
| [計算コア](native/core/README.md) | ライブラリのビルド、データ形式、天体位置の計算と原版との比較 |
| [公式ソースの取得記録](sources/README.md) | 比較テストに使う 1.3.1 の原本と SHA-256 |
| [ソースとデータの利用条件](SOURCE_AVAILABILITY.md) | Mitaka、旧 Plus、第三者著作物の出典と適用範囲 |

ビルドしたアプリには [Mitaka の第三者著作権表示](native/gui/THIRD_PARTY_NOTICES.txt) と [Lua の許諾表示](native/gui/LUA_LICENSE.txt) を同梱します。プロジェクトのコードの許諾は [LICENSE](../../LICENSE) を参照してください。
