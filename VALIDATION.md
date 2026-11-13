# 検証手順

以下のコマンドはリポジトリのルートで実行します。初回のビルドに必要なツールと Git LFS の設定は [README](README.md) を参照してください。

| コマンド | 確認する内容 |
| --- | --- |
| `make build` | AppKit アプリ、C++17 コア、Lua helper のビルド |
| `make test` | コア・GUI・コントローラーの自動テスト |
| `make data-test` | 実データを使ったカタログ、暦表、画像、描画モデルの読み込みと評価 |
| `make reference-test` | 公式 Mitaka 1.3.1 の計算との比較。CF96、自転、月、大気、食、天の川が対象 |
| `make smoke` | macOS の GUI セッションでアプリを起動し、描画、状態の復元、画像出力、再生、飛行、Lua 連携を確認 |

実データ試験は既定で `resources/data` を使います。別のデータを試す場合は `DATA_ROOT` に `data` ディレクトリの絶対パスを指定してください。ファイル構成や版に依存する試験の比較基準は同梱データです。地形の取得は `git lfs ls-files` で確認でき、取得済みの地形ファイルには `*` が付きます。

## 表示と操作の比較資料

自動テストのほかに、旧 Plus とネイティブ版の表示・操作を比較した測定値があります。以下の資料は記載されたデータと観測条件に対応します。

<a id="p1-camera-attitude"></a>

- [カメラの姿勢と時間補間](verification/p6/)では、旧版の Euler 角と quaternion の読み戻し値、ネイティブ版のフレームと終端値を比較できます。

<a id="p1-earth-flight"></a>

- [地球からの離陸と地平図への帰還](verification/p5/)には、同一地点への帰還時の姿勢、地球の輪郭、飛行中の画角の測定値があります。

<a id="p1-orbit-formats"></a>

- [軌道と探査機](verification/p4/)には、小天体の軌道標本、旧版の投影結果、探査機の時刻と座標を収録しています。

<a id="p1-ground-window"></a>
<a id="2026-11-11-火星への連続降下中の地形更新"></a>

- [地平図と地形](verification/p1-ground/)では、地表付近の表示や着地時の地形の測定値を確認できます。地形の実データ試験は `make -C vendor/mitaka/native/gui terrain-real-data-test` です。

<a id="p1-window-flight"></a>

- [地球から大規模構造までの往復](verification/p1-1-window-roundtrip.tsv)には、カメラの距離を変えたときの描画と選択の結果があります。
